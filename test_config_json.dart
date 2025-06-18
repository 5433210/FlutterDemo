import 'dart:convert';

import 'lib/domain/models/config/config_item.dart';

void main() {
  print('🧪 Testing ConfigCategory JSON parsing...');

  // Test JSON data that should match what's in the database
  const toolJson = '''
{
  "category": "tool",
  "displayName": "书写工具",
  "updateTime": null,
  "items": [
    {
      "key": "brush",
      "displayName": "毛笔",
      "sortOrder": 1,
      "isSystem": true,
      "isActive": true,
      "localizedNames": {"en": "Brush", "zh": "毛笔"},
      "createTime": null,
      "updateTime": null
    }
  ]
}''';

  try {
    print('📝 Testing JSON data:');
    print(toolJson);

    final jsonMap = jsonDecode(toolJson) as Map<String, dynamic>;
    print('✅ JSON decoded successfully');
    print('📋 Decoded map: $jsonMap');

    final category = ConfigCategory.fromJson(jsonMap);
    print('✅ ConfigCategory created successfully');
    print('📂 Category: ${category.category}');
    print('🏷️ Display Name: ${category.displayName}');
    print('📦 Items count: ${category.items.length}');

    if (category.items.isNotEmpty) {
      final firstItem = category.items.first;
      print('🔧 First item: ${firstItem.key} - ${firstItem.displayName}');
    }
  } catch (e, stackTrace) {
    print('❌ Error: $e');
    print('📍 Stack trace: $stackTrace');
  }
}
