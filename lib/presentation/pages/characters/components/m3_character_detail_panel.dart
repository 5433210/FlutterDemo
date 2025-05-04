import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';

import '../../../../domain/models/character/character_image_type.dart';
import '../../../../domain/models/character/character_view.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../presentation/widgets/common/zoomable_image_view.dart';
import '../../../../theme/app_sizes.dart';
import '../../../../widgets/layout/flexible_row.dart';
import '../../../providers/character/character_detail_provider.dart';

/// Material 3 version of the character detail panel
class M3CharacterDetailPanel extends ConsumerStatefulWidget {
  /// ID of the character to display
  final String characterId;

  /// Callback when the close button is pressed
  final VoidCallback? onClose;

  /// Callback when the edit button is pressed
  final VoidCallback? onEdit;

  /// Callback when the favorite button is pressed
  final Future<void> Function()? onToggleFavorite;

  /// Constructor
  const M3CharacterDetailPanel({
    super.key,
    required this.characterId,
    this.onClose,
    this.onEdit,
    this.onToggleFavorite,
  });

  @override
  ConsumerState<M3CharacterDetailPanel> createState() =>
      _M3CharacterDetailPanelState();
}

class _M3CharacterDetailPanelState
    extends ConsumerState<M3CharacterDetailPanel> {
  int selectedFormat = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    // Get character detail state
    final detailAsync = ref.watch(characterDetailProvider(widget.characterId));

    return Material(
      color: theme.colorScheme.surface,
      elevation: 0,
      surfaceTintColor: theme.colorScheme.surfaceTint,
      child: Container(
        padding: const EdgeInsets.all(AppSizes.spacingMedium),
        child: detailAsync.when(
          data: (state) {
            if (state == null || state.character == null) {
              return Center(
                child: Text(l10n.characterDetailLoadError),
              );
            }

            final character = state.character!;
            final formats = state.availableFormats;
            final currentFormat = selectedFormat < formats.length
                ? formats[selectedFormat]
                : formats.first;

            // Get the current format's image path
            Future<String> currentImagePathFuture =
                currentFormat.resolvePath(widget.characterId);

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with actions
                _buildHeader(ref, theme, character, l10n),

                const Divider(),

                // Image preview - using the selected format's image
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

                      return _buildImagePreview(
                          theme, character, imagePath, l10n);
                    },
                  ),
                ),

                // Format thumbnails
                _buildFormatSelector(ref, theme, selectedFormat, l10n),

                const Divider(),

                // Character details
                Expanded(
                  flex: 2,
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.characterDetailBasicInfo,
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: AppSizes.spacingSmall),
                        _buildInfoItem(
                          theme,
                          title: l10n.characterDetailSimplifiedChar,
                          content: character.character,
                          iconData: Icons.text_format,
                        ),
                        if (character.tool != null)
                          _buildInfoItem(
                            theme,
                            title: l10n.characterDetailWritingTool,
                            content: character.tool?.label ??
                                l10n.characterDetailUnknown,
                            iconData: Icons.brush,
                          ),
                        if (character.style != null)
                          _buildInfoItem(
                            theme,
                            title: l10n.characterDetailCalligraphyStyle,
                            content: character.style?.label ??
                                l10n.characterDetailUnknown,
                            iconData: Icons.style,
                          ),
                        _buildInfoItem(
                          theme,
                          title: l10n.characterDetailCollectionTime,
                          content: _formatDateTime(character.collectionTime),
                          iconData: Icons.access_time,
                        ),
                        const Divider(),
                        Text(
                          l10n.characterDetailWorkInfo,
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: AppSizes.spacingSmall),
                        _buildInfoItem(
                          theme,
                          title: l10n.characterDetailWorkTitle,
                          content: character.title,
                          iconData: Icons.book,
                        ),
                        if (character.author != null)
                          _buildInfoItem(
                            theme,
                            title: l10n.characterDetailAuthor,
                            content:
                                character.author ?? l10n.characterDetailUnknown,
                            iconData: Icons.person,
                          ),
                        if (character.creationTime != null)
                          _buildInfoItem(
                            theme,
                            title: l10n.characterDetailCreationTime,
                            content: _formatDateTime(character.creationTime!),
                            iconData: Icons.calendar_today,
                          ),
                        if (character.tags.isNotEmpty) ...[
                          const Divider(),
                          Text(
                            l10n.characterDetailTags,
                            style: theme.textTheme.titleMedium,
                          ),
                          const SizedBox(height: AppSizes.spacingSmall),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: character.tags.map((tag) {
                              return Chip(
                                label: Text(tag),
                                backgroundColor:
                                    theme.colorScheme.surfaceContainerHighest,
                                labelStyle: TextStyle(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              );
                            }).toList(),
                          ),
                        ],
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
            child: Text(
              '${l10n.characterDetailLoadError}: $error',
              style: TextStyle(color: theme.colorScheme.error),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }

  Widget _buildFormatSelector(
    WidgetRef ref,
    ThemeData theme,
    int selectedIndex,
    AppLocalizations l10n,
  ) {
    final detailState = ref.watch(characterDetailProvider(widget.characterId));

    return detailState.maybeWhen(
      data: (state) {
        if (state == null) return const SizedBox.shrink();

        final formats = state.availableFormats;
        if (formats.isEmpty) return const SizedBox.shrink();

        return SizedBox(
          height: 60,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: formats.length,
            itemBuilder: (context, index) {
              final format = formats[index];
              final isSelected = index == selectedIndex;

              return FutureBuilder<String>(
                future: format.resolvePath(widget.characterId),
                builder: (context, snapshot) {
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedFormat = index;
                      });
                    },
                    child: Container(
                      width: 60,
                      height: 60,
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
                      child: snapshot.hasData
                          ? Tooltip(
                              message: _getFormatTooltip(format),
                              child: _buildFormatThumbnail(snapshot.data!),
                            )
                          : const Center(
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            ),
                    ),
                  );
                },
              );
            },
          ),
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }

  /// 根据文件路径构建缩略图
  Widget _buildFormatThumbnail(String imagePath) {
    final extension = imagePath.toLowerCase().split('.').last;
    final isSvg = extension == 'svg';

    if (isSvg) {
      // SVG 渲染
      return SvgPicture.file(
        File(imagePath),
        fit: BoxFit.contain,
        placeholderBuilder: (context) => const Icon(Icons.image),
      );
    } else {
      // 常规图片渲染
      return Image.file(
        File(imagePath),
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return const Icon(Icons.broken_image);
        },
      );
    }
  }

  Widget _buildHeader(
    WidgetRef ref,
    ThemeData theme,
    CharacterView character,
    AppLocalizations l10n,
  ) {
    // Create lists of widgets for each section
    final startSectionWidgets = [
      Text(
        character.character,
        style: theme.textTheme.headlineMedium?.copyWith(
          fontWeight: FontWeight.bold,
        ),
        overflow: TextOverflow.ellipsis,
      ),
      if (character.isFavorite)
        Icon(
          Icons.star,
          color: theme.colorScheme.primary,
        ),
    ];

    final endSectionWidgets = <Widget>[];

    // Add action buttons to end section
    if (widget.onToggleFavorite != null) {
      endSectionWidgets.add(
        IconButton(
          icon: Icon(
            character.isFavorite ? Icons.star : Icons.star_border,
            color: character.isFavorite
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurface,
          ),
          onPressed: () async {
            widget.onToggleFavorite?.call();
          },
          tooltip: character.isFavorite
              ? l10n.workBrowseRemoveFavorite
              : l10n.workBrowseAddFavorite,
          constraints: const BoxConstraints(
            minWidth: 40,
            minHeight: 40,
          ),
          padding: EdgeInsets.zero,
          visualDensity: VisualDensity.compact,
        ),
      );
    }

    if (widget.onEdit != null) {
      endSectionWidgets.add(
        IconButton(
          icon: const Icon(Icons.edit),
          onPressed: widget.onEdit,
          tooltip: l10n.edit,
          constraints: const BoxConstraints(
            minWidth: 40,
            minHeight: 40,
          ),
          padding: EdgeInsets.zero,
          visualDensity: VisualDensity.compact,
        ),
      );
    }

    if (widget.onClose != null) {
      endSectionWidgets.add(
        IconButton(
          icon: const Icon(Icons.close),
          onPressed: widget.onClose,
          tooltip: l10n.cancel,
          constraints: const BoxConstraints(
            minWidth: 40,
            minHeight: 40,
          ),
          padding: EdgeInsets.zero,
          visualDensity: VisualDensity.compact,
        ),
      );
    }

    // Use AdaptiveRow to handle overflow
    return AdaptiveRow(
      startSection: startSectionWidgets,
      endSection: endSectionWidgets,
      sectionSpacing: 8.0,
      itemSpacing: 4.0,
    );
  }

  Widget _buildImagePreview(
    ThemeData theme,
    CharacterView character,
    String? imagePath,
    AppLocalizations l10n,
  ) {
    return Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest
            .withAlpha(77), // 0.3 opacity = 77 alpha
        borderRadius: BorderRadius.circular(8),
      ),
      child: imagePath != null && imagePath.isNotEmpty
          ? ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: ZoomableImageView(
                imagePath: imagePath,
                enableMouseWheel: true,
                minScale: 0.5,
                maxScale: 5.0,
                showControls: true,
                errorBuilder: (context, error, stackTrace) {
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.broken_image,
                        size: 48,
                        color: theme.colorScheme.error,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        l10n.characterCollectionImageLoadError,
                        style: TextStyle(color: theme.colorScheme.error),
                      ),
                    ],
                  );
                },
                loadingBuilder: (context) {
                  return Center(
                    child: CircularProgressIndicator(
                      color: theme.colorScheme.primary,
                      strokeWidth: 2,
                    ),
                  );
                },
              ),
            )
          : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.image_not_supported,
                  size: 48,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.characterCollectionNoCharacter,
                  style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
            ),
    );
  }

  Widget _buildInfoItem(
    ThemeData theme, {
    required String title,
    required String content,
    required IconData iconData,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.spacingMedium),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: Icon(
              iconData,
              size: 20,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  content,
                  style: theme.textTheme.bodyMedium,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 3,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return DateFormat('yyyy-MM-dd HH:mm').format(dateTime);
  }

  /// 获取格式的提示文本
  String _getFormatTooltip(CharacterFormatInfo format) {
    final l10n = AppLocalizations.of(context);

    // 获取本地化的格式类型名称
    String formatTypeName;
    switch (format.format) {
      case CharacterImageType.original:
        formatTypeName = l10n.characterDetailFormatOriginal;
        break;
      case CharacterImageType.binary:
        formatTypeName = l10n.characterDetailFormatBinary;
        break;
      case CharacterImageType.thumbnail:
        formatTypeName = l10n.characterDetailFormatThumbnail;
        break;
      case CharacterImageType.squareBinary:
        formatTypeName = l10n.characterDetailFormatSquareBinary;
        break;
      case CharacterImageType.squareTransparent:
        formatTypeName = l10n.characterDetailFormatSquareTransparent;
        break;
      case CharacterImageType.transparent:
        formatTypeName = l10n.characterDetailFormatTransparent;
        break;
      case CharacterImageType.outline:
        formatTypeName = l10n.characterDetailFormatOutline;
        break;
      case CharacterImageType.squareOutline:
        formatTypeName = l10n.characterDetailFormatSquareOutline;
        break;
      default:
        formatTypeName = format.format.toString().split('.').last;
    }

    // 根据格式类型确定文件扩展名
    String extension;
    switch (format.format) {
      case CharacterImageType.outline:
      case CharacterImageType.squareOutline:
        extension = 'SVG';
        break;
      default:
        extension = 'PNG';
        break;
    }

    return '${format.name}\n${l10n.characterDetailFormatType}: $formatTypeName\n${l10n.characterDetailFormatExtension}: $extension\n${l10n.characterDetailFormatDescription}: ${format.description}';
  }
}
