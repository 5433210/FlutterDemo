import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../domain/models/character/character_view.dart';
import '../../../presentation/providers/character/character_detail_provider.dart';

part 'character_detail_state.freezed.dart';
part 'character_detail_state.g.dart';

/// State for character detail view
@freezed
class CharacterDetailState with _$CharacterDetailState {
  const factory CharacterDetailState({
    /// The character being viewed
    CharacterView? character,

    /// Related characters (usually from the same work)
    @Default([]) List<CharacterView> relatedCharacters,

    /// Selected format index
    @Default(0) int selectedFormat,

    /// Available image formats
    @JsonKey(includeFromJson: false, includeToJson: false)
    @Default([])
    List<CharacterFormatInfo> availableFormats,

    /// Path to original image
    String? originalPath,

    /// Path to binary image
    String? binaryPath,

    /// Path to transparent image
    String? transparentPath,

    /// Path to square binary image
    String? squareBinaryPath,

    /// Path to square transparent image
    String? squareTransparentPath,

    /// Path to SVG outline
    String? outlinePath,

    /// Path to thumbnail image
    String? thumbnailPath,

    /// Whether loading is in progress
    @Default(false) bool isLoading,

    /// Error message if loading failed
    String? error,
  }) = _CharacterDetailState;

  factory CharacterDetailState.fromJson(Map<String, dynamic> json) =>
      _$CharacterDetailStateFromJson(json);

  /// Create initial state
  factory CharacterDetailState.initial() =>
      const CharacterDetailState(isLoading: true);

  const CharacterDetailState._(); // Add private constructor
}
