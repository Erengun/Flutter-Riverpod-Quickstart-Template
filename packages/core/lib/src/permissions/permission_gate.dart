import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import 'permission_checks.dart';
import 'permissions.dart';

/// Turns colors into their grey of the same luminance.
const ColorFilter _greyscale = ColorFilter.matrix(<double>[
  0.2126, 0.7152, 0.0722, 0, 0, //
  0.2126, 0.7152, 0.0722, 0, 0, //
  0.2126, 0.7152, 0.0722, 0, 0, //
  0, 0, 0, 1, 0, //
]);

/// Shows [child] as the Component rule for [componentKey] says:
///
/// - no rule: as it is;
/// - [ComponentState.hidden]: removed;
/// - [ComponentState.readonly]: shown as it is, but taps and focus never
///   reach it;
/// - [ComponentState.disabled]: greyed out (grey at the theme's
///   `disabledColor` opacity), and taps and focus never reach it.
///
/// While the permissions are not known yet, the child is hidden
/// (fail-closed), and it appears once they load.
class PermissionGate extends ConsumerWidget {
  const PermissionGate({
    required this.componentKey,
    required this.child,
    super.key,
  });

  /// The control's component key, a typed constant of the app.
  final String componentKey;

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ComponentState? state = ref.watch(
      componentStateProvider(componentKey),
    );
    return switch (state) {
      null => child,
      ComponentState.hidden => const SizedBox.shrink(),
      ComponentState.readonly => AbsorbPointer(
        child: ExcludeFocus(child: child),
      ),
      ComponentState.disabled => AbsorbPointer(
        child: ExcludeFocus(
          child: Opacity(
            opacity: Theme.of(context).disabledColor.a,
            child: ColorFiltered(colorFilter: _greyscale, child: child),
          ),
        ),
      ),
    };
  }
}
