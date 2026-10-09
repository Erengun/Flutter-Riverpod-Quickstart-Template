import 'package:core/core.dart';

import '../../../shared/permission_keys.dart';

/// The demo `loadPermissions` hook. reqres has no permissions, so it
/// answers locally: the profile, settings and orders areas, but not
/// reports, so the reports demo screen opens Core's "no permission" page
/// and the menu leaves it out (orders has no screen, so its entry opens the
/// under-construction page). It also carries one component rule per state,
/// shown by the demo home screen's `PermissionGate`s.
///
/// A real loader fetches the backend's tree with [session]'s token (sent
/// as its own `Authorization` header: the session isn't saved yet at
/// login), keeps this app's branch, flattens it and returns [Permissions].
Future<Permissions> loadDemoPermissions(Session session) async {
  return const Permissions(
    areas: <String>{AppAreas.profile, AppAreas.settings, AppAreas.orders},
    components: <String, ComponentState>{
      AppComponents.profileEmail: ComponentState.readonly,
      AppComponents.profileEdit: ComponentState.disabled,
      AppComponents.settingsDeleteAccount: ComponentState.hidden,
    },
  );
}
