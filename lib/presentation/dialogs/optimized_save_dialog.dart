import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
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
  final String _message = '';
  bool _completed = false;
  bool _hasError = false;
  String? _errorMessage;

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

    _startSaving();
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  Future<void> _startSaving() async {
    try {
      final result = await widget.saveFuture;

      if (mounted) {
        setState(() {
          _progress = 1.0;
          _completed = true;
          _hasError = !result.success;
        });

        await _progressController.forward();

        // 成功时自动关闭，失败时让用户手动关闭
        if (result.success) {
          await Future.delayed(const Duration(milliseconds: 1000));
          if (mounted) {
            Navigator.of(context).pop(result);
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _progress = 1.0;
          _completed = true;
          _hasError = true;
          _errorMessage = e.toString();
        });

        await _progressController.forward();
      }
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
                return LinearProgressIndicator(
                  value: _progressAnimation.value,
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

            // 状态消息
            Text(
              _message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: _hasError
                    ? theme.colorScheme.error
                    : theme.colorScheme.onSurface,
              ),
            ),

            // 错误详情
            if (_hasError && _errorMessage != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.errorContainer.withOpacity(0.3),
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

            // 进度百分比
            if (!_completed) ...[
              const SizedBox(height: 8),
              Text(
                '${(_progress * 100).toInt()}%',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
        actions: [
          if (_completed) ...[
            if (_hasError) ...[
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(l10n.retry),
              ),
            ],
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(_hasError ? l10n.confirm : l10n.done),
            ),
          ] else ...[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
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
