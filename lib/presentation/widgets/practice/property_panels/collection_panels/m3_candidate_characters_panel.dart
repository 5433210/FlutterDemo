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
  final Function(CharacterEntity) onCharacterSelected;
  final Widget? additionalContent; // 新增：用於放置額外內容（如字符變換控制器）

  const M3CandidateCharactersPanel({
    Key? key,
    required this.element,
    required this.selectedCharIndex,
    required this.candidateCharacters,
    required this.isLoading,
    required this.onCharacterSelected,
    this.additionalContent, // 新增參數
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

    // Character inversion functionality removed

    // Filter matching characters
    final matchingCharacters = candidateCharacters
        .where((entity) => entity.character == selectedChar)
        .toList();

    // Show loading state
    if (isLoading && candidateCharacters.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withAlpha(76), // 0.3 透明度
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
                l10n.searching,
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
          color: colorScheme.surfaceContainerHighest.withAlpha(76), // 0.3 透明度
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(color: colorScheme.outline),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Text(
                l10n.noCharactersFound,
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(height: 8),
            if (selectedChar.isNotEmpty)
              Text(
                '${l10n.selectedCharacter}: "$selectedChar"',
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant.withAlpha(179), // 0.7 透明度
                ),
              ),
            if (candidateCharacters.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(
                  '${l10n.availableCharacters}: ${candidateCharacters.map((e) => e.character).join(", ")}',
                  style: textTheme.bodySmall?.copyWith(
                    color:
                        colorScheme.onSurfaceVariant.withAlpha(179), // 0.7 透明度
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
        color: colorScheme.surfaceContainerHighest.withAlpha(76), // 0.3 透明度
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: colorScheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

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
                );
              },
            ),
          ),
          
          // 添加額外內容（如字符變換控制器）
          if (additionalContent != null) ...[
            const SizedBox(height: 16.0),
            additionalContent!,
          ],
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
                          color: colorScheme.shadow.withAlpha(76), // 0.3 透明度
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

                          // Character inversion removed - show image directly
                          return Center(
                            child: ClipRRect(
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

                  // Inversion indicator removed
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // Character inversion check function removed
}
