import 'package:flutter/cupertino.dart';
import '../../core/models.dart';
import '../../core/theme_palette.dart';
import '../../state/commander_controller.dart';

class FavoritesHotlistModal extends StatelessWidget {
  final CommanderController controller;

  const FavoritesHotlistModal({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final p = controller.palette;
    final items = controller.favoriteHotlistItems;
    final targetSide = controller.favoritesTargetSide;
    final targetTab = controller.tabFor(targetSide);
    final currentPath = targetTab.summary.currentPath;
    final isCurrentPinned = controller.isPathPinned(currentPath);

    return Container(
      width: 660,
      constraints: const BoxConstraints(maxHeight: 580),
      decoration: BoxDecoration(
        color: p.toolbarBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: p.primaryAccent, width: 1.5),
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
          _buildHeader(p, targetSide, currentPath, isCurrentPinned),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                final prevCategory = index > 0
                    ? items[index - 1].category
                    : null;
                final showCategoryHeader = item.category != prevCategory;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (showCategoryHeader)
                      Padding(
                        padding: EdgeInsets.only(
                          top: index == 0 ? 2 : 10,
                          bottom: 4,
                          left: 4,
                        ),
                        child: Text(
                          item.category.toUpperCase(),
                          style: TextStyle(
                            color: p.mutedText,
                            fontSize: 10,
                            fontFamily: 'Menlo',
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.7,
                          ),
                        ),
                      ),
                    _buildFavoriteRow(p, item, index, currentPath),
                  ],
                );
              },
            ),
          ),
          _buildFooter(p),
        ],
      ),
    );
  }

  Widget _buildHeader(
    TcThemePalette p,
    PaneSide targetSide,
    String currentPath,
    bool isCurrentPinned,
  ) {
    final sideLabel = targetSide == PaneSide.left ? 'LEFT PANE' : 'RIGHT PANE';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: p.headerBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(10.5)),
        border: Border(bottom: BorderSide(color: p.dividerColor, width: 1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                CupertinoIcons.star_fill,
                size: 16,
                color: p.selectedText,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Directory Hotlist & macOS Favorites',
                  style: TextStyle(
                    color: p.fileImportantText,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              GestureDetector(
                onTap: controller.toggleFavoritesTargetSide,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: p.primaryAccent.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: p.primaryAccent, width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        CupertinoIcons.arrow_right_arrow_left,
                        size: 11,
                        color: p.primaryAccent,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        'Target: $sideLabel (Tab)',
                        style: TextStyle(
                          color: p.primaryAccent,
                          fontSize: 11,
                          fontFamily: 'Menlo',
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: controller.closeDialog,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: p.paneBgOdd,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Esc',
                    style: TextStyle(
                      color: p.mutedText,
                      fontSize: 11,
                      fontFamily: 'Menlo',
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Current: $currentPath',
                  style: TextStyle(
                    color: p.semiHighlightedText,
                    fontSize: 11.5,
                    fontFamily: 'Menlo',
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => controller.togglePinFolder(currentPath),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: isCurrentPinned
                        ? p.selectedRowBg
                        : p.primaryAccent,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isCurrentPinned
                          ? p.selectedText
                          : p.primaryAccent,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isCurrentPinned
                            ? CupertinoIcons.star_slash_fill
                            : CupertinoIcons.star_fill,
                        size: 12,
                        color: isCurrentPinned
                            ? p.selectedText
                            : p.cursorActiveText,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        isCurrentPinned
                            ? 'Unpin Current Folder [P]'
                            : '+ Pin Current Folder [P]',
                        style: TextStyle(
                          color: isCurrentPinned
                              ? p.selectedText
                              : p.cursorActiveText,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFavoriteRow(
    TcThemePalette p,
    FavoriteFolderItem item,
    int index,
    String currentPath,
  ) {
    final isSelected = index == controller.favoritesSelectedIndex;
    final isCurrent = item.path == currentPath;
    final keyBadge = index < 9 ? '${index + 1}' : '·';

    IconData rowIcon = CupertinoIcons.folder_fill;
    if (item.isCustomPinned) {
      rowIcon = CupertinoIcons.star_fill;
    } else if (item.label.startsWith('Home')) {
      rowIcon = CupertinoIcons.house_fill;
    } else if (item.label.startsWith('Desktop')) {
      rowIcon = CupertinoIcons.desktopcomputer;
    } else if (item.label.startsWith('Downloads')) {
      rowIcon = CupertinoIcons.arrow_down_circle_fill;
    } else if (item.label.startsWith('Documents')) {
      rowIcon = CupertinoIcons.doc_text_fill;
    } else if (item.label.startsWith('Applications')) {
      rowIcon = CupertinoIcons.app_badge_fill;
    } else if (item.label.startsWith('iCloud')) {
      rowIcon = CupertinoIcons.cloud_fill;
    } else if (item.category == 'Volumes & Drives') {
      rowIcon = CupertinoIcons.device_laptop;
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => controller.launchFavoriteAtIndex(index),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? p.cursorActiveBg : p.paneBgEven,
          borderRadius: BorderRadius.circular(7),
          border: Border.all(
            color: isSelected
                ? p.cursorActiveBorder
                : isCurrent
                ? p.primaryAccent.withValues(alpha: 0.6)
                : p.dividerColor,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 22,
              height: 20,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected
                    ? p.cursorActiveText.withValues(alpha: 0.2)
                    : p.headerBg,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: isSelected ? p.cursorActiveText : p.dividerColor,
                  width: 1,
                ),
              ),
              child: Text(
                keyBadge,
                style: TextStyle(
                  color: isSelected ? p.cursorActiveText : p.primaryAccent,
                  fontSize: 11,
                  fontFamily: 'Menlo',
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 9),
            Icon(
              rowIcon,
              size: 14,
              color: isSelected
                  ? p.cursorActiveText
                  : item.isCustomPinned
                  ? p.selectedText
                  : p.dirIcon,
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 155,
              child: Text(
                item.label,
                style: TextStyle(
                  color: isSelected ? p.cursorActiveText : p.fileImportantText,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                item.path,
                style: TextStyle(
                  color: isSelected
                      ? p.cursorActiveText.withValues(alpha: 0.85)
                      : p.semiHighlightedText,
                  fontSize: 11,
                  fontFamily: 'Menlo',
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 6),
            _miniActionBtn(
              p: p,
              isSelected: isSelected,
              label: '+Tab',
              onTap: () =>
                  controller.launchFavoriteAtIndex(index, inNewTab: true),
            ),
            const SizedBox(width: 4),
            _miniActionBtn(
              p: p,
              isSelected: isSelected,
              label: '⇄ Other',
              onTap: () =>
                  controller.launchFavoriteAtIndex(index, inOtherPane: true),
            ),
            if (item.isCustomPinned) ...[
              const SizedBox(width: 4),
              GestureDetector(
                onTap: () => controller.togglePinFolder(item.path),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: p.dangerColor.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Icon(
                    CupertinoIcons.xmark,
                    size: 11,
                    color: isSelected ? p.cursorActiveText : p.dangerColor,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _miniActionBtn({
    required TcThemePalette p,
    required bool isSelected,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
        decoration: BoxDecoration(
          color: isSelected
              ? p.cursorActiveText.withValues(alpha: 0.18)
              : p.headerBg,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: isSelected
                ? p.cursorActiveText.withValues(alpha: 0.45)
                : p.dividerColor,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? p.cursorActiveText : p.semiHighlightedText,
            fontSize: 10,
            fontFamily: 'Menlo',
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _buildFooter(TcThemePalette p) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: p.footerBg,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(10.5)),
        border: Border(top: BorderSide(color: p.dividerColor, width: 1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '[1–9] Instant Jump • [Enter] Open • [⇧Enter] Open in New Tab • [P] Pin/Unpin',
            style: TextStyle(
              color: p.mutedText,
              fontSize: 10.5,
              fontFamily: 'Menlo',
            ),
          ),
          Text(
            '⌘B / Ctrl+D',
            style: TextStyle(
              color: p.primaryAccent,
              fontSize: 10.5,
              fontFamily: 'Menlo',
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
