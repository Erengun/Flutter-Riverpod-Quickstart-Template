// test_reflective_loader finds test methods by their test_ prefix.
// ignore_for_file: non_constant_identifier_names

import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
// ExpectedDiagnostic is only exported from src/, but lint() returns it.
// ignore: implementation_imports
import 'package:analyzer_testing/src/analysis_rule/pub_package_resolution.dart'
    show ExpectedDiagnostic;
import 'package:app_lints/src/template/ui_no_backend_providers.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UiNoBackendProvidersTest);
  });
}

@reflectiveTest
class UiNoBackendProvidersTest extends AnalysisRuleTest {
  String get _login => '$testPackageLibPath/features/auth/presentation/login';

  /// The import of the providers file from a file in [_login].
  static const String _import = "import '../../../../providers.dart';\n";

  @override
  void setUp() {
    rule = UiNoBackendProviders();
    super.setUp();
    // Stand-ins for Core's barrel and the app's generated providers.
    newFile('$testPackageLibPath/providers.dart', '''
final Object authenticationRepositoryProvider = Object();
final Object dioProvider = Object();
final Object apiCallProvider = Object();
final Object dioInterceptorsProvider = Object();
final Object authInterceptorProvider = Object();
final Object sessionBoxProvider = Object();
final Object sessionProvider = Object();
final Object loginControllerProvider = Object();
final Object repositoryProviders = Object();
''');
  }

  // Forbidden

  Future<void> test_repositoryProviderInScreen() async {
    const String content =
        '${_import}Object r = authenticationRepositoryProvider;\n';
    final String path = '$_login/login_screen.dart';
    newFile(path, content);
    await assertDiagnosticsInFile(path, <ExpectedDiagnostic>[
      lint(
        _import.length + 11,
        32,
        messageContainsAll: <Pattern>['authenticationRepositoryProvider'],
      ),
    ]);
  }

  Future<void> test_everyNamedBackendProvider() async {
    const String content =
        '${_import}List<Object> all = <Object>[\n'
        '  dioProvider,\n'
        '  apiCallProvider,\n'
        '  dioInterceptorsProvider,\n'
        '  authInterceptorProvider,\n'
        '  sessionBoxProvider,\n'
        '];\n';
    final String path = '$_login/login_screen.dart';
    newFile(path, content);
    const int start = _import.length + 'List<Object> all = <Object>[\n'.length;
    await assertDiagnosticsInFile(path, <ExpectedDiagnostic>[
      lint(start + 2, 11),
      lint(start + 17, 15),
      lint(start + 36, 23),
      lint(start + 63, 23),
      lint(start + 90, 18),
    ]);
  }

  Future<void> test_prefixedReference() async {
    const String import = "import '../../../../providers.dart' as core;\n";
    const String content = '${import}Object d = core.dioProvider;\n';
    final String path = '$_login/login_screen.dart';
    newFile(path, content);
    await assertDiagnosticsInFile(path, <ExpectedDiagnostic>[
      lint(import.length + 16, 11),
    ]);
  }

  Future<void> test_newFileInPresentationIsUiFile() async {
    const String import = "import '../../../../../providers.dart';\n";
    const String content = '${import}Object d = dioProvider;\n';
    final String path = '$_login/widgets/brand_new_thing.dart';
    newFile(path, content);
    await assertDiagnosticsInFile(path, <ExpectedDiagnostic>[
      lint(import.length + 11, 11),
    ]);
  }

  Future<void> test_sharedWidgetReadsRepository() async {
    const String import = "import '../../providers.dart';\n";
    const String content =
        '${import}Object r = authenticationRepositoryProvider;\n';
    final String path = '$testPackageLibPath/shared/widgets/user_card.dart';
    newFile(path, content);
    await assertDiagnosticsInFile(path, <ExpectedDiagnostic>[
      lint(import.length + 11, 32),
    ]);
  }

  Future<void> test_referenceInsideAFunctionBody() async {
    const String content =
        '${_import}Object read() {\n'
        '  return sessionBoxProvider;\n'
        '}\n';
    final String path = '$_login/login_screen.dart';
    newFile(path, content);
    await assertDiagnosticsInFile(path, <ExpectedDiagnostic>[
      lint(_import.length + 'Object read() {\n'.length + 9, 18),
    ]);
  }

  // Allowed

  Future<void> test_controllerReadsRepository() async {
    const String content =
        '${_import}Object r = authenticationRepositoryProvider;\n'
        'Object d = dioProvider;\n';
    final String path = '$_login/login_controller.dart';
    newFile(path, content);
    await assertNoDiagnosticsInFile(path);
  }

  Future<void> test_uiModelReadsRepository() async {
    const String content =
        '${_import}Object r = authenticationRepositoryProvider;\n';
    final String path = '$_login/auth_ui_model.dart';
    newFile(path, content);
    await assertNoDiagnosticsInFile(path);
  }

  Future<void> test_generatedFileReadsRepository() async {
    const String content =
        '${_import}Object r = authenticationRepositoryProvider;\n';
    final String path = '$_login/login_controller.g.dart';
    newFile(path, content);
    await assertNoDiagnosticsInFile(path);
  }

  Future<void> test_freezedFileReadsRepository() async {
    const String content =
        '${_import}Object r = authenticationRepositoryProvider;\n';
    final String path = '$_login/auth_ui_model.freezed.dart';
    newFile(path, content);
    await assertNoDiagnosticsInFile(path);
  }

  Future<void> test_uiFileReadsOtherProviders() async {
    const String content =
        '${_import}List<Object> all = <Object>[\n'
        '  sessionProvider,\n'
        '  loginControllerProvider,\n'
        '  repositoryProviders,\n'
        '];\n';
    final String path = '$_login/login_screen.dart';
    newFile(path, content);
    await assertNoDiagnosticsInFile(path);
  }

  Future<void> test_hideCombinatorIsNotAReference() async {
    const String content =
        "import '../../../../providers.dart' hide dioProvider;\n"
        'Object s = sessionProvider;\n';
    final String path = '$_login/login_screen.dart';
    newFile(path, content);
    await assertNoDiagnosticsInFile(path);
  }

  Future<void> test_dataFileReadsBackendProviders() async {
    const String content =
        "import '../../../providers.dart';\n"
        'Object d = dioProvider;\n'
        'Object a = apiCallProvider;\n';
    final String path =
        '$testPackageLibPath/features/auth/data/http_auth_repository.dart';
    newFile(path, content);
    await assertNoDiagnosticsInFile(path);
  }

  Future<void> test_testFileReadsBackendProviders() async {
    const String content =
        "import 'package:test/providers.dart';\n"
        'Object d = dioProvider;\n'
        'Object b = sessionBoxProvider;\n';
    final String path = '$testPackageTestPath/login_screen_test.dart';
    newFile(path, content);
    await assertNoDiagnosticsInFile(path);
  }
}
