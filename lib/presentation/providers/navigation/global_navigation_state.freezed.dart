// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'global_navigation_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

GlobalNavigationState _$GlobalNavigationStateFromJson(
    Map<String, dynamic> json) {
  return _GlobalNavigationState.fromJson(json);
}

/// @nodoc
mixin _$GlobalNavigationState {
  /// 当前功能区索引
  int get currentSectionIndex => throw _privateConstructorUsedError;

  /// 导航历史记录
  List<NavigationHistoryItem> get history => throw _privateConstructorUsedError;

  /// 各功能区当前路由状态
  Map<int, String?> get sectionRoutes => throw _privateConstructorUsedError;

  /// 导航栏展开状态
  bool get isNavigationExtended => throw _privateConstructorUsedError;

  /// 是否正在导航中状态
  bool get isNavigating => throw _privateConstructorUsedError;

  /// 上次导航时间戳
  DateTime? get lastNavigationTime => throw _privateConstructorUsedError;

  /// 各功能区内部后退栈状态
  Map<int, bool> get canPopInSection => throw _privateConstructorUsedError;

  /// Serializes this GlobalNavigationState to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of GlobalNavigationState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $GlobalNavigationStateCopyWith<GlobalNavigationState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $GlobalNavigationStateCopyWith<$Res> {
  factory $GlobalNavigationStateCopyWith(GlobalNavigationState value,
          $Res Function(GlobalNavigationState) then) =
      _$GlobalNavigationStateCopyWithImpl<$Res, GlobalNavigationState>;
  @useResult
  $Res call(
      {int currentSectionIndex,
      List<NavigationHistoryItem> history,
      Map<int, String?> sectionRoutes,
      bool isNavigationExtended,
      bool isNavigating,
      DateTime? lastNavigationTime,
      Map<int, bool> canPopInSection});
}

/// @nodoc
class _$GlobalNavigationStateCopyWithImpl<$Res,
        $Val extends GlobalNavigationState>
    implements $GlobalNavigationStateCopyWith<$Res> {
  _$GlobalNavigationStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of GlobalNavigationState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? currentSectionIndex = null,
    Object? history = null,
    Object? sectionRoutes = null,
    Object? isNavigationExtended = null,
    Object? isNavigating = null,
    Object? lastNavigationTime = freezed,
    Object? canPopInSection = null,
  }) {
    return _then(_value.copyWith(
      currentSectionIndex: null == currentSectionIndex
          ? _value.currentSectionIndex
          : currentSectionIndex // ignore: cast_nullable_to_non_nullable
              as int,
      history: null == history
          ? _value.history
          : history // ignore: cast_nullable_to_non_nullable
              as List<NavigationHistoryItem>,
      sectionRoutes: null == sectionRoutes
          ? _value.sectionRoutes
          : sectionRoutes // ignore: cast_nullable_to_non_nullable
              as Map<int, String?>,
      isNavigationExtended: null == isNavigationExtended
          ? _value.isNavigationExtended
          : isNavigationExtended // ignore: cast_nullable_to_non_nullable
              as bool,
      isNavigating: null == isNavigating
          ? _value.isNavigating
          : isNavigating // ignore: cast_nullable_to_non_nullable
              as bool,
      lastNavigationTime: freezed == lastNavigationTime
          ? _value.lastNavigationTime
          : lastNavigationTime // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      canPopInSection: null == canPopInSection
          ? _value.canPopInSection
          : canPopInSection // ignore: cast_nullable_to_non_nullable
              as Map<int, bool>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$GlobalNavigationStateImplCopyWith<$Res>
    implements $GlobalNavigationStateCopyWith<$Res> {
  factory _$$GlobalNavigationStateImplCopyWith(
          _$GlobalNavigationStateImpl value,
          $Res Function(_$GlobalNavigationStateImpl) then) =
      __$$GlobalNavigationStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {int currentSectionIndex,
      List<NavigationHistoryItem> history,
      Map<int, String?> sectionRoutes,
      bool isNavigationExtended,
      bool isNavigating,
      DateTime? lastNavigationTime,
      Map<int, bool> canPopInSection});
}

/// @nodoc
class __$$GlobalNavigationStateImplCopyWithImpl<$Res>
    extends _$GlobalNavigationStateCopyWithImpl<$Res,
        _$GlobalNavigationStateImpl>
    implements _$$GlobalNavigationStateImplCopyWith<$Res> {
  __$$GlobalNavigationStateImplCopyWithImpl(_$GlobalNavigationStateImpl _value,
      $Res Function(_$GlobalNavigationStateImpl) _then)
      : super(_value, _then);

  /// Create a copy of GlobalNavigationState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? currentSectionIndex = null,
    Object? history = null,
    Object? sectionRoutes = null,
    Object? isNavigationExtended = null,
    Object? isNavigating = null,
    Object? lastNavigationTime = freezed,
    Object? canPopInSection = null,
  }) {
    return _then(_$GlobalNavigationStateImpl(
      currentSectionIndex: null == currentSectionIndex
          ? _value.currentSectionIndex
          : currentSectionIndex // ignore: cast_nullable_to_non_nullable
              as int,
      history: null == history
          ? _value._history
          : history // ignore: cast_nullable_to_non_nullable
              as List<NavigationHistoryItem>,
      sectionRoutes: null == sectionRoutes
          ? _value._sectionRoutes
          : sectionRoutes // ignore: cast_nullable_to_non_nullable
              as Map<int, String?>,
      isNavigationExtended: null == isNavigationExtended
          ? _value.isNavigationExtended
          : isNavigationExtended // ignore: cast_nullable_to_non_nullable
              as bool,
      isNavigating: null == isNavigating
          ? _value.isNavigating
          : isNavigating // ignore: cast_nullable_to_non_nullable
              as bool,
      lastNavigationTime: freezed == lastNavigationTime
          ? _value.lastNavigationTime
          : lastNavigationTime // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      canPopInSection: null == canPopInSection
          ? _value._canPopInSection
          : canPopInSection // ignore: cast_nullable_to_non_nullable
              as Map<int, bool>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$GlobalNavigationStateImpl extends _GlobalNavigationState {
  const _$GlobalNavigationStateImpl(
      {this.currentSectionIndex = 0,
      final List<NavigationHistoryItem> history = const [],
      final Map<int, String?> sectionRoutes = const {},
      this.isNavigationExtended = true,
      this.isNavigating = false,
      this.lastNavigationTime,
      final Map<int, bool> canPopInSection = const {}})
      : _history = history,
        _sectionRoutes = sectionRoutes,
        _canPopInSection = canPopInSection,
        super._();

  factory _$GlobalNavigationStateImpl.fromJson(Map<String, dynamic> json) =>
      _$$GlobalNavigationStateImplFromJson(json);

  /// 当前功能区索引
  @override
  @JsonKey()
  final int currentSectionIndex;

  /// 导航历史记录
  final List<NavigationHistoryItem> _history;

  /// 导航历史记录
  @override
  @JsonKey()
  List<NavigationHistoryItem> get history {
    if (_history is EqualUnmodifiableListView) return _history;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_history);
  }

  /// 各功能区当前路由状态
  final Map<int, String?> _sectionRoutes;

  /// 各功能区当前路由状态
  @override
  @JsonKey()
  Map<int, String?> get sectionRoutes {
    if (_sectionRoutes is EqualUnmodifiableMapView) return _sectionRoutes;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_sectionRoutes);
  }

  /// 导航栏展开状态
  @override
  @JsonKey()
  final bool isNavigationExtended;

  /// 是否正在导航中状态
  @override
  @JsonKey()
  final bool isNavigating;

  /// 上次导航时间戳
  @override
  final DateTime? lastNavigationTime;

  /// 各功能区内部后退栈状态
  final Map<int, bool> _canPopInSection;

  /// 各功能区内部后退栈状态
  @override
  @JsonKey()
  Map<int, bool> get canPopInSection {
    if (_canPopInSection is EqualUnmodifiableMapView) return _canPopInSection;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_canPopInSection);
  }

  @override
  String toString() {
    return 'GlobalNavigationState(currentSectionIndex: $currentSectionIndex, history: $history, sectionRoutes: $sectionRoutes, isNavigationExtended: $isNavigationExtended, isNavigating: $isNavigating, lastNavigationTime: $lastNavigationTime, canPopInSection: $canPopInSection)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$GlobalNavigationStateImpl &&
            (identical(other.currentSectionIndex, currentSectionIndex) ||
                other.currentSectionIndex == currentSectionIndex) &&
            const DeepCollectionEquality().equals(other._history, _history) &&
            const DeepCollectionEquality()
                .equals(other._sectionRoutes, _sectionRoutes) &&
            (identical(other.isNavigationExtended, isNavigationExtended) ||
                other.isNavigationExtended == isNavigationExtended) &&
            (identical(other.isNavigating, isNavigating) ||
                other.isNavigating == isNavigating) &&
            (identical(other.lastNavigationTime, lastNavigationTime) ||
                other.lastNavigationTime == lastNavigationTime) &&
            const DeepCollectionEquality()
                .equals(other._canPopInSection, _canPopInSection));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      currentSectionIndex,
      const DeepCollectionEquality().hash(_history),
      const DeepCollectionEquality().hash(_sectionRoutes),
      isNavigationExtended,
      isNavigating,
      lastNavigationTime,
      const DeepCollectionEquality().hash(_canPopInSection));

  /// Create a copy of GlobalNavigationState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$GlobalNavigationStateImplCopyWith<_$GlobalNavigationStateImpl>
      get copyWith => __$$GlobalNavigationStateImplCopyWithImpl<
          _$GlobalNavigationStateImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$GlobalNavigationStateImplToJson(
      this,
    );
  }
}

abstract class _GlobalNavigationState extends GlobalNavigationState {
  const factory _GlobalNavigationState(
      {final int currentSectionIndex,
      final List<NavigationHistoryItem> history,
      final Map<int, String?> sectionRoutes,
      final bool isNavigationExtended,
      final bool isNavigating,
      final DateTime? lastNavigationTime,
      final Map<int, bool> canPopInSection}) = _$GlobalNavigationStateImpl;
  const _GlobalNavigationState._() : super._();

  factory _GlobalNavigationState.fromJson(Map<String, dynamic> json) =
      _$GlobalNavigationStateImpl.fromJson;

  /// 当前功能区索引
  @override
  int get currentSectionIndex;

  /// 导航历史记录
  @override
  List<NavigationHistoryItem> get history;

  /// 各功能区当前路由状态
  @override
  Map<int, String?> get sectionRoutes;

  /// 导航栏展开状态
  @override
  bool get isNavigationExtended;

  /// 是否正在导航中状态
  @override
  bool get isNavigating;

  /// 上次导航时间戳
  @override
  DateTime? get lastNavigationTime;

  /// 各功能区内部后退栈状态
  @override
  Map<int, bool> get canPopInSection;

  /// Create a copy of GlobalNavigationState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$GlobalNavigationStateImplCopyWith<_$GlobalNavigationStateImpl>
      get copyWith => throw _privateConstructorUsedError;
}
