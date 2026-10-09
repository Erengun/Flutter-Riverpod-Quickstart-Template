import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('NoopRemoteFlags returns every fallback', () async {
    const RemoteFlags flags = NoopRemoteFlags();

    expect(flags.getBool('flag', fallback: true), isTrue);
    expect(flags.getInt('count', fallback: 7), 7);
    expect(flags.getString('text', fallback: 'x'), 'x');
    await flags.refresh();
    expect(await flags.onChanged.isEmpty, isTrue);
  });

  test('the no-op reporter and analytics accept every call', () {
    const ErrorReporter reporter = NoopErrorReporter();
    const Analytics analytics = NoopAnalytics();

    reporter
      ..report(StateError('x'), StackTrace.current, fatal: true)
      ..addBreadcrumb('crumb', level: BreadcrumbLevel.warning)
      ..setUser(null);
    analytics
      ..logEvent('event', <String, Object>{'count': 1, 'name': 'n'})
      ..logScreen('home')
      ..setUserId('id');
  });
}
