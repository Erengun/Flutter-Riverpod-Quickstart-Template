import 'package:analysis_server_plugin/plugin.dart';
import 'package:analysis_server_plugin/registry.dart';

/// Entry point the analysis server loads for this plugin.
final AppLintsPlugin plugin = AppLintsPlugin();

/// The app's own analyzer rules. It ships empty: register rules here with
/// `registry.registerWarningRule(...)`, following packages/konteyner_lints.
class AppLintsPlugin extends Plugin {
  @override
  String get name => 'app_lints';

  @override
  void register(PluginRegistry registry) {}
}
