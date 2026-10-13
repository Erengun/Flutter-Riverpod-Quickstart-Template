// test_reflective_loader finds test methods by their test_ prefix.
// ignore_for_file: non_constant_identifier_names

import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
// ExpectedDiagnostic is only exported from src/, but lint() returns it.
// ignore: implementation_imports
import 'package:analyzer_testing/src/analysis_rule/pub_package_resolution.dart'
    show ExpectedDiagnostic;
import 'package:app_lints/src/template/no_widget_functions.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NoWidgetFunctionsTest);
  });
}

@reflectiveTest
class NoWidgetFunctionsTest extends AnalysisRuleTest {
  static const String _topLevel = '''
import 'package:flutter/widgets.dart';

Widget buildHeader() => const Text('Header');
''';

  @override
  bool get addFlutterPackageDep => true;

  @override
  void setUp() {
    rule = NoWidgetFunctions();
    super.setUp();
  }

  // Forbidden

  Future<void> test_topLevelFunctionInFeature() async {
    final String path =
        '$testPackageLibPath/features/home/presentation/header.dart';
    newFile(path, _topLevel);
    await assertDiagnosticsInFile(path, <ExpectedDiagnostic>[lint(47, 11)]);
  }

  Future<void> test_topLevelFunctionInShared() async {
    final String path = '$testPackageLibPath/shared/widgets/header.dart';
    newFile(path, _topLevel);
    await assertDiagnosticsInFile(path, <ExpectedDiagnostic>[lint(47, 11)]);
  }

  Future<void> test_helperMethods() async {
    const String content = '''
import 'package:flutter/widgets.dart';

class Home extends StatelessWidget {
  const Home({super.key});

  static Widget divider() => const Text('-');

  @override
  Widget build(BuildContext context) => Column(children: <Widget>[_title()]);

  Text _title() => const Text('Home');

  Widget? _maybeFooter() => null;

  Widget get header => const Text('Header');
}
''';
    final String path = '$testPackageLibPath/features/home/home_screen.dart';
    newFile(path, content);
    await assertDiagnosticsInFile(path, <ExpectedDiagnostic>[
      lint(121, 7),
      lint(250, 6),
      lint(293, 12),
      lint(331, 6),
    ]);
  }

  Future<void> test_abstractBuildBody() async {
    // A known false positive: the base class's hook needs `// ignore:`.
    const String content = '''
import 'package:flutter/widgets.dart';

abstract class Page extends StatelessWidget {
  const Page({super.key});

  Widget buildBody(BuildContext context);

  @override
  Widget build(BuildContext context) => buildBody(context);
}
''';
    final String path = '$testPackageLibPath/shared/widgets/page.dart';
    newFile(path, content);
    await assertDiagnosticsInFile(path, <ExpectedDiagnostic>[lint(123, 9)]);
  }

  // Allowed

  Future<void> test_abstractBuildBodyIgnored() async {
    const String content = '''
import 'package:flutter/widgets.dart';

abstract class Page extends StatelessWidget {
  const Page({super.key});

  // ignore: no_widget_functions
  Widget buildBody(BuildContext context);

  @override
  Widget build(BuildContext context) => buildBody(context);
}
''';
    final String path = '$testPackageLibPath/shared/widgets/page.dart';
    newFile(path, content);
    await assertNoDiagnosticsInFile(path);
  }

  Future<void> test_overrideBuild() async {
    const String content = '''
import 'package:flutter/widgets.dart';

class Home extends StatelessWidget {
  const Home({super.key});

  @override
  Widget build(BuildContext context) => const Text('Home');
}

class Counter extends StatefulWidget {
  const Counter({super.key});

  @override
  State<Counter> createState() => _CounterState();
}

class _CounterState extends State<Counter> {
  @override
  Widget build(BuildContext context) => const Text('0');
}
''';
    final String path = '$testPackageLibPath/features/home/home_screen.dart';
    newFile(path, content);
    await assertNoDiagnosticsInFile(path);
  }

  Future<void> test_closuresAndLocalFunctions() async {
    const String content = '''
import 'package:flutter/widgets.dart';

final Widget Function() header = () => const Text('Header');

class Home extends StatelessWidget {
  const Home({super.key});

  @override
  Widget build(BuildContext context) {
    Widget title() => const Text('Home');
    return Builder(builder: (BuildContext context) => title());
  }
}
''';
    final String path = '$testPackageLibPath/features/home/home_screen.dart';
    newFile(path, content);
    await assertNoDiagnosticsInFile(path);
  }

  Future<void> test_listOfWidgetsHelper() async {
    const String content = '''
import 'package:flutter/widgets.dart';

List<Widget> tiles() => <Widget>[const Text('a'), const Text('b')];

class Home extends StatelessWidget {
  const Home({super.key});

  List<Widget> _rows() => tiles();

  @override
  Widget build(BuildContext context) => Column(children: _rows());
}
''';
    final String path = '$testPackageLibPath/features/home/home_screen.dart';
    newFile(path, content);
    await assertNoDiagnosticsInFile(path);
  }

  Future<void> test_otherReturnTypes() async {
    const String content = '''
import 'package:flutter/widgets.dart';

String label() => 'Home';
Future<Widget> load() async => const Text('Home');
''';
    final String path = '$testPackageLibPath/features/home/labels.dart';
    newFile(path, content);
    await assertNoDiagnosticsInFile(path);
  }

  Future<void> test_inCatalog() async {
    // The catalog mirrors the app's paths under lib/app/; its @UseCase
    // builders are functions by design.
    final String path =
        '$testPackageLibPath/app/features/home/presentation/header.use_cases.dart';
    newFile(path, _topLevel);
    await assertNoDiagnosticsInFile(path);
  }

  Future<void> test_inCore() async {
    final String path = '$testPackageLibPath/src/widgets/header.dart';
    newFile(path, _topLevel);
    await assertNoDiagnosticsInFile(path);
  }

  Future<void> test_inTest() async {
    final String path = '$testPackageTestPath/features/header_test.dart';
    newFile(path, _topLevel);
    await assertNoDiagnosticsInFile(path);
  }
}
