import 'dart:async';
import 'dart:math';

import '../utils/check_logger.dart';

/// 可信度级别
enum ConfidenceLevel {
  proven, // 已验证
  reliable, // 可靠的
  experimental, // 实验性
  uncertain, // 不确定
}

/// 知识库配置
class KnowledgeConfig {
  final Duration learningWindow;
  final int minSamplesForLearning;
  final double minEffectivenessThreshold;
  final bool autoLearn;
  final String storagePath;

  const KnowledgeConfig({
    this.learningWindow = const Duration(days: 30),
    this.minSamplesForLearning = 10,
    this.minEffectivenessThreshold = 0.7,
    this.autoLearn = true,
    this.storagePath = 'data/knowledge',
  });
}

/// 知识条目
class KnowledgeItem {
  final String id;
  final DateTime timestamp;
  final KnowledgeType type;
  final String title;
  final String description;
  final Map<String, dynamic> context;
  final List<String> tags;
  final List<String> relatedIds;
  final KnowledgeSource source;
  final ConfidenceLevel confidence;
  final Map<String, double> effectiveness;
  final int usageCount;
  final List<String> feedback;

  const KnowledgeItem({
    required this.id,
    required this.timestamp,
    required this.type,
    required this.title,
    required this.description,
    this.context = const {},
    this.tags = const [],
    this.relatedIds = const [],
    required this.source,
    required this.confidence,
    this.effectiveness = const {},
    this.usageCount = 0,
    this.feedback = const [],
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'timestamp': timestamp.toIso8601String(),
        'type': type.toString(),
        'title': title,
        'description': description,
        'context': context,
        'tags': tags,
        'relatedIds': relatedIds,
        'source': source.toString(),
        'confidence': confidence.toString(),
        'effectiveness': effectiveness,
        'usageCount': usageCount,
        'feedback': feedback,
      };
}

/// 知识来源
enum KnowledgeSource {
  manual, // 手动录入
  automatic, // 自动学习
  imported, // 外部导入
  community, // 社区贡献
}

/// 知识类型
enum KnowledgeType {
  solution, // 解决方案
  bestPractice, // 最佳实践
  diagnostic, // 故障诊断
  optimization, // 优化建议
  prevention, // 预防措施
}

/// 运维知识库
class OpsKnowledgeBase {
  final CheckLogger logger;
  final KnowledgeConfig config;
  final _items = <String, KnowledgeItem>{};
  final _tagIndex = <String, Set<String>>{};
  final _typeIndex = <KnowledgeType, Set<String>>{};
  Timer? _learningTimer;

  OpsKnowledgeBase({
    required this.config,
    CheckLogger? logger,
  }) : logger = logger ?? CheckLogger.instance {
    _startLearningTimer();
  }

  /// 添加知识条目
  String addKnowledge({
    required KnowledgeType type,
    required String title,
    required String description,
    Map<String, dynamic> context = const {},
    List<String> tags = const [],
    List<String> relatedIds = const [],
    KnowledgeSource source = KnowledgeSource.manual,
    ConfidenceLevel confidence = ConfidenceLevel.reliable,
  }) {
    final id = _generateId();
    final item = KnowledgeItem(
      id: id,
      timestamp: DateTime.now(),
      type: type,
      title: title,
      description: description,
      context: context,
      tags: tags,
      relatedIds: relatedIds,
      source: source,
      confidence: confidence,
    );

    _items[id] = item;
    _updateIndices(item);

    logger.info('''
添加知识条目:
- ID: $id
- 类型: $type
- 标题: $title
- 标签: ${tags.join(', ')}
''');

    return id;
  }

  /// 分析知识库
  Map<String, dynamic> analyzeKnowledge() {
    // 总体统计
    final totalItems = _items.length;
    final typeStats = <KnowledgeType, int>{};
    final sourceStats = <KnowledgeSource, int>{};
    final confidenceStats = <ConfidenceLevel, int>{};
    final tagStats = <String, int>{};
    var totalUsage = 0;
    var effectiveCount = 0;

    for (final item in _items.values) {
      typeStats[item.type] = (typeStats[item.type] ?? 0) + 1;
      sourceStats[item.source] = (sourceStats[item.source] ?? 0) + 1;
      confidenceStats[item.confidence] =
          (confidenceStats[item.confidence] ?? 0) + 1;

      for (final tag in item.tags) {
        tagStats[tag] = (tagStats[tag] ?? 0) + 1;
      }

      totalUsage += item.usageCount;
      if (_calculateSuccessRate(item) >= config.minEffectivenessThreshold) {
        effectiveCount++;
      }
    }

    return {
      'totalItems': totalItems,
      'totalUsage': totalUsage,
      'effectiveCount': effectiveCount,
      'effectiveRate': totalItems > 0 ? effectiveCount / totalItems : 0.0,
      'typeStats': typeStats.map((k, v) => MapEntry(k.toString(), v)),
      'sourceStats': sourceStats.map((k, v) => MapEntry(k.toString(), v)),
      'confidenceStats':
          confidenceStats.map((k, v) => MapEntry(k.toString(), v)),
      'topTags': _sortMapByValue(tagStats).take(10).toList(),
    };
  }

  /// 删除知识条目
  bool deleteKnowledge(String id) {
    final item = _items.remove(id);
    if (item == null) return false;

    // 清理索引
    for (final tag in item.tags) {
      _tagIndex[tag]?.remove(id);
    }
    _typeIndex[item.type]?.remove(id);

    logger.info('删除知识条目: $id');
    return true;
  }

  /// 释放资源
  void dispose() {
    _learningTimer?.cancel();
    _items.clear();
    _tagIndex.clear();
    _typeIndex.clear();
  }

  /// 查找知识
  List<KnowledgeItem> findKnowledge({
    String? query,
    KnowledgeType? type,
    List<String>? tags,
    ConfidenceLevel? minConfidence,
    DateTime? after,
    DateTime? before,
  }) {
    var results = _items.values.toList();

    // 按查询过滤
    if (query != null && query.isNotEmpty) {
      final terms = query.toLowerCase().split(' ');
      results = results.where((item) {
        final text = '${item.title} ${item.description}'.toLowerCase();
        return terms.every((term) => text.contains(term));
      }).toList();
    }

    // 按类型过滤
    if (type != null) {
      results = results.where((item) => item.type == type).toList();
    }

    // 按标签过滤
    if (tags != null && tags.isNotEmpty) {
      results = results.where((item) {
        return tags.every((tag) => item.tags.contains(tag));
      }).toList();
    }

    // 按可信度过滤
    if (minConfidence != null) {
      results = results.where((item) {
        return item.confidence.index <= minConfidence.index;
      }).toList();
    }

    // 按时间过滤
    if (after != null) {
      results = results
          .where(
            (item) => item.timestamp.isAfter(after),
          )
          .toList();
    }
    if (before != null) {
      results = results
          .where(
            (item) => item.timestamp.isBefore(before),
          )
          .toList();
    }

    // 按相关度排序
    results.sort((a, b) {
      // 首先按可信度排序
      final confidenceCompare =
          a.confidence.index.compareTo(b.confidence.index);
      if (confidenceCompare != 0) return confidenceCompare;

      // 其次按使用次数排序
      final usageCompare = b.usageCount.compareTo(a.usageCount);
      if (usageCompare != 0) return usageCompare;

      // 最后按时间排序
      return b.timestamp.compareTo(a.timestamp);
    });

    return results;
  }

  /// 获取相关知识
  List<KnowledgeItem> getRelatedKnowledge(String id) {
    final item = _items[id];
    if (item == null) return [];

    final relatedIds = Set<String>.from(item.relatedIds);

    // 添加具有相同标签的条目
    for (final tag in item.tags) {
      final taggedIds = _tagIndex[tag] ?? {};
      relatedIds.addAll(taggedIds);
    }

    // 添加同类型的高效条目
    final typeIds = _typeIndex[item.type] ?? {};
    relatedIds.addAll(typeIds.where((rid) {
      final related = _items[rid];
      if (related == null) return false;
      final successRate = _calculateSuccessRate(related);
      return successRate >= config.minEffectivenessThreshold;
    }));

    relatedIds.remove(id); // 移除自身

    return relatedIds
        .map((rid) => _items[rid])
        .whereType<KnowledgeItem>()
        .toList();
  }

  /// 记录使用情况
  void recordUsage(
    String id, {
    bool effective = true,
    String? feedback,
  }) {
    final item = _items[id];
    if (item == null) return;

    // 更新使用统计
    final effectiveness = Map<String, double>.from(item.effectiveness);
    final category = effective ? 'success' : 'failure';
    effectiveness[category] = (effectiveness[category] ?? 0.0) + 1.0;

    // 创建更新后的条目
    final updated = KnowledgeItem(
      id: id,
      timestamp: item.timestamp,
      type: item.type,
      title: item.title,
      description: item.description,
      context: item.context,
      tags: item.tags,
      relatedIds: item.relatedIds,
      source: item.source,
      confidence: item.confidence,
      effectiveness: effectiveness,
      usageCount: item.usageCount + 1,
      feedback: feedback != null ? [...item.feedback, feedback] : item.feedback,
    );

    _items[id] = updated;
  }

  /// 更新知识条目
  bool updateKnowledge(
    String id, {
    String? title,
    String? description,
    Map<String, dynamic>? context,
    List<String>? tags,
    List<String>? relatedIds,
    ConfidenceLevel? confidence,
  }) {
    final item = _items[id];
    if (item == null) return false;

    final updated = KnowledgeItem(
      id: id,
      timestamp: DateTime.now(),
      type: item.type,
      title: title ?? item.title,
      description: description ?? item.description,
      context: context ?? item.context,
      tags: tags ?? item.tags,
      relatedIds: relatedIds ?? item.relatedIds,
      source: item.source,
      confidence: confidence ?? item.confidence,
      effectiveness: item.effectiveness,
      usageCount: item.usageCount,
      feedback: item.feedback,
    );

    _items[id] = updated;
    _updateIndices(updated);

    logger.info('更新知识条目: $id');
    return true;
  }

  /// 计算成功率
  double _calculateSuccessRate(KnowledgeItem item) {
    final success = item.effectiveness['success'] ?? 0.0;
    final failure = item.effectiveness['failure'] ?? 0.0;
    final total = success + failure;
    return total > 0 ? success / total : 0.0;
  }

  /// 生成知识ID
  String _generateId() {
    final random = Random();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final randomPart = random.nextInt(10000).toString().padLeft(4, '0');
    return 'K$timestamp$randomPart';
  }

  /// 识别模式
  List<String> _identifyPatterns(List<KnowledgeItem> items) {
    final patterns = <String>[];

    // TODO: 实现模式识别算法
    // 1. 分析上下文相似性
    // 2. 提取共同特征
    // 3. 评估效果一致性

    return patterns;
  }

  /// 从历史记录中学习
  void _learnFromHistory() {
    final cutoff = DateTime.now().subtract(config.learningWindow);

    // 分析每个类型的成功模式
    for (final type in KnowledgeType.values) {
      final typeItems = _items.values.where((item) {
        return item.type == type &&
            item.timestamp.isAfter(cutoff) &&
            item.usageCount >= config.minSamplesForLearning;
      }).toList();

      if (typeItems.isEmpty) continue;

      // 识别成功模式
      final patterns = _identifyPatterns(typeItems);

      // 创建最佳实践
      for (final pattern in patterns) {
        addKnowledge(
          type: KnowledgeType.bestPractice,
          title: '自动发现的最佳实践: $type',
          description: pattern,
          source: KnowledgeSource.automatic,
          confidence: ConfidenceLevel.experimental,
          tags: ['auto_learned', type.toString()],
        );
      }
    }
  }

  /// 对Map按值排序
  List<MapEntry<K, V>> _sortMapByValue<K, V extends Comparable>(
    Map<K, V> map,
  ) {
    final entries = map.entries.toList();
    entries.sort((a, b) => b.value.compareTo(a.value));
    return entries;
  }

  /// 启动学习定时器
  void _startLearningTimer() {
    if (!config.autoLearn) return;

    _learningTimer?.cancel();
    _learningTimer = Timer.periodic(
      const Duration(hours: 1),
      (_) => _learnFromHistory(),
    );
  }

  /// 更新索引
  void _updateIndices(KnowledgeItem item) {
    // 更新标签索引
    for (final tag in item.tags) {
      _tagIndex.putIfAbsent(tag, () => {}).add(item.id);
    }

    // 更新类型索引
    _typeIndex.putIfAbsent(item.type, () => {}).add(item.id);
  }
}
