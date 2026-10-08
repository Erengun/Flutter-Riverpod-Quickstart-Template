import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ionicons/ionicons.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../../config/theme/theme_logic.dart';

class ThemeWidget extends ConsumerWidget {
  const ThemeWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.all(15),
          child: Text(
            tr('toggle_theme'),
            style: Theme.of(
              context,
            ).textTheme.titleMedium!.apply(fontWeightDelta: 2),
          ),
        ),
        const Spacer(),
        SegmentedButton<ThemeMode>(
          showSelectedIcon: false,
          selected: <ThemeMode>{ref.watch(themeLogicProvider).themeMode},
          segments: const <ButtonSegment<ThemeMode>>[
            ButtonSegment<ThemeMode>(
              icon: Icon(Ionicons.sunnyOutline),
              value: ThemeMode.light,
            ),
            ButtonSegment<ThemeMode>(
              icon: Icon(Ionicons.phonePortraitOutline),
              value: ThemeMode.system,
            ),
            ButtonSegment<ThemeMode>(
              icon: Icon(Ionicons.moonOutline),
              value: ThemeMode.dark,
            ),
          ],
          onSelectionChanged: (Set<ThemeMode> theme) =>
              ref.read(themeLogicProvider.notifier).setThemeMode(theme.first),
        ),
      ],
    );
  }
}
