// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'base_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_BaseResponse<T> _$BaseResponseFromJson<T>(
  Map<String, dynamic> json,
  T Function(Object? json) fromJsonT,
) => _BaseResponse<T>(
  success: json['success'] as bool?,
  data: fromJsonT(json['data']),
  errorMessage: json['errorMessage'] as String?,
  message: json['message'] as String?,
  statusCode: json['statusCode'] as String?,
);

Map<String, dynamic> _$BaseResponseToJson<T>(
  _BaseResponse<T> instance,
  Object? Function(T value) toJsonT,
) => <String, dynamic>{
  'success': instance.success,
  'data': toJsonT(instance.data),
  'errorMessage': instance.errorMessage,
  'message': instance.message,
  'statusCode': instance.statusCode,
};
