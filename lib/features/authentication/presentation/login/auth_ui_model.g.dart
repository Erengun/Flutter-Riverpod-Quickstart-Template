// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_ui_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_AuthUiModel _$AuthUiModelFromJson(Map<String, dynamic> json) => _AuthUiModel(
  user: json['user'] == null
      ? null
      : LoginCredentials.fromJson(json['user'] as Map<String, dynamic>),
  rememberMe: json['rememberMe'] as bool? ?? false,
  showPassword: json['showPassword'] as bool? ?? false,
  isLoading: json['isLoading'] as bool? ?? false,
);

Map<String, dynamic> _$AuthUiModelToJson(_AuthUiModel instance) =>
    <String, dynamic>{
      'user': instance.user,
      'rememberMe': instance.rememberMe,
      'showPassword': instance.showPassword,
      'isLoading': instance.isLoading,
    };
