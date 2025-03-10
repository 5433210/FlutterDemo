import 'dart:async';

import 'check_logger.dart';
import 'monitor_auth.dart';

/// 资源配额
class ResourceQuota {
  final int maxMetrics; // 最大指标数
  final int maxDataPoints; // 最大数据点数
  final int maxStorage; // 最大存储空间(MB)
  final int maxUsers; // 最大用户数
  final Duration retention; // 数据保留时间

  const ResourceQuota({
    this.maxMetrics = 100,
    this.maxDataPoints = 1000000,
    this.maxStorage = 1024,
    this.maxUsers = 10,
    this.retention = const Duration(days: 30),
  });

  Map<String, dynamic> toJson() => {
        'maxMetrics': maxMetrics,
        'maxDataPoints': maxDataPoints,
        'maxStorage': maxStorage,
        'maxUsers': maxUsers,
        'retention': retention.inDays,
      };
}

/// 资源使用统计
class ResourceUsage {
  final int currentMetrics;
  final int currentDataPoints;
  final int currentStorage;
  final int currentUsers;
  final DateTime lastUpdated;

  ResourceUsage({
    this.currentMetrics = 0,
    this.currentDataPoints = 0,
    this.currentStorage = 0,
    this.currentUsers = 0,
    DateTime? lastUpdated,
  }) : lastUpdated = lastUpdated ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'currentMetrics': currentMetrics,
        'currentDataPoints': currentDataPoints,
        'currentStorage': currentStorage,
        'currentUsers': currentUsers,
        'lastUpdated': lastUpdated.toIso8601String(),
      };
}

/// 租户配置
class TenantConfig {
  final String id;
  final String name;
  final TenantStatus status;
  final ResourceQuota quota;
  final Map<String, dynamic> settings;
  final Set<AccessLevel> permissions;

  const TenantConfig({
    required this.id,
    required this.name,
    this.status = TenantStatus.active,
    this.quota = const ResourceQuota(),
    this.settings = const {},
    this.permissions = const {AccessLevel.read},
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'status': status.toString(),
        'quota': quota.toJson(),
        'settings': settings,
        'permissions': permissions.map((p) => p.toString()).toList(),
      };
}

/// 多租户管理器
class TenantManager {
  final CheckLogger logger;
  final Map<String, TenantConfig> _tenants = {};
  final Map<String, ResourceUsage> _usage = {};
  final Map<String, AuthManager> _authManagers = {};
  Timer? _usageTimer;

  TenantManager({
    CheckLogger? logger,
  }) : logger = logger ?? CheckLogger.instance {
    _setupUsageTracking();
  }

  /// 创建租户
  Future<bool> createTenant(TenantConfig config) async {
    if (_tenants.containsKey(config.id)) {
      logger.error('租户已存在: ${config.id}');
      return false;
    }

    try {
      _tenants[config.id] = config;
      _usage[config.id] = ResourceUsage();

      // 创建认证管理器
      _authManagers[config.id] = AuthManager(
        config: const AuthConfig(
          method: AuthMethod.token,
          tokenExpiry: Duration(hours: 24),
        ),
      );

      logger.info('创建租户: ${config.id}');
      return true;
    } catch (e) {
      logger.error('创建租户失败: ${config.id}', e);
      return false;
    }
  }

  /// 删除租户
  Future<bool> deleteTenant(String id) async {
    if (!_tenants.containsKey(id)) {
      logger.error('租户不存在: $id');
      return false;
    }

    try {
      _tenants.remove(id);
      _usage.remove(id);
      _authManagers[id]?.dispose();
      _authManagers.remove(id);

      logger.info('删除租户: $id');
      return true;
    } catch (e) {
      logger.error('删除租户失败: $id', e);
      return false;
    }
  }

  /// 释放资源
  void dispose() {
    _usageTimer?.cancel();
    for (final auth in _authManagers.values) {
      auth.dispose();
    }
    _tenants.clear();
    _usage.clear();
    _authManagers.clear();
  }

  /// 获取租户认证管理器
  AuthManager? getAuthManager(String id) => _authManagers[id];

  /// 获取租户资源使用情况
  ResourceUsage? getResourceUsage(String id) => _usage[id];

  /// 获取租户配置
  TenantConfig? getTenant(String id) => _tenants[id];

  /// 获取租户列表
  List<TenantConfig> listTenants({
    TenantStatus? status,
    bool activeOnly = false,
  }) {
    return _tenants.values.where((tenant) {
      if (status != null && tenant.status != status) return false;
      if (activeOnly && tenant.status != TenantStatus.active) return false;
      return true;
    }).toList();
  }

  /// 更新资源使用
  void updateResourceUsage(
    String id, {
    int? metrics,
    int? dataPoints,
    int? storage,
    int? users,
  }) {
    final usage = _usage[id];
    if (usage == null) return;

    _usage[id] = ResourceUsage(
      currentMetrics: metrics ?? usage.currentMetrics,
      currentDataPoints: dataPoints ?? usage.currentDataPoints,
      currentStorage: storage ?? usage.currentStorage,
      currentUsers: users ?? usage.currentUsers,
    );
  }

  /// 更新租户配置
  Future<bool> updateTenant(String id, TenantConfig config) async {
    if (!_tenants.containsKey(id)) {
      logger.error('租户不存在: $id');
      return false;
    }

    try {
      _tenants[id] = config;
      logger.info('更新租户: $id');
      return true;
    } catch (e) {
      logger.error('更新租户失败: $id', e);
      return false;
    }
  }

  /// 验证资源使用
  bool validateResourceUsage(
    String id, {
    int? additionalMetrics,
    int? additionalDataPoints,
    int? additionalStorage,
    int? additionalUsers,
  }) {
    final tenant = _tenants[id];
    final usage = _usage[id];

    if (tenant == null || usage == null) return false;

    if (additionalMetrics != null &&
        usage.currentMetrics + additionalMetrics > tenant.quota.maxMetrics) {
      return false;
    }

    if (additionalDataPoints != null &&
        usage.currentDataPoints + additionalDataPoints >
            tenant.quota.maxDataPoints) {
      return false;
    }

    if (additionalStorage != null &&
        usage.currentStorage + additionalStorage > tenant.quota.maxStorage) {
      return false;
    }

    if (additionalUsers != null &&
        usage.currentUsers + additionalUsers > tenant.quota.maxUsers) {
      return false;
    }

    return true;
  }

  /// 设置资源使用跟踪
  void _setupUsageTracking() {
    _usageTimer?.cancel();
    _usageTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      for (final tenant in _tenants.entries) {
        final usage = _usage[tenant.key] ?? ResourceUsage();

        if (usage.currentMetrics > tenant.value.quota.maxMetrics ||
            usage.currentDataPoints > tenant.value.quota.maxDataPoints ||
            usage.currentStorage > tenant.value.quota.maxStorage ||
            usage.currentUsers > tenant.value.quota.maxUsers) {
          logger.warning('''
资源超限警告 - 租户: ${tenant.key}
- 指标: ${usage.currentMetrics}/${tenant.value.quota.maxMetrics}
- 数据点: ${usage.currentDataPoints}/${tenant.value.quota.maxDataPoints}
- 存储: ${usage.currentStorage}/${tenant.value.quota.maxStorage}MB
- 用户: ${usage.currentUsers}/${tenant.value.quota.maxUsers}
''');
        }
      }
    });
  }
}

/// 租户状态
enum TenantStatus {
  active, // 活跃
  suspended, // 暂停
  archived, // 归档
}
