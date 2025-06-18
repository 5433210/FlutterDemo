import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/providers/initialization_providers.dart';
import '../../../l10n/app_localizations.dart';

class InitializationScreen extends ConsumerWidget {
  const InitializationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final initState = ref.watch(appInitializationProvider);

    // 在初始化屏幕中，我们可能还没有完全设置好本地化
    // 所以我们使用一个Builder来确保我们可以访问本地化资源
    return Scaffold(
      body: Center(
        child: Builder(builder: (context) {
          // 尝试获取本地化资源，如果不可用则使用硬编码字符串
          AppLocalizations? l10n;
          try {
            l10n = AppLocalizations.of(context);
          } catch (e) {
            // 如果本地化资源不可用，我们将使用硬编码字符串
            l10n = null;
          }

          return initState.when(
            data: (_) => Text(l10n?.appTitle ?? 'Initialization Complete'),
            loading: () => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(l10n?.initializing ?? 'Initializing...'),
              ],
            ),
            error: (error, stack) => Text(
              l10n?.initializationFailed(error.toString()) ??
                  'Initialization failed: $error',
              style: const TextStyle(color: Colors.red),
            ),
          );
        }),
      ),
    );
  }
}
