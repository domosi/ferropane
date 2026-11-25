import 'package:flutter/cupertino.dart';
import '../../core/models.dart';
import '../../core/theme_palette.dart';
import '../../state/commander_controller.dart';
import '../common/file_search_modal.dart';

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
            width: isActive ? 1.8 : 1.0,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildTabBar(p),
            _buildPathBar(p, summary),
            _buildColumnHeaders(p, summary),
            Expanded(child: _buildFileList(p, summary)),
            if (isActive && controller.typeAheadQuery.isNotEmpty)
              TypeAheadJumpBar(controller: controller),
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

  IconData _iconForTabPath(String path, bool isArchive) {
    if (isArchive) return CupertinoIcons.archivebox_fill;
    final lower = path.toLowerCase();
    if (lower.endsWith('/downloads')) {
      return CupertinoIcons.arrow_down_circle_fill;
    }
    if (lower.endsWith('/desktop')) return CupertinoIcons.desktopcomputer;
    if (lower.endsWith('/documents')) return CupertinoIcons.doc_text_fill;
    if (lower == '/applications') return CupertinoIcons.app_badge_fill;
    if (lower.startsWith('/volumes')) return CupertinoIcons.device_laptop;
    if (lower.split('/').where((s) => s.isNotEmpty).length <= 2) {
      return CupertinoIcons.house_fill;
    }
    return CupertinoIcons.folder_fill;
  }

  /// Design B: 2-Line Context Tabs (Folder Name + Item Count on top, Parent Path below)
  Widget _buildTabBar(TcThemePalette p) {
    final tabs = controller.tabsFor(side);
    final activeIdx = controller.activeTabIndexFor(side);
    final activeSurface = isActive ? p.headerBg : p.paneBgEven;

    return Container(
      height: 44,
      padding: const EdgeInsets.only(left: 6, right: 4, top: 4),
      decoration: BoxDecoration(
        color: p.windowBg,
      ),
      child: Row(
        children: [
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: tabs.length,
              itemBuilder: (context, idx) {
                final t = tabs[idx];
                final selected = idx == activeIdx;
                final tabIcon = _iconForTabPath(
                  t.displayPath,
                  t.isInsideArchive,
                );

                return GestureDetector(
                  onTap: () => controller.selectTab(side, idx),
                  child: Opacity(
                    opacity: selected ? 1.0 : 0.68,
                    child: Container(
                      constraints: const BoxConstraints(
                        minWidth: 135,
                        maxWidth: 235,
                      ),
                      margin: const EdgeInsets.only(right: 4),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: selected ? activeSurface : p.footerBg,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(8),
                        ),
                        border: Border(
                          top: BorderSide(
                            color: selected
                                ? (isActive
                                      ? p.primaryAccent
                                      : p.semiHighlightedText)
                                : p.dividerColor,
                            width: selected ? 2.8 : 1.0,
                          ),
                          left: BorderSide(
                            color: selected
                                ? (isActive
                                      ? p.primaryAccent
                                      : p.semiHighlightedText)
                                : p.dividerColor,
                            width: 1,
                          ),
                          right: BorderSide(
                            color: selected
                                ? (isActive
                                      ? p.primaryAccent
                                      : p.semiHighlightedText)
                                : p.dividerColor,
                            width: 1,
                          ),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4.5,
                              vertical: 1.5,
                            ),
                            decoration: BoxDecoration(
                              color: selected && isActive
                                  ? p.primaryAccent
                                  : p.paneBgOdd,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '${idx + 1}',
                              style: TextStyle(
                                color: selected && isActive
                                    ? p.cursorActiveText
                                    : p.mutedText,
                                fontSize: 10,
                                fontFamily: 'Menlo',
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Icon(
                            tabIcon,
                            size: 13.5,
                            color: selected ? p.dirIcon : p.mutedText,
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Flexible(
                                      child: Text(
                                        t.title,
                                        style: TextStyle(
                                          color: selected
                                              ? p.fileImportantText
                                              : p.semiHighlightedText,
                                          fontSize: 12,
                                          fontWeight: selected
                                              ? FontWeight.w800
                                              : FontWeight.w600,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 5),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 4.5,
                                        vertical: 0.5,
                                      ),
                                      decoration: BoxDecoration(
                                        color: p.paneBgOdd,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        '${t.itemCount}',
                                        style: TextStyle(
                                          color: selected
                                              ? p.primaryAccent
                                              : p.mutedText,
                                          fontSize: 9.5,
                                          fontFamily: 'Menlo',
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                Text(
                                  t.parentContextLabel,
                                  style: TextStyle(
                                    color: p.mutedText,
                                    fontSize: 9.5,
                                    fontFamily: 'Menlo',
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          if (tabs.length > 1) ...[
                            const SizedBox(width: 6),
                            GestureDetector(
                              onTap: () => controller.closeTab(side, idx),
                              child: Icon(
                                CupertinoIcons.xmark,
                                size: 10.5,
                                color: p.mutedText,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          CupertinoButton(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            minimumSize: const Size(28, 28),
            onPressed: () => controller.addNewTab(side: side),
            child: Icon(
              CupertinoIcons.plus_circle_fill,
              size: 15,
              color: p.primaryAccent,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPathBar(TcThemePalette p, PaneSummaryModel summary) {
    final segments = tab.displayPath
        .split('/')
        .where((s) => s.isNotEmpty)
        .toList();
    final sideLabel = side == PaneSide.left ? 'LEFT' : 'RIGHT';

    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: isActive ? p.headerBg : p.footerBg,
        border: Border(bottom: BorderSide(color: p.dividerColor, width: 1)),
      ),
      child: Row(
        children: [
          // Explicit Active/Inactive Pane Identity Badge
          Container(
            margin: const EdgeInsets.only(right: 6),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: isActive ? p.primaryAccent : p.paneBgOdd,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: isActive ? p.primaryAccent : p.dividerColor,
                width: 1,
              ),
            ),
            child: Text(
              isActive ? '● $sideLabel' : '○ $sideLabel',
              style: TextStyle(
                color: isActive ? p.cursorActiveText : p.mutedText,
                fontSize: 10,
                fontFamily: 'Menlo',
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
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
          if (tab.isInsideArchive)
            GestureDetector(
              onTap: () {
                controller.setActiveSide(side);
                if (tab.archiveFilePath != null) {
                  final host = tab.archiveFilePath!;
                  final parentDir = host.substring(0, host.lastIndexOf('/'));
                  final name = host.split('/').last;
                  tab.archiveFilePath = null;
                  tab.archiveMountDir = null;
                  controller.navigateToPath(
                    parentDir.isEmpty ? '/' : parentDir,
                    side: side,
                    selectChildName: name,
                  );
                }
              },
              child: Container(
                margin: const EdgeInsets.only(right: 6),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: p.selectedRowBg,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: p.selectedText, width: 1),
                ),
                child: Text(
                  '📦 Exit ZIP',
                  style: TextStyle(
                    color: p.selectedText,
                    fontSize: 10.5,
                    fontFamily: 'Menlo',
                    fontWeight: FontWeight.w800,
                  ),
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
            onTap: () => controller.startInlineRename(side: side),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: p.paneBgOdd,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: p.dividerColor,
                  width: 1,
                ),
              ),
              child: Text(
                'F2 Rename',
                style: TextStyle(
                  color: p.fileImportantText,
                  fontSize: 10.5,
                  fontFamily: 'Menlo',
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 5),
          GestureDetector(
            onTap: () => controller.openFavoritesHotlist(side: side),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: controller.isPathPinned(summary.currentPath)
                    ? p.selectedRowBg
                    : p.paneBgOdd,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: controller.isPathPinned(summary.currentPath)
                      ? p.selectedText
                      : p.primaryAccent.withValues(alpha: 0.45),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    controller.isPathPinned(summary.currentPath)
                        ? CupertinoIcons.star_fill
                        : CupertinoIcons.star,
                    size: 11.5,
                    color: controller.isPathPinned(summary.currentPath)
                        ? p.selectedText
                        : p.primaryAccent,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Favs ▾',
                    style: TextStyle(
                      color: controller.isPathPinned(summary.currentPath)
                          ? p.selectedText
                          : p.primaryAccent,
                      fontSize: 10.5,
                      fontFamily: 'Menlo',
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 5),
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
                CupertinoIcons.compass,
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
          padding: const EdgeInsets.symmetric(horizontal: 10),
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
      height: 25,
      decoration: BoxDecoration(
        color: p.headerBg,
        border: Border(bottom: BorderSide(color: p.dividerColor, width: 1)),
      ),
      child: Row(
        children: [
          headerCell('Name', SortField.name, flex: 5),
          headerCell('Type', SortField.extension, width: 74),
          headerCell(
            'Size',
            SortField.size,
            width: 96,
            alignment: Alignment.centerRight,
          ),
          headerCell('Modified', SortField.modified, width: 138),
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
        final isRenaming = controller.isRowRenaming(side, index);
        final highlightQuery =
            (isActive && controller.typeAheadQuery.isNotEmpty)
            ? controller.typeAheadQuery
            : summary.filterQuery;

        return _MacosFileRow(
          controller: controller,
          side: side,
          palette: p,
          entry: entry,
          index: index,
          isCursor: isCursor,
          isPaneActive: isActive,
          isRenaming: isRenaming,
          highlightQuery: highlightQuery,
          onTap: () {
            if (controller.isInlineRenaming && !isRenaming) {
              controller.commitInlineRename();
            }
            controller.setCursor(side, index, ensureVisible: false);
          },
          onDoubleTap: () {
            if (isRenaming) return;
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
        ? '★ Selected: ${formatBytes(summary.selectedBytes)} in ${summary.selectedFiles} file(s), ${summary.selectedDirs} folder(s)'
        : '${summary.totalDirs} folder(s), ${summary.totalFiles} file(s) (${formatBytes(summary.totalBytes)})';

    return Container(
      height: 25,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: p.footerBg,
        border: Border(top: BorderSide(color: p.dividerColor, width: 1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              text,
              style: TextStyle(
                color: hasSel ? p.selectedText : p.semiHighlightedText,
                fontSize: 11.5,
                fontWeight: hasSel ? FontWeight.w700 : FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            'F2 / ⇧F6: Rename',
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

class _MacosFileRow extends StatelessWidget {
  final CommanderController controller;
  final PaneSide side;
  final TcThemePalette palette;
  final DirEntryModel entry;
  final int index;
  final bool isCursor;
  final bool isPaneActive;
  final bool isRenaming;
  final String highlightQuery;
  final VoidCallback onTap;
  final VoidCallback onDoubleTap;
  final GestureTapDownCallback onSecondaryTapDown;

  const _MacosFileRow({
    required this.controller,
    required this.side,
    required this.palette,
    required this.entry,
    required this.index,
    required this.isCursor,
    required this.isPaneActive,
    required this.isRenaming,
    required this.highlightQuery,
    required this.onTap,
    required this.onDoubleTap,
    required this.onSecondaryTapDown,
  });

  @override
  Widget build(BuildContext context) {
    final activeCur = isCursor && isPaneActive;

    Color bgColor;
    if (isRenaming) {
      bgColor = palette.selectedRowBg;
    } else if (activeCur) {
      bgColor = palette.cursorActiveBg;
    } else if (isCursor && !isPaneActive) {
      bgColor = palette.cursorInactiveBg;
    } else if (entry.selected) {
      bgColor = palette.selectedRowBg;
    } else {
      bgColor = index.isEven ? palette.paneBgEven : palette.paneBgOdd;
    }

    final nameColor = palette.resolveEntryNameColor(
      entry,
      isActiveCursor: activeCur && !isRenaming,
    );
    final extColor = palette.resolveExtColor(
      entry,
      isActiveCursor: activeCur && !isRenaming,
    );
    final sizeColor = palette.resolveSizeColor(
      entry,
      isActiveCursor: activeCur && !isRenaming,
    );
    final metaColor = (activeCur && !isRenaming)
        ? palette.cursorActiveText.withValues(alpha: 0.82)
        : entry.selected
        ? palette.selectedText.withValues(alpha: 0.85)
        : palette.mutedText;

    final iconData = entry.isParent
        ? CupertinoIcons.arrow_up_left_square_fill
        : entry.isAppBundle
        ? CupertinoIcons.app_badge_fill
        : entry.isDir
        ? CupertinoIcons.folder_fill
        : entry.isArchive
        ? CupertinoIcons.archivebox_fill
        : entry.isDiskImage
        ? CupertinoIcons.lessthan_circle_fill
        : entry.isExecutableScript
        ? CupertinoIcons.chevron_right_square_fill
        : entry.isSymlink
        ? CupertinoIcons.link
        : CupertinoIcons.doc_text_fill;

    final iconColor = (activeCur && !isRenaming)
        ? palette.cursorActiveText
        : entry.selected
        ? palette.selectedText
        : entry.isDir
        ? palette.dirIcon
        : nameColor.withValues(alpha: 0.9);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      onDoubleTap: onDoubleTap,
      onSecondaryTapDown: onSecondaryTapDown,
      child: Container(
        decoration: BoxDecoration(
          color: bgColor,
          border: (activeCur || isRenaming)
              ? Border(
                  left: BorderSide(
                    color: isRenaming
                        ? palette.selectedText
                        : palette.cursorActiveBorder,
                    width: 3.5,
                  ),
                )
              : null,
        ),
        padding: EdgeInsets.only(
          left: (activeCur || isRenaming) ? 6.5 : 10,
          right: 10,
        ),
        child: Row(
          children: [
            Expanded(
              flex: 5,
              child: isRenaming
                  ? _buildInlineRenameEditor(iconData)
                  : Row(
                      children: [
                        Icon(iconData, size: 15, color: iconColor),
                        const SizedBox(width: 8),
                        Expanded(
                          child: buildHighlightedNameText(
                            displayText: entry.isDir
                                ? entry.name
                                : entry.stem,
                            extSuffix: (!entry.isDir && !entry.isParent)
                                ? entry.ext
                                : '',
                            extColor: extColor,
                            query: entry.isParent ? '' : highlightQuery,
                            palette: palette,
                            isActiveCursor: activeCur,
                            baseStyle: TextStyle(
                              color: nameColor,
                              fontSize: 12.5,
                              fontWeight:
                                  entry.isDir || entry.selected || activeCur
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                            ),
                          ),
                        ),
                        if (activeCur && !entry.isParent) ...[
                          const SizedBox(width: 6),
                          GestureDetector(
                            onTap: () => controller.startInlineRename(
                              side: side,
                              rowIndex: index,
                            ),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 5.5,
                                vertical: 1.5,
                              ),
                              decoration: BoxDecoration(
                                color: palette.cursorActiveText.withValues(
                                  alpha: 0.18,
                                ),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '✎ Rename',
                                style: TextStyle(
                                  color: palette.cursorActiveText,
                                  fontSize: 10,
                                  fontFamily: 'Menlo',
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
            ),
            SizedBox(
              width: 74,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 1.5,
                  ),
                  decoration: BoxDecoration(
                    color: (activeCur && !isRenaming)
                        ? palette.cursorActiveText.withValues(alpha: 0.16)
                        : palette.headerBg,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    entry.typeBadge,
                    style: TextStyle(
                      color: extColor,
                      fontSize: 10,
                      fontFamily: 'Menlo',
                      fontWeight: FontWeight.w700,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ),
            SizedBox(
              width: 96,
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
              width: 138,
              child: Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Text(
                  entry.displayDate,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    color: metaColor,
                    fontSize: 11.5,
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

  Widget _buildInlineRenameEditor(IconData iconData) {
    return Row(
      children: [
        Icon(iconData, size: 15, color: palette.selectedText),
        const SizedBox(width: 6),
        Expanded(
          child: SizedBox(
            height: 23,
            child: CupertinoTextField(
              controller: controller.inlineRenameController,
              focusNode: controller.inlineRenameFocusNode,
              autofocus: true,
              style: TextStyle(
                color: palette.fileImportantText,
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: palette.paneBgEven,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: palette.primaryAccent, width: 1.5),
              ),
              onSubmitted: (_) => controller.commitInlineRename(),
            ),
          ),
        ),
        const SizedBox(width: 5),
        GestureDetector(
          onTap: controller.commitInlineRename,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
            decoration: BoxDecoration(
              color: palette.primaryAccent,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '↵ Save',
              style: TextStyle(
                color: palette.cursorActiveText,
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
        const SizedBox(width: 4),
        GestureDetector(
          onTap: controller.cancelInlineRename,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
            decoration: BoxDecoration(
              color: palette.headerBg,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: palette.dividerColor, width: 1),
            ),
            child: Text(
              'Esc',
              style: TextStyle(
                color: palette.mutedText,
                fontSize: 10,
                fontFamily: 'Menlo',
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
