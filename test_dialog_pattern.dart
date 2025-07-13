import 'dart:async';

/// 测试对话框问题的简单脚本
void main() {
  print('=== 备份对话框问题诊断 ===');

  // 模拟异步操作
  testDialogPattern();
}

Future<void> testDialogPattern() async {
  print('开始测试对话框模式...');

  // 模拟当前的问题模式
  bool dialogShown = false;

  try {
    print('显示进度对话框...');
    // 这里模拟 showDialog
    dialogShown = true;

    print('执行异步操作...');
    await simulateAsyncOperation();

    print('操作完成，尝试关闭对话框...');
    if (dialogShown) {
      print('✅ 对话框应该被关闭');
      dialogShown = false;
    }
  } catch (e) {
    print('❌ 操作失败: $e');
    if (dialogShown) {
      print('✅ 错误处理：对话框应该被关闭');
      dialogShown = false;
    }
  }

  print('测试完成');
}

Future<void> simulateAsyncOperation() async {
  // 模拟文件操作
  await Future.delayed(const Duration(milliseconds: 100));
  print('模拟操作完成');
}
