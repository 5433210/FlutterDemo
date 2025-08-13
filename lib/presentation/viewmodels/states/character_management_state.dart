import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../domain/models/character/character_filter.dart';
import '../../../domain/models/character/character_view.dart';

part 'character_management_state.freezed.dart';
part 'character_management_state.g.dart';

/// To JSON converter for CharacterFilter
@JsonSerializable()
class CharacterFilterConverter {
  static CharacterFilter fromJson(Map<String, dynamic> json) =>
      CharacterFilter.fromJson(json);
  static Map<String, dynamic> toJson(CharacterFilter filter) => filter.toJson();
}

/// State for the character management page
@freezed
class CharacterManagementState with _$CharacterManagementState {
  const factory CharacterManagementState({
    /// List of characters to display
    @Default([]) List<CharacterView> characters,

    /// All available tags for filtering
    @Default([]) List<String> allTags,

    /// Current filter settings
    @Default(CharacterFilter()) CharacterFilter filter,

    /// Whether data is currently loading
    @Default(false) bool isLoading,

    /// Whether batch selection mode is active
    @Default(false) bool isBatchMode,

    /// Set of selected character IDs in batch mode
    @Default({}) Set<String> selectedCharacters,

    /// Whether the detail panel is open
    @Default(false) bool isDetailOpen,

    /// Whether the filter panel is shown
    @Default(true) bool showFilterPanel,

    /// Error message, if any
    String? errorMessage,

    /// ID of selected character for detail view
    String? selectedCharacterId,

    /// Current view mode (grid or list)
    @Default(ViewMode.grid) ViewMode viewMode,

    /// Total character count (for pagination)
    @Default(0) int totalCount,

    /// Current page (for pagination)
    @Default(1) int currentPage,

    /// Page size (for pagination)
    @Default(20) int pageSize,
  }) = _CharacterManagementState;

  /// Create from JSON
  factory CharacterManagementState.fromJson(Map<String, dynamic> json) =>
      _$CharacterManagementStateFromJson(json);

  /// Create an initial state
  factory CharacterManagementState.initial() =>
      const CharacterManagementState();
}

/// View mode enum for the character management page
enum ViewMode {
  /// Grid view (displays characters as cards in a grid)
  grid,

  /// List view (displays characters in a table-like list)
  list,
}
