import 'package:core/core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const AppConfig _config = AppConfig(
  flavor: Flavor.dev,
  apiBaseUrl: 'https://example.com/',
  apiKey: 'demo',
);

class _Report {
  const _Report(this.error, {required this.fatal});

  final Object error;
  final bool fatal;
}

class _FakeReporter implements ErrorReporter {
  final List<_Report> reports = <_Report>[];

  @override
  void report(
    Object error,
    StackTrace? stackTrace, {
    bool fatal = false,
    String? groupKey,
    Map<String, String> tags = const <String, String>{},
    Map<String, Object?> extra = const <String, Object?>{},
  }) {
    reports.add(_Report(error, fatal: fatal));
  }

  @override
  void addBreadcrumb(
    String message, {
    String? category,
    BreadcrumbLevel level = BreadcrumbLevel.info,
    Map<String, Object?> data = const <String, Object?>{},
  }) {}

  @override
  void setUser(String? id) {}
}

class _FakeAnalytics implements Analytics {
  @override
  void logEvent(
    String name, [
    Map<String, Object> params = const <String, Object>{},
  ]) {}

  @override
  void logScreen(String name) {}

  @override
  void setUserId(String? id) {}
}

class _FakeModule implements KonteynerModule {
  _FakeModule(
    this.name, {
    this.platforms = const <KonteynerPlatform>{...KonteynerPlatform.values},
    this.contributions = const ModuleContributions(),
    this.error,
  });

  @override
  final String name;

  @override
  final Set<KonteynerPlatform> platforms;

  final ModuleContributions contributions;
  final Error? error;
  AppConfig? receivedConfig;

  @override
  Future<ModuleContributions> init(AppConfig config) async {
    receivedConfig = config;
    final Error? failure = error;
    if (failure != null) throw failure;
    return contributions;
  }
}

ProviderContainer _containerFor(StartedModules started) {
  final ProviderContainer container = ProviderContainer(
    overrides: started.overrides,
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  test('with no Modules every interface keeps its no-op default', () async {
    final StartedModules started = await startModules(
      const <KonteynerModule>[],
      _config,
      platform: KonteynerPlatform.android,
    );
    final ProviderContainer container = _containerFor(started);

    expect(container.read(errorReporterProvider), isA<NoopErrorReporter>());
    expect(container.read(analyticsProvider), isA<NoopAnalytics>());
    expect(container.read(remoteFlagsProvider), isA<NoopRemoteFlags>());
    expect(started.failures, isEmpty);
  });

  test(
    'a Module contribution replaces the default and gets the config',
    () async {
      final _FakeReporter reporter = _FakeReporter();
      final _FakeModule module = _FakeModule(
        'reporting',
        contributions: ModuleContributions(errorReporter: reporter),
      );

      final StartedModules started = await startModules(
        <KonteynerModule>[module],
        _config,
        platform: KonteynerPlatform.ios,
      );
      final ProviderContainer container = _containerFor(started);

      expect(container.read(errorReporterProvider), same(reporter));
      expect(module.receivedConfig, same(_config));
    },
  );

  test('a Module is skipped on a platform outside its platforms', () async {
    final _FakeModule module = _FakeModule(
      'mobile_only',
      platforms: const <KonteynerPlatform>{
        KonteynerPlatform.android,
        KonteynerPlatform.ios,
      },
      contributions: ModuleContributions(analytics: _FakeAnalytics()),
    );

    final StartedModules started = await startModules(
      <KonteynerModule>[module],
      _config,
      platform: KonteynerPlatform.macos,
    );
    final ProviderContainer container = _containerFor(started);

    expect(module.receivedConfig, isNull);
    expect(container.read(analyticsProvider), isA<NoopAnalytics>());
    expect(started.failures, isEmpty);
  });

  test('a throwing init keeps the defaults and the failure is reported '
      'once every Module has started', () async {
    final _FakeReporter reporter = _FakeReporter();
    final StateError failure = StateError('init failed');
    final _FakeModule broken = _FakeModule(
      'broken',
      error: failure,
      contributions: ModuleContributions(analytics: _FakeAnalytics()),
    );
    final _FakeModule reporting = _FakeModule(
      'reporting',
      contributions: ModuleContributions(errorReporter: reporter),
    );

    final StartedModules started = await startModules(
      <KonteynerModule>[broken, reporting],
      _config,
      platform: KonteynerPlatform.web,
    );
    final ProviderContainer container = _containerFor(started);

    expect(container.read(analyticsProvider), isA<NoopAnalytics>());
    expect(container.read(errorReporterProvider), same(reporter));
    expect(started.failures, hasLength(1));
    expect(started.failures.single.moduleName, 'broken');
    expect(started.failures.single.error, same(failure));
    expect(reporter.reports, hasLength(1));
    expect(reporter.reports.single.fatal, isFalse);
    expect(
      reporter.reports.single.error,
      isA<ModuleStartupException>().having(
        (ModuleStartupException e) => e.moduleName,
        'moduleName',
        'broken',
      ),
    );
  });

  test('two Modules providing one interface stop startup', () async {
    final _FakeModule first = _FakeModule(
      'first',
      contributions: ModuleContributions(errorReporter: _FakeReporter()),
    );
    final _FakeModule second = _FakeModule(
      'second',
      contributions: ModuleContributions(errorReporter: _FakeReporter()),
    );

    await expectLater(
      startModules(
        <KonteynerModule>[first, second],
        _config,
        platform: KonteynerPlatform.android,
      ),
      throwsA(
        isA<ModuleConflictError>()
            .having(
              (ModuleConflictError e) => e.interfaceName,
              'interfaceName',
              'ErrorReporter',
            )
            .having(
              (ModuleConflictError e) => e.moduleNames,
              'moduleNames',
              <String>['first', 'second'],
            ),
      ),
    );
  });
}
