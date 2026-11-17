import 'package:flutter/material.dart';
import '../../core/models.dart';
import '../../state/commander_controller.dart';
import '../common/deep_compare_modal.dart';
import '../common/favorites_hotlist_modal.dart';
import '../common/open_with_overlays.dart';

class MaterialDialogOverlay extends StatelessWidget {
  final CommanderController controller;

  const MaterialDialogOverlay({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    if (controller.activeDialog == ActiveDialog.none) {
      return const SizedBox.shrink();
    }

    return Container(
      color: Colors.black54,
      alignment: Alignment.center,
      child: GestureDetector(
        onTap: () {},
        child: controller.activeDialog == ActiveDialog.lister
            ? _buildMaterialLister(context, controller)
            : controller.activeDialog == ActiveDialog.openWithPalette
            ? OpenWithPaletteCard(controller: controller)
            : controller.activeDialog == ActiveDialog.favoritesHotlist
            ? FavoritesHotlistModal(controller: controller)
            : controller.activeDialog == ActiveDialog.deepCompare
            ? DeepCompareModal(controller: controller)
            : _buildMaterialActionDialog(context, controller),
      ),
    );
  }

  Widget _buildMaterialActionDialog(
    BuildContext context,
    CommanderController ctrl,
  ) {
    final cs = Theme.of(context).colorScheme;
    final targets = ctrl.getActionTargetPaths();
    String title = '';
    String subtitle = '';
    String primaryLabel = 'Confirm (Enter)';
    IconData leadingIcon = Icons.folder_copy_outlined;
    bool isDestructive = false;
    bool showInput = true;

    switch (ctrl.activeDialog) {
      case ActiveDialog.copyConfirm:
        leadingIcon = Icons.copy_all_rounded;
        title = 'Copy ${targets.length} item(s) (F5)';
        subtitle = 'Destination directory (APFS clonefile/copyfile):';
        primaryLabel = 'Copy (Enter)';
        break;
      case ActiveDialog.moveConfirm:
        leadingIcon = Icons.drive_file_move_rounded;
        title = 'Move / Rename ${targets.length} item(s) (F6)';
        subtitle = 'Destination path:';
        primaryLabel = 'Move (Enter)';
        break;
      case ActiveDialog.mkdirPrompt:
        leadingIcon = Icons.create_new_folder_rounded;
        title = 'Create Directory (F7)';
        subtitle = 'Parent: ${ctrl.activeTab.summary.currentPath}';
        primaryLabel = 'Create (Enter)';
        break;
      case ActiveDialog.deleteConfirm:
        showInput = false;
        isDestructive = true;
        leadingIcon = Icons.delete_outline_rounded;
        title = ctrl.deleteUseTrash
            ? 'Move ${targets.length} item(s) to Trash? (F8)'
            : 'Permanently delete ${targets.length} item(s)? (Shift+F8)';
        subtitle = targets.take(4).join('\n') +
            (targets.length > 4 ? '\n...and ${targets.length - 4} more' : '');
        primaryLabel = ctrl.deleteUseTrash
            ? 'Move to Trash (Enter)'
            : 'Delete Forever (Enter)';
        break;
      case ActiveDialog.selectPattern:
        leadingIcon = Icons.checklist_rounded;
        title = 'Select by Wildcard Pattern (+)';
        subtitle = 'Example: *.dart, *.rs, *config*';
        primaryLabel = 'Select Matching (Enter)';
        break;
      case ActiveDialog.gotoPath:
        leadingIcon = Icons.directions_rounded;
        title = 'Go to Directory (Cmd+G)';
        subtitle = 'Enter absolute path:';
        primaryLabel = 'Navigate (Enter)';
        break;
      default:
        break;
    }

    return Card(
      elevation: 12,
      color: cs.surfaceContainerHigh,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: isDestructive
                      ? cs.errorContainer
                      : cs.primaryContainer,
                  child: Icon(
                    leadingIcon,
                    color: isDestructive
                        ? cs.onErrorContainer
                        : cs.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontFamily: 'Menlo',
                color: cs.onSurfaceVariant,
              ),
            ),
            if (showInput) ...[
              const SizedBox(height: 14),
              TextField(
                controller: ctrl.dialogTextController,
                focusNode: ctrl.dialogInputFocusNode,
                autofocus: true,
                style: const TextStyle(fontFamily: 'Menlo', fontSize: 13),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: cs.surfaceContainerLowest,
                  isDense: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onSubmitted: (_) => ctrl.confirmActiveDialog(),
              ),
            ],
            const SizedBox(height: 22),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: ctrl.closeDialog,
                  child: const Text('Cancel (Esc)'),
                ),
                const SizedBox(width: 10),
                FilledButton(
                  style: isDestructive
                      ? FilledButton.styleFrom(
                          backgroundColor: cs.error,
                          foregroundColor: cs.onError,
                        )
                      : null,
                  onPressed: ctrl.confirmActiveDialog,
                  child: Text(primaryLabel),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMaterialLister(
    BuildContext context,
    CommanderController ctrl,
  ) {
    final cs = Theme.of(context).colorScheme;
    final slice = ctrl.listerSlice;
    if (slice == null) return const SizedBox.shrink();

    return Card(
      elevation: 16,
      color: cs.surfaceContainerHigh,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SizedBox(
        width: 980,
        height: 650,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: [
                  Icon(Icons.memory_rounded, color: cs.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'F3 Lister (mmap) — ${slice.filePath} (${formatBytes(slice.fileSize)})',
                      style: const TextStyle(
                        fontFamily: 'Menlo',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment(
                        value: false,
                        label: Text('1: Text'),
                        icon: Icon(Icons.notes_rounded, size: 16),
                      ),
                      ButtonSegment(
                        value: true,
                        label: Text('3: Hex'),
                        icon: Icon(Icons.data_object_rounded, size: 16),
                      ),
                    ],
                    selected: {ctrl.listerHexMode},
                    onSelectionChanged: (s) =>
                        ctrl.setListerMode(hex: s.first),
                  ),
                  const SizedBox(width: 10),
                  IconButton.filledTonal(
                    tooltip: 'Previous Page (PgUp)',
                    onPressed: () => ctrl.pageLister(-16384),
                    icon: const Icon(Icons.chevron_left_rounded),
                  ),
                  const SizedBox(width: 4),
                  IconButton.filledTonal(
                    tooltip: 'Next Page (PgDn)',
                    onPressed: () => ctrl.pageLister(16384),
                    icon: const Icon(Icons.chevron_right_rounded),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.tonalIcon(
                    onPressed: ctrl.closeDialog,
                    icon: const Icon(Icons.close_rounded, size: 16),
                    label: const Text('Close'),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: Container(
                color: cs.surfaceContainerLowest,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: SelectableText(
                    slice.error ?? slice.content,
                    style: TextStyle(
                      fontFamily: 'Menlo',
                      fontSize: 12,
                      height: 1.45,
                      color: cs.onSurface,
                    ),
                  ),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: cs.surfaceContainer,
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(20),
                ),
              ),
              child: Text(
                'Offset: ${slice.offset} / ${slice.fileSize} bytes  •  Shortcuts: [1] Text  [3] Hex  [PgUp/PgDn] Page  [Esc/Enter] Close',
                style: TextStyle(
                  fontFamily: 'Menlo',
                  fontSize: 11,
                  color: cs.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
