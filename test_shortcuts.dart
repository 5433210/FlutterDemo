// 快捷键测试脚本
// 这个文件用于测试快捷键是否正常工作

void main() async {
  print('=== 快捷键测试指南 ===');
  print('请按照以下步骤测试快捷键功能：');
  print('');
  print('1. 运行 Flutter 应用');
  print('2. 导航到作品浏览页面');
  print('3. 测试以下快捷键：');
  print('   - Ctrl+N: 新增作品（应该打开新增作品对话框）');
  print('   - Ctrl+I: 导入作品（应该打开导入对话框）');
  print('   - Ctrl+Shift+A: 全选作品（批量模式下选中所有作品）');
  print('   - Ctrl+D: 删除选中作品（需要先选中作品）');
  print('   - Ctrl+E: 导出选中作品（需要先选中作品）');
  print('   - Ctrl+Shift+N: 取消选择（清除所有选中的作品）');
  print('');
  print('4. 观察控制台输出，查看是否有快捷键触发的日志');
  print('');
  print('测试提示：');
  print('- 如果快捷键没有响应，请检查：');
  print('  * 页面是否获得了焦点');
  print('  * 是否有其他组件拦截了快捷键');
  print('  * 控制台是否有相关错误信息');
  print('');
  print('- 在 Linux/WSL 环境下：');
  print('  * 确保 X11 转发正常工作');
  print('  * 检查桌面环境是否拦截了快捷键');
  print('');
  print('如果仍有问题，请检查以下文件：');
  print('- lib/presentation/pages/works/m3_work_browse_page.dart');
  print('- 快捷键定义和 Actions 配置');
  print('');
}
