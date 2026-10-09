import 'package:core/core.dart';

import '../../../shared/permission_keys.dart';

/// The demo `loadPermissions` hook. reqres has no permissions, so it
/// answers locally: the profile and settings areas, but not reports, so the
/// reports demo screen opens Core's "no permission" page. It also carries
/// one component rule per state.
///
/// A real loader fetches the backend's tree with [session]'s token (sent
/// as its own `Authorization` header: the session isn't saved yet at
/// login), keeps this app's branch, flattens it and returns [Permissions].
Future<Permissions> loadDemoPermissions(Session session) async {
  return const Permissions(
    areas: <String>{AppAreas.profile, AppAreas.settings},
    components: <String, ComponentState>{
      AppComponents.profileEmail: ComponentState.readonly,
      AppComponents.profileEdit: ComponentState.disabled,
      AppComponents.settingsDeleteAccount: ComponentState.hidden,
    },
  );
}
