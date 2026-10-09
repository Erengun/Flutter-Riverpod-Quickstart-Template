import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_module/src/firebase_analytics_adapter.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeFirebaseAnalytics extends Fake implements FirebaseAnalytics {
  final List<String> calls = <String>[];
  bool fail = false;

  Future<void> _record(String call) async {
    calls.add(call);
    if (fail) throw Exception('analytics failed');
  }

  @override
  Future<void> logEvent({
    required String name,
    Map<String, Object>? parameters,
    List<AnalyticsEventItem>? items,
    AnalyticsCallOptions? callOptions,
  }) => _record('event $name $parameters');

  @override
  Future<void> logScreenView({
    String? screenClass,
    String? screenName,
    Map<String, Object>? parameters,
    AnalyticsCallOptions? callOptions,
  }) => _record('screen $screenName');

  @override
  Future<void> setUserId({String? id, AnalyticsCallOptions? callOptions}) =>
      _record('user $id');
}

void main() {
  late _FakeFirebaseAnalytics firebase;
  late FirebaseAnalyticsAdapter analytics;

  setUp(() {
    firebase = _FakeFirebaseAnalytics();
    analytics = FirebaseAnalyticsAdapter(firebase);
  });

  test('forwards events, screens and the user id to Firebase', () {
    analytics
      ..logEvent('login', <String, Object>{'method': 'email', 'tries': 1})
      ..logEvent('logout')
      ..logScreen('home')
      ..setUserId('42')
      ..setUserId(null);

    expect(firebase.calls, <String>[
      'event login {method: email, tries: 1}',
      'event logout null',
      'screen home',
      'user 42',
      'user null',
    ]);
  });

  test('a failing Firebase call is logged, not thrown', () async {
    firebase.fail = true;

    analytics.logEvent('login');
    await pumpEventQueue();

    expect(firebase.calls, hasLength(1));
  });
}
