import 'package:analysis_server_plugin/registry.dart';

import 'no_cross_feature_imports.dart';
import 'tokens_only_in_theme.dart';

/// Registers the template's architecture rules. The template owns this file.
void registerTemplateRules(PluginRegistry registry) {
  // Warning rules are on by default in every package that enables the plugin.
  registry
    ..registerWarningRule(NoCrossFeatureImports())
    ..registerWarningRule(TokensOnlyInTheme());
}
