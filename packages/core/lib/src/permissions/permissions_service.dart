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
  return service._resolve(ref.watch(sessionBoxProvider).value);
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
/// - Results belong to the signed-in user, not to one access token: a token
///   refresh keeps them, a sign-out drops them (see
///   `sessionGenerationProvider`).
class PermissionsService {
  PermissionsService(this._ref);

  static final Logger _log = Logger('permissions');

  final Ref _ref;

  /// The permissions loaded during this run, for the session generation
  /// they belong to.
  ({int generation, Permissions permissions})? _loaded;

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
    // signIn keeps the generation when nobody is signed in.
    _loaded = (generation: _generation, permissions: permissions);
    // A fresh load counts as this launch's load.
    _launchReloadStarted = true;
  }

  /// Reloads once after a 403, at most once per launch. `ApiCall` calls it
  /// for every `ApiForbiddenException`; the user still sees Core's default
  /// "no permission" message.
  void reloadAfterForbidden() {
    if (_ref.read(sessionProvider).value == null) return;
    if (_ref.read(sessionHooksProvider).loadPermissions == null) return;
    if (_forbiddenReloadUsed) return;
    _forbiddenReloadUsed = true;
    _log.info('Reloading permissions after a 403.');
    unawaited(_reload());
  }

  int get _generation => _ref.read(sessionGenerationProvider).value;

  /// Whether someone is signed in and it is still [generation]'s user.
  bool _isCurrent(int generation) =>
      _ref.read(sessionProvider).value != null && _generation == generation;

  Permissions? _resolve(Box<String>? box) {
    final int generation = _generation;
    final ({int generation, Permissions permissions})? loaded = _loaded;
    if (loaded != null && loaded.generation == generation) {
      return loaded.permissions;
    }
    final Permissions? saved = box == null ? null : _read(box);
    if (saved != null) {
      _loaded = (generation: generation, permissions: saved);
    }
    if (!_launchReloadStarted) {
      _launchReloadStarted = true;
      // Never during a provider build: a landed reload rebuilds it.
      scheduleMicrotask(() => unawaited(_reload()));
    }
    // Nothing saved: unknown until the reload lands.
    return saved;
  }

  void _forget() => _loaded = null;

  /// The reload in progress, or `null`. Tests await it to know a reload
  /// has landed, however long saving it takes.
  @visibleForTesting
  Future<void>? get reloading => _reloading;

  /// One reload at a time: a second caller joins the running one.
  Future<void> _reload() {
    return _reloading ??= _runReload().whenComplete(() => _reloading = null);
  }

  /// After every await it checks `_ref.mounted`: the provider is keep-alive
  /// and never rebuilt, so it is only disposed with its container (the app
  /// closing, a test ending). Nothing is left to update then; the reload
  /// stops instead of using the disposed [Ref].
  Future<void> _runReload() async {
    if (!_ref.mounted) return;
    final LoadPermissionsHook? hook = _ref
        .read(sessionHooksProvider)
        .loadPermissions;
    // The session as it is now: a refresh may have run since it was asked
    // for.
    final Session? session = _ref.read(sessionProvider).value;
    if (hook == null || session == null) return;
    final int generation = _generation;
    try {
      final Permissions permissions = await hook(session);
      if (!_ref.mounted) return;
      final Box<String> box = await _ref.read(sessionBoxProvider.future);
      if (!_ref.mounted) return;
      // Signed out (or in as someone else) meanwhile: drop the result. A
      // token refresh keeps it. Checked right before the write is issued,
      // and a sign-out marks itself before it clears the box, so the clear
      // always comes after this write.
      if (!_isCurrent(generation)) return;
      _loaded = (generation: generation, permissions: permissions);
      await _save(box, permissions);
      if (!_ref.mounted) return;
      if (_ref.read(sessionProvider).value == null) {
        // Signed out while it was written: never leave it on disk.
        await _delete(box);
      }
    } catch (error, stackTrace) {
      if (!_ref.mounted) return;
      _log.info('Reloading permissions failed; keeping the current list.');
      _reportUnhandled(error, stackTrace);
      // Nothing was known (a cold start with nothing saved): fail closed.
      if (_loaded?.generation != generation && _isCurrent(generation)) {
        _loaded = (generation: generation, permissions: Permissions.none);
      }
    }
    if (!_ref.mounted) return;
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

  Future<void> _delete(Box<String> box) async {
    try {
      await box.delete(permissionsKey);
    } catch (_) {
      // The box was deleted from disk instead of cleared; nothing is left.
      _log.warning('Permissions could not be deleted.');
    }
  }

  /// `ApiCall` has already handled an [ApiException]; anything else is
  /// reported here, since it fails no provider.
  void _reportUnhandled(Object error, StackTrace stackTrace) {
    if (error is ApiException) return;
    _ref.read(errorReporterProvider).report(error, stackTrace);
  }
}
