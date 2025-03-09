// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'practice_page.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

PageSize _$PageSizeFromJson(Map<String, dynamic> json) {
  return _PageSize.fromJson(json);
}

/// @nodoc
mixin _$PageSize {
  /// 尺寸单位 (例如: 'mm')
  String get unit => throw _privateConstructorUsedError;

  /// 分辨率单位 (例如: 'dpi')
  String get resUnit => throw _privateConstructorUsedError;

  /// 分辨率单位值
  int get resUnitValue => throw _privateConstructorUsedError;

  /// 宽度 (默认A4宽度210mm)
  double get width => throw _privateConstructorUsedError;

  /// 高度 (默认A4高度297mm)
  double get height => throw _privateConstructorUsedError;

  /// Serializes this PageSize to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of PageSize
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PageSizeCopyWith<PageSize> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PageSizeCopyWith<$Res> {
  factory $PageSizeCopyWith(PageSize value, $Res Function(PageSize) then) =
      _$PageSizeCopyWithImpl<$Res, PageSize>;
  @useResult
  $Res call(
      {String unit,
      String resUnit,
      int resUnitValue,
      double width,
      double height});
}

/// @nodoc
class _$PageSizeCopyWithImpl<$Res, $Val extends PageSize>
    implements $PageSizeCopyWith<$Res> {
  _$PageSizeCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PageSize
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? unit = null,
    Object? resUnit = null,
    Object? resUnitValue = null,
    Object? width = null,
    Object? height = null,
  }) {
    return _then(_value.copyWith(
      unit: null == unit
          ? _value.unit
          : unit // ignore: cast_nullable_to_non_nullable
              as String,
      resUnit: null == resUnit
          ? _value.resUnit
          : resUnit // ignore: cast_nullable_to_non_nullable
              as String,
      resUnitValue: null == resUnitValue
          ? _value.resUnitValue
          : resUnitValue // ignore: cast_nullable_to_non_nullable
              as int,
      width: null == width
          ? _value.width
          : width // ignore: cast_nullable_to_non_nullable
              as double,
      height: null == height
          ? _value.height
          : height // ignore: cast_nullable_to_non_nullable
              as double,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$PageSizeImplCopyWith<$Res>
    implements $PageSizeCopyWith<$Res> {
  factory _$$PageSizeImplCopyWith(
          _$PageSizeImpl value, $Res Function(_$PageSizeImpl) then) =
      __$$PageSizeImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String unit,
      String resUnit,
      int resUnitValue,
      double width,
      double height});
}

/// @nodoc
class __$$PageSizeImplCopyWithImpl<$Res>
    extends _$PageSizeCopyWithImpl<$Res, _$PageSizeImpl>
    implements _$$PageSizeImplCopyWith<$Res> {
  __$$PageSizeImplCopyWithImpl(
      _$PageSizeImpl _value, $Res Function(_$PageSizeImpl) _then)
      : super(_value, _then);

  /// Create a copy of PageSize
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? unit = null,
    Object? resUnit = null,
    Object? resUnitValue = null,
    Object? width = null,
    Object? height = null,
  }) {
    return _then(_$PageSizeImpl(
      unit: null == unit
          ? _value.unit
          : unit // ignore: cast_nullable_to_non_nullable
              as String,
      resUnit: null == resUnit
          ? _value.resUnit
          : resUnit // ignore: cast_nullable_to_non_nullable
              as String,
      resUnitValue: null == resUnitValue
          ? _value.resUnitValue
          : resUnitValue // ignore: cast_nullable_to_non_nullable
              as int,
      width: null == width
          ? _value.width
          : width // ignore: cast_nullable_to_non_nullable
              as double,
      height: null == height
          ? _value.height
          : height // ignore: cast_nullable_to_non_nullable
              as double,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$PageSizeImpl extends _PageSize {
  const _$PageSizeImpl(
      {this.unit = 'mm',
      this.resUnit = 'dpi',
      this.resUnitValue = 300,
      this.width = 210.0,
      this.height = 297.0})
      : super._();

  factory _$PageSizeImpl.fromJson(Map<String, dynamic> json) =>
      _$$PageSizeImplFromJson(json);

  /// 尺寸单位 (例如: 'mm')
  @override
  @JsonKey()
  final String unit;

  /// 分辨率单位 (例如: 'dpi')
  @override
  @JsonKey()
  final String resUnit;

  /// 分辨率单位值
  @override
  @JsonKey()
  final int resUnitValue;

  /// 宽度 (默认A4宽度210mm)
  @override
  @JsonKey()
  final double width;

  /// 高度 (默认A4高度297mm)
  @override
  @JsonKey()
  final double height;

  @override
  String toString() {
    return 'PageSize(unit: $unit, resUnit: $resUnit, resUnitValue: $resUnitValue, width: $width, height: $height)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PageSizeImpl &&
            (identical(other.unit, unit) || other.unit == unit) &&
            (identical(other.resUnit, resUnit) || other.resUnit == resUnit) &&
            (identical(other.resUnitValue, resUnitValue) ||
                other.resUnitValue == resUnitValue) &&
            (identical(other.width, width) || other.width == width) &&
            (identical(other.height, height) || other.height == height));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, unit, resUnit, resUnitValue, width, height);

  /// Create a copy of PageSize
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PageSizeImplCopyWith<_$PageSizeImpl> get copyWith =>
      __$$PageSizeImplCopyWithImpl<_$PageSizeImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$PageSizeImplToJson(
      this,
    );
  }
}

abstract class _PageSize extends PageSize {
  const factory _PageSize(
      {final String unit,
      final String resUnit,
      final int resUnitValue,
      final double width,
      final double height}) = _$PageSizeImpl;
  const _PageSize._() : super._();

  factory _PageSize.fromJson(Map<String, dynamic> json) =
      _$PageSizeImpl.fromJson;

  /// 尺寸单位 (例如: 'mm')
  @override
  String get unit;

  /// 分辨率单位 (例如: 'dpi')
  @override
  String get resUnit;

  /// 分辨率单位值
  @override
  int get resUnitValue;

  /// 宽度 (默认A4宽度210mm)
  @override
  double get width;

  /// 高度 (默认A4高度297mm)
  @override
  double get height;

  /// Create a copy of PageSize
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PageSizeImplCopyWith<_$PageSizeImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

PracticePage _$PracticePageFromJson(Map<String, dynamic> json) {
  return _PracticePage.fromJson(json);
}

/// @nodoc
mixin _$PracticePage {
  /// 页面序号
  int get index => throw _privateConstructorUsedError;

  /// 页面尺寸
  PageSize get size => throw _privateConstructorUsedError;

  /// 页面图层列表
  List<PracticeLayer> get layers => throw _privateConstructorUsedError;

  /// 创建时间
  @JsonKey(name: 'create_time')
  DateTime get createTime => throw _privateConstructorUsedError;

  /// 更新时间
  @JsonKey(name: 'update_time')
  DateTime get updateTime => throw _privateConstructorUsedError;

  /// Serializes this PracticePage to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of PracticePage
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PracticePageCopyWith<PracticePage> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PracticePageCopyWith<$Res> {
  factory $PracticePageCopyWith(
          PracticePage value, $Res Function(PracticePage) then) =
      _$PracticePageCopyWithImpl<$Res, PracticePage>;
  @useResult
  $Res call(
      {int index,
      PageSize size,
      List<PracticeLayer> layers,
      @JsonKey(name: 'create_time') DateTime createTime,
      @JsonKey(name: 'update_time') DateTime updateTime});

  $PageSizeCopyWith<$Res> get size;
}

/// @nodoc
class _$PracticePageCopyWithImpl<$Res, $Val extends PracticePage>
    implements $PracticePageCopyWith<$Res> {
  _$PracticePageCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PracticePage
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? index = null,
    Object? size = null,
    Object? layers = null,
    Object? createTime = null,
    Object? updateTime = null,
  }) {
    return _then(_value.copyWith(
      index: null == index
          ? _value.index
          : index // ignore: cast_nullable_to_non_nullable
              as int,
      size: null == size
          ? _value.size
          : size // ignore: cast_nullable_to_non_nullable
              as PageSize,
      layers: null == layers
          ? _value.layers
          : layers // ignore: cast_nullable_to_non_nullable
              as List<PracticeLayer>,
      createTime: null == createTime
          ? _value.createTime
          : createTime // ignore: cast_nullable_to_non_nullable
              as DateTime,
      updateTime: null == updateTime
          ? _value.updateTime
          : updateTime // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ) as $Val);
  }

  /// Create a copy of PracticePage
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $PageSizeCopyWith<$Res> get size {
    return $PageSizeCopyWith<$Res>(_value.size, (value) {
      return _then(_value.copyWith(size: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$PracticePageImplCopyWith<$Res>
    implements $PracticePageCopyWith<$Res> {
  factory _$$PracticePageImplCopyWith(
          _$PracticePageImpl value, $Res Function(_$PracticePageImpl) then) =
      __$$PracticePageImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {int index,
      PageSize size,
      List<PracticeLayer> layers,
      @JsonKey(name: 'create_time') DateTime createTime,
      @JsonKey(name: 'update_time') DateTime updateTime});

  @override
  $PageSizeCopyWith<$Res> get size;
}

/// @nodoc
class __$$PracticePageImplCopyWithImpl<$Res>
    extends _$PracticePageCopyWithImpl<$Res, _$PracticePageImpl>
    implements _$$PracticePageImplCopyWith<$Res> {
  __$$PracticePageImplCopyWithImpl(
      _$PracticePageImpl _value, $Res Function(_$PracticePageImpl) _then)
      : super(_value, _then);

  /// Create a copy of PracticePage
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? index = null,
    Object? size = null,
    Object? layers = null,
    Object? createTime = null,
    Object? updateTime = null,
  }) {
    return _then(_$PracticePageImpl(
      index: null == index
          ? _value.index
          : index // ignore: cast_nullable_to_non_nullable
              as int,
      size: null == size
          ? _value.size
          : size // ignore: cast_nullable_to_non_nullable
              as PageSize,
      layers: null == layers
          ? _value._layers
          : layers // ignore: cast_nullable_to_non_nullable
              as List<PracticeLayer>,
      createTime: null == createTime
          ? _value.createTime
          : createTime // ignore: cast_nullable_to_non_nullable
              as DateTime,
      updateTime: null == updateTime
          ? _value.updateTime
          : updateTime // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$PracticePageImpl extends _PracticePage {
  const _$PracticePageImpl(
      {required this.index,
      this.size = const PageSize(),
      final List<PracticeLayer> layers = const [],
      @JsonKey(name: 'create_time') required this.createTime,
      @JsonKey(name: 'update_time') required this.updateTime})
      : _layers = layers,
        super._();

  factory _$PracticePageImpl.fromJson(Map<String, dynamic> json) =>
      _$$PracticePageImplFromJson(json);

  /// 页面序号
  @override
  final int index;

  /// 页面尺寸
  @override
  @JsonKey()
  final PageSize size;

  /// 页面图层列表
  final List<PracticeLayer> _layers;

  /// 页面图层列表
  @override
  @JsonKey()
  List<PracticeLayer> get layers {
    if (_layers is EqualUnmodifiableListView) return _layers;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_layers);
  }

  /// 创建时间
  @override
  @JsonKey(name: 'create_time')
  final DateTime createTime;

  /// 更新时间
  @override
  @JsonKey(name: 'update_time')
  final DateTime updateTime;

  @override
  String toString() {
    return 'PracticePage(index: $index, size: $size, layers: $layers, createTime: $createTime, updateTime: $updateTime)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PracticePageImpl &&
            (identical(other.index, index) || other.index == index) &&
            (identical(other.size, size) || other.size == size) &&
            const DeepCollectionEquality().equals(other._layers, _layers) &&
            (identical(other.createTime, createTime) ||
                other.createTime == createTime) &&
            (identical(other.updateTime, updateTime) ||
                other.updateTime == updateTime));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, index, size,
      const DeepCollectionEquality().hash(_layers), createTime, updateTime);

  /// Create a copy of PracticePage
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PracticePageImplCopyWith<_$PracticePageImpl> get copyWith =>
      __$$PracticePageImplCopyWithImpl<_$PracticePageImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$PracticePageImplToJson(
      this,
    );
  }
}

abstract class _PracticePage extends PracticePage {
  const factory _PracticePage(
          {required final int index,
          final PageSize size,
          final List<PracticeLayer> layers,
          @JsonKey(name: 'create_time') required final DateTime createTime,
          @JsonKey(name: 'update_time') required final DateTime updateTime}) =
      _$PracticePageImpl;
  const _PracticePage._() : super._();

  factory _PracticePage.fromJson(Map<String, dynamic> json) =
      _$PracticePageImpl.fromJson;

  /// 页面序号
  @override
  int get index;

  /// 页面尺寸
  @override
  PageSize get size;

  /// 页面图层列表
  @override
  List<PracticeLayer> get layers;

  /// 创建时间
  @override
  @JsonKey(name: 'create_time')
  DateTime get createTime;

  /// 更新时间
  @override
  @JsonKey(name: 'update_time')
  DateTime get updateTime;

  /// Create a copy of PracticePage
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PracticePageImplCopyWith<_$PracticePageImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
