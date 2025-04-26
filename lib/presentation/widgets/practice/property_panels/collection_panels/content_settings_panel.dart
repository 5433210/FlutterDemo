import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../domain/models/character/character_entity.dart';
import 'candidate_characters_panel.dart';
import 'character_input_field.dart';
import 'character_preview_panel.dart';
import 'text_format_panel.dart';

/// 集字内容设置面板
class ContentSettingsPanel extends ConsumerWidget {
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
  final Function(int, bool) onCharacterInvertToggled; // 新增：当前字符反转切换回调
  final VoidCallback onClearImageCache;

  const ContentSettingsPanel({
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
    required this.onCharacterInvertToggled, // 新增参数
    required this.onClearImageCache,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final content = element['content'] as Map<String, dynamic>;
    final characters = content['characters'] as String? ?? '';

    return ExpansionTile(
      title: const Text('内容设置'),
      initiallyExpanded: true,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 汉字内容
              const Text('汉字内容:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8.0),
              CharacterInputField(
                initialText: characters,
                selectedCharIndex: selectedCharIndex,
                onTextChanged: onTextChanged,
                onSelectedCharIndexChanged: onCharacterSelected,
              ),

              const SizedBox(height: 16.0),

              // 集字预览
              const Text('集字预览:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8.0),
              CharacterPreviewPanel(
                element: element,
                selectedCharIndex: selectedCharIndex,
                onCharacterSelected: onCharacterSelected,
              ),

              const SizedBox(height: 16.0),

              // 候选集字
              const Text('候选集字:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8.0),
              CandidateCharactersPanel(
                element: element,
                selectedCharIndex: selectedCharIndex,
                candidateCharacters: candidateCharacters,
                isLoading: isLoading,
                invertDisplay: invertDisplay,
                onCharacterSelected: onCandidateCharacterSelected,
                onInvertDisplayToggled: onInvertDisplayToggled,
                onCharacterInvertToggled: onCharacterInvertToggled, // 传递新回调
              ),

              const SizedBox(height: 16.0),

              // 清除图片缓存按钮
              ElevatedButton.icon(
                icon: const Icon(Icons.cleaning_services),
                label: const Text('清除图片缓存'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[100],
                  foregroundColor: Colors.red[900],
                ),
                onPressed: onClearImageCache,
              ),

              const SizedBox(height: 16.0),

              // 文本格式设置
              TextFormatPanel(
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
