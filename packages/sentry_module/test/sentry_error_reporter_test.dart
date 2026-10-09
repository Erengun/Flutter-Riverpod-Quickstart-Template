import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:sentry_module/sentry_module.dart';

/// Sends nothing anywhere.
class _NoTransport implements Transport {
  @override
  Future<SentryId?> send(SentryEnvelope envelope) async => null;
}

void main() {
  late List<SentryEvent> events;
  late Hub hub;
  late SentryErrorReporter reporter;

  setUp(() {
    events = <SentryEvent>[];
    final SentryOptions options =
        SentryOptions(dsn: 'https://public@example.ingest.sentry.io/1')
          ..transport = _NoTransport()
          ..beforeSend = (SentryEvent event, Hint hint) {
            events.add(event);
            return null;
          };
    hub = Hub(options);
    reporter = SentryErrorReporter(hub: hub);
  });

  /// Lets the reporter's fire-and-forget futures finish.
  Future<void> settle() => pumpEventQueue();

  test('report captures the exception with its stack trace', () async {
    final StateError error = StateError('boom');
    final StackTrace stackTrace = StackTrace.current;

    reporter.report(error, stackTrace);
    await settle();

    expect(events, hasLength(1));
    final SentryEvent event = events.single;
    expect(event.throwable, same(error));
    expect(event.exceptions, isNotEmpty);
    expect(event.exceptions!.first.stackTrace, isNotNull);
    expect(event.level, isNot(SentryLevel.fatal));
  });

  test('report maps groupKey, tags and extra', () async {
    reporter.report(
      Exception('server'),
      StackTrace.current,
      groupKey: 'GET /orders/:id 500',
      tags: <String, String>{'http.method': 'GET', 'http.status': '500'},
      extra: <String, Object?>{'requestId': 'abc', 'errorMessage': null},
    );
    await settle();

    final SentryEvent event = events.single;
    expect(event.fingerprint, <String>['GET /orders/:id 500']);
    expect(event.tags, containsPair('http.method', 'GET'));
    expect(event.tags, containsPair('http.status', '500'));
    expect(
      event.contexts[SentryErrorReporter.extraContextKey],
      <String, Object?>{'requestId': 'abc', 'errorMessage': null},
    );
  });

  test('report scope does not leak into the next report', () async {
    reporter
      ..report(
        Exception('first'),
        null,
        fatal: true,
        groupKey: 'first',
        tags: <String, String>{'a': '1'},
        extra: <String, Object?>{'b': 2},
      )
      ..report(Exception('second'), null);
    await settle();

    expect(events, hasLength(2));
    final SentryEvent second = events.firstWhere(
      (SentryEvent event) => event.throwable.toString().contains('second'),
    );
    expect(second.fingerprint, isNot(contains('first')));
    expect(second.tags ?? <String, String>{}, isNot(contains('a')));
    expect(second.contexts[SentryErrorReporter.extraContextKey], isNull);
    expect(second.level, isNot(SentryLevel.fatal));
  });

  test('fatal sets the fatal level', () async {
    reporter.report(Exception('fatal'), StackTrace.current, fatal: true);
    await settle();

    expect(events.single.level, SentryLevel.fatal);
  });

  test('setUser sets only the id, and null clears it', () async {
    reporter.setUser('42');
    await settle();
    reporter.report(Exception('with user'), null);
    await settle();

    final SentryUser? user = events.single.user;
    expect(user?.id, '42');
    expect(user?.email, isNull);
    expect(user?.username, isNull);
    expect(user?.ipAddress, isNull);
    expect(user?.name, isNull);

    reporter.setUser(null);
    await settle();
    reporter.report(Exception('without user'), null);
    await settle();

    expect(events[1].user, isNull);
  });

  test('breadcrumbs are attached to the next report', () async {
    reporter
      ..addBreadcrumb(
        'GET /orders 200',
        category: 'network',
        level: BreadcrumbLevel.warning,
        data: <String, Object?>{'duration': 12},
      )
      ..addBreadcrumb('plain');
    await settle();
    reporter.report(Exception('after breadcrumbs'), null);
    await settle();

    final List<Breadcrumb> crumbs = events.single.breadcrumbs!;
    final Breadcrumb network = crumbs.firstWhere(
      (Breadcrumb crumb) => crumb.message == 'GET /orders 200',
    );
    expect(network.category, 'network');
    expect(network.level, SentryLevel.warning);
    expect(network.data, <String, Object?>{'duration': 12});

    final Breadcrumb plain = crumbs.firstWhere(
      (Breadcrumb crumb) => crumb.message == 'plain',
    );
    expect(plain.category, isNull);
    expect(plain.level, SentryLevel.info);
  });

  test('maps every breadcrumb level', () async {
    for (final BreadcrumbLevel level in BreadcrumbLevel.values) {
      reporter.addBreadcrumb(level.name, level: level);
    }
    await settle();
    reporter.report(Exception('levels'), null);
    await settle();

    final Map<String?, SentryLevel?> levels = <String?, SentryLevel?>{
      for (final Breadcrumb crumb in events.single.breadcrumbs!)
        crumb.message: crumb.level,
    };
    expect(levels, <String?, SentryLevel?>{
      'debug': SentryLevel.debug,
      'info': SentryLevel.info,
      'warning': SentryLevel.warning,
      'error': SentryLevel.error,
    });
  });
}
