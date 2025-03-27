// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'detected_outline.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

DetectedOutline _$DetectedOutlineFromJson(Map<String, dynamic> json) {
  return _DetectedOutline.fromJson(json);
}

/// @nodoc
mixin _$DetectedOutline {
  @RectConverter()
  Rect get boundingRect => throw _privateConstructorUsedError;
  @ContourPointsConverter()
  List<List<Offset>> get contourPoints => throw _privateConstructorUsedError;

  /// Serializes this DetectedOutline to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of DetectedOutline
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $DetectedOutlineCopyWith<DetectedOutline> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $DetectedOutlineCopyWith<$Res> {
  factory $DetectedOutlineCopyWith(
          DetectedOutline value, $Res Function(DetectedOutline) then) =
      _$DetectedOutlineCopyWithImpl<$Res, DetectedOutline>;
  @useResult
  $Res call(
      {@RectConverter() Rect boundingRect,
      @ContourPointsConverter() List<List<Offset>> contourPoints});
}

/// @nodoc
class _$DetectedOutlineCopyWithImpl<$Res, $Val extends DetectedOutline>
    implements $DetectedOutlineCopyWith<$Res> {
  _$DetectedOutlineCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of DetectedOutline
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? boundingRect = null,
    Object? contourPoints = null,
  }) {
    return _then(_value.copyWith(
      boundingRect: null == boundingRect
          ? _value.boundingRect
          : boundingRect // ignore: cast_nullable_to_non_nullable
              as Rect,
      contourPoints: null == contourPoints
          ? _value.contourPoints
          : contourPoints // ignore: cast_nullable_to_non_nullable
              as List<List<Offset>>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$DetectedOutlineImplCopyWith<$Res>
    implements $DetectedOutlineCopyWith<$Res> {
  factory _$$DetectedOutlineImplCopyWith(_$DetectedOutlineImpl value,
          $Res Function(_$DetectedOutlineImpl) then) =
      __$$DetectedOutlineImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@RectConverter() Rect boundingRect,
      @ContourPointsConverter() List<List<Offset>> contourPoints});
}

/// @nodoc
class __$$DetectedOutlineImplCopyWithImpl<$Res>
    extends _$DetectedOutlineCopyWithImpl<$Res, _$DetectedOutlineImpl>
    implements _$$DetectedOutlineImplCopyWith<$Res> {
  __$$DetectedOutlineImplCopyWithImpl(
      _$DetectedOutlineImpl _value, $Res Function(_$DetectedOutlineImpl) _then)
      : super(_value, _then);

  /// Create a copy of DetectedOutline
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? boundingRect = null,
    Object? contourPoints = null,
  }) {
    return _then(_$DetectedOutlineImpl(
      boundingRect: null == boundingRect
          ? _value.boundingRect
          : boundingRect // ignore: cast_nullable_to_non_nullable
              as Rect,
      contourPoints: null == contourPoints
          ? _value._contourPoints
          : contourPoints // ignore: cast_nullable_to_non_nullable
              as List<List<Offset>>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$DetectedOutlineImpl implements _DetectedOutline {
  const _$DetectedOutlineImpl(
      {@RectConverter() required this.boundingRect,
      @ContourPointsConverter()
      required final List<List<Offset>> contourPoints})
      : _contourPoints = contourPoints;

  factory _$DetectedOutlineImpl.fromJson(Map<String, dynamic> json) =>
      _$$DetectedOutlineImplFromJson(json);

  @override
  @RectConverter()
  final Rect boundingRect;
  final List<List<Offset>> _contourPoints;
  @override
  @ContourPointsConverter()
  List<List<Offset>> get contourPoints {
    if (_contourPoints is EqualUnmodifiableListView) return _contourPoints;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_contourPoints);
  }

  @override
  String toString() {
    return 'DetectedOutline(boundingRect: $boundingRect, contourPoints: $contourPoints)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DetectedOutlineImpl &&
            (identical(other.boundingRect, boundingRect) ||
                other.boundingRect == boundingRect) &&
            const DeepCollectionEquality()
                .equals(other._contourPoints, _contourPoints));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, boundingRect,
      const DeepCollectionEquality().hash(_contourPoints));

  /// Create a copy of DetectedOutline
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$DetectedOutlineImplCopyWith<_$DetectedOutlineImpl> get copyWith =>
      __$$DetectedOutlineImplCopyWithImpl<_$DetectedOutlineImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$DetectedOutlineImplToJson(
      this,
    );
  }
}

abstract class _DetectedOutline implements DetectedOutline {
  const factory _DetectedOutline(
      {@RectConverter() required final Rect boundingRect,
      @ContourPointsConverter()
      required final List<List<Offset>> contourPoints}) = _$DetectedOutlineImpl;

  factory _DetectedOutline.fromJson(Map<String, dynamic> json) =
      _$DetectedOutlineImpl.fromJson;

  @override
  @RectConverter()
  Rect get boundingRect;
  @override
  @ContourPointsConverter()
  List<List<Offset>> get contourPoints;

  /// Create a copy of DetectedOutline
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$DetectedOutlineImplCopyWith<_$DetectedOutlineImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
