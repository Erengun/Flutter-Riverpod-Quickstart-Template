import 'package:core/core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

// One use case per ApiException kind. Each fails a request with that kind:
// `ref.listenApiErrors` shows its snackbar and `ApiErrorView` its full-screen
// error; Retry fails it again. Unauthorized and cancelled show no snackbar,
// as in the app.

/// A request whose result the use case sets.
final NotifierProvider<_Request, AsyncValue<void>> _requestProvider =
    NotifierProvider<_Request, AsyncValue<void>>(
      _Request.new,
      name: 'widgetbookRequestProvider',
    );

class _Request extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncLoading<void>();

  /// Sends the request again and fails it with [error].
  void fail(ApiException error) {
    state = const AsyncLoading<void>();
    state = AsyncError<void>(error, StackTrace.current);
  }
}

class _FailingRequest extends ConsumerStatefulWidget {
  const _FailingRequest(this.error);

  final ApiException error;

  @override
  ConsumerState<_FailingRequest> createState() => _FailingRequestState();
}

class _FailingRequestState extends ConsumerState<_FailingRequest> {
  @override
  void initState() {
    super.initState();
    // After the first frame, so the listener below is registered.
    WidgetsBinding.instance.addPostFrameCallback((Duration _) => _fail());
  }

  void _fail() {
    if (!mounted) return;
    ref.read(_requestProvider.notifier).fail(widget.error);
  }

  @override
  Widget build(BuildContext context) {
    ref.listenApiErrors(_requestProvider, context);
    return Scaffold(
      body: ApiErrorView(error: widget.error, onRetry: _fail),
    );
  }
}

Widget _failWith(ApiException error) {
  return ProviderScope(child: _FailingRequest(error));
}

const ApiRequestInfo _request = ApiRequestInfo(
  method: 'GET',
  path: '/api/users/:id',
  statusCode: 500,
);

@widgetbook.UseCase(
  name: 'connection',
  type: ApiErrorView,
  path: '[Core]/network',
)
Widget buildConnectionError(BuildContext context) =>
    _failWith(const ApiConnectionException());

@widgetbook.UseCase(name: 'timeout', type: ApiErrorView, path: '[Core]/network')
Widget buildTimeoutError(BuildContext context) =>
    _failWith(const ApiTimeoutException());

@widgetbook.UseCase(
  name: 'cancelled',
  type: ApiErrorView,
  path: '[Core]/network',
)
Widget buildCancelledError(BuildContext context) =>
    _failWith(const ApiCancelledException());

@widgetbook.UseCase(
  name: 'unauthorized',
  type: ApiErrorView,
  path: '[Core]/network',
)
Widget buildUnauthorizedError(BuildContext context) =>
    _failWith(const ApiUnauthorizedException());

@widgetbook.UseCase(
  name: 'forbidden',
  type: ApiErrorView,
  path: '[Core]/network',
)
Widget buildForbiddenError(BuildContext context) =>
    _failWith(const ApiForbiddenException());

@widgetbook.UseCase(
  name: 'notFound',
  type: ApiErrorView,
  path: '[Core]/network',
)
Widget buildNotFoundError(BuildContext context) =>
    _failWith(const ApiNotFoundException());

@widgetbook.UseCase(name: 'server', type: ApiErrorView, path: '[Core]/network')
Widget buildServerError(BuildContext context) =>
    _failWith(const ApiServerException(500, request: _request));

/// The backend refused a valid request; its own message is shown.
@widgetbook.UseCase(
  name: 'business',
  type: ApiErrorView,
  path: '[Core]/network',
)
Widget buildBusinessError(BuildContext context) => _failWith(
  const ApiBusinessException(message: 'This order is already closed.'),
);

@widgetbook.UseCase(name: 'decode', type: ApiErrorView, path: '[Core]/network')
Widget buildDecodeError(BuildContext context) =>
    _failWith(const ApiDecodeException());

@widgetbook.UseCase(
  name: 'unknown',
  type: ApiErrorView,
  path: '[Core]/network',
)
Widget buildUnknownError(BuildContext context) =>
    _failWith(const ApiUnknownException());
