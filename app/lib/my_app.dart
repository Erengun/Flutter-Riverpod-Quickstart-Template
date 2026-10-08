import 'package:core/core.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'config/theme/theme_logic.dart';
import 'config/theme/theme_ui_model.dart';
import 'constants/strings.dart';
import 'router/app_router.dart';

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeUiModel currentTheme = ref.watch(themeLogicProvider);
    final GoRouter router = ref.watch(goRouterProvider);
    final KonteynerTheme theme = ref.watch(konteynerThemeProvider);
    return MaterialApp.router(
      routerConfig: router,

      /// A plain constant until the title comes from the translations.
      title: Strings.appName,

      theme: theme.light,
      darkTheme: theme.dark,
      themeMode: currentTheme.themeMode,
      debugShowCheckedModeBanner: false,
      localizationsDelegates: appLocalizationsDelegates(
        context.localizationDelegates,
      ),
      supportedLocales: context.supportedLocales,
      locale: context.locale,
    );
  }
}

/// Localization delegates for the app.
///
/// easy_localization only ships flutter_localizations delegates, which
/// material_ui widgets cannot see, so material_ui's own delegates are added.
List<LocalizationsDelegate<Object?>> appLocalizationsDelegates(
  Iterable<LocalizationsDelegate<Object?>> baseDelegates,
) {
  return <LocalizationsDelegate<Object?>>[
    ...baseDelegates,
    ...GlobalMaterialLocalizations.delegates,
  ];
}
