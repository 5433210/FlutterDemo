import 'package:freezed_annotation/freezed_annotation.dart';

import '../../widgets/character_collection/filter_type.dart';

part 'character_grid_state.freezed.dart';
part 'character_grid_state.g.dart';

@freezed
class CharacterGridState with _$CharacterGridState {
  const factory CharacterGridState({
    @Default([]) List<CharacterViewModel> characters,
    @Default([]) List<CharacterViewModel> filteredCharacters,
    @Default('') String searchTerm,
    @Default(FilterType.all) FilterType filterType,
    @Default({}) Set<String> selectedIds,
    @Default(1) int currentPage,
    @Default(1) int totalPages,
    @Default(false) bool loading,
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
  }) = _CharacterViewModel;

  factory CharacterViewModel.fromJson(Map<String, dynamic> json) =>
      _$CharacterViewModelFromJson(json);
}
