import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Reads remotely configured values.
///
/// Core's default returns every fallback; a Module (such as Firebase Remote
/// Config) contributes the real one.
abstract interface class RemoteFlags {
  bool getBool(String key, {required bool fallback});

  int getInt(String key, {required int fallback});

  String getString(String key, {required String fallback});

  /// Fetches fresh values in the background. Reads keep returning the last
  /// cached values until it completes.
  Future<void> refresh();

  /// Emits whenever the values change.
  Stream<void> get onChanged;
}

/// The default [RemoteFlags]: returns every fallback and never changes.
class NoopRemoteFlags implements RemoteFlags {
  const NoopRemoteFlags();

  @override
  bool getBool(String key, {required bool fallback}) => fallback;

  @override
  int getInt(String key, {required int fallback}) => fallback;

  @override
  String getString(String key, {required String fallback}) => fallback;

  @override
  Future<void> refresh() async {}

  @override
  Stream<void> get onChanged => const Stream<void>.empty();
}

/// The app's [RemoteFlags]. `bootstrap` overrides it when a Module
/// contributes one.
final Provider<RemoteFlags> remoteFlagsProvider = Provider<RemoteFlags>(
  (Ref ref) => const NoopRemoteFlags(),
  name: 'remoteFlagsProvider',
);
