import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import '../core/models.dart';
import 'commander_controller.dart';

class CommanderKeyboardScope extends StatefulWidget {
  final CommanderController controller;
  final Widget child;

  const CommanderKeyboardScope({
    super.key,
    required this.controller,
    required this.child,
  });

  @override
  State<CommanderKeyboardScope> createState() => _CommanderKeyboardScopeState();
}

class _CommanderKeyboardScopeState extends State<CommanderKeyboardScope> {
  final FocusNode _rootFocusNode = FocusNode(debugLabel: 'CommanderRootFocus');

  @override
  void dispose() {
    _rootFocusNode.dispose();
    super.dispose();
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }

    final ctrl = widget.controller;
    final key = event.logicalKey;
    final isMeta = HardwareKeyboard.instance.isMetaPressed;
    final isControl = HardwareKeyboard.instance.isControlPressed;
    final isShift = HardwareKeyboard.instance.isShiftPressed;
    final isAlt = HardwareKeyboard.instance.isAltPressed;

    // If right-click context menu is open, Escape closes it
    if (ctrl.contextMenuPosition != null &&
        key == LogicalKeyboardKey.escape) {
      ctrl.closeContextMenu();
      return KeyEventResult.handled;
    }

    // If a modal dialog is open, handle Enter (confirm), Escape (cancel), or dialog-specific hotkeys
    if (ctrl.activeDialog != ActiveDialog.none) {
      if (key == LogicalKeyboardKey.escape ||
          (ctrl.activeDialog == ActiveDialog.lister &&
              key == LogicalKeyboardKey.f3) ||
          (ctrl.activeDialog == ActiveDialog.favoritesHotlist &&
              ((isMeta && key == LogicalKeyboardKey.keyB) ||
                  (isControl && key == LogicalKeyboardKey.keyD)))) {
        ctrl.closeDialog();
        _rootFocusNode.requestFocus();
        return KeyEventResult.handled;
      }
      if (ctrl.activeDialog == ActiveDialog.favoritesHotlist) {
        if (key == LogicalKeyboardKey.arrowDown) {
          ctrl.moveFavoritesSelection(1);
          return KeyEventResult.handled;
        }
        if (key == LogicalKeyboardKey.arrowUp) {
          ctrl.moveFavoritesSelection(-1);
          return KeyEventResult.handled;
        }
        if (key == LogicalKeyboardKey.tab) {
          ctrl.toggleFavoritesTargetSide();
          return KeyEventResult.handled;
        }
        if (key == LogicalKeyboardKey.keyP ||
            key == LogicalKeyboardKey.numpadAdd ||
            (key == LogicalKeyboardKey.equal && isShift)) {
          ctrl.togglePinCurrentFolder();
          return KeyEventResult.handled;
        }
        if (key == LogicalKeyboardKey.enter ||
            key == LogicalKeyboardKey.numpadEnter) {
          ctrl.launchSelectedFavorite(inNewTab: isShift);
          _rootFocusNode.requestFocus();
          return KeyEventResult.handled;
        }
        final favDigitMap = <LogicalKeyboardKey, int>{
          LogicalKeyboardKey.digit1: 0,
          LogicalKeyboardKey.digit2: 1,
          LogicalKeyboardKey.digit3: 2,
          LogicalKeyboardKey.digit4: 3,
          LogicalKeyboardKey.digit5: 4,
          LogicalKeyboardKey.digit6: 5,
          LogicalKeyboardKey.digit7: 6,
          LogicalKeyboardKey.digit8: 7,
          LogicalKeyboardKey.digit9: 8,
          LogicalKeyboardKey.numpad1: 0,
          LogicalKeyboardKey.numpad2: 1,
          LogicalKeyboardKey.numpad3: 2,
          LogicalKeyboardKey.numpad4: 3,
          LogicalKeyboardKey.numpad5: 4,
          LogicalKeyboardKey.numpad6: 5,
          LogicalKeyboardKey.numpad7: 6,
          LogicalKeyboardKey.numpad8: 7,
          LogicalKeyboardKey.numpad9: 8,
        };
        if (favDigitMap.containsKey(key)) {
          ctrl.launchFavoriteAtIndex(favDigitMap[key]!, inNewTab: isShift);
          _rootFocusNode.requestFocus();
          return KeyEventResult.handled;
        }
      }
      if (ctrl.activeDialog == ActiveDialog.openWithPalette) {
        if (key == LogicalKeyboardKey.arrowDown) {
          ctrl.moveOpenWithSelection(1);
          return KeyEventResult.handled;
        }
        if (key == LogicalKeyboardKey.arrowUp) {
          ctrl.moveOpenWithSelection(-1);
          return KeyEventResult.handled;
        }
        if (key == LogicalKeyboardKey.space) {
          ctrl.toggleOpenWithRemember();
          return KeyEventResult.handled;
        }
        if (key == LogicalKeyboardKey.keyB) {
          ctrl.browseOtherAppForOpenWith();
          return KeyEventResult.handled;
        }
        final digitMap = <LogicalKeyboardKey, int>{
          LogicalKeyboardKey.digit1: 0,
          LogicalKeyboardKey.digit2: 1,
          LogicalKeyboardKey.digit3: 2,
          LogicalKeyboardKey.digit4: 3,
          LogicalKeyboardKey.digit5: 4,
          LogicalKeyboardKey.digit6: 5,
          LogicalKeyboardKey.digit7: 6,
          LogicalKeyboardKey.digit8: 7,
          LogicalKeyboardKey.digit9: 8,
          LogicalKeyboardKey.numpad1: 0,
          LogicalKeyboardKey.numpad2: 1,
          LogicalKeyboardKey.numpad3: 2,
          LogicalKeyboardKey.numpad4: 3,
          LogicalKeyboardKey.numpad5: 4,
          LogicalKeyboardKey.numpad6: 5,
          LogicalKeyboardKey.numpad7: 6,
          LogicalKeyboardKey.numpad8: 7,
          LogicalKeyboardKey.numpad9: 8,
        };
        if (digitMap.containsKey(key)) {
          ctrl.launchOpenWithIndex(digitMap[key]!);
          _rootFocusNode.requestFocus();
          return KeyEventResult.handled;
        }
      }
      if (key == LogicalKeyboardKey.enter ||
          key == LogicalKeyboardKey.numpadEnter) {
        ctrl.confirmActiveDialog();
        _rootFocusNode.requestFocus();
        return KeyEventResult.handled;
      }
      if (ctrl.activeDialog == ActiveDialog.lister) {
        if (key == LogicalKeyboardKey.digit1) {
          ctrl.setListerMode(hex: false);
          return KeyEventResult.handled;
        }
        if (key == LogicalKeyboardKey.digit3) {
          ctrl.setListerMode(hex: true);
          return KeyEventResult.handled;
        }
        if (key == LogicalKeyboardKey.pageDown ||
            key == LogicalKeyboardKey.space) {
          ctrl.pageLister(16384);
          return KeyEventResult.handled;
        }
        if (key == LogicalKeyboardKey.pageUp) {
          ctrl.pageLister(-16384);
          return KeyEventResult.handled;
        }
      }
      return KeyEventResult.ignored;
    }

    // If an editable text field (like quick filter) currently holds focus, only intercept Escape or Up/Down/Tab
    final primaryFocus = FocusManager.instance.primaryFocus;
    final isEditingText =
        primaryFocus != null &&
        primaryFocus != _rootFocusNode &&
        primaryFocus.context?.findAncestorWidgetOfExactType<EditableText>() !=
            null;

    if (isEditingText) {
      if (key == LogicalKeyboardKey.escape) {
        ctrl.setQuickFilter('');
        ctrl.filterBarVisible = false;
        _rootFocusNode.requestFocus();
        return KeyEventResult.handled;
      }
      if (key == LogicalKeyboardKey.arrowDown) {
        _rootFocusNode.requestFocus();
        ctrl.moveCursorBy(1);
        return KeyEventResult.handled;
      }
      if (key == LogicalKeyboardKey.arrowUp) {
        _rootFocusNode.requestFocus();
        ctrl.moveCursorBy(-1);
        return KeyEventResult.handled;
      }
      return KeyEventResult.ignored;
    }

    // Global Meta (Cmd) shortcuts
    if (isMeta) {
      if (key == LogicalKeyboardKey.keyT) {
        ctrl.addNewTab();
        return KeyEventResult.handled;
      }
      if (key == LogicalKeyboardKey.keyW) {
        ctrl.closeTab(
          ctrl.activeSide,
          ctrl.activeTabIndexFor(ctrl.activeSide),
        );
        return KeyEventResult.handled;
      }
      if (key == LogicalKeyboardKey.keyR) {
        ctrl.reloadBothPanes();
        return KeyEventResult.handled;
      }
      if (key == LogicalKeyboardKey.keyF) {
        ctrl.toggleQuickFilterBar();
        return KeyEventResult.handled;
      }
      if (key == LogicalKeyboardKey.keyG) {
        ctrl.openGotoPathDialog();
        return KeyEventResult.handled;
      }
      if (key == LogicalKeyboardKey.keyB) {
        ctrl.openFavoritesHotlist();
        return KeyEventResult.handled;
      }
      if (key == LogicalKeyboardKey.keyD) {
        ctrl.openDeepCompare();
        return KeyEventResult.handled;
      }
      if (key == LogicalKeyboardKey.arrowDown) {
        ctrl.enterDirectoryOrPackageContents();
        return KeyEventResult.handled;
      }
      if (key == LogicalKeyboardKey.arrowUp) {
        ctrl.navigateUp();
        return KeyEventResult.handled;
      }
      if (key == LogicalKeyboardKey.keyO) {
        ctrl.openOpenWithPalette();
        return KeyEventResult.handled;
      }
      if (key == LogicalKeyboardKey.keyY) {
        ctrl.triggerQuickLook();
        return KeyEventResult.handled;
      }
      if (key == LogicalKeyboardKey.keyU) {
        final next = ctrl.uiFramework == UiFrameworkMode.macos
            ? UiFrameworkMode.material3
            : UiFrameworkMode.macos;
        ctrl.setUiFramework(next);
        return KeyEventResult.handled;
      }
      if (key == LogicalKeyboardKey.period && isShift) {
        ctrl.toggleHiddenFiles();
        return KeyEventResult.handled;
      }
      if (key == LogicalKeyboardKey.keyA) {
        ctrl.selectAll(!isShift);
        return KeyEventResult.handled;
      }
      if (key == LogicalKeyboardKey.backspace) {
        ctrl.openDeleteDialog(useTrash: !isShift);
        return KeyEventResult.handled;
      }
      // Cmd+3..Cmd+8 fallback for MacBook keyboards without Fn held
      if (key == LogicalKeyboardKey.digit3) {
        ctrl.openLister();
        return KeyEventResult.handled;
      }
      if (key == LogicalKeyboardKey.digit4) {
        ctrl.triggerSmartF4(forcePicker: isShift);
        return KeyEventResult.handled;
      }
      if (key == LogicalKeyboardKey.digit5) {
        ctrl.openCopyDialog();
        return KeyEventResult.handled;
      }
      if (key == LogicalKeyboardKey.digit6) {
        ctrl.openMoveDialog();
        return KeyEventResult.handled;
      }
      if (key == LogicalKeyboardKey.digit7) {
        ctrl.openMkdirDialog();
        return KeyEventResult.handled;
      }
      if (key == LogicalKeyboardKey.digit8) {
        ctrl.openDeleteDialog(useTrash: !isShift);
        return KeyEventResult.handled;
      }
    }

    // Total Commander classic Ctrl+D Directory Hotlist shortcut
    if (isControl && !isMeta && key == LogicalKeyboardKey.keyD) {
      ctrl.openFavoritesHotlist();
      return KeyEventResult.handled;
    }

    // Standard Total Commander navigation & function keys
    if (key == LogicalKeyboardKey.tab) {
      ctrl.toggleActiveSide();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowDown) {
      if (isShift) {
        ctrl.toggleSelectionAtCursor(
          advanceCursor: true,
          calculateDirSize: false,
        );
      } else {
        ctrl.moveCursorBy(1);
      }
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowUp) {
      if (isShift) {
        ctrl.toggleSelectionAtCursor(
          advanceCursor: false,
          calculateDirSize: false,
        );
        ctrl.moveCursorBy(-1);
      } else {
        ctrl.moveCursorBy(-1);
      }
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.pageDown) {
      ctrl.moveCursorBy(25);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.pageUp) {
      ctrl.moveCursorBy(-25);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.home) {
      ctrl.moveCursorToStart();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.end) {
      ctrl.moveCursorToEnd();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter) {
      if (isShift) {
        ctrl.openOpenWithPalette();
      } else {
        ctrl.activateFocusedEntry();
      }
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.backspace) {
      ctrl.navigateUp();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.space) {
      if (isAlt) {
        ctrl.triggerQuickLook();
      } else {
        ctrl.toggleSelectionAtCursor(
          advanceCursor: false,
          calculateDirSize: true,
        );
      }
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.insert) {
      ctrl.toggleSelectionAtCursor(
        advanceCursor: true,
        calculateDirSize: false,
      );
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.numpadMultiply ||
        (key == LogicalKeyboardKey.digit8 && isShift && !isMeta)) {
      ctrl.invertSelection();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.numpadAdd ||
        (key == LogicalKeyboardKey.equal && isShift && !isMeta)) {
      ctrl.openSelectPatternDialog();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.slash) {
      ctrl.toggleQuickFilterBar();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.escape) {
      if (ctrl.filterBarVisible ||
          ctrl.activeTab.summary.filterQuery.isNotEmpty) {
        ctrl.setQuickFilter('');
        ctrl.filterBarVisible = false;
        return KeyEventResult.handled;
      }
    }

    // Function keys F3 - F8
    if (key == LogicalKeyboardKey.f3) {
      ctrl.openLister();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.f4) {
      ctrl.triggerSmartF4(forcePicker: isShift);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.f5) {
      ctrl.openCopyDialog();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.f6) {
      ctrl.openMoveDialog();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.f7) {
      ctrl.openMkdirDialog();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.f8 || key == LogicalKeyboardKey.delete) {
      ctrl.openDeleteDialog(useTrash: !isShift);
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _rootFocusNode,
      autofocus: true,
      onKeyEvent: _handleKeyEvent,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () {
          if (!_rootFocusNode.hasFocus) {
            _rootFocusNode.requestFocus();
          }
        },
        child: widget.child,
      ),
    );
  }
}
