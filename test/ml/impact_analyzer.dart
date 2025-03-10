import 'dart:async';
import 'dart:math';

import '../utils/check_logger.dart';

/// 组件影响
class ComponentImpact {
  final String componentId;
  final Map<ImpactType, double> impacts;
  final ImpactLevel level;
  final Map<String, dynamic> metrics;
  final List<String> affectedFeatures;
  final DateTime timestamp;

  const ComponentImpact({
    required this.componentId,
    required this.impacts,
    required this.level,
    this.metrics = const {},
    this.affectedFeatures = const [],
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'componentId': componentId,
        'impacts': impacts.map((k, v) => MapEntry(k.toString(), v)),
        'level': level.toString(),
        'metrics': metrics,
        'affectedFeatures': affectedFeatures,
        'timestamp': timestamp.toIso8601String(),
      };
}

/// 影响分析结果
class ImpactAnalysisResult {
  final List<ComponentImpact> impacts;
  final List<PropagationPath> propagations;
  final Map<String, List<String>> mitigations;
  final Map<String, double> risks;
  final DateTime timestamp;

  const ImpactAnalysisResult({
    required this.impacts,
    required this.propagations,
    this.mitigations = const {},
    this.risks = const {},
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'impacts': impacts.map((i) => i.toJson()).toList(),
        'propagations': propagations.map((p) => p.toJson()).toList(),
        'mitigations': mitigations,
        'risks': risks,
        'timestamp': timestamp.toIso8601String(),
      };
}

/// 影响分析器
class ImpactAnalyzer {
  final CheckLogger logger;
  final ImpactConfig config;
  final _topology = <String, Set<String>>{};
  final _dependencies = <String, Set<String>>{};
  final _impacts = <ComponentImpact>[];
  Timer? _analysisTimer;

  ImpactAnalyzer({
    required this.config,
    CheckLogger? logger,
  }) : logger = logger ?? CheckLogger.instance;

  /// 分析影响
  Future<ImpactAnalysisResult> analyzeImpact(
    String sourceId, {
    Set<ImpactType>? types,
    int? maxDepth,
  }) async {
    types ??= ImpactType.values.toSet();
    maxDepth ??= config.maxPropagationDepth;

    logger.info('''
开始影响分析:
- 源组件: $sourceId
- 影响类型: $types
- 最大深度: $maxDepth
''');

    try {
      // 计算初始影响
      final impacts = await _calculateImpacts(sourceId, types);

      // 分析传播路径
      final propagations = await _analyzePropagation(
        sourceId,
        impacts,
        maxDepth,
      );

      // 生成缓解建议
      final mitigations = _generateMitigations(
        impacts,
        propagations,
      );

      // 评估风险
      final risks = _evaluateRisks(
        impacts,
        propagations,
      );

      final result = ImpactAnalysisResult(
        impacts: impacts,
        propagations: propagations,
        mitigations: mitigations,
        risks: risks,
        timestamp: DateTime.now(),
      );

      logger.info('''
分析完成:
- 影响组件: ${impacts.length}
- 传播路径: ${propagations.length}
- 缓解建议: ${mitigations.length}
''');

      return result;
    } catch (e) {
      logger.error('影响分析失败', e);
      rethrow;
    }
  }

  /// 释放资源
  void dispose() {
    _analysisTimer?.cancel();
    _topology.clear();
    _dependencies.clear();
    _impacts.clear();
  }

  /// 获取影响历史
  List<ComponentImpact> getImpactHistory(
    String componentId, {
    DateTime? start,
    DateTime? end,
  }) {
    return _impacts.where((i) {
      if (i.componentId != componentId) return false;
      if (start != null && i.timestamp.isBefore(start)) return false;
      if (end != null && i.timestamp.isAfter(end)) return false;
      return true;
    }).toList();
  }

  /// 预测影响
  Future<ImpactAnalysisResult> predictImpact(
    String componentId,
    Map<ImpactType, double> initialImpacts,
  ) async {
    if (!config.enablePrediction) {
      throw StateError('Impact prediction is not enabled');
    }

    logger.info('''
开始影响预测:
- 组件: $componentId
- 初始影响: $initialImpacts
''');

    // 创建模拟影响
    final impact = ComponentImpact(
      componentId: componentId,
      impacts: initialImpacts,
      level: _determineLevel(initialImpacts),
      timestamp: DateTime.now(),
    );

    // 分析潜在影响
    return analyzeImpact(
      componentId,
      types: initialImpacts.keys.toSet(),
    );
  }

  /// 记录影响
  void recordImpact(ComponentImpact impact) {
    _impacts.add(impact);
    _cleanHistory();

    logger.info('''
记录组件影响:
- 组件: ${impact.componentId}
- 级别: ${impact.level}
- 影响: ${impact.impacts}
''');
  }

  /// 注册组件依赖
  void registerDependency(
    String componentId,
    String dependencyId,
  ) {
    _dependencies.putIfAbsent(componentId, () => {}).add(dependencyId);
    _updateTopology();
  }

  /// 分析下游传播
  Future<List<PropagationPath>> _analyzeDownstreamPropagation(
    String componentId,
  ) async {
    final paths = <PropagationPath>[];
    final dependents = _findDependents(componentId);

    for (final dependentId in dependents) {
      final probability = await _calculatePropagationProbability(
        componentId,
        dependentId,
        PropagationDirection.downstream,
      );

      if (probability >= config.propagationThreshold) {
        paths.add(PropagationPath(
          sourceId: componentId,
          targetId: dependentId,
          direction: PropagationDirection.downstream,
          probability: probability,
        ));
      }
    }

    return paths;
  }

  /// 分析横向传播
  Future<List<PropagationPath>> _analyzeLateralPropagation(
    String componentId,
  ) async {
    final paths = <PropagationPath>[];
    final siblings = _findSiblings(componentId);

    for (final siblingId in siblings) {
      final probability = await _calculatePropagationProbability(
        componentId,
        siblingId,
        PropagationDirection.lateral,
      );

      if (probability >= config.propagationThreshold) {
        paths.add(PropagationPath(
          sourceId: componentId,
          targetId: siblingId,
          direction: PropagationDirection.lateral,
          probability: probability,
        ));
      }
    }

    return paths;
  }

  /// 分析传播路径
  Future<List<PropagationPath>> _analyzePropagation(
    String sourceId,
    List<ComponentImpact> impacts,
    int maxDepth,
  ) async {
    final paths = <PropagationPath>[];
    final queue = <_PropagationNode>[
      _PropagationNode(sourceId, 0),
    ];
    final visited = <String>{};

    while (queue.isNotEmpty) {
      final node = queue.removeAt(0);
      if (visited.contains(node.id)) continue;
      visited.add(node.id);

      // 检查深度限制
      if (node.depth >= maxDepth) continue;

      // 分析上游传播
      final upstream = await _analyzeUpstreamPropagation(node.id);
      paths.addAll(upstream);

      // 分析下游传播
      final downstream = await _analyzeDownstreamPropagation(node.id);
      paths.addAll(downstream);

      // 分析横向传播
      final lateral = await _analyzeLateralPropagation(node.id);
      paths.addAll(lateral);

      // 添加下一层节点
      for (final path in [...upstream, ...downstream, ...lateral]) {
        if (!visited.contains(path.targetId)) {
          queue.add(_PropagationNode(
            path.targetId,
            node.depth + 1,
          ));
        }
      }
    }

    return paths;
  }

  /// 分析上游传播
  Future<List<PropagationPath>> _analyzeUpstreamPropagation(
    String componentId,
  ) async {
    final paths = <PropagationPath>[];
    final dependencies = _dependencies[componentId] ?? {};

    for (final dependencyId in dependencies) {
      final probability = await _calculatePropagationProbability(
        dependencyId,
        componentId,
        PropagationDirection.upstream,
      );

      if (probability >= config.propagationThreshold) {
        paths.add(PropagationPath(
          sourceId: componentId,
          targetId: dependencyId,
          direction: PropagationDirection.upstream,
          probability: probability,
        ));
      }
    }

    return paths;
  }

  /// 计算历史相关性
  double _calculateHistoricalCorrelation(
    List<ComponentImpact> source,
    List<ComponentImpact> target,
  ) {
    if (source.isEmpty || target.isEmpty) return 1.0;

    // 将影响转换为时间序列
    final sourceSeries = <double>[];
    final targetSeries = <double>[];

    for (var i = 0; i < min(source.length, target.length); i++) {
      final sourceImpact = source[i];
      final targetImpact = target[i];

      // 使用平均影响值
      sourceSeries.add(
        sourceImpact.impacts.values.reduce((a, b) => a + b) /
            sourceImpact.impacts.length,
      );
      targetSeries.add(
        targetImpact.impacts.values.reduce((a, b) => a + b) /
            targetImpact.impacts.length,
      );
    }

    // 计算皮尔逊相关系数
    return _calculatePearsonCorrelation(
      sourceSeries,
      targetSeries,
    );
  }

  /// 计算组件影响
  Future<List<ComponentImpact>> _calculateImpacts(
    String sourceId,
    Set<ImpactType> types,
  ) async {
    final impacts = <ComponentImpact>[];
    final queue = <String>{sourceId};
    final visited = <String>{};

    while (queue.isNotEmpty) {
      final componentId = queue.first;
      queue.remove(componentId);

      if (visited.contains(componentId)) continue;
      visited.add(componentId);

      // 计算当前组件的影响
      final impact = await _evaluateComponentImpact(
        componentId,
        types,
      );
      impacts.add(impact);

      // 添加相关组件到队列
      final related = _topology[componentId] ?? {};
      queue.addAll(related.difference(visited));
    }

    return impacts;
  }

  /// 计算皮尔逊相关系数
  double _calculatePearsonCorrelation(
    List<double> x,
    List<double> y,
  ) {
    final n = min(x.length, y.length);
    if (n < 2) return 1.0;

    final xMean = x.reduce((a, b) => a + b) / n;
    final yMean = y.reduce((a, b) => a + b) / n;

    var numerator = 0.0;
    var xDenom = 0.0;
    var yDenom = 0.0;

    for (var i = 0; i < n; i++) {
      final xDiff = x[i] - xMean;
      final yDiff = y[i] - yMean;
      numerator += xDiff * yDiff;
      xDenom += xDiff * xDiff;
      yDenom += yDiff * yDiff;
    }

    if (xDenom == 0 || yDenom == 0) return 1.0;
    return (numerator / sqrt(xDenom * yDenom)).abs();
  }

  /// 计算传播概率
  Future<double> _calculatePropagationProbability(
    String sourceId,
    String targetId,
    PropagationDirection direction,
  ) async {
    // 基础概率
    var probability = switch (direction) {
      PropagationDirection.upstream => 0.7, // 上游影响较大
      PropagationDirection.downstream => 0.8, // 下游影响最大
      PropagationDirection.lateral => 0.5, // 横向影响较小
    };

    // 考虑历史影响
    final sourceHistory = getImpactHistory(sourceId);
    final targetHistory = getImpactHistory(targetId);

    if (sourceHistory.isNotEmpty && targetHistory.isNotEmpty) {
      // 计算历史相关性
      probability *= _calculateHistoricalCorrelation(
        sourceHistory,
        targetHistory,
      );
    }

    // 考虑依赖关系
    final dependencies = _dependencies[targetId] ?? {};
    if (dependencies.contains(sourceId)) {
      probability *= 1.2; // 直接依赖增加概率
    }

    return min(probability, 1.0); // 确保概率不超过1
  }

  /// 计算类型影响
  Future<double> _calculateTypeImpact(
    String componentId,
    ImpactType type,
  ) async {
    // 获取组件权重
    final weight = config.componentWeights[componentId] ?? 1.0;

    // 获取类型权重
    final typeWeight = config.typeWeights[type] ?? 1.0;

    // 分析历史影响
    final history = getImpactHistory(
      componentId,
      start: DateTime.now().subtract(config.analysisWindow),
    );

    // 如果没有历史数据，返回基准影响
    if (history.isEmpty) {
      return 0.5 * weight * typeWeight;
    }

    // 计算历史平均影响
    var total = 0.0;
    var count = 0;

    for (final impact in history) {
      final value = impact.impacts[type];
      if (value != null) {
        total += value;
        count++;
      }
    }

    final average = count > 0 ? total / count : 0.5;
    return average * weight * typeWeight;
  }

  /// 清理历史数据
  void _cleanHistory() {
    final cutoff = DateTime.now().subtract(config.analysisWindow);
    _impacts.removeWhere((i) => i.timestamp.isBefore(cutoff));
  }

  /// 确定影响级别
  ImpactLevel _determineLevel(Map<ImpactType, double> impacts) {
    if (impacts.isEmpty) return ImpactLevel.minimal;

    final avgImpact = impacts.values.reduce((a, b) => a + b) / impacts.length;

    return switch (avgImpact) {
      >= 0.8 => ImpactLevel.critical,
      >= 0.6 => ImpactLevel.high,
      >= 0.4 => ImpactLevel.medium,
      >= 0.2 => ImpactLevel.low,
      _ => ImpactLevel.minimal,
    };
  }

  /// 评估组件影响
  Future<ComponentImpact> _evaluateComponentImpact(
    String componentId,
    Set<ImpactType> types,
  ) async {
    final impacts = <ImpactType, double>{};

    // 分析每种影响类型
    for (final type in types) {
      impacts[type] = await _calculateTypeImpact(
        componentId,
        type,
      );
    }

    return ComponentImpact(
      componentId: componentId,
      impacts: impacts,
      level: _determineLevel(impacts),
      timestamp: DateTime.now(),
    );
  }

  /// 评估风险
  Map<String, double> _evaluateRisks(
    List<ComponentImpact> impacts,
    List<PropagationPath> paths,
  ) {
    final risks = <String, double>{};

    // 为每个组件计算风险分数
    for (final impact in impacts) {
      final componentId = impact.componentId;

      // 基础风险分数
      var risk =
          impact.impacts.values.reduce((a, b) => a + b) / impact.impacts.length;

      // 考虑传播概率
      final componentPaths = paths.where(
        (p) => p.sourceId == componentId || p.targetId == componentId,
      );

      if (componentPaths.isNotEmpty) {
        final avgProbability =
            componentPaths.map((p) => p.probability).reduce((a, b) => a + b) /
                componentPaths.length;

        risk *= (1 + avgProbability);
      }

      // 考虑依赖数量
      final dependencies = _dependencies[componentId]?.length ?? 0;
      final dependents = _findDependents(componentId).length;

      risk *= (1 + 0.1 * (dependencies + dependents));

      risks[componentId] = min(risk, 1.0); // 确保风险分数不超过1
    }

    return risks;
  }

  /// 查找依赖此组件的组件
  Set<String> _findDependents(String componentId) {
    return _dependencies.entries
        .where((e) => e.value.contains(componentId))
        .map((e) => e.key)
        .toSet();
  }

  /// 查找兄弟组件（共享依赖或被依赖）
  Set<String> _findSiblings(String componentId) {
    final siblings = <String>{};

    // 查找共享依赖的组件
    final dependencies = _dependencies[componentId] ?? {};
    for (final dependency in dependencies) {
      siblings.addAll(
        _findDependents(dependency)..remove(componentId),
      );
    }

    // 查找共同被依赖的组件
    final dependents = _findDependents(componentId);
    for (final dependent in dependents) {
      siblings.addAll(
        _dependencies[dependent] ?? {}
          ..remove(componentId),
      );
    }

    return siblings;
  }

  /// 生成缓解建议
  Map<String, List<String>> _generateMitigations(
    List<ComponentImpact> impacts,
    List<PropagationPath> paths,
  ) {
    final mitigations = <String, List<String>>{};

    // 为每个受影响组件生成建议
    for (final impact in impacts) {
      final suggestions = <String>[];
      final componentId = impact.componentId;

      // 基于影响级别的建议
      switch (impact.level) {
        case ImpactLevel.critical:
          suggestions.addAll([
            '立即隔离组件防止进一步传播',
            '启动应急响应流程',
            '准备故障切换方案',
          ]);
        case ImpactLevel.high:
          suggestions.addAll([
            '密切监控组件状态',
            '准备降级策略',
            '评估故障域范围',
          ]);
        case ImpactLevel.medium:
          suggestions.addAll([
            '增加监控频率',
            '审查依赖关系',
            '更新恢复计划',
          ]);
        case ImpactLevel.low:
          suggestions.add('继续观察组件表现');
        case ImpactLevel.minimal:
          suggestions.add('保持常规监控');
      }

      // 基于传播路径的建议
      final componentPaths = paths.where(
        (p) => p.sourceId == componentId || p.targetId == componentId,
      );

      if (componentPaths.isNotEmpty) {
        suggestions.addAll([
          '检查与其他组件的集成点',
          '评估依赖链健康状态',
          '考虑实施熔断机制',
        ]);
      }

      mitigations[componentId] = suggestions;
    }

    return mitigations;
  }

  /// 更新拓扑关系
  void _updateTopology() {
    _topology.clear();

    // 添加所有依赖关系
    for (final entry in _dependencies.entries) {
      final componentId = entry.key;
      final dependencies = entry.value;

      // 添加依赖
      _topology.putIfAbsent(componentId, () => {}).addAll(dependencies);

      // 添加反向依赖
      for (final dependencyId in dependencies) {
        _topology.putIfAbsent(dependencyId, () => {}).add(componentId);
      }
    }
  }
}

/// 影响配置
class ImpactConfig {
  final Duration analysisWindow;
  final Map<String, double> componentWeights;
  final Map<ImpactType, double> typeWeights;
  final double propagationThreshold;
  final int maxPropagationDepth;
  final bool enablePrediction;

  const ImpactConfig({
    this.analysisWindow = const Duration(hours: 1),
    this.componentWeights = const {},
    this.typeWeights = const {},
    this.propagationThreshold = 0.3,
    this.maxPropagationDepth = 5,
    this.enablePrediction = true,
  });
}

/// 影响级别
enum ImpactLevel {
  critical, // 严重
  high, // 高
  medium, // 中
  low, // 低
  minimal, // 极小
}

/// 影响类型
enum ImpactType {
  performance, // 性能影响
  reliability, // 可靠性影响
  security, // 安全影响
  resource, // 资源影响
  business, // 业务影响
}

/// 传播方向
enum PropagationDirection {
  upstream, // 上游传播
  downstream, // 下游传播
  lateral, // 横向传播
}

/// 传播链路
class PropagationPath {
  final String sourceId;
  final String targetId;
  final PropagationDirection direction;
  final double probability;
  final Map<ImpactType, double> attenuation;
  final List<String> dependencies;

  const PropagationPath({
    required this.sourceId,
    required this.targetId,
    required this.direction,
    required this.probability,
    this.attenuation = const {},
    this.dependencies = const [],
  });

  Map<String, dynamic> toJson() => {
        'sourceId': sourceId,
        'targetId': targetId,
        'direction': direction.toString(),
        'probability': probability,
        'attenuation': attenuation.map((k, v) => MapEntry(k.toString(), v)),
        'dependencies': dependencies,
      };
}

/// 传播节点（内部使用）
class _PropagationNode {
  final String id;
  final int depth;

  const _PropagationNode(this.id, this.depth);
}
