import 'package:flutter/cupertino.dart';
import '../../core/models.dart';
import '../../state/commander_controller.dart';
import '../common/open_with_overlays.dart';

class MacosDialogOverlay extends StatelessWidget {
  final CommanderController controller;

  const MacosDialogOverlay({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    if (controller.activeDialog == ActiveDialog.none) {
      return const SizedBox.shrink();
    }

    return Container(
      color: const Color(0x99000000),
      alignment: Alignment.center,
      child: GestureDetector(
        onTap: () {},
        child: _buildDialogCard(controller),
      ),
    );
  }

  Widget _buildDialogCard(CommanderController ctrl) {
    if (ctrl.activeDialog == ActiveDialog.lister) {
      return _buildListerSheet(ctrl);
    }
    if (ctrl.activeDialog == ActiveDialog.openWithPalette) {
      return OpenWithPaletteCard(controller: ctrl);
    }

    final targets = ctrl.getActionTargetPaths();
    String title = '';
    String subtitle = '';
    String primaryLabel = 'OK (Enter)';
    bool isDestructive = false;
    bool showInput = true;

    switch (ctrl.activeDialog) {
      case ActiveDialog.copyConfirm:
        title = 'F5 — Copy ${targets.length} item(s)';
        subtitle = 'Copy selected item(s) (APFS clonefile/copyfile) to:';
        primaryLabel = 'Copy (Enter)';
        break;
      case ActiveDialog.moveConfirm:
        title = 'F6 — Move / Rename ${targets.length} item(s)';
        subtitle = 'Move or rename selected item(s) to:';
        primaryLabel = 'Move (Enter)';
        break;
      case ActiveDialog.mkdirPrompt:
        title = 'F7 — Create New Folder';
        subtitle = 'In ${ctrl.activeTab.summary.currentPath}:';
        primaryLabel = 'Create (Enter)';
        break;
      case ActiveDialog.deleteConfirm:
        showInput = false;
        isDestructive = true;
        title = ctrl.deleteUseTrash
            ? 'F8 — Move ${targets.length} item(s) to macOS Trash?'
            : 'Shift+F8 — Permanently Delete ${targets.length} item(s)?';
        subtitle = targets.take(4).join('\n') +
            (targets.length > 4 ? '\n...and ${targets.length - 4} more' : '');
        primaryLabel = ctrl.deleteUseTrash
            ? 'Move to Trash (Enter)'
            : 'Delete Forever (Enter)';
        break;
      case ActiveDialog.selectPattern:
        title = 'Select Files by Pattern (+)';
        subtitle = 'Enter wildcard pattern (e.g. *.dart, *.rs, *test*):';
        primaryLabel = 'Select (Enter)';
        break;
      case ActiveDialog.gotoPath:
        title = 'Go to Directory (Cmd+G)';
        subtitle = 'Enter directory path:';
        primaryLabel = 'Open (Enter)';
        break;
      default:
        break;
    }

    return Container(
      width: 480,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF25262B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF42454F), width: 1),
        boxShadow: const [
          BoxShadow(
            color: Color(0xAA000000),
            blurRadius: 24,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFFF2F3F5),
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(
              color: Color(0xFFA6AAB4),
              fontSize: 12,
              fontFamily: 'Menlo',
            ),
          ),
          if (showInput) ...[
            const SizedBox(height: 12),
            CupertinoTextField(
              controller: ctrl.dialogTextController,
              focusNode: ctrl.dialogInputFocusNode,
              autofocus: true,
              style: const TextStyle(
                color: Color(0xFFF2F3F5),
                fontSize: 13,
                fontFamily: 'Menlo',
              ),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF18191C),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFF0A84FF), width: 1),
              ),
              onSubmitted: (_) => ctrl.confirmActiveDialog(),
            ),
          ],
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              CupertinoButton(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                minimumSize: const Size(0, 28),
                color: const Color(0xFF383A42),
                onPressed: ctrl.closeDialog,
                child: const Text(
                  'Cancel (Esc)',
                  style: TextStyle(color: Color(0xFFE0E2E8), fontSize: 12),
                ),
              ),
              const SizedBox(width: 10),
              CupertinoButton(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                minimumSize: const Size(0, 28),
                color: isDestructive
                    ? const Color(0xFFFF453A)
                    : const Color(0xFF0A84FF),
                onPressed: ctrl.confirmActiveDialog,
                child: Text(
                  primaryLabel,
                  style: const TextStyle(
                    color: CupertinoColors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildListerSheet(CommanderController ctrl) {
    final slice = ctrl.listerSlice;
    if (slice == null) return const SizedBox.shrink();

    return Container(
      width: 960,
      height: 640,
      decoration: BoxDecoration(
        color: const Color(0xFF1A1B1E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF3E414A), width: 1),
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: const BoxDecoration(
              color: Color(0xFF25262B),
              borderRadius: BorderRadius.vertical(top: Radius.circular(11)),
              border: Border(
                bottom: BorderSide(color: Color(0xFF383A42), width: 1),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  CupertinoIcons.doc_text_search,
                  size: 16,
                  color: Color(0xFF0A84FF),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Lister (F3 mmap) — ${slice.filePath} (${formatBytes(slice.fileSize)})',
                    style: const TextStyle(
                      color: Color(0xFFF2F3F5),
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Menlo',
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                CupertinoSlidingSegmentedControl<bool>(
                  groupValue: ctrl.listerHexMode,
                  backgroundColor: const Color(0xFF18191C),
                  thumbColor: const Color(0xFF0A84FF),
                  children: const {
                    false: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10),
                      child: Text(
                        '1: Text',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: CupertinoColors.white,
                        ),
                      ),
                    ),
                    true: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10),
                      child: Text(
                        '3: Hex',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: CupertinoColors.white,
                        ),
                      ),
                    ),
                  },
                  onValueChanged: (v) {
                    if (v != null) ctrl.setListerMode(hex: v);
                  },
                ),
                const SizedBox(width: 10),
                CupertinoButton(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  minimumSize: const Size(0, 24),
                  color: const Color(0xFF383A42),
                  onPressed: () => ctrl.pageLister(-16384),
                  child: const Text(
                    '◀ Prev',
                    style: TextStyle(
                      fontSize: 11,
                      color: CupertinoColors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                CupertinoButton(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  minimumSize: const Size(0, 24),
                  color: const Color(0xFF383A42),
                  onPressed: () => ctrl.pageLister(16384),
                  child: const Text(
                    'Next ▶',
                    style: TextStyle(
                      fontSize: 11,
                      color: CupertinoColors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                CupertinoButton(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  minimumSize: const Size(0, 24),
                  color: const Color(0xFFFF453A),
                  onPressed: ctrl.closeDialog,
                  child: const Text(
                    'Close (Esc/Enter)',
                    style: TextStyle(
                      fontSize: 11,
                      color: CupertinoColors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(14),
              child: Text(
                slice.error ?? slice.content,
                style: const TextStyle(
                  color: Color(0xFFD9DCE3),
                  fontSize: 12,
                  height: 1.4,
                  fontFamily: 'Menlo',
                ),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: const BoxDecoration(
              color: Color(0xFF212226),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(11)),
              border: Border(
                top: BorderSide(color: Color(0xFF34363E), width: 1),
              ),
            ),
            child: Text(
              'Offset: ${slice.offset} / ${slice.fileSize} bytes  |  Keys: [1] Text  [3] Hex  [PgUp/PgDn] Scroll  [Esc/Enter/F3] Close',
              style: const TextStyle(
                color: Color(0xFF8F94A0),
                fontSize: 11,
                fontFamily: 'Menlo',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
