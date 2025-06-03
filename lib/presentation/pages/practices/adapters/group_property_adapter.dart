/// 组属性适配器
/// 用于编辑组的属性，如名称、可见性、锁定状态等
library;

import 'package:flutter/material.dart';

import 'property_panel_adapter.dart';

/// 组属性适配器
class GroupPropertyAdapter extends BasePropertyPanelAdapter {
  @override
  List<String> get supportedElementTypes => ['group'];

  @override
  Widget buildPropertyEditor({
    required BuildContext context,
    required List<dynamic> selectedElements,
    required Function(String elementId, String property, dynamic value)
        onPropertyChanged,
    PropertyPanelConfig? config,
  }) {
    if (selectedElements.isEmpty) {
      return const Center(child: Text('请选择一个组'));
    }

    final element = selectedElements.first;
    final definitions = getPropertyDefinitions('group').values.toList();

    return ListView.builder(
      itemCount: definitions.length,
      itemBuilder: (context, index) {
        final property = definitions[index];
        final currentValue = getPropertyValue(element, property.name);

        return ListTile(
          title: Text(property.displayName),
          subtitle: _buildPropertyInput(
            property,
            currentValue,
            (value) {
              if (element is Map<String, dynamic> &&
                  element.containsKey('id')) {
                onPropertyChanged(element['id'], property.name, value);
              }
            },
          ),
        );
      },
    );
  }

  @override
  dynamic getDefaultValue(String propertyName) {
    final definitions = getPropertyDefinitions('group');
    return definitions[propertyName]?.defaultValue;
  }

  @override
  Map<String, PropertyDefinition> getPropertyDefinitions(String elementType) {
    return {
      'name': const PropertyDefinition(
        name: 'name',
        displayName: '组名',
        type: PropertyType.string,
        isRequired: true,
        description: '组的名称',
      ),
      'visible': const PropertyDefinition(
        name: 'visible',
        displayName: '可见',
        type: PropertyType.boolean,
        defaultValue: true,
        description: '组是否可见',
      ),
      'locked': const PropertyDefinition(
        name: 'locked',
        displayName: '锁定',
        type: PropertyType.boolean,
        defaultValue: false,
        description: '组是否锁定编辑',
      ),
      'opacity': const PropertyDefinition(
        name: 'opacity',
        displayName: '透明度',
        type: PropertyType.number,
        defaultValue: 1.0,
        minValue: 0.0,
        maxValue: 1.0,
        description: '组的透明度',
      ),
    };
  }

  @override
  dynamic getPropertyValue(dynamic element, String propertyName) {
    if (element is! Map<String, dynamic>) return null;

    switch (propertyName) {
      case 'name':
        return element['name'] ?? '未命名组';
      case 'visible':
        return element['visible'] ?? true;
      case 'locked':
        return element['locked'] ?? false;
      case 'opacity':
        return element['opacity'] ?? 1.0;
      default:
        return null;
    }
  }

  @override
  void setPropertyValue(dynamic element, String propertyName, dynamic value) {
    if (element is! Map<String, dynamic>) return;

    switch (propertyName) {
      case 'name':
        if (value is String) element['name'] = value;
        break;
      case 'visible':
        if (value is bool) element['visible'] = value;
        break;
      case 'locked':
        if (value is bool) element['locked'] = value;
        break;
      case 'opacity':
        if (value is num) {
          element['opacity'] = value.toDouble().clamp(0.0, 1.0);
        }
        break;
    }
  }

  Widget _buildPropertyInput(
    PropertyDefinition property,
    dynamic currentValue,
    Function(dynamic) onChanged,
  ) {
    switch (property.type) {
      case PropertyType.string:
        return TextFormField(
          initialValue: currentValue?.toString() ?? '',
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: property.description,
          ),
        );
      case PropertyType.number:
        return TextFormField(
          initialValue: currentValue?.toString() ?? '',
          keyboardType: TextInputType.number,
          onChanged: (value) {
            final numValue = double.tryParse(value);
            if (numValue != null) {
              onChanged(numValue);
            }
          },
          decoration: InputDecoration(
            hintText: property.description,
          ),
        );
      case PropertyType.boolean:
        return SwitchListTile(
          value: currentValue == true,
          onChanged: onChanged,
          title: Text(property.description ?? ''),
          dense: true,
        );
      default:
        return Text(currentValue?.toString() ?? '');
    }
  }
}
