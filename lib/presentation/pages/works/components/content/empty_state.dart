import 'package:flutter/material.dart';

class WorkEmptyState extends StatelessWidget {
  final VoidCallback onImport;
  
  const WorkEmptyState({
    super.key,
    required this.onImport,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.image_outlined, size: 64),
          const SizedBox(height: 16),
          const Text('暂无作品'),
          const SizedBox(height: 24),
          FilledButton.icon(
            icon: const Icon(Icons.add),
            label: const Text('导入作品'),
            onPressed: onImport,
          ),
        ],
      ),
    );
  }
}
