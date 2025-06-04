// filepath: lib/canvas/integration/practice_edit_canvas_adapter.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../presentation/widgets/practice/practice_edit_controller.dart';
import '../compatibility/canvas_controller_adapter.dart';
import '../ui/canvas_widget.dart';

/// 练习编辑Canvas适配器 - 专门为practice edit页面设计的新Canvas集成
class PracticeEditCanvasAdapter extends ConsumerStatefulWidget {
  final PracticeEditController controller;
  final bool isPreviewMode;
  final TransformationController transformationController;

  const PracticeEditCanvasAdapter({
    super.key,
    required this.controller,
    required this.isPreviewMode,
    required this.transformationController,
  });

  @override
  ConsumerState<PracticeEditCanvasAdapter> createState() =>
      _PracticeEditCanvasAdapterState();
}

class _PracticeEditCanvasAdapterState
    extends ConsumerState<PracticeEditCanvasAdapter> {
  late final CanvasControllerAdapter _canvasAdapter;
  late final CanvasConfiguration _canvasConfiguration;
  bool _initialized = false;

  @override
  Widget build(BuildContext context) {
    return CanvasWidget(
      configuration: _canvasConfiguration,
      controller: _canvasAdapter,
      transformationController: widget.transformationController,
      isPreviewMode: widget.isPreviewMode,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // 在build完成后，确保同步数据和设置监听器
    if (!_initialized) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _syncInitialData();
        _setupEventListeners();
        _initialized = true;
        
        // 强制刷新一次
        if (mounted) {
          setState(() {});
        }
      });
    }
  }

  @override
  void dispose() {
    // 移除监听器
    widget.controller.removeListener(_onControllerStateChanged);
    _canvasAdapter.removeListener(_onCanvasStateChanged);
    _canvasAdapter.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _initializeAdapter();
  }

  CanvasConfiguration _createCanvasConfiguration() {
    return CanvasConfiguration(
      size: const Size(800, 600), // 可根据需要调整
      backgroundColor: Colors.white,
      showGrid: !widget.isPreviewMode, // 预览模式不显示网格
      gridSize: 20.0,
      gridColor: const Color(0xFFE0E0E0),
      enableGestures: !widget.isPreviewMode, // 预览模式禁用手势
      enablePerformanceMonitoring: true,
    );
  }

  void _initializeAdapter() {
    // 创建Canvas适配器
    _canvasAdapter = CanvasControllerAdapter();

    // 设置Canvas配置
    _canvasConfiguration = _createCanvasConfiguration();
  }

  void _onCanvasStateChanged() {
    // 当Canvas状态变化时，同步到原Controller
    debugPrint('🔄 Canvas状态变化，同步到Controller');
    
    // 这里我们不实现从Canvas到Controller的同步，避免循环依赖
    // 但保留这个方法以便将来需要时实现
  }
  
  void _onControllerStateChanged() {
    // 当原Controller状态变化时，同步到新Canvas
    debugPrint('🔄 Controller状态变化，同步到Canvas');
    final currentPage = widget.controller.state.currentPage;
    if (currentPage != null) {
      try {
        debugPrint('⚡ 开始同步状态到Canvas...');

        // 获取控制器中当前页面的所有元素
        final elements = widget.controller.state.currentPageElements;
        debugPrint('📊 当前页面有 ${elements.length} 个元素');

        // 获取已经存在于Canvas中的元素
        final existingElements = _canvasAdapter.elements;
        debugPrint('📊 Canvas中有 ${existingElements.length} 个元素');

        // 为避免不必要的重复刷新，只有当元素发生变化时才进行更新
        bool needsUpdate = existingElements.length != elements.length;
        
        if (!needsUpdate) {
          // 检查元素内容是否相同
          for (int i = 0; i < elements.length; i++) {
            if (i >= existingElements.length || 
                elements[i]['id'] != existingElements[i]['id']) {
              needsUpdate = true;
              break;
            }
          }
        }

        if (needsUpdate) {
          debugPrint('🔄 检测到元素变化，更新Canvas');
          
          // 1. 先清除所有选择
          _canvasAdapter.clearSelection();

          // 2. 选择所有现有元素
          for (final element in existingElements) {
            final id = element['id'] as String;
            _canvasAdapter.selectElement(id);
          }

          // 3. 删除所有选中的元素
          if (existingElements.isNotEmpty) {
            debugPrint('🗑️ 删除所有现有元素');
            _canvasAdapter.deleteSelectedElements();
          }

          // 4. 添加所有新元素
          debugPrint('➕ 添加 ${elements.length} 个新元素');
          for (final element in elements) {
            // 对于文本元素，记录更多详细信息以便于调试
            if (element['type'] == 'text') {
              final content = element['content'] as Map<String, dynamic>?;
              final textContent = content?['text'] as String? ?? '未找到文本';
              debugPrint('📝 添加文本元素，内容: "$textContent"');
              debugPrint('📊 文本属性: ${content?.keys.join(', ')}');
            }
            
            _canvasAdapter.addElement(element);
          }

          // 5. 同步选中状态
          final selectedIds = widget.controller.state.selectedElementIds;
          debugPrint('🎯 选中 ${selectedIds.length} 个元素');

          // 先清除选择
          _canvasAdapter.clearSelection();

          // 然后选择应该被选中的元素
          for (final id in selectedIds) {
            _canvasAdapter.selectElement(id);
          }

          debugPrint('✅ 状态同步完成');
          
          // 手动触发一次重绘，确保元素被渲染
          if (mounted) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              debugPrint('🔄 手动触发状态变更后的重绘');
              setState(() {});
            });
          }
        } else {
          debugPrint('✅ 元素未变化，无需更新Canvas');
        }
      } catch (e, stackTrace) {
        debugPrint('❌ 同步状态时发生错误: $e');
        debugPrint('📍 Stack trace: $stackTrace');
      }
    }
  }

  void _setupEventListeners() {
    debugPrint('🔄 设置事件监听器');
    
    // 监听Controller状态变化，同步到Canvas
    widget.controller.addListener(_onControllerStateChanged);

    // 监听Canvas变化，同步到Controller
    _canvasAdapter.addListener(_onCanvasStateChanged);
  }

  void _syncInitialData() {
    debugPrint('📊 开始同步初始数据到Canvas...');

    // 同步当前页面的元素到新Canvas
    final currentPage = widget.controller.state.currentPage;
    if (currentPage != null) {
      final elements = widget.controller.state.currentPageElements;
      debugPrint('📊 初始同步: 当前页面有 ${elements.length} 个元素');
      if (elements.isNotEmpty) {
        for (final element in elements) {
          final elementType = element['type'] as String;
          final elementId = element['id'] as String;
          debugPrint('➕ 添加元素: $elementId ($elementType)');
          
          // 对于文本元素，记录更多详细信息以便于调试
          if (elementType == 'text') {
            final content = element['content'] as Map<String, dynamic>?;
            final textContent = content?['text'] as String? ?? '未找到文本';
            debugPrint('📝 文本内容: "$textContent"');
            debugPrint('📊 文本属性: ${content?.keys.join(', ')}');
          }
          
          _canvasAdapter.addElement(element);
        }
        debugPrint('✅ 所有元素添加完成');
        
        // 手动触发一次重绘，确保元素被渲染
        if (mounted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            debugPrint('🔄 手动触发重绘');
            setState(() {});
          });
        }
      } else {
        debugPrint('⚠️ 当前页面没有元素');
      }
    } else {
      debugPrint('⚠️ 当前页面为null');
    }

    // 同步选中状态
    final selectedIds = widget.controller.state.selectedElementIds;
    if (selectedIds.isNotEmpty) {
      debugPrint('🎯 初始同步: 选中 ${selectedIds.length} 个元素');
      for (final id in selectedIds) {
        _canvasAdapter.selectElement(id);
      }
    }

    debugPrint('✅ 初始数据同步完成');
  }
}
