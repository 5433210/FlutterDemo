/// Canvas工具栏系统 - 工具状态管理器
///
/// 职责：
/// 1. 管理当前选中的工具类型
/// 2. 管理各工具的配置状态
/// 3. 提供工具变更通知
/// 4. 支持工具状态的保存和恢复
library;

import 'package:flutter/foundation.dart';

/// 集字工具配置
class CollectionToolConfiguration extends ToolConfiguration {
  final int columns;
  final double spacing;
  final String sortOrder;

  const CollectionToolConfiguration({
    this.columns = 3,
    this.spacing = 8.0,
    this.sortOrder = 'newest',
  });

  CollectionToolConfiguration copyWith({
    int? columns,
    double? spacing,
    String? sortOrder,
  }) {
    return CollectionToolConfiguration(
      columns: columns ?? this.columns,
      spacing: spacing ?? this.spacing,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'columns': columns,
      'spacing': spacing,
      'sortOrder': sortOrder,
    };
  }

  static CollectionToolConfiguration fromMap(Map<String, dynamic> map) {
    return CollectionToolConfiguration(
      columns: map['columns'] as int? ?? 3,
      spacing: (map['spacing'] as num?)?.toDouble() ?? 8.0,
      sortOrder: map['sortOrder'] as String? ?? 'newest',
    );
  }
}

/// 默认工具配置
class DefaultToolConfiguration extends ToolConfiguration {
  const DefaultToolConfiguration();

  @override
  Map<String, dynamic> toMap() => <String, dynamic>{};

  static DefaultToolConfiguration fromMap(Map<String, dynamic> map) {
    return const DefaultToolConfiguration();
  }
}

/// 图像工具配置
class ImageToolConfiguration extends ToolConfiguration {
  final double opacity;
  final String blendMode;
  final bool maintainAspectRatio;

  const ImageToolConfiguration({
    this.opacity = 1.0,
    this.blendMode = 'normal',
    this.maintainAspectRatio = true,
  });

  ImageToolConfiguration copyWith({
    double? opacity,
    String? blendMode,
    bool? maintainAspectRatio,
  }) {
    return ImageToolConfiguration(
      opacity: opacity ?? this.opacity,
      blendMode: blendMode ?? this.blendMode,
      maintainAspectRatio: maintainAspectRatio ?? this.maintainAspectRatio,
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'opacity': opacity,
      'blendMode': blendMode,
      'maintainAspectRatio': maintainAspectRatio,
    };
  }

  static ImageToolConfiguration fromMap(Map<String, dynamic> map) {
    return ImageToolConfiguration(
      opacity: (map['opacity'] as num?)?.toDouble() ?? 1.0,
      blendMode: map['blendMode'] as String? ?? 'normal',
      maintainAspectRatio: map['maintainAspectRatio'] as bool? ?? true,
    );
  }
}

/// 文本工具配置
class TextToolConfiguration extends ToolConfiguration {
  final String fontFamily;
  final double fontSize;
  final String color;
  final bool isBold;
  final bool isItalic;
  final String alignment;

  const TextToolConfiguration({
    this.fontFamily = 'System',
    this.fontSize = 16.0,
    this.color = '#000000',
    this.isBold = false,
    this.isItalic = false,
    this.alignment = 'left',
  });

  TextToolConfiguration copyWith({
    String? fontFamily,
    double? fontSize,
    String? color,
    bool? isBold,
    bool? isItalic,
    String? alignment,
  }) {
    return TextToolConfiguration(
      fontFamily: fontFamily ?? this.fontFamily,
      fontSize: fontSize ?? this.fontSize,
      color: color ?? this.color,
      isBold: isBold ?? this.isBold,
      isItalic: isItalic ?? this.isItalic,
      alignment: alignment ?? this.alignment,
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'fontFamily': fontFamily,
      'fontSize': fontSize,
      'color': color,
      'isBold': isBold,
      'isItalic': isItalic,
      'alignment': alignment,
    };
  }

  static TextToolConfiguration fromMap(Map<String, dynamic> map) {
    return TextToolConfiguration(
      fontFamily: map['fontFamily'] as String? ?? 'System',
      fontSize: (map['fontSize'] as num?)?.toDouble() ?? 16.0,
      color: map['color'] as String? ?? '#000000',
      isBold: map['isBold'] as bool? ?? false,
      isItalic: map['isItalic'] as bool? ?? false,
      alignment: map['alignment'] as String? ?? 'left',
    );
  }
}

/// 工具配置基类
abstract class ToolConfiguration {
  const ToolConfiguration();

  /// 将配置转换为Map
  Map<String, dynamic> toMap();

  /// 从Map创建配置
  static ToolConfiguration fromMap(ToolType type, Map<String, dynamic> map) {
    switch (type) {
      case ToolType.text:
        return TextToolConfiguration.fromMap(map);
      case ToolType.image:
        return ImageToolConfiguration.fromMap(map);
      case ToolType.collection:
        return CollectionToolConfiguration.fromMap(map);
      default:
        return DefaultToolConfiguration.fromMap(map);
    }
  }
}

/// 工具状态管理器
class ToolStateManager extends ChangeNotifier {
  ToolType _currentTool = ToolType.select;
  final Map<ToolType, ToolConfiguration> _toolConfigurations = {};
  ToolType? _previousTool;
  final List<ToolType> _toolHistory = [];
  bool _isDisposed = false;

  /// 是否可以返回上一个工具
  bool get canGoBack => _toolHistory.isNotEmpty;

  /// 获取当前工具配置
  ToolConfiguration? get currentConfiguration =>
      _toolConfigurations[_currentTool];

  /// 获取当前工具类型
  ToolType get currentTool => _currentTool;

  /// 是否有历史记录
  bool get hasHistory => _toolHistory.isNotEmpty;

  /// 是否已释放
  bool get isDisposed => _isDisposed;

  /// 获取上一个工具类型
  ToolType? get previousTool => _previousTool;

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  /// 导出工具状态
  Map<String, dynamic> exportState() {
    return {
      'currentTool': _currentTool.value,
      'previousTool': _previousTool?.value,
      'configurations': _toolConfigurations.map(
        (key, value) => MapEntry(key.value, value.toMap()),
      ),
    };
  }

  /// 获取指定工具的配置 (测试兼容方法)
  ToolConfiguration getConfiguration(ToolType toolType) {
    return getOrCreateToolConfiguration(toolType);
  }

  /// 获取指定工具的配置，如果不存在则创建默认配置
  ToolConfiguration getOrCreateToolConfiguration(ToolType toolType) {
    return _toolConfigurations[toolType] ??
        _createDefaultConfiguration(toolType);
  }

  /// 获取指定工具的配置
  ToolConfiguration? getToolConfiguration(ToolType toolType) {
    return _toolConfigurations[toolType];
  }

  /// 返回上一个工具
  ToolType? goBack() {
    if (_toolHistory.isNotEmpty) {
      final previousTool = _toolHistory.removeLast();
      _currentTool = previousTool;
      notifyListeners();
      return previousTool;
    }
    return null;
  }

  /// 导入工具状态
  void importState(Map<String, dynamic> state) {
    try {
      // 设置当前工具
      final currentToolValue = state['currentTool'] as String?;
      if (currentToolValue != null) {
        final tool = ToolType.values.firstWhere(
          (t) => t.value == currentToolValue,
          orElse: () => ToolType.select,
        );
        _currentTool = tool;
      }

      // 设置上一个工具
      final previousToolValue = state['previousTool'] as String?;
      if (previousToolValue != null) {
        _previousTool = ToolType.values.firstWhere(
          (t) => t.value == previousToolValue,
          orElse: () => ToolType.select,
        );
      }

      // 导入配置
      final configurationsMap =
          state['configurations'] as Map<String, dynamic>?;
      if (configurationsMap != null) {
        _toolConfigurations.clear();
        for (final entry in configurationsMap.entries) {
          final toolType = ToolType.values.firstWhere(
            (t) => t.value == entry.key,
            orElse: () => ToolType.select,
          );
          if (toolType != ToolType.select &&
              entry.value is Map<String, dynamic>) {
            _toolConfigurations[toolType] = ToolConfiguration.fromMap(
              toolType,
              entry.value as Map<String, dynamic>,
            );
          }
        }
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error importing tool state: $e');
    }
  }

  /// 重置所有工具配置
  void resetAllConfigurations() {
    _toolConfigurations.clear();
    notifyListeners();
  }

  /// 重置工具配置
  void resetToolConfiguration(ToolType toolType) {
    _toolConfigurations.remove(toolType);
    if (_currentTool == toolType) {
      notifyListeners();
    }
  }

  /// 设置当前工具 (测试兼容方法)
  void setCurrentTool(ToolType toolType) {
    setTool(toolType);
    _toolHistory.add(_currentTool);
  }

  /// 设置当前工具
  void setTool(ToolType toolType) {
    if (_currentTool != toolType) {
      _previousTool = _currentTool;
      _currentTool = toolType;
      notifyListeners();
    }
  }

  /// 切换回上一个工具
  void switchToPreviousTool() {
    if (_previousTool != null) {
      final temp = _currentTool;
      _currentTool = _previousTool!;
      _previousTool = temp;
      notifyListeners();
    }
  }

  /// 更新工具配置 (测试兼容方法)
  void updateConfiguration(ToolType toolType, ToolConfiguration configuration) {
    updateToolConfiguration(toolType, configuration);
  }

  /// 更新工具配置
  void updateToolConfiguration(
      ToolType toolType, ToolConfiguration configuration) {
    _toolConfigurations[toolType] = configuration;
    if (_currentTool == toolType) {
      notifyListeners();
    }
  }

  /// 创建默认配置
  ToolConfiguration _createDefaultConfiguration(ToolType toolType) {
    switch (toolType) {
      case ToolType.text:
        return const TextToolConfiguration();
      case ToolType.image:
        return const ImageToolConfiguration();
      case ToolType.collection:
        return const CollectionToolConfiguration();
      default:
        return const DefaultToolConfiguration();
    }
  }
}

/// 工具类型枚举
enum ToolType {
  /// 选择工具
  select('select', 'Select', 'select_all'),

  /// 文本工具
  text('text', 'Text', 'text_fields'),

  /// 图像工具
  image('image', 'Image', 'image'),

  /// 集字工具
  collection('collection', 'Collection', 'grid_on'),

  /// 移动工具
  move('move', 'Move', 'open_with'),

  /// 缩放工具
  resize('resize', 'Resize', 'crop_free'),

  /// 旋转工具
  rotate('rotate', 'Rotate', 'rotate_90_degrees_ccw'),

  /// 平移工具
  pan('pan', 'Pan', 'pan_tool'),

  /// 缩放画布工具
  zoom('zoom', 'Zoom', 'zoom_in');

  final String value;

  final String displayName;
  final String iconName;
  const ToolType(this.value, this.displayName, this.iconName);

  /// 是否为元素创建工具
  bool get isCreationTool {
    switch (this) {
      case ToolType.text:
      case ToolType.image:
      case ToolType.collection:
        return true;
      default:
        return false;
    }
  }

  /// 是否为操作工具
  bool get isManipulationTool {
    switch (this) {
      case ToolType.select:
      case ToolType.move:
      case ToolType.resize:
      case ToolType.rotate:
        return true;
      default:
        return false;
    }
  }

  /// 是否为视图工具
  bool get isViewTool {
    switch (this) {
      case ToolType.pan:
      case ToolType.zoom:
        return true;
      default:
        return false;
    }
  }
}
