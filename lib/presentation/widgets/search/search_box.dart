import 'package:flutter/material.dart';

/// 搜索框组件
class SearchBox extends StatelessWidget {
  /// 文本控制器
  final TextEditingController controller;

  /// 提示文本
  final String hintText;

  /// 提交回调
  final void Function(String) onSubmitted;

  /// 构造函数
  const SearchBox({
    super.key,
    required this.controller,
    required this.hintText,
    required this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: const Icon(Icons.search),
        suffixIcon: IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () {
            controller.clear();
            onSubmitted('');
          },
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      onSubmitted: onSubmitted,
    );
  }
}
