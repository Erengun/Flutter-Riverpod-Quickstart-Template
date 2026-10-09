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
}
