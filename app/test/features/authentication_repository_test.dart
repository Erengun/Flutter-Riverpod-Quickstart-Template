import 'dart:convert';
import 'dart:typed_data';

import 'package:core/core.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod_template/features/authentication/data/authentication_repository.dart';
import 'package:flutter_riverpod_template/features/authentication/domain/login_response.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/misc.dart';
import 'package:riverpod/riverpod.dart';

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

ProviderContainer _container(_FakeAdapter adapter) {
  final ProviderContainer container = ProviderContainer(
    overrides: <Override>[appConfigProvider.overrideWithValue(_config)],
  );
  container.read(dioProvider).httpClientAdapter = adapter;
  addTearDown(container.dispose);
  return container;
}

void main() {
  test('login posts the credentials through the retrofit client', () async {
    final _FakeAdapter adapter = _FakeAdapter(200, <String, Object?>{
      'token': 'QpwL5tke4Pnpja7X4',
    });
    final ProviderContainer container = _container(adapter);

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
    final ProviderContainer container = _container(adapter);

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
    final ProviderContainer container = _container(adapter);

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
}
