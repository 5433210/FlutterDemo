 日期时间字段UTC迁移方案

1. 概述
将所有表的日期时间字段从时间戳(INTEGER)改为UTC格式的ISO8601字符串(TEXT)存储，统一日期时间处理。

2. 技术决策
2.1 存储格式
采用UTC时间，格式为YYYY-MM-DDThh:mm:ssZ
使用TEXT类型存储
统一使用Z后缀表示UTC时间
2.2 优势
避免多时区数据不一致
简化日期时间处理逻辑
提高数据可读性
支持完整的日期时间信息
3. 实施方案
3.1 基础设施
class DateTimeHelper {
  static String toStorageFormat(DateTime? dateTime);
  static DateTime? fromStorageFormat(String? utcString);
  static String? timestampToUtc(int? timestamp);
}
3.2 数据库迁移
添加新列
转换现有数据
替换原有列
更新触发器
创建索引
3.3 代码适配
更新所有Repository实现
修改查询条件构建逻辑
调整测试用例
4. 应用层使用指南
4.1 日期时间处理
// 创建新记录时
work = work.copyWith(
  createTime: DateTime.now(), // 使用本地时间
  updateTime: DateTime.now(),
);
// Repository会自动转换为UTC存储

// 读取记录时
final work = await repository.get(id);
print(work.createTime); // 自动转换为本地时间显示
4.2 日期范围查询
// 按创建日期筛选
final filter = WorkFilter(
  dateRange: DateTimeRange(
    start: DateTime(2025, 3, 1), // 使用本地时间
    end: DateTime(2025, 3, 31),
  ),
);
// Repository会自动处理时区转换

// 获取今天的数据
final today = DateTime.now();
final start = DateTime(today.year, today.month, today.day);
final end = start.add(Duration(days: 1));
4.3 相对时间处理
// 获取最近7天数据
final end = DateTime.now();
final start = end.subtract(Duration(days: 7));

// 获取本月数据
final now = DateTime.now();
final start = DateTime(now.year, now.month, 1);
final end = DateTime(now.year, now.month + 1, 1);
4.4 注意事项
DateTime默认使用本地时区
日期比较要考虑时区影响
界面显示应使用本地时间
存储和查询自动处理UTC转换
跨天统计要注意时区边界
5. 迁移步骤
创建DateTimeHelper工具类
执行数据库迁移脚本
更新Repository实现
修改应用层代码
进行完整测试
6. 回滚预案
保留原有时间字段
准备回滚脚本
验证数据一致性
7. 验收标准
所有日期时间字段采用UTC格式
现有功能正常工作
跨时区数据处理正确
性能符合要求 </new_file>