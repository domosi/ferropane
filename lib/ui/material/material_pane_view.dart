import 'package:flutter/material.dart';
import '../../core/models.dart';
import '../../core/theme_palette.dart';
import '../../state/commander_controller.dart';

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

  Widget _buildMaterialTabBar(BuildContext context, TcThemePalette p) {
    final tabs = controller.tabsFor(side);
    final activeIdx = controller.activeTabIndexFor(side);

    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      color: p.footerBg,
      child: Row(
        children: [
          Expanded(
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: tabs.length,
              separatorBuilder: (_, _) => const SizedBox(width: 6),
              itemBuilder: (context, idx) {
                final t = tabs[idx];
                final selected = idx == activeIdx;
                return InputChip(
                  selected: selected,
                  showCheckmark: false,
                  selectedColor: p.headerBg,
                  backgroundColor: p.paneBgEven,
                  side: BorderSide(
                    color: selected && isActive
                        ? p.primaryAccent
                        : p.dividerColor,
                    width: selected ? 1.4 : 1.0,
                  ),
                  avatar: Icon(
                    Icons.folder_rounded,
                    size: 15,
                    color: selected ? p.dirIcon : p.mutedText,
                  ),
                  label: Text(
                    t.title,
                    style: TextStyle(
                      fontSize: 12,
                      color: selected ? p.fileImportantText : p.mutedText,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                  visualDensity: VisualDensity.compact,
                  onPressed: () => controller.selectTab(side, idx),
                  onDeleted: tabs.length > 1
                      ? () => controller.closeTab(side, idx)
                      : null,
                );
              },
            ),
          ),
          IconButton(
            tooltip: 'New Tab (Cmd+T)',
            visualDensity: VisualDensity.compact,
            icon: Icon(Icons.add_rounded, size: 18, color: p.primaryAccent),
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
    final usedRatio = summary.volumeTotalBytes > 0
        ? ((summary.volumeTotalBytes - summary.volumeFreeBytes) /
                  summary.volumeTotalBytes)
              .clamp(0.0, 1.0)
        : 0.0;

    return Container(
      height: 34,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: isActive ? p.headerBg : p.footerBg,
        border: Border(bottom: BorderSide(color: p.dividerColor, width: 1)),
      ),
      child: Row(
        children: [
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
                            fontFamily: 'Menlo',
                            fontSize: 11.5,
                            fontWeight: i == segments.length - 1
                                ? FontWeight.w700
                                : FontWeight.w500,
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
                      fontWeight: FontWeight.w700,
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
            tooltip: 'Edit Path (Cmd+G)',
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
          SizedBox(
            width: 52,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: usedRatio,
                minHeight: 5,
                color: p.primaryAccent,
                backgroundColor: p.dividerColor,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${formatBytes(summary.volumeFreeBytes)} free',
            style: TextStyle(
              fontFamily: 'Menlo',
              fontSize: 11,
              fontWeight: FontWeight.w600,
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
    Widget headerCell(
      String label,
      SortField field, {
      int flex = 1,
      double? width,
      Alignment alignment = Alignment.centerLeft,
    }) {
      final isSorted = summary.sortField == field;
      final icon = isSorted
          ? (summary.sortAscending
                ? Icons.arrow_upward_rounded
                : Icons.arrow_downward_rounded)
          : null;

      final child = InkWell(
        onTap: () => controller.toggleSort(side, field),
        child: Container(
          alignment: alignment,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: isSorted ? FontWeight.w800 : FontWeight.w600,
                  color: isSorted ? p.primaryAccent : p.semiHighlightedText,
                ),
              ),
              if (icon != null) ...[
                const SizedBox(width: 3),
                Icon(icon, size: 13, color: p.primaryAccent),
              ],
            ],
          ),
        ),
      );

      if (width != null) return SizedBox(width: width, child: child);
      return Expanded(flex: flex, child: child);
    }

    return Container(
      height: 26,
      decoration: BoxDecoration(
        color: p.headerBg,
        border: Border(bottom: BorderSide(color: p.dividerColor, width: 1)),
      ),
      child: Row(
        children: [
          headerCell('Name', SortField.name, flex: 5),
          headerCell('Ext', SortField.extension, width: 70),
          headerCell(
            'Size',
            SortField.size,
            width: 96,
            alignment: Alignment.centerRight,
          ),
          headerCell('Modified', SortField.modified, width: 128),
          SizedBox(
            width: 88,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                'Perms',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: p.mutedText,
                ),
              ),
            ),
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
          style: TextStyle(color: p.dangerColor, fontSize: 13),
        ),
      );
    }

    return Material(
      type: MaterialType.transparency,
      child: ListView.builder(
        controller: tab.scrollController,
        itemExtent: CommanderController.rowExtent,
        itemCount: summary.totalRows,
        itemBuilder: (context, index) {
          final entry = controller.getRow(tab, index);
          if (entry == null) return const SizedBox.shrink();
          final isCursor = index == tab.cursorIndex;
          final activeCur = isCursor && isActive;

          Color rowBg;
          if (activeCur) {
            rowBg = p.cursorActiveBg;
          } else if (isCursor && !isActive) {
            rowBg = p.cursorInactiveBg;
          } else if (entry.selected) {
            rowBg = p.selectedRowBg;
          } else {
            rowBg = index.isEven ? p.paneBgEven : p.paneBgOdd;
          }

          // 1. IMPORTANT: Primary Name & Icon Color
          final nameColor = p.resolveEntryNameColor(
            entry,
            isActiveCursor: activeCur,
          );

          // 2. SEMI-HIGHLIGHTED: Extension & Size
          final extColor = p.resolveExtColor(entry, isActiveCursor: activeCur);
          final sizeColor = p.resolveSizeColor(
            entry,
            isActiveCursor: activeCur,
          );

          // 3. LESS IMPORTANT (SUBDUED): Date & Permissions
          final metaColor = activeCur
              ? p.cursorActiveText.withValues(alpha: 0.78)
              : entry.selected
              ? p.selectedText.withValues(alpha: 0.8)
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

          final iconColor = activeCur
              ? p.cursorActiveText
              : entry.selected
              ? p.selectedText
              : entry.isDir
              ? p.dirIcon
              : nameColor.withValues(alpha: 0.85);

          return InkWell(
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
            child: Ink(
              decoration: BoxDecoration(
                color: rowBg,
                border: activeCur
                    ? Border(
                        left: BorderSide(
                          color: p.cursorActiveBorder,
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
                        Icon(icon, size: 15, color: iconColor),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            entry.isDir && !entry.isParent
                                ? '[${entry.name}]'
                                : entry.stem,
                            style: TextStyle(
                              fontFamily: 'Menlo',
                              fontSize: 12,
                              color: nameColor,
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
                    width: 70,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Text(
                        entry.ext,
                        style: TextStyle(
                          fontFamily: 'Menlo',
                          fontSize: 11.5,
                          color: extColor,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
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
                          fontFamily: 'Menlo',
                          fontSize: 11.5,
                          color: sizeColor,
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
                    width: 128,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Text(
                        entry.displayDate,
                        style: TextStyle(
                          fontFamily: 'Menlo',
                          fontSize: 11,
                          color: metaColor,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 88,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Text(
                        entry.permissions,
                        style: TextStyle(
                          fontFamily: 'Menlo',
                          fontSize: 10.5,
                          color: metaColor.withValues(alpha: 0.75),
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
      ),
    );
  }

  Widget _buildMaterialFilterBar(
    BuildContext context,
    TcThemePalette p,
    PaneSummaryModel summary,
  ) {
    return Container(
      height: 34,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: p.headerBg,
        border: Border(top: BorderSide(color: p.primaryAccent, width: 1.5)),
      ),
      child: Row(
        children: [
          Icon(Icons.filter_alt_rounded, size: 15, color: p.primaryAccent),
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
                hintText: 'Quick filter files (Esc to close)...',
                hintStyle: TextStyle(color: p.mutedText, fontSize: 12),
                isDense: true,
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
        ? '★ Selected: ${formatBytes(summary.selectedBytes)} in ${summary.selectedFiles} file(s), ${summary.selectedDirs} dir(s)'
        : '${formatBytes(summary.totalBytes)} in ${summary.totalFiles} file(s), ${summary.totalDirs} dir(s)';

    return Container(
      height: 26,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: p.footerBg,
        border: Border(top: BorderSide(color: p.dividerColor, width: 1)),
      ),
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: TextStyle(
          fontFamily: 'Menlo',
          fontSize: 11,
          fontWeight: hasSel ? FontWeight.w700 : FontWeight.w500,
          color: hasSel ? p.selectedText : p.semiHighlightedText,
        ),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
