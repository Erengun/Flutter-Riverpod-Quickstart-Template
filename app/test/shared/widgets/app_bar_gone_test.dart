import 'package:flutter/services.dart';
import 'package:flutter_riverpod_template/app/theme.dart';
import 'package:flutter_riverpod_template/shared/widgets/app_bar_gone.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  // The theme starts loading the bundled fonts, which needs the binding.
  TestWidgetsFlutterBinding.ensureInitialized();
  final ThemeData light = buildAppTheme().light;
  final ThemeData dark = buildAppTheme().dark;

  Future<SystemUiOverlayStyle> pumpBar(
    WidgetTester tester,
    ThemeData theme,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: const Scaffold(appBar: EmptyAppBar(), body: Text('Content')),
      ),
    );
    await tester.pumpAndSettle();
    return tester.widget<AppBar>(find.byType(AppBar)).systemOverlayStyle!;
  }

  test('takes no height', () {
    expect(const EmptyAppBar().preferredSize.height, 0);
  });

  testWidgets('dark status bar icons on a light theme', (
    WidgetTester tester,
  ) async {
    final SystemUiOverlayStyle style = await pumpBar(tester, light);

    expect(style.statusBarIconBrightness, Brightness.dark);
    expect(style.statusBarColor, light.colorScheme.surface);
    expect(find.text('Content'), findsOneWidget);
  });

  testWidgets('light status bar icons on a dark theme', (
    WidgetTester tester,
  ) async {
    final SystemUiOverlayStyle style = await pumpBar(tester, dark);

    expect(style.statusBarIconBrightness, Brightness.light);
    expect(style.statusBarColor, dark.colorScheme.surface);
  });
}
