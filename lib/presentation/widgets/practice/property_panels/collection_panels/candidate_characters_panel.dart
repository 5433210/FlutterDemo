import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../application/providers/service_providers.dart';
import '../../../../../domain/models/character/character_entity.dart';
import 'collection_color_utils.dart';

/// 候选集字面板
class CandidateCharactersPanel extends ConsumerWidget {
  final Map<String, dynamic> element;
  final int selectedCharIndex;
  final List<CharacterEntity> candidateCharacters;
  final bool isLoading;
  final bool invertDisplay;
  final Function(CharacterEntity) onCharacterSelected;
  final Function(bool) onInvertDisplayToggled;
  final Function(int, bool) onCharacterInvertToggled; // 新增：切换当前字符反转状态的回调

  const CandidateCharactersPanel({
    Key? key,
    required this.element,
    required this.selectedCharIndex,
    required this.candidateCharacters,
    required this.isLoading,
    required this.invertDisplay,
    required this.onCharacterSelected,
    required this.onInvertDisplayToggled,
    required this.onCharacterInvertToggled, // 新增参数
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final content = element['content'] as Map<String, dynamic>;
    final characters = content['characters'] as String? ?? '';
    final selectedChar = selectedCharIndex < characters.length
        ? characters[selectedCharIndex]
        : '';

    // 获取当前字符的反转状态
    final bool isCurrentCharInverted =
        _isCharacterInverted(content, selectedCharIndex);

    // 过滤出与当前选中字符匹配的候选集字
    final matchingCharacters = candidateCharacters
        .where((entity) => entity.character == selectedChar)
        .toList();

    if (isLoading && candidateCharacters.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(8.0),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(4.0),
        ),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (matchingCharacters.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(8.0),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(4.0),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Center(
              child: Text('无匹配的候选集字', style: TextStyle(color: Colors.grey)),
            ),
            const SizedBox(height: 8),
            Text('当前选中字符: "$selectedChar"',
                style: const TextStyle(fontSize: 10, color: Colors.grey)),
            if (candidateCharacters.isNotEmpty)
              Text(
                  '可用字符: ${candidateCharacters.map((e) => e.character).join(", ")}',
                  style: const TextStyle(fontSize: 10, color: Colors.grey)),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(4.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(bottom: 8.0),
            child:
                Text('候选集字列表', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          // 显示控制按钮组 - 修改为两个按钮
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              children: [
                const Text('显示效果:'),
                const SizedBox(width: 8.0),
                // 全局反转按钮
                InkWell(
                  onTap: () {
                    onInvertDisplayToggled(!invertDisplay);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8.0, vertical: 4.0),
                    decoration: BoxDecoration(
                      color: invertDisplay
                          ? Colors.blue.withOpacity(0.2)
                          : Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4.0),
                      border: Border.all(
                        color:
                            invertDisplay ? Colors.blue : Colors.grey.shade400,
                        width: 1.0,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.invert_colors,
                          size: 18.0,
                          color: invertDisplay
                              ? Colors.blue
                              : Colors.grey.shade700,
                        ),
                        const SizedBox(width: 4.0),
                        Text(
                          '全局反转',
                          style: TextStyle(
                            color: invertDisplay
                                ? Colors.blue
                                : Colors.grey.shade700,
                            fontWeight: invertDisplay
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8.0),
                // 新增：当前字符反转按钮
                InkWell(
                  onTap: () {
                    onCharacterInvertToggled(
                        selectedCharIndex, !isCurrentCharInverted);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8.0, vertical: 4.0),
                    decoration: BoxDecoration(
                      color: isCurrentCharInverted
                          ? Colors.purple.withOpacity(0.2)
                          : Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4.0),
                      border: Border.all(
                        color: isCurrentCharInverted
                            ? Colors.purple
                            : Colors.grey.shade400,
                        width: 1.0,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.format_color_reset,
                          size: 18.0,
                          color: isCurrentCharInverted
                              ? Colors.purple
                              : Colors.grey.shade700,
                        ),
                        const SizedBox(width: 4.0),
                        Text(
                          '当前字符反转',
                          style: TextStyle(
                            color: isCurrentCharInverted
                                ? Colors.purple
                                : Colors.grey.shade700,
                            fontWeight: isCurrentCharInverted
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Wrap(
            spacing: 8.0,
            runSpacing: 8.0,
            children: List.generate(
              matchingCharacters.length,
              (index) {
                final entity = matchingCharacters[index];

                // 检查当前元素是否已经选中
                final characterImages =
                    content['characterImages'] as Map<String, dynamic>? ?? {};
                final imageInfo = characterImages['$selectedCharIndex']
                    as Map<String, dynamic>?;
                final isSelected =
                    imageInfo != null && imageInfo['characterId'] == entity.id;

                return _buildCandidateCharacterItem(context, ref, entity,
                    isSelected, index, isCurrentCharInverted);
              },
            ),
          ),
        ],
      ),
    );
  }

  /// 构建候选字符项
  Widget _buildCandidateCharacterItem(
      BuildContext context,
      WidgetRef ref,
      CharacterEntity entity,
      bool isSelected,
      int index,
      bool isCurrentCharInverted) {
    return FutureBuilder<Map<String, String>?>(
      future:
          ref.read(characterImageServiceProvider).getAvailableFormat(entity.id),
      builder: (context, snapshot) {
        return GestureDetector(
          onTap: () => onCharacterSelected(entity),
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              border: Border.all(
                color: isSelected ? Colors.blue : Colors.grey.shade300,
                width: isSelected ? 2.0 : 1.0,
              ),
              borderRadius: BorderRadius.circular(4.0),
            ),
            child: Stack(
              children: [
                if (snapshot.connectionState == ConnectionState.waiting)
                  const Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
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
                        return const Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        );
                      } else if (imageSnapshot.hasData &&
                          imageSnapshot.data != null) {
                        // 应用反转颜色效果 - 现在考虑全局反转和当前字符反转
                        final imageWidget = Image.memory(
                          imageSnapshot.data!,
                          fit: BoxFit.contain,
                        );

                        // 根据全局反转和当前字符反转的设置确定是否反转
                        final shouldInvert =
                            invertDisplay || isCurrentCharInverted;

                        return Center(
                          child: shouldInvert
                              ? ColorFiltered(
                                  colorFilter: const ColorFilter.matrix([
                                    -1, 0, 0, 0, 255, // 红色通道反转
                                    0, -1, 0, 0, 255, // 绿色通道反转
                                    0, 0, -1, 0, 255, // 蓝色通道反转
                                    0, 0, 0, 1, 0, // 透明度保持不变
                                  ]),
                                  child: imageWidget,
                                )
                              : imageWidget,
                        );
                      } else {
                        return Center(
                          child: Text(
                            '${entity.character}${CollectionColorUtils.getSubscript(index + 1)}',
                            style: const TextStyle(fontSize: 20),
                          ),
                        );
                      }
                    },
                  )
                else
                  Center(
                    child: Text(
                      '${entity.character}${CollectionColorUtils.getSubscript(index + 1)}',
                      style: const TextStyle(fontSize: 20),
                    ),
                  ),
                if (isSelected)
                  const Positioned(
                    right: 2,
                    bottom: 2,
                    child: Icon(
                      Icons.check_circle,
                      size: 16,
                      color: Colors.green,
                    ),
                  ),
                // 如果当前字符设置了反转，添加一个反转指示器
                if (isCurrentCharInverted)
                  Positioned(
                    right: isSelected ? 20 : 2,
                    bottom: 2,
                    child: const Icon(
                      Icons.format_color_reset,
                      size: 16,
                      color: Colors.purple,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// 检查字符是否设置了反转状态
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

    // 检查是否有transform属性
    if (!charImageInfo.containsKey('transform')) {
      return false;
    }

    final transform = charImageInfo['transform'] as Map<String, dynamic>?;
    if (transform == null) {
      return false;
    }

    // 获取反转状态
    return transform['invert'] == true;
  }
}
