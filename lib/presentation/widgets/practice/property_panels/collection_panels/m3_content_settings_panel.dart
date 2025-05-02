import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../domain/models/character/character_entity.dart';
import '../../../../../l10n/app_localizations.dart';
import 'm3_candidate_characters_panel.dart';
import 'm3_character_input_field.dart';
import 'm3_character_preview_panel.dart';
import 'm3_text_format_panel.dart';

/// Material 3 content settings panel for collection elements
class M3ContentSettingsPanel extends ConsumerWidget {
  final Map<String, dynamic> element;
  final int selectedCharIndex;
  final List<CharacterEntity> candidateCharacters;
  final bool isLoading;
  final bool invertDisplay;
  final Function(String) onTextChanged;
  final Function(int) onCharacterSelected;
  final Function(CharacterEntity) onCandidateCharacterSelected;
  final Function(bool) onInvertDisplayToggled;
  final Function(String, dynamic) onContentPropertyChanged;
  final Function(int, bool) onCharacterInvertToggled;
  final VoidCallback onClearImageCache;

  const M3ContentSettingsPanel({
    Key? key,
    required this.element,
    required this.selectedCharIndex,
    required this.candidateCharacters,
    required this.isLoading,
    required this.invertDisplay,
    required this.onTextChanged,
    required this.onCharacterSelected,
    required this.onCandidateCharacterSelected,
    required this.onInvertDisplayToggled,
    required this.onContentPropertyChanged,
    required this.onCharacterInvertToggled,
    required this.onClearImageCache,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final content = element['content'] as Map<String, dynamic>;
    final characters = content['characters'] as String? ?? '';

    return ExpansionTile(
      title: Text(
        l10n.contentSettings,
        style: textTheme.titleMedium?.copyWith(
          color: colorScheme.onSurface,
        ),
      ),
      initiallyExpanded: true,
      collapsedIconColor: colorScheme.onSurfaceVariant,
      iconColor: colorScheme.primary,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Character content
              Text(
                '${l10n.collectionPropertyPanelCharacter}:',
                style: textTheme.titleSmall?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8.0),
              M3CharacterInputField(
                initialText: characters,
                selectedCharIndex: selectedCharIndex,
                onTextChanged: onTextChanged,
                onSelectedCharIndexChanged: onCharacterSelected,
              ),

              const SizedBox(height: 16.0),

              // Character preview
              Text(
                '${l10n.characterCollectionPreviewTab}:',
                style: textTheme.titleSmall?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8.0),
              M3CharacterPreviewPanel(
                element: element,
                selectedCharIndex: selectedCharIndex,
                onCharacterSelected: onCharacterSelected,
              ),

              const SizedBox(height: 16.0),

              // Candidate characters
              Text(
                '${l10n.collectionPropertyPanelCandidateCharacters}:',
                style: textTheme.titleSmall?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8.0),
              M3CandidateCharactersPanel(
                element: element,
                selectedCharIndex: selectedCharIndex,
                candidateCharacters: candidateCharacters,
                isLoading: isLoading,
                invertDisplay: invertDisplay,
                onCharacterSelected: onCandidateCharacterSelected,
                onInvertDisplayToggled: onInvertDisplayToggled,
                onCharacterInvertToggled: onCharacterInvertToggled,
              ),

              const SizedBox(height: 16.0),

              // Clear image cache button
              FilledButton.tonal(
                onPressed: onClearImageCache,
                style: FilledButton.styleFrom(
                  backgroundColor: colorScheme.errorContainer,
                  foregroundColor: colorScheme.onErrorContainer,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.cleaning_services,
                      size: 20,
                      color: colorScheme.onErrorContainer,
                    ),
                    const SizedBox(width: 8),
                    Text(l10n.clearImageCache),
                  ],
                ),
              ),

              const SizedBox(height: 16.0),

              // Text format settings
              Text(
                '${l10n.collectionPropertyPanelTextSettings}:',
                style: textTheme.titleSmall?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8.0),
              M3TextFormatPanel(
                content: content,
                onContentPropertyChanged: onContentPropertyChanged,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
