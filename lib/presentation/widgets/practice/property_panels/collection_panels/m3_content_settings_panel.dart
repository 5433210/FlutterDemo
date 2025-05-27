import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../domain/models/character/character_entity.dart';
import '../../../../../l10n/app_localizations.dart';
import '../m3_panel_styles.dart';
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
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    final content = element['content'] as Map<String, dynamic>;
    final characters = content['characters'] as String? ?? '';
    return M3PanelStyles.buildPersistentPanelCard(
      context: context,
      panelId: 'collection_content_settings',
      title: l10n.contentSettings,
      defaultExpanded: true,
      children: [
        // Character content
        M3PanelStyles.buildSectionTitle(
            context, l10n.collectionPropertyPanelCharacter),
        M3CharacterInputField(
          initialText: characters,
          selectedCharIndex: selectedCharIndex,
          onTextChanged: onTextChanged,
          onSelectedCharIndexChanged: onCharacterSelected,
        ),

        const SizedBox(height: 16.0),

        // Character preview
        M3PanelStyles.buildSectionTitle(
            context, l10n.characterCollectionPreviewTab),
        M3CharacterPreviewPanel(
          element: element,
          selectedCharIndex: selectedCharIndex,
          onCharacterSelected: onCharacterSelected,
        ),

        const SizedBox(height: 16.0),

        // Candidate characters
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

        const SizedBox(height: 16.0), // Text format settings
        M3PanelStyles.buildSectionTitle(
            context, l10n.collectionPropertyPanelTextSettings),
        M3TextFormatPanel(
          content: content,
          onContentPropertyChanged: onContentPropertyChanged,
        ),

        const SizedBox(height: 16.0),

        // Auto line break setting
        M3PanelStyles.buildSectionTitle(
            context, l10n.collectionPropertyPanelAutoLineBreak),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Switch(
              value: content['enableSoftLineBreak'] as bool? ?? false,
              activeColor: Theme.of(context).colorScheme.primary,
              onChanged: (value) {
                onContentPropertyChanged('enableSoftLineBreak', value);
              },
            ),
            const SizedBox(width: 8.0),
            Text(
              (content['enableSoftLineBreak'] as bool? ?? false)
                  ? l10n.collectionPropertyPanelAutoLineBreakEnabled
                  : l10n.collectionPropertyPanelAutoLineBreakDisabled,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const Spacer(),
            Tooltip(
              message: l10n.collectionPropertyPanelAutoLineBreakTooltip,
              child: Icon(
                Icons.info_outline,
                size: 16.0,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
