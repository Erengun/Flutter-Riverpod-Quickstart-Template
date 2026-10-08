import 'package:material_ui/material_ui.dart';

/// Extension for BuildContext to get theme, textTheme and colorScheme
extension BuildContextExtensions on BuildContext {
  ThemeData get theme => Theme.of(this);
  TextTheme get textTheme => theme.textTheme;
  ColorScheme get colorScheme => theme.colorScheme;
}
