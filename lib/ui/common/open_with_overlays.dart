import 'package:flutter/widgets.dart';
import '../../state/commander_controller.dart';

class OpenWithPaletteCard extends StatelessWidget {
  final CommanderController controller;

  const OpenWithPaletteCard({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final p = controller.palette;
    final entry = controller.openWithTargetEntry ?? controller.focusedEntry;
    if (entry == null) return const SizedBox.shrink();

    final apps = controller.openWithApps;
    final selectedIdx = controller.openWithSelectedIndex;
    final extLabel = entry.ext.isEmpty ? 'these' : '.${entry.ext}';

    return Container(
      width: 620,
      constraints: const BoxConstraints(maxHeight: 500),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: p.toolbarBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: p.activeBorder, width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0xBB000000),
            blurRadius: 28,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Open "${entry.name}" With…',
                      style: TextStyle(
                        color: p.fileImportantText,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Press [1]–[9] or [Enter] to launch immediately • [↑/↓] Navigate • [Esc] Cancel',
                      style: TextStyle(
                        color: p.mutedText,
                        fontSize: 11,
                        fontFamily: 'Menlo',
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: p.headerBg,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: p.dividerColor, width: 1),
                ),
                child: Text(
                  'NSWorkspace',
                  style: TextStyle(
                    color: p.primaryAccent,
                    fontSize: 10.5,
                    fontFamily: 'Menlo',
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(height: 1, color: p.dividerColor),
          const SizedBox(height: 8),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: apps.length,
              itemBuilder: (context, idx) {
                final app = apps[idx];
                final isSelected = idx == selectedIdx;
                final keyBadge = idx < 9 ? '${idx + 1}' : '·';

                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => controller.launchOpenWithIndex(idx),
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 2),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected ? p.cursorActiveBg : p.paneBgEven,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected
                            ? p.cursorActiveBorder
                            : p.dividerColor,
                        width: isSelected ? 1.4 : 1.0,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 22,
                          height: 22,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? p.cursorActiveText.withValues(alpha: 0.18)
                                : p.headerBg,
                            borderRadius: BorderRadius.circular(5),
                            border: Border.all(
                              color: isSelected
                                  ? p.cursorActiveText
                                  : p.primaryAccent.withValues(alpha: 0.6),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            keyBadge,
                            style: TextStyle(
                              color: isSelected
                                  ? p.cursorActiveText
                                  : p.primaryAccent,
                              fontSize: 11.5,
                              fontFamily: 'Menlo',
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                app.name,
                                style: TextStyle(
                                  color: isSelected
                                      ? p.cursorActiveText
                                      : p.fileImportantText,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                app.path,
                                style: TextStyle(
                                  color: isSelected
                                      ? p.cursorActiveText.withValues(
                                          alpha: 0.8,
                                        )
                                      : p.mutedText,
                                  fontSize: 10.5,
                                  fontFamily: 'Menlo',
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        if (app.isRemembered)
                          Container(
                            margin: const EdgeInsets.only(right: 6),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: p.selectedRowBg,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: p.selectedText,
                                width: 1,
                              ),
                            ),
                            child: Text(
                              '★ F4 Saved',
                              style: TextStyle(
                                color: p.selectedText,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        if (app.isDefault)
                          Container(
                            margin: const EdgeInsets.only(right: 6),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: p.headerBg,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Default',
                              style: TextStyle(
                                color: p.primaryAccent,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        Text(
                          '↵',
                          style: TextStyle(
                            color: isSelected
                                ? p.cursorActiveText
                                : p.mutedText,
                            fontSize: 13,
                            fontFamily: 'Menlo',
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 10),
          Container(height: 1, color: p.dividerColor),
          const SizedBox(height: 10),
          Row(
            children: [
              if (entry.ext.isNotEmpty)
                 Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: controller.toggleOpenWithRemember,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 16,
                          height: 16,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: controller.openWithRememberForExt
                                ? p.primaryAccent
                                : p.paneBgEven,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: controller.openWithRememberForExt
                                  ? p.primaryAccent
                                  : p.mutedText,
                              width: 1.2,
                            ),
                          ),
                          child: controller.openWithRememberForExt
                              ? Text(
                                  '✓',
                                  style: TextStyle(
                                    color: p.cursorActiveText,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                  ),
                                )
                              : const SizedBox.shrink(),
                        ),
                        const SizedBox(width: 7),
                        Flexible(
                          child: Text(
                            'Remember for $extLabel on F4',
                            style: TextStyle(
                              color: p.semiHighlightedText,
                              fontSize: 11.5,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                const Spacer(),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: controller.browseOtherAppForOpenWith,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: p.headerBg,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: p.dividerColor, width: 1),
                  ),
                  child: Text(
                    '+ Browse Apps… (B)',
                    style: TextStyle(
                      color: p.primaryAccent,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: controller.confirmActiveDialog,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: p.primaryAccent,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Open (Enter)',
                    style: TextStyle(
                      color: p.cursorActiveText,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class FileRowContextMenuOverlay extends StatelessWidget {
  final CommanderController controller;

  const FileRowContextMenuOverlay({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final pos = controller.contextMenuPosition;
    final entry = controller.contextMenuEntry;
    if (pos == null || entry == null) return const SizedBox.shrink();

    final p = controller.palette;
    final size = MediaQuery.sizeOf(context);
    const menuWidth = 265.0;
    const estMenuHeight = 340.0;
    final left = pos.dx.clamp(8.0, (size.width - menuWidth - 8.0).clamp(8.0, size.width));
    final top = pos.dy.clamp(8.0, (size.height - estMenuHeight - 8.0).clamp(8.0, size.height));

    final topApps = controller.openWithApps.take(4).toList();

    Widget menuRow({
      required String label,
      String? shortcut,
      Color? labelColor,
      required VoidCallback onTap,
    }) {
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: labelColor ?? p.fileImportantText,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (shortcut != null)
                Text(
                  shortcut,
                  style: TextStyle(
                    color: p.mutedText,
                    fontSize: 10.5,
                    fontFamily: 'Menlo',
                  ),
                ),
            ],
          ),
        ),
      );
    }

    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: controller.closeContextMenu,
            onSecondaryTap: controller.closeContextMenu,
            child: const SizedBox.expand(),
          ),
        ),
        Positioned(
          left: left,
          top: top,
          child: Container(
            width: menuWidth,
            padding: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(
              color: p.toolbarBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: p.activeBorder, width: 1.2),
              boxShadow: const [
                BoxShadow(
                  color: Color(0xAA000000),
                  blurRadius: 20,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  child: Text(
                    entry.name,
                    style: TextStyle(
                      color: p.primaryAccent,
                      fontSize: 11.5,
                      fontFamily: 'Menlo',
                      fontWeight: FontWeight.w800,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  height: 1,
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  color: p.dividerColor,
                ),
                menuRow(
                  label: entry.isAppBundle
                      ? '🚀 Launch Application'
                      : entry.isArchive
                      ? '📦 Browse Inside Archive'
                      : entry.isDiskImage
                      ? '💿 Mount Disk Image & Open'
                      : entry.isExecutableScript
                      ? '⚡ Run in Terminal'
                      : 'Open Default',
                  shortcut: 'Enter',
                  labelColor:
                      (entry.isAppBundle ||
                          entry.isArchive ||
                          entry.isDiskImage ||
                          entry.isExecutableScript)
                      ? p.primaryAccent
                      : p.fileImportantText,
                  onTap: () {
                    controller.closeContextMenu();
                    controller.activateFocusedEntry();
                  },
                ),
                if (entry.isAppBundle)
                  menuRow(
                    label: '📂 Show Package Contents',
                    shortcut: '⌘↓',
                    onTap: () => controller.enterDirectoryOrPackageContents(
                      target: entry,
                    ),
                  ),
                if (entry.isArchive) ...[
                  menuRow(
                    label: '📦 Extract Archive Here',
                    onTap: () =>
                        controller.extractArchive(entry, toOtherPane: false),
                  ),
                  menuRow(
                    label: '📦 Extract Archive to Other Pane',
                    onTap: () =>
                        controller.extractArchive(entry, toOtherPane: true),
                  ),
                ],
                if (entry.isDir &&
                    entry.fullPath.startsWith('/Volumes/') &&
                    entry.fullPath != '/Volumes/Macintosh HD')
                  menuRow(
                    label: '⏏ Eject / Unmount Volume',
                    labelColor: p.selectedText,
                    onTap: () => controller.ejectVolumePath(entry.fullPath),
                  ),
                menuRow(
                  label: 'Open With Palette…',
                  shortcut: '⇧Enter / ⌘O',
                  labelColor: p.primaryAccent,
                  onTap: () => controller.openOpenWithPalette(target: entry),
                ),
                if (topApps.isNotEmpty) ...[
                  Container(
                    height: 1,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    color: p.dividerColor,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 2,
                    ),
                    child: Text(
                      'QUICK OPEN WITH:',
                      style: TextStyle(
                        color: p.mutedText,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  for (int i = 0; i < topApps.length; i++)
                    menuRow(
                      label: '  ▸ ${topApps[i].name}',
                      shortcut: topApps[i].isDefault ? 'Default' : null,
                      labelColor: p.semiHighlightedText,
                      onTap: () => controller.launchOpenWithIndex(i),
                    ),
                  menuRow(
                    label: '  ▸ Browse /Applications…',
                    labelColor: p.primaryAccent,
                    onTap: controller.browseOtherAppForOpenWith,
                  ),
                ],
                Container(
                  height: 1,
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  color: p.dividerColor,
                ),
                if (!entry.isDir)
                  menuRow(
                    label: 'View in Lister (mmap)',
                    shortcut: 'F3',
                    onTap: () {
                      controller.closeContextMenu();
                      controller.openLister();
                    },
                  ),
                menuRow(
                  label: 'Quick Look Preview',
                  shortcut: '⌘Y',
                  onTap: () {
                    controller.closeContextMenu();
                    controller.triggerQuickLook();
                  },
                ),
                menuRow(
                  label: 'Toggle Select / Calc Size',
                  shortcut: 'Space',
                  onTap: () {
                    controller.closeContextMenu();
                    controller.toggleSelectionAtCursor(
                      advanceCursor: false,
                      calculateDirSize: true,
                    );
                  },
                ),
                menuRow(
                  label: 'Copy Full Path',
                  onTap: () => controller.copyPathToClipboard(entry.fullPath),
                ),
                menuRow(
                  label: 'Reveal in Finder',
                  onTap: () {
                    controller.closeContextMenu();
                    controller.revealFocusedInFinder();
                  },
                ),
                if (entry.isDir && !entry.isParent)
                  menuRow(
                    label: controller.isPathPinned(entry.fullPath)
                        ? '★ Unpin Folder from Favorites'
                        : '★ Pin Folder to Favorites',
                    labelColor: p.selectedText,
                    onTap: () {
                      controller.closeContextMenu();
                      controller.togglePinFolder(entry.fullPath);
                    },
                  ),
                menuRow(
                  label: '★ Directory Hotlist & Favorites…',
                  shortcut: '⌘B',
                  labelColor: p.primaryAccent,
                  onTap: () => controller.openFavoritesHotlist(),
                ),
                menuRow(
                  label: '🔍 Find Files in Folder…',
                  shortcut: '⌘F',
                  labelColor: p.primaryAccent,
                  onTap: () => controller.openFileSearch(),
                ),
                menuRow(
                  label: 'Deep Compare Folders…',
                  shortcut: '⌘D',
                  labelColor: p.primaryAccent,
                  onTap: () => controller.openDeepCompare(),
                ),
                Container(
                  height: 1,
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  color: p.dividerColor,
                ),
                menuRow(
                  label: 'Move to Trash…',
                  shortcut: 'F8',
                  labelColor: p.dangerColor,
                  onTap: () {
                    controller.closeContextMenu();
                    controller.openDeleteDialog(useTrash: true);
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
