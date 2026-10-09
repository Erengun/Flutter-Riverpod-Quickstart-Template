import 'dart:typed_data';

import 'package:core/core.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';

import '../support/fake_http_adapter.dart';

void main() {
  group('AuthInterceptor', () {
    String? token;
    late FakeHttpAdapter adapter;
    late Dio dio;

    setUp(() {
      token = null;
      adapter = FakeHttpAdapter(<FakeReply>[jsonReply(200, null)]);
      dio = createDio(
        'https://api.example.com',
        interceptors: <Interceptor>[
          AuthInterceptor(
            session: () => switch (token) {
              final String value => Session(accessToken: value),
              null => null,
            },
          ),
        ],
        retryDelays: const <Duration>[],
      )..httpClientAdapter = adapter;
    });

    String? authorization() =>
        adapter.requests.single.headers['Authorization'] as String?;

    test('adds the access token while signed in', () async {
      token = 'abc';
      await dio.get<Object?>('/orders');
      expect(authorization(), 'Bearer abc');
    });

    test('adds nothing while signed out', () async {
      await dio.get<Object?>('/orders');
      expect(authorization(), isNull);
    });

    test('skips requests marked skipAuth', () async {
      token = 'abc';
      await dio.post<Object?>(
        '/login',
        options: Options(extra: <String, Object?>{skipAuthKey: true}),
      );
      expect(authorization(), isNull);
    });

    test('keeps an Authorization header the request already has', () async {
      token = 'new';
      await dio.post<Object?>(
        '/logout',
        options: Options(
          headers: <String, Object?>{'authorization': 'Bearer old'},
        ),
      );
      expect(
        adapter.requests.single.headers.entries
            .where(
              (MapEntry<String, dynamic> e) =>
                  e.key.toLowerCase() == 'authorization',
            )
            .map((MapEntry<String, dynamic> e) => e.value),
        <Object?>['Bearer old'],
      );
    });
  });

  test('the shared Dio sends the session token by default', () async {
    final Box<String> box = await Hive.openBox<String>(
      sessionBoxName,
      bytes: Uint8List(0),
    );
    addTearDown(box.close);
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
      ],
    );
    addTearDown(container.dispose);
    final FakeHttpAdapter adapter = FakeHttpAdapter(<FakeReply>[
      jsonReply(200, null),
    ]);
    final Dio dio = container.read(dioProvider)..httpClientAdapter = adapter;

    await container.read(sessionProvider.future);
    await dio.get<Object?>('/a');
    await container
        .read(sessionProvider.notifier)
        .signIn(const Session(accessToken: 'abc'));
    await dio.get<Object?>('/b');
    await container.read(sessionProvider.notifier).logout();
    await dio.get<Object?>('/c');

    expect(
      adapter.requests.map(
        (RequestOptions request) => request.headers['Authorization'],
      ),
      <Object?>[null, 'Bearer abc', null],
    );
    // The token is read per request: the Dio itself never changed.
    expect(container.read(dioProvider), same(dio));
  });
}
