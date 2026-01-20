import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/login_request.dart';

part 'auth_ui_model.freezed.dart';
part 'auth_ui_model.g.dart';

@freezed
abstract class AuthUiModel with _$AuthUiModel {
  const factory AuthUiModel({
    LoginCredentials? user,
    @Default(false) bool rememberMe,
    @Default(false) bool showPassword,
  }) = _AuthUiModel;

  factory AuthUiModel.fromJson(Map<String, dynamic> json) =>
      _$AuthUiModelFromJson(json);
}
