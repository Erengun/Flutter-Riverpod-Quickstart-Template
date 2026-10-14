import 'package:flutter_riverpod_template/app/theme.dart';
import 'package:flutter_riverpod_template/shared/widgets/grid_item.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ionicons/ionicons.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  // The theme starts loading the bundled fonts, which needs the binding.
  TestWidgetsFlutterBinding.ensureInitialized();
  final ThemeData theme = buildAppTheme().light;

  Future<void> pumpItem(WidgetTester tester, {String? version}) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: Scaffold(
          body: SizedBox(
            width: 200,
            height: 200,
            child: GridItem(
              title: 'Riverpod',
              icon: Ionicons.logoGithub,
              url: Uri.parse('https://riverpod.dev'),
              version: version,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows the icon and the title', (WidgetTester tester) async {
    await pumpItem(tester);

    expect(find.byIcon(Ionicons.logoGithub), findsOneWidget);
    expect(find.text('Riverpod'), findsOneWidget);
    expect(
      tester.widget<Icon>(find.byIcon(Ionicons.logoGithub)).color,
      theme.colorScheme.primary,
    );
  });

  testWidgets('shows the version only when given', (WidgetTester tester) async {
    await pumpItem(tester, version: '3.0.0');
    expect(find.text('3.0.0'), findsOneWidget);

    await pumpItem(tester);
    expect(find.text('3.0.0'), findsNothing);
  });
}
