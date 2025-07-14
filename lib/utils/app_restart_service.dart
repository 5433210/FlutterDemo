import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../infrastructure/logging/logger.dart';
import '../l10n/app_localizations.dart';

/// 应用重启服务
///
/// 提供重启应用的功能，在需要重新加载应用状态时使用
class AppRestartService {
  /// 重启应用
  ///
  /// 在Windows平台上，尝试使用平台通道调用原生代码重启应用
  /// 如果平台通道不可用，则直接退出应用，用户需要手动重启
  static Future<void> restartApp(BuildContext context) async {
    AppLogger.info('AppRestartService.restartApp 被调用', tag: 'AppRestart');
    
    final l10n = AppLocalizations.of(context);

    AppLogger.info('开始重启应用流程', tag: 'AppRestart');

    // 显示重启提示对话框
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PopScope(
        canPop: false, // 防止用户通过返回键关闭对话框
        child: AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.restart_alt, color: Colors.blue),
              const SizedBox(width: 8),
              Text(l10n.appRestarting),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(l10n.appRestartingMessage),
              const SizedBox(height: 8),
              Text(
                '应用将在 3 秒后重启...',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    // 等待一段时间，让UI更新
    await Future.delayed(const Duration(seconds: 3));

    AppLogger.info('正在重启应用', tag: 'AppRestart');

    // 在Windows平台上，我们可以使用平台通道调用原生代码来重启应用
    if (Platform.isWindows) {
      bool restartSuccess = false;
      
      try {
        const platform = MethodChannel('app.restart/channel');
        
        // 尝试平台通道重启，但添加超时检测
        await Future.any([
          platform.invokeMethod('restartApp').then((_) {
            AppLogger.info('平台通道重启调用成功', tag: 'AppRestart');
            restartSuccess = true;
          }),
          Future.delayed(const Duration(seconds: 5), () {
            // 如果5秒后还没重启，说明平台通道调用可能失败
            AppLogger.warning('平台通道重启超时', tag: 'AppRestart');
            throw Exception('平台通道重启超时');
          }),
        ]);
        
        // 如果平台通道调用成功，等待重启发生
        if (restartSuccess) {
          await Future.delayed(const Duration(seconds: 3));
          
          // 如果执行到这里，说明重启可能失败了
          AppLogger.warning('平台通道调用成功但应用未重启', tag: 'AppRestart');
          restartSuccess = false;
        }
      } catch (e) {
        AppLogger.warning('平台通道重启失败，将使用备用方案',
            tag: 'AppRestart', data: {'error': e});
        restartSuccess = false;
      }
      
      // 如果平台通道失败，或者等待一段时间后仍未重启，使用备用方案
      if (!restartSuccess) {
        // 先关闭重启对话框
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        }
        
        // 尝试使用Process.run启动新实例并退出当前实例
        try {
          await _attemptProcessRestart();
          AppLogger.info('进程重启方案启动成功', tag: 'AppRestart');
          
          // 等待一段时间让新进程启动
          await Future.delayed(const Duration(seconds: 2));
          
          // 退出当前进程
          exit(0);
        } catch (processError) {
          AppLogger.warning('进程重启方案失败',
              tag: 'AppRestart', data: {'error': processError});
          
          // 如果进程重启也失败，显示手动重启提示
          await _showManualRestartDialog(context, l10n);
        }
      }
    } else {
      // 在其他平台上，我们直接退出应用
      AppLogger.info('非Windows平台，将直接退出应用', tag: 'AppRestart');
      exit(0);
    }
  }

  /// 尝试使用Process.run重启应用
  static Future<void> _attemptProcessRestart() async {
    try {
      // 获取当前可执行文件路径
      final executable = Platform.resolvedExecutable;
      
      AppLogger.info('尝试重启应用', tag: 'AppRestart', data: {
        'executable': executable,
      });
      
      // 启动新的应用实例
      await Process.start(
        executable,
        [],
        mode: ProcessStartMode.detached,
      );
      
      AppLogger.info('新应用实例已启动', tag: 'AppRestart');
    } catch (e) {
      AppLogger.error('启动新应用实例失败', error: e, tag: 'AppRestart');
      rethrow;
    }
  }

  /// 显示手动重启提示对话框
  static Future<void> _showManualRestartDialog(BuildContext context, AppLocalizations l10n) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.warning, color: Colors.orange),
            const SizedBox(width: 8),
            Text(l10n.needRestartApp),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.dataPathChangedMessage),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info, color: Colors.blue, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '自动重启失败，请手动重启应用以完成恢复。',
                      style: TextStyle(
                        color: Colors.blue.shade700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              exit(0); // 退出应用
            },
            child: const Text('退出应用'),
          ),
        ],
      ),
    );
  }
}
