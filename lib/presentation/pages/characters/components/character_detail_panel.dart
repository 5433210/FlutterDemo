import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../domain/models/character/character_view.dart';
import '../../../../theme/app_sizes.dart';
import '../../../providers/character/character_detail_provider.dart';
import '../../../widgets/common/zoomable_image_view.dart';

class CharacterDetailPanel extends ConsumerWidget {
  final String characterId;
  final VoidCallback onClose;
  final VoidCallback? onEdit;
  final VoidCallback? onToggleFavorite;

  const CharacterDetailPanel({
    super.key,
    required this.characterId,
    required this.onClose,
    this.onEdit,
    this.onToggleFavorite,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final detailAsync = ref.watch(characterDetailProvider(characterId));
    final selectedFormat = ref.watch(selectedFormatProvider);

    return Material(
      color: theme.colorScheme.surface,
      elevation: AppSizes.cardElevation,
      child: Container(
        width: 350,
        padding: const EdgeInsets.all(AppSizes.spacingMedium),
        child: detailAsync.when(
          data: (state) {
            if (state == null || state.character == null) {
              return const Center(
                child: Text('无法加载字符详情'),
              );
            }

            final character = state.character!;
            final formats = state.availableFormats;
            final currentFormat = selectedFormat < formats.length
                ? formats[selectedFormat]
                : formats.first;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with actions
                _buildHeader(theme, character),

                const Divider(),

                // Image preview
                Expanded(
                  flex: 3,
                  child: _buildImagePreview(
                      theme, character, state.transparentPath),
                ),

                // Format thumbnails
                _buildFormatSelector(ref, theme, selectedFormat),

                const Divider(),

                // Character details
                Expanded(
                  flex: 2,
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '基本信息',
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: AppSizes.spacingSmall),

                        _buildInfoItem(
                          theme,
                          title: '简体字',
                          content: character.character,
                          iconData: Icons.text_format,
                        ),

                        _buildInfoItem(
                          theme,
                          title: '收集时间',
                          content: _formatDateTime(character.collectionTime),
                          iconData: Icons.access_time,
                        ),

                        if (character.author != null)
                          _buildInfoItem(
                            theme,
                            title: '作者',
                            content: character.author!,
                            iconData: Icons.person,
                          ),

                        _buildInfoItem(
                          theme,
                          title: '作品来源',
                          content: character.title,
                          iconData: Icons.book,
                          isLink: true,
                          onTap: () {
                            // Navigate to work details
                          },
                        ),

                        if (character.creationTime != null)
                          _buildInfoItem(
                            theme,
                            title: '创作时间',
                            content: _formatDateTime(character.creationTime!),
                            iconData: Icons.calendar_today,
                          ),

                        const SizedBox(height: AppSizes.spacingMedium),

                        // Tags
                        Text(
                          '标签',
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: AppSizes.spacingSmall),

                        if (character.tags.isEmpty)
                          Text(
                            '无标签',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.outline,
                              fontStyle: FontStyle.italic,
                            ),
                          )
                        else
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              for (final tag in character.tags)
                                Chip(
                                  label: Text(tag),
                                  backgroundColor:
                                      theme.colorScheme.surfaceContainerHighest,
                                ),
                              IconButton.filled(
                                onPressed: () {
                                  // Show tag editor
                                },
                                icon: const Icon(Icons.add),
                                constraints: const BoxConstraints.tightFor(
                                  width: 32,
                                  height: 32,
                                ),
                              ),
                            ],
                          ),

                        const SizedBox(height: AppSizes.spacingMedium),

                        // Related characters
                        if (state.relatedCharacters.isNotEmpty) ...[
                          Text(
                            '相关字符',
                            style: theme.textTheme.titleMedium,
                          ),
                          const SizedBox(height: AppSizes.spacingSmall),
                          SizedBox(
                            height: 60,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: state.relatedCharacters.length,
                              itemBuilder: (context, index) {
                                final relatedChar =
                                    state.relatedCharacters[index];
                                return Padding(
                                  padding: const EdgeInsets.only(right: 8.0),
                                  child: InkWell(
                                    onTap: () {
                                      // Navigate to related character
                                    },
                                    child: Column(
                                      children: [
                                        Container(
                                          width: 40,
                                          height: 40,
                                          decoration: BoxDecoration(
                                            color: theme.colorScheme
                                                .surfaceContainerHighest,
                                            borderRadius:
                                                BorderRadius.circular(4),
                                          ),
                                          child: Center(
                                            child: Text(
                                              relatedChar.character,
                                              style:
                                                  theme.textTheme.titleMedium,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ]
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
          loading: () => const Center(
            child: CircularProgressIndicator(),
          ),
          error: (error, stack) => Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.error_outline,
                  color: Colors.red,
                  size: 48,
                ),
                const SizedBox(height: AppSizes.spacingMedium),
                Text('加载详情时出错: $error'),
                const SizedBox(height: AppSizes.spacingMedium),
                ElevatedButton(
                  onPressed: () =>
                      ref.refresh(characterDetailProvider(characterId)),
                  child: const Text('重试'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormatSelector(
      WidgetRef ref, ThemeData theme, int selectedFormat) {
    // Here we would use ThumbnailStrip in a real implementation
    // Since we don't have the actual image paths, we'll use a simplified version
    return SizedBox(
      height: 60,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 5, // Simplified with 5 fixed formats
        itemBuilder: (context, index) {
          final bool isSelected = index == selectedFormat;

          return GestureDetector(
            onTap: () =>
                ref.read(selectedFormatProvider.notifier).state = index,
            child: Container(
              width: 60,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                border: Border.all(
                  color: isSelected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.outline,
                  width: isSelected ? 2 : 1,
                ),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Center(
                child: Text(
                  ['原图', '二值', '透明', '方形', '轮廓'][index],
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isSelected ? theme.colorScheme.primary : null,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, CharacterView character) {
    return Row(
      children: [
        IconButton(
          onPressed: onClose,
          icon: const Icon(Icons.close),
          tooltip: '关闭详情',
        ),
        const SizedBox(width: AppSizes.spacingSmall),
        Text(
          '字符详情',
          style: theme.textTheme.titleLarge,
        ),
        const Spacer(),
        if (onEdit != null)
          IconButton(
            onPressed: onEdit,
            icon: const Icon(Icons.edit),
            tooltip: '修改',
          ),
        if (onToggleFavorite != null)
          IconButton(
            onPressed: onToggleFavorite,
            icon: Icon(
              character.isFavorite ? Icons.star : Icons.star_border,
              color: character.isFavorite ? theme.colorScheme.primary : null,
            ),
            tooltip: character.isFavorite ? '取消收藏' : '收藏',
          ),
      ],
    );
  }

  Widget _buildImagePreview(
      ThemeData theme, CharacterView character, String? imagePath) {
    if (imagePath == null) {
      return Container(
        color: theme.colorScheme.surfaceContainerHighest,
        child: Center(
          child: Text(
            character.character,
            style: theme.textTheme.displayLarge?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
        ),
      );
    }

    final file = File(imagePath);
    return FutureBuilder<bool>(
      future: file.exists(),
      builder: (context, snapshot) {
        final fileExists = snapshot.data ?? false;

        if (fileExists) {
          return ZoomableImageView(
            imagePath: imagePath,
            enableMouseWheel: true,
            showControls: true,
          );
        }

        return Container(
          color: theme.colorScheme.surfaceContainerHighest,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  character.character,
                  style: theme.textTheme.displayLarge?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.5),
                  ),
                ),
                const SizedBox(height: AppSizes.spacingMedium),
                Text(
                  '图像文件不存在',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoItem(
    ThemeData theme, {
    required String title,
    required String content,
    required IconData iconData,
    bool isLink = false,
    VoidCallback? onTap,
  }) {
    final textWidget = Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: '$title: ',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          TextSpan(
            text: content,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: isLink ? theme.colorScheme.primary : null,
              decoration: isLink ? TextDecoration.underline : null,
            ),
          ),
        ],
      ),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            iconData,
            size: 18,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: isLink && onTap != null
                ? InkWell(
                    onTap: onTap,
                    child: textWidget,
                  )
                : textWidget,
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays < 1) {
      return '今天 ${DateFormat('HH:mm').format(dateTime)}';
    } else if (difference.inDays < 2) {
      return '昨天 ${DateFormat('HH:mm').format(dateTime)}';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}天前';
    } else {
      return DateFormat('yyyy年MM月dd日 HH:mm').format(dateTime);
    }
  }
}
