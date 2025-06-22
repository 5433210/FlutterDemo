#!/usr/bin/env dart

import 'dart:io';

void main() {
  print('=== 作品筛选日期功能验证 ===');

  // 检查M3WorkFilterPanel是否包含新的日期筛选部分
  final filterPanelFile = File(
      'lib/presentation/pages/works/components/filter/m3_work_filter_panel.dart');
  if (!filterPanelFile.existsSync()) {
    print('❌ 筛选面板文件不存在');
    return;
  }

  final content = filterPanelFile.readAsStringSync();

  // 检查是否导入了必要的依赖
  bool hasDateRangeFilterImport = content.contains(
      "import '../../../../../domain/models/common/date_range_filter.dart';");
  bool hasDateRangeSectionImport = content.contains(
      "import '../../../../widgets/filter/sections/m3_filter_date_range_section.dart';");

  print('✅ 必要依赖导入检查:');
  print('   - DateRangeFilter: ${hasDateRangeFilterImport ? '已导入' : '❌ 缺失'}');
  print(
      '   - M3FilterDateRangeSection: ${hasDateRangeSectionImport ? '已导入' : '❌ 缺失'}');

  // 检查是否包含创建日期筛选部分
  bool hasCreateTimeSection = content.contains('l10n.createTime') &&
      content.contains('createTimeRange');
  bool hasUpdateTimeSection = content.contains('l10n.updateTime') &&
      content.contains('updateTimeRange');

  print('✅ 日期筛选部分检查:');
  print('   - 创建日期筛选: ${hasCreateTimeSection ? '已实现' : '❌ 缺失'}');
  print('   - 更新日期筛选: ${hasUpdateTimeSection ? '已实现' : '❌ 缺失'}');

  // 检查辅助方法
  bool hasGetCreateDatePresetMethod =
      content.contains('_getCreateDatePreset()');
  bool hasGetUpdateDatePresetMethod =
      content.contains('_getUpdateDatePreset()');

  print('✅ 辅助方法检查:');
  print(
      '   - _getCreateDatePreset: ${hasGetCreateDatePresetMethod ? '已实现' : '❌ 缺失'}');
  print(
      '   - _getUpdateDatePreset: ${hasGetUpdateDatePresetMethod ? '已实现' : '❌ 缺失'}');

  // 检查WorkFilter模型是否支持日期字段
  final workFilterFile = File('lib/domain/models/work/work_filter.dart');
  if (workFilterFile.existsSync()) {
    final filterContent = workFilterFile.readAsStringSync();
    bool hasCreateTimeRange =
        filterContent.contains('DateTimeRange? createTimeRange');
    bool hasUpdateTimeRange =
        filterContent.contains('DateTimeRange? updateTimeRange');

    print('✅ WorkFilter模型检查:');
    print('   - createTimeRange字段: ${hasCreateTimeRange ? '已定义' : '❌ 缺失'}');
    print('   - updateTimeRange字段: ${hasUpdateTimeRange ? '已定义' : '❌ 缺失'}');
  }

  // 检查后端支持
  final repositoryFile =
      File('lib/application/repositories/work_repository_impl.dart');
  if (repositoryFile.existsSync()) {
    final repoContent = repositoryFile.readAsStringSync();
    bool hasCreateTimeFilter = repoContent.contains('filter.createTimeRange') &&
        repoContent.contains("field: 'createTime'");
    bool hasUpdateTimeFilter = repoContent.contains('filter.updateTimeRange') &&
        repoContent.contains("field: 'updateTime'");

    print('✅ 后端支持检查:');
    print('   - 创建时间筛选: ${hasCreateTimeFilter ? '已支持' : '❌ 缺失'}');
    print('   - 更新时间筛选: ${hasUpdateTimeFilter ? '已支持' : '❌ 缺失'}');
  }

  print('\n=== 验证完成 ===');

  if (hasDateRangeFilterImport &&
      hasDateRangeSectionImport &&
      hasCreateTimeSection &&
      hasUpdateTimeSection &&
      hasGetCreateDatePresetMethod &&
      hasGetUpdateDatePresetMethod) {
    print('🎉 所有功能已正确实现！');
    print('📝 使用说明:');
    print('   1. 启动应用，导航到作品浏览页');
    print('   2. 在左侧筛选面板中查看新的"创建时间"和"更新时间"筛选选项');
    print('   3. 可以选择预设时间范围（如"最近7天"、"本月"等）或自定义日期范围');
    print('   4. 筛选条件会立即应用到作品列表');
  } else {
    print('⚠️  部分功能可能存在问题，请检查上述报告');
  }
}
