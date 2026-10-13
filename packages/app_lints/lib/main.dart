import 'package:analysis_server_plugin/plugin.dart';
import 'package:analysis_server_plugin/registry.dart';

import 'app_rules.dart';
import 'src/template/template_rules.dart';

/// Entry point the analysis server loads for this plugin.
final AppLintsPlugin plugin = AppLintsPlugin();

/// The template's architecture rules plus the app's own.
///
/// The template owns this file and `src/template/`. A Company copy or a
/// Derived app adds its rules in `app_rules.dart` (and `src/app/`), never
/// here, so template updates merge without conflicts.
class AppLintsPlugin extends Plugin {
  @override
  String get name => 'app_lints';

  @override
  void register(PluginRegistry registry) {
    registerTemplateRules(registry);
    registerAppRules(registry);
  }
}
