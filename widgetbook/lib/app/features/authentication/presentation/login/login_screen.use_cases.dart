import 'package:core/core.dart';
import 'package:flutter_riverpod_template/fakes/fake_scope.dart';
import 'package:flutter_riverpod_template/features/authentication/fakes/fake_auth_repository.dart';
import 'package:flutter_riverpod_template/features/authentication/presentation/login/login_screen.dart';
import 'package:material_ui/material_ui.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

// The demo login screen, as an example of use cases for an app's own
// screens: wrapped in `FakeScope` (a `ProviderScope` with the tests' fake
// repository and in-memory boxes). Signing in works but goes nowhere: the
// catalog has no router.

@widgetbook.UseCase(
  name: 'Signed out',
  type: LoginScreen,
  path: '[App]/authentication',
)
Widget buildLoginScreen(BuildContext context) {
  return const FakeScope(child: LoginScreen());
}

@widgetbook.UseCase(
  name: 'Remembered credentials',
  type: LoginScreen,
  path: '[App]/authentication',
)
Widget buildLoginScreenRemembered(BuildContext context) {
  return const FakeScope(
    seed: FakeSeed(credentials: demoCredentials),
    child: LoginScreen(),
  );
}

/// The backend rejects the login: tap Login to see the error snackbar.
@widgetbook.UseCase(
  name: 'Login fails',
  type: LoginScreen,
  path: '[App]/authentication',
)
Widget buildLoginScreenFailing(BuildContext context) {
  return FakeScope(
    seed: const FakeSeed(credentials: demoCredentials),
    authRepository: FakeAuthRepository(
      loginError: const ApiServerException(400, message: 'user not found'),
    ),
    child: const LoginScreen(),
  );
}
