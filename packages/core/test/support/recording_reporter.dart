import 'package:core/core.dart';

/// One call to [RecordingReporter.report].
class RecordedReport {
  const RecordedReport(
    this.error,
    this.stackTrace, {
    required this.fatal,
    required this.groupKey,
    required this.tags,
  });

  final Object error;
  final StackTrace? stackTrace;
  final bool fatal;
  final String? groupKey;
  final Map<String, String> tags;
}

/// One call to [RecordingReporter.addBreadcrumb].
class RecordedBreadcrumb {
  const RecordedBreadcrumb(this.message, {this.category, required this.level});

  final String message;
  final String? category;
  final BreadcrumbLevel level;
}

/// An [ErrorReporter] that records every call.
class RecordingReporter implements ErrorReporter {
  final List<RecordedReport> reports = <RecordedReport>[];
  final List<RecordedBreadcrumb> breadcrumbs = <RecordedBreadcrumb>[];
  final List<String?> users = <String?>[];

  @override
  void report(
    Object error,
    StackTrace? stackTrace, {
    bool fatal = false,
    String? groupKey,
    Map<String, String> tags = const <String, String>{},
    Map<String, Object?> extra = const <String, Object?>{},
  }) {
    reports.add(
      RecordedReport(
        error,
        stackTrace,
        fatal: fatal,
        groupKey: groupKey,
        tags: tags,
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
    breadcrumbs.add(
      RecordedBreadcrumb(message, category: category, level: level),
    );
  }

  @override
  void setUser(String? id) {
    users.add(id);
  }
}
