import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'session.dart';

/// The `options.extra` flag that keeps the auth interceptor away from a
/// request: login, register and refresh set it through retrofit's
/// `@Extra(<String, Object>{skipAuthKey: true})`.
const String skipAuthKey = 'skipAuth';

/// Adds `Authorization: Bearer <token>` to every request while signed in.
///
/// The token is read per request, so the shared Dio never changes. Skips
/// requests marked with [skipAuthKey] and never replaces an
/// `Authorization` header the request already has.
class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._accessToken);

  final String? Function() _accessToken;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final bool hasHeader = options.headers.keys.any(
      (String name) => name.toLowerCase() == 'authorization',
    );
    if (options.extra[skipAuthKey] != true && !hasHeader) {
      final String? token = _accessToken();
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }
    handler.next(options);
  }
}

/// Core's [AuthInterceptor], reading the token from [sessionProvider]. It is
/// in `dioInterceptorsProvider`'s default list.
final Provider<AuthInterceptor> authInterceptorProvider =
    Provider<AuthInterceptor>(
      (Ref ref) =>
          AuthInterceptor(() => ref.read(sessionProvider).value?.accessToken),
      name: 'authInterceptorProvider',
    );
