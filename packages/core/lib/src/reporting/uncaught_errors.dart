import 'dart:async';
import 'dart:ui' show ErrorCallback;

import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';

import '../config/konteyner_platform.dart';

final Logger _log = Logger('uncaught');

/// Installs log-only `FlutterError.onError` and `PlatformDispatcher.onError`
/// handlers. `bootstrap` calls it before any Module starts.
///
/// Each uncaught error is logged once at `SEVERE`. Core never reports it: an
/// error-tracker Module keeps these handlers, calls them, and records the
/// error as unhandled itself. `PlatformDispatcher.onError` returns `false`
/// so the tracker sees it as unhandled.
///
/// The web engine never calls `PlatformDispatcher.onError`
/// (flutter/flutter#100277); [runGuarded] calls it there instead.
void installUncaughtErrorLogging() {
  FlutterError.onError = (FlutterErrorDetails details) {
    final DiagnosticsNode? context = details.context;
    _log.severe(
      context == null
          ? 'Uncaught Flutter error'
          : 'Uncaught Flutter error ${context.toDescription()}',
      details.exception,
      details.stack,
    );
  };
  PlatformDispatcher.instance.onError = (Object error, StackTrace stackTrace) {
    _log.severe('Uncaught error', error, stackTrace);
    return false;
  };
}

/// Runs [body], the whole of a flavor entrypoint's `main`, so uncaught
/// asynchronous errors reach `PlatformDispatcher.onError` on every platform.
///
/// The web engine never calls `PlatformDispatcher.onError`
/// (flutter/flutter#100277), so on web [body] runs in a guarded zone whose
/// handler calls the current `PlatformDispatcher.onError` (Core's log-only
/// handler, and an error-tracker Module's handler chained to it). The zone
/// must enclose `WidgetsFlutterBinding.ensureInitialized` so frame and event
/// callbacks run in it too, which is why the entrypoint, not `bootstrap`,
/// opens it.
///
/// On every other platform [body] runs as is: the engine already calls
/// `PlatformDispatcher.onError`, and a zone would only add a second path.
/// [platform] defaults to [KonteynerPlatform.current].
Future<void> runGuarded(
  Future<void> Function() body, {
  KonteynerPlatform? platform,
}) {
  if ((platform ?? KonteynerPlatform.current) != KonteynerPlatform.web) {
    return body();
  }
  return runZonedGuarded<Future<void>>(body, (
        Object error,
        StackTrace stackTrace,
      ) {
        final ErrorCallback? onError = PlatformDispatcher.instance.onError;
        if (onError == null) {
          _log.severe('Uncaught error', error, stackTrace);
        } else {
          onError(error, stackTrace);
        }
      }) ??
      Future<void>.value();
}
