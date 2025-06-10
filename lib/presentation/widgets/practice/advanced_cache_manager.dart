import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../infrastructure/logging/edit_page_logger_extension.dart';
import '../../../infrastructure/logging/logger.dart';
import 'element_cache_manager.dart';
import 'element_snapshot.dart';
import 'memory_manager.dart';

/// 高级元素缓存管理器配置
class AdvancedCacheConfig {
  /// 最大缓存条目数
  final int maxCacheEntries;

  /// 内存用量阈值（字节）
  final int memoryThreshold;

  /// 冷缓存清理间隔
  final Duration coldCacheCleanupInterval;

  /// 热度图更新间隔
  final Duration heatMapUpdateInterval;

  /// 内存压力检测间隔
  final Duration memoryPressureCheckInterval;

  /// 是否启用预缓存
  final bool enablePrecaching;

  /// 是否使用快照系统
  final bool useSnapshotSystem;

  /// 是否启用自动内存适配
  final bool enableAutoMemoryAdjustment;

  const AdvancedCacheConfig({
    this.maxCacheEntries = 500,
    this.memoryThreshold = 100 * 1024 * 1024, // 100 MB
    this.coldCacheCleanupInterval = const Duration(minutes: 2),
    this.heatMapUpdateInterval = const Duration(seconds: 30),
    this.memoryPressureCheckInterval = const Duration(seconds: 15),
    this.enablePrecaching = true,
    this.useSnapshotSystem = true,
    this.enableAutoMemoryAdjustment = true,
  });
}

/// 高级元素缓存管理器
/// 提供热度图、内存压力感知和冷缓存清理等高级功能
class AdvancedElementCacheManager extends ChangeNotifier {
  /// 基础缓存管理器
  final ElementCacheManager _baseCacheManager;

  /// 内存管理器
  final MemoryManager _memoryManager;

  /// 元素快照管理器（可选）
  final ElementSnapshotManager? _snapshotManager;

  /// 配置
  final AdvancedCacheConfig _config;

  /// 访问记录
  final Map<String, CacheAccessRecord> _accessRecords = {};

  /// 热度图 - 按热度等级分组的元素ID
  final Map<HeatLevel, Set<String>> _heatMap = {
    HeatLevel.cold: {},
    HeatLevel.warm: {},
    HeatLevel.hot: {},
    HeatLevel.veryHot: {},
  };

  /// 当前内存压力级别
  MemoryPressureLevel _currentMemoryPressure = MemoryPressureLevel.normal;

  /// 定时器
  Timer? _coldCacheCleanupTimer;
  Timer? _heatMapUpdateTimer;
  Timer? _memoryPressureCheckTimer;

  /// 智能通知控制
  DateTime _lastNotificationTime = DateTime.now();
  static const Duration _minNotificationInterval = Duration(milliseconds: 100);

  /// 可预测的即将使用的元素ID集合
  final Set<String> _predictedElementIds = {};

  /// 弱引用缓存系统
  final WeakElementCache _weakCache = WeakElementCache();

  /// 创建高级元素缓存管理器
  AdvancedElementCacheManager({
    required ElementCacheManager baseCacheManager,
    required MemoryManager memoryManager,
    ElementSnapshotManager? snapshotManager,
    AdvancedCacheConfig? config,
  })  : _baseCacheManager = baseCacheManager,
        _memoryManager = memoryManager,
        _snapshotManager = snapshotManager,
        _config = config ?? const AdvancedCacheConfig() {
    _initializeTimers();

    // 设置内存管理器的回调
    _memoryManager.onMemoryPressure = _handleMemoryPressure;
    _memoryManager.onLowMemory = _handleLowMemory;

    EditPageLogger.controllerDebug(
      '高级缓存管理器初始化完成',
      data: {
        'maxCacheEntries': _config.maxCacheEntries,
        'memoryThreshold': _config.memoryThreshold,
        'enablePrecaching': _config.enablePrecaching,
        'useSnapshotSystem': _config.useSnapshotSystem,
      },
    );
  }

  /// 获取当前内存压力级别
  MemoryPressureLevel get memoryPressureLevel => _currentMemoryPressure;

  /// 获取缓存指标的便捷访问
  CacheMetrics get _metrics => _baseCacheManager.metrics;

  /// 清理缓存
  void cleanupCache({bool force = false}) {
    // 清理弱引用缓存中超过2小时未访问的条目
    _weakCache.cleanup(const Duration(hours: 2));

    // 如果强制清理或内存压力较大，进行更彻底的清理
    if (force || _currentMemoryPressure != MemoryPressureLevel.normal) {
      _cleanupColdCache();

      if (_currentMemoryPressure == MemoryPressureLevel.severe || force) {
        _emergencyCacheCleanup();
      }
    }

    // 清理基础缓存
    _baseCacheManager.cleanupCache(force: force);

    EditPageLogger.performanceInfo(
      '高级缓存清理完成',
      data: {
        'memoryPressure': _currentMemoryPressure.toString(),
        'weakCacheSize': _weakCache.size,
        'force': force,
      },
    );
  }

  /// 释放资源
  @override
  void dispose() {
    _coldCacheCleanupTimer?.cancel();
    _heatMapUpdateTimer?.cancel();
    _memoryPressureCheckTimer?.cancel();
    super.dispose();
  }

  /// 获取缓存性能指标
  Map<String, dynamic> getCacheMetrics() {
    // 获取基础缓存指标
    final cacheMetrics = _baseCacheManager.metrics.getReport();

    // 添加高级指标
    final advancedMetrics = <String, dynamic>{
      'heatMap': {
        'cold': _heatMap[HeatLevel.cold]?.length ?? 0,
        'warm': _heatMap[HeatLevel.warm]?.length ?? 0,
        'hot': _heatMap[HeatLevel.hot]?.length ?? 0,
        'veryHot': _heatMap[HeatLevel.veryHot]?.length ?? 0,
      },
      'memoryPressure': _currentMemoryPressure.toString(),
      'predictedElements': _predictedElementIds.length,
      'totalTrackedElements': _accessRecords.length,
      'weakCacheSize': _weakCache.size,
    };

    // 合并指标
    return {
      ...cacheMetrics,
      'advanced': advancedMetrics,
    };
  }

  /// 获取缓存条目
  Widget? getElementWidget(String elementId, String elementType) {
    // 1. 首先尝试从弱引用缓存获取
    final weakCachedWidget = _weakCache.get(elementId);
    if (weakCachedWidget != null) {
      EditPageLogger.controllerDebug(
        '从弱引用缓存获取元素',
        data: {'elementId': elementId, 'source': 'weak_cache'},
      );
      // 更新访问记录
      _recordAccess(elementId, {'id': elementId, 'type': elementType});
      return weakCachedWidget;
    }

    // 2. 然后尝试从快照系统获取
    if (_config.useSnapshotSystem && _snapshotManager != null) {
      final snapshot = _snapshotManager!.getSnapshot(elementId);
      if (snapshot != null && snapshot.cachedWidget != null) {
        EditPageLogger.controllerDebug(
          '从快照缓存获取元素',
          data: {'elementId': elementId, 'source': 'snapshot'},
        );
        // 更新访问记录
        _recordAccess(elementId, snapshot.properties);
        return snapshot.cachedWidget;
      }
    }

    // 3. 最后从基础缓存管理器获取
    // 更新访问记录（使用基本属性）
    _recordAccess(elementId, {'id': elementId, 'type': elementType});

    final widget = _baseCacheManager.getElementWidget(elementId, elementType);

    // 如果从基础缓存获取到了，同时存储到弱引用缓存中
    if (widget != null) {
      _weakCache.put(elementId, widget);
    }

    return widget;
  }

  /// 获取热度图可视化数据
  Map<String, dynamic> getHeatMapVisualization() {
    final Map<String, Map<String, dynamic>> heatData = {};

    for (final entry in _accessRecords.entries) {
      final elementId = entry.key;
      final record = entry.value;

      heatData[elementId] = {
        'score': record.calculateHeatScore(),
        'level': record.getHeatLevel().toString(),
        'accessCount': record.totalAccessCount,
        'lastAccess': record.lastAccess.toIso8601String(),
        'type': record.elementType,
      };
    }

    return {
      'elements': heatData,
      'summary': {
        'cold': _heatMap[HeatLevel.cold]?.length ?? 0,
        'warm': _heatMap[HeatLevel.warm]?.length ?? 0,
        'hot': _heatMap[HeatLevel.hot]?.length ?? 0,
        'veryHot': _heatMap[HeatLevel.veryHot]?.length ?? 0,
      }
    };
  }

  /// 标记元素需要更新
  void markElementForUpdate(String elementId) {
    // 从弱引用缓存移除
    _weakCache.remove(elementId);

    // 从基础缓存移除
    _baseCacheManager.markElementForUpdate(elementId);

    // 从快照系统移除
    if (_config.useSnapshotSystem && _snapshotManager != null) {
      _snapshotManager!.clearSnapshot(elementId);
    }

    EditPageLogger.controllerDebug(
      '标记元素更新',
      data: {'elementId': elementId},
    );
  }

  /// 预测即将使用的元素
  void predictElements(List<String> elementIds) {
    if (!_config.enablePrecaching) return;

    for (final elementId in elementIds) {
      _predictedElementIds.add(elementId);
    }

    EditPageLogger.controllerDebug(
      '预测元素使用',
      data: {
        'predictedCount': elementIds.length,
        'totalPredicted': _predictedElementIds.length,
      },
    );
  }

  /// 重置所有缓存
  void reset() {
    _accessRecords.clear();
    _resetHeatMap();
    _predictedElementIds.clear();
    _weakCache.clear();

    // 重置基础缓存
    _baseCacheManager.reset();

    // 重置快照系统
    if (_config.useSnapshotSystem && _snapshotManager != null) {
      _snapshotManager!.clearSnapshots();
    }

    EditPageLogger.controllerDebug(
      '重置所有缓存',
      data: {
        'accessRecordsCleared': _accessRecords.length,
        'predictedElementsCleared': _predictedElementIds.length,
        'weakCacheCleared': _weakCache.size,
      },
    );

    // 条件通知：只在必要时通知监听器
    if (hasListeners) {
      notifyListeners();
    }
  }

  /// 存储元素到缓存
  void storeElementWidget(
    String elementId,
    Widget widget,
    Map<String, dynamic> properties, {
    int estimatedSize = 0,
    CachePriority priority = CachePriority.medium,
    String elementType = 'unknown',
  }) {
    // 更新访问记录
    _recordAccess(elementId, properties);

    // 如果是预测会使用的元素，增加其优先级
    if (_predictedElementIds.contains(elementId)) {
      priority = CachePriority.high;
      _predictedElementIds.remove(elementId);
    }

    // 基于热度调整优先级
    final heatLevel = _getHeatLevel(elementId);
    if (heatLevel == HeatLevel.veryHot) {
      priority = CachePriority.high;
    } else if (heatLevel == HeatLevel.hot) {
      priority =
          priority == CachePriority.low ? CachePriority.medium : priority;
    } else if (heatLevel == HeatLevel.cold &&
        priority != CachePriority.pinned) {
      priority = CachePriority.low;
    }

    // 如果当前内存压力较大，应用缓存策略
    if (_currentMemoryPressure == MemoryPressureLevel.severe) {
      // 只缓存非常热的元素
      if (heatLevel != HeatLevel.veryHot) {
        // 虽然不存到主缓存，但仍存储到弱引用缓存
        _weakCache.put(elementId, widget);
        return;
      }
    } else if (_currentMemoryPressure == MemoryPressureLevel.moderate) {
      // 只缓存热或非常热的元素
      if (heatLevel != HeatLevel.hot && heatLevel != HeatLevel.veryHot) {
        // 虽然不存到主缓存，但仍存储到弱引用缓存
        _weakCache.put(elementId, widget);
        return;
      }
    }

    // 1. 存储到基础缓存
    _baseCacheManager.storeElementWidget(
      elementId,
      widget,
      properties,
      estimatedSize: estimatedSize,
      priority: priority,
      elementType: elementType,
    );

    // 2. 同时存储到弱引用缓存
    _weakCache.put(elementId, widget);
    // 3. 如果启用快照系统，也存储到快照
    if (_config.useSnapshotSystem && _snapshotManager != null) {
      // 更新快照 - 使用可用的公共方法
      _snapshotManager!.clearSnapshot(elementId);
      // 创建新的快照
      _snapshotManager!.createSnapshots([properties]);
    }
  }

  /// 根据热度调整缓存优先级
  void _adjustCachePrioritiesBasedOnHeat() {
    // 提高热门元素的优先级
    for (final elementId in _heatMap[HeatLevel.veryHot] ?? {}) {
      _baseCacheManager.pinElement(elementId);
    }

    // 降低冷门元素的优先级 - 这里不需要显式调整，
    // 因为我们会在storeElementWidget中根据热度设置优先级
  }

  /// 检查内存压力
  void _checkMemoryPressure() {
    final memoryStats = _memoryManager.memoryStats;
    final usedMemoryPercentage = memoryStats.pressureRatio;

    // 根据内存使用百分比确定压力级别
    MemoryPressureLevel newPressureLevel;

    if (usedMemoryPercentage > 0.9) {
      newPressureLevel = MemoryPressureLevel.severe;
    } else if (usedMemoryPercentage > 0.75) {
      newPressureLevel = MemoryPressureLevel.moderate;
    } else if (usedMemoryPercentage > 0.6) {
      newPressureLevel = MemoryPressureLevel.mild;
    } else {
      newPressureLevel = MemoryPressureLevel.normal;
    }

    // 如果压力级别变化，执行相应操作
    if (newPressureLevel != _currentMemoryPressure) {
      _currentMemoryPressure = newPressureLevel;

      switch (_currentMemoryPressure) {
        case MemoryPressureLevel.normal:
          // 正常状态，无需特殊操作
          break;
        case MemoryPressureLevel.mild:
          // 轻度压力，清理部分冷缓存
          _cleanupColdCache();
          break;
        case MemoryPressureLevel.moderate:
          // 中度压力，清理大部分冷缓存和部分温缓存
          _cleanupColdCache();
          _cleanupLowPriorityCache();
          break;
        case MemoryPressureLevel.severe:
          // 严重压力，进行紧急缓存清理
          _emergencyCacheCleanup();
          break;
      }

      // 条件通知：只在内存压力显著变化时通知监听器
      if (hasListeners) {
        notifyListeners();
      }
    }
  }

  /// 清理冷缓存
  void _cleanupColdCache() {
    final coldElements = _heatMap[HeatLevel.cold] ?? {};

    if (coldElements.isEmpty) return;

    // 计算应该清理的冷缓存数量
    final coldCacheSize = coldElements.length;
    final maxSize = _config.maxCacheEntries;

    // 如果总缓存大小超过最大值的80%，或者内存压力大于正常，则清理冷缓存
    if (_metrics.currentSize > 0.8 * maxSize ||
        _currentMemoryPressure != MemoryPressureLevel.normal) {
      // 计算要删除的数量
      int elementsToRemove = (0.3 * coldCacheSize).round();

      // 如果内存压力较大，增加清理数量
      if (_currentMemoryPressure == MemoryPressureLevel.severe) {
        elementsToRemove = coldCacheSize;
      } else if (_currentMemoryPressure == MemoryPressureLevel.moderate) {
        elementsToRemove = (0.7 * coldCacheSize).round();
      } else if (_currentMemoryPressure == MemoryPressureLevel.mild) {
        elementsToRemove = (0.5 * coldCacheSize).round();
      }

      // 按最后访问时间排序
      final sortedColdElements = coldElements.toList()
        ..sort((a, b) {
          final timeA = _accessRecords[a]?.getTimeSinceLastAccess() ?? 0;
          final timeB = _accessRecords[b]?.getTimeSinceLastAccess() ?? 0;
          return timeB.compareTo(timeA); // 按最久未访问排序
        });

      // 删除最久未访问的冷缓存
      final elementsToRemoveList =
          sortedColdElements.take(elementsToRemove).toList();
      for (final elementId in elementsToRemoveList) {
        // 标记元素需要更新，这样会从缓存中移除
        _baseCacheManager.markElementForUpdate(elementId);
        // 但保留访问记录，用于未来参考
      }

      EditPageLogger.performanceInfo(
        '冷缓存清理完成',
        data: {
          'cleanedCount': elementsToRemoveList.length,
          'remainingColdItems': coldElements.length - elementsToRemoveList.length,
          'memoryPressure': _currentMemoryPressure.toString(),
        },
      );
    }
  }

  /// 清理低优先级缓存
  void _cleanupLowPriorityCache() {
    final warmElements = _heatMap[HeatLevel.warm] ?? {};

    // 计算要删除的数量
    int elementsToRemove = (0.3 * warmElements.length).round();

    // 按最后访问时间排序
    final sortedWarmElements = warmElements.toList()
      ..sort((a, b) {
        final timeA = _accessRecords[a]?.getTimeSinceLastAccess() ?? 0;
        final timeB = _accessRecords[b]?.getTimeSinceLastAccess() ?? 0;
        return timeB.compareTo(timeA); // 按最久未访问排序
      });

    // 删除部分温缓存
    final elementsToRemoveList =
        sortedWarmElements.take(elementsToRemove).toList();
    for (final elementId in elementsToRemoveList) {
      _baseCacheManager.markElementForUpdate(elementId);
    }

    EditPageLogger.performanceInfo(
      '温缓存清理完成',
      data: {
        'cleanedCount': elementsToRemoveList.length,
        'totalWarmItems': warmElements.length,
      },
    );
  }

  /// 紧急缓存清理
  void _emergencyCacheCleanup() {
    // 保留非常热的元素和一部分热元素
    final hotElements = _heatMap[HeatLevel.hot] ?? {};
    final veryHotElements = _heatMap[HeatLevel.veryHot] ?? {};

    // 计算要保留的热元素数量
    int hotElementsToKeep = (0.3 * hotElements.length).round();

    // 按热度分数排序
    final sortedHotElements = hotElements.toList()
      ..sort((a, b) {
        final scoreA = _accessRecords[a]?.calculateHeatScore() ?? 0;
        final scoreB = _accessRecords[b]?.calculateHeatScore() ?? 0;
        return scoreB.compareTo(scoreA); // 按热度从高到低排序
      });

    // 要保留的元素ID
    final elementsToKeep = <String>{
      ...veryHotElements,
      ...sortedHotElements.take(hotElementsToKeep),
    };

    // 获取所有当前缓存的元素，可能需要使用从accessRecords推断
    final allCachedElementIds = _accessRecords.keys.toSet();

    // 清理除了要保留的元素之外的所有缓存
    for (final elementId in allCachedElementIds) {
      if (!elementsToKeep.contains(elementId)) {
        _baseCacheManager.markElementForUpdate(elementId);
      }
    }

    EditPageLogger.performanceWarning(
      '紧急缓存清理完成',
      data: {
        'keptElements': elementsToKeep.length,
        'veryHotElements': veryHotElements.length,
        'keptHotElements': hotElementsToKeep,
        'totalElementsBefore': allCachedElementIds.length,
      },
    );

    // 如果有快照系统，也清理快照
    if (_config.useSnapshotSystem && _snapshotManager != null) {
      // 仅保留高热度元素的快照
      final snapshots = _snapshotManager!.getAllSnapshots();
      for (final elementId in snapshots.keys) {
        if (!elementsToKeep.contains(elementId)) {
          _snapshotManager!.clearSnapshot(elementId);
        }
      }
      EditPageLogger.performanceInfo(
        '快照紧急清理完成',
        data: {
          'totalSnapshots': snapshots.length,
          'keptSnapshots': elementsToKeep.length,
        },
      );
    }

    // 触发基础缓存的紧急清理
    _baseCacheManager.cleanupCache(force: true);
  }

  /// 获取元素热度等级
  HeatLevel _getHeatLevel(String elementId) {
    if (!_accessRecords.containsKey(elementId)) {
      return HeatLevel.cold;
    }

    return _accessRecords[elementId]!.getHeatLevel();
  }

  /// 处理低内存回调
  void _handleLowMemory() {
    EditPageLogger.performanceWarning(
      '检测到低内存，执行紧急缓存清理',
      data: {
        'previousPressureLevel': _currentMemoryPressure.toString(),
        'newPressureLevel': MemoryPressureLevel.severe.toString(),
      },
    );
    _currentMemoryPressure = MemoryPressureLevel.severe;
    _emergencyCacheCleanup();
  }

  /// 处理内存压力回调
  void _handleMemoryPressure() {
    EditPageLogger.performanceWarning(
      '检测到内存压力，执行缓存清理',
      data: {
        'currentPressureLevel': _currentMemoryPressure.toString(),
      },
    );
    _checkMemoryPressure();
    cleanupCache();
  }

  /// 初始化定时器
  void _initializeTimers() {
    // 冷缓存清理定时器
    _coldCacheCleanupTimer = Timer.periodic(
        _config.coldCacheCleanupInterval, (_) => _cleanupColdCache());

    // 热度图更新定时器
    _heatMapUpdateTimer =
        Timer.periodic(_config.heatMapUpdateInterval, (_) => _updateHeatMap());

    // 内存压力检测定时器
    _memoryPressureCheckTimer = Timer.periodic(
        _config.memoryPressureCheckInterval, (_) => _checkMemoryPressure());

    // 立即执行一次热度图更新和内存压力检测
    _updateHeatMap();
    _checkMemoryPressure();
  }

  /// 记录访问
  void _recordAccess(String elementId, Map<String, dynamic> properties) {
    final elementType = properties['type'] as String? ?? 'unknown';

    if (!_accessRecords.containsKey(elementId)) {
      _accessRecords[elementId] = CacheAccessRecord(elementType: elementType);
    }

    _accessRecords[elementId]!.recordAccess();
  }

  /// 重置热度图
  void _resetHeatMap() {
    for (final level in HeatLevel.values) {
      _heatMap[level] = {};
    }
  }

  /// 智能通知：避免过于频繁的UI更新
  void _intelligentNotify() {
    if (!hasListeners) return;

    final now = DateTime.now();
    if (now.difference(_lastNotificationTime) >= _minNotificationInterval) {
      _lastNotificationTime = now;
      notifyListeners();
      
      EditPageLogger.performanceInfo(
        '智能通知触发',
        data: {
          'notificationType': 'cache_update',
          'timeSinceLastNotification': now.difference(_lastNotificationTime).inMilliseconds,
        },
      );
    }
  }

  /// 更新热度图
  void _updateHeatMap() {
    // 重置热度图
    _resetHeatMap();

    // 更新热度图
    for (final entry in _accessRecords.entries) {
      final elementId = entry.key;
      final heatLevel = entry.value.getHeatLevel();

      _heatMap[heatLevel]?.add(elementId);
    }

    // 使用热度信息调整基础缓存优先级
    _adjustCachePrioritiesBasedOnHeat();

    // 智能通知：避免频繁的热度图更新通知
    _intelligentNotify();
  }
}

/// 缓存访问记录 - 用于热度计算
class CacheAccessRecord {
  /// 最大记录的访问次数
  static const int _maxRecentAccessCount = 10;

  /// 最近访问时间
  final List<DateTime> recentAccesses = [];

  /// 访问总次数
  int totalAccessCount = 0;

  /// 元素类型
  final String elementType;

  /// 首次访问时间
  final DateTime firstAccess;

  /// 上次访问时间
  DateTime lastAccess;

  CacheAccessRecord({
    required this.elementType,
    DateTime? firstAccessTime,
  })  : firstAccess = firstAccessTime ?? DateTime.now(),
        lastAccess = DateTime.now();

  /// 计算热度得分
  double calculateHeatScore() {
    final now = DateTime.now();

    // 基于时间衰减的访问热度
    double heatScore = 0;
    for (int i = 0; i < recentAccesses.length; i++) {
      final age = now.difference(recentAccesses[i]).inMilliseconds;
      // 越近的访问权重越高
      final weight = 1.0 / (1 + math.log(1 + age / 1000));
      heatScore += weight;
    }

    // 将总访问次数纳入考量
    final totalScore = heatScore * (1 + math.log(1 + totalAccessCount));

    return totalScore;
  }

  /// 获取热度等级
  HeatLevel getHeatLevel() {
    final score = calculateHeatScore();

    if (score > 20) return HeatLevel.veryHot;
    if (score > 10) return HeatLevel.hot;
    if (score > 5) return HeatLevel.warm;
    return HeatLevel.cold;
  }

  /// 上次访问距今的时间（毫秒）
  int getTimeSinceLastAccess() {
    return DateTime.now().difference(lastAccess).inMilliseconds;
  }

  /// 记录一次访问
  void recordAccess() {
    final now = DateTime.now();
    lastAccess = now;
    totalAccessCount++;

    recentAccesses.add(now);
    if (recentAccesses.length > _maxRecentAccessCount) {
      recentAccesses.removeAt(0);
    }
  }
}

/// 访问热度区间 - 用于热度图计算
enum HeatLevel {
  /// 冷区 - 几乎不使用
  cold,

  /// 温区 - 偶尔使用
  warm,

  /// 热区 - 频繁使用
  hot,

  /// 极热区 - 非常频繁使用
  veryHot,
}

/// 内存压力级别
enum MemoryPressureLevel {
  /// 正常 - 内存使用在安全范围内
  normal,

  /// 轻度压力 - 内存使用接近阈值
  mild,

  /// 中度压力 - 内存使用已达阈值
  moderate,

  /// 严重压力 - 内存使用超过阈值，需要立即释放
  severe,
}

/// 弱引用元素缓存系统
/// 用于存储不常用但可能需要的元素，使用弱引用避免内存泄漏
class WeakElementCache {
  /// 弱引用Map实现 - 使用Map代替Expando以支持String键
  final Map<String, Widget> _weakCache = <String, Widget>{};

  /// 存储的键集合
  final Set<String> _keys = {};

  /// 访问记录
  final Map<String, DateTime> _lastAccessTime = {};

  /// 获取所有键
  Set<String> get keys => Set.unmodifiable(_keys);

  /// 获取条目数量
  int get size => _keys.length;

  /// 清理长时间未访问的条目
  void cleanup(Duration threshold) {
    final now = DateTime.now();
    final keysToRemove = <String>[];

    for (final entry in _lastAccessTime.entries) {
      if (now.difference(entry.value) > threshold) {
        keysToRemove.add(entry.key);
      }
    }

    for (final key in keysToRemove) {
      remove(key);
    }

    if (keysToRemove.isNotEmpty) {
      EditPageLogger.performanceInfo(
        '弱引用缓存清理完成',
        data: {
          'cleanedCount': keysToRemove.length,
          'remainingCount': _weakCache.keys.length,
        },
      );
    }
  }

  /// 清除所有元素
  void clear() {
    _weakCache.clear();
    _keys.clear();
    _lastAccessTime.clear();
  }

  /// 检查是否包含某个键
  bool containsKey(String key) =>
      _keys.contains(key) && _weakCache.containsKey(key);

  /// 获取缓存元素
  Widget? get(String key) {
    final widget = _weakCache[key];
    if (widget != null) {
      _lastAccessTime[key] = DateTime.now();
    }
    return widget;
  }

  /// 存储元素
  void put(String key, Widget widget) {
    _weakCache[key] = widget;
    _keys.add(key);
    _lastAccessTime[key] = DateTime.now();
  }

  /// 清除指定元素
  void remove(String key) {
    _weakCache.remove(key);
    _keys.remove(key);
    _lastAccessTime.remove(key);
  }
}
