import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class LanguageTile extends StatelessWidget {
  const LanguageTile({super.key});

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      onChanged: (bool newValue) {
        /// Example: Change locale
        /// The initial locale is automatically determined by the library.
        /// Changing the locale like this will persist the selected locale.
        context.setLocale(newValue ? const Locale('tr') : const Locale('en'));
      },
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
      value: context.locale == const Locale('tr'),
      title: Text(
        tr('toggle_language'),
        style: Theme.of(
          context,
        ).textTheme.titleMedium!.apply(fontWeightDelta: 2),
      ),
    );
  }
}
