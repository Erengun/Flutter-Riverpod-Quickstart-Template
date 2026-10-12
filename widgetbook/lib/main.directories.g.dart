// dart format width=80
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_import, prefer_relative_imports, directives_ordering

// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AppGenerator
// **************************************************************************

// ignore_for_file: no_leading_underscores_for_library_prefixes

import 'package:widgetbook/widgetbook.dart' as _widgetbook;
import 'package:widgetbook_catalog/app/features/authentication/presentation/login/login_screen.use_cases.dart'
    as _widgetbook_catalog_app_features_authentication_presentation_login_login_screen_use_cases;
import 'package:widgetbook_catalog/app/features/home/presentation/home_screen.use_cases.dart'
    as _widgetbook_catalog_app_features_home_presentation_home_screen_use_cases;
import 'package:widgetbook_catalog/core/api_error_ui.use_cases.dart'
    as _widgetbook_catalog_core_api_error_ui_use_cases;
import 'package:widgetbook_catalog/core/no_permission_page.use_cases.dart'
    as _widgetbook_catalog_core_no_permission_page_use_cases;
import 'package:widgetbook_catalog/core/permission_gate.use_cases.dart'
    as _widgetbook_catalog_core_permission_gate_use_cases;
import 'package:widgetbook_catalog/core/under_construction_page.use_cases.dart'
    as _widgetbook_catalog_core_under_construction_page_use_cases;
import 'package:widgetbook_catalog/core/update_dialog.use_cases.dart'
    as _widgetbook_catalog_core_update_dialog_use_cases;

final directories = <_widgetbook.WidgetbookNode>[
  _widgetbook.WidgetbookCategory(
    name: 'App',
    children: [
      _widgetbook.WidgetbookFolder(
        name: 'authentication',
        children: [
          _widgetbook.WidgetbookComponent(
            name: 'LoginScreen',
            useCases: [
              _widgetbook.WidgetbookUseCase(
                name: 'Login fails',
                builder:
                    _widgetbook_catalog_app_features_authentication_presentation_login_login_screen_use_cases
                        .buildLoginScreenFailing,
              ),
              _widgetbook.WidgetbookUseCase(
                name: 'Remembered credentials',
                builder:
                    _widgetbook_catalog_app_features_authentication_presentation_login_login_screen_use_cases
                        .buildLoginScreenRemembered,
              ),
              _widgetbook.WidgetbookUseCase(
                name: 'Signed out',
                builder:
                    _widgetbook_catalog_app_features_authentication_presentation_login_login_screen_use_cases
                        .buildLoginScreen,
              ),
            ],
          ),
        ],
      ),
      _widgetbook.WidgetbookFolder(
        name: 'home',
        children: [
          _widgetbook.WidgetbookComponent(
            name: 'HomeScreen',
            useCases: [
              _widgetbook.WidgetbookUseCase(
                name: 'Demo permissions',
                builder:
                    _widgetbook_catalog_app_features_home_presentation_home_screen_use_cases
                        .buildHomeScreen,
              ),
            ],
          ),
        ],
      ),
    ],
  ),
  _widgetbook.WidgetbookCategory(
    name: 'Core',
    children: [
      _widgetbook.WidgetbookFolder(
        name: 'network',
        children: [
          _widgetbook.WidgetbookComponent(
            name: 'ApiErrorView',
            useCases: [
              _widgetbook.WidgetbookUseCase(
                name: 'business',
                builder: _widgetbook_catalog_core_api_error_ui_use_cases
                    .buildBusinessError,
              ),
              _widgetbook.WidgetbookUseCase(
                name: 'cancelled',
                builder: _widgetbook_catalog_core_api_error_ui_use_cases
                    .buildCancelledError,
              ),
              _widgetbook.WidgetbookUseCase(
                name: 'connection',
                builder: _widgetbook_catalog_core_api_error_ui_use_cases
                    .buildConnectionError,
              ),
              _widgetbook.WidgetbookUseCase(
                name: 'decode',
                builder: _widgetbook_catalog_core_api_error_ui_use_cases
                    .buildDecodeError,
              ),
              _widgetbook.WidgetbookUseCase(
                name: 'forbidden',
                builder: _widgetbook_catalog_core_api_error_ui_use_cases
                    .buildForbiddenError,
              ),
              _widgetbook.WidgetbookUseCase(
                name: 'notFound',
                builder: _widgetbook_catalog_core_api_error_ui_use_cases
                    .buildNotFoundError,
              ),
              _widgetbook.WidgetbookUseCase(
                name: 'server',
                builder: _widgetbook_catalog_core_api_error_ui_use_cases
                    .buildServerError,
              ),
              _widgetbook.WidgetbookUseCase(
                name: 'timeout',
                builder: _widgetbook_catalog_core_api_error_ui_use_cases
                    .buildTimeoutError,
              ),
              _widgetbook.WidgetbookUseCase(
                name: 'unauthorized',
                builder: _widgetbook_catalog_core_api_error_ui_use_cases
                    .buildUnauthorizedError,
              ),
              _widgetbook.WidgetbookUseCase(
                name: 'unknown',
                builder: _widgetbook_catalog_core_api_error_ui_use_cases
                    .buildUnknownError,
              ),
            ],
          ),
        ],
      ),
      _widgetbook.WidgetbookFolder(
        name: 'permissions',
        children: [
          _widgetbook.WidgetbookComponent(
            name: 'NoPermissionPage',
            useCases: [
              _widgetbook.WidgetbookUseCase(
                name: 'Default',
                builder: _widgetbook_catalog_core_no_permission_page_use_cases
                    .buildNoPermissionPage,
              ),
            ],
          ),
          _widgetbook.WidgetbookComponent(
            name: 'PermissionGate',
            useCases: [
              _widgetbook.WidgetbookUseCase(
                name: 'Disabled',
                builder: _widgetbook_catalog_core_permission_gate_use_cases
                    .buildPermissionGateDisabled,
              ),
              _widgetbook.WidgetbookUseCase(
                name: 'Hidden',
                builder: _widgetbook_catalog_core_permission_gate_use_cases
                    .buildPermissionGateHidden,
              ),
              _widgetbook.WidgetbookUseCase(
                name: 'No rule',
                builder: _widgetbook_catalog_core_permission_gate_use_cases
                    .buildPermissionGateNoRule,
              ),
              _widgetbook.WidgetbookUseCase(
                name: 'Readonly',
                builder: _widgetbook_catalog_core_permission_gate_use_cases
                    .buildPermissionGateReadonly,
              ),
            ],
          ),
          _widgetbook.WidgetbookComponent(
            name: 'UnderConstructionPage',
            useCases: [
              _widgetbook.WidgetbookUseCase(
                name: 'Default',
                builder:
                    _widgetbook_catalog_core_under_construction_page_use_cases
                        .buildUnderConstructionPage,
              ),
            ],
          ),
        ],
      ),
      _widgetbook.WidgetbookFolder(
        name: 'update',
        children: [
          _widgetbook.WidgetbookComponent(
            name: 'KonteynerUpdateDialog',
            useCases: [
              _widgetbook.WidgetbookUseCase(
                name: 'Blocking',
                builder: _widgetbook_catalog_core_update_dialog_use_cases
                    .buildBlockingUpdateDialog,
              ),
              _widgetbook.WidgetbookUseCase(
                name: 'Dismissible',
                builder: _widgetbook_catalog_core_update_dialog_use_cases
                    .buildDismissibleUpdateDialog,
              ),
            ],
          ),
        ],
      ),
    ],
  ),
];
