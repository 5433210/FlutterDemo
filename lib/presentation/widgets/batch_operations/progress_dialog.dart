import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';

/// 批量操作进度对话框
class ProgressDialog extends StatefulWidget {
  final String title;
  final String? initialMessage;
  final VoidCallback? onCancel;
  final bool canCancel;

  const ProgressDialog({
    super.key,
    required this.title,
    this.initialMessage,
    this.onCancel,
    this.canCancel = true,
  });

  @override
  State<ProgressDialog> createState() => _ProgressDialogState();

  /// 显示进度对话框的便捷方法
  static Future<T?> show<T>({
    required BuildContext context,
    required String title,
    String? initialMessage,
    VoidCallback? onCancel,
    bool canCancel = true,
    bool barrierDismissible = false,
  }) {
    return showDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible && canCancel,
      builder: (context) => ProgressDialog(
        title: title,
        initialMessage: initialMessage,
        onCancel: onCancel,
        canCancel: canCancel,
      ),
    );
  }
}

class _ProgressDialogState extends State<ProgressDialog> {
  double _progress = 0.0;
  String _message = '';
  Map<String, dynamic>? _data;
  bool _isCompleted = false;
  bool _hasError = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _message = widget.initialMessage ?? '';
  }

  /// 更新进度
  void updateProgress(double progress, String message, [Map<String, dynamic>? data]) {
    if (mounted) {
      setState(() {
        _progress = progress.clamp(0.0, 1.0);
        _message = message;
        _data = data;
        _isCompleted = progress >= 1.0;
        _hasError = false;
        _errorMessage = null;
      });
    }
  }

  /// 显示错误
  void showError(String errorMessage) {
    if (mounted) {
      setState(() {
        _hasError = true;
        _errorMessage = errorMessage;
        _isCompleted = false;
      });
    }
  }

  /// 完成操作
  void complete([String? finalMessage]) {
    if (mounted) {
      setState(() {
        _progress = 1.0;
        _message = finalMessage ?? _message;
        _isCompleted = true;
        _hasError = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return PopScope(
      canPop: widget.canCancel && !_isCompleted && !_hasError,
      child: AlertDialog(
        title: Row(
          children: [
            if (_hasError)
              Icon(Icons.error, color: theme.colorScheme.error)
            else if (_isCompleted)
              Icon(Icons.check_circle, color: Colors.green)
            else
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                widget.title,
                style: theme.textTheme.titleLarge?.copyWith(
                  color: _hasError ? theme.colorScheme.error : null,
                ),
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 300,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 进度条
              if (!_hasError) ...[
                LinearProgressIndicator(
                  value: _progress,
                  backgroundColor: theme.colorScheme.surfaceVariant,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _isCompleted ? Colors.green : theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 8),
                // 进度百分比
                Text(
                  '${(_progress * 100).toInt()}%',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // 状态消息
              if (_message.isNotEmpty) ...[
                Text(
                  _message,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: _hasError ? theme.colorScheme.error : null,
                  ),
                ),
                const SizedBox(height: 8),
              ],

              // 错误消息
              if (_hasError && _errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.errorContainer.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: theme.colorScheme.error.withOpacity(0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 16,
                            color: theme.colorScheme.error,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            l10n.error(''),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.error,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _errorMessage!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onErrorContainer,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
              ],

              // 附加数据显示
              if (_data != null && _data!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: _data!.entries.map((entry) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 1),
                        child: Text(
                          '${entry.key}: ${entry.value}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          // 取消按钮
          if (widget.canCancel && !_isCompleted && !_hasError)
            TextButton(
              onPressed: () {
                widget.onCancel?.call();
                Navigator.of(context).pop();
              },
              child: Text(l10n.cancel),
            ),

          // 重试按钮（错误时）
          if (_hasError)
            TextButton(
              onPressed: () {
                setState(() {
                  _hasError = false;
                  _errorMessage = null;
                  _progress = 0.0;
                  _message = widget.initialMessage ?? '';
                });
              },
              child: Text(l10n.retry),
            ),

          // 关闭按钮（完成或错误时）
          if (_isCompleted || _hasError)
            FilledButton(
              onPressed: () => Navigator.of(context).pop(_isCompleted),
              child: Text(_isCompleted ? l10n.done : l10n.close),
            ),
        ],
      ),
    );
  }
}

/// 进度对话框控制器
class ProgressDialogController {
  dynamic _state;
  bool _isDisposed = false;

  /// 绑定到对话框状态
  void _bind(dynamic state) {
    _state = state;
  }

  /// 更新进度
  void updateProgress(double progress, String message, [Map<String, dynamic>? data]) {
    if (!_isDisposed && _state != null) {
      _state!.updateProgress(progress, message, data);
    }
  }

  /// 显示错误
  void showError(String errorMessage) {
    if (!_isDisposed && _state != null) {
      _state!.showError(errorMessage);
    }
  }

  /// 完成操作
  void complete([String? finalMessage]) {
    if (!_isDisposed && _state != null) {
      _state!.complete(finalMessage);
    }
  }

  /// 释放资源
  void dispose() {
    _isDisposed = true;
    _state = null;
  }
}

/// 带控制器的进度对话框
class ControlledProgressDialog extends StatefulWidget {
  final String title;
  final String? initialMessage;
  final ProgressDialogController controller;
  final VoidCallback? onCancel;
  final bool canCancel;

  const ControlledProgressDialog({
    super.key,
    required this.title,
    required this.controller,
    this.initialMessage,
    this.onCancel,
    this.canCancel = true,
  });

  @override
  State<ControlledProgressDialog> createState() => _ControlledProgressDialogState();

  /// 显示带控制器的进度对话框
  static Future<T?> show<T>({
    required BuildContext context,
    required String title,
    required ProgressDialogController controller,
    String? initialMessage,
    VoidCallback? onCancel,
    bool canCancel = true,
    bool barrierDismissible = false,
  }) {
    return showDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible && canCancel,
      builder: (context) => ControlledProgressDialog(
        title: title,
        controller: controller,
        initialMessage: initialMessage,
        onCancel: onCancel,
        canCancel: canCancel,
      ),
    );
  }
}

class _ControlledProgressDialogState extends State<ControlledProgressDialog> {
  double _progress = 0.0;
  String _message = '';
  Map<String, dynamic>? _data;
  bool _isCompleted = false;
  bool _hasError = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _message = widget.initialMessage ?? '';
    // 绑定控制器
    widget.controller._bind(this);
  }

  @override
  void dispose() {
    // 解绑控制器
    widget.controller._state = null;
    super.dispose();
  }

  /// 更新进度
  void updateProgress(double progress, String message, [Map<String, dynamic>? data]) {
    if (mounted) {
      setState(() {
        _progress = progress.clamp(0.0, 1.0);
        _message = message;
        _data = data;
        _isCompleted = progress >= 1.0;
        _hasError = false;
        _errorMessage = null;
      });
    }
  }

  /// 显示错误
  void showError(String errorMessage) {
    if (mounted) {
      setState(() {
        _hasError = true;
        _errorMessage = errorMessage;
        _isCompleted = false;
      });
    }
  }

  /// 完成操作
  void complete([String? finalMessage]) {
    if (mounted) {
      setState(() {
        _progress = 1.0;
        _message = finalMessage ?? _message;
        _isCompleted = true;
        _hasError = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return PopScope(
      canPop: widget.canCancel && !_isCompleted && !_hasError,
      child: AlertDialog(
        title: Row(
          children: [
            if (_hasError)
              Icon(Icons.error, color: theme.colorScheme.error)
            else if (_isCompleted)
              Icon(Icons.check_circle, color: Colors.green)
            else
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                widget.title,
                style: theme.textTheme.titleLarge?.copyWith(
                  color: _hasError ? theme.colorScheme.error : null,
                ),
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 300,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 进度条
              if (!_hasError) ...[
                LinearProgressIndicator(
                  value: _progress,
                  backgroundColor: theme.colorScheme.surfaceVariant,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _isCompleted ? Colors.green : theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 8),
                // 进度百分比
                Text(
                  '${(_progress * 100).toInt()}%',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // 状态消息
              if (_message.isNotEmpty) ...[
                Text(
                  _message,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: _hasError ? theme.colorScheme.error : null,
                  ),
                ),
                const SizedBox(height: 8),
              ],

              // 错误消息
              if (_hasError && _errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.errorContainer.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: theme.colorScheme.error.withOpacity(0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 16,
                            color: theme.colorScheme.error,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            l10n.error(''),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.error,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _errorMessage!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onErrorContainer,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
              ],

              // 附加数据显示
              if (_data != null && _data!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: _data!.entries.map((entry) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 1),
                        child: Text(
                          '${entry.key}: ${entry.value}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          // 取消按钮
          if (widget.canCancel && !_isCompleted && !_hasError)
            TextButton(
              onPressed: () {
                widget.onCancel?.call();
                Navigator.of(context).pop();
              },
              child: Text(l10n.cancel),
            ),

          // 重试按钮（错误时）
          if (_hasError)
            TextButton(
              onPressed: () {
                setState(() {
                  _hasError = false;
                  _errorMessage = null;
                  _progress = 0.0;
                  _message = widget.initialMessage ?? '';
                });
              },
              child: Text(l10n.retry),
            ),

          // 关闭按钮（完成或错误时）
          if (_isCompleted || _hasError)
            FilledButton(
              onPressed: () => Navigator.of(context).pop(_isCompleted),
              child: Text(_isCompleted ? l10n.done : l10n.close),
            ),
        ],
      ),
    );
  }
}

 