import 'app_localizations.dart';

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get about => 'About';

  @override
  String get appName => 'Calligraphy Collection';

  @override
  String get cancel => 'Cancel';

  @override
  String get characters => 'Characters';

  @override
  String get confirm => 'Confirm';

  @override
  String get delete => 'Delete';

  @override
  String get edit => 'Edit';

  @override
  String get export => 'Export';

  @override
  String get filterDateApply => 'Apply';

  @override
  String get filterDateClear => 'Clear';

  @override
  String get filterDateCustom => 'Custom';

  @override
  String get filterDateEndDate => 'End Date';

  @override
  String get filterDatePresetAll => 'All Time';

  @override
  String get filterDatePresetLast30Days => 'Last 30 Days';

  @override
  String get filterDatePresetLast365Days => 'Last 365 Days';

  @override
  String get filterDatePresetLast7Days => 'Last 7 Days';

  @override
  String get filterDatePresetLast90Days => 'Last 90 Days';

  @override
  String get filterDatePresetLastMonth => 'Last Month';

  @override
  String get filterDatePresetLastWeek => 'Last Week';

  @override
  String get filterDatePresetLastYear => 'Last Year';

  @override
  String get filterDatePresets => 'Presets';

  @override
  String get filterDatePresetThisMonth => 'This Month';

  @override
  String get filterDatePresetThisWeek => 'This Week';

  @override
  String get filterDatePresetThisYear => 'This Year';

  @override
  String get filterDatePresetToday => 'Today';

  @override
  String get filterDatePresetYesterday => 'Yesterday';

  @override
  String get filterDateSection => 'Creation Time';

  @override
  String get filterDateSelectPrompt => 'Select Date';

  @override
  String get filterDateStartDate => 'Start Date';

  @override
  String get filterReset => 'Reset Filters';

  @override
  String get filterSortAscending => 'Ascending';

  @override
  String get filterSortDescending => 'Descending';

  @override
  String get filterSortFieldAuthor => 'Author';

  @override
  String get filterSortFieldCreateTime => 'Create Time';

  @override
  String get filterSortFieldCreationDate => 'Creation Date';

  @override
  String get filterSortFieldNone => 'None';

  @override
  String get filterSortFieldStyle => 'Style';

  @override
  String get filterSortFieldTitle => 'Title';

  @override
  String get filterSortFieldTool => 'Tool';

  @override
  String get filterSortFieldUpdateTime => 'Update Time';

  @override
  String get filterSortSection => 'Sort';

  @override
  String get filterStyleClerical => 'Clerical Script';

  @override
  String get filterStyleCursive => 'Cursive Script';

  @override
  String get filterStyleOther => 'Other';

  @override
  String get filterStyleRegular => 'Regular Script';

  @override
  String get filterStyleRunning => 'Running Script';

  @override
  String get filterStyleSeal => 'Seal Script';

  @override
  String get filterStyleSection => 'Calligraphy Style';

  @override
  String get filterTitle => 'Filter & Sort';

  @override
  String get filterToolBrush => 'Brush';

  @override
  String get filterToolHardPen => 'Hard Pen';

  @override
  String get filterToolOther => 'Other';

  @override
  String get filterToolSection => 'Writing Tool';

  @override
  String get generalSettings => 'General Settings';

  @override
  String get import => 'Import';

  @override
  String get language => 'Language';

  @override
  String get languageEn => 'English';

  @override
  String get languageSystem => 'System';

  @override
  String get languageZh => '简体中文';

  @override
  String get navCollapseSidebar => 'Collapse Sidebar';

  @override
  String get navExpandSidebar => 'Expand Sidebar';

  @override
  String get practices => 'Practices';

  @override
  String get print => 'Print';

  @override
  String get save => 'Save';

  @override
  String get settings => 'Settings';

  @override
  String get storageSettings => 'Storage Settings';

  @override
  String get themeMode => 'Theme Mode';

  @override
  String get themeModeDark => 'Dark';

  @override
  String get themeModeLight => 'Light';

  @override
  String get themeModeSystem => 'System';

  @override
  String get workBrowseBatchDone => 'Done';

  @override
  String get workBrowseBatchMode => 'Batch Mode';

  @override
  String get workBrowseCancel => 'Cancel';

  @override
  String get workBrowseDelete => 'Delete';

  @override
  String get workBrowseDeleteConfirmTitle => 'Confirm Deletion';

  @override
  String get workBrowseGridView => 'Grid View';

  @override
  String get workBrowseImport => 'Import Work';

  @override
  String get workBrowseListView => 'List View';

  @override
  String get workBrowseLoading => 'Loading works...';

  @override
  String get workBrowseNoWorks => 'No works found';

  @override
  String get workBrowseNoWorksHint =>
      'Try importing new works or changing filters';

  @override
  String get workBrowseReload => 'Reload';

  @override
  String get workBrowseSearch => 'Search works...';

  @override
  String get workBrowseTitle => 'Works';

  @override
  String get works => 'Works';

  @override
  String initializationFailed(String error) => 'Initialization failed: $error';

  @override
  String workBrowseDeleteConfirmMessage(int count) =>
      'Are you sure you want to delete $count selected works? This action cannot be undone.';

  @override
  String workBrowseDeleteSelected(int count) => 'Delete $count';

  @override
  String workBrowseError(String message) => 'Error: $message';

  @override
  String workBrowseSelectedCount(int count) => '$count selected';
}
