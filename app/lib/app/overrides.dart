import 'package:core/core.dart';
import 'package:flutter_riverpod/misc.dart';

import '../features/authentication/data/auth_session_hooks.dart';

/// The app's own `ProviderScope` overrides, passed to `bootstrap`.
List<Override> buildAppOverrides() => <Override>[
  sessionHooksProvider.overrideWith(authSessionHooks),
];
