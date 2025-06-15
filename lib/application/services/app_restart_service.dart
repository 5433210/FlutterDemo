import 'package:flutter/material.dart';

import '../../infrastructure/logging/logger.dart';
import '../../infrastructure/utils/app_restart.dart';
import '../../l10n/app_localizations.dart';

/// 应用重启服务
class AppRestartService {
  /// 重启应用
  static Future<void> restartApp(BuildContext context) async {
    AppLogger.info('应用重启服务：准备重启应用', tag: 'AppRestartService');

    try {
      // 使用AppRestart工具重启应用
      await AppRestart.restart(context);
    } catch (e) {
      AppLogger.error('应用重启失败', tag: 'AppRestartService', error: e);

      // 显示错误提示
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).appRestartFailed),
          ),
        );
      }
    }
  }
}
