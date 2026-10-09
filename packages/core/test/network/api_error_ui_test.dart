import 'package:core/core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

class _Screen extends Notifier<AsyncValue<int>> {
  @override
  AsyncValue<int> build() => const AsyncData<int>(0);

  void fail(Object error) {
    state = AsyncError<int>(error, StackTrace.current);
  }
}

final NotifierProvider<_Screen, AsyncValue<int>> _screenProvider =
    NotifierProvider<_Screen, AsyncValue<int>>(_Screen.new);

class _Listening extends ConsumerWidget {
  const _Listening();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listenApiErrors(_screenProvider, context);
    return const Scaffold(body: SizedBox.shrink());
  }
}

final CoreLocalizations _en = lookupCoreLocalizations(const Locale('en'));

Widget _app(Widget home, {ProviderContainer? container}) {
  final Widget app = MaterialApp(
    localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
      CoreLocalizations.delegate,
      ...GlobalMaterialLocalizations.delegates,
    ],
    supportedLocales: CoreLocalizations.supportedLocales,
    home: home,
  );
  return container == null
      ? ProviderScope(child: app)
      : UncontrolledProviderScope(container: container, child: app);
}

Future<String?> _snackbarFor(WidgetTester tester, Object error) async {
  final ProviderContainer container = ProviderContainer();
  addTearDown(container.dispose);
  await tester.pumpWidget(_app(const _Listening(), container: container));
  container.read(_screenProvider.notifier).fail(error);
  await tester.pump();
  final Finder snackbar = find.byType(SnackBar);
  if (snackbar.evaluate().isEmpty) return null;
  expect(tester.widget<SnackBar>(snackbar).behavior, SnackBarBehavior.floating);
  return tester
      .widget<Text>(find.descendant(of: snackbar, matching: find.byType(Text)))
      .data;
}

void main() {
  final Map<ApiException, String> shown = <ApiException, String>{
    const ApiConnectionException(): _en.errorConnection,
    const ApiTimeoutException(): _en.errorTimeout,
    const ApiForbiddenException(): _en.errorNoPermission,
    const ApiNotFoundException(): _en.errorNotFound,
    const ApiServerException(500): _en.errorServer,
    const ApiBusinessException(): _en.errorSomethingWentWrong,
    const ApiDecodeException(): _en.errorSomethingWentWrong,
    const ApiUnknownException(): _en.errorSomethingWentWrong,
  };

  for (final MapEntry<ApiException, String> entry in shown.entries) {
    testWidgets('${entry.key.kind} shows its message', (WidgetTester t) async {
      expect(await _snackbarFor(t, entry.key), entry.value);
    });
  }

  testWidgets('the backend message wins over the default', (
    WidgetTester tester,
  ) async {
    expect(
      await _snackbarFor(
        tester,
        const ApiServerException(400, message: 'Email is taken'),
      ),
      'Email is taken',
    );
  });

  testWidgets('unauthorized and cancelled show nothing', (
    WidgetTester tester,
  ) async {
    expect(
      await _snackbarFor(tester, const ApiUnauthorizedException()),
      isNull,
    );
    expect(await _snackbarFor(tester, const ApiCancelledException()), isNull);
  });

  testWidgets('a non-API error shows the generic message', (
    WidgetTester tester,
  ) async {
    expect(
      await _snackbarFor(tester, StateError('x')),
      _en.errorSomethingWentWrong,
    );
  });

  testWidgets('ApiErrorView shows the message and retries', (
    WidgetTester tester,
  ) async {
    int retries = 0;
    await tester.pumpWidget(
      _app(
        Scaffold(
          body: ApiErrorView(
            error: const ApiConnectionException(),
            onRetry: () => retries++,
          ),
        ),
      ),
    );

    expect(find.text(_en.errorConnection), findsOneWidget);
    await tester.tap(find.text(_en.errorRetry));
    expect(retries, 1);
  });

  testWidgets('ApiErrorView has no button without onRetry', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _app(const Scaffold(body: ApiErrorView(error: ApiNotFoundException()))),
    );
    expect(find.text(_en.errorNotFound), findsOneWidget);
    expect(find.text(_en.errorRetry), findsNothing);
  });
}
