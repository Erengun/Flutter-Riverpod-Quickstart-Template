import 'dart:async';
import 'dart:typed_data';

import 'package:core/core.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';

import '../support/fake_http_adapter.dart';
import '../support/recording_reporter.dart';

/// 200 for a request carrying the `new` token, 401 for anything else.
FakeReply _acceptsNewToken() {
  return (RequestOptions options) =>
      options.headers['Authorization'] == 'Bearer new'
      ? jsonReply(200, <String, Object?>{'ok': true})(options)
      : jsonReply(401, <String, Object?>{'error': 'expired'})(options);
}

DioException _refreshStatus(int status) {
  final RequestOptions options = RequestOptions(path: '/refresh');
  return DioException.badResponse(
    statusCode: status,
    requestOptions: options,
    response: Response<Object?>(requestOptions: options, statusCode: status),
  );
}

void main() {
  group('AuthInterceptor on a 401', () {
    Session? session;
    late int refreshCalls;
    late int expiredCalls;
    late Completer<void> refreshGate;
    late RecordingReporter reporter;
    late FakeHttpAdapter adapter;
    late Dio dio;
    late ApiCall apiCall;

    setUp(() {
      session = const Session(accessToken: 'old', refreshToken: 'r1');
      refreshCalls = 0;
      expiredCalls = 0;
      refreshGate = Completer<void>()..complete();
      reporter = RecordingReporter();
      apiCall = ApiCall(reporter);
    });

    Future<Session> refreshToNew(Session current) async {
      refreshCalls++;
      await refreshGate.future;
      return Session(
        accessToken: 'new',
        refreshToken: 'r2',
        userId: current.userId,
      );
    }

    void build({RefreshHook? refresh, FakeReply? reply}) {
      adapter = FakeHttpAdapter(<FakeReply>[reply ?? _acceptsNewToken()]);
      dio = createDio(
        'https://api.example.com',
        reporter: reporter,
        interceptors: <Interceptor>[
          AuthInterceptor(
            session: () => session,
            refreshHook: () => refresh,
            onRefreshed: (Session next) async => session = next,
            onExpired: () async {
              expiredCalls++;
              await Future<void>.delayed(Duration.zero);
              session = null;
            },
            reporter: reporter,
          ),
        ],
        retryDelays: const <Duration>[Duration.zero],
      )..httpClientAdapter = adapter;
    }

    List<Object?> sentTokens() => adapter.requests
        .map((RequestOptions request) => request.headers['Authorization'])
        .toList();

    Future<ApiException> failure(Future<Object?> request) async {
      try {
        await request;
      } catch (error) {
        return apiCall.map(error);
      }
      fail('The request succeeded.');
    }

    test('concurrent 401s share one refresh; each is replayed once', () async {
      refreshGate = Completer<void>();
      build(refresh: refreshToNew);

      final List<Future<Response<Object?>>> requests =
          <Future<Response<Object?>>>[
            dio.get<Object?>('/a'),
            dio.get<Object?>('/b'),
            dio.post<Object?>('/c', data: <String, Object?>{'x': 1}),
          ];
      await pumpEventQueue();
      expect(refreshCalls, 1);
      refreshGate.complete();
      final List<Response<Object?>> responses = await Future.wait(requests);

      expect(
        responses.map((Response<Object?> response) => response.statusCode),
        <int>[200, 200, 200],
      );
      expect(refreshCalls, 1);
      expect(sentTokens(), <Object?>[
        'Bearer old',
        'Bearer old',
        'Bearer old',
        'Bearer new',
        'Bearer new',
        'Bearer new',
      ]);
      expect(
        adapter.requests.skip(3).map((RequestOptions r) => r.path).toSet(),
        <String>{'/a', '/b', '/c'},
      );
      expect(session?.accessToken, 'new');
      expect(expiredCalls, 0);
    });

    test('a later 401 starts a new refresh', () async {
      build(refresh: refreshToNew);
      await dio.get<Object?>('/a');
      session = const Session(accessToken: 'old', refreshToken: 'r2');

      await dio.get<Object?>('/b');

      expect(refreshCalls, 2);
    });

    test('a request sent with an older token replays without a refresh', () {
      final FakeReply accepts = _acceptsNewToken();
      build(
        refresh: refreshToNew,
        reply: (RequestOptions options) {
          // Someone else refreshed while this request was in flight.
          if (options.headers['Authorization'] == 'Bearer old') {
            session = const Session(accessToken: 'new', refreshToken: 'r2');
          }
          return accepts(options);
        },
      );

      return dio.get<Object?>('/a').then((Response<Object?> response) {
        expect(response.statusCode, 200);
        expect(refreshCalls, 0);
        expect(sentTokens(), <Object?>['Bearer old', 'Bearer new']);
      });
    });

    test('replays a multipart body', () async {
      build(refresh: refreshToNew);

      final Response<Object?> response = await dio.post<Object?>(
        '/upload',
        data: FormData.fromMap(<String, Object?>{'name': 'file'}),
      );

      expect(response.statusCode, 200);
      expect(sentTokens(), <Object?>['Bearer old', 'Bearer new']);
    });

    test('without a refresh hook a 401 signs out once', () async {
      build();

      final List<ApiException> errors = await Future.wait(
        <Future<ApiException>>[
          failure(dio.get<Object?>('/a')),
          failure(dio.get<Object?>('/b')),
        ],
      );

      expect(errors, everyElement(isA<ApiUnauthorizedException>()));
      expect(expiredCalls, 1);
      expect(session, isNull);
      expect(adapter.requests, hasLength(2));
      expect(reporter.reports, isEmpty);
    });

    test('without a refresh token a 401 signs out', () async {
      session = const Session(accessToken: 'old');
      build(refresh: refreshToNew);

      expect(
        await failure(dio.get<Object?>('/a')),
        isA<ApiUnauthorizedException>(),
      );
      expect(refreshCalls, 0);
      expect(expiredCalls, 1);
    });

    for (final (String name, Exception error) in <(String, Exception)>[
      ('400', _refreshStatus(400)),
      ('401', _refreshStatus(401)),
      ('unauthorized', const ApiUnauthorizedException()),
      ('server 400', const ApiServerException(400)),
    ]) {
      test('a refresh rejected with $name signs out once; waiting requests '
          'fail as unauthorized', () async {
        refreshGate = Completer<void>();
        build(
          refresh: (Session current) async {
            refreshCalls++;
            await refreshGate.future;
            throw error;
          },
        );

        final List<Future<ApiException>> waiting = <Future<ApiException>>[
          failure(dio.get<Object?>('/a')),
          failure(dio.get<Object?>('/b')),
        ];
        await pumpEventQueue();
        refreshGate.complete();
        final List<ApiException> errors = await Future.wait(waiting);

        expect(errors, everyElement(isA<ApiUnauthorizedException>()));
        expect(refreshCalls, 1);
        expect(expiredCalls, 1);
        expect(session, isNull);
        // Nothing was replayed.
        expect(adapter.requests, hasLength(2));
      });
    }

    for (final (String name, Exception error, Matcher kind)
        in <(String, Exception, Matcher)>[
          (
            'no network',
            DioException.connectionError(
              requestOptions: RequestOptions(path: '/refresh'),
              reason: 'offline',
            ),
            isA<ApiConnectionException>(),
          ),
          ('a 503', _refreshStatus(503), isA<ApiServerException>()),
          (
            'a mapped 503',
            const ApiServerException(503),
            isA<ApiServerException>(),
          ),
        ]) {
      test('$name during the refresh keeps the user signed in', () async {
        build(
          refresh: (Session current) async {
            refreshCalls++;
            throw error;
          },
        );

        final List<ApiException> errors = await Future.wait(
          <Future<ApiException>>[
            failure(dio.get<Object?>('/a')),
            failure(dio.get<Object?>('/b')),
          ],
        );

        expect(errors, everyElement(kind));
        if (error is DioException) {
          expect(
            errors.map((ApiException e) => e.request?.path),
            containsAll(<String>['/a', '/b']),
            reason: 'The error points at the waiting request.',
          );
        }
        expect(expiredCalls, 0);
        expect(session?.accessToken, 'old');
        // Neither retried with the stale token nor replayed.
        expect(adapter.requests, hasLength(2));
      });
    }

    test('a 401 right after a successful refresh is reported once, then '
        'signs out', () async {
      refreshGate = Completer<void>();
      build(
        refresh: refreshToNew,
        reply: jsonReply(401, <String, Object?>{'error': 'expired'}),
      );

      final List<Future<ApiException>> waiting = <Future<ApiException>>[
        failure(dio.get<Object?>('/orders/12')),
        failure(dio.get<Object?>('/orders/13')),
      ];
      await pumpEventQueue();
      refreshGate.complete();
      final List<ApiException> errors = await Future.wait(waiting);

      expect(errors, everyElement(isA<ApiUnauthorizedException>()));
      expect(refreshCalls, 1);
      expect(sentTokens(), <Object?>[
        'Bearer old',
        'Bearer old',
        'Bearer new',
        'Bearer new',
      ]);
      expect(reporter.reports, hasLength(1));
      final RecordedReport report = reporter.reports.single;
      expect(report.error, isA<UnauthorizedAfterRefreshException>());
      expect(report.fatal, isFalse);
      expect(report.tags['http.path'], '/orders/:id');
      expect(expiredCalls, 1);
      expect(session, isNull);
    });

    test('a request marked skipAuth never refreshes', () async {
      build(refresh: refreshToNew);

      await failure(
        dio.post<Object?>(
          '/refresh',
          options: Options(extra: <String, Object?>{skipAuthKey: true}),
        ),
      );

      expect(refreshCalls, 0);
      expect(expiredCalls, 0);
    });

    test('a request with its own Authorization header never refreshes', () {
      build(refresh: refreshToNew);

      return failure(
        dio.post<Object?>(
          '/logout',
          options: Options(
            headers: <String, Object?>{'Authorization': 'Bearer gone'},
          ),
        ),
      ).then((_) {
        expect(refreshCalls, 0);
        expect(expiredCalls, 0);
      });
    });

    test('a 401 while signed out passes through', () async {
      session = null;
      build(refresh: refreshToNew);

      expect(
        await failure(dio.get<Object?>('/a')),
        isA<ApiUnauthorizedException>(),
      );
      expect(refreshCalls, 0);
      expect(expiredCalls, 0);
    });

    test('a logout during the refresh is not undone', () async {
      refreshGate = Completer<void>();
      build(refresh: refreshToNew);

      final Future<ApiException> waiting = failure(dio.get<Object?>('/a'));
      await pumpEventQueue();
      session = null;
      refreshGate.complete();

      expect(await waiting, isA<ApiUnauthorizedException>());
      expect(session, isNull);
      expect(expiredCalls, 0);
    });
  });

  group('the shared Dio', () {
    late Box<String> box;
    late RecordingReporter reporter;
    late FakeHttpAdapter adapter;

    setUp(() async {
      box = await Hive.openBox<String>(sessionBoxName, bytes: Uint8List(0));
      reporter = RecordingReporter();
    });

    tearDown(() => box.close());

    /// A container whose auth Feature refreshes at `POST /refresh`, which
    /// answers with [refreshReply].
    Future<ProviderContainer> signedIn(FakeReply refreshReply) async {
      final FakeReply accepts = _acceptsNewToken();
      adapter = FakeHttpAdapter(<FakeReply>[
        (RequestOptions options) => options.path == '/refresh'
            ? refreshReply(options)
            : accepts(options),
      ]);
      final ProviderContainer container = ProviderContainer(
        overrides: <Override>[
          appConfigProvider.overrideWithValue(
            const AppConfig(
              flavor: Flavor.prod,
              apiBaseUrl: 'https://api.example.com/',
              apiKey: '',
            ),
          ),
          sessionBoxProvider.overrideWith((Ref ref) async => box),
          errorReporterProvider.overrideWithValue(reporter),
          sessionHooksProvider.overrideWith(
            (Ref ref) => SessionHooks(
              // What an auth Feature's hook looks like.
              refresh: (Session session) async {
                final Response<Map<String, Object?>> response = await ref
                    .read(dioProvider)
                    .post<Map<String, Object?>>(
                      '/refresh',
                      data: <String, Object?>{
                        'refreshToken': session.refreshToken,
                      },
                      options: Options(
                        extra: <String, Object?>{skipAuthKey: true},
                      ),
                    );
                return Session(
                  accessToken: response.data!['token']! as String,
                  refreshToken: session.refreshToken,
                  userId: session.userId,
                );
              },
            ),
          ),
        ],
      );
      addTearDown(container.dispose);
      container.read(dioProvider).httpClientAdapter = adapter;
      await container.read(sessionProvider.future);
      await container
          .read(sessionProvider.notifier)
          .signIn(const Session(accessToken: 'old', refreshToken: 'r1'));
      return container;
    }

    test('saves the refreshed tokens', () async {
      final ProviderContainer container = await signedIn(
        jsonReply(200, <String, Object?>{'token': 'new'}),
      );

      final Response<Object?> response = await container
          .read(dioProvider)
          .get<Object?>('/orders');

      expect(response.statusCode, 200);
      expect(
        container.read(sessionProvider).value,
        const Session(accessToken: 'new', refreshToken: 'r1'),
      );
      expect(box.get('accessToken'), 'new');
      // The refresh call itself carried no token.
      expect(
        adapter.requests
            .singleWhere((RequestOptions r) => r.path == '/refresh')
            .headers['Authorization'],
        isNull,
      );
    });

    test('a rejected refresh signs out and returns to the same place after '
        'signing in', () async {
      final ProviderContainer container = await signedIn(
        jsonReply(401, <String, Object?>{'error': 'refresh expired'}),
      );
      final ApiCall apiCall = container.read(apiCallProvider);

      await expectLater(
        apiCall(() => container.read(dioProvider).get<Object?>('/orders')),
        throwsA(isA<ApiUnauthorizedException>()),
      );

      expect(container.read(sessionProvider).value, isNull);
      expect(box.isEmpty, isTrue);
      expect(container.read(sessionExpiredProvider), isTrue);
      expect(reporter.reports, isEmpty);

      String? redirect(String location) {
        final Uri uri = Uri.parse(location);
        return sessionRedirect(
          container.read(sessionProvider),
          uri.path,
          splashPath: '/splash',
          loginPath: '/login',
          homePath: '/home',
          uri: uri,
          expired: container.read(sessionExpiredProvider),
        );
      }

      final String? login = redirect('/orders?tab=2');
      expect(login, '/login?from=%2Forders%3Ftab%3D2');
      expect(redirect(login!), isNull);

      await container
          .read(sessionProvider.notifier)
          .signIn(const Session(accessToken: 'new'));

      expect(container.read(sessionExpiredProvider), isFalse);
      expect(redirect(login), '/orders?tab=2');
    });
  });
}
