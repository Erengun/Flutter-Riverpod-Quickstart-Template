import 'dart:async';

import 'package:core/core.dart';

import '../data/authentication_repository.dart';
import '../domain/login_request.dart';
import '../domain/login_response.dart';
import '../domain/register_response.dart';

/// An [AuthenticationRepository] that never calls the backend, for tests and
/// the catalog.
class FakeAuthRepository implements AuthenticationRepository {
  FakeAuthRepository({this.loginError, this.loginGate});

  /// The token [login] and [register] return.
  static const String token = 'token-from-fake-auth-repository';

  /// Thrown by [login] instead of signing in, when set.
  final ApiException? loginError;

  /// While set, [login] waits for it before answering, like a call still on
  /// the network. One that never completes keeps the login loading.
  final Completer<void>? loginGate;

  /// How many times [login] was called.
  int logins = 0;

  @override
  Future<LoginResponse> login(String email, String password) async {
    logins++;
    await loginGate?.future;
    final ApiException? error = loginError;
    if (error != null) throw error;
    return const LoginResponse(token: token);
  }

  @override
  Future<RegisterResponse> register(String email, String password) async =>
      const RegisterResponse(id: 4, token: token);
}

/// The demo login, for remembered-credentials cases.
const LoginCredentials demoCredentials = LoginCredentials(
  email: 'eve.holt@reqres.in',
  password: 'cityslicka',
);
