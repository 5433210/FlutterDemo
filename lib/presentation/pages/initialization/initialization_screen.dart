import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../infrastructure/logging/logger.dart';
import '../../../infrastructure/providers/initialization_providers.dart';

class InitializationScreen extends ConsumerWidget {
  const InitializationScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final initState = ref.watch(appInitializationProvider);
    final dbState = ref.watch(databaseStateProvider);

    return Scaffold(
      body: Center(
        child: initState.when(
          data: (isInitialized) => isInitialized
              ? const SizedBox() // 初始化完成后这个界面不会显示
              : const _LoadingView(),
          loading: () => const _LoadingView(),
          error: (error, stack) => _ErrorView(
            error: error,
            onRetry: () {
              AppLogger.info('重试初始化',
                  tag: 'InitializationScreen',
                  data: {'error': error.toString()});
              ref.read(databaseStateProvider.notifier).retry();
            },
          ),
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final Object error;
  final VoidCallback onRetry;

  const _ErrorView({
    Key? key,
    required this.error,
    required this.onRetry,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            color: Colors.red,
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            '初始化失败',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            error.toString(),
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('重试'),
          ),
        ],
      ),
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const CircularProgressIndicator(),
        const SizedBox(height: 16),
        Text(
          '正在初始化应用...',
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ],
    );
  }
}
