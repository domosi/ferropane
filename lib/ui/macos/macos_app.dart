import 'package:flutter/cupertino.dart';
import '../../state/commander_controller.dart';
import 'macos_shell.dart';

class MacosCommanderApp extends StatelessWidget {
  final CommanderController controller;

  const MacosCommanderApp({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final p = controller.palette;
        return CupertinoApp(
          title: 'FerroPane (macOS Desktop UI)',
          debugShowCheckedModeBanner: false,
          theme: CupertinoThemeData(
            brightness: p.brightness,
            primaryColor: p.primaryAccent,
            scaffoldBackgroundColor: p.windowBg,
            barBackgroundColor: p.toolbarBg,
          ),
          home: MacosCommanderShell(controller: controller),
        );
      },
    );
  }
}
