import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../core/canvas_state_manager.dart';
import '../core/interfaces/element_data.dart';
import 'gpu_acceleration_utils.dart';
import 'render_cache.dart';
import 'render_performance_monitor.dart';
import 'render_quality_optimizer.dart';
import 'specialized_renderers/collection_element_renderer.dart';
import 'specialized_renderers/image_element_renderer.dart';
import 'specialized_renderers/path_element_renderer.dart';
import 'specialized_renderers/shape_element_renderer.dart';
import 'specialized_renderers/text_element_renderer.dart';

/// Canvas渲染引擎 - 按照设计文档实现
///
/// 职责：
/// 1. 管理专用渲染器
/// 2. 实现增量渲染
/// 3. 优化渲染性能
/// 4. 管理渲染资源
class CanvasRenderingEngine {
  final CanvasStateManager _stateManager;
  final Map<String, ElementRenderer> _renderers = {};
  final Set<String> _dirtyElements = {};
  final RenderCache _renderCache = RenderCache();
  final RenderPerformanceMonitor _performanceMonitor =
      RenderPerformanceMonitor();
  final RenderQualityOptimizer _qualityOptimizer = RenderQualityOptimizer();

  // GPU加速相关
  late Future<GpuCapabilities> _gpuCapabilitiesFuture;
  RenderStrategy _renderStrategy = RenderStrategy.hybridPreferSoftware;
  bool _gpuAccelerationEnabled = true;

  // 性能统计
  int _renderCount = 0;
  DateTime? _lastRenderTime;
  CanvasRenderingEngine(this._stateManager) {
    _initializeRenderers();
    _stateManager.addListener(_onStateChanged);

    // 初始化GPU能力检测
    _initializeGpuCapabilities();
  }

  /// 清理缓存
  void clearCache() {
    _renderCache.clear();
  }

  /// 资源清理
  void dispose() {
    _stateManager.removeListener(_onStateChanged);
    for (final renderer in _renderers.values) {
      renderer.dispose();
    }
    _renderCache.clear();
    _performanceMonitor.clear();
  }

  /// 获取GPU加速状态
  Future<Map<String, dynamic>> getGpuAccelerationStatus() async {
    final capabilities = await _gpuCapabilitiesFuture;

    return {
      'enabled': _gpuAccelerationEnabled,
      'strategy': _renderStrategy.toString(),
      'capabilities': {
        'accelerationLevel': capabilities.accelerationLevel.toString(),
        'maxTextureSize': capabilities.maxTextureSize,
        'supportedShaders': capabilities.supportedShaders,
        'supportedBlendModes':
            capabilities.supportedBlendModes.map((e) => e.toString()).toList(),
      }
    };
  }

  //量设置
  RenderQualitySettings getRenderQualitySettings() {
    return _qualityOptimizer.currentSettings;
  }

  /// 获取渲染统计信息
  Map<String, dynamic> getRenderStats() {
    final performanceStats = _performanceMonitor.getRecentStats();
    final cacheStats = _renderCache.getStats();
    final qualitySettings = _qualityOptimizer.currentSettings;

    return {
      'renderCount': _renderCount,
      'lastRenderTime': _lastRenderTime?.toIso8601String(),
      'dirtyElementsCount': _dirtyElements.length,
      'registeredRenderers': _renderers.keys.toList(),
      'gpuAcceleration': {
        'enabled': _gpuAccelerationEnabled,
        'strategy': _renderStrategy.toString(),
      },
      'renderQuality': {
        'level': qualitySettings.qualityLevel.toString(),
        'antiAlias': qualitySettings.antiAlias,
        'filterQuality': qualitySettings.filterQuality.toString(),
      },
      'performance': {
        'frameRate': performanceStats.frameRate,
        'frameTime': performanceStats.frameTime,
        'elementsPerFrame': performanceStats.elementsPerFrame,
        'cacheHitRate': performanceStats.cacheHitRate,
      },
      'cache': cacheStats,
      'performanceIssues': _performanceMonitor.checkPerformanceIssues(),
    };
  }

  /// 优化性能设置

  /// 优化性能设置
  void optimizePerformance() {
    // 清理过期缓存
    _renderCache.cleanup();

    // 检查性能问题并记录
    final issues = _performanceMonitor.checkPerformanceIssues();
    final performanceStats = _performanceMonitor.getRecentStats();

    if (issues.isNotEmpty) {
      print('Performance issues detected: ${issues.join(', ')}');

      // 自动调整GPU加速策略
      if (issues.any((issue) =>
          issue.contains('Low frame rate') ||
          issue.contains('High frame time'))) {
        // 如果检测到帧率问题，考虑切换渲染策略
        _gpuCapabilitiesFuture.then((capabilities) {
          if (_gpuAccelerationEnabled &&
              _renderStrategy == RenderStrategy.gpuAccelerated) {
            // 如果已经在使用GPU加速但性能不佳，降级到混合模式
            _renderStrategy = RenderStrategy.hybridPreferGpu;
          } else if (!_gpuAccelerationEnabled &&
              capabilities.accelerationLevel != GpuAccelerationLevel.none) {
            // 如果未启用GPU加速但设备支持，尝试启用
            _gpuAccelerationEnabled = true;
            _renderStrategy = RenderStrategy.hybridPreferSoftware;
          }
        });

        // 同时降低渲染质量
        _qualityOptimizer.setQualityLevel(RenderQualityLevel.low);
      }
    } else {
      // 如果性能良好，可以尝试提高渲染质量
      _qualityOptimizer.adjustForPerformance(performanceStats.frameRate);
    }

    // 定期重新评估GPU能力
    if (_renderCount % 100 == 0) {
      _initializeGpuCapabilities();
    }
  }

  /// 主渲染方法
  void render(Canvas canvas, Size size) {
    debugPrint('🎨 CanvasRenderingEngine.render 开始渲染');
    debugPrint('   - 画布尺寸: $size');
    debugPrint('   - 渲染计数: $_renderCount');

    _performanceMonitor.startFrame();
    _renderCount++;
    _lastRenderTime = DateTime.now();

    // 获取可见元素（按Z-index排序）
    final visibleElements = _getVisibleElements(size);
    debugPrint('📊 可见元素: ${visibleElements.length}个');

    // 输出可见元素的详细信息
    if (visibleElements.isNotEmpty) {
      debugPrint('📋 可见元素列表:');
      for (final element in visibleElements) {
        debugPrint('   - [${element.type}] ${element.id} (${element.bounds})');
      }
    }

    if (_gpuAccelerationEnabled &&
        _renderStrategy != RenderStrategy.softwareOnly) {
      // GPU加速渲染路径
      debugPrint('🚀 使用GPU加速渲染路径');
      _renderWithGpuAcceleration(canvas, size, visibleElements);
    } else {
      // 标准渲染路径
      debugPrint('🖌️ 使用标准渲染路径');
      _renderWithoutGpuAcceleration(canvas, size, visibleElements);
    }

    // 渲染选择框
    _renderSelectionBoxes(canvas);
    debugPrint('🔲 渲染选择框');

    // 清除脏标记
    _dirtyElements.clear();

    _performanceMonitor.endFrame();
    debugPrint('✅ CanvasRenderingEngine.render 渲染完成');
  }

  /// 渲染元素 - render方法的公共接口别名
  void renderElements(Canvas canvas, Size size) {
    render(canvas, size);
  }

  /// 设置是否自动调整渲染质量
  void setAutoQualityAdjustment(bool enabled) {
    _qualityOptimizer.autoAdjust = enabled;
  }

  /// 设置是否启用GPU加速
  void setGpuAccelerationEnabled(bool enabled) {
    _gpuAccelerationEnabled = enabled;
  }

  /// 设置渲染质量级别
  void setRenderQualityLevel(RenderQualityLevel level) {
    _qualityOptimizer.setQualityLevel(level);
  }

  /// 应用元素变换
  void _applyElementTransform(Canvas canvas, ElementData element) {
    if (element.type == 'text') {
      debugPrint('🔄 应用元素变换: ${element.id}');
      debugPrint('   - 位置: (${element.bounds.left}, ${element.bounds.top})');
      debugPrint('   - 尺寸: ${element.bounds.width} x ${element.bounds.height}');
      debugPrint('   - 旋转: ${element.rotation}');
      debugPrint('   - 透明度: ${element.opacity}');
    }

    // 移动到元素位置
    canvas.translate(element.bounds.left, element.bounds.top);

    // 应用旋转
    if (element.rotation != 0) {
      final center =
          Offset(element.bounds.width / 2, element.bounds.height / 2);
      canvas.translate(center.dx, center.dy);
      canvas.rotate(element.rotation);
      canvas.translate(-center.dx, -center.dy);

      if (element.type == 'text') {
        debugPrint('   - 已应用旋转变换: ${element.rotation} rad');
      }
    }

    // 应用透明度
    if (element.opacity < 1.0) {
      canvas.saveLayer(
        Rect.fromLTWH(0, 0, element.bounds.width, element.bounds.height),
        Paint()..color = Color.fromRGBO(255, 255, 255, element.opacity),
      );

      if (element.type == 'text') {
        debugPrint('   - 已应用透明度图层: ${element.opacity}');
      }
    }

    if (element.type == 'text') {
      debugPrint('✅ 元素变换应用完成');
    }
  }

  /// 批量渲染同类型元素
  void _batchRenderElements(Canvas canvas, List<ElementData> elements) {
    if (elements.isEmpty) return;

    final elementType = elements.first.type;
    final renderer = _renderers[elementType];
    if (renderer == null) return;

    // 检查是否有缓存可用
    final needRenderElements = <ElementData>[];

    for (final element in elements) {
      // 检查缓存
      final cachedElement =
          _renderCache.getRenderedElement(element.id, element.version);
      if (cachedElement != null) {
        // 使用缓存
        _performanceMonitor.recordCacheHit();
        canvas.save();
        canvas.translate(element.bounds.left, element.bounds.top);
        canvas.drawPicture(cachedElement);
        canvas.restore();
      } else {
        // 需要渲染
        needRenderElements.add(element);
      }
    }

    // 渲染未缓存的元素
    for (final element in needRenderElements) {
      _performanceMonitor.recordElementRender();
      _renderElement(canvas, element);
    }
  }

  /// 缓存渲染结果
  void _cachePicture(ElementData element) {
    // 创建临时记录器
    final recorder = ui.PictureRecorder();
    final recordCanvas = Canvas(recorder);

    // 在新画布上渲染
    final renderer = _renderers[element.type];
    if (renderer != null) {
      renderer.render(recordCanvas, element);

      // 完成记录并缓存
      final picture = recorder.endRecording();
      _renderCache.cacheElement(element.id, element.version, picture);
    }
  }

  /// 判断元素是否可以批处理渲染
  bool _canBatchRender(ElementData element) {
    // 相同类型、相近区域、未选中的元素可以批处理
    return !_stateManager.selectionState.isSelected(element.id) &&
        ['shape', 'path'].contains(element.type);
  }

  /// 获取可见元素
  List<ElementData> _getVisibleElements(Size canvasSize) {
    final allElements = _stateManager.elementState.elements.values.toList();
    debugPrint('📊 _getVisibleElements - 所有元素数量: ${allElements.length}');

    final result = allElements.where((element) {
      final visible = element.visible;
      final inViewport = _isElementInViewport(element, canvasSize);
      return visible && inViewport;
    }).toList()
      ..sort((a, b) => a.zIndex.compareTo(b.zIndex));

    debugPrint('📊 _getVisibleElements - 可见元素数量: ${result.length}');
    return result;
  }

  /// 初始化GPU能力检测
  void _initializeGpuCapabilities() {
    // 检测设备GPU能力
    _gpuCapabilitiesFuture =
        GpuAccelerationUtils.detectGpuCapabilities().then((capabilities) {
      // 根据能力决定渲染策略
      _renderStrategy =
          GpuAccelerationUtils.determineRenderStrategy(capabilities);
      return capabilities;
    });
  }

  /// 初始化专用渲染器
  void _initializeRenderers() {
    _renderers['text'] = TextElementRenderer();
    _renderers['image'] = ImageElementRenderer();
    _renderers['shape'] = ShapeElementRenderer();
    _renderers['path'] = PathElementRenderer();
    _renderers['collection'] = CollectionElementRenderer();
  }

  /// 检查元素是否在视口内
  bool _isElementInViewport(ElementData element, Size canvasSize) {
    final viewport = Rect.fromLTWH(0, 0, canvasSize.width, canvasSize.height);
    final result = element.bounds.overlaps(viewport);

    if (element.type == 'text') {
      debugPrint('🔍 检查文本元素是否在视口内:');
      debugPrint('   - 元素: ${element.id}');
      debugPrint('   - 元素边界: ${element.bounds}');
      debugPrint('   - 视口: $viewport');
      debugPrint('   - 结果: ${result ? "在视口内" : "不在视口内"}');
    }

    return result;
  }

  /// 标记脏元素
  void _markDirtyElements() {
    // TODO: 实现更精确的脏元素检测
    _dirtyElements.addAll(_stateManager.elementState.elements.keys);
  }

  /// 状态变化处理
  void _onStateChanged() {
    // 标记需要重绘的元素
    _markDirtyElements();

    // 确保选中元素被标记为脏元素
    final selectedIds = _stateManager.selectionState.selectedIds;
    _dirtyElements.addAll(selectedIds);
  }

  /// 渲染控制点
  void _renderControlPoints(Canvas canvas, Rect bounds) {
    final paint = Paint()
      ..color = const Color(0xFF2196F3)
      ..style = PaintingStyle.fill;

    const pointSize = 8.0;
    const halfPoint = pointSize / 2;

    // 8个控制点位置
    final points = [
      bounds.topLeft,
      bounds.topRight,
      bounds.bottomLeft,
      bounds.bottomRight,
      Offset(bounds.center.dx, bounds.top),
      Offset(bounds.center.dx, bounds.bottom),
      Offset(bounds.left, bounds.center.dy),
      Offset(bounds.right, bounds.center.dy),
    ];

    // 绘制控制点
    final whitePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    for (final point in points) {
      // 白色背景
      canvas.drawCircle(point, halfPoint + 1, whitePaint);
      // 蓝色前景
      canvas.drawCircle(point, halfPoint, paint);
    }
  }

  /// 渲染单个元素
  void _renderElement(Canvas canvas, ElementData element) {
    final renderer = _renderers[element.type];
    if (renderer != null) {
      // 添加调试日志，特别是针对文本元素
      if (element.type == 'text') {
        debugPrint('🎨 开始渲染文本元素: ${element.id}');
        final text = element.properties['text'] as String? ?? '未找到文本';
        debugPrint('📝 文本内容: "$text"');
        debugPrint('📐 文本边界: ${element.bounds}');
        debugPrint('📊 文本属性: ${element.properties.keys.join(', ')}');
      }

      // 检查缓存
      final cachedElement =
          _renderCache.getRenderedElement(element.id, element.version);
      if (cachedElement != null) {
        // 使用缓存
        _performanceMonitor.recordCacheHit();
        canvas.drawPicture(cachedElement);
        if (element.type == 'text') {
          debugPrint('🖼️ 使用缓存渲染文本元素: ${element.id}');
        }
        return;
      }

      // 没有缓存，需要重新渲染
      canvas.save();
      try {
        // 应用元素变换
        _applyElementTransform(canvas, element);

        // 准备渲染用的画笔
        final paint = Paint();
        _qualityOptimizer.applyToPaint(paint); // 渲染元素
        try {
          if (element.type == 'text') {
            debugPrint('🖌️ 调用文本渲染器渲染元素: ${element.id}');
          }
          renderer.render(canvas, element);
          if (element.type == 'text') {
            debugPrint('✅ 文本渲染器完成渲染: ${element.id}');
          }
        } catch (e, stackTrace) {
          debugPrint('❌ 渲染元素时出错: $e');
          debugPrint('📍 元素类型: ${element.type}, ID: ${element.id}');
          debugPrint('📍 Stack trace: $stackTrace');
        }

        // 记录渲染
        _performanceMonitor.recordElementRender();

        // 尝试缓存渲染结果（仅非选中状态的元素）
        if (!_stateManager.selectionState.isSelected(element.id) &&
            !_shouldSkipCaching(element)) {
          _cachePicture(element);
        }
      } finally {
        canvas.restore();
      }
    }
  }

  /// 渲染单个选择框
  void _renderSelectionBox(Canvas canvas, ElementData element) {
    canvas.save();
    try {
      final paint = Paint()
        ..color = const Color(0xFF2196F3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;

      // 绘制选择框
      canvas.drawRect(element.bounds, paint);

      // 渲染控制点
      _renderControlPoints(canvas, element.bounds);
    } finally {
      canvas.restore();
    }
  }

  /// 渲染选择框
  void _renderSelectionBoxes(Canvas canvas) {
    final selectedIds = _stateManager.selectionState.selectedIds;

    for (final elementId in selectedIds) {
      final element = _stateManager.elementState.getElementById(elementId);
      if (element != null && element.visible) {
        _renderSelectionBox(canvas, element);
      }
    }
  }

  /// 使用GPU加速渲染
  void _renderWithGpuAcceleration(
      Canvas canvas, Size size, List<ElementData> elements) {
    // 在实际实现中，这里应该有GPU特定的加速代码
    // 目前仍使用标准渲染路径，但可以应用GPU特定优化

    // 对于可以GPU批处理的元素，进行分组
    final batchableElements = <String, List<ElementData>>{};
    final unbatchableElements = <ElementData>[];

    for (final element in elements) {
      if (_canBatchRender(element)) {
        final type = element.type;
        batchableElements.putIfAbsent(type, () => []).add(element);
      } else {
        unbatchableElements.add(element);
      }
    }

    // 先批量渲染同类型元素
    for (final entry in batchableElements.entries) {
      _batchRenderElements(canvas, entry.value);
    }

    // 再渲染不可批处理的元素
    for (final element in unbatchableElements) {
      _performanceMonitor.recordElementRender();
      _renderElement(canvas, element);
    }
  }

  /// 标准渲染路径（无GPU加速）
  void _renderWithoutGpuAcceleration(
      Canvas canvas, Size size, List<ElementData> elements) {
    debugPrint('🖌️ 开始标准渲染路径');
    debugPrint('   - 待渲染元素数量: ${elements.length}');

    // 渲染元素
    for (final element in elements) {
      debugPrint('   - 渲染元素: ${element.id} (${element.type})');
      _performanceMonitor.recordElementRender();
      _renderElement(canvas, element);
    }

    debugPrint('✅ 标准渲染路径完成');
  }

  /// 判断是否应该跳过缓存
  bool _shouldSkipCaching(ElementData element) {
    // 对于文本元素，记录调试信息
    if (element.type == 'text') {
      debugPrint('📋 检查是否应该缓存文本元素: ${element.id}');
      debugPrint(
          '   - 元素尺寸: ${element.bounds.width} x ${element.bounds.height}');
      debugPrint('   - 面积: ${element.bounds.width * element.bounds.height}');
    }

    // 跳过较小的元素缓存（面积小于100平方像素）
    if (element.bounds.width * element.bounds.height < 100) {
      if (element.type == 'text') {
        debugPrint('   - 决定: 不缓存 (元素太小)');
      }
      return true;
    }

    // 根据元素类型判断
    switch (element.type) {
      case 'text':
        // 文本元素小于200宽度时不缓存
        final skip = element.bounds.width < 200;
        debugPrint(
            '   - 决定: ${skip ? "不缓存" : "缓存"} (宽度${skip ? "<" : ">="}200)');
        return skip;
      case 'image':
        // 图像元素通常较大，缓存
        return false;
      default:
        return false;
    }
  }
}

/// 元素渲染器基类
abstract class ElementRenderer {
  /// 清理资源
  void dispose() {}

  /// 渲染元素
  void render(Canvas canvas, ElementData element);
}
