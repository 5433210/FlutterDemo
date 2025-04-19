import 'dart:async';
import 'package:flutter/material.dart';

/// 优化的文本输入框，具有防抖动功能，保持光标位置，并实时更新
class OptimizedTextField extends StatefulWidget {
  /// 输入框的装饰
  final InputDecoration decoration;
  
  /// 初始文本值
  final String initialValue;
  
  /// 文本变化回调
  final Function(String) onChanged;
  
  /// 是否是数字输入
  final bool isNumeric;
  
  /// 防抖动延迟（毫秒）
  final int debounceMilliseconds;
  
  /// 最大行数
  final int? maxLines;
  
  /// 最小行数
  final int? minLines;
  
  /// 键盘类型
  final TextInputType? keyboardType;
  
  /// 文本对齐方式
  final TextAlign textAlign;
  
  /// 后缀文本
  final String? suffixText;

  const OptimizedTextField({
    Key? key,
    required this.initialValue,
    required this.onChanged,
    this.decoration = const InputDecoration(),
    this.isNumeric = false,
    this.debounceMilliseconds = 300,
    this.maxLines = 1,
    this.minLines,
    this.keyboardType,
    this.textAlign = TextAlign.start,
    this.suffixText,
  }) : super(key: key);

  @override
  State<OptimizedTextField> createState() => _OptimizedTextFieldState();
}

class _OptimizedTextFieldState extends State<OptimizedTextField> {
  late TextEditingController _controller;
  Timer? _debounceTimer;
  String _lastAppliedValue = '';
  
  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
    _lastAppliedValue = widget.initialValue;
  }
  
  @override
  void didUpdateWidget(OptimizedTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // 只有当外部值变化且与当前值不同时才更新控制器
    if (widget.initialValue != oldWidget.initialValue && 
        widget.initialValue != _controller.text) {
      final selection = _controller.selection;
      _controller.text = widget.initialValue;
      _lastAppliedValue = widget.initialValue;
      
      // 尝试保持光标位置
      if (selection.start <= widget.initialValue.length && 
          selection.end <= widget.initialValue.length) {
        _controller.selection = selection;
      }
    }
  }
  
  @override
  void dispose() {
    _debounceTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onTextChanged(String value) {
    // 如果是数字输入，验证输入是否为有效数字
    if (widget.isNumeric) {
      final numValue = double.tryParse(value);
      if (numValue == null && value.isNotEmpty) {
        return; // 无效数字输入，不处理
      }
    }
    
    // 取消之前的定时器
    _debounceTimer?.cancel();
    
    // 设置新的定时器
    _debounceTimer = Timer(Duration(milliseconds: widget.debounceMilliseconds), () {
      // 只有当值真正变化时才调用回调
      if (value != _lastAppliedValue) {
        widget.onChanged(value);
        _lastAppliedValue = value;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      decoration: widget.decoration.copyWith(
        suffixText: widget.suffixText,
      ),
      maxLines: widget.maxLines,
      minLines: widget.minLines,
      keyboardType: widget.keyboardType ?? (widget.isNumeric ? TextInputType.number : TextInputType.text),
      textAlign: widget.textAlign,
      onChanged: _onTextChanged,
    );
  }
}
