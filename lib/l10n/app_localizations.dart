import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart';

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

AppLocalizations lookupAppLocalizations(Locale locale) {
  // 添加日志，记录本地化查找过程
  debugPrint('lookupAppLocalizations: 查找本地化资源，语言代码: ${locale.languageCode}');

  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      debugPrint('lookupAppLocalizations: 使用英文本地化资源');
      return AppLocalizationsEn();
    case 'zh':
      debugPrint('lookupAppLocalizations: 使用中文本地化资源');
      return AppLocalizationsZh();
    default:
      debugPrint(
          'lookupAppLocalizations: 未知语言代码 ${locale.languageCode}，默认使用中文本地化资源');
      return AppLocalizationsZh(); // 默认使用中文
  }
}

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
/// dev_dependencies:
///   intl_translation: ^0.17.0
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you'll need to edit this
/// file.
///
/// First, open your project's ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project's Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh')
  ];

  final String localeName;

  AppLocalizations(String locale)
      : localeName = Intl.canonicalizedLocale(locale);

  String get about;

  // App name
  String get appName;

  // Common actions
  String get cancel;
  String get characters;
  String get confirm;
  String get delete;
  String get edit;
  String get export;

  String get filterReset;
  // Filter panel
  String get filterTitle;
  // Settings
  String get generalSettings;

  String get import;
  // Language
  String get language;
  String get languageEn;
  String get languageSystem;
  String get languageZh;
  String get navCollapseSidebar;
  String get navExpandSidebar;
  String get practices;

  String get print;
  String get save;
  String get settings;
  String get storageSettings;

  // Theme
  String get themeMode;
  String get themeModeDark;
  String get themeModeLight;
  String get themeModeSystem;

  String get workBrowseBatchDone;
  String get workBrowseBatchMode;
  String get workBrowseCancel;
  String get workBrowseDelete;
  String get workBrowseDeleteConfirmTitle;
  String get workBrowseGridView;
  String get workBrowseImport;
  String get workBrowseListView;
  String get workBrowseLoading;
  String get workBrowseNoWorks;
  String get workBrowseNoWorksHint;
  String get workBrowseReload;
  String get workBrowseSearch;
  // Work browse page
  String get workBrowseTitle;
  // Navigation
  String get works;
  // Initialization
  String initializationFailed(String error);
  String workBrowseDeleteConfirmMessage(int count);
  String workBrowseDeleteSelected(int count);

  String workBrowseError(String message);
  String workBrowseSelectedCount(int count);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }
}

/// The delegate for the app's localizations.
class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    final isSupported = <String>['en', 'zh'].contains(locale.languageCode);
    debugPrint(
        '_AppLocalizationsDelegate.isSupported: 语言代码 ${locale.languageCode} ${isSupported ? "受支持" : "不受支持"}');
    return isSupported;
  }

  @override
  Future<AppLocalizations> load(Locale locale) {
    debugPrint(
        '_AppLocalizationsDelegate.load: 加载本地化资源，语言代码: ${locale.languageCode}');
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
