import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../infrastructure/providers/storage_providers.dart';
import '../services/initialization/app_initialization_service.dart';

/// 应用初始化状态Provider
final appInitializationProvider = FutureProvider<void>((ref) async {
  final initService = ref.watch(appInitializationServiceProvider);
  await initService.initialize();
});

/// 应用初始化服务Provider
final appInitializationServiceProvider =
    Provider<AppInitializationService>((ref) {
  final storage = ref.watch(storageProvider);
  return AppInitializationService(storage);
});
