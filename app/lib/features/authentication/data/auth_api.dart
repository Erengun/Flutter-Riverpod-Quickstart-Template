import 'package:core/core.dart';
import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../domain/login_request.dart';
import '../domain/login_response.dart';
import '../domain/register_response.dart';

part 'auth_api.g.dart';

/// The reqres demo backend's auth endpoints, relative to
/// `AppConfig.apiBaseUrl`.
///
/// reqres doesn't wrap responses in `BaseResponse`, so the methods return
/// the model directly and the repository uses plain `apiCall`.
@RestApi()
abstract class AuthApi {
  factory AuthApi(Dio dio, {String? baseUrl, ParseErrorLogger? errorLogger}) =
      _AuthApi;

  @POST('api/login')
  Future<LoginResponse> login(@Body() LoginCredentials credentials);

  @POST('api/register')
  Future<RegisterResponse> register(@Body() LoginCredentials credentials);
}

@Riverpod(keepAlive: true)
AuthApi authApi(Ref ref) {
  return AuthApi(ref.watch(dioProvider), errorLogger: apiParseErrorLogger);
}
