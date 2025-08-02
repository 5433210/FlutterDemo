#!/usr/bin/env dart

/// 图像裁剪日志过滤器
///
/// 这个脚本可以用来过滤和高亮显示与图像裁剪相关的日志输出

void main(List<String> args) {
  print('=== 图像裁剪日志过滤器 ===');
  print('');
  print('搜索关键词：');
  print('- "裁剪拖拽更新"');
  print('- "调用 onCropChanged"');
  print('- "图像属性面板 onCropChanged 回调"');
  print('- "updateCropValue"');
  print('- "handlePropertyChange"');
  print('- "didUpdateWidget"');
  print('- "检测到外部状态变化"');
  print('');
  print('使用方法：');
  print('flutter run | dart filter_crop_logs.dart');
  print('');
  print('或者直接运行应用并搜索上述关键词。');
}
