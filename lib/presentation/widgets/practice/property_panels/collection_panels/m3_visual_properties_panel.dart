import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../infrastructure/providers/storage_providers.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../common/editable_number_field.dart';
import '../../../common/m3_color_picker.dart';
import '../../../library/m3_library_picker_dialog.dart';
import '../m3_panel_styles.dart';
import 'm3_collection_color_utils.dart';

/// Material 3 visual properties panel for collection content
class M3VisualPropertiesPanel extends ConsumerStatefulWidget {
  final Map<String, dynamic> element;
  final Function(String, dynamic) onPropertyChanged;
  final Function(String, dynamic) onContentPropertyChanged;

  const M3VisualPropertiesPanel({
    Key? key,
    required this.element,
    required this.onPropertyChanged,
    required this.onContentPropertyChanged,
  }) : super(key: key);

  @override
  ConsumerState<M3VisualPropertiesPanel> createState() =>
      _M3VisualPropertiesPanelState();
}

class _M3VisualPropertiesPanelState
    extends ConsumerState<M3VisualPropertiesPanel> {
  // 加载纹理图片 - 优化版
  // 使用内存缓存避免重复加载
  static final Map<String, List<int>> _textureCache = {};

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final opacity = (widget.element['opacity'] as num?)?.toDouble() ?? 1.0;
    final content = widget.element['content'] as Map<String, dynamic>;
    final fontColor = content['fontColor'] as String? ?? '#000000';
    final backgroundColor =
        content['backgroundColor'] as String? ?? 'transparent';
    final padding = (content['padding'] as num?)?.toDouble() ?? 0.0;
    final enableSoftLineBreak =
        content['enableSoftLineBreak'] as bool? ?? false;
    final textureApplicationRange =
        content['textureApplicationRange'] as String? ?? 'characterBackground';
    final textureFillMode = content['textureFillMode'] as String? ?? 'repeat';

    return M3PanelStyles.buildPanelCard(
      context: context,
      title: l10n.visualSettings,
      initiallyExpanded: true,
      children: [
        // Color settings
        M3PanelStyles.buildSectionTitle(
            context, l10n.collectionPropertyPanelColorSettings),
        Row(
          children: [
            Text(
              '${l10n.textPropertyPanelFontColor}:',
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 8.0),
            InkWell(
              onTap: () async {
                final color = await M3ColorPicker.show(
                  context,
                  initialColor: CollectionColorUtils.hexToColor(fontColor),
                  enableAlpha: true,
                  enableColorCode: true,
                );
                if (color != null) {
                  widget.onContentPropertyChanged(
                      'fontColor', CollectionColorUtils.colorToHex(color));
                }
              },
              borderRadius: BorderRadius.circular(8),
              child: Ink(
                decoration: BoxDecoration(
                  color: CollectionColorUtils.hexToColor(fontColor),
                  border: Border.all(color: colorScheme.outline),
                  borderRadius: BorderRadius.circular(8),
                ),
                width: 40,
                height: 40,
              ),
            ),
            const SizedBox(width: 16.0),
            Text(
              '${l10n.backgroundColor}:',
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 8.0),
            InkWell(
              onTap: () async {
                final color = await M3ColorPicker.show(
                  context,
                  initialColor:
                      CollectionColorUtils.hexToColor(backgroundColor),
                  enableAlpha: true,
                  enableColorCode: true,
                );
                if (color != null) {
                  widget.onContentPropertyChanged('backgroundColor',
                      CollectionColorUtils.colorToHex(color));
                }
              },
              borderRadius: BorderRadius.circular(8),
              child: Ink(
                decoration: BoxDecoration(
                  color: CollectionColorUtils.hexToColor(backgroundColor),
                  border: Border.all(color: colorScheme.outline),
                  borderRadius: BorderRadius.circular(8),
                ),
                width: 40,
                height: 40,
              ),
            ),
          ],
        ),

        const SizedBox(height: 16.0),

        // Opacity
        M3PanelStyles.buildSectionTitle(context, l10n.opacity),
        Row(
          children: [
            Expanded(
              flex: 3,
              child: Slider(
                value: opacity,
                min: 0.0,
                max: 1.0,
                divisions: 100,
                label: '${(opacity * 100).round()}%',
                activeColor: colorScheme.primary,
                inactiveColor: colorScheme.surfaceContainerHighest,
                onChanged: (value) {
                  widget.onPropertyChanged('opacity', value);
                },
              ),
            ),
            const SizedBox(width: 8.0),
            Expanded(
              flex: 2,
              child: EditableNumberField(
                label: l10n.opacity,
                value: opacity * 100,
                suffix: '%',
                min: 0,
                max: 100,
                decimalPlaces: 0,
                onChanged: (value) {
                  widget.onPropertyChanged('opacity', value / 100);
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16.0),

        // Background Texture Settings
        if (content.containsKey('backgroundTexture')) ...[
          M3PanelStyles.buildSectionTitle(
              context, l10n.textureApplicationRange),
          SegmentedButton<String>(
            segments: [
              const ButtonSegment<String>(
                value: 'characterBackground',
                label: Text('字符背景'),
                icon: Icon(Icons.text_fields),
              ),
              ButtonSegment<String>(
                value: 'background',
                label: Text(l10n.textureRangeBackground),
                icon: const Icon(Icons.crop_free),
              ),
            ],
            selected: {textureApplicationRange},
            onSelectionChanged: (selection) {
              widget.onContentPropertyChanged(
                  'textureApplicationRange', selection.first);
            },
          ),
          const SizedBox(height: 16.0),
          M3PanelStyles.buildSectionTitle(context, l10n.textureFillMode),
          DropdownButton<String>(
            value: textureFillMode,
            isExpanded: true,
            items: [
              DropdownMenuItem(
                value: 'repeat',
                child: Text(l10n.textureFillModeRepeat),
              ),
              DropdownMenuItem(
                value: 'repeatX',
                child: Text(l10n.textureFillModeRepeatX),
              ),
              DropdownMenuItem(
                value: 'repeatY',
                child: Text(l10n.textureFillModeRepeatY),
              ),
              DropdownMenuItem(
                value: 'noRepeat',
                child: Text(l10n.textureFillModeNoRepeat),
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
                widget.onContentPropertyChanged('textureFillMode', value);
              }
            },
          ),
        ],

        // Texture preview and select button
        const SizedBox(height: 16.0),
        Row(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                border: Border.all(color: colorScheme.outline),
                borderRadius: BorderRadius.circular(8),
              ),
              child: _buildTexturePreview(content),
            ),
            const SizedBox(width: 16.0),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FilledButton.icon(
                  icon: const Icon(Icons.image),
                  label: Text(l10n.textureSelectFromLibrary),
                  onPressed: () => _selectTexture(
                      context, content, widget.onContentPropertyChanged),
                ),
                if (content.containsKey('backgroundTexture'))
                  const SizedBox(height: 8.0),
                if (content.containsKey('backgroundTexture'))
                  TextButton.icon(
                    icon: const Icon(Icons.delete_outline),
                    label: Text(l10n.textureRemove),
                    onPressed: () {
                      debugPrint('✨ 尝试移除背景纹理');
                      widget.onContentPropertyChanged(
                          'backgroundTexture', null);
                      setState(() {});
                    },
                  ),
              ],
            ),
          ],
        ),

        const SizedBox(height: 16.0),

        // Padding
        M3PanelStyles.buildSectionTitle(context, l10n.textPropertyPanelPadding),
        Row(
          children: [
            Expanded(
              flex: 3,
              child: Slider(
                value: padding,
                min: 0,
                max: 50,
                divisions: 50,
                label: '${padding.round()}px',
                activeColor: colorScheme.primary,
                inactiveColor: colorScheme.surfaceContainerHighest,
                onChanged: (value) {
                  widget.onContentPropertyChanged('padding', value);
                },
              ),
            ),
            const SizedBox(width: 8.0),
            Expanded(
              flex: 2,
              child: EditableNumberField(
                label: l10n.textPropertyPanelPadding,
                value: padding,
                suffix: 'px',
                min: 0,
                max: 100,
                decimalPlaces: 0,
                onChanged: (value) {
                  widget.onContentPropertyChanged('padding', value);
                },
              ),
            ),
          ],
        ),

        const SizedBox(height: 16.0),

        // Auto line break
        M3PanelStyles.buildSectionTitle(
            context, l10n.collectionPropertyPanelAutoLineBreak),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Switch(
              value: enableSoftLineBreak,
              activeColor: colorScheme.primary,
              onChanged: (value) {
                widget.onContentPropertyChanged('enableSoftLineBreak', value);
              },
            ),
            const SizedBox(width: 8.0),
            Text(
              enableSoftLineBreak
                  ? l10n.collectionPropertyPanelAutoLineBreakEnabled
                  : l10n.collectionPropertyPanelAutoLineBreakDisabled,
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const Spacer(),
            Tooltip(
              message: l10n.collectionPropertyPanelAutoLineBreakTooltip,
              child: Icon(
                Icons.info_outline,
                size: 16.0,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // 增强版的纹理预览
  Widget _buildTexturePreview(Map<String, dynamic> content) {
    // 递归查找纹理数据
    final texture = _findTextureData(content);

    debugPrint('纹理预览检查: 找到纹理=${texture != null}');

    if (texture == null || texture.isEmpty) {
      debugPrint('未检测到纹理：没有找到有效的 backgroundTexture 数据');
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.texture_outlined, color: Colors.grey),
            SizedBox(height: 4),
            Text('无纹理', style: TextStyle(fontSize: 10, color: Colors.grey)),
          ],
        ),
      );
    }

    final textureId = texture['id'] as String?;
    final texturePath = texture['path'] as String?;

    debugPrint('纹理数据: id=$textureId, path=$texturePath');

    if (textureId == null || texturePath == null || texturePath.isEmpty) {
      debugPrint('纹理数据不完整: id=$textureId, path=$texturePath');
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.broken_image_outlined, color: Colors.orange),
            SizedBox(height: 4),
            Text('数据不完整', style: TextStyle(fontSize: 10, color: Colors.orange)),
          ],
        ),
      );
    }

    // 获取纹理填充模式和应用范围
    final fillMode =
        _getLatestTextureProperty('textureFillMode', content) ?? 'repeat';
    final applicationRange =
        _getLatestTextureProperty('textureApplicationRange', content) ??
            'character';

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

    debugPrint(
        '纹理样式: 填充模式=$fillMode, 应用范围=$applicationRange, 预览适应方式=$previewFit');

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
                debugPrint('加载纹理失败: ${snapshot.error}');
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, color: Colors.red, size: 18),
                      SizedBox(height: 4),
                      Text('加载失败',
                          style: TextStyle(fontSize: 10, color: Colors.red)),
                    ],
                  ),
                );
              }

              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                debugPrint('纹理数据为空');
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.image_not_supported,
                          color: Colors.orange, size: 18),
                      SizedBox(height: 4),
                      Text('数据为空',
                          style: TextStyle(fontSize: 10, color: Colors.orange)),
                    ],
                  ),
                );
              }

              debugPrint(
                  '纹理加载成功, 图片数据长度: ${snapshot.data!.length}, 不透明度: $textureOpacity');
              return Opacity(
                opacity: textureOpacity,
                child: Image.memory(
                  Uint8List.fromList(snapshot.data!),
                  fit: previewFit,
                  width: double.infinity,
                  height: double.infinity,
                  errorBuilder: (context, error, stackTrace) {
                    debugPrint('渲染纹理失败: $error');
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.image_not_supported,
                              color: Colors.red, size: 18),
                          SizedBox(height: 4),
                          Text('渲染失败',
                              style:
                                  TextStyle(fontSize: 10, color: Colors.red)),
                        ],
                      ),
                    );
                  },
                ),
              );
            },
          ),

          // 右下角显示填充模式标识
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(2),
              color: Colors.black.withOpacity(0.5),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    applicationRange == 'character'
                        ? Icons.text_fields
                        : Icons.crop_free,
                    color: Colors.white,
                    size: 10,
                  ),
                  const SizedBox(width: 2),
                  Icon(
                    fillMode == 'repeat'
                        ? Icons.grid_on
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

  // 递归查找纹理数据
  Map<String, dynamic>? _findTextureData(Map<String, dynamic> content) {
    // 首先检查当前层是否有背景纹理
    if (content.containsKey('backgroundTexture') &&
        content['backgroundTexture'] != null &&
        content['backgroundTexture'] is Map<String, dynamic>) {
      return content['backgroundTexture'] as Map<String, dynamic>;
    }

    // 如果当前层没有背景纹理，但有嵌套内容，则递归查找
    if (content.containsKey('content') &&
        content['content'] != null &&
        content['content'] is Map<String, dynamic>) {
      return _findTextureData(content['content'] as Map<String, dynamic>);
    }

    // 如果没有找到任何纹理数据，返回null
    return null;
  }

  // 获取最新的纹理不透明度值
  double _getLatestTextureOpacity(Map<String, dynamic> localContent) {
    if (widget.element['content'] != null &&
        (widget.element['content'] as Map<String, dynamic>)
            .containsKey('textureOpacity')) {
      final value =
          (widget.element['content'] as Map<String, dynamic>)['textureOpacity'];
      if (value is num) {
        return value.toDouble();
      }
    }

    final value = localContent['textureOpacity'];
    if (value is num) {
      return value.toDouble();
    }

    return 1.0;
  }

  // 获取最新的纹理属性值
  String? _getLatestTextureProperty(
      String propertyName, Map<String, dynamic> localContent) {
    if (widget.element['content'] != null &&
        (widget.element['content'] as Map<String, dynamic>)
            .containsKey(propertyName)) {
      final value =
          (widget.element['content'] as Map<String, dynamic>)[propertyName];
      return value is String ? value : value?.toString();
    }

    final value = localContent[propertyName];
    return value is String ? value : value?.toString();
  }

  Future<List<int>> _loadTextureImage(String path) async {
    debugPrint('加载纹理图片: $path');

    // 检查内存缓存
    final cacheKey = path.split('/').last;
    if (_textureCache.containsKey(cacheKey)) {
      debugPrint(
          '✅ 从内存缓存加载纹理: $cacheKey, 大小: ${_textureCache[cacheKey]!.length} 字节');
      return _textureCache[cacheKey]!;
    }

    try {
      final storage = ref.read(initializedStorageProvider);

      // 更详细的日志信息帮助调试
      debugPrint('存储服务: ${storage.runtimeType}');
      debugPrint('应用数据路径: ${storage.getAppDataPath()}');

      // 直接尝试完整路径 - 这是日志中显示的路径
      if (path.contains('C:\\Users')) {
        final exists = await storage.fileExists(path);
        if (exists) {
          final imageBytes = await storage.readFile(path);
          debugPrint('✅ 成功从完整路径加载纹理: $path, 大小: ${imageBytes.length} 字节');
          _textureCache[cacheKey] = imageBytes; // 缓存结果
          return imageBytes;
        }
      }

      // 尝试多种路径格式
      final List<String> pathsToTry = [
        path, // 原始路径
        path.startsWith('/') ? path : '/$path', // 绝对路径
        !path.startsWith('/')
            ? '${storage.getAppDataPath()}/$path'
            : path, // 带应用数据路径
        '${storage.getAppDataPath()}/library/${path.split('/').last}', // 库目录路径
      ];

      // 记录所有尝试的路径
      debugPrint('将尝试以下路径: $pathsToTry');

      // 尝试所有可能的路径
      for (final tryPath in pathsToTry) {
        final exists = await storage.fileExists(tryPath);
        debugPrint('尝试路径: $tryPath, 存在: $exists');

        if (exists) {
          final imageBytes = await storage.readFile(tryPath);
          debugPrint('✅ 成功从 $tryPath 加载纹理, 大小: ${imageBytes.length} 字节');
          _textureCache[cacheKey] = imageBytes; // 缓存结果
          return imageBytes;
        }
      }

      // 如果所有直接路径都失败，尝试在库目录中查找文件名相似的文件
      try {
        final libraryDir = '${storage.getAppDataPath()}/library';
        final dirContents = await storage.listDirectoryFiles(libraryDir);
        debugPrint('库目录内容: $libraryDir - $dirContents');

        final fileName = path.split('/').last.toLowerCase();
        final fileId = path.split('/').last.split('.').first.toLowerCase();

        // 遍历库目录中的文件，查找文件名相似的
        for (final file in dirContents) {
          final fileBaseName = file.split('/').last.toLowerCase();
          if (fileBaseName.contains(fileName) ||
              fileName.contains(fileBaseName) ||
              fileBaseName.contains(fileId) ||
              fileId.contains(fileBaseName)) {
            debugPrint('找到可能匹配的文件: $file');
            try {
              final fullPath = '$libraryDir/${file.split('/').last}';
              final imageBytes = await storage.readFile(fullPath);
              debugPrint('✅ 使用匹配文件成功加载纹理, 大小: ${imageBytes.length} 字节');
              _textureCache[cacheKey] = imageBytes; // 缓存结果
              return imageBytes;
            } catch (fileError) {
              debugPrint('尝试加载匹配文件失败: $fileError');
            }
          }
        }
      } catch (dirError) {
        debugPrint('无法列出目录内容: $dirError');
      }

      // 如果此时仍未找到文件，抛出异常
      throw Exception('找不到纹理图片文件: 已尝试多种路径但均失败');
    } catch (e, stackTrace) {
      debugPrint('❌ 加载纹理图片失败: $e');
      debugPrint('堆栈跟踪: $stackTrace');
      rethrow;
    }
  }

  // 完全重写的选择纹理方法 - 防止嵌套问题
  Future<void> _selectTexture(
    BuildContext context,
    Map<String, dynamic> content,
    Function(String, dynamic) onContentPropertyChanged,
  ) async {
    final l10n = AppLocalizations.of(context);
    debugPrint('✨ 打开纹理选择对话框');

    // 打开选择对话框
    final selectedTexture = await M3LibraryPickerDialog.show(
      context,
      title: l10n.textureSelectFromLibrary,
    );

    // 如果用户取消了选择，直接返回
    if (selectedTexture == null) {
      debugPrint('❌ 用户取消了纹理选择');
      return;
    }

    debugPrint(
        '✅ 用户选择了纹理: ID=${selectedTexture.id}, 路径=${selectedTexture.path}');

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
        debugPrint('❌ 元素内容为空，无法应用纹理');
        return;
      }

      // 复制现有内容，添加纹理数据
      final newContent = Map<String, dynamic>.from(elementContent);
      newContent['backgroundTexture'] = textureData;

      // 设置纹理相关属性（如果不存在）
      newContent['textureApplicationRange'] =
          elementContent['textureApplicationRange'] ?? 'characterBackground';
      newContent['textureFillMode'] =
          elementContent['textureFillMode'] ?? 'repeat';
      newContent['textureOpacity'] = elementContent['textureOpacity'] ?? 1.0;

      // 更新内容
      widget.onContentPropertyChanged('content', newContent);

      // 强制刷新UI
      setState(() {});

      debugPrint('✅ 纹理应用成功');
    } catch (e) {
      debugPrint('❌ 应用纹理时出错: $e');
    }
  }
}
