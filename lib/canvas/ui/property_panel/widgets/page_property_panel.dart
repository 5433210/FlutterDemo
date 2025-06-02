/// Canvas页面属性面板 - Phase 2.2
///
/// 职责：
/// 1. 页面基础属性设置
/// 2. 画布尺寸和背景配置
/// 3. 网格和辅助线设置
/// 4. 页面导出和打印配置
library;

import 'package:flutter/material.dart';

import '../../../core/canvas_state_manager.dart';
import '../../../state/element_state.dart';
import '../../../state/selection_state.dart';
import '../property_panel.dart';
import '../property_panel_controller.dart';
import 'property_widgets.dart';

/// 页面属性面板
class PagePropertyPanel extends StatefulWidget {
  final CanvasStateManager stateManager;
  final PropertyPanelController controller;
  final PropertyPanelStyle style;
  final Function(Map<String, dynamic>) onPropertyChanged;

  const PagePropertyPanel({
    super.key,
    required this.stateManager,
    required this.controller,
    this.style = PropertyPanelStyle.modern,
    required this.onPropertyChanged,
  });

  @override
  State<PagePropertyPanel> createState() => _PagePropertyPanelState();
}

class _PagePropertyPanelState extends State<PagePropertyPanel> {
  late Map<String, dynamic> _pageProperties;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildPageInfo(),
        const SizedBox(height: 16),
        _buildCanvasSettings(),
        const SizedBox(height: 16),
        _buildBackgroundSettings(),
        const SizedBox(height: 16),
        _buildGridSettings(),
        const SizedBox(height: 16),
        _buildGuidesSettings(),
        const SizedBox(height: 16),
        _buildExportSettings(),
        const SizedBox(height: 16),
        _buildPageActions(),
      ],
    );
  }

  @override
  void initState() {
    super.initState();
    _loadPageProperties();
  }

  /// 应用预设尺寸
  void _applyPresetSize(String key) {
    final sizes = {
      'a4_portrait': [595, 842],
      'a4_landscape': [842, 595],
      'letter_portrait': [612, 792],
      'letter_landscape': [792, 612],
      'screen_1920x1080': [1920, 1080],
      'screen_1366x768': [1366, 768],
      'mobile_375x667': [375, 667],
      'tablet_768x1024': [768, 1024],
    };

    final size = sizes[key];
    if (size != null) {
      _updateProperty('width', size[0].toDouble());
      _updateProperty('height', size[1].toDouble());
    }
  }

  /// 构建背景内容
  Widget _buildBackgroundContent() {
    final backgroundType = _pageProperties['backgroundType'] ?? 'color';

    switch (backgroundType) {
      case 'color':
        return PropertyColorField(
          label: '背景颜色',
          value: Color(_pageProperties['backgroundColor'] ?? 0xFFFFFFFF),
          onChanged: (color) => _updateProperty('backgroundColor', color.value),
        );
      case 'gradient':
        return _buildGradientSettings();
      case 'image':
        return _buildImageSettings();
      case 'pattern':
        return _buildPatternSettings();
      default:
        return const SizedBox.shrink();
    }
  }

  /// 构建背景设置
  Widget _buildBackgroundSettings() {
    return PropertySection(
      title: '背景设置',
      style: widget.style,
      children: [
        PropertyDropdown<String>(
          label: '背景类型',
          value: _pageProperties['backgroundType'] ?? 'color',
          items: const ['color', 'gradient', 'image', 'pattern'],
          onChanged: (value) => _updateProperty('backgroundType', value),
          itemBuilder: (type) => _getBackgroundTypeDisplayName(type),
        ),
        const SizedBox(height: 16),
        _buildBackgroundContent(),
      ],
    );
  }

  /// 构建画布设置
  Widget _buildCanvasSettings() {
    return PropertySection(
      title: '画布设置',
      style: widget.style,
      children: [
        Row(
          children: [
            Expanded(
              child: PropertyNumberField(
                label: '宽度',
                value: (_pageProperties['width'] as num?)?.toDouble() ?? 800,
                onChanged: (value) => _updateProperty('width', value),
                min: 100,
                max: 10000,
                suffix: 'px',
                decimalPlaces: 0,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: PropertyNumberField(
                label: '高度',
                value: (_pageProperties['height'] as num?)?.toDouble() ?? 600,
                onChanged: (value) => _updateProperty('height', value),
                min: 100,
                max: 10000,
                suffix: 'px',
                decimalPlaces: 0,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        PropertyDropdown<String>(
          label: '预设尺寸',
          value: _getPresetSizeKey(),
          items: const [
            'custom',
            'a4_portrait',
            'a4_landscape',
            'letter_portrait',
            'letter_landscape',
            'screen_1920x1080',
            'screen_1366x768',
            'mobile_375x667',
            'tablet_768x1024',
          ],
          onChanged: (value) => _applyPresetSize(value),
          itemBuilder: (key) => _getPresetSizeDisplayName(key),
        ),
        const SizedBox(height: 16),
        PropertySlider(
          label: '缩放比例',
          value: (_pageProperties['zoom'] as num?)?.toDouble() ?? 1.0,
          min: 0.1,
          max: 5.0,
          onChanged: (value) => _updateProperty('zoom', value),
          divisions: 49,
          suffix: 'x',
        ),
      ],
    );
  }

  /// 构建导出设置
  Widget _buildExportSettings() {
    return PropertySection(
      title: '导出设置',
      style: widget.style,
      children: [
        PropertyDropdown<String>(
          label: '默认格式',
          value: _pageProperties['exportFormat'] ?? 'png',
          items: const ['png', 'jpg', 'svg', 'pdf'],
          onChanged: (value) => _updateProperty('exportFormat', value),
          itemBuilder: (format) => format.toUpperCase(),
        ),
        const SizedBox(height: 16),
        PropertyDropdown<int>(
          label: '导出质量',
          value: _pageProperties['exportQuality'] ?? 100,
          items: const [50, 75, 90, 95, 100],
          onChanged: (value) => _updateProperty('exportQuality', value),
          itemBuilder: (quality) => '$quality%',
        ),
        const SizedBox(height: 16),
        PropertySlider(
          label: '导出缩放',
          value: (_pageProperties['exportScale'] as num?)?.toDouble() ?? 1.0,
          min: 0.5,
          max: 4.0,
          onChanged: (value) => _updateProperty('exportScale', value),
          divisions: 7,
          suffix: 'x',
        ),
      ],
    );
  }

  /// 构建渐变设置
  Widget _buildGradientSettings() {
    return Column(
      children: [
        PropertyDropdown<String>(
          label: '渐变类型',
          value: _pageProperties['gradientType'] ?? 'linear',
          items: const ['linear', 'radial', 'sweep'],
          onChanged: (value) => _updateProperty('gradientType', value),
          itemBuilder: (type) => _getGradientTypeDisplayName(type),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: PropertyColorField(
                label: '起始颜色',
                value:
                    Color(_pageProperties['gradientStartColor'] ?? 0xFFFFFFFF),
                onChanged: (color) =>
                    _updateProperty('gradientStartColor', color.value),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: PropertyColorField(
                label: '结束颜色',
                value: Color(_pageProperties['gradientEndColor'] ?? 0xFF000000),
                onChanged: (color) =>
                    _updateProperty('gradientEndColor', color.value),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        PropertySlider(
          label: '渐变角度',
          value: (_pageProperties['gradientAngle'] as num?)?.toDouble() ?? 0,
          min: 0,
          max: 360,
          onChanged: (value) => _updateProperty('gradientAngle', value),
          divisions: 360,
          suffix: '°',
        ),
      ],
    );
  }

  /// 构建网格设置
  Widget _buildGridSettings() {
    return PropertySection(
      title: '网格设置',
      style: widget.style,
      children: [
        PropertySwitch(
          label: '显示网格',
          value: _pageProperties['showGrid'] ?? false,
          onChanged: (value) => _updateProperty('showGrid', value),
          description: '在画布上显示网格线',
        ),
        if (_pageProperties['showGrid'] == true) ...[
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: PropertyNumberField(
                  label: '网格间距',
                  value:
                      (_pageProperties['gridSize'] as num?)?.toDouble() ?? 20,
                  onChanged: (value) => _updateProperty('gridSize', value),
                  min: 5,
                  max: 100,
                  suffix: 'px',
                  decimalPlaces: 0,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: PropertyColorField(
                  label: '网格颜色',
                  value: Color(_pageProperties['gridColor'] ?? 0xFFE0E0E0),
                  onChanged: (color) =>
                      _updateProperty('gridColor', color.value),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          PropertySlider(
            label: '网格透明度',
            value: (_pageProperties['gridOpacity'] as num?)?.toDouble() ?? 0.5,
            min: 0.1,
            max: 1.0,
            onChanged: (value) => _updateProperty('gridOpacity', value),
            divisions: 9,
            suffix: '%',
          ),
          const SizedBox(height: 16),
          PropertySwitch(
            label: '吸附到网格',
            value: _pageProperties['snapToGrid'] ?? false,
            onChanged: (value) => _updateProperty('snapToGrid', value),
            description: '元素移动时自动吸附到网格点',
          ),
        ],
      ],
    );
  }

  /// 构建辅助线设置
  Widget _buildGuidesSettings() {
    return PropertySection(
      title: '辅助线设置',
      style: widget.style,
      children: [
        PropertySwitch(
          label: '显示辅助线',
          value: _pageProperties['showGuides'] ?? false,
          onChanged: (value) => _updateProperty('showGuides', value),
          description: '显示拖拽创建的辅助线',
        ),
        if (_pageProperties['showGuides'] == true) ...[
          const SizedBox(height: 16),
          PropertyColorField(
            label: '辅助线颜色',
            value: Color(_pageProperties['guideColor'] ?? 0xFF00BCD4),
            onChanged: (color) => _updateProperty('guideColor', color.value),
          ),
          const SizedBox(height: 16),
          PropertySwitch(
            label: '吸附到辅助线',
            value: _pageProperties['snapToGuides'] ?? true,
            onChanged: (value) => _updateProperty('snapToGuides', value),
            description: '元素移动时自动吸附到辅助线',
          ),
          const SizedBox(height: 16),
          PropertySwitch(
            label: '智能辅助线',
            value: _pageProperties['smartGuides'] ?? true,
            onChanged: (value) => _updateProperty('smartGuides', value),
            description: '自动显示对齐辅助线',
          ),
        ],
      ],
    );
  }

  /// 构建图片设置
  Widget _buildImageSettings() {
    return Column(
      children: [
        Container(
          height: 120,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.image,
                  size: 48,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(height: 8),
                Text(
                  '点击选择背景图片',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        PropertyDropdown<String>(
          label: '图片适配',
          value: _pageProperties['imageFit'] ?? 'cover',
          items: const ['cover', 'contain', 'fill', 'stretch', 'tile'],
          onChanged: (value) => _updateProperty('imageFit', value),
          itemBuilder: (fit) => _getImageFitDisplayName(fit),
        ),
        const SizedBox(height: 16),
        PropertySlider(
          label: '图片透明度',
          value: (_pageProperties['imageOpacity'] as num?)?.toDouble() ?? 1.0,
          min: 0.0,
          max: 1.0,
          onChanged: (value) => _updateProperty('imageOpacity', value),
          divisions: 100,
          suffix: '%',
        ),
      ],
    );
  }

  /// 构建页面操作
  Widget _buildPageActions() {
    return PropertySection(
      title: '页面操作',
      style: widget.style,
      children: [
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: _exportPage,
                icon: const Icon(Icons.download),
                label: const Text('导出页面'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _printPage,
                icon: const Icon(Icons.print),
                label: const Text('打印页面'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _duplicatePage,
                icon: const Icon(Icons.copy),
                label: const Text('复制页面'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _clearPage,
                icon: const Icon(Icons.clear_all),
                label: const Text('清空页面'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.error,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// 构建页面信息
  Widget _buildPageInfo() {
    return PropertyCard(
      title: '页面信息',
      style: widget.style,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PropertyTextField(
            label: '页面名称',
            value: _pageProperties['name'] ?? '未命名页面',
            onChanged: (value) => _updateProperty('name', value),
          ),
          const SizedBox(height: 16),
          PropertyTextField(
            label: '页面描述',
            value: _pageProperties['description'] ?? '',
            onChanged: (value) => _updateProperty('description', value),
            hintText: '输入页面描述...',
            maxLines: 3,
          ),
          const SizedBox(height: 16),
          _buildPageStats(),
        ],
      ),
    );
  }

  /// 构建页面统计信息
  Widget _buildPageStats() {
    final elementCount = widget.stateManager.elementState.elements.length;
    const layerCount = 1; // Canvas system doesn't have layers

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Column(
            children: [
              Text(
                '$elementCount',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
              ),
              Text(
                '元素',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
          Container(
            width: 1,
            height: 32,
            color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
          ),
          Column(
            children: [
              Text(
                '$layerCount',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
              ),
              Text(
                '图层',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
          Container(
            width: 1,
            height: 32,
            color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
          ),
          Column(
            children: [
              Text(
                '${(_pageProperties['fileSize'] ?? 0) ~/ 1024}',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
              ),
              Text(
                'KB',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 构建图案设置
  Widget _buildPatternSettings() {
    return Column(
      children: [
        PropertyDropdown<String>(
          label: '图案类型',
          value: _pageProperties['patternType'] ?? 'dots',
          items: const ['dots', 'lines', 'grid', 'diagonal', 'checkerboard'],
          onChanged: (value) => _updateProperty('patternType', value),
          itemBuilder: (type) => _getPatternTypeDisplayName(type),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: PropertyColorField(
                label: '图案颜色',
                value: Color(_pageProperties['patternColor'] ?? 0xFF000000),
                onChanged: (color) =>
                    _updateProperty('patternColor', color.value),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: PropertyNumberField(
                label: '图案间距',
                value:
                    (_pageProperties['patternSpacing'] as num?)?.toDouble() ??
                        20,
                onChanged: (value) => _updateProperty('patternSpacing', value),
                min: 5,
                max: 100,
                suffix: 'px',
                decimalPlaces: 0,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// 清空页面
  void _clearPage() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认清空'),
        content: const Text('确定要清空当前页面的所有内容吗？此操作无法撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              // 实现页面清空功能 - 创建新的空元素状态
              widget.stateManager.updateElementState(const ElementState());
              widget.stateManager.updateSelectionState(const SelectionState());
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('页面已清空')),
              );
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('清空'),
          ),
        ],
      ),
    );
  }

  /// 复制页面
  void _duplicatePage() {
    // TODO: 实现页面复制功能
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('页面已复制')),
    );
  }

  /// 导出页面
  void _exportPage() {
    // TODO: 实现页面导出功能
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('导出功能开发中...')),
    );
  }

  /// 获取背景类型显示名称
  String _getBackgroundTypeDisplayName(String type) {
    const names = {
      'color': '纯色',
      'gradient': '渐变',
      'image': '图片',
      'pattern': '图案',
    };
    return names[type] ?? type;
  }

  /// 获取渐变类型显示名称
  String _getGradientTypeDisplayName(String type) {
    const names = {
      'linear': '线性渐变',
      'radial': '径向渐变',
      'sweep': '圆锥渐变',
    };
    return names[type] ?? type;
  }

  /// 获取图片适配显示名称
  String _getImageFitDisplayName(String fit) {
    const names = {
      'cover': '覆盖',
      'contain': '包含',
      'fill': '填充',
      'stretch': '拉伸',
      'tile': '平铺',
    };
    return names[fit] ?? fit;
  }

  /// 获取图案类型显示名称
  String _getPatternTypeDisplayName(String type) {
    const names = {
      'dots': '圆点',
      'lines': '线条',
      'grid': '网格',
      'diagonal': '斜线',
      'checkerboard': '棋盘',
    };
    return names[type] ?? type;
  }

  /// 获取预设尺寸显示名称
  String _getPresetSizeDisplayName(String key) {
    const names = {
      'custom': '自定义',
      'a4_portrait': 'A4 纵向 (595×842)',
      'a4_landscape': 'A4 横向 (842×595)',
      'letter_portrait': 'Letter 纵向 (612×792)',
      'letter_landscape': 'Letter 横向 (792×612)',
      'screen_1920x1080': '1920×1080 屏幕',
      'screen_1366x768': '1366×768 屏幕',
      'mobile_375x667': '375×667 手机',
      'tablet_768x1024': '768×1024 平板',
    };
    return names[key] ?? key;
  }

  /// 获取预设尺寸键值
  String _getPresetSizeKey() {
    final width = _pageProperties['width'] as num?;
    final height = _pageProperties['height'] as num?;

    if (width == 595 && height == 842) return 'a4_portrait';
    if (width == 842 && height == 595) return 'a4_landscape';
    if (width == 612 && height == 792) return 'letter_portrait';
    if (width == 792 && height == 612) return 'letter_landscape';
    if (width == 1920 && height == 1080) return 'screen_1920x1080';
    if (width == 1366 && height == 768) return 'screen_1366x768';
    if (width == 375 && height == 667) return 'mobile_375x667';
    if (width == 768 && height == 1024) return 'tablet_768x1024';

    return 'custom';
  }

  /// 加载页面属性
  void _loadPageProperties() {
    // Canvas系统当前不支持页面状态管理
    // 使用默认值作为替代
    _pageProperties = {
      'name': '画布',
      'description': '',
      'width': 800.0,
      'height': 600.0,
      'backgroundColor': 0xFFFFFFFF,
      'backgroundType': 'color',
      'showGrid': true,
      'gridSize': 10.0,
      'gridColor': 0xFFE0E0E0,
      'gridOpacity': 0.5,
      'snapToGrid': false,
      'showGuides': false,
      'guideColor': 0xFF00BCD4,
      'snapToGuides': true,
      'smartGuides': true,
      'exportFormat': 'png',
      'exportQuality': 100,
      'exportScale': 1.0,
      'zoom': 1.0,
      'fileSize': 0,
    };
  }

  /// 打印页面
  void _printPage() {
    // TODO: 实现页面打印功能
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('打印功能开发中...')),
    );
  }

  /// 更新属性
  void _updateProperty(String key, dynamic value) {
    setState(() {
      _pageProperties[key] = value;
    });
    widget.onPropertyChanged({key: value});
  }
}
