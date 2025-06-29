import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../infrastructure/logging/logger.dart';

/// 对话框导航助手
/// 提供安全的对话框弹出和导航功能，防止"cannot pop after deferred attempt"等错误
class DialogNavigationHelper {
  static const String _tag = 'DialogNavigationHelper';

  /// 安全地弹出对话框
  /// 
  /// 参数：
  /// - [context] 构建上下文
  /// - [result] 要返回的结果（可选）
  /// - [dialogName] 对话框名称（用于日志）
  static void safePop<T>(
    BuildContext context, {
    T? result,
    String dialogName = 'Dialog',
  }) {
    if (!_isContextValid(context, dialogName)) return;

    final navigator = Navigator.of(context);
    if (!navigator.canPop()) {
      AppLogger.warning(
        '$dialogName cannot pop - no route to pop',
        tag: _tag,
      );
      return;
    }

    try {
      AppLogger.debug(
        '$dialogName attempting to pop with result',
        tag: _tag,
        data: {
          'resultType': result?.runtimeType.toString() ?? 'null',
          'hasResult': result != null,
          'dialogName': dialogName,
        },
      );

      navigator.pop<T>(result);
      
      AppLogger.info(
        '$dialogName pop successful',
        tag: _tag,
        data: {
          'hasResult': result != null,
          'resultType': result?.runtimeType.toString() ?? 'null',
        },
      );
    } catch (e) {
      AppLogger.warning(
        '$dialogName immediate pop failed, trying deferred approach',
        tag: _tag,
        data: {
          'error': e.toString(),
          'resultType': result?.runtimeType.toString() ?? 'null',
          'stackTrace': e is Error ? e.stackTrace?.toString() : null,
        },
      );
      _attemptDeferredPop<T>(context, result, dialogName);
    }
  }

  /// 安全地取消对话框（无返回值）
  static void safeCancel(
    BuildContext context, {
    String dialogName = 'Dialog',
  }) {
    safePop<dynamic>(context, dialogName: dialogName);
  }

  /// 检查上下文是否有效
  static bool _isContextValid(BuildContext context, String dialogName) {
    if (!context.mounted) {
      AppLogger.warning(
        '$dialogName context not mounted, cannot navigate',
        tag: _tag,
      );
      return false;
    }
    return true;
  }

  /// 尝试延迟弹出
  static void _attemptDeferredPop<T>(
    BuildContext context,
    T? result,
    String dialogName,
  ) {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _performDeferredPop<T>(context, result, dialogName);
    });
  }

  /// 执行延迟弹出
  static void _performDeferredPop<T>(
    BuildContext context,
    T? result,
    String dialogName,
  ) {
    if (!_isContextValid(context, dialogName)) return;

    Future.microtask(() async {
      if (!_isContextValid(context, dialogName)) return;

      // 等待一小段时间确保所有状态更新完成
      await Future.delayed(const Duration(milliseconds: 10));

      if (!_isContextValid(context, dialogName)) return;

      try {
        final navigator = Navigator.of(context);
        if (navigator.canPop()) {
          AppLogger.debug(
            '$dialogName deferred pop attempting',
            tag: _tag,
            data: {
              'resultType': result?.runtimeType.toString() ?? 'null',
              'hasResult': result != null,
            },
          );

          navigator.pop<T>(result);
          AppLogger.info(
            '$dialogName deferred pop successful',
            tag: _tag,
            data: {
              'hasResult': result != null,
              'resultType': result?.runtimeType.toString() ?? 'null',
            },
          );
        } else {
          AppLogger.warning(
            '$dialogName cannot pop after deferred attempt',
            tag: _tag,
          );
          _attemptRootNavigation<T>(context, result, dialogName);
        }
      } catch (e) {
        AppLogger.error(
          '$dialogName deferred pop failed',
          tag: _tag,
          data: {
            'error': e.toString(),
            'resultType': result?.runtimeType.toString() ?? 'null',
            'stackTrace': e is Error ? e.stackTrace?.toString() : null,
          },
        );
        _attemptRootNavigation<T>(context, result, dialogName);
      }
    });
  }

  /// 尝试使用根导航器
  static void _attemptRootNavigation<T>(
    BuildContext context,
    T? result,
    String dialogName,
  ) {
    if (!_isContextValid(context, dialogName)) return;

    try {
      final rootNavigator = Navigator.of(context, rootNavigator: true);
      if (rootNavigator.canPop()) {
        AppLogger.debug(
          '$dialogName root navigation attempting',
          tag: _tag,
          data: {
            'resultType': result?.runtimeType.toString() ?? 'null',
            'hasResult': result != null,
          },
        );

        rootNavigator.pop<T>(result);
        AppLogger.info(
          '$dialogName root navigation successful',
          tag: _tag,
          data: {
            'hasResult': result != null,
            'resultType': result?.runtimeType.toString() ?? 'null',
          },
        );
      } else {
        AppLogger.error(
          '$dialogName all navigation attempts failed - no route to pop',
          tag: _tag,
        );
      }
    } catch (e) {
      AppLogger.error(
        '$dialogName all navigation attempts failed',
        tag: _tag,
        data: {
          'error': e.toString(),
          'resultType': result?.runtimeType.toString() ?? 'null',
          'stackTrace': e is Error ? e.stackTrace?.toString() : null,
        },
      );
    }
  }

  /// 安全地显示对话框
  /// 
  /// 提供统一的对话框显示接口，带有错误处理
  static Future<T?> showSafeDialog<T>({
    required BuildContext context,
    required Widget Function(BuildContext) builder,
    bool barrierDismissible = true,
    String? barrierLabel,
    Color? barrierColor,
    String dialogName = 'Dialog',
  }) async {
    if (!_isContextValid(context, dialogName)) return null;

    try {
      AppLogger.info(
        '$dialogName showing dialog',
        tag: _tag,
      );

      final result = await showDialog<T>(
        context: context,
        builder: builder,
        barrierDismissible: barrierDismissible,
        barrierLabel: barrierLabel,
        barrierColor: barrierColor,
      );

      AppLogger.info(
        '$dialogName dialog closed',
        tag: _tag,
        data: {'hasResult': result != null},
      );

      return result;
    } catch (e) {
      AppLogger.error(
        '$dialogName show dialog failed',
        tag: _tag,
        data: {'error': e.toString()},
      );
      return null;
    }
  }

  /// 带有延迟的安全弹出
  /// 适用于需要等待状态更新完成的场景
  static Future<void> safePopWithDelay<T>(
    BuildContext context, {
    T? result,
    Duration delay = const Duration(milliseconds: 100),
    String dialogName = 'Dialog',
  }) async {
    if (!_isContextValid(context, dialogName)) return;

    await Future.delayed(delay);
    
    // 重新检查上下文有效性
    if (!context.mounted) {
      AppLogger.warning(
        '$dialogName context no longer mounted after delay',
        tag: _tag,
      );
      return;
    }

    safePop<T>(context, result: result, dialogName: dialogName);
  }

  /// 🔧 专门用于处理可能存在类型混乱的复杂对话框场景
  /// 通过额外的检查和延迟来避免导航栈污染
  static Future<void> safePopWithTypeGuard<T>(
    BuildContext context, {
    T? result,
    String dialogName = 'Dialog',
    Duration guardDelay = const Duration(milliseconds: 150),
  }) async {
    if (!_isContextValid(context, dialogName)) return;

    // 记录详细的导航状态
    final navigator = Navigator.of(context);
    AppLogger.debug(
      '$dialogName type-guarded pop initiated',
      tag: _tag,
      data: {
        'canPop': navigator.canPop(),
        'resultType': result?.runtimeType.toString() ?? 'null',
        'hasResult': result != null,
        'expectedType': T.toString(),
      },
    );

    // 额外的延迟确保任何前序对话框完全清理
    await Future.delayed(guardDelay);

    // 再次检查上下文和导航状态
    if (!_isContextValid(context, dialogName)) return;

    final currentNavigator = Navigator.of(context);
    if (!currentNavigator.canPop()) {
      AppLogger.warning(
        '$dialogName cannot pop after type guard delay',
        tag: _tag,
      );
      return;
    }

    // 执行类型保护的弹出
    try {
      currentNavigator.pop<T>(result);
      AppLogger.info(
        '$dialogName type-guarded pop successful',
        tag: _tag,
        data: {
          'resultType': result?.runtimeType.toString() ?? 'null',
          'expectedType': T.toString(),
        },
      );
    } catch (e) {
      AppLogger.error(
        '$dialogName type-guarded pop failed',
        tag: _tag,
        data: {
          'error': e.toString(),
          'resultType': result?.runtimeType.toString() ?? 'null',
          'expectedType': T.toString(),
          'stackTrace': e is Error ? e.stackTrace?.toString() : null,
        },
      );
      
      // 如果类型保护弹出失败，尝试使用根导航器
      _attemptRootNavigation<T>(context, result, dialogName);
    }
  }

  /// 安全地弹出所有对话框直到指定路由
  static void safePopUntil(
    BuildContext context,
    bool Function(Route<dynamic>) predicate, {
    String dialogName = 'Dialog',
  }) {
    if (!_isContextValid(context, dialogName)) return;

    try {
      Navigator.of(context).popUntil(predicate);
      AppLogger.info(
        '$dialogName popUntil successful',
        tag: _tag,
      );
    } catch (e) {
      AppLogger.error(
        '$dialogName popUntil failed',
        tag: _tag,
        data: {'error': e.toString()},
      );
    }
  }
}
