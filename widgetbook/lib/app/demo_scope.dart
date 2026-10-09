import 'dart:typed_data';

import 'package:core/core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_riverpod_template/features/authentication/data/authentication_repository.dart';
import 'package:flutter_riverpod_template/features/authentication/data/credentials_store.dart';
import 'package:flutter_riverpod_template/features/authentication/data/demo_permissions.dart';
import 'package:flutter_riverpod_template/features/authentication/domain/login_request.dart';
import 'package:flutter_riverpod_template/features/authentication/domain/login_response.dart';
import 'package:flutter_riverpod_template/features/authentication/domain/register_response.dart';
import 'package:flutter_riverpod_template/hive/hive_registrar.g.dart';
import 'package:hive_ce/hive.dart';
import 'package:material_ui/material_ui.dart';

/// An [AuthenticationRepository] that never calls the backend.
class FakeAuthRepository implements AuthenticationRepository {
  const FakeAuthRepository({this.loginError});

  /// Thrown by [login] instead of signing in, when set.
  final ApiException? loginError;

  @override
  Future<LoginResponse> login(String email, String password) async {
    final ApiException? error = loginError;
    if (error != null) throw error;
    return const LoginResponse(token: 'widgetbook-token');
  }

  @override
  Future<RegisterResponse> register(String email, String password) async =>
      const RegisterResponse(id: 4, token: 'widgetbook-token');
}

/// The demo login, remembered by the "remembered credentials" use cases.
const LoginCredentials demoCredentials = LoginCredentials(
  email: 'eve.holt@reqres.in',
  password: 'cityslicka',
);

/// What the demo boxes hold when a use case opens.
class DemoSeed {
  const DemoSeed({this.credentials, this.signedIn = false});

  /// Remembered login credentials.
  final LoginCredentials? credentials;

  /// Whether a session and the demo permissions are saved, as after a login.
  final bool signedIn;
}

/// Runs a demo screen with the overrides the app's tests use: in-memory
/// Hive boxes instead of the encrypted ones, a fake
/// [AuthenticationRepository] and the demo `loadPermissions` hook.
///
/// The boxes are emptied and seeded with [seed] each time the use case
/// opens, so every visit starts the same.
class DemoScope extends StatefulWidget {
  const DemoScope({
    required this.child,
    this.seed = const DemoSeed(),
    this.repository = const FakeAuthRepository(),
    super.key,
  });

  final DemoSeed seed;

  final AuthenticationRepository repository;

  /// The screen.
  final Widget child;

  @override
  State<DemoScope> createState() => _DemoScopeState();
}

class _DemoScopeState extends State<DemoScope> {
  late final Future<_DemoBoxes> _boxes = _DemoBoxes.open(widget.seed);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_DemoBoxes>(
      future: _boxes,
      builder: (BuildContext context, AsyncSnapshot<_DemoBoxes> snapshot) {
        final _DemoBoxes? boxes = snapshot.data;
        if (boxes == null) {
          return const Center(child: CircularProgressIndicator());
        }
        // The root scope of this use case (the catalog has no ProviderScope
        // above it), so overriding a provider without dependencies is fine.
        return ProviderScope(
          overrides: <Override>[
            ...boxes.overrides,
            // ignore: riverpod_lint/scoped_providers_should_specify_dependencies
            authenticationRepositoryProvider.overrideWithValue(
              widget.repository,
            ),
            sessionHooksProvider.overrideWithValue(
              const SessionHooks(loadPermissions: loadDemoPermissions),
            ),
          ],
          child: widget.child,
        );
      },
    );
  }
}

class _DemoBoxes {
  _DemoBoxes._(this.prefs, this.session, this.credentials);

  final Box<String> prefs;
  final Box<String> session;
  final Box<LoginCredentials> credentials;

  static bool _adaptersRegistered = false;

  /// Opens (or reuses) the in-memory boxes, empties them and writes [seed].
  static Future<_DemoBoxes> open(DemoSeed seed) async {
    if (!_adaptersRegistered) {
      Hive.registerAdapters();
      _adaptersRegistered = true;
    }
    final _DemoBoxes boxes = _DemoBoxes._(
      await Hive.openBox<String>('widgetbook_prefs', bytes: Uint8List(0)),
      await Hive.openBox<String>('widgetbook_session', bytes: Uint8List(0)),
      await Hive.openBox<LoginCredentials>(
        'widgetbook_credentials',
        bytes: Uint8List(0),
      ),
    );
    await boxes.prefs.clear();
    await boxes.session.clear();
    await boxes.credentials.clear();
    final LoginCredentials? credentials = seed.credentials;
    if (credentials != null) {
      await boxes.credentials.put('credentials', credentials);
    }
    if (seed.signedIn) {
      await boxes.session.putAll(<String, String>{
        'accessToken': 'widgetbook-token',
        permissionsKey: (await loadDemoPermissions(
          const Session(accessToken: 'widgetbook-token'),
        )).encode(),
      });
    }
    return boxes;
  }

  List<Override> get overrides => <Override>[
    prefsBoxProvider.overrideWithValue(prefs),
    sessionBoxProvider.overrideWith((Ref ref) async => session),
    credentialsBoxProvider.overrideWith((Ref ref) async => credentials),
  ];
}
