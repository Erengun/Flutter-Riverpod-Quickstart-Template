import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// The app's light and dark themes. The app builds them and passes them to
/// `bootstrap`; `MaterialApp` reads them from [konteynerThemeProvider].
class KonteynerTheme {
  const KonteynerTheme({required this.light, required this.dark});

  /// Material's default light and dark themes.
  factory KonteynerTheme.fallback() =>
      KonteynerTheme(light: ThemeData.light(), dark: ThemeData.dark());

  final ThemeData light;
  final ThemeData dark;
}

/// The theme passed to `bootstrap`. Defaults to Material's own themes so
/// tests work without an override.
final Provider<KonteynerTheme> konteynerThemeProvider =
    Provider<KonteynerTheme>(
      (Ref ref) => KonteynerTheme.fallback(),
      name: 'konteynerThemeProvider',
    );

/// Core's default splash: a centered progress indicator.
class KonteynerSplash extends StatelessWidget {
  const KonteynerSplash({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}

/// The splash widget passed to `bootstrap`, or [KonteynerSplash].
final Provider<Widget> splashProvider = Provider<Widget>(
  (Ref ref) => const KonteynerSplash(),
  name: 'splashProvider',
);
