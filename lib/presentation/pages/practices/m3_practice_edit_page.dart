import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/providers/service_providers.dart';
import '../../widgets/page_layout.dart';
import '../../widgets/practice/m3_top_navigation_bar.dart';
import '../../widgets/practice/practice_edit_controller.dart';
import 'state/practice_edit_state_manager.dart';
import 'widgets/practice_edit_layout.dart';

/// Material 3 版本的字帖编辑页面 - 重构版本
/// 集成新的状态管理器和布局组件
class M3PracticeEditPageRefactored extends ConsumerStatefulWidget {
  final String? practiceId;

  const M3PracticeEditPageRefactored({super.key, this.practiceId});

  @override
  ConsumerState<M3PracticeEditPageRefactored> createState() =>
      _M3PracticeEditPageRefactoredState();
}

class _M3PracticeEditPageRefactoredState
    extends ConsumerState<M3PracticeEditPageRefactored>
    with WidgetsBindingObserver {
  // 核心组件
  late final PracticeEditController _controller;
  late final PracticeEditStateManager _stateManager;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: PageLayout(
        toolbar: AnimatedBuilder(
          animation: Listenable.merge([_controller, _stateManager]),
          builder: (context, child) {
            return M3TopNavigationBar(
              controller: _controller,
              practiceId: widget.practiceId,
              isPreviewMode: _stateManager.isPreviewMode,
              onTogglePreviewMode: () {
                _stateManager.togglePreviewMode();
                _controller.togglePreviewMode(_stateManager.isPreviewMode);
              },
              showThumbnails: _stateManager.showThumbnails,
              onThumbnailToggle: _stateManager.setShowThumbnails,
            );
          },
        ),
        body: PracticeEditLayout(
          controller: _controller,
          stateManager: _stateManager,
        ),
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.practiceId != null) {
      _loadPractice(widget.practiceId!);
    }
  }

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    // 窗口大小变化时重置视图位置
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        _resetViewPosition();
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stateManager.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // 初始化状态管理器
    _stateManager = PracticeEditStateManager();

    // 创建控制器
    final practiceService = ref.read(practiceServiceProvider);
    _controller = PracticeEditController(practiceService);
    _controller.setCanvasKey(_stateManager.canvasKey);

    // 设置预览模式回调
    _controller.setPreviewModeCallback((isPreview) {
      _stateManager.setPreviewMode(isPreview);
    });

    // 同步工具状态
    _controller.addListener(_syncToolState);

    // Canvas连接
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupCanvasReference();
    });
  }

  Future<void> _loadPractice(String practiceId) async {
    try {
      await _controller.loadPractice(practiceId);
    } catch (e) {
      // 处理加载错误
      debugPrint('加载练习失败: $e');
    }
  }

  Future<bool> _onWillPop() async {
    // 简化的退出检查
    return true;
  }

  void _resetViewPosition() {
    _stateManager.transformationController.value = Matrix4.identity();
  }

  void _setupCanvasReference() {
    // 设置canvas引用，用于重置视图等功能
  }

  // === 私有方法 ===

  void _syncToolState() {
    final controllerTool = _controller.state.currentTool;
    if (_stateManager.currentTool != controllerTool) {
      _stateManager.setCurrentTool(controllerTool);
    }
  }
}
