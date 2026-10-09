import 'package:core/core.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/authentication_repository.dart';
import '../../data/credentials_store.dart';
import '../../domain/login_request.dart';
import '../../domain/login_response.dart';
import '../../domain/register_response.dart';
import 'auth_ui_model.dart';

part 'login_controller.g.dart';

@riverpod
class LoginController extends _$LoginController {
  @override
  FutureOr<AuthUiModel> build() async {
    final CredentialsStore store = await ref.watch(
      credentialsStoreProvider.future,
    );
    // Remember me only pre-fills the form; it never signs in by itself.
    final LoginCredentials? saved = store.read();
    return AuthUiModel(user: saved, rememberMe: saved != null);
  }

  /// Ticks or unticks remember me. Unticking deletes the saved credentials
  /// at once.
  Future<void> updateRememberMe({required bool rememberMe}) async {
    state = AsyncData<AuthUiModel>(
      state.value!.copyWith(rememberMe: rememberMe),
    );
    if (rememberMe) return;
    final ErrorReporter reporter = ref.read(errorReporterProvider);
    try {
      await (await ref.read(credentialsStoreProvider.future)).clear();
    } catch (error, stackTrace) {
      // Handled without failing a provider, so report it explicitly.
      reporter.report(error, stackTrace);
    }
  }

  void updateShowPassword({required bool showPassword}) {
    state = AsyncData<AuthUiModel>(
      state.value!.copyWith(showPassword: showPassword),
    );
  }

  /// Signs in and starts the [Session]; the router then leaves the login
  /// page. With remember me ticked the credentials are saved to pre-fill
  /// the form next time, otherwise any saved ones are deleted.
  ///
  /// Returns `null` when the call failed: the state is then an `AsyncError`
  /// holding the `ApiException` (the form values are kept), and the screen
  /// shows it through `ref.listenApiErrors`.
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
    // Signing in leaves the login page and disposes this controller, so
    // everything needed afterwards is read now. A failing store is
    // reported below, when it is awaited.
    final bool rememberMe = state.value?.rememberMe ?? false;
    final SessionNotifier session = ref.read(sessionProvider.notifier);
    final ErrorReporter reporter = ref.read(errorReporterProvider);
    final Future<CredentialsStore> store = ref.read(
      credentialsStoreProvider.future,
    )..ignore();

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
    if (loginResponse.token.isEmpty) {
      if (ref.mounted) state = AsyncData<AuthUiModel>(state.value!);
      return loginResponse;
    }

    try {
      final CredentialsStore credentials = await store;
      if (rememberMe) {
        await credentials.save(user);
      } else {
        await credentials.clear();
      }
    } catch (error, stackTrace) {
      // Handled without failing a provider, so report it explicitly.
      reporter.report(error, stackTrace);
    }

    try {
      // reqres returns no user id; pass `userId:` when the backend does.
      await session.signIn(Session(accessToken: loginResponse.token));
    } catch (error, stackTrace) {
      if (ref.mounted) state = AsyncError<AuthUiModel>(error, stackTrace);
      return null;
    }
    if (ref.mounted) {
      state = AsyncData<AuthUiModel>(state.value!.copyWith(user: user));
    }
    return loginResponse;
  }

  /// Registers, then pre-fills the login form with the new account. Nothing
  /// is saved and nobody is signed in.
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
    if (registerResponse.token.isEmpty) {
      throw Exception('Registration failed');
    }
    if (ref.mounted) {
      state = AsyncData<AuthUiModel>(
        state.value!.copyWith(
          user: LoginCredentials(email: email, password: password),
        ),
      );
    }
    return registerResponse;
  }
}
