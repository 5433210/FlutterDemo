import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../application/providers/service_providers.dart';

/// 集字预览组件
class CharacterPreviewPanel extends ConsumerWidget {
  final Map<String, dynamic> element;
  final int selectedCharIndex;
  final Function(int) onCharacterSelected;

  const CharacterPreviewPanel({
    Key? key,
    required this.element,
    required this.selectedCharIndex,
    required this.onCharacterSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final content = element['content'] as Map<String, dynamic>;
    final characters = content['characters'] as String? ?? '';

    if (characters.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(8.0),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(4.0),
        ),
        child: const Center(
          child: Text('无集字内容', style: TextStyle(color: Colors.grey)),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(4.0),
      ),
      child: Wrap(
        spacing: 8.0,
        runSpacing: 8.0,
        children: List.generate(
          characters.characters.length,
          (index) => GestureDetector(
            onTap: () => onCharacterSelected(index),
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                border: Border.all(
                  color: selectedCharIndex == index
                      ? Colors.blue
                      : Colors.grey.shade300,
                  width: selectedCharIndex == index ? 2.0 : 1.0,
                ),
                borderRadius: BorderRadius.circular(4.0),
              ),
              child: _buildCharacterImage(
                  context, ref, characters.characters.elementAt(index),
                  isSelected: selectedCharIndex == index, index: index),
            ),
          ),
        ),
      ),
    );
  }

  /// 构建字符图像
  Widget _buildCharacterImage(
      BuildContext context, WidgetRef ref, String character,
      {bool isSelected = false, int? index}) {
    // 检查元素内容中是否已有字符图像信息
    final content = element['content'] as Map<String, dynamic>? ?? {};
    final characterImages =
        content['characterImages'] as Map<String, dynamic>? ?? {};
    final idx = index ?? selectedCharIndex;

    // 如果有该索引的字符图像信息，则使用它
    if (characterImages.containsKey('$idx')) {
      final imageInfo = characterImages['$idx'] as Map<String, dynamic>;
      final characterId = imageInfo['characterId'] as String?;
      final type = imageInfo['type'] as String?;
      final format = imageInfo['format'] as String?;

      if (characterId != null && type != null && format != null) {
        return FutureBuilder<Uint8List?>(
          future: Future.any([
            ref
                .read(characterImageServiceProvider)
                .getCharacterImage(characterId, type, format),
            // 添加3秒超时
            Future.delayed(const Duration(seconds: 3), () => null),
          ]),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                  child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2)));
            }

            if (!snapshot.hasData || snapshot.data == null) {
              return _buildDefaultCharacterText(character, isSelected);
            }

            return Image.memory(
              snapshot.data!,
              fit: BoxFit.contain,
              color: isSelected ? Colors.blue : null,
              colorBlendMode: isSelected ? BlendMode.srcATop : null,
              errorBuilder: (context, error, stackTrace) {
                return _buildDefaultCharacterText(character, isSelected);
              },
            );
          },
        );
      }
    }

    return _buildDefaultCharacterText(character, isSelected);
  }

  /// 构建默认字符文本显示
  Widget _buildDefaultCharacterText(String character, bool isSelected) {
    return Center(
      child: Text(
        character,
        style: TextStyle(
          fontSize: 24,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? Colors.blue : Colors.black,
        ),
      ),
    );
  }
}
