import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('the no-op analytics accepts every call', () {
    const Analytics analytics = NoopAnalytics();

    analytics
      ..logEvent('event', <String, Object>{'count': 1, 'name': 'n'})
      ..logScreen('home')
      ..setUserId('id');
  });
}
