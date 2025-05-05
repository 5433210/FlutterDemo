// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'character_grid_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

CharacterGridState _$CharacterGridStateFromJson(Map<String, dynamic> json) {
  return _CharacterGridState.fromJson(json);
}

/// @nodoc
mixin _$CharacterGridState {
  List<CharacterViewModel> get characters => throw _privateConstructorUsedError;
  List<CharacterViewModel> get filteredCharacters =>
      throw _privateConstructorUsedError;
  String get searchTerm => throw _privateConstructorUsedError;
  FilterType get filterType => throw _privateConstructorUsedError;
  Set<String> get selectedIds =>
      throw _privateConstructorUsedError; // Keeping for transition period
  int get currentPage => throw _privateConstructorUsedError;
  int get totalPages => throw _privateConstructorUsedError;
  bool get loading => throw _privateConstructorUsedError;
  bool get isInitialLoad =>
      throw _privateConstructorUsedError; // 添加初始加载标志，默认为true
  String? get error => throw _privateConstructorUsedError;

  /// Serializes this CharacterGridState to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of CharacterGridState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CharacterGridStateCopyWith<CharacterGridState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CharacterGridStateCopyWith<$Res> {
  factory $CharacterGridStateCopyWith(
          CharacterGridState value, $Res Function(CharacterGridState) then) =
      _$CharacterGridStateCopyWithImpl<$Res, CharacterGridState>;
  @useResult
  $Res call(
      {List<CharacterViewModel> characters,
      List<CharacterViewModel> filteredCharacters,
      String searchTerm,
      FilterType filterType,
      Set<String> selectedIds,
      int currentPage,
      int totalPages,
      bool loading,
      bool isInitialLoad,
      String? error});
}

/// @nodoc
class _$CharacterGridStateCopyWithImpl<$Res, $Val extends CharacterGridState>
    implements $CharacterGridStateCopyWith<$Res> {
  _$CharacterGridStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of CharacterGridState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? characters = null,
    Object? filteredCharacters = null,
    Object? searchTerm = null,
    Object? filterType = null,
    Object? selectedIds = null,
    Object? currentPage = null,
    Object? totalPages = null,
    Object? loading = null,
    Object? isInitialLoad = null,
    Object? error = freezed,
  }) {
    return _then(_value.copyWith(
      characters: null == characters
          ? _value.characters
          : characters // ignore: cast_nullable_to_non_nullable
              as List<CharacterViewModel>,
      filteredCharacters: null == filteredCharacters
          ? _value.filteredCharacters
          : filteredCharacters // ignore: cast_nullable_to_non_nullable
              as List<CharacterViewModel>,
      searchTerm: null == searchTerm
          ? _value.searchTerm
          : searchTerm // ignore: cast_nullable_to_non_nullable
              as String,
      filterType: null == filterType
          ? _value.filterType
          : filterType // ignore: cast_nullable_to_non_nullable
              as FilterType,
      selectedIds: null == selectedIds
          ? _value.selectedIds
          : selectedIds // ignore: cast_nullable_to_non_nullable
              as Set<String>,
      currentPage: null == currentPage
          ? _value.currentPage
          : currentPage // ignore: cast_nullable_to_non_nullable
              as int,
      totalPages: null == totalPages
          ? _value.totalPages
          : totalPages // ignore: cast_nullable_to_non_nullable
              as int,
      loading: null == loading
          ? _value.loading
          : loading // ignore: cast_nullable_to_non_nullable
              as bool,
      isInitialLoad: null == isInitialLoad
          ? _value.isInitialLoad
          : isInitialLoad // ignore: cast_nullable_to_non_nullable
              as bool,
      error: freezed == error
          ? _value.error
          : error // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$CharacterGridStateImplCopyWith<$Res>
    implements $CharacterGridStateCopyWith<$Res> {
  factory _$$CharacterGridStateImplCopyWith(_$CharacterGridStateImpl value,
          $Res Function(_$CharacterGridStateImpl) then) =
      __$$CharacterGridStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {List<CharacterViewModel> characters,
      List<CharacterViewModel> filteredCharacters,
      String searchTerm,
      FilterType filterType,
      Set<String> selectedIds,
      int currentPage,
      int totalPages,
      bool loading,
      bool isInitialLoad,
      String? error});
}

/// @nodoc
class __$$CharacterGridStateImplCopyWithImpl<$Res>
    extends _$CharacterGridStateCopyWithImpl<$Res, _$CharacterGridStateImpl>
    implements _$$CharacterGridStateImplCopyWith<$Res> {
  __$$CharacterGridStateImplCopyWithImpl(_$CharacterGridStateImpl _value,
      $Res Function(_$CharacterGridStateImpl) _then)
      : super(_value, _then);

  /// Create a copy of CharacterGridState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? characters = null,
    Object? filteredCharacters = null,
    Object? searchTerm = null,
    Object? filterType = null,
    Object? selectedIds = null,
    Object? currentPage = null,
    Object? totalPages = null,
    Object? loading = null,
    Object? isInitialLoad = null,
    Object? error = freezed,
  }) {
    return _then(_$CharacterGridStateImpl(
      characters: null == characters
          ? _value._characters
          : characters // ignore: cast_nullable_to_non_nullable
              as List<CharacterViewModel>,
      filteredCharacters: null == filteredCharacters
          ? _value._filteredCharacters
          : filteredCharacters // ignore: cast_nullable_to_non_nullable
              as List<CharacterViewModel>,
      searchTerm: null == searchTerm
          ? _value.searchTerm
          : searchTerm // ignore: cast_nullable_to_non_nullable
              as String,
      filterType: null == filterType
          ? _value.filterType
          : filterType // ignore: cast_nullable_to_non_nullable
              as FilterType,
      selectedIds: null == selectedIds
          ? _value._selectedIds
          : selectedIds // ignore: cast_nullable_to_non_nullable
              as Set<String>,
      currentPage: null == currentPage
          ? _value.currentPage
          : currentPage // ignore: cast_nullable_to_non_nullable
              as int,
      totalPages: null == totalPages
          ? _value.totalPages
          : totalPages // ignore: cast_nullable_to_non_nullable
              as int,
      loading: null == loading
          ? _value.loading
          : loading // ignore: cast_nullable_to_non_nullable
              as bool,
      isInitialLoad: null == isInitialLoad
          ? _value.isInitialLoad
          : isInitialLoad // ignore: cast_nullable_to_non_nullable
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
class _$CharacterGridStateImpl implements _CharacterGridState {
  const _$CharacterGridStateImpl(
      {final List<CharacterViewModel> characters = const [],
      final List<CharacterViewModel> filteredCharacters = const [],
      this.searchTerm = '',
      this.filterType = FilterType.all,
      final Set<String> selectedIds = const {},
      this.currentPage = 1,
      this.totalPages = 1,
      this.loading = false,
      this.isInitialLoad = true,
      this.error})
      : _characters = characters,
        _filteredCharacters = filteredCharacters,
        _selectedIds = selectedIds;

  factory _$CharacterGridStateImpl.fromJson(Map<String, dynamic> json) =>
      _$$CharacterGridStateImplFromJson(json);

  final List<CharacterViewModel> _characters;
  @override
  @JsonKey()
  List<CharacterViewModel> get characters {
    if (_characters is EqualUnmodifiableListView) return _characters;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_characters);
  }

  final List<CharacterViewModel> _filteredCharacters;
  @override
  @JsonKey()
  List<CharacterViewModel> get filteredCharacters {
    if (_filteredCharacters is EqualUnmodifiableListView)
      return _filteredCharacters;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_filteredCharacters);
  }

  @override
  @JsonKey()
  final String searchTerm;
  @override
  @JsonKey()
  final FilterType filterType;
  final Set<String> _selectedIds;
  @override
  @JsonKey()
  Set<String> get selectedIds {
    if (_selectedIds is EqualUnmodifiableSetView) return _selectedIds;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableSetView(_selectedIds);
  }

// Keeping for transition period
  @override
  @JsonKey()
  final int currentPage;
  @override
  @JsonKey()
  final int totalPages;
  @override
  @JsonKey()
  final bool loading;
  @override
  @JsonKey()
  final bool isInitialLoad;
// 添加初始加载标志，默认为true
  @override
  final String? error;

  @override
  String toString() {
    return 'CharacterGridState(characters: $characters, filteredCharacters: $filteredCharacters, searchTerm: $searchTerm, filterType: $filterType, selectedIds: $selectedIds, currentPage: $currentPage, totalPages: $totalPages, loading: $loading, isInitialLoad: $isInitialLoad, error: $error)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CharacterGridStateImpl &&
            const DeepCollectionEquality()
                .equals(other._characters, _characters) &&
            const DeepCollectionEquality()
                .equals(other._filteredCharacters, _filteredCharacters) &&
            (identical(other.searchTerm, searchTerm) ||
                other.searchTerm == searchTerm) &&
            (identical(other.filterType, filterType) ||
                other.filterType == filterType) &&
            const DeepCollectionEquality()
                .equals(other._selectedIds, _selectedIds) &&
            (identical(other.currentPage, currentPage) ||
                other.currentPage == currentPage) &&
            (identical(other.totalPages, totalPages) ||
                other.totalPages == totalPages) &&
            (identical(other.loading, loading) || other.loading == loading) &&
            (identical(other.isInitialLoad, isInitialLoad) ||
                other.isInitialLoad == isInitialLoad) &&
            (identical(other.error, error) || other.error == error));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      const DeepCollectionEquality().hash(_characters),
      const DeepCollectionEquality().hash(_filteredCharacters),
      searchTerm,
      filterType,
      const DeepCollectionEquality().hash(_selectedIds),
      currentPage,
      totalPages,
      loading,
      isInitialLoad,
      error);

  /// Create a copy of CharacterGridState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CharacterGridStateImplCopyWith<_$CharacterGridStateImpl> get copyWith =>
      __$$CharacterGridStateImplCopyWithImpl<_$CharacterGridStateImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$CharacterGridStateImplToJson(
      this,
    );
  }
}

abstract class _CharacterGridState implements CharacterGridState {
  const factory _CharacterGridState(
      {final List<CharacterViewModel> characters,
      final List<CharacterViewModel> filteredCharacters,
      final String searchTerm,
      final FilterType filterType,
      final Set<String> selectedIds,
      final int currentPage,
      final int totalPages,
      final bool loading,
      final bool isInitialLoad,
      final String? error}) = _$CharacterGridStateImpl;

  factory _CharacterGridState.fromJson(Map<String, dynamic> json) =
      _$CharacterGridStateImpl.fromJson;

  @override
  List<CharacterViewModel> get characters;
  @override
  List<CharacterViewModel> get filteredCharacters;
  @override
  String get searchTerm;
  @override
  FilterType get filterType;
  @override
  Set<String> get selectedIds; // Keeping for transition period
  @override
  int get currentPage;
  @override
  int get totalPages;
  @override
  bool get loading;
  @override
  bool get isInitialLoad; // 添加初始加载标志，默认为true
  @override
  String? get error;

  /// Create a copy of CharacterGridState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CharacterGridStateImplCopyWith<_$CharacterGridStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

CharacterViewModel _$CharacterViewModelFromJson(Map<String, dynamic> json) {
  return _CharacterViewModel.fromJson(json);
}

/// @nodoc
mixin _$CharacterViewModel {
  String get id => throw _privateConstructorUsedError;
  String get pageId => throw _privateConstructorUsedError;
  String get character => throw _privateConstructorUsedError;
  String get thumbnailPath => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;
  DateTime get updatedAt => throw _privateConstructorUsedError;
  bool get isFavorite => throw _privateConstructorUsedError;
  bool get isSelected => throw _privateConstructorUsedError; // New property
  bool get isModified => throw _privateConstructorUsedError;

  /// Serializes this CharacterViewModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of CharacterViewModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CharacterViewModelCopyWith<CharacterViewModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CharacterViewModelCopyWith<$Res> {
  factory $CharacterViewModelCopyWith(
          CharacterViewModel value, $Res Function(CharacterViewModel) then) =
      _$CharacterViewModelCopyWithImpl<$Res, CharacterViewModel>;
  @useResult
  $Res call(
      {String id,
      String pageId,
      String character,
      String thumbnailPath,
      DateTime createdAt,
      DateTime updatedAt,
      bool isFavorite,
      bool isSelected,
      bool isModified});
}

/// @nodoc
class _$CharacterViewModelCopyWithImpl<$Res, $Val extends CharacterViewModel>
    implements $CharacterViewModelCopyWith<$Res> {
  _$CharacterViewModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of CharacterViewModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? pageId = null,
    Object? character = null,
    Object? thumbnailPath = null,
    Object? createdAt = null,
    Object? updatedAt = null,
    Object? isFavorite = null,
    Object? isSelected = null,
    Object? isModified = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      pageId: null == pageId
          ? _value.pageId
          : pageId // ignore: cast_nullable_to_non_nullable
              as String,
      character: null == character
          ? _value.character
          : character // ignore: cast_nullable_to_non_nullable
              as String,
      thumbnailPath: null == thumbnailPath
          ? _value.thumbnailPath
          : thumbnailPath // ignore: cast_nullable_to_non_nullable
              as String,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      updatedAt: null == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      isFavorite: null == isFavorite
          ? _value.isFavorite
          : isFavorite // ignore: cast_nullable_to_non_nullable
              as bool,
      isSelected: null == isSelected
          ? _value.isSelected
          : isSelected // ignore: cast_nullable_to_non_nullable
              as bool,
      isModified: null == isModified
          ? _value.isModified
          : isModified // ignore: cast_nullable_to_non_nullable
              as bool,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$CharacterViewModelImplCopyWith<$Res>
    implements $CharacterViewModelCopyWith<$Res> {
  factory _$$CharacterViewModelImplCopyWith(_$CharacterViewModelImpl value,
          $Res Function(_$CharacterViewModelImpl) then) =
      __$$CharacterViewModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String pageId,
      String character,
      String thumbnailPath,
      DateTime createdAt,
      DateTime updatedAt,
      bool isFavorite,
      bool isSelected,
      bool isModified});
}

/// @nodoc
class __$$CharacterViewModelImplCopyWithImpl<$Res>
    extends _$CharacterViewModelCopyWithImpl<$Res, _$CharacterViewModelImpl>
    implements _$$CharacterViewModelImplCopyWith<$Res> {
  __$$CharacterViewModelImplCopyWithImpl(_$CharacterViewModelImpl _value,
      $Res Function(_$CharacterViewModelImpl) _then)
      : super(_value, _then);

  /// Create a copy of CharacterViewModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? pageId = null,
    Object? character = null,
    Object? thumbnailPath = null,
    Object? createdAt = null,
    Object? updatedAt = null,
    Object? isFavorite = null,
    Object? isSelected = null,
    Object? isModified = null,
  }) {
    return _then(_$CharacterViewModelImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      pageId: null == pageId
          ? _value.pageId
          : pageId // ignore: cast_nullable_to_non_nullable
              as String,
      character: null == character
          ? _value.character
          : character // ignore: cast_nullable_to_non_nullable
              as String,
      thumbnailPath: null == thumbnailPath
          ? _value.thumbnailPath
          : thumbnailPath // ignore: cast_nullable_to_non_nullable
              as String,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      updatedAt: null == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      isFavorite: null == isFavorite
          ? _value.isFavorite
          : isFavorite // ignore: cast_nullable_to_non_nullable
              as bool,
      isSelected: null == isSelected
          ? _value.isSelected
          : isSelected // ignore: cast_nullable_to_non_nullable
              as bool,
      isModified: null == isModified
          ? _value.isModified
          : isModified // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$CharacterViewModelImpl implements _CharacterViewModel {
  const _$CharacterViewModelImpl(
      {required this.id,
      required this.pageId,
      required this.character,
      required this.thumbnailPath,
      required this.createdAt,
      required this.updatedAt,
      this.isFavorite = false,
      this.isSelected = false,
      this.isModified = false});

  factory _$CharacterViewModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$CharacterViewModelImplFromJson(json);

  @override
  final String id;
  @override
  final String pageId;
  @override
  final String character;
  @override
  final String thumbnailPath;
  @override
  final DateTime createdAt;
  @override
  final DateTime updatedAt;
  @override
  @JsonKey()
  final bool isFavorite;
  @override
  @JsonKey()
  final bool isSelected;
// New property
  @override
  @JsonKey()
  final bool isModified;

  @override
  String toString() {
    return 'CharacterViewModel(id: $id, pageId: $pageId, character: $character, thumbnailPath: $thumbnailPath, createdAt: $createdAt, updatedAt: $updatedAt, isFavorite: $isFavorite, isSelected: $isSelected, isModified: $isModified)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CharacterViewModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.pageId, pageId) || other.pageId == pageId) &&
            (identical(other.character, character) ||
                other.character == character) &&
            (identical(other.thumbnailPath, thumbnailPath) ||
                other.thumbnailPath == thumbnailPath) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt) &&
            (identical(other.isFavorite, isFavorite) ||
                other.isFavorite == isFavorite) &&
            (identical(other.isSelected, isSelected) ||
                other.isSelected == isSelected) &&
            (identical(other.isModified, isModified) ||
                other.isModified == isModified));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, pageId, character,
      thumbnailPath, createdAt, updatedAt, isFavorite, isSelected, isModified);

  /// Create a copy of CharacterViewModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CharacterViewModelImplCopyWith<_$CharacterViewModelImpl> get copyWith =>
      __$$CharacterViewModelImplCopyWithImpl<_$CharacterViewModelImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$CharacterViewModelImplToJson(
      this,
    );
  }
}

abstract class _CharacterViewModel implements CharacterViewModel {
  const factory _CharacterViewModel(
      {required final String id,
      required final String pageId,
      required final String character,
      required final String thumbnailPath,
      required final DateTime createdAt,
      required final DateTime updatedAt,
      final bool isFavorite,
      final bool isSelected,
      final bool isModified}) = _$CharacterViewModelImpl;

  factory _CharacterViewModel.fromJson(Map<String, dynamic> json) =
      _$CharacterViewModelImpl.fromJson;

  @override
  String get id;
  @override
  String get pageId;
  @override
  String get character;
  @override
  String get thumbnailPath;
  @override
  DateTime get createdAt;
  @override
  DateTime get updatedAt;
  @override
  bool get isFavorite;
  @override
  bool get isSelected; // New property
  @override
  bool get isModified;

  /// Create a copy of CharacterViewModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CharacterViewModelImplCopyWith<_$CharacterViewModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
