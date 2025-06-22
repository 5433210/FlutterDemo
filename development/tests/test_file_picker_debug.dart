import 'lib/application/services/file_picker_service.dart';

void main() async {
  print('=== 文件选择器测试 ===');
  
  try {
    final filePickerService = FilePickerServiceImpl();
    
    print('测试1: 选择单个文件');
    final selectedFile = await filePickerService.pickFile(
      dialogTitle: '选择导入文件',
      allowedExtensions: ['zip', 'json'],
    );
    
    if (selectedFile != null) {
      print('成功选择文件: $selectedFile');
    } else {
      print('用户取消选择或选择失败');
    }
    
    print('\n测试2: 选择保存文件');
    final saveFile = await filePickerService.pickSaveFile(
      dialogTitle: '选择保存位置',
      suggestedName: 'test_export.zip',
      allowedExtensions: ['zip'],
    );
    
    if (saveFile != null) {
      print('成功选择保存位置: $saveFile');
    } else {
      print('用户取消选择或选择失败');
    }
    
  } catch (e, stackTrace) {
    print('测试过程中发生错误: $e');
    print('堆栈跟踪: $stackTrace');
  }
  
  print('测试完成');
} 