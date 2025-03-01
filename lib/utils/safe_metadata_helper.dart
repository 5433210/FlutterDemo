import 'dart:convert';

import 'package:flutter/foundation.dart';

/// 用于安全处理元数据的工具类
class SafeMetadataHelper {
  /// 安全地获取标签列表
  static List<String> getTags(dynamic metadata) {
    try {
      if (metadata == null) {
        return [];
      }

      Map<String, dynamic> metadataMap;

      if (metadata is String) {
        metadataMap = parseMetadata(metadata);
      } else if (metadata is Map) {
        metadataMap = Map<String, dynamic>.from(metadata);
      } else {
        return [];
      }

      if (metadataMap.containsKey('tags') && metadataMap['tags'] is List) {
        final dynamicTags = metadataMap['tags'] as List;
        // 显式转换为 List<String>
        return dynamicTags.map<String>((item) => item.toString()).toList();
      }
    } catch (e) {
      debugPrint('Error getting tags: $e');
    }

    return [];
  }

  /// 安全地解析元数据 JSON 字符串
  static Map<String, dynamic> parseMetadata(dynamic rawMetadata) {
    if (rawMetadata == null) {
      return {'tags': []};
    }

    try {
      if (rawMetadata is String) {
        if (rawMetadata.isEmpty || rawMetadata == 'null') {
          return {'tags': []};
        }
        return jsonDecode(rawMetadata) as Map<String, dynamic>;
      } else if (rawMetadata is Map) {
        return Map<String, dynamic>.from(rawMetadata);
      }
    } catch (e) {
      debugPrint('Error parsing metadata: $e');
    }

    return {'tags': []};
  }
}
