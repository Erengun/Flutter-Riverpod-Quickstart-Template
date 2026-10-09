import 'package:flutter_riverpod/misc.dart';
import 'package:logging/logging.dart';

import '../config/app_config.dart';
import '../config/konteyner_platform.dart';
import '../reporting/analytics.dart';
import '../reporting/error_reporter.dart';
import '../reporting/remote_flags.dart';
import '../reporting/report_dispatcher.dart';

/// An optional piece of infrastructure an app opts into, such as Firebase or
/// Sentry. A Module lives in `packages/<name>_module` and is listed in the
/// app's `lib/app/modules.dart`.
abstract class KonteynerModule {
  /// A short name used in startup errors and logs.
  String get name;

  /// The platforms where the Module's native SDK exists. On any other
  /// platform the Module is skipped before any of its plugins is touched.
  Set<KonteynerPlatform> get platforms;

  /// Starts the Module and returns what it provides. Runs before the
  /// `ProviderScope` exists, so it receives the [config] directly.
  Future<ModuleContributions> init(AppConfig config);
}

/// What a Module provides. A `null` field leaves Core's no-op default.
///
/// Core turns these into `ProviderScope` overrides; Modules never write
/// overrides themselves.
class ModuleContributions {
  const ModuleContributions({
    this.errorReporter,
    this.analytics,
    this.remoteFlags,
  });

  final ErrorReporter? errorReporter;
  final Analytics? analytics;
  final RemoteFlags? remoteFlags;
}

/// Thrown when two Modules provide the same interface. Only one Module may
/// provide each interface.
class ModuleConflictError extends Error {
  ModuleConflictError({required this.interfaceName, required this.moduleNames});

  final String interfaceName;
  final List<String> moduleNames;

  @override
  String toString() =>
      'ModuleConflictError: $interfaceName is provided by more than one '
      'Module (${moduleNames.join(', ')}). Remove all but one of them from '
      'lib/app/modules.dart.';
}

/// A Module whose `init` threw. The app still starts with the defaults.
class ModuleStartupFailure {
  const ModuleStartupFailure({
    required this.moduleName,
    required this.error,
    required this.stackTrace,
  });

  final String moduleName;
  final Object error;
  final StackTrace stackTrace;
}

/// The error sent to the [ErrorReporter] for a [ModuleStartupFailure].
class ModuleStartupException implements Exception {
  const ModuleStartupException(this.moduleName, this.cause);

  final String moduleName;
  final Object cause;

  @override
  String toString() =>
      'ModuleStartupException: Module "$moduleName" failed to start: $cause';
}

/// The result of [startModules].
class StartedModules {
  const StartedModules({
    required this.errorReporter,
    required this.analytics,
    required this.remoteFlags,
    required this.failures,
    required this.reportDispatcher,
  });

  /// The reporter a Module contributed, or the no-op default.
  final ErrorReporter errorReporter;
  final Analytics analytics;
  final RemoteFlags remoteFlags;

  /// Modules whose `init` threw, in start order.
  final List<ModuleStartupFailure> failures;

  /// Core's dispatcher, now attached to [errorReporter]. Everything the app
  /// reports goes through it.
  final ReportDispatcher reportDispatcher;

  /// The `ProviderScope` overrides for the started interfaces.
  /// `errorReporterProvider` gets [reportDispatcher], not [errorReporter].
  List<Override> get overrides => <Override>[
    errorReporterProvider.overrideWithValue(reportDispatcher),
    analyticsProvider.overrideWithValue(analytics),
    remoteFlagsProvider.overrideWithValue(remoteFlags),
  ];
}

final Logger _log = Logger('modules');

class _Slot<T extends Object> {
  _Slot(this.interfaceName, this.fallback);

  final String interfaceName;
  final T fallback;
  T? value;
  String? owner;

  void offer(T? contribution, String moduleName) {
    if (contribution == null) return;
    final String? current = owner;
    if (current != null) {
      throw ModuleConflictError(
        interfaceName: interfaceName,
        moduleNames: <String>[current, moduleName],
      );
    }
    value = contribution;
    owner = moduleName;
  }

  T get resolved => value ?? fallback;
}

/// Starts [modules] in order on [platform] (the current one by default).
///
/// - A Module whose [KonteynerModule.platforms] lacks [platform] is skipped.
/// - A Module whose `init` throws is logged and recorded in
///   [StartedModules.failures]; the defaults stay and the app still starts.
///   Each failure is reported, non-fatal, through [reports] (a new
///   [ReportDispatcher] by default), which buffers it.
/// - Once every Module has started, [reports] is attached to whichever
///   [ErrorReporter] came up and sends the buffered reports; a report that
///   throws is logged and startup continues. [reports] must not be attached
///   yet.
/// - Two Modules providing the same interface throw [ModuleConflictError].
Future<StartedModules> startModules(
  List<KonteynerModule> modules,
  AppConfig config, {
  KonteynerPlatform? platform,
  ReportDispatcher? reports,
}) async {
  final KonteynerPlatform target = platform ?? KonteynerPlatform.current;
  final ReportDispatcher dispatcher = reports ?? ReportDispatcher();
  final _Slot<ErrorReporter> reporter = _Slot<ErrorReporter>(
    'ErrorReporter',
    const NoopErrorReporter(),
  );
  final _Slot<Analytics> analytics = _Slot<Analytics>(
    'Analytics',
    const NoopAnalytics(),
  );
  final _Slot<RemoteFlags> remoteFlags = _Slot<RemoteFlags>(
    'RemoteFlags',
    const NoopRemoteFlags(),
  );
  final List<ModuleStartupFailure> failures = <ModuleStartupFailure>[];

  for (final KonteynerModule module in modules) {
    if (!module.platforms.contains(target)) continue;
    final ModuleContributions contributions;
    try {
      contributions = await module.init(config);
    } catch (error, stackTrace) {
      _log.warning(
        'Module "${module.name}" failed to start; keeping the defaults.',
      );
      failures.add(
        ModuleStartupFailure(
          moduleName: module.name,
          error: error,
          stackTrace: stackTrace,
        ),
      );
      dispatcher.report(
        ModuleStartupException(module.name, error),
        stackTrace,
        tags: <String, String>{'module': module.name},
      );
      continue;
    }
    reporter.offer(contributions.errorReporter, module.name);
    analytics.offer(contributions.analytics, module.name);
    remoteFlags.offer(contributions.remoteFlags, module.name);
  }

  final ErrorReporter startedReporter = reporter.resolved;
  dispatcher.attach(startedReporter);

  return StartedModules(
    errorReporter: startedReporter,
    analytics: analytics.resolved,
    remoteFlags: remoteFlags.resolved,
    failures: List<ModuleStartupFailure>.unmodifiable(failures),
    reportDispatcher: dispatcher,
  );
}
