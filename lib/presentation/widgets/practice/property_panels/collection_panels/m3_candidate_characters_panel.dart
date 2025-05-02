import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../application/providers/service_providers.dart';
import '../../../../../domain/models/character/character_entity.dart';
import '../../../../../l10n/app_localizations.dart';
import 'm3_collection_color_utils.dart';

/// Material 3 candidate characters panel
class M3CandidateCharactersPanel extends ConsumerWidget {
  final Map<String, dynamic> element;
  final int selectedCharIndex;
  final List<CharacterEntity> candidateCharacters;
  final bool isLoading;
  final bool invertDisplay;
  final Function(CharacterEntity) onCharacterSelected;
  final Function(bool) onInvertDisplayToggled;
  final Function(int, bool) onCharacterInvertToggled;

  const M3CandidateCharactersPanel({
    Key? key,
    required this.element,
    required this.selectedCharIndex,
    required this.candidateCharacters,
    required this.isLoading,
    required this.invertDisplay,
    required this.onCharacterSelected,
    required this.onInvertDisplayToggled,
    required this.onCharacterInvertToggled,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final content = element['content'] as Map<String, dynamic>;
    final characters = content['characters'] as String? ?? '';
    final selectedChar = selectedCharIndex < characters.length
        ? characters[selectedCharIndex]
        : '';

    // Check if the current character is inverted
    final isCurrentCharInverted =
        _isCharacterInverted(content, selectedCharIndex);

    // Filter matching characters
    final matchingCharacters = candidateCharacters
        .where((entity) => entity.character == selectedChar)
        .toList();

    // Show loading state
    if (isLoading && candidateCharacters.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(color: colorScheme.outline),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: colorScheme.primary),
              const SizedBox(height: 16),
              Text(
                l10n.collectionPropertyPanelSearchInProgress,
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // No matching characters found
    if (matchingCharacters.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(color: colorScheme.outline),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Text(
                l10n.collectionPropertyPanelNoCharactersFound,
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(height: 8),
            if (selectedChar.isNotEmpty)
              Text(
                '${l10n.collectionPropertyPanelSelectedCharacter}: "$selectedChar"',
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant.withOpacity(0.7),
                ),
              ),
            if (candidateCharacters.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(
                  '${l10n.collectionPropertyPanelAvailableCharacters}: ${candidateCharacters.map((e) => e.character).join(", ")}',
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant.withOpacity(0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      );
    }

    // Character candidates display
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: colorScheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.collectionPropertyPanelCandidateCharacters,
            style: textTheme.titleSmall?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12.0),

          // Display control buttons
          Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              alignment: WrapAlignment.start,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  '${l10n.imagePropertyPanelDisplay}:',
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),

                // Global inversion button
                FilterChip(
                  label: Text(l10n.collectionPropertyPanelGlobalInversion),
                  selected: invertDisplay,
                  showCheckmark: true,
                  checkmarkColor: colorScheme.onPrimaryContainer,
                  backgroundColor: colorScheme.surfaceContainerHighest,
                  selectedColor: colorScheme.primaryContainer,
                  labelStyle: TextStyle(
                    color: invertDisplay
                        ? colorScheme.onPrimaryContainer
                        : colorScheme.onSurfaceVariant,
                  ),
                  avatar: Icon(
                    Icons.invert_colors,
                    size: 18.0,
                    color: invertDisplay
                        ? colorScheme.onPrimaryContainer
                        : colorScheme.onSurfaceVariant,
                  ),
                  onSelected: (value) {
                    onInvertDisplayToggled(value);
                  },
                ),

                // Current character inversion button
                FilterChip(
                  label: Text(l10n.collectionPropertyPanelCurrentCharInversion),
                  selected: isCurrentCharInverted,
                  showCheckmark: true,
                  checkmarkColor: colorScheme.onSecondaryContainer,
                  backgroundColor: colorScheme.surfaceContainerHighest,
                  selectedColor: colorScheme.secondaryContainer,
                  labelStyle: TextStyle(
                    color: isCurrentCharInverted
                        ? colorScheme.onSecondaryContainer
                        : colorScheme.onSurfaceVariant,
                  ),
                  avatar: Icon(
                    Icons.format_color_reset,
                    size: 18.0,
                    color: isCurrentCharInverted
                        ? colorScheme.onSecondaryContainer
                        : colorScheme.onSurfaceVariant,
                  ),
                  onSelected: (value) {
                    onCharacterInvertToggled(selectedCharIndex, value);
                  },
                ),
              ],
            ),
          ),

          // Character grid
          Wrap(
            spacing: 8.0,
            runSpacing: 8.0,
            children: List.generate(
              matchingCharacters.length,
              (index) {
                final entity = matchingCharacters[index];

                // Check if this candidate is already selected
                final characterImages =
                    content['characterImages'] as Map<String, dynamic>? ?? {};
                final imageInfo = characterImages['$selectedCharIndex']
                    as Map<String, dynamic>?;
                final isSelected =
                    imageInfo != null && imageInfo['characterId'] == entity.id;

                return _buildCandidateCharacterItem(
                  context,
                  ref,
                  entity,
                  isSelected,
                  index,
                  isCurrentCharInverted,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Build a candidate character item
  Widget _buildCandidateCharacterItem(
    BuildContext context,
    WidgetRef ref,
    CharacterEntity entity,
    bool isSelected,
    int index,
    bool isCurrentCharInverted,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return FutureBuilder<Map<String, String>?>(
      future:
          ref.read(characterImageServiceProvider).getAvailableFormat(entity.id),
      builder: (context, snapshot) {
        return Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          child: InkWell(
            onTap: () => onCharacterSelected(entity),
            borderRadius: BorderRadius.circular(8),
            child: Ink(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: isSelected
                    ? colorScheme.primaryContainer
                    : colorScheme.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected
                      ? colorScheme.primary
                      : colorScheme.outlineVariant,
                  width: isSelected ? 2.0 : 1.0,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: colorScheme.shadow.withOpacity(0.3),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        )
                      ]
                    : null,
              ),
              child: Stack(
                children: [
                  if (snapshot.connectionState == ConnectionState.waiting)
                    Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: isSelected
                              ? colorScheme.primary
                              : colorScheme.secondary,
                        ),
                      ),
                    )
                  else if (snapshot.hasData && snapshot.data != null)
                    FutureBuilder<Uint8List?>(
                      future: ref
                          .read(characterImageServiceProvider)
                          .getCharacterImage(
                            entity.id,
                            snapshot.data!['type']!,
                            snapshot.data!['format']!,
                          ),
                      builder: (context, imageSnapshot) {
                        if (imageSnapshot.connectionState ==
                            ConnectionState.waiting) {
                          return Center(
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: isSelected
                                    ? colorScheme.primary
                                    : colorScheme.secondary,
                              ),
                            ),
                          );
                        } else if (imageSnapshot.hasData &&
                            imageSnapshot.data != null) {
                          // Apply inversion if needed
                          final imageWidget = Image.memory(
                            imageSnapshot.data!,
                            fit: BoxFit.contain,
                          );

                          // Determine if inversion should be applied
                          final shouldInvert =
                              invertDisplay || isCurrentCharInverted;

                          return Center(
                            child: shouldInvert
                                ? Stack(
                                    children: [
                                      ColorFiltered(
                                        colorFilter: const ColorFilter.matrix([
                                          -1, 0, 0, 0, 255, // Red channel
                                          0, -1, 0, 0, 255, // Green channel
                                          0, 0, -1, 0, 255, // Blue channel
                                          0, 0, 0, 1, 0, // Alpha channel
                                        ]),
                                        child: Stack(
                                          children: [
                                            // Convert transparent to white first (white background)
                                            Container(
                                              color: Colors.white,
                                              width: double.infinity,
                                              height: double.infinity,
                                            ),
                                            ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                              child: imageWidget,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  )
                                : ClipRRect(
                                    borderRadius: BorderRadius.circular(6),
                                    child: imageWidget,
                                  ),
                          );
                        } else {
                          return Center(
                            child: Text(
                              '${entity.character}${CollectionColorUtils.getSubscript(index + 1)}',
                              style: textTheme.headlineSmall,
                            ),
                          );
                        }
                      },
                    )
                  else
                    Center(
                      child: Text(
                        '${entity.character}${CollectionColorUtils.getSubscript(index + 1)}',
                        style: textTheme.headlineSmall,
                      ),
                    ),

                  // Selection indicator
                  if (isSelected)
                    Positioned(
                      right: 4,
                      bottom: 4,
                      child: Container(
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer,
                          shape: BoxShape.circle,
                          border:
                              Border.all(color: colorScheme.primary, width: 1),
                        ),
                        padding: const EdgeInsets.all(2),
                        child: Icon(
                          Icons.check,
                          size: 14,
                          color: colorScheme.primary,
                        ),
                      ),
                    ),

                  // Inversion indicator
                  if (isCurrentCharInverted)
                    Positioned(
                      right: isSelected ? 24 : 4,
                      bottom: 4,
                      child: Container(
                        decoration: BoxDecoration(
                          color: colorScheme.secondaryContainer,
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: colorScheme.secondary, width: 1),
                        ),
                        padding: const EdgeInsets.all(2),
                        child: Icon(
                          Icons.format_color_reset,
                          size: 14,
                          color: colorScheme.secondary,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Check if a character has the invert transform property
  bool _isCharacterInverted(Map<String, dynamic> content, int charIndex) {
    if (!content.containsKey('characterImages')) {
      return false;
    }

    final characterImages = content['characterImages'] as Map<String, dynamic>?;
    if (characterImages == null) {
      return false;
    }

    final charImageInfo =
        characterImages['$charIndex'] as Map<String, dynamic>?;
    if (charImageInfo == null) {
      return false;
    }

    // Check for transform property
    if (!charImageInfo.containsKey('transform')) {
      return false;
    }

    final transform = charImageInfo['transform'] as Map<String, dynamic>?;
    if (transform == null) {
      return false;
    }

    // Get invert state
    return transform['invert'] == true;
  }
}
