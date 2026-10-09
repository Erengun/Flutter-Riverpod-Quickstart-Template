import 'dart:convert';
import 'dart:typed_data';

import 'package:core/core.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod_template/features/authentication/data/authentication_repository.dart';
import 'package:flutter_riverpod_template/features/authentication/domain/login_response.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/misc.dart';
import 'package:riverpod/riverpod.dart';

import '../support/storage.dart';

/// Answers every request with [status] and [body], and records requests.
class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this.status, this.body);

  final int status;
  final Object? body;
  final List<RequestOptions> requests = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: <String, List<String>>{
        Headers.contentTypeHeader: <String>[Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

const AppConfig _config = AppConfig(
  flavor: Flavor.dev,
  apiBaseUrl: 'https://reqres.in/',
  apiKey: 'demo-key',
);

ProviderContainer _container(_FakeAdapter adapter, TestStorage storage) {
  final ProviderContainer container = ProviderContainer(
    overrides: <Override>[
      appConfigProvider.overrideWithValue(_config),
      // The auth interceptor reads the session from these boxes.
      ...storage.overrides,
    ],
  );
  container.read(dioProvider).httpClientAdapter = adapter;
  addTearDown(container.dispose);
  return container;
}

void main() {
  late TestStorage storage;

  setUp(() async {
    storage = await TestStorage.open();
  });

  tearDown(() => storage.close());

  test('login posts the credentials through the retrofit client', () async {
    final _FakeAdapter adapter = _FakeAdapter(200, <String, Object?>{
      'token': 'QpwL5tke4Pnpja7X4',
    });
    final ProviderContainer container = _container(adapter, storage);

    final LoginResponse response = await container
        .read(authenticationRepositoryProvider)
        .login('eve.holt@reqres.in', 'cityslicka');

    expect(response.token, 'QpwL5tke4Pnpja7X4');
    final RequestOptions request = adapter.requests.single;
    expect(request.method, 'POST');
    expect(request.uri.toString(), 'https://reqres.in/api/login');
    expect(request.headers['x-api-key'], 'demo-key');
    expect(request.data, isNotNull);
  });

  test('a rejected login is an ApiException, not retried', () async {
    final _FakeAdapter adapter = _FakeAdapter(400, <String, Object?>{
      'error': 'user not found',
    });
    final ProviderContainer container = _container(adapter, storage);

    await expectLater(
      container
          .read(authenticationRepositoryProvider)
          .login('nobody@reqres.in', 'x'),
      throwsA(isA<ApiServerException>()),
    );
    expect(adapter.requests, hasLength(1));
  });

  test('a response that does not fit the model is decode', () async {
    final _FakeAdapter adapter = _FakeAdapter(200, <String, Object?>{
      'token': 42,
    });
    final ProviderContainer container = _container(adapter, storage);

    Object? caught;
    try {
      await container
          .read(authenticationRepositoryProvider)
          .login('eve.holt@reqres.in', 'cityslicka');
    } on ApiException catch (error) {
      caught = error;
    }
    expect(caught, isA<ApiDecodeException>());
    expect((caught! as ApiException).request?.path, '/api/login');
  });

  test('login and register never send the session token', () async {
    await storage.session.put('accessToken', 'old-token');
    final _FakeAdapter adapter = _FakeAdapter(200, <String, Object?>{
      'id': 4,
      'token': 'QpwL5tke4Pnpja7X4',
    });
    final ProviderContainer container = _container(adapter, storage);
    expect(
      await container.read(sessionProvider.future),
      const Session(accessToken: 'old-token'),
    );

    final AuthenticationRepository repository = container.read(
      authenticationRepositoryProvider,
    );
    await repository.login('eve.holt@reqres.in', 'cityslicka');
    await repository.register('eve.holt@reqres.in', 'pistol');

    for (final RequestOptions request in adapter.requests) {
      expect(request.extra[skipAuthKey], isTrue);
      expect(request.headers['Authorization'], isNull);
    }
  });
}
