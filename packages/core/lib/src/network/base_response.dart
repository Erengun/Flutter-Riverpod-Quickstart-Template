import 'package:freezed_annotation/freezed_annotation.dart';

import 'api_exception.dart';

part 'base_response.freezed.dart';
part 'base_response.g.dart';

/// The backend's response envelope.
///
/// This is Core's default shape. Edit the fields to fit your backend, and
/// edit [BaseResponseUnwrap.unwrap] and [envelopeErrorMessage] below with
/// them: the unwrap rule lives next to the fields it reads.
///
/// A retrofit method returning `Future<BaseResponse<T>>` goes through
/// `apiCall.unwrap`; a method returning `Future<T>` (a backend that doesn't
/// wrap) goes through plain `apiCall` and gets only the error mapping.
@Freezed(genericArgumentFactories: true)
abstract class BaseResponse<T> with _$BaseResponse<T> {
  const factory BaseResponse({
    required bool? success,
    required T data,
    required String? errorMessage,
    required String? message,
    required String? statusCode,
  }) = _BaseResponse<T>;

  factory BaseResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Object? json) fromJsonT,
  ) => _$BaseResponseFromJson<T>(json, fromJsonT);
}

/// The unwrap rule for a 2xx response.
extension BaseResponseUnwrap<T> on BaseResponse<T> {
  /// Returns [BaseResponse.data], or throws [ApiBusinessException] when
  /// `success != true` (the backend refused a valid request). Its message is
  /// `errorMessage ?? message`.
  T unwrap() {
    if (success != true) {
      throw ApiBusinessException(message: errorMessage ?? message);
    }
    return data;
  }
}

/// The message to recover from a 4xx/5xx error [body], read the same way as
/// [BaseResponseUnwrap.unwrap]: `errorMessage ?? message`. `null` when the
/// body isn't an envelope.
String? envelopeErrorMessage(Object? body) {
  if (body is! Map) return null;
  final Object? errorMessage = body['errorMessage'];
  if (errorMessage is String && errorMessage.isNotEmpty) return errorMessage;
  final Object? message = body['message'];
  if (message is String && message.isNotEmpty) return message;
  return null;
}
