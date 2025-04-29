import 'app_localizations.dart';

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appName => '书法集字';

  @override
  String get works => '作品';

  @override
  String get characters => '集字';

  @override
  String get practices => '字帖';

  @override
  String get settings => '设置';

  @override
  String get navExpandSidebar => '展开侧边栏';

  @override
  String get navCollapseSidebar => '收起侧边栏';

  @override
  String get generalSettings => '常规设置';

  @override
  String get storageSettings => '存储设置';

  @override
  String get about => '关于';

  @override
  String get cancel => '取消';

  @override
  String get confirm => '确定';

  @override
  String get save => '保存';

  @override
  String get edit => '编辑';

  @override
  String get delete => '删除';

  @override
  String get export => '导出';

  @override
  String get import => '导入';

  @override
  String get print => '打印';

  @override
  String get themeMode => '主题模式';

  @override
  String get themeModeSystem => '跟随系统';

  @override
  String get themeModeLight => '明亮模式';

  @override
  String get themeModeDark => '暗黑模式';

  @override
  String get language => '语言';

  @override
  String get languageSystem => '跟随系统';

  @override
  String get languageZh => '简体中文';

  @override
  String get languageEn => 'English';

  @override
  String get workBrowseTitle => '作品';

  @override
  String get workBrowseImport => '导入作品';

  @override
  String get workBrowseBatchMode => '批量处理';

  @override
  String get workBrowseBatchDone => '完成';

  @override
  String workBrowseSelectedCount(int count) => '已选择 $count 项';

  @override
  String workBrowseDeleteSelected(int count) => '删除${count}项';

  @override
  String get workBrowseSearch => '搜索作品...';

  @override
  String get workBrowseGridView => '网格视图';

  @override
  String get workBrowseListView => '列表视图';

  @override
  String get workBrowseDeleteConfirmTitle => '确认删除';

  @override
  String workBrowseDeleteConfirmMessage(int count) => '确定要删除选中的 $count 个作品吗？此操作不可恢复。';

  @override
  String get workBrowseCancel => '取消';

  @override
  String get workBrowseDelete => '删除';

  @override
  String get workBrowseLoading => '正在加载作品...';

  @override
  String workBrowseError(String message) => '发生错误: $message';

  @override
  String get workBrowseReload => '重新加载';

  @override
  String get workBrowseNoWorks => '没有找到作品';

  @override
  String get workBrowseNoWorksHint => '尝试导入新作品或修改筛选条件';

  @override
  String get filterTitle => '筛选与排序';

  @override
  String get filterReset => '重置筛选条件';

  @override
  String initializationFailed(String error) => '初始化失败: $error';
}
