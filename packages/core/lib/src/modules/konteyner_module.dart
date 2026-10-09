import 'dart:developer' as developer;

import 'package:flutter_riverpod/misc.dart';

import '../config/app_config.dart';
import '../config/konteyner_platform.dart';
import '../reporting/analytics.dart';
import '../reporting/error_reporter.dart';
import '../reporting/remote_flags.dart';

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
  });

  final ErrorReporter errorReporter;
  final Analytics analytics;
  final RemoteFlags remoteFlags;

  /// Modules whose `init` threw, in start order.
  final List<ModuleStartupFailure> failures;

  /// The `ProviderScope` overrides for the started interfaces.
  List<Override> get overrides => <Override>[
    errorReporterProvider.overrideWithValue(errorReporter),
    analyticsProvider.overrideWithValue(analytics),
    remoteFlagsProvider.overrideWithValue(remoteFlags),
  ];
}

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
///   Once every Module has started, each failure is sent, non-fatal, through
///   whichever [ErrorReporter] came up; a report that throws is logged and
///   startup continues.
/// - Two Modules providing the same interface throw [ModuleConflictError].
Future<StartedModules> startModules(
  List<KonteynerModule> modules,
  AppConfig config, {
  KonteynerPlatform? platform,
}) async {
  final KonteynerPlatform target = platform ?? KonteynerPlatform.current;
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
      developer.log(
        'Module "${module.name}" failed to start; keeping the defaults.',
        name: 'modules',
        level: 1000,
        error: error,
        stackTrace: stackTrace,
      );
      failures.add(
        ModuleStartupFailure(
          moduleName: module.name,
          error: error,
          stackTrace: stackTrace,
        ),
      );
      continue;
    }
    reporter.offer(contributions.errorReporter, module.name);
    analytics.offer(contributions.analytics, module.name);
    remoteFlags.offer(contributions.remoteFlags, module.name);
  }

  final ErrorReporter startedReporter = reporter.resolved;
  for (final ModuleStartupFailure failure in failures) {
    try {
      startedReporter.report(
        ModuleStartupException(failure.moduleName, failure.error),
        failure.stackTrace,
        tags: <String, String>{'module': failure.moduleName},
      );
    } catch (error, stackTrace) {
      developer.log(
        'Reporting the failure of Module "${failure.moduleName}" failed.',
        name: 'modules',
        level: 1000,
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  return StartedModules(
    errorReporter: startedReporter,
    analytics: analytics.resolved,
    remoteFlags: remoteFlags.resolved,
    failures: List<ModuleStartupFailure>.unmodifiable(failures),
  );
}
