import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('the no-op reporter accepts every call', () {
    const ErrorReporter reporter = NoopErrorReporter();

    reporter
      ..report(StateError('x'), StackTrace.current, fatal: true)
      ..addBreadcrumb('crumb', level: BreadcrumbLevel.warning)
      ..setUser(null);
  });
}
