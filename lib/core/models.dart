enum UiFrameworkMode {
  macos('macos', 'macOS Desktop UI'),
  material3('material3', 'Material 3 UI');

  final String key;
  final String label;
  const UiFrameworkMode(this.key, this.label);

  static UiFrameworkMode fromKey(String? key) {
    if (key == 'material3') return UiFrameworkMode.material3;
    return UiFrameworkMode.macos;
  }
}

enum SortField {
  name(0, 'Name'),
  extension(1, 'Ext'),
  size(2, 'Size'),
  modified(3, 'Date');

  final int code;
  final String label;
  const SortField(this.code, this.label);

  static SortField fromCode(int code) {
    for (final f in SortField.values) {
      if (f.code == code) return f;
    }
    return SortField.name;
  }
}

class DirEntryModel {
  final String name;
  final String stem;
  final String ext;
  final String fullPath;
  final int size;
  final bool sizeCalculated;
  final int modifiedSec;
  final bool isDir;
  final bool isParent;
  final bool isSymlink;
  final bool isHidden;
  final String permissions;
  final bool selected;

  const DirEntryModel({
    required this.name,
    required this.stem,
    required this.ext,
    required this.fullPath,
    required this.size,
    required this.sizeCalculated,
    required this.modifiedSec,
    required this.isDir,
    required this.isParent,
    required this.isSymlink,
    required this.isHidden,
    required this.permissions,
    required this.selected,
  });

  factory DirEntryModel.fromJson(Map<String, dynamic> json) {
    return DirEntryModel(
      name: json['name'] as String? ?? '',
      stem: json['stem'] as String? ?? '',
      ext: json['ext'] as String? ?? '',
      fullPath: json['full_path'] as String? ?? '',
      size: (json['size'] as num?)?.toInt() ?? 0,
      sizeCalculated: json['size_calculated'] as bool? ?? false,
      modifiedSec: (json['modified_sec'] as num?)?.toInt() ?? 0,
      isDir: json['is_dir'] as bool? ?? false,
      isParent: json['is_parent'] as bool? ?? false,
      isSymlink: json['is_symlink'] as bool? ?? false,
      isHidden: json['is_hidden'] as bool? ?? false,
      permissions: json['permissions'] as String? ?? '----------',
      selected: json['selected'] as bool? ?? false,
    );
  }

  String get displaySize {
    if (isParent) return '<UP--DIR>';
    if (isAppBundle) return '<APP>';
    if (isDir && !sizeCalculated) return '<DIR>';
    return formatBytes(size);
  }

  bool get isAppBundle {
    return isDir && !isParent && name.toLowerCase().endsWith('.app');
  }

  bool get isArchive {
    if (isDir || isParent) return false;
    final lower = name.toLowerCase();
    return lower.endsWith('.zip') ||
        lower.endsWith('.tar.gz') ||
        lower.endsWith('.tgz') ||
        lower.endsWith('.tar') ||
        lower.endsWith('.tar.bz2') ||
        lower.endsWith('.tbz2') ||
        lower.endsWith('.tar.xz') ||
        lower.endsWith('.txz');
  }

  String get archiveBaseName {
    final lower = name.toLowerCase();
    for (final suffix in [
      '.tar.gz',
      '.tar.bz2',
      '.tar.xz',
      '.tgz',
      '.tbz2',
      '.txz',
      '.zip',
      '.tar',
    ]) {
      if (lower.endsWith(suffix) && name.length > suffix.length) {
        return name.substring(0, name.length - suffix.length);
      }
    }
    return stem;
  }

  bool get isDiskImage {
    return !isDir && !isParent && ext.toLowerCase() == 'dmg';
  }

  bool get isPkgInstaller {
    return !isParent && ext.toLowerCase() == 'pkg';
  }

  bool get isExecutableScript {
    if (isDir || isParent) return false;
    final lowerExt = ext.toLowerCase();
    if (const {'sh', 'zsh', 'command', 'bash'}.contains(lowerExt)) {
      return true;
    }
    // Unix executable file (+x) without a common document/archive extension
    if (permissions.contains('x') &&
        !isArchive &&
        !isDiskImage &&
        !const {
          'txt',
          'md',
          'json',
          'yaml',
          'yml',
          'xml',
          'html',
          'css',
          'js',
          'ts',
          'dart',
          'rs',
          'c',
          'cpp',
          'h',
          'png',
          'jpg',
          'jpeg',
          'gif',
          'webp',
          'svg',
          'pdf',
          'mp3',
          'mp4',
          'mov',
          'wav',
          'dmg',
          'pkg',
        }.contains(lowerExt)) {
      return true;
    }
    return false;
  }

  String get typeBadge {
    if (isParent) return 'Parent';
    if (isAppBundle) return 'APP';
    if (isDir) return 'Folder';
    if (ext.isNotEmpty) {
      final upper = ext.toUpperCase();
      return upper.length > 6 ? upper.substring(0, 6) : upper;
    }
    if (isExecutableScript) return 'EXEC';
    if (isSymlink) return 'LINK';
    return 'File';
  }

  String get displayDate {
    if (isParent || modifiedSec <= 0) return '';
    final dt = DateTime.fromMillisecondsSinceEpoch(modifiedSec * 1000);
    final now = DateTime.now();
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');

    final today = DateTime(now.year, now.month, now.day);
    final fileDay = DateTime(dt.year, dt.month, dt.day);
    final diffDays = today.difference(fileDay).inDays;

    if (diffDays == 0) {
      return 'Today $hh:$mm';
    }
    if (diffDays == 1) {
      return 'Yesterday $hh:$mm';
    }
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final mName = months[(dt.month - 1).clamp(0, 11)];
    if (dt.year == now.year) {
      return '$mName ${dt.day}, $hh:$mm';
    }
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}

class PaneSummaryModel {
  final String currentPath;
  final int totalRows;
  final int totalFiles;
  final int totalDirs;
  final int selectedFiles;
  final int selectedDirs;
  final int selectedBytes;
  final int totalBytes;
  final int volumeFreeBytes;
  final int volumeTotalBytes;
  final SortField sortField;
  final bool sortAscending;
  final bool showHidden;
  final String filterQuery;
  final String? errorMessage;

  const PaneSummaryModel({
    required this.currentPath,
    required this.totalRows,
    required this.totalFiles,
    required this.totalDirs,
    required this.selectedFiles,
    required this.selectedDirs,
    required this.selectedBytes,
    required this.totalBytes,
    required this.volumeFreeBytes,
    required this.volumeTotalBytes,
    required this.sortField,
    required this.sortAscending,
    required this.showHidden,
    required this.filterQuery,
    this.errorMessage,
  });

  factory PaneSummaryModel.empty(String path) => PaneSummaryModel(
    currentPath: path,
    totalRows: 0,
    totalFiles: 0,
    totalDirs: 0,
    selectedFiles: 0,
    selectedDirs: 0,
    selectedBytes: 0,
    totalBytes: 0,
    volumeFreeBytes: 0,
    volumeTotalBytes: 0,
    sortField: SortField.name,
    sortAscending: true,
    showHidden: false,
    filterQuery: '',
  );

  factory PaneSummaryModel.fromJson(Map<String, dynamic> json) {
    return PaneSummaryModel(
      currentPath: json['current_path'] as String? ?? '/',
      totalRows: (json['total_rows'] as num?)?.toInt() ?? 0,
      totalFiles: (json['total_files'] as num?)?.toInt() ?? 0,
      totalDirs: (json['total_dirs'] as num?)?.toInt() ?? 0,
      selectedFiles: (json['selected_files'] as num?)?.toInt() ?? 0,
      selectedDirs: (json['selected_dirs'] as num?)?.toInt() ?? 0,
      selectedBytes: (json['selected_bytes'] as num?)?.toInt() ?? 0,
      totalBytes: (json['total_bytes'] as num?)?.toInt() ?? 0,
      volumeFreeBytes: (json['volume_free_bytes'] as num?)?.toInt() ?? 0,
      volumeTotalBytes: (json['volume_total_bytes'] as num?)?.toInt() ?? 0,
      sortField: SortField.fromCode((json['sort_field'] as num?)?.toInt() ?? 0),
      sortAscending: json['sort_ascending'] as bool? ?? true,
      showHidden: json['show_hidden'] as bool? ?? false,
      filterQuery: json['filter_query'] as String? ?? '',
      errorMessage: json['error_message'] as String?,
    );
  }
}

class FileOpResultModel {
  final bool ok;
  final int processedCount;
  final String message;

  const FileOpResultModel({
    required this.ok,
    required this.processedCount,
    required this.message,
  });

  factory FileOpResultModel.fromJson(Map<String, dynamic> json) {
    return FileOpResultModel(
      ok: json['ok'] as bool? ?? false,
      processedCount: (json['processed_count'] as num?)?.toInt() ?? 0,
      message: json['message'] as String? ?? '',
    );
  }
}

class ListerSliceModel {
  final bool ok;
  final String filePath;
  final int fileSize;
  final int offset;
  final int length;
  final bool isBinary;
  final String mode;
  final String content;
  final String? error;

  const ListerSliceModel({
    required this.ok,
    required this.filePath,
    required this.fileSize,
    required this.offset,
    required this.length,
    required this.isBinary,
    required this.mode,
    required this.content,
    this.error,
  });

  factory ListerSliceModel.fromJson(Map<String, dynamic> json) {
    return ListerSliceModel(
      ok: json['ok'] as bool? ?? false,
      filePath: json['file_path'] as String? ?? '',
      fileSize: (json['file_size'] as num?)?.toInt() ?? 0,
      offset: (json['offset'] as num?)?.toInt() ?? 0,
      length: (json['length'] as num?)?.toInt() ?? 0,
      isBinary: json['is_binary'] as bool? ?? false,
      mode: json['mode'] as String? ?? 'text',
      content: json['content'] as String? ?? '',
      error: json['error'] as String?,
    );
  }
}

class CompareEntryModel {
  final String relPath;
  final bool isDir;
  final String status; // "only_left", "only_right", "different", "identical"
  final String newerSide; // "left", "right", "same"
  final int leftSize;
  final int rightSize;
  final int leftModified;
  final int rightModified;

  const CompareEntryModel({
    required this.relPath,
    required this.isDir,
    required this.status,
    required this.newerSide,
    required this.leftSize,
    required this.rightSize,
    required this.leftModified,
    required this.rightModified,
  });

  factory CompareEntryModel.fromJson(Map<String, dynamic> json) {
    return CompareEntryModel(
      relPath: json['rel_path'] as String? ?? '',
      isDir: json['is_dir'] as bool? ?? false,
      status: json['status'] as String? ?? 'identical',
      newerSide: json['newer_side'] as String? ?? 'same',
      leftSize: (json['left_size'] as num?)?.toInt() ?? 0,
      rightSize: (json['right_size'] as num?)?.toInt() ?? 0,
      leftModified: (json['left_modified'] as num?)?.toInt() ?? 0,
      rightModified: (json['right_modified'] as num?)?.toInt() ?? 0,
    );
  }
}

class DirCompareResultModel {
  final bool ok;
  final String leftRoot;
  final String rightRoot;
  final bool compareContent;
  final int onlyLeftCount;
  final int onlyRightCount;
  final int differentCount;
  final int identicalCount;
  final List<CompareEntryModel> items;
  final String? error;

  const DirCompareResultModel({
    required this.ok,
    required this.leftRoot,
    required this.rightRoot,
    required this.compareContent,
    required this.onlyLeftCount,
    required this.onlyRightCount,
    required this.differentCount,
    required this.identicalCount,
    required this.items,
    this.error,
  });

  factory DirCompareResultModel.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List<dynamic>? ?? const [];
    return DirCompareResultModel(
      ok: json['ok'] as bool? ?? false,
      leftRoot: json['left_root'] as String? ?? '',
      rightRoot: json['right_root'] as String? ?? '',
      compareContent: json['compare_content'] as bool? ?? false,
      onlyLeftCount: (json['only_left_count'] as num?)?.toInt() ?? 0,
      onlyRightCount: (json['only_right_count'] as num?)?.toInt() ?? 0,
      differentCount: (json['different_count'] as num?)?.toInt() ?? 0,
      identicalCount: (json['identical_count'] as num?)?.toInt() ?? 0,
      items: rawItems
          .map((e) => CompareEntryModel.fromJson(e as Map<String, dynamic>))
          .toList(growable: false),
      error: json['error'] as String?,
    );
  }
}

class FavoriteFolderItem {
  final String label;
  final String path;
  final String category; // 'Pinned', 'macOS Favorites', 'Volumes'
  final bool isCustomPinned;

  const FavoriteFolderItem({
    required this.label,
    required this.path,
    required this.category,
    this.isCustomPinned = false,
  });
}

class SearchHitModel {
  final String name;
  final String relPath;
  final String fullPath;
  final String parentDir;
  final bool isDir;
  final int size;
  final int modifiedSec;
  final bool isPrefixMatch;
  final String? matchedLine;

  const SearchHitModel({
    required this.name,
    required this.relPath,
    required this.fullPath,
    required this.parentDir,
    required this.isDir,
    required this.size,
    required this.modifiedSec,
    required this.isPrefixMatch,
    this.matchedLine,
  });

  factory SearchHitModel.fromJson(Map<String, dynamic> json) {
    return SearchHitModel(
      name: json['name'] as String? ?? '',
      relPath: json['rel_path'] as String? ?? '',
      fullPath: json['full_path'] as String? ?? '',
      parentDir: json['parent_dir'] as String? ?? '',
      isDir: json['is_dir'] as bool? ?? false,
      size: (json['size'] as num?)?.toInt() ?? 0,
      modifiedSec: (json['modified_sec'] as num?)?.toInt() ?? 0,
      isPrefixMatch: json['is_prefix_match'] as bool? ?? false,
      matchedLine: json['matched_line'] as String?,
    );
  }
}

class DirSearchResultModel {
  final bool ok;
  final String rootDir;
  final int scannedCount;
  final List<SearchHitModel> items;
  final String? error;

  const DirSearchResultModel({
    required this.ok,
    required this.rootDir,
    required this.scannedCount,
    required this.items,
    this.error,
  });

  factory DirSearchResultModel.fromJson(Map<String, dynamic> json) {
    final raw = json['items'] as List<dynamic>? ?? const [];
    return DirSearchResultModel(
      ok: json['ok'] as bool? ?? false,
      rootDir: json['root_dir'] as String? ?? '',
      scannedCount: (json['scanned_count'] as num?)?.toInt() ?? 0,
      items: raw
          .map((e) => SearchHitModel.fromJson(e as Map<String, dynamic>))
          .toList(growable: false),
      error: json['error'] as String?,
    );
  }
}

String formatBytes(int bytes) {
  if (bytes < 1024) return '$bytes B';
  final kb = bytes / 1024.0;
  if (kb < 1024) return '${kb.toStringAsFixed(1)} KB';
  final mb = kb / 1024.0;
  if (mb < 1024) return '${mb.toStringAsFixed(1)} MB';
  final gb = mb / 1024.0;
  if (gb < 1024) return '${gb.toStringAsFixed(2)} GB';
  final tb = gb / 1024.0;
  return '${tb.toStringAsFixed(2)} TB';
}
