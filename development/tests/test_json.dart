import 'dart:convert';

void main() {
  // 测试JSON格式是否正确
  const styleJson =
      '''{"category": "style", "displayName": "书法风格", "updateTime": null, "items": [{"key": "regular", "displayName": "楷书", "sortOrder": 1, "isSystem": true, "isActive": true, "localizedNames": {"en": "Regular Script", "zh": "楷书"}, "createTime": null, "updateTime": null}]}''';

  const toolJson =
      '''{"category": "tool", "displayName": "书写工具", "updateTime": null, "items": [{"key": "brush", "displayName": "毛笔", "sortOrder": 1, "isSystem": true, "isActive": true, "localizedNames": {"en": "Brush", "zh": "毛笔"}, "createTime": null, "updateTime": null}]}''';

  try {
    print('测试样式JSON解析...');
    final styleData = jsonDecode(styleJson);
    print('解析成功: $styleData');

    print('\n测试工具JSON解析...');
    final toolData = jsonDecode(toolJson);
    print('解析成功: $toolData');

    print('\n检查必需字段...');
    print('Style category: ${styleData['category']}');
    print('Style displayName: ${styleData['displayName']}');
    print('Tool category: ${toolData['category']}');
    print('Tool displayName: ${toolData['displayName']}');
  } catch (e) {
    print('JSON解析失败: $e');
  }
}
