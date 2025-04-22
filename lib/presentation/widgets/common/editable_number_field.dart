import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 可编辑数值字段
/// 显示为只读文本框加编辑按钮，点击编辑按钮弹出对话框输入新值
class EditableNumberField extends StatelessWidget {
  /// 字段标签
  final String label;
  
  /// 当前值
  final double value;
  
  /// 值变化回调
  final Function(double) onChanged;
  
  /// 单位后缀（可选）
  final String? suffix;
  
  /// 最小值（可选）
  final double? min;
  
  /// 最大值（可选）
  final double? max;
  
  /// 小数位数（默认为0，表示整数）
  final int decimalPlaces;
  
  /// 构造函数
  const EditableNumberField({
    Key? key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.suffix,
    this.min,
    this.max,
    this.decimalPlaces = 0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 格式化显示值
    final displayValue = decimalPlaces > 0
        ? value.toStringAsFixed(decimalPlaces)
        : value.toStringAsFixed(0);
    
    // 构建显示文本
    final displayText = suffix != null ? '$displayValue $suffix' : displayValue;
    
    return Row(
      children: [
        // 只读文本框
        Expanded(
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: label,
              border: const OutlineInputBorder(),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12.0,
                vertical: 8.0,
              ),
            ),
            child: Text(
              displayText,
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ),
        
        // 编辑按钮
        IconButton(
          icon: const Icon(Icons.edit),
          tooltip: '编辑$label',
          onPressed: () => _showEditDialog(context),
        ),
      ],
    );
  }

  /// 显示编辑对话框
  void _showEditDialog(BuildContext context) {
    // 创建文本控制器并设置初始值
    final controller = TextEditingController(
      text: decimalPlaces > 0
          ? value.toStringAsFixed(decimalPlaces)
          : value.toStringAsFixed(0),
    );
    
    // 创建焦点节点，用于自动聚焦
    final focusNode = FocusNode();
    
    // 在对话框关闭时释放资源
    void dispose() {
      controller.dispose();
      focusNode.dispose();
    }
    
    // 显示对话框
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('编辑$label'),
          content: TextField(
            controller: controller,
            focusNode: focusNode,
            keyboardType: TextInputType.numberWithOptions(
              decimal: decimalPlaces > 0,
              signed: min != null && min! < 0,
            ),
            inputFormatters: [
              // 根据小数位数决定使用哪种格式化器
              if (decimalPlaces > 0)
                FilteringTextInputFormatter.allow(RegExp(r'^\-?\d*\.?\d*')),
              if (decimalPlaces == 0)
                FilteringTextInputFormatter.digitsOnly,
            ],
            decoration: InputDecoration(
              labelText: label,
              hintText: '请输入$label',
              suffix: suffix != null ? Text(suffix!) : null,
            ),
            autofocus: true,
            onSubmitted: (_) => _applyValue(context, controller.text, dispose),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('取消'),
              onPressed: () {
                dispose();
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('确定'),
              onPressed: () => _applyValue(context, controller.text, dispose),
            ),
          ],
        );
      },
    );
    
    // 对话框显示后自动聚焦
    Future.delayed(const Duration(milliseconds: 100), () {
      if (focusNode.canRequestFocus) {
        focusNode.requestFocus();
      }
    });
  }

  /// 应用新值
  void _applyValue(BuildContext context, String text, Function dispose) {
    // 尝试解析值
    final newValue = double.tryParse(text);
    
    // 验证值
    if (newValue == null) {
      _showErrorSnackBar(context, '请输入有效的数字');
      return;
    }
    
    // 检查最小值
    if (min != null && newValue < min!) {
      _showErrorSnackBar(context, '$label不能小于${min!}');
      return;
    }
    
    // 检查最大值
    if (max != null && newValue > max!) {
      _showErrorSnackBar(context, '$label不能大于${max!}');
      return;
    }
    
    // 应用新值
    dispose();
    Navigator.of(context).pop();
    onChanged(newValue);
  }

  /// 显示错误提示
  void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
