# 数据库初始化设计方案

## 问题背景

当前数据库初始化和依赖它的服务之间存在竞争条件，导致在数据库未完全初始化时出现null错误。

## 解决方案

### 1. 初始化服务层

创建一个专门的初始化服务来管理应用启动流程：

```dart
class AppInitializationService {
  // 数据库初始化
  Future<DatabaseInterface> initializeDatabase(AppConfig config) async {
    final database = await DatabaseFactory.create(config);
    await database.initialize();
    return database;
  }

  // 其他初始化操作
  Future<void> initializeOtherServices() async {
    // ...
  }
}
```

### 2. Provider链设计

构建一个Provider依赖链来确保正确的初始化顺序：

```dart
// 1. 配置Provider
final appConfigProvider = Provider<AppConfig>((ref) {
  return AppConfig(
    dataPath: AppConfig.dataPath,
    // ...其他配置
  );
});

// 2. 数据库Provider
final databaseProvider = FutureProvider<DatabaseInterface>((ref) async {
  final config = ref.watch(appConfigProvider);
  final initService = AppInitializationService();
  return initService.initializeDatabase(config);
});

// 3. 应用初始化状态Provider
final appInitializationProvider = FutureProvider<bool>((ref) async {
  // 等待数据库初始化
  await ref.watch(databaseProvider.future);
  return true;
});
```

### 3. Repository层改造

修改Repository providers以依赖初始化完成的数据库：

```dart
final workRepositoryProvider = Provider<WorkRepository>((ref) {
  // 通过databaseProvider.value获取已初始化的数据库实例
  final db = ref.watch(databaseProvider).value!;
  return WorkRepositoryImpl(db);
});
```

### 4. UI层处理

在应用根部添加初始化状态检查：

```dart
class MyApp extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final initState = ref.watch(appInitializationProvider);
    
    return MaterialApp(
      home: initState.when(
        loading: () => const InitializationScreen(),
        error: (error, stack) => ErrorScreen(error: error),
        data: (_) => const HomePage(),
      ),
    );
  }
}

class InitializationScreen extends StatelessWidget {
  const InitializationScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('正在初始化应用...'),
          ],
        ),
      ),
    );
  }
}
```

## 实施步骤

1. 创建新的初始化服务类和Provider
2. 修改现有的数据库Provider实现
3. 添加初始化状态Provider
4. 在UI层添加初始化状态检查
5. 修改Repository层以使用新的Provider模式
6. 添加错误处理和重试机制

## 优势

1. 明确的初始化流程
2. 避免空值错误
3. 更好的用户体验（显示加载状态）
4. 集中的错误处理
5. 易于扩展其他初始化需求

## 注意事项

1. 初始化超时处理
2. 错误恢复机制
3. 开发模式下的快速重载支持
4. 内存占用考虑
