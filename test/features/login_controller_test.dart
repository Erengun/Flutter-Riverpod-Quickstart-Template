import 'dart:async';

import 'package:flutter_riverpod_template/features/authentication/data/authentication_repository.dart';
import 'package:flutter_riverpod_template/features/authentication/data/hive/user_repository.dart';
import 'package:flutter_riverpod_template/features/authentication/domain/login_request.dart';
import 'package:flutter_riverpod_template/features/authentication/domain/login_response.dart';
import 'package:flutter_riverpod_template/features/authentication/domain/register_response.dart';
import 'package:flutter_riverpod_template/features/authentication/presentation/login/auth_ui_model.dart';
import 'package:flutter_riverpod_template/features/authentication/presentation/login/login_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/src/framework.dart';

class FakeAuthRepository implements AuthenticationRepository {
  @override
  Future<LoginResponse> login(String email, String password) async {
    if (email.isEmpty || password.isEmpty) throw Exception('Empty');
    return const LoginResponse(token: 'fake_token');
  }

  @override
  Future<RegisterResponse> register(String email, String password) async {
    if (email.isEmpty || password.isEmpty) throw Exception('Empty');
    return const RegisterResponse(id: 1, token: 'fake_token');
  }
}

class FakeUserRepository extends UserRepository {
  @override
  FutureOr<LoginCredentials?> build() => null;

  @override
  Future<void> cacheUser(LoginCredentials user) async {}

  @override
  Future<LoginCredentials?> getCachedUser() async => null;
}

void main() {
  late ProviderContainer container;
  late LoginController controller;

  setUp(() {
    container = ProviderContainer(
      overrides: <Override>[
        authenticationRepositoryProvider.overrideWithValue(FakeAuthRepository()),
        userRepositoryProvider.overrideWith(FakeUserRepository.new),
      ],
    )
    // Listen to the provider to keep it alive during the test
    ..listen<AsyncValue<AuthUiModel>>(
      loginControllerProvider,
      (AsyncValue<AuthUiModel>? previous, AsyncValue<AuthUiModel> next) {},
    );
    controller = container.read(loginControllerProvider.notifier);
  });

  tearDown(() {
    container.dispose();
  });

  test('initial state is correct', () async {
    await container.read(loginControllerProvider.future);
    final AuthUiModel state = controller.state.requireValue;
    expect(state.user, isNull);
    expect(state.rememberMe, isFalse);
    expect(state.showPassword, isFalse);
    expect(state.isLoading, isFalse);
  });

  group('login', () {
    test('successful login updates state correctly', () async {
      await container.read(loginControllerProvider.future);
      controller.updateRememberMe(rememberMe: false);

      await controller.login(
        email: 'eve.holt@reqres.in',
        password: 'cityslicka',
      );

      expect(controller.state.requireValue.isLoading, isFalse);
    });

    test('throws exception when credentials are empty', () async {
      await container.read(loginControllerProvider.future);
      expect(() => controller.login(email: '', password: ''), throwsException);
    });
  });

  group('register', () {
    test('successful registration updates state correctly', () async {
      await container.read(loginControllerProvider.future);

      await controller.register(
        email: 'eve.holt@reqres.in',
        password: 'pistol',
      );

      expect(controller.state.requireValue.rememberMe, isTrue);
    });

    test('throws exception when credentials are empty', () async {
      await container.read(loginControllerProvider.future);

      expect(
        () => controller.register(email: '', password: ''),
        throwsException,
      );
    });
  });
}
