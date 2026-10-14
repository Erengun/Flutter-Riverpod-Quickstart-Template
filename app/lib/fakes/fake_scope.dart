import 'package:core/core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:material_ui/material_ui.dart';

import '../features/authentication/data/authentication_repository.dart';
import '../features/authentication/data/demo_permissions.dart';
import '../features/authentication/domain/login_request.dart';
import '../features/authentication/fakes/fake_auth_repository.dart';
import 'fake_storage.dart';

/// What the [FakeStorage] boxes hold when a [FakeScope] opens.
class FakeSeed {
  const FakeSeed({this.credentials, this.signedIn = false, this.permissions});

  /// Remembered login credentials.
  final LoginCredentials? credentials;

  /// Whether a session and the permissions are saved, as after a login.
  final bool signedIn;

  /// The permissions saved with the session and answered by the
  /// `loadPermissions` hook; `null` for the demo permissions. Must survive
  /// `Permissions.encode`, so list the areas instead of using
  /// `Permissions.unrestricted`.
  final Permissions? permissions;
}

/// Runs a screen on Fakes: [FakeStorage] instead of the encrypted boxes, one
/// Fake per repository and the demo `loadPermissions` hook.
/// `FakeScope(child: AnyScreen())` renders with no other arguments; [seed],
/// [sessionExpired] and the repository Fakes are only for variants.
///
/// The boxes are emptied and seeded with [seed] each time the scope opens,
/// so every visit starts the same. It is the root `ProviderScope` of its
/// screen, so nothing may sit above it.
class FakeScope extends StatefulWidget {
  const FakeScope({
    required this.child,
    this.seed = const FakeSeed(),
    this.authRepository,
    this.sessionExpired = false,
    super.key,
  });

  final FakeSeed seed;

  /// Whether the user was just signed out by an expired session, as when the
  /// router sends them to the login page.
  final bool sessionExpired;

  /// Defaults to a [FakeAuthRepository] that signs in.
  final AuthenticationRepository? authRepository;

  /// The screen.
  final Widget child;

  @override
  State<FakeScope> createState() => _FakeScopeState();
}

class _FakeScopeState extends State<FakeScope> {
  late final Future<FakeStorage> _storage = _open(widget.seed);

  static Future<FakeStorage> _open(FakeSeed seed) async {
    final FakeStorage storage = await FakeStorage.open();
    final LoginCredentials? credentials = seed.credentials;
    if (credentials != null) await storage.remember(credentials);
    if (seed.signedIn) await storage.signIn(permissions: seed.permissions);
    return storage;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<FakeStorage>(
      future: _storage,
      builder: (BuildContext context, AsyncSnapshot<FakeStorage> snapshot) {
        final FakeStorage? storage = snapshot.data;
        if (storage == null) {
          return const Center(child: CircularProgressIndicator());
        }
        // The root scope of this screen, so overriding a provider without
        // dependencies is fine.
        return ProviderScope(
          overrides: <Override>[
            ...storage.overrides,
            sessionHooksProvider.overrideWithValue(
              SessionHooks(loadPermissions: _loadPermissions),
            ),
            if (widget.sessionExpired)
              sessionExpiredProvider.overrideWith(_ExpiredSession.new),
            // One line per repository Fake.
            // ignore: riverpod_lint/scoped_providers_should_specify_dependencies
            authenticationRepositoryProvider.overrideWithValue(
              widget.authRepository ?? FakeAuthRepository(),
            ),
          ],
          child: widget.child,
        );
      },
    );
  }

  /// The demo permissions, or the [FakeSeed.permissions] when given, so the
  /// launch reload keeps what the seed saved.
  Future<Permissions> _loadPermissions(Session session) async =>
      widget.seed.permissions ?? await loadDemoPermissions(session);
}

/// Starts as after a rejected refresh: the user was signed out because the
/// session expired.
class _ExpiredSession extends SessionExpiredNotifier {
  @override
  bool build() => true;
}
