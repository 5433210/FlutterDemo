// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'batch_selection_provider.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$BatchSelectionState {
  /// 是否启用批量模式
  bool get isBatchMode => throw _privateConstructorUsedError;

  /// 选中的作品ID列表
  Set<String> get selectedWorkIds => throw _privateConstructorUsedError;

  /// 选中的集字ID列表
  Set<String> get selectedCharacterIds => throw _privateConstructorUsedError;

  /// 当前页面类型
  PageType get pageType => throw _privateConstructorUsedError;

  /// 是否全选状态
  bool get isAllSelected => throw _privateConstructorUsedError;

  /// 最后操作时间
  DateTime? get lastOperationTime => throw _privateConstructorUsedError;

  /// Create a copy of BatchSelectionState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $BatchSelectionStateCopyWith<BatchSelectionState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $BatchSelectionStateCopyWith<$Res> {
  factory $BatchSelectionStateCopyWith(
          BatchSelectionState value, $Res Function(BatchSelectionState) then) =
      _$BatchSelectionStateCopyWithImpl<$Res, BatchSelectionState>;
  @useResult
  $Res call(
      {bool isBatchMode,
      Set<String> selectedWorkIds,
      Set<String> selectedCharacterIds,
      PageType pageType,
      bool isAllSelected,
      DateTime? lastOperationTime});
}

/// @nodoc
class _$BatchSelectionStateCopyWithImpl<$Res, $Val extends BatchSelectionState>
    implements $BatchSelectionStateCopyWith<$Res> {
  _$BatchSelectionStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of BatchSelectionState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? isBatchMode = null,
    Object? selectedWorkIds = null,
    Object? selectedCharacterIds = null,
    Object? pageType = null,
    Object? isAllSelected = null,
    Object? lastOperationTime = freezed,
  }) {
    return _then(_value.copyWith(
      isBatchMode: null == isBatchMode
          ? _value.isBatchMode
          : isBatchMode // ignore: cast_nullable_to_non_nullable
              as bool,
      selectedWorkIds: null == selectedWorkIds
          ? _value.selectedWorkIds
          : selectedWorkIds // ignore: cast_nullable_to_non_nullable
              as Set<String>,
      selectedCharacterIds: null == selectedCharacterIds
          ? _value.selectedCharacterIds
          : selectedCharacterIds // ignore: cast_nullable_to_non_nullable
              as Set<String>,
      pageType: null == pageType
          ? _value.pageType
          : pageType // ignore: cast_nullable_to_non_nullable
              as PageType,
      isAllSelected: null == isAllSelected
          ? _value.isAllSelected
          : isAllSelected // ignore: cast_nullable_to_non_nullable
              as bool,
      lastOperationTime: freezed == lastOperationTime
          ? _value.lastOperationTime
          : lastOperationTime // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$BatchSelectionStateImplCopyWith<$Res>
    implements $BatchSelectionStateCopyWith<$Res> {
  factory _$$BatchSelectionStateImplCopyWith(_$BatchSelectionStateImpl value,
          $Res Function(_$BatchSelectionStateImpl) then) =
      __$$BatchSelectionStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {bool isBatchMode,
      Set<String> selectedWorkIds,
      Set<String> selectedCharacterIds,
      PageType pageType,
      bool isAllSelected,
      DateTime? lastOperationTime});
}

/// @nodoc
class __$$BatchSelectionStateImplCopyWithImpl<$Res>
    extends _$BatchSelectionStateCopyWithImpl<$Res, _$BatchSelectionStateImpl>
    implements _$$BatchSelectionStateImplCopyWith<$Res> {
  __$$BatchSelectionStateImplCopyWithImpl(_$BatchSelectionStateImpl _value,
      $Res Function(_$BatchSelectionStateImpl) _then)
      : super(_value, _then);

  /// Create a copy of BatchSelectionState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? isBatchMode = null,
    Object? selectedWorkIds = null,
    Object? selectedCharacterIds = null,
    Object? pageType = null,
    Object? isAllSelected = null,
    Object? lastOperationTime = freezed,
  }) {
    return _then(_$BatchSelectionStateImpl(
      isBatchMode: null == isBatchMode
          ? _value.isBatchMode
          : isBatchMode // ignore: cast_nullable_to_non_nullable
              as bool,
      selectedWorkIds: null == selectedWorkIds
          ? _value._selectedWorkIds
          : selectedWorkIds // ignore: cast_nullable_to_non_nullable
              as Set<String>,
      selectedCharacterIds: null == selectedCharacterIds
          ? _value._selectedCharacterIds
          : selectedCharacterIds // ignore: cast_nullable_to_non_nullable
              as Set<String>,
      pageType: null == pageType
          ? _value.pageType
          : pageType // ignore: cast_nullable_to_non_nullable
              as PageType,
      isAllSelected: null == isAllSelected
          ? _value.isAllSelected
          : isAllSelected // ignore: cast_nullable_to_non_nullable
              as bool,
      lastOperationTime: freezed == lastOperationTime
          ? _value.lastOperationTime
          : lastOperationTime // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// @nodoc

class _$BatchSelectionStateImpl extends _BatchSelectionState {
  const _$BatchSelectionStateImpl(
      {this.isBatchMode = false,
      final Set<String> selectedWorkIds = const {},
      final Set<String> selectedCharacterIds = const {},
      this.pageType = PageType.works,
      this.isAllSelected = false,
      this.lastOperationTime})
      : _selectedWorkIds = selectedWorkIds,
        _selectedCharacterIds = selectedCharacterIds,
        super._();

  /// 是否启用批量模式
  @override
  @JsonKey()
  final bool isBatchMode;

  /// 选中的作品ID列表
  final Set<String> _selectedWorkIds;

  /// 选中的作品ID列表
  @override
  @JsonKey()
  Set<String> get selectedWorkIds {
    if (_selectedWorkIds is EqualUnmodifiableSetView) return _selectedWorkIds;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableSetView(_selectedWorkIds);
  }

  /// 选中的集字ID列表
  final Set<String> _selectedCharacterIds;

  /// 选中的集字ID列表
  @override
  @JsonKey()
  Set<String> get selectedCharacterIds {
    if (_selectedCharacterIds is EqualUnmodifiableSetView)
      return _selectedCharacterIds;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableSetView(_selectedCharacterIds);
  }

  /// 当前页面类型
  @override
  @JsonKey()
  final PageType pageType;

  /// 是否全选状态
  @override
  @JsonKey()
  final bool isAllSelected;

  /// 最后操作时间
  @override
  final DateTime? lastOperationTime;

  @override
  String toString() {
    return 'BatchSelectionState(isBatchMode: $isBatchMode, selectedWorkIds: $selectedWorkIds, selectedCharacterIds: $selectedCharacterIds, pageType: $pageType, isAllSelected: $isAllSelected, lastOperationTime: $lastOperationTime)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$BatchSelectionStateImpl &&
            (identical(other.isBatchMode, isBatchMode) ||
                other.isBatchMode == isBatchMode) &&
            const DeepCollectionEquality()
                .equals(other._selectedWorkIds, _selectedWorkIds) &&
            const DeepCollectionEquality()
                .equals(other._selectedCharacterIds, _selectedCharacterIds) &&
            (identical(other.pageType, pageType) ||
                other.pageType == pageType) &&
            (identical(other.isAllSelected, isAllSelected) ||
                other.isAllSelected == isAllSelected) &&
            (identical(other.lastOperationTime, lastOperationTime) ||
                other.lastOperationTime == lastOperationTime));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      isBatchMode,
      const DeepCollectionEquality().hash(_selectedWorkIds),
      const DeepCollectionEquality().hash(_selectedCharacterIds),
      pageType,
      isAllSelected,
      lastOperationTime);

  /// Create a copy of BatchSelectionState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$BatchSelectionStateImplCopyWith<_$BatchSelectionStateImpl> get copyWith =>
      __$$BatchSelectionStateImplCopyWithImpl<_$BatchSelectionStateImpl>(
          this, _$identity);
}

abstract class _BatchSelectionState extends BatchSelectionState {
  const factory _BatchSelectionState(
      {final bool isBatchMode,
      final Set<String> selectedWorkIds,
      final Set<String> selectedCharacterIds,
      final PageType pageType,
      final bool isAllSelected,
      final DateTime? lastOperationTime}) = _$BatchSelectionStateImpl;
  const _BatchSelectionState._() : super._();

  /// 是否启用批量模式
  @override
  bool get isBatchMode;

  /// 选中的作品ID列表
  @override
  Set<String> get selectedWorkIds;

  /// 选中的集字ID列表
  @override
  Set<String> get selectedCharacterIds;

  /// 当前页面类型
  @override
  PageType get pageType;

  /// 是否全选状态
  @override
  bool get isAllSelected;

  /// 最后操作时间
  @override
  DateTime? get lastOperationTime;

  /// Create a copy of BatchSelectionState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$BatchSelectionStateImplCopyWith<_$BatchSelectionStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
