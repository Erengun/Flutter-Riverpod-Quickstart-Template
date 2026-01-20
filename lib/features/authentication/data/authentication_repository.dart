import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../constants/endpoints.dart';
import '../../../data/repository/network_repository.dart';
import '../domain/login_request.dart';
import '../domain/login_response.dart';
import '../domain/register_response.dart';

part 'authentication_repository.g.dart';

/// An abstract class that defines the authentication methods.
abstract class AuthenticationRepository {
  /// Authenticates a user with the given [email] and [password].
  /// Returns a [LoginResponse] containing the authentication details.
  Future<LoginResponse> login(String email, String password);

  /// Registers a new user with the given [email] and [password].
  /// Returns a [RegisterResponse] containing the registration details.
  Future<RegisterResponse> register(String email, String password);
}

/// A class that implements the [AuthenticationRepository] using HTTP requests.
class HttpAuthRepository implements AuthenticationRepository {
  /// Creates an instance of [HttpAuthRepository].
  HttpAuthRepository(this.ref);
  final Ref ref;

  /// The Dio instance used for making HTTP requests.
  Dio get dio => ref.read(networkRepositoryProvider);

  @override
  Future<LoginResponse> login(String email, String password) async {
    try {
      final Response<dynamic> response = await dio.post(
        Endpoints.login,
        data: LoginCredentials(email: email, password: password),
      );
      if (response.statusCode != 200) {
        throw Exception('Failed to login');
      }
      final LoginResponse loginResponse = LoginResponse.fromJson(
        response.data as Map<String, dynamic>,
      );
      ref
          .read(networkRepositoryProvider.notifier)
          .setToken(loginResponse.token);
      return loginResponse;
    } catch (e) {
      if (e is DioException) {
        if (e.response?.statusCode == 401) {
          throw Exception('Invalid credentials');
        }
        if (e.response?.statusCode == 400) {
          throw Exception('User not found');
        } else {
          throw Exception('Login failed');
        }
      }

      /// Handle other exceptions as needed. Or you can create a custom exception class.
      /// For example, you can create a class called `AuthenticationException` and throw it here.
      /// throw AuthenticationException.invalidCredentials();
      /// Or you can just log the error and rethrow it.
      rethrow;
    }
  }

  @override
  Future<RegisterResponse> register(String email, String password) async {
    try {
      final Response<dynamic> response = await dio.post(
        Endpoints.register,
        data: LoginCredentials(email: email, password: password),
      );
      if (response.statusCode != 200) {
        throw Exception('Failed to register');
      }
      return RegisterResponse.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      if (e is DioException) {
        if (e.response?.statusCode == 409) {
          throw Exception('User already exists');
        }
      }

      /// Handle other exceptions as needed. Or you can create a custom exception class.
      /// For example, you can create a class called `AuthenticationException` and throw it here.
      /// throw AuthenticationException.userAlreadyExists();
      /// Or you can just log the error and rethrow it.
      rethrow;
    }
  }
}

@riverpod
AuthenticationRepository authenticationRepository(Ref ref) {
  return HttpAuthRepository(ref);
}
