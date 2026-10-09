import 'package:core/core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logging/logging.dart';

import '../support/recording_reporter.dart';

class _HandledApiError extends ApiException {
  const _HandledApiError();
}

final Provider<int> _failing = Provider<int>(
  (Ref ref) => throw StateError('build failed'),
  name: 'failingProvider',
);

final Provider<int> _otherFailing = Provider<int>(
  (Ref ref) => throw StateError('other failed'),
  name: 'otherFailingProvider',
);

final Provider<int> _apiFailing = Provider<int>(
  (Ref ref) => throw const _HandledApiError(),
  name: 'apiFailingProvider',
);

class _GuardedNotifier extends AsyncNotifier<int> {
  @override
  Future<int> build() async => 0;

  Future<void> load() async {
    state = await AsyncValue.guard<int>(
      () async => throw StateError('load failed'),
    );
  }
}

final AsyncNotifierProvider<_GuardedNotifier, int> _guarded =
    AsyncNotifierProvider<_GuardedNotifier, int>(
      _GuardedNotifier.new,
      name: 'guardedProvider',
    );

void main() {
  late RecordingReporter reporter;
  late ReportDispatcher dispatcher;
  late ProviderContainer container;

  setUp(() {
    reporter = RecordingReporter();
    dispatcher = ReportDispatcher()..attach(reporter);
    configureLogging(
      LogPolicy.forFlavor(Flavor.dev),
      reporter: dispatcher,
      printer: (LogRecord record) {},
    );
    container = ProviderContainer(
      observers: <ProviderObserver>[ProviderFailureObserver(dispatcher)],
      retry: (int retryCount, Object error) => null,
    );
  });

  tearDown(() {
    container.dispose();
    resetLogging();
  });

  void readAndIgnore(ProviderListenable<Object?> provider) {
    try {
      container.read(provider);
    } on Object {
      // The failure is what the observer sees.
    }
  }

  test('a failing provider is reported once, non-fatal, with its name', () {
    readAndIgnore(_failing);

    expect(reporter.reports, hasLength(1));
    expect(reporter.reports.single.fatal, isFalse);
    expect(reporter.reports.single.error, isA<StateError>());
    expect(reporter.reports.single.tags, <String, String>{
      'provider': 'failingProvider',
    });
  });

  test('repeat failures of one provider become breadcrumbs', () {
    readAndIgnore(_failing);
    container.invalidate(_failing);
    readAndIgnore(_failing);
    container.invalidate(_failing);
    readAndIgnore(_failing);

    expect(reporter.reports, hasLength(1));
    final List<RecordedBreadcrumb> repeats = reporter.breadcrumbs
        .where((RecordedBreadcrumb b) => b.category == 'provider')
        .toList();
    expect(repeats, hasLength(2));
    expect(repeats.first.message, contains('failingProvider'));
    expect(repeats.first.message, isNot(contains('build failed')));
  });

  test('each provider gets its own report', () {
    readAndIgnore(_failing);
    readAndIgnore(_otherFailing);

    expect(
      reporter.reports.map((RecordedReport r) => r.tags['provider']),
      <String>['failingProvider', 'otherFailingProvider'],
    );
  });

  test('an ApiException is skipped: the network layer handled it', () {
    readAndIgnore(_apiFailing);

    expect(reporter.reports, isEmpty);
  });

  test('an AsyncError set by a notifier is reported', () async {
    await container.read(_guarded.future);

    await container.read(_guarded.notifier).load();

    expect(reporter.reports, hasLength(1));
    expect(reporter.reports.single.tags['provider'], 'guardedProvider');
  });
}
