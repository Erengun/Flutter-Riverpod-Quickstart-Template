// ignore_for_file: prefer_function_declarations_over_variables

import 'package:core/core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../features/authentication/presentation/login/login_screen.dart';
import '../features/home/presentation/home_screen.dart';

part 'app_router.g.dart';

enum SGRoute {
  splash,
  home,
  login,
  register,
  forgotPassword,
  profile,
  editProfile,
  changePassword;

  String get route => '/${toString().replaceAll('SGRoute.', '')}';
  String get name => toString().replaceAll('SGRoute.', '');
}

@riverpod
GoRouter goRouter(Ref ref) {
  // Re-runs the redirect whenever the session loads, starts or ends.
  final ValueListenable<AsyncValue<Session?>> session = ref.watch(
    sessionListenableProvider,
  );
  final GoRouter router = GoRouter(
    initialLocation: SGRoute.splash.route,
    observers: <NavigatorObserver>[NavigationBreadcrumbObserver()],
    refreshListenable: session,
    // Splash while the session loads, then home when signed in, else login.
    // A redirect replaces the whole stack, so back never undoes a logout.
    redirect: (BuildContext context, GoRouterState state) => sessionRedirect(
      session.value,
      state.uri.path,
      splashPath: SGRoute.splash.route,
      loginPath: SGRoute.login.route,
      homePath: SGRoute.home.route,
      // An expired session returns to /login?from=<location>.
      uri: state.uri,
      expired: ref.read(sessionExpiredProvider),
    ),
    // Every route needs a `name`: breadcrumbs record route names only.
    routes: <GoRoute>[
      GoRoute(
        path: SGRoute.splash.route,
        name: SGRoute.splash.name,
        builder: (BuildContext context, GoRouterState state) =>
            const _SplashPage(),
      ),
      GoRoute(
        path: SGRoute.login.route,
        name: SGRoute.login.name,
        builder: (BuildContext context, GoRouterState state) {
          return const LoginScreen();
        },
      ).fade(),
      GoRoute(
        path: SGRoute.home.route,
        name: SGRoute.home.name,
        builder: (BuildContext context, GoRouterState state) =>
            const HomeScreen(),
      ).fade(),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
}

/// The splash passed to `bootstrap` (Core's progress indicator by default).
class _SplashPage extends ConsumerWidget {
  const _SplashPage();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(body: ref.watch(splashProvider));
  }
}
