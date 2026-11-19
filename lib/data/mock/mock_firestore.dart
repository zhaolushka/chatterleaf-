import 'dart:async';

/// In-memory store that mimics Firestore document paths + snapshot streams.
/// Paths look like: users/{uid}, greenhouses/{gid}, greenhouses/{gid}/devices/{id}
class MockFirestore {
  MockFirestore._();
  static final MockFirestore instance = MockFirestore._();

  final Map<String, Map<String, dynamic>> _docs = {};
  final Map<String, StreamController<Map<String, dynamic>?>> _docCtrls = {};
  final Map<String, StreamController<Map<String, Map<String, dynamic>>>>
      _colCtrls = {};

  void clear() {
    _docs.clear();
    for (final c in _docCtrls.values) {
      if (!c.isClosed) c.add(null);
    }
    for (final c in _colCtrls.values) {
      if (!c.isClosed) c.add({});
    }
  }

  Map<String, dynamic>? getDoc(String path) {
    final data = _docs[path];
    return data == null ? null : Map<String, dynamic>.from(data);
  }

  void setDoc(String path, Map<String, dynamic> data, {bool merge = false}) {
    final existing = _docs[path];
    final next = merge && existing != null
        ? {...existing, ...data}
        : Map<String, dynamic>.from(data);
    _docs[path] = next;
    _emitDoc(path);
    _emitCollectionFor(path);
  }

  void deleteDoc(String path) {
    _docs.remove(path);
    _emitDoc(path);
    _emitCollectionFor(path);
  }

  Stream<Map<String, dynamic>?> watchDoc(String path) {
    final ctrl = _docCtrls.putIfAbsent(
      path,
      () => StreamController<Map<String, dynamic>?>.broadcast(),
    );
    // Seed new listeners asynchronously so StreamBuilder gets first value.
    scheduleMicrotask(() => ctrl.add(getDoc(path)));
    return ctrl.stream;
  }

  /// Watches a collection path, e.g. greenhouses/{gid}/history
  Stream<Map<String, Map<String, dynamic>>> watchCollection(String colPath) {
    final ctrl = _colCtrls.putIfAbsent(
      colPath,
      () => StreamController<Map<String, Map<String, dynamic>>>.broadcast(),
    );
    scheduleMicrotask(() => ctrl.add(_collectionSnapshot(colPath)));
    return ctrl.stream;
  }

  Map<String, Map<String, dynamic>> _collectionSnapshot(String colPath) {
    final prefix = '$colPath/';
    final out = <String, Map<String, dynamic>>{};
    for (final entry in _docs.entries) {
      if (!entry.key.startsWith(prefix)) continue;
      final rest = entry.key.substring(prefix.length);
      if (rest.contains('/')) continue; // only direct children
      out[rest] = Map<String, dynamic>.from(entry.value);
    }
    return out;
  }

  void _emitDoc(String path) {
    final ctrl = _docCtrls[path];
    if (ctrl != null && !ctrl.isClosed) {
      ctrl.add(getDoc(path));
    }
  }

  void _emitCollectionFor(String docPath) {
    final slash = docPath.lastIndexOf('/');
    if (slash <= 0) return;
    final colPath = docPath.substring(0, slash);
    final ctrl = _colCtrls[colPath];
    if (ctrl != null && !ctrl.isClosed) {
      ctrl.add(_collectionSnapshot(colPath));
    }
  }

  /// Deletes every doc under a collection path.
  void clearCollection(String colPath) {
    final prefix = '$colPath/';
    final keys = _docs.keys.where((k) => k.startsWith(prefix)).toList();
    for (final k in keys) {
      _docs.remove(k);
    }
    final ctrl = _colCtrls[colPath];
    if (ctrl != null && !ctrl.isClosed) {
      ctrl.add({});
    }
  }
}
