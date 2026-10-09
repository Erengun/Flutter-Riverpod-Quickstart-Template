import '../../l10n/core_localizations.dart';

/// Where a failed request went: what the error report and breadcrumb carry.
///
/// Never holds headers, bodies or query values.
class ApiRequestInfo {
  const ApiRequestInfo({
    required this.method,
    required this.path,
    this.statusCode,
    this.requestId,
  });

  /// The HTTP method, upper case (`GET`, `POST`).
  final String method;

  /// The request path with numeric and UUID segments replaced by `:id`.
  final String path;

  /// The response status, or `null` when there was no response.
  final int? statusCode;

  /// The backend's request id response header, when it sent one.
  final String? requestId;

  @override
  String toString() => '$method $path ${statusCode ?? '-'}';
}

/// A failed backend call, already mapped by `apiCall`. It reaches the UI as
/// an `AsyncError`; show it with `ref.listenApiErrors` or `ApiErrorView`.
///
/// `apiCall` has already reported it or recorded it as a breadcrumb, so
/// `ProviderFailureObserver` skips it.
///
/// [message] is the envelope's `errorMessage` when the backend sent one.
sealed class ApiException implements Exception {
  const ApiException({this.message, this.request, this.cause});

  /// The backend's own message, shown instead of Core's default.
  final String? message;

  /// The request that failed, when known.
  final ApiRequestInfo? request;

  /// The underlying error (a `DioException`, a decode error), for debugging.
  final Object? cause;

  /// A short name for the kind, used in breadcrumbs and logs.
  String get kind;

  /// Whether `apiCall` sends this kind to the error tracker (once per launch
  /// per method, path and status) instead of only leaving a breadcrumb.
  bool get isReported => switch (this) {
    ApiServerException() ||
    ApiNotFoundException() ||
    ApiDecodeException() ||
    ApiUnknownException() => true,
    _ => false,
  };

  /// The text to show the user: [message] when the backend sent one,
  /// otherwise Core's default for the kind.
  String localizedMessage(CoreLocalizations l10n) {
    final String? own = message;
    if (own != null && own.isNotEmpty) return own;
    return switch (this) {
      ApiConnectionException() => l10n.errorConnection,
      ApiTimeoutException() => l10n.errorTimeout,
      ApiUnauthorizedException() => l10n.authSessionExpired,
      ApiForbiddenException() => l10n.errorNoPermission,
      ApiNotFoundException() => l10n.errorNotFound,
      ApiServerException() => l10n.errorServer,
      ApiCancelledException() ||
      ApiBusinessException() ||
      ApiDecodeException() ||
      ApiUnknownException() => l10n.errorSomethingWentWrong,
    };
  }

  @override
  String toString() {
    final StringBuffer buffer = StringBuffer('ApiException.$kind');
    final ApiRequestInfo? info = request;
    if (info != null) buffer.write(' ($info)');
    if (message != null) buffer.write(': $message');
    return buffer.toString();
  }
}

/// The request never reached the server.
final class ApiConnectionException extends ApiException {
  const ApiConnectionException({super.request, super.cause});

  @override
  String get kind => 'connection';
}

/// A connect, send or receive timeout.
final class ApiTimeoutException extends ApiException {
  const ApiTimeoutException({super.request, super.cause});

  @override
  String get kind => 'timeout';
}

/// The request was cancelled. Never shown to the user.
final class ApiCancelledException extends ApiException {
  const ApiCancelledException({super.request, super.cause});

  @override
  String get kind => 'cancelled';
}

/// 401. The auth Feature redirects, so no snackbar is shown.
final class ApiUnauthorizedException extends ApiException {
  const ApiUnauthorizedException({super.message, super.request, super.cause});

  @override
  String get kind => 'unauthorized';
}

/// 403.
final class ApiForbiddenException extends ApiException {
  const ApiForbiddenException({super.message, super.request, super.cause});

  @override
  String get kind => 'forbidden';
}

/// 404.
final class ApiNotFoundException extends ApiException {
  const ApiNotFoundException({super.message, super.request, super.cause});

  @override
  String get kind => 'notFound';
}

/// Any other 4xx or 5xx.
final class ApiServerException extends ApiException {
  const ApiServerException(
    this.statusCode, {
    super.message,
    super.request,
    super.cause,
  });

  final int statusCode;

  @override
  String get kind => 'server';
}

/// A 2xx whose envelope says `success != true`: the backend refused a valid
/// request.
final class ApiBusinessException extends ApiException {
  const ApiBusinessException({super.message, super.request, super.cause});

  @override
  String get kind => 'business';
}

/// The response didn't fit the model.
final class ApiDecodeException extends ApiException {
  const ApiDecodeException({super.request, super.cause});

  @override
  String get kind => 'decode';
}

/// Anything else.
final class ApiUnknownException extends ApiException {
  const ApiUnknownException({super.message, super.request, super.cause});

  @override
  String get kind => 'unknown';
}
