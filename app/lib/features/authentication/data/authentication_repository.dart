import 'package:core/core.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../domain/login_request.dart';
import '../domain/login_response.dart';
import '../domain/register_response.dart';
import 'auth_api.dart';

part 'authentication_repository.g.dart';

/// The authentication calls the app makes. Tests override
/// [authenticationRepositoryProvider] with a fake.
abstract class AuthenticationRepository {
  /// Authenticates a user with the given [email] and [password].
  /// Throws an [ApiException] when the call fails.
  Future<LoginResponse> login(String email, String password);

  /// Registers a new user with the given [email] and [password].
  /// Throws an [ApiException] when the call fails.
  Future<RegisterResponse> register(String email, String password);
}

/// [AuthenticationRepository] over the retrofit [AuthApi]. Each call goes
/// through Core's [ApiCall], which maps and reports failures.
class HttpAuthRepository implements AuthenticationRepository {
  HttpAuthRepository(this._api, this._apiCall);

  final AuthApi _api;
  final ApiCall _apiCall;

  @override
  Future<LoginResponse> login(String email, String password) {
    return _apiCall(
      () => _api.login(LoginCredentials(email: email, password: password)),
    );
  }

  @override
  Future<RegisterResponse> register(String email, String password) {
    return _apiCall(
      () => _api.register(LoginCredentials(email: email, password: password)),
    );
  }
}

@Riverpod(keepAlive: true)
AuthenticationRepository authenticationRepository(Ref ref) {
  return HttpAuthRepository(
    ref.watch(authApiProvider),
    ref.watch(apiCallProvider),
  );
}
