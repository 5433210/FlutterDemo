import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../infrastructure/providers/config_providers.dart';
import '../../infrastructure/providers/database_providers.dart';
import '../../infrastructure/providers/storage_providers.dart';

/// 应用初始化Provider
final appInitializationProvider = FutureProvider<void>((ref) async {
  // 使用debugPrint替代AppLogger，避免在provider初始化期间的ref问题
  debugPrint('[Initialization] 开始应用初始化');
  
  // 记录开始时间
  final startTime = DateTime.now();
  
  // 启动异步计时器确保最小显示时间
  final minimumDurationCompleter = Completer<void>();
  Timer(const Duration(seconds: 5), () {
    if (!minimumDurationCompleter.isCompleted) {
      minimumDurationCompleter.complete();
      debugPrint('[Initialization] 最小显示时间完成');
    }
  });
  
  // 执行实际的初始化
  try {
    // 等待存储服务初始化完成
    await ref.watch(storageProvider.future);
    await ref.watch(databaseProvider.future);

    // 等待配置初始化完成（这会确保默认配置被创建）
    await ref.watch(configInitializationProvider.future);
    
    // 使用debugPrint避免在初始化期间可能的ref问题
    debugPrint('[Initialization] 应用核心初始化完成');
  } catch (e) {
    // 使用debugPrint而不是AppLogger，避免在provider重建期间使用ref
    debugPrint('[Initialization] 应用初始化失败: $e');
    rethrow;
  }
  
  // 等待最小显示时间完成
  await minimumDurationCompleter.future;
  
  final duration = DateTime.now().difference(startTime);
  debugPrint('[Initialization] 应用初始化全部完成，总耗时: ${duration.inMilliseconds}ms');
});
