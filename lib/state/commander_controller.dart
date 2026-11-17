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

  int _cachedStart = -1;
  int _cachedCount = 0;
  List<DirEntryModel> _cachedSlice = const [];

  PaneTabController({required this.rustPaneId, required this.summary});

  String get title {
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

  String statusBanner =
      'Ready — Tab: switch pane | Space: select | ⇧Enter / F4: Open With';
  bool filterBarVisible = false;

  static const double rowExtent = 24.0;

  CommanderController({
    required SessionData initialSession,
    required this.onUiFrameworkChanged,
  }) : _uiFramework = initialSession.uiFramework,
       _themeId = initialSession.themeId,
       showHidden = initialSession.showHidden {
    preferredAppsByExt.addAll(initialSession.preferredAppsByExt);
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

  void navigateToPath(String path, {PaneSide? side}) {
    final targetSide = side ?? activeSide;
    final tab = tabFor(targetSide);
    final prevPath = tab.summary.currentPath;
    if (_bridge.loadDirectory(tab.rustPaneId, path)) {
      _refreshTab(tab, clampCursor: false);
      tab.cursorIndex = 0;
      if (prevPath.startsWith(tab.summary.currentPath) &&
          prevPath != tab.summary.currentPath) {
        final childName = prevPath
            .substring(tab.summary.currentPath.length)
            .split('/')
            .where((s) => s.isNotEmpty)
            .firstOrNull;
        if (childName != null) {
          for (int i = 0; i < tab.summary.totalRows; i++) {
            final row = getRow(tab, i);
            if (row != null && row.name == childName) {
              tab.cursorIndex = i;
              break;
            }
          }
        }
      }
      filterBarVisible = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollCursorIntoView(tab);
      });
      persistSession();
      statusBanner = 'Opened ${tab.summary.currentPath}';
    } else {
      _refreshTab(tab);
      statusBanner = tab.summary.errorMessage ?? 'Cannot open $path';
    }
    notifyListeners();
  }

  void navigateUp() {
    final current = activeTab.summary.currentPath;
    final parent = Directory(current).parent.path;
    if (parent != current) {
      navigateToPath(parent);
    }
  }

  Future<void> activateFocusedEntry() async {
    final entry = focusedEntry;
    if (entry == null) return;
    if (entry.isParent || entry.isDir) {
      navigateToPath(entry.fullPath);
    } else {
      statusBanner = 'Opening ${entry.name}...';
      notifyListeners();
      final ok = await NativeMacosBridge.openFile(entry.fullPath);
      if (!ok) {
        openLister();
      }
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
      case ActiveDialog.none:
        break;
    }
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
