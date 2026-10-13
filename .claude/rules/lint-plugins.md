---
paths:
  - "packages/app_lints/**"
  - "analysis_options.yaml"
  - "lint_rules.yaml"
---

# Analyzer plugins

**Analyzer plugins.** The root `analysis_options.yaml` loads two plugins: `riverpod_lint` and `packages/app_lints`. `app_lints` holds the template's architecture rules (currently `no_cross_feature_imports`, `tokens_only_in_theme`, `no_set_state`, `no_shrink_wrap`, `no_widget_functions`, `ui_no_data_imports`, `ui_no_backend_providers` and `no_fake_imports`) and the app's own, split by owner: the template owns `lib/main.dart`, `lib/src/template/` and its `registerTemplateRules`; the app owns `lib/app_rules.dart` (`registerAppRules`, shipped empty) and `lib/src/app/`, where a Company copy or a Derived app adds its rules without editing template files. It is referenced by `path:`, is not a workspace member (it has its own `pubspec.lock`) and reports in every package that includes the root options. Notes:
- Only `dart analyze` runs plugins; `flutter analyze` does not, so a clean `flutter analyze` alone proves nothing for plugin rules. The Melos `analyze` script runs both.
- Rule tests use `analyzer_testing` (`AnalysisRuleTest`, see `packages/app_lints/test/template/`). Run them with `dart run melos run test:lints` (also part of `melos run test`); `melos run analyze:lints` analyzes the plugin package (also part of `melos run analyze`).
- `analysis_server_plugin` is 0.x and pinned to an exact version, with `analyzer` pinned to the version it requires. Bump both together. After changing a plugin, restart the analysis server (or rerun `dart analyze`) to pick it up.
