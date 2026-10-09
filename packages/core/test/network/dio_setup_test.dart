import 'package:core/core.dart';
import 'package:dio/dio.dart';
import 'package:dio_smart_retry/dio_smart_retry.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logging/logging.dart';

import '../support/fake_http_adapter.dart';
import '../support/recording_reporter.dart';

class _ExtraInterceptor extends Interceptor {}

// Dio adds its own ImplyContentTypeInterceptor first; it isn't exported.
bool _ours(Interceptor interceptor) =>
    interceptor.runtimeType.toString() != 'ImplyContentTypeInterceptor';

const AppConfig _dev = AppConfig(
  flavor: Flavor.dev,
  apiBaseUrl: 'https://api.example.com/',
  apiKey: 'demo-key',
);

void main() {
  test('createDio applies the base URL and timeouts', () {
    final Dio dio = createDio('https://api.example.com');
    expect(dio.options.baseUrl, 'https://api.example.com');
    expect(dio.options.connectTimeout, const Duration(seconds: 10));
    expect(dio.options.sendTimeout, const Duration(seconds: 30));
    expect(dio.options.receiveTimeout, const Duration(seconds: 30));
    expect(dio.options.headers.containsKey('content-type'), isFalse);
  });

  test('interceptors run extras, breadcrumb, retry, then logging', () {
    final _ExtraInterceptor extra = _ExtraInterceptor();
    final Dio dio = createDio(
      'https://api.example.com',
      interceptors: <Interceptor>[extra],
      logRequests: true,
    );
    final List<Interceptor> own = dio.interceptors.where(_ours).toList();
    expect(own, hasLength(4));
    expect(own[0], same(extra));
    expect(own[1], isA<BreadcrumbInterceptor>());
    expect(own[2], isA<RetryInterceptor>());
    expect(own[3], isA<RedactedLogInterceptor>());
  });

  test('no logging interceptor unless asked', () {
    final Dio dio = createDio('https://api.example.com');
    expect(dio.interceptors.whereType<RedactedLogInterceptor>(), isEmpty);
  });

  group('dioProvider', () {
    ProviderContainer container(AppConfig config, {List<Override>? more}) {
      final ProviderContainer c = ProviderContainer(
        overrides: <Override>[
          appConfigProvider.overrideWithValue(config),
          ...?more,
        ],
      );
      addTearDown(c.dispose);
      return c;
    }

    test('uses the config base URL and api key', () {
      final Dio dio = container(_dev).read(dioProvider);
      expect(dio.options.baseUrl, 'https://api.example.com/');
      expect(dio.options.headers['x-api-key'], 'demo-key');
    });

    test('logs on dev and staging, not prod', () {
      bool logs(Flavor flavor) =>
          container(
                AppConfig(
                  flavor: flavor,
                  apiBaseUrl: _dev.apiBaseUrl,
                  apiKey: _dev.apiKey,
                ),
              )
              .read(dioProvider)
              .interceptors
              .whereType<RedactedLogInterceptor>()
              .isNotEmpty;

      expect(logs(Flavor.dev), isTrue);
      expect(logs(Flavor.staging), isTrue);
      expect(logs(Flavor.prod), isFalse);
    });

    test('puts the app extras first', () {
      final _ExtraInterceptor extra = _ExtraInterceptor();
      final Dio dio = container(
        _dev,
        more: <Override>[
          dioInterceptorsProvider.overrideWithValue(<Interceptor>[extra]),
        ],
      ).read(dioProvider);
      expect(dio.interceptors.where(_ours).first, same(extra));
    });
  });

  test('one breadcrumb per request, without query values', () async {
    final RecordingReporter reporter = RecordingReporter();
    final Dio dio = createDio('https://api.example.com', reporter: reporter)
      ..httpClientAdapter = FakeHttpAdapter(<FakeReply>[jsonReply(200, null)]);

    await dio.get<Object?>(
      '/orders/42',
      queryParameters: <String, Object?>{'token': 'secret'},
    );

    final RecordedBreadcrumb crumb = reporter.breadcrumbs.single;
    expect(crumb.category, 'http');
    expect(crumb.message, 'GET /orders/:id 200');
    expect(crumb.data['method'], 'GET');
    expect(crumb.data['path'], '/orders/:id');
    expect(crumb.data['status'], 200);
    expect(crumb.data['duration_ms'], isA<int>());
    expect(crumb.toString(), isNot(contains('secret')));
  });

  test('the log redacts Authorization and x-api-key', () async {
    final List<LogRecord> records = <LogRecord>[];
    configureLogging(
      LogPolicy.forFlavor(Flavor.dev),
      reporter: RecordingReporter(),
      printer: records.add,
    );
    addTearDown(resetLogging);

    final Dio dio = createDio(
      'https://api.example.com',
      headers: <String, String>{'x-api-key': 'demo-key'},
      logRequests: true,
    )..httpClientAdapter = FakeHttpAdapter(<FakeReply>[jsonReply(200, null)]);

    await dio.get<Object?>(
      '/me',
      options: Options(
        headers: <String, Object?>{'Authorization': 'Bearer t0k'},
      ),
    );

    final String log = records
        .where((LogRecord r) => r.loggerName == 'network')
        .map((LogRecord r) => r.message)
        .join('\n');
    expect(log, contains('--> GET https://api.example.com/me'));
    expect(log, isNot(contains('demo-key')));
    expect(log, isNot(contains('t0k')));
    expect(log, contains('<redacted>'));
    expect(
      records
          .where((LogRecord r) => r.loggerName == 'network')
          .every((LogRecord r) => r.level == Level.FINE),
      isTrue,
    );
  });
}
