// ignore_for_file: strict_raw_type, always_specify_types

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class FadeTransitionPage extends CustomTransitionPage {
  FadeTransitionPage({required LocalKey super.key, required super.child})
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
extension GoRouteExtension on GoRoute {
  /// Add fade transition to the route page
  GoRoute fade() {
    return GoRoute(
      path: path,
      pageBuilder: (BuildContext context, GoRouterState state) {
        return FadeTransitionPage(
          key: ValueKey<String>(path),
          child: builder!(context, state),
        );
      },
    );
  }
}
