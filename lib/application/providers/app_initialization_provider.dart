import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/app_initialization_service.dart';
import 'data_path_provider.dart';

/// 应用初始化Provider
/// 管理应用启动时的初始化状态
final appInitializationProvider =
    FutureProvider<AppInitializationResult>((ref) async {
  // 创建一个简化的初始化方法，直接使用FutureProviderRef
  return await _initializeAppWithRef(ref);
});

/// 简化的初始化方法，适配Provider环境
Future<AppInitializationResult> _initializeAppWithRef(Ref ref) async {
  try {
    // 确保数据路径配置加载
    final configAsync = ref.watch(dataPathConfigProvider);
    configAsync.when(
      data: (config) => config,
      loading: () => throw Exception('配置加载中'),
      error: (error, _) => throw error,
    );

    // 确保实际数据路径加载
    await ref.watch(actualDataPathProvider.future);

    return AppInitializationResult.success();
  } catch (e) {
    return AppInitializationResult.failure('应用初始化失败: $e');
  }
}

/// 应用初始化状态Provider
/// 提供应用初始化状态的详细信息
final appInitializationStatusProvider =
    FutureProvider<AppInitializationStatus>((ref) async {
  return AppInitializationService.getInitializationStatus();
});

/// 应用是否已初始化Provider
/// 简单的布尔值Provider，用于快速检查应用是否已初始化
final appIsInitializedProvider = Provider<bool>((ref) {
  final initAsync = ref.watch(appInitializationProvider);
  return initAsync.when(
    data: (result) => result.isSuccess,
    loading: () => false,
    error: (_, __) => false,
  );
});
