import 'package:flutter/material.dart';
import '../../../dialogs/work_import/work_import_dialog.dart';

class ImportButton extends StatelessWidget {
  final VoidCallback onPressed;

  const ImportButton({
    super.key, 
    required this.onPressed,
  });

  @override 
  Widget build(BuildContext context) {
    return FilledButton.icon(
      icon: const Icon(Icons.add),
      label: const Text('导入作品'),
      onPressed: onPressed,
    );
  }
}
