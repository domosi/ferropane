import 'dart:io';
import 'package:flutter/cupertino.dart';
import '../../core/models.dart';
import '../../core/theme_palette.dart';
import '../../state/commander_controller.dart';
import '../../state/keyboard_handler.dart';
import '../common/open_with_overlays.dart';
import '../common/toolbar_dropdown.dart';
import 'macos_dialogs.dart';
import 'macos_pane_view.dart';

class MacosCommanderShell extends StatelessWidget {
  final CommanderController controller;

  const MacosCommanderShell({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final p = controller.palette;
    return CommanderKeyboardScope(
      controller: controller,
      child: CupertinoPageScaffold(
        backgroundColor: p.windowBg,
        child: ListenableBuilder(
          listenable: controller,
          builder: (context, _) {
            final pal = controller.palette;
            return Stack(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildTopToolbar(pal),
                    Expanded(child: _buildDualPanes(pal)),
                    _buildActivePathPromptBar(pal),
                    _buildFunctionKeyBar(pal),
                    _buildStatusBar(pal),
                  ],
                ),
                FileRowContextMenuOverlay(controller: controller),
                MacosDialogOverlay(controller: controller),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildTopToolbar(TcThemePalette p) {
    Widget toolBtn({
      required IconData icon,
      required String label,
      required VoidCallback onPressed,
      bool active = false,
    }) {
      return Padding(
        padding: const EdgeInsets.only(right: 5),
        child: CupertinoButton(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
          minimumSize: const Size(0, 25),
          color: active ? p.primaryAccent : p.headerBg,
          borderRadius: BorderRadius.circular(6),
          onPressed: onPressed,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 12.5,
                color: active
                    ? p.cursorActiveText
                    : p.primaryAccent,
              ),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  color: active ? p.cursorActiveText : p.fileImportantText,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: p.toolbarBg,
        border: Border(bottom: BorderSide(color: p.dividerColor, width: 1)),
      ),
      child: Row(
        children: [
          Icon(
            CupertinoIcons.square_split_2x1_fill,
            size: 16,
            color: p.primaryAccent,
          ),
          const SizedBox(width: 7),
          Text(
            'FerroPane',
            style: TextStyle(
              color: p.fileImportantText,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  toolBtn(
                    icon: CupertinoIcons.house_fill,
                    label: 'Home',
                    onPressed: () => controller.navigateToPath(
                      Platform.environment['HOME'] ?? '/Users',
                    ),
                  ),
                  toolBtn(
                    icon: CupertinoIcons.eye_fill,
                    label: 'Dotfiles',
                    active: controller.showHidden,
                    onPressed: controller.toggleHiddenFiles,
                  ),
                  toolBtn(
                    icon: CupertinoIcons.search,
                    label: 'Filter',
                    active: controller.filterBarVisible,
                    onPressed: controller.toggleQuickFilterBar,
                  ),
                  toolBtn(
                    icon: CupertinoIcons.arrow_right_arrow_left,
                    label: 'Sync (=)',
                    onPressed: controller.syncOtherPaneToActive,
                  ),
                  toolBtn(
                    icon: CupertinoIcons.doc_on_doc_fill,
                    label: 'Compare',
                    active: controller.activeDialog == ActiveDialog.deepCompare,
                    onPressed: () => controller.openDeepCompare(),
                  ),
                  toolBtn(
                    icon: CupertinoIcons.eye,
                    label: 'QuickLook',
                    onPressed: controller.triggerQuickLook,
                  ),
                  toolBtn(
                    icon: CupertinoIcons.folder_open,
                    label: 'Finder',
                    onPressed: controller.revealFocusedInFinder,
                  ),
                  toolBtn(
                    icon: CupertinoIcons.chevron_right_2,
                    label: 'Terminal',
                    onPressed: controller.openTerminalInActivePane,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          _buildThemeAndUiDropdowns(p),
        ],
      ),
    );
  }

  Widget _buildThemeAndUiDropdowns(TcThemePalette p) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ToolbarDropdownPicker<TcThemeId>(
          prefixLabel: 'Theme',
          selectedValue: controller.themeId,
          palette: p,
          menuWidth: 185,
          items: [
            for (final t in TcThemeId.values)
              ToolbarDropdownItem<TcThemeId>(
                value: t,
                label: t.shortLabel,
                swatchColor: t.swatch,
              ),
          ],
          onChanged: controller.setTheme,
        ),
        const SizedBox(width: 6),
        ToolbarDropdownPicker<UiFrameworkMode>(
          prefixLabel: 'UI',
          selectedValue: controller.uiFramework,
          palette: p,
          menuWidth: 185,
          items: const [
            ToolbarDropdownItem(
              value: UiFrameworkMode.macos,
              label: 'macOS UI',
              subtitle: 'Cupertino / AppKit style',
              icon: CupertinoIcons.desktopcomputer,
            ),
            ToolbarDropdownItem(
              value: UiFrameworkMode.material3,
              label: 'Material 3',
              subtitle: 'Google M3 surfaces & chips',
              icon: CupertinoIcons.layers_alt_fill,
            ),
          ],
          onChanged: controller.setUiFramework,
        ),
      ],
    );
  }

  Widget _buildDualPanes(TcThemePalette p) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;
        const dividerWidth = 6.0;
        final usableWidth = (totalWidth - dividerWidth).clamp(200.0, 10000.0);
        final leftWidth = usableWidth * controller.splitRatio;
        final rightWidth = usableWidth - leftWidth;

        return Row(
          children: [
            SizedBox(
              width: leftWidth,
              child: MacosPaneView(
                controller: controller,
                side: PaneSide.left,
              ),
            ),
            MouseRegion(
              cursor: SystemMouseCursors.resizeColumn,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onHorizontalDragUpdate: (details) {
                  final delta = details.delta.dx / usableWidth;
                  controller.setSplitRatio(controller.splitRatio + delta);
                },
                onDoubleTap: () => controller.setSplitRatio(0.5),
                child: Container(
                  width: dividerWidth,
                  color: p.toolbarBg,
                  alignment: Alignment.center,
                  child: Container(
                    width: 2,
                    height: 36,
                    color: p.primaryAccent.withValues(alpha: 0.6),
                  ),
                ),
              ),
            ),
            SizedBox(
              width: rightWidth,
              child: MacosPaneView(
                controller: controller,
                side: PaneSide.right,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildActivePathPromptBar(TcThemePalette p) {
    final activePath = controller.activeTab.summary.currentPath;
    final focusedName = controller.focusedEntry?.name ?? '';
    return GestureDetector(
      onTap: controller.openGotoPathDialog,
      child: Container(
        height: 25,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: p.headerBg,
          border: Border(top: BorderSide(color: p.dividerColor, width: 1)),
        ),
        child: Row(
          children: [
            Text(
              '$activePath >',
              style: TextStyle(
                color: p.primaryAccent,
                fontSize: 11.5,
                fontFamily: 'Menlo',
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                focusedName.isNotEmpty && focusedName != '..'
                    ? focusedName
                    : '(Click or press ⌘G to jump to any path)',
                style: TextStyle(
                  color: focusedName.isNotEmpty && focusedName != '..'
                      ? p.fileImportantText
                      : p.mutedText,
                  fontSize: 11.5,
                  fontFamily: 'Menlo',
                  fontWeight: focusedName.isNotEmpty && focusedName != '..'
                      ? FontWeight.w600
                      : FontWeight.w400,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFunctionKeyBar(TcThemePalette p) {
    Widget fKeyBtn(String keyNum, String label, VoidCallback onTap) {
      return Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 3),
          child: CupertinoButton(
            padding: EdgeInsets.zero,
            minimumSize: const Size(0, 26),
            color: p.headerBg,
            borderRadius: BorderRadius.circular(4),
            onPressed: onTap,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: p.primaryAccent.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Text(
                    keyNum,
                    style: TextStyle(
                      color: p.primaryAccent,
                      fontSize: 11.5,
                      fontFamily: 'Menlo',
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    color: p.fileImportantText,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      height: 33,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: p.toolbarBg,
        border: Border(top: BorderSide(color: p.dividerColor, width: 1)),
      ),
      child: Row(
        children: [
          fKeyBtn('F3', 'View (mmap)', controller.openLister),
          fKeyBtn(
            'F4',
            'Open With ▾',
            () => controller.triggerSmartF4(forcePicker: true),
          ),
          fKeyBtn('F5', 'Copy (APFS)', controller.openCopyDialog),
          fKeyBtn('F6', 'Move/Ren', controller.openMoveDialog),
          fKeyBtn('F7', 'MkDir', controller.openMkdirDialog),
          fKeyBtn(
            'F8',
            'Trash',
            () => controller.openDeleteDialog(useTrash: true),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBar(TcThemePalette p) {
    return Container(
      height: 22,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: p.windowBg,
        border: Border(top: BorderSide(color: p.dividerColor, width: 1)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              controller.statusBanner,
              style: TextStyle(
                color: p.semiHighlightedText,
                fontSize: 11,
                fontFamily: 'Menlo',
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            'Theme: ${p.id.shortLabel} • Rust Core • macOS UI (⌘U)',
            style: TextStyle(
              color: p.mutedText,
              fontSize: 10.5,
              fontFamily: 'Menlo',
            ),
          ),
        ],
      ),
    );
  }
}
