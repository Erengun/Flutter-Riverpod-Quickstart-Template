// ignore_for_file: strict_raw_type, always_specify_types

import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import 'transition_route.dart';

class FadeTransitionPage extends CustomTransitionPage {
  FadeTransitionPage({
    required LocalKey super.key,
    required super.child,
    super.name,
  })
    : super(
        transitionsBuilder:
            (
              BuildContext context,
              Animation<double> animation,
              Animation<double> secondaryAnimation,
              Widget child,
            ) {
              return FadeTransition(opacity: animation, child: child);
            },
      );
}

/// Extension for GoRouter to add fade transition
extension FadeGoRouteExtension on GoRoute {
  /// Returns this route with a fade transition; every other field is kept.
  ///
  /// The route must have a `builder` (throws [ArgumentError] otherwise).
  GoRoute fade() {
    return withTransitionPage(
      this,
      (GoRouterState state, Widget child) => FadeTransitionPage(
        key: state.pageKey,
        name: state.name,
        child: child,
      ),
      transition: 'fade',
    );
  }
}
