import 'dart:io';

import 'package:flutter/material.dart';

import '../../viewmodels/states/character_grid_state.dart';

class CharacterTile extends StatelessWidget {
  final CharacterViewModel character;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const CharacterTile({
    Key? key,
    required this.character,
    required this.isSelected,
    required this.onTap,
    required this.onLongPress,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      borderRadius: BorderRadius.circular(8.0),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? theme.colorScheme.primary : theme.dividerColor,
            width: isSelected ? 2.0 : 1.0,
          ),
          borderRadius: BorderRadius.circular(8.0),
          color: isSelected ? theme.colorScheme.primary.withOpacity(0.1) : null,
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 字符图片
                Expanded(
                  flex: 5,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: _buildImage(context),
                  ),
                ),

                // 字符信息
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 6.0),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(7.0),
                      bottomRight: Radius.circular(7.0),
                    ),
                  ),
                  child: Text(
                    character.character.isEmpty ? '无字符' : character.character,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            // 选中指示器
            if (isSelected)
              Positioned(
                top: 4,
                right: 4,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check,
                    size: 16,
                    color: theme.colorScheme.onPrimary,
                  ),
                ),
              ),

            // 收藏指示器
            if (character.isFavorite)
              const Positioned(
                top: 4,
                left: 4,
                child: Icon(
                  Icons.favorite,
                  size: 16,
                  color: Colors.red,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage(BuildContext context) {
    // 尝试加载缩略图
    try {
      return Image.file(
        File(character.thumbnailPath),
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return _buildPlaceholder(context);
        },
      );
    } catch (e) {
      return _buildPlaceholder(context);
    }
  }

  Widget _buildPlaceholder(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(4.0),
      ),
      child: Center(
        child: Icon(
          Icons.image_not_supported,
          size: 24,
          color: Colors.grey[400],
        ),
      ),
    );
  }
}
