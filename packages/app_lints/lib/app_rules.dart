import 'package:analysis_server_plugin/registry.dart';

/// Registers the app's own rules. The app owns this file and ships it empty:
/// add rules under `src/app/` and register them here with
/// `registry.registerWarningRule(...)`, following `src/template/`.
void registerAppRules(PluginRegistry registry) {}
