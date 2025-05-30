import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../infrastructure/logging/logger.dart';

/// 应用重启服务
///
/// 提供重启应用的功能，在需要重新加载应用状态时使用
class AppRestartService {
  /// 重启应用
  ///
  /// 在Windows平台上，尝试使用平台通道调用原生代码重启应用
  /// 如果平台通道不可用，则直接退出应用，用户需要手动重启
  static Future<void> restartApp(BuildContext context) async {
    // 显示加载对话框
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const PopScope(
        canPop: false, // 防止用户通过返回键关闭对话框
        child: AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('正在重启应用...'),
            ],
          ),
        ),
      ),
    );

    // 等待一段时间，让UI更新
    await Future.delayed(const Duration(milliseconds: 500));

    AppLogger.info('正在重启应用', tag: 'AppRestart');

    // 在Windows平台上，我们可以使用平台通道调用原生代码来重启应用
    if (Platform.isWindows) {
      try {
        const platform = MethodChannel('app.restart/channel');
        await platform.invokeMethod('restartApp');
        AppLogger.info('已通过平台通道请求重启应用', tag: 'AppRestart');
      } catch (e) {
        // 如果平台通道失败，回退到退出应用
        AppLogger.warning('平台通道重启失败，将直接退出应用',
            tag: 'AppRestart', data: {'error': e});
        exit(0); // 这将导致应用退出，用户需要手动重启
      }
    } else {
      // 在其他平台上，我们直接退出应用
      AppLogger.info('非Windows平台，将直接退出应用', tag: 'AppRestart');
      exit(0);
    }
  }
}
