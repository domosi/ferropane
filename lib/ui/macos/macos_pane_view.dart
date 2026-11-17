import 'package:flutter/cupertino.dart';
import '../../core/models.dart';
import '../../core/theme_palette.dart';
import '../../state/commander_controller.dart';

class MacosPaneView extends StatelessWidget {
  final CommanderController controller;
  final PaneSide side;

  const MacosPaneView({
    super.key,
    required this.controller,
    required this.side,
  });

  bool get isActive => controller.activeSide == side;
  PaneTabController get tab => controller.tabFor(side);

  @override
  Widget build(BuildContext context) {
    final p = controller.palette;
    final summary = tab.summary;
    final activeBorderColor = isActive ? p.activeBorder : p.inactiveBorder;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => controller.setActiveSide(side),
      child: Container(
        decoration: BoxDecoration(
          color: p.paneBgEven,
          border: Border.all(
            color: activeBorderColor,
            width: isActive ? 1.6 : 1.0,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildTabBar(p),
            _buildPathBar(p, summary),
            _buildColumnHeaders(p, summary),
            Expanded(child: _buildFileList(p, summary)),
            if (isActive &&
                (controller.filterBarVisible ||
                    summary.filterQuery.isNotEmpty))
              _buildQuickFilterBar(p, summary),
            _buildPaneFooter(p, summary),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBar(TcThemePalette p) {
    final tabs = controller.tabsFor(side);
    final activeIdx = controller.activeTabIndexFor(side);

    return Container(
      height: 29,
      color: p.footerBg,
      child: Row(
        children: [
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: tabs.length,
              itemBuilder: (context, idx) {
                final t = tabs[idx];
                final selected = idx == activeIdx;
                return GestureDetector(
                  onTap: () => controller.selectTab(side, idx),
                  child: Container(
                    constraints: const BoxConstraints(
                      minWidth: 90,
                      maxWidth: 180,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: selected ? p.paneBgEven : p.footerBg,
                      border: Border(
                        right: BorderSide(color: p.dividerColor, width: 1),
                        top: BorderSide(
                          color: selected
                              ? (isActive
                                    ? p.primaryAccent
                                    : p.semiHighlightedText)
                              : const Color(0x00000000),
                          width: 2.5,
                        ),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          CupertinoIcons.folder_fill,
                          size: 12.5,
                          color: selected ? p.dirIcon : p.mutedText,
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            t.title,
                            style: TextStyle(
                              color: selected
                                  ? p.fileImportantText
                                  : p.mutedText,
                              fontSize: 11.5,
                              fontWeight: selected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (tabs.length > 1) ...[
                          const SizedBox(width: 6),
                          GestureDetector(
                            onTap: () => controller.closeTab(side, idx),
                            child: Icon(
                              CupertinoIcons.xmark,
                              size: 10,
                              color: p.mutedText,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          CupertinoButton(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            minimumSize: const Size(26, 26),
            onPressed: () => controller.addNewTab(side: side),
            child: Icon(
              CupertinoIcons.plus,
              size: 13,
              color: p.primaryAccent,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPathBar(TcThemePalette p, PaneSummaryModel summary) {
    final segments = summary.currentPath
        .split('/')
        .where((s) => s.isNotEmpty)
        .toList();

    return Container(
      height: 30,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: isActive ? p.headerBg : p.footerBg,
        border: Border(bottom: BorderSide(color: p.dividerColor, width: 1)),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              controller.setActiveSide(side);
              controller.navigateUp();
            },
            child: Padding(
              padding: const EdgeInsets.only(right: 6),
              child: Icon(
                CupertinoIcons.arrow_turn_up_left,
                size: 13,
                color: p.primaryAccent,
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => controller.navigateToPath('/', side: side),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: p.paneBgOdd,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '/',
                        style: TextStyle(
                          color: p.primaryAccent,
                          fontSize: 11.5,
                          fontFamily: 'Menlo',
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  for (int i = 0; i < segments.length; i++) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: Icon(
                        CupertinoIcons.chevron_right,
                        size: 10,
                        color: p.mutedText,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        final targetPath =
                            '/${segments.take(i + 1).join('/')}';
                        controller.navigateToPath(targetPath, side: side);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: i == segments.length - 1 && isActive
                              ? p.primaryAccent
                              : p.paneBgOdd,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          segments[i],
                          style: TextStyle(
                            color: i == segments.length - 1 && isActive
                                ? p.cursorActiveText
                                : p.semiHighlightedText,
                            fontSize: 11.5,
                            fontFamily: 'Menlo',
                            fontWeight: i == segments.length - 1
                                ? FontWeight.w700
                                : FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: () {
              controller.setActiveSide(side);
              controller.openGotoPathDialog();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: p.paneBgOdd,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Icon(
                CupertinoIcons.pencil,
                size: 12,
                color: p.primaryAccent,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${formatBytes(summary.volumeFreeBytes)} free',
            style: TextStyle(
              color: p.semiHighlightedText,
              fontSize: 11,
              fontFamily: 'Menlo',
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColumnHeaders(TcThemePalette p, PaneSummaryModel summary) {
    Widget headerCell(
      String title,
      SortField field, {
      int flex = 1,
      double? width,
      Alignment alignment = Alignment.centerLeft,
    }) {
      final isSorted = summary.sortField == field;
      final arrow = isSorted ? (summary.sortAscending ? ' ▲' : ' ▼') : '';
      final content = GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => controller.toggleSort(side, field),
        child: Container(
          alignment: alignment,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            border: Border(right: BorderSide(color: p.dividerColor, width: 1)),
          ),
          child: Text(
            '$title$arrow',
            style: TextStyle(
              color: isSorted ? p.primaryAccent : p.semiHighlightedText,
              fontSize: 11,
              fontWeight: isSorted ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
        ),
      );

      if (width != null) {
        return SizedBox(width: width, child: content);
      }
      return Expanded(flex: flex, child: content);
    }

    return Container(
      height: 24,
      decoration: BoxDecoration(
        color: p.headerBg,
        border: Border(bottom: BorderSide(color: p.dividerColor, width: 1)),
      ),
      child: Row(
        children: [
          headerCell('Name', SortField.name, flex: 5),
          headerCell('Ext', SortField.extension, width: 68),
          headerCell(
            'Size',
            SortField.size,
            width: 92,
            alignment: Alignment.centerRight,
          ),
          headerCell('Modified', SortField.modified, width: 126),
          Container(
            width: 86,
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              'Attr',
              style: TextStyle(
                color: p.mutedText,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFileList(TcThemePalette p, PaneSummaryModel summary) {
    if (summary.errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            summary.errorMessage!,
            style: TextStyle(color: p.dangerColor, fontSize: 12.5),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return ListView.builder(
      controller: tab.scrollController,
      itemExtent: CommanderController.rowExtent,
      itemCount: summary.totalRows,
      itemBuilder: (context, index) {
        final entry = controller.getRow(tab, index);
        if (entry == null) {
          return const SizedBox.shrink();
        }
        final isCursor = index == tab.cursorIndex;
        return _MacosFileRow(
          palette: p,
          entry: entry,
          index: index,
          isCursor: isCursor,
          isPaneActive: isActive,
          onTap: () =>
              controller.setCursor(side, index, ensureVisible: false),
          onDoubleTap: () {
            controller.setCursor(side, index, ensureVisible: false);
            controller.activateFocusedEntry();
          },
          onSecondaryTapDown: (details) => controller.showRowContextMenu(
            side,
            index,
            details.globalPosition,
          ),
        );
      },
    );
  }

  Widget _buildQuickFilterBar(TcThemePalette p, PaneSummaryModel summary) {
    return Container(
      height: 30,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: p.headerBg,
        border: Border(top: BorderSide(color: p.primaryAccent, width: 1.5)),
      ),
      child: Row(
        children: [
          Icon(CupertinoIcons.search, size: 13, color: p.primaryAccent),
          const SizedBox(width: 6),
          Text(
            'Filter:',
            style: TextStyle(
              color: p.semiHighlightedText,
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: CupertinoTextField(
              autofocus: true,
              placeholder: 'Type to filter files (Esc to clear)...',
              placeholderStyle: TextStyle(color: p.mutedText, fontSize: 12),
              style: TextStyle(
                color: p.fileImportantText,
                fontSize: 12,
                fontFamily: 'Menlo',
              ),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: p.paneBgEven,
                borderRadius: BorderRadius.circular(4),
              ),
              onChanged: controller.setQuickFilter,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaneFooter(TcThemePalette p, PaneSummaryModel summary) {
    final hasSel = summary.selectedFiles > 0 || summary.selectedDirs > 0;
    final text = hasSel
        ? '★ Selected: ${formatBytes(summary.selectedBytes)} in ${summary.selectedFiles} file(s), ${summary.selectedDirs} dir(s)'
        : '${formatBytes(summary.totalBytes)} in ${summary.totalFiles} file(s), ${summary.totalDirs} dir(s)';

    return Container(
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: p.footerBg,
        border: Border(top: BorderSide(color: p.dividerColor, width: 1)),
      ),
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: TextStyle(
          color: hasSel ? p.selectedText : p.semiHighlightedText,
          fontSize: 11,
          fontFamily: 'Menlo',
          fontWeight: hasSel ? FontWeight.w700 : FontWeight.w500,
        ),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

class _MacosFileRow extends StatelessWidget {
  final TcThemePalette palette;
  final DirEntryModel entry;
  final int index;
  final bool isCursor;
  final bool isPaneActive;
  final VoidCallback onTap;
  final VoidCallback onDoubleTap;
  final GestureTapDownCallback onSecondaryTapDown;

  const _MacosFileRow({
    required this.palette,
    required this.entry,
    required this.index,
    required this.isCursor,
    required this.isPaneActive,
    required this.onTap,
    required this.onDoubleTap,
    required this.onSecondaryTapDown,
  });

  @override
  Widget build(BuildContext context) {
    final activeCur = isCursor && isPaneActive;

    Color bgColor;
    if (activeCur) {
      bgColor = palette.cursorActiveBg;
    } else if (isCursor && !isPaneActive) {
      bgColor = palette.cursorInactiveBg;
    } else if (entry.selected) {
      bgColor = palette.selectedRowBg;
    } else {
      bgColor = index.isEven ? palette.paneBgEven : palette.paneBgOdd;
    }

    // 1. IMPORTANT: Primary Name & Icon Color
    final nameColor = palette.resolveEntryNameColor(
      entry,
      isActiveCursor: activeCur,
    );

    // 2. SEMI-HIGHLIGHTED: Extension & Size
    final extColor = palette.resolveExtColor(entry, isActiveCursor: activeCur);
    final sizeColor = palette.resolveSizeColor(
      entry,
      isActiveCursor: activeCur,
    );

    // 3. LESS IMPORTANT (SUBDUED): Date & Permissions
    final metaColor = activeCur
        ? palette.cursorActiveText.withValues(alpha: 0.78)
        : entry.selected
        ? palette.selectedText.withValues(alpha: 0.8)
        : palette.mutedText;

    final iconData = entry.isParent
        ? CupertinoIcons.arrow_up_left_square_fill
        : entry.isDir
        ? CupertinoIcons.folder_fill
        : entry.isSymlink
        ? CupertinoIcons.link
        : CupertinoIcons.doc_text_fill;

    final iconColor = activeCur
        ? palette.cursorActiveText
        : entry.selected
        ? palette.selectedText
        : entry.isDir
        ? palette.dirIcon
        : nameColor.withValues(alpha: 0.85);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      onDoubleTap: onDoubleTap,
      onSecondaryTapDown: onSecondaryTapDown,
      child: Container(
        decoration: BoxDecoration(
          color: bgColor,
          border: activeCur
              ? Border(
                  left: BorderSide(
                    color: palette.cursorActiveBorder,
                    width: 3.0,
                  ),
                )
              : null,
        ),
        padding: EdgeInsets.only(left: activeCur ? 5 : 8, right: 8),
        child: Row(
          children: [
            Expanded(
              flex: 5,
              child: Row(
                children: [
                  Icon(iconData, size: 13.5, color: iconColor),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      entry.isDir && !entry.isParent
                          ? '[${entry.name}]'
                          : entry.stem,
                      style: TextStyle(
                        color: nameColor,
                        fontSize: 12,
                        fontFamily: 'Menlo',
                        fontWeight:
                            entry.isDir || entry.selected || activeCur
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              width: 68,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Text(
                  entry.ext,
                  style: TextStyle(
                    color: extColor,
                    fontSize: 11.5,
                    fontFamily: 'Menlo',
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            SizedBox(
              width: 92,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Text(
                  entry.displaySize,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    color: sizeColor,
                    fontSize: 11.5,
                    fontFamily: 'Menlo',
                    fontWeight:
                        (entry.size >= 10 * 1024 * 1024 ||
                            entry.sizeCalculated && entry.isDir)
                        ? FontWeight.w700
                        : FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            SizedBox(
              width: 126,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Text(
                  entry.displayDate,
                  style: TextStyle(
                    color: metaColor,
                    fontSize: 11,
                    fontFamily: 'Menlo',
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            SizedBox(
              width: 86,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  entry.permissions,
                  style: TextStyle(
                    color: metaColor.withValues(alpha: 0.75),
                    fontSize: 10.5,
                    fontFamily: 'Menlo',
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
