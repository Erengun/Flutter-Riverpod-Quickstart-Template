import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logging/logging.dart';

import '../support/recording_reporter.dart';

class _ThrowingReporter extends RecordingReporter {
  @override
  void report(
    Object error,
    StackTrace? stackTrace, {
    bool fatal = false,
    String? groupKey,
    Map<String, String> tags = const <String, String>{},
    Map<String, Object?> extra = const <String, Object?>{},
  }) {
    super.report(error, stackTrace, fatal: fatal);
    throw StateError('tracker down');
  }
}

void main() {
  late List<LogRecord> logged;

  setUp(() {
    logged = <LogRecord>[];
    configureLogging(
      LogPolicy.forFlavor(Flavor.dev),
      reporter: const NoopErrorReporter(),
      printer: logged.add,
    );
  });

  tearDown(resetLogging);

  test('every report is logged at SEVERE with the error first', () {
    final ReportDispatcher dispatcher = ReportDispatcher();
    final StateError error = StateError('boom');

    dispatcher.report(error, StackTrace.current, groupKey: 'GET /a 500');

    expect(logged, hasLength(1));
    expect(logged.single.level, Level.SEVERE);
    expect(logged.single.error, same(error));
    expect(logged.single.message, contains('GET /a 500'));
  });

  test('reports are buffered until attach, then sent in order', () {
    final ReportDispatcher dispatcher = ReportDispatcher();
    final RecordingReporter target = RecordingReporter();

    dispatcher
      ..report(StateError('first'), null, tags: <String, String>{'a': '1'})
      ..report(StateError('second'), null, fatal: true);
    expect(target.reports, isEmpty);

    dispatcher.attach(target);

    expect(
      target.reports.map((RecordedReport r) => (r.error as StateError).message),
      <String>['first', 'second'],
    );
    expect(target.reports.first.tags, <String, String>{'a': '1'});
    expect(target.reports.last.fatal, isTrue);

    dispatcher.report(StateError('third'), null);
    expect(target.reports, hasLength(3));
  });

  test('breadcrumbs before attach are dropped; later ones pass through', () {
    final ReportDispatcher dispatcher = ReportDispatcher();
    final RecordingReporter target = RecordingReporter();

    dispatcher
      ..addBreadcrumb('too early', category: 'auth')
      ..attach(target)
      ..addBreadcrumb('signed in', category: 'auth');

    expect(
      target.breadcrumbs.map((RecordedBreadcrumb b) => b.message),
      <String>['signed in'],
    );
  });

  test('a user set before attach reaches the reporter on attach', () {
    final ReportDispatcher dispatcher = ReportDispatcher();
    final RecordingReporter target = RecordingReporter();

    dispatcher
      ..setUser('42')
      ..attach(target)
      ..setUser(null);

    expect(target.users, <String?>['42', null]);
  });

  test('a throwing reporter is logged and never escapes', () {
    final ReportDispatcher dispatcher = ReportDispatcher();
    final _ThrowingReporter target = _ThrowingReporter();

    dispatcher
      ..report(StateError('buffered'), null)
      ..attach(target)
      ..report(StateError('direct'), null);

    expect(target.reports, hasLength(2));
    expect(
      logged.where(
        (LogRecord r) =>
            r.error is StateError &&
            (r.error! as StateError).message == 'tracker down',
      ),
      hasLength(2),
    );
  });

  test('attaching twice is an error', () {
    final ReportDispatcher dispatcher = ReportDispatcher()
      ..attach(RecordingReporter());

    expect(() => dispatcher.attach(RecordingReporter()), throwsStateError);
  });

  test('logs become breadcrumbs through the dispatcher once attached', () {
    final ReportDispatcher dispatcher = ReportDispatcher();
    final RecordingReporter target = RecordingReporter();
    configureLogging(
      LogPolicy.forFlavor(Flavor.prod),
      reporter: dispatcher,
      printer: logged.add,
    );

    Logger('auth').info('before modules');
    dispatcher.attach(target);
    Logger('auth').info('after modules');
    dispatcher.report(StateError('boom'), null);

    expect(
      target.breadcrumbs.map((RecordedBreadcrumb b) => b.message),
      <String>['after modules'],
    );
    expect(target.reports, hasLength(1));
  });
}
