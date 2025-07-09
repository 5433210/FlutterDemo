#!/usr/bin/env dart
// 图片顺序调整日志分析脚本

void main() async {
  print('=== 图片顺序调整日志分析 ===');
  await analyzeImageOrderLogs();
}

Future<void> analyzeImageOrderLogs() async {
  print('\n--- 分析图片顺序调整相关日志 ---');

  // 重要的日志关键字
  final keyLogMessages = [
    '开始重排序图片',
    '重排序完成',
    '开始保存图片更改',
    '收集所有应该保留的文件路径',
    '添加封面文件到保护列表',
    '路径标准化完成',
    '详细文件使用状态检查',
    '所有文件详细信息',
    '封面文件检查',
    '文件删除安全检查完成',
    '准备删除未使用文件',
    '已删除未使用文件',
    '跳过删除不安全的文件',
    '没有发现未使用的文件',
    '批量保存图片到数据库',
    '数据库保存验证',
    '图片保存完成',
  ];

  // 错误和警告关键字
  final warningMessages = [
    '发现未使用的文件',
    '封面文件丢失',
    '现有图片文件缺失',
    '无法找到有效的源图片文件',
    '删除未使用文件失败',
    '跳过删除不安全的文件',
  ];

  print('重要日志关键字检查清单:');
  for (final message in keyLogMessages) {
    print('  ✓ $message');
  }

  print('\n需要关注的警告信息:');
  for (final message in warningMessages) {
    print('  ⚠️  $message');
  }

  print('\n--- 调试建议 ---');
  print('1. 在调整图片顺序前，检查 "开始重排序图片" 日志');
  print('2. 确认 "收集所有应该保留的文件路径" 包含所有必要文件');
  print('3. 验证 "添加封面文件到保护列表" 成功执行');
  print('4. 检查 "路径标准化完成" 是否正确处理路径');
  print('5. 关注 "详细文件使用状态检查" 中的文件状态');
  print('6. 确认 "所有文件详细信息" 中封面文件的存在状态');
  print('7. 验证 "封面文件检查" 中的路径匹配结果');
  print('8. 检查是否有 "发现未使用的文件" 警告');
  print('9. 确认 "没有发现未使用的文件" 或安全删除完成');
  print('10. 最后确认 "图片保存完成" 和数据库验证成功');

  print('\n--- 问题排查步骤 ---');
  print('如果图片文件丢失，请按以下步骤排查:');
  print('1. 搜索日志中的 "发现未使用的文件，准备删除"');
  print('2. 检查被删除的文件列表，确认是否包含重要图片');
  print('3. 查看 "路径标准化完成" 日志，确认路径处理正确');
  print('4. 检查 "添加封面文件到保护列表" 是否成功');
  print('5. 验证 "usedPaths" 中是否包含所有必要的文件路径');
  print('6. 查看 "文件删除安全检查完成" 的结果');
  print('7. 确认 "跳过删除不安全的文件" 是否正确保护了重要文件');

  print('\n--- 日志过滤命令 ---');
  print('可以使用以下命令过滤相关日志:');
  print(
      '  grep -E "(WorkImageService|WorkImageEditor|WorkImageRepository)" app.log');
  print('  grep -E "(重排序|保存|删除|封面)" app.log');
  print('  grep -E "(usedPaths|unusedFiles|cleanupUnusedFiles)" app.log');

  print('\n--- 预期正常流程 ---');
  print('正常的图片顺序调整应该产生以下日志序列:');
  print('1. [INFO] 开始重排序图片');
  print('2. [INFO] 重排序完成 - 内存中的状态');
  print('3. [INFO] 开始保存图片更改');
  print('4. [INFO] 收集所有应该保留的文件路径');
  print('5. [INFO] 添加封面文件到保护列表');
  print('6. [INFO] 路径标准化完成');
  print('7. [INFO] 详细文件使用状态检查');
  print('8. [INFO] 所有文件详细信息');
  print('9. [INFO] 封面文件检查');
  print('10. [INFO] 没有发现未使用的文件 (或安全删除完成)');
  print('11. [INFO] 批量保存图片到数据库');
  print('12. [INFO] 数据库保存验证');
  print('13. [INFO] 图片保存完成');
}
