// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'expansion_tile_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$ExpansionTileState {
  /// 所有 ExpansionTile 的状态映射
  /// key: 唯一标识符，value: 是否展开
  Map<String, bool> get tileStates => throw _privateConstructorUsedError;

  /// Create a copy of ExpansionTileState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ExpansionTileStateCopyWith<ExpansionTileState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ExpansionTileStateCopyWith<$Res> {
  factory $ExpansionTileStateCopyWith(
          ExpansionTileState value, $Res Function(ExpansionTileState) then) =
      _$ExpansionTileStateCopyWithImpl<$Res, ExpansionTileState>;
  @useResult
  $Res call({Map<String, bool> tileStates});
}

/// @nodoc
class _$ExpansionTileStateCopyWithImpl<$Res, $Val extends ExpansionTileState>
    implements $ExpansionTileStateCopyWith<$Res> {
  _$ExpansionTileStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ExpansionTileState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? tileStates = null,
  }) {
    return _then(_value.copyWith(
      tileStates: null == tileStates
          ? _value.tileStates
          : tileStates // ignore: cast_nullable_to_non_nullable
              as Map<String, bool>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ExpansionTileStateImplCopyWith<$Res>
    implements $ExpansionTileStateCopyWith<$Res> {
  factory _$$ExpansionTileStateImplCopyWith(_$ExpansionTileStateImpl value,
          $Res Function(_$ExpansionTileStateImpl) then) =
      __$$ExpansionTileStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({Map<String, bool> tileStates});
}

/// @nodoc
class __$$ExpansionTileStateImplCopyWithImpl<$Res>
    extends _$ExpansionTileStateCopyWithImpl<$Res, _$ExpansionTileStateImpl>
    implements _$$ExpansionTileStateImplCopyWith<$Res> {
  __$$ExpansionTileStateImplCopyWithImpl(_$ExpansionTileStateImpl _value,
      $Res Function(_$ExpansionTileStateImpl) _then)
      : super(_value, _then);

  /// Create a copy of ExpansionTileState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? tileStates = null,
  }) {
    return _then(_$ExpansionTileStateImpl(
      tileStates: null == tileStates
          ? _value._tileStates
          : tileStates // ignore: cast_nullable_to_non_nullable
              as Map<String, bool>,
    ));
  }
}

/// @nodoc

class _$ExpansionTileStateImpl implements _ExpansionTileState {
  const _$ExpansionTileStateImpl(
      {final Map<String, bool> tileStates = const <String, bool>{}})
      : _tileStates = tileStates;

  /// 所有 ExpansionTile 的状态映射
  /// key: 唯一标识符，value: 是否展开
  final Map<String, bool> _tileStates;

  /// 所有 ExpansionTile 的状态映射
  /// key: 唯一标识符，value: 是否展开
  @override
  @JsonKey()
  Map<String, bool> get tileStates {
    if (_tileStates is EqualUnmodifiableMapView) return _tileStates;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_tileStates);
  }

  @override
  String toString() {
    return 'ExpansionTileState(tileStates: $tileStates)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ExpansionTileStateImpl &&
            const DeepCollectionEquality()
                .equals(other._tileStates, _tileStates));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType, const DeepCollectionEquality().hash(_tileStates));

  /// Create a copy of ExpansionTileState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ExpansionTileStateImplCopyWith<_$ExpansionTileStateImpl> get copyWith =>
      __$$ExpansionTileStateImplCopyWithImpl<_$ExpansionTileStateImpl>(
          this, _$identity);
}

abstract class _ExpansionTileState implements ExpansionTileState {
  const factory _ExpansionTileState({final Map<String, bool> tileStates}) =
      _$ExpansionTileStateImpl;

  /// 所有 ExpansionTile 的状态映射
  /// key: 唯一标识符，value: 是否展开
  @override
  Map<String, bool> get tileStates;

  /// Create a copy of ExpansionTileState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ExpansionTileStateImplCopyWith<_$ExpansionTileStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
