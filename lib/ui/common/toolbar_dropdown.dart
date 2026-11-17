import 'package:flutter/widgets.dart';
import '../../core/theme_palette.dart';

class ToolbarDropdownItem<T> {
  final T value;
  final String label;
  final String? subtitle;
  final Color? swatchColor;
  final IconData? icon;

  const ToolbarDropdownItem({
    required this.value,
    required this.label,
    this.subtitle,
    this.swatchColor,
    this.icon,
  });
}

class ToolbarDropdownPicker<T> extends StatefulWidget {
  final String prefixLabel;
  final T selectedValue;
  final List<ToolbarDropdownItem<T>> items;
  final ValueChanged<T> onChanged;
  final TcThemePalette palette;
  final double menuWidth;

  const ToolbarDropdownPicker({
    super.key,
    required this.prefixLabel,
    required this.selectedValue,
    required this.items,
    required this.onChanged,
    required this.palette,
    this.menuWidth = 190,
  });

  @override
  State<ToolbarDropdownPicker<T>> createState() =>
      _ToolbarDropdownPickerState<T>();
}

class _ToolbarDropdownPickerState<T> extends State<ToolbarDropdownPicker<T>> {
  final OverlayPortalController _portalController = OverlayPortalController();
  final LayerLink _layerLink = LayerLink();

  ToolbarDropdownItem<T> get _selectedItem {
    for (final item in widget.items) {
      if (item.value == widget.selectedValue) return item;
    }
    return widget.items.first;
  }

  void _toggleMenu() {
    _portalController.toggle();
    setState(() {});
  }

  void _hideMenu() {
    if (_portalController.isShowing) {
      _portalController.hide();
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.palette;
    final current = _selectedItem;
    final isOpen = _portalController.isShowing;

    return CompositedTransformTarget(
      link: _layerLink,
      child: OverlayPortal(
        controller: _portalController,
        overlayChildBuilder: (context) {
          return Stack(
            children: [
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: _hideMenu,
                  child: const SizedBox.expand(),
                ),
              ),
              CompositedTransformFollower(
                link: _layerLink,
                targetAnchor: Alignment.bottomRight,
                followerAnchor: Alignment.topRight,
                offset: const Offset(0, 4),
                child: Container(
                  width: widget.menuWidth,
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  decoration: BoxDecoration(
                    color: p.toolbarBg,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: p.activeBorder, width: 1.2),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x88000000),
                        blurRadius: 16,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final item in widget.items)
                        _buildDropdownRow(p, item),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _toggleMenu,
          child: Container(
            height: 27,
            padding: const EdgeInsets.symmetric(horizontal: 9),
            decoration: BoxDecoration(
              color: isOpen ? p.headerBg : p.windowBg,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: isOpen ? p.activeBorder : p.dividerColor,
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${widget.prefixLabel}: ',
                  style: TextStyle(
                    color: p.mutedText,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (current.swatchColor != null) ...[
                  Container(
                    width: 9,
                    height: 9,
                    decoration: BoxDecoration(
                      color: current.swatchColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 5),
                ] else if (current.icon != null) ...[
                  Icon(current.icon, size: 12.5, color: p.primaryAccent),
                  const SizedBox(width: 5),
                ],
                Text(
                  current.label,
                  style: TextStyle(
                    color: p.fileImportantText,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  isOpen ? '▴' : '▾',
                  style: TextStyle(
                    color: p.primaryAccent,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDropdownRow(TcThemePalette p, ToolbarDropdownItem<T> item) {
    final isSelected = item.value == widget.selectedValue;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        _hideMenu();
        widget.onChanged(item.value);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
        decoration: BoxDecoration(
          color: isSelected
              ? p.primaryAccent.withValues(alpha: 0.2)
              : const Color(0x00000000),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          children: [
            if (item.swatchColor != null) ...[
              Container(
                width: 11,
                height: 11,
                decoration: BoxDecoration(
                  color: item.swatchColor,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: p.fileImportantText.withValues(alpha: 0.4),
                    width: 1,
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ] else if (item.icon != null) ...[
              Icon(
                item.icon,
                size: 14,
                color: isSelected ? p.primaryAccent : p.semiHighlightedText,
              ),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    item.label,
                    style: TextStyle(
                      color: isSelected
                          ? p.primaryAccent
                          : p.fileImportantText,
                      fontSize: 12,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w500,
                    ),
                  ),
                  if (item.subtitle != null)
                    Text(
                      item.subtitle!,
                      style: TextStyle(color: p.mutedText, fontSize: 10),
                    ),
                ],
              ),
            ),
            if (isSelected)
              Text(
                '✓',
                style: TextStyle(
                  color: p.primaryAccent,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
