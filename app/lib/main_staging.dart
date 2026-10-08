import 'package:core/core.dart';

import 'app/config.dart';
import 'app/modules.dart';
import 'app/setup.dart';
import 'app/theme.dart';

Future<void> main() async {
  await setUpApp();
  await bootstrap(
    stagingConfig,
    app: buildAppRoot(),
    theme: buildAppTheme(),
    modules: buildAppModules(),
  );
}
