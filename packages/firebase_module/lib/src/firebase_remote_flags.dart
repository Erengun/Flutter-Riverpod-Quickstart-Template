import 'dart:async';

import 'package:core/core.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:logging/logging.dart';

final Logger _log = Logger('firebase.remote_config');

const Set<String> _trueValues = <String>{'1', 'true', 't', 'yes', 'y', 'on'};
const Set<String> _falseValues = <String>{'0', 'false', 'f', 'no', 'n', 'off'};

/// Core's [RemoteFlags] backed by Firebase Remote Config.
///
/// - Reads return the caller's fallback for a key Remote Config has no value
///   for, or whose value has the wrong type.
/// - [refresh] fetches within the throttle set on Remote Config and never
///   throws: when the fetch fails, the cached values stay (fail-open).
/// - [onChanged] emits after new values are activated, by [refresh] or by
///   Remote Config's real-time listener, so reads already see them.
class FirebaseRemoteFlags implements RemoteFlags {
  FirebaseRemoteFlags(this._config);

  final FirebaseRemoteConfig _config;
  final StreamController<void> _changes = StreamController<void>.broadcast();
  StreamSubscription<RemoteConfigUpdate>? _updates;

  /// Activates the values fetched on an earlier run and starts the real-time
  /// listener. Does not touch the network itself; call [refresh] for that.
  Future<void> start() async {
    try {
      await _config.ensureInitialized();
      await _config.activate();
    } catch (error, stackTrace) {
      _log.warning(
        'Could not activate the cached Remote Config values.',
        error,
        stackTrace,
      );
    }
    try {
      _updates ??= _config.onConfigUpdated.listen(
        _onConfigUpdated,
        onError: (Object error, StackTrace stackTrace) {
          _log.warning(
            'Remote Config real-time listener failed.',
            error,
            stackTrace,
          );
        },
      );
    } catch (error, stackTrace) {
      _log.warning(
        'Could not start the Remote Config real-time listener.',
        error,
        stackTrace,
      );
    }
  }

  Future<void> _onConfigUpdated(RemoteConfigUpdate update) async {
    try {
      await _config.activate();
    } catch (error, stackTrace) {
      _log.warning(
        'Could not activate a Remote Config update.',
        error,
        stackTrace,
      );
      return;
    }
    _changes.add(null);
  }

  /// Stops the real-time listener. Used by tests.
  Future<void> dispose() async {
    await _updates?.cancel();
    _updates = null;
    await _changes.close();
  }

  /// The active value for [key], or `null` when Remote Config has none and
  /// would return its static default.
  RemoteConfigValue? _value(String key) {
    final RemoteConfigValue value = _config.getValue(key);
    return value.source == ValueSource.valueStatic ? null : value;
  }

  @override
  bool getBool(String key, {required bool fallback}) {
    final String? raw = _value(key)?.asString().trim().toLowerCase();
    if (raw == null) return fallback;
    if (_trueValues.contains(raw)) return true;
    if (_falseValues.contains(raw)) return false;
    return fallback;
  }

  @override
  int getInt(String key, {required int fallback}) {
    final String? raw = _value(key)?.asString().trim();
    if (raw == null) return fallback;
    return int.tryParse(raw) ?? fallback;
  }

  @override
  String getString(String key, {required String fallback}) {
    return _value(key)?.asString() ?? fallback;
  }

  @override
  Future<void> refresh() async {
    final bool changed;
    try {
      changed = await _config.fetchAndActivate();
    } catch (error, stackTrace) {
      _log.warning(
        'Remote Config fetch failed; keeping the cached values.',
        error,
        stackTrace,
      );
      return;
    }
    if (changed) _changes.add(null);
  }

  @override
  Stream<void> get onChanged => _changes.stream;
}
