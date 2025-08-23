import 'dart:async';

import 'package:flutter/material.dart';

import '../../../application/services/backup_progress_manager.dart';

/// 备份进度对话框 - 增强版
class BackupProgressDialog extends StatefulWidget {
  final String title;
  final String? message;
  final VoidCallback? onCancel;
  final Future<void>? backupFuture; // 添加备份Future来监听完成状态

  const BackupProgressDialog({
    super.key,
    this.title = '创建备份',
    this.message,
    this.onCancel,
    this.backupFuture,
  });

  @override
  State<BackupProgressDialog> createState() => _BackupProgressDialogState();
}

class _BackupProgressDialogState extends State<BackupProgressDialog> {
  late Timer _timer;
  Timer? _statusUpdateTimer; // 分离状态更新定时器
  Duration _elapsed = Duration.zero;
  String _currentStep = '准备备份...';
  String _currentDetail = '';
  int _processedFiles = 0;
  int _totalFiles = 0;
  bool _isHanging = false;

  // 添加进度管理器订阅
  StreamSubscription<BackupProgressState>? _progressSubscription;
  StreamSubscription<String>? _stepSubscription;
  bool _hasRealProgress = false; // 标记是否收到了真实进度

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _elapsed = Duration(seconds: _elapsed.inSeconds + 1);

        // 检测是否可能卡住
        if (_elapsed.inSeconds > 120 && _currentStep == _currentStep) {
          _isHanging = true;
        }
      });
    });

    // 连接到真实的备份进度管理器
    _connectToRealProgress();
  }

  void _connectToRealProgress() {
    final progressManager = BackupProgressManager();

    // 监听进度更新
    _progressSubscription = progressManager.progressStream.listen((state) {
      if (!mounted) return;

      _hasRealProgress = true; // 收到真实进度，停止模拟

      setState(() {
        if (state.status == BackupStatus.completed) {
          // 备份完成，关闭对话框
          _closeDialog();
        } else if (state.status == BackupStatus.failed) {
          // 备份失败，也关闭对话框
          _closeDialog();
        } else if (state.progress != null) {
          // 更新进度
          final progress = state.progress!;
          _totalFiles = 1000; // 假设总文件数
          _processedFiles = (progress * _totalFiles).round();
        }
      });
    });

    // 监听步骤更新
    _stepSubscription = progressManager.stepStream.listen((step) {
      if (!mounted) return;

      _hasRealProgress = true; // 收到真实进度，停止模拟

      setState(() {
        final parts = step.split('\n');
        _currentStep = parts.isNotEmpty ? parts[0] : step;
        _currentDetail = parts.length > 1 ? parts[1] : '';
      });
    });

    // 保留备用的模拟更新（如果真实进度不可用）
    _listenToBackupUpdates();
  }

  void _closeDialog() {
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  void _listenToBackupUpdates() {
    // 只在没有真实进度时使用模拟更新
    _statusUpdateTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (!mounted || _hasRealProgress) {
        timer.cancel();
        return;
      }

      setState(() {
        if (_elapsed.inSeconds < 10) {
          _currentStep = '分析数据目录...';
          _currentDetail = '正在扫描文件和目录';
        } else if (_elapsed.inSeconds < 30) {
          _currentStep = '备份数据库...';
          _currentDetail = '正在复制数据库文件';
        } else if (_elapsed.inSeconds < 90) {
          _currentStep = '备份应用数据...';
          _currentDetail = '正在复制用户文件 ($_processedFiles/$_totalFiles)';
          _processedFiles = (_elapsed.inSeconds - 30) * 10;
          _totalFiles = 800;
        } else {
          _currentStep = '创建备份文件...';
          _currentDetail = '正在压缩数据';
        }
      });
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _statusUpdateTimer?.cancel();
    _progressSubscription?.cancel();
    _stepSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: Row(
        children: [
          const CircularProgressIndicator(
            strokeWidth: 2,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.title),
                Text(
                  '已用时: ${_formatDuration(_elapsed)}',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 优化：简化信息显示，优先显示当前步骤，避免冗余信息
          Text(
            _currentStep.isNotEmpty ? _currentStep : (
              widget.message ?? '正在处理...'
            ),
            style: theme.textTheme.titleSmall,
          ),
          // 仅在当前步骤与详细信息不同时显示详细信息
          if (_currentDetail.isNotEmpty && _currentDetail != _currentStep) ...[
            const SizedBox(height: 8),
            Text(
              _currentDetail,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          // 优化進度显示：简化進度文本
          if (_processedFiles > 0 && _totalFiles > 0) ...[
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: _processedFiles / _totalFiles,
            ),
            const SizedBox(height: 4),
            Text(
              '${(_processedFiles / _totalFiles * 100).toStringAsFixed(1)}% ($_processedFiles/$_totalFiles)',
              style: theme.textTheme.bodySmall,
            ),
          ],
          if (_isHanging) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning,
                    color: theme.colorScheme.onErrorContainer,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '备份过程似乎卡住了。这可能是由于大文件或网络问题导致的。',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onErrorContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
      actions: [
        if (widget.onCancel != null)
          TextButton(
            onPressed: () {
              widget.onCancel?.call();
              Navigator.of(context).pop();
            },
            child: const Text('取消'),
          ),
        if (_isHanging)
          TextButton(
            onPressed: () {
              // 强制退出
              Navigator.of(context).pop();
            },
            style: TextButton.styleFrom(
              foregroundColor: theme.colorScheme.error,
            ),
            child: const Text('强制退出'),
          ),
      ],
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}
