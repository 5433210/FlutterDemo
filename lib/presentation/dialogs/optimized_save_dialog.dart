import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../utils/dialog_navigation_helper.dart';
import '../widgets/practice/optimized_save_service.dart';

/// 优化保存进度对话框
class OptimizedSaveDialog extends StatefulWidget {
  final Future<SaveResult> saveFuture;
  final String title;

  const OptimizedSaveDialog({
    super.key,
    required this.saveFuture,
    required this.title,
  });

  @override
  State<OptimizedSaveDialog> createState() => _OptimizedSaveDialogState();
}

class _OptimizedSaveDialogState extends State<OptimizedSaveDialog>
    with TickerProviderStateMixin {
  late AnimationController _progressController;
  late Animation<double> _progressAnimation;
  double _progress = 0.0;
  String _currentStage = '';
  String _stageDetail = '';
  bool _completed = false;
  bool _hasError = false;
  String? _errorMessage;
  bool _hasNavigated = false; // 添加标志防止重复导航

  @override
  void initState() {
    super.initState();

    _progressController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _progressAnimation = CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeInOut,
    );

    // 在下一帧开始保存操作，确保组件完全初始化
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _startSaving();
      }
    });
  }

  @override
  void dispose() {
    // 确保动画控制器被正确销毁
    try {
      _progressController.dispose();
    } catch (e) {
      debugPrint(
          'OptimizedSaveDialog: Error disposing animation controller: $e');
    }
    super.dispose();
  }

  Future<void> _startSaving() async {
    final l10n = AppLocalizations.of(context);
    
    try {
      // 更新保存阶段信息 - 优化：避免重复显示相同信息
      setState(() {
        _progress = 0.1;
        _currentStage = l10n.savingToStorage;
        _stageDetail = ''; // 避免重复显示相同信息
      });

      final result = await widget.saveFuture;

      if (!mounted) return;

      setState(() {
        _progress = 1.0;
        _completed = true;
        _hasError = !result.success;
        if (result.success) {
          _currentStage = l10n.saveSuccess;
          _stageDetail = ''; // 简化显示，避免冗余
        } else {
          _currentStage = l10n.saveFailure;
          _stageDetail = result.message ?? l10n.saveFailed;
          _errorMessage = result.message ?? l10n.saveFailed;
        }
      });

      // 安全地执行动画
      await _safeAnimateProgress();

      // 成功时自动关闭，失败时让用户手动关闭
      if (result.success && !_hasNavigated && mounted) {
        await Future.delayed(const Duration(milliseconds: 1000));
        if (mounted && !_hasNavigated) {
          _hasNavigated = true; // 标记已开始导航
          await DialogNavigationHelper.safePopWithTypeGuard<SaveResult>(
            context,
            result: result,
            dialogName: 'OptimizedSaveDialog',
          );
        }
      }
    } catch (e) {
      if (!mounted) return;

      // 特殊处理图像相关错误
      String errorMessage = _formatErrorMessage(e);

      setState(() {
        _progress = 1.0;
        _completed = true;
        _hasError = true;
        _currentStage = l10n.saveFailure;
        _stageDetail = ''; // 错误详情会单独显示，避免冗余
        _errorMessage = errorMessage;
      });

      // 安全地执行动画
      await _safeAnimateProgress();
    }
  }

  /// 格式化错误消息，对常见错误提供更友好的提示
  String _formatErrorMessage(dynamic error) {
    final errorStr = error.toString().toLowerCase();

    if (errorStr.contains('invalid image data')) {
      // 检查是否为SVG相关错误
      if (errorStr.contains('svg') || errorStr.contains('.svg')) {
        return 'SVG图像格式不受支持，请使用PNG或JPG格式';
      }
      return '图像数据无效，可能是文件损坏或格式不受支持。\n建议：请确保文件为有效的PNG、JPG或SVG格式';
    } else if (errorStr.contains('file not found') ||
        errorStr.contains('no such file')) {
      return '找不到指定的文件，可能文件已被移动或删除';
    } else if (errorStr.contains('permission denied')) {
      return '文件访问权限不足，请检查文件读写权限';
    } else if (errorStr.contains('disk full') ||
        errorStr.contains('no space left')) {
      return '磁盘空间不足，请清理磁盘空间后重试';
    } else if (errorStr.contains('timeout')) {
      return '操作超时，请检查网络连接或重试';
    } else if (errorStr.contains('network')) {
      return '网络连接错误，请检查网络状态';
    } else if (errorStr.contains('format') || errorStr.contains('codec')) {
      return '图像格式不受支持或文件已损坏';
    } else {
      // 提取更有用的错误信息
      final lines = error.toString().split('\n');
      final firstLine = lines.isNotEmpty ? lines[0] : error.toString();
      return '操作失败：$firstLine';
    }
  }

  /// 安全地执行进度动画，避免在组件销毁后操作动画控制器
  Future<void> _safeAnimateProgress() async {
    if (!mounted) return;

    try {
      // 检查动画控制器是否仍然有效
      if (_progressController.status != AnimationStatus.dismissed &&
          _progressController.status != AnimationStatus.completed) {
        await _progressController.forward();
      } else {
        // 如果动画已经完成或被重置，直接设置为完成状态
        _progressController.value = 1.0;
      }
    } catch (e) {
      // 动画控制器可能已被销毁或遇到其他错误，忽略
      debugPrint('OptimizedSaveDialog: Animation controller error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return PopScope(
      canPop: _completed,
      child: AlertDialog(
        title: Row(
          children: [
            Icon(
              _hasError
                  ? Icons.error_outline
                  : _completed
                      ? Icons.check_circle_outline
                      : Icons.save_outlined,
              color: _hasError
                  ? theme.colorScheme.error
                  : _completed
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurface,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _hasError
                    ? l10n.saveFailure
                    : _completed
                        ? l10n.saveSuccess
                        : '${l10n.save} ${widget.title}...',
                style: theme.textTheme.titleLarge,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 进度条
            AnimatedBuilder(
              animation: _progressAnimation,
              builder: (context, child) {
                // 安全地获取动画值，防止在重建过程中出现错误
                double animationValue;
                try {
                  animationValue = _progressAnimation.value;
                } catch (e) {
                  // 如果动画值获取失败，使用当前进度值
                  animationValue = _progress;
                }

                return LinearProgressIndicator(
                  value: animationValue,
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _hasError
                        ? theme.colorScheme.error
                        : theme.colorScheme.primary,
                  ),
                );
              },
            ),

            const SizedBox(height: 16),

            // 状态消息 - 显示当前阶段和详细信息
            if (_currentStage.isNotEmpty) ...[
              Text(
                _currentStage,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: _hasError
                      ? theme.colorScheme.error
                      : theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (_stageDetail.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  _stageDetail,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: _hasError
                        ? theme.colorScheme.error
                        : theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ],

            // 错误详情
            if (_hasError && _errorMessage != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.errorContainer.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  _errorMessage!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onErrorContainer,
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          if (_completed) ...[
            if (_hasError) ...[
              TextButton(
                onPressed: () => DialogNavigationHelper.safeCancel(
                  context,
                  dialogName: 'OptimizedSaveDialog',
                ),
                child: Text(l10n.retry),
              ),
            ],
            FilledButton(
              onPressed: () => DialogNavigationHelper.safeCancel(
                context,
                dialogName: 'OptimizedSaveDialog',
              ),
              child: Text(_hasError ? l10n.confirm : l10n.done),
            ),
          ] else ...[
            TextButton(
              onPressed: () => DialogNavigationHelper.safeCancel(
                context,
                dialogName: 'OptimizedSaveDialog',
              ),
              child: Text(l10n.cancel),
            ),
          ],
        ],
      ),
    );
  }
}

/// 显示优化保存对话框的便捷方法
Future<SaveResult?> showOptimizedSaveDialog({
  required BuildContext context,
  required Future<SaveResult> saveFuture,
  required String title,
}) async {
  return await showDialog<SaveResult>(
    context: context,
    barrierDismissible: false,
    builder: (context) => OptimizedSaveDialog(
      saveFuture: saveFuture,
      title: title,
    ),
  );
}
