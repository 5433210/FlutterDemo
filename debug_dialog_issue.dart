import 'package:flutter/material.dart';
import 'lib/presentation/dialogs/practice_save_dialog.dart';

void main() {
  runApp(const DebugApp());
}

class DebugApp extends StatelessWidget {
  const DebugApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Debug Dialog Issue',
      home: DebugPage(),
    );
  }
}

class DebugPage extends StatelessWidget {
  const DebugPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Debug Dialog Issue')),
      body: Center(
        child: ElevatedButton(
          onPressed: () async {
            try {
              print('About to show PracticeSaveDialog...');
              final result = await showDialog<String>(
                context: context,
                builder: (context) => PracticeSaveDialog(
                  initialTitle: 'Test Practice',
                  isSaveAs: true,
                  checkTitleExists: (title) async {
                    print('Checking title: $title');
                    return false; // No conflict for testing
                  },
                ),
              );
              print('Dialog result: $result');
              print('Result type: ${result.runtimeType}');
            } catch (e, stackTrace) {
              print('Error occurred: $e');
              print('Stack trace: $stackTrace');
            }
          },
          child: const Text('Test PracticeSaveDialog'),
        ),
      ),
    );
  }
}
