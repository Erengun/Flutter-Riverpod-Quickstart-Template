import 'package:core/core.dart';
import 'package:material_ui/material_ui.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

/// The force-update dialog over a scrim, as `KonteynerUpdateGate` shows it.
/// The gate never checks on web, so the catalog shows the dialog itself.
Widget _overScrim(BuildContext context, Widget dialog) {
  return Scaffold(
    backgroundColor: Theme.of(context).colorScheme.scrim.withValues(alpha: 0.5),
    body: dialog,
  );
}

/// Hard update (below the minimum version): only Update, and the gate never
/// lets it be dismissed.
@widgetbook.UseCase(
  name: 'Blocking',
  type: KonteynerUpdateDialog,
  path: '[Core]/update',
)
Widget buildBlockingUpdateDialog(BuildContext context) {
  return _overScrim(
    context,
    KonteynerUpdateDialog(updateRequired: true, onUpdate: () {}),
  );
}

/// Soft update (below the recommended version): Ignore, Later and Update.
@widgetbook.UseCase(
  name: 'Dismissible',
  type: KonteynerUpdateDialog,
  path: '[Core]/update',
)
Widget buildDismissibleUpdateDialog(BuildContext context) {
  return _overScrim(
    context,
    KonteynerUpdateDialog(
      updateRequired: false,
      onUpdate: () {},
      onIgnore: () {},
      onLater: () {},
    ),
  );
}
