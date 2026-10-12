import 'package:material_ui/material_ui.dart';

import 'konteyner_upgrader_messages.dart';

/// The force-update dialog that `KonteynerUpdateGate` shows, built from
/// material_ui so it follows the app's theme. Its text comes from Core's
/// localizations in the current locale (the device's when there is no
/// `Localizations` above it; English when Core has no strings for it).
///
/// The gate shows it as a dialog route that can't be dismissed; it is public
/// so a widget catalog can show it on its own.
///
/// - [updateRequired] (hard update): the required body and only Update.
/// - Otherwise (soft update): the optional body with Ignore, Later and Update.
class KonteynerUpdateDialog extends StatelessWidget {
  const KonteynerUpdateDialog({
    required this.updateRequired,
    required this.onUpdate,
    this.onIgnore,
    this.onLater,
    this.title,
    this.message,
    super.key,
  });

  /// Whether this is a hard update (below the minimum version).
  final bool updateRequired;

  /// Runs when the user taps Update.
  final VoidCallback onUpdate;

  /// Runs when the user taps Ignore (soft update only).
  final VoidCallback? onIgnore;

  /// Runs when the user taps Later (soft update only).
  final VoidCallback? onLater;

  /// Replaces Core's title.
  final String? title;

  /// Replaces Core's body.
  final String? message;

  @override
  Widget build(BuildContext context) {
    final KonteynerUpgraderMessages messages =
        KonteynerUpgraderMessages.forLocale(
          Localizations.maybeLocaleOf(context) ??
              WidgetsBinding.instance.platformDispatcher.locale,
          updateRequired: updateRequired,
        );
    return AlertDialog(
      title: Text(
        title ?? messages.title,
        key: const Key('upgrader.dialog.title'),
      ),
      content: SingleChildScrollView(child: Text(message ?? messages.body)),
      actions: <Widget>[
        if (!updateRequired) ...<Widget>[
          TextButton(
            onPressed: onIgnore,
            child: Text(messages.buttonTitleIgnore),
          ),
          TextButton(
            onPressed: onLater,
            child: Text(messages.buttonTitleLater),
          ),
        ],
        TextButton(
          onPressed: onUpdate,
          child: Text(messages.buttonTitleUpdate),
        ),
      ],
    );
  }
}
