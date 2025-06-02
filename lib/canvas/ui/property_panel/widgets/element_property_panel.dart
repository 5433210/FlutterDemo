/// Canvas元素属性面板 - Phase 2.2
///
/// 职责：
/// 1. 单个元素属性编辑
/// 2. 实时属性同步
/// 3. 基础和高级属性分组
/// 4. 类型特定的属性编辑器
library;

import 'package:flutter/material.dart';

import '../../../core/canvas_state_manager.dart';
import '../../../core/interfaces/element_data.dart';
import '../property_panel.dart';
import '../property_panel_controller.dart';
import 'property_widgets.dart';

/// 元素属性面板
class ElementPropertyPanel extends StatefulWidget {
  final CanvasStateManager stateManager;
  final PropertyPanelController controller;
  final ElementData element;
  final PropertyPanelStyle style;
  final Function(String, Map<String, dynamic>) onPropertyChanged;

  const ElementPropertyPanel({
    super.key,
    required this.stateManager,
    required this.controller,
    required this.element,
    required this.style,
    required this.onPropertyChanged,
  });

  @override
  State<ElementPropertyPanel> createState() => _ElementPropertyPanelState();
}

class _ElementPropertyPanelState extends State<ElementPropertyPanel> {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 16),
          _buildBasicProperties(),
          const SizedBox(height: 16),
          _buildGeometryProperties(),
          const SizedBox(height: 16),
          _buildVisualProperties(),
          if (_shouldShowAdvancedProperties()) ...[
            const SizedBox(height: 16),
            _buildAdvancedProperties(),
          ],
          if (_shouldShowTypeSpecificProperties()) ...[
            const SizedBox(height: 16),
            _buildTypeSpecificProperties(),
          ],
        ],
      ),
    );
  }

  /// 构建高级属性
  Widget _buildAdvancedProperties() {
    return PropertySection(
      title: '高级属性',
      style: widget.style,
      isExpanded: false,
      children: [
        PropertyTextField(
          label: '元素类型',
          value: widget.element.type,
          onChanged: (_) {}, // 只读
        ),
        const SizedBox(height: 12),
        PropertyTextField(
          label: '创建时间',
          value: widget.element.properties['createdAt']?.toString() ?? '未知',
          onChanged: (_) {}, // 只读
        ),
      ],
    );
  }

  /// 构建基础属性
  Widget _buildBasicProperties() {
    return PropertySection(
      title: '基础属性',
      style: widget.style,
      children: [
        PropertyTextField(
          label: '名称',
          value: widget.element.properties['name']?.toString() ?? '未命名元素',
          onChanged: (value) => _updateProperty('name', value),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: PropertySwitch(
                label: '可见',
                value: !widget.element.isHidden,
                onChanged: (value) => _updateProperty('isHidden', !value),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: PropertySwitch(
                label: '锁定',
                value: widget.element.isLocked,
                onChanged: (value) => _updateProperty('isLocked', value),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// 构建集字特定属性
  Widget _buildCollectionProperties() {
    return PropertySection(
      title: '集字属性',
      style: widget.style,
      children: [
        Row(
          children: [
            Expanded(
              child: PropertyNumberField(
                label: '列数',
                value: (widget.element.properties['columns'] as num?)
                        ?.toDouble() ??
                    3.0,
                onChanged: (value) => _updateProperty('columns', value.round()),
                min: 1,
                max: 10,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: PropertyNumberField(
                label: '间距',
                value: (widget.element.properties['spacing'] as num?)
                        ?.toDouble() ??
                    8.0,
                onChanged: (value) => _updateProperty('spacing', value),
                min: 0,
                max: 50,
                suffix: 'px',
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// 构建几何属性
  Widget _buildGeometryProperties() {
    return PropertySection(
      title: '几何属性',
      style: widget.style,
      children: [
        Row(
          children: [
            Expanded(
              child: PropertyNumberField(
                label: 'X',
                value: widget.element.bounds.left,
                onChanged: (value) => _updateBounds(x: value),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: PropertyNumberField(
                label: 'Y',
                value: widget.element.bounds.top,
                onChanged: (value) => _updateBounds(y: value),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: PropertyNumberField(
                label: '宽度',
                value: widget.element.bounds.width,
                onChanged: (value) => _updateBounds(width: value),
                min: 1,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: PropertyNumberField(
                label: '高度',
                value: widget.element.bounds.height,
                onChanged: (value) => _updateBounds(height: value),
                min: 1,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        PropertyNumberField(
          label: '旋转角度',
          value: widget.element.rotation * 180 / 3.14159, // 转换为度数
          onChanged: (value) =>
              _updateProperty('rotation', value * 3.14159 / 180), // 转换为弧度
          min: -360,
          max: 360,
          suffix: '°',
        ),
      ],
    );
  }

  /// 构建头部信息
  Widget _buildHeader() {
    return PropertyCard(
      style: widget.style,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _getElementIcon(),
                size: 24,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                _getElementTypeName(),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'ID: ${widget.element.id}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontFamily: 'monospace',
                ),
          ),
        ],
      ),
    );
  }

  /// 构建图像特定属性
  Widget _buildImageProperties() {
    return PropertySection(
      title: '图像属性',
      style: widget.style,
      children: [
        PropertyTextField(
          label: '图像路径',
          value: widget.element.properties['imagePath']?.toString() ?? '无',
          onChanged: (_) {}, // 只读
        ),
        const SizedBox(height: 12),
        PropertySwitch(
          label: '保持纵横比',
          value:
              widget.element.properties['maintainAspectRatio'] as bool? ?? true,
          onChanged: (value) => _updateProperty('maintainAspectRatio', value),
        ),
      ],
    );
  }

  /// 构建文本特定属性
  Widget _buildTextProperties() {
    return PropertySection(
      title: '文本属性',
      style: widget.style,
      children: [
        PropertyTextField(
          label: '文本内容',
          value: widget.element.properties['text']?.toString() ?? '',
          onChanged: (value) => _updateProperty('text', value),
          maxLines: 3,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: PropertyNumberField(
                label: '字体大小',
                value: (widget.element.properties['fontSize'] as num?)
                        ?.toDouble() ??
                    16.0,
                onChanged: (value) => _updateProperty('fontSize', value),
                min: 8,
                max: 200,
                suffix: 'px',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: PropertyDropdown<String>(
                label: '字体粗细',
                value: widget.element.properties['fontWeight']?.toString() ??
                    'normal',
                items: const [
                  'normal',
                  'bold',
                  'w100',
                  'w200',
                  'w300',
                  'w400',
                  'w500',
                  'w600',
                  'w700',
                  'w800',
                  'w900'
                ],
                onChanged: (value) => _updateProperty('fontWeight', value),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        PropertyColorField(
          label: '文本颜色',
          value:
              Color(widget.element.properties['color'] as int? ?? 0xFF000000),
          onChanged: (value) => _updateProperty('color', value.value),
        ),
      ],
    );
  }

  /// 构建类型特定属性
  Widget _buildTypeSpecificProperties() {
    switch (widget.element.type) {
      case 'text':
        return _buildTextProperties();
      case 'image':
        return _buildImageProperties();
      case 'collection':
        return _buildCollectionProperties();
      default:
        return const SizedBox.shrink();
    }
  }

  /// 构建视觉属性
  Widget _buildVisualProperties() {
    return PropertySection(
      title: '视觉属性',
      style: widget.style,
      children: [
        PropertySlider(
          label: '透明度',
          value: widget.element.opacity,
          onChanged: (value) => _updateProperty('opacity', value),
          min: 0.0,
          max: 1.0,
          divisions: 100,
        ),
        const SizedBox(height: 12),
        PropertyNumberField(
          label: 'Z 索引',
          value: widget.element.zIndex.toDouble(),
          onChanged: (value) => _updateProperty('zIndex', value.round()),
        ),
      ],
    );
  }

  /// 获取元素图标
  IconData _getElementIcon() {
    switch (widget.element.type) {
      case 'text':
        return Icons.text_fields;
      case 'image':
        return Icons.image;
      case 'collection':
        return Icons.font_download;
      default:
        return Icons.crop_square;
    }
  }

  /// 获取元素类型名称
  String _getElementTypeName() {
    switch (widget.element.type) {
      case 'text':
        return '文本元素';
      case 'image':
        return '图像元素';
      case 'collection':
        return '集字元素';
      default:
        return '元素';
    }
  }

  /// 是否显示高级属性
  bool _shouldShowAdvancedProperties() {
    return widget.controller.config.showAdvancedProperties;
  }

  /// 是否显示类型特定属性
  bool _shouldShowTypeSpecificProperties() {
    return widget.element.type == 'text' ||
        widget.element.type == 'image' ||
        widget.element.type == 'collection';
  }

  /// 更新边界
  void _updateBounds({double? x, double? y, double? width, double? height}) {
    final currentBounds = widget.element.bounds;
    final newBounds = Rect.fromLTWH(
      x ?? currentBounds.left,
      y ?? currentBounds.top,
      width ?? currentBounds.width,
      height ?? currentBounds.height,
    );
    widget.onPropertyChanged(widget.element.id, {'bounds': newBounds});
  }

  /// 更新属性
  void _updateProperty(String key, dynamic value) {
    widget.onPropertyChanged(widget.element.id, {key: value});
  }
}
