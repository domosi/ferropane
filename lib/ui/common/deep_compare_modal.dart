import 'package:flutter/widgets.dart';
import '../../core/models.dart';
import '../../core/theme_palette.dart';
import '../../state/commander_controller.dart';

class DeepCompareModal extends StatelessWidget {
  final CommanderController controller;

  const DeepCompareModal({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final p = controller.palette;
    final res = controller.compareResult;
    if (res == null) return const SizedBox.shrink();

    final items = controller.filteredCompareItems;

    return Container(
      width: 1040,
      height: 660,
      decoration: BoxDecoration(
        color: p.toolbarBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: p.activeBorder, width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0xCC000000),
            blurRadius: 32,
            offset: Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(p, res),
          _buildFilterAndSyncBar(p, res),
          _buildTableColumnHeader(p),
          Expanded(
            child: res.error != null
                ? Center(
                    child: Text(
                      res.error!,
                      style: TextStyle(color: p.dangerColor, fontSize: 13),
                    ),
                  )
                : items.isEmpty
                ? Center(
                    child: Text(
                      res.identicalCount > 0 && !controller.compareShowIdentical
                          ? 'No differences found! (${res.identicalCount} identical item(s) hidden — click "= Identical" above to view)'
                          : 'No matching entries for active filters.',
                      style: TextStyle(
                        color: p.semiHighlightedText,
                        fontSize: 13,
                        fontFamily: 'Menlo',
                      ),
                    ),
                  )
                : ListView.builder(
                    itemExtent: 28.0,
                    itemCount: items.length,
                    itemBuilder: (context, idx) =>
                        _buildCompareRow(p, items[idx], idx),
                  ),
          ),
          _buildFooter(p, res, items.length),
        ],
      ),
    );
  }

  Widget _buildHeader(TcThemePalette p, DirCompareResultModel res) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: p.headerBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(13)),
        border: Border(bottom: BorderSide(color: p.dividerColor, width: 1)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Folder Deep Compare & Synchronize (⌘D)',
                  style: TextStyle(
                    color: p.fileImportantText,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Left: ${res.leftRoot}   ⇄   Right: ${res.rightRoot}',
                  style: TextStyle(
                    color: p.primaryAccent,
                    fontSize: 11.5,
                    fontFamily: 'Menlo',
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => controller.openDeepCompare(
              byContent: !controller.deepCompareByContent,
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: controller.deepCompareByContent
                    ? p.primaryAccent.withValues(alpha: 0.2)
                    : p.paneBgEven,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: controller.deepCompareByContent
                      ? p.primaryAccent
                      : p.dividerColor,
                  width: 1.2,
                ),
              ),
              child: Text(
                controller.deepCompareByContent
                    ? '✓ Byte Content Check: ON'
                    : 'Byte Content Check: OFF (Size+Time)',
                style: TextStyle(
                  color: controller.deepCompareByContent
                      ? p.primaryAccent
                      : p.semiHighlightedText,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => controller.openDeepCompare(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: p.paneBgEven,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: p.dividerColor, width: 1),
              ),
              child: Text(
                '↻ Rescan',
                style: TextStyle(
                  color: p.fileImportantText,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: controller.closeDialog,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: p.dangerColor,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'Close (Esc)',
                style: TextStyle(
                  color: Color(0xFFFFFFFF),
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterAndSyncBar(TcThemePalette p, DirCompareResultModel res) {
    Widget filterPill({
      required String label,
      required bool active,
      required Color accent,
      required VoidCallback onTap,
    }) {
      return Padding(
        padding: const EdgeInsets.only(right: 6),
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: active ? accent.withValues(alpha: 0.2) : p.paneBgEven,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: active ? accent : p.dividerColor,
                width: active ? 1.4 : 1.0,
              ),
            ),
            child: Text(
              label,
              style: TextStyle(
                color: active ? accent : p.mutedText,
                fontSize: 11.5,
                fontFamily: 'Menlo',
                fontWeight: active ? FontWeight.w800 : FontWeight.w500,
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: p.footerBg,
        border: Border(bottom: BorderSide(color: p.dividerColor, width: 1)),
      ),
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  Text(
                    'Show:',
                    style: TextStyle(
                      color: p.mutedText,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 8),
                  filterPill(
                    label: '→ Only Left (${res.onlyLeftCount})',
                    active: controller.compareShowOnlyLeft,
                    accent: p.execText,
                    onTap: () => controller.toggleCompareFilter(
                      onlyLeft: !controller.compareShowOnlyLeft,
                    ),
                  ),
                  filterPill(
                    label: '≠ Different (${res.differentCount})',
                    active: controller.compareShowDifferent,
                    accent: p.selectedText,
                    onTap: () => controller.toggleCompareFilter(
                      different: !controller.compareShowDifferent,
                    ),
                  ),
                  filterPill(
                    label: '← Only Right (${res.onlyRightCount})',
                    active: controller.compareShowOnlyRight,
                    accent: p.primaryAccent,
                    onTap: () => controller.toggleCompareFilter(
                      onlyRight: !controller.compareShowOnlyRight,
                    ),
                  ),
                  filterPill(
                    label: '= Identical (${res.identicalCount})',
                    active: controller.compareShowIdentical,
                    accent: p.semiHighlightedText,
                    onTap: () => controller.toggleCompareFilter(
                      identical: !controller.compareShowIdentical,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => controller.syncAllCompare(leftToRight: true),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: p.execText.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: p.execText, width: 1),
              ),
              child: Text(
                'Sync Left → Right',
                style: TextStyle(
                  color: p.execText,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: () => controller.syncAllCompare(leftToRight: false),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: p.primaryAccent.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: p.primaryAccent, width: 1),
              ),
              child: Text(
                'Sync Right ← Left',
                style: TextStyle(
                  color: p.primaryAccent,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableColumnHeader(TcThemePalette p) {
    return Container(
      height: 26,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: p.headerBg,
        border: Border(bottom: BorderSide(color: p.dividerColor, width: 1)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 5,
            child: Text(
              'Left Pane Relative Path',
              style: TextStyle(
                color: p.semiHighlightedText,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          SizedBox(
            width: 85,
            child: Text(
              'Left Size',
              textAlign: TextAlign.right,
              style: TextStyle(
                color: p.semiHighlightedText,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          SizedBox(
            width: 120,
            child: Text(
              'Status / Sync',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: p.primaryAccent,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          SizedBox(
            width: 85,
            child: Text(
              'Right Size',
              style: TextAlign.left == TextAlign.left
                  ? TextStyle(
                      color: p.semiHighlightedText,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    )
                  : const TextStyle(),
            ),
          ),
          Expanded(
            flex: 5,
            child: Text(
              'Right Pane Relative Path',
              style: TextStyle(
                color: p.semiHighlightedText,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompareRow(TcThemePalette p, CompareEntryModel item, int idx) {
    final bg = idx.isEven ? p.paneBgEven : p.paneBgOdd;
    final hasLeft = item.status != 'only_right';
    final hasRight = item.status != 'only_left';

    Color statusColor;
    String statusBadge;
    switch (item.status) {
      case 'only_left':
        statusColor = p.execText;
        statusBadge = 'Copy →';
        break;
      case 'only_right':
        statusColor = p.primaryAccent;
        statusBadge = '← Copy';
        break;
      case 'different':
        statusColor = p.selectedText;
        statusBadge = item.newerSide == 'left'
            ? '≠ (L newer)'
            : item.newerSide == 'right'
            ? '≠ (R newer)'
            : '≠ Diff';
        break;
      default:
        statusColor = p.mutedText;
        statusBadge = '= Equal';
    }

    final displayName = item.isDir ? '[${item.relPath}]' : item.relPath;

    return Container(
      color: bg,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        children: [
          Expanded(
            flex: 5,
            child: Text(
              hasLeft ? displayName : '—',
              style: TextStyle(
                color: hasLeft ? statusColor : p.mutedText,
                fontSize: 12,
                fontFamily: 'Menlo',
                fontWeight: item.status != 'identical'
                    ? FontWeight.w700
                    : FontWeight.w400,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(
            width: 85,
            child: Text(
              hasLeft
                  ? (item.isDir ? '<DIR>' : formatBytes(item.leftSize))
                  : '',
              textAlign: TextAlign.right,
              style: TextStyle(
                color: p.semiHighlightedText,
                fontSize: 11.5,
                fontFamily: 'Menlo',
              ),
            ),
          ),
          SizedBox(
            width: 120,
            child: Center(
              child: GestureDetector(
                onTap: item.status == 'identical'
                    ? null
                    : () {
                        final copyLeftToRight =
                            item.status == 'only_left' ||
                            (item.status == 'different' &&
                                item.newerSide != 'right');
                        controller.syncCompareSingleItem(
                          item,
                          leftToRight: copyLeftToRight,
                        );
                      },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: statusColor.withValues(alpha: 0.6),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    statusBadge,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 10.5,
                      fontFamily: 'Menlo',
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ),
          ),
          SizedBox(
            width: 85,
            child: Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Text(
                hasRight
                    ? (item.isDir ? '<DIR>' : formatBytes(item.rightSize))
                    : '',
                style: TextStyle(
                  color: p.semiHighlightedText,
                  fontSize: 11.5,
                  fontFamily: 'Menlo',
                ),
              ),
            ),
          ),
          Expanded(
            flex: 5,
            child: Text(
              hasRight ? displayName : '—',
              style: TextStyle(
                color: hasRight ? statusColor : p.mutedText,
                fontSize: 12,
                fontFamily: 'Menlo',
                fontWeight: item.status != 'identical'
                    ? FontWeight.w700
                    : FontWeight.w400,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(TcThemePalette p, DirCompareResultModel res, int shown) {
    final total =
        res.onlyLeftCount +
        res.differentCount +
        res.onlyRightCount +
        res.identicalCount;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: p.headerBg,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(13)),
        border: Border(top: BorderSide(color: p.dividerColor, width: 1)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Showing $shown of $total compared entries  •  Click any middle badge (Copy → / ← Copy / ≠) to sync an individual item',
              style: TextStyle(
                color: p.mutedText,
                fontSize: 11,
                fontFamily: 'Menlo',
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
