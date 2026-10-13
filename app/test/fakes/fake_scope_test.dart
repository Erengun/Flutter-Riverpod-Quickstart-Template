import 'package:flutter_riverpod_template/app/l10n.dart';
import 'package:flutter_riverpod_template/app/theme.dart';
import 'package:flutter_riverpod_template/fakes/fake_scope.dart';
import 'package:flutter_riverpod_template/features/authentication/presentation/login/login_screen.dart';
import 'package:flutter_riverpod_template/features/demo/presentation/demo_area_screen.dart';
import 'package:flutter_riverpod_template/features/home/presentation/home_screen.dart';
import 'package:flutter_riverpod_template/l10n/app_localizations.dart';
import 'package:flutter_riverpod_template/shared/permission_keys.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  // The theme starts loading the bundled fonts, which needs the binding.
  TestWidgetsFlutterBinding.ensureInitialized();
  final ThemeData theme = buildAppTheme().light;

  /// Every screen, as `FakeScope(child: ...)` with no other arguments.
  final Map<Type, Widget> screens = <Type, Widget>{
    LoginScreen: const LoginScreen(),
    HomeScreen: const HomeScreen(),
    DemoAreaScreen: const DemoAreaScreen(
      title: 'Orders',
      area: AppAreas.orders,
    ),
  };

  for (final MapEntry<Type, Widget> screen in screens.entries) {
    testWidgets('renders ${screen.key} with no other arguments', (
      WidgetTester tester,
    ) async {
      tester.view
        ..physicalSize = const Size(1080, 2340)
        ..devicePixelRatio = 2;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: appLocalizationsDelegates,
          home: FakeScope(child: screen.value),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(screen.key), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
