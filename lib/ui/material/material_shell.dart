import 'dart:io';
import 'package:flutter/material.dart';
import '../../core/models.dart';
import '../../core/theme_palette.dart';
import '../../state/commander_controller.dart';
import '../../state/keyboard_handler.dart';
import '../common/open_with_overlays.dart';
import '../common/toolbar_dropdown.dart';
import 'material_dialogs.dart';
import 'material_pane_view.dart';

class MaterialCommanderShell extends StatelessWidget {
  final CommanderController controller;

  const MaterialCommanderShell({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return CommanderKeyboardScope(
      controller: controller,
      child: ListenableBuilder(
        listenable: controller,
        builder: (context, _) {
          final p = controller.palette;
          return Scaffold(
            backgroundColor: p.windowBg,
            appBar: _buildMaterialAppBar(context, p),
            body: Stack(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(child: _buildDualPanes(context, p)),
                    _buildActivePathPromptBar(context, p),
                    _buildBottomActionBar(context, p),
                    _buildStatusBar(context, p),
                  ],
                ),
                FileRowContextMenuOverlay(controller: controller),
                MaterialDialogOverlay(controller: controller),
              ],
            ),
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildMaterialAppBar(
    BuildContext context,
    TcThemePalette p,
  ) {
    return AppBar(
      toolbarHeight: 48,
      backgroundColor: p.toolbarBg,
      surfaceTintColor: Colors.transparent,
      titleSpacing: 10,
      title: Row(
        children: [
          Icon(Icons.view_column_rounded, color: p.primaryAccent, size: 20),
          const SizedBox(width: 7),
          Text(
            'FerroPane',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 15,
              color: p.fileImportantText,
            ),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: p.primaryAccent.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: p.primaryAccent.withValues(alpha: 0.5),
                width: 1,
              ),
            ),
            child: Text(
              'M3',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: p.primaryAccent,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ActionChip(
                    avatar: Icon(
                      Icons.home_rounded,
                      size: 15,
                      color: p.primaryAccent,
                    ),
                    label: const Text('Home', style: TextStyle(fontSize: 11.5)),
                    visualDensity: VisualDensity.compact,
                    onPressed: () => controller.navigateToPath(
                      Platform.environment['HOME'] ?? '/Users',
                    ),
                  ),
                  const SizedBox(width: 5),
                  ActionChip(
                    avatar: Icon(
                      Icons.star_rounded,
                      size: 15,
                      color: p.selectedText,
                    ),
                    label: const Text(
                      'Favorites',
                      style: TextStyle(fontSize: 11.5),
                    ),
                    visualDensity: VisualDensity.compact,
                    onPressed: () => controller.openFavoritesHotlist(),
                  ),
                  const SizedBox(width: 5),
                  FilterChip(
                    selected: controller.showHidden,
                    label: const Text(
                      'Dotfiles',
                      style: TextStyle(fontSize: 11.5),
                    ),
                    visualDensity: VisualDensity.compact,
                    onSelected: (_) => controller.toggleHiddenFiles(),
                  ),
                  const SizedBox(width: 5),
                  FilterChip(
                    selected: controller.filterBarVisible,
                    avatar: Icon(
                      Icons.filter_alt_outlined,
                      size: 14,
                      color: p.primaryAccent,
                    ),
                    label: const Text(
                      'Filter',
                      style: TextStyle(fontSize: 11.5),
                    ),
                    visualDensity: VisualDensity.compact,
                    onSelected: (_) => controller.toggleQuickFilterBar(),
                  ),
                  const SizedBox(width: 5),
                  ActionChip(
                    avatar: Icon(
                      Icons.sync_alt_rounded,
                      size: 14,
                      color: p.primaryAccent,
                    ),
                    label: const Text(
                      'Sync (=)',
                      style: TextStyle(fontSize: 11.5),
                    ),
                    visualDensity: VisualDensity.compact,
                    onPressed: controller.syncOtherPaneToActive,
                  ),
                  const SizedBox(width: 5),
                  ActionChip(
                    avatar: Icon(
                      Icons.compare_arrows_rounded,
                      size: 15,
                      color: p.primaryAccent,
                    ),
                    label: const Text(
                      'Compare',
                      style: TextStyle(fontSize: 11.5),
                    ),
                    visualDensity: VisualDensity.compact,
                    onPressed: () => controller.openDeepCompare(),
                  ),
                  const SizedBox(width: 5),
                  ActionChip(
                    avatar: Icon(
                      Icons.preview_rounded,
                      size: 14,
                      color: p.primaryAccent,
                    ),
                    label: const Text(
                      'QuickLook',
                      style: TextStyle(fontSize: 11.5),
                    ),
                    visualDensity: VisualDensity.compact,
                    onPressed: controller.triggerQuickLook,
                  ),
                  const SizedBox(width: 5),
                  ActionChip(
                    avatar: Icon(
                      Icons.terminal_rounded,
                      size: 14,
                      color: p.primaryAccent,
                    ),
                    label: const Text(
                      'Terminal',
                      style: TextStyle(fontSize: 11.5),
                    ),
                    visualDensity: VisualDensity.compact,
                    onPressed: controller.openTerminalInActivePane,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 10),
          child: _buildThemeAndUiDropdowns(p),
        ),
      ],
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
              icon: Icons.desktop_mac_rounded,
            ),
            ToolbarDropdownItem(
              value: UiFrameworkMode.material3,
              label: 'Material 3',
              subtitle: 'Google M3 surfaces & chips',
              icon: Icons.layers_rounded,
            ),
          ],
          onChanged: controller.setUiFramework,
        ),
      ],
    );
  }

  Widget _buildDualPanes(BuildContext context, TcThemePalette p) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;
        const dividerWidth = 8.0;
        final usableWidth = (totalWidth - dividerWidth).clamp(200.0, 10000.0);
        final leftWidth = usableWidth * controller.splitRatio;
        final rightWidth = usableWidth - leftWidth;

        return Row(
          children: [
            SizedBox(
              width: leftWidth,
              child: MaterialPaneView(
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
                child: SizedBox(
                  width: dividerWidth,
                  child: Center(
                    child: Container(
                      width: 4,
                      height: 48,
                      decoration: BoxDecoration(
                        color: p.primaryAccent.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(
              width: rightWidth,
              child: MaterialPaneView(
                controller: controller,
                side: PaneSide.right,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildActivePathPromptBar(BuildContext context, TcThemePalette p) {
    final activePath = controller.activeTab.summary.currentPath;
    final focusedName = controller.focusedEntry?.name ?? '';

    return InkWell(
      onTap: controller.openGotoPathDialog,
      child: Container(
        height: 27,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: p.headerBg,
          border: Border(top: BorderSide(color: p.dividerColor, width: 1)),
        ),
        child: Row(
          children: [
            Text(
              '$activePath >',
              style: TextStyle(
                fontFamily: 'Menlo',
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
                color: p.primaryAccent,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                focusedName.isNotEmpty && focusedName != '..'
                    ? focusedName
                    : '(Click or press ⌘G to jump to any path)',
                style: TextStyle(
                  fontFamily: 'Menlo',
                  fontSize: 11.5,
                  fontWeight: focusedName.isNotEmpty && focusedName != '..'
                      ? FontWeight.w600
                      : FontWeight.w400,
                  color: focusedName.isNotEmpty && focusedName != '..'
                      ? p.fileImportantText
                      : p.mutedText,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomActionBar(BuildContext context, TcThemePalette p) {
    Widget m3KeyButton(
      IconData icon,
      String keyBadge,
      String label,
      VoidCallback onTap,
    ) {
      return Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 5),
          child: FilledButton.tonalIcon(
            style: FilledButton.styleFrom(
              backgroundColor: p.headerBg,
              foregroundColor: p.fileImportantText,
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            ),
            onPressed: onTap,
            icon: Icon(icon, size: 15, color: p.primaryAccent),
            label: RichText(
              overflow: TextOverflow.ellipsis,
              text: TextSpan(
                style: const TextStyle(fontFamily: 'Menlo', fontSize: 11.5),
                children: [
                  TextSpan(
                    text: '$keyBadge ',
                    style: TextStyle(
                      color: p.primaryAccent,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  TextSpan(
                    text: label,
                    style: TextStyle(
                      color: p.fileImportantText,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: p.toolbarBg,
        border: Border(top: BorderSide(color: p.dividerColor, width: 1)),
      ),
      child: Row(
        children: [
          m3KeyButton(
            Icons.visibility_outlined,
            'F3',
            'View (mmap)',
            controller.openLister,
          ),
          m3KeyButton(
            Icons.open_in_new_rounded,
            'F4',
            'Open With ▾',
            () => controller.triggerSmartF4(forcePicker: true),
          ),
          m3KeyButton(
            Icons.copy_all_rounded,
            'F5',
            'Copy (APFS)',
            controller.openCopyDialog,
          ),
          m3KeyButton(
            Icons.drive_file_move_outline,
            'F6',
            'Move/Ren',
            controller.openMoveDialog,
          ),
          m3KeyButton(
            Icons.create_new_folder_outlined,
            'F7',
            'MkDir',
            controller.openMkdirDialog,
          ),
          m3KeyButton(
            Icons.delete_outline_rounded,
            'F8',
            'Trash',
            () => controller.openDeleteDialog(useTrash: true),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBar(BuildContext context, TcThemePalette p) {
    return Container(
      height: 23,
      padding: const EdgeInsets.symmetric(horizontal: 14),
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
                fontFamily: 'Menlo',
                fontSize: 11,
                color: p.semiHighlightedText,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            'Theme: ${p.id.shortLabel} • Rust Core • Material 3 UI (⌘U)',
            style: TextStyle(
              fontFamily: 'Menlo',
              fontSize: 10.5,
              color: p.mutedText,
            ),
          ),
        ],
      ),
    );
  }
}
