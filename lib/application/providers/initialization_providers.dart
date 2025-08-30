import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../infrastructure/logging/logger.dart';
import '../../infrastructure/providers/config_providers.dart';
import '../../infrastructure/providers/database_providers.dart';
import '../../infrastructure/providers/storage_providers.dart';

/// 应用初始化Provider
final appInitializationProvider = FutureProvider<void>((ref) async {
  AppLogger.info('开始应用初始化', tag: 'Initialization');
  
  // 记录开始时间
  final startTime = DateTime.now();
  
  // 启动异步计时器确保最小显示时间
  final minimumDurationCompleter = Completer<void>();
  Timer(const Duration(seconds: 5), () {
    if (!minimumDurationCompleter.isCompleted) {
      minimumDurationCompleter.complete();
      AppLogger.info('最小显示时间完成', tag: 'Initialization');
    }
  });
  
  // 执行实际的初始化
  try {
    // 等待存储服务初始化完成
    await ref.watch(storageProvider.future);
    await ref.watch(databaseProvider.future);

    // 等待配置初始化完成（这会确保默认配置被创建）
    await ref.watch(configInitializationProvider.future);
    
    AppLogger.info('应用核心初始化完成', tag: 'Initialization');
  } catch (e) {
    AppLogger.error('应用初始化失败', error: e, tag: 'Initialization');
    rethrow;
  }
  
  // 等待最小显示时间完成
  await minimumDurationCompleter.future;
  
  final duration = DateTime.now().difference(startTime);
  AppLogger.info('应用初始化全部完成', 
    tag: 'Initialization', 
    data: {'totalDuration': '${duration.inMilliseconds}ms'}
  );
});
