import 'package:analysis_server_plugin/registry.dart';

import 'no_cross_feature_imports.dart';
import 'no_fake_imports.dart';
import 'no_set_state.dart';
import 'no_shrink_wrap.dart';
import 'no_widget_functions.dart';
import 'tokens_only_in_theme.dart';
import 'ui_no_backend_providers.dart';
import 'ui_no_data_imports.dart';

/// Registers the template's architecture rules. The template owns this file.
void registerTemplateRules(PluginRegistry registry) {
  // Warning rules are on by default in every package that enables the plugin.
  registry
    ..registerWarningRule(NoCrossFeatureImports())
    ..registerWarningRule(TokensOnlyInTheme())
    ..registerWarningRule(NoSetState())
    ..registerWarningRule(NoShrinkWrap())
    ..registerWarningRule(NoWidgetFunctions())
    ..registerWarningRule(UiNoDataImports())
    ..registerWarningRule(UiNoBackendProviders())
    ..registerWarningRule(NoFakeImports());
}
