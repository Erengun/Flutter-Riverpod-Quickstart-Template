// ignore_for_file: prefer_function_declarations_over_variables

import 'package:core/core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../features/authentication/presentation/login/login_screen.dart';
import '../features/demo/presentation/demo_area_screen.dart';
import '../features/home/presentation/home_screen.dart';
import '../l10n/app_localizations.dart';
import '../shared/permission_keys.dart';

part 'app_router.g.dart';

/// The app's routes. A route guarded by a Permission area declares it with
/// `area:`; without one any signed-in user may open it.
enum SGRoute {
  splash,
  home,
  login,
  register,
  forgotPassword,
  profile(area: AppAreas.profile),
  editProfile,
  changePassword,
  settings(area: AppAreas.settings),
  reports(area: AppAreas.reports),
  noPermission;

  const SGRoute({this.area});

  /// The Permission area this route needs, checked by Core's
  /// `permissionRedirect`.
  final String? area;

  /// The route named [name], if any.
  static SGRoute? byName(String? name) {
    for (final SGRoute route in values) {
      if (route.name == name) return route;
    }
    return null;
  }

  String get route => '/${toString().replaceAll('SGRoute.', '')}';
  String get name => toString().replaceAll('SGRoute.', '');
}

@riverpod
GoRouter goRouter(Ref ref) {
  // Re-runs the redirect whenever the session loads, starts or ends.
  final ValueListenable<AsyncValue<Session?>> session = ref.watch(
    sessionListenableProvider,
  );
  // Re-runs the permission guard whenever the permissions load or change.
  final ValueListenable<Permissions?> permissions = ref.watch(
    permissionsListenableProvider,
  );
  final GoRouter router = GoRouter(
    initialLocation: SGRoute.splash.route,
    observers: <NavigatorObserver>[NavigationBreadcrumbObserver()],
    refreshListenable: Listenable.merge(<Listenable>[session, permissions]),
    // Splash while the session loads, then home when signed in, else login.
    // A redirect replaces the whole stack, so back never undoes a logout.
    // Then the permission guard: a route outside the user's areas opens
    // Core's no-permission page, links and direct `go()` calls included.
    redirect: (BuildContext context, GoRouterState state) =>
        sessionRedirect(
          session.value,
          state.uri.path,
          splashPath: SGRoute.splash.route,
          loginPath: SGRoute.login.route,
          homePath: SGRoute.home.route,
        ) ??
        permissionRedirect(
          permissions.value,
          state.uri.path,
          area: SGRoute.byName(state.topRoute?.name)?.area,
          splashPath: SGRoute.splash.route,
          noPermissionPath: SGRoute.noPermission.route,
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
      GoRoute(
        path: SGRoute.profile.route,
        name: SGRoute.profile.name,
        builder: (BuildContext context, GoRouterState state) => DemoAreaScreen(
          title: AppLocalizations.of(context).demoProfileTitle,
          area: AppAreas.profile,
        ),
      ).slide(),
      GoRoute(
        path: SGRoute.settings.route,
        name: SGRoute.settings.name,
        builder: (BuildContext context, GoRouterState state) => DemoAreaScreen(
          title: AppLocalizations.of(context).demoSettingsTitle,
          area: AppAreas.settings,
        ),
      ).slide(),
      GoRoute(
        path: SGRoute.reports.route,
        name: SGRoute.reports.name,
        builder: (BuildContext context, GoRouterState state) => DemoAreaScreen(
          title: AppLocalizations.of(context).demoReportsTitle,
          area: AppAreas.reports,
        ),
      ).slide(),
      GoRoute(
        path: SGRoute.noPermission.route,
        name: SGRoute.noPermission.name,
        builder: (BuildContext context, GoRouterState state) =>
            NoPermissionPage(onBackHome: () => context.go(SGRoute.home.route)),
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
