/// Canvas主页面 - 集成新工具栏系统的测试页面
///
/// 职责：
/// 1. 展示新的Canvas系统
/// 2. 集成工具栏组件
/// 3. 验证工具切换功能
/// 4. 提供完整的Canvas编辑体验
library;

import 'package:flutter/material.dart';

import '../core/canvas_state_manager.dart';
import 'canvas_widget.dart';
import 'toolbar/canvas_toolbar.dart';
import 'toolbar/tool_state_manager.dart';

/// Canvas主页面
class CanvasPage extends StatefulWidget {
  const CanvasPage({super.key});

  @override
  State<CanvasPage> createState() => _CanvasPageState();
}

class _CanvasPageState extends State<CanvasPage> {
  late final CanvasStateManager _stateManager;
  late final ToolStateManager _toolStateManager;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Canvas重构 - Phase 2.1'),
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerLow,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _showCanvasInfo,
            icon: const Icon(Icons.info_outline),
            tooltip: '显示Canvas信息',
          ),
          IconButton(
            onPressed: _resetCanvas,
            icon: const Icon(Icons.refresh),
            tooltip: '重置Canvas',
          ),
        ],
      ),
      body: Column(
        children: [
          // 工具栏
          CanvasToolbar(
            stateManager: _stateManager,
            toolStateManager: _toolStateManager,
            onToolSelected: _onToolSelected,
            showAdvancedTools: true,
          ),

          // Canvas区域
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Card(
                elevation: 2,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: const CanvasWidget(
                    configuration: CanvasConfiguration(
                      size: Size(800, 600),
                      backgroundColor: Colors.white,
                      showGrid: true,
                      gridSize: 20,
                      enableGestures: true,
                      enablePerformanceMonitoring: true,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // 状态栏
          _buildStatusBar(),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _toolStateManager.removeListener(_onToolChanged);
    _toolStateManager.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _stateManager = CanvasStateManager();
    _toolStateManager = ToolStateManager();

    // 监听工具变化
    _toolStateManager.addListener(_onToolChanged);
  }

  /// 构建信息行
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  /// 构建状态栏
  Widget _buildStatusBar() {
    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHigh,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).colorScheme.outlineVariant,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.circle,
            size: 8,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Text(
            '当前工具: ${_toolStateManager.currentTool.displayName}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const Spacer(),
          Text(
            'Canvas重构 Phase 2.1 - 工具栏系统',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }

  void _onToolChanged() {
    // 当工具变化时可以执行额外逻辑
    debugPrint('Canvas页面：工具切换为 ${_toolStateManager.currentTool}');
  }

  /// 工具选择回调
  void _onToolSelected(ToolType tool) {
    debugPrint('Canvas页面：用户选择工具 $tool');

    // 显示工具选择反馈
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('已切换到 ${tool.displayName} 工具'),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  /// 重置Canvas
  void _resetCanvas() {
    setState(() {});

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Canvas已重置'),
        duration: Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.all(16),
      ),
    );
  }

  /// 显示Canvas信息
  void _showCanvasInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Canvas系统信息'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow('当前阶段', 'Phase 2.1 - 工具栏系统重构'),
            _buildInfoRow('当前工具', _toolStateManager.currentTool.displayName),
            _buildInfoRow(
                '元素数量', '${_stateManager.elementState.elements.length}'),
            _buildInfoRow(
                '选中元素', '${_stateManager.selectionState.selectedIds.length}'),
            const SizedBox(height: 16),
            const Text(
              '这是Canvas重构第二阶段的测试页面，展示了新的工具栏系统与手势处理器的集成。',
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }
}
