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
  void updateProgress(double progress, String message,
      [Map<String, dynamic>? data]) {
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
    final theme = Theme.of(context);

    return PopScope(
      canPop: widget.canCancel && !_isCompleted && !_hasError,
      child: AlertDialog(
        title: Row(
          children: [
            if (_hasError)
              Icon(Icons.error, color: theme.colorScheme.error)
            else if (_isCompleted)
              const Icon(Icons.check_circle, color: Colors.green)
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
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
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
                            AppLocalizations.of(context).error(''),
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
                    color: theme.colorScheme.surfaceContainerHighest
                        .withOpacity(0.3),
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
              child: Text(AppLocalizations.of(context).cancel),
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
              child: Text(AppLocalizations.of(context).retry),
            ),

          // 关闭按钮（完成或错误时）
          if (_isCompleted || _hasError)
            FilledButton(
              onPressed: () => Navigator.of(context).pop(_isCompleted),
              child: Text(_isCompleted
                  ? AppLocalizations.of(context).done
                  : AppLocalizations.of(context).close),
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
  void updateProgress(double progress, String message,
      [Map<String, dynamic>? data]) {
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

  /// 显示导入结果
  void showImportResult(dynamic importResult, String filePath) {
    if (!_isDisposed && _state != null) {
      _state!.showImportResult(importResult, filePath);
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
  State<ControlledProgressDialog> createState() =>
      _ControlledProgressDialogState();

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

  // 导入结果相关状态
  bool _showingResult = false;
  dynamic _importResult;
  String? _importFilePath;

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
  void updateProgress(double progress, String message,
      [Map<String, dynamic>? data]) {
    if (mounted) {
      setState(() {
        _progress = progress.clamp(0.0, 1.0);
        _message = message;
        _data = data;
        _isCompleted = progress >= 1.0;
        _hasError = false;
        _errorMessage = null;
        _showingResult = false; // 重置结果显示状态
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
        _showingResult = false;
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
        _showingResult = false;
      });
    }
  }

  /// 显示导入结果
  void showImportResult(dynamic importResult, String filePath) {
    if (mounted) {
      setState(() {
        _progress = 1.0;
        _isCompleted = true;
        _hasError = false;
        _showingResult = true;
        _importResult = importResult;
        _importFilePath = filePath;
        _message = '导入完成';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PopScope(
      canPop: widget.canCancel && !_isCompleted && !_hasError,
      child: AlertDialog(
        title: Row(
          children: [
            if (_hasError)
              Icon(Icons.error, color: theme.colorScheme.error)
            else if (_isCompleted)
              const Icon(Icons.check_circle, color: Colors.green)
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
          width: _showingResult ? 400 : 300,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 进度条
              if (!_hasError) ...[
                LinearProgressIndicator(
                  value: _progress,
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
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
                            AppLocalizations.of(context).error(''),
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

              // 导入结果显示
              if (_showingResult && _importResult != null) ...[
                const SizedBox(height: 16),
                _buildImportResultSection(context, theme),
              ]
              // 附加数据显示
              else if (_data != null && _data!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest
                        .withOpacity(0.3),
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
              child: Text(AppLocalizations.of(context).cancel),
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
              child: Text(AppLocalizations.of(context).retry),
            ),

          // 关闭按钮（完成或错误时）
          if (_isCompleted || _hasError)
            FilledButton(
              onPressed: () => Navigator.of(context).pop(_isCompleted),
              child: Text(_isCompleted
                  ? AppLocalizations.of(context).done
                  : AppLocalizations.of(context).close),
            ),
        ],
      ),
    );
  }

  /// 构建导入结果显示区域
  Widget _buildImportResultSection(BuildContext context, ThemeData theme) {
    final l10n = AppLocalizations.of(context);
    final result = _importResult;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.green.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题
          Row(
            children: [
              const Icon(
                Icons.check_circle_outline,
                color: Colors.green,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                l10n.importResultTitle,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: Colors.green[700],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 统计信息
          _buildResultStatistics(context, theme, result),

          // 冲突处理明细
          if (result.details != null &&
              result.details['conflictDetails'] != null) ...[
            const SizedBox(height: 12),
            _buildConflictDetails(
                context, theme, result.details['conflictDetails']),
          ],

          // 文件信息
          if (_importFilePath != null) ...[
            const SizedBox(height: 12),
            _buildFileInfo(context, theme),
          ],

          // 错误和警告
          if (result.errors.isNotEmpty || result.warnings.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildErrorsAndWarnings(context, theme, result),
          ],
        ],
      ),
    );
  }

  /// 构建统计信息
  Widget _buildResultStatistics(
      BuildContext context, ThemeData theme, dynamic result) {
    final l10n = AppLocalizations.of(context);

    return Column(
      children: [
        _buildStatRow(
            l10n.importedWorks, result.importedWorks, Icons.article, theme),
        _buildStatRow(l10n.importedCharacters, result.importedCharacters,
            Icons.text_fields, theme),
        _buildStatRow(
            l10n.importedImages, result.importedImages, Icons.image, theme),
        if (result.skippedItems > 0)
          _buildStatRow(
              l10n.skippedItems, result.skippedItems, Icons.skip_next, theme,
              isWarning: true),
      ],
    );
  }

  /// 构建统计行
  Widget _buildStatRow(String label, int count, IconData icon, ThemeData theme,
      {bool isWarning = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: isWarning ? Colors.orange : Colors.green,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodyMedium,
            ),
          ),
          Text(
            count.toString(),
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: isWarning ? Colors.orange[700] : Colors.green[700],
            ),
          ),
        ],
      ),
    );
  }

  /// 构建文件信息
  Widget _buildFileInfo(BuildContext context, ThemeData theme) {
    final l10n = AppLocalizations.of(context);
    final fileName = _importFilePath!.split('\\').last.split('/').last;

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          Icon(
            Icons.folder_zip,
            size: 16,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.importedFile,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  fileName,
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 构建错误和警告信息
  Widget _buildErrorsAndWarnings(
      BuildContext context, ThemeData theme, dynamic result) {
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (result.warnings.isNotEmpty) ...[
          Row(
            children: [
              const Icon(
                Icons.warning_amber,
                size: 16,
                color: Colors.orange,
              ),
              const SizedBox(width: 8),
              Text(
                '${l10n.warnings} (${result.warnings.length})',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.orange[700],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ...result.warnings.map<Widget>((warning) => Padding(
                padding: const EdgeInsets.only(left: 24, bottom: 2),
                child: Text(
                  '• $warning',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.orange[600],
                  ),
                ),
              )),
        ],
        if (result.errors.isNotEmpty) ...[
          if (result.warnings.isNotEmpty) const SizedBox(height: 8),
          Row(
            children: [
              const Icon(
                Icons.error_outline,
                size: 16,
                color: Colors.red,
              ),
              const SizedBox(width: 8),
              Text(
                '${l10n.errors} (${result.errors.length})',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.red[700],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ...result.errors.map<Widget>((error) => Padding(
                padding: const EdgeInsets.only(left: 24, bottom: 2),
                child: Text(
                  '• $error',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.red[600],
                  ),
                ),
              )),
        ],
      ],
    );
  }

  /// 构建冲突处理明细
  Widget _buildConflictDetails(BuildContext context, ThemeData theme,
      Map<String, dynamic> conflictDetails) {
    final l10n = AppLocalizations.of(context);

    final skippedWorks =
        conflictDetails['skippedWorks'] as List<Map<String, dynamic>>? ?? [];
    final overwrittenWorks =
        conflictDetails['overwrittenWorks'] as List<Map<String, dynamic>>? ??
            [];
    final skippedCharacters =
        conflictDetails['skippedCharacters'] as List<Map<String, dynamic>>? ??
            [];
    final overwrittenCharacters = conflictDetails['overwrittenCharacters']
            as List<Map<String, dynamic>>? ??
        [];

    // 如果没有任何冲突处理，则不显示
    if (skippedWorks.isEmpty &&
        overwrittenWorks.isEmpty &&
        skippedCharacters.isEmpty &&
        overwrittenCharacters.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.orange.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题
          Row(
            children: [
              const Icon(
                Icons.info_outline,
                color: Colors.orange,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                l10n.conflictDetailsTitle,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: Colors.orange[700],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // 跳过的作品
          if (skippedWorks.isNotEmpty) ...[
            _buildConflictSection(
              l10n.skippedWorks,
              skippedWorks,
              theme,
              Icons.skip_next,
              Colors.orange,
              isWork: true,
            ),
            const SizedBox(height: 8),
          ],

          // 覆盖的作品
          if (overwrittenWorks.isNotEmpty) ...[
            _buildConflictSection(
              l10n.overwrittenWorks,
              overwrittenWorks,
              theme,
              Icons.refresh,
              Colors.blue,
              isWork: true,
            ),
            const SizedBox(height: 8),
          ],

          // 跳过的集字
          if (skippedCharacters.isNotEmpty) ...[
            _buildConflictSection(
              l10n.skippedCharacters,
              skippedCharacters,
              theme,
              Icons.skip_next,
              Colors.orange,
              isWork: false,
            ),
            const SizedBox(height: 8),
          ],

          // 覆盖的集字
          if (overwrittenCharacters.isNotEmpty) ...[
            _buildConflictSection(
              l10n.overwrittenCharacters,
              overwrittenCharacters,
              theme,
              Icons.refresh,
              Colors.blue,
              isWork: false,
            ),
          ],
        ],
      ),
    );
  }

  /// 构建冲突处理区域
  Widget _buildConflictSection(String title, List<Map<String, dynamic>> items,
      ThemeData theme, IconData icon, Color color,
      {required bool isWork}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 区域标题
        Row(
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 6),
            Text(
              '$title (${items.length})',
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),

        // 项目列表
        ...items.map((item) => Padding(
              padding: const EdgeInsets.only(left: 20, bottom: 2),
              child: Text(
                isWork
                    ? '• ${item['title']} (${item['author']})'
                    : '• ${item['character']} (${item['workTitle']})',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            )),
      ],
    );
  }
}
