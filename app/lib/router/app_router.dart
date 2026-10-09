// ignore_for_file: prefer_function_declarations_over_variables

import 'package:core/core.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../features/authentication/presentation/login/login_screen.dart';
import '../features/home/presentation/home_screen.dart';

part 'app_router.g.dart';

enum SGRoute {
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
GoRouter goRouter(Ref ref) => GoRouter(
  initialLocation: SGRoute.login.route,
  observers: <NavigatorObserver>[NavigationBreadcrumbObserver()],
  // Every route needs a `name`: breadcrumbs record route names only.
  routes: <GoRoute>[
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
