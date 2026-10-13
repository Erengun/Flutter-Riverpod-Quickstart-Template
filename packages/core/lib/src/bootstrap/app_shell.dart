import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// The app's light and dark themes. The app builds them and passes them to
/// `bootstrap`; `MaterialApp` reads them from [coreThemeProvider].
class CoreTheme {
  const CoreTheme({required this.light, required this.dark});

  /// Material's default light and dark themes.
  factory CoreTheme.fallback() =>
      CoreTheme(light: ThemeData.light(), dark: ThemeData.dark());

  final ThemeData light;
  final ThemeData dark;
}

/// The theme passed to `bootstrap`. Defaults to Material's own themes so
/// tests work without an override.
final Provider<CoreTheme> coreThemeProvider =
    Provider<CoreTheme>(
      (Ref ref) => CoreTheme.fallback(),
      name: 'coreThemeProvider',
    );

/// Core's default splash: a centered progress indicator.
class CoreSplash extends StatelessWidget {
  const CoreSplash({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}

/// The splash widget passed to `bootstrap`, or [CoreSplash].
final Provider<Widget> splashProvider = Provider<Widget>(
  (Ref ref) => const CoreSplash(),
  name: 'splashProvider',
);
