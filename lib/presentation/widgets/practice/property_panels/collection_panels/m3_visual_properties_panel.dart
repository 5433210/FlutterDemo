import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../infrastructure/providers/storage_providers.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../common/editable_number_field.dart';
import '../../../library/m3_library_picker_dialog.dart';
import '../m3_panel_styles.dart';
import 'm3_collection_color_utils.dart';

// 简单的颜色选择器组件
class ColorPicker extends StatefulWidget {
  final Color color;
  final Function(Color) onColorChanged;

  const ColorPicker({
    Key? key,
    required this.color,
    required this.onColorChanged,
  }) : super(key: key);

  @override
  State<ColorPicker> createState() => _ColorPickerState();
}

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

class _ColorPickerState extends State<ColorPicker> {
  late Color _currentColor;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 当前颜色预览
        Container(
          width: double.infinity,
          height: 60,
          decoration: BoxDecoration(
            color: _currentColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: colorScheme.outline),
          ),
        ),
        const SizedBox(height: 16),

        // 预设颜色
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildColorButton(Colors.black),
            _buildColorButton(Colors.white),
            _buildColorButton(Colors.red),
            _buildColorButton(Colors.pink),
            _buildColorButton(Colors.purple),
            _buildColorButton(Colors.deepPurple),
            _buildColorButton(Colors.indigo),
            _buildColorButton(Colors.blue),
            _buildColorButton(Colors.lightBlue),
            _buildColorButton(Colors.cyan),
            _buildColorButton(Colors.teal),
            _buildColorButton(Colors.green),
            _buildColorButton(Colors.lightGreen),
            _buildColorButton(Colors.lime),
            _buildColorButton(Colors.yellow),
            _buildColorButton(Colors.amber),
            _buildColorButton(Colors.orange),
            _buildColorButton(Colors.deepOrange),
            _buildColorButton(Colors.brown),
            _buildColorButton(Colors.grey),
            _buildColorButton(Colors.blueGrey),
            _buildColorButton(Colors.transparent),
          ],
        ),
      ],
    );
  }

  @override
  void initState() {
    super.initState();
    _currentColor = widget.color;
  }

  Widget _buildColorButton(Color color) {
    final isSelected = _currentColor == color;
    final isTransparent = color == Colors.transparent;

    return InkWell(
      onTap: () {
        setState(() {
          _currentColor = color;
        });
        widget.onColorChanged(color);
      },
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: isTransparent
            ? const Icon(Icons.block, color: Colors.red)
            : isSelected
                ? Icon(
                    Icons.check,
                    color: color.computeLuminance() > 0.5
                        ? Colors.black
                        : Colors.white,
                  )
                : null,
      ),
    );
  }
}

class _M3VisualPropertiesPanelState
    extends ConsumerState<M3VisualPropertiesPanel> {
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
              onTap: () {
                showColorPickerDialog(
                  context,
                  fontColor,
                  (color) {
                    widget.onContentPropertyChanged(
                        'fontColor', CollectionColorUtils.colorToHex(color));
                  },
                );
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
              onTap: () {
                showColorPickerDialog(
                  context,
                  backgroundColor,
                  (color) {
                    widget.onContentPropertyChanged('backgroundColor',
                        CollectionColorUtils.colorToHex(color));
                  },
                );
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
                value: opacity * 100, // Convert to percentage
                suffix: '%',
                min: 0,
                max: 100,
                decimalPlaces: 0,
                onChanged: (value) {
                  // Convert back to 0-1 range
                  widget.onPropertyChanged('opacity', value / 100);
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16.0),

        // Background Texture Settings
        M3PanelStyles.buildSectionTitle(context, l10n.textureApplicationRange),

        // Texture preview and select button
        Row(
          children: [
            // Texture preview
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

            // Select texture button
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FilledButton.icon(
                  icon: const Icon(Icons.image),
                  label: Text(
                      l10n.textureSelectFromLibrary), // Select from Library
                  onPressed: () => _selectTexture(
                      context, content, widget.onContentPropertyChanged),
                ),
                if (content.containsKey('backgroundTexture'))
                  const SizedBox(height: 8.0),
                if (content.containsKey('backgroundTexture'))
                  TextButton.icon(
                    icon: const Icon(Icons.delete_outline),
                    label: Text(l10n.textureRemove), // Remove
                    onPressed: () {
                      final updatedContent = Map<String, dynamic>.from(content);
                      updatedContent.remove('backgroundTexture');
                      widget.onContentPropertyChanged(
                          'content', updatedContent);
                    },
                  ),
              ],
            ),
          ],
        ), // Texture application range and settings (only visible when texture is selected)        if (content.containsKey('backgroundTexture')) ...[
        const SizedBox(height: 16.0),
        M3PanelStyles.buildSectionTitle(context, l10n.textureApplicationRange),
        Builder(builder: (context) {
          // 确保每次都获取最新的值
          final currentApplicationRange = widget.element['content'] != null
              ? (widget.element['content']
                          as Map<String, dynamic>)['textureApplicationRange']
                      as String? ??
                  'characterBackground'
              : 'characterBackground';

          // 兼容旧版本中使用的'character'应用模式，自动转换为'characterBackground'
          final effectiveApplicationRange =
              currentApplicationRange == 'character'
                  ? 'characterBackground'
                  : currentApplicationRange;

          debugPrint('当前纹理应用范围: $effectiveApplicationRange');
          return SegmentedButton<String>(
            segments: [
              const ButtonSegment<String>(
                value: 'characterBackground',
                label: Text(
                    '字符背景'), // Temporarily using hardcoded text until we add localization
                icon: Icon(Icons.text_fields),
              ),
              ButtonSegment<String>(
                value: 'background',
                label: Text(l10n.textureRangeBackground),
                icon: const Icon(Icons.crop_free),
              ),
            ],
            selected: {
              currentApplicationRange == 'character'
                  ? 'characterBackground'
                  : currentApplicationRange
            },
            onSelectionChanged: (selection) {
              debugPrint('纹理应用范围改变: ${selection.first}');
              final updatedContent = Map<String, dynamic>.from(content);

              // 如果切换到characterBackground，检查原来是否为character
              final selectedMode = selection.first;

              // 更新纹理应用范围
              updatedContent['textureApplicationRange'] = selectedMode;
              debugPrint('更新纹理应用范围: $updatedContent');

              // 直接更新属性而不是整个content对象
              widget.onContentPropertyChanged(
                  'textureApplicationRange', selectedMode);

              // 强制刷新UI
              setState(() {});
            },
          );
        }), // Texture fill mode        const SizedBox(height: 16.0),
        M3PanelStyles.buildSectionTitle(context, l10n.textureFillMode),
        Builder(builder: (context) {
          // 确保每次都获取最新的值
          final currentFillMode = widget.element['content'] != null
              ? (widget.element['content']
                      as Map<String, dynamic>)['textureFillMode'] as String? ??
                  'repeat'
              : 'repeat';
          debugPrint('当前纹理填充模式: $currentFillMode');

          return DropdownButton<String>(
            value: currentFillMode,
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
                debugPrint('纹理填充模式改变: $value');
                final updatedContent = Map<String, dynamic>.from(content);
                updatedContent['textureFillMode'] = value;
                debugPrint('更新纹理填充模式: $updatedContent');

                // 直接更新属性而不是整个content对象
                widget.onContentPropertyChanged('textureFillMode', value);

                // 强制刷新UI
                setState(() {});
              }
            },
          );
        }), // Texture opacity        const SizedBox(height: 16.0),
        M3PanelStyles.buildSectionTitle(context, l10n.textureOpacity),
        Builder(builder: (context) {
          // 确保每次都获取最新的值
          final currentOpacity = widget.element['content'] != null
              ? ((widget.element['content']
                          as Map<String, dynamic>)['textureOpacity'] as num?)
                      ?.toDouble() ??
                  1.0
              : 1.0;
          debugPrint('当前纹理不透明度: $currentOpacity');

          return Row(
            children: [
              Expanded(
                flex: 3,
                child: Slider(
                  value: currentOpacity,
                  min: 0.0,
                  max: 1.0,
                  divisions: 100,
                  label: '${(currentOpacity * 100).round()}%',
                  activeColor: colorScheme.primary,
                  inactiveColor: colorScheme.surfaceContainerHighest,
                  onChanged: (value) {
                    debugPrint('纹理不透明度改变: $value');
                    final updatedContent = Map<String, dynamic>.from(content);
                    updatedContent['textureOpacity'] = value;
                    debugPrint('更新纹理不透明度: $updatedContent');

                    // 直接更新属性而不是整个content对象
                    widget.onContentPropertyChanged('textureOpacity', value);

                    // 强制刷新UI
                    setState(() {});
                  },
                ),
              ),
              const SizedBox(width: 8.0),
              Expanded(
                flex: 2,
                child: EditableNumberField(
                  label: l10n.textureOpacity,
                  value: currentOpacity * 100,
                  suffix: '%',
                  min: 0,
                  max: 100,
                  decimalPlaces: 0,
                  onChanged: (value) {
                    // 直接更新属性而不是整个content对象
                    widget.onContentPropertyChanged(
                        'textureOpacity', value / 100);

                    // 强制刷新UI
                    setState(() {});
                  },
                ),
              ),
            ],
          );
        }),

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

  // 显示颜色选择器对话框
  void showColorPickerDialog(
    BuildContext context,
    String initialColor,
    Function(Color) onColorSelected,
  ) {
    final Color color = CollectionColorUtils.hexToColor(initialColor);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('选择颜色'), // 使用硬编码文本，因为本地化字符串尚未定义
        content: SingleChildScrollView(
          child: ColorPicker(
            color: color,
            onColorChanged: onColorSelected,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'), // 使用硬编码文本，因为本地化字符串尚未定义
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('确定'), // 使用硬编码文本，因为本地化字符串尚未定义
          ),
        ],
      ),
    );
  }

  // 增强版的纹理预览
  Widget _buildTexturePreview(Map<String, dynamic> content) {
    // 检查内容中是否直接包含 backgroundTexture
    final hasDirectTexture = content.containsKey('backgroundTexture') &&
        content['backgroundTexture'] != null &&
        content['backgroundTexture'] is Map<String, dynamic>;

    // 检查嵌套内容中是否包含 backgroundTexture
    final hasNestedTexture = content.containsKey('content') &&
        content['content'] is Map<String, dynamic> &&
        (content['content'] as Map<String, dynamic>)
            .containsKey('backgroundTexture') &&
        (content['content'] as Map<String, dynamic>)['backgroundTexture'] !=
            null;

    debugPrint('纹理预览检查: 直接包含=$hasDirectTexture, 嵌套包含=$hasNestedTexture');

    // 获取纹理数据，优先使用直接的，其次使用嵌套的
    Map<String, dynamic>? texture;
    if (hasDirectTexture) {
      texture = content['backgroundTexture'] as Map<String, dynamic>;
      debugPrint('使用直接纹理数据: $texture');
    } else if (hasNestedTexture) {
      texture = (content['content']
          as Map<String, dynamic>)['backgroundTexture'] as Map<String, dynamic>;
      debugPrint('使用嵌套纹理数据: $texture');
    }

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

  // 获取最新的纹理不透明度值
  double _getLatestTextureOpacity(Map<String, dynamic> localContent) {
    // 尝试从widget.element['content']中获取最新的不透明度值
    if (widget.element['content'] != null &&
        (widget.element['content'] as Map<String, dynamic>)
            .containsKey('textureOpacity')) {
      final value =
          (widget.element['content'] as Map<String, dynamic>)['textureOpacity'];
      if (value is num) {
        return value.toDouble();
      }
    }

    // 如果在widget.element中找不到，则从传入的局部content中获取
    final value = localContent['textureOpacity'];
    if (value is num) {
      return value.toDouble();
    }

    // 默认值
    return 1.0;
  }

  // 获取最新的纹理属性值
  String? _getLatestTextureProperty(
      String propertyName, Map<String, dynamic> localContent) {
    // 尝试从widget.element['content']中获取最新的属性值
    if (widget.element['content'] != null &&
        (widget.element['content'] as Map<String, dynamic>)
            .containsKey(propertyName)) {
      final value =
          (widget.element['content'] as Map<String, dynamic>)[propertyName];
      return value is String ? value : value?.toString();
    }

    // 如果在widget.element中找不到，则从传入的局部content中获取
    final value = localContent[propertyName];
    return value is String ? value : value?.toString();
  }

  // 加载纹理图片 - 优化版
  // 使用内存缓存避免重复加载
  static final Map<String, List<int>> _textureCache = {};
  
  Future<List<int>> _loadTextureImage(String path) async {
    debugPrint('加载纹理图片: $path');
    
    // 检查内存缓存
    final cacheKey = path.split('/').last;
    if (_textureCache.containsKey(cacheKey)) {
      debugPrint('✅ 从内存缓存加载纹理: $cacheKey, 大小: ${_textureCache[cacheKey]!.length} 字节');
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

  // 选择纹理 - 优化版
  Future<void> _selectTexture(
    BuildContext context,
    Map<String, dynamic> content,
    Function(String, dynamic) onContentPropertyChanged,
  ) async {
    final l10n = AppLocalizations.of(context);
    debugPrint('_selectTexture: 打开纹理选择对话框');

    final selectedTexture = await M3LibraryPickerDialog.show(
      context,
      title: l10n.textureSelectFromLibrary,
    );

    if (selectedTexture != null) {
      debugPrint(
          '_selectTexture: 已选择纹理，ID=${selectedTexture.id}, 路径=${selectedTexture.path}');

      // 使用原始路径创建纹理数据
      String texturePath = selectedTexture.path;

      // 验证选择的纹理路径是否存在
      try {
        final storage = ref.read(initializedStorageProvider);
        final fileExists = await storage.fileExists(texturePath);
        debugPrint('_selectTexture: 验证纹理文件存在: $fileExists');

        if (!fileExists) {
          // 尝试不同的路径格式
          final String libraryPath =
              '${storage.getAppDataPath()}/library/${texturePath.split('/').last}';
          final libraryPathExists = await storage.fileExists(libraryPath);
          debugPrint(
              '_selectTexture: 尝试库路径: $libraryPath, 存在: $libraryPathExists');

          if (libraryPathExists) {
            texturePath = libraryPath;
            debugPrint('_selectTexture: 使用库路径: $texturePath');
          } else {
            // 尝试其他路径
            final absolutePath =
                texturePath.startsWith('/') ? texturePath : '/$texturePath';
            final absolutePathExists = await storage.fileExists(absolutePath);
            debugPrint(
                '_selectTexture: 尝试绝对路径: $absolutePath, 存在: $absolutePathExists');

            if (absolutePathExists) {
              texturePath = absolutePath;
              debugPrint('_selectTexture: 使用绝对路径: $texturePath');
            } else if (!texturePath.startsWith('/')) {
              final appDataPath = '${storage.getAppDataPath()}/$texturePath';
              final appDataPathExists = await storage.fileExists(appDataPath);
              debugPrint(
                  '_selectTexture: 尝试应用数据路径: $appDataPath, 存在: $appDataPathExists');

              if (appDataPathExists) {
                texturePath = appDataPath;
                debugPrint('_selectTexture: 使用应用数据路径: $texturePath');
              }
            }
          }
        }
      } catch (e) {
        debugPrint('_selectTexture: 验证纹理文件时出错: $e');
      }

      // 创建纹理数据
      final textureData = {
        'id': selectedTexture.id,
        'path': texturePath,
        'width': selectedTexture.width,
        'height': selectedTexture.height,
        'type': selectedTexture.type,
        'format': selectedTexture.format,
        // 添加时间戳确保纹理数据被视为新数据
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };

      // 先完全移除旧的纹理数据（如果存在）
      final updatedContent = Map<String, dynamic>.from(content);
      updatedContent.remove('backgroundTexture');
      
      // 确保UI更新，先通知移除
      widget.onContentPropertyChanged('content', updatedContent);
      
      // 短暂延迟后添加新纹理，确保状态更新
      Future.delayed(const Duration(milliseconds: 50), () {
        // 添加新的纹理数据
        updatedContent['backgroundTexture'] = textureData;
        
        debugPrint('选择的纹理数据：$textureData');

        // 设置默认值（如果尚未设置）
        if (!updatedContent.containsKey('textureApplicationRange')) {
          updatedContent['textureApplicationRange'] = 'character';
        }

        if (!updatedContent.containsKey('textureFillMode')) {
          updatedContent['textureFillMode'] = 'repeat';
        }

        if (!updatedContent.containsKey('textureOpacity')) {
          updatedContent['textureOpacity'] = 1.0;
        }

        debugPrint(
            '_selectTexture: 更新内容属性，backgroundTexture=${updatedContent['backgroundTexture']}');
        debugPrint('更新后的完整内容：$updatedContent');
        
        // 立即应用更新以确保预览能正确显示
        widget.onContentPropertyChanged('content', updatedContent);

        // 直接更新每个纹理相关属性，确保UI能够反映变化
        widget.onContentPropertyChanged(
            'textureApplicationRange', updatedContent['textureApplicationRange']);
        widget.onContentPropertyChanged(
            'textureFillMode', updatedContent['textureFillMode']);
        widget.onContentPropertyChanged(
            'textureOpacity', updatedContent['textureOpacity']);

        // 强制刷新UI
        if (mounted) {
          setState(() {});
        }
      });
    } else {
      debugPrint('_selectTexture: 未选择纹理');
    }
  }
}
