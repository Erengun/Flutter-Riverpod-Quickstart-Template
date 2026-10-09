import 'dart:async';

import 'package:core/core.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

/// Core's [ErrorReporter] backed by Sentry.
///
/// - [report] calls `captureException`; `groupKey` becomes the fingerprint,
///   `tags` become tags, `extra` becomes the `extra` context and `fatal`
///   sets the level to fatal.
/// - [addBreadcrumb] adds a Sentry breadcrumb.
/// - [setUser] sets only the user id.
class SentryErrorReporter implements ErrorReporter {
  /// Sends through [hub], Sentry's global hub by default.
  SentryErrorReporter({Hub? hub}) : _hub = hub ?? HubAdapter();

  final Hub _hub;

  /// The name of the context that holds a report's `extra`.
  static const String extraContextKey = 'extra';

  @override
  void report(
    Object error,
    StackTrace? stackTrace, {
    bool fatal = false,
    String? groupKey,
    Map<String, String> tags = const <String, String>{},
    Map<String, Object?> extra = const <String, Object?>{},
  }) {
    unawaited(
      _hub.captureException(
        error,
        stackTrace: stackTrace,
        withScope: (Scope scope) async {
          if (groupKey != null) scope.fingerprint = <String>[groupKey];
          if (fatal) scope.level = SentryLevel.fatal;
          for (final MapEntry<String, String> tag in tags.entries) {
            await scope.setTag(tag.key, tag.value);
          }
          if (extra.isNotEmpty) {
            await scope.setContexts(
              extraContextKey,
              Map<String, Object?>.of(extra),
            );
          }
        },
      ),
    );
  }

  @override
  void addBreadcrumb(
    String message, {
    String? category,
    BreadcrumbLevel level = BreadcrumbLevel.info,
    Map<String, Object?> data = const <String, Object?>{},
  }) {
    unawaited(
      _hub.addBreadcrumb(
        Breadcrumb(
          message: message,
          category: category,
          level: _levelFor(level),
          data: data.isEmpty ? null : Map<String, Object?>.of(data),
        ),
      ),
    );
  }

  @override
  void setUser(String? id) {
    unawaited(
      Future<void>.value(
        _hub.configureScope(
          (Scope scope) =>
              scope.setUser(id == null ? null : SentryUser(id: id)),
        ),
      ),
    );
  }

  static SentryLevel _levelFor(BreadcrumbLevel level) {
    return switch (level) {
      BreadcrumbLevel.debug => SentryLevel.debug,
      BreadcrumbLevel.info => SentryLevel.info,
      BreadcrumbLevel.warning => SentryLevel.warning,
      BreadcrumbLevel.error => SentryLevel.error,
    };
  }
}
