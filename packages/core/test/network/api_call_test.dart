import 'package:core/core.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_http_adapter.dart';
import '../support/recording_reporter.dart';

class _Harness {
  _Harness(List<FakeReply> replies, {this.method = 'GET'})
    : adapter = FakeHttpAdapter(replies) {
    dio = createDio(
      'https://api.example.com',
      reporter: reporter,
      retryDelays: const <Duration>[],
    )..httpClientAdapter = adapter;
    apiCall = ApiCall(reporter);
  }

  final FakeHttpAdapter adapter;
  final RecordingReporter reporter = RecordingReporter();
  final String method;
  late final Dio dio;
  late final ApiCall apiCall;

  Future<Object?> send(String path, {CancelToken? cancelToken}) {
    return apiCall<Object?>(() async {
      final Response<Object?> response = await dio.request<Object?>(
        path,
        cancelToken: cancelToken,
        options: Options(method: method),
      );
      return response.data;
    });
  }

  Future<ApiException> failure(String path, {CancelToken? cancelToken}) async {
    try {
      await send(path, cancelToken: cancelToken);
    } on ApiException catch (error) {
      return error;
    }
    fail('expected an ApiException');
  }

  List<RecordedBreadcrumb> get apiBreadcrumbs => reporter.breadcrumbs
      .where((RecordedBreadcrumb b) => b.message.startsWith('API error'))
      .toList();
}

void main() {
  group('mapping', () {
    test('a connection error is connection', () async {
      final _Harness h = _Harness(<FakeReply>[connectionErrorReply()]);
      expect(await h.failure('/a'), isA<ApiConnectionException>());
    });

    test('a timeout is timeout', () async {
      final _Harness h = _Harness(<FakeReply>[receiveTimeoutReply()]);
      expect(await h.failure('/a'), isA<ApiTimeoutException>());
    });

    test('a cancelled request is cancelled', () async {
      final _Harness h = _Harness(<FakeReply>[
        jsonReply(200, <String, Object?>{}),
      ]);
      final CancelToken token = CancelToken()..cancel();
      expect(
        await h.failure('/a', cancelToken: token),
        isA<ApiCancelledException>(),
      );
    });

    test('401, 403 and 404 map to their kinds', () async {
      expect(
        await _Harness(<FakeReply>[jsonReply(401, null)]).failure('/a'),
        isA<ApiUnauthorizedException>(),
      );
      expect(
        await _Harness(<FakeReply>[jsonReply(403, null)]).failure('/a'),
        isA<ApiForbiddenException>(),
      );
      expect(
        await _Harness(<FakeReply>[jsonReply(404, null)]).failure('/a'),
        isA<ApiNotFoundException>(),
      );
    });

    test('any other 4xx/5xx is server, with its status', () async {
      final ApiException error = await _Harness(<FakeReply>[
        jsonReply(422, null),
      ]).failure('/a');
      expect(error, isA<ApiServerException>());
      expect((error as ApiServerException).statusCode, 422);
    });

    test('an error body envelope gives its errorMessage', () async {
      final ApiException error = await _Harness(<FakeReply>[
        jsonReply(400, <String, Object?>{
          'success': false,
          'errorMessage': 'Email is taken',
          'message': 'ignored',
        }),
      ]).failure('/a');
      expect(error.message, 'Email is taken');
    });

    test('malformed JSON is decode', () async {
      final _Harness h = _Harness(<FakeReply>[malformedJsonReply()]);
      expect(await h.failure('/a'), isA<ApiDecodeException>());
    });

    test(
      'a parse error logged by retrofit is decode, with its request',
      () async {
        final _Harness h = _Harness(<FakeReply>[
          jsonReply(200, <String, Object?>{'id': 'not a number'}),
        ]);
        Object? caught;
        try {
          await h.apiCall<int>(() async {
            final Response<Map<String, dynamic>> response = await h.dio
                .get<Map<String, dynamic>>('/users/42');
            // What retrofit's generated code does around fromJson.
            try {
              return response.data!['id'] as int;
            } on Object catch (e, s) {
              apiParseErrorLogger.logError(
                e,
                s,
                response.requestOptions,
                response: response,
              );
              rethrow;
            }
          });
        } on ApiException catch (error) {
          caught = error;
        }
        expect(caught, isA<ApiDecodeException>());
        final ApiRequestInfo request = (caught! as ApiException).request!;
        expect(request.method, 'GET');
        expect(request.path, '/users/:id');
        expect(request.statusCode, 200);
      },
    );

    test('anything else is unknown', () async {
      final ApiCall apiCall = ApiCall(RecordingReporter());
      await expectLater(
        apiCall<int>(() async => throw StateError('boom')),
        throwsA(isA<ApiUnknownException>()),
      );
    });

    test('an ApiException passes through unchanged', () async {
      final ApiCall apiCall = ApiCall(RecordingReporter());
      const ApiException original = ApiForbiddenException(message: 'no');
      await expectLater(
        apiCall<int>(() async => throw original),
        throwsA(same(original)),
      );
    });
  });

  group('retry', () {
    test('a GET 503 is retried 3 times, then fails as server', () async {
      final _Harness h = _Harness(<FakeReply>[jsonReply(503, null)]);
      expect(await h.failure('/a'), isA<ApiServerException>());
      expect(h.adapter.requests, hasLength(4));
    });

    test('a POST 503 is not retried', () async {
      final _Harness h = _Harness(<FakeReply>[
        jsonReply(503, null),
      ], method: 'POST');
      await h.failure('/a');
      expect(h.adapter.requests, hasLength(1));
    });

    test('a PATCH connection error is not retried', () async {
      final _Harness h = _Harness(<FakeReply>[
        connectionErrorReply(),
      ], method: 'PATCH');
      await h.failure('/a');
      expect(h.adapter.requests, hasLength(1));
    });

    test('a GET 404 is not retried', () async {
      final _Harness h = _Harness(<FakeReply>[jsonReply(404, null)]);
      await h.failure('/a');
      expect(h.adapter.requests, hasLength(1));
    });

    test('a GET receive timeout is not retried', () async {
      final _Harness h = _Harness(<FakeReply>[receiveTimeoutReply()]);
      await h.failure('/a');
      expect(h.adapter.requests, hasLength(1));
    });

    test('connection errors and connect timeouts are retried', () async {
      final _Harness h = _Harness(<FakeReply>[connectionErrorReply()]);
      await h.failure('/a');
      expect(h.adapter.requests, hasLength(4));

      final _Harness t = _Harness(<FakeReply>[connectTimeoutReply()]);
      await t.failure('/a');
      expect(t.adapter.requests, hasLength(4));
    });

    test('a GET 429 then 200 succeeds on the retry', () async {
      final _Harness h = _Harness(<FakeReply>[
        jsonReply(429, null),
        jsonReply(200, <String, Object?>{'ok': true}),
      ]);
      expect(await h.send('/a'), <String, Object?>{'ok': true});
      expect(h.adapter.requests, hasLength(2));
    });

    for (final String method in <String>['PUT', 'DELETE', 'HEAD', 'OPTIONS']) {
      test('a $method 408 is retried', () async {
        final _Harness h = _Harness(<FakeReply>[
          jsonReply(408, null),
        ], method: method);
        await h.failure('/a');
        expect(h.adapter.requests, hasLength(4));
      });
    }
  });

  group('reporting', () {
    test(
      'a server error is reported once with group key, tags and extra',
      () async {
        final _Harness h = _Harness(<FakeReply>[
          jsonReply(
            500,
            <String, Object?>{'errorMessage': 'Database down'},
            headers: <String, List<String>>{
              'x-request-id': <String>['req-123'],
            },
          ),
        ]);
        final ApiException error = await h.failure('/orders/42?token=secret');

        final RecordedReport report = h.reporter.reports.single;
        expect(report.error, same(error));
        expect(report.fatal, isFalse);
        expect(report.groupKey, 'GET /orders/:id 500');
        expect(report.tags, <String, String>{
          'http.method': 'GET',
          'http.path': '/orders/:id',
          'http.status': '500',
        });
        expect(report.extra, <String, Object?>{
          'errorMessage': 'Database down',
          'requestId': 'req-123',
        });
      },
    );

    test('a retried 5xx is one report', () async {
      final _Harness h = _Harness(<FakeReply>[jsonReply(502, null)]);
      await h.failure('/a');
      expect(h.adapter.requests, hasLength(4));
      expect(h.reporter.reports, hasLength(1));
    });

    test(
      'the same method, path and status is reported once per launch',
      () async {
        final _Harness h = _Harness(<FakeReply>[jsonReply(404, null)]);
        await h.failure('/users/42');
        await h.failure('/users/7');
        await h.failure('/users/3f2504e0-4f89-11d3-9a0c-0305e82c3301');

        expect(h.reporter.reports, hasLength(1));
        expect(h.reporter.reports.single.groupKey, 'GET /users/:id 404');
        expect(h.apiBreadcrumbs, hasLength(2));
      },
    );

    test('a different status on the same path is reported again', () async {
      final _Harness h = _Harness(<FakeReply>[
        jsonReply(500, null),
        jsonReply(500, null),
        jsonReply(500, null),
        jsonReply(500, null),
        jsonReply(404, null),
      ]);
      await h.failure('/a');
      await h.failure('/a');
      expect(h.reporter.reports.map((RecordedReport r) => r.groupKey), <String>[
        'GET /a 500',
        'GET /a 404',
      ]);
    });

    test('decode and unknown are reported', () async {
      final _Harness h = _Harness(<FakeReply>[malformedJsonReply()]);
      await h.failure('/a');
      await expectLater(
        h.apiCall<int>(() async => throw StateError('boom')),
        throwsA(isA<ApiUnknownException>()),
      );
      expect(h.reporter.reports, hasLength(2));
    });

    test('the other kinds only leave a breadcrumb', () async {
      final RecordingReporter reporter = RecordingReporter();
      final ApiCall apiCall = ApiCall(reporter);
      final List<ApiException> kinds = <ApiException>[
        const ApiUnauthorizedException(),
        const ApiForbiddenException(),
        const ApiBusinessException(message: 'no'),
        const ApiConnectionException(),
        const ApiTimeoutException(),
        const ApiCancelledException(),
      ];
      for (final ApiException kind in kinds) {
        await expectLater(
          apiCall<int>(() async => throw kind),
          throwsA(same(kind)),
        );
      }
      expect(reporter.reports, isEmpty);
      expect(
        reporter.breadcrumbs.map((RecordedBreadcrumb b) => b.data['kind']),
        <String>[
          'unauthorized',
          'forbidden',
          'business',
          'connection',
          'timeout',
          'cancelled',
        ],
      );
    });

    test('a nested apiCall records the error once', () async {
      final RecordingReporter reporter = RecordingReporter();
      final ApiCall apiCall = ApiCall(reporter);
      await expectLater(
        apiCall<int>(() => apiCall<int>(() async => throw StateError('x'))),
        throwsA(isA<ApiUnknownException>()),
      );
      expect(reporter.reports, hasLength(1));
      expect(reporter.breadcrumbs, isEmpty);
    });
  });

  group('unwrap', () {
    test('returns data when the envelope succeeded', () async {
      final ApiCall apiCall = ApiCall(RecordingReporter());
      final int value = await apiCall.unwrap<int>(
        () async => const BaseResponse<int>(
          success: true,
          data: 7,
          errorMessage: null,
          message: null,
          statusCode: '200',
        ),
      );
      expect(value, 7);
    });

    test('a 2xx envelope with success != true is business', () async {
      final RecordingReporter reporter = RecordingReporter();
      final _Harness h = _Harness(<FakeReply>[
        jsonReply(200, <String, Object?>{
          'success': false,
          'data': null,
          'errorMessage': null,
          'message': 'Out of stock',
          'statusCode': '200',
        }),
      ]);
      final ApiCall apiCall = ApiCall(reporter);
      Object? caught;
      try {
        await apiCall.unwrap<int?>(() async {
          final Response<Map<String, dynamic>> response = await h.dio
              .get<Map<String, dynamic>>('/stock');
          return BaseResponse<int?>.fromJson(
            response.data!,
            (Object? json) => json as int?,
          );
        });
      } on ApiException catch (error) {
        caught = error;
      }
      expect(caught, isA<ApiBusinessException>());
      expect((caught! as ApiException).message, 'Out of stock');
      expect(reporter.reports, isEmpty);
    });
  });
}
