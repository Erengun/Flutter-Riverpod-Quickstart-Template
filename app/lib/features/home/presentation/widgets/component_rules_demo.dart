import 'package:core/core.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../router/app_router.dart';
import '../../../../shared/permission_keys.dart';

/// One control per Component rule the demo loader sends, each behind a
/// `PermissionGate`: email is readonly (shown, taps do nothing), edit
/// profile is disabled (greyed out) and delete account is hidden.
class ComponentRulesDemo extends StatelessWidget {
  const ComponentRulesDemo({super.key});

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final KonteynerTokens tokens = KonteynerTokens.of(context);
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: tokens.spaceMd),
      child: Wrap(
        spacing: tokens.spaceSm,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: <Widget>[
          Text(l10n.demoComponentRulesTitle),
          PermissionGate(
            componentKey: AppComponents.profileEmail,
            child: ActionChip(
              avatar: const Icon(Icons.email_outlined),
              label: Text(l10n.demoEmailReadonly),
              onPressed: () => context.push(SGRoute.profile.route),
            ),
          ),
          PermissionGate(
            componentKey: AppComponents.profileEdit,
            child: ActionChip(
              avatar: const Icon(Icons.edit_outlined),
              label: Text(l10n.demoEditProfileDisabled),
              onPressed: () => context.push(SGRoute.profile.route),
            ),
          ),
          PermissionGate(
            componentKey: AppComponents.settingsDeleteAccount,
            child: ActionChip(
              avatar: const Icon(Icons.delete_outline),
              label: Text(l10n.demoDeleteAccountHidden),
              onPressed: () => context.push(SGRoute.settings.route),
            ),
          ),
        ],
      ),
    );
  }
}
