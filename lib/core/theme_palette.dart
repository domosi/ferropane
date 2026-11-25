import 'package:flutter/material.dart';
import 'models.dart';

enum TcThemeId {
  cyberDark('cyber_dark', 'Dark', Color(0xFF38BDF8), Brightness.dark),
  solarDay('solar_day', 'Day', Color(0xFFF59E0B), Brightness.light),
  classicTc('classic_tc', 'TC Blue', Color(0xFF00E5FF), Brightness.dark),
  dracula('dracula', 'Dracula', Color(0xFFFF79C6), Brightness.dark),
  emerald('emerald', 'Emerald', Color(0xFF10B981), Brightness.dark);

  final String key;
  final String shortLabel;
  final Color swatch;
  final Brightness brightness;

  const TcThemeId(this.key, this.shortLabel, this.swatch, this.brightness);

  static TcThemeId fromKey(String? key) {
    for (final t in TcThemeId.values) {
      if (t.key == key) return t;
    }
    return TcThemeId.cyberDark;
  }
}

class TcThemePalette {
  final TcThemeId id;
  final Brightness brightness;

  // Surfaces
  final Color windowBg;
  final Color toolbarBg;
  final Color paneBgEven;
  final Color paneBgOdd;
  final Color headerBg;
  final Color footerBg;
  final Color dividerColor;
  final Color activeBorder;
  final Color inactiveBorder;

  // Cursor & Selection (High-importance highlights)
  final Color cursorActiveBg;
  final Color cursorActiveBorder;
  final Color cursorActiveText;
  final Color cursorInactiveBg;
  final Color selectedRowBg;
  final Color selectedText;

  // Semantic Hierarchy: Important (Highlighted)
  final Color primaryAccent;
  final Color secondaryAccent;
  final Color dirText;
  final Color dirIcon;
  final Color fileImportantText;
  final Color execText;
  final Color archiveText;
  final Color codeText;
  final Color mediaText;

  // Semantic Hierarchy: Semi-Highlighted (Medium importance: Ext, Size, Breadcrumbs, Active Tabs)
  final Color semiHighlightedText;
  final Color largeSizeText;
  final Color extBadgeText;

  // Semantic Hierarchy: Low-Importance / Muted (Dates, Permissions, Hidden dotfiles, Inactive labels)
  final Color mutedText;
  final Color hiddenFileText;
  final Color dangerColor;

  const TcThemePalette({
    required this.id,
    required this.brightness,
    required this.windowBg,
    required this.toolbarBg,
    required this.paneBgEven,
    required this.paneBgOdd,
    required this.headerBg,
    required this.footerBg,
    required this.dividerColor,
    required this.activeBorder,
    required this.inactiveBorder,
    required this.cursorActiveBg,
    required this.cursorActiveBorder,
    required this.cursorActiveText,
    required this.cursorInactiveBg,
    required this.selectedRowBg,
    required this.selectedText,
    required this.primaryAccent,
    required this.secondaryAccent,
    required this.dirText,
    required this.dirIcon,
    required this.fileImportantText,
    required this.execText,
    required this.archiveText,
    required this.codeText,
    required this.mediaText,
    required this.semiHighlightedText,
    required this.largeSizeText,
    required this.extBadgeText,
    required this.mutedText,
    required this.hiddenFileText,
    required this.dangerColor,
  });

  bool get isLight => brightness == Brightness.light;

  /// Soft, readable row highlight tint for the active cursor row (Design B: soft surface tint + 4px left accent bar)
  Color get rowCursorBg {
    switch (id) {
      case TcThemeId.solarDay:
        return const Color(0xFFE0ECFF);
      case TcThemeId.cyberDark:
        return const Color(0xFF17263C);
      case TcThemeId.classicTc:
        return const Color(0xFF002D6B);
      case TcThemeId.dracula:
        return const Color(0xFF312C48);
      case TcThemeId.emerald:
        return const Color(0xFF14352C);
    }
  }

  static TcThemePalette of(TcThemeId id) {
    switch (id) {
      case TcThemeId.cyberDark:
        return const TcThemePalette(
          id: TcThemeId.cyberDark,
          brightness: Brightness.dark,
          windowBg: Color(0xFF0B0E14),
          toolbarBg: Color(0xFF131722),
          paneBgEven: Color(0xFF0F131C),
          paneBgOdd: Color(0xFF141925),
          headerBg: Color(0xFF1A2130),
          footerBg: Color(0xFF151B28),
          dividerColor: Color(0xFF263044),
          activeBorder: Color(0xFF38BDF8),
          inactiveBorder: Color(0xFF232B3E),
          cursorActiveBg: Color(0xFF0284C7),
          cursorActiveBorder: Color(0xFF7DD3FC),
          cursorActiveText: Color(0xFFFFFFFF),
          cursorInactiveBg: Color(0xFF1E293B),
          selectedRowBg: Color(0xFF3B2F0B),
          selectedText: Color(0xFFFACC15),
          primaryAccent: Color(0xFF38BDF8),
          secondaryAccent: Color(0xFF818CF8),
          dirText: Color(0xFF7DD3FC),
          dirIcon: Color(0xFF38BDF8),
          fileImportantText: Color(0xFFF8FAFC),
          execText: Color(0xFF4ADE80),
          archiveText: Color(0xFFFB923C),
          codeText: Color(0xFF2DD4BF),
          mediaText: Color(0xFFF472B6),
          semiHighlightedText: Color(0xFFCBD5E1),
          largeSizeText: Color(0xFFFBBF24),
          extBadgeText: Color(0xFF93C5FD),
          mutedText: Color(0xFF64748B),
          hiddenFileText: Color(0xFF475569),
          dangerColor: Color(0xFFEF4444),
        );

      case TcThemeId.solarDay:
        return const TcThemePalette(
          id: TcThemeId.solarDay,
          brightness: Brightness.light,
          windowBg: Color(0xFFE2E8F0),
          toolbarBg: Color(0xFFF1F5F9),
          paneBgEven: Color(0xFFFFFFFF),
          paneBgOdd: Color(0xFFF8FAFC),
          headerBg: Color(0xFFE2E8F0),
          footerBg: Color(0xFFF1F5F9),
          dividerColor: Color(0xFFCBD5E1),
          activeBorder: Color(0xFF2563EB),
          inactiveBorder: Color(0xFFCBD5E1),
          cursorActiveBg: Color(0xFF2563EB),
          cursorActiveBorder: Color(0xFF1D4ED8),
          cursorActiveText: Color(0xFFFFFFFF),
          cursorInactiveBg: Color(0xFFDBEAFE),
          selectedRowBg: Color(0xFFFEF3C7),
          selectedText: Color(0xFFB45309),
          primaryAccent: Color(0xFF2563EB),
          secondaryAccent: Color(0xFF4F46E5),
          dirText: Color(0xFF1E40AF),
          dirIcon: Color(0xFF2563EB),
          fileImportantText: Color(0xFF0F172A),
          execText: Color(0xFF15803D),
          archiveText: Color(0xFFC2410C),
          codeText: Color(0xFF0F766E),
          mediaText: Color(0xFFBE185D),
          semiHighlightedText: Color(0xFF334155),
          largeSizeText: Color(0xFFD97706),
          extBadgeText: Color(0xFF1D4ED8),
          mutedText: Color(0xFF94A3B8),
          hiddenFileText: Color(0xFFA1A1AA),
          dangerColor: Color(0xFFDC2626),
        );

      case TcThemeId.classicTc:
        return const TcThemePalette(
          id: TcThemeId.classicTc,
          brightness: Brightness.dark,
          windowBg: Color(0xFF001233),
          toolbarBg: Color(0xFF001845),
          paneBgEven: Color(0xFF001B48),
          paneBgOdd: Color(0xFF00225B),
          headerBg: Color(0xFF00286B),
          footerBg: Color(0xFF001845),
          dividerColor: Color(0xFF00509D),
          activeBorder: Color(0xFF00E5FF),
          inactiveBorder: Color(0xFF003F88),
          cursorActiveBg: Color(0xFF00B4D8),
          cursorActiveBorder: Color(0xFF90E0EF),
          cursorActiveText: Color(0xFF001233),
          cursorInactiveBg: Color(0xFF003566),
          selectedRowBg: Color(0xFF00296B),
          selectedText: Color(0xFFFFFF00),
          primaryAccent: Color(0xFF00E5FF),
          secondaryAccent: Color(0xFFFFD60A),
          dirText: Color(0xFFFFFFFF),
          dirIcon: Color(0xFF00E5FF),
          fileImportantText: Color(0xFFCAF0F8),
          execText: Color(0xFF52B788),
          archiveText: Color(0xFFFF9F1C),
          codeText: Color(0xFF48CAE4),
          mediaText: Color(0xFFFF70A6),
          semiHighlightedText: Color(0xFF90E0EF),
          largeSizeText: Color(0xFFFFD166),
          extBadgeText: Color(0xFF48CAE4),
          mutedText: Color(0xFF5C80BC),
          hiddenFileText: Color(0xFF415A77),
          dangerColor: Color(0xFFFF4D6D),
        );

      case TcThemeId.dracula:
        return const TcThemePalette(
          id: TcThemeId.dracula,
          brightness: Brightness.dark,
          windowBg: Color(0xFF191622),
          toolbarBg: Color(0xFF211E2E),
          paneBgEven: Color(0xFF201C2D),
          paneBgOdd: Color(0xFF262235),
          headerBg: Color(0xFF2D283E),
          footerBg: Color(0xFF211E2E),
          dividerColor: Color(0xFF44475A),
          activeBorder: Color(0xFFFF79C6),
          inactiveBorder: Color(0xFF383A4E),
          cursorActiveBg: Color(0xFF6272A4),
          cursorActiveBorder: Color(0xFFFF79C6),
          cursorActiveText: Color(0xFFFFFFFF),
          cursorInactiveBg: Color(0xFF343746),
          selectedRowBg: Color(0xFF3B3524),
          selectedText: Color(0xFFF1FA8C),
          primaryAccent: Color(0xFFFF79C6),
          secondaryAccent: Color(0xFFBD93F9),
          dirText: Color(0xFF8BE9FD),
          dirIcon: Color(0xFFBD93F9),
          fileImportantText: Color(0xFFF8F8F2),
          execText: Color(0xFF50FA7B),
          archiveText: Color(0xFFFFB86C),
          codeText: Color(0xFF8BE9FD),
          mediaText: Color(0xFFFF79C6),
          semiHighlightedText: Color(0xFFD6ACFF),
          largeSizeText: Color(0xFFFFB86C),
          extBadgeText: Color(0xFFBD93F9),
          mutedText: Color(0xFF6272A4),
          hiddenFileText: Color(0xFF51597E),
          dangerColor: Color(0xFFFF5555),
        );

      case TcThemeId.emerald:
        return const TcThemePalette(
          id: TcThemeId.emerald,
          brightness: Brightness.dark,
          windowBg: Color(0xFF07110E),
          toolbarBg: Color(0xFF0C1D18),
          paneBgEven: Color(0xFF0B1915),
          paneBgOdd: Color(0xFF10231D),
          headerBg: Color(0xFF142E26),
          footerBg: Color(0xFF0C1D18),
          dividerColor: Color(0xFF1E463A),
          activeBorder: Color(0xFF10B981),
          inactiveBorder: Color(0xFF16352C),
          cursorActiveBg: Color(0xFF059669),
          cursorActiveBorder: Color(0xFF6EE7B7),
          cursorActiveText: Color(0xFFFFFFFF),
          cursorInactiveBg: Color(0xFF16382E),
          selectedRowBg: Color(0xFF362E0D),
          selectedText: Color(0xFFFBBF24),
          primaryAccent: Color(0xFF10B981),
          secondaryAccent: Color(0xFF14B8A6),
          dirText: Color(0xFF34D399),
          dirIcon: Color(0xFF10B981),
          fileImportantText: Color(0xFFECFDF5),
          execText: Color(0xFFA3E635),
          archiveText: Color(0xFFFB923C),
          codeText: Color(0xFF2DD4BF),
          mediaText: Color(0xFFF472B6),
          semiHighlightedText: Color(0xFFA7F3D0),
          largeSizeText: Color(0xFFFBBF24),
          extBadgeText: Color(0xFF5EEAD4),
          mutedText: Color(0xFF4E8271),
          hiddenFileText: Color(0xFF386153),
          dangerColor: Color(0xFFF87171),
        );
    }
  }

  /// Resolves the foreground color for a file row (Design B: one calm, high-contrast neutral color for all filenames)
  Color resolveEntryNameColor(
    DirEntryModel entry, {
    required bool isActiveCursor,
  }) {
    if (entry.selected) return selectedText;
    if (entry.isHidden) return hiddenFileText;
    return fileImportantText;
  }

  /// Accent color for the inline `.ext` suffix
  Color resolveExtColor(DirEntryModel entry, {required bool isActiveCursor}) {
    if (entry.selected) return selectedText;
    if (entry.isHidden) return hiddenFileText;
    return primaryAccent;
  }

  /// Calm, readable color for the Size column
  Color resolveSizeColor(DirEntryModel entry, {required bool isActiveCursor}) {
    if (entry.selected) return selectedText;
    if (entry.isParent || (entry.isDir && !entry.sizeCalculated)) {
      return mutedText;
    }
    return fileImportantText;
  }

  /// Category-tinted icon color so icons carry semantic cues while filename text remains calm and neutral
  Color resolveEntryIconColor(DirEntryModel entry) {
    if (entry.selected) return selectedText;
    if (entry.isParent) return primaryAccent;
    if (entry.isAppBundle) return execText;
    if (entry.isDir) return dirIcon;
    if (entry.isHidden) return hiddenFileText;
    final ext = entry.ext.toLowerCase();
    if (_archiveExts.contains(ext)) return archiveText;
    if (_execExts.contains(ext) || entry.isExecutableScript) return execText;
    if (_codeExts.contains(ext)) return codeText;
    if (_mediaExts.contains(ext)) return mediaText;
    return semiHighlightedText;
  }

  static const Set<String> _archiveExts = {
    'zip',
    'tar',
    'gz',
    'tgz',
    'bz2',
    'xz',
    'zst',
    '7z',
    'rar',
    'dmg',
    'pkg',
    'iso',
  };

  static const Set<String> _execExts = {
    'sh',
    'zsh',
    'bash',
    'command',
    'app',
    'bin',
    'run',
  };

  static const Set<String> _codeExts = {
    'rs',
    'dart',
    'swift',
    'py',
    'js',
    'ts',
    'tsx',
    'jsx',
    'go',
    'c',
    'cpp',
    'h',
    'json',
    'yaml',
    'yml',
    'toml',
    'md',
    'html',
    'css',
    'sql',
    'lock',
  };

  static const Set<String> _mediaExts = {
    'png',
    'jpg',
    'jpeg',
    'gif',
    'webp',
    'svg',
    'ico',
    'icns',
    'mp4',
    'mov',
    'mkv',
    'mp3',
    'wav',
    'flac',
    'pdf',
  };
}
