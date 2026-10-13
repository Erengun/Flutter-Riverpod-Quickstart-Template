import 'package:flutter_riverpod_template/app/theme.dart';
import 'package:flutter_riverpod_template/shared/widgets/link_card.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ionicons/ionicons.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  // The theme starts loading the bundled fonts, which needs the binding.
  TestWidgetsFlutterBinding.ensureInitialized();
  final ThemeData theme = buildAppTheme().light;

  testWidgets('shows the icon, the title and the open-link icon', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: Scaffold(
          body: LinkCard(
            title: 'Github',
            icon: Ionicons.logoGithub,
            url: Uri.parse('https://github.com/erengun'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Github'), findsOneWidget);
    expect(find.byIcon(Ionicons.logoGithub), findsOneWidget);
    expect(find.byIcon(Ionicons.openOutline), findsOneWidget);
    expect(
      tester.widget<Icon>(find.byIcon(Ionicons.logoGithub)).color,
      theme.colorScheme.primary,
    );
    // Tapping opens the link through url_launcher.
    expect(tester.widget<ListTile>(find.byType(ListTile)).onTap, isNotNull);
  });
}
