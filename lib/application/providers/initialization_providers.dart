import 'package:demo/infrastructure/providers/database_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../infrastructure/providers/storage_providers.dart';

/// 应用初始化Provider
final appInitializationProvider = FutureProvider<void>((ref) async {
  // 等待存储服务初始化完成
  await ref.watch(storageProvider.future);
  await ref.watch(databaseProvider.future);
});
