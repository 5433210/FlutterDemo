import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../application/providers/repository_providers.dart';
import '../../../application/services/character/character_service.dart';
import '../../../domain/models/character/character_image_type.dart';
import '../../../domain/models/character/character_view.dart';
import '../../../infrastructure/logging/logger.dart';
import '../../../l10n/app_localizations.dart';

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
    final thumbnailPath = await characterService.getCharacterImagePath(
        characterId, CharacterImageType.thumbnail);
    final transparentPath = await characterService.getCharacterImagePath(
        characterId, CharacterImageType.transparent);

    return CharacterDetailState(
      character: character,
      relatedCharacters: relatedCharacters,
      selectedFormat: 0,
      availableFormats: _getAvailableFormats(character.id, characterService),
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

/// 获取本地化的格式描述
String getLocalizedFormatDescription(
    BuildContext context, CharacterImageType format) {
  final l10n = AppLocalizations.of(context);

  switch (format) {
    case CharacterImageType.original:
      return l10n.originalImageDesc;
    case CharacterImageType.binary:
      return l10n.characterDetailFormatBinaryDesc;
    case CharacterImageType.thumbnail:
      return l10n.characterDetailFormatThumbnailDesc;
    case CharacterImageType.squareBinary:
      return l10n.characterDetailFormatSquareBinaryDesc;
    case CharacterImageType.squareTransparent:
      return l10n.characterDetailFormatSquareTransparentDesc;
    case CharacterImageType.transparent:
      return l10n.characterDetailFormatTransparentDesc;
    case CharacterImageType.outline:
      return l10n.characterDetailFormatOutlineDesc;
    case CharacterImageType.squareOutline:
      return l10n.characterDetailFormatSquareOutlineDesc;
  }
}

/// 获取本地化的格式名称
String getLocalizedFormatName(BuildContext context, CharacterImageType format) {
  final l10n = AppLocalizations.of(context);

  switch (format) {
    case CharacterImageType.original:
      return l10n.original;
    case CharacterImageType.binary:
      return l10n.characterDetailFormatBinary;
    case CharacterImageType.thumbnail:
      return l10n.characterDetailFormatThumbnail;
    case CharacterImageType.squareBinary:
      return l10n.characterDetailFormatSquareBinary;
    case CharacterImageType.squareTransparent:
      return l10n.characterDetailFormatSquareTransparent;
    case CharacterImageType.transparent:
      return l10n.characterDetailFormatTransparent;
    case CharacterImageType.outline:
      return l10n.characterDetailFormatOutline;
    case CharacterImageType.squareOutline:
      return l10n.characterDetailFormatSquareOutline;
  }
}

/// Available character image formats
List<CharacterFormatInfo> _getAvailableFormats(
    String characterId, CharacterService characterService) {
  // 注意：这里使用英文字符串，将在UI层通过本地化替换
  return [
    CharacterFormatInfo(
      format: CharacterImageType.original,
      name: 'Original Image', // 将在UI层通过本地化替换
      description: 'Unprocessed original image', // 将在UI层通过本地化替换
      pathResolver: (id) async => await characterService.getCharacterImagePath(
          id, CharacterImageType.original),
    ),
    CharacterFormatInfo(
      format: CharacterImageType.binary,
      name: 'Binary', // 将在UI层通过本地化替换
      description: 'Black and white binary image', // 将在UI层通过本地化替换
      pathResolver: (id) async => await characterService.getCharacterImagePath(
          id, CharacterImageType.binary),
    ),
    CharacterFormatInfo(
      format: CharacterImageType.transparent,
      name: 'Transparent Background', // 将在UI层通过本地化替换
      description:
          'Transparent PNG image with background removed', // 将在UI层通过本地化替换
      pathResolver: (id) async => await characterService.getCharacterImagePath(
          id, CharacterImageType.transparent),
    ),
    CharacterFormatInfo(
      format: CharacterImageType.squareBinary,
      name: 'Square Binary', // 将在UI层通过本地化替换
      description: 'Binary image normalized to square', // 将在UI层通过本地化替换
      pathResolver: (id) async => await characterService.getCharacterImagePath(
          id, CharacterImageType.squareBinary),
    ),
    CharacterFormatInfo(
      format: CharacterImageType.squareTransparent,
      name: 'Square Transparent', // 将在UI层通过本地化替换
      description: 'Transparent PNG image normalized to square', // 将在UI层通过本地化替换
      pathResolver: (id) async => await characterService.getCharacterImagePath(
          id, CharacterImageType.squareTransparent),
    ),
    CharacterFormatInfo(
      format: CharacterImageType.outline,
      name: 'Outline', // 将在UI层通过本地化替换
      description: 'Shows only the outline', // 将在UI层通过本地化替换
      pathResolver: (id) async => await characterService.getCharacterImagePath(
          id, CharacterImageType.outline),
    ),
    CharacterFormatInfo(
      format: CharacterImageType.squareOutline,
      name: 'Square Outline', // 将在UI层通过本地化替换
      description: 'Outline image normalized to square', // 将在UI层通过本地化替换
      pathResolver: (id) async => await characterService.getCharacterImagePath(
          id, CharacterImageType.squareOutline),
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
    required CharacterImageType format,
    required String name,
    required String description,
    @JsonKey(includeFromJson: false, includeToJson: false)
    Future<String> Function(String)? pathResolver,
  }) = _CharacterFormatInfo;

  factory CharacterFormatInfo.fromJson(Map<String, dynamic> json) =>
      _$CharacterFormatInfoFromJson(json);

  const CharacterFormatInfo._();

  Future<String> resolvePath(String characterId) async {
    if (pathResolver == null) {
      // Default path resolution if no custom resolver provided
      switch (format) {
        case CharacterImageType.original:
          return '$characterId-original';
        case CharacterImageType.binary:
          return '$characterId-binary';
        case CharacterImageType.transparent:
          return '$characterId-transparent';
        case CharacterImageType.squareBinary:
          return '$characterId-square-binary';
        case CharacterImageType.squareTransparent:
          return '$characterId-square-transparent';
        case CharacterImageType.outline:
          return '$characterId-outline';
        case CharacterImageType.squareOutline:
          return '$characterId-square-outline';
        case CharacterImageType.thumbnail:
          return '$characterId-thumbnail';
      }
    }
    return pathResolver!(characterId);
  }
}
