import 'dart:io';
import 'package:flutter/services.dart';

class OpenWithAppInfo {
  final String name;
  final String path;
  final bool isDefault;
  final bool isRemembered;

  const OpenWithAppInfo({
    required this.name,
    required this.path,
    this.isDefault = false,
    this.isRemembered = false,
  });

  OpenWithAppInfo copyWith({bool? isRemembered}) => OpenWithAppInfo(
    name: name,
    path: path,
    isDefault: isDefault,
    isRemembered: isRemembered ?? this.isRemembered,
  );
}

class NativeMacosBridge {
  static const MethodChannel _channel = MethodChannel(
    'com.domosi.ferropane/native',
  );

  static Future<bool> openFile(String path) async {
    try {
      final res = await _channel.invokeMethod<bool>('openFile', {'path': path});
      return res ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<List<OpenWithAppInfo>> getOpenWithApps(String path) async {
    try {
      final raw = await _channel.invokeMethod<List<dynamic>>(
        'getOpenWithApps',
        {'path': path},
      );
      if (raw != null && raw.isNotEmpty) {
        return raw.map((item) {
          final m = Map<String, dynamic>.from(item as Map);
          return OpenWithAppInfo(
            name: m['name']?.toString() ?? 'App',
            path: m['path']?.toString() ?? '',
            isDefault: m['isDefault'] as bool? ?? false,
          );
        }).toList();
      }
    } catch (_) {}

    // Fallback (e.g. during headless widget tests)
    final candidates = <String>[
      '/Applications/Cursor.app',
      '/Applications/Visual Studio Code.app',
      '/Applications/Zed.app',
      '/System/Applications/TextEdit.app',
      '/System/Applications/Preview.app',
    ];
    final out = <OpenWithAppInfo>[];
    for (final p in candidates) {
      if (Directory(p).existsSync()) {
        final name = p.split('/').last.replaceAll('.app', '');
        out.add(OpenWithAppInfo(name: name, path: p, isDefault: out.isEmpty));
      }
    }
    if (out.isEmpty) {
      out.add(
        const OpenWithAppInfo(
          name: 'TextEdit',
          path: '/System/Applications/TextEdit.app',
          isDefault: true,
        ),
      );
    }
    return out;
  }

  static Future<bool> openFileWithApp(String path, String appPath) async {
    try {
      final res = await _channel.invokeMethod<bool>('openFileWithApp', {
        'path': path,
        'appPath': appPath,
      });
      return res ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<String?> pickOtherAppAndOpen(String path) async {
    try {
      return await _channel.invokeMethod<String>('pickOtherAppAndOpen', {
        'path': path,
      });
    } catch (_) {
      return null;
    }
  }

  static Future<void> revealInFinder(String path) async {
    try {
      await _channel.invokeMethod<bool>('revealInFinder', {'path': path});
    } catch (_) {}
  }

  static Future<void> openTerminal(String dirPath) async {
    try {
      await _channel.invokeMethod<bool>('openTerminal', {'path': dirPath});
    } catch (_) {}
  }

  static Future<void> toggleQuickLook(String path) async {
    try {
      await _channel.invokeMethod<bool>('quickLook', {'path': path});
    } catch (_) {}
  }

  /// Extracts a .zip or .tar* archive into [destDir] using macOS native ditto/tar.
  static Future<bool> extractArchiveToDirectory(
    String archivePath,
    String destDir,
  ) async {
    try {
      Directory(destDir).createSync(recursive: true);
      final lower = archivePath.toLowerCase();
      ProcessResult res;
      if (lower.endsWith('.zip')) {
        res = await Process.run('/usr/bin/ditto', [
          '-x',
          '-k',
          archivePath,
          destDir,
        ]);
      } else {
        res = await Process.run('/usr/bin/tar', [
          '-xf',
          archivePath,
          '-C',
          destDir,
        ]);
      }
      return res.exitCode == 0;
    } catch (_) {
      return false;
    }
  }

  /// Mounts a .dmg file via hdiutil and returns the mounted `/Volumes/<Name>` path.
  static Future<String?> mountDiskImage(String dmgPath) async {
    try {
      final res = await Process.run('/usr/bin/hdiutil', [
        'attach',
        dmgPath,
        '-noidme',
      ]);
      if (res.exitCode != 0) return null;
      final out = res.stdout.toString();
      for (final line in out.split('\n').reversed) {
        final idx = line.indexOf('/Volumes/');
        if (idx >= 0) {
          final mountPoint = line.substring(idx).trim();
          if (Directory(mountPoint).existsSync()) {
            return mountPoint;
          }
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Unmounts / ejects a mounted `/Volumes/<Name>` disk image.
  static Future<bool> ejectVolume(String volumePath) async {
    try {
      final res = await Process.run('/usr/bin/hdiutil', [
        'detach',
        volumePath,
      ]);
      if (res.exitCode == 0) return true;
      final forceRes = await Process.run('/usr/bin/hdiutil', [
        'detach',
        '-force',
        volumePath,
      ]);
      return forceRes.exitCode == 0;
    } catch (_) {
      return false;
    }
  }

  /// Executes a script (.sh, .zsh, .command) or Unix binary inside macOS Terminal.app.
  static Future<bool> runExecutableInTerminal(String filePath) async {
    try {
      final file = File(filePath);
      if (!file.existsSync()) return false;
      final parentDir = file.parent.path;
      final ext = filePath.split('.').last.toLowerCase();
      if (const {'sh', 'zsh', 'command', 'bash'}.contains(ext)) {
        await Process.run('/bin/chmod', ['+x', filePath]);
      }
      if (ext == 'command') {
        return await openFile(filePath);
      }
      final escDir = parentDir.replaceAll("'", "'\\''");
      final escFile = filePath.replaceAll("'", "'\\''");
      final cmd = "cd '$escDir' && '$escFile'";
      final appleScript =
          'tell application "Terminal"\n'
          '  activate\n'
          '  do script "${cmd.replaceAll('\\', '\\\\').replaceAll('"', '\\"')}"\n'
          'end tell';
      final res = await Process.run('/usr/bin/osascript', ['-e', appleScript]);
      if (res.exitCode == 0) return true;
      await openTerminal(parentDir);
      return true;
    } catch (_) {
      return false;
    }
  }
}
