import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../application/providers/service_providers.dart';
import '../../../../application/services/services.dart';
import '../../../../domain/models/character/character_entity.dart';
import '../../../../l10n/app_localizations.dart';
import '../practice_edit_controller.dart';
import 'collection_panels/m3_content_settings_panel.dart';
import 'collection_panels/m3_geometry_properties_panel.dart';
import 'collection_panels/m3_visual_properties_panel.dart';
import 'm3_element_common_property_panel.dart';
import 'm3_layer_info_panel.dart';

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

  // Last input text
  String _lastInputText = '';

  // Controls candidate character color inversion
  bool _invertCandidateDisplay = false;

  @override
  Widget build(BuildContext context) {
    final layerId = widget.element['layerId'] as String?;
    final l10n = AppLocalizations.of(context);

    // Get layer information
    Map<String, dynamic>? layer;
    if (layerId != null) {
      layer = widget.controller.state.getLayerById(layerId);
    }

    return ListView(
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
        ),

        // Visual properties section
        M3VisualPropertiesPanel(
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
          onTextChanged: _onTextChanged,
          onCharacterSelected: _selectCharacter,
          onCandidateCharacterSelected: _selectCandidateCharacter,
          onInvertDisplayToggled: _onInvertDisplayToggled,
          onCharacterInvertToggled: _onCharacterInvertToggled,
          onContentPropertyChanged: _updateContentProperty,
          onClearImageCache: _clearImageCache,
        ),
      ],
    );
  }

  @override
  void didUpdateWidget(M3CollectionPropertyPanel oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.element != widget.element) {
      // Update text controller
      final content = widget.element['content'] as Map<String, dynamic>;
      final characters = content['characters'] as String? ?? '';
      final oldContent = oldWidget.element['content'] as Map<String, dynamic>;
      final oldCharacters = oldContent['characters'] as String? ?? '';

      // Only update controller when text actually changes to avoid cursor position reset
      if (_textController.text != characters) {
        _textController.text = characters;
      }

      // Check if characterImages should be preserved
      final shouldPreserveImages = oldContent.containsKey('characterImages') &&
          content.containsKey('characterImages') &&
          oldCharacters == characters;

      // Update candidate characters
      if (oldCharacters != characters) {
        _lastInputText = characters;
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

  @override
  void initState() {
    super.initState();

    // Initialize text controller
    final content = widget.element['content'] as Map<String, dynamic>;
    final characters = content['characters'] as String? ?? '';
    _textController.text = characters;

    // Use addPostFrameCallback to defer state updates to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Load candidate characters
      _loadCandidateCharacters();

      // Auto-update missing character images
      if (characters.isNotEmpty) {
        _autoUpdateMissingCharacterImages(characters);
      }
    });
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

        // Search for matching candidate characters
        final matchingCharacters =
            await characterService.searchCharacters(char);

        // Skip if no matching candidates found
        if (matchingCharacters.isEmpty) continue;

        // Get detailed info of the first matching character
        final characterEntity = await characterService
            .getCharacterDetails(matchingCharacters.first.id);

        // Skip if cannot get details
        if (characterEntity == null) continue;

        // Get character image format
        final format =
            await characterImageService.getAvailableFormat(characterEntity.id);

        // Skip if cannot get format
        if (format == null) continue;

        // Check available image formats
        final hasSquareBinary = await characterImageService.hasCharacterImage(
            characterEntity.id, 'square-binary', 'png-binary');
        final hasSquareOutline = await characterImageService.hasCharacterImage(
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

        debugPrint('Auto-updated missing character images');
      }
    } catch (e) {
      debugPrint('Failed to auto-update missing character images: $e');
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
          debugPrint(
              'Cleaned up invalid keys in top-level characterImages: $keysToRemove');
        }
        if (hasNestedStructure) {
          debugPrint('Cleaned up nested characterImages structure');
        }
      }
    } catch (e) {
      debugPrint('Failed to clean up character image info: $e');
    }
  }

  // Clear image cache
  void _clearImageCache() {
    Future.delayed(const Duration(milliseconds: 100), () async {
      try {
        // Clear cache
        final characterImageService = ref.read(characterImageServiceProvider);
        await characterImageService.clearAllImageCache();

        // Ensure component is still mounted
        if (!mounted) return;

        // Show success message
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.collectionPropertyPanelCacheCleared),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );

        // Refresh UI
        setState(() {});
      } catch (e) {
        // Ensure component is still mounted
        if (!mounted) return;

        // Show error message
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('${l10n.collectionPropertyPanelCacheClearFailed}: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    });
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

  // Get character display label
  String _getCharacterLabel(int charIndex) {
    final content = widget.element['content'] as Map<String, dynamic>;
    final characters = content['characters'] as String? ?? '';

    if (charIndex >= 0 && charIndex < characters.length) {
      return '"${characters[charIndex]}"';
    }

    return AppLocalizations.of(context).collectionPropertyPanelUnknown;
  }

  // Load candidate characters
  Future<void> _loadCandidateCharacters() async {
    try {
      setState(() {
        _isLoadingCharacters = true;
      });

      // Use CharacterService to get all characters
      final characterService = ref.read(characterServiceProvider);

      // Get currently selected character
      final content = widget.element['content'] as Map<String, dynamic>;
      final characters = content['characters'] as String? ?? '';

      if (characters.isEmpty) {
        setState(() {
          _candidateCharacters = [];
          _isLoadingCharacters = false;
        });
        return;
      }

      final selectedChar = _selectedCharIndex < characters.length
          ? characters[_selectedCharIndex]
          : '';

      if (selectedChar.isEmpty) {
        setState(() {
          _candidateCharacters = [];
          _isLoadingCharacters = false;
        });
        return;
      }

      // Search character library for matching characters
      final matchingCharacters =
          await characterService.searchCharacters(selectedChar);

      if (matchingCharacters.isEmpty) {
        setState(() {
          _candidateCharacters = [];
          _isLoadingCharacters = false;
        });
        return;
      }

      // Convert to CharacterEntity list
      final futures = matchingCharacters.map((viewModel) async {
        return await characterService.getCharacterDetails(viewModel.id);
      }).toList();

      final results = await Future.wait(futures);
      final entities = results.whereType<CharacterEntity>().toList();

      setState(() {
        _candidateCharacters = entities;
        _isLoadingCharacters = false;
      });

      // Auto-select first candidate as default
      if (entities.isNotEmpty) {
        // Find candidates matching the selected character
        final matchingEntities = entities
            .where((entity) => entity.character == selectedChar)
            .toList();

        if (matchingEntities.isNotEmpty) {
          // Check if this candidate is already selected
          final characterImages =
              content['characterImages'] as Map<String, dynamic>? ?? {};
          final imageInfo =
              characterImages['$_selectedCharIndex'] as Map<String, dynamic>?;

          if (imageInfo == null ||
              imageInfo['characterId'] != matchingEntities.first.id) {
            // If not already selected, select it
            _selectCandidateCharacter(matchingEntities.first);
          }
        }
      }
    } catch (e) {
      setState(() {
        _candidateCharacters = [];
        _isLoadingCharacters = false;
      });
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

        // 3. Update content
        final updatedContent = Map<String, dynamic>.from(oldContent);
        updatedContent['characters'] = value;
        updatedContent['characterImages'] = newIndexBasedImages;

        // Update property
        widget.onElementPropertiesChanged({'content': updatedContent});

        // Log
        debugPrint('Text updated and character image info remapped');
      } else {
        // If no characterImages, update text directly
        widget.onUpdateChars(value);
      }
    } else {
      // Text unchanged, call original method
      widget.onUpdateChars(value);
    }
  }

  // Select candidate character
  Future<void> _selectCandidateCharacter(CharacterEntity entity) async {
    try {
      // Get character image format
      final characterImageService = ref.read(characterImageServiceProvider);
      final format = await characterImageService.getAvailableFormat(entity.id);

      if (format == null) {
        return;
      }

      // Update character image info
      await _updateCharacterImage(
        _selectedCharIndex,
        entity.id,
        format['type'] ?? 'square-binary',
        format['format'] ?? 'png-binary',
      );

      // Refresh UI
      setState(() {});
    } catch (e) {
      debugPrint('Failed to select candidate character: $e');
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
      debugPrint('Failed to update character image info: $e');
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
      debugPrint('Failed to update character image info: $e');
    }
  }

  // Update content property
  void _updateContentProperty(String key, dynamic value) {
    final content = Map<String, dynamic>.from(
        widget.element['content'] as Map<String, dynamic>? ?? {});
    content[key] = value;
    _updateProperty('content', content);
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
          content: Text(l10n.collectionPropertyPanelSelectCharacterFirst),
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
        propertyLabel = l10n.collectionPropertyPanelColorInversion;
        valueLabel = value
            ? l10n.collectionPropertyPanelEnabled
            : l10n.collectionPropertyPanelDisabled;
        break;
      case 'scale':
        propertyLabel = l10n.collectionPropertyPanelScale;
        valueLabel = value.toString();
        break;
      case 'rotation':
        propertyLabel = l10n.collectionPropertyPanelRotation;
        valueLabel = value.toString();
        break;
      case 'opacity':
        propertyLabel = l10n.collectionPropertyPanelOpacity;
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
}
