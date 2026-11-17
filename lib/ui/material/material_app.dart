import 'package:flutter/material.dart';
import '../../state/commander_controller.dart';
import 'material_shell.dart';

class MaterialCommanderApp extends StatelessWidget {
  final CommanderController controller;

  const MaterialCommanderApp({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final p = controller.palette;
        final scheme = ColorScheme.fromSeed(
          seedColor: p.primaryAccent,
          brightness: p.brightness,
          surface: p.windowBg,
        );
        return MaterialApp(
          title: 'FerroPane (Material 3 UI)',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            useMaterial3: true,
            brightness: p.brightness,
            visualDensity: VisualDensity.compact,
            colorScheme: scheme,
            scaffoldBackgroundColor: p.windowBg,
          ),
          home: MaterialCommanderShell(controller: controller),
        );
      },
    );
  }
}
