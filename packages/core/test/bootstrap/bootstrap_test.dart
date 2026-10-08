import 'package:core/core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

const AppConfig _config = AppConfig(
  flavor: Flavor.staging,
  apiBaseUrl: 'https://example.com/',
  apiKey: 'demo',
);

class _ProbeApp extends ConsumerWidget {
  const _ProbeApp();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppConfig config = ref.watch(appConfigProvider);
    final KonteynerTheme theme = ref.watch(konteynerThemeProvider);
    return MaterialApp(
      theme: theme.light,
      home: Column(
        children: <Widget>[Text(config.flavor.name), ref.watch(splashProvider)],
      ),
    );
  }
}

void main() {
  final StackTrace Function(StackTrace) originalDemangle =
      FlutterError.demangleStackTrace;

  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
    FlutterError.demangleStackTrace = originalDemangle;
  });

  testWidgets('runs the app with the config, theme and splash overridden', (
    WidgetTester tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    final KonteynerTheme theme = KonteynerTheme(
      light: ThemeData(colorSchemeSeed: Colors.teal),
      dark: ThemeData.dark(),
    );

    await bootstrap(
      _config,
      app: const _ProbeApp(),
      theme: theme,
      splash: const Text('custom splash'),
    );
    await tester.pump();

    expect(find.text('staging'), findsOneWidget);
    expect(find.text('custom splash'), findsOneWidget);
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets(
    'throws before runApp when the native flavor differs on Android',
    (WidgetTester tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;

      // Tests run without --flavor, so the native flavor is null.
      await expectLater(
        bootstrap(
          _config,
          app: const _ProbeApp(),
          theme: KonteynerTheme.fallback(),
        ),
        throwsA(isA<FlavorMismatchError>()),
      );
      await tester.pump();

      expect(find.byType(_ProbeApp), findsNothing);
      debugDefaultTargetPlatformOverride = null;
    },
  );
}
