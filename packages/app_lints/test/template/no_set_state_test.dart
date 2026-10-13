// test_reflective_loader finds test methods by their test_ prefix.
// ignore_for_file: non_constant_identifier_names

import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
// ExpectedDiagnostic is only exported from src/, but lint() returns it.
// ignore: implementation_imports
import 'package:analyzer_testing/src/analysis_rule/pub_package_resolution.dart'
    show ExpectedDiagnostic;
import 'package:app_lints/src/template/no_set_state.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NoSetStateTest);
  });
}

@reflectiveTest
class NoSetStateTest extends AnalysisRuleTest {
  static const String _counter = r'''
import 'package:flutter/widgets.dart';

class Counter extends StatefulWidget {
  const Counter({super.key});

  @override
  State<Counter> createState() => _CounterState();
}

class _CounterState extends State<Counter> {
  int count = 0;

  void increment() {
    setState(() => count++);
  }

  @override
  Widget build(BuildContext context) => Text('$count');
}
''';

  @override
  bool get addFlutterPackageDep => true;

  @override
  void setUp() {
    rule = NoSetState();
    super.setUp();
  }

  // Forbidden

  Future<void> test_inFeature() async {
    final String path =
        '$testPackageLibPath/features/counter/presentation/counter_screen.dart';
    newFile(path, _counter);
    await assertDiagnosticsInFile(path, <ExpectedDiagnostic>[lint(264, 8)]);
  }

  Future<void> test_inSharedWidget() async {
    final String path = '$testPackageLibPath/shared/widgets/counter.dart';
    newFile(path, _counter);
    await assertDiagnosticsInFile(path, <ExpectedDiagnostic>[lint(264, 8)]);
  }

  Future<void> test_inClosureAndThroughThis() async {
    const String content = r'''
import 'package:flutter/widgets.dart';

class Toggle extends StatefulWidget {
  const Toggle({super.key});

  @override
  State<Toggle> createState() => _ToggleState();
}

class _ToggleState extends State<Toggle> {
  bool on = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => setState(() => on = !on),
      onDoubleTap: () => this.setState(() => on = false),
      child: Text('$on'),
    );
  }
}
''';
    final String path = '$testPackageLibPath/shared/toggle.dart';
    newFile(path, content);
    await assertDiagnosticsInFile(path, <ExpectedDiagnostic>[
      lint(333, 8),
      lint(389, 8),
    ]);
  }

  // Allowed

  Future<void> test_classWithOwnSetState() async {
    const String content = '''
class Store {
  int count = 0;

  void setState(void Function() fn) => fn();

  void increment() {
    setState(() => count++);
  }
}
''';
    final String path = '$testPackageLibPath/features/counter/data/store.dart';
    newFile(path, content);
    await assertNoDiagnosticsInFile(path);
  }

  Future<void> test_inCoreWidget() async {
    // Core's widgets live in lib/src/, outside features/ and shared/.
    final String path = '$testPackageLibPath/src/widgets/counter.dart';
    newFile(path, _counter);
    await assertNoDiagnosticsInFile(path);
  }

  Future<void> test_inAppFolder() async {
    final String path = '$testPackageLibPath/app/counter.dart';
    newFile(path, _counter);
    await assertNoDiagnosticsInFile(path);
  }

  Future<void> test_inCatalogFeatureFolder() async {
    // The catalog mirrors the app's paths under lib/app/.
    final String path =
        '$testPackageLibPath/app/features/counter/counter.use_cases.dart';
    newFile(path, _counter);
    await assertNoDiagnosticsInFile(path);
  }

  Future<void> test_inTest() async {
    final String path = '$testPackageTestPath/features/counter_test.dart';
    newFile(path, _counter);
    await assertNoDiagnosticsInFile(path);
  }
}
