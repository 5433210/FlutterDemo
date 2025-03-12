import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/providers/initialization_providers.dart';
import '../../../infrastructure/providers/database_providers.dart';

class InitializationScreen extends ConsumerWidget {
  const InitializationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dbState = ref.watch(databaseStateProvider);
    final initState = ref.watch(appInitializationProvider);

    return Scaffold(
      body: Center(
        child: initState.when(
          data: (_) => const Text('初始化完成'),
          loading: () => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                dbState.isInitialized
                    ? '数据库已初始化 (v${dbState.version})'
                    : '正在初始化...',
              ),
              Text(
                dbState.error,
                style: const TextStyle(color: Colors.red),
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
