import 'dart:async';
import 'dart:io';

import 'package:core/core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';

import '../support/recording_reporter.dart';

void main() {
  late Directory directory;
  late Box<String> box;
  late RecordingReporter reporter;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('core_session_test');
    Hive.init(directory.path);
    box = await Hive.openBox<String>(sessionBoxName);
    reporter = RecordingReporter();
  });

  tearDown(() async {
    await Hive.close();
    await directory.delete(recursive: true);
  });

  ProviderContainer createContainer({
    SessionHooks hooks = const SessionHooks(),
  }) {
    final ProviderContainer container = ProviderContainer(
      overrides: <Override>[
        sessionBoxProvider.overrideWith((Ref ref) async => box),
        errorReporterProvider.overrideWithValue(reporter),
        sessionHooksProvider.overrideWithValue(hooks),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  test('is signed out when nothing is saved', () async {
    expect(await createContainer().read(sessionProvider.future), isNull);
  });

  test('signing in saves the session, which survives a restart', () async {
    const Session session = Session(
      accessToken: 'access',
      refreshToken: 'refresh',
      userId: '42',
    );
    final ProviderContainer first = createContainer();
    await first.read(sessionProvider.future);
    await first.read(sessionProvider.notifier).signIn(session);

    expect(first.read(sessionProvider).value, session);

    final ProviderContainer restarted = createContainer();
    expect(await restarted.read(sessionProvider.future), session);
  });

  test('a session without optional fields survives a restart', () async {
    final ProviderContainer first = createContainer();
    await first.read(sessionProvider.future);
    await first
        .read(sessionProvider.notifier)
        .signIn(const Session(accessToken: 'one', userId: '1'));
    await first
        .read(sessionProvider.notifier)
        .signIn(const Session(accessToken: 'two'));

    expect(
      await createContainer().read(sessionProvider.future),
      const Session(accessToken: 'two'),
    );
  });

  test('signing in sets the reporter user only when an id is given', () async {
    final ProviderContainer container = createContainer();
    await container.read(sessionProvider.future);

    await container
        .read(sessionProvider.notifier)
        .signIn(const Session(accessToken: 'a'));
    expect(reporter.users, isEmpty);

    await container
        .read(sessionProvider.notifier)
        .signIn(const Session(accessToken: 'a', userId: '7'));
    expect(reporter.users, <String?>['7']);
  });

  group('logout', () {
    const Session session = Session(accessToken: 'access', userId: '7');

    Future<ProviderContainer> signedIn({
      SessionHooks hooks = const SessionHooks(),
    }) async {
      final ProviderContainer container = createContainer(hooks: hooks);
      await container.read(sessionProvider.future);
      await container.read(sessionProvider.notifier).signIn(session);
      return container;
    }

    test('clears the tokens and the reporter user', () async {
      final ProviderContainer container = await signedIn();

      await container.read(sessionProvider.notifier).logout();

      expect(container.read(sessionProvider).value, isNull);
      expect(box.isEmpty, isTrue);
      expect(reporter.users.last, isNull);
      expect(await createContainer().read(sessionProvider.future), isNull);
    });

    test('calls the hook with the session without waiting for it', () async {
      final Completer<void> backend = Completer<void>();
      final List<Session> calls = <Session>[];
      final ProviderContainer container = await signedIn(
        hooks: SessionHooks(
          logout: (Session session) {
            calls.add(session);
            return backend.future;
          },
        ),
      );

      // Completes although the backend never answers.
      await container.read(sessionProvider.notifier).logout();

      expect(calls, <Session>[session]);
      expect(container.read(sessionProvider).value, isNull);
      expect(box.isEmpty, isTrue);
    });

    test('clears the tokens when the hook fails', () async {
      final ProviderContainer container = await signedIn(
        hooks: SessionHooks(
          logout: (Session session) async =>
              throw const ApiServerException(500),
        ),
      );

      await container.read(sessionProvider.notifier).logout();
      await pumpEventQueue();

      expect(container.read(sessionProvider).value, isNull);
      expect(box.isEmpty, isTrue);
    });

    test('clears the tokens when the hook throws synchronously', () async {
      final ProviderContainer container = await signedIn(
        hooks: SessionHooks(
          logout: (Session session) => throw StateError('no backend'),
        ),
      );

      await container.read(sessionProvider.notifier).logout();

      expect(container.read(sessionProvider).value, isNull);
    });

    test('works when already signed out, without calling the hook', () async {
      int calls = 0;
      final ProviderContainer container = createContainer(
        hooks: SessionHooks(logout: (Session session) async => calls++),
      );
      await container.read(sessionProvider.future);

      await container.read(sessionProvider.notifier).logout();

      expect(calls, 0);
      expect(container.read(sessionProvider).value, isNull);
    });
  });
}
