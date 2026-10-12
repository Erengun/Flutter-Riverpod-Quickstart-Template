import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';

import '../config/app_config.dart';
import '../reporting/error_reporter.dart';

/// How much a [Flavor] logs and whether it prints to the console.
class LogPolicy {
  const LogPolicy({
    required this.level,
    required this.console,
    this.loggerLevels = const <String, Level>{},
  });

  /// dev keeps everything and prints it; staging keeps `INFO` and above
  /// (`FINE` for `Logger('network')`, so the request log works) and prints
  /// it; prod keeps `INFO` and above without a console.
  factory LogPolicy.forFlavor(Flavor flavor) {
    return switch (flavor) {
      Flavor.dev => const LogPolicy(level: Level.ALL, console: true),
      Flavor.staging => const LogPolicy(
        level: Level.INFO,
        console: true,
        loggerLevels: <String, Level>{'network': Level.FINE},
      ),
      Flavor.prod => const LogPolicy(level: Level.INFO, console: false),
    };
  }

  /// The lowest level kept.
  final Level level;

  /// Whether kept records are printed.
  final bool console;

  /// The lowest level kept for single named loggers, overriding [level].
  /// Records below `INFO` never become breadcrumbs, whatever is kept here.
  final Map<String, Level> loggerLevels;
}

/// Writes one kept record somewhere a developer can read it.
typedef LogPrinter = void Function(LogRecord record);

StreamSubscription<LogRecord>? _subscription;

/// The loggers whose level [configureLogging] set from
/// [LogPolicy.loggerLevels].
final Set<String> _leveledLoggers = <String>{};

void _clearLoggerLevels() {
  for (final String name in _leveledLoggers) {
    Logger(name).level = null;
  }
  _leveledLoggers.clear();
}

/// Attaches the only listener on the root logger. `bootstrap` calls it once;
/// calling it again replaces the previous listener.
///
/// - Records below [LogPolicy.level] are dropped, except for the loggers
///   in [LogPolicy.loggerLevels], which keep their own level (this turns on
///   the `logging` package's `hierarchicalLoggingEnabled`).
/// - Kept records go to [printer] (the console by default) when
///   [LogPolicy.console] is on.
/// - Kept records at `INFO` and above become breadcrumbs on [reporter], with
///   the logger's name as the category. A record carrying an error never
///   does: it is the echo of an error report or an uncaught error.
void configureLogging(
  LogPolicy policy, {
  required ErrorReporter reporter,
  LogPrinter? printer,
}) {
  unawaited(_subscription?.cancel());
  _clearLoggerLevels();
  Logger.root.level = policy.level;
  if (policy.loggerLevels.isNotEmpty) {
    hierarchicalLoggingEnabled = true;
    for (final MapEntry<String, Level> entry in policy.loggerLevels.entries) {
      Logger(entry.key).level = entry.value;
      _leveledLoggers.add(entry.key);
    }
  }
  final LogPrinter? console = policy.console
      ? (printer ?? printLogRecord)
      : null;
  _subscription = Logger.root.onRecord.listen((LogRecord record) {
    console?.call(record);
    if (record.error == null && record.level >= Level.INFO) {
      reporter.addBreadcrumb(
        record.message,
        category: record.loggerName.isEmpty ? null : record.loggerName,
        level: breadcrumbLevelFor(record.level),
      );
    }
  });
}

/// Removes the listener [configureLogging] attached and restores the
/// `logging` package's default levels. For tests.
void resetLogging() {
  unawaited(_subscription?.cancel());
  _subscription = null;
  _clearLoggerLevels();
  hierarchicalLoggingEnabled = false;
  Logger.root.level = Level.INFO;
}

/// The breadcrumb level for a log [level].
BreadcrumbLevel breadcrumbLevelFor(Level level) {
  if (level >= Level.SEVERE) return BreadcrumbLevel.error;
  if (level >= Level.WARNING) return BreadcrumbLevel.warning;
  if (level >= Level.INFO) return BreadcrumbLevel.info;
  return BreadcrumbLevel.debug;
}

/// Whether `bootstrap` replaces `debugPrint` with a no-op: only in release
/// builds of prod. dev and staging keep the real `debugPrint` in every build
/// mode, so staging release builds still reach the platform log.
bool shouldSilenceDebugPrint({
  required bool isRelease,
  required Flavor flavor,
}) {
  return isRelease && flavor == Flavor.prod;
}

/// Core's console printer: one line per record, then the error and stack
/// trace when present. Writes through `debugPrint`, which throttles long
/// output so the platform log does not drop lines. prod never reaches it
/// (its [LogPolicy] has no console), and `bootstrap` silences `debugPrint`
/// in prod release builds (see [shouldSilenceDebugPrint]).
void printLogRecord(LogRecord record) {
  final StringBuffer line = StringBuffer(
    '[${record.level.name}] ${record.loggerName}: ${record.message}',
  );
  final Object? error = record.error;
  if (error != null) line.write('\n$error');
  final StackTrace? stackTrace = record.stackTrace;
  if (stackTrace != null) line.write('\n$stackTrace');
  debugPrint(line.toString());
}
