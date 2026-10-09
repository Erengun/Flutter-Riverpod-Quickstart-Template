import 'package:core/core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_riverpod_template/features/authentication/data/authentication_repository.dart';
import 'package:flutter_riverpod_template/features/authentication/data/credentials_store.dart';
import 'package:flutter_riverpod_template/features/authentication/domain/login_request.dart';
import 'package:flutter_riverpod_template/features/authentication/domain/login_response.dart';
import 'package:flutter_riverpod_template/features/authentication/domain/register_response.dart';
import 'package:flutter_riverpod_template/features/authentication/presentation/login/auth_ui_model.dart';
import 'package:flutter_riverpod_template/features/authentication/presentation/login/login_controller.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/storage.dart';

class FakeAuthRepository implements AuthenticationRepository {
  @override
  Future<LoginResponse> login(String email, String password) async {
    if (email.isEmpty || password.isEmpty) throw Exception('Empty');
    return const LoginResponse(token: 'fake_token');
  }

  @override
  Future<RegisterResponse> register(String email, String password) async {
    if (email.isEmpty || password.isEmpty) throw Exception('Empty');
    return const RegisterResponse(id: 1, token: 'fake_token');
  }
}

class _RejectingAuthRepository extends FakeAuthRepository {
  @override
  Future<LoginResponse> login(String email, String password) async {
    throw const ApiServerException(400, message: 'user not found');
  }
}

class _FailingCredentialsStore extends CredentialsStore {
  const _FailingCredentialsStore(super.box);

  @override
  Future<void> save(LoginCredentials credentials) async {
    throw StateError('disk full');
  }
}

class _RecordingReporter extends NoopErrorReporter {
  final List<Object> errors = <Object>[];

  @override
  void report(
    Object error,
    StackTrace? stackTrace, {
    bool fatal = false,
    String? groupKey,
    Map<String, String> tags = const <String, String>{},
    Map<String, Object?> extra = const <String, Object?>{},
  }) {
    errors.add(error);
  }
}

const LoginCredentials _eve = LoginCredentials(
  email: 'eve.holt@reqres.in',
  password: 'cityslicka',
);

void main() {
  late TestStorage storage;

  setUp(() async {
    storage = await TestStorage.open();
  });

  tearDown(() => storage.close());

  /// A container whose login controller stays alive, after its first load.
  Future<ProviderContainer> createContainer({
    AuthenticationRepository? repository,
    List<Override> more = const <Override>[],
  }) async {
    final ProviderContainer container = ProviderContainer(
      overrides: <Override>[
        ...storage.overrides,
        authenticationRepositoryProvider.overrideWithValue(
          repository ?? FakeAuthRepository(),
        ),
        ...more,
      ],
    );
    addTearDown(container.dispose);
    container.listen<AsyncValue<AuthUiModel>>(
      loginControllerProvider,
      (AsyncValue<AuthUiModel>? previous, AsyncValue<AuthUiModel> next) {},
    );
    await container.read(loginControllerProvider.future);
    return container;
  }

  LoginCredentials? savedCredentials() =>
      storage.credentials.get('credentials');

  test('starts empty when nothing is remembered', () async {
    final ProviderContainer container = await createContainer();

    final AuthUiModel state = container.read(loginControllerProvider).value!;
    expect(state.user, isNull);
    expect(state.rememberMe, isFalse);
    expect(state.showPassword, isFalse);
  });

  test(
    'remembered credentials pre-fill the form and tick remember me',
    () async {
      await storage.credentials.put('credentials', _eve);

      final ProviderContainer container = await createContainer();

      final AuthUiModel state = container.read(loginControllerProvider).value!;
      expect(state.user, _eve);
      expect(state.rememberMe, isTrue);
      // Pre-fill only: nobody is signed in.
      expect(await container.read(sessionProvider.future), isNull);
    },
  );

  group('login', () {
    test('starts the session', () async {
      final ProviderContainer container = await createContainer();

      final LoginResponse? response = await container
          .read(loginControllerProvider.notifier)
          .login(email: _eve.email, password: _eve.password);

      expect(response?.token, 'fake_token');
      expect(
        container.read(sessionProvider).value,
        const Session(accessToken: 'fake_token'),
      );
      expect(storage.session.get('accessToken'), 'fake_token');
    });

    test('with remember me ticked saves the credentials', () async {
      final ProviderContainer container = await createContainer();
      final LoginController controller = container.read(
        loginControllerProvider.notifier,
      );

      await controller.updateRememberMe(rememberMe: true);
      await controller.login(email: _eve.email, password: _eve.password);

      expect(savedCredentials(), _eve);
    });

    test('without remember me saves nothing and forgets old ones', () async {
      await storage.credentials.put(
        'credentials',
        const LoginCredentials(email: 'old@reqres.in', password: 'old'),
      );
      final ProviderContainer container = await createContainer();
      final LoginController controller = container.read(
        loginControllerProvider.notifier,
      );
      // Untick, then type over the pre-filled form.
      await controller.updateRememberMe(rememberMe: false);

      await controller.login(email: _eve.email, password: _eve.password);

      expect(savedCredentials(), isNull);
    });

    test('throws when the credentials are empty', () async {
      final ProviderContainer container = await createContainer();

      expect(
        () => container
            .read(loginControllerProvider.notifier)
            .login(email: '', password: ''),
        throwsException,
      );
    });

    test('a failed login is an AsyncError that keeps the form', () async {
      final ProviderContainer container = await createContainer(
        repository: _RejectingAuthRepository(),
      );
      final LoginController controller = container.read(
        loginControllerProvider.notifier,
      )..updateShowPassword(showPassword: true);

      final LoginResponse? response = await controller.login(
        email: _eve.email,
        password: 'wrong',
      );

      expect(response, isNull);
      final AsyncValue<AuthUiModel> state = container.read(
        loginControllerProvider,
      );
      expect(state.error, isA<ApiServerException>());
      expect(state.value?.showPassword, isTrue);
      expect(container.read(sessionProvider).value, isNull);
    });

    test('a failed save is reported and login still succeeds', () async {
      final _RecordingReporter reporter = _RecordingReporter();
      final ProviderContainer container = await createContainer(
        more: <Override>[
          credentialsStoreProvider.overrideWith(
            (Ref ref) async => _FailingCredentialsStore(storage.credentials),
          ),
          errorReporterProvider.overrideWithValue(reporter),
        ],
      );
      final LoginController controller = container.read(
        loginControllerProvider.notifier,
      );
      await controller.updateRememberMe(rememberMe: true);

      final LoginResponse? response = await controller.login(
        email: _eve.email,
        password: _eve.password,
      );

      expect(response?.token, 'fake_token');
      expect(reporter.errors.single, isA<StateError>());
      expect(container.read(sessionProvider).value, isNotNull);
    });
  });

  group('remember me', () {
    test('unticking deletes the saved credentials at once', () async {
      await storage.credentials.put('credentials', _eve);
      final ProviderContainer container = await createContainer();

      await container
          .read(loginControllerProvider.notifier)
          .updateRememberMe(rememberMe: false);

      expect(savedCredentials(), isNull);
      expect(container.read(loginControllerProvider).value?.rememberMe, false);
    });

    test('logout keeps the saved credentials', () async {
      final ProviderContainer container = await createContainer();
      final LoginController controller = container.read(
        loginControllerProvider.notifier,
      );
      await controller.updateRememberMe(rememberMe: true);
      await controller.login(email: _eve.email, password: _eve.password);

      await container.read(sessionProvider.notifier).logout();

      expect(container.read(sessionProvider).value, isNull);
      expect(savedCredentials(), _eve);
    });
  });

  group('register', () {
    test('pre-fills the form without saving or signing in', () async {
      final ProviderContainer container = await createContainer();

      await container
          .read(loginControllerProvider.notifier)
          .register(email: _eve.email, password: 'pistol');

      expect(
        container.read(loginControllerProvider).value?.user,
        LoginCredentials(email: _eve.email, password: 'pistol'),
      );
      expect(savedCredentials(), isNull);
      expect(container.read(sessionProvider).value, isNull);
    });

    test('throws when the credentials are empty', () async {
      final ProviderContainer container = await createContainer();

      expect(
        () => container
            .read(loginControllerProvider.notifier)
            .register(email: '', password: ''),
        throwsException,
      );
    });
  });
}
