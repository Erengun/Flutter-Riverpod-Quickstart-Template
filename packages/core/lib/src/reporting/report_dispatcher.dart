import 'package:logging/logging.dart';

import 'error_reporter.dart';

class _PendingReport {
  const _PendingReport(
    this.error,
    this.stackTrace, {
    required this.fatal,
    required this.groupKey,
    required this.tags,
    required this.extra,
  });

  final Object error;
  final StackTrace? stackTrace;
  final bool fatal;
  final String? groupKey;
  final Map<String, String> tags;
  final Map<String, Object?> extra;
}

/// Core's [ErrorReporter]: every report, breadcrumb and user goes through it
/// on the way to the reporter a Module contributed.
///
/// - Every [report] is first logged at `SEVERE` with the error attached, so
///   reports show in the console even when the reporter is the no-op.
/// - Until [attach] is called (once every Module has started), reports are
///   buffered and breadcrumbs are dropped. [attach] sends the buffered
///   reports in order.
/// - A reporter that throws is logged; the error never escapes.
///
/// `bootstrap` overrides `errorReporterProvider` with it.
class ReportDispatcher implements ErrorReporter {
  ReportDispatcher();

  static final Logger _log = Logger('report');

  ErrorReporter? _target;
  final List<_PendingReport> _pending = <_PendingReport>[];
  bool _hasPendingUser = false;
  String? _pendingUser;

  /// Whether [attach] has been called.
  bool get isAttached => _target != null;

  /// Starts forwarding to [target] and sends the buffered reports.
  void attach(ErrorReporter target) {
    if (_target != null) {
      throw StateError('ReportDispatcher.attach was called twice.');
    }
    _target = target;
    if (_hasPendingUser) {
      _guard('Setting the user', () => target.setUser(_pendingUser));
      _hasPendingUser = false;
      _pendingUser = null;
    }
    final List<_PendingReport> pending = List<_PendingReport>.of(_pending);
    _pending.clear();
    pending.forEach(_send);
  }

  @override
  void report(
    Object error,
    StackTrace? stackTrace, {
    bool fatal = false,
    String? groupKey,
    Map<String, String> tags = const <String, String>{},
    Map<String, Object?> extra = const <String, Object?>{},
  }) {
    final String kind = fatal ? 'Fatal error report' : 'Error report';
    _log.severe(
      groupKey == null ? kind : '$kind ($groupKey)',
      error,
      stackTrace,
    );
    final _PendingReport pending = _PendingReport(
      error,
      stackTrace,
      fatal: fatal,
      groupKey: groupKey,
      tags: tags,
      extra: extra,
    );
    if (_target == null) {
      _pending.add(pending);
    } else {
      _send(pending);
    }
  }

  @override
  void addBreadcrumb(
    String message, {
    String? category,
    BreadcrumbLevel level = BreadcrumbLevel.info,
    Map<String, Object?> data = const <String, Object?>{},
  }) {
    final ErrorReporter? target = _target;
    if (target == null) return;
    _guard(
      'Adding a breadcrumb',
      () => target.addBreadcrumb(
        message,
        category: category,
        level: level,
        data: data,
      ),
    );
  }

  @override
  void setUser(String? id) {
    final ErrorReporter? target = _target;
    if (target == null) {
      _hasPendingUser = true;
      _pendingUser = id;
      return;
    }
    _guard('Setting the user', () => target.setUser(id));
  }

  void _send(_PendingReport report) {
    final ErrorReporter target = _target!;
    _guard(
      'Sending an error report',
      () => target.report(
        report.error,
        report.stackTrace,
        fatal: report.fatal,
        groupKey: report.groupKey,
        tags: report.tags,
        extra: report.extra,
      ),
    );
  }

  // The failure is logged with the error attached, so it never turns into a
  // breadcrumb and cannot loop back into the reporter.
  void _guard(String action, void Function() call) {
    try {
      call();
    } catch (error, stackTrace) {
      _log.severe('$action failed.', error, stackTrace);
    }
  }
}
