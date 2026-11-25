import 'package:flutter/material.dart';
import '../../core/models.dart';
import '../../core/theme_palette.dart';
import '../../state/commander_controller.dart';
import '../common/file_search_modal.dart';

class MaterialPaneView extends StatelessWidget {
  final CommanderController controller;
  final PaneSide side;

  const MaterialPaneView({
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

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => controller.setActiveSide(side),
      child: Card(
        margin: const EdgeInsets.all(5),
        elevation: isActive ? 6 : 1,
        color: p.paneBgEven,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(
            color: isActive ? p.activeBorder : p.inactiveBorder,
            width: isActive ? 2.0 : 1.0,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildMaterialTabBar(context, p),
            _buildMaterialPathHeader(context, p, summary),
            _buildMaterialColumnHeaders(context, p, summary),
            Expanded(child: _buildMaterialFileList(context, p, summary)),
            if (isActive && controller.typeAheadQuery.isNotEmpty)
              TypeAheadJumpBar(controller: controller),
            if (isActive &&
                (controller.filterBarVisible ||
                    summary.filterQuery.isNotEmpty))
              _buildMaterialFilterBar(context, p, summary),
            _buildMaterialFooter(context, p, summary),
          ],
        ),
      ),
    );
  }

  IconData _iconForTabPath(String path, bool isArchive) {
    if (isArchive) return Icons.folder_zip_rounded;
    final lower = path.toLowerCase();
    if (lower.endsWith('/downloads')) return Icons.download_rounded;
    if (lower.endsWith('/desktop')) return Icons.desktop_mac_rounded;
    if (lower.endsWith('/documents')) return Icons.description_rounded;
    if (lower == '/applications') return Icons.apps_rounded;
    if (lower.startsWith('/volumes')) return Icons.storage_rounded;
    if (lower.split('/').where((s) => s.isNotEmpty).length <= 2) {
      return Icons.home_rounded;
    }
    return Icons.folder_rounded;
  }

  /// Design B: 2-Line Context Tabs (Folder Name + Item Count on top, Parent Path below)
  Widget _buildMaterialTabBar(BuildContext context, TcThemePalette p) {
    final tabs = controller.tabsFor(side);
    final activeIdx = controller.activeTabIndexFor(side);
    final activeSurface = isActive ? p.headerBg : p.paneBgEven;

    return Container(
      height: 46,
      padding: const EdgeInsets.only(left: 6, right: 4, top: 4),
      color: p.windowBg,
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

                return Opacity(
                  opacity: selected ? 1.0 : 0.68,
                  child: InkWell(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(10),
                    ),
                    onTap: () => controller.selectTab(side, idx),
                    child: Container(
                      constraints: const BoxConstraints(
                        minWidth: 140,
                        maxWidth: 240,
                      ),
                      margin: const EdgeInsets.only(right: 4),
                      decoration: BoxDecoration(
                        color: selected ? activeSurface : p.footerBg,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(10),
                        ),
                        border: Border(
                          top: BorderSide(color: p.dividerColor, width: 1),
                          left: BorderSide(color: p.dividerColor, width: 1),
                          right: BorderSide(color: p.dividerColor, width: 1),
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(9),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Container(
                              height: 2.5,
                              color: selected
                                  ? (isActive
                                        ? p.primaryAccent
                                        : p.semiHighlightedText)
                                  : Colors.transparent,
                            ),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 5,
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
                                          fontFamily: 'Menlo',
                                          fontSize: 10,
                                          fontWeight: FontWeight.w500,
                                          color: selected && isActive
                                              ? p.cursorActiveText
                                              : p.mutedText,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Icon(
                                      tabIcon,
                                      size: 15,
                                      color: selected ? p.dirIcon : p.mutedText,
                                    ),
                                    const SizedBox(width: 6),
                                    Flexible(
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Flexible(
                                                child: Text(
                                                  t.title,
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: selected
                                                        ? FontWeight.w600
                                                        : FontWeight.w400,
                                                    color: selected
                                                        ? p.fileImportantText
                                                        : p.semiHighlightedText,
                                                  ),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                              const SizedBox(width: 5),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 5,
                                                      vertical: 0.5,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: p.paneBgOdd,
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                ),
                                                child: Text(
                                                  '${t.itemCount}',
                                                  style: TextStyle(
                                                    fontFamily: 'Menlo',
                                                    fontSize: 9.5,
                                                    fontWeight: FontWeight.w500,
                                                    color: selected
                                                        ? p.primaryAccent
                                                        : p.mutedText,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          Text(
                                            t.parentContextLabel,
                                            style: TextStyle(
                                              fontFamily: 'Menlo',
                                              fontSize: 9.5,
                                              fontWeight: FontWeight.w400,
                                              color: p.mutedText,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (tabs.length > 1) ...[
                                      const SizedBox(width: 6),
                                      InkWell(
                                        onTap: () =>
                                            controller.closeTab(side, idx),
                                        child: Icon(
                                          Icons.close_rounded,
                                          size: 13,
                                          color: p.mutedText,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          IconButton(
            tooltip: 'New Tab (Cmd+T)',
            visualDensity: VisualDensity.compact,
            icon: Icon(
              Icons.add_circle_rounded,
              size: 17,
              color: p.primaryAccent,
            ),
            onPressed: () => controller.addNewTab(side: side),
          ),
        ],
      ),
    );
  }

  Widget _buildMaterialPathHeader(
    BuildContext context,
    TcThemePalette p,
    PaneSummaryModel summary,
  ) {
    final segments = tab.displayPath
        .split('/')
        .where((s) => s.isNotEmpty)
        .toList();
    final sideLabel = side == PaneSide.left ? 'LEFT' : 'RIGHT';

    return Container(
      height: 34,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: isActive ? p.headerBg : p.footerBg,
        border: Border(bottom: BorderSide(color: p.dividerColor, width: 1)),
      ),
      child: Row(
        children: [
          Container(
            margin: const EdgeInsets.only(right: 6),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: isActive ? p.primaryAccent : p.paneBgOdd,
              borderRadius: BorderRadius.circular(5),
              border: Border.all(
                color: isActive ? p.primaryAccent : p.dividerColor,
                width: 1,
              ),
            ),
            child: Text(
              isActive ? '● $sideLabel' : '○ $sideLabel',
              style: TextStyle(
                fontFamily: 'Menlo',
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: isActive ? p.cursorActiveText : p.mutedText,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Parent Directory (Backspace)',
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
            icon: Icon(
              Icons.drive_folder_upload_rounded,
              size: 16,
              color: p.primaryAccent,
            ),
            onPressed: () {
              controller.setActiveSide(side);
              controller.navigateUp();
            },
          ),
          const SizedBox(width: 4),
          if (tab.isInsideArchive)
            InkWell(
              borderRadius: BorderRadius.circular(6),
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
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: p.selectedText, width: 1),
                ),
                child: Text(
                  '📦 Exit ZIP',
                  style: TextStyle(
                    fontFamily: 'Menlo',
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    color: p.selectedText,
                  ),
                ),
              ),
            ),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  InkWell(
                    borderRadius: BorderRadius.circular(6),
                    onTap: () => controller.navigateToPath('/', side: side),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: p.paneBgOdd,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '/',
                        style: TextStyle(
                          fontFamily: 'Menlo',
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          color: p.primaryAccent,
                        ),
                      ),
                    ),
                  ),
                  for (int i = 0; i < segments.length; i++) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: Icon(
                        Icons.chevron_right_rounded,
                        size: 14,
                        color: p.mutedText,
                      ),
                    ),
                    InkWell(
                      borderRadius: BorderRadius.circular(6),
                      onTap: () {
                        final targetPath =
                            '/${segments.take(i + 1).join('/')}';
                        controller.navigateToPath(targetPath, side: side);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: i == segments.length - 1 && isActive
                              ? p.primaryAccent
                              : p.paneBgOdd,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          segments[i],
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: i == segments.length - 1
                                ? FontWeight.w500
                                : FontWeight.w400,
                            color: i == segments.length - 1 && isActive
                                ? p.cursorActiveText
                                : p.semiHighlightedText,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(width: 4),
          InkWell(
            borderRadius: BorderRadius.circular(6),
            onTap: () => controller.startInlineRename(side: side),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: p.paneBgOdd,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: p.dividerColor, width: 1),
              ),
              child: Text(
                'F2 Rename',
                style: TextStyle(
                  fontFamily: 'Menlo',
                  fontSize: 10.5,
                  fontWeight: FontWeight.w500,
                  color: p.fileImportantText,
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          InkWell(
            borderRadius: BorderRadius.circular(6),
            onTap: () => controller.openFavoritesHotlist(side: side),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: controller.isPathPinned(summary.currentPath)
                    ? p.selectedRowBg
                    : p.paneBgOdd,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: controller.isPathPinned(summary.currentPath)
                      ? p.selectedText
                      : p.primaryAccent.withValues(alpha: 0.5),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    controller.isPathPinned(summary.currentPath)
                        ? Icons.star_rounded
                        : Icons.star_border_rounded,
                    size: 14,
                    color: controller.isPathPinned(summary.currentPath)
                        ? p.selectedText
                        : p.primaryAccent,
                  ),
                  const SizedBox(width: 3),
                  Text(
                    'Favs ▾',
                    style: TextStyle(
                      fontFamily: 'Menlo',
                      fontSize: 10.5,
                      fontWeight: FontWeight.w500,
                      color: controller.isPathPinned(summary.currentPath)
                          ? p.selectedText
                          : p.primaryAccent,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 4),
          IconButton(
            tooltip: 'Go to Path (Cmd+G)',
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
            icon: Icon(
              Icons.edit_location_alt_outlined,
              size: 15,
              color: p.primaryAccent,
            ),
            onPressed: () {
              controller.setActiveSide(side);
              controller.openGotoPathDialog();
            },
          ),
          const SizedBox(width: 6),
          Text(
            '${formatBytes(summary.volumeFreeBytes)} free',
            style: TextStyle(
              fontFamily: 'Menlo',
              fontSize: 11,
              fontWeight: FontWeight.w400,
              color: p.semiHighlightedText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMaterialColumnHeaders(
    BuildContext context,
    TcThemePalette p,
    PaneSummaryModel summary,
  ) {
    Widget colHeader(
      String label,
      SortField field, {
      int flex = 1,
      double? width,
      Alignment alignment = Alignment.centerLeft,
    }) {
      final sorted = summary.sortField == field;
      final icon = sorted
          ? (summary.sortAscending
                ? Icons.arrow_upward_rounded
                : Icons.arrow_downward_rounded)
          : null;

      final cell = InkWell(
        onTap: () => controller.toggleSort(side, field),
        child: Container(
          alignment: alignment,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: sorted ? FontWeight.w600 : FontWeight.w400,
                  color: sorted ? p.primaryAccent : p.semiHighlightedText,
                ),
              ),
              if (icon != null) ...[
                const SizedBox(width: 3),
                Icon(icon, size: 12, color: p.primaryAccent),
              ],
            ],
          ),
        ),
      );

      if (width != null) return SizedBox(width: width, child: cell);
      return Expanded(flex: flex, child: cell);
    }

    return Container(
      height: 26,
      decoration: BoxDecoration(
        color: p.headerBg,
        border: Border(bottom: BorderSide(color: p.dividerColor, width: 1)),
      ),
      child: Row(
        children: [
          colHeader('Name', SortField.name, flex: 5),
          colHeader(
            'Size',
            SortField.size,
            width: 90,
            alignment: Alignment.centerRight,
          ),
          colHeader(
            'Modified',
            SortField.modified,
            width: 134,
            alignment: Alignment.centerRight,
          ),
        ],
      ),
    );
  }

  Widget _buildMaterialFileList(
    BuildContext context,
    TcThemePalette p,
    PaneSummaryModel summary,
  ) {
    if (summary.errorMessage != null) {
      return Center(
        child: Text(
          summary.errorMessage!,
          style: TextStyle(color: p.dangerColor),
        ),
      );
    }

    return ListView.builder(
      controller: tab.scrollController,
      itemExtent: CommanderController.rowExtent,
      itemCount: summary.totalRows,
      itemBuilder: (context, index) {
        final entry = controller.getRow(tab, index);
        if (entry == null) return const SizedBox.shrink();
        final isCursor = index == tab.cursorIndex;
        final isRenaming = controller.isRowRenaming(side, index);
        final activeCur = isCursor && isActive && !isRenaming;

        Color rowBg;
        if (isRenaming) {
          rowBg = p.selectedRowBg;
        } else if (activeCur) {
          rowBg = p.rowCursorBg;
        } else if (isCursor && !isActive) {
          rowBg = p.cursorInactiveBg.withValues(alpha: 0.45);
        } else if (entry.selected) {
          rowBg = p.selectedRowBg;
        } else {
          rowBg = index.isEven ? p.paneBgEven : p.paneBgOdd;
        }

        final nameColor = p.resolveEntryNameColor(
          entry,
          isActiveCursor: activeCur,
        );
        final extColor = p.resolveExtColor(entry, isActiveCursor: activeCur);
        final sizeColor = p.resolveSizeColor(entry, isActiveCursor: activeCur);
        final metaColor = entry.selected
            ? p.selectedText.withValues(alpha: 0.85)
            : p.mutedText;

        final icon = entry.isParent
            ? Icons.subdirectory_arrow_left_rounded
            : entry.isAppBundle
            ? Icons.apps_rounded
            : entry.isDir
            ? Icons.folder_rounded
            : entry.isArchive
            ? Icons.folder_zip_rounded
            : entry.isDiskImage
            ? Icons.album_rounded
            : entry.isExecutableScript
            ? Icons.terminal_rounded
            : entry.isSymlink
            ? Icons.link_rounded
            : Icons.insert_drive_file_rounded;

        final iconColor = p.resolveEntryIconColor(entry);

        final highlightQuery =
            (isActive && controller.typeAheadQuery.isNotEmpty)
            ? controller.typeAheadQuery
            : summary.filterQuery;

        return InkWell(
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
          child: Ink(
            decoration: BoxDecoration(
              color: rowBg,
              border: (activeCur || isRenaming)
                  ? Border(
                      left: BorderSide(
                        color: isRenaming
                            ? p.selectedText
                            : p.primaryAccent,
                        width: 4.0,
                      ),
                    )
                  : null,
            ),
            padding: EdgeInsets.only(
              left: (activeCur || isRenaming) ? 6.0 : 10,
              right: 10,
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 5,
                  child: isRenaming
                      ? _buildMaterialInlineRenameEditor(p, icon)
                      : Row(
                          children: [
                            Icon(icon, size: 16, color: iconColor),
                            const SizedBox(width: 8),
                            Flexible(
                              child: buildHighlightedNameText(
                                displayText: entry.isDir
                                    ? entry.name
                                    : entry.stem,
                                extSuffix: (!entry.isDir && !entry.isParent)
                                    ? entry.ext
                                    : '',
                                extColor: extColor,
                                query: entry.isParent ? '' : highlightQuery,
                                palette: p,
                                isActiveCursor: activeCur,
                                baseStyle: TextStyle(
                                  fontSize: 12.5,
                                  color: nameColor,
                                  fontWeight:
                                      entry.isDir ||
                                          entry.selected ||
                                          activeCur
                                      ? FontWeight.w500
                                      : FontWeight.w400,
                                ),
                              ),
                            ),
                            if (!entry.isParent) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 5.5,
                                  vertical: 1,
                                ),
                                decoration: BoxDecoration(
                                  color: p.footerBg,
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: p.dividerColor,
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  entry.typeBadge,
                                  style: TextStyle(
                                    fontFamily: 'Menlo',
                                    fontSize: 9.5,
                                    color: p.mutedText,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ),
                            ],
                            if (activeCur && !entry.isParent) ...[
                              const SizedBox(width: 6),
                              InkWell(
                                onTap: () => controller.startInlineRename(
                                  side: side,
                                  rowIndex: index,
                                ),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 1.5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: p.paneBgEven,
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(
                                      color: p.primaryAccent,
                                      width: 1,
                                    ),
                                  ),
                                  child: Text(
                                    '✎ Rename',
                                    style: TextStyle(
                                      fontFamily: 'Menlo',
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w500,
                                      color: p.primaryAccent,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                ),
                SizedBox(
                  width: 90,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Text(
                      entry.displaySize,
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontFamily: 'Menlo',
                        fontSize: 11.5,
                        color: sizeColor,
                        fontWeight: FontWeight.w400,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                SizedBox(
                  width: 134,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Text(
                      entry.displayDate,
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontFamily: 'Menlo',
                        fontSize: 11,
                        color: metaColor,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMaterialInlineRenameEditor(TcThemePalette p, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: p.selectedText),
        const SizedBox(width: 6),
        Expanded(
          child: SizedBox(
            height: 23,
            child: TextField(
              controller: controller.inlineRenameController,
              focusNode: controller.inlineRenameFocusNode,
              autofocus: true,
              style: TextStyle(
                color: p.fileImportantText,
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
              ),
              decoration: InputDecoration(
                isDense: true,
                filled: true,
                fillColor: p.paneBgEven,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 3,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                  borderSide: BorderSide(color: p.primaryAccent, width: 1.5),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                  borderSide: BorderSide(color: p.primaryAccent, width: 1.5),
                ),
              ),
              onSubmitted: (_) => controller.commitInlineRename(),
            ),
          ),
        ),
        const SizedBox(width: 5),
        InkWell(
          onTap: controller.commitInlineRename,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
            decoration: BoxDecoration(
              color: p.primaryAccent,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '↵ Save',
              style: TextStyle(
                color: p.cursorActiveText,
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
        const SizedBox(width: 4),
        InkWell(
          onTap: controller.cancelInlineRename,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
            decoration: BoxDecoration(
              color: p.headerBg,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: p.dividerColor, width: 1),
            ),
            child: Text(
              'Esc',
              style: TextStyle(
                color: p.mutedText,
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

  Widget _buildMaterialFilterBar(
    BuildContext context,
    TcThemePalette p,
    PaneSummaryModel summary,
  ) {
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: p.headerBg,
        border: Border(top: BorderSide(color: p.primaryAccent, width: 1.5)),
      ),
      child: Row(
        children: [
          Icon(Icons.filter_list_rounded, size: 15, color: p.primaryAccent),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              autofocus: true,
              style: TextStyle(
                fontFamily: 'Menlo',
                fontSize: 12,
                color: p.fileImportantText,
              ),
              decoration: InputDecoration(
                isDense: true,
                hintText: 'Quick filter files (Esc to clear)...',
                hintStyle: TextStyle(fontSize: 12, color: p.mutedText),
                border: InputBorder.none,
              ),
              onChanged: controller.setQuickFilter,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMaterialFooter(
    BuildContext context,
    TcThemePalette p,
    PaneSummaryModel summary,
  ) {
    final hasSel = summary.selectedFiles > 0 || summary.selectedDirs > 0;
    final text = hasSel
        ? '★ Selected: ${formatBytes(summary.selectedBytes)} in ${summary.selectedFiles} file(s), ${summary.selectedDirs} folder(s)'
        : '${summary.totalDirs} folder(s), ${summary.totalFiles} file(s) (${formatBytes(summary.totalBytes)})';

    return Container(
      height: 26,
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
                fontSize: 11.5,
                fontWeight: hasSel ? FontWeight.w700 : FontWeight.w500,
                color: hasSel ? p.selectedText : p.semiHighlightedText,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            'F2 / ⇧F6: Rename',
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
