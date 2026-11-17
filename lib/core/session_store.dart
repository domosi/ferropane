import 'dart:convert';
import 'dart:io';
import 'models.dart';
import 'theme_palette.dart';

class SessionData {
  final UiFrameworkMode uiFramework;
  final TcThemeId themeId;
  final List<String> leftTabs;
  final int activeLeftTab;
  final List<String> rightTabs;
  final int activeRightTab;
  final bool showHidden;
  final Map<String, String> preferredAppsByExt;

  const SessionData({
    required this.uiFramework,
    this.themeId = TcThemeId.cyberDark,
    required this.leftTabs,
    required this.activeLeftTab,
    required this.rightTabs,
    required this.activeRightTab,
    required this.showHidden,
    this.preferredAppsByExt = const {},
  });

  factory SessionData.defaults() {
    final home = Platform.environment['HOME'] ?? '/Users';
    final downloads = Directory('$home/Downloads').existsSync()
        ? '$home/Downloads'
        : home;
    return SessionData(
      uiFramework: UiFrameworkMode.macos,
      themeId: TcThemeId.cyberDark,
      leftTabs: [home],
      activeLeftTab: 0,
      rightTabs: [downloads],
      activeRightTab: 0,
      showHidden: false,
      preferredAppsByExt: const {},
    );
  }

  Map<String, dynamic> toJson() => {
    'ui_framework': uiFramework.key,
    'theme_id': themeId.key,
    'left_tabs': leftTabs,
    'active_left_tab': activeLeftTab,
    'right_tabs': rightTabs,
    'active_right_tab': activeRightTab,
    'show_hidden': showHidden,
    'preferred_apps_by_ext': preferredAppsByExt,
  };

  static List<String> _sanitizePaths(
    List<dynamic>? rawList,
    List<String> fallback,
  ) {
    if (rawList == null) return fallback;
    final valid = rawList
        .map((e) => e.toString())
        .where((s) => s.isNotEmpty && Directory(s).existsSync())
        .toList();
    return valid.isEmpty ? fallback : valid;
  }

  factory SessionData.fromJson(Map<String, dynamic> json) {
    final defaults = SessionData.defaults();
    final left = _sanitizePaths(
      json['left_tabs'] as List<dynamic>?,
      defaults.leftTabs,
    );
    final right = _sanitizePaths(
      json['right_tabs'] as List<dynamic>?,
      defaults.rightTabs,
    );
    final rawPrefs = json['preferred_apps_by_ext'] as Map<String, dynamic>?;
    final prefs = <String, String>{};
    if (rawPrefs != null) {
      for (final entry in rawPrefs.entries) {
        if (entry.key.isNotEmpty && entry.value.toString().isNotEmpty) {
          prefs[entry.key.toLowerCase()] = entry.value.toString();
        }
      }
    }

    return SessionData(
      uiFramework: UiFrameworkMode.fromKey(json['ui_framework'] as String?),
      themeId: TcThemeId.fromKey(json['theme_id'] as String?),
      leftTabs: left,
      activeLeftTab: ((json['active_left_tab'] as num?)?.toInt() ?? 0).clamp(
        0,
        left.length - 1,
      ),
      rightTabs: right,
      activeRightTab: ((json['active_right_tab'] as num?)?.toInt() ?? 0).clamp(
        0,
        right.length - 1,
      ),
      showHidden: json['show_hidden'] as bool? ?? false,
      preferredAppsByExt: prefs,
    );
  }
}

class SessionStore {
  static bool disablePersistenceForTests = false;

  static String get configFilePath {
    final home = Platform.environment['HOME'] ?? Directory.systemTemp.path;
    return '$home/.config/ferropane/session.json';
  }

  static SessionData load() {
    try {
      final file = File(configFilePath);
      if (!file.existsSync()) {
        return SessionData.defaults();
      }
      final raw = file.readAsStringSync();
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return SessionData.fromJson(map);
    } catch (_) {
      return SessionData.defaults();
    }
  }

  static void save(SessionData data) {
    if (disablePersistenceForTests) return;
    try {
      final file = File(configFilePath);
      file.parent.createSync(recursive: true);
      file.writeAsStringSync(
        const JsonEncoder.withIndent('  ').convert(data.toJson()),
      );
    } catch (_) {}
  }
}
