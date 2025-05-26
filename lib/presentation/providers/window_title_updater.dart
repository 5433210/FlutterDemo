import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';

import '../../l10n/app_localizations.dart';
import 'settings_provider.dart';

/// 窗口标题更新器 - 使用正式的l10n机制更新窗口标题
class WindowTitleUpdater extends ConsumerWidget {
  final Widget child;

  const WindowTitleUpdater({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 监听语言变化
    ref.watch(settingsProvider.select((s) => s.language));

    // 使用正式的l10n机制获取标题
    final l10n = AppLocalizations.of(context);
    final appTitle = l10n.appTitle;

    // 更新窗口标题 - 仅在桌面平台
    Future.microtask(() {
      if (!kIsWeb &&
          (Platform.isWindows || Platform.isMacOS || Platform.isLinux)) {
        windowManager.setTitle(appTitle);
      }
    });

    return child;
  }
}
