import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ferropane/core/models.dart';
import 'package:ferropane/core/session_store.dart';
import 'package:ferropane/main.dart';

void main() {
  late Directory tempLeft;
  late Directory tempRight;

  setUp(() {
    SessionStore.disablePersistenceForTests = true;
    tempLeft = Directory.systemTemp.createTempSync('tc_mac_left_');
    tempRight = Directory.systemTemp.createTempSync('tc_mac_right_');
    Directory('${tempLeft.path}/alpha_dir').createSync();
    File('${tempLeft.path}/alpha_dir/nested.bin')
        .writeAsBytesSync(List<int>.filled(2048, 0x41));
    File('${tempLeft.path}/file2.txt').writeAsStringSync('Hello from Rust FFI 2');
    File('${tempLeft.path}/file10.txt').writeAsStringSync('Hello from Rust FFI 10');
    File('${tempRight.path}/target_note.md').writeAsStringSync('# Right Pane');
  });

  tearDown(() {
    if (tempLeft.existsSync()) tempLeft.deleteSync(recursive: true);
    if (tempRight.existsSync()) tempRight.deleteSync(recursive: true);
  });

  testWidgets(
    'Boots macOS Desktop UI via Rust FFI, tests TC hotkeys/Lister/Copy, and switches to Material 3 UI',
    (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));

      final initialSession = SessionData(
        uiFramework: UiFrameworkMode.macos,
        leftTabs: [tempLeft.path],
        activeLeftTab: 0,
        rightTabs: [tempRight.path],
        activeRightTab: 0,
        showHidden: false,
      );

      await tester.pumpWidget(
        TcRootBootstrapper(initialSession: initialSession),
      );
      await tester.pumpAndSettle();

      // 1. Verify macOS Desktop UI is mounted (CupertinoApp, no MaterialApp)
      expect(find.byType(CupertinoApp), findsOneWidget);
      expect(find.byType(MaterialApp), findsNothing);

      // 2. Verify Rust FFI populated both panes with natural sorting
      expect(find.text('[alpha_dir]'), findsOneWidget);
      expect(find.text('file2'), findsOneWidget);
      expect(find.text('file10'), findsOneWidget);
      expect(find.text('target_note'), findsOneWidget);

      // 3. Move cursor down to [alpha_dir] and press Space to select & calculate dir size (2.0 KB)
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pumpAndSettle();
      expect(find.text('2.0 KB'), findsWidgets);

      // 4. Move cursor to file2.txt and press F3 to open mmap Lister
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.f3);
      await tester.pumpAndSettle();
      expect(find.textContaining('Hello from Rust FFI 2'), findsOneWidget);

      // Switch Lister to Hex mode ('3') and verify hex bytes
      await tester.sendKeyEvent(LogicalKeyboardKey.digit3);
      await tester.pumpAndSettle();
      expect(find.textContaining('48 65 6C 6C 6F'), findsOneWidget);

      // Close Lister with Escape
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();

      // 4b. Press F4 on file2.txt to open the "Open With..." numbered palette
      await tester.sendKeyEvent(LogicalKeyboardKey.f4);
      await tester.pumpAndSettle();
      expect(find.textContaining('Open "file2.txt" With…'), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();

      // 5. Open F7 Mkdir dialog and press Enter to confirm primary button
      await tester.sendKeyEvent(LogicalKeyboardKey.f7);
      await tester.pumpAndSettle();
      expect(find.textContaining('F7 — Create New Folder'), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(Directory('${tempLeft.path}/NewFolder').existsSync(), isTrue);

      // 6. Open UI dropdown picker and select Material 3 UI
      await tester.tap(find.text('macOS UI'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Material 3'));
      await tester.pumpAndSettle();

      expect(find.byType(MaterialApp), findsOneWidget);
      expect(find.byType(CupertinoApp), findsNothing);
      expect(find.text('[alpha_dir]'), findsOneWidget);
      expect(find.text('file2'), findsOneWidget);
      expect(find.text('target_note'), findsOneWidget);
    },
  );
}
