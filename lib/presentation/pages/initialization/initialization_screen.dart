import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/providers/initialization_providers.dart';

class InitializationScreen extends ConsumerWidget {
  const InitializationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final initState = ref.watch(appInitializationProvider);

    return Scaffold(
      body: Center(
        child: initState.when(
          data: (_) => const Text('初始化完成'),
          loading: () => const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('正在初始化...'),
              Text(
                '加载中...',
                style: TextStyle(color: Colors.red),
              ),
            ],
          ),
          error: (error, stack) => Text(
            '初始化失败: $error',
            style: const TextStyle(color: Colors.red),
          ),
        ),
      ),
    );
  }
}
