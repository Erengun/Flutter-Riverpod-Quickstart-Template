import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:stack_trace/stack_trace.dart' as stack_trace;

import '../config/app_config.dart';
import '../config/flavor_check.dart';
import '../config/konteyner_platform.dart';
import '../logging/log_setup.dart';
import '../modules/konteyner_module.dart';
import '../reporting/provider_failure_observer.dart';
import '../reporting/report_dispatcher.dart';
import '../reporting/uncaught_errors.dart';
import 'app_shell.dart';

/// Starts the app. Each flavor entrypoint (`main_<flavor>.dart`) calls it
/// with its own [config].
///
/// In order, it:
/// 1. throws [FlavorMismatchError] on Android and iOS when the native
///    `--flavor` differs from [config]'s flavor, in every build mode;
/// 2. attaches the only root-logger listener for [config]'s flavor (see
///    [configureLogging]), feeding breadcrumbs to a [ReportDispatcher];
/// 3. installs log-only uncaught-error handlers
///    (see [installUncaughtErrorLogging]);
/// 4. starts [modules] (see [startModules]); reports made until then are
///    buffered and sent once the Modules' reporter is up;
/// 5. runs [app] inside a `ProviderScope` that overrides
///    [appConfigProvider], [konteynerThemeProvider], [splashProvider] and the
///    interfaces the Modules contributed (`errorReporterProvider` is the
///    dispatcher), plus [overrides], and observes it with a
///    [ProviderFailureObserver].
///
/// [theme] holds the app's light and dark themes. [splash] replaces Core's
/// default progress indicator. [overrides] are the app's own `ProviderScope`
/// overrides, such as the auth Feature's `sessionHooksProvider` or extra
/// `dioInterceptorsProvider` entries; they must not repeat a provider
/// `bootstrap` already overrides.
Future<void> bootstrap(
  AppConfig config, {
  required Widget app,
  required KonteynerTheme theme,
  Widget splash = const KonteynerSplash(),
  List<KonteynerModule> modules = const <KonteynerModule>[],
  List<Override> overrides = const <Override>[],
}) async {
  WidgetsFlutterBinding.ensureInitialized();
  final KonteynerPlatform platform = KonteynerPlatform.current;
  checkNativeFlavor(config.flavor, nativeFlavor: appFlavor, platform: platform);

  final ReportDispatcher reports = ReportDispatcher();
  configureLogging(LogPolicy.forFlavor(config.flavor), reporter: reports);
  installUncaughtErrorLogging();

  if (shouldSilenceDebugPrint(isRelease: kReleaseMode, flavor: config.flavor)) {
    // Silence debugPrint in prod release builds; staging keeps its console.
    debugPrint = (String? message, {int? wrapWidth}) {};
  }

  // Readable stack traces in release builds.
  FlutterError.demangleStackTrace = (StackTrace stack) {
    if (stack is stack_trace.Trace) return stack.vmTrace;
    if (stack is stack_trace.Chain) return stack.toTrace().vmTrace;
    return stack;
  };

  final StartedModules started = await startModules(
    modules,
    config,
    platform: platform,
    reports: reports,
  );

  runApp(
    ProviderScope(
      observers: <ProviderObserver>[ProviderFailureObserver(reports)],
      overrides: <Override>[
        appConfigProvider.overrideWithValue(config),
        konteynerThemeProvider.overrideWithValue(theme),
        splashProvider.overrideWithValue(splash),
        ...started.overrides,
        ...overrides,
      ],
      child: app,
    ),
  );
}
