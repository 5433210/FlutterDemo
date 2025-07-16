import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/providers/initialization_providers.dart';
import '../../../infrastructure/logging/logger.dart';
import '../../../l10n/app_localizations.dart';

class InitializationScreen extends ConsumerWidget {
  const InitializationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    AppLogger.info('初始化屏幕构建开始', tag: 'InitScreen');
    final initState = ref.watch(appInitializationProvider);
    AppLogger.info('初始化屏幕状态', tag: 'InitScreen', data: {
      'state': initState.toString(),
    });

    // 在初始化屏幕中，我们可能还没有完全设置好本地化
    // 所以我们使用一个Builder来确保我们可以访问本地化资源
    return Scaffold(
      body: Center(
        child: Builder(builder: (context) {
          AppLogger.info('初始化屏幕Builder构建', tag: 'InitScreen');
          // 尝试获取本地化资源，如果不可用则使用硬编码字符串
          AppLocalizations? l10n;
          try {
            l10n = AppLocalizations.of(context);
            AppLogger.debug('成功获取本地化资源', tag: 'InitScreen');
          } catch (e) {
            // 如果本地化资源不可用，我们将使用硬编码字符串
            AppLogger.warning('无法获取本地化资源', error: e, tag: 'InitScreen');
            l10n = null;
          }

          return initState.when(
            data: (_) {
              AppLogger.info('初始化完成', tag: 'InitScreen');
              return Text(l10n?.appTitle ?? 'Initialization Complete');
            },
            loading: () {
              AppLogger.info('初始化加载中', tag: 'InitScreen');
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(l10n?.initializing ?? 'Initializing...'),
                ],
              );
            },
            error: (error, stack) {
              AppLogger.error('初始化失败', error: error, stackTrace: stack, tag: 'InitScreen');
              return Text(
                l10n?.initializationFailed(error.toString()) ??
                    'Initialization failed: $error',
                style: const TextStyle(color: Colors.red),
              );
            },
          );
        }),
      ),
    );
  }
}
