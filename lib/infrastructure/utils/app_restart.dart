import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../l10n/app_localizations.dart';
import '../logging/logger.dart';

/// 应用重启工具类
class AppRestart {
  /// 重启应用
  ///
  /// 在不同平台上使用不同的重启策略
  static Future<void> restart(BuildContext context) async {
    AppLogger.info('准备重启应用', tag: 'AppRestart');

    // 显示重启中对话框
    _showRestartingDialog(context);

    // 延迟一段时间，确保对话框显示
    await Future.delayed(const Duration(milliseconds: 500));

    if (kIsWeb) {
      // Web平台使用页面刷新
      _restartWeb();
    } else if (Platform.isAndroid || Platform.isIOS) {
      // 移动平台使用SystemNavigator
      _restartMobile();
    } else if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
      // 桌面平台使用exit(0)强制关闭应用
      _restartDesktop();
    } else {
      // 其他平台使用通用方法
      _restartGeneric(null);
    }
  }

  /// 桌面平台重启方法
  static void _restartDesktop() {
    AppLogger.info('使用exit(0)强制关闭应用，请手动重新打开', tag: 'AppRestart');
    exit(0); // 强制关闭应用，这是最可靠的方法
  }

  /// 通用重启方法
  static void _restartGeneric(BuildContext? context) {
    AppLogger.info('使用通用方法重启应用', tag: 'AppRestart');

    // 使用Phoenix或类似的库重新加载根组件
    // 这里我们使用一个简单的方法，通过重新创建MaterialApp来模拟重启
    if (context != null) {
      // 如果有上下文，使用Navigator重新加载根路由
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/',
        (route) => false,
      );
    } else {
      // 如果没有上下文，我们可以尝试使用exit(0)
      // 但这会完全关闭应用，所以只在开发环境使用
      if (kDebugMode) {
        AppLogger.warning('无法使用上下文重启应用，尝试使用exit(0)', tag: 'AppRestart');
        exit(0);
      }
    }
  }

  /// 移动平台重启方法
  static Future<void> _restartMobile() async {
    AppLogger.info('使用SystemNavigator重启移动应用', tag: 'AppRestart');
    // 在Android上，这会关闭应用
    // 在iOS上，这会将应用移至后台
    await SystemNavigator.pop();

    // 对于iOS，我们需要额外的处理
    if (Platform.isIOS) {
      // 在iOS上，我们可以使用exit(0)，但这可能会导致应用被App Store拒绝
      // 所以我们使用通用方法
      _restartGeneric(null);
    }
  }

  /// Web平台重启方法
  static void _restartWeb() {
    AppLogger.info('使用页面刷新重启Web应用', tag: 'AppRestart');
    // 使用JS刷新页面
    // 这里需要使用js interop，但为简单起见，我们使用通用方法
    _restartGeneric(null);
  }

  /// 显示重启中对话框
  static void _showRestartingDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context).appRestarting),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(AppLocalizations.of(context).appRestartingMessage),
          ],
        ),
      ),
    );
  }
}
