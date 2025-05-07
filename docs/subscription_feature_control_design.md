# 订阅级别功能控制设计文档

**创建日期**：2025年5月7日  
**状态**：初稿  
**作者**：技术团队  

## 1. 概述

本文档详细描述了应用程序如何根据用户的订阅级别控制功能访问的设计和实现方案。该设计旨在提供一个灵活、可扩展的系统，用于管理不同订阅级别的功能权限，确保未订阅用户无法访问高级功能，同时提供平滑的升级体验。

### 1.1 设计目标

- 建立清晰的订阅级别和功能权限模型
- 提供统一的功能访问控制机制
- 支持多种功能限制策略（完全限制、功能降级、使用量限制）
- 确保离线状态下的功能控制
- 提供平滑的订阅过期和续订体验

### 1.2 系统架构

```
┌─────────────────────────┐
│     应用界面层 (UI)      │
│  ┌───────────────────┐  │
│  │   FeatureGate     │  │
│  │    组件         │  │
│  └───────────────────┘  │
└───────────┬─────────────┘
            │
┌───────────▼─────────────┐
│     业务逻辑层           │
│  ┌───────────────────┐  │
│  │ 功能服务(带权限检查) │  │
│  └───────────────────┘  │
└───────────┬─────────────┘
            │
┌───────────▼─────────────┐
│     权限管理层           │
│  ┌───────────────────┐  │
│  │ SubscriptionProvider │  │
│  └───────────┬───────┘  │
│  ┌───────────▼───────┐  │
│  │FeaturePermissions │  │
│  └───────────────────┘  │
└───────────┬─────────────┘
            │
┌───────────▼─────────────┐
│    订阅服务抽象层        │
│  ┌───────────────────┐  │
│  │SubscriptionService│  │
│  └───────────────────┘  │
└─────────────────────────┘
```

## 2. 订阅级别与功能权限模型

### 2.1 订阅级别定义

```dart
// 订阅级别枚举
enum SubscriptionTier {
  free,
  standard,
  premium,
}
```

### 2.2 功能权限模型

```dart
// 功能权限模型
class FeaturePermission {
  final String featureId;
  final String featureName;
  final String description;
  final Set<SubscriptionTier> allowedTiers;
  
  const FeaturePermission({
    required this.featureId,
    required this.featureName,
    required this.description,
    required this.allowedTiers,
  });
  
  bool isAllowedForTier(SubscriptionTier tier) {
    return allowedTiers.contains(tier);
  }
}
```

### 2.3 权限配置

中心化的权限配置，定义应用中所有功能的访问控制：

```dart
// 功能权限配置
class FeaturePermissions {
  static const Map<String, FeaturePermission> all = {
    'export_high_res': FeaturePermission(
      featureId: 'export_high_res',
      featureName: '高分辨率导出',
      description: '导出高分辨率图像文件',
      allowedTiers: {SubscriptionTier.standard, SubscriptionTier.premium},
    ),
    'batch_processing': FeaturePermission(
      featureId: 'batch_processing',
      featureName: '批量处理',
      description: '同时处理多个文件',
      allowedTiers: {SubscriptionTier.premium},
    ),
    'cloud_storage': FeaturePermission(
      featureId: 'cloud_storage',
      featureName: '云存储',
      description: '将文件保存到云端',
      allowedTiers: {SubscriptionTier.standard, SubscriptionTier.premium},
    ),
    'advanced_filters': FeaturePermission(
      featureId: 'advanced_filters',
      featureName: '高级滤镜',
      description: '使用高级图像处理滤镜',
      allowedTiers: {SubscriptionTier.premium},
    ),
    'multi_device': FeaturePermission(
      featureId: 'multi_device',
      featureName: '多设备同步',
      description: '在多台设备上同步项目',
      allowedTiers: {SubscriptionTier.standard, SubscriptionTier.premium},
    ),
    // 更多功能权限...
  };
}
```

## 3. 订阅状态管理

### 3.1 订阅提供者 (SubscriptionProvider)

```dart
class SubscriptionProvider extends ChangeNotifier {
  SubscriptionTier _currentTier = SubscriptionTier.free;
  DateTime? _expiryDate;
  bool _isLoading = false;
  String? _error;
  
  // 获取当前订阅级别
  SubscriptionTier get currentTier => _currentTier;
  
  // 检查订阅是否已过期
  bool get isExpired => _expiryDate != null && 
      _expiryDate!.isBefore(DateTime.now());
      
  // 检查订阅是否即将过期（7天内）
  bool get isExpiringSoon => _expiryDate != null && 
      _expiryDate!.isBefore(DateTime.now().add(const Duration(days: 7))) &&
      _expiryDate!.isAfter(DateTime.now());
  
  // 检查功能是否可用
  bool canUseFeature(String featureId) {
    if (_isLoading) return false;
    if (isExpired) return FeaturePermissions.all[featureId]!
        .isAllowedForTier(SubscriptionTier.free);
    
    return FeaturePermissions.all[featureId]!
        .isAllowedForTier(_currentTier);
  }
  
  // 更新订阅状态
  Future<void> updateSubscriptionStatus() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      final subscriptionService = ServiceFactory.createSubscriptionService();
      final status = await subscriptionService.checkSubscriptionStatus();
      
      _currentTier = _mapStatusToTier(status);
      _expiryDate = status.expiryDate;
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // 将订阅状态映射到订阅级别
  SubscriptionTier _mapStatusToTier(SubscriptionStatus status) {
    if (!status.isActive) return SubscriptionTier.free;
    
    switch (status.planId) {
      case 'standard_monthly':
      case 'standard_yearly':
        return SubscriptionTier.standard;
      case 'premium_monthly':
      case 'premium_yearly':
        return SubscriptionTier.premium;
      default:
        return SubscriptionTier.free;
    }
  }
}
```

### 3.2 离线支持和状态缓存

```dart
// SubscriptionProvider类的扩展方法
class SubscriptionProvider extends ChangeNotifier {
  // ... 前面定义的属性和方法 ...
  
  // 本地存储键
  static const String _storageKey = 'subscription_status';
  
  // 初始化并加载缓存的订阅信息
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final statusJson = prefs.getString(_storageKey);
    
    if (statusJson != null) {
      try {
        final cachedStatus = SubscriptionStatus.fromJson(
            json.decode(statusJson));
        
        // 使用缓存的状态，但仍然触发在线刷新
        _currentTier = _mapStatusToTier(cachedStatus);
        _expiryDate = cachedStatus.expiryDate;
        notifyListeners();
      } catch (e) {
        // 忽略解析错误
      }
    }
    
    // 尝试在线更新
    updateSubscriptionStatus();
  }
  
  // 更新订阅状态并缓存
  @override
  Future<void> updateSubscriptionStatus() async {
    // ... 现有实现 ...
    
    // 添加缓存逻辑
    if (!_isLoading && _error == null) {
      final status = SubscriptionStatus(
        isActive: _currentTier != SubscriptionTier.free,
        planId: _currentTier.toString(),
        expiryDate: _expiryDate,
        autoRenewing: true, // 假设为真
      );
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_storageKey, json.encode(status.toJson()));
    }
  }
}
```

## 4. 功能访问控制实现

### 4.1 UI层功能控制

#### 4.1.1 FeatureGate组件

```dart
class FeatureGate extends StatelessWidget {
  final String featureId;
  final Widget child;
  final Widget? alternativeWidget;
  
  const FeatureGate({
    Key? key,
    required this.featureId,
    required this.child,
    this.alternativeWidget,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Consumer<SubscriptionProvider>(
      builder: (context, subscription, _) {
        if (subscription.canUseFeature(featureId)) {
          return child;
        } else {
          return alternativeWidget ?? _buildUpgradePrompt(context, featureId);
        }
      },
    );
  }
  
  Widget _buildUpgradePrompt(BuildContext context, String featureId) {
    final permission = FeaturePermissions.all[featureId]!;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('此功能需要升级订阅',
              style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(permission.description),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _showSubscriptionOptions(context),
              child: const Text('升级订阅'),
            ),
          ],
        ),
      ),
    );
  }
  
  void _showSubscriptionOptions(BuildContext context) {
    Navigator.of(context).pushNamed('/subscription');
  }
}
```

#### 4.1.2 使用示例

```dart
class ExportPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('导出')),
      body: Column(
        children: [
          // 基础导出功能 - 对所有用户开放
          ElevatedButton(
            onPressed: () => _exportStandard(context),
            child: const Text('标准导出'),
          ),
          
          const SizedBox(height: 16),
          
          // 高分辨率导出 - 受订阅控制
          FeatureGate(
            featureId: 'export_high_res',
            child: ElevatedButton(
              onPressed: () => _exportHighRes(context),
              child: const Text('高分辨率导出'),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // 批量处理 - 受订阅控制
          FeatureGate(
            featureId: 'batch_processing',
            child: ElevatedButton(
              onPressed: () => _batchProcess(context),
              child: const Text('批量处理'),
            ),
          ),
        ],
      ),
    );
  }
  
  // 功能实现方法...
}
```

### 4.2 业务逻辑层功能控制

```dart
class ImageProcessingService {
  final SubscriptionProvider _subscriptionProvider;
  
  ImageProcessingService(this._subscriptionProvider);
  
  Future<void> exportHighResolution(String imagePath) async {
    if (!_subscriptionProvider.canUseFeature('export_high_res')) {
      throw FeatureNotAvailableException('此功能需要标准或高级订阅');
    }
    
    // 执行高分辨率导出逻辑...
  }
  
  Future<void> batchProcess(List<String> imagePaths) async {
    if (!_subscriptionProvider.canUseFeature('batch_processing')) {
      throw FeatureNotAvailableException('此功能需要高级订阅');
    }
    
    // 执行批量处理逻辑...
  }
}

class FeatureNotAvailableException implements Exception {
  final String message;
  FeatureNotAvailableException(this.message);
  
  @override
  String toString() => message;
}
```

## 5. 功能限制策略

### 5.1 完全限制

某些功能完全无法使用，除非有相应订阅：

```dart
FeatureGate(
  featureId: 'ai_enhancement',
  child: AIEnhancementWidget(),
  alternativeWidget: UpgradePromptWidget(
    title: 'AI增强功能',
    description: '使用AI算法自动提升图像质量',
  ),
)
```

### 5.2 功能降级

低级别订阅提供有限功能：

```dart
Consumer<SubscriptionProvider>(
  builder: (context, subscription, _) {
    final maxExportSize = subscription.currentTier == SubscriptionTier.premium
        ? 3840 // 4K
        : subscription.currentTier == SubscriptionTier.standard
            ? 1920 // 1080p
            : 1280; // 720p
            
    return ExportOptionsWidget(maxResolution: maxExportSize);
  },
)
```

### 5.3 使用量限制

限制使用次数或处理数量：

```dart
class UsageLimiter {
  static int getMonthlyExportLimit(SubscriptionTier tier) {
    switch (tier) {
      case SubscriptionTier.free:
        return 5;
      case SubscriptionTier.standard:
        return 50;
      case SubscriptionTier.premium:
        return -1; // 无限制
    }
  }
  
  static Future<bool> canPerformExport(
      SubscriptionProvider subscription) async {
    final limit = getMonthlyExportLimit(subscription.currentTier);
    if (limit < 0) return true; // 无限制
    
    final usageService = UsageTrackingService();
    final currentUsage = await usageService.getCurrentMonthExports();
    
    return currentUsage < limit;
  }
}
```

## 6. 订阅状态通知和处理

### 6.1 订阅过期处理

```dart
class SubscriptionExpiryHandler {
  final BuildContext context;
  final SubscriptionProvider subscriptionProvider;
  
  SubscriptionExpiryHandler(this.context, this.subscriptionProvider);
  
  void checkAndNotify() {
    if (subscriptionProvider.isExpired) {
      _showExpiryNotification();
    } else if (subscriptionProvider.isExpiringSoon) {
      _showExpiryWarning();
    }
  }
  
  void _showExpiryNotification() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('订阅已过期'),
        content: const Text('您的订阅已过期，部分高级功能将不可用。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('稍后再说'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pushNamed('/subscription');
            },
            child: const Text('续订'),
          ),
        ],
      ),
    );
  }
  
  void _showExpiryWarning() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('订阅即将到期'),
        content: Text('您的订阅将在${_getExpiryDaysText()}后到期。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('稍后再说'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pushNamed('/subscription');
            },
            child: const Text('立即续订'),
          ),
        ],
      ),
    );
  }
  
  String _getExpiryDaysText() {
    final days = subscriptionProvider._expiryDate!
        .difference(DateTime.now()).inDays;
    return '$days天';
  }
}
```

### 6.2 订阅状态UI指示器

```dart
class SubscriptionStatusIndicator extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<SubscriptionProvider>(
      builder: (context, subscription, _) {
        if (subscription.isExpired) {
          return _buildStatusBadge(
            context, 
            Icons.error_outline, 
            Colors.red, 
            '已过期'
          );
        } else if (subscription.isExpiringSoon) {
          return _buildStatusBadge(
            context, 
            Icons.warning_amber_outlined, 
            Colors.orange, 
            '即将到期'
          );
        } else if (subscription.currentTier == SubscriptionTier.premium) {
          return _buildStatusBadge(
            context, 
            Icons.star, 
            Colors.purple, 
            '高级版'
          );
        } else if (subscription.currentTier == SubscriptionTier.standard) {
          return _buildStatusBadge(
            context, 
            Icons.check_circle_outline, 
            Colors.green, 
            '标准版'
          );
        } else {
          return _buildStatusBadge(
            context, 
            Icons.info_outline, 
            Colors.grey, 
            '免费版'
          );
        }
      },
    );
  }
  
  Widget _buildStatusBadge(
    BuildContext context, 
    IconData icon, 
    Color color, 
    String text
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(text, style: TextStyle(color: color, fontSize: 12)),
        ],
      ),
    );
  }
}
```

## 7. 应用初始化和集成

### 7.1 在应用启动时初始化

```dart
void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SubscriptionProvider()),
        // 其他 providers...
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    // 启动时加载订阅状态
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<SubscriptionProvider>(context, listen: false)
          .initialize();
    });
  }
  
  // 应用构建...
}
```

### 7.2 全局订阅状态监听

```dart
class SubscriptionMonitor extends StatefulWidget {
  final Widget child;
  
  const SubscriptionMonitor({Key? key, required this.child}) 
      : super(key: key);
      
  @override
  _SubscriptionMonitorState createState() => _SubscriptionMonitorState();
}

class _SubscriptionMonitorState extends State<SubscriptionMonitor> 
    with WidgetsBindingObserver {
  late SubscriptionProvider _subscription;
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _subscription = Provider.of<SubscriptionProvider>(
        context, listen: false);
    
    // 首次检查订阅状态
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkSubscriptionStatus();
    });
  }
  
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // 应用从后台恢复时刷新订阅状态
      _subscription.updateSubscriptionStatus();
    }
  }
  
  void _checkSubscriptionStatus() {
    final handler = SubscriptionExpiryHandler(context, _subscription);
    handler.checkAndNotify();
  }
  
  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
```

## 8. 测试策略

### 8.1 单元测试

```dart
void main() {
  group('SubscriptionProvider Tests', () {
    late SubscriptionProvider provider;
    late MockSubscriptionService mockService;
    
    setUp(() {
      mockService = MockSubscriptionService();
      provider = SubscriptionProvider();
      // 注入模拟服务
    });
    
    test('Should correctly determine feature availability', () {
      // Arrange
      provider._currentTier = SubscriptionTier.standard;
      
      // Act & Assert
      expect(provider.canUseFeature('export_high_res'), true);
      expect(provider.canUseFeature('batch_processing'), false);
    });
    
    test('Should handle expired subscription', () {
      // Arrange
      provider._currentTier = SubscriptionTier.premium;
      provider._expiryDate = DateTime.now().subtract(const Duration(days: 1));
      
      // Act & Assert
      expect(provider.isExpired, true);
      expect(provider.canUseFeature('batch_processing'), false);
    });
    
    // 更多测试...
  });
}
```

### 8.2 Widget测试

```dart
void main() {
  testWidgets('FeatureGate shows upgrade prompt for unavailable features',
      (WidgetTester tester) async {
    // Arrange
    final mockProvider = MockSubscriptionProvider();
    when(mockProvider.canUseFeature('premium_feature'))
        .thenReturn(false);
    
    // Act
    await tester.pumpWidget(
      MaterialApp(
        home: ChangeNotifierProvider<SubscriptionProvider>.value(
          value: mockProvider,
          child: Scaffold(
            body: FeatureGate(
              featureId: 'premium_feature',
              child: Text('Premium Content'),
            ),
          ),
        ),
      ),
    );
    
    // Assert
    expect(find.text('Premium Content'), findsNothing);
    expect(find.text('此功能需要升级订阅'), findsOneWidget);
    expect(find.text('升级订阅'), findsOneWidget);
  });
  
  // 更多测试...
}
```

## 9. 安全考量

### 9.1 防篡改机制

为防止用户通过修改本地缓存数据来获取未付费功能访问权限，应考虑以下策略：

1. **加密存储**：对本地存储的订阅信息进行加密
2. **签名验证**：添加服务器生成的签名，验证数据完整性
3. **定期在线验证**：定期与服务器验证订阅状态
4. **时间检查**：检测设备时间是否被篡改

### 9.2 实现建议

```dart
class SecureSubscriptionStorage {
  static Future<void> storeSubscriptionData(SubscriptionStatus status, 
      String userId) async {
    final data = status.toJson();
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    
    // 添加时间戳和用户ID
    data['timestamp'] = timestamp;
    data['userId'] = userId;
    
    // 生成签名（在实际应用中应使用更安全的方法）
    final signature = await _generateSignature(json.encode(data));
    data['signature'] = signature;
    
    // 加密数据
    final encryptedData = await _encryptData(json.encode(data));
    
    // 存储加密数据
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('secure_subscription', encryptedData);
  }
  
  static Future<SubscriptionStatus?> retrieveSubscriptionData() async {
    final prefs = await SharedPreferences.getInstance();
    final encryptedData = prefs.getString('secure_subscription');
    
    if (encryptedData == null) return null;
    
    try {
      // 解密数据
      final decryptedJson = await _decryptData(encryptedData);
      final data = json.decode(decryptedJson);
      
      // 验证签名
      final storedSignature = data['signature'];
      data.remove('signature');
      
      final calculatedSignature = 
          await _generateSignature(json.encode(data));
          
      if (storedSignature != calculatedSignature) {
        return null; // 签名验证失败
      }
      
      // 验证时间戳（防止重放攻击）
      final timestamp = int.parse(data['timestamp']);
      final now = DateTime.now().millisecondsSinceEpoch;
      
      if (now - timestamp > 24 * 60 * 60 * 1000) {
        return null; // 数据过期（超过24小时）
      }
      
      // 清除额外字段
      data.remove('timestamp');
      data.remove('userId');
      
      return SubscriptionStatus.fromJson(data);
    } catch (e) {
      return null;
    }
  }
  
  // 加密和签名方法实现...
}
```

## 10. 后续优化与扩展

### 10.1 功能分析和使用统计

实现功能使用统计，以便：

- 分析哪些高级功能最受欢迎
- 了解用户从免费升级到付费的转化路径
- 优化功能权限配置和营销策略

### 10.2 A/B测试框架

实现A/B测试框架，测试不同的功能限制策略和提示信息对转化率的影响。

### 10.3 自定义订阅计划

支持自定义订阅计划，允许用户选择特定功能包而非完整订阅。

### 10.4 推荐系统

基于用户使用行为，智能推荐可能感兴趣的高级功能和订阅计划。
