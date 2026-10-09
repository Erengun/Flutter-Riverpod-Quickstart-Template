import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Sends product analytics events.
///
/// Core's default does nothing; a Module (such as Firebase) contributes the
/// real one.
abstract interface class Analytics {
  /// Logs the event [name]. Each value in [params] must be a [String] or a
  /// [num].
  void logEvent(
    String name, [
    Map<String, Object> params = const <String, Object>{},
  ]);

  /// Logs that the screen [name] was shown.
  void logScreen(String name);

  /// Sets the signed-in user's id, or clears it with `null`.
  void setUserId(String? id);
}

/// The default [Analytics]: does nothing.
class NoopAnalytics implements Analytics {
  const NoopAnalytics();

  @override
  void logEvent(
    String name, [
    Map<String, Object> params = const <String, Object>{},
  ]) {}

  @override
  void logScreen(String name) {}

  @override
  void setUserId(String? id) {}
}

/// The app's [Analytics]. `bootstrap` overrides it when a Module contributes
/// one.
final Provider<Analytics> analyticsProvider = Provider<Analytics>(
  (Ref ref) => const NoopAnalytics(),
  name: 'analyticsProvider',
);
