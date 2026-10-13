import 'dart:async';

import 'package:core/core.dart';

/// A [RemoteFlags] whose values the test sets.
class FakeRemoteFlags implements RemoteFlags {
  final Map<String, String> values = <String, String>{};
  final StreamController<void> _changes = StreamController<void>.broadcast();
  int refreshCount = 0;

  /// Values the next [refresh] fetches, without emitting [onChanged], like a
  /// fetch that finds newer values while the real-time listener is silent.
  Map<String, String>? nextFetch;

  /// While set, [refresh] waits for it before applying [nextFetch], like a
  /// fetch still on the network.
  Completer<void>? refreshGate;

  /// Changes the values and emits [onChanged], like a real-time update.
  void change(Map<String, String> newValues) {
    values
      ..clear()
      ..addAll(newValues);
    _changes.add(null);
  }

  @override
  bool getBool(String key, {required bool fallback}) => fallback;

  @override
  int getInt(String key, {required int fallback}) => fallback;

  @override
  String getString(String key, {required String fallback}) =>
      values[key] ?? fallback;

  @override
  Future<void> refresh() async {
    refreshCount++;
    await refreshGate?.future;
    final Map<String, String>? fetched = nextFetch;
    if (fetched == null) return;
    nextFetch = null;
    values
      ..clear()
      ..addAll(fetched);
  }

  @override
  Stream<void> get onChanged => _changes.stream;

  Future<void> close() => _changes.close();
}
