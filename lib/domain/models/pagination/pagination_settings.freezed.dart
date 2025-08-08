// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'pagination_settings.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

PaginationSettings _$PaginationSettingsFromJson(Map<String, dynamic> json) {
  return _PaginationSettings.fromJson(json);
}

/// @nodoc
mixin _$PaginationSettings {
  /// 页面标识符（用于区分不同页面的设置）
  String get pageId => throw _privateConstructorUsedError;

  /// 每页项数
  int get pageSize => throw _privateConstructorUsedError;

  /// 上次更新时间
  DateTime? get lastUpdated => throw _privateConstructorUsedError;

  /// Serializes this PaginationSettings to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of PaginationSettings
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PaginationSettingsCopyWith<PaginationSettings> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PaginationSettingsCopyWith<$Res> {
  factory $PaginationSettingsCopyWith(
          PaginationSettings value, $Res Function(PaginationSettings) then) =
      _$PaginationSettingsCopyWithImpl<$Res, PaginationSettings>;
  @useResult
  $Res call({String pageId, int pageSize, DateTime? lastUpdated});
}

/// @nodoc
class _$PaginationSettingsCopyWithImpl<$Res, $Val extends PaginationSettings>
    implements $PaginationSettingsCopyWith<$Res> {
  _$PaginationSettingsCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PaginationSettings
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? pageId = null,
    Object? pageSize = null,
    Object? lastUpdated = freezed,
  }) {
    return _then(_value.copyWith(
      pageId: null == pageId
          ? _value.pageId
          : pageId // ignore: cast_nullable_to_non_nullable
              as String,
      pageSize: null == pageSize
          ? _value.pageSize
          : pageSize // ignore: cast_nullable_to_non_nullable
              as int,
      lastUpdated: freezed == lastUpdated
          ? _value.lastUpdated
          : lastUpdated // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$PaginationSettingsImplCopyWith<$Res>
    implements $PaginationSettingsCopyWith<$Res> {
  factory _$$PaginationSettingsImplCopyWith(_$PaginationSettingsImpl value,
          $Res Function(_$PaginationSettingsImpl) then) =
      __$$PaginationSettingsImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String pageId, int pageSize, DateTime? lastUpdated});
}

/// @nodoc
class __$$PaginationSettingsImplCopyWithImpl<$Res>
    extends _$PaginationSettingsCopyWithImpl<$Res, _$PaginationSettingsImpl>
    implements _$$PaginationSettingsImplCopyWith<$Res> {
  __$$PaginationSettingsImplCopyWithImpl(_$PaginationSettingsImpl _value,
      $Res Function(_$PaginationSettingsImpl) _then)
      : super(_value, _then);

  /// Create a copy of PaginationSettings
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? pageId = null,
    Object? pageSize = null,
    Object? lastUpdated = freezed,
  }) {
    return _then(_$PaginationSettingsImpl(
      pageId: null == pageId
          ? _value.pageId
          : pageId // ignore: cast_nullable_to_non_nullable
              as String,
      pageSize: null == pageSize
          ? _value.pageSize
          : pageSize // ignore: cast_nullable_to_non_nullable
              as int,
      lastUpdated: freezed == lastUpdated
          ? _value.lastUpdated
          : lastUpdated // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$PaginationSettingsImpl implements _PaginationSettings {
  const _$PaginationSettingsImpl(
      {required this.pageId, this.pageSize = 20, this.lastUpdated});

  factory _$PaginationSettingsImpl.fromJson(Map<String, dynamic> json) =>
      _$$PaginationSettingsImplFromJson(json);

  /// 页面标识符（用于区分不同页面的设置）
  @override
  final String pageId;

  /// 每页项数
  @override
  @JsonKey()
  final int pageSize;

  /// 上次更新时间
  @override
  final DateTime? lastUpdated;

  @override
  String toString() {
    return 'PaginationSettings(pageId: $pageId, pageSize: $pageSize, lastUpdated: $lastUpdated)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PaginationSettingsImpl &&
            (identical(other.pageId, pageId) || other.pageId == pageId) &&
            (identical(other.pageSize, pageSize) ||
                other.pageSize == pageSize) &&
            (identical(other.lastUpdated, lastUpdated) ||
                other.lastUpdated == lastUpdated));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, pageId, pageSize, lastUpdated);

  /// Create a copy of PaginationSettings
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PaginationSettingsImplCopyWith<_$PaginationSettingsImpl> get copyWith =>
      __$$PaginationSettingsImplCopyWithImpl<_$PaginationSettingsImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$PaginationSettingsImplToJson(
      this,
    );
  }
}

abstract class _PaginationSettings implements PaginationSettings {
  const factory _PaginationSettings(
      {required final String pageId,
      final int pageSize,
      final DateTime? lastUpdated}) = _$PaginationSettingsImpl;

  factory _PaginationSettings.fromJson(Map<String, dynamic> json) =
      _$PaginationSettingsImpl.fromJson;

  /// 页面标识符（用于区分不同页面的设置）
  @override
  String get pageId;

  /// 每页项数
  @override
  int get pageSize;

  /// 上次更新时间
  @override
  DateTime? get lastUpdated;

  /// Create a copy of PaginationSettings
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PaginationSettingsImplCopyWith<_$PaginationSettingsImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

AllPaginationSettings _$AllPaginationSettingsFromJson(
    Map<String, dynamic> json) {
  return _AllPaginationSettings.fromJson(json);
}

/// @nodoc
mixin _$AllPaginationSettings {
  /// 按页面ID映射的分页设置
  Map<String, PaginationSettings> get settings =>
      throw _privateConstructorUsedError;

  /// 上次更新时间
  DateTime? get lastUpdated => throw _privateConstructorUsedError;

  /// Serializes this AllPaginationSettings to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of AllPaginationSettings
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $AllPaginationSettingsCopyWith<AllPaginationSettings> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AllPaginationSettingsCopyWith<$Res> {
  factory $AllPaginationSettingsCopyWith(AllPaginationSettings value,
          $Res Function(AllPaginationSettings) then) =
      _$AllPaginationSettingsCopyWithImpl<$Res, AllPaginationSettings>;
  @useResult
  $Res call({Map<String, PaginationSettings> settings, DateTime? lastUpdated});
}

/// @nodoc
class _$AllPaginationSettingsCopyWithImpl<$Res,
        $Val extends AllPaginationSettings>
    implements $AllPaginationSettingsCopyWith<$Res> {
  _$AllPaginationSettingsCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of AllPaginationSettings
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? settings = null,
    Object? lastUpdated = freezed,
  }) {
    return _then(_value.copyWith(
      settings: null == settings
          ? _value.settings
          : settings // ignore: cast_nullable_to_non_nullable
              as Map<String, PaginationSettings>,
      lastUpdated: freezed == lastUpdated
          ? _value.lastUpdated
          : lastUpdated // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$AllPaginationSettingsImplCopyWith<$Res>
    implements $AllPaginationSettingsCopyWith<$Res> {
  factory _$$AllPaginationSettingsImplCopyWith(
          _$AllPaginationSettingsImpl value,
          $Res Function(_$AllPaginationSettingsImpl) then) =
      __$$AllPaginationSettingsImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({Map<String, PaginationSettings> settings, DateTime? lastUpdated});
}

/// @nodoc
class __$$AllPaginationSettingsImplCopyWithImpl<$Res>
    extends _$AllPaginationSettingsCopyWithImpl<$Res,
        _$AllPaginationSettingsImpl>
    implements _$$AllPaginationSettingsImplCopyWith<$Res> {
  __$$AllPaginationSettingsImplCopyWithImpl(_$AllPaginationSettingsImpl _value,
      $Res Function(_$AllPaginationSettingsImpl) _then)
      : super(_value, _then);

  /// Create a copy of AllPaginationSettings
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? settings = null,
    Object? lastUpdated = freezed,
  }) {
    return _then(_$AllPaginationSettingsImpl(
      settings: null == settings
          ? _value._settings
          : settings // ignore: cast_nullable_to_non_nullable
              as Map<String, PaginationSettings>,
      lastUpdated: freezed == lastUpdated
          ? _value.lastUpdated
          : lastUpdated // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$AllPaginationSettingsImpl implements _AllPaginationSettings {
  const _$AllPaginationSettingsImpl(
      {final Map<String, PaginationSettings> settings = const {},
      this.lastUpdated})
      : _settings = settings;

  factory _$AllPaginationSettingsImpl.fromJson(Map<String, dynamic> json) =>
      _$$AllPaginationSettingsImplFromJson(json);

  /// 按页面ID映射的分页设置
  final Map<String, PaginationSettings> _settings;

  /// 按页面ID映射的分页设置
  @override
  @JsonKey()
  Map<String, PaginationSettings> get settings {
    if (_settings is EqualUnmodifiableMapView) return _settings;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_settings);
  }

  /// 上次更新时间
  @override
  final DateTime? lastUpdated;

  @override
  String toString() {
    return 'AllPaginationSettings(settings: $settings, lastUpdated: $lastUpdated)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AllPaginationSettingsImpl &&
            const DeepCollectionEquality().equals(other._settings, _settings) &&
            (identical(other.lastUpdated, lastUpdated) ||
                other.lastUpdated == lastUpdated));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType, const DeepCollectionEquality().hash(_settings), lastUpdated);

  /// Create a copy of AllPaginationSettings
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AllPaginationSettingsImplCopyWith<_$AllPaginationSettingsImpl>
      get copyWith => __$$AllPaginationSettingsImplCopyWithImpl<
          _$AllPaginationSettingsImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$AllPaginationSettingsImplToJson(
      this,
    );
  }
}

abstract class _AllPaginationSettings implements AllPaginationSettings {
  const factory _AllPaginationSettings(
      {final Map<String, PaginationSettings> settings,
      final DateTime? lastUpdated}) = _$AllPaginationSettingsImpl;

  factory _AllPaginationSettings.fromJson(Map<String, dynamic> json) =
      _$AllPaginationSettingsImpl.fromJson;

  /// 按页面ID映射的分页设置
  @override
  Map<String, PaginationSettings> get settings;

  /// 上次更新时间
  @override
  DateTime? get lastUpdated;

  /// Create a copy of AllPaginationSettings
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AllPaginationSettingsImplCopyWith<_$AllPaginationSettingsImpl>
      get copyWith => throw _privateConstructorUsedError;
}
