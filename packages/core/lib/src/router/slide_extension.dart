// ignore_for_file: strict_raw_type, always_specify_types

import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import 'transition_route.dart';

class SlideTransitionPage extends CustomTransitionPage {
  SlideTransitionPage({
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
              return SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(1, 0),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              );
            },
      );
}

/// Extension for GoRouter to add slide transition
extension SlideGoRouteExtension on GoRoute {
  /// Returns this route with a slide transition; every other field is kept.
  ///
  /// The route must have a `builder` (throws [ArgumentError] otherwise).
  GoRoute slide() {
    return withTransitionPage(
      this,
      (GoRouterState state, Widget child) => SlideTransitionPage(
        key: state.pageKey,
        name: state.name,
        child: child,
      ),
      transition: 'slide',
    );
  }
}
