import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:logging/logging.dart';
import 'package:material_ui/material_ui.dart';
import 'package:upgrader/upgrader.dart';

import '../config/app_config.dart';
import '../config/konteyner_platform.dart';
import '../reporting/remote_flags.dart';
import 'app_version_source.dart';
import 'konteyner_upgrader_messages.dart';
import 'konteyner_upgrader_store.dart';
import 'update_dialog.dart';

final Logger _log = Logger('update');

/// Force update: shows the update dialog over the whole app when the
/// installed version is below the minimum or recommended app version.
///
/// Place it in `MaterialApp.router`'s `builder` with the router's navigator
/// key:
///
/// ```dart
/// builder: (BuildContext context, Widget? child) => KonteynerUpdateGate(
///   navigatorKey: router.configuration.navigatorKey,
///   child: child ?? const SizedBox.shrink(),
/// ),
/// ```
///
/// - **Hard update** (below the minimum): only Update; back and outside taps
///   do nothing.
/// - **Soft update** (below the recommended): Update, Ignore and Later.
///   Ignore silences that version until a newer one is offered; Later shows
///   it again after three days.
/// - **Update:** on Android a hard update starts Play's immediate in-app
///   update and falls back to the store link; everywhere else the link from
///   [AppConfig.storeLinks] opens.
/// - An empty store link turns the check off on that platform; web is never
///   checked.
/// - Startup never waits on a fetch: the cached values are checked straight
///   away while `RemoteFlags.refresh` runs in the background. The check runs
///   again when the app resumes and whenever `RemoteFlags.onChanged` emits.
///   A failed check lets the user in.
class KonteynerUpdateGate extends ConsumerStatefulWidget {
  const KonteynerUpdateGate({
    super.key,
    required this.navigatorKey,
    required this.child,
  });

  /// The router's root navigator key; the dialog is shown on that navigator.
  final GlobalKey<NavigatorState> navigatorKey;

  /// The app below the dialog.
  final Widget child;

  @override
  ConsumerState<KonteynerUpdateGate> createState() =>
      _KonteynerUpdateGateState();
}

class _KonteynerUpdateGateState extends ConsumerState<KonteynerUpdateGate> {
  late final KonteynerPlatform _platform;
  _KonteynerUpgrader? _upgrader;
  StreamSubscription<void>? _flagChanges;

  @override
  void initState() {
    super.initState();
    _platform = KonteynerPlatform.current;
    final String storeLink = ref
        .read(appConfigProvider)
        .storeLinks
        .linkFor(_platform);
    if (storeLink.isEmpty) return;

    final _KonteynerUpgrader upgrader = _KonteynerUpgrader(
      KonteynerUpgraderStore(
        source: ref.read(appVersionSourceProvider),
        platform: _platform,
        storeLink: storeLink,
      ),
    );
    _upgrader = upgrader;

    final RemoteFlags flags = ref.read(remoteFlagsProvider);
    _flagChanges = flags.onChanged.listen(
      (_) => unawaited(upgrader.updateVersionInfo()),
      onError: (Object error, StackTrace stackTrace) => _log.warning(
        'RemoteFlags.onChanged failed; keeping the current values.',
        error,
        stackTrace,
      ),
    );
    unawaited(_refresh(flags, upgrader));
  }

  Future<void> _refresh(RemoteFlags flags, Upgrader upgrader) async {
    try {
      await flags.refresh();
    } catch (error, stackTrace) {
      _log.warning(
        'Refreshing RemoteFlags failed; using the cached values.',
        error,
        stackTrace,
      );
      return;
    }
    if (!mounted) return;
    await upgrader.updateVersionInfo();
  }

  /// Android hard update: Play's immediate in-app update, then the store
  /// link if that can't run. Returns `false` to skip upgrader's own launch.
  bool _onUpdate() {
    final _KonteynerUpgrader? upgrader = _upgrader;
    if (upgrader == null ||
        _platform != KonteynerPlatform.android ||
        !upgrader.blocked()) {
      return true;
    }
    unawaited(_immediateUpdate(upgrader));
    return false;
  }

  Future<void> _immediateUpdate(Upgrader upgrader) async {
    try {
      final AppUpdateInfo info = await InAppUpdate.checkForUpdate();
      if (info.updateAvailability == UpdateAvailability.updateAvailable &&
          info.immediateUpdateAllowed) {
        final AppUpdateResult result =
            await InAppUpdate.performImmediateUpdate();
        // Declining leaves the user on the dialog, which they can't dismiss.
        if (result != AppUpdateResult.inAppUpdateFailed) return;
      }
    } catch (error, stackTrace) {
      _log.warning(
        'Play in-app update failed; opening the store link.',
        error,
        stackTrace,
      );
    }
    await upgrader.sendUserToAppStore();
  }

  @override
  void dispose() {
    unawaited(_flagChanges?.cancel());
    _upgrader?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final _KonteynerUpgrader? upgrader = _upgrader;
    if (upgrader == null) return widget.child;
    return _KonteynerUpgradeAlert(
      upgrader: upgrader,
      navigatorKey: widget.navigatorKey,
      onUpdate: _onUpdate,
      child: widget.child,
    );
  }
}

/// An [Upgrader] that only asks [KonteynerUpgraderStore] and reads its text
/// from Core's localizations.
class _KonteynerUpgrader extends Upgrader {
  _KonteynerUpgrader(UpgraderStore store)
    : super(
        storeController: UpgraderStoreController(
          onAndroid: () => store,
          oniOS: () => store,
          onMacOS: () => store,
          onWindows: () => store,
          onLinux: () => store,
        ),
      );

  @override
  UpgraderMessages determineMessages(BuildContext context) {
    return KonteynerUpgraderMessages.forLocale(
      findLocale(context: context),
      updateRequired: blocked(),
    );
  }
}

/// upgrader's [UpgradeAlert] with the dialog built from material_ui, so it
/// follows the app's theme.
class _KonteynerUpgradeAlert extends UpgradeAlert {
  _KonteynerUpgradeAlert({
    required Upgrader super.upgrader,
    required GlobalKey<NavigatorState> super.navigatorKey,
    required BoolCallback super.onUpdate,
    required Widget super.child,
  }) : super(showPrompt: false, showReleaseNotes: false);

  @override
  UpgradeAlertState createState() => _KonteynerUpgradeAlertState();
}

class _KonteynerUpgradeAlertState extends UpgradeAlertState {
  @override
  void showTheDialog({
    Key? key,
    required BuildContext context,
    required String? title,
    required String message,
    required String? releaseNotes,
    required bool barrierDismissible,
    required UpgraderMessages messages,
  }) {
    if (!context.mounted) return;
    unawaited(widget.upgrader.saveLastAlerted());
    unawaited(
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext dialogContext) => PopScope<void>(
          canPop: false,
          child: alertDialog(
            key,
            title ?? '',
            message,
            null,
            dialogContext,
            false,
            messages,
          ),
        ),
      ),
    );
  }

  @override
  Widget alertDialog(
    Key? key,
    String title,
    String message,
    String? releaseNotes,
    BuildContext context,
    bool cupertino,
    UpgraderMessages messages,
  ) {
    return KonteynerUpdateDialog(
      key: key,
      updateRequired: widget.upgrader.blocked(),
      title: title,
      message: message,
      onUpdate: () => onUserUpdated(context, !widget.upgrader.blocked()),
      onIgnore: () => onUserIgnored(context, true),
      onLater: () => onUserLater(context, true),
    );
  }
}
