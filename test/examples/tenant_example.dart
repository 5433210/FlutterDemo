import 'dart:async';

import '../utils/monitor_auth.dart';
import '../utils/tenant_manager.dart';

Future<void> main() async {
  print('多租户系统示例开始...\n');

  final tenantManager = TenantManager();

  // 1. 创建租户
  print('1. 创建租户...');

  const basicTenant = TenantConfig(
    id: 'tenant1',
    name: '基础租户',
    quota: ResourceQuota(
      maxMetrics: 50,
      maxDataPoints: 100000,
      maxStorage: 512,
      maxUsers: 5,
    ),
    permissions: {AccessLevel.read, AccessLevel.write},
  );

  const premiumTenant = TenantConfig(
    id: 'tenant2',
    name: '高级租户',
    quota: ResourceQuota(
      maxMetrics: 200,
      maxDataPoints: 1000000,
      maxStorage: 2048,
      maxUsers: 20,
    ),
    permissions: {
      AccessLevel.read,
      AccessLevel.write,
      AccessLevel.admin,
    },
  );

  await tenantManager.createTenant(basicTenant);
  await tenantManager.createTenant(premiumTenant);

  // 2. 列出所有租户
  print('\n2. 列出所有租户:');
  for (final tenant in tenantManager.listTenants()) {
    print('''
租户: ${tenant.id}
- 名称: ${tenant.name}
- 状态: ${tenant.status}
- 配额: ${tenant.quota.toJson()}
- 权限: ${tenant.permissions}
''');
  }

  // 3. 更新资源使用
  print('\n3. 更新资源使用...');
  tenantManager.updateResourceUsage(
    'tenant1',
    metrics: 30,
    dataPoints: 50000,
    storage: 256,
    users: 3,
  );

  tenantManager.updateResourceUsage(
    'tenant2',
    metrics: 150,
    dataPoints: 750000,
    storage: 1536,
    users: 15,
  );

  // 4. 检查资源使用
  print('\n4. 检查资源使用:');
  for (final tenant in tenantManager.listTenants()) {
    final usage = tenantManager.getResourceUsage(tenant.id);
    if (usage != null) {
      print('''
租户: ${tenant.id}
资源使用情况:
- 指标: ${usage.currentMetrics}/${tenant.quota.maxMetrics}
- 数据点: ${usage.currentDataPoints}/${tenant.quota.maxDataPoints}
- 存储: ${usage.currentStorage}/${tenant.quota.maxStorage}MB
- 用户: ${usage.currentUsers}/${tenant.quota.maxUsers}
''');
    }
  }

  // 5. 验证资源限制
  print('\n5. 验证资源限制...');
  final tenant1 = tenantManager.getTenant('tenant1');
  if (tenant1 != null) {
    final canAddMetrics = tenantManager.validateResourceUsage(
      'tenant1',
      additionalMetrics: 30,
    );
    print('基础租户能否添加30个指标: ${canAddMetrics ? '是' : '否'}');

    final canAddStorage = tenantManager.validateResourceUsage(
      'tenant1',
      additionalStorage: 512,
    );
    print('基础租户能否添加512MB存储: ${canAddStorage ? '是' : '否'}');
  }

  // 6. 测试认证
  print('\n6. 测试认证...');
  final authManager = tenantManager.getAuthManager('tenant1');
  if (authManager != null) {
    final token = await authManager.generateToken('user1', 'pass123');
    if (token != null) {
      print('生成令牌: ${token.token}');

      final hasReadAccess = authManager.verifyToken(
        token.token,
        {AccessLevel.read},
      );
      print('读取权限: ${hasReadAccess ? '有' : '无'}');

      authManager.revokeToken(token.token);
      print('令牌已吊销');
    }
  }

  // 7. 修改租户状态
  print('\n7. 修改租户状态...');
  await tenantManager.updateTenant(
    'tenant1',
    TenantConfig(
      id: 'tenant1',
      name: '基础租户(已暂停)',
      status: TenantStatus.suspended,
      quota: basicTenant.quota,
      permissions: basicTenant.permissions,
    ),
  );

  print('\n当前活跃租户:');
  for (final tenant in tenantManager.listTenants(activeOnly: true)) {
    print('- ${tenant.name} (${tenant.id})');
  }

  // 8. 删除租户
  print('\n8. 删除租户...');
  await tenantManager.deleteTenant('tenant1');
  print('剩余租户数: ${tenantManager.listTenants().length}');

  // 清理
  tenantManager.dispose();
  print('\n示例完成!\n');

  print('''
主要功能演示:
1. 租户管理
   - 创建/更新/删除租户
   - 状态管理
   - 配置管理

2. 资源配额
   - 资源限制
   - 使用跟踪
   - 超限检查

3. 认证集成
   - 租户认证
   - 权限控制
   - 令牌管理

使用说明:
1. 创建租户:
   final config = TenantConfig(...)
   await tenantManager.createTenant(config)

2. 管理资源:
   tenantManager.updateResourceUsage(...)
   tenantManager.validateResourceUsage(...)

3. 认证控制:
   final auth = tenantManager.getAuthManager(id)
   await auth.generateToken(...)
''');
}
