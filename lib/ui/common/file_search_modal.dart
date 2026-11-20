import 'package:flutter/cupertino.dart';
import '../../core/models.dart';
import '../../core/theme_palette.dart';
import '../../state/commander_controller.dart';

/// Builds a RichText widget that highlights any prefix or substring match of [query] inside [displayText].
Widget buildHighlightedNameText({
  required String displayText,
  required String query,
  required TextStyle baseStyle,
  required TcThemePalette palette,
  required bool isActiveCursor,
}) {
  final cleanQuery = query.trim().replaceAll('*', '').toLowerCase();
  if (cleanQuery.isEmpty) {
    return Text(
      displayText,
      style: baseStyle,
      overflow: TextOverflow.ellipsis,
    );
  }

  final lowerText = displayText.toLowerCase();
  // Prefer matching right after '[' for directory names like "[ferropane]"
  int matchStart = -1;
  if (lowerText.startsWith('[$cleanQuery')) {
    matchStart = 1;
  } else if (lowerText.startsWith(cleanQuery)) {
    matchStart = 0;
  } else {
    matchStart = lowerText.indexOf(cleanQuery);
  }

  if (matchStart < 0) {
    return Text(
      displayText,
      style: baseStyle,
      overflow: TextOverflow.ellipsis,
    );
  }

  final matchEnd = matchStart + cleanQuery.length;
  final before = displayText.substring(0, matchStart);
  final matched = displayText.substring(matchStart, matchEnd);
  final after = displayText.substring(matchEnd);

  final highlightBg = isActiveCursor
      ? const Color(0xFFFFD60A)
      : palette.selectedText;
  final highlightFg = const Color(0xFF111216);

  return RichText(
    overflow: TextOverflow.ellipsis,
    maxLines: 1,
    text: TextSpan(
      style: baseStyle,
      children: [
        if (before.isNotEmpty) TextSpan(text: before),
        TextSpan(
          text: matched,
          style: baseStyle.copyWith(
            backgroundColor: highlightBg,
            color: highlightFg,
            fontWeight: FontWeight.w900,
          ),
        ),
        if (after.isNotEmpty) TextSpan(text: after),
      ],
    ),
  );
}

/// Compact bar shown at the bottom of the active pane when Type-Ahead Prefix Jump is active.
class TypeAheadJumpBar extends StatelessWidget {
  final CommanderController controller;

  const TypeAheadJumpBar({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final p = controller.palette;
    final q = controller.typeAheadQuery;
    final matches = controller.typeAheadMatchIndices;
    final pos = controller.typeAheadCurrentMatchPos;

    return Container(
      height: 30,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: p.headerBg,
        border: Border(
          top: BorderSide(color: p.selectedText, width: 1.8),
        ),
      ),
      child: Row(
        children: [
          Icon(
            CupertinoIcons.textformat_abc,
            size: 14,
            color: p.selectedText,
          ),
          const SizedBox(width: 6),
          Text(
            'Jump:',
            style: TextStyle(
              color: p.semiHighlightedText,
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: p.selectedText,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              q,
              style: const TextStyle(
                color: Color(0xFF111216),
                fontSize: 12,
                fontFamily: 'Menlo',
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            matches.isEmpty
                ? 'No match in folder'
                : '${pos + 1} / ${matches.length} matches',
            style: TextStyle(
              color: matches.isEmpty ? p.dangerColor : p.fileImportantText,
              fontSize: 11,
              fontFamily: 'Menlo',
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          if (matches.length > 1) ...[
            _pillBtn(
              p: p,
              label: '◀ Prev',
              onTap: () => controller.cycleTypeAheadMatch(-1),
            ),
            const SizedBox(width: 4),
            _pillBtn(
              p: p,
              label: 'Next ▶ (Ctrl+N)',
              onTap: () => controller.cycleTypeAheadMatch(1),
            ),
            const SizedBox(width: 6),
          ],
          _pillBtn(
            p: p,
            label: 'Filter Only (/)',
            onTap: controller.convertTypeAheadToFilter,
          ),
          const SizedBox(width: 6),
          _pillBtn(
            p: p,
            label: 'Search Subfolders (⌘F)',
            accent: true,
            onTap: () => controller.openFileSearch(initialQuery: q),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: controller.clearTypeAhead,
            child: Icon(
              CupertinoIcons.xmark_circle_fill,
              size: 14,
              color: p.mutedText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _pillBtn({
    required TcThemePalette p,
    required String label,
    required VoidCallback onTap,
    bool accent = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: accent
              ? p.primaryAccent.withValues(alpha: 0.2)
              : p.paneBgEven,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: accent ? p.primaryAccent : p.dividerColor,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: accent ? p.primaryAccent : p.fileImportantText,
            fontSize: 10.5,
            fontFamily: 'Menlo',
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

/// Recursive Easy File Search Modal (⌘F / Alt+F7 / Toolbar Search Button).
class FileSearchModal extends StatelessWidget {
  final CommanderController controller;

  const FileSearchModal({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final p = controller.palette;
    final res = controller.searchResult;
    final items = res?.items ?? const [];
    final rootDir = controller.activeTab.summary.currentPath;
    final queryText = controller.searchNameController.text;

    return Container(
      width: 820,
      height: 600,
      decoration: BoxDecoration(
        color: p.toolbarBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: p.primaryAccent, width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0xCC000000),
            blurRadius: 30,
            offset: Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(p, rootDir, res),
          _buildSearchInputs(p),
          Expanded(
            child: items.isEmpty
                ? Center(
                    child: Text(
                      queryText.isEmpty &&
                              controller.searchContentController.text.isEmpty
                          ? 'Type any letters or wildcard (e.g. *.dart, readme) above to search.'
                          : 'No matching files found in $rootDir',
                      style: TextStyle(
                        color: p.mutedText,
                        fontSize: 12.5,
                        fontFamily: 'Menlo',
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      return _buildHitRow(
                        p,
                        items[index],
                        index,
                        queryText,
                      );
                    },
                  ),
          ),
          _buildFooter(p, items.length, res?.scannedCount ?? 0),
        ],
      ),
    );
  }

  Widget _buildHeader(
    TcThemePalette p,
    String rootDir,
    DirSearchResultModel? res,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
      decoration: BoxDecoration(
        color: p.headerBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(10.5)),
        border: Border(bottom: BorderSide(color: p.dividerColor, width: 1)),
      ),
      child: Row(
        children: [
          Icon(
            CupertinoIcons.search_circle_fill,
            size: 18,
            color: p.primaryAccent,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Find Files in $rootDir',
              style: TextStyle(
                color: p.fileImportantText,
                fontSize: 13.5,
                fontWeight: FontWeight.w800,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          GestureDetector(
            onTap: controller.toggleSearchRecursive,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                color: controller.searchRecursive
                    ? p.primaryAccent.withValues(alpha: 0.2)
                    : p.paneBgOdd,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: controller.searchRecursive
                      ? p.primaryAccent
                      : p.dividerColor,
                  width: 1,
                ),
              ),
              child: Text(
                controller.searchRecursive
                    ? '✓ Include Subfolders: ON'
                    : 'Current Folder Only',
                style: TextStyle(
                  color: controller.searchRecursive
                      ? p.primaryAccent
                      : p.mutedText,
                  fontSize: 11,
                  fontFamily: 'Menlo',
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: controller.closeDialog,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
    );
  }

  Widget _buildSearchInputs(TcThemePalette p) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: p.footerBg,
        border: Border(bottom: BorderSide(color: p.dividerColor, width: 1)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 6,
            child: Row(
              children: [
                Text(
                  'Filename:',
                  style: TextStyle(
                    color: p.fileImportantText,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: CupertinoTextField(
                    controller: controller.searchNameController,
                    focusNode: controller.searchNameFocusNode,
                    autofocus: true,
                    placeholder:
                        'Type filename prefix, substring, or *.ext...',
                    placeholderStyle: TextStyle(
                      color: p.mutedText,
                      fontSize: 12,
                      fontFamily: 'Menlo',
                    ),
                    style: TextStyle(
                      color: p.fileImportantText,
                      fontSize: 12.5,
                      fontFamily: 'Menlo',
                      fontWeight: FontWeight.w700,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: p.paneBgEven,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: p.primaryAccent, width: 1.2),
                    ),
                    onChanged: (_) => controller.runFileSearch(),
                    onSubmitted: (_) => controller.jumpToSearchHit(),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            flex: 5,
            child: Row(
              children: [
                Text(
                  'Containing text:',
                  style: TextStyle(
                    color: p.semiHighlightedText,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: CupertinoTextField(
                    controller: controller.searchContentController,
                    placeholder: 'Optional grep inside files...',
                    placeholderStyle: TextStyle(
                      color: p.mutedText,
                      fontSize: 12,
                      fontFamily: 'Menlo',
                    ),
                    style: TextStyle(
                      color: p.fileImportantText,
                      fontSize: 12,
                      fontFamily: 'Menlo',
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: p.paneBgEven,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: p.dividerColor, width: 1),
                    ),
                    onChanged: (_) => controller.runFileSearch(),
                    onSubmitted: (_) => controller.jumpToSearchHit(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHitRow(
    TcThemePalette p,
    SearchHitModel hit,
    int index,
    String queryText,
  ) {
    final isSelected = index == controller.searchSelectedIndex;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        controller.searchSelectedIndex = index;
        controller.jumpToSearchHit(index);
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? p.cursorActiveBg : p.paneBgEven,
          borderRadius: BorderRadius.circular(7),
          border: Border.all(
            color: isSelected ? p.cursorActiveBorder : p.dividerColor,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  hit.isDir
                      ? CupertinoIcons.folder_fill
                      : CupertinoIcons.doc_text_fill,
                  size: 14,
                  color: isSelected
                      ? p.cursorActiveText
                      : hit.isDir
                      ? p.dirIcon
                      : p.primaryAccent,
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 220,
                  child: buildHighlightedNameText(
                    displayText: hit.isDir ? '[${hit.name}]' : hit.name,
                    query: queryText,
                    palette: p,
                    isActiveCursor: isSelected,
                    baseStyle: TextStyle(
                      color: isSelected
                          ? p.cursorActiveText
                          : p.fileImportantText,
                      fontSize: 12,
                      fontFamily: 'Menlo',
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    hit.relPath,
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
                const SizedBox(width: 8),
                SizedBox(
                  width: 72,
                  child: Text(
                    hit.isDir ? '<DIR>' : formatBytes(hit.size),
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      color: isSelected
                          ? p.cursorActiveText
                          : p.semiHighlightedText,
                      fontSize: 11,
                      fontFamily: 'Menlo',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _rowBtn(
                  p: p,
                  isSelected: isSelected,
                  label: 'Go to File ↵',
                  onTap: () => controller.jumpToSearchHit(index),
                ),
                const SizedBox(width: 4),
                _rowBtn(
                  p: p,
                  isSelected: isSelected,
                  label: '⇄ Other',
                  onTap: () => controller.jumpToSearchHit(index, true),
                ),
                if (!hit.isDir) ...[
                  const SizedBox(width: 4),
                  _rowBtn(
                    p: p,
                    isSelected: isSelected,
                    label: 'F3 View',
                    onTap: () => controller.viewSearchHitInLister(index),
                  ),
                ],
              ],
            ),
            if (hit.matchedLine != null && hit.matchedLine!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.only(left: 22),
                child: Text(
                  hit.matchedLine!,
                  style: TextStyle(
                    color: isSelected ? p.cursorActiveText : p.selectedText,
                    fontSize: 11,
                    fontFamily: 'Menlo',
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _rowBtn({
    required TcThemePalette p,
    required bool isSelected,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: isSelected
              ? p.cursorActiveText.withValues(alpha: 0.2)
              : p.headerBg,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: isSelected
                ? p.cursorActiveText.withValues(alpha: 0.5)
                : p.dividerColor,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? p.cursorActiveText : p.primaryAccent,
            fontSize: 10,
            fontFamily: 'Menlo',
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _buildFooter(TcThemePalette p, int matchCount, int scannedCount) {
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
            '[↑/↓] Navigate • [Enter] Go to File & Highlight • [F3] View in Lister • [Esc] Close',
            style: TextStyle(
              color: p.mutedText,
              fontSize: 10.5,
              fontFamily: 'Menlo',
            ),
          ),
          Text(
            '$matchCount result(s) ($scannedCount items scanned in Rust)',
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
