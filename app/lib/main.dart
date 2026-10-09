import 'package:core/core.dart';

import 'app/config.dart';
import 'app/modules.dart';
import 'app/overrides.dart';
import 'app/setup.dart';
import 'app/theme.dart';

/// Bare `main.dart` means dev, matching `default-flavor: dev` in the
/// pubspec, so a plain `flutter run` never points at prod.
Future<void> main() async {
  await setUpApp();
  await bootstrap(
    devConfig,
    app: buildAppRoot(),
    theme: buildAppTheme(),
    modules: buildAppModules(),
    overrides: buildAppOverrides(),
  );
}
