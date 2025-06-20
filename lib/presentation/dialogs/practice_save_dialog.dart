import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import '../../infrastructure/logging/logger.dart';
import '../../l10n/app_localizations.dart';

/// 字帖保存对话框
/// 用于输入字帖标题
class PracticeSaveDialog extends StatefulWidget {
  /// 初始标题
  final String? initialTitle;

  /// 是否为另存为操作
  final bool isSaveAs;

  /// 检查标题是否存在的回调
  final Future<bool> Function(String title)? checkTitleExists;

  const PracticeSaveDialog({
    super.key,
    this.initialTitle,
    this.isSaveAs = false,
    this.checkTitleExists,
  });

  @override
  State<PracticeSaveDialog> createState() => _PracticeSaveDialogState();
}

class _PracticeSaveDialogState extends State<PracticeSaveDialog> {
  late final TextEditingController _titleController;
  String? _errorText;
  bool _isChecking = false;
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final title = widget.isSaveAs ? l10n.saveAs : l10n.save;

    return KeyboardListener(
      focusNode: FocusNode(),
      autofocus: true,
      onKeyEvent: (KeyEvent event) {
        if (event is KeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.enter) {
            _handleSave();
          } else if (event.logicalKey == LogicalKeyboardKey.escape) {
            _safeCancel();
          }
        }
      },
      child: AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: l10n.title,
                hintText: l10n.inputTitle,
                errorText: _errorText,
                border: const OutlineInputBorder(),
              ),
              autofocus: true,
              onChanged: (_) {
                // 清除错误提示
                if (_errorText != null) {
                  setState(() {
                    _errorText = null;
                  });
                }
              },
              onSubmitted: (_) => _handleSave(),
            ),
            if (_isChecking)
              const Padding(
                padding: EdgeInsets.only(top: 8.0),
                child: LinearProgressIndicator(),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: _safeCancel,
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: _handleSave,
            child: Text(l10n.save),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.initialTitle ?? '');
  }

  /// 处理保存操作
  Future<void> _handleSave() async {
    if (await _validateTitle()) {
      if (mounted) {
        // 返回标题字符串，确保使用正确的Navigator和类型
        final title = _titleController.text.trim();

        // 记录导航信息以帮助调试
        AppLogger.info(
          'PracticeSaveDialog attempting to pop with result',
          tag: 'PracticeSaveDialog',
          data: {
            'title': title,
            'resultType': 'String',
            'canPop': Navigator.of(context).canPop(),
            'currentRoute': ModalRoute.of(context)?.settings.name ?? 'unknown',
          },
        );

        // 使用更安全的导航方法
        _safeNavigatePop(title);
      }
    }
  }

  /// 安全地取消对话框
  void _safeCancel() {
    if (!mounted) return;

    final navigator = Navigator.of(context);
    if (!navigator.canPop()) return;

    try {
      navigator.pop();
    } catch (e) {
      AppLogger.warning(
        'PracticeSaveDialog cancel navigation failed, trying deferred approach',
        tag: 'PracticeSaveDialog',
        data: {'error': e.toString()},
      );

      // 使用延迟方法
      SchedulerBinding.instance.addPostFrameCallback((_) {
        Future.microtask(() {
          if (mounted) {
            try {
              Navigator.of(context).pop();
            } catch (e2) {
              AppLogger.error(
                'PracticeSaveDialog cancel deferred navigation failed',
                tag: 'PracticeSaveDialog',
                data: {'error': e2.toString()},
              );
            }
          }
        });
      });
    }
  }

  /// 安全地执行导航弹出操作
  void _safeNavigatePop(String title) {
    // 检查是否可以安全地导航
    if (!mounted) {
      AppLogger.warning(
        'PracticeSaveDialog widget not mounted, cannot navigate',
        tag: 'PracticeSaveDialog',
      );
      return;
    }

    final navigator = Navigator.of(context);
    if (!navigator.canPop()) {
      AppLogger.warning(
        'PracticeSaveDialog navigator cannot pop',
        tag: 'PracticeSaveDialog',
      );
      return;
    }

    // 使用多层防护确保安全导航
    try {
      // 首先尝试立即导航
      navigator.pop<String>(title);
      AppLogger.info(
        'PracticeSaveDialog navigation successful',
        tag: 'PracticeSaveDialog',
        data: {'title': title},
      );
    } catch (e) {
      AppLogger.warning(
        'PracticeSaveDialog immediate navigation failed, trying deferred approach',
        tag: 'PracticeSaveDialog',
        data: {'error': e.toString()},
      );

      // 如果立即导航失败，使用延迟方法
      SchedulerBinding.instance.addPostFrameCallback((_) {
        _attemptDeferredNavigation(title);
      });
    }
  }

  /// 尝试延迟导航
  void _attemptDeferredNavigation(String title) {
    if (!mounted) return;

    Future.microtask(() async {
      if (!mounted) return;

      // 等待一个更长的时间确保所有状态更新完成
      await Future.delayed(const Duration(milliseconds: 50));

      if (!mounted) return;

      try {
        final navigator = Navigator.of(context);
        if (navigator.canPop()) {
          navigator.pop<String>(title);
          AppLogger.info(
            'PracticeSaveDialog deferred navigation successful',
            tag: 'PracticeSaveDialog',
            data: {'title': title},
          );
        } else {
          AppLogger.error(
            'PracticeSaveDialog cannot pop after deferred attempt',
            tag: 'PracticeSaveDialog',
          );
        }
      } catch (e) {
        AppLogger.error(
          'PracticeSaveDialog deferred navigation failed',
          tag: 'PracticeSaveDialog',
          data: {'error': e.toString()},
        );

        // 最后的备用方案：尝试使用根导航器
        _attemptRootNavigation(title);
      }
    });
  }

  /// 尝试使用根导航器
  void _attemptRootNavigation(String title) {
    if (!mounted) return;

    try {
      Navigator.of(context, rootNavigator: true).pop<String>(title);
      AppLogger.info(
        'PracticeSaveDialog root navigation successful',
        tag: 'PracticeSaveDialog',
        data: {'title': title},
      );
    } catch (e) {
      AppLogger.error(
        'PracticeSaveDialog all navigation attempts failed',
        tag: 'PracticeSaveDialog',
        data: {'error': e.toString()},
      );
    }
  }

  /// 验证标题
  Future<bool> _validateTitle() async {
    final l10n = AppLocalizations.of(context);
    final title = _titleController.text.trim();

    // 检查标题是否为空
    if (title.isEmpty) {
      if (mounted) {
        setState(() {
          _errorText = l10n.inputTitle;
        });
      }
      return false;
    }

    // 检查标题是否已存在
    if (widget.checkTitleExists != null) {
      if (mounted) {
        setState(() {
          _isChecking = true;
          _errorText = null;
        });
      }

      try {
        final exists = await widget.checkTitleExists!(title);

        // 如果是另存为操作，标题已存在且非本身的标题，显示错误
        if (exists && (widget.isSaveAs || title != widget.initialTitle)) {
          if (mounted) {
            setState(() {
              _errorText = l10n.titleExistsMessage;
              _isChecking = false;
            });
          }
          return false;
        }

        // 确保在成功验证后清除检查状态
        if (mounted) {
          setState(() {
            _isChecking = false;
            _errorText = null;
          });
        }

        return true;
      } catch (e) {
        // 处理验证过程中的错误
        AppLogger.error(
          'PracticeSaveDialog title validation error',
          tag: 'PracticeSaveDialog',
          data: {'error': e.toString(), 'title': title},
        );

        if (mounted) {
          setState(() {
            _isChecking = false;
            _errorText = l10n.titleExistsMessage; // 使用通用错误消息
          });
        }
        return false;
      }
    }

    return true;
  }
}
