import 'package:core/core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'app/l10n.dart';
import 'l10n/app_localizations.dart';
import 'router/app_router.dart';

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final GoRouter router = ref.watch(goRouterProvider);
    final KonteynerTheme theme = ref.watch(konteynerThemeProvider);
    return MaterialApp.router(
      routerConfig: router,
      onGenerateTitle: (BuildContext context) =>
          AppLocalizations.of(context).appTitle,
      theme: theme.light,
      darkTheme: theme.dark,
      themeMode: ref.watch(themeModeProvider),
      debugShowCheckedModeBanner: false,
      localizationsDelegates: appLocalizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: ref.watch(localeProvider),
    );
  }
}
