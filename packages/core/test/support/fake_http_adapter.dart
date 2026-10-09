import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

/// Answers one request. Throw a `DioException` to fail it.
typedef FakeReply = FutureOr<ResponseBody> Function(RequestOptions options);

/// A Dio adapter that answers from a script instead of the network.
///
/// Each request takes the next reply; the last one repeats once the script
/// runs out. Every request is recorded in [requests].
class FakeHttpAdapter implements HttpClientAdapter {
  FakeHttpAdapter(this._replies) : assert(_replies.isNotEmpty, 'No replies');

  final List<FakeReply> _replies;
  final List<RequestOptions> requests = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final int index = requests.length < _replies.length
        ? requests.length
        : _replies.length - 1;
    requests.add(options);
    return _replies[index](options);
  }

  @override
  void close({bool force = false}) {}
}

/// A JSON reply with [status] and [body].
FakeReply jsonReply(
  int status,
  Object? body, {
  Map<String, List<String>> headers = const <String, List<String>>{},
}) {
  return (RequestOptions options) => ResponseBody.fromString(
    jsonEncode(body),
    status,
    headers: <String, List<String>>{
      Headers.contentTypeHeader: <String>[Headers.jsonContentType],
      ...headers,
    },
  );
}

/// A reply whose body claims to be JSON but isn't.
FakeReply malformedJsonReply() {
  return (RequestOptions options) => ResponseBody.fromString(
    '{not json',
    200,
    headers: <String, List<String>>{
      Headers.contentTypeHeader: <String>[Headers.jsonContentType],
    },
  );
}

/// A reply that fails before reaching the server.
FakeReply connectionErrorReply() {
  return (RequestOptions options) => throw DioException.connectionError(
    requestOptions: options,
    reason: 'fake connection error',
  );
}

/// A reply that times out while receiving.
FakeReply receiveTimeoutReply() {
  return (RequestOptions options) => throw DioException.receiveTimeout(
    timeout: const Duration(seconds: 30),
    requestOptions: options,
  );
}

/// A reply that fails to connect in time.
FakeReply connectTimeoutReply() {
  return (RequestOptions options) => throw DioException.connectionTimeout(
    timeout: const Duration(seconds: 10),
    requestOptions: options,
  );
}
