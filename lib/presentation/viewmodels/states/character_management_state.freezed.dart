// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'character_management_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

CharacterManagementState _$CharacterManagementStateFromJson(
    Map<String, dynamic> json) {
  return _CharacterManagementState.fromJson(json);
}

/// @nodoc
mixin _$CharacterManagementState {
  /// List of characters to display
  List<CharacterView> get characters => throw _privateConstructorUsedError;

  /// All available tags for filtering
  List<String> get allTags => throw _privateConstructorUsedError;

  /// Current filter settings
  CharacterFilter get filter => throw _privateConstructorUsedError;

  /// Whether data is currently loading
  bool get isLoading => throw _privateConstructorUsedError;

  /// Whether batch selection mode is active
  bool get isBatchMode => throw _privateConstructorUsedError;

  /// Set of selected character IDs in batch mode
  Set<String> get selectedCharacters => throw _privateConstructorUsedError;

  /// Whether the detail panel is open
  bool get isDetailOpen => throw _privateConstructorUsedError;

  /// Whether the filter panel is shown
  bool get showFilterPanel => throw _privateConstructorUsedError;

  /// Error message, if any
  String? get errorMessage => throw _privateConstructorUsedError;

  /// ID of selected character for detail view
  String? get selectedCharacterId => throw _privateConstructorUsedError;

  /// Current view mode (grid or list)
  ViewMode get viewMode => throw _privateConstructorUsedError;

  /// Total character count (for pagination)
  int get totalCount => throw _privateConstructorUsedError;

  /// Current page (for pagination)
  int get currentPage => throw _privateConstructorUsedError;

  /// Page size (for pagination)
  int get pageSize => throw _privateConstructorUsedError;

  /// Serializes this CharacterManagementState to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of CharacterManagementState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CharacterManagementStateCopyWith<CharacterManagementState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CharacterManagementStateCopyWith<$Res> {
  factory $CharacterManagementStateCopyWith(CharacterManagementState value,
          $Res Function(CharacterManagementState) then) =
      _$CharacterManagementStateCopyWithImpl<$Res, CharacterManagementState>;
  @useResult
  $Res call(
      {List<CharacterView> characters,
      List<String> allTags,
      CharacterFilter filter,
      bool isLoading,
      bool isBatchMode,
      Set<String> selectedCharacters,
      bool isDetailOpen,
      bool showFilterPanel,
      String? errorMessage,
      String? selectedCharacterId,
      ViewMode viewMode,
      int totalCount,
      int currentPage,
      int pageSize});

  $CharacterFilterCopyWith<$Res> get filter;
}

/// @nodoc
class _$CharacterManagementStateCopyWithImpl<$Res,
        $Val extends CharacterManagementState>
    implements $CharacterManagementStateCopyWith<$Res> {
  _$CharacterManagementStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of CharacterManagementState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? characters = null,
    Object? allTags = null,
    Object? filter = null,
    Object? isLoading = null,
    Object? isBatchMode = null,
    Object? selectedCharacters = null,
    Object? isDetailOpen = null,
    Object? showFilterPanel = null,
    Object? errorMessage = freezed,
    Object? selectedCharacterId = freezed,
    Object? viewMode = null,
    Object? totalCount = null,
    Object? currentPage = null,
    Object? pageSize = null,
  }) {
    return _then(_value.copyWith(
      characters: null == characters
          ? _value.characters
          : characters // ignore: cast_nullable_to_non_nullable
              as List<CharacterView>,
      allTags: null == allTags
          ? _value.allTags
          : allTags // ignore: cast_nullable_to_non_nullable
              as List<String>,
      filter: null == filter
          ? _value.filter
          : filter // ignore: cast_nullable_to_non_nullable
              as CharacterFilter,
      isLoading: null == isLoading
          ? _value.isLoading
          : isLoading // ignore: cast_nullable_to_non_nullable
              as bool,
      isBatchMode: null == isBatchMode
          ? _value.isBatchMode
          : isBatchMode // ignore: cast_nullable_to_non_nullable
              as bool,
      selectedCharacters: null == selectedCharacters
          ? _value.selectedCharacters
          : selectedCharacters // ignore: cast_nullable_to_non_nullable
              as Set<String>,
      isDetailOpen: null == isDetailOpen
          ? _value.isDetailOpen
          : isDetailOpen // ignore: cast_nullable_to_non_nullable
              as bool,
      showFilterPanel: null == showFilterPanel
          ? _value.showFilterPanel
          : showFilterPanel // ignore: cast_nullable_to_non_nullable
              as bool,
      errorMessage: freezed == errorMessage
          ? _value.errorMessage
          : errorMessage // ignore: cast_nullable_to_non_nullable
              as String?,
      selectedCharacterId: freezed == selectedCharacterId
          ? _value.selectedCharacterId
          : selectedCharacterId // ignore: cast_nullable_to_non_nullable
              as String?,
      viewMode: null == viewMode
          ? _value.viewMode
          : viewMode // ignore: cast_nullable_to_non_nullable
              as ViewMode,
      totalCount: null == totalCount
          ? _value.totalCount
          : totalCount // ignore: cast_nullable_to_non_nullable
              as int,
      currentPage: null == currentPage
          ? _value.currentPage
          : currentPage // ignore: cast_nullable_to_non_nullable
              as int,
      pageSize: null == pageSize
          ? _value.pageSize
          : pageSize // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }

  /// Create a copy of CharacterManagementState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $CharacterFilterCopyWith<$Res> get filter {
    return $CharacterFilterCopyWith<$Res>(_value.filter, (value) {
      return _then(_value.copyWith(filter: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$CharacterManagementStateImplCopyWith<$Res>
    implements $CharacterManagementStateCopyWith<$Res> {
  factory _$$CharacterManagementStateImplCopyWith(
          _$CharacterManagementStateImpl value,
          $Res Function(_$CharacterManagementStateImpl) then) =
      __$$CharacterManagementStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {List<CharacterView> characters,
      List<String> allTags,
      CharacterFilter filter,
      bool isLoading,
      bool isBatchMode,
      Set<String> selectedCharacters,
      bool isDetailOpen,
      bool showFilterPanel,
      String? errorMessage,
      String? selectedCharacterId,
      ViewMode viewMode,
      int totalCount,
      int currentPage,
      int pageSize});

  @override
  $CharacterFilterCopyWith<$Res> get filter;
}

/// @nodoc
class __$$CharacterManagementStateImplCopyWithImpl<$Res>
    extends _$CharacterManagementStateCopyWithImpl<$Res,
        _$CharacterManagementStateImpl>
    implements _$$CharacterManagementStateImplCopyWith<$Res> {
  __$$CharacterManagementStateImplCopyWithImpl(
      _$CharacterManagementStateImpl _value,
      $Res Function(_$CharacterManagementStateImpl) _then)
      : super(_value, _then);

  /// Create a copy of CharacterManagementState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? characters = null,
    Object? allTags = null,
    Object? filter = null,
    Object? isLoading = null,
    Object? isBatchMode = null,
    Object? selectedCharacters = null,
    Object? isDetailOpen = null,
    Object? showFilterPanel = null,
    Object? errorMessage = freezed,
    Object? selectedCharacterId = freezed,
    Object? viewMode = null,
    Object? totalCount = null,
    Object? currentPage = null,
    Object? pageSize = null,
  }) {
    return _then(_$CharacterManagementStateImpl(
      characters: null == characters
          ? _value._characters
          : characters // ignore: cast_nullable_to_non_nullable
              as List<CharacterView>,
      allTags: null == allTags
          ? _value._allTags
          : allTags // ignore: cast_nullable_to_non_nullable
              as List<String>,
      filter: null == filter
          ? _value.filter
          : filter // ignore: cast_nullable_to_non_nullable
              as CharacterFilter,
      isLoading: null == isLoading
          ? _value.isLoading
          : isLoading // ignore: cast_nullable_to_non_nullable
              as bool,
      isBatchMode: null == isBatchMode
          ? _value.isBatchMode
          : isBatchMode // ignore: cast_nullable_to_non_nullable
              as bool,
      selectedCharacters: null == selectedCharacters
          ? _value._selectedCharacters
          : selectedCharacters // ignore: cast_nullable_to_non_nullable
              as Set<String>,
      isDetailOpen: null == isDetailOpen
          ? _value.isDetailOpen
          : isDetailOpen // ignore: cast_nullable_to_non_nullable
              as bool,
      showFilterPanel: null == showFilterPanel
          ? _value.showFilterPanel
          : showFilterPanel // ignore: cast_nullable_to_non_nullable
              as bool,
      errorMessage: freezed == errorMessage
          ? _value.errorMessage
          : errorMessage // ignore: cast_nullable_to_non_nullable
              as String?,
      selectedCharacterId: freezed == selectedCharacterId
          ? _value.selectedCharacterId
          : selectedCharacterId // ignore: cast_nullable_to_non_nullable
              as String?,
      viewMode: null == viewMode
          ? _value.viewMode
          : viewMode // ignore: cast_nullable_to_non_nullable
              as ViewMode,
      totalCount: null == totalCount
          ? _value.totalCount
          : totalCount // ignore: cast_nullable_to_non_nullable
              as int,
      currentPage: null == currentPage
          ? _value.currentPage
          : currentPage // ignore: cast_nullable_to_non_nullable
              as int,
      pageSize: null == pageSize
          ? _value.pageSize
          : pageSize // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$CharacterManagementStateImpl implements _CharacterManagementState {
  const _$CharacterManagementStateImpl(
      {final List<CharacterView> characters = const [],
      final List<String> allTags = const [],
      this.filter = const CharacterFilter(),
      this.isLoading = false,
      this.isBatchMode = false,
      final Set<String> selectedCharacters = const {},
      this.isDetailOpen = false,
      this.showFilterPanel = true,
      this.errorMessage,
      this.selectedCharacterId,
      this.viewMode = ViewMode.grid,
      this.totalCount = 0,
      this.currentPage = 1,
      this.pageSize = 20})
      : _characters = characters,
        _allTags = allTags,
        _selectedCharacters = selectedCharacters;

  factory _$CharacterManagementStateImpl.fromJson(Map<String, dynamic> json) =>
      _$$CharacterManagementStateImplFromJson(json);

  /// List of characters to display
  final List<CharacterView> _characters;

  /// List of characters to display
  @override
  @JsonKey()
  List<CharacterView> get characters {
    if (_characters is EqualUnmodifiableListView) return _characters;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_characters);
  }

  /// All available tags for filtering
  final List<String> _allTags;

  /// All available tags for filtering
  @override
  @JsonKey()
  List<String> get allTags {
    if (_allTags is EqualUnmodifiableListView) return _allTags;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_allTags);
  }

  /// Current filter settings
  @override
  @JsonKey()
  final CharacterFilter filter;

  /// Whether data is currently loading
  @override
  @JsonKey()
  final bool isLoading;

  /// Whether batch selection mode is active
  @override
  @JsonKey()
  final bool isBatchMode;

  /// Set of selected character IDs in batch mode
  final Set<String> _selectedCharacters;

  /// Set of selected character IDs in batch mode
  @override
  @JsonKey()
  Set<String> get selectedCharacters {
    if (_selectedCharacters is EqualUnmodifiableSetView)
      return _selectedCharacters;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableSetView(_selectedCharacters);
  }

  /// Whether the detail panel is open
  @override
  @JsonKey()
  final bool isDetailOpen;

  /// Whether the filter panel is shown
  @override
  @JsonKey()
  final bool showFilterPanel;

  /// Error message, if any
  @override
  final String? errorMessage;

  /// ID of selected character for detail view
  @override
  final String? selectedCharacterId;

  /// Current view mode (grid or list)
  @override
  @JsonKey()
  final ViewMode viewMode;

  /// Total character count (for pagination)
  @override
  @JsonKey()
  final int totalCount;

  /// Current page (for pagination)
  @override
  @JsonKey()
  final int currentPage;

  /// Page size (for pagination)
  @override
  @JsonKey()
  final int pageSize;

  @override
  String toString() {
    return 'CharacterManagementState(characters: $characters, allTags: $allTags, filter: $filter, isLoading: $isLoading, isBatchMode: $isBatchMode, selectedCharacters: $selectedCharacters, isDetailOpen: $isDetailOpen, showFilterPanel: $showFilterPanel, errorMessage: $errorMessage, selectedCharacterId: $selectedCharacterId, viewMode: $viewMode, totalCount: $totalCount, currentPage: $currentPage, pageSize: $pageSize)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CharacterManagementStateImpl &&
            const DeepCollectionEquality()
                .equals(other._characters, _characters) &&
            const DeepCollectionEquality().equals(other._allTags, _allTags) &&
            (identical(other.filter, filter) || other.filter == filter) &&
            (identical(other.isLoading, isLoading) ||
                other.isLoading == isLoading) &&
            (identical(other.isBatchMode, isBatchMode) ||
                other.isBatchMode == isBatchMode) &&
            const DeepCollectionEquality()
                .equals(other._selectedCharacters, _selectedCharacters) &&
            (identical(other.isDetailOpen, isDetailOpen) ||
                other.isDetailOpen == isDetailOpen) &&
            (identical(other.showFilterPanel, showFilterPanel) ||
                other.showFilterPanel == showFilterPanel) &&
            (identical(other.errorMessage, errorMessage) ||
                other.errorMessage == errorMessage) &&
            (identical(other.selectedCharacterId, selectedCharacterId) ||
                other.selectedCharacterId == selectedCharacterId) &&
            (identical(other.viewMode, viewMode) ||
                other.viewMode == viewMode) &&
            (identical(other.totalCount, totalCount) ||
                other.totalCount == totalCount) &&
            (identical(other.currentPage, currentPage) ||
                other.currentPage == currentPage) &&
            (identical(other.pageSize, pageSize) ||
                other.pageSize == pageSize));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      const DeepCollectionEquality().hash(_characters),
      const DeepCollectionEquality().hash(_allTags),
      filter,
      isLoading,
      isBatchMode,
      const DeepCollectionEquality().hash(_selectedCharacters),
      isDetailOpen,
      showFilterPanel,
      errorMessage,
      selectedCharacterId,
      viewMode,
      totalCount,
      currentPage,
      pageSize);

  /// Create a copy of CharacterManagementState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CharacterManagementStateImplCopyWith<_$CharacterManagementStateImpl>
      get copyWith => __$$CharacterManagementStateImplCopyWithImpl<
          _$CharacterManagementStateImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$CharacterManagementStateImplToJson(
      this,
    );
  }
}

abstract class _CharacterManagementState implements CharacterManagementState {
  const factory _CharacterManagementState(
      {final List<CharacterView> characters,
      final List<String> allTags,
      final CharacterFilter filter,
      final bool isLoading,
      final bool isBatchMode,
      final Set<String> selectedCharacters,
      final bool isDetailOpen,
      final bool showFilterPanel,
      final String? errorMessage,
      final String? selectedCharacterId,
      final ViewMode viewMode,
      final int totalCount,
      final int currentPage,
      final int pageSize}) = _$CharacterManagementStateImpl;

  factory _CharacterManagementState.fromJson(Map<String, dynamic> json) =
      _$CharacterManagementStateImpl.fromJson;

  /// List of characters to display
  @override
  List<CharacterView> get characters;

  /// All available tags for filtering
  @override
  List<String> get allTags;

  /// Current filter settings
  @override
  CharacterFilter get filter;

  /// Whether data is currently loading
  @override
  bool get isLoading;

  /// Whether batch selection mode is active
  @override
  bool get isBatchMode;

  /// Set of selected character IDs in batch mode
  @override
  Set<String> get selectedCharacters;

  /// Whether the detail panel is open
  @override
  bool get isDetailOpen;

  /// Whether the filter panel is shown
  @override
  bool get showFilterPanel;

  /// Error message, if any
  @override
  String? get errorMessage;

  /// ID of selected character for detail view
  @override
  String? get selectedCharacterId;

  /// Current view mode (grid or list)
  @override
  ViewMode get viewMode;

  /// Total character count (for pagination)
  @override
  int get totalCount;

  /// Current page (for pagination)
  @override
  int get currentPage;

  /// Page size (for pagination)
  @override
  int get pageSize;

  /// Create a copy of CharacterManagementState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CharacterManagementStateImplCopyWith<_$CharacterManagementStateImpl>
      get copyWith => throw _privateConstructorUsedError;
}
