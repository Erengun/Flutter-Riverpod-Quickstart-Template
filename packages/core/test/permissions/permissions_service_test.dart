import 'dart:async';
import 'dart:io';

import 'package:core/core.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';

import '../support/recording_reporter.dart';

const Session _session = Session(accessToken: 'access');

const Permissions _saved = Permissions(areas: <String>{'orders'});

const Permissions _fresh = Permissions(
  areas: <String>{'orders', 'reports'},
  components: <String, ComponentState>{
    'orders.delete': ComponentState.hidden,
  },
);

/// A `loadPermissions` hook answering from a script. Each call takes the
/// next reply; the last one repeats.
class _Loader {
  _Loader(this._replies);

  final List<FutureOr<Permissions> Function()> _replies;
  final List<Session> calls = <Session>[];

  Future<Permissions> call(Session session) async {
    final int index = calls.length < _replies.length
        ? calls.length
        : _replies.length - 1;
    calls.add(session);
    return _replies[index]();
  }
}

/// Lets scheduled microtasks run (a launch reload starts in one). Only for
/// checking that nothing more happened: a reload that saves writes a file,
/// which can take longer than any fixed number of event-loop turns.
Future<void> _settle() async {
  for (int i = 0; i < 10; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

/// Waits until the running reload has landed, box write included.
Future<void> _reloaded(ProviderContainer container) async {
  await _settle();
  final Future<void>? reloading = container
      .read(permissionsServiceProvider)
      .reloading;
  if (reloading != null) await reloading;
}

DioException _forbidden() {
  final RequestOptions options = RequestOptions(path: '/orders');
  return DioException(
    requestOptions: options,
    type: DioExceptionType.badResponse,
    response: Response<Object?>(requestOptions: options, statusCode: 403),
  );
}

void main() {
  late Directory directory;
  late Box<String> box;
  late RecordingReporter reporter;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('core_permissions_test');
    Hive.init(directory.path);
    box = await Hive.openBox<String>(sessionBoxName);
    reporter = RecordingReporter();
  });

  tearDown(() async {
    await Hive.close();
    await directory.delete(recursive: true);
  });

  ProviderContainer createContainer({LoadPermissionsHook? loadPermissions}) {
    final ProviderContainer container = ProviderContainer(
      overrides: <Override>[
        sessionBoxProvider.overrideWith((Ref ref) async => box),
        errorReporterProvider.overrideWithValue(reporter),
        sessionHooksProvider.overrideWithValue(
          SessionHooks(loadPermissions: loadPermissions),
        ),
      ],
    );
    addTearDown(container.dispose);
    // The router keeps it listened to in the app.
    container.listen<Permissions?>(
      permissionsProvider,
      (Permissions? previous, Permissions? next) {},
    );
    return container;
  }

  Future<void> saveSignedIn({Permissions? permissions}) async {
    await box.put('accessToken', _session.accessToken);
    if (permissions != null) {
      await box.put(permissionsKey, permissions.encode());
    }
  }

  Future<void> forbiddenCall(ProviderContainer container) {
    return expectLater(
      container.read(apiCallProvider)<void>(() async => throw _forbidden()),
      throwsA(isA<ApiForbiddenException>()),
    );
  }

  group('without a loadPermissions hook', () {
    test('a signed-in user may open everything', () async {
      await saveSignedIn();
      final ProviderContainer container = createContainer();
      await container.read(sessionProvider.future);

      expect(container.read(permissionsProvider), Permissions.unrestricted);
    });

    test('login and a 403 load nothing', () async {
      final ProviderContainer container = createContainer();
      await container.read(sessionProvider.future);

      await container.read(permissionsServiceProvider).loadForSignIn(_session);
      await forbiddenCall(container);

      expect(box.get(permissionsKey), isNull);
    });
  });

  test('a signed-out user has no permissions', () async {
    final _Loader loader = _Loader(<Permissions Function()>[() => _fresh]);
    final ProviderContainer container = createContainer(
      loadPermissions: loader.call,
    );
    await container.read(sessionProvider.future);
    await _settle();

    expect(container.read(permissionsProvider), Permissions.none);
    expect(loader.calls, isEmpty);
  });

  group('at login', () {
    test('loads and saves them before the session starts', () async {
      final _Loader loader = _Loader(<Permissions Function()>[() => _fresh]);
      final ProviderContainer container = createContainer(
        loadPermissions: loader.call,
      );
      await container.read(sessionProvider.future);

      await container.read(permissionsServiceProvider).loadForSignIn(_session);
      expect(Permissions.decode(box.get(permissionsKey)!), _fresh);

      await container.read(sessionProvider.notifier).signIn(_session);
      await _settle();

      expect(container.read(permissionsProvider), _fresh);
      // The login load is this launch's load.
      expect(loader.calls, <Session>[_session]);
    });

    test('fails closed when the load fails and nothing is saved', () async {
      final Exception failure = Exception('backend down');
      final _Loader loader = _Loader(<Permissions Function()>[
        () => throw failure,
      ]);
      final ProviderContainer container = createContainer(
        loadPermissions: loader.call,
      );
      await container.read(sessionProvider.future);

      await expectLater(
        container.read(permissionsServiceProvider).loadForSignIn(_session),
        throwsA(same(failure)),
      );
      expect(box.get(permissionsKey), isNull);
    });

    test('uses the saved list when the load fails', () async {
      await box.put(permissionsKey, _saved.encode());
      final _Loader loader = _Loader(<Permissions Function()>[
        () => throw Exception('backend down'),
      ]);
      final ProviderContainer container = createContainer(
        loadPermissions: loader.call,
      );
      await container.read(sessionProvider.future);

      await container.read(permissionsServiceProvider).loadForSignIn(_session);
      await container.read(sessionProvider.notifier).signIn(_session);

      expect(container.read(permissionsProvider), _saved);
    });
  });

  group('once per launch', () {
    test('uses the saved list at once, then reloads it in the background',
        () async {
      await saveSignedIn(permissions: _saved);
      final Completer<Permissions> reload = Completer<Permissions>();
      final _Loader loader = _Loader(<FutureOr<Permissions> Function()>[
        () => reload.future,
      ]);
      final ProviderContainer container = createContainer(
        loadPermissions: loader.call,
      );
      await container.read(sessionProvider.future);

      expect(container.read(permissionsProvider), _saved);

      await _settle();
      expect(loader.calls, <Session>[_session]);
      expect(container.read(permissionsProvider), _saved);

      reload.complete(_fresh);
      await _reloaded(container);
      expect(container.read(permissionsProvider), _fresh);
      expect(Permissions.decode(box.get(permissionsKey)!), _fresh);

      // Rebuilding never reloads again.
      container
        ..invalidate(permissionsProvider)
        ..read(permissionsProvider);
      await _settle();
      expect(loader.calls, hasLength(1));
    });

    test('a failed background reload keeps the current list', () async {
      await saveSignedIn(permissions: _saved);
      final _Loader loader = _Loader(<Permissions Function()>[
        () => throw StateError('broken loader'),
      ]);
      final ProviderContainer container = createContainer(
        loadPermissions: loader.call,
      );
      await container.read(sessionProvider.future);
      container.read(permissionsProvider);
      await _reloaded(container);

      expect(loader.calls, hasLength(1));
      expect(container.read(permissionsProvider), _saved);
      expect(Permissions.decode(box.get(permissionsKey)!), _saved);
      // Not an ApiException, so nothing else reported it.
      expect(reporter.reports.single.error, isA<StateError>());
    });

    test('nothing saved: unknown until the reload lands', () async {
      await saveSignedIn();
      final Completer<Permissions> reload = Completer<Permissions>();
      final _Loader loader = _Loader(<FutureOr<Permissions> Function()>[
        () => reload.future,
      ]);
      final ProviderContainer container = createContainer(
        loadPermissions: loader.call,
      );
      await container.read(sessionProvider.future);

      expect(container.read(permissionsProvider), isNull);
      reload.complete(_fresh);
      await _reloaded(container);
      expect(container.read(permissionsProvider), _fresh);
    });

    test('nothing saved and the reload fails: no areas (fail-closed)',
        () async {
      await saveSignedIn();
      final _Loader loader = _Loader(<Permissions Function()>[
        () => throw const ApiConnectionException(),
      ]);
      final ProviderContainer container = createContainer(
        loadPermissions: loader.call,
      );
      await container.read(sessionProvider.future);
      container.read(permissionsProvider);
      await _reloaded(container);

      expect(container.read(permissionsProvider), Permissions.none);
      // ApiCall already handled it.
      expect(reporter.reports, isEmpty);
    });
  });

  group('after a 403', () {
    test('reloads at most once per launch', () async {
      await saveSignedIn(permissions: _saved);
      final _Loader loader = _Loader(<Permissions Function()>[
        () => _saved,
        () => _fresh,
      ]);
      final ProviderContainer container = createContainer(
        loadPermissions: loader.call,
      );
      await container.read(sessionProvider.future);
      container.read(permissionsProvider);
      // The launch reload, box write included, ends before the 403;
      // otherwise the 403 would join it.
      await _reloaded(container);
      expect(loader.calls, hasLength(1));

      await forbiddenCall(container);
      await _reloaded(container);
      expect(loader.calls, hasLength(2));
      expect(container.read(permissionsProvider), _fresh);

      await forbiddenCall(container);
      await forbiddenCall(container);
      await _settle();
      expect(loader.calls, hasLength(2));
    });

    test('joins a reload already running (single-flight)', () async {
      await saveSignedIn(permissions: _saved);
      final Completer<Permissions> reload = Completer<Permissions>();
      final _Loader loader = _Loader(<FutureOr<Permissions> Function()>[
        () => reload.future,
      ]);
      final ProviderContainer container = createContainer(
        loadPermissions: loader.call,
      );
      await container.read(sessionProvider.future);
      container.read(permissionsProvider);
      await _settle();
      expect(loader.calls, hasLength(1));

      await forbiddenCall(container);
      await _settle();
      expect(loader.calls, hasLength(1));

      reload.complete(_fresh);
      await _reloaded(container);
      expect(container.read(permissionsProvider), _fresh);
    });

    test('does nothing while signed out', () async {
      final _Loader loader = _Loader(<Permissions Function()>[() => _fresh]);
      final ProviderContainer container = createContainer(
        loadPermissions: loader.call,
      );
      await container.read(sessionProvider.future);

      await forbiddenCall(container);
      await _settle();

      expect(loader.calls, isEmpty);
    });
  });

  group('sign-out', () {
    test('deletes the saved list and resets them', () async {
      await saveSignedIn(permissions: _saved);
      final _Loader loader = _Loader(<Permissions Function()>[() => _saved]);
      final ProviderContainer container = createContainer(
        loadPermissions: loader.call,
      );
      await container.read(sessionProvider.future);
      container.read(permissionsProvider);
      await _reloaded(container);

      await container.read(sessionProvider.notifier).logout();

      expect(box.get(permissionsKey), isNull);
      expect(container.read(permissionsProvider), Permissions.none);
    });

    test('drops a reload that finishes after it', () async {
      await saveSignedIn(permissions: _saved);
      final Completer<Permissions> reload = Completer<Permissions>();
      final _Loader loader = _Loader(<FutureOr<Permissions> Function()>[
        () => reload.future,
      ]);
      final ProviderContainer container = createContainer(
        loadPermissions: loader.call,
      );
      await container.read(sessionProvider.future);
      container.read(permissionsProvider);
      await _settle();

      await container.read(sessionProvider.notifier).logout();
      reload.complete(_fresh);
      await _reloaded(container);

      expect(box.get(permissionsKey), isNull);
      expect(container.read(permissionsProvider), Permissions.none);
    });
  });

  group('the container is disposed while a reload runs', () {
    /// Starts the launch reload with a hook waiting on [reply], then
    /// disposes the container (the app closing, a test ending) while the
    /// hook is still waiting.
    Future<PermissionsService> disposeMidReload(
      Completer<Permissions> reply,
    ) async {
      await saveSignedIn(permissions: _saved);
      final _Loader loader = _Loader(<FutureOr<Permissions> Function()>[
        () => reply.future,
      ]);
      final ProviderContainer container = createContainer(
        loadPermissions: loader.call,
      );
      await container.read(sessionProvider.future);
      container.read(permissionsProvider);
      await _settle();
      expect(loader.calls, hasLength(1));
      final PermissionsService service = container.read(
        permissionsServiceProvider,
      );

      container.dispose();
      return service;
    }

    test('a reload that lands afterwards stops quietly', () async {
      final Completer<Permissions> reply = Completer<Permissions>();
      final PermissionsService service = await disposeMidReload(reply);

      reply.complete(_fresh);
      // Finishes without using the disposed Ref (or throwing).
      await service.reloading!;

      expect(Permissions.decode(box.get(permissionsKey)!), _saved);
    });

    test('a reload that fails afterwards stops quietly', () async {
      final Completer<Permissions> reply = Completer<Permissions>();
      final PermissionsService service = await disposeMidReload(reply);

      reply.completeError(StateError('broken loader'));
      // Finishes without using the disposed Ref (or throwing).
      await service.reloading!;

      expect(reporter.reports, isEmpty);
      expect(Permissions.decode(box.get(permissionsKey)!), _saved);
    });
  });
}
