import 'dart:async';

import 'package:core/core.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:logging/logging.dart';

final Logger _log = Logger('firebase.analytics');

/// Core's [Analytics] backed by Firebase Analytics.
///
/// Calls are fire-and-forget: a failing Firebase call is logged and never
/// reaches the caller.
class FirebaseAnalyticsAdapter implements Analytics {
  FirebaseAnalyticsAdapter(this._analytics);

  final FirebaseAnalytics _analytics;

  @override
  void logEvent(
    String name, [
    Map<String, Object> params = const <String, Object>{},
  ]) {
    _send(
      'logEvent($name)',
      () => _analytics.logEvent(
        name: name,
        parameters: params.isEmpty ? null : params,
      ),
    );
  }

  @override
  void logScreen(String name) {
    _send(
      'logScreen($name)',
      () => _analytics.logScreenView(screenName: name),
    );
  }

  @override
  void setUserId(String? id) {
    _send('setUserId', () => _analytics.setUserId(id: id));
  }

  void _send(String call, Future<void> Function() send) {
    unawaited(
      Future<void>.sync(send).catchError((Object error, StackTrace stackTrace) {
        _log.warning('Firebase Analytics $call failed.', error, stackTrace);
      }),
    );
  }
}
