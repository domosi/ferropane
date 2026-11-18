import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import '../core/ffi_bridge.dart';
import '../core/models.dart';
import '../core/native_macos.dart';
import '../core/session_store.dart';
import '../core/theme_palette.dart';

enum PaneSide { left, right }

enum ActiveDialog {
  none,
  lister,
  openWithPalette,
  favoritesHotlist,
  deepCompare,
  copyConfirm,
  moveConfirm,
  mkdirPrompt,
  deleteConfirm,
  selectPattern,
  gotoPath,
}

class PaneTabController {
  final int rustPaneId;
  PaneSummaryModel summary;
  int cursorIndex = 0;
  final ScrollController scrollController = ScrollController();

  /// When browsing inside a virtual .zip / .tar.gz archive:
  String? archiveFilePath;
  String? archiveMountDir;

  int _cachedStart = -1;
  int _cachedCount = 0;
  List<DirEntryModel> _cachedSlice = const [];

  PaneTabController({required this.rustPaneId, required this.summary});

  bool get isInsideArchive =>
      archiveFilePath != null &&
      archiveMountDir != null &&
      summary.currentPath.startsWith(archiveMountDir!);

  String get displayPath {
    if (isInsideArchive) {
      final rel = summary.currentPath.substring(archiveMountDir!.length);
      return '${archiveFilePath!}$rel';
    }
    return summary.currentPath;
  }

  String get title {
    if (isInsideArchive) {
      final rel = summary.currentPath.substring(archiveMountDir!.length);
      final archiveName = archiveFilePath!.split('/').last;
      if (rel.isEmpty || rel == '/') {
        return '📦 $archiveName';
      }
      final sub = rel.split('/').where((s) => s.isNotEmpty).last;
      return '📦 $sub';
    }
    final p = summary.currentPath;
    if (p == '/' || p.isEmpty) return '/';
    final segments = p.split('/').where((s) => s.isNotEmpty).toList();
    return segments.isEmpty ? '/' : segments.last;
  }

  void invalidateCache() {
    _cachedStart = -1;
    _cachedCount = 0;
    _cachedSlice = const [];
  }

  DirEntryModel? getRow(TcRustBridge bridge, int index) {
    if (index < 0 || index >= summary.totalRows) return null;
    if (index < _cachedStart || index >= _cachedStart + _cachedCount) {
      _cachedStart = (index - 30).clamp(0, summary.totalRows);
      _cachedCount = 120;
      _cachedSlice = bridge.getVisibleSlice(
        rustPaneId,
        _cachedStart,
        _cachedCount,
      );
    }
    final offset = index - _cachedStart;
    if (offset >= 0 && offset < _cachedSlice.length) {
      return _cachedSlice[offset];
    }
    return null;
  }

  void dispose(TcRustBridge bridge) {
    scrollController.dispose();
    bridge.destroyPane(rustPaneId);
  }
}

class CommanderController extends ChangeNotifier {
  final TcRustBridge _bridge = TcRustBridge.instance;
  final ValueChanged<UiFrameworkMode> onUiFrameworkChanged;

  UiFrameworkMode _uiFramework;
  TcThemeId _themeId;
  PaneSide activeSide = PaneSide.left;
  double splitRatio = 0.5;
  bool showHidden = false;

  final List<PaneTabController> leftTabs = [];
  final List<PaneTabController> rightTabs = [];
  int activeLeftTabIndex = 0;
  int activeRightTabIndex = 0;

  ActiveDialog activeDialog = ActiveDialog.none;
  final TextEditingController dialogTextController = TextEditingController();
  final FocusNode dialogInputFocusNode = FocusNode(
    debugLabel: 'DialogInputFocus',
  );

  bool deleteUseTrash = true;
  ListerSliceModel? listerSlice;
  bool listerHexMode = false;
  int listerOffset = 0;

  // "Open With..." state (Palette + Right-Click Context Menu + Smart F4)
  final Map<String, String> preferredAppsByExt = {};
  DirEntryModel? openWithTargetEntry;
  List<OpenWithAppInfo> openWithApps = const [];
  int openWithSelectedIndex = 0;
  bool openWithRememberForExt = false;

  Offset? contextMenuPosition;
  DirEntryModel? contextMenuEntry;

  // Deep Compare (Synchronize Directories) state
  DirCompareResultModel? compareResult;
  bool deepCompareByContent = true;
  bool compareShowOnlyLeft = true;
  bool compareShowDifferent = true;
  bool compareShowOnlyRight = true;
  bool compareShowIdentical = false;

  // ★ Directory Hotlist & macOS Favorites state
  final List<String> customFavorites = [];
  PaneSide favoritesTargetSide = PaneSide.left;
  int favoritesSelectedIndex = 0;

  String statusBanner =
      'Ready — Tab: switch pane | Space: select | ⌘B: Favorites | ⇧Enter / F4: Open With';
  bool filterBarVisible = false;

  static const double rowExtent = 24.0;

  CommanderController({
    required SessionData initialSession,
    required this.onUiFrameworkChanged,
  }) : _uiFramework = initialSession.uiFramework,
       _themeId = initialSession.themeId,
       showHidden = initialSession.showHidden {
    preferredAppsByExt.addAll(initialSession.preferredAppsByExt);
    customFavorites.addAll(initialSession.favoriteFolders);
    for (final path in initialSession.leftTabs) {
      leftTabs.add(_createTab(path));
    }
    for (final path in initialSession.rightTabs) {
      rightTabs.add(_createTab(path));
    }
    if (leftTabs.isEmpty) {
      leftTabs.add(_createTab(Platform.environment['HOME'] ?? '/'));
    }
    if (rightTabs.isEmpty) {
      rightTabs.add(_createTab(Platform.environment['HOME'] ?? '/'));
    }
    activeLeftTabIndex = initialSession.activeLeftTab.clamp(
      0,
      leftTabs.length - 1,
    );
    activeRightTabIndex = initialSession.activeRightTab.clamp(
      0,
      rightTabs.length - 1,
    );
  }

  UiFrameworkMode get uiFramework => _uiFramework;
  TcThemeId get themeId => _themeId;
  TcThemePalette get palette => TcThemePalette.of(_themeId);

  PaneTabController get leftTab => leftTabs[activeLeftTabIndex];
  PaneTabController get rightTab => rightTabs[activeRightTabIndex];

  PaneTabController get activeTab =>
      activeSide == PaneSide.left ? leftTab : rightTab;
  PaneTabController get inactiveTab =>
      activeSide == PaneSide.left ? rightTab : leftTab;

  List<PaneTabController> tabsFor(PaneSide side) =>
      side == PaneSide.left ? leftTabs : rightTabs;

  int activeTabIndexFor(PaneSide side) =>
      side == PaneSide.left ? activeLeftTabIndex : activeRightTabIndex;

  PaneTabController tabFor(PaneSide side) =>
      side == PaneSide.left ? leftTab : rightTab;

  PaneTabController _createTab(String path) {
    final id = _bridge.createPane(path);
    if (showHidden) {
      _bridge.setShowHidden(id, true);
    }
    final summary = _bridge.getSummary(id);
    return PaneTabController(rustPaneId: id, summary: summary);
  }

  void _refreshTab(PaneTabController tab, {bool clampCursor = true}) {
    tab.invalidateCache();
    tab.summary = _bridge.getSummary(tab.rustPaneId);
    if (clampCursor) {
      if (tab.summary.totalRows == 0) {
        tab.cursorIndex = 0;
      } else if (tab.cursorIndex >= tab.summary.totalRows) {
        tab.cursorIndex = tab.summary.totalRows - 1;
      }
    }
  }

  void persistSession() {
    SessionStore.save(
      SessionData(
        uiFramework: _uiFramework,
        themeId: _themeId,
        leftTabs: leftTabs.map((t) => t.summary.currentPath).toList(),
        activeLeftTab: activeLeftTabIndex,
        rightTabs: rightTabs.map((t) => t.summary.currentPath).toList(),
        activeRightTab: activeRightTabIndex,
        showHidden: showHidden,
        preferredAppsByExt: Map<String, String>.from(preferredAppsByExt),
        favoriteFolders: List<String>.from(customFavorites),
      ),
    );
  }

  void setTheme(TcThemeId newTheme) {
    if (_themeId == newTheme) return;
    _themeId = newTheme;
    persistSession();
    statusBanner = 'Switched color theme to ${newTheme.shortLabel}';
    notifyListeners();
  }

  void setUiFramework(UiFrameworkMode mode) {
    if (_uiFramework == mode) return;
    _uiFramework = mode;
    persistSession();
    statusBanner = 'Switched UI framework to ${mode.label}';
    onUiFrameworkChanged(mode);
    notifyListeners();
  }

  void setSplitRatio(double ratio) {
    splitRatio = ratio.clamp(0.2, 0.8);
    notifyListeners();
  }

  void setActiveSide(PaneSide side) {
    if (activeSide == side) return;
    activeSide = side;
    filterBarVisible = activeTab.summary.filterQuery.isNotEmpty;
    notifyListeners();
  }

  void toggleActiveSide() {
    setActiveSide(
      activeSide == PaneSide.left ? PaneSide.right : PaneSide.left,
    );
  }

  // --- Tab management ---
  void addNewTab({PaneSide? side, String? path}) {
    final targetSide = side ?? activeSide;
    final currentTab = tabFor(targetSide);
    final newTab = _createTab(path ?? currentTab.summary.currentPath);
    if (targetSide == PaneSide.left) {
      leftTabs.add(newTab);
      activeLeftTabIndex = leftTabs.length - 1;
    } else {
      rightTabs.add(newTab);
      activeRightTabIndex = rightTabs.length - 1;
    }
    persistSession();
    notifyListeners();
  }

  void closeTab(PaneSide side, int index) {
    final list = tabsFor(side);
    if (list.length <= 1) return;
    final removed = list.removeAt(index);
    removed.dispose(_bridge);
    if (side == PaneSide.left) {
      activeLeftTabIndex = activeLeftTabIndex.clamp(0, leftTabs.length - 1);
    } else {
      activeRightTabIndex = activeRightTabIndex.clamp(0, rightTabs.length - 1);
    }
    persistSession();
    notifyListeners();
  }

  void selectTab(PaneSide side, int index) {
    activeSide = side;
    if (side == PaneSide.left) {
      activeLeftTabIndex = index.clamp(0, leftTabs.length - 1);
    } else {
      activeRightTabIndex = index.clamp(0, rightTabs.length - 1);
    }
    filterBarVisible = activeTab.summary.filterQuery.isNotEmpty;
    persistSession();
    notifyListeners();
  }

  // --- Navigation & Cursor ---
  DirEntryModel? getRow(PaneTabController tab, int index) {
    return tab.getRow(_bridge, index);
  }

  DirEntryModel? get focusedEntry => getRow(activeTab, activeTab.cursorIndex);

  void setCursor(PaneSide side, int index, {bool ensureVisible = true}) {
    activeSide = side;
    final tab = tabFor(side);
    if (tab.summary.totalRows == 0) {
      tab.cursorIndex = 0;
    } else {
      tab.cursorIndex = index.clamp(0, tab.summary.totalRows - 1);
    }
    if (ensureVisible) {
      _scrollCursorIntoView(tab);
    }
    notifyListeners();
  }

  void moveCursorBy(int delta) {
    setCursor(activeSide, activeTab.cursorIndex + delta);
  }

  void moveCursorToStart() => setCursor(activeSide, 0);

  void moveCursorToEnd() =>
      setCursor(activeSide, activeTab.summary.totalRows - 1);

  void _scrollCursorIntoView(PaneTabController tab) {
    if (!tab.scrollController.hasClients) return;
    final pos = tab.scrollController.position;
    final itemTop = tab.cursorIndex * rowExtent;
    final itemBottom = itemTop + rowExtent;
    if (itemTop < pos.pixels) {
      tab.scrollController.jumpTo(itemTop);
    } else if (itemBottom > pos.pixels + pos.viewportDimension) {
      tab.scrollController.jumpTo(
        (itemBottom - pos.viewportDimension).clamp(0.0, pos.maxScrollExtent),
      );
    }
  }

  void navigateToPath(
    String path, {
    PaneSide? side,
    String? selectChildName,
  }) {
    final targetSide = side ?? activeSide;
    final tab = tabFor(targetSide);
    final prevPath = tab.summary.currentPath;

    // If stepping out of the root of a virtual archive via ".." or breadcrumb, return to the archive's parent folder
    if (tab.archiveMountDir != null &&
        tab.archiveFilePath != null &&
        !path.startsWith(tab.archiveMountDir!)) {
      final archiveParent = Directory(tab.archiveMountDir!).parent.path;
      final hostFile = File(tab.archiveFilePath!);
      final hostName = hostFile.uri.pathSegments.isNotEmpty
          ? hostFile.uri.pathSegments.last
          : null;
      final hostDir = hostFile.parent.path;
      tab.archiveFilePath = null;
      tab.archiveMountDir = null;
      if (path == archiveParent) {
        navigateToPath(
          hostDir,
          side: targetSide,
          selectChildName: hostName,
        );
        statusBanner = 'Exited archive → $hostDir';
        return;
      }
    }

    if (_bridge.loadDirectory(tab.rustPaneId, path)) {
      _refreshTab(tab, clampCursor: false);
      tab.cursorIndex = 0;
      final targetChild =
          selectChildName ??
          ((prevPath.startsWith(tab.summary.currentPath) &&
                  prevPath != tab.summary.currentPath)
              ? prevPath
                    .substring(tab.summary.currentPath.length)
                    .split('/')
                    .where((s) => s.isNotEmpty)
                    .firstOrNull
              : null);
      if (targetChild != null) {
        for (int i = 0; i < tab.summary.totalRows; i++) {
          final row = getRow(tab, i);
          if (row != null && row.name == targetChild) {
            tab.cursorIndex = i;
            break;
          }
        }
      }
      filterBarVisible = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollCursorIntoView(tab);
      });
      persistSession();
      statusBanner = tab.isInsideArchive
          ? '📦 Inside Archive: ${tab.displayPath}'
          : 'Opened ${tab.summary.currentPath}';
    } else {
      _refreshTab(tab);
      statusBanner = tab.summary.errorMessage ?? 'Cannot open $path';
    }
    notifyListeners();
  }

  void navigateUp() {
    final tab = activeTab;
    if (tab.isInsideArchive && tab.summary.currentPath == tab.archiveMountDir) {
      final hostFile = File(tab.archiveFilePath!);
      final hostDir = hostFile.parent.path;
      final hostName = hostFile.path.split('/').last;
      tab.archiveFilePath = null;
      tab.archiveMountDir = null;
      navigateToPath(hostDir, selectChildName: hostName);
      statusBanner = 'Exited archive $hostName';
      return;
    }
    final current = tab.summary.currentPath;
    final parent = Directory(current).parent.path;
    if (parent != current) {
      navigateToPath(parent);
    }
  }

  /// Enters inside a directory or macOS .app bundle (Show Package Contents, Cmd+Down)
  Future<void> enterDirectoryOrPackageContents({DirEntryModel? target}) async {
    closeContextMenu();
    final entry = target ?? focusedEntry;
    if (entry == null) return;
    if (entry.isParent) {
      navigateUp();
      return;
    }
    if (entry.isDir) {
      navigateToPath(entry.fullPath);
      return;
    }
    if (entry.isArchive) {
      await browseArchiveInPane(entry);
    }
  }

  /// Opens a .zip / .tar.gz archive directly inside the pane as a virtual folder (Total Commander VFS mode)
  Future<void> browseArchiveInPane(
    DirEntryModel entry, {
    PaneSide? side,
  }) async {
    closeContextMenu();
    final targetSide = side ?? activeSide;
    final tab = tabFor(targetSide);
    statusBanner = '📦 Opening archive ${entry.name}...';
    notifyListeners();

    final safeKey =
        '${entry.name.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_')}_${entry.modifiedSec}_${entry.size}';
    final vfsBase = Directory('${Directory.systemTemp.path}/ferropane_vfs');
    final stagingDir = Directory('${vfsBase.path}/$safeKey');

    bool ready = stagingDir.existsSync() && stagingDir.listSync().isNotEmpty;
    if (!ready) {
      if (stagingDir.existsSync()) {
        try {
          stagingDir.deleteSync(recursive: true);
        } catch (_) {}
      }
      ready = await NativeMacosBridge.extractArchiveToDirectory(
        entry.fullPath,
        stagingDir.path,
      );
    }

    if (!ready || !stagingDir.existsSync()) {
      statusBanner = 'Failed to open archive ${entry.name}';
      notifyListeners();
      return;
    }

    final resolvedMount = stagingDir.resolveSymbolicLinksSync();
    tab.archiveFilePath = entry.fullPath;
    tab.archiveMountDir = resolvedMount;
    navigateToPath(resolvedMount, side: targetSide);
    statusBanner =
        '📦 Browsing ${entry.name} — Press F3 to view, F5 to extract selected, Backspace to exit';
    notifyListeners();
  }

  /// Extracts an archive either into a subfolder in the current pane or into the opposite pane
  Future<void> extractArchive(
    DirEntryModel entry, {
    required bool toOtherPane,
  }) async {
    closeContextMenu();
    final baseDir = toOtherPane
        ? inactiveTab.summary.currentPath
        : activeTab.summary.currentPath;
    final destDir = '$baseDir/${entry.archiveBaseName}';
    statusBanner = '📦 Extracting ${entry.name} to $destDir...';
    notifyListeners();

    final ok = await NativeMacosBridge.extractArchiveToDirectory(
      entry.fullPath,
      destDir,
    );
    reloadBothPanes();
    statusBanner = ok
        ? '📦 Extracted ${entry.name} → $destDir'
        : 'Failed to extract ${entry.name}';
    notifyListeners();
  }

  /// Mounts a .dmg disk image and navigates the pane directly into the mounted `/Volumes/<Disk>`
  Future<void> mountAndOpenDiskImage(
    DirEntryModel entry, {
    PaneSide? side,
  }) async {
    closeContextMenu();
    final targetSide = side ?? activeSide;
    statusBanner = '💿 Mounting disk image ${entry.name}...';
    notifyListeners();

    final mountPoint = await NativeMacosBridge.mountDiskImage(entry.fullPath);
    if (mountPoint != null && Directory(mountPoint).existsSync()) {
      navigateToPath(mountPoint, side: targetSide);
      statusBanner = '💿 Mounted ${entry.name} → $mountPoint';
    } else {
      // Fallback to macOS DiskImageMounter
      await NativeMacosBridge.openFile(entry.fullPath);
      statusBanner = '💿 Opened ${entry.name} with DiskImageMounter';
    }
    notifyListeners();
  }

  /// Unmounts / ejects a mounted volume under /Volumes
  Future<void> ejectVolumePath(String volumePath) async {
    closeContextMenu();
    statusBanner = '⏏ Ejecting $volumePath...';
    notifyListeners();
    final ok = await NativeMacosBridge.ejectVolume(volumePath);
    if (ok) {
      if (leftTab.summary.currentPath.startsWith(volumePath)) {
        navigateToPath('/Volumes', side: PaneSide.left);
      }
      if (rightTab.summary.currentPath.startsWith(volumePath)) {
        navigateToPath('/Volumes', side: PaneSide.right);
      }
      reloadBothPanes();
      statusBanner = '⏏ Ejected $volumePath';
    } else {
      statusBanner = 'Could not eject $volumePath (volume may be busy)';
    }
    notifyListeners();
  }

  /// Smart Enter / Double-Click execution tailored to each file type
  Future<void> activateFocusedEntry() async {
    final entry = focusedEntry;
    if (entry == null) return;

    // 0. Parent directory ("..") -> step up (or exit virtual archive)
    if (entry.isParent) {
      navigateUp();
      return;
    }

    // 1. macOS .app Application Bundle -> launch the app natively! (Use ⌘↓ for Package Contents)
    if (entry.isAppBundle) {
      statusBanner =
          '🚀 Launching ${entry.name}... (Tip: Press ⌘↓ to browse Package Contents)';
      notifyListeners();
      await NativeMacosBridge.openFile(entry.fullPath);
      return;
    }

    // 2. Regular Directory -> navigate inside
    if (entry.isDir) {
      navigateToPath(entry.fullPath);
      return;
    }

    // 3. Archive (.zip, .tar.gz, .tgz, .tar, .tar.bz2, .tar.xz) -> browse inside pane!
    if (entry.isArchive) {
      await browseArchiveInPane(entry);
      return;
    }

    // 4. Disk Image (.dmg) -> auto-mount via hdiutil & open /Volumes/<Disk> in active pane!
    if (entry.isDiskImage) {
      await mountAndOpenDiskImage(entry);
      return;
    }

    // 5. User-remembered preferred app for this file extension (if configured)
    final extKey = entry.ext.toLowerCase();
    final rememberedApp = preferredAppsByExt[extKey];
    if (rememberedApp != null &&
        rememberedApp.isNotEmpty &&
        Directory(rememberedApp).existsSync()) {
      final appName = rememberedApp.split('/').last.replaceAll('.app', '');
      statusBanner = 'Opened ${entry.name} with $appName';
      notifyListeners();
      await NativeMacosBridge.openFileWithApp(entry.fullPath, rememberedApp);
      return;
    }

    // 6. Executable Script (.sh, .zsh, .command) or Unix +x binary -> execute in Terminal.app
    if (entry.isExecutableScript) {
      statusBanner =
          '⚡ Executing ${entry.name} in Terminal... (Press F4 to edit, F3 to view)';
      notifyListeners();
      final ran = await NativeMacosBridge.runExecutableInTerminal(
        entry.fullPath,
      );
      if (ran) return;
    }

    // 7. Documents, Media, Code, PDFs -> open with default macOS app, or fallback to F3 Lister
    statusBanner = 'Opening ${entry.name}...';
    notifyListeners();
    final ok = await NativeMacosBridge.openFile(entry.fullPath);
    if (!ok) {
      openLister();
    }
  }

  void syncOtherPaneToActive() {
    navigateToPath(
      activeTab.summary.currentPath,
      side: activeSide == PaneSide.left ? PaneSide.right : PaneSide.left,
    );
  }

  void reloadBothPanes() {
    _bridge.reloadPane(leftTab.rustPaneId);
    _bridge.reloadPane(rightTab.rustPaneId);
    _refreshTab(leftTab);
    _refreshTab(rightTab);
    notifyListeners();
  }

  // --- Sorting, Hidden Files, Quick Filter ---
  void toggleSort(PaneSide side, SortField field) {
    activeSide = side;
    final tab = tabFor(side);
    final asc = (tab.summary.sortField == field)
        ? !tab.summary.sortAscending
        : (field == SortField.name || field == SortField.extension);
    _bridge.setSort(tab.rustPaneId, field, asc);
    _refreshTab(tab);
    notifyListeners();
  }

  void toggleHiddenFiles() {
    showHidden = !showHidden;
    for (final t in [...leftTabs, ...rightTabs]) {
      _bridge.setShowHidden(t.rustPaneId, showHidden);
      _refreshTab(t);
    }
    persistSession();
    statusBanner = showHidden ? 'Showing hidden dotfiles' : 'Hiding dotfiles';
    notifyListeners();
  }

  void setQuickFilter(String query) {
    final tab = activeTab;
    _bridge.setFilter(tab.rustPaneId, query);
    _refreshTab(tab);
    filterBarVisible = query.isNotEmpty || filterBarVisible;
    notifyListeners();
  }

  void toggleQuickFilterBar() {
    filterBarVisible = !filterBarVisible;
    if (!filterBarVisible && activeTab.summary.filterQuery.isNotEmpty) {
      setQuickFilter('');
    }
    notifyListeners();
  }

  // --- Selection (Insert, Space, *, +) ---
  void toggleSelectionAtCursor({
    required bool advanceCursor,
    required bool calculateDirSize,
  }) {
    final tab = activeTab;
    if (tab.summary.totalRows == 0) return;
    _bridge.toggleSelect(
      tab.rustPaneId,
      tab.cursorIndex,
      calcDirSize: calculateDirSize,
    );
    if (advanceCursor && tab.cursorIndex < tab.summary.totalRows - 1) {
      tab.cursorIndex += 1;
    }
    _refreshTab(tab);
    _scrollCursorIntoView(tab);
    notifyListeners();
  }

  void selectAll(bool select) {
    _bridge.selectAll(activeTab.rustPaneId, select);
    _refreshTab(activeTab);
    notifyListeners();
  }

  void invertSelection() {
    _bridge.invertSelection(activeTab.rustPaneId);
    _refreshTab(activeTab);
    notifyListeners();
  }

  void selectByPattern(String pattern, bool select) {
    _bridge.selectByPattern(activeTab.rustPaneId, pattern, select);
    _refreshTab(activeTab);
    activeDialog = ActiveDialog.none;
    notifyListeners();
  }

  List<String> getActionTargetPaths() {
    final selected = _bridge.getSelectedPaths(activeTab.rustPaneId);
    if (selected.isNotEmpty) return selected;
    final entry = focusedEntry;
    if (entry != null && !entry.isParent) {
      return [entry.fullPath];
    }
    return const [];
  }

  void _openDialogWithText(ActiveDialog dialog, String initialText) {
    activeDialog = dialog;
    dialogTextController.text = initialText;
    dialogTextController.selection = TextSelection(
      baseOffset: 0,
      extentOffset: initialText.length,
    );
    notifyListeners();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (activeDialog != ActiveDialog.none &&
          activeDialog != ActiveDialog.deleteConfirm &&
          activeDialog != ActiveDialog.lister) {
        dialogInputFocusNode.requestFocus();
      }
    });
  }

  /// Confirms whichever modal dialog is currently active when the user presses Enter or clicks the primary button.
  void confirmActiveDialog() {
    final input = dialogTextController.text.trim();
    switch (activeDialog) {
      case ActiveDialog.copyConfirm:
        executeCopy(input);
        break;
      case ActiveDialog.moveConfirm:
        executeMove(input);
        break;
      case ActiveDialog.mkdirPrompt:
        executeMkdir(input);
        break;
      case ActiveDialog.deleteConfirm:
        executeDelete();
        break;
      case ActiveDialog.selectPattern:
        selectByPattern(input, true);
        break;
      case ActiveDialog.gotoPath:
        closeDialog();
        if (input.isNotEmpty) {
          navigateToPath(input);
        }
        break;
      case ActiveDialog.lister:
        closeDialog();
        break;
      case ActiveDialog.openWithPalette:
        launchSelectedOpenWithApp();
        break;
      case ActiveDialog.favoritesHotlist:
        launchSelectedFavorite();
        break;
      case ActiveDialog.deepCompare:
        closeDialog();
        break;
      case ActiveDialog.none:
        break;
    }
  }

  // --- ★ Directory Hotlist & macOS Favorites (⌘B / Ctrl+D) ---
  bool isPathPinned(String path) {
    return customFavorites.contains(path);
  }

  List<FavoriteFolderItem> get favoriteHotlistItems {
    final items = <FavoriteFolderItem>[];
    final seenPaths = <String>{};

    void addIfValid(
      String label,
      String path,
      String category, {
      bool isCustom = false,
    }) {
      if (path.isEmpty || seenPaths.contains(path)) return;
      try {
        if (Directory(path).existsSync()) {
          seenPaths.add(path);
          items.add(
            FavoriteFolderItem(
              label: label,
              path: path,
              category: category,
              isCustomPinned: isCustom,
            ),
          );
        }
      } catch (_) {}
    }

    // 1. User-Pinned Custom Favorites
    for (final pinnedPath in customFavorites) {
      final segs = pinnedPath.split('/').where((s) => s.isNotEmpty).toList();
      final name = segs.isEmpty
          ? '/'
          : (segs.length >= 2
                ? '${segs[segs.length - 2]}/${segs.last}'
                : segs.last);
      addIfValid(name, pinnedPath, 'Pinned Folders', isCustom: true);
    }

    // 2. Standard macOS Finder Favorites
    final home = Platform.environment['HOME'] ?? '/Users';
    addIfValid('Home (~)', home, 'macOS Favorites');
    addIfValid('Desktop', '$home/Desktop', 'macOS Favorites');
    addIfValid('Documents', '$home/Documents', 'macOS Favorites');
    addIfValid('Downloads', '$home/Downloads', 'macOS Favorites');
    addIfValid('Applications', '/Applications', 'macOS Favorites');
    addIfValid('Developer (~/dev)', '$home/dev', 'macOS Favorites');
    addIfValid(
      'iCloud Drive',
      '$home/Library/Mobile Documents/com~apple~CloudDocs',
      'macOS Favorites',
    );

    // 3. Mounted Volumes (/ and /Volumes/*)
    addIfValid('Macintosh HD (/)', '/', 'Volumes & Drives');
    try {
      final volDir = Directory('/Volumes');
      if (volDir.existsSync()) {
        for (final entity in volDir.listSync(followLinks: false)) {
          final name = entity.path.split('/').last;
          if (name.isEmpty || name.startsWith('.') || name == 'Macintosh HD') {
            continue;
          }
          addIfValid(name, entity.path, 'Volumes & Drives');
        }
      }
    } catch (_) {}

    return items;
  }

  void openFavoritesHotlist({PaneSide? side}) {
    closeContextMenu();
    if (side != null) {
      activeSide = side;
    }
    favoritesTargetSide = side ?? activeSide;
    final items = favoriteHotlistItems;
    final currentPath = tabFor(favoritesTargetSide).summary.currentPath;
    final matchIdx = items.indexWhere((f) => f.path == currentPath);
    favoritesSelectedIndex = matchIdx >= 0 ? matchIdx : 0;
    activeDialog = ActiveDialog.favoritesHotlist;
    notifyListeners();
  }

  void toggleFavoritesTargetSide() {
    favoritesTargetSide = favoritesTargetSide == PaneSide.left
        ? PaneSide.right
        : PaneSide.left;
    notifyListeners();
  }

  void togglePinFolder(String path) {
    if (path.isEmpty) return;
    if (customFavorites.contains(path)) {
      customFavorites.remove(path);
      statusBanner = 'Unpinned $path from Favorites';
    } else {
      customFavorites.insert(0, path);
      statusBanner = '★ Pinned $path to Favorites';
    }
    persistSession();
    final items = favoriteHotlistItems;
    if (items.isEmpty) {
      favoritesSelectedIndex = 0;
    } else {
      favoritesSelectedIndex = favoritesSelectedIndex.clamp(
        0,
        items.length - 1,
      );
    }
    notifyListeners();
  }

  void togglePinCurrentFolder({PaneSide? side}) {
    final target = side ??
        (activeDialog == ActiveDialog.favoritesHotlist
            ? favoritesTargetSide
            : activeSide);
    final path = tabFor(target).summary.currentPath;
    togglePinFolder(path);
  }

  void moveFavoritesSelection(int delta) {
    final items = favoriteHotlistItems;
    if (items.isEmpty) return;
    favoritesSelectedIndex = (favoritesSelectedIndex + delta).clamp(
      0,
      items.length - 1,
    );
    notifyListeners();
  }

  void launchFavoriteAtIndex(
    int index, {
    bool inNewTab = false,
    bool inOtherPane = false,
  }) {
    final items = favoriteHotlistItems;
    if (index < 0 || index >= items.length) return;
    favoritesSelectedIndex = index;
    launchSelectedFavorite(inNewTab: inNewTab, inOtherPane: inOtherPane);
  }

  void launchSelectedFavorite({
    bool inNewTab = false,
    bool inOtherPane = false,
  }) {
    final items = favoriteHotlistItems;
    if (items.isEmpty) {
      closeDialog();
      return;
    }
    final idx = favoritesSelectedIndex.clamp(0, items.length - 1);
    final chosen = items[idx];
    final targetSide = inOtherPane
        ? (favoritesTargetSide == PaneSide.left
              ? PaneSide.right
              : PaneSide.left)
        : favoritesTargetSide;

    activeDialog = ActiveDialog.none;
    closeContextMenu();
    activeSide = targetSide;

    if (inNewTab) {
      addNewTab(side: targetSide, path: chosen.path);
      statusBanner = 'Opened ★ ${chosen.label} in new tab (${chosen.path})';
    } else {
      navigateToPath(chosen.path, side: targetSide);
      statusBanner = 'Opened ★ ${chosen.label} (${chosen.path})';
    }
    notifyListeners();
  }

  // --- Deep Compare Folders (Synchronize Dirs) ---
  void openDeepCompare({bool? byContent}) {
    closeContextMenu();
    if (byContent != null) {
      deepCompareByContent = byContent;
    }
    compareResult = _bridge.compareDirectories(
      leftTab.summary.currentPath,
      rightTab.summary.currentPath,
      compareContent: deepCompareByContent,
      showHidden: showHidden,
    );
    activeDialog = ActiveDialog.deepCompare;
    final res = compareResult!;
    statusBanner =
        'Deep Compare: ${res.onlyLeftCount} only left, ${res.differentCount} diff, ${res.onlyRightCount} only right, ${res.identicalCount} identical';
    notifyListeners();
  }

  void toggleCompareFilter({
    bool? onlyLeft,
    bool? different,
    bool? onlyRight,
    bool? identical,
  }) {
    if (onlyLeft != null) compareShowOnlyLeft = onlyLeft;
    if (different != null) compareShowDifferent = different;
    if (onlyRight != null) compareShowOnlyRight = onlyRight;
    if (identical != null) compareShowIdentical = identical;
    notifyListeners();
  }

  List<CompareEntryModel> get filteredCompareItems {
    final res = compareResult;
    if (res == null) return const [];
    return res.items.where((item) {
      switch (item.status) {
        case 'only_left':
          return compareShowOnlyLeft;
        case 'different':
          return compareShowDifferent;
        case 'only_right':
          return compareShowOnlyRight;
        case 'identical':
          return compareShowIdentical;
        default:
          return true;
      }
    }).toList(growable: false);
  }

  void syncCompareSingleItem(CompareEntryModel item, {required bool leftToRight}) {
    final res = compareResult;
    if (res == null) return;
    final srcRoot = leftToRight ? res.leftRoot : res.rightRoot;
    final dstRoot = leftToRight ? res.rightRoot : res.leftRoot;
    final srcFull = '$srcRoot/${item.relPath}';
    final dstFull = '$dstRoot/${item.relPath}';
    final dstParent = File(dstFull).parent.path;
    _bridge.copyItems([srcFull], dstParent);
    reloadBothPanes();
    openDeepCompare();
  }

  void syncAllCompare({required bool leftToRight}) {
    final res = compareResult;
    if (res == null) return;
    final srcRoot = leftToRight ? res.leftRoot : res.rightRoot;
    final dstRoot = leftToRight ? res.rightRoot : res.leftRoot;
    int synced = 0;

    for (final item in filteredCompareItems) {
      if (item.isDir) continue;
      final shouldCopy = leftToRight
          ? (item.status == 'only_left' ||
                (item.status == 'different' && item.newerSide != 'right'))
          : (item.status == 'only_right' ||
                (item.status == 'different' && item.newerSide != 'left'));
      if (!shouldCopy) continue;
      final srcFull = '$srcRoot/${item.relPath}';
      final dstFull = '$dstRoot/${item.relPath}';
      final dstParent = File(dstFull).parent.path;
      final op = _bridge.copyItems([srcFull], dstParent);
      if (op.ok) synced++;
    }

    reloadBothPanes();
    openDeepCompare();
    statusBanner = leftToRight
        ? 'Synced $synced file(s) from Left → Right'
        : 'Synced $synced file(s) from Right ← Left';
    notifyListeners();
  }

  // --- "Open With..." Palette, Smart F4, and Right-Click Context Menu ---
  Future<void> _loadOpenWithAppsFor(DirEntryModel entry) async {
    final apps = await NativeMacosBridge.getOpenWithApps(entry.fullPath);
    final extKey = entry.ext.toLowerCase();
    final rememberedPath = preferredAppsByExt[extKey];
    if (rememberedPath != null && rememberedPath.isNotEmpty) {
      final list = <OpenWithAppInfo>[];
      for (final a in apps) {
        if (a.path == rememberedPath) {
          list.insert(0, a.copyWith(isRemembered: true));
        } else {
          list.add(a);
        }
      }
      if (list.every((a) => a.path != rememberedPath) &&
          Directory(rememberedPath).existsSync()) {
        final name = rememberedPath.split('/').last.replaceAll('.app', '');
        list.insert(
          0,
          OpenWithAppInfo(
            name: name,
            path: rememberedPath,
            isRemembered: true,
          ),
        );
      }
      openWithApps = list;
    } else {
      openWithApps = apps;
    }
  }

  Future<void> openOpenWithPalette({DirEntryModel? target}) async {
    closeContextMenu();
    final entry = target ?? focusedEntry;
    if (entry == null || entry.isParent) return;
    openWithTargetEntry = entry;
    openWithSelectedIndex = 0;
    openWithRememberForExt = false;
    if (openWithApps.isEmpty) {
      openWithApps = const [
        OpenWithAppInfo(
          name: 'TextEdit',
          path: '/System/Applications/TextEdit.app',
          isDefault: true,
        ),
      ];
    }
    activeDialog = ActiveDialog.openWithPalette;
    notifyListeners();
    await _loadOpenWithAppsFor(entry);
    notifyListeners();
  }

  Future<void> triggerSmartF4({bool forcePicker = false}) async {
    final entry = focusedEntry;
    if (entry == null || entry.isParent) return;
    if (entry.isDir) {
      await openOpenWithPalette(target: entry);
      return;
    }
    final extKey = entry.ext.toLowerCase();
    final rememberedApp = preferredAppsByExt[extKey];
    if (!forcePicker &&
        rememberedApp != null &&
        rememberedApp.isNotEmpty &&
        Directory(rememberedApp).existsSync()) {
      final appName = rememberedApp.split('/').last.replaceAll('.app', '');
      statusBanner = 'Opening ${entry.name} with $appName...';
      notifyListeners();
      await NativeMacosBridge.openFileWithApp(entry.fullPath, rememberedApp);
      return;
    }
    await openOpenWithPalette(target: entry);
  }

  void moveOpenWithSelection(int delta) {
    if (openWithApps.isEmpty) return;
    openWithSelectedIndex = (openWithSelectedIndex + delta).clamp(
      0,
      openWithApps.length - 1,
    );
    notifyListeners();
  }

  void toggleOpenWithRemember() {
    openWithRememberForExt = !openWithRememberForExt;
    notifyListeners();
  }

  Future<void> launchOpenWithIndex(int index) async {
    if (index < 0 || index >= openWithApps.length) return;
    openWithSelectedIndex = index;
    await launchSelectedOpenWithApp();
  }

  Future<void> launchSelectedOpenWithApp() async {
    final entry = openWithTargetEntry ?? focusedEntry;
    if (entry == null || openWithApps.isEmpty) {
      closeDialog();
      return;
    }
    final idx = openWithSelectedIndex.clamp(0, openWithApps.length - 1);
    final chosen = openWithApps[idx];
    final extKey = entry.ext.toLowerCase();
    if (openWithRememberForExt && extKey.isNotEmpty) {
      preferredAppsByExt[extKey] = chosen.path;
      persistSession();
    }
    activeDialog = ActiveDialog.none;
    closeContextMenu();
    statusBanner = 'Opened ${entry.name} with ${chosen.name}';
    notifyListeners();
    await NativeMacosBridge.openFileWithApp(entry.fullPath, chosen.path);
  }

  Future<void> browseOtherAppForOpenWith() async {
    final entry = openWithTargetEntry ?? contextMenuEntry ?? focusedEntry;
    if (entry == null) return;
    final remember = openWithRememberForExt;
    activeDialog = ActiveDialog.none;
    closeContextMenu();
    notifyListeners();
    final chosenPath = await NativeMacosBridge.pickOtherAppAndOpen(
      entry.fullPath,
    );
    if (chosenPath != null && chosenPath.isNotEmpty) {
      final appName = chosenPath.split('/').last.replaceAll('.app', '');
      if (remember && entry.ext.isNotEmpty) {
        preferredAppsByExt[entry.ext.toLowerCase()] = chosenPath;
        persistSession();
      }
      statusBanner = 'Opened ${entry.name} with $appName';
      notifyListeners();
    }
  }

  Future<void> showRowContextMenu(
    PaneSide side,
    int rowIndex,
    Offset globalPosition,
  ) async {
    setCursor(side, rowIndex, ensureVisible: false);
    final entry = focusedEntry;
    if (entry == null || entry.isParent) return;
    openWithTargetEntry = entry;
    contextMenuEntry = entry;
    contextMenuPosition = globalPosition;
    await _loadOpenWithAppsFor(entry);
    notifyListeners();
  }

  void closeContextMenu() {
    if (contextMenuPosition != null || contextMenuEntry != null) {
      contextMenuPosition = null;
      contextMenuEntry = null;
      notifyListeners();
    }
  }

  Future<void> copyPathToClipboard(String path) async {
    closeContextMenu();
    await Clipboard.setData(ClipboardData(text: path));
    statusBanner = 'Copied path to clipboard: $path';
    notifyListeners();
  }

  // --- F3 Lister, QuickLook, F4 Edit, F5 Copy, F6 Move, F7 Mkdir, F8 Delete ---
  void openLister() {
    final entry = focusedEntry;
    if (entry == null || entry.isParent) return;
    if (entry.isDir) {
      toggleSelectionAtCursor(advanceCursor: false, calculateDirSize: true);
      return;
    }
    listerOffset = 0;
    listerHexMode = false;
    listerSlice = _bridge.readListerSlice(
      entry.fullPath,
      offset: 0,
      maxBytes: 24576,
      hexMode: false,
    );
    activeDialog = ActiveDialog.lister;
    notifyListeners();
  }

  void setListerMode({required bool hex}) {
    final current = listerSlice;
    if (current == null) return;
    listerHexMode = hex;
    listerSlice = _bridge.readListerSlice(
      current.filePath,
      offset: listerOffset,
      maxBytes: 24576,
      hexMode: listerHexMode,
    );
    notifyListeners();
  }

  void pageLister(int byteDelta) {
    final current = listerSlice;
    if (current == null) return;
    final maxStart = (current.fileSize - 1024).clamp(0, current.fileSize);
    listerOffset = (listerOffset + byteDelta).clamp(0, maxStart);
    listerSlice = _bridge.readListerSlice(
      current.filePath,
      offset: listerOffset,
      maxBytes: 24576,
      hexMode: listerHexMode,
    );
    notifyListeners();
  }

  Future<void> triggerQuickLook() async {
    final entry = focusedEntry;
    if (entry == null || entry.isParent) return;
    await NativeMacosBridge.toggleQuickLook(entry.fullPath);
  }

  Future<void> revealFocusedInFinder() async {
    final entry = focusedEntry;
    final path = (entry == null || entry.isParent)
        ? activeTab.summary.currentPath
        : entry.fullPath;
    await NativeMacosBridge.revealInFinder(path);
  }

  Future<void> openTerminalInActivePane() async {
    await NativeMacosBridge.openTerminal(activeTab.summary.currentPath);
  }

  void openCopyDialog() {
    if (getActionTargetPaths().isEmpty) return;
    _openDialogWithText(
      ActiveDialog.copyConfirm,
      inactiveTab.summary.currentPath,
    );
  }

  void executeCopy(String destinationDir) {
    final targets = getActionTargetPaths();
    activeDialog = ActiveDialog.none;
    if (targets.isEmpty) return;
    final res = _bridge.copyItems(targets, destinationDir);
    statusBanner = res.message;
    reloadBothPanes();
  }

  void openMoveDialog() {
    if (getActionTargetPaths().isEmpty) return;
    _openDialogWithText(
      ActiveDialog.moveConfirm,
      inactiveTab.summary.currentPath,
    );
  }

  void executeMove(String destinationDir) {
    final targets = getActionTargetPaths();
    activeDialog = ActiveDialog.none;
    if (targets.isEmpty) return;
    final res = _bridge.moveItems(targets, destinationDir);
    statusBanner = res.message;
    reloadBothPanes();
  }

  void openMkdirDialog() {
    _openDialogWithText(ActiveDialog.mkdirPrompt, 'NewFolder');
  }

  void executeMkdir(String folderName) {
    activeDialog = ActiveDialog.none;
    final res = _bridge.createDirectory(
      activeTab.summary.currentPath,
      folderName,
    );
    statusBanner = res.message;
    reloadBothPanes();
  }

  void openDeleteDialog({bool useTrash = true}) {
    if (getActionTargetPaths().isEmpty) return;
    deleteUseTrash = useTrash;
    _openDialogWithText(ActiveDialog.deleteConfirm, '');
  }

  void executeDelete() {
    final targets = getActionTargetPaths();
    final trash = deleteUseTrash;
    activeDialog = ActiveDialog.none;
    if (targets.isEmpty) return;
    final res = _bridge.deleteItems(targets, useTrash: trash);
    statusBanner = res.message;
    reloadBothPanes();
  }

  void openSelectPatternDialog() {
    _openDialogWithText(ActiveDialog.selectPattern, '*.*');
  }

  void openGotoPathDialog() {
    _openDialogWithText(ActiveDialog.gotoPath, activeTab.summary.currentPath);
  }

  void closeDialog() {
    activeDialog = ActiveDialog.none;
    notifyListeners();
  }
}
