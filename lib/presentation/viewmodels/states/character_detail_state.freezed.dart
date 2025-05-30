// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'character_detail_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

CharacterDetailState _$CharacterDetailStateFromJson(Map<String, dynamic> json) {
  return _CharacterDetailState.fromJson(json);
}

/// @nodoc
mixin _$CharacterDetailState {
  /// The character being viewed
  CharacterView? get character => throw _privateConstructorUsedError;

  /// Related characters (usually from the same work)
  List<CharacterView> get relatedCharacters =>
      throw _privateConstructorUsedError;

  /// Selected format index
  int get selectedFormat => throw _privateConstructorUsedError;

  /// Available image formats
  @JsonKey(includeFromJson: false, includeToJson: false)
  List<CharacterFormatInfo> get availableFormats =>
      throw _privateConstructorUsedError;

  /// Path to original image
  String? get originalPath => throw _privateConstructorUsedError;

  /// Path to binary image
  String? get binaryPath => throw _privateConstructorUsedError;

  /// Path to transparent image
  String? get transparentPath => throw _privateConstructorUsedError;

  /// Path to square binary image
  String? get squareBinaryPath => throw _privateConstructorUsedError;

  /// Path to square transparent image
  String? get squareTransparentPath => throw _privateConstructorUsedError;

  /// Path to SVG outline
  String? get outlinePath => throw _privateConstructorUsedError;

  /// Path to thumbnail image
  String? get thumbnailPath => throw _privateConstructorUsedError;

  /// Whether loading is in progress
  bool get isLoading => throw _privateConstructorUsedError;

  /// Error message if loading failed
  String? get error => throw _privateConstructorUsedError;

  /// Serializes this CharacterDetailState to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of CharacterDetailState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CharacterDetailStateCopyWith<CharacterDetailState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CharacterDetailStateCopyWith<$Res> {
  factory $CharacterDetailStateCopyWith(CharacterDetailState value,
          $Res Function(CharacterDetailState) then) =
      _$CharacterDetailStateCopyWithImpl<$Res, CharacterDetailState>;
  @useResult
  $Res call(
      {CharacterView? character,
      List<CharacterView> relatedCharacters,
      int selectedFormat,
      @JsonKey(includeFromJson: false, includeToJson: false)
      List<CharacterFormatInfo> availableFormats,
      String? originalPath,
      String? binaryPath,
      String? transparentPath,
      String? squareBinaryPath,
      String? squareTransparentPath,
      String? outlinePath,
      String? thumbnailPath,
      bool isLoading,
      String? error});

  $CharacterViewCopyWith<$Res>? get character;
}

/// @nodoc
class _$CharacterDetailStateCopyWithImpl<$Res,
        $Val extends CharacterDetailState>
    implements $CharacterDetailStateCopyWith<$Res> {
  _$CharacterDetailStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of CharacterDetailState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? character = freezed,
    Object? relatedCharacters = null,
    Object? selectedFormat = null,
    Object? availableFormats = null,
    Object? originalPath = freezed,
    Object? binaryPath = freezed,
    Object? transparentPath = freezed,
    Object? squareBinaryPath = freezed,
    Object? squareTransparentPath = freezed,
    Object? outlinePath = freezed,
    Object? thumbnailPath = freezed,
    Object? isLoading = null,
    Object? error = freezed,
  }) {
    return _then(_value.copyWith(
      character: freezed == character
          ? _value.character
          : character // ignore: cast_nullable_to_non_nullable
              as CharacterView?,
      relatedCharacters: null == relatedCharacters
          ? _value.relatedCharacters
          : relatedCharacters // ignore: cast_nullable_to_non_nullable
              as List<CharacterView>,
      selectedFormat: null == selectedFormat
          ? _value.selectedFormat
          : selectedFormat // ignore: cast_nullable_to_non_nullable
              as int,
      availableFormats: null == availableFormats
          ? _value.availableFormats
          : availableFormats // ignore: cast_nullable_to_non_nullable
              as List<CharacterFormatInfo>,
      originalPath: freezed == originalPath
          ? _value.originalPath
          : originalPath // ignore: cast_nullable_to_non_nullable
              as String?,
      binaryPath: freezed == binaryPath
          ? _value.binaryPath
          : binaryPath // ignore: cast_nullable_to_non_nullable
              as String?,
      transparentPath: freezed == transparentPath
          ? _value.transparentPath
          : transparentPath // ignore: cast_nullable_to_non_nullable
              as String?,
      squareBinaryPath: freezed == squareBinaryPath
          ? _value.squareBinaryPath
          : squareBinaryPath // ignore: cast_nullable_to_non_nullable
              as String?,
      squareTransparentPath: freezed == squareTransparentPath
          ? _value.squareTransparentPath
          : squareTransparentPath // ignore: cast_nullable_to_non_nullable
              as String?,
      outlinePath: freezed == outlinePath
          ? _value.outlinePath
          : outlinePath // ignore: cast_nullable_to_non_nullable
              as String?,
      thumbnailPath: freezed == thumbnailPath
          ? _value.thumbnailPath
          : thumbnailPath // ignore: cast_nullable_to_non_nullable
              as String?,
      isLoading: null == isLoading
          ? _value.isLoading
          : isLoading // ignore: cast_nullable_to_non_nullable
              as bool,
      error: freezed == error
          ? _value.error
          : error // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }

  /// Create a copy of CharacterDetailState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $CharacterViewCopyWith<$Res>? get character {
    if (_value.character == null) {
      return null;
    }

    return $CharacterViewCopyWith<$Res>(_value.character!, (value) {
      return _then(_value.copyWith(character: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$CharacterDetailStateImplCopyWith<$Res>
    implements $CharacterDetailStateCopyWith<$Res> {
  factory _$$CharacterDetailStateImplCopyWith(_$CharacterDetailStateImpl value,
          $Res Function(_$CharacterDetailStateImpl) then) =
      __$$CharacterDetailStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {CharacterView? character,
      List<CharacterView> relatedCharacters,
      int selectedFormat,
      @JsonKey(includeFromJson: false, includeToJson: false)
      List<CharacterFormatInfo> availableFormats,
      String? originalPath,
      String? binaryPath,
      String? transparentPath,
      String? squareBinaryPath,
      String? squareTransparentPath,
      String? outlinePath,
      String? thumbnailPath,
      bool isLoading,
      String? error});

  @override
  $CharacterViewCopyWith<$Res>? get character;
}

/// @nodoc
class __$$CharacterDetailStateImplCopyWithImpl<$Res>
    extends _$CharacterDetailStateCopyWithImpl<$Res, _$CharacterDetailStateImpl>
    implements _$$CharacterDetailStateImplCopyWith<$Res> {
  __$$CharacterDetailStateImplCopyWithImpl(_$CharacterDetailStateImpl _value,
      $Res Function(_$CharacterDetailStateImpl) _then)
      : super(_value, _then);

  /// Create a copy of CharacterDetailState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? character = freezed,
    Object? relatedCharacters = null,
    Object? selectedFormat = null,
    Object? availableFormats = null,
    Object? originalPath = freezed,
    Object? binaryPath = freezed,
    Object? transparentPath = freezed,
    Object? squareBinaryPath = freezed,
    Object? squareTransparentPath = freezed,
    Object? outlinePath = freezed,
    Object? thumbnailPath = freezed,
    Object? isLoading = null,
    Object? error = freezed,
  }) {
    return _then(_$CharacterDetailStateImpl(
      character: freezed == character
          ? _value.character
          : character // ignore: cast_nullable_to_non_nullable
              as CharacterView?,
      relatedCharacters: null == relatedCharacters
          ? _value._relatedCharacters
          : relatedCharacters // ignore: cast_nullable_to_non_nullable
              as List<CharacterView>,
      selectedFormat: null == selectedFormat
          ? _value.selectedFormat
          : selectedFormat // ignore: cast_nullable_to_non_nullable
              as int,
      availableFormats: null == availableFormats
          ? _value._availableFormats
          : availableFormats // ignore: cast_nullable_to_non_nullable
              as List<CharacterFormatInfo>,
      originalPath: freezed == originalPath
          ? _value.originalPath
          : originalPath // ignore: cast_nullable_to_non_nullable
              as String?,
      binaryPath: freezed == binaryPath
          ? _value.binaryPath
          : binaryPath // ignore: cast_nullable_to_non_nullable
              as String?,
      transparentPath: freezed == transparentPath
          ? _value.transparentPath
          : transparentPath // ignore: cast_nullable_to_non_nullable
              as String?,
      squareBinaryPath: freezed == squareBinaryPath
          ? _value.squareBinaryPath
          : squareBinaryPath // ignore: cast_nullable_to_non_nullable
              as String?,
      squareTransparentPath: freezed == squareTransparentPath
          ? _value.squareTransparentPath
          : squareTransparentPath // ignore: cast_nullable_to_non_nullable
              as String?,
      outlinePath: freezed == outlinePath
          ? _value.outlinePath
          : outlinePath // ignore: cast_nullable_to_non_nullable
              as String?,
      thumbnailPath: freezed == thumbnailPath
          ? _value.thumbnailPath
          : thumbnailPath // ignore: cast_nullable_to_non_nullable
              as String?,
      isLoading: null == isLoading
          ? _value.isLoading
          : isLoading // ignore: cast_nullable_to_non_nullable
              as bool,
      error: freezed == error
          ? _value.error
          : error // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$CharacterDetailStateImpl extends _CharacterDetailState {
  const _$CharacterDetailStateImpl(
      {this.character,
      final List<CharacterView> relatedCharacters = const [],
      this.selectedFormat = 0,
      @JsonKey(includeFromJson: false, includeToJson: false)
      final List<CharacterFormatInfo> availableFormats = const [],
      this.originalPath,
      this.binaryPath,
      this.transparentPath,
      this.squareBinaryPath,
      this.squareTransparentPath,
      this.outlinePath,
      this.thumbnailPath,
      this.isLoading = false,
      this.error})
      : _relatedCharacters = relatedCharacters,
        _availableFormats = availableFormats,
        super._();

  factory _$CharacterDetailStateImpl.fromJson(Map<String, dynamic> json) =>
      _$$CharacterDetailStateImplFromJson(json);

  /// The character being viewed
  @override
  final CharacterView? character;

  /// Related characters (usually from the same work)
  final List<CharacterView> _relatedCharacters;

  /// Related characters (usually from the same work)
  @override
  @JsonKey()
  List<CharacterView> get relatedCharacters {
    if (_relatedCharacters is EqualUnmodifiableListView)
      return _relatedCharacters;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_relatedCharacters);
  }

  /// Selected format index
  @override
  @JsonKey()
  final int selectedFormat;

  /// Available image formats
  final List<CharacterFormatInfo> _availableFormats;

  /// Available image formats
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  List<CharacterFormatInfo> get availableFormats {
    if (_availableFormats is EqualUnmodifiableListView)
      return _availableFormats;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_availableFormats);
  }

  /// Path to original image
  @override
  final String? originalPath;

  /// Path to binary image
  @override
  final String? binaryPath;

  /// Path to transparent image
  @override
  final String? transparentPath;

  /// Path to square binary image
  @override
  final String? squareBinaryPath;

  /// Path to square transparent image
  @override
  final String? squareTransparentPath;

  /// Path to SVG outline
  @override
  final String? outlinePath;

  /// Path to thumbnail image
  @override
  final String? thumbnailPath;

  /// Whether loading is in progress
  @override
  @JsonKey()
  final bool isLoading;

  /// Error message if loading failed
  @override
  final String? error;

  @override
  String toString() {
    return 'CharacterDetailState(character: $character, relatedCharacters: $relatedCharacters, selectedFormat: $selectedFormat, availableFormats: $availableFormats, originalPath: $originalPath, binaryPath: $binaryPath, transparentPath: $transparentPath, squareBinaryPath: $squareBinaryPath, squareTransparentPath: $squareTransparentPath, outlinePath: $outlinePath, thumbnailPath: $thumbnailPath, isLoading: $isLoading, error: $error)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CharacterDetailStateImpl &&
            (identical(other.character, character) ||
                other.character == character) &&
            const DeepCollectionEquality()
                .equals(other._relatedCharacters, _relatedCharacters) &&
            (identical(other.selectedFormat, selectedFormat) ||
                other.selectedFormat == selectedFormat) &&
            const DeepCollectionEquality()
                .equals(other._availableFormats, _availableFormats) &&
            (identical(other.originalPath, originalPath) ||
                other.originalPath == originalPath) &&
            (identical(other.binaryPath, binaryPath) ||
                other.binaryPath == binaryPath) &&
            (identical(other.transparentPath, transparentPath) ||
                other.transparentPath == transparentPath) &&
            (identical(other.squareBinaryPath, squareBinaryPath) ||
                other.squareBinaryPath == squareBinaryPath) &&
            (identical(other.squareTransparentPath, squareTransparentPath) ||
                other.squareTransparentPath == squareTransparentPath) &&
            (identical(other.outlinePath, outlinePath) ||
                other.outlinePath == outlinePath) &&
            (identical(other.thumbnailPath, thumbnailPath) ||
                other.thumbnailPath == thumbnailPath) &&
            (identical(other.isLoading, isLoading) ||
                other.isLoading == isLoading) &&
            (identical(other.error, error) || other.error == error));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      character,
      const DeepCollectionEquality().hash(_relatedCharacters),
      selectedFormat,
      const DeepCollectionEquality().hash(_availableFormats),
      originalPath,
      binaryPath,
      transparentPath,
      squareBinaryPath,
      squareTransparentPath,
      outlinePath,
      thumbnailPath,
      isLoading,
      error);

  /// Create a copy of CharacterDetailState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CharacterDetailStateImplCopyWith<_$CharacterDetailStateImpl>
      get copyWith =>
          __$$CharacterDetailStateImplCopyWithImpl<_$CharacterDetailStateImpl>(
              this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$CharacterDetailStateImplToJson(
      this,
    );
  }
}

abstract class _CharacterDetailState extends CharacterDetailState {
  const factory _CharacterDetailState(
      {final CharacterView? character,
      final List<CharacterView> relatedCharacters,
      final int selectedFormat,
      @JsonKey(includeFromJson: false, includeToJson: false)
      final List<CharacterFormatInfo> availableFormats,
      final String? originalPath,
      final String? binaryPath,
      final String? transparentPath,
      final String? squareBinaryPath,
      final String? squareTransparentPath,
      final String? outlinePath,
      final String? thumbnailPath,
      final bool isLoading,
      final String? error}) = _$CharacterDetailStateImpl;
  const _CharacterDetailState._() : super._();

  factory _CharacterDetailState.fromJson(Map<String, dynamic> json) =
      _$CharacterDetailStateImpl.fromJson;

  /// The character being viewed
  @override
  CharacterView? get character;

  /// Related characters (usually from the same work)
  @override
  List<CharacterView> get relatedCharacters;

  /// Selected format index
  @override
  int get selectedFormat;

  /// Available image formats
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  List<CharacterFormatInfo> get availableFormats;

  /// Path to original image
  @override
  String? get originalPath;

  /// Path to binary image
  @override
  String? get binaryPath;

  /// Path to transparent image
  @override
  String? get transparentPath;

  /// Path to square binary image
  @override
  String? get squareBinaryPath;

  /// Path to square transparent image
  @override
  String? get squareTransparentPath;

  /// Path to SVG outline
  @override
  String? get outlinePath;

  /// Path to thumbnail image
  @override
  String? get thumbnailPath;

  /// Whether loading is in progress
  @override
  bool get isLoading;

  /// Error message if loading failed
  @override
  String? get error;

  /// Create a copy of CharacterDetailState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CharacterDetailStateImplCopyWith<_$CharacterDetailStateImpl>
      get copyWith => throw _privateConstructorUsedError;
}
