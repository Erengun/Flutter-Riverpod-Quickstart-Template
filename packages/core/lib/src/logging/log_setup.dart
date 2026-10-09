import 'dart:async';

import 'package:logging/logging.dart';

import '../config/app_config.dart';
import '../reporting/error_reporter.dart';

/// How much a [Flavor] logs and whether it prints to the console.
class LogPolicy {
  const LogPolicy({required this.level, required this.console});

  /// dev keeps everything and prints it; staging keeps `INFO` and above and
  /// prints it; prod keeps `INFO` and above without a console.
  factory LogPolicy.forFlavor(Flavor flavor) {
    return switch (flavor) {
      Flavor.dev => const LogPolicy(level: Level.ALL, console: true),
      Flavor.staging => const LogPolicy(level: Level.INFO, console: true),
      Flavor.prod => const LogPolicy(level: Level.INFO, console: false),
    };
  }

  /// The lowest level kept.
  final Level level;

  /// Whether kept records are printed.
  final bool console;
}

/// Writes one kept record somewhere a developer can read it.
typedef LogPrinter = void Function(LogRecord record);

StreamSubscription<LogRecord>? _subscription;

/// Attaches the only listener on the root logger. `bootstrap` calls it once;
/// calling it again replaces the previous listener.
///
/// - Records below [LogPolicy.level] are dropped.
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
  Logger.root.level = policy.level;
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
/// `logging` package's default level. For tests.
void resetLogging() {
  unawaited(_subscription?.cancel());
  _subscription = null;
  Logger.root.level = Level.INFO;
}

/// The breadcrumb level for a log [level].
BreadcrumbLevel breadcrumbLevelFor(Level level) {
  if (level >= Level.SEVERE) return BreadcrumbLevel.error;
  if (level >= Level.WARNING) return BreadcrumbLevel.warning;
  if (level >= Level.INFO) return BreadcrumbLevel.info;
  return BreadcrumbLevel.debug;
}

/// Core's console printer: one line per record, then the error and stack
/// trace when present. Uses `print` so staging release builds still reach
/// the platform log (`debugPrint` is silenced in release builds).
void printLogRecord(LogRecord record) {
  final StringBuffer line = StringBuffer(
    '[${record.level.name}] ${record.loggerName}: ${record.message}',
  );
  final Object? error = record.error;
  if (error != null) line.write('\n$error');
  final StackTrace? stackTrace = record.stackTrace;
  if (stackTrace != null) line.write('\n$stackTrace');
  // ignore: avoid_print
  print(line);
}
