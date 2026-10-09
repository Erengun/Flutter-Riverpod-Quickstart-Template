import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';

/// Installs log-only `FlutterError.onError` and `PlatformDispatcher.onError`
/// handlers. `bootstrap` calls it before any Module starts.
///
/// Each uncaught error is logged once at `SEVERE`. Core never reports it: an
/// error-tracker Module keeps these handlers, calls them, and records the
/// error as unhandled itself. `PlatformDispatcher.onError` returns `false`
/// so the tracker sees it as unhandled.
void installUncaughtErrorLogging() {
  final Logger log = Logger('uncaught');
  FlutterError.onError = (FlutterErrorDetails details) {
    final DiagnosticsNode? context = details.context;
    log.severe(
      context == null
          ? 'Uncaught Flutter error'
          : 'Uncaught Flutter error ${context.toDescription()}',
      details.exception,
      details.stack,
    );
  };
  PlatformDispatcher.instance.onError = (Object error, StackTrace stackTrace) {
    log.severe('Uncaught error', error, stackTrace);
    return false;
  };
}
