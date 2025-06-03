/// 属性面板适配器接口
/// 用于统一不同类型元素的属性编辑
library;

import 'package:flutter/material.dart';

/// 属性面板适配器基类
abstract class BasePropertyPanelAdapter implements PropertyPanelAdapter {
  @override
  void applyFormatData(dynamic element, Map<String, dynamic> formatData) {
    // Default implementation - applies format data to element
    for (final entry in formatData.entries) {
      try {
        setPropertyValue(element, entry.key, entry.value);
      } catch (e) {
        // Ignore errors for properties that can't be set
      }
    }
  }

  @override
  bool canAcceptFormatFrom(
      String sourceElementType, Map<String, dynamic> formatData) {
    // Default implementation - check if any of the format properties are supported
    final supportedTypes = supportedElementTypes;
    if (supportedTypes.isEmpty) return false;

    // Check if we have any common properties with the format data
    final definitions = getPropertyDefinitions(supportedTypes.first);
    return formatData.keys.any((key) => definitions.containsKey(key));
  }

  @override
  bool canHandle(String elementType) {
    return supportedElementTypes.contains(elementType);
  }

  @override
  Map<String, dynamic>? extractFormatData(dynamic element) {
    // Default implementation - extracts common formatting properties
    final formatData = <String, dynamic>{};

    // Try to extract common properties that might exist
    try {
      for (final propertyName in [
        'color',
        'backgroundColor',
        'fontSize',
        'fontWeight',
        'fontStyle'
      ]) {
        final value = getPropertyValue(element, propertyName);
        if (value != null) {
          formatData[propertyName] = value;
        }
      }
    } catch (e) {
      // Ignore errors for properties that don't exist
    }

    return formatData.isEmpty ? null : formatData;
  }

  @override
  String formatPropertyValue(String propertyName, dynamic value) {
    final definition = getPropertyDefinitions('').values.firstWhere(
        (def) => def.name == propertyName,
        orElse: () => const PropertyDefinition(
            name: '', displayName: '', type: PropertyType.string));

    if (value == null) return '';

    switch (definition.type) {
      case PropertyType.number:
        if (definition.unit != null) {
          return '$value ${definition.unit}';
        }
        return value.toString();
      case PropertyType.boolean:
        return value ? '是' : '否';
      case PropertyType.color:
        return value.toString();
      default:
        return value.toString();
    }
  }

  @override
  String getFormatPreview(Map<String, dynamic> formatData) {
    // Default implementation - creates a preview string
    final preview = <String>[];

    if (formatData.containsKey('color')) {
      preview.add('颜色: ${formatData['color']}');
    }
    if (formatData.containsKey('backgroundColor')) {
      preview.add('背景: ${formatData['backgroundColor']}');
    }
    if (formatData.containsKey('fontSize')) {
      preview.add('字号: ${formatData['fontSize']}');
    }
    if (formatData.containsKey('fontWeight')) {
      preview.add('粗细: ${formatData['fontWeight']}');
    }

    return preview.isEmpty ? '无格式信息' : preview.join(', ');
  }

  @override
  void setBatchProperties(
      List<dynamic> elements, Map<String, dynamic> properties) {
    for (final element in elements) {
      for (final entry in properties.entries) {
        setPropertyValue(element, entry.key, entry.value);
      }
    }
  }

  @override
  ValidationResult validatePropertyValue(String propertyName, dynamic value) {
    final definition = getPropertyDefinitions('').values.firstWhere(
        (def) => def.name == propertyName,
        orElse: () => const PropertyDefinition(
            name: '', displayName: '', type: PropertyType.string));

    if (definition.name.isEmpty) {
      return ValidationResult.invalid('未知的属性: $propertyName');
    }

    // 基础验证
    if (definition.isRequired && (value == null || value.toString().isEmpty)) {
      return ValidationResult.invalid('${definition.displayName} 是必填项');
    }

    // 数值范围验证
    if (definition.type == PropertyType.number && value is num) {
      if (definition.minValue != null && value < definition.minValue!) {
        return ValidationResult.invalid(
            '${definition.displayName} 不能小于 ${definition.minValue}');
      }
      if (definition.maxValue != null && value > definition.maxValue!) {
        return ValidationResult.invalid(
            '${definition.displayName} 不能大于 ${definition.maxValue}');
      }
    }

    // 枚举值验证
    if (definition.allowedValues != null &&
        !definition.allowedValues!.contains(value)) {
      return ValidationResult.invalid('${definition.displayName} 的值无效');
    }
    return ValidationResult.valid();
  }
}

/// 属性变更事件
class PropertyChangeEvent {
  final String elementId;
  final String propertyName;
  final dynamic oldValue;
  final dynamic newValue;
  final DateTime timestamp;

  PropertyChangeEvent({
    required this.elementId,
    required this.propertyName,
    required this.oldValue,
    required this.newValue,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

/// 属性定义
class PropertyDefinition {
  final String name;
  final String displayName;
  final PropertyType type;
  final dynamic defaultValue;
  final List<dynamic>? allowedValues;
  final double? minValue;
  final double? maxValue;
  final bool isRequired;
  final bool isAdvanced;
  final String? description;
  final String? unit;

  const PropertyDefinition({
    required this.name,
    required this.displayName,
    required this.type,
    this.defaultValue,
    this.allowedValues,
    this.minValue,
    this.maxValue,
    this.isRequired = false,
    this.isAdvanced = false,
    this.description,
    this.unit,
  });
}

/// 属性组
class PropertyGroup {
  final String id;
  final String title;
  final List<PropertyDefinition> properties;
  final bool isCollapsed;
  final bool isVisible;

  const PropertyGroup({
    required this.id,
    required this.title,
    required this.properties,
    this.isCollapsed = false,
    this.isVisible = true,
  });
}

/// 属性面板适配器接口
abstract class PropertyPanelAdapter {
  /// 获取支持的元素类型
  List<String> get supportedElementTypes;

  /// 应用格式数据到元素
  void applyFormatData(dynamic element, Map<String, dynamic> formatData);

  /// 构建属性编辑UI
  Widget buildPropertyEditor({
    required BuildContext context,
    required List<dynamic> selectedElements,
    required Function(String elementId, String property, dynamic value)
        onPropertyChanged,
    PropertyPanelConfig? config,
  });

  /// 检查是否可以从指定类型接受格式
  bool canAcceptFormatFrom(
      String sourceElementType, Map<String, dynamic> formatData);

  /// 判断是否支持指定类型的元素
  bool canHandle(String elementType);

  /// 提取元素的格式数据
  Map<String, dynamic>? extractFormatData(dynamic element);

  /// 格式化属性值显示
  String formatPropertyValue(String propertyName, dynamic value);

  /// 获取属性的默认值
  dynamic getDefaultValue(String propertyName);

  /// 获取格式预览文本
  String getFormatPreview(Map<String, dynamic> formatData);

  /// 获取元素的属性定义
  Map<String, PropertyDefinition> getPropertyDefinitions(String elementType);

  // Format painter methods
  /// 获取属性的当前值
  dynamic getPropertyValue(dynamic element, String propertyName);

  /// 批量设置属性
  void setBatchProperties(
      List<dynamic> elements, Map<String, dynamic> properties);

  /// 设置属性值
  void setPropertyValue(dynamic element, String propertyName, dynamic value);

  /// 验证属性值
  ValidationResult validatePropertyValue(String propertyName, dynamic value);
}

/// 属性面板配置
class PropertyPanelConfig {
  final bool enableBatchEdit;
  final bool showAdvancedProperties;
  final bool enableUndoRedo;
  final Map<String, dynamic> customSettings;

  const PropertyPanelConfig({
    this.enableBatchEdit = false,
    this.showAdvancedProperties = false,
    this.enableUndoRedo = true,
    this.customSettings = const {},
  });
}

/// 属性类型枚举
enum PropertyType {
  string,
  text,
  number,
  boolean,
  color,
  font,
  select,
  dropdown,
  multiSelect,
  slider,
  file,
  date,
  display,
  custom,
  // 新增的属性类型
  image,
  video,
  audio,
  document,
}

/// 验证结果
class ValidationResult {
  final bool isValid;
  final String? errorMessage;

  const ValidationResult({
    required this.isValid,
    this.errorMessage,
  });

  factory ValidationResult.invalid(String message) => ValidationResult(
        isValid: false,
        errorMessage: message,
      );

  factory ValidationResult.valid() => const ValidationResult(isValid: true);
}
