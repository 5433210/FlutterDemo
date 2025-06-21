import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'lib/application/services/file_picker_service.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'File Picker Test',
      home: FilePickerTestPage(),
    );
  }
}

class FilePickerTestPage extends StatefulWidget {
  @override
  _FilePickerTestPageState createState() => _FilePickerTestPageState();
}

class _FilePickerTestPageState extends State<FilePickerTestPage> {
  String _selectedFile = '未选择文件';
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('文件选择器测试'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('选择的文件: $_selectedFile'),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _testDirectFilePicker,
              child: Text('测试直接使用FilePicker'),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: _testFilePickerService,
              child: Text('测试FilePickerService'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _testDirectFilePicker() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['zip', 'json'],
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        setState(() {
          _selectedFile = file.path ?? '路径为空';
        });
      } else {
        setState(() {
          _selectedFile = '用户取消选择';
        });
      }
    } catch (e) {
      setState(() {
        _selectedFile = '错误: $e';
      });
    }
  }

  Future<void> _testFilePickerService() async {
    try {
      final filePickerService = FilePickerServiceImpl();
      final selectedFile = await filePickerService.pickFile(
        dialogTitle: '选择导入文件',
        allowedExtensions: ['zip', 'json'],
      );

      if (selectedFile != null) {
        setState(() {
          _selectedFile = selectedFile;
        });
      } else {
        setState(() {
          _selectedFile = '用户取消选择';
        });
      }
    } catch (e) {
      setState(() {
        _selectedFile = '错误: $e';
      });
    }
  }
} 