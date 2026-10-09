import 'package:core/core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../l10n/app_localizations.dart';

class LanguageTile extends ConsumerWidget {
  const LanguageTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SwitchListTile(
      onChanged: (bool newValue) {
        /// Example: change the locale. Until the user picks one the app
        /// follows the device; the choice is saved and survives a restart.
        ref
            .read(localeProvider.notifier)
            .set(newValue ? const Locale('tr') : const Locale('en'));
      },
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
      value: Localizations.localeOf(context).languageCode == 'tr',
      title: Text(
        AppLocalizations.of(context).homeToggleLanguage,
        style: Theme.of(
          context,
        ).textTheme.titleMedium!.apply(fontWeightDelta: 2),
      ),
    );
  }
}
