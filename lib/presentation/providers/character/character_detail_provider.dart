import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../application/providers/repository_providers.dart';
import '../../../application/services/character/character_service.dart';
import '../../../domain/models/character/character_view.dart';
import '../../../infrastructure/logging/logger.dart';

part 'character_detail_provider.freezed.dart';
part 'character_detail_provider.g.dart';

/// Provider family for selected character details
final characterDetailProvider =
    FutureProvider.family<CharacterDetailState?, String?>(
        (ref, characterId) async {
  if (characterId == null) return null;

  final characterViewRepository = ref.watch(characterViewRepositoryProvider);
  final characterService = ref.watch(characterServiceProvider);

  try {
    // Fetch character details
    final character =
        await characterViewRepository.getCharacterById(characterId);
    if (character == null) return null;

    // Fetch related characters
    final relatedCharacters =
        await characterViewRepository.getRelatedCharacters(characterId);

    // Get image paths
    final thumbnailPath =
        await characterService.getCharacterThumbnailPath(characterId);
    final transparentPath =
        await characterService.getCharacterImagePath(characterId);

    return CharacterDetailState(
      character: character,
      relatedCharacters: relatedCharacters,
      selectedFormat: 0,
      availableFormats: _getAvailableFormats(character.id),
      thumbnailPath: thumbnailPath,
      transparentPath: transparentPath,
      isLoading: false,
    );
  } catch (e) {
    AppLogger.error('Error loading character details',
        error: e, data: {'characterId': characterId});
    return CharacterDetailState(
      isLoading: false,
      error: e.toString(),
    );
  }
});

/// Provider for selected format in detail view
final selectedFormatProvider = StateProvider<int>((ref) => 0);

/// Available character image formats
List<CharacterFormatInfo> _getAvailableFormats(String characterId) {
  return [
    CharacterFormatInfo(
      format: CharacterImageFormat.original,
      name: '原始图像',
      description: '未经处理的原始图像',
      pathResolver: (id) => '${id}_original',
    ),
    CharacterFormatInfo(
      format: CharacterImageFormat.binary,
      name: '二值化',
      description: '黑白二值化图像',
      pathResolver: (id) => '${id}_binary',
    ),
    CharacterFormatInfo(
      format: CharacterImageFormat.transparent,
      name: '透明背景',
      description: '去背景的透明PNG图像',
      pathResolver: (id) => '${id}_transparent',
    ),
    CharacterFormatInfo(
      format: CharacterImageFormat.squareBinary,
      name: '方形二值化',
      description: '规整为正方形的二值化图像',
      pathResolver: (id) => '${id}_square_binary',
    ),
    CharacterFormatInfo(
      format: CharacterImageFormat.squareTransparent,
      name: '方形透明',
      description: '规整为正方形的透明PNG图像',
      pathResolver: (id) => '${id}_square_transparent',
    ),
  ];
}

/// State for character detail view
class CharacterDetailState {
  final CharacterView? character;
  final List<CharacterView> relatedCharacters;
  final int selectedFormat;
  final List<CharacterFormatInfo> availableFormats;
  final bool isLoading;
  final String? error;
  final String? thumbnailPath;
  final String? transparentPath;

  const CharacterDetailState({
    this.character,
    this.relatedCharacters = const [],
    this.selectedFormat = 0,
    this.availableFormats = const [],
    this.isLoading = true,
    this.error,
    this.thumbnailPath,
    this.transparentPath,
  });
}

/// Character format information with JSON serialization support
@freezed
class CharacterFormatInfo with _$CharacterFormatInfo {
  const factory CharacterFormatInfo({
    required CharacterImageFormat format,
    required String name,
    required String description,
    @JsonKey(ignore: true) String Function(String)? pathResolver,
  }) = _CharacterFormatInfo;

  factory CharacterFormatInfo.fromJson(Map<String, dynamic> json) =>
      _$CharacterFormatInfoFromJson(json);

  const CharacterFormatInfo._();

  String resolvePath(String characterId) {
    if (pathResolver == null) {
      // Default path resolution if no custom resolver provided
      switch (format) {
        case CharacterImageFormat.original:
          return '${characterId}_original';
        case CharacterImageFormat.binary:
          return '${characterId}_binary';
        case CharacterImageFormat.transparent:
          return '${characterId}_transparent';
        case CharacterImageFormat.squareBinary:
          return '${characterId}_square_binary';
        case CharacterImageFormat.squareTransparent:
          return '${characterId}_square_transparent';
        default:
          return '${characterId}_original';
      }
    }
    return pathResolver!(characterId);
  }
}

/// Image format types
@JsonEnum()
enum CharacterImageFormat {
  original,
  binary,
  transparent,
  squareBinary,
  squareTransparent,
}
