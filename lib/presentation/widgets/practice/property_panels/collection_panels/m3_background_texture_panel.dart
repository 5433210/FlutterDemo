import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../infrastructure/logging/logger.dart';
import '../../../../../infrastructure/providers/cache_providers.dart'
    as cache_providers;
import '../../../../../infrastructure/providers/storage_providers.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../common/editable_number_field.dart';
import '../../../library/m3_library_picker_dialog.dart';
import '../m3_panel_styles.dart';

/// Material 3 background texture panel for collection content
class M3BackgroundTexturePanel extends ConsumerStatefulWidget {
  final Map<String, dynamic> element;
  final Function(String, dynamic) onPropertyChanged;
  final Function(String, dynamic) onContentPropertyChanged;
  final Function(String, dynamic)? onPropertyUpdateStart;
  final Function(String, dynamic)? onPropertyUpdatePreview;
  final Function(String, dynamic, dynamic)? onPropertyUpdateWithUndo;
  final Function(String, dynamic)? onContentPropertyUpdateStart;
  final Function(String, dynamic)? onContentPropertyUpdatePreview;
  final Function(String, dynamic, dynamic)? onContentPropertyUpdateWithUndo;

  const M3BackgroundTexturePanel({
    Key? key,
    required this.element,
    required this.onPropertyChanged,
    required this.onContentPropertyChanged,
    this.onPropertyUpdateStart,
    this.onPropertyUpdatePreview,
    this.onPropertyUpdateWithUndo,
    this.onContentPropertyUpdateStart,
    this.onContentPropertyUpdatePreview,
    this.onContentPropertyUpdateWithUndo,
  }) : super(key: key);

  @override
  ConsumerState<M3BackgroundTexturePanel> createState() =>
      _M3BackgroundTexturePanelState();
}

class _M3BackgroundTexturePanelState
    extends ConsumerState<M3BackgroundTexturePanel> {
  // 滑块拖动时的原始值
  double? _originalTextureOpacity;

  // 加载纹理图片 - 优化版
  // 使用内存缓存避免重复加载
  // static final Map<String, List<int>> _textureCache = {};
  // 本地状态来跟踪填充模式和适应模式
  String? _localTextureFillMode;
  String? _localTextureFitMode;

  // 🚀 性能优化：纹理查询结果缓存
  static final Map<String, Map<String, dynamic>?> _textureQueryCache = {};
  static String? _lastQueryKey;

  // 🚀 优化：纹理预览构建状态缓存
  static String? _lastPreviewKey;
  static int _previewBuildCount = 0;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final content = widget.element['content'] as Map<String, dynamic>;

    // 生成查询缓存键
    final queryKey = '${widget.element['id']}_${content.hashCode}';

    // 🚀 性能优化：检查缓存避免重复日志输出
    if (_lastQueryKey != queryKey) {
      AppLogger.debug(
        '构建背景纹理面板',
        tag: 'texture_panel',
        data: {
          'elementType': widget.element['type'],
          'contentKeys': content.keys.toList(),
          'hasBackgroundTexture': content.containsKey('backgroundTexture'),
          'backgroundTextureData': content.containsKey('backgroundTexture')
              ? content['backgroundTexture']
              : null,
          'operation': 'build_texture_panel',
        },
      );
      _lastQueryKey = queryKey;
    }

    return _buildBackgroundTextureSubPanel(
        context, content, colorScheme, l10n, textTheme);
  }

  // Build background texture sub-panel with organized controls
  Widget _buildBackgroundTextureSubPanel(
    BuildContext context,
    Map<String, dynamic> content,
    ColorScheme colorScheme,
    AppLocalizations l10n,
    TextTheme textTheme,
  ) {
    // Get texture properties - only background mode is used now
    final textureFillMode = _localTextureFillMode ??
        content['textureFillMode'] as String? ??
        'stretch'; // Default to stretch as specified

    final textureFitMode = content['textureFitMode'] as String? ??
        'fill'; // Default to fill as specified
    final textureOpacity = _getLatestTextureOpacity(content);

    // Get texture size properties (actual pixel values)
    final texture = _findTextureData(content);
    final defaultWidth = texture?['width']?.toDouble() ?? 100.0;
    final defaultHeight = texture?['height']?.toDouble() ?? 100.0;
    final textureWidth =
        (content['textureWidth'] as num?)?.toDouble() ?? defaultWidth;
    final textureHeight =
        (content['textureHeight'] as num?)?.toDouble() ?? defaultHeight;

    return M3PanelStyles.buildPersistentPanelCard(
      context: context,
      panelId: 'background_texture_subpanel',
      title: l10n.backgroundTexture,
      defaultExpanded: false,
      children: [
        // 1. Texture preview and management
        M3PanelStyles.buildSectionTitle(context, l10n.texturePreview),
        Row(
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                border: Border.all(color: colorScheme.outline),
                borderRadius: BorderRadius.circular(8),
              ),
              child: _buildTexturePreview(content),
            ),
            const SizedBox(width: 16.0),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  FilledButton.icon(
                    icon: const Icon(Icons.image),
                    label: Text(l10n.fromGallery),
                    onPressed: () => _selectTexture(
                        context, content, widget.onContentPropertyChanged),
                  ),
                  if (_findTextureData(content) != null)
                    const SizedBox(height: 8.0),
                  if (_findTextureData(content) != null)
                    SizedBox(
                      width: double.infinity,
                      child: TextButton.icon(
                        icon: const Icon(Icons.delete_outline),
                        label: Text(l10n.remove),
                        onPressed: () {
                          AppLogger.info(
                            '用户移除背景纹理',
                            tag: 'texture_panel',
                            data: {
                              'elementId': widget.element['id'],
                              'operation': 'remove_background_texture',
                            },
                          );
                          widget.onContentPropertyChanged(
                              'backgroundTexture', null);
                          setState(() {});
                        },
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 16.0), // 2. Texture Transparency Settings
        M3PanelStyles.buildSectionTitle(context, l10n.textureOpacity),
        Row(
          children: [
            Expanded(
              flex: 3,
              child: Slider(
                value: textureOpacity.clamp(0.0, 1.0),
                min: 0.0,
                max: 1.0,
                divisions: 100,
                label: '${(textureOpacity * 100).round()}%',
                activeColor: colorScheme.primary,
                inactiveColor: colorScheme.surfaceContainerHighest,
                onChangeStart: (value) {
                  // 拖动开始时保存原始值
                  _originalTextureOpacity = textureOpacity;
                  if (widget.onContentPropertyUpdateStart != null) {
                    widget.onContentPropertyUpdateStart!(
                        'textureOpacity', textureOpacity);
                  }
                },
                onChanged: (value) {
                  // 只更新UI状态，不记录undo
                  if (widget.onContentPropertyUpdatePreview != null) {
                    widget.onContentPropertyUpdatePreview!(
                        'textureOpacity', value);
                  } else {
                    _updateTexturePropertyPreview('textureOpacity', value);
                  }
                },
                onChangeEnd: (value) {
                  // 拖动结束时基于原始值记录undo
                  _updateTexturePropertyWithUndo(
                      'textureOpacity', value, _originalTextureOpacity);
                  _originalTextureOpacity = null;
                },
              ),
            ),
            const SizedBox(width: 8.0),
            Expanded(
              flex: 2,
              child: EditableNumberField(
                label: l10n.opacity,
                value: (textureOpacity.clamp(0.0, 1.0) * 100),
                suffix: '%',
                min: 0,
                max: 100,
                decimalPlaces: 0,
                onChanged: (value) {
                  _updateTextureProperty('textureOpacity', value / 100);
                },
              ),
            ),
          ],
        ),

        const SizedBox(height: 16.0),

        // 3. Texture Fill Mode Settings (only repeat, cover, stretch, contain)
        M3PanelStyles.buildSectionTitle(context, l10n.textureFillMode),
        DropdownButton<String>(
          value: textureFillMode,
          isExpanded: true,
          items: [
            DropdownMenuItem(
              value: 'stretch',
              child: Text(l10n.stretch), // Use English fallback for stretch
            ),
            DropdownMenuItem(
              value: 'repeat',
              child: Text(l10n.textureFillModeRepeat),
            ),
            DropdownMenuItem(
              value: 'cover',
              child: Text(l10n.textureFillModeCover),
            ),
            DropdownMenuItem(
              value: 'contain',
              child: Text(l10n.textureFillModeContain),
            ),
          ],
          onChanged: (value) {
            if (value != null) {
              AppLogger.info(
                '纹理填充模式变更',
                tag: 'texture_panel',
                data: {
                  'oldMode': textureFillMode,
                  'newMode': value,
                  'elementId': widget.element['id'],
                  'operation': 'change_texture_fill_mode',
                },
              );

              // Update local state first
              _localTextureFillMode = value;

              _updateTextureProperty('textureFillMode', value);
            }
          },
        ),

        const SizedBox(height: 16.0),

        // 4. Texture Size Settings with restore default button
        M3PanelStyles.buildSectionTitle(context, l10n.textureSize),
        Row(
          children: [
            Expanded(
              child: EditableNumberField(
                label: l10n.width,
                value: textureWidth,
                suffix: 'px',
                min: 1,
                max: 9999,
                decimalPlaces: 0,
                onChanged: (value) {
                  _updateTextureProperty('textureWidth', value);
                },
              ),
            ),
            const SizedBox(width: 8.0),
            Expanded(
              child: EditableNumberField(
                label: l10n.height,
                value: textureHeight,
                suffix: 'px',
                min: 1,
                max: 9999,
                decimalPlaces: 0,
                onChanged: (value) {
                  _updateTextureProperty('textureHeight', value);
                },
              ),
            ),
            const SizedBox(width: 8.0),
            IconButton(
              icon: const Icon(Icons.restore),
              tooltip: l10n.restoreDefaultSize,
              onPressed: () {
                _updateTextureProperty('textureWidth', defaultWidth);
                _updateTextureProperty('textureHeight', defaultHeight);
              },
            ),
          ],
        ),
        const SizedBox(height: 16.0),

        // 5. Texture Fit Mode Settings (scaleToFit, fill, scaleToCover)
        M3PanelStyles.buildSectionTitle(context, l10n.fitMode),
        DropdownButton<String>(
          value: textureFitMode,
          isExpanded: true,
          items: [
            DropdownMenuItem(
              value: 'fill',
              child: Text(l10n.fitFill),
            ),
            DropdownMenuItem(
              value: 'scaleToFit',
              child: Text(l10n
                  .fitContain), // Use contain as closest equivalent to scaleToFit
            ),
            DropdownMenuItem(
              value: 'scaleToCover',
              child: Text(l10n.fitCover), // Use cover for scaleToCover
            ),
          ],
          onChanged: (value) {
            if (value != null) {
              AppLogger.info(
                '纹理适应模式变更',
                tag: 'texture_panel',
                data: {
                  'oldMode': textureFitMode,
                  'newMode': value,
                  'elementId': widget.element['id'],
                  'operation': 'change_texture_fit_mode',
                },
              );
              _localTextureFitMode = value;
              _updateTextureProperty('textureFitMode', value);
            }
          },
        ),
      ],
    );
  }

  // 增强版的纹理预览
  Widget _buildTexturePreview(Map<String, dynamic> content) {
    // 递归查找纹理数据
    final texture = _findTextureData(content);

    // 🚀 优化：减少纹理预览构建的重复日志
    final previewKey = '${texture?.hashCode ?? 'null'}_${content.hashCode}';
    _previewBuildCount++;

    if (_lastPreviewKey != previewKey) {
      AppLogger.debug(
        '构建纹理预览',
        tag: 'texture_panel',
        data: {
          'hasTexture': texture != null,
          'buildCount': _previewBuildCount,
          'changeType':
              _lastPreviewKey == null ? 'first_build' : 'content_changed',
          'operation': 'build_texture_preview',
          'optimization': 'texture_preview_optimized',
        },
      );
      _lastPreviewKey = previewKey;
    } else if (_previewBuildCount % 20 == 0) {
      // 里程碑记录，避免完全静默
      AppLogger.debug(
        '纹理预览构建里程碑',
        tag: 'texture_panel',
        data: {
          'hasTexture': texture != null,
          'buildCount': _previewBuildCount,
          'operation': 'texture_preview_milestone',
        },
      );
    }

    if (texture == null || texture.isEmpty) {
      // 🚀 优化：只在首次或状态变化时记录无纹理信息
      if (_lastPreviewKey != previewKey) {
        AppLogger.debug(
          '无纹理数据',
          tag: 'texture_panel',
          data: {
            'reason': 'no_valid_texture_data',
            'operation': 'texture_preview_empty',
            'optimization': 'no_texture_state_changed',
          },
        );
      }
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.texture_outlined, color: Colors.grey),
            const SizedBox(height: 4),
            Text(AppLocalizations.of(context).noTexture,
                style: const TextStyle(fontSize: 10, color: Colors.grey)),
          ],
        ),
      );
    }

    final textureId = texture['id'] as String?;
    final texturePath = texture['path'] as String?;

    AppLogger.debug(
      '纹理预览数据',
      tag: 'texture_panel',
      data: {
        'textureId': textureId,
        'texturePath': texturePath,
        'operation': 'texture_preview_data',
      },
    );

    if (textureId == null || texturePath == null || texturePath.isEmpty) {
      AppLogger.warning(
        '纹理数据不完整',
        tag: 'texture_panel',
        data: {
          'textureId': textureId,
          'texturePath': texturePath,
          'operation': 'incomplete_texture_data',
        },
      );
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.broken_image_outlined, color: Colors.orange),
            const SizedBox(height: 4),
            Text(AppLocalizations.of(context).dataIncomplete,
                style: const TextStyle(fontSize: 10, color: Colors.orange)),
          ],
        ),
      );
    } // 获取纹理填充模式和应用范围
    final fillMode = _getLatestTextureProperty('textureFillMode', content) ??
        'repeat'; // 由于移除了textureApplicationRange，直接使用background模式
    const applicationRange = 'background';

    // 确定纹理预览的 BoxFit 模式
    BoxFit previewFit;
    switch (fillMode) {
      case 'contain':
        previewFit = BoxFit.contain;
        break;
      case 'cover':
        previewFit = BoxFit.cover;
        break;
      case 'noRepeat':
        previewFit = BoxFit.none;
        break;
      case 'repeat':
      case 'repeatX':
      case 'repeatY':
      default:
        // 对于重复模式，使用 cover 以便于预览
        previewFit = BoxFit.cover;
        break;
    }

    AppLogger.debug(
      '纹理预览配置',
      tag: 'texture_panel',
      data: {
        'fillMode': fillMode,
        'applicationRange': applicationRange,
        'previewFit': previewFit.toString(),
        'operation': 'texture_preview_config',
      },
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Stack(
        children: [
          // 纹理图像
          FutureBuilder<List<int>>(
            future: _loadTextureImage(texturePath),
            builder: (context, snapshot) {
              // 获取最新的纹理不透明度
              final textureOpacity = _getLatestTextureOpacity(content);

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                );
              }

              if (snapshot.hasError) {
                AppLogger.error(
                  '纹理加载失败',
                  tag: 'texture_panel',
                  error: snapshot.error,
                  data: {
                    'texturePath': texturePath,
                    'operation': 'texture_load_error',
                  },
                );
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline,
                          color: Colors.red, size: 18),
                      const SizedBox(height: 4),
                      Text(AppLocalizations.of(context).loadFailed,
                          style:
                              const TextStyle(fontSize: 10, color: Colors.red)),
                    ],
                  ),
                );
              }

              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                AppLogger.warning(
                  '纹理数据为空',
                  tag: 'texture_panel',
                  data: {
                    'texturePath': texturePath,
                    'operation': 'texture_data_empty',
                  },
                );
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.image_not_supported,
                          color: Colors.orange, size: 18),
                      const SizedBox(height: 4),
                      Text(AppLocalizations.of(context).dataEmpty,
                          style: const TextStyle(
                              fontSize: 10, color: Colors.orange)),
                    ],
                  ),
                );
              }

              AppLogger.info(
                '纹理加载成功',
                tag: 'texture_panel',
                data: {
                  'texturePath': texturePath,
                  'dataLength': snapshot.data!.length,
                  'opacity': textureOpacity,
                  'operation': 'texture_load_success',
                },
              );

              return Opacity(
                opacity: textureOpacity.clamp(0.0, 1.0),
                child: Image.memory(
                  Uint8List.fromList(snapshot.data!),
                  fit: previewFit,
                  width: double.infinity,
                  height: double.infinity,
                  errorBuilder: (context, error, stackTrace) {
                    AppLogger.error(
                      '纹理渲染失败',
                      tag: 'texture_panel',
                      error: error,
                      stackTrace: stackTrace,
                      data: {
                        'texturePath': texturePath,
                        'operation': 'texture_render_error',
                      },
                    );
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.image_not_supported,
                              color: Colors.red, size: 18),
                          const SizedBox(height: 4),
                          Text(AppLocalizations.of(context).renderFailed,
                              style: const TextStyle(
                                  fontSize: 10, color: Colors.red)),
                        ],
                      ),
                    );
                  },
                ),
              );
            },
          ),

          // 填充模式指示器叠加层
          Positioned(
            top: 4,
            right: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    fillMode == 'repeat'
                        ? 'REP'
                        : fillMode == 'contain'
                            ? 'CON'
                            : fillMode == 'cover'
                                ? 'COV'
                                : 'STR',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 2),
                  Icon(
                    fillMode == 'repeat'
                        ? Icons.grid_4x4
                        : fillMode == 'contain'
                            ? Icons.fit_screen
                            : fillMode == 'cover'
                                ? Icons.crop
                                : Icons.texture,
                    color: Colors.white,
                    size: 10,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 🚀 性能优化：带缓存的纹理数据查找
  Map<String, dynamic>? _findTextureData(Map<String, dynamic> content) {
    // 生成缓存键
    final cacheKey = content.hashCode.toString();

    // 检查缓存
    if (_textureQueryCache.containsKey(cacheKey)) {
      final cachedResult = _textureQueryCache[cacheKey];
      if (cachedResult != null) {
        AppLogger.info(
          '使用纹理查询缓存',
          tag: 'texture_panel',
          data: {
            'cacheKey': cacheKey,
            'textureId': cachedResult['id'],
            'optimization': 'texture_query_cache_hit',
          },
        );
      }
      return cachedResult;
    }

    // 缓存未命中，执行查询
    Map<String, dynamic>? result;

    // 检查参数是否有效 - 只在content级别查找backgroundTexture
    if (content.containsKey('backgroundTexture') &&
        content['backgroundTexture'] != null &&
        content['backgroundTexture'] is Map<String, dynamic> &&
        (content['backgroundTexture'] as Map<String, dynamic>).isNotEmpty) {
      final texData = content['backgroundTexture'] as Map<String, dynamic>;

      // 确保纹理数据包含必要的字段
      if (texData.containsKey('path') && texData.containsKey('id')) {
        AppLogger.debug(
          '找到有效纹理数据',
          tag: 'texture_panel',
          data: {
            'textureId': texData['id'],
            'texturePath': texData['path'],
            'operation': 'find_valid_texture_data',
          },
        );
        result = texData;
      } else {
        AppLogger.warning(
          '纹理数据不完整',
          tag: 'texture_panel',
          data: {
            'textureData': texData,
            'operation': 'incomplete_texture_data',
          },
        );
      }
    }

    // 如果当前层没有背景纹理，但有嵌套内容，则递归查找
    if (result == null &&
        content.containsKey('content') &&
        content['content'] != null &&
        content['content'] is Map<String, dynamic>) {
      AppLogger.debug(
        '递归搜索嵌套内容',
        tag: 'texture_panel',
        data: {
          'operation': 'recursive_texture_search',
        },
      );
      result = _findTextureData(content['content'] as Map<String, dynamic>);
    }

    // 缓存查询结果（包括null结果）
    _textureQueryCache[cacheKey] = result;

    // 限制缓存大小，避免内存泄漏
    if (_textureQueryCache.length > 50) {
      final oldestKey = _textureQueryCache.keys.first;
      _textureQueryCache.remove(oldestKey);
    }

    if (result == null) {
      AppLogger.debug(
        '未找到纹理数据',
        tag: 'texture_panel',
        data: {
          'operation': 'texture_data_not_found',
        },
      );
    }

    return result;
  }

  // 获取最新的纹理不透明度
  double _getLatestTextureOpacity(Map<String, dynamic> content) {
    // 递归查找纹理不透明度
    double? findOpacity(Map<String, dynamic> data) {
      if (data.containsKey('textureOpacity')) {
        return (data['textureOpacity'] as num?)?.toDouble();
      }
      if (data.containsKey('content') &&
          data['content'] is Map<String, dynamic>) {
        return findOpacity(data['content'] as Map<String, dynamic>);
      }
      return null;
    }

    final opacity = findOpacity(content) ?? 1.0; // 默认为100%不透明度
    // 允许完全不透明度，范围从0到1
    return opacity.clamp(0.0, 1.0);
  }

  // 获取最新的纹理属性（支持本地状态覆盖）
  String? _getLatestTextureProperty(
      String property, Map<String, dynamic> content) {
    // 优先使用本地状态
    if (property == 'textureFillMode' && _localTextureFillMode != null) {
      return _localTextureFillMode;
    }
    if (property == 'textureFitMode' && _localTextureFitMode != null) {
      return _localTextureFitMode;
    }

    // 递归查找纹理相关属性
    String? findProperty(Map<String, dynamic> data) {
      if (data.containsKey(property)) {
        return data[property] as String?;
      }
      if (data.containsKey('content') &&
          data['content'] is Map<String, dynamic>) {
        return findProperty(data['content'] as Map<String, dynamic>);
      }
      return null;
    }

    return findProperty(content);
  }

  // 缓存优化版加载纹理图片方法
  Future<List<int>> _loadTextureImage(String path) async {
    // 使用路径作为缓存键
    final cacheKey = path;

    // 首先检查内存缓存
    // if (_textureCache.containsKey(cacheKey)) {
    //   logger.debug(
    //     '从内存缓存加载纹理',
    //     data: {
    //       'cacheKey': cacheKey,
    //       'operation': 'load_texture_from_memory_cache',
    //     },
    //     tags: ['texture', 'cache'],
    //   );
    //   return _textureCache[cacheKey]!;
    // }

    try {
      final storageService = ref.read(initializedStorageProvider);
      final imageCacheService = ref.read(imageCacheServiceProvider);

      // final imageBytes = await imageCacheService.getBinaryImage(cacheKey);
      // if (imageBytes != null) {
      //   logger.debug(
      //     '从缓存加载纹理图片',
      //     data: {
      //       'path': path,
      //       'operation': 'load_texture_from_cache',
      //     },
      //     tags: ['texture', 'cache'],
      //   );
      //   return imageBytes;
      // }

      AppLogger.debug(
        '从存储加载纹理图片',
        tag: 'texture_panel',
        data: {
          'path': path,
          'operation': 'load_texture_from_storage',
        },
      );
      final imageBytesFromStorage = await storageService.readFile(path);

      if (imageBytesFromStorage.isNotEmpty) {
        // 缓存到内存
        final decodedImage = await imageCacheService
            .decodeImageFromBytes(Uint8List.fromList(imageBytesFromStorage));
        if (decodedImage != null) {
          imageCacheService.cacheUiImage(cacheKey, decodedImage);
        }
        AppLogger.info(
          '纹理图片加载成功',
          tag: 'texture_panel',
          data: {
            'path': path,
            'dataSize': imageBytesFromStorage.length,
            'operation': 'texture_load_success',
          },
        );
        return imageBytesFromStorage;
      } else {
        throw Exception('图片文件为空');
      }
    } catch (e) {
      AppLogger.error(
        '纹理图片加载失败',
        tag: 'texture_panel',
        error: e,
        data: {
          'path': path,
          'operation': 'texture_load_failed',
        },
      );
      throw Exception('无法加载纹理图片: $e');
    }
  }

  // 完全重写的选择纹理方法 - 防止嵌套问题
  Future<void> _selectTexture(
    BuildContext context,
    Map<String, dynamic> content,
    Function(String, dynamic) onContentPropertyChanged,
  ) async {
    final l10n = AppLocalizations.of(context);
    AppLogger.info(
      '打开纹理选择对话框',
      tag: 'texture_panel',
      data: {
        'elementId': widget.element['id'],
        'operation': 'open_texture_selection_dialog',
      },
    );

    // 打开选择对话框
    final selectedTexture = await M3LibraryPickerDialog.show(
      context,
      title: l10n.fromGallery,
    );

    // 如果用户取消了选择，直接返回
    if (selectedTexture == null) {
      AppLogger.info(
        '用户取消纹理选择',
        tag: 'texture_panel',
        data: {
          'operation': 'texture_selection_cancelled',
        },
      );
      return;
    }

    AppLogger.info(
      '用户选择纹理',
      tag: 'texture_panel',
      data: {
        'selectedTextureId': selectedTexture.id,
        'selectedTexturePath': selectedTexture.path,
        'textureWidth': selectedTexture.width,
        'textureHeight': selectedTexture.height,
        'operation': 'texture_selected',
      },
    );

    try {
      // 创建纹理数据对象
      final textureData = {
        'id': selectedTexture.id,
        'path': selectedTexture.path,
        'width': selectedTexture.width,
        'height': selectedTexture.height,
        'type': selectedTexture.type,
        'format': selectedTexture.format,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };

      // 获取元素的完整内容
      final elementContent = widget.element['content'] as Map<String, dynamic>?;
      if (elementContent == null) {
        AppLogger.error(
          '元素内容为空，无法应用纹理',
          tag: 'texture_panel',
          data: {
            'elementId': widget.element['id'],
            'operation': 'apply_texture_failed_no_content',
          },
        );
        return;
      }

      // 创建全新的内容对象而不是修改现有对象，以避免任何引用问题
      final newContent = <String, dynamic>{};

      // 复制所有属性
      for (final key in elementContent.keys) {
        newContent[key] = elementContent[key];
      } // 添加纹理数据和相关属性
      newContent['backgroundTexture'] = textureData;
      newContent['textureFillMode'] =
          elementContent['textureFillMode'] ?? 'stretch';
      newContent['textureFitMode'] = elementContent['textureFitMode'] ?? 'fill';
      newContent['textureOpacity'] = elementContent['textureOpacity'] ?? 1.0;
      newContent['textureWidth'] = selectedTexture.width;
      newContent['textureHeight'] = selectedTexture.height;

      // 注意：不再在characterImages中存储背景纹理数据
      // characterImages应该只包含角色相关的图像，不包含背景纹理信息

      AppLogger.info(
        '应用纹理数据到元素',
        tag: 'texture_panel',
        data: {
          'elementId': widget.element['id'],
          'textureId': selectedTexture.id,
          'texturePath': selectedTexture.path,
          'contentKeys': newContent.keys.toList(),
          'operation': 'apply_texture_data',
        },
      );

      // 尝试多种更新方式以确保更新生效
      AppLogger.debug(
        '使用onPropertyChanged更新内容',
        tag: 'texture_panel',
        data: {
          'operation': 'update_content_via_property_changed',
        },
      );
      widget.onPropertyChanged('content', newContent);

      // 等待一下，确保第一次更新已处理
      await Future.delayed(const Duration(milliseconds: 50));

      AppLogger.debug(
        '使用onContentPropertyChanged作为备选方案',
        tag: 'texture_panel',
        data: {
          'operation': 'update_content_via_content_property_changed',
        },
      );
      onContentPropertyChanged('content', newContent);

      // // 清空缓存，强制重新加载纹理
      // _textureCache.clear();
      // logger.debug(
      //   '清空本地纹理缓存',
      //   data: {
      //     'operation': 'clear_local_texture_cache',
      //   },
      //   tags: ['texture', 'cache'],
      // );

      // 清除全局图像缓存
      try {
        final imageCacheService =
            ref.read(cache_providers.imageCacheServiceProvider);
        await imageCacheService.clearAll();
        AppLogger.info(
          '清除全局图像缓存',
          tag: 'texture_panel',
          data: {
            'operation': 'clear_global_image_cache',
          },
        );
      } catch (e) {
        AppLogger.warning(
          '清除全局缓存失败',
          tag: 'texture_panel',
          error: e,
          data: {
            'operation': 'clear_global_cache_failed',
          },
        );
      }

      AppLogger.info(
        '纹理应用完成',
        tag: 'texture_panel',
        data: {
          'elementId': widget.element['id'],
          'operation': 'texture_application_complete',
        },
      );

      // 强制刷新UI
      setState(() {});
    } catch (e) {
      AppLogger.error(
        '应用纹理时发生错误',
        tag: 'texture_panel',
        error: e,
        data: {
          'elementId': widget.element['id'],
          'selectedTextureId': selectedTexture.id,
          'operation': 'apply_texture_error',
        },
      );
    }
  }

  /// 更新纹理属性并确保更新整个内容对象
  void _updateTextureProperty(String propertyName, dynamic value) async {
    try {
      AppLogger.debug(
        '更新纹理属性',
        tag: 'texture_panel',
        data: {
          'propertyName': propertyName,
          'newValue': value,
          'elementId': widget.element['id'],
          'operation': 'update_texture_property',
        },
      );

      // 获取当前内容
      final originalContent = widget.element['content'] as Map<String, dynamic>;

      // 输出原始内容的属性信息
      AppLogger.debug(
        '更新前的内容属性',
        tag: 'texture_panel',
        data: {
          'propertyName': propertyName,
          'oldValue': originalContent[propertyName],
          'operation': 'texture_property_before_update',
        },
      );

      // 创建全新的内容对象而不是修改现有对象，以避免任何引用问题
      final content = <String, dynamic>{};

      // 复制所有属性
      for (final key in originalContent.keys) {
        content[key] = originalContent[key];
      } // 更新指定属性
      content[propertyName] = value;

      // 注意：不再同步更新characterImages中的纹理属性
      // characterImages应该只包含角色相关的图像，不包含背景纹理信息

      // 应用更新 - 正确调用onPropertyChanged更新整个content
      AppLogger.debug(
        '使用onPropertyChanged更新整个content对象',
        tag: 'texture_panel',
        data: {
          'propertyName': propertyName,
          'operation': 'update_content_object',
        },
      );
      widget.onPropertyChanged('content', content);

      // 等待一下，确保更新已处理
      await Future.delayed(const Duration(milliseconds: 50));

      // 输出更新后的内容信息
      AppLogger.info(
        '纹理属性更新完成',
        tag: 'texture_panel',
        data: {
          'propertyName': propertyName,
          'newValue': value,
          'elementId': widget.element['id'],
          'operation': 'texture_property_update_complete',
        },
      );

      // 确认更新是否生效 - 获取更新后的内容进行检查
      Future.delayed(Duration.zero, () {
        final updatedContent =
            widget.element['content'] as Map<String, dynamic>?;
        if (updatedContent != null) {
          final isUpdateSuccessful = updatedContent[propertyName] == value;
          AppLogger.debug(
            '纹理属性更新验证',
            tag: 'texture_panel',
            data: {
              'propertyName': propertyName,
              'expectedValue': value,
              'actualValue': updatedContent[propertyName],
              'updateSuccessful': isUpdateSuccessful,
              'operation': 'texture_property_update_verification',
            },
          );
        }
      });

      // 更新本地状态（如果需要）
      if (propertyName == 'textureFillMode') {
        _localTextureFillMode = value as String?;
      } else if (propertyName == 'textureFitMode') {
        _localTextureFitMode = value as String?;
      }

      // 刷新UI
      setState(() {});
    } catch (e) {
      AppLogger.error(
        '更新纹理属性时发生错误',
        tag: 'texture_panel',
        error: e,
        data: {
          'propertyName': propertyName,
          'value': value,
          'elementId': widget.element['id'],
          'operation': 'update_texture_property_error',
        },
      );
    }
  }

  /// 基于原始值更新纹理属性并记录undo操作（用于滑块拖动结束）
  void _updateTexturePropertyWithUndo(
      String propertyName, dynamic newValue, dynamic originalValue) {
    // 优先使用主面板提供的撤销回调
    if (widget.onContentPropertyUpdateWithUndo != null) {
      widget.onContentPropertyUpdateWithUndo!(
          propertyName, newValue, originalValue);
    } else {
      // 备用方案：如果有原始值且值发生了变化，使用主面板的撤销机制
      if (originalValue != null && originalValue != newValue) {
        // 先调用开始回调保存原始值
        if (widget.onContentPropertyUpdateStart != null) {
          widget.onContentPropertyUpdateStart!(propertyName, originalValue);
        }

        // 然后使用正常的更新方法更新到最终值
        _updateTextureProperty(propertyName, newValue);
      } else {
        // 值没有变化，直接调用正常的更新方法
        _updateTextureProperty(propertyName, newValue);
      }
    }
  }

  /// 仅预览更新纹理属性，不记录undo（用于滑块拖动过程中的实时预览）
  void _updateTexturePropertyPreview(String propertyName, dynamic value) {
    try {
      // 获取当前内容
      final originalContent = widget.element['content'] as Map<String, dynamic>;

      // 创建全新的内容对象
      final content = <String, dynamic>{};

      // 复制所有属性
      for (final key in originalContent.keys) {
        content[key] = originalContent[key];
      }

      // 更新指定属性
      content[propertyName] = value;

      // 只更新UI，不记录undo - 直接更新本地状态和UI
      if (propertyName == 'textureOpacity') {
        // 直接更新UI状态，不调用onPropertyChanged避免记录undo
        setState(() {
          // 本地状态会在下次widget更新时同步
        });

        // 通过临时的属性回调来更新画布预览，但不记录到历史栈
        final tempElement = Map<String, dynamic>.from(widget.element);
        tempElement['content'] = content;
        widget.onPropertyChanged('_preview_content', content); // 使用特殊前缀标识这是预览更新
      }
    } catch (e) {
      AppLogger.error('预览纹理属性更新失败', tag: 'texture_panel', error: e);
    }
  }
}
