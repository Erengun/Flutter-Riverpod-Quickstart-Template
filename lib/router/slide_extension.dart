// ignore_for_file: strict_raw_type, always_specify_types

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SlideTransitionPage extends CustomTransitionPage {
  SlideTransitionPage({required LocalKey super.key, required super.child})
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
extension GoRouteExtension on GoRoute {
  /// Add slide transition to the route page
  GoRoute slide() {
    return GoRoute(
      path: path,
      pageBuilder: (BuildContext context, GoRouterState state) {
        return SlideTransitionPage(
          key: ValueKey<String>(path),
          child: builder!(context, state),
        );
      },
    );
  }
}
