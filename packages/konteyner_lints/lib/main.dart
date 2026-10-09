import 'package:analysis_server_plugin/plugin.dart';
import 'package:analysis_server_plugin/registry.dart';

import 'src/no_cross_feature_imports.dart';

/// Entry point the analysis server loads for this plugin.
final KonteynerLintsPlugin plugin = KonteynerLintsPlugin();

/// Architecture rules owned by the template.
class KonteynerLintsPlugin extends Plugin {
  @override
  String get name => 'konteyner_lints';

  @override
  void register(PluginRegistry registry) {
    // Warning rules are on by default in every package that enables the plugin.
    registry.registerWarningRule(NoCrossFeatureImports());
  }
}
