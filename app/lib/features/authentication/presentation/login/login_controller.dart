import 'package:core/core.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/authentication_repository.dart';
import '../../data/hive/user_repository.dart';
import '../../domain/login_request.dart';
import '../../domain/login_response.dart';
import '../../domain/register_response.dart';
import 'auth_ui_model.dart';

part 'login_controller.g.dart';

@riverpod
class LoginController extends _$LoginController {
  @override
  FutureOr<AuthUiModel> build() async {
    final LoginCredentials? user = await ref.read(
      userRepositoryProvider.future,
    );

    return AuthUiModel(user: user);
  }

  void updateRememberMe({required bool rememberMe}) {
    if (rememberMe) {
      ref.keepAlive();
    }
    state = AsyncData<AuthUiModel>(
      state.value!.copyWith(rememberMe: rememberMe),
    );
  }

  void updateShowPassword({required bool showPassword}) {
    state = AsyncData<AuthUiModel>(
      state.value!.copyWith(showPassword: showPassword),
    );
  }

  /// Signs in. Returns `null` when the call failed: the state is then an
  /// `AsyncError` holding the `ApiException` (the form values are kept), and
  /// the screen shows it through `ref.listenApiErrors`.
  Future<LoginResponse?> login({
    required String email,
    required String password,
  }) async {
    final LoginCredentials user = LoginCredentials(
      email: email,
      password: password,
    );
    if (user.email.isEmpty || user.password.isEmpty) {
      throw Exception('Email and password cannot be empty');
    }
    state = const AsyncLoading<AuthUiModel>();
    final LoginResponse loginResponse;
    try {
      loginResponse = await ref
          .read(authenticationRepositoryProvider)
          .login(user.email, user.password);
    } catch (error, stackTrace) {
      if (ref.mounted) state = AsyncError<AuthUiModel>(error, stackTrace);
      return null;
    }
    if (!ref.mounted) return loginResponse;
    state = AsyncData<AuthUiModel>(state.value!);
    if (loginResponse.token.isNotEmpty) {
      if (state.value!.rememberMe) {
        state = AsyncData<AuthUiModel>(
          state.value!.copyWith(
            user: state.value!.user?.copyWith(
              email: user.email,
              password: user.password,
            ),
          ),
        );
        try {
          await ref.read(userRepositoryProvider.notifier).cacheUser(user);
        } catch (error, stackTrace) {
          // Handled without failing a provider, so report it explicitly.
          ref.read(errorReporterProvider).report(error, stackTrace);
        }
      }
    }
    return loginResponse;
  }

  Future<RegisterResponse> register({
    required String email,
    required String password,
  }) async {
    if (email.isEmpty || password.isEmpty) {
      throw Exception('Email and password cannot be empty');
    }
    final RegisterResponse registerResponse = await ref
        .read(authenticationRepositoryProvider)
        .register(email, password);
    if (registerResponse.token.isNotEmpty) {
      // Handle successful registration
      state = AsyncData<AuthUiModel>(
        state.value!.copyWith(
          user: state.value!.user?.copyWith(email: email, password: password),
          rememberMe: true,
        ),
      );
      if (state.value!.user != null) {
        await ref
            .read(userRepositoryProvider.notifier)
            .cacheUser(state.value!.user!)
            .catchError((dynamic error) {
              throw Exception('Failed to cache user: $error');
            });
      }
    } else {
      throw Exception('Registration failed');
    }
    return registerResponse;
  }
}
