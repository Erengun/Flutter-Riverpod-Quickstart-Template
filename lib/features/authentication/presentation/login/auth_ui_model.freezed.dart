// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'auth_ui_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$AuthUiModel {

 LoginCredentials? get user; bool get rememberMe; bool get showPassword;
/// Create a copy of AuthUiModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AuthUiModelCopyWith<AuthUiModel> get copyWith => _$AuthUiModelCopyWithImpl<AuthUiModel>(this as AuthUiModel, _$identity);

  /// Serializes this AuthUiModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AuthUiModel&&(identical(other.user, user) || other.user == user)&&(identical(other.rememberMe, rememberMe) || other.rememberMe == rememberMe)&&(identical(other.showPassword, showPassword) || other.showPassword == showPassword));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,user,rememberMe,showPassword);

@override
String toString() {
  return 'AuthUiModel(user: $user, rememberMe: $rememberMe, showPassword: $showPassword)';
}


}

/// @nodoc
abstract mixin class $AuthUiModelCopyWith<$Res>  {
  factory $AuthUiModelCopyWith(AuthUiModel value, $Res Function(AuthUiModel) _then) = _$AuthUiModelCopyWithImpl;
@useResult
$Res call({
 LoginCredentials? user, bool rememberMe, bool showPassword
});


$LoginCredentialsCopyWith<$Res>? get user;

}
/// @nodoc
class _$AuthUiModelCopyWithImpl<$Res>
    implements $AuthUiModelCopyWith<$Res> {
  _$AuthUiModelCopyWithImpl(this._self, this._then);

  final AuthUiModel _self;
  final $Res Function(AuthUiModel) _then;

/// Create a copy of AuthUiModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? user = freezed,Object? rememberMe = null,Object? showPassword = null,}) {
  return _then(_self.copyWith(
user: freezed == user ? _self.user : user // ignore: cast_nullable_to_non_nullable
as LoginCredentials?,rememberMe: null == rememberMe ? _self.rememberMe : rememberMe // ignore: cast_nullable_to_non_nullable
as bool,showPassword: null == showPassword ? _self.showPassword : showPassword // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}
/// Create a copy of AuthUiModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$LoginCredentialsCopyWith<$Res>? get user {
    if (_self.user == null) {
    return null;
  }

  return $LoginCredentialsCopyWith<$Res>(_self.user!, (value) {
    return _then(_self.copyWith(user: value));
  });
}
}


/// Adds pattern-matching-related methods to [AuthUiModel].
extension AuthUiModelPatterns on AuthUiModel {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AuthUiModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AuthUiModel() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AuthUiModel value)  $default,){
final _that = this;
switch (_that) {
case _AuthUiModel():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AuthUiModel value)?  $default,){
final _that = this;
switch (_that) {
case _AuthUiModel() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( LoginCredentials? user,  bool rememberMe,  bool showPassword)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AuthUiModel() when $default != null:
return $default(_that.user,_that.rememberMe,_that.showPassword);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( LoginCredentials? user,  bool rememberMe,  bool showPassword)  $default,) {final _that = this;
switch (_that) {
case _AuthUiModel():
return $default(_that.user,_that.rememberMe,_that.showPassword);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( LoginCredentials? user,  bool rememberMe,  bool showPassword)?  $default,) {final _that = this;
switch (_that) {
case _AuthUiModel() when $default != null:
return $default(_that.user,_that.rememberMe,_that.showPassword);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AuthUiModel implements AuthUiModel {
  const _AuthUiModel({this.user, this.rememberMe = false, this.showPassword = false});
  factory _AuthUiModel.fromJson(Map<String, dynamic> json) => _$AuthUiModelFromJson(json);

@override final  LoginCredentials? user;
@override@JsonKey() final  bool rememberMe;
@override@JsonKey() final  bool showPassword;

/// Create a copy of AuthUiModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AuthUiModelCopyWith<_AuthUiModel> get copyWith => __$AuthUiModelCopyWithImpl<_AuthUiModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AuthUiModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AuthUiModel&&(identical(other.user, user) || other.user == user)&&(identical(other.rememberMe, rememberMe) || other.rememberMe == rememberMe)&&(identical(other.showPassword, showPassword) || other.showPassword == showPassword));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,user,rememberMe,showPassword);

@override
String toString() {
  return 'AuthUiModel(user: $user, rememberMe: $rememberMe, showPassword: $showPassword)';
}


}

/// @nodoc
abstract mixin class _$AuthUiModelCopyWith<$Res> implements $AuthUiModelCopyWith<$Res> {
  factory _$AuthUiModelCopyWith(_AuthUiModel value, $Res Function(_AuthUiModel) _then) = __$AuthUiModelCopyWithImpl;
@override @useResult
$Res call({
 LoginCredentials? user, bool rememberMe, bool showPassword
});


@override $LoginCredentialsCopyWith<$Res>? get user;

}
/// @nodoc
class __$AuthUiModelCopyWithImpl<$Res>
    implements _$AuthUiModelCopyWith<$Res> {
  __$AuthUiModelCopyWithImpl(this._self, this._then);

  final _AuthUiModel _self;
  final $Res Function(_AuthUiModel) _then;

/// Create a copy of AuthUiModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? user = freezed,Object? rememberMe = null,Object? showPassword = null,}) {
  return _then(_AuthUiModel(
user: freezed == user ? _self.user : user // ignore: cast_nullable_to_non_nullable
as LoginCredentials?,rememberMe: null == rememberMe ? _self.rememberMe : rememberMe // ignore: cast_nullable_to_non_nullable
as bool,showPassword: null == showPassword ? _self.showPassword : showPassword // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

/// Create a copy of AuthUiModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$LoginCredentialsCopyWith<$Res>? get user {
    if (_self.user == null) {
    return null;
  }

  return $LoginCredentialsCopyWith<$Res>(_self.user!, (value) {
    return _then(_self.copyWith(user: value));
  });
}
}

// dart format on
