import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../application/services/character/character_service.dart';
import '../../../../domain/models/character/character_image_type.dart';
import '../../../../domain/models/character/character_view.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../theme/app_sizes.dart';

/// Material 3 card for displaying a character in grid view
class M3CharacterCard extends StatelessWidget {
  /// Character to display
  final CharacterView character;

  /// Path to the character's thumbnail image
  final String? thumbnailPath;

  /// Whether the character is selected
  final bool isSelected;

  /// Whether batch selection mode is active
  final bool isBatchMode;

  /// Callback when the card is tapped
  final VoidCallback onTap;

  /// Callback when the favorite button is tapped
  final VoidCallback? onToggleFavorite;

  /// Constructor
  const M3CharacterCard({
    super.key,
    required this.character,
    this.thumbnailPath,
    required this.isSelected,
    required this.isBatchMode,
    required this.onTap,
    this.onToggleFavorite,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Card(
      elevation: isSelected ? 4 : 1,
      surfaceTintColor: isSelected ? theme.colorScheme.primaryContainer : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isSelected
            ? BorderSide(
                color: theme.colorScheme.primary,
                width: 2,
              )
            : BorderSide.none,
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Stack(
          children: [
            // Main content
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Thumbnail
                Expanded(
                  flex: 3,
                  child: _buildThumbnail(context, theme),
                ),

                // Character info
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6.0, vertical: 4.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Character with favorite indicator
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                character.character,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14, // 🔧 增大字符名称字体大小
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            // if (character.isFavorite) ...[
                            //   const SizedBox(width: 2),
                            //   Icon(
                            //     Icons.favorite,
                            //     color: theme.colorScheme.error,
                            //     size: 12, // Reduce icon size
                            //   ),
                            // ],
                          ],
                        ),

                        const SizedBox(height: 2), // 🔧 稍微增加间距

                        // Work title
                        Flexible(
                          child: Text(
                            character.title,
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontSize: 11, // 🔧 增大作品标题字体大小
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // Selection indicator for batch mode
            if (isBatchMode)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.surfaceContainerHighest
                            .withAlpha(179), // 0.7 opacity = 179 alpha
                    shape: BoxShape.circle,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(2.0),
                    child: isSelected
                        ? Icon(
                            Icons.check,
                            size: 16,
                            color: theme.colorScheme.onPrimary,
                          )
                        : Icon(
                            Icons.circle_outlined,
                            size: 16,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                  ),
                ),
              ),

            // Favorite button - 🔧 调整按钮大小，减小遮挡
            if (!isBatchMode && onToggleFavorite != null)
              Positioned(
                top: 4,
                right: 4,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: onToggleFavorite,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface.withAlpha(179), // 0.7 opacity
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        character.isFavorite
                            ? Icons.favorite
                            : Icons.favorite_border,
                        color: character.isFavorite
                            ? theme.colorScheme.error
                            : theme.colorScheme.onSurfaceVariant,
                        size: 14, // 🔧 缩小图标尺寸
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildThumbnail(BuildContext context, ThemeData theme) {
    // 🔧 使用固定的浅色背景，不跟随系统主题，提高黑白对比度
    return Container(
      color: Colors.grey.shade50, // 固定浅色背景
      padding: const EdgeInsets.all(8.0), // 🔧 添加20%左右的内边距，为字符图像提供留白
      child: thumbnailPath != null && thumbnailPath!.isNotEmpty
          ? Image.file(
              File(thumbnailPath!),
              fit: BoxFit.contain, // 🔧 改为contain以保持图像比例并显示完整内容
              errorBuilder: (context, error, stackTrace) {
                return Center(
                  child: Text(
                    character.character,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: Colors.black87, // 确保文字在浅色背景上清晰可见
                    ),
                  ),
                );
              },
            )
          : Center(
              child: Text(
                character.character,
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: Colors.black87, // 确保文字在浅色背景上清晰可见
                ),
              ),
            ),
    );
  }
}

/// Material 3 version of the grid view for displaying characters
class M3CharacterGridView extends ConsumerWidget {
  /// Characters to display
  final List<CharacterView> characters;

  /// Whether batch selection mode is active
  final bool isBatchMode;

  /// Set of selected character IDs
  final Set<String> selectedCharacters;

  /// Callback when a character is tapped
  final void Function(String) onCharacterTap;

  /// Callback when a character's favorite status is toggled
  final void Function(String) onToggleFavorite;

  /// Whether the view is in loading state
  final bool isLoading;

  /// Error message to display (if any)
  final String? errorMessage;

  /// Constructor
  const M3CharacterGridView({
    super.key,
    required this.characters,
    required this.onCharacterTap,
    required this.onToggleFavorite,
    this.isBatchMode = false,
    this.selectedCharacters = const {},
    this.isLoading = false,
    this.errorMessage,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    if (isLoading) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(l10n.loading),
          ],
        ),
      );
    }

    if (errorMessage != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              color: theme.colorScheme.error,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.error(errorMessage!),
              style: TextStyle(color: theme.colorScheme.error),
            ),
          ],
        ),
      );
    }

    if (characters.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off,
              color: theme.colorScheme.onSurfaceVariant,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.noCharacters,
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.noCharactersFound,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        // 设置固定的卡片宽度和最小宽度
        const double fixedCardWidth = 140.0; // 固定卡片宽度
        const double minContainerWidth = 400.0; // 最小容器宽度
        const double spacing = 16.0;
        const double padding = AppSizes.spacingMedium;

        // 计算可用宽度
        final double availableWidth = constraints.maxWidth;

        // 判断是否需要裁剪显示
        final bool needsClipping = availableWidth < minContainerWidth;

        // 如果需要裁剪，使用固定列数和固定卡片宽度
        if (needsClipping) {
          // 固定显示2列
          const int fixedColumnCount = 2;
          // 计算宽高比（略微高于宽度以容纳文本）
          const double childAspectRatio = 0.85;

          // 创建一个固定宽度的容器，允许水平滚动
          return SizedBox(
            width: availableWidth,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                // 设置一个固定的内容宽度，确保卡片大小不变
                width: fixedColumnCount * fixedCardWidth +
                    (fixedColumnCount - 1) * spacing +
                    padding * 2,
                child: GridView.builder(
                  padding: const EdgeInsets.all(padding),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: fixedColumnCount,
                    childAspectRatio: childAspectRatio,
                    crossAxisSpacing: spacing,
                    mainAxisSpacing: spacing,
                  ),
                  itemCount: characters.length,
                  itemBuilder: (context, index) {
                    final character = characters[index];
                    final isSelected =
                        selectedCharacters.contains(character.id);

                    // Use FutureBuilder to handle the async operation
                    return FutureBuilder<String>(
                      future: ref
                          .read(characterServiceProvider)
                          .getCharacterImagePath(
                              character.id, CharacterImageType.thumbnail),
                      builder: (context, snapshot) {
                        return Container(
                          key: ValueKey('character_${character.id}'),
                          child: M3CharacterCard(
                            character: character,
                            thumbnailPath: snapshot.data,
                            isSelected: isSelected,
                            isBatchMode: isBatchMode,
                            onTap: () => onCharacterTap(character.id),
                            onToggleFavorite: () =>
                                onToggleFavorite(character.id),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          );
        } else {
          // 正常模式：根据可用宽度动态调整列数
          // 计算最佳列数
          // 🔧 缩小网格最大尺寸，提高显示精度 - 设置最小卡片宽度为120像素，最大为140像素
          const double minCardWidth = 120.0;
          const double maxCardWidth = 140.0;

          // 计算可用宽度（减去padding）
          final double adjustedWidth = availableWidth - padding * 2;

          // 计算可以放置的最大列数（基于最小卡片宽度）
          int maxColumns = (adjustedWidth / minCardWidth).floor();

          // 确保至少有2列，最多有8列
          int crossAxisCount = maxColumns.clamp(2, 8);

          // 计算实际卡片宽度
          double actualCardWidth =
              (adjustedWidth - (spacing * (crossAxisCount - 1))) /
                  crossAxisCount;

          // 确保卡片宽度不超过最大值
          if (actualCardWidth > maxCardWidth && crossAxisCount < 8) {
            // 如果卡片太宽，增加列数
            crossAxisCount += 1;
            actualCardWidth =
                (adjustedWidth - (spacing * (crossAxisCount - 1))) /
                    crossAxisCount;
          }

          // 计算宽高比（略微高于宽度以容纳文本）
          double childAspectRatio = 0.85;

          return GridView.builder(
            padding: const EdgeInsets.all(padding),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              childAspectRatio: childAspectRatio,
              crossAxisSpacing: spacing,
              mainAxisSpacing: spacing,
            ),
            itemCount: characters.length,
            itemBuilder: (context, index) {
              final character = characters[index];
              final isSelected = selectedCharacters.contains(character.id);

              // Use FutureBuilder to handle the async operation
              return FutureBuilder<String>(
                future: ref
                    .read(characterServiceProvider)
                    .getCharacterImagePath(
                        character.id, CharacterImageType.thumbnail),
                builder: (context, snapshot) {
                  return Container(
                    key: ValueKey('character_${character.id}'),
                    child: M3CharacterCard(
                      character: character,
                      thumbnailPath: snapshot.data,
                      isSelected: isSelected,
                      isBatchMode: isBatchMode,
                      onTap: () => onCharacterTap(character.id),
                      onToggleFavorite: () => onToggleFavorite(character.id),
                    ),
                  );
                },
              );
            },
          );
        }
      },
    );
  }
}
