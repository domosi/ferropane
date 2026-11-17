import 'package:flutter/widgets.dart';
import 'core/models.dart';
import 'core/session_store.dart';
import 'state/commander_controller.dart';
import 'ui/macos/macos_app.dart';
import 'ui/material/material_app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final session = SessionStore.load();
  runApp(TcRootBootstrapper(initialSession: session));
}

class TcRootBootstrapper extends StatefulWidget {
  final SessionData initialSession;

  const TcRootBootstrapper({super.key, required this.initialSession});

  @override
  State<TcRootBootstrapper> createState() => _TcRootBootstrapperState();
}

class _TcRootBootstrapperState extends State<TcRootBootstrapper> {
  late final CommanderController _controller;
  late UiFrameworkMode _activeMode;

  @override
  void initState() {
    super.initState();
    _activeMode = widget.initialSession.uiFramework;
    _controller = CommanderController(
      initialSession: widget.initialSession,
      onUiFrameworkChanged: (newMode) {
        setState(() {
          _activeMode = newMode;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_activeMode == UiFrameworkMode.material3) {
      return MaterialCommanderApp(
        key: const ValueKey('root_material3_app'),
        controller: _controller,
      );
    }
    return MacosCommanderApp(
      key: const ValueKey('root_macos_app'),
      controller: _controller,
    );
  }
}
