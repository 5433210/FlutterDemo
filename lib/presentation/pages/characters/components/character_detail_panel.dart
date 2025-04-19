import 'dart:io';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';

import '../../../../domain/models/character/character_view.dart';
import '../../../../theme/app_sizes.dart';
import '../../../providers/character/character_detail_provider.dart';
import '../../../widgets/common/zoomable_image_view.dart';

class CharacterDetailPanel extends ConsumerStatefulWidget {
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
  ConsumerState<CharacterDetailPanel> createState() =>
      _CharacterDetailPanelState();
}

class _CharacterDetailPanelState extends ConsumerState<CharacterDetailPanel> {
  final ScrollController _formatScrollController = ScrollController();

  String get characterId => widget.characterId;
  VoidCallback get onClose => widget.onClose;
  VoidCallback? get onEdit => widget.onEdit;
  VoidCallback? get onToggleFavorite => widget.onToggleFavorite;

  @override
  Widget build(BuildContext context) {
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

            // Get the current format's image path
            Future<String> currentImagePathFuture =
                currentFormat.resolvePath(characterId);

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with actions
                _buildHeader(ref, theme, character),

                const Divider(),

                // Image preview - now using the selected format's image
                Expanded(
                  flex: 3,
                  child: FutureBuilder<String>(
                    future: currentImagePathFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      }

                      final imagePath = snapshot.data;

                      return _buildImagePreview(theme, character, imagePath);
                    },
                  ),
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

                        if (character.tool != null)
                          _buildInfoItem(
                            theme,
                            title: '书写工具',
                            content: character.tool?.label ?? '未知',
                            iconData: Icons.brush,
                          ),

                        if (character.style != null)
                          _buildInfoItem(
                            theme,
                            title: '书法风格',
                            content: character.style?.label ?? '未知',
                            iconData: Icons.style,
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
                            if (character.workId.isNotEmpty) {
                              Navigator.pushNamed(
                                context,
                                '/work_detail',
                                arguments: {
                                  'workId': character.workId,
                                  'pageId': character.pageId
                                },
                              );
                            }
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
                                      Navigator.pushNamed(
                                        context,
                                        '/characters/${relatedChar.id}',
                                      );
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

  @override
  void dispose() {
    _formatScrollController.dispose();
    super.dispose();
  }

  Widget _buildFormatSelector(
      WidgetRef ref, ThemeData theme, int selectedFormat) {
    final detailState = ref.watch(characterDetailProvider(characterId));

    return detailState.maybeWhen(
      data: (state) {
        if (state == null) return const SizedBox(height: 90);

        final formats = state.availableFormats;

        return Container(
          height: 90,
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: ScrollConfiguration(
            behavior: ScrollConfiguration.of(context).copyWith(
              dragDevices: {
                PointerDeviceKind.touch,
                PointerDeviceKind.mouse,
              },
            ),
            child: ListView.builder(
              controller: _formatScrollController,
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: formats.length,
              itemBuilder: (context, index) {
                final label = index < formats.length
                    ? formats[index].name
                    : 'Format $index';
                final isSelected = index == selectedFormat;
                final format = formats[index];

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        ref.read(selectedFormatProvider.notifier).state = index;
                      },
                      borderRadius: BorderRadius.circular(4),
                      child: Container(
                        width: 80,
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: isSelected
                                ? theme.colorScheme.primary
                                : theme.colorScheme.outline,
                            width: isSelected ? 2 : 1,
                          ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Image thumbnail
                            Expanded(
                                child: FutureBuilder<String>(
                              future: format.resolvePath(characterId),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return const Center(
                                      child: SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  ));
                                }

                                return ClipRRect(
                                  borderRadius: BorderRadius.circular(2),
                                  child: Image.file(
                                    File(snapshot.data ?? ''),
                                    fit: BoxFit.contain,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Center(
                                        child: Text(
                                          state.character?.character ?? '',
                                          style: theme.textTheme.bodyLarge,
                                        ),
                                      );
                                    },
                                  ),
                                );
                              },
                            )),
                            const SizedBox(height: 4),
                            // Format label
                            Text(
                              label,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: isSelected
                                    ? theme.colorScheme.primary
                                    : null,
                                fontWeight: isSelected ? FontWeight.bold : null,
                              ),
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
      orElse: () => const SizedBox(height: 90),
    );
  }

  Widget _buildHeader(WidgetRef ref, ThemeData theme, CharacterView character) {
    // Use a smaller icon size
    const double iconSize = 16.0;

    return LayoutBuilder(builder: (context, constraints) {
      // Get available width for layout decisions
      final availableWidth = constraints.maxWidth;

      // Determine if we have very limited space
      final isVeryNarrow = availableWidth < 100;

      return Row(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Close button with smaller size
          SizedBox(
            width: 24,
            height: 24,
            child: IconButton(
              padding: EdgeInsets.zero,
              onPressed: onClose,
              icon: const Icon(Icons.close, size: iconSize),
              tooltip: '关闭详情',
              constraints: const BoxConstraints.tightFor(width: 24, height: 24),
              visualDensity: VisualDensity.compact,
            ),
          ),

          // Title with flexible width
          if (!isVeryNarrow)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: Text(
                  '字符详情',
                  style: theme.textTheme.bodyMedium, // Even smaller text
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
            ),

          // Action buttons in a tight row
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (onEdit != null)
                SizedBox(
                  width: 24,
                  height: 24,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    onPressed: () {
                      final characterView = ref
                          .read(characterDetailProvider(characterId))
                          .value
                          ?.character;
                      if (characterView != null) {
                        Navigator.pushNamed(
                          context,
                          '/character_collection',
                          arguments: {
                            'workId': characterView.workId,
                            'pageId': characterView.pageId,
                            'characterId': characterView.id,
                          },
                        );
                      } else {
                        onEdit?.call();
                      }
                    },
                    icon: const Icon(Icons.edit, size: iconSize),
                    tooltip: '修改',
                    constraints:
                        const BoxConstraints.tightFor(width: 24, height: 24),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              if (onToggleFavorite != null)
                SizedBox(
                  width: 24,
                  height: 24,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    onPressed: () {
                      onToggleFavorite?.call();
                      ref.invalidate(characterDetailProvider(characterId));
                    },
                    icon: Icon(
                      character.isFavorite ? Icons.star : Icons.star_border,
                      size: iconSize,
                      color: character.isFavorite
                          ? theme.colorScheme.primary
                          : null,
                    ),
                    tooltip: character.isFavorite ? '取消收藏' : '收藏',
                    constraints:
                        const BoxConstraints.tightFor(width: 24, height: 24),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
            ],
          ),
        ],
      );
    });
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
          // Check if the file is an SVG format
          if (imagePath.toLowerCase().endsWith('.svg')) {
            // Use SvgPicture for SVG files
            return SvgPicture.asset(
              imagePath,
              fit: BoxFit.contain,
              placeholderBuilder: (context) => const Center(
                child: CircularProgressIndicator(),
              ),
            );
          } else {
            // Use ZoomableImageView for regular image files (PNG, JPG)
            return ZoomableImageView(
              imagePath: imagePath,
              enableMouseWheel: true,
              showControls: true,
            );
          }
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
