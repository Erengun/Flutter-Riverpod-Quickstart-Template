import 'package:flutter_riverpod/flutter_riverpod.dart';

/// How serious a breadcrumb is. Core's own enum, so no vendor type leaks.
enum BreadcrumbLevel { debug, info, warning, error }

/// Sends errors and breadcrumbs to an error tracker.
///
/// Core's default does nothing; a Module (such as Sentry) contributes the
/// real one.
abstract interface class ErrorReporter {
  /// Sends [error] to the tracker.
  ///
  /// [groupKey] decides grouping (for example `GET /orders/:id 500`),
  /// [tags] are short searchable values and [extra] is detail.
  void report(
    Object error,
    StackTrace? stackTrace, {
    bool fatal = false,
    String? groupKey,
    Map<String, String> tags = const <String, String>{},
    Map<String, Object?> extra = const <String, Object?>{},
  });

  /// Records a short note of a recent event, attached to the next report.
  void addBreadcrumb(
    String message, {
    String? category,
    BreadcrumbLevel level = BreadcrumbLevel.info,
    Map<String, Object?> data = const <String, Object?>{},
  });

  /// Sets the signed-in user's id, or clears it with `null`.
  void setUser(String? id);
}

/// The default [ErrorReporter]: does nothing.
class NoopErrorReporter implements ErrorReporter {
  const NoopErrorReporter();

  @override
  void report(
    Object error,
    StackTrace? stackTrace, {
    bool fatal = false,
    String? groupKey,
    Map<String, String> tags = const <String, String>{},
    Map<String, Object?> extra = const <String, Object?>{},
  }) {}

  @override
  void addBreadcrumb(
    String message, {
    String? category,
    BreadcrumbLevel level = BreadcrumbLevel.info,
    Map<String, Object?> data = const <String, Object?>{},
  }) {}

  @override
  void setUser(String? id) {}
}

/// The app's [ErrorReporter]. `bootstrap` overrides it when a Module
/// contributes one.
final Provider<ErrorReporter> errorReporterProvider = Provider<ErrorReporter>(
  (Ref ref) => const NoopErrorReporter(),
  name: 'errorReporterProvider',
);
