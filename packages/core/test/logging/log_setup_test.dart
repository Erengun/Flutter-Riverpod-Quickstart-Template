import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logging/logging.dart';

import '../support/recording_reporter.dart';

void main() {
  late RecordingReporter reporter;
  late List<LogRecord> printed;

  void configure(Flavor flavor) {
    configureLogging(
      LogPolicy.forFlavor(flavor),
      reporter: reporter,
      printer: printed.add,
    );
  }

  setUp(() {
    reporter = RecordingReporter();
    printed = <LogRecord>[];
  });

  tearDown(resetLogging);

  group('levels per flavor', () {
    test('dev keeps everything and prints it', () {
      configure(Flavor.dev);

      Logger('network').finest('request sent');

      expect(Logger.root.level, Level.ALL);
      expect(printed.map((LogRecord r) => r.message), <String>['request sent']);
    });

    test('staging keeps INFO and above and prints it', () {
      configure(Flavor.staging);

      Logger('network')
        ..fine('request sent')
        ..info('signed in');

      expect(Logger.root.level, Level.INFO);
      expect(printed.map((LogRecord r) => r.message), <String>['signed in']);
    });

    test('prod keeps INFO and above without a console', () {
      configure(Flavor.prod);

      Logger('auth')
        ..fine('token read')
        ..info('signed in');

      expect(Logger.root.level, Level.INFO);
      expect(printed, isEmpty);
      expect(
        reporter.breadcrumbs.map((RecordedBreadcrumb b) => b.message),
        <String>['signed in'],
      );
    });
  });

  group('breadcrumbs', () {
    test('records at INFO and above become breadcrumbs named by logger', () {
      configure(Flavor.dev);

      Logger('auth')
        ..fine('token read')
        ..info('signed in')
        ..warning('session about to expire')
        ..severe('session lost');

      expect(
        reporter.breadcrumbs
            .map(
              (RecordedBreadcrumb b) =>
                  '${b.category} ${b.level.name} '
                  '${b.message}',
            )
            .toList(),
        <String>[
          'auth info signed in',
          'auth warning session about to expire',
          'auth error session lost',
        ],
      );
      expect(reporter.reports, isEmpty);
    });

    test('a record carrying an error never becomes a breadcrumb', () {
      configure(Flavor.dev);

      Logger('auth').severe('echo of a report', StateError('boom'));
      Logger('auth').warning('also an echo', StateError('boom'));

      expect(reporter.breadcrumbs, isEmpty);
      expect(printed, hasLength(2));
    });

    test('configuring again replaces the only listener', () {
      configure(Flavor.dev);
      configure(Flavor.dev);

      Logger('auth').info('signed in');

      expect(reporter.breadcrumbs, hasLength(1));
      expect(printed, hasLength(1));
    });
  });
}
