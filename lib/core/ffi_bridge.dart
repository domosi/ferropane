import 'dart:convert';
import 'dart:ffi' as ffi;
import 'dart:io';
import 'package:ffi/ffi.dart';
import 'models.dart';

typedef _TcStringFreeC = ffi.Void Function(ffi.Pointer<Utf8>);
typedef _TcStringFreeDart = void Function(ffi.Pointer<Utf8>);

typedef _TcPaneCreateC = ffi.Uint32 Function(ffi.Pointer<Utf8>);
typedef _TcPaneCreateDart = int Function(ffi.Pointer<Utf8>);

typedef _TcPaneDestroyC = ffi.Void Function(ffi.Uint32);
typedef _TcPaneDestroyDart = void Function(int);

typedef _TcPaneLoadDirC = ffi.Bool Function(ffi.Uint32, ffi.Pointer<Utf8>);
typedef _TcPaneLoadDirDart = bool Function(int, ffi.Pointer<Utf8>);

typedef _TcPaneReloadC = ffi.Void Function(ffi.Uint32);
typedef _TcPaneReloadDart = void Function(int);

typedef _TcPaneSetSortC = ffi.Void Function(ffi.Uint32, ffi.Uint8, ffi.Bool);
typedef _TcPaneSetSortDart = void Function(int, int, bool);

typedef _TcPaneSetHiddenC = ffi.Void Function(ffi.Uint32, ffi.Bool);
typedef _TcPaneSetHiddenDart = void Function(int, bool);

typedef _TcPaneSetFilterC = ffi.Void Function(ffi.Uint32, ffi.Pointer<Utf8>);
typedef _TcPaneSetFilterDart = void Function(int, ffi.Pointer<Utf8>);

typedef _TcPaneToggleSelectC = ffi.Bool Function(ffi.Uint32, ffi.Size, ffi.Bool);
typedef _TcPaneToggleSelectDart = bool Function(int, int, bool);

typedef _TcPaneSelectAllC = ffi.Void Function(ffi.Uint32, ffi.Bool);
typedef _TcPaneSelectAllDart = void Function(int, bool);

typedef _TcPaneInvertSelectC = ffi.Void Function(ffi.Uint32);
typedef _TcPaneInvertSelectDart = void Function(int);

typedef _TcPaneSelectPatternC =
    ffi.Void Function(ffi.Uint32, ffi.Pointer<Utf8>, ffi.Bool);
typedef _TcPaneSelectPatternDart = void Function(int, ffi.Pointer<Utf8>, bool);

typedef _TcPaneSummaryJsonC = ffi.Pointer<Utf8> Function(ffi.Uint32);
typedef _TcPaneSummaryJsonDart = ffi.Pointer<Utf8> Function(int);

typedef _TcPaneSliceJsonC =
    ffi.Pointer<Utf8> Function(ffi.Uint32, ffi.Size, ffi.Size);
typedef _TcPaneSliceJsonDart = ffi.Pointer<Utf8> Function(int, int, int);

typedef _TcPaneSelectedPathsJsonC = ffi.Pointer<Utf8> Function(ffi.Uint32);
typedef _TcPaneSelectedPathsJsonDart = ffi.Pointer<Utf8> Function(int);

typedef _TcOpsTwoStrC =
    ffi.Pointer<Utf8> Function(ffi.Pointer<Utf8>, ffi.Pointer<Utf8>);
typedef _TcOpsTwoStrDart =
    ffi.Pointer<Utf8> Function(ffi.Pointer<Utf8>, ffi.Pointer<Utf8>);

typedef _TcOpsDeleteC =
    ffi.Pointer<Utf8> Function(ffi.Pointer<Utf8>, ffi.Bool);
typedef _TcOpsDeleteDart =
    ffi.Pointer<Utf8> Function(ffi.Pointer<Utf8>, bool);

typedef _TcListerReadC =
    ffi.Pointer<Utf8> Function(
      ffi.Pointer<Utf8>,
      ffi.Uint64,
      ffi.Size,
      ffi.Bool,
    );
typedef _TcListerReadDart =
    ffi.Pointer<Utf8> Function(ffi.Pointer<Utf8>, int, int, bool);

typedef _TcCompareDirsC =
    ffi.Pointer<Utf8> Function(
      ffi.Pointer<Utf8>,
      ffi.Pointer<Utf8>,
      ffi.Bool,
      ffi.Bool,
    );
typedef _TcCompareDirsDart =
    ffi.Pointer<Utf8> Function(
      ffi.Pointer<Utf8>,
      ffi.Pointer<Utf8>,
      bool,
      bool,
    );

typedef _TcSearchDirC =
    ffi.Pointer<Utf8> Function(
      ffi.Pointer<Utf8>,
      ffi.Pointer<Utf8>,
      ffi.Pointer<Utf8>,
      ffi.Bool,
      ffi.Bool,
      ffi.Size,
    );
typedef _TcSearchDirDart =
    ffi.Pointer<Utf8> Function(
      ffi.Pointer<Utf8>,
      ffi.Pointer<Utf8>,
      ffi.Pointer<Utf8>,
      bool,
      bool,
      int,
    );

class TcRustBridge {
  static TcRustBridge? _instance;
  static TcRustBridge get instance => _instance ??= TcRustBridge._init();

  late final ffi.DynamicLibrary _lib;
  late final _TcStringFreeDart _stringFree;
  late final _TcPaneCreateDart _paneCreate;
  late final _TcPaneDestroyDart _paneDestroy;
  late final _TcPaneLoadDirDart _paneLoadDir;
  late final _TcPaneReloadDart _paneReload;
  late final _TcPaneSetSortDart _paneSetSort;
  late final _TcPaneSetHiddenDart _paneSetHidden;
  late final _TcPaneSetFilterDart _paneSetFilter;
  late final _TcPaneToggleSelectDart _paneToggleSelect;
  late final _TcPaneSelectAllDart _paneSelectAll;
  late final _TcPaneInvertSelectDart _paneInvertSelect;
  late final _TcPaneSelectPatternDart _paneSelectPattern;
  late final _TcPaneSummaryJsonDart _paneSummaryJson;
  late final _TcPaneSliceJsonDart _paneSliceJson;
  late final _TcPaneSelectedPathsJsonDart _paneSelectedPathsJson;
  late final _TcOpsTwoStrDart _opsCopy;
  late final _TcOpsTwoStrDart _opsMove;
  late final _TcOpsTwoStrDart _opsMkdir;
  late final _TcOpsDeleteDart _opsDelete;
  late final _TcListerReadDart _listerRead;
  late final _TcCompareDirsDart _compareDirs;
  late final _TcSearchDirDart _searchDir;

  TcRustBridge._init() {
    _lib = _openLibrary();
    _stringFree = _lib
        .lookupFunction<_TcStringFreeC, _TcStringFreeDart>('tc_string_free');
    _paneCreate = _lib
        .lookupFunction<_TcPaneCreateC, _TcPaneCreateDart>('tc_pane_create');
    _paneDestroy = _lib
        .lookupFunction<_TcPaneDestroyC, _TcPaneDestroyDart>('tc_pane_destroy');
    _paneLoadDir = _lib
        .lookupFunction<_TcPaneLoadDirC, _TcPaneLoadDirDart>('tc_pane_load_dir');
    _paneReload = _lib
        .lookupFunction<_TcPaneReloadC, _TcPaneReloadDart>('tc_pane_reload');
    _paneSetSort = _lib
        .lookupFunction<_TcPaneSetSortC, _TcPaneSetSortDart>('tc_pane_set_sort');
    _paneSetHidden = _lib
        .lookupFunction<_TcPaneSetHiddenC, _TcPaneSetHiddenDart>(
          'tc_pane_set_hidden',
        );
    _paneSetFilter = _lib
        .lookupFunction<_TcPaneSetFilterC, _TcPaneSetFilterDart>(
          'tc_pane_set_filter',
        );
    _paneToggleSelect = _lib
        .lookupFunction<_TcPaneToggleSelectC, _TcPaneToggleSelectDart>(
          'tc_pane_toggle_select',
        );
    _paneSelectAll = _lib
        .lookupFunction<_TcPaneSelectAllC, _TcPaneSelectAllDart>(
          'tc_pane_select_all',
        );
    _paneInvertSelect = _lib
        .lookupFunction<_TcPaneInvertSelectC, _TcPaneInvertSelectDart>(
          'tc_pane_invert_selection',
        );
    _paneSelectPattern = _lib
        .lookupFunction<_TcPaneSelectPatternC, _TcPaneSelectPatternDart>(
          'tc_pane_select_pattern',
        );
    _paneSummaryJson = _lib
        .lookupFunction<_TcPaneSummaryJsonC, _TcPaneSummaryJsonDart>(
          'tc_pane_summary_json',
        );
    _paneSliceJson = _lib
        .lookupFunction<_TcPaneSliceJsonC, _TcPaneSliceJsonDart>(
          'tc_pane_slice_json',
        );
    _paneSelectedPathsJson = _lib
        .lookupFunction<
          _TcPaneSelectedPathsJsonC,
          _TcPaneSelectedPathsJsonDart
        >('tc_pane_selected_paths_json');
    _opsCopy = _lib
        .lookupFunction<_TcOpsTwoStrC, _TcOpsTwoStrDart>('tc_ops_copy');
    _opsMove = _lib
        .lookupFunction<_TcOpsTwoStrC, _TcOpsTwoStrDart>('tc_ops_move');
    _opsMkdir = _lib
        .lookupFunction<_TcOpsTwoStrC, _TcOpsTwoStrDart>('tc_ops_mkdir');
    _opsDelete = _lib
        .lookupFunction<_TcOpsDeleteC, _TcOpsDeleteDart>('tc_ops_delete');
    _listerRead = _lib
        .lookupFunction<_TcListerReadC, _TcListerReadDart>('tc_lister_read');
    _compareDirs = _lib
        .lookupFunction<_TcCompareDirsC, _TcCompareDirsDart>('tc_compare_dirs');
    _searchDir = _lib
        .lookupFunction<_TcSearchDirC, _TcSearchDirDart>('tc_search_dir');
  }

  static ffi.DynamicLibrary _openLibrary() {
    final exeDir = File(Platform.resolvedExecutable).parent.path;
    final candidates = <String>[
      '$exeDir/../Frameworks/libtc_core.dylib',
      '${Directory.current.path}/rust/target/release/libtc_core.dylib',
      '${Directory.current.path}/rust/target/debug/libtc_core.dylib',
      '/Users/domosi/dev/ferropane/rust/target/release/libtc_core.dylib',
      '/Users/domosi/dev/ferropane/rust/target/debug/libtc_core.dylib',
      '/Users/domosi/dev/tc-mac/rust/target/release/libtc_core.dylib',
      '/Users/domosi/dev/tc-mac/rust/target/debug/libtc_core.dylib',
    ];
    for (final path in candidates) {
      if (File(path).existsSync()) {
        return ffi.DynamicLibrary.open(path);
      }
    }
    return ffi.DynamicLibrary.open('libtc_core.dylib');
  }

  String _consumeRustString(ffi.Pointer<Utf8> ptr) {
    if (ptr == ffi.nullptr) return '';
    try {
      return ptr.toDartString();
    } finally {
      _stringFree(ptr);
    }
  }

  int createPane(String initialPath) {
    final cPath = initialPath.toNativeUtf8();
    try {
      return _paneCreate(cPath);
    } finally {
      calloc.free(cPath);
    }
  }

  void destroyPane(int paneId) => _paneDestroy(paneId);

  bool loadDirectory(int paneId, String path) {
    final cPath = path.toNativeUtf8();
    try {
      return _paneLoadDir(paneId, cPath);
    } finally {
      calloc.free(cPath);
    }
  }

  void reloadPane(int paneId) => _paneReload(paneId);

  void setSort(int paneId, SortField field, bool ascending) {
    _paneSetSort(paneId, field.code, ascending);
  }

  void setShowHidden(int paneId, bool showHidden) {
    _paneSetHidden(paneId, showHidden);
  }

  void setFilter(int paneId, String query) {
    final cQuery = query.toNativeUtf8();
    try {
      _paneSetFilter(paneId, cQuery);
    } finally {
      calloc.free(cQuery);
    }
  }

  bool toggleSelect(int paneId, int visibleRow, {bool calcDirSize = false}) {
    return _paneToggleSelect(paneId, visibleRow, calcDirSize);
  }

  void selectAll(int paneId, bool select) => _paneSelectAll(paneId, select);

  void invertSelection(int paneId) => _paneInvertSelect(paneId);

  void selectByPattern(int paneId, String pattern, bool select) {
    final cPat = pattern.toNativeUtf8();
    try {
      _paneSelectPattern(paneId, cPat, select);
    } finally {
      calloc.free(cPat);
    }
  }

  PaneSummaryModel getSummary(int paneId) {
    final raw = _consumeRustString(_paneSummaryJson(paneId));
    if (raw.isEmpty) return PaneSummaryModel.empty('/');
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    return PaneSummaryModel.fromJson(decoded);
  }

  List<DirEntryModel> getVisibleSlice(int paneId, int start, int count) {
    final raw = _consumeRustString(_paneSliceJson(paneId, start, count));
    if (raw.isEmpty) return const [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((e) => DirEntryModel.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
  }

  List<String> getSelectedPaths(int paneId) {
    final raw = _consumeRustString(_paneSelectedPathsJson(paneId));
    if (raw.isEmpty) return const [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list.map((e) => e.toString()).toList(growable: false);
  }

  FileOpResultModel copyItems(List<String> sources, String destDir) {
    final cSrc = jsonEncode(sources).toNativeUtf8();
    final cDst = destDir.toNativeUtf8();
    try {
      final raw = _consumeRustString(_opsCopy(cSrc, cDst));
      return FileOpResultModel.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
    } finally {
      calloc.free(cSrc);
      calloc.free(cDst);
    }
  }

  FileOpResultModel moveItems(List<String> sources, String destDir) {
    final cSrc = jsonEncode(sources).toNativeUtf8();
    final cDst = destDir.toNativeUtf8();
    try {
      final raw = _consumeRustString(_opsMove(cSrc, cDst));
      return FileOpResultModel.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
    } finally {
      calloc.free(cSrc);
      calloc.free(cDst);
    }
  }

  FileOpResultModel createDirectory(String baseDir, String name) {
    final cBase = baseDir.toNativeUtf8();
    final cName = name.toNativeUtf8();
    try {
      final raw = _consumeRustString(_opsMkdir(cBase, cName));
      return FileOpResultModel.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
    } finally {
      calloc.free(cBase);
      calloc.free(cName);
    }
  }

  FileOpResultModel deleteItems(List<String> sources, {bool useTrash = true}) {
    final cSrc = jsonEncode(sources).toNativeUtf8();
    try {
      final raw = _consumeRustString(_opsDelete(cSrc, useTrash));
      return FileOpResultModel.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
    } finally {
      calloc.free(cSrc);
    }
  }

  ListerSliceModel readListerSlice(
    String filePath, {
    int offset = 0,
    int maxBytes = 16384,
    bool hexMode = false,
  }) {
    final cPath = filePath.toNativeUtf8();
    try {
      final raw = _consumeRustString(
        _listerRead(cPath, offset, maxBytes, hexMode),
      );
      return ListerSliceModel.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } finally {
      calloc.free(cPath);
    }
  }

  DirCompareResultModel compareDirectories(
    String leftDir,
    String rightDir, {
    required bool compareContent,
    required bool showHidden,
  }) {
    final cLeft = leftDir.toNativeUtf8();
    final cRight = rightDir.toNativeUtf8();
    try {
      final raw = _consumeRustString(
        _compareDirs(cLeft, cRight, compareContent, showHidden),
      );
      return DirCompareResultModel.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
    } finally {
      calloc.free(cLeft);
      calloc.free(cRight);
    }
  }

  DirSearchResultModel searchDirectory(
    String rootDir, {
    required String nameQuery,
    String contentQuery = '',
    bool recursive = true,
    bool showHidden = false,
    int maxResults = 300,
  }) {
    final cRoot = rootDir.toNativeUtf8();
    final cName = nameQuery.toNativeUtf8();
    final cContent = contentQuery.toNativeUtf8();
    try {
      final raw = _consumeRustString(
        _searchDir(
          cRoot,
          cName,
          cContent,
          recursive,
          showHidden,
          maxResults,
        ),
      );
      return DirSearchResultModel.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
    } finally {
      calloc.free(cRoot);
      calloc.free(cName);
      calloc.free(cContent);
    }
  }
}
