import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../infrastructure/logging/logger.dart';
import '../../l10n/app_localizations.dart';
import '../utils/dialog_navigation_helper.dart';

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
        final title = _titleController.text.trim();

        AppLogger.info(
          'PracticeSaveDialog saving with title',
          tag: 'PracticeSaveDialog',
          data: {'title': title},
        );

        // 🔧 使用类型保护的安全导航助手，避免与其他对话框的类型混乱
        await DialogNavigationHelper.safePopWithTypeGuard<String>(
          context,
          result: title,
          dialogName: 'PracticeSaveDialog',
        );
      }
    }
  }

  /// 安全地取消对话框
  void _safeCancel() {
    DialogNavigationHelper.safeCancel(
      context,
      dialogName: 'PracticeSaveDialog',
    );
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
