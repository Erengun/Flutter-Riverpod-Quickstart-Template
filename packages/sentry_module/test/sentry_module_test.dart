import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:sentry_module/sentry_module.dart';

AppConfig _config(Flavor flavor) =>
    AppConfig(flavor: flavor, apiBaseUrl: 'https://example.com', apiKey: '');

const String _dsn = 'https://public@example.ingest.sentry.io/1';

void main() {
  group('SentryModule', () {
    test('runs on all six platforms', () {
      expect(SentryModule().platforms, KonteynerPlatform.values.toSet());
    });

    test('dev never starts Sentry and returns the no-op reporter', () async {
      int starts = 0;
      final SentryModule module = SentryModule(
        dsn: _dsn,
        start: (FlutterOptionsConfiguration configure) async => starts++,
      );

      final ModuleContributions contributions = await module.init(
        _config(Flavor.dev),
      );

      expect(starts, 0);
      expect(contributions.errorReporter, isA<NoopErrorReporter>());
      expect(contributions.analytics, isNull);
      expect(contributions.remoteFlags, isNull);
    });

    for (final Flavor flavor in <Flavor>[Flavor.staging, Flavor.prod]) {
      test('${flavor.name} starts Sentry with the flavor as environment and '
          'returns the Sentry reporter', () async {
        final List<SentryFlutterOptions> started = <SentryFlutterOptions>[];
        final SentryModule module = SentryModule(
          dsn: _dsn,
          start: (FlutterOptionsConfiguration configure) async {
            final SentryFlutterOptions options = SentryFlutterOptions();
            await configure(options);
            started.add(options);
          },
        );

        final ModuleContributions contributions = await module.init(
          _config(flavor),
        );

        expect(started, hasLength(1));
        expect(started.single.dsn, _dsn);
        expect(started.single.environment, flavor.name);
        expect(contributions.errorReporter, isA<SentryErrorReporter>());
      });
    }

    test('the default empty DSN never starts Sentry', () async {
      int starts = 0;
      final SentryModule module = SentryModule(
        start: (FlutterOptionsConfiguration configure) async => starts++,
      );

      final ModuleContributions contributions = await module.init(
        _config(Flavor.prod),
      );

      expect(starts, 0);
      expect(contributions.errorReporter, isA<NoopErrorReporter>());
    });

    test('the DSN constant ships empty', () {
      expect(sentryDsn, isEmpty);
    });
  });

  group('configureSentryOptions', () {
    late SentryFlutterOptions options;

    setUp(() {
      options = SentryFlutterOptions();
      configureSentryOptions(options, _config(Flavor.staging), dsn: _dsn);
    });

    test('sets the DSN and the flavor as environment', () {
      expect(options.dsn, _dsn);
      expect(options.environment, 'staging');
    });

    test('keeps every error and crash-free statistics on', () {
      expect(options.sampleRate, 1.0);
      expect(options.enableAutoSessionTracking, isTrue);
    });

    test('turns tracing off', () {
      expect(options.tracesSampleRate, isNull);
      expect(options.tracesSampler, isNull);
      expect(options.isTracingEnabled(), isFalse);
      expect(options.enableAutoPerformanceTracing, isFalse);
    });

    test('turns screenshots and replay off', () {
      expect(options.attachScreenshot, isFalse);
      expect(options.replay.sessionSampleRate, 0);
      expect(options.replay.onErrorSampleRate, 0);
    });

    test('sends no PII, no HTTP failures and no logs', () {
      expect(options.sendDefaultPii, isFalse);
      expect(options.captureFailedRequests, isFalse);
      expect(options.captureNativeFailedRequests, isFalse);
      expect(options.enableLogs, isFalse);
    });

    test('leaves release and dist to sentry_flutter', () {
      expect(options.release, isNull);
      expect(options.dist, isNull);
    });
  });
}
