import 'dart:async';

import 'package:core/core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod_template/fakes/fake_scope.dart';
import 'package:flutter_riverpod_template/features/authentication/fakes/fake_auth_repository.dart';
import 'package:flutter_riverpod_template/features/authentication/presentation/login/login_controller.dart';
import 'package:flutter_riverpod_template/features/authentication/presentation/login/login_screen.dart';
import 'package:material_ui/material_ui.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

// The demo login screen, one use case per state, each on its own Fakes
// through `FakeScope` (a `ProviderScope` with the tests' fake repository and
// in-memory boxes). Signing in works but goes nowhere: the catalog has no
// router.

/// The empty form, as on a first launch.
@widgetbook.UseCase(
  name: 'Default',
  type: LoginScreen,
  path: '[App]/authentication',
)
Widget buildLoginScreen(BuildContext context) {
  return const FakeScope(child: LoginScreen());
}

/// Remember me was ticked at the last login: the form is pre-filled.
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

/// Login was tapped and the backend has not answered yet: the button shows
/// a spinner.
@widgetbook.UseCase(
  name: 'Signing in',
  type: LoginScreen,
  path: '[App]/authentication',
)
Widget buildLoginScreenSigningIn(BuildContext context) {
  return FakeScope(
    seed: const FakeSeed(credentials: demoCredentials),
    authRepository: FakeAuthRepository(loginGate: Completer<void>()),
    child: const _SubmittedLogin(),
  );
}

/// The backend rejects the email and password with a 401 and no message:
/// the Feature's own text in a snackbar, over the kept form.
@widgetbook.UseCase(
  name: 'Wrong credentials',
  type: LoginScreen,
  path: '[App]/authentication',
)
Widget buildLoginScreenWrongCredentials(BuildContext context) {
  return FakeScope(
    seed: const FakeSeed(credentials: demoCredentials),
    authRepository: FakeAuthRepository(
      loginError: const ApiUnauthorizedException(),
    ),
    child: const _SubmittedLogin(),
  );
}

/// The login call fails on the server: Core's message in a snackbar, over
/// the kept form.
@widgetbook.UseCase(
  name: 'Server error',
  type: LoginScreen,
  path: '[App]/authentication',
)
Widget buildLoginScreenServerError(BuildContext context) {
  return FakeScope(
    seed: const FakeSeed(credentials: demoCredentials),
    authRepository: FakeAuthRepository(
      loginError: const ApiServerException(500),
    ),
    child: const _SubmittedLogin(),
  );
}

/// An expired session signed the user out: the form shows Core's
/// session-expired message until the next sign-in.
@widgetbook.UseCase(
  name: 'Session expired',
  type: LoginScreen,
  path: '[App]/authentication',
)
Widget buildLoginScreenSessionExpired(BuildContext context) {
  return const FakeScope(sessionExpired: true, child: LoginScreen());
}

/// The login screen with Login tapped once its form has loaded, so the use
/// case opens on what follows the tap. It submits the seeded
/// [demoCredentials], which the form shows.
class _SubmittedLogin extends ConsumerStatefulWidget {
  const _SubmittedLogin();

  @override
  ConsumerState<_SubmittedLogin> createState() => _SubmittedLoginState();
}

class _SubmittedLoginState extends ConsumerState<_SubmittedLogin> {
  bool _submitted = false;

  @override
  Widget build(BuildContext context) {
    // Submitting before the form has loaded would fail with no form to
    // keep, so the screen would show its error view instead.
    final bool loaded = ref.watch(loginControllerProvider).hasValue;
    if (loaded && !_submitted) {
      _submitted = true;
      WidgetsBinding.instance.addPostFrameCallback((Duration _) {
        if (!mounted) return;
        unawaited(
          ref
              .read(loginControllerProvider.notifier)
              .login(
                email: demoCredentials.email,
                password: demoCredentials.password,
              ),
        );
      });
    }
    return const LoginScreen();
  }
}
