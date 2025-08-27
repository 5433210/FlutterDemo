import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../application/services/character/character_service.dart';
import '../../../../domain/models/character/character_image_type.dart';
import '../../../../domain/models/character/character_view.dart';
import '../../../../infrastructure/providers/config_providers.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../presentation/widgets/common/zoomable_image_view.dart';
import '../../../../routes/app_routes.dart';
import '../../../../theme/app_sizes.dart';
import '../../../../utils/chinese_font_helper.dart';
import '../../../providers/character/character_detail_provider.dart';
import '../../../utils/image_validator.dart';
import '../../../widgets/common/cross_platform_svg_picture.dart';
import '../../../widgets/layout/flexible_row.dart';

/// 图片尺寸信息类
class ImageDimensions {
  final int width;
  final int height;
  final bool isSvg;

  const ImageDimensions({
    required this.width,
    required this.height,
    required this.isSvg,
  });
}

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
  final TextEditingController _tagController = TextEditingController();

  @override
  void initState() {
    super.initState();
  }

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
              // Character doesn't exist (likely deleted), close the panel
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted && widget.onClose != null) {
                  widget.onClose!();
                }
              });
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

                // 🔧 添加预览区域与缩略图列表之间的间隙
                const SizedBox(height: 12),

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
                          l10n.basicInfo,
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
                          Consumer(
                            builder: (context, ref, child) {
                              final locale = Localizations.localeOf(context);
                              final toolDisplayName = ref
                                  .watch(toolDisplayNamesWithLocaleProvider(
                                      locale.languageCode))
                                  .maybeWhen(
                                    data: (names) =>
                                        names[character.tool] ??
                                        character.tool ??
                                        l10n.unknown,
                                    orElse: () =>
                                        character.tool ?? l10n.unknown,
                                  );
                              return _buildInfoItem(
                                theme,
                                title: l10n.writingTool,
                                content: toolDisplayName,
                                iconData: Icons.brush,
                              );
                            },
                          ),
                        if (character.style != null)
                          Consumer(
                            builder: (context, ref, child) {
                              final locale = Localizations.localeOf(context);
                              final styleDisplayName = ref
                                  .watch(styleDisplayNamesWithLocaleProvider(
                                      locale.languageCode))
                                  .maybeWhen(
                                    data: (names) =>
                                        names[character.style] ??
                                        character.style ??
                                        l10n.unknown,
                                    orElse: () =>
                                        character.style ?? l10n.unknown,
                                  );
                              return _buildInfoItem(
                                theme,
                                title: l10n.calligraphyStyle,
                                content: styleDisplayName,
                                iconData: Icons.style,
                              );
                            },
                          ),
                        _buildInfoItem(
                          theme,
                          title: l10n.collectionTime,
                          content: _formatDateTime(character.collectionTime),
                          iconData: Icons.access_time,
                        ),
                        const Divider(),
                        Text(
                          l10n.workInfo,
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: AppSizes.spacingSmall),
                        _buildInfoItemWithButton(
                          theme,
                          title: l10n.title,
                          content: character.title,
                          iconData: Icons.book,
                          buttonIcon: Icons.arrow_forward,
                          buttonTooltip: l10n.back,
                          onButtonPressed: () {
                            if (character.workId.isNotEmpty) {
                              // 使用命名路由导航到作品详情页
                              // 注意：这里我们使用的是当前导航器的上下文，而不是根导航器
                              // 这样可以确保导航发生在当前的嵌套导航器中
                              Navigator.of(context).pushNamed(
                                AppRoutes.workDetail,
                                arguments: character.workId,
                              );
                            }
                          },
                        ),
                        if (character.author != null)
                          _buildInfoItem(
                            theme,
                            title: l10n.author,
                            content: character.author ?? l10n.unknown,
                            iconData: Icons.person,
                          ),
                        if (character.tags.isNotEmpty) ...[
                          const Divider(),
                          Text(
                            l10n.tags,
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
                                onDeleted: () => _removeTag(character, tag),
                              );
                            }).toList(),
                          ),
                        ],
                        const SizedBox(height: AppSizes.spacingSmall),
                        ElevatedButton.icon(
                          onPressed: () => _showAddTagDialog(character, l10n),
                          icon: const Icon(Icons.add),
                          label: Text(l10n.addTag),
                        ),
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
          error: (error, stack) {
            // Character loading failed (likely deleted), close the panel
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && widget.onClose != null) {
                widget.onClose!();
              }
            });
            return Center(
              child: Text(
                '${l10n.characterDetailLoadError}: $error',
                style: TextStyle(color: theme.colorScheme.error),
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    _tagController.dispose();
    super.dispose();
  }

  // Add a tag to the character
  Future<void> _addTag(CharacterView character, String tag) async {
    try {
      final characterService = ref.read(characterServiceProvider);
      await characterService.addTag(character.id, tag);

      // Refresh character detail
      ref.invalidate(characterDetailProvider(widget.characterId));
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.tagAddError(e.toString())),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
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
                          ? _buildFormatThumbnailWithTooltip(
                              snapshot.data!, format)
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

  /// 根据文件路径构建带有提示的缩略图
  Widget _buildFormatThumbnailWithTooltip(String imagePath, dynamic format) {
    final extension = imagePath.toLowerCase().split('.').last;
    final isSvg = extension == 'svg';
    final l10n = AppLocalizations.of(context);

    // 获取实际的图像尺寸信息
    return FutureBuilder<ImageDimensions?>(
      future: _getImageDimensions(imagePath, isSvg),
      builder: (context, snapshot) {
        // 构建基本的提示文本
        String tooltipText = _getFormatTooltip(format);

        // 添加多语言支持的尺寸信息到提示文本中
        if (snapshot.hasData && snapshot.data != null) {
          final dimensions = snapshot.data!;
          tooltipText +=
              '\n${l10n.dimensions}: ${dimensions.width}×${dimensions.height} px';
        } else {
          // 如果无法获取尺寸，显示加载中或默认信息
          tooltipText += '\n${l10n.dimensions}: ${l10n.loading}...';
        }

        return Tooltip(
          message: tooltipText,
          waitDuration: const Duration(milliseconds: 500), // 减少等待时间
          showDuration: const Duration(seconds: 5), // 增加显示时间
          textStyle: const TextStyle(
            fontSize: 14,
            color: Colors.white,
          ),
          decoration: BoxDecoration(
            color: Colors.black87,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Container(
            color: Colors.grey.shade50, // 🔧 使用固定的浅色背景，不跟随系统主题，提高黑白对比度
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Image
                if (isSvg)
                  // SVG 渲染 with error handling
                  _buildSvgImage(imagePath)
                else
                  // 常规图片渲染，添加更好的错误处理
                  Image.file(
                    File(imagePath),
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Theme.of(context)
                            .colorScheme
                            .errorContainer
                            .withValues(alpha: 0.3),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.broken_image,
                                size: 24,
                                color: Theme.of(context).colorScheme.error,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '图像加载失败',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Theme.of(context).colorScheme.error,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
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
      // if (character.isFavorite)
      //   Icon(
      //     Icons.favorite,
      //     color: theme.colorScheme.error,
      //   ),
    ];

    final endSectionWidgets = <Widget>[];

    // Add action buttons to end section
    if (widget.onToggleFavorite != null) {
      endSectionWidgets.add(
        IconButton(
          icon: Icon(
            character.isFavorite ? Icons.favorite : Icons.favorite_border,
            color: character.isFavorite
                ? theme.colorScheme.error
                : theme.colorScheme.onSurface,
          ),
          onPressed: () async {
            widget.onToggleFavorite?.call();
          },
          tooltip:
              character.isFavorite ? l10n.removeFavorite : l10n.addFavorite,
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
          onPressed: () {
            // 获取字符详情
            final characterView = ref
                .read(characterDetailProvider(widget.characterId))
                .value
                ?.character;

            if (characterView != null) {
              // 使用命名路由导航到集字功能页，这样会在主窗体内容区域显示
              Navigator.of(context).pushNamed(
                AppRoutes.characterCollection,
                arguments: {
                  'workId': characterView.workId,
                  'pageId': characterView.pageId,
                  'characterId': characterView.id,
                },
              );
            } else {
              // 如果无法获取字符详情，则调用原始的onEdit回调
              widget.onEdit?.call();
            }
          },
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
        // 🔧 使用固定的浅色背景，不跟随系统主题，提高黑白对比度
        color: Colors.grey.shade50, // 固定浅色背景
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
                        l10n.imageLoadError(error.toString()),
                        style: TextStyle(color: theme.colorScheme.error),
                      ),
                    ],
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
                  l10n.noCharacters,
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
                ChineseFontHelper.createTextWithChineseSupport(
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

  Widget _buildInfoItemWithButton(
    ThemeData theme, {
    required String title,
    required String content,
    required IconData iconData,
    required IconData buttonIcon,
    required String buttonTooltip,
    required VoidCallback onButtonPressed,
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
                Row(
                  children: [
                    Expanded(
                      child: ChineseFontHelper.createTextWithChineseSupport(
                        content,
                        style: theme.textTheme.bodyMedium,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        buttonIcon,
                        size: 18,
                        color: theme.colorScheme.primary,
                      ),
                      onPressed: onButtonPressed,
                      tooltip: buttonTooltip,
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                      padding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
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
  String _getFormatTooltip(dynamic format) {
    final l10n = AppLocalizations.of(context);

    try {
      // 获取本地化的格式类型名称
      String formatTypeName;
      switch (format.format) {
        case CharacterImageType.original:
          formatTypeName = l10n.original;
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
          formatTypeName = format.format.toString();
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

      return '${format.name}\n${l10n.formatType}: $formatTypeName\n${l10n.fileExtension}: $extension\n${l10n.characterDetailFormatDescription}: ${format.description}';
    } catch (e) {
      // 如果格式对象不是预期的类型，返回一个简单的提示
      return '图片格式信息';
    }
  }

  // Remove a tag from the character
  Future<void> _removeTag(CharacterView character, String tag) async {
    try {
      final characterService = ref.read(characterServiceProvider);
      await characterService.removeTag(character.id, tag);

      // Refresh character detail
      ref.invalidate(characterDetailProvider(widget.characterId));
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.tagRemoveError(e.toString())),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  // Show dialog to add a new tag
  void _showAddTagDialog(CharacterView character, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(l10n.addTag),
          content: TextField(
            controller: _tagController,
            autofocus: true,
            decoration: InputDecoration(
              hintText: l10n.tagHint,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () {
                final tag = _tagController.text.trim();
                if (tag.isNotEmpty) {
                  _addTag(character, tag);
                }
                _tagController.clear();
                Navigator.of(context).pop();
              },
              child: Text(l10n.addTag),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSvgImage(String imagePath) {
    // 使用flutter_svg渲染SVG文件，添加错误处理
    return FutureBuilder<void>(
      future: _validateSvgFile(imagePath),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        }

        if (snapshot.hasError) {
          return Container(
            color:
                Theme.of(context).colorScheme.errorContainer.withValues(alpha: 0.3),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.broken_image,
                    size: 24,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'SVG加载失败',
                    style: TextStyle(
                      fontSize: 10,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        return CrossPlatformSvgPicture.fromPath(
          imagePath,
          fit: BoxFit.contain,
          placeholderBuilder: (context) => const Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        );
      },
    );
  }

  /// 验证SVG文件
  Future<void> _validateSvgFile(String path) async {
    try {
      final file = File(path);
      if (!await file.exists()) {
        throw Exception('SVG文件不存在');
      }

      final content = await file.readAsString();
      if (content.trim().isEmpty) {
        throw Exception('SVG文件为空');
      }

      if (!content.toLowerCase().contains('<svg')) {
        throw Exception('不是有效的SVG文件');
      }
    } catch (e) {
      throw Exception('SVG验证失败: $e');
    }
  }

  /// 获取图像尺寸信息
  Future<ImageDimensions?> _getImageDimensions(
      String imagePath, bool isSvg) async {
    try {
      if (isSvg) {
        // 对于SVG文件，解析SVG内容来获取真实尺寸
        return await _parseSvgDimensions(imagePath);
      } else {
        // 对于其他图像格式，使用ImageValidator获取尺寸
        final imageInfo = await ImageValidator.getImageInfo(imagePath);
        if (imageInfo != null) {
          return ImageDimensions(
            width: imageInfo.width,
            height: imageInfo.height,
            isSvg: false,
          );
        }
      }
    } catch (e) {
      // 如果获取尺寸失败，返回null
      debugPrint('获取图像尺寸失败: $e');
    }
    return null;
  }

  /// 解析SVG文件的真实尺寸
  Future<ImageDimensions?> _parseSvgDimensions(String svgPath) async {
    try {
      final file = File(svgPath);
      if (!await file.exists()) {
        return null;
      }

      final svgContent = await file.readAsString();

      // 使用正则表达式解析SVG的width和height属性
      // 支持不同的属性顺序
      final widthRegex = RegExp(r'width="([^"]*)"', caseSensitive: false);
      final heightRegex = RegExp(r'height="([^"]*)"', caseSensitive: false);

      final widthMatch = widthRegex.firstMatch(svgContent);
      final heightMatch = heightRegex.firstMatch(svgContent);

      if (widthMatch != null && heightMatch != null) {
        final widthStr = widthMatch.group(1);
        final heightStr = heightMatch.group(1);

        if (widthStr != null && heightStr != null) {
          // 尝试解析数值，移除可能的单位
          final width =
              double.tryParse(widthStr.replaceAll(RegExp(r'[^0-9.]'), ''));
          final height =
              double.tryParse(heightStr.replaceAll(RegExp(r'[^0-9.]'), ''));

          if (width != null && height != null) {
            return ImageDimensions(
              width: width.round(),
              height: height.round(),
              isSvg: true,
            );
          }
        }
      }

      // 如果无法解析width和height属性，尝试解析viewBox
      final viewBoxRegex = RegExp(r'viewBox="([^"]*)"', caseSensitive: false);
      final viewBoxMatch = viewBoxRegex.firstMatch(svgContent);

      if (viewBoxMatch != null) {
        final viewBoxStr = viewBoxMatch.group(1);
        if (viewBoxStr != null) {
          final values = viewBoxStr.split(RegExp(r'\s+'));
          if (values.length >= 4) {
            final width = double.tryParse(values[2]);
            final height = double.tryParse(values[3]);

            if (width != null && height != null) {
              return ImageDimensions(
                width: width.round(),
                height: height.round(),
                isSvg: true,
              );
            }
          }
        }
      }

      // 如果都无法解析，返回默认值
      return const ImageDimensions(width: 500, height: 500, isSvg: true);
    } catch (e) {
      debugPrint('解析SVG尺寸失败: $e');
      return const ImageDimensions(width: 500, height: 500, isSvg: true);
    }
  }
}
