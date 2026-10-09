import 'package:core/core.dart';
import 'package:logging/logging.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import 'sentry_error_reporter.dart';
import 'sentry_options.dart';

/// Starts Sentry with [configureOptions]. The default calls
/// `SentryFlutter.init` without an `appRunner`: Core's `bootstrap` calls
/// `runApp` itself.
typedef SentryStarter = Future<void> Function(
  FlutterOptionsConfiguration configureOptions,
);

Future<void> _startSentry(FlutterOptionsConfiguration configureOptions) =>
    SentryFlutter.init(configureOptions);

/// Sends errors and crash-free statistics to Sentry on staging and prod.
///
/// - **dev:** Sentry never starts and the Module returns the no-op
///   reporter, so dev errors only reach the console.
/// - **staging, prod:** Sentry starts with [configureSentryOptions]
///   (`environment` is the flavor name) and the Module returns a
///   [SentryErrorReporter].
///
/// Sentry's Flutter and platform error integrations keep the uncaught-error
/// handlers Core installed before the Modules started and call them, so each
/// uncaught error is logged once by Core and reported once, as unhandled, by
/// Sentry. On web, where the engine never calls `PlatformDispatcher.onError`,
/// Core's `runGuarded` zone calls it, and [configureSentryOptions] adds the
/// platform error integration sentry_flutter leaves out there.
class SentryModule implements KonteynerModule {
  /// [dsn] defaults to [sentryDsn]; [start] defaults to `SentryFlutter.init`.
  /// Both are replaceable for tests.
  SentryModule({this.dsn = sentryDsn, SentryStarter? start})
    : _start = start ?? _startSentry;

  /// The DSN Sentry starts with. Empty means Sentry never starts.
  final String dsn;
  final SentryStarter _start;

  static final Logger _log = Logger('sentry');

  @override
  String get name => 'sentry';

  @override
  Set<KonteynerPlatform> get platforms => KonteynerPlatform.values.toSet();

  @override
  Future<ModuleContributions> init(AppConfig config) async {
    switch (config.flavor) {
      case Flavor.dev:
        return const ModuleContributions(errorReporter: NoopErrorReporter());
      case Flavor.staging:
      case Flavor.prod:
        if (dsn.isEmpty) {
          _log.warning(
            'Sentry is not started: the DSN is empty. Set sentryDsn in '
            'packages/sentry_module/lib/src/sentry_options.dart.',
          );
          return const ModuleContributions(errorReporter: NoopErrorReporter());
        }
        await _start(
          (SentryFlutterOptions options) =>
              configureSentryOptions(options, config, dsn: dsn),
        );
        return ModuleContributions(errorReporter: SentryErrorReporter());
    }
  }
}
