import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../l10n/app_localizations.dart';

/// 字帖标题编辑对话框
class PracticeTitleEditDialog extends StatefulWidget {
  /// 初始标题
  final String? initialTitle;

  /// 检查标题是否存在的回调
  final Future<bool> Function(String title)? checkTitleExists;

  const PracticeTitleEditDialog({
    super.key,
    this.initialTitle,
    this.checkTitleExists,
  });

  @override
  State<PracticeTitleEditDialog> createState() =>
      _PracticeTitleEditDialogState();
}

class _PracticeTitleEditDialogState extends State<PracticeTitleEditDialog> {
  late final TextEditingController _titleController;
  late final FocusNode _focusNode;
  String? _errorText;
  bool _isChecking = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return KeyboardListener(
      focusNode: FocusNode(),
      autofocus: true,
      onKeyEvent: (KeyEvent event) {
        if (event is KeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.enter) {
            _handleSave();
          } else if (event.logicalKey == LogicalKeyboardKey.escape) {
            Navigator.of(context).pop();
          }
        }
      },
      child: AlertDialog(
        title: Text(l10n.editTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _titleController,
              focusNode: _focusNode,
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
            onPressed: () => Navigator.of(context).pop(),
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
    _focusNode.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.initialTitle ?? '');
    _focusNode = FocusNode();

    // 确保在对话框显示后文本框获得焦点
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        _focusNode.requestFocus();
      }
    });
  }

  /// 处理保存操作
  Future<void> _handleSave() async {
    if (await _validateTitle()) {
      if (mounted) {
        Navigator.of(context).pop(_titleController.text.trim());
      }
    }
  }

  /// 验证标题
  Future<bool> _validateTitle() async {
    final l10n = AppLocalizations.of(context);
    final title = _titleController.text.trim();

    // 检查标题是否为空
    if (title.isEmpty) {
      setState(() {
        _errorText = l10n.titleCannotBeEmpty;
      });
      return false;
    }

    // 检查标题是否已存在
    if (widget.checkTitleExists != null) {
      setState(() {
        _isChecking = true;
        _errorText = null;
      });

      try {
        final exists = await widget.checkTitleExists!(title);

        // 如果标题已存在且非本身的标题，显示错误
        if (exists && title != widget.initialTitle) {
          setState(() {
            _errorText = l10n.titleAlreadyExists;
          });
          return false;
        }

        return true;
      } finally {
        setState(() {
          _isChecking = false;
        });
      }
    }

    return true;
  }
}
