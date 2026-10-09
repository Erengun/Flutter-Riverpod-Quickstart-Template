import 'package:core/core.dart';

import 'app/config.dart';
import 'app/modules.dart';
import 'app/overrides.dart';
import 'app/setup.dart';
import 'app/theme.dart';

Future<void> main() => runGuarded(() async {
  await setUpApp();
  await bootstrap(
    prodConfig,
    app: buildAppRoot(),
    theme: buildAppTheme(),
    modules: buildAppModules(),
    overrides: buildAppOverrides(),
  );
});
