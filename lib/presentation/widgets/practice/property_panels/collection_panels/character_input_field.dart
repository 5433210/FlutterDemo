import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

/// 集字内容文本输入字段组件
class CharacterInputField extends StatefulWidget {
  final String initialText;
  final int selectedCharIndex;
  final Function(String) onTextChanged;
  final Function(int) onSelectedCharIndexChanged;

  const CharacterInputField({
    Key? key,
    required this.initialText,
    required this.selectedCharIndex,
    required this.onTextChanged,
    required this.onSelectedCharIndexChanged,
  }) : super(key: key);

  @override
  State<CharacterInputField> createState() => _CharacterInputFieldState();
}

class _CharacterInputFieldState extends State<CharacterInputField> {
  late TextEditingController _textController;
  Timer? _debounceTimer;
  String _lastInputText = '';

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _textController,
      decoration: const InputDecoration(
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      ),
      keyboardType: TextInputType.multiline,
      maxLines: 5,
      minLines: 3,
      onChanged: (value) {
        // 获取当前内容和新内容
        final oldCharacters = _lastInputText;

        // 立即更新字符内容，确保UI响应
        widget.onTextChanged(value);

        // 记录最后一次输入的文本
        _lastInputText = value;

        // 如果是新增字符，则选中新增的字符
        if (value.length > oldCharacters.length && oldCharacters.isNotEmpty) {
          // 找出新增的字符位置
          int newCharIndex = -1;

          // 如果是在末尾添加字符
          if (value.startsWith(oldCharacters)) {
            newCharIndex = oldCharacters.length;
          }
          // 如果是在中间或开头添加字符，尝试找出新增的位置
          else {
            // 这里使用一个简单的算法来尝试找出新增的字符位置
            for (int i = 0; i < value.length; i++) {
              if (i >= oldCharacters.length || value[i] != oldCharacters[i]) {
                newCharIndex = i;
                break;
              }
            }
          }

          // 如果找到了新增的字符位置，则选中它
          if (newCharIndex >= 0 && newCharIndex < value.length) {
            widget.onSelectedCharIndexChanged(newCharIndex);
          } else {
            // 如果无法确定新增的字符位置，则选中最后一个字符
            widget.onSelectedCharIndexChanged(value.length - 1);
          }
        }
        // 如果是删除字符或清空内容，则选中第一个字符（如果有的话）
        else if (value.length < oldCharacters.length) {
          widget.onSelectedCharIndexChanged(value.isEmpty
              ? 0
              : math.min(widget.selectedCharIndex, value.length - 1));
        }
        // 如果是第一次输入字符，则选中第一个字符
        else if (oldCharacters.isEmpty && value.isNotEmpty) {
          widget.onSelectedCharIndexChanged(0);
        }

        // 使用防抖处理，延迟处理输入
        if (_debounceTimer?.isActive ?? false) {
          _debounceTimer!.cancel();
        }

        // 延迟300毫秒处理输入
        _debounceTimer = Timer(const Duration(milliseconds: 300), () {
          // 使用最后一次输入的文本
          final textToProcess = _lastInputText;

          // 更新文本，这可能会触发候选集字加载等操作
          widget.onTextChanged(textToProcess);
        });
      },
    );
  }

  @override
  void didUpdateWidget(CharacterInputField oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 只在文本实际变化时更新控制器，避免光标位置重置
    if (_textController.text != widget.initialText) {
      _textController.text = widget.initialText;
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    if (_debounceTimer?.isActive ?? false) {
      _debounceTimer!.cancel();
    }
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.initialText);
    _lastInputText = widget.initialText;
  }
}
