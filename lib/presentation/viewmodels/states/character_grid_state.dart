import 'package:freezed_annotation/freezed_annotation.dart';

part 'character_grid_state.freezed.dart';
part 'character_grid_state.g.dart';

@freezed
class CharacterGridState with _$CharacterGridState {
  const factory CharacterGridState({
    @Default([]) List<CharacterViewModel> characters,
    @Default([]) List<CharacterViewModel> filteredCharacters,
    @Default('') String searchTerm,
    @Default(FilterType.all) FilterType filterType,
    @Default({}) Set<String> selectedIds, // Keeping for transition period
    @Default(1) int currentPage,
    @Default(1) int totalPages,
    @Default(16) int pageSize, // 每页显示数量，默认16
    @Default(false) bool loading,
    @Default(true) bool isInitialLoad, // 添加初始加载标志，默认为true
    String? error,
  }) = _CharacterGridState;

  factory CharacterGridState.fromJson(Map<String, dynamic> json) =>
      _$CharacterGridStateFromJson(json);
}

@freezed
class CharacterViewModel with _$CharacterViewModel {
  const factory CharacterViewModel({
    required String id,
    required String pageId,
    required String character,
    required String thumbnailPath,
    required DateTime createdAt,
    required DateTime updatedAt,
    @Default(false) bool isFavorite,
    @Default(false) bool isSelected, // New property
    @Default(false) bool isModified, // New property
  }) = _CharacterViewModel;

  factory CharacterViewModel.fromJson(Map<String, dynamic> json) =>
      _$CharacterViewModelFromJson(json);
}

enum FilterType {
  all,
  recent,
  favorite,
}
