import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

/// Builds the transition page that shows a route's [child].
typedef TransitionPageBuilder = Page<Object?> Function(
  GoRouterState state,
  Widget child,
);

/// Returns a copy of [route] whose page comes from [buildPage].
///
/// Every other [GoRoute] field (name, sub-routes, redirect, navigator key,
/// metadata, onExit, case sensitivity) is kept. [buildPage] should key the
/// page with `state.pageKey`, so each location and each push gets its own
/// page. [route] must have a `builder`: a `pageBuilder` already picks its own
/// page, and a redirect-only route has nothing to show. [transition] names the
/// calling extension in the error.
GoRoute withTransitionPage(
  GoRoute route,
  TransitionPageBuilder buildPage, {
  required String transition,
}) {
  final GoRouterWidgetBuilder? builder = route.builder;
  if (builder == null) {
    throw ArgumentError.value(
      route.path,
      'route',
      '.$transition() needs a GoRoute with a builder',
    );
  }
  return GoRoute(
    path: route.path,
    name: route.name,
    pageBuilder: (BuildContext context, GoRouterState state) =>
        buildPage(state, builder(context, state)),
    parentNavigatorKey: route.parentNavigatorKey,
    redirect: route.redirect,
    metadata: route.metadata,
    onExit: route.onExit,
    caseSensitive: route.caseSensitive,
    routes: route.routes,
  );
}
