import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../domain/models/character/character_entity.dart';
import '../../../../../l10n/app_localizations.dart';
import '../m3_panel_styles.dart';
import 'm3_candidate_characters_panel.dart';
import 'm3_character_input_field.dart';
import 'm3_character_preview_panel.dart';
import 'm3_character_transform_controller.dart';
import 'm3_text_format_panel.dart';

/// Material 3 content settings panel for collection elements
class M3ContentSettingsPanel extends ConsumerWidget {
  final Map<String, dynamic> element;
  final int selectedCharIndex;
  final List<CharacterEntity> candidateCharacters;
  final bool isLoading;
  final Function(String) onTextChanged;
  final Function(int) onCharacterSelected;
  final Function(CharacterEntity) onCandidateCharacterSelected;
  final Function(String, dynamic) onContentPropertyChanged;
  final Function(String, dynamic)? onContentPropertyUpdateStart;
  final Function(String, dynamic)? onContentPropertyUpdatePreview;
  final Function(String, dynamic, dynamic)? onContentPropertyUpdateWithUndo;
  // 新增：字符变换回调函数
  final Function(int, String, dynamic)? onCharacterTransformChanged;
  final Function(int, String, dynamic)? onCharacterTransformUpdateStart;
  final Function(int, String, dynamic)? onCharacterTransformUpdatePreview;
  final Function(int, String, dynamic, dynamic)?
      onCharacterTransformUpdateWithUndo;
  final Function(int, Map<String, dynamic>, Map<String, dynamic>)?
      onCharacterTransformBatchUndo;

  const M3ContentSettingsPanel({
    Key? key,
    required this.element,
    required this.selectedCharIndex,
    required this.candidateCharacters,
    required this.isLoading,
    required this.onTextChanged,
    required this.onCharacterSelected,
    required this.onCandidateCharacterSelected,
    required this.onContentPropertyChanged,
    this.onContentPropertyUpdateStart,
    this.onContentPropertyUpdatePreview,
    this.onContentPropertyUpdateWithUndo,
    // 新增参数
    this.onCharacterTransformChanged,
    this.onCharacterTransformUpdateStart,
    this.onCharacterTransformUpdatePreview,
    this.onCharacterTransformUpdateWithUndo,
    this.onCharacterTransformBatchUndo,
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
        M3PanelStyles.buildSectionTitle(context, l10n.characterCollection),
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

        // Single character transform controller
        M3PanelStyles.buildSectionTitle(context, '单字符调整'),
        M3CharacterTransformController(
          element: element,
          selectedCharIndex: selectedCharIndex,
          onTransformPropertyChanged: (key, value) {
            onCharacterTransformChanged?.call(selectedCharIndex, key, value);
          },
          onTransformPropertyUpdateStart: (charIndex, key, value) {
            onCharacterTransformUpdateStart?.call(charIndex, key, value);
          },
          onTransformPropertyUpdatePreview: (charIndex, key, value) {
            onCharacterTransformUpdatePreview?.call(charIndex, key, value);
          },
          onTransformPropertyUpdateWithUndo: (charIndex, key, value, oldValue) {
            developer.log(
                '内容设置面板 - undo回调: charIndex=$charIndex, key=$key, value=$value, oldValue=$oldValue',
                name: 'CharacterTransform');
            onCharacterTransformUpdateWithUndo?.call(
                charIndex, key, value, oldValue);
          },
          onTransformPropertiesBatchUndo: (charIndex, changes, originalValues) {
            developer.log(
                '内容设置面板 - 批量undo回调: charIndex=$charIndex, changes=$changes, originalValues=$originalValues',
                name: 'CharacterTransform');
            onCharacterTransformBatchUndo?.call(
                charIndex, changes, originalValues);
          },
        ),

        const SizedBox(height: 16.0),

        // Candidate characters
        M3CandidateCharactersPanel(
          element: element,
          selectedCharIndex: selectedCharIndex,
          candidateCharacters: candidateCharacters,
          isLoading: isLoading,
          onCharacterSelected: onCandidateCharacterSelected,
        ),

        const SizedBox(height: 16.0), // Text format settings
        M3PanelStyles.buildSectionTitle(context, l10n.textSettings),
        M3TextFormatPanel(
          content: content,
          onContentPropertyChanged: onContentPropertyChanged,
          onContentPropertyUpdateStart: onContentPropertyUpdateStart,
          onContentPropertyUpdatePreview: onContentPropertyUpdatePreview,
          onContentPropertyUpdateWithUndo: onContentPropertyUpdateWithUndo,
        ),

        const SizedBox(height: 16.0),

        // Auto line break setting
        M3PanelStyles.buildSectionTitle(context, l10n.autoLineBreak),
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
                  ? l10n.autoLineBreakEnabled
                  : l10n.autoLineBreakDisabled,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const Spacer(),
            Tooltip(
              message: l10n.autoLineBreak,
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
