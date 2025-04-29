import 'app_localizations.dart';

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get about => '关于';

  @override
  String get appName => '书法集字';

  @override
  String get cancel => '取消';

  @override
  String get characters => '集字';

  @override
  String get confirm => '确定';

  @override
  String get delete => '删除';

  @override
  String get edit => '编辑';

  @override
  String get export => '导出';

  @override
  String get filterDateApply => '应用';

  @override
  String get filterDateClear => '清除';

  @override
  String get filterDateCustom => '自定义';

  @override
  String get filterDateEndDate => '结束日期';

  @override
  String get filterDatePresetAll => '全部时间';

  @override
  String get filterDatePresetLast30Days => '最近30天';

  @override
  String get filterDatePresetLast365Days => '最近一年';

  @override
  String get filterDatePresetLast7Days => '最近7天';

  @override
  String get filterDatePresetLast90Days => '最近90天';

  @override
  String get filterDatePresetLastMonth => '上月';

  @override
  String get filterDatePresetLastWeek => '上周';

  @override
  String get filterDatePresetLastYear => '去年';

  @override
  String get filterDatePresets => '预设';

  @override
  String get filterDatePresetThisMonth => '本月';

  @override
  String get filterDatePresetThisWeek => '本周';

  @override
  String get filterDatePresetThisYear => '今年';

  @override
  String get filterDatePresetToday => '今天';

  @override
  String get filterDatePresetYesterday => '昨天';

  @override
  String get filterDateSection => '创作时间';

  @override
  String get filterDateSelectPrompt => '点击选择日期';

  @override
  String get filterDateStartDate => '开始日期';

  @override
  String get filterReset => '重置筛选条件';

  @override
  String get filterSortAscending => '升序';

  @override
  String get filterSortDescending => '降序';

  @override
  String get filterSortFieldAuthor => '作者';

  @override
  String get filterSortFieldCreateTime => '创建时间';

  @override
  String get filterSortFieldCreationDate => '创作日期';

  @override
  String get filterSortFieldNone => '无';

  @override
  String get filterSortFieldStyle => '风格';

  @override
  String get filterSortFieldTitle => '标题';

  @override
  String get filterSortFieldTool => '工具';

  @override
  String get filterSortFieldUpdateTime => '更新时间';

  @override
  String get filterSortSection => '排序';

  @override
  String get filterStyleClerical => '隶书';

  @override
  String get filterStyleCursive => '草书';

  @override
  String get filterStyleOther => '其他';

  @override
  String get filterStyleRegular => '楷书';

  @override
  String get filterStyleRunning => '行书';

  @override
  String get filterStyleSeal => '篆书';

  @override
  String get filterStyleSection => '书法风格';

  @override
  String get filterTitle => '筛选与排序';

  @override
  String get filterToolBrush => '毛笔';

  @override
  String get filterToolHardPen => '硬笔';

  @override
  String get filterToolOther => '其他';

  @override
  String get filterToolSection => '书写工具';

  @override
  String get generalSettings => '常规设置';

  @override
  String get import => '导入';

  @override
  String get language => '语言';

  @override
  String get languageEn => 'English';

  @override
  String get languageSystem => '跟随系统';

  @override
  String get languageZh => '简体中文';

  @override
  String get navCollapseSidebar => '收起侧边栏';

  @override
  String get navExpandSidebar => '展开侧边栏';

  @override
  String get practices => '字帖';

  @override
  String get print => '打印';

  @override
  String get save => '保存';

  @override
  String get settings => '设置';

  @override
  String get storageSettings => '存储设置';

  @override
  String get themeMode => '主题模式';

  @override
  String get themeModeDark => '暗黑模式';

  @override
  String get themeModeLight => '明亮模式';

  @override
  String get themeModeSystem => '跟随系统';

  @override
  String get workBrowseBatchDone => '完成';

  @override
  String get workBrowseBatchMode => '批量处理';

  @override
  String get workBrowseCancel => '取消';

  @override
  String get workBrowseDelete => '删除';

  @override
  String get workBrowseDeleteConfirmTitle => '确认删除';

  @override
  String get workBrowseGridView => '网格视图';

  @override
  String get workBrowseImport => '导入作品';

  @override
  String get workBrowseListView => '列表视图';

  @override
  String get workBrowseLoading => '正在加载作品...';

  @override
  String get workBrowseNoWorks => '没有找到作品';

  @override
  String get workBrowseNoWorksHint => '尝试导入新作品或修改筛选条件';

  @override
  String get workBrowseReload => '重新加载';

  @override
  String get workBrowseSearch => '搜索作品...';

  @override
  String get workBrowseTitle => '作品';

  @override
  String get works => '作品';

  @override
  String initializationFailed(String error) => '初始化失败: $error';

  @override
  String workBrowseDeleteConfirmMessage(int count) =>
      '确定要删除选中的 $count 个作品吗？此操作不可恢复。';

  @override
  String workBrowseDeleteSelected(int count) => '删除$count项';

  @override
  String workBrowseError(String message) => '发生错误: $message';

  @override
  String workBrowseSelectedCount(int count) => '已选择 $count 项';
}
