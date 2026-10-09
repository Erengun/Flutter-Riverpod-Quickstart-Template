import 'package:core/core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'demo_permissions.dart';

/// The auth Feature's backend calls for Core's session. The app overrides
/// `sessionHooksProvider` with it (`lib/app/overrides.dart`).
SessionHooks authSessionHooks(Ref ref) {
  return const SessionHooks(loadPermissions: loadDemoPermissions);
}
