import 'package:core/core.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

/// The app's Sentry DSN. One Sentry project serves every flavor; events are
/// told apart by `environment`.
///
/// Paste the DSN from the Sentry project's Client Keys page. A DSN is not a
/// secret: it only lets a client send events. While it is empty, Sentry
/// never starts and errors only reach the console.
const String sentryDsn = '';

/// Applies the template's Sentry settings to [options] for [config]'s
/// flavor, with [dsn].
///
/// Errors and crash-free statistics only:
/// - error events at sample rate 1.0 and automatic session tracking on;
/// - no performance tracing, screenshots or session replay;
/// - no PII, no automatic HTTP capture (Core's network layer reports API
///   errors itself) and no Sentry structured logs (Core's logger already
///   turns log records into breadcrumbs).
///
/// Release and dist are left to sentry_flutter, which reads them from the
/// platform's package info.
///
/// On web ([platform] defaults to [KonteynerPlatform.current]) it also adds
/// sentry_flutter's `OnErrorIntegration`, which sentry_flutter leaves out on
/// web because the web engine never calls `PlatformDispatcher.onError`.
/// Core's `runGuarded` zone calls it there instead, so uncaught asynchronous
/// errors on web are reported once, like on the other platforms.
void configureSentryOptions(
  SentryFlutterOptions options,
  AppConfig config, {
  String dsn = sentryDsn,
  KonteynerPlatform? platform,
}) {
  options
    ..dsn = dsn
    ..environment = config.flavor.name
    ..sampleRate = 1
    ..enableAutoSessionTracking = true
    // Tracing stays off: a null rate (not 0) keeps the tracing machinery
    // disabled. An app that wants tracing sets a rate here.
    ..tracesSampleRate = null
    ..tracesSampler = null
    ..enableAutoPerformanceTracing = false
    ..attachScreenshot = false
    ..sendDefaultPii = false
    ..captureFailedRequests = false
    ..captureNativeFailedRequests = false
    ..enableLogs = false;
  options.replay
    ..sessionSampleRate = 0
    ..onErrorSampleRate = 0;
  if ((platform ?? KonteynerPlatform.current) == KonteynerPlatform.web) {
    options.addIntegration(OnErrorIntegration());
  }
}
