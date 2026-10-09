import 'dart:async';
import 'dart:ui';

import 'package:core/core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logging/logging.dart';

import '../support/recording_reporter.dart';

void main() {
  late RecordingReporter reporter;
  late List<LogRecord> logged;

  setUp(() {
    reporter = RecordingReporter();
    logged = <LogRecord>[];
    configureLogging(
      LogPolicy.forFlavor(Flavor.dev),
      reporter: reporter,
      printer: logged.add,
    );
  });

  tearDown(resetLogging);

  test('uncaught errors are logged once at SEVERE and never reported', () {
    final FlutterExceptionHandler? originalFlutter = FlutterError.onError;
    final ErrorCallback? originalPlatform = PlatformDispatcher.instance.onError;
    addTearDown(() {
      FlutterError.onError = originalFlutter;
      PlatformDispatcher.instance.onError = originalPlatform;
    });

    installUncaughtErrorLogging();
    final StateError flutterError = StateError('build failed');
    final StateError asyncError = StateError('async failed');

    FlutterError.onError!(FlutterErrorDetails(exception: flutterError));
    final bool handled = PlatformDispatcher.instance.onError!(
      asyncError,
      StackTrace.current,
    );

    expect(handled, isFalse);
    expect(logged.map((LogRecord r) => r.error), <Object>[
      flutterError,
      asyncError,
    ]);
    expect(logged.every((LogRecord r) => r.level == Level.SEVERE), isTrue);
    expect(reporter.reports, isEmpty);
    expect(reporter.breadcrumbs, isEmpty);
  });

  group('runGuarded', () {
    late List<Object> forwarded;

    setUp(() {
      final ErrorCallback? original = PlatformDispatcher.instance.onError;
      addTearDown(() => PlatformDispatcher.instance.onError = original);
      forwarded = <Object>[];
      PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
        forwarded.add(error);
        return false;
      };
    });

    test('on web, sends an uncaught async error to '
        'PlatformDispatcher.onError once', () async {
      final StateError error = StateError('async on web');
      final Completer<void> thrown = Completer<void>();

      await runGuarded(() async {
        Timer.run(() {
          thrown.complete();
          throw error;
        });
      }, platform: KonteynerPlatform.web);
      await thrown.future;
      await pumpEventQueue();

      expect(forwarded, <Object>[error]);
    });

    test('on web, logs the error when PlatformDispatcher.onError is '
        'unset', () async {
      PlatformDispatcher.instance.onError = null;
      final StateError error = StateError('no handler');

      await runGuarded(() async {
        Timer.run(() => throw error);
      }, platform: KonteynerPlatform.web);
      await pumpEventQueue();

      expect(logged.map((LogRecord r) => r.error), <Object>[error]);
      expect(logged.single.level, Level.SEVERE);
    });

    for (final KonteynerPlatform platform in KonteynerPlatform.values.where(
      (KonteynerPlatform p) => p != KonteynerPlatform.web,
    )) {
      test("on ${platform.name}, runs the body in the caller's zone", () async {
        final Zone caller = Zone.current;
        Zone? bodyZone;

        await runGuarded(() async {
          bodyZone = Zone.current;
        }, platform: platform);

        expect(bodyZone, same(caller));
        expect(forwarded, isEmpty);
      });
    }
  });
}
