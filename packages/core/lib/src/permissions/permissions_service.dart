import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce/hive.dart';
import 'package:logging/logging.dart';

import '../network/api_exception.dart';
import '../reporting/error_reporter.dart';
import '../session/session.dart';
import 'permissions.dart';

/// The key the last loaded [Permissions] are saved under in the encrypted
/// session box, so signing out (which clears that box) deletes them.
const String permissionsKey = 'permissions';

/// The signed-in user's [Permissions], or `null` while they are not known
/// yet (the session is loading, or a cold start found nothing saved and is
/// loading them). Signed out: [Permissions.none]. Without a
/// `SessionHooks.loadPermissions` hook: [Permissions.unrestricted].
///
/// It watches [sessionProvider], so it resets on sign-out. Loading and
/// reloading go through [permissionsServiceProvider].
final Provider<Permissions?> permissionsProvider = Provider<Permissions?>((
  Ref ref,
) {
  final AsyncValue<Session?> session = ref.watch(sessionProvider);
  final PermissionsService service = ref.watch(permissionsServiceProvider);
  // Bumped by the service when a reload lands.
  ref.watch(_revisionProvider);
  if (!session.hasValue && !session.hasError) return null;
  final Session? current = session.hasError ? null : session.value;
  if (current == null) {
    service._forget();
    return Permissions.none;
  }
  if (ref.watch(sessionHooksProvider).loadPermissions == null) {
    return Permissions.unrestricted;
  }
  return service._resolve(current, ref.watch(sessionBoxProvider).value);
}, name: 'permissionsProvider');

/// [permissionsProvider]'s current value as a [Listenable], for go_router's
/// `refreshListenable` (merged with `sessionListenableProvider`): the guard
/// re-runs whenever the permissions load or change.
final Provider<ValueListenable<Permissions?>> permissionsListenableProvider =
    Provider<ValueListenable<Permissions?>>((Ref ref) {
      final ValueNotifier<Permissions?> notifier = ValueNotifier<Permissions?>(
        ref.read(permissionsProvider),
      );
      ref
        ..listen<Permissions?>(
          permissionsProvider,
          (Permissions? previous, Permissions? next) => notifier.value = next,
        )
        ..onDispose(notifier.dispose);
      return notifier;
    }, name: 'permissionsListenableProvider');

/// Loads, saves and reloads the [Permissions]. Keep-alive and never rebuilt,
/// so its per-launch limits hold for the whole run.
final Provider<PermissionsService> permissionsServiceProvider =
    Provider<PermissionsService>(
      PermissionsService.new,
      name: 'permissionsServiceProvider',
    );

/// Counts the reloads that landed, so [permissionsProvider] rebuilds.
final NotifierProvider<_Revision, int> _revisionProvider =
    NotifierProvider<_Revision, int>(
      _Revision.new,
      name: 'permissionsRevisionProvider',
    );

class _Revision extends Notifier<int> {
  @override
  int build() => 0;

  void bump() => state++;
}

/// Core's permission service.
///
/// - [loadForSignIn] runs at login, before the session is saved: login
///   completes only once the permissions have loaded.
/// - Once per launch, a saved list is used at once and reloaded in the
///   background.
/// - [reloadAfterForbidden] reloads at most once per launch after a 403.
/// - One reload at a time; a failed reload keeps the current list. Nothing
///   reloads on app foreground.
class PermissionsService {
  PermissionsService(this._ref);

  static final Logger _log = Logger('permissions');

  final Ref _ref;

  /// The permissions loaded during this run, for the session they belong
  /// to.
  ({Session session, Permissions permissions})? _loaded;

  bool _launchReloadStarted = false;
  bool _forbiddenReloadUsed = false;
  Future<void>? _reloading;

  /// Loads [session]'s permissions and saves them. Call it after the login
  /// call succeeds and before `sessionProvider.notifier.signIn(session)`.
  ///
  /// Without a hook this does nothing. If the hook throws, a saved list is
  /// used when there is one; otherwise the error is rethrown and login
  /// must fail (show it with `listenApiErrors`).
  Future<void> loadForSignIn(Session session) async {
    final LoadPermissionsHook? hook = _ref
        .read(sessionHooksProvider)
        .loadPermissions;
    if (hook == null) return;
    final Box<String> box = await _ref.read(sessionBoxProvider.future);
    Permissions permissions;
    try {
      permissions = await hook(session);
    } catch (_) {
      final Permissions? saved = _read(box);
      if (saved == null) {
        // The login controller's AsyncError carries it to the user.
        _log.info('Permissions could not be loaded; login fails.');
        rethrow;
      }
      _log.info('Permissions could not be loaded; using the saved list.');
      permissions = saved;
    }
    await _save(box, permissions);
    _loaded = (session: session, permissions: permissions);
    // A fresh load counts as this launch's load.
    _launchReloadStarted = true;
  }

  /// Reloads once after a 403, at most once per launch. `ApiCall` calls it
  /// for every `ApiForbiddenException`; the user still sees Core's default
  /// "no permission" message.
  void reloadAfterForbidden() {
    final Session? session = _ref.read(sessionProvider).value;
    if (session == null) return;
    if (_ref.read(sessionHooksProvider).loadPermissions == null) return;
    if (_forbiddenReloadUsed) return;
    _forbiddenReloadUsed = true;
    _log.info('Reloading permissions after a 403.');
    unawaited(_reload(session));
  }

  Permissions? _resolve(Session session, Box<String>? box) {
    final ({Session session, Permissions permissions})? loaded = _loaded;
    if (loaded != null && loaded.session == session) {
      return loaded.permissions;
    }
    final Permissions? saved = box == null ? null : _read(box);
    if (saved != null) _loaded = (session: session, permissions: saved);
    if (!_launchReloadStarted) {
      _launchReloadStarted = true;
      // Never during a provider build: a landed reload rebuilds it.
      scheduleMicrotask(() => unawaited(_reload(session)));
    }
    // Nothing saved: unknown until the reload lands.
    return saved;
  }

  void _forget() => _loaded = null;

  /// One reload at a time: a second caller joins the running one.
  Future<void> _reload(Session session) {
    return _reloading ??= _runReload(session).whenComplete(
      () => _reloading = null,
    );
  }

  Future<void> _runReload(Session session) async {
    final LoadPermissionsHook? hook = _ref
        .read(sessionHooksProvider)
        .loadPermissions;
    if (hook == null) return;
    try {
      final Permissions permissions = await hook(session);
      final Box<String> box = await _ref.read(sessionBoxProvider.future);
      // Signed out (or in as someone else) meanwhile: drop the result.
      if (_ref.read(sessionProvider).value != session) return;
      _loaded = (session: session, permissions: permissions);
      await _save(box, permissions);
    } catch (error, stackTrace) {
      _log.info('Reloading permissions failed; keeping the current list.');
      _reportUnhandled(error, stackTrace);
      // Nothing was known (a cold start with nothing saved): fail closed.
      if (_loaded?.session != session &&
          _ref.read(sessionProvider).value == session) {
        _loaded = (session: session, permissions: Permissions.none);
      }
    }
    _ref.read(_revisionProvider.notifier).bump();
  }

  Permissions? _read(Box<String> box) {
    final String? saved = box.get(permissionsKey);
    return saved == null ? null : Permissions.decode(saved);
  }

  Future<void> _save(Box<String> box, Permissions permissions) async {
    try {
      await box.put(permissionsKey, permissions.encode());
    } catch (_) {
      // Kept in memory for this run; the next launch loads them again.
      _log.warning('Permissions could not be saved.');
    }
  }

  /// `ApiCall` has already handled an [ApiException]; anything else is
  /// reported here, since it fails no provider.
  void _reportUnhandled(Object error, StackTrace stackTrace) {
    if (error is ApiException) return;
    _ref.read(errorReporterProvider).report(error, stackTrace);
  }
}
