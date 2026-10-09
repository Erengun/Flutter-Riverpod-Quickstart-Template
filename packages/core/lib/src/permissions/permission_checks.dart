import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:logging/logging.dart';

import 'permissions.dart';
import 'permissions_service.dart';

/// Whether the Permission area is granted, for checks in code:
/// `ref.watch(canProvider(AppAreas.reports))`.
///
/// Fail-closed: `false` while the permissions are not known yet. Debug
/// builds note the key for [permissionKeyLogProvider].
final ProviderFamily<bool, String> canProvider = Provider.autoDispose
    .family<bool, String>((Ref ref, String area) {
      ref.read(permissionKeyLogProvider).checked(area);
      return ref.watch(permissionsProvider)?.can(area) ?? false;
    }, name: 'canProvider');

/// The Component rule for one control, for checks in code:
/// `ref.watch(componentStateProvider(AppComponents.profileEdit))`. `null`
/// means no rule (unrestricted). `PermissionGate` reads it.
///
/// Fail-closed: [ComponentState.hidden] while the permissions are not known
/// yet. Debug builds note the key for [permissionKeyLogProvider].
final ProviderFamily<ComponentState?, String> componentStateProvider = Provider
    .autoDispose
    .family<ComponentState?, String>((Ref ref, String componentKey) {
      ref.read(permissionKeyLogProvider).checked(componentKey);
      final Permissions? permissions = ref.watch(permissionsProvider);
      if (permissions == null) return ComponentState.hidden;
      return permissions.stateOf(componentKey);
    }, name: 'componentStateProvider');

/// Debug builds' check of the area and component keys the app checks.
/// [canProvider], [componentStateProvider] (so `PermissionGate`) and menus
/// filtered through [canProvider] note every key they check.
final Provider<PermissionKeyLog> permissionKeyLogProvider =
    Provider<PermissionKeyLog>((Ref ref) {
      final PermissionKeyLog log = PermissionKeyLog();
      if (log.enabled) {
        ref.listen<Permissions?>(
          permissionsProvider,
          (Permissions? previous, Permissions? next) => log.loaded(next),
          fireImmediately: true,
        );
      }
      return log;
    }, name: 'permissionKeyLogProvider');

/// Logs, once per key, every checked key that no loaded permission tree
/// contained. Without a key list from the backend team, this is how a typo
/// surfaces: a component key the backend never sends always allows, so its
/// check would otherwise look like it works.
///
/// - A tree counts once it is loaded: not `null`, not
///   [Permissions.unrestricted] (no hook, so no tree) and not empty (signed
///   out, or nothing could load).
/// - A key counts as seen when it is one of the tree's areas or has a
///   Component rule in it. The flat model keeps no other keys, so a control
///   the backend sends without a rule is logged too.
/// - Keys checked before a tree loads are judged when it does; later checks
///   at once.
/// - Off outside debug builds.
class PermissionKeyLog {
  PermissionKeyLog({this.enabled = kDebugMode});

  static final Logger _log = Logger('permissions');

  /// Whether keys are noted and logged at all.
  final bool enabled;

  final Set<String> _checked = <String>{};
  final Set<String> _seen = <String>{};
  final Set<String> _logged = <String>{};
  bool _treeLoaded = false;

  /// The keys logged so far.
  Set<String> get logged => Set<String>.unmodifiable(_logged);

  /// Notes that [key] was checked.
  void checked(String key) {
    if (!enabled || !_checked.add(key)) return;
    if (_treeLoaded) _judge(key);
  }

  /// Notes a new value of `permissionsProvider`.
  void loaded(Permissions? permissions) {
    if (!enabled || permissions == null || permissions.allowsEverything) {
      return;
    }
    if (permissions.areas.isEmpty && permissions.components.isEmpty) return;
    _treeLoaded = true;
    _seen
      ..addAll(permissions.areas)
      ..addAll(permissions.components.keys);
    _checked.forEach(_judge);
  }

  void _judge(String key) {
    if (_seen.contains(key) || !_logged.add(key)) return;
    _log.warning(
      'Permission key "$key" is checked but no loaded permissions contain '
      'it. Check it against the keys the backend sends.',
    );
  }
}
