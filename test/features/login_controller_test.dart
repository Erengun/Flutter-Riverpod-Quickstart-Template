import 'package:flutter_riverpod_template/features/authentication/presentation/login/login_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/riverpod.dart';

void main() {
  late ProviderContainer container;
  late LoginController controller;

  setUp(() {
    container = ProviderContainer();
    controller = container.read(loginControllerProvider.notifier);
  });

  tearDown(() {
    container.dispose();
  });

  test('initial state is correct', () {
    expect(controller.state.user, isNull);
    expect(controller.state.rememberMe, isFalse);
    expect(controller.state.showPassword, isFalse);
    expect(controller.state.isLoading, isFalse);
  });

  group('login', () {
    test('successful login updates state correctly', () async {
      controller.updateRememberMe(false);

      await controller.login(
        email: 'eve.holt@reqres.in',
        password: 'cityslicka',
      );

      expect(controller.state.isLoading, isFalse);
    });

    test('throws exception when credentials are empty', () async {
      final LoginController controller = container.read(
        loginControllerProvider.notifier,
      );
      expect(() => controller.login(email: '', password: ''), throwsException);
    });
  });

  group('register', () {
    test('successful registration updates state correctly', () async {
      final LoginController controller = container.read(
        loginControllerProvider.notifier,
      );

      await controller.register(
        email: 'eve.holt@reqres.in',
        password: 'pistol',
      );

      expect(controller.state.rememberMe, isTrue);
    });

    test('throws exception when credentials are empty', () async {
      final LoginController controller = container.read(
        loginControllerProvider.notifier,
      );

      expect(
        () => controller.register(email: '', password: ''),
        throwsException,
      );
    });
  });
}
