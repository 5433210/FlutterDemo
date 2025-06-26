import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../application/providers/service_providers.dart';
import '../../../../application/services/services.dart';
import '../../../../domain/models/character/character_entity.dart';
import '../../../../infrastructure/logging/edit_page_logger_extension.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../presentation/viewmodels/states/character_grid_state.dart';
import '../../../../utils/config/edit_page_logging_config.dart';
import '../practice_edit_controller.dart';
import 'collection_panels/m3_background_texture_panel.dart';
import 'collection_panels/m3_content_settings_panel.dart';
import 'collection_panels/m3_geometry_properties_panel.dart';
import 'collection_panels/m3_visual_properties_panel.dart';
import 'm3_element_common_property_panel.dart';
import 'm3_layer_info_panel.dart';

/// 匹配模式枚举
enum MatchingMode {
  /// 词匹配模式：优先寻找完整匹配的词，没有时智能分词
  wordMatching,

  /// 字符匹配模式：逐个字符精确匹配
  characterMatching,
}

/// Material 3 version of the Collection Property Panel with internationalization support
class M3CollectionPropertyPanel extends ConsumerStatefulWidget {
  final Map<String, dynamic> element;
  final Function(Map<String, dynamic>) onElementPropertiesChanged;
  final Function(String) onUpdateChars;
  final PracticeEditController controller;
  final WidgetRef? ref;

  const M3CollectionPropertyPanel({
    Key? key,
    required this.controller,
    required this.element,
    required this.onElementPropertiesChanged,
    required this.onUpdateChars,
    this.ref,
  }) : super(key: key);

  @override
  ConsumerState<M3CollectionPropertyPanel> createState() =>
      _M3CollectionPropertyPanelState();
}

class _M3CollectionPropertyPanelState
    extends ConsumerState<M3CollectionPropertyPanel> {
  // Current selected character index
  int _selectedCharIndex = 0;

  // Candidate characters list for the selected character
  List<CharacterEntity> _candidateCharacters = [];
  bool _isLoadingCharacters = false;

  // Text controller
  final TextEditingController _textController = TextEditingController();
  // Debounce timer
  Timer? _debounceTimer;

  // Controls candidate character color inversion
  bool _invertCandidateDisplay = false;

  // 匹配模式状态
  MatchingMode _matchingMode = MatchingMode.wordMatching;
  @override
  Widget build(BuildContext context) {
    final layerId = widget.element['layerId'] as String?;

    // Get layer information
    Map<String, dynamic>? layer;
    if (layerId != null) {
      layer = widget.controller.state.getLayerById(layerId);
    }

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      children: [
        // Basic properties section (at the top)
        M3ElementCommonPropertyPanel(
          element: widget.element,
          onElementPropertiesChanged: widget.onElementPropertiesChanged,
          controller: widget.controller,
        ),

        // Layer information section
        M3LayerInfoPanel(layer: layer),

        // Geometry properties section
        M3GeometryPropertiesPanel(
          element: widget.element,
          onPropertyChanged: _updateProperty,
        ), // Visual properties section
        M3VisualPropertiesPanel(
          element: widget.element,
          onPropertyChanged: _updateProperty,
          onContentPropertyChanged: _updateContentProperty,
        ),

        // Background texture section
        M3BackgroundTexturePanel(
          element: widget.element,
          onPropertyChanged: _updateProperty,
          onContentPropertyChanged: _updateContentProperty,
        ),

        // Content settings section
        M3ContentSettingsPanel(
          element: widget.element,
          selectedCharIndex: _selectedCharIndex,
          candidateCharacters: _candidateCharacters,
          isLoading: _isLoadingCharacters,
          invertDisplay: _invertCandidateDisplay,
          wordMatchingMode: _matchingMode == MatchingMode.wordMatching,
          searchQuery: _getSearchQuery(),
          onTextChanged: _onTextChanged,
          onCharacterSelected: _selectCharacter,
          onCandidateCharacterSelected: _selectCandidateCharacter,
          onInvertDisplayToggled: _onInvertDisplayToggled,
          onCharacterInvertToggled: _onCharacterInvertToggled,
          onWordMatchingModeChanged: _onWordMatchingModeChanged,
          onContentPropertyChanged: _updateContentProperty,
        ),
      ],
    );
  }

  @override
  void didUpdateWidget(M3CollectionPropertyPanel oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.element != widget.element) {
      // 检查并清理嵌套的 content 结构
      Future.microtask(() {
        _cleanupNestedContent();
      });

      // Update text controller
      final content = widget.element['content'] as Map<String, dynamic>;
      final characters = content['characters'] as String? ?? '';
      final oldContent = oldWidget.element['content'] as Map<String, dynamic>;
      final oldCharacters = oldContent['characters'] as String? ?? '';

      // Only update controller when text actually changes to avoid cursor position reset
      if (_textController.text != characters) {
        _textController.text = characters;
      }

      // 检查是否需要保留字符图像信息
      // 注意：此变量目前未使用，但保留以便将来可能的扩展
      // final shouldPreserveImages = oldContent.containsKey('characterImages') &&
      //     content.containsKey('characterImages') &&
      //     oldCharacters == characters;      // Update candidate characters
      if (oldCharacters != characters) {
        Future.microtask(() {
          _cleanupCharacterImages(characters);
          _loadCandidateCharacters();
          _updateCharacterImagesForNewText(characters);
        });
      }
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    if (_debounceTimer?.isActive ?? false) {
      _debounceTimer!.cancel();
    }
    super.dispose();
  }

  // 递归处理嵌套的 content 结构，提取所有属性到根级别
  // 该方法已被 _deepFlattenContent 替代

  // 该方法已在上面定义

  @override
  void initState() {
    super.initState();

    // Initialize text controller
    final content = widget.element['content'] as Map<String, dynamic>;
    final characters = content['characters'] as String? ?? '';
    _textController.text = characters;

    // Use addPostFrameCallback to defer state updates to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // 首先清理嵌套的 content 结构
      _cleanupNestedContent();

      // 初始化匹配模式和 segments
      _initializeMatchingModeAndSegments();

      // Load candidate characters
      _loadCandidateCharacters();

      // Auto-update missing character images
      if (characters.isNotEmpty) {
        _autoUpdateMissingCharacterImages(characters);
      }
    });
  }

  /// 初始化匹配模式和 segments
  void _initializeMatchingModeAndSegments() {
    final content = Map<String, dynamic>.from(
        widget.element['content'] as Map<String, dynamic>);
    final characters = content['characters'] as String? ?? '';

    // 检查是否已有匹配模式设置，如果没有则使用默认值
    final hasWordMatchingPriority = content.containsKey('wordMatchingPriority');
    final wordMatchingPriority = content['wordMatchingPriority'] as bool? ??
        (_matchingMode == MatchingMode.wordMatching);

    // 更新内部状态以匹配 content 中的设置
    _matchingMode = wordMatchingPriority
        ? MatchingMode.wordMatching
        : MatchingMode.characterMatching;

    bool needsUpdate = false;

    // 如果 content 中没有匹配模式设置，添加它
    if (!hasWordMatchingPriority) {
      content['wordMatchingPriority'] = wordMatchingPriority;
      needsUpdate = true;
    }

    // 检查是否需要生成 segments
    final segments = content['segments'] as List<dynamic>? ?? [];
    if (segments.isEmpty && characters.isNotEmpty) {
      content['segments'] = _generateSegments(characters, wordMatchingPriority);
      needsUpdate = true;
    }

    // 如果需要更新 content，执行更新
    if (needsUpdate) {
      EditPageLogger.propertyPanelDebug(
        '[WORD_MATCHING_DEBUG] 初始化匹配模式和segments',
        tag: EditPageLoggingConfig.TAG_COLLECTION_PANEL,
        data: {
          'wordMatchingPriority': wordMatchingPriority,
          'characters': characters,
          'segmentsCount': (content['segments'] as List<dynamic>).length,
        },
      );

      widget.onElementPropertiesChanged({'content': content});
    }
  }

  // Auto-update missing character images
  Future<void> _autoUpdateMissingCharacterImages(String characters) async {
    try {
      if (characters.isEmpty) return;

      // Get current content
      final content = Map<String, dynamic>.from(
          widget.element['content'] as Map<String, dynamic>? ?? {});

      // Get existing character image information
      Map<String, dynamic> characterImages = {};
      if (content.containsKey('characterImages')) {
        characterImages = Map<String, dynamic>.from(
            content['characterImages'] as Map<String, dynamic>);
      }

      // Get character services
      final characterService = ref.read(characterServiceProvider);
      final characterImageService = ref.read(characterImageServiceProvider);

      // Track if there are updates
      bool hasUpdates = false;

      // Process each character
      for (int i = 0; i < characters.length; i++) {
        final char = characters[i];

        // Skip newlines
        if (char == '\n') continue;

        // Check if this character already has valid image info
        final imageInfo = characterImages['$i'] as Map<String, dynamic>?;

        // Skip if already has valid image info and not temporary
        if (imageInfo != null &&
            imageInfo.containsKey('characterId') &&
            imageInfo.containsKey('type') &&
            imageInfo.containsKey('format') &&
            imageInfo['isTemporary'] != true) {
          continue;
        }

        try {
          // Search for matching candidate characters
          EditPageLogger.propertyPanelDebug(
            '[CHARACTER_MATCHING_DEBUG] 搜索字符匹配结果',
            tag: EditPageLoggingConfig.TAG_COLLECTION_PANEL,
            data: {
              'operation': 'search_character',
              'character': char,
              'index': i,
              'charCode': char.codeUnitAt(0),
            },
          );

          final matchingCharacters =
              await characterService.searchCharacters(char);

          EditPageLogger.propertyPanelDebug(
            '[CHARACTER_MATCHING_DEBUG] 字符搜索结果',
            tag: EditPageLoggingConfig.TAG_COLLECTION_PANEL,
            data: {
              'operation': 'search_result',
              'character': char,
              'index': i,
              'resultCount': matchingCharacters.length,
            },
          );

          // If no matching candidates found, set placeholder
          if (matchingCharacters.isEmpty) {
            final placeholderId = 'placeholder_${char}_$i';
            characterImages['$i'] = {
              'characterId': placeholderId,
              'type': 'placeholder',
              'format': 'text',
              'drawingType': 'placeholder',
              'drawingFormat': 'text',
              'isPlaceholder': true,
              'originalCharacter': char,
              'transform': {
                'scale': 1.0,
                'rotation': 0.0,
                'color': content['fontColor'] ?? '#000000',
                'opacity': 0.5,
                'invert': false,
              },
            };
            hasUpdates = true;

            EditPageLogger.propertyPanelDebug(
              '[CHARACTER_MATCHING_DEBUG] 设置占位符',
              tag: EditPageLoggingConfig.TAG_COLLECTION_PANEL,
              data: {
                'operation': 'set_placeholder',
                'character': char,
                'index': i,
                'placeholderId': placeholderId,
              },
            );
            continue;
          }

          // Get detailed info of the first matching character
          final characterEntity = await characterService
              .getCharacterDetails(matchingCharacters.first.id);

          // Skip if cannot get details
          if (characterEntity == null) {
            final placeholderId = 'placeholder_${char}_$i';
            characterImages['$i'] = {
              'characterId': placeholderId,
              'type': 'placeholder',
              'format': 'text',
              'drawingType': 'placeholder',
              'drawingFormat': 'text',
              'isPlaceholder': true,
              'originalCharacter': char,
              'transform': {
                'scale': 1.0,
                'rotation': 0.0,
                'color': content['fontColor'] ?? '#000000',
                'opacity': 0.5,
                'invert': false,
              },
            };
            hasUpdates = true;

            EditPageLogger.propertyPanelDebug(
              '[CHARACTER_MATCHING_DEBUG] 获取字符详情失败，设置占位符',
              tag: EditPageLoggingConfig.TAG_COLLECTION_PANEL,
              data: {
                'operation': 'character_details_failed',
                'character': char,
                'index': i,
                'placeholderId': placeholderId,
              },
            );
            continue;
          }

          // Get character image format
          final format = await characterImageService
              .getAvailableFormat(characterEntity.id);

          // Skip if cannot get format
          if (format == null) {
            final placeholderId = 'placeholder_${char}_$i';
            characterImages['$i'] = {
              'characterId': placeholderId,
              'type': 'placeholder',
              'format': 'text',
              'drawingType': 'placeholder',
              'drawingFormat': 'text',
              'isPlaceholder': true,
              'originalCharacter': char,
              'transform': {
                'scale': 1.0,
                'rotation': 0.0,
                'color': content['fontColor'] ?? '#000000',
                'opacity': 0.5,
                'invert': false,
              },
            };
            hasUpdates = true;

            EditPageLogger.propertyPanelDebug(
              '[CHARACTER_MATCHING_DEBUG] 获取图像格式失败，设置占位符',
              tag: EditPageLoggingConfig.TAG_COLLECTION_PANEL,
              data: {
                'operation': 'format_failed',
                'character': char,
                'index': i,
                'placeholderId': placeholderId,
              },
            );
            continue;
          }

          // Check available image formats
          final hasSquareBinary = await characterImageService.hasCharacterImage(
              characterEntity.id, 'square-binary', 'png-binary');
          final hasSquareOutline =
              await characterImageService.hasCharacterImage(
                  characterEntity.id, 'square-outline', 'svg-outline');

          // Determine drawing format
          String drawingType;
          String drawingFormat;

          if (hasSquareBinary) {
            drawingType = 'square-binary';
            drawingFormat = 'png-binary';
          } else if (hasSquareOutline) {
            drawingType = 'square-outline';
            drawingFormat = 'svg-outline';
          } else {
            drawingType = format['type'] ?? 'square-binary';
            drawingFormat = format['format'] ?? 'png-binary';
          }

          // Create character image info
          final Map<String, dynamic> newImageInfo = {
            'characterId': characterEntity.id,
            'type': format['type'] ?? 'square-binary',
            'format': format['format'] ?? 'png-binary',
            'drawingType': drawingType,
            'drawingFormat': drawingFormat,
            'transform': {
              'scale': 1.0,
              'rotation': 0.0,
              'color': content['fontColor'] ?? '#000000',
              'opacity': 1.0,
              'invert': false,
            }
          };

          // If previous image info exists, try to preserve transform property
          if (imageInfo != null && imageInfo.containsKey('transform')) {
            newImageInfo['transform'] = Map<String, dynamic>.from(
                imageInfo['transform'] as Map<String, dynamic>);
          }

          // Update character image info
          characterImages['$i'] = newImageInfo;
          hasUpdates = true;

          EditPageLogger.propertyPanelDebug(
            '[CHARACTER_MATCHING_DEBUG] 成功绑定字符',
            tag: EditPageLoggingConfig.TAG_COLLECTION_PANEL,
            data: {
              'operation': 'character_bound',
              'character': char,
              'index': i,
              'characterId': characterEntity.id,
              'type': format['type'],
              'format': format['format'],
            },
          );
        } catch (e) {
          // If any error occurs during character processing, set placeholder
          final placeholderId = 'placeholder_${char}_$i';
          characterImages['$i'] = {
            'characterId': placeholderId,
            'type': 'placeholder',
            'format': 'text',
            'drawingType': 'placeholder',
            'drawingFormat': 'text',
            'isPlaceholder': true,
            'originalCharacter': char,
            'transform': {
              'scale': 1.0,
              'rotation': 0.0,
              'color': content['fontColor'] ?? '#000000',
              'opacity': 0.5,
              'invert': false,
            },
          };
          hasUpdates = true;

          EditPageLogger.propertyPanelError(
            '[CHARACTER_MATCHING_DEBUG] 字符处理异常，设置占位符',
            tag: EditPageLoggingConfig.TAG_COLLECTION_PANEL,
            error: e,
            data: {
              'operation': 'character_processing_error',
              'character': char,
              'index': i,
              'placeholderId': placeholderId,
              'missingIndex': i,
            },
          );
        }
      }

      // If there are updates, update element content
      if (hasUpdates) {
        final updatedContent = Map<String, dynamic>.from(content);
        updatedContent['characterImages'] = characterImages;
        _updateProperty('content', updatedContent);

        // Refresh UI
        if (mounted) {
          setState(() {});
        }

        EditPageLogger.propertyPanelDebug(
          '自动更新缺失字符图像完成',
          tag: EditPageLoggingConfig.TAG_COLLECTION_PANEL,
          data: {
            'charCount': characters.length,
            'operation': 'auto_update_missing_images',
          },
        );
      }
    } catch (e) {
      EditPageLogger.propertyPanelError(
        '自动更新缺失字符图像失败',
        tag: EditPageLoggingConfig.TAG_COLLECTION_PANEL,
        error: e,
        data: {
          'charCount': characters.length,
          'operation': 'auto_update_missing_images',
        },
      );
    }
  }

  // Clean up excess character image info
  void _cleanupCharacterImages(String characters) {
    try {
      final content = widget.element['content'] as Map<String, dynamic>? ?? {};
      if (!content.containsKey('characterImages')) {
        return;
      }

      final characterImages = Map<String, dynamic>.from(
          content['characterImages'] as Map<String, dynamic>? ?? {});

      // Record keys to keep
      final Set<String> validKeys = {};

      // Add valid keys for each character
      for (int i = 0; i < characters.length; i++) {
        validKeys.add('$i');
      }

      // Find keys to remove
      final List<String> keysToRemove = [];
      for (final key in characterImages.keys) {
        if (!validKeys.contains(key)) {
          keysToRemove.add(key);
        }
      }

      // Check for nested characterImages structure
      bool hasNestedStructure = false;
      if (characterImages.containsKey('characterImages')) {
        hasNestedStructure = true;
        // Clean nested characterImages
        var nestedImages = characterImages['characterImages'];
        if (nestedImages is Map<String, dynamic>) {
          final nestedKeysToRemove = <String>[];
          for (final key in nestedImages.keys) {
            if (!validKeys.contains(key) && !characters.contains(key)) {
              nestedKeysToRemove.add(key);
            }
          }

          // Remove invalid nested keys
          for (final key in nestedKeysToRemove) {
            nestedImages.remove(key);
          }

          characterImages['characterImages'] = nestedImages;
        }
      }

      // Check for content.characterImages nested structure
      if (characterImages.containsKey('content')) {
        final content = characterImages['content'] as Map<String, dynamic>?;
        if (content != null && content.containsKey('characterImages')) {
          hasNestedStructure = true;
          var contentImages = content['characterImages'];
          if (contentImages is Map<String, dynamic>) {
            final contentKeysToRemove = <String>[];
            for (final key in contentImages.keys) {
              if (!validKeys.contains(key) && !characters.contains(key)) {
                contentKeysToRemove.add(key);
              }
            }

            // Remove invalid content keys
            for (final key in contentKeysToRemove) {
              contentImages.remove(key);
            }

            content['characterImages'] = contentImages;
            characterImages['content'] = content;
          }
        }
      }

      // If there are keys to remove, update element content
      if (keysToRemove.isNotEmpty || hasNestedStructure) {
        // Delete excess keys
        for (final key in keysToRemove) {
          characterImages.remove(key);
        }

        // Update element content
        final updatedContent = Map<String, dynamic>.from(content);
        updatedContent['characterImages'] = characterImages;
        _updateProperty('content', updatedContent);

        // Log cleanup info
        if (keysToRemove.isNotEmpty) {
          EditPageLogger.propertyPanelDebug(
            '清理字符图像信息无效键',
            tag: EditPageLoggingConfig.TAG_COLLECTION_PANEL,
            data: {
              'removedKeys': keysToRemove,
              'operation': 'cleanup_character_images',
            },
          );
        }
        if (hasNestedStructure) {
          EditPageLogger.propertyPanelDebug(
            '清理嵌套字符图像结构',
            tag: EditPageLoggingConfig.TAG_COLLECTION_PANEL,
            data: {
              'operation': 'cleanup_nested_structure',
            },
          );
        }
      }
    } catch (e) {
      EditPageLogger.propertyPanelError(
        '清理字符图像信息失败',
        tag: EditPageLoggingConfig.TAG_COLLECTION_PANEL,
        error: e,
        data: {
          'operation': 'cleanup_character_images',
        },
      );
    }
  }

  // 清理元素中的嵌套内容结构
  void _cleanupNestedContent() {
    try {
      if (widget.element.containsKey('content') &&
          widget.element['content'] is Map<String, dynamic>) {
        final content = widget.element['content'] as Map<String, dynamic>;

        // 检查是否有嵌套结构
        if (content.containsKey('content')) {
          EditPageLogger.propertyPanelDebug(
            '发现嵌套的content结构，开始清理',
            tag: EditPageLoggingConfig.TAG_COLLECTION_PANEL,
            data: {
              'operation': 'cleanup_nested_content',
            },
          );

          // 扁平化嵌套结构
          final flattenedContent = _deepFlattenContent(content);

          // 更新元素内容
          widget.onElementPropertiesChanged({'content': flattenedContent});

          EditPageLogger.propertyPanelDebug(
            '嵌套content结构清理完成',
            tag: EditPageLoggingConfig.TAG_COLLECTION_PANEL,
            data: {
              'operation': 'cleanup_nested_content_complete',
            },
          );
        }
      }
    } catch (e) {
      EditPageLogger.propertyPanelError(
        '清理嵌套content结构时出错',
        tag: EditPageLoggingConfig.TAG_COLLECTION_PANEL,
        error: e,
        data: {
          'operation': 'cleanup_nested_content',
        },
      );
    }
  }

  // Convert index-based characterImages to character-based format
  Map<String, dynamic> _convertToCharacterBasedImages(
      String characters, Map<String, dynamic> indexBasedImages) {
    final Map<String, dynamic> characterBasedImages = {};

    // Iterate through each index
    for (final entry in indexBasedImages.entries) {
      final String indexKey = entry.key;
      final dynamic imageInfo = entry.value;

      // Try to parse index
      try {
        final int index = int.parse(indexKey);
        if (index >= 0 && index < characters.length) {
          // Generate new key: character+position to ensure uniqueness
          final String character = characters[index];
          final String newKey = '$character-$index';

          // Copy image info and add character information
          if (imageInfo is Map<String, dynamic>) {
            final Map<String, dynamic> newImageInfo =
                Map<String, dynamic>.from(imageInfo);
            newImageInfo['character'] = character; // Store character itself
            newImageInfo['originalIndex'] =
                index; // Store original index for reference
            characterBasedImages[newKey] = newImageInfo;
          } else {
            characterBasedImages[newKey] = imageInfo;
          }
        }
      } catch (e) {
        // If key is not an index, copy directly
        characterBasedImages[indexKey] = imageInfo;
      }
    }

    return characterBasedImages;
  }

  // Convert character-based characterImages back to index-based format
  Map<String, dynamic> _convertToIndexBasedImages(
      String characters, Map<String, dynamic> characterBasedImages) {
    final Map<String, dynamic> indexBasedImages = {};

    // Create character-to-indices mapping
    final Map<String, List<int>> characterToIndices = {};
    for (int i = 0; i < characters.length; i++) {
      final String character = characters[i];
      characterToIndices.putIfAbsent(character, () => []).add(i);
    }

    // Iterate through character-based image info
    for (final entry in characterBasedImages.entries) {
      final String key = entry.key;
      final dynamic imageInfo = entry.value;

      if (imageInfo is Map<String, dynamic> &&
          imageInfo.containsKey('character')) {
        final String character = imageInfo['character'];

        // Find all indices for this character
        final List<int>? indices = characterToIndices[character];
        if (indices != null && indices.isNotEmpty) {
          // Try to match original index
          int targetIndex = indices.first; // Default to first matching index
          if (imageInfo.containsKey('originalIndex')) {
            final int originalIndex = imageInfo['originalIndex'];
            if (indices.contains(originalIndex)) {
              targetIndex = originalIndex; // Use original index if still valid
            }
          }

          // Copy image info and remove unneeded fields
          final Map<String, dynamic> newImageInfo =
              Map<String, dynamic>.from(imageInfo);
          newImageInfo.remove('character');
          newImageInfo.remove('originalIndex');

          // Add to index-based mapping
          indexBasedImages['$targetIndex'] = newImageInfo;
        }
      } else {
        // Handle entries not in expected format
        final keyParts = key.split('-');
        if (keyParts.length == 2) {
          try {
            final int index = int.parse(keyParts[1]);
            if (index >= 0 && index < characters.length) {
              indexBasedImages['$index'] = imageInfo;
            }
          } catch (e) {
            // Cannot parse index, skip
          }
        } else {
          // Preserve original key
          indexBasedImages[key] = imageInfo;
        }
      }
    }

    return indexBasedImages;
  }

  // 递归处理嵌套的 content 结构，提取所有属性到根级别
  Map<String, dynamic> _deepFlattenContent(Map<String, dynamic> content) {
    final result = <String, dynamic>{};

    // 递归提取所有属性
    void extractProperties(Map<String, dynamic> source) {
      for (final entry in source.entries) {
        if (entry.key == 'content' && entry.value is Map<String, dynamic>) {
          // 如果是嵌套的 content，递归提取其属性
          extractProperties(entry.value as Map<String, dynamic>);
        } else {
          // 对于其他属性，仅当尚未存在时才复制
          if (!result.containsKey(entry.key)) {
            result[entry.key] = entry.value;
          }
        }
      }
    }

    // 开始提取
    extractProperties(content);

    return result;
  }

  // Get character display label
  String _getCharacterLabel(int charIndex) {
    final content = widget.element['content'] as Map<String, dynamic>;
    final characters = content['characters'] as String? ?? '';

    if (charIndex >= 0 && charIndex < characters.length) {
      return '"${characters[charIndex]}"';
    }

    return AppLocalizations.of(context).unknown;
  }

  // Load candidate characters
  Future<void> _loadCandidateCharacters() async {
    try {
      setState(() {
        _isLoadingCharacters = true;
      });

      final characterService = ref.read(characterServiceProvider);
      final content = widget.element['content'] as Map<String, dynamic>;
      final characters = content['characters'] as String? ?? '';

      if (characters.isEmpty) {
        setState(() {
          _candidateCharacters = [];
          _isLoadingCharacters = false;
        });
        return;
      }

      final searchQuery = _getSearchQuery();

      if (searchQuery.isEmpty) {
        setState(() {
          _candidateCharacters = [];
          _isLoadingCharacters = false;
        });
        return;
      }

      EditPageLogger.propertyPanelDebug(
        '[WORD_MATCHING_DEBUG] 开始加载候选字符',
        tag: EditPageLoggingConfig.TAG_COLLECTION_PANEL,
        data: {
          'searchQuery': searchQuery,
          'matchingMode': _matchingMode.toString(),
          'selectedCharIndex': _selectedCharIndex,
        },
      );

      // 根据匹配模式选择搜索策略
      List<CharacterViewModel> matchingCharacters;
      if (_matchingMode == MatchingMode.wordMatching) {
        // 词匹配优先模式
        matchingCharacters = await characterService.searchCharactersWithMode(
          searchQuery,
          wordMatchingPriority: true,
        );
      } else {
        // 字符匹配模式 - 精确匹配单字符
        matchingCharacters = await characterService.searchCharactersWithMode(
          searchQuery,
          wordMatchingPriority: false,
        );
      }

      EditPageLogger.propertyPanelDebug(
        '[WORD_MATCHING_DEBUG] 搜索完成',
        tag: EditPageLoggingConfig.TAG_COLLECTION_PANEL,
        data: {
          'searchQuery': searchQuery,
          'resultCount': matchingCharacters.length,
        },
      );

      // 转换为 CharacterEntity 列表
      List<CharacterEntity> entities = [];
      if (matchingCharacters.isNotEmpty) {
        final futures = matchingCharacters.map((viewModel) async {
          return await characterService.getCharacterDetails(viewModel.id);
        }).toList();

        final results = await Future.wait(futures);
        entities = results.whereType<CharacterEntity>().toList();
      }

      setState(() {
        _candidateCharacters = entities;
        _isLoadingCharacters = false;
      });

      // 字符匹配模式下的特殊处理
      if (_matchingMode == MatchingMode.characterMatching) {
        await _handleCharacterMatchingMode(entities, searchQuery);
      } else {
        // 词匹配模式下的自动选择（仅当当前没有绑定候选时）
        if (entities.isNotEmpty) {
          _autoSelectFirstCandidateIfNeeded(entities, searchQuery);
        }
      }
    } catch (e) {
      setState(() {
        _candidateCharacters = [];
        _isLoadingCharacters = false;
      });
    }
  }

  /// 处理字符匹配模式的特殊逻辑
  Future<void> _handleCharacterMatchingMode(
      List<CharacterEntity> entities, String searchQuery) async {
    final content = widget.element['content'] as Map<String, dynamic>;
    final characterImages =
        content['characterImages'] as Map<String, dynamic>? ?? {};
    final charIndex = _selectedCharIndex.toString();

    EditPageLogger.propertyPanelDebug(
      '[CHARACTER_MATCHING_DEBUG] 处理字符匹配模式',
      tag: EditPageLoggingConfig.TAG_COLLECTION_PANEL,
      data: {
        'searchQuery': searchQuery,
        'selectedCharIndex': _selectedCharIndex,
        'candidateCount': entities.length,
        'hasExistingBinding': characterImages.containsKey(charIndex),
      },
    );

    // 检查当前字符是否已有绑定
    if (characterImages.containsKey(charIndex)) {
      EditPageLogger.propertyPanelDebug(
        '[CHARACTER_MATCHING_DEBUG] 当前字符已有绑定，跳过自动选择',
        tag: EditPageLoggingConfig.TAG_COLLECTION_PANEL,
        data: {'selectedCharIndex': _selectedCharIndex},
      );
      return;
    }

    if (entities.isNotEmpty) {
      // 查找精确匹配的候选字符
      final exactMatches =
          entities.where((entity) => entity.character == searchQuery).toList();

      EditPageLogger.propertyPanelDebug(
        '[CHARACTER_MATCHING_DEBUG] 实时搜索精确匹配检查',
        tag: EditPageLoggingConfig.TAG_COLLECTION_PANEL,
        data: {
          'searchQuery': searchQuery,
          'totalEntities': entities.length,
          'exactMatches': exactMatches.length,
          'exactMatchCharacters': exactMatches.map((e) => e.character).toList(),
          'exactMatchIds': exactMatches.map((e) => e.id).toList(),
          'entityDetails': entities
              .take(3)
              .map((e) => {
                    'id': e.id,
                    'character': e.character,
                    'pageId': e.pageId,
                  })
              .toList(),
        },
      );

      if (exactMatches.isNotEmpty) {
        // 自动选择第一个精确匹配的候选
        EditPageLogger.propertyPanelDebug(
          '[CHARACTER_MATCHING_DEBUG] 找到精确匹配，自动选择',
          tag: EditPageLoggingConfig.TAG_COLLECTION_PANEL,
          data: {
            'searchQuery': searchQuery,
            'isChineseChar': _isChineseCharacter(searchQuery),
            'selectedCandidateId': exactMatches.first.id,
            'selectedCandidateCharacter': exactMatches.first.character,
            'allExactMatches': exactMatches
                .map((e) => {
                      'id': e.id,
                      'character': e.character,
                      'pageId': e.pageId,
                    })
                .toList(),
          },
        );
        await _selectCandidateCharacter(exactMatches.first);
      } else {
        // 没有精确匹配，设置占位符
        EditPageLogger.propertyPanelDebug(
          '[CHARACTER_MATCHING_DEBUG] 无精确匹配，设置占位符',
          tag: EditPageLoggingConfig.TAG_COLLECTION_PANEL,
          data: {
            'searchQuery': searchQuery,
            'isChineseChar': _isChineseCharacter(searchQuery),
            'candidateCount': entities.length,
            'allCandidates': entities
                .take(5)
                .map((e) => {
                      'id': e.id,
                      'character': e.character,
                      'pageId': e.pageId,
                    })
                .toList(),
            'reasonForPlaceholder': 'no_exact_match_found',
          },
        );
        await _setPlaceholderForCharacter(_selectedCharIndex, searchQuery);
      }
    } else {
      // 没有候选字符，设置占位符
      EditPageLogger.propertyPanelDebug(
        '[CHARACTER_MATCHING_DEBUG] 无候选字符，设置占位符',
        tag: EditPageLoggingConfig.TAG_COLLECTION_PANEL,
        data: {
          'searchQuery': searchQuery,
          'isChineseChar': _isChineseCharacter(searchQuery),
          'reasonForPlaceholder': 'no_candidates_found',
        },
      );
      await _setPlaceholderForCharacter(_selectedCharIndex, searchQuery);
    }
  }

  /// 为字符设置占位符
  Future<void> _setPlaceholderForCharacter(
      int charIndex, String character) async {
    try {
      final content = widget.element['content'] as Map<String, dynamic>;
      Map<String, dynamic> characterImages = {};

      if (content.containsKey('characterImages')) {
        characterImages = Map<String, dynamic>.from(
            content['characterImages'] as Map<String, dynamic>);
      }

      // 创建占位符图像信息
      final placeholderInfo = {
        'characterId': 'placeholder_${character}_$charIndex',
        'type': 'placeholder',
        'format': 'text',
        'drawingType': 'placeholder',
        'drawingFormat': 'text',
        'isPlaceholder': true,
        'originalCharacter': character,
        'transform': {
          'scale': 1.0,
          'rotation': 0.0,
          'color': content['fontColor'] ?? '#999999',
          'opacity': 0.5,
          'invert': false,
        },
      };

      characterImages['$charIndex'] = placeholderInfo;

      final updatedContent = Map<String, dynamic>.from(content);
      updatedContent['characterImages'] = characterImages;

      _updateProperty('content', updatedContent);

      EditPageLogger.propertyPanelDebug(
        '[CHARACTER_MATCHING_DEBUG] 占位符设置完成',
        tag: EditPageLoggingConfig.TAG_COLLECTION_PANEL,
        data: {
          'charIndex': charIndex,
          'character': character,
          'placeholderId': placeholderInfo['characterId'],
        },
      );
    } catch (e) {
      EditPageLogger.propertyPanelError(
        '设置占位符失败',
        tag: EditPageLoggingConfig.TAG_COLLECTION_PANEL,
        error: e,
        data: {
          'charIndex': charIndex,
          'character': character,
        },
      );
    }
  }

  /// 自动选择首个候选字符（仅当当前没有绑定时）
  void _autoSelectFirstCandidateIfNeeded(
      List<CharacterEntity> entities, String searchQuery) {
    final content = widget.element['content'] as Map<String, dynamic>;
    final characterImages =
        content['characterImages'] as Map<String, dynamic>? ?? {};
    final charIndex = _selectedCharIndex.toString();

    // 检查当前字符是否已有绑定
    if (characterImages.containsKey(charIndex)) {
      return;
    }

    // 查找匹配的候选字符
    final matchingEntities =
        entities.where((entity) => entity.character == searchQuery).toList();

    if (matchingEntities.isNotEmpty) {
      // 自动选择第一个匹配的候选
      _selectCandidateCharacter(matchingEntities.first);
    }
  }

  // Handle current character invert state toggle
  void _onCharacterInvertToggled(int charIndex, bool invertState) {
    // Use single character transform property update method
    _updateSingleCharacterTransformProperty(charIndex, 'invert', invertState);
  }

  // Toggle invert display
  void _onInvertDisplayToggled(bool value) {
    setState(() {
      _invertCandidateDisplay = value;
    });
  }

  // Handle text changes
  void _onTextChanged(String value) {
    final oldContent = widget.element['content'] as Map<String, dynamic>;
    final oldCharacters = oldContent['characters'] as String? ?? '';

    EditPageLogger.propertyPanelDebug(
      '[SEGMENTS_SYNC] 文本变更开始处理',
      tag: EditPageLoggingConfig.TAG_COLLECTION_PANEL,
      data: {
        'oldText': oldCharacters,
        'newText': value,
        'textChanged': oldCharacters != value,
      },
    );

    // If text actually changed
    if (oldCharacters != value) {
      // Get current characterImages
      Map<String, dynamic> characterImages = {};
      if (oldContent.containsKey('characterImages')) {
        characterImages = Map<String, dynamic>.from(
            oldContent['characterImages'] as Map<String, dynamic>);

        // 1. First convert to character-based format
        final characterBasedImages =
            _convertToCharacterBasedImages(oldCharacters, characterImages);

        // 2. Then convert back to index-based format using new string
        final newIndexBasedImages =
            _convertToIndexBasedImages(value, characterBasedImages);

        // 3. Update content with new segments
        final updatedContent = Map<String, dynamic>.from(oldContent);
        updatedContent['characters'] = value;
        updatedContent['characterImages'] = newIndexBasedImages;

        // 重要修复：重新生成 segments 以匹配新文本和当前匹配模式
        final wordMatchingPriority =
            updatedContent['wordMatchingPriority'] as bool? ??
                (_matchingMode == MatchingMode.wordMatching);
        updatedContent['segments'] =
            _generateSegments(value, wordMatchingPriority);

        EditPageLogger.propertyPanelDebug(
          '[SEGMENTS_SYNC] 文本更新时重新生成segments',
          tag: EditPageLoggingConfig.TAG_COLLECTION_PANEL,
          data: {
            'newText': value,
            'textLength': value.length,
            'wordMatchingPriority': wordMatchingPriority,
            'segmentsCount':
                (updatedContent['segments'] as List<dynamic>).length,
            'operation': 'text_update_remap_segments',
          },
        );

        // Update property
        widget.onElementPropertiesChanged({'content': updatedContent});

        // 重置候选字符状态并重新加载
        _resetCandidatesState();
        _loadCandidateCharacters();
      } else {
        // If no characterImages, still need to generate segments for new text
        final updatedContent = Map<String, dynamic>.from(oldContent);
        updatedContent['characters'] = value;

        // 重新生成 segments
        final wordMatchingPriority =
            updatedContent['wordMatchingPriority'] as bool? ??
                (_matchingMode == MatchingMode.wordMatching);
        updatedContent['segments'] =
            _generateSegments(value, wordMatchingPriority);

        EditPageLogger.propertyPanelDebug(
          '[SEGMENTS_SYNC] 文本更新时生成segments（无characterImages）',
          tag: EditPageLoggingConfig.TAG_COLLECTION_PANEL,
          data: {
            'newText': value,
            'wordMatchingPriority': wordMatchingPriority,
            'segmentsCount':
                (updatedContent['segments'] as List<dynamic>).length,
          },
        );

        // 使用完整的content更新而不是仅更新文本
        widget.onElementPropertiesChanged({'content': updatedContent});

        // 重置候选字符状态并重新加载
        _resetCandidatesState();
        _loadCandidateCharacters();
      }
    } else {
      // Text unchanged, call original method
      widget.onUpdateChars(value);
    }
  }

  // Select candidate character
  Future<void> _selectCandidateCharacter(CharacterEntity entity) async {
    try {
      final content = widget.element['content'] as Map<String, dynamic>;
      final characters = content['characters'] as String? ?? '';
      final currentChar =
          (_selectedCharIndex >= 0 && _selectedCharIndex < characters.length)
              ? characters[_selectedCharIndex]
              : '';

      EditPageLogger.propertyPanelDebug(
        '[SELECT_CANDIDATE_DEBUG] 开始选择候选字符',
        tag: EditPageLoggingConfig.TAG_COLLECTION_PANEL,
        data: {
          'selectedCharIndex': _selectedCharIndex,
          'currentChar': currentChar,
          'isChineseChar': _isChineseCharacter(currentChar),
          'candidateId': entity.id,
          'candidateCharacter': entity.character,
          'candidatePageId': entity.pageId,
          'matchingMode': _matchingMode.toString(),
        },
      );

      // Get character image format
      final characterImageService = ref.read(characterImageServiceProvider);
      final format = await characterImageService.getAvailableFormat(entity.id);

      if (format == null) {
        EditPageLogger.propertyPanelError(
          '候选字符格式获取失败',
          tag: EditPageLoggingConfig.TAG_COLLECTION_PANEL,
          data: {
            'candidateId': entity.id,
            'candidateCharacter': entity.character,
          },
        );
        return;
      }

      EditPageLogger.propertyPanelDebug(
        '[SELECT_CANDIDATE_DEBUG] 候选字符格式获取成功',
        tag: EditPageLoggingConfig.TAG_COLLECTION_PANEL,
        data: {
          'candidateId': entity.id,
          'format': format,
        },
      );

      // Update character image info
      await _updateCharacterImage(
        _selectedCharIndex,
        entity.id,
        format['type'] ?? 'square-binary',
        format['format'] ?? 'png-binary',
      );

      EditPageLogger.propertyPanelDebug(
        '[SELECT_CANDIDATE_DEBUG] 候选字符选择完成',
        tag: EditPageLoggingConfig.TAG_COLLECTION_PANEL,
        data: {
          'selectedCharIndex': _selectedCharIndex,
          'candidateId': entity.id,
          'candidateCharacter': entity.character,
        },
      );

      // Refresh UI
      setState(() {});
    } catch (e) {
      EditPageLogger.propertyPanelError(
        '选择候选字符失败',
        tag: EditPageLoggingConfig.TAG_COLLECTION_PANEL,
        error: e,
        data: {
          'selectedCharIndex': _selectedCharIndex,
          'entityId': entity.id,
          'operation': 'select_candidate_character',
        },
      );
    }
  }

  // Select character
  void _selectCharacter(int index) {
    final content = widget.element['content'] as Map<String, dynamic>;
    final characters = content['characters'] as String? ?? '';

    if (index >= 0 && index < characters.length) {
      setState(() {
        _selectedCharIndex = index;
      });

      _loadCandidateCharacters();
    }
  }

  // Update character image info
  Future<void> _updateCharacterImage(
      int index, String characterId, String type, String format,
      {bool isTemporary = false}) async {
    try {
      final content = widget.element['content'] as Map<String, dynamic>;
      Map<String, dynamic> characterImages;

      if (content.containsKey('characterImages')) {
        characterImages = Map<String, dynamic>.from(
            content['characterImages'] as Map<String, dynamic>);
      } else {
        characterImages = {};
      }

      // First check if image info already exists for this index
      final existingInfo = characterImages['$index'] as Map<String, dynamic>?;

      // If characterId is the same, preserve existing image info where possible
      if (existingInfo != null && existingInfo['characterId'] == characterId) {
        // Only update type and format, preserve drawingType and drawingFormat
        existingInfo['type'] = type;
        existingInfo['format'] = format;

        // Add isTemporary marker if temporary
        if (isTemporary) {
          existingInfo['isTemporary'] = true;
        } else if (existingInfo.containsKey('isTemporary')) {
          existingInfo.remove('isTemporary');
        }

        // Use updated existing info directly
        characterImages['$index'] = existingInfo;
      } else {
        // If doesn't exist or characterId is different, create new image info

        // Use thumbnails in property panel, but prefer square binary for drawing,
        // followed by square SVG outline
        final characterImageService = ref.read(characterImageServiceProvider);

        // Check available image formats
        bool hasSquareBinary = await characterImageService.hasCharacterImage(
            characterId, 'square-binary', 'png-binary');
        bool hasSquareOutline = await characterImageService.hasCharacterImage(
            characterId, 'square-outline', 'svg-outline');

        // Determine drawing format
        String drawingType;
        String drawingFormat;

        if (hasSquareBinary) {
          drawingType = 'square-binary';
          drawingFormat = 'png-binary';
        } else if (hasSquareOutline) {
          drawingType = 'square-outline';
          drawingFormat = 'svg-outline';
        } else {
          drawingType = type;
          drawingFormat = format;
        }

        // Create new character image info
        final Map<String, dynamic> imageInfo = {
          'characterId': characterId,
          'type': type,
          'format': format,
          'drawingType': drawingType,
          'drawingFormat': drawingFormat,
        };

        // Try to preserve existing transform property
        if (existingInfo != null && existingInfo.containsKey('transform')) {
          imageInfo['transform'] = Map<String, dynamic>.from(
              existingInfo['transform'] as Map<String, dynamic>);
        } else {
          // Otherwise create default transform property
          imageInfo['transform'] = {
            'scale': 1.0,
            'rotation': 0.0,
            'color': content['fontColor'] ?? '#000000',
            'opacity': 1.0,
            'invert': false,
          };
        }

        // Add isTemporary marker if temporary
        if (isTemporary) {
          imageInfo['isTemporary'] = true;
        }

        // Preserve other fields that might exist
        if (existingInfo != null) {
          for (final key in existingInfo.keys) {
            if (!imageInfo.containsKey(key) &&
                key != 'characterId' &&
                key != 'type' &&
                key != 'format' &&
                key != 'drawingType' &&
                key != 'drawingFormat' &&
                key != 'transform' &&
                key != 'isTemporary') {
              imageInfo[key] = existingInfo[key];
            }
          }
        }

        characterImages['$index'] = imageInfo;
      }

      final updatedContent = Map<String, dynamic>.from(content);
      updatedContent['characterImages'] = characterImages;

      _updateProperty('content', updatedContent);
    } catch (e) {
      EditPageLogger.propertyPanelError(
        '更新字符图像信息失败',
        tag: EditPageLoggingConfig.TAG_COLLECTION_PANEL,
        error: e,
        data: {
          'characterIndex': index,
          'characterId': characterId,
          'operation': 'update_character_image',
        },
      );
    }
  }

  // Update character images for new text
  Future<void> _updateCharacterImagesForNewText(String newText) async {
    try {
      // Get current content
      final content = Map<String, dynamic>.from(
          widget.element['content'] as Map<String, dynamic>? ?? {});

      // Check if each character already has image info
      bool hasUpdates = false;

      // Get existing character image info
      Map<String, dynamic> characterImages = {};
      if (content.containsKey('characterImages')) {
        characterImages = Map<String, dynamic>.from(
            content['characterImages'] as Map<String, dynamic>);

        // Clean up excess character image info
        final Set<String> validKeys = {};
        for (int i = 0; i < newText.length; i++) {
          validKeys.add('$i');
        }

        final List<String> keysToRemove = [];
        for (final key in characterImages.keys) {
          if (!validKeys.contains(key)) {
            keysToRemove.add(key);
          }
        }

        if (keysToRemove.isNotEmpty) {
          for (final key in keysToRemove) {
            characterImages.remove(key);
          }
          hasUpdates = true;
        }
      }

      // If there are updates, update element content
      if (hasUpdates) {
        final updatedContent = Map<String, dynamic>.from(content);
        updatedContent['characterImages'] = characterImages;
        _updateProperty('content', updatedContent);

        // Refresh UI
        setState(() {});
      }

      // Auto-update missing character images
      await _autoUpdateMissingCharacterImages(newText);
    } catch (e) {
      EditPageLogger.propertyPanelError(
        '更新新文本字符图像失败',
        tag: EditPageLoggingConfig.TAG_COLLECTION_PANEL,
        error: e,
        data: {
          'newText': newText,
          'textLength': newText.length,
          'operation': 'update_character_images_for_new_text',
        },
      );
    }
  }

  // 更新内容属性 - 完全重写版本，防止嵌套问题
  void _updateContentProperty(String key, dynamic value) {
    try {
      // 获取当前元素的内容
      final Map<String, dynamic> originalContent = Map<String, dynamic>.from(
          widget.element['content'] as Map<String, dynamic>? ?? {});

      // 创建一个全新的内容对象，而不是修改现有的
      final Map<String, dynamic> newContent = <String, dynamic>{};

      // 首先将原始内容扁平化，确保没有嵌套
      final flattenedOriginal = _deepFlattenContent(originalContent);

      // 复制所有原始属性（除了要更新的键和任何嵌套的 content）
      for (final entry in flattenedOriginal.entries) {
        if (entry.key != 'content' && entry.key != key) {
          newContent[entry.key] = entry.value;
        }
      }

      // 特殊处理：如果更新的是 content 属性本身
      if (key == 'content' && value is Map<String, dynamic>) {
        // 扁平化要设置的 content 值
        final flattenedValue = _deepFlattenContent(value);

        // 将扁平化后的属性合并到新内容中
        for (final entry in flattenedValue.entries) {
          if (entry.key != 'content') {
            // 确保不会再次引入 content 嵌套
            newContent[entry.key] = entry.value;
          }
        }

        EditPageLogger.propertyPanelDebug(
          '处理content更新：已扁平化并合并属性',
          tag: EditPageLoggingConfig.TAG_COLLECTION_PANEL,
          data: {
            'key': key,
            'operation': 'content_update_flatten',
          },
        );
      } else {
        // 常规属性更新
        newContent[key] = value;
      }

      // 最后检查确保没有 content 属性
      if (newContent.containsKey('content')) {
        newContent.remove('content');
        EditPageLogger.propertyPanelDebug(
          'Warning: Nested content removed in final processing',
          tag: EditPageLoggingConfig.TAG_COLLECTION_PANEL,
          data: {
            'key': key,
            'operation': 'remove_nested_content',
          },
        );
      }

      // 更新元素属性
      _updateProperty('content', newContent);

      EditPageLogger.propertyPanelDebug(
        '更新内容属性完成',
        tag: EditPageLoggingConfig.TAG_COLLECTION_PANEL,
        data: {
          'key': key,
          'propertyCount': newContent.length,
          'operation': 'update_content_property_complete',
        },
      );
    } catch (e) {
      EditPageLogger.propertyPanelError(
        '更新内容属性时出错',
        tag: EditPageLoggingConfig.TAG_COLLECTION_PANEL,
        error: e,
        data: {
          'key': key,
          'operation': 'update_content_property',
        },
      );
    }
  }

  // Update element property
  void _updateProperty(String key, dynamic value) {
    final updates = {key: value};
    widget.onElementPropertiesChanged(updates);
  }

  // Update single character transform property
  void _updateSingleCharacterTransformProperty(
      int charIndex, String propertyName, dynamic value) {
    final l10n = AppLocalizations.of(context);
    final content = Map<String, dynamic>.from(
        widget.element['content'] as Map<String, dynamic>);

    // Check if characterImages exists
    if (!content.containsKey('characterImages')) {
      // Create empty Map if no characterImages
      content['characterImages'] = <String, dynamic>{};
    }

    var characterImages = content['characterImages'] as Map<String, dynamic>;

    // Check if image info exists for current character
    if (!characterImages.containsKey('$charIndex')) {
      // Skip if no image info for current index
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.selectCharacterFirst),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    // Get character image info
    var charInfo = characterImages['$charIndex'] as Map<String, dynamic>;

    // Ensure transform property exists
    if (!charInfo.containsKey('transform')) {
      charInfo['transform'] = {
        'scale': 1.0,
        'rotation': 0.0,
        'color': content['fontColor'] ?? '#000000',
        'opacity': 1.0,
        'invert': false,
      };
    }

    // Update specified property
    var transform = charInfo['transform'] as Map<String, dynamic>;
    transform[propertyName] = value;

    // Update character image info
    characterImages['$charIndex'] = charInfo;

    // Update element content
    widget.onElementPropertiesChanged({'content': content});

    // Refresh UI
    setState(() {});

    // Show success message
    String propertyLabel;
    String valueLabel;

    switch (propertyName) {
      case 'invert':
        propertyLabel = l10n.colorInversion;
        valueLabel = value ? l10n.enabled : l10n.disabled;
        break;
      case 'scale':
        propertyLabel = l10n.scale;
        valueLabel = value.toString();
        break;
      case 'rotation':
        propertyLabel = l10n.rotation;
        valueLabel = value.toString();
        break;
      case 'opacity':
        propertyLabel = l10n.opacity;
        valueLabel = value.toString();
        break;
      default:
        propertyLabel = propertyName;
        valueLabel = value.toString();
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:
            Text('$_getCharacterLabel(charIndex), $propertyLabel: $valueLabel'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  /// 获取搜索查询字符串 - 根据匹配模式决定返回内容
  String _getSearchQuery() {
    final content = widget.element['content'] as Map<String, dynamic>;
    final characters = content['characters'] as String? ?? '';

    if (characters.isEmpty || _selectedCharIndex >= characters.length) {
      EditPageLogger.propertyPanelDebug(
        '[SEARCH_QUERY_DEBUG] 空查询条件',
        tag: EditPageLoggingConfig.TAG_COLLECTION_PANEL,
        data: {
          'charactersLength': characters.length,
          'selectedCharIndex': _selectedCharIndex,
          'reason':
              characters.isEmpty ? 'empty_characters' : 'index_out_of_bounds',
        },
      );
      return '';
    }

    final char = characters[_selectedCharIndex];

    if (_matchingMode == MatchingMode.wordMatching) {
      // 词匹配模式：基于 segments 获取对应的文本段
      final segments = content['segments'] as List<dynamic>? ?? [];

      // 找到包含当前选中字符的段
      int currentPos = 0;
      for (final segment in segments) {
        final segmentMap = segment as Map<String, dynamic>;
        final text = segmentMap['text'] as String? ?? '';
        final endPos = currentPos + text.length;

        if (_selectedCharIndex >= currentPos && _selectedCharIndex < endPos) {
          EditPageLogger.propertyPanelDebug(
            '[SEARCH_QUERY_DEBUG] 词匹配模式获取查询',
            tag: EditPageLoggingConfig.TAG_COLLECTION_PANEL,
            data: {
              'selectedCharIndex': _selectedCharIndex,
              'selectedChar': char,
              'segmentText': text,
              'segmentStart': currentPos,
              'segmentEnd': endPos,
              'isChineseChar': _isChineseCharacter(char),
            },
          );
          return text;
        }
        currentPos = endPos;
      }

      // 如果没有找到对应的段，返回单字符
      EditPageLogger.propertyPanelDebug(
        '[SEARCH_QUERY_DEBUG] 未找到对应的段，回退到单字符',
        tag: EditPageLoggingConfig.TAG_COLLECTION_PANEL,
        data: {
          'selectedCharIndex': _selectedCharIndex,
          'selectedChar': char,
          'charactersLength': characters.length,
          'segmentsCount': segments.length,
          'isChineseChar': _isChineseCharacter(char),
        },
      );
      return char;
    } else {
      // 字符匹配模式：返回单个字符
      EditPageLogger.propertyPanelDebug(
        '[SEARCH_QUERY_DEBUG] 字符匹配模式获取查询',
        tag: EditPageLoggingConfig.TAG_COLLECTION_PANEL,
        data: {
          'selectedCharIndex': _selectedCharIndex,
          'selectedChar': char,
          'isChineseChar': _isChineseCharacter(char),
        },
      );
      return char;
    }
  }

  /// 切换匹配模式
  void _onWordMatchingModeChanged(bool isWordMatching) {
    setState(() {
      _matchingMode = isWordMatching
          ? MatchingMode.wordMatching
          : MatchingMode.characterMatching;
    });

    // 更新 content 中的匹配模式和 segments
    final content = Map<String, dynamic>.from(
        widget.element['content'] as Map<String, dynamic>);
    final characters = content['characters'] as String? ?? '';

    // 更新匹配模式标志
    content['wordMatchingPriority'] = isWordMatching;

    // 根据匹配模式重新生成 segments
    if (characters.isNotEmpty) {
      content['segments'] = _generateSegments(characters, isWordMatching);
    }

    // 关键修复：切换到字符匹配模式时清空现有的 characterImages
    if (_matchingMode == MatchingMode.characterMatching) {
      // 清空所有现有的字符图像绑定，强制重新初始化
      content['characterImages'] = <String, dynamic>{};

      EditPageLogger.propertyPanelDebug(
        '[CHARACTER_MATCHING_DEBUG] 切换到字符匹配模式，清空现有绑定',
        tag: EditPageLoggingConfig.TAG_COLLECTION_PANEL,
        data: {
          'characters': characters,
          'charactersLength': characters.length,
          'operation': 'clear_character_images_on_mode_switch',
        },
      );
    }

    EditPageLogger.propertyPanelDebug(
      '[WORD_MATCHING_DEBUG] 匹配模式切换并更新content',
      tag: EditPageLoggingConfig.TAG_COLLECTION_PANEL,
      data: {
        'newMode': _matchingMode.toString(),
        'wordMatchingPriority': isWordMatching,
        'characters': characters,
        'segmentsCount': (content['segments'] as List<dynamic>?)?.length ?? 0,
        'characterImagesCleared':
            _matchingMode == MatchingMode.characterMatching,
      },
    );

    // 更新元素属性
    _updateProperty('content', content);

    // 如果切换到字符匹配模式，需要为所有字符预处理占位符
    if (_matchingMode == MatchingMode.characterMatching &&
        characters.isNotEmpty) {
      Future.microtask(() => _initializeCharacterMatchingMode(characters));
    }

    // 重新加载候选字符
    _loadCandidateCharacters();
  }

  /// 初始化字符匹配模式，为所有字符设置匹配项或占位符
  Future<void> _initializeCharacterMatchingMode(String characters) async {
    try {
      EditPageLogger.propertyPanelDebug(
        '[CHARACTER_MATCHING_DEBUG] 初始化字符匹配模式',
        tag: EditPageLoggingConfig.TAG_COLLECTION_PANEL,
        data: {
          'characters': characters,
          'charactersLength': characters.length,
        },
      );

      final characterService = ref.read(characterServiceProvider);
      final content = Map<String, dynamic>.from(
          widget.element['content'] as Map<String, dynamic>);

      Map<String, dynamic> characterImages = {};
      if (content.containsKey('characterImages')) {
        characterImages = Map<String, dynamic>.from(
            content['characterImages'] as Map<String, dynamic>);
      }

      bool hasUpdates = false;

      // 为每个字符位置处理匹配或设置占位符
      for (int i = 0; i < characters.length; i++) {
        final char = characters[i];
        final charIndex = i.toString();

        try {
          // 注意：在字符匹配模式初始化时，强制处理所有字符位置
          // 因为我们在模式切换时已经清空了 characterImages
          EditPageLogger.propertyPanelDebug(
            '[CHARACTER_MATCHING_DEBUG] 处理字符位置',
            tag: EditPageLoggingConfig.TAG_COLLECTION_PANEL,
            data: {
              'charIndex': i,
              'character': char,
              'hasExistingBinding': characterImages.containsKey(charIndex),
            },
          );

          // 跳过空白字符，直接设置占位符
          if (char.trim().isEmpty) {
            await _setPlaceholderForCharacter(i, char);
            hasUpdates = true;
            continue;
          }

          // 对所有字符进行搜索匹配（包括英文字符）
          EditPageLogger.propertyPanelDebug(
            '[CHARACTER_MATCHING_DEBUG] 开始搜索字符',
            tag: EditPageLoggingConfig.TAG_COLLECTION_PANEL,
            data: {
              'charIndex': i,
              'character': char,
              'isChineseChar': _isChineseCharacter(char),
              'isEnglishChar': RegExp(r'^[a-zA-Z]$').hasMatch(char),
            },
          );

          // 搜索匹配的字符
          final matchingCharacters =
              await characterService.searchCharactersWithMode(
            char,
            wordMatchingPriority: false,
          );

          EditPageLogger.propertyPanelDebug(
            '[CHARACTER_MATCHING_DEBUG] 搜索结果详情',
            tag: EditPageLoggingConfig.TAG_COLLECTION_PANEL,
            data: {
              'searchQuery': char,
              'totalResults': matchingCharacters.length,
              'resultIds': matchingCharacters.map((c) => c.id).take(5).toList(),
              'resultCharacters':
                  matchingCharacters.map((c) => c.character).take(5).toList(),
            },
          );

          if (matchingCharacters.isNotEmpty) {
            // 转换为 CharacterEntity
            final futures = matchingCharacters.map((viewModel) async {
              return await characterService.getCharacterDetails(viewModel.id);
            }).toList();

            final results = await Future.wait(futures);
            final entities = results.whereType<CharacterEntity>().toList();

            EditPageLogger.propertyPanelDebug(
              '[CHARACTER_MATCHING_DEBUG] 实体详情',
              tag: EditPageLoggingConfig.TAG_COLLECTION_PANEL,
              data: {
                'searchQuery': char,
                'entityCount': entities.length,
                'entityIds': entities.map((e) => e.id).take(5).toList(),
                'entityCharacters':
                    entities.map((e) => e.character).take(5).toList(),
                'entityDetails': entities
                    .take(3)
                    .map((e) => {
                          'id': e.id,
                          'character': e.character,
                          'pageId': e.pageId,
                        })
                    .toList(),
              },
            );

            // 查找精确匹配
            final exactMatches =
                entities.where((entity) => entity.character == char).toList();

            EditPageLogger.propertyPanelDebug(
              '[CHARACTER_MATCHING_DEBUG] 精确匹配检查结果',
              tag: EditPageLoggingConfig.TAG_COLLECTION_PANEL,
              data: {
                'charIndex': i,
                'searchChar': char,
                'totalEntities': entities.length,
                'exactMatches': exactMatches.length,
                'exactMatchCharacters':
                    exactMatches.map((e) => e.character).toList(),
                'exactMatchIds': exactMatches.map((e) => e.id).toList(),
                'exactMatchDetails': exactMatches
                    .take(3)
                    .map((e) => {
                          'id': e.id,
                          'character': e.character,
                          'pageId': e.pageId,
                        })
                    .toList(),
              },
            );

            if (exactMatches.isNotEmpty) {
              // 非英文字符自动绑定第一个精确匹配
              EditPageLogger.propertyPanelDebug(
                '[CHARACTER_MATCHING_DEBUG] 找到精确匹配，自动绑定',
                tag: EditPageLoggingConfig.TAG_COLLECTION_PANEL,
                data: {
                  'charIndex': i,
                  'character': char,
                  'matchedEntity': exactMatches.first.character,
                  'matchedId': exactMatches.first.id,
                },
              );

              // 临时设置选中索引以便更新正确的位置
              final originalSelectedIndex = _selectedCharIndex;
              _selectedCharIndex = i;
              await _selectCandidateCharacter(exactMatches.first);
              _selectedCharIndex = originalSelectedIndex;
              hasUpdates = true;
            } else {
              // 没有精确匹配，设置占位符
              await _setPlaceholderForCharacter(i, char);
              hasUpdates = true;
            }
          } else {
            // 没有候选字符，设置占位符
            await _setPlaceholderForCharacter(i, char);
            hasUpdates = true;
          }
        } catch (e) {
          EditPageLogger.propertyPanelError(
            '处理单个字符失败，强制设置占位符',
            tag: EditPageLoggingConfig.TAG_COLLECTION_PANEL,
            error: e,
            data: {
              'charIndex': i,
              'character': char,
            },
          );

          // 异常情况下强制设置占位符
          try {
            await _setPlaceholderForCharacter(i, char);
            hasUpdates = true;
          } catch (placeholderError) {
            EditPageLogger.propertyPanelError(
              '设置占位符也失败了',
              tag: EditPageLoggingConfig.TAG_COLLECTION_PANEL,
              error: placeholderError,
              data: {
                'charIndex': i,
                'character': char,
              },
            );
          }
        }
      }

      if (hasUpdates) {
        // 刷新UI
        setState(() {});

        // 验证所有字符位置都已处理
        final updatedContent =
            widget.element['content'] as Map<String, dynamic>;
        final finalCharacterImages =
            updatedContent['characterImages'] as Map<String, dynamic>? ?? {};

        EditPageLogger.propertyPanelDebug(
          '[CHARACTER_MATCHING_DEBUG] 字符匹配模式初始化完成',
          tag: EditPageLoggingConfig.TAG_COLLECTION_PANEL,
          data: {
            'charactersLength': characters.length,
            'hasUpdates': hasUpdates,
            'finalCharacterImagesKeys': finalCharacterImages.keys.toList(),
            'missingIndices': List.generate(characters.length, (index) => index)
                .where((index) =>
                    !finalCharacterImages.containsKey(index.toString()))
                .toList(),
          },
        );
      }
    } catch (e) {
      EditPageLogger.propertyPanelError(
        '初始化字符匹配模式失败',
        tag: EditPageLoggingConfig.TAG_COLLECTION_PANEL,
        error: e,
        data: {
          'characters': characters,
        },
      );
    }
  }

  /// 根据匹配模式生成 segments
  List<Map<String, dynamic>> _generateSegments(String text, bool wordMatching) {
    final segments = <Map<String, dynamic>>[];

    if (wordMatching) {
      // 词匹配模式：智能分词
      // 简单分词逻辑：按空格分割，但可以扩展为更智能的分词
      final parts = text.split(' ');
      int startIndex = 0;

      for (int i = 0; i < parts.length; i++) {
        final part = parts[i];

        if (part.isNotEmpty) {
          segments.add({
            'text': part,
            'startIndex': startIndex,
            'length': part.length,
          });
          startIndex += part.length;
        }

        // 添加空格分隔符（除了最后一个部分）
        if (i < parts.length - 1) {
          segments.add({
            'text': ' ',
            'startIndex': startIndex,
            'length': 1,
          });
          startIndex += 1;
        }
      }
    } else {
      // 字符匹配模式：每个字符一个段
      for (int i = 0; i < text.length; i++) {
        segments.add({
          'text': text[i],
          'startIndex': i,
          'length': 1,
        });
      }
    }

    EditPageLogger.propertyPanelDebug(
      '[WORD_MATCHING_DEBUG] 生成新的segments',
      tag: EditPageLoggingConfig.TAG_COLLECTION_PANEL,
      data: {
        'text': text,
        'wordMatching': wordMatching,
        'segmentsCount': segments.length,
        'segments': segments,
      },
    );

    return segments;
  }

  /// 重置候选字符状态
  void _resetCandidatesState() {
    setState(() {
      _selectedCharIndex = 0;
      _candidateCharacters.clear();
      _isLoadingCharacters = false;
    });
  }

  /// 检查是否为中文字符
  bool _isChineseCharacter(String char) {
    if (char.isEmpty) return false;
    final int code = char.codeUnitAt(0);
    return code >= 0x4e00 && code <= 0x9fff;
  }
}
