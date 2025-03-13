import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../infrastructure/providers/storage_providers.dart';
import '../services/initialization/app_initialization_service.dart';

/// 应用初始化Provider
final appInitializationProvider = FutureProvider<void>((ref) async {
  // 等待存储服务初始化完成
  final storage = await ref.watch(storageProvider.future);

  // 创建并运行应用初始化服务
  final initService = AppInitializationService(storage);
  await initService.initialize();
});
