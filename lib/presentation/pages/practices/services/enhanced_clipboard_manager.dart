import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../adapters/property_panel_adapter.dart';

/// 剪贴板数据类型
enum ClipboardDataType {
  practiceElements, // 字帖元素
  formatData, // 格式数据
  systemClipboard, // 系统剪贴板内容
}

/// 剪贴板项目
class ClipboardItem {
  final String id;
  final ClipboardDataType type;
  final Map<String, dynamic> data;
  final DateTime createdAt;
  final String? description;

  ClipboardItem({
    required this.id,
    required this.type,
    required this.data,
    required this.createdAt,
    this.description,
  });

  /// 从JSON创建
  factory ClipboardItem.fromJson(Map<String, dynamic> json) {
    return ClipboardItem(
      id: json['id'] as String,
      type: ClipboardDataType.values[json['type'] as int],
      data: Map<String, dynamic>.from(json['data'] as Map),
      createdAt: DateTime.parse(json['createdAt'] as String),
      description: json['description'] as String?,
    );
  }

  /// 是否过期（7天后过期）
  bool get isExpired {
    final now = DateTime.now();
    final difference = now.difference(createdAt);
    return difference.inDays >= 7;
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.index,
      'data': data,
      'createdAt': createdAt.toIso8601String(),
      'description': description,
    };
  }
}

/// 增强的剪贴板管理器
class EnhancedClipboardManager extends ChangeNotifier {
  /// 单例实例
  static final EnhancedClipboardManager _instance =
      EnhancedClipboardManager._();

  /// 最大历史记录数量
  static const int _maxHistoryItems = 20;

  /// 获取单例实例
  static EnhancedClipboardManager get instance => _instance;

  /// 内部剪贴板历史（最多保存20项）
  final List<ClipboardItem> _clipboardHistory = [];

  /// 当前选中的剪贴板项目
  ClipboardItem? _currentItem;

  /// 系统剪贴板监控定时器
  DateTime? _lastSystemClipboardCheck;

  /// 私有构造函数
  EnhancedClipboardManager._();

  /// 获取当前项目
  ClipboardItem? get currentItem => _currentItem;

  /// 是否有可用的内容
  bool get hasContent => _currentItem != null;

  /// 是否有字帖元素
  bool get hasElements =>
      _currentItem?.type == ClipboardDataType.practiceElements;

  /// 获取剪贴板历史
  List<ClipboardItem> get history => List.unmodifiable(_clipboardHistory);

  /// 检查系统剪贴板并同步内容
  Future<void> checkSystemClipboard() async {
    try {
      final data = await Clipboard.getData(Clipboard.kTextPlain);
      if (data?.text != null && data!.text!.isNotEmpty) {
        // 尝试解析为JSON
        final jsonData = _tryParseJson(data.text!);

        if (jsonData != null && _isValidClipboardData(jsonData)) {
          await _importFromSystemClipboard(jsonData);
        }
      }

      _lastSystemClipboardCheck = DateTime.now();
    } catch (e) {
      debugPrint('剪贴板: 检查系统剪贴板失败 - $e');
    }
  }

  /// 清理过期项目
  void cleanupExpiredItems() {
    final beforeCount = _clipboardHistory.length;
    _clipboardHistory.removeWhere((item) => item.isExpired);

    if (_currentItem?.isExpired == true) {
      _currentItem =
          _clipboardHistory.isNotEmpty ? _clipboardHistory.first : null;
    }

    final removedCount = beforeCount - _clipboardHistory.length;
    if (removedCount > 0) {
      debugPrint('剪贴板: 已清理 $removedCount 个过期项目');
      notifyListeners();
    }
  }

  /// 清空剪贴板
  void clear() {
    _clipboardHistory.clear();
    _currentItem = null;
    debugPrint('剪贴板: 已清空');
    notifyListeners();
  }

  /// 复制字帖元素到剪贴板
  Future<void> copyElements(
    List<Map<String, dynamic>> elements,
    Map<String, PropertyPanelAdapter> adapters,
  ) async {
    if (elements.isEmpty) {
      debugPrint('剪贴板: 没有要复制的元素');
      return;
    }

    try {
      // 准备复制数据
      final copyData = {
        'elements': elements,
        'elementCount': elements.length,
        'elementTypes': elements.map((e) => e['type']).toSet().toList(),
        'adapters': adapters.keys.toList(),
        'copiedAt': DateTime.now().toIso8601String(),
      };

      // 创建剪贴板项目
      final item = ClipboardItem(
        id: 'elements_${DateTime.now().millisecondsSinceEpoch}',
        type: ClipboardDataType.practiceElements,
        data: copyData,
        createdAt: DateTime.now(),
        description:
            '${elements.length}个元素: ${(copyData['elementTypes'] as List<dynamic>?)?.join(', ') ?? ''}',
      );

      // 添加到历史记录
      _addToHistory(item);
      _currentItem = item;

      // 同时复制到系统剪贴板
      await _copyToSystemClipboard(item);

      debugPrint('剪贴板: 已复制 ${elements.length} 个元素');
      notifyListeners();
    } catch (e) {
      debugPrint('剪贴板: 复制元素失败 - $e');
    }
  }

  /// 复制格式数据到剪贴板
  Future<void> copyFormat(
    Map<String, dynamic> formatData,
    String sourceElementType,
  ) async {
    try {
      final copyData = {
        'format': formatData,
        'sourceElementType': sourceElementType,
        'copiedAt': DateTime.now().toIso8601String(),
      };

      final item = ClipboardItem(
        id: 'format_${DateTime.now().millisecondsSinceEpoch}',
        type: ClipboardDataType.formatData,
        data: copyData,
        createdAt: DateTime.now(),
        description: '格式数据: $sourceElementType',
      );

      _addToHistory(item);
      _currentItem = item;

      debugPrint('剪贴板: 已复制格式数据');
      notifyListeners();
    } catch (e) {
      debugPrint('剪贴板: 复制格式失败 - $e');
    }
  }

  /// 获取剪贴板状态信息
  Map<String, dynamic> getStatusInfo() {
    return {
      'hasContent': hasContent,
      'hasElements': hasElements,
      'currentItemType': _currentItem?.type.name,
      'currentItemDescription': _currentItem?.description,
      'historyCount': _clipboardHistory.length,
      'lastSystemCheck': _lastSystemClipboardCheck?.toIso8601String(),
    };
  }

  /// 粘贴元素
  List<Map<String, dynamic>>? pasteElements() {
    if (!hasElements) {
      debugPrint('剪贴板: 没有可粘贴的元素');
      return null;
    }

    try {
      final data = _currentItem!.data;
      final elements = data['elements'] as List<dynamic>;

      // 生成新的ID以避免冲突
      final pastedElements = elements.map((element) {
        final elementMap = Map<String, dynamic>.from(element as Map);
        elementMap['id'] =
            'element_${DateTime.now().millisecondsSinceEpoch}_${elements.indexOf(element)}';
        return elementMap;
      }).toList();

      debugPrint('剪贴板: 已粘贴 ${pastedElements.length} 个元素');
      return pastedElements;
    } catch (e) {
      debugPrint('剪贴板: 粘贴元素失败 - $e');
      return null;
    }
  }

  /// 删除历史记录项目
  void removeHistoryItem(String itemId) {
    _clipboardHistory.removeWhere((item) => item.id == itemId);

    if (_currentItem?.id == itemId) {
      _currentItem =
          _clipboardHistory.isNotEmpty ? _clipboardHistory.first : null;
    }

    debugPrint('剪贴板: 已删除历史项目');
    notifyListeners();
  }

  /// 从历史记录中选择项目
  void selectHistoryItem(String itemId) {
    final item = _clipboardHistory.firstWhere(
      (item) => item.id == itemId,
      orElse: () => throw Exception('未找到剪贴板项目: $itemId'),
    );

    _currentItem = item;
    debugPrint('剪贴板: 已选择历史项目 - ${item.description}');
    notifyListeners();
  }

  /// 添加到历史记录
  void _addToHistory(ClipboardItem item) {
    // 移除同类型的旧项目
    _clipboardHistory.removeWhere(
        (existing) => existing.type == item.type && existing.id != item.id);

    // 添加新项目到开头
    _clipboardHistory.insert(0, item);

    // 保持最大数量限制
    if (_clipboardHistory.length > _maxHistoryItems) {
      _clipboardHistory.removeRange(_maxHistoryItems, _clipboardHistory.length);
    }
  }

  /// 复制到系统剪贴板
  Future<void> _copyToSystemClipboard(ClipboardItem item) async {
    try {
      final jsonString = json.encode(item.toJson());
      await Clipboard.setData(ClipboardData(text: jsonString));
    } catch (e) {
      debugPrint('剪贴板: 复制到系统剪贴板失败 - $e');
    }
  }

  /// 从系统剪贴板导入数据
  Future<void> _importFromSystemClipboard(Map<String, dynamic> jsonData) async {
    try {
      final item = ClipboardItem.fromJson(jsonData);

      // 检查是否已存在
      final existingIndex =
          _clipboardHistory.indexWhere((existing) => existing.id == item.id);
      if (existingIndex != -1) {
        return; // 已存在，不重复添加
      }

      _addToHistory(item);
      _currentItem = item;

      debugPrint('剪贴板: 从系统剪贴板导入数据 - ${item.description}');
      notifyListeners();
    } catch (e) {
      debugPrint('剪贴板: 导入系统剪贴板数据失败 - $e');
    }
  }

  /// 验证剪贴板数据格式
  bool _isValidClipboardData(Map<String, dynamic> data) {
    return data.containsKey('id') &&
        data.containsKey('type') &&
        data.containsKey('data') &&
        data.containsKey('createdAt');
  }

  /// 尝试解析JSON
  Map<String, dynamic>? _tryParseJson(String text) {
    try {
      final decoded = json.decode(text);
      return decoded is Map<String, dynamic> ? decoded : null;
    } catch (e) {
      return null;
    }
  }
}
