// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'processing_options.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

ProcessingOptions _$ProcessingOptionsFromJson(Map<String, dynamic> json) {
  return _ProcessingOptions.fromJson(json);
}

/// @nodoc
mixin _$ProcessingOptions {
  bool get inverted => throw _privateConstructorUsedError;
  bool get showContour => throw _privateConstructorUsedError;
  double get threshold => throw _privateConstructorUsedError;
  double get noiseReduction => throw _privateConstructorUsedError;

  /// Serializes this ProcessingOptions to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ProcessingOptions
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ProcessingOptionsCopyWith<ProcessingOptions> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ProcessingOptionsCopyWith<$Res> {
  factory $ProcessingOptionsCopyWith(
          ProcessingOptions value, $Res Function(ProcessingOptions) then) =
      _$ProcessingOptionsCopyWithImpl<$Res, ProcessingOptions>;
  @useResult
  $Res call(
      {bool inverted,
      bool showContour,
      double threshold,
      double noiseReduction});
}

/// @nodoc
class _$ProcessingOptionsCopyWithImpl<$Res, $Val extends ProcessingOptions>
    implements $ProcessingOptionsCopyWith<$Res> {
  _$ProcessingOptionsCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ProcessingOptions
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? inverted = null,
    Object? showContour = null,
    Object? threshold = null,
    Object? noiseReduction = null,
  }) {
    return _then(_value.copyWith(
      inverted: null == inverted
          ? _value.inverted
          : inverted // ignore: cast_nullable_to_non_nullable
              as bool,
      showContour: null == showContour
          ? _value.showContour
          : showContour // ignore: cast_nullable_to_non_nullable
              as bool,
      threshold: null == threshold
          ? _value.threshold
          : threshold // ignore: cast_nullable_to_non_nullable
              as double,
      noiseReduction: null == noiseReduction
          ? _value.noiseReduction
          : noiseReduction // ignore: cast_nullable_to_non_nullable
              as double,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ProcessingOptionsImplCopyWith<$Res>
    implements $ProcessingOptionsCopyWith<$Res> {
  factory _$$ProcessingOptionsImplCopyWith(_$ProcessingOptionsImpl value,
          $Res Function(_$ProcessingOptionsImpl) then) =
      __$$ProcessingOptionsImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {bool inverted,
      bool showContour,
      double threshold,
      double noiseReduction});
}

/// @nodoc
class __$$ProcessingOptionsImplCopyWithImpl<$Res>
    extends _$ProcessingOptionsCopyWithImpl<$Res, _$ProcessingOptionsImpl>
    implements _$$ProcessingOptionsImplCopyWith<$Res> {
  __$$ProcessingOptionsImplCopyWithImpl(_$ProcessingOptionsImpl _value,
      $Res Function(_$ProcessingOptionsImpl) _then)
      : super(_value, _then);

  /// Create a copy of ProcessingOptions
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? inverted = null,
    Object? showContour = null,
    Object? threshold = null,
    Object? noiseReduction = null,
  }) {
    return _then(_$ProcessingOptionsImpl(
      inverted: null == inverted
          ? _value.inverted
          : inverted // ignore: cast_nullable_to_non_nullable
              as bool,
      showContour: null == showContour
          ? _value.showContour
          : showContour // ignore: cast_nullable_to_non_nullable
              as bool,
      threshold: null == threshold
          ? _value.threshold
          : threshold // ignore: cast_nullable_to_non_nullable
              as double,
      noiseReduction: null == noiseReduction
          ? _value.noiseReduction
          : noiseReduction // ignore: cast_nullable_to_non_nullable
              as double,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ProcessingOptionsImpl implements _ProcessingOptions {
  const _$ProcessingOptionsImpl(
      {this.inverted = false,
      this.showContour = false,
      this.threshold = 128.0,
      this.noiseReduction = 0.5});

  factory _$ProcessingOptionsImpl.fromJson(Map<String, dynamic> json) =>
      _$$ProcessingOptionsImplFromJson(json);

  @override
  @JsonKey()
  final bool inverted;
  @override
  @JsonKey()
  final bool showContour;
  @override
  @JsonKey()
  final double threshold;
  @override
  @JsonKey()
  final double noiseReduction;

  @override
  String toString() {
    return 'ProcessingOptions(inverted: $inverted, showContour: $showContour, threshold: $threshold, noiseReduction: $noiseReduction)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ProcessingOptionsImpl &&
            (identical(other.inverted, inverted) ||
                other.inverted == inverted) &&
            (identical(other.showContour, showContour) ||
                other.showContour == showContour) &&
            (identical(other.threshold, threshold) ||
                other.threshold == threshold) &&
            (identical(other.noiseReduction, noiseReduction) ||
                other.noiseReduction == noiseReduction));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType, inverted, showContour, threshold, noiseReduction);

  /// Create a copy of ProcessingOptions
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ProcessingOptionsImplCopyWith<_$ProcessingOptionsImpl> get copyWith =>
      __$$ProcessingOptionsImplCopyWithImpl<_$ProcessingOptionsImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ProcessingOptionsImplToJson(
      this,
    );
  }
}

abstract class _ProcessingOptions implements ProcessingOptions {
  const factory _ProcessingOptions(
      {final bool inverted,
      final bool showContour,
      final double threshold,
      final double noiseReduction}) = _$ProcessingOptionsImpl;

  factory _ProcessingOptions.fromJson(Map<String, dynamic> json) =
      _$ProcessingOptionsImpl.fromJson;

  @override
  bool get inverted;
  @override
  bool get showContour;
  @override
  double get threshold;
  @override
  double get noiseReduction;

  /// Create a copy of ProcessingOptions
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ProcessingOptionsImplCopyWith<_$ProcessingOptionsImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
