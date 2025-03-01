import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../infrastructure/logging/logger.dart';
import '../presentation/providers/work_browse_provider.dart';

/// 帮助诊断应用程序问题的工具类
class DiagnosticHelper {
  /// 诊断WorkBrowseProvider的状态
  static void diagnoseWorkBrowseState(WidgetRef ref) {
    final state = ref.read(workBrowseProvider);

    AppLogger.info('WorkBrowseState诊断', tag: 'Diagnostics', data: {
      'isLoading': state.isLoading,
      'hasError': state.error != null,
      'errorMsg': state.error,
      'worksCount': state.works.length,
      'viewMode': state.viewMode.toString(),
      'isSidebarOpen': state.isSidebarOpen,
      'searchQuery': state.searchQuery,
    });

    // 尝试检查数据加载问题
    try {
      // 尝试直接加载
      ref.read(workBrowseProvider.notifier).loadWorks(forceRefresh: true);
    } catch (e, stack) {
      AppLogger.error('诊断时重新加载失败',
          tag: 'Diagnostics', error: e, stackTrace: stack);
    }
  }

  /// 获取应用状态快照
  static Map<String, dynamic> getAppStateSnapshot(WidgetRef ref) {
    final snapshot = <String, dynamic>{};

    try {
      final browseState = ref.read(workBrowseProvider);
      snapshot['workBrowseState'] = {
        'isLoading': browseState.isLoading,
        'hasError': browseState.error != null,
        'worksCount': browseState.works.length,
      };
    } catch (e) {
      snapshot['workBrowseStateError'] = e.toString();
    }

    return snapshot;
  }

  /// 运行诊断任务，包含超时保护
  static Future<T> runWithDiagnostics<T>(
    Future<T> Function() task, {
    String taskName = '未命名任务',
    Duration timeout = const Duration(seconds: 10),
  }) async {
    try {
      AppLogger.debug('开始任务: $taskName', tag: 'Diagnostics');
      final Stopwatch stopwatch = Stopwatch()..start();

      final result = await task().timeout(timeout, onTimeout: () {
        AppLogger.warning('任务超时: $taskName', tag: 'Diagnostics');
        throw TimeoutException('任务 $taskName 超时');
      });

      stopwatch.stop();
      AppLogger.debug('完成任务: $taskName',
          tag: 'Diagnostics', data: {'耗时(ms)': stopwatch.elapsedMilliseconds});

      return result;
    } catch (e, stack) {
      AppLogger.error('任务执行失败: $taskName',
          tag: 'Diagnostics', error: e, stackTrace: stack);
      rethrow;
    }
  }
}
