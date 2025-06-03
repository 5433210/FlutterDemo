import 'package:flutter/foundation.dart';

import '../adapters/property_panel_adapter.dart';

/// 格式刷服务
/// 负责管理格式的复制、存储和应用
class FormatPainterService extends ChangeNotifier {
  /// 单例实例
  static final FormatPainterService _instance = FormatPainterService._();

  /// 获取单例实例
  static FormatPainterService get instance => _instance;

  /// 当前复制的格式数据
  Map<String, dynamic>? _copiedFormat;

  /// 格式来源的元素类型
  String? _sourceElementType;

  /// 格式复制的时间戳
  DateTime? _copiedAt;

  /// 私有构造函数
  FormatPainterService._();

  /// 获取格式复制的时间
  DateTime? get copiedAt => _copiedAt;

  /// 获取复制的格式数据
  Map<String, dynamic>? get copiedFormat =>
      _copiedFormat != null ? Map<String, dynamic>.from(_copiedFormat!) : null;

  /// 是否有可用的格式
  bool get hasFormat => _copiedFormat != null && _sourceElementType != null;

  /// 检查格式是否过期（24小时后过期）
  bool get isFormatExpired {
    if (_copiedAt == null) return true;

    final now = DateTime.now();
    final difference = now.difference(_copiedAt!);
    return difference.inHours >= 24;
  }

  /// 获取格式来源的元素类型
  String? get sourceElementType => _sourceElementType;

  /// 将格式应用到目标元素
  /// [targetElements] 目标元素列表
  /// [adapters] 对应的适配器映射
  /// 返回应用了格式的元素列表
  List<Map<String, dynamic>> applyFormat(
    List<Map<String, dynamic>> targetElements,
    Map<String, PropertyPanelAdapter> adapters,
  ) {
    if (!hasFormat) {
      debugPrint('格式刷: 没有可用的格式数据');
      return targetElements;
    }

    final modifiedElements = <Map<String, dynamic>>[];

    for (final element in targetElements) {
      try {
        final elementType = element['type'] as String?;
        final adapter = adapters[elementType];

        if (adapter == null) {
          debugPrint('格式刷: 未找到类型 $elementType 的适配器');
          modifiedElements.add(element);
          continue;
        } // 应用格式到目标元素
        adapter.applyFormatData(element, _copiedFormat!);
        modifiedElements.add(element);

        debugPrint('格式刷: 已应用格式到 ${element['id']} ($elementType)');
      } catch (e) {
        debugPrint('格式刷: 应用格式失败 - ${element['id']}: $e');
        modifiedElements.add(element);
      }
    }

    return modifiedElements;
  }

  /// 检查格式是否可以应用到指定类型的元素
  /// [elementType] 目标元素类型
  /// [adapter] 目标元素的适配器
  bool canApplyToElementType(String elementType, PropertyPanelAdapter adapter) {
    if (!hasFormat || _sourceElementType == null) {
      return false;
    }

    return adapter.canAcceptFormatFrom(_sourceElementType!, _copiedFormat!);
  }

  /// 清除复制的格式
  void clearFormat() {
    _copiedFormat = null;
    _sourceElementType = null;
    _copiedAt = null;

    debugPrint('格式刷: 已清除格式');
    notifyListeners();
  }

  /// 复制元素的格式
  /// [element] 要复制格式的元素
  /// [adapter] 元素对应的适配器
  void copyFormat(Map<String, dynamic> element, PropertyPanelAdapter adapter) {
    try {
      final formatData = adapter.extractFormatData(element);
      _copiedFormat = formatData;
      _sourceElementType = element['type'] as String?;
      _copiedAt = DateTime.now();
      debugPrint('格式刷: 已复制格式 - 类型: $_sourceElementType');
      debugPrint('格式刷: 复制的属性: ${formatData?.keys.join(', ') ?? 'none'}');

      notifyListeners();
    } catch (e) {
      debugPrint('格式刷: 复制格式失败 - $e');
      clearFormat();
    }
  }

  /// 获取格式的详细信息用于调试
  Map<String, dynamic> getFormatDebugInfo() {
    return {
      'hasFormat': hasFormat,
      'sourceElementType': _sourceElementType,
      'copiedAt': _copiedAt?.toIso8601String(),
      'isExpired': isFormatExpired,
      'formatKeys': _copiedFormat?.keys.toList() ?? [],
      'formatData': _copiedFormat,
    };
  }

  /// 获取格式的预览信息
  /// [adapter] 用于解析格式的适配器
  Map<String, String> getFormatPreview(PropertyPanelAdapter? adapter) {
    if (!hasFormat || adapter == null) {
      return {};
    }

    try {
      final preview = adapter.getFormatPreview(_copiedFormat!);
      return {'preview': preview};
    } catch (e) {
      debugPrint('格式刷: 获取格式预览失败 - $e');
      return {};
    }
  }
}
