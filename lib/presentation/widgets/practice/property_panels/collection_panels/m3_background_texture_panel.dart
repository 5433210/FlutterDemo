import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

  const M3BackgroundTexturePanel({
    Key? key,
    required this.element,
    required this.onPropertyChanged,
    required this.onContentPropertyChanged,
  }) : super(key: key);

  @override
  ConsumerState<M3BackgroundTexturePanel> createState() =>
      _M3BackgroundTexturePanelState();
}

class _M3BackgroundTexturePanelState
    extends ConsumerState<M3BackgroundTexturePanel> {
  // 加载纹理图片 - 优化版
  // 使用内存缓存避免重复加载
  static final Map<String, List<int>> _textureCache = {};
  // 本地状态来跟踪填充模式和适应模式
  String? _localTextureFillMode;
  String? _localTextureFitMode;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final content = widget.element['content'] as Map<String, dynamic>;

    // 调试输出元素结构，以便识别任何可能的嵌套问题
    debugPrint('🔍 构建背景纹理面板 - 元素结构检查:');
    debugPrint('  - 元素类型: ${widget.element['type']}');
    debugPrint('  - 内容键: ${content.keys.toList()}');
    if (content.containsKey('backgroundTexture')) {
      final textureData = content['backgroundTexture'];
      debugPrint('  - 背景纹理数据: $textureData');
    } else {
      debugPrint('  - 无背景纹理数据');
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
        'repeat'; // Default to repeat as specified

    final textureFitMode = content['textureFitMode'] as String? ??
        'scaleToFill'; // Default to scaleToFill as specified
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
      title:
          'Background Texture', // Use English fallback for background texture
      defaultExpanded: false,
      children: [
        // 1. Texture preview and management
        M3PanelStyles.buildSectionTitle(context,
            'Texture Preview'), // Use English fallback for texture preview
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
                    label: Text(l10n.textureSelectFromLibrary),
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
                        label: Text(l10n.textureRemove),
                        onPressed: () {
                          debugPrint('✨ 尝试移除背景纹理');
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
                onChanged: (value) {
                  _updateTextureProperty('textureOpacity', value);
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
              value: 'repeat',
              child: Text(l10n.textureFillModeRepeat),
            ),
            DropdownMenuItem(
              value: 'cover',
              child: Text(l10n.textureFillModeCover),
            ),
            const DropdownMenuItem(
              value: 'stretch',
              child: Text('Stretch'), // Use English fallback for stretch
            ),
            DropdownMenuItem(
              value: 'contain',
              child: Text(l10n.textureFillModeContain),
            ),
          ],
          onChanged: (value) {
            if (value != null) {
              debugPrint('🔄 纹理填充模式切换: $textureFillMode -> $value');

              // Update local state first
              _localTextureFillMode = value;

              _updateTextureProperty('textureFillMode', value);
            }
          },
        ),

        const SizedBox(height: 16.0),

        // 4. Texture Size Settings with restore default button
        M3PanelStyles.buildSectionTitle(
            context, 'Texture Size'), // Use English fallback for texture size
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
              tooltip:
                  'Restore Default Size', // Use English fallback for restore default size
              onPressed: () {
                _updateTextureProperty('textureWidth', defaultWidth);
                _updateTextureProperty('textureHeight', defaultHeight);
              },
            ),
          ],
        ),
        const SizedBox(height: 16.0),

        // 5. Texture Fit Mode Settings (scaleToFit, scaleToFill, scaleToCover)
        M3PanelStyles.buildSectionTitle(
            context, l10n.imagePropertyPanelFitMode),
        DropdownButton<String>(
          value: textureFitMode,
          isExpanded: true,
          items: [
            DropdownMenuItem(
              value: 'scaleToFit',
              child: Text(l10n
                  .imagePropertyPanelFitContain), // Use contain as closest equivalent to scaleToFit
            ),
            DropdownMenuItem(
              value: 'scaleToFill',
              child: Text(
                  l10n.imagePropertyPanelFitFill), // Use fill for scaleToFill
            ),
            DropdownMenuItem(
              value: 'scaleToCover',
              child: Text(l10n
                  .imagePropertyPanelFitCover), // Use cover for scaleToCover
            ),
          ],
          onChanged: (value) {
            if (value != null) {
              debugPrint('🔄 纹理适应模式切换: $textureFitMode -> $value');
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
                opacity: textureOpacity.clamp(0.0, 1.0),
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

  // 查找纹理数据 - 只从content层级查找，不从characterImages查找
  Map<String, dynamic>? _findTextureData(Map<String, dynamic> content) {
    // 检查参数是否有效 - 只在content级别查找backgroundTexture
    if (content.containsKey('backgroundTexture') &&
        content['backgroundTexture'] != null &&
        content['backgroundTexture'] is Map<String, dynamic> &&
        (content['backgroundTexture'] as Map<String, dynamic>).isNotEmpty) {
      final texData = content['backgroundTexture'] as Map<String, dynamic>;

      // 确保纹理数据包含必要的字段
      if (texData.containsKey('path') && texData.containsKey('id')) {
        debugPrint('✅ 找到有效的纹理数据: ${texData['id']}');
        return texData;
      } else {
        debugPrint('⚠️ 纹理数据不完整: $texData');
      }
    }

    // 注意：不再从characterImages中查找背景纹理数据
    // characterImages应该只包含角色相关的图像，不包含背景纹理

    // 如果当前层没有背景纹理，但有嵌套内容，则递归查找
    if (content.containsKey('content') &&
        content['content'] != null &&
        content['content'] is Map<String, dynamic>) {
      debugPrint('🔍 搜索嵌套内容中的纹理数据...');
      return _findTextureData(content['content'] as Map<String, dynamic>);
    }

    debugPrint('⚠️ 未找到任何纹理数据');
    return null;
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
    if (_textureCache.containsKey(cacheKey)) {
      debugPrint('从内存缓存加载纹理: $cacheKey');
      return _textureCache[cacheKey]!;
    }

    try {
      final storageService = ref.read(initializedStorageProvider);

      debugPrint('从存储加载纹理图片: $path');
      final imageBytes = await storageService.readFile(path);

      if (imageBytes.isNotEmpty) {
        // 缓存到内存
        _textureCache[cacheKey] = imageBytes;
        debugPrint('纹理图片加载并缓存成功: ${imageBytes.length} bytes');
        return imageBytes;
      } else {
        throw Exception('图片文件为空');
      }
    } catch (e) {
      debugPrint('加载纹理图片失败: $e');
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
    debugPrint('✨ 打开纹理选择对话框 - 增强版');

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

      // 创建全新的内容对象而不是修改现有对象，以避免任何引用问题
      final newContent = <String, dynamic>{};

      // 复制所有属性
      for (final key in elementContent.keys) {
        newContent[key] = elementContent[key];
      } // 添加纹理数据和相关属性
      newContent['backgroundTexture'] = textureData;
      newContent['textureFillMode'] =
          elementContent['textureFillMode'] ?? 'repeat';
      newContent['textureFitMode'] =
          elementContent['textureFitMode'] ?? 'scaleToFill';
      newContent['textureOpacity'] = elementContent['textureOpacity'] ?? 1.0;
      newContent['textureWidth'] = selectedTexture.width;
      newContent['textureHeight'] = selectedTexture.height;

      // 注意：不再在characterImages中存储背景纹理数据
      // characterImages应该只包含角色相关的图像，不包含背景纹理信息

      debugPrint('🔧 应用纹理数据到元素内容...');
      debugPrint('📊 完整的新内容: $newContent');

      // 尝试多种更新方式以确保更新生效
      debugPrint('📝 尝试使用onPropertyChanged更新内容...');
      widget.onPropertyChanged('content', newContent);

      // 等待一下，确保第一次更新已处理
      await Future.delayed(const Duration(milliseconds: 50));

      debugPrint('📝 尝试使用onContentPropertyChanged作为备选方案...');
      onContentPropertyChanged('content', newContent);

      // 清空缓存，强制重新加载纹理
      _textureCache.clear();
      debugPrint('🧹 清空本地纹理缓存');

      // 清除全局图像缓存
      try {
        final imageCacheService =
            ref.read(cache_providers.imageCacheServiceProvider);
        await imageCacheService.clearAll();
        debugPrint('🔄 已清除全局图像缓存');
      } catch (e) {
        debugPrint('⚠️ 清除全局缓存失败: $e');
      }

      debugPrint('✅ 纹理应用完成，触发界面更新');

      // 强制刷新UI
      setState(() {});
    } catch (e) {
      debugPrint('❌ 应用纹理时发生错误: $e');
    }
  }

  /// 更新纹理属性并确保更新整个内容对象
  void _updateTextureProperty(String propertyName, dynamic value) async {
    try {
      debugPrint('⚙️ 更新纹理属性: $propertyName = $value');

      // 获取当前内容
      final originalContent = widget.element['content'] as Map<String, dynamic>;

      // 输出原始内容的属性信息
      debugPrint('🔍 更新前的内容属性:');
      debugPrint('  - $propertyName: ${originalContent[propertyName]}');

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
      debugPrint('📝 使用onPropertyChanged更新整个content对象...');
      widget.onPropertyChanged('content', content);

      // 等待一下，确保更新已处理
      await Future.delayed(const Duration(milliseconds: 50));

      // 输出更新后的内容信息
      debugPrint('✅ 属性更新完成:');
      debugPrint('  - 更新的属性: $propertyName = $value');

      // 确认更新是否生效 - 获取更新后的内容进行检查
      Future.delayed(Duration.zero, () {
        final updatedContent =
            widget.element['content'] as Map<String, dynamic>?;
        if (updatedContent != null) {
          debugPrint(
              '  - 更新后检查: $propertyName = ${updatedContent[propertyName]}');
          debugPrint(
              '  - 更新${updatedContent[propertyName] == value ? "成功" : "失败"}');
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
      debugPrint('❌ 更新纹理属性时发生错误: $e');
    }
  }
}
