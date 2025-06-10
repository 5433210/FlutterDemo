import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../infrastructure/logging/edit_page_logger_extension.dart';
import '../../../infrastructure/services/character_image_service.dart';
import '../../../infrastructure/cache/services/optimized_image_cache_service.dart';

/// 🚀 优化的集字元素渲染器
/// 减少重复渲染，智能缓存管理，批量处理
class OptimizedCollectionElementRenderer {
  final CharacterImageService _characterImageService;
  final OptimizedImageCacheService _optimizedCache;
  
  // 🔧 渲染状态缓存 - 避免重复渲染相同内容
  final Map<String, _RenderState> _renderStateCache = {};
  
  // 🔧 渲染队列 - 批量处理渲染请求
  final List<_RenderRequest> _renderQueue = [];
  Timer? _renderTimer;
  
  // 🔧 性能统计
  int _renderCount = 0;
  int _cacheHits = 0;
  int _renderSkips = 0;
  
  // 🚀 新增：重复渲染检测
  final Map<String, DateTime> _lastRenderTime = {};
  final Map<String, String> _lastRenderContent = {};
  static const Duration _minRenderInterval = Duration(milliseconds: 100);
  
  // 🚀 新增：性能优化配置
  bool _enableRenderCompleteCallbacks = false; // 默认禁用非关键回调
  static const bool _debugMode = false; // 调试模式开关

  OptimizedCollectionElementRenderer(
    this._characterImageService,
    this._optimizedCache,
  );

  /// 🚀 优化的集字渲染方法 - 增强重复检测
  Future<void> renderCollectionElement({
    required String elementId,
    required String characters,
    required Map<String, dynamic> config,
    required VoidCallback onRenderComplete,
  }) async {
    final now = DateTime.now();
    
    // 🚀 检查是否为重复渲染请求
    final lastRenderTime = _lastRenderTime[elementId];
    final lastContent = _lastRenderContent[elementId];
    
    if (lastRenderTime != null && lastContent == characters) {
      final timeSinceLastRender = now.difference(lastRenderTime);
      if (timeSinceLastRender < _minRenderInterval) {
        _renderSkips++;
        EditPageLogger.performanceInfo(
          '跳过重复渲染请求',
          data: {
            'elementId': elementId,
            'characters': characters.length > 10 ? '${characters.substring(0, 10)}...' : characters,
            'timeSinceLastMs': timeSinceLastRender.inMilliseconds,
            'minIntervalMs': _minRenderInterval.inMilliseconds,
            'optimization': 'duplicate_render_skip',
          },
        );
        onRenderComplete();
        return;
      }
    }
    
    // 更新渲染时间和内容记录
    _lastRenderTime[elementId] = now;
    _lastRenderContent[elementId] = characters;
    
    // 生成渲染状态键
    final stateKey = _generateStateKey(elementId, characters, config);
    
    // 检查是否需要重新渲染
    final cachedState = _renderStateCache[stateKey];
    if (cachedState != null && !_shouldRerender(cachedState, config)) {
      _cacheHits++;
      EditPageLogger.performanceInfo(
        '跳过元素重建',
        data: {
          'elementId': elementId,
          'reason': 'Cache hit and not dirty',
          'optimization': 'render_cache_hit',
        },
      );
      onRenderComplete();
      return;
    }

    // 添加到渲染队列
    final request = _RenderRequest(
      elementId: elementId,
      characters: characters,
      config: config,
      stateKey: stateKey,
      onComplete: onRenderComplete,
    );
    
    _renderQueue.add(request);
    _scheduleRender();
  }

  /// 🚀 智能预加载字符图像 - 避免重复预加载
  final Map<String, DateTime> _lastPreloadTime = {};
  final Map<String, Set<String>> _preloadedChars = {};
  
  Future<void> preloadCharacterImages(String characters) async {
    final uniqueChars = characters.split('').toSet();
    final cacheKey = uniqueChars.join('');
    final now = DateTime.now();
    
    // 检查是否最近已经预加载过相同字符
    final lastPreload = _lastPreloadTime[cacheKey];
    final preloadedSet = _preloadedChars[cacheKey];
    
    if (lastPreload != null && preloadedSet != null) {
      final timeSincePreload = now.difference(lastPreload);
      if (timeSincePreload.inMinutes < 5 && preloadedSet.containsAll(uniqueChars)) {
        EditPageLogger.performanceInfo(
          '跳过重复预加载',
          data: {
            'characters': uniqueChars.join(''),
            'timeSinceLastMin': timeSincePreload.inMinutes,
            'optimization': 'preload_skip',
          },
        );
        return;
      }
    }
    
    // 记录预加载时间和字符
    _lastPreloadTime[cacheKey] = now;
    _preloadedChars[cacheKey] = uniqueChars;
    
    EditPageLogger.performanceInfo(
      '开始预加载字符图像',
      data: {
        'totalChars': characters.length,
        'uniqueChars': uniqueChars.length,
        'optimization': 'character_preload',
      },
    );
    
    // TODO: 实现批量缓存逻辑
    // _optimizedCache.batchCacheImages(cacheKeys);
  }

  /// 🚀 清理过期渲染状态
  void cleanupExpiredStates() {
    final now = DateTime.now();
    final expiredKeys = <String>[];
    
    _renderStateCache.forEach((key, state) {
      if (now.difference(state.lastRender).inMinutes > 30) {
        expiredKeys.add(key);
      }
    });
    
    for (final key in expiredKeys) {
      _renderStateCache.remove(key);
    }
    
    if (expiredKeys.isNotEmpty) {
      EditPageLogger.performanceInfo(
        '清理过期渲染状态',
        data: {
          'expiredCount': expiredKeys.length,
          'optimization': 'state_cleanup',
        },
      );
    }
  }

  /// 获取渲染统计信息 - 增强统计
  Map<String, dynamic> getRenderStats() {
    return {
      'totalRenders': _renderCount,
      'cacheHits': _cacheHits,
      'renderSkips': _renderSkips,
      'queueSize': _renderQueue.length,
      'statesCached': _renderStateCache.length,
      'hitRate': _renderCount > 0 ? _cacheHits / _renderCount : 0.0,
      'skipRate': (_renderCount + _renderSkips) > 0 ? _renderSkips / (_renderCount + _renderSkips) : 0.0,
      'duplicateDetectionActive': _lastRenderTime.isNotEmpty,
      'callbacksEnabled': _enableRenderCompleteCallbacks,
    };
  }

  /// 🚀 启用或禁用渲染完成回调
  void setRenderCompleteCallbacksEnabled(bool enabled) {
    _enableRenderCompleteCallbacks = enabled;
    EditPageLogger.performanceInfo(
      '渲染完成回调状态变更',
      data: {
        'enabled': enabled,
        'optimization': 'callback_state_change',
      },
    );
  }

  /// 🚀 获取当前回调启用状态
  bool get isRenderCompleteCallbacksEnabled => _enableRenderCompleteCallbacks;

  /// 生成渲染状态键
  String _generateStateKey(String elementId, String characters, Map<String, dynamic> config) {
    final configHash = config.hashCode;
    return '$elementId-${characters.hashCode}-$configHash';
  }

  /// 检查是否需要重新渲染
  bool _shouldRerender(_RenderState cachedState, Map<String, dynamic> newConfig) {
    // 检查配置是否发生变化
    if (cachedState.configHash != newConfig.hashCode) {
      return true;
    }
    
    // 检查是否超过缓存时间
    final now = DateTime.now();
    if (now.difference(cachedState.lastRender).inMinutes > 10) {
      return true;
    }
    
    return false;
  }

  /// 调度渲染处理
  void _scheduleRender() {
    _renderTimer?.cancel();
    _renderTimer = Timer(const Duration(milliseconds: 16), _processRenderQueue);
  }

  /// 处理渲染队列
  Future<void> _processRenderQueue() async {
    if (_renderQueue.isEmpty) return;
    
    final batch = <_RenderRequest>[];
    while (_renderQueue.isNotEmpty && batch.length < 5) {
      batch.add(_renderQueue.removeAt(0));
    }
    
    EditPageLogger.performanceInfo(
      '处理渲染批次',
      data: {
        'batchSize': batch.length,
        'remainingQueue': _renderQueue.length,
        'optimization': 'batch_render',
      },
    );
    
    // 并行处理渲染请求
    await Future.wait(
      batch.map((request) => _processRenderRequest(request)),
    );
    
    // 如果还有待处理的请求，继续调度
    if (_renderQueue.isNotEmpty) {
      _scheduleRender();
    }
  }

  /// 处理单个渲染请求
  Future<void> _processRenderRequest(_RenderRequest request) async {
    try {
      _renderCount++;
      
      EditPageLogger.performanceInfo(
        '开始处理渲染请求',
        data: {
          'elementId': request.elementId,
          'characters': request.characters.length > 10 
              ? '${request.characters.substring(0, 10)}...' 
              : request.characters,
          'optimization': 'render_processing',
        },
      );
      
      // 执行实际渲染逻辑
      await _executeRender(request);
      
      // 更新渲染状态缓存
      _renderStateCache[request.stateKey] = _RenderState(
        lastRender: DateTime.now(),
        configHash: request.config.hashCode,
      );
      
      // 🚀 优化：延迟调用完成回调，避免同步触发UI重建
      if (_enableRenderCompleteCallbacks || _debugMode) {
        scheduleMicrotask(() {
          try {
            request.onComplete();
          } catch (e) {
            EditPageLogger.rendererError(
              '渲染完成回调执行失败',
              error: e,
              data: {
                'elementId': request.elementId,
                'optimization': 'callback_error',
              },
            );
          }
        });
      } else {
        // 🚀 性能优化：跳过非关键回调以避免额外的Canvas重建
        EditPageLogger.performanceInfo(
          '跳过渲染完成回调（性能优化）',
          data: {
            'elementId': request.elementId,
            'optimization': 'skip_callback_for_performance',
          },
        );
      }
      
    } catch (e) {
      EditPageLogger.rendererError(
        '渲染请求处理失败',
        error: e,
        data: {
          'elementId': request.elementId,
          'optimization': 'render_failed',
        },
      );
    }
  }

  /// 执行实际渲染
  Future<void> _executeRender(_RenderRequest request) async {
    // 这里实现具体的渲染逻辑
    // 可以调用原有的渲染方法或实现新的优化渲染逻辑
    
    // 预加载所需的字符图像
    await preloadCharacterImages(request.characters);
    
    // 模拟渲染处理时间
    await Future.delayed(const Duration(milliseconds: 1));
  }

  /// 释放资源 - 清理所有缓存
  void dispose() {
    _renderTimer?.cancel();
    _renderQueue.clear();
    _renderStateCache.clear();
    _lastRenderTime.clear();
    _lastRenderContent.clear();
    _lastPreloadTime.clear();
    _preloadedChars.clear();
  }
}

/// 渲染状态
class _RenderState {
  final DateTime lastRender;
  final int configHash;
  
  _RenderState({
    required this.lastRender,
    required this.configHash,
  });
}

/// 渲染请求
class _RenderRequest {
  final String elementId;
  final String characters;
  final Map<String, dynamic> config;
  final String stateKey;
  final VoidCallback onComplete;
  
  _RenderRequest({
    required this.elementId,
    required this.characters,
    required this.config,
    required this.stateKey,
    required this.onComplete,
  });
} 