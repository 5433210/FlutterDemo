import 'app_localizations.dart';

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Calligraphy Collection';

  @override
  String get works => 'Works';

  @override
  String get characters => 'Characters';

  @override
  String get practices => 'Practices';

  @override
  String get settings => 'Settings';

  @override
  String get navExpandSidebar => 'Expand Sidebar';

  @override
  String get navCollapseSidebar => 'Collapse Sidebar';

  @override
  String get generalSettings => 'General Settings';

  @override
  String get storageSettings => 'Storage Settings';

  @override
  String get about => 'About';

  @override
  String get cancel => 'Cancel';

  @override
  String get confirm => 'Confirm';

  @override
  String get save => 'Save';

  @override
  String get edit => 'Edit';

  @override
  String get delete => 'Delete';

  @override
  String get export => 'Export';

  @override
  String get import => 'Import';

  @override
  String get print => 'Print';

  @override
  String get themeMode => 'Theme Mode';

  @override
  String get themeModeSystem => 'System';

  @override
  String get themeModeLight => 'Light';

  @override
  String get themeModeDark => 'Dark';

  @override
  String get language => 'Language';

  @override
  String get languageSystem => 'System';

  @override
  String get languageZh => '简体中文';

  @override
  String get languageEn => 'English';

  @override
  String get workBrowseTitle => 'Works';

  @override
  String get workBrowseImport => 'Import Work';

  @override
  String get workBrowseBatchMode => 'Batch Mode';

  @override
  String get workBrowseBatchDone => 'Done';

  @override
  String workBrowseSelectedCount(int count) => '$count selected';

  @override
  String workBrowseDeleteSelected(int count) => 'Delete $count';

  @override
  String get workBrowseSearch => 'Search works...';

  @override
  String get workBrowseGridView => 'Grid View';

  @override
  String get workBrowseListView => 'List View';

  @override
  String get workBrowseDeleteConfirmTitle => 'Confirm Deletion';

  @override
  String workBrowseDeleteConfirmMessage(int count) => 'Are you sure you want to delete $count selected works? This action cannot be undone.';

  @override
  String get workBrowseCancel => 'Cancel';

  @override
  String get workBrowseDelete => 'Delete';

  @override
  String get workBrowseLoading => 'Loading works...';

  @override
  String workBrowseError(String message) => 'Error: $message';

  @override
  String get workBrowseReload => 'Reload';

  @override
  String get workBrowseNoWorks => 'No works found';

  @override
  String get workBrowseNoWorksHint => 'Try importing new works or changing filters';

  @override
  String get filterTitle => 'Filter & Sort';

  @override
  String get filterReset => 'Reset Filters';

  @override
  String initializationFailed(String error) => 'Initialization failed: $error';
}
