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
  String get characterCollectionBack;
  String get characterCollectionDeleteConfirm;
  String get characterCollectionDeleteMessage;
  String get characterCollectionDeleteShortcuts;
  String get characterCollectionFilterAll;

  String get characterCollectionFilterFavorite;
  String get characterCollectionFilterRecent;

  String get characterCollectionHelp;
  String get characterCollectionHelpClose;
  String get characterCollectionHelpExport;
  String get characterCollectionHelpExportSoon;
  String get characterCollectionHelpGuide;
  String get characterCollectionHelpIntro;
  String get characterCollectionHelpNotes;
  String get characterCollectionHelpSection1;
  String get characterCollectionHelpSection2;
  String get characterCollectionHelpSection3;
  String get characterCollectionHelpSection4;

  String get characterCollectionHelpSection5;
  String get characterCollectionHelpTitle;
  String get characterCollectionImageInvalid;
  String get characterCollectionImageLoadError;
  String get characterCollectionLeave;
  String get characterCollectionLoadingImage;
  String get characterCollectionNextPage;
  String get characterCollectionNoCharacter;
  String get characterCollectionNoCharacters;
  String get characterCollectionPreviewTab;
  String get characterCollectionPreviousPage;
  String get characterCollectionProcessing;
  String get characterCollectionResultsTab;
  String get characterCollectionRetry;
  String get characterCollectionReturnToDetails;
  String get characterCollectionSearchHint;
  String get characterCollectionSelectRegion;
  String get characterCollectionSwitchingPage;
  // Character Collection Page
  String get characterCollectionTitle;
  String get characterCollectionToolDelete;
  String get characterCollectionToolPan;
  String get characterCollectionToolSelect;

  String get characterCollectionUnsavedChanges;
  String get characterCollectionUnsavedChangesMessage;
  String get characterCollectionUseSelectionTool;
  String get characterEditCompletingSave;

  String get characterEditImageInvert;
  String get characterEditImageLoadError;
  String get characterEditImageLoadFailed;
  String get characterEditInitializing;
  // Character Edit Panel localization keys
  String get characterEditInputCharacter;
  String get characterEditInputHint;
  String get characterEditInvertMode;
  String get characterEditLoadingImage;

  String get characterEditNoRegionSelected;
  String get characterEditOnlyOneCharacter;
  String get characterEditPanImage;
  String get characterEditPleaseEnterCharacter;
  String get characterEditPreparingSave;
  String get characterEditProcessingEraseData;
  String get characterEditProcessingImage;
  String get characterEditRedo;
  String get characterEditSaveComplete;
  String get characterEditSaveConfirmTitle;
  String get characterEditSavePreview;
  String get characterEditSaveShortcuts;
  String get characterEditSaveTimeout;
  String get characterEditSavingToStorage;
  String get characterEditShowContour;
  String get characterEditThumbnailCheckFailed;
  String get characterEditThumbnailEmpty;
  String get characterEditThumbnailLoadError;

  String get characterEditThumbnailLoadFailed;
  String get characterEditThumbnailNotFound;
  String get characterEditThumbnailSizeError;
  String get characterEditUndo;
  String get characterEditUnknownError;
  String get characterEditValidChineseCharacter;
  String get characters;
  String get confirm;

  String get delete;
  String get edit;
  String get export;
  String get filterDateApply;

  String get filterDateClear;
  String get filterDateCustom;
  String get filterDateEndDate;
  String get filterDatePresetAll;

  String get filterDatePresetLast30Days;
  String get filterDatePresetLast365Days;
  String get filterDatePresetLast7Days;
  String get filterDatePresetLast90Days;
  String get filterDatePresetLastMonth;
  String get filterDatePresetLastWeek;
  String get filterDatePresetLastYear;
  String get filterDatePresets;
  String get filterDatePresetThisMonth;
  String get filterDatePresetThisWeek;
  String get filterDatePresetThisYear;
  // Date presets
  String get filterDatePresetToday;
  String get filterDatePresetYesterday;
  // Date section
  String get filterDateSection;
  String get filterDateSelectPrompt;
  String get filterDateStartDate;
  String get filterReset;
  String get filterSortAscending;

  String get filterSortDescending;
  String get filterSortFieldAuthor;
  String get filterSortFieldCreateTime;
  String get filterSortFieldCreationDate;

  String get filterSortFieldNone;
  String get filterSortFieldStyle;
  String get filterSortFieldTitle;
  String get filterSortFieldTool;
  String get filterSortFieldUpdateTime;
  // Sort section
  String get filterSortSection;
  String get filterStyleClerical;
  String get filterStyleCursive;
  String get filterStyleOther;
  String get filterStyleRegular;
  String get filterStyleRunning;
  String get filterStyleSeal;
  // Style section
  String get filterStyleSection;
  // Filter panel
  String get filterTitle;
  String get filterToolBrush;
  String get filterToolHardPen;
  String get filterToolOther;
  // Tool section
  String get filterToolSection;
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
  // Tag Editor
  String get tagEditorEnterTagHint;
  String get tagEditorNoTags;
  String get tagEditorSuggestedTags;
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
  String get workDetailBack;
  String get workDetailBasicInfo;
  String get workDetailCancel;
  String get workDetailCharacters;
  String get workDetailCreateTime;
  String get workDetailEdit;
  String get workDetailExtract;
  String get workDetailExtractionError;
  String get workDetailImageCount;
  String get workDetailImageLoadError;
  String get workDetailLoading;

  String get workDetailNoCharacters;
  String get workDetailNoImages;
  String get workDetailNoImagesForExtraction;
  String get workDetailNoWork;
  String get workDetailOtherInfo;

  String get workDetailSave;
  String get workDetailSaveFailure;
  String get workDetailSaveSuccess;

  String get workDetailTags;
  // Work Detail Page
  String get workDetailTitle;
  String get workDetailUnsavedChanges;
  String get workDetailUpdateTime;
  String get workDetailViewMore;
  String get workFormAuthor;

  String get workFormAuthorHelp;
  String get workFormAuthorHint;
  String get workFormAuthorMaxLength;
  String get workFormAuthorTooltip;
  String get workFormCreationDate;
  String get workFormDateHelp;
  String get workFormDateTooltip;
  String get workFormHelp;
  String get workFormNextField;
  String get workFormPreviousField;
  String get workFormRemark;
  String get workFormRemarkHelp;
  String get workFormRemarkHint;
  String get workFormRemarkMaxLength;
  String get workFormRemarkTooltip;
  String get workFormRequiredField;
  String get workFormSelectDate;
  String get workFormShortcuts;
  String get workFormStyle;
  String get workFormStyleHelp;
  String get workFormStyleTooltip;
  // Work Form
  String get workFormTitle;
  // Field help texts
  String get workFormTitleHelp;
  String get workFormTitleHint;
  String get workFormTitleMaxLength;
  String get workFormTitleMinLength;
  String get workFormTitleRequired;
  // Field tooltips
  String get workFormTitleTooltip;
  String get workFormTool;
  String get workFormToolHelp;
  String get workFormToolTooltip;
  String get workImportDialogAddImages;

  String get workImportDialogCancel;
  String get workImportDialogDeleteImage;
  String get workImportDialogDeleteImageConfirm;
  String get workImportDialogImport;
  String get workImportDialogNoImages;
  String get workImportDialogNoImagesHint;
  String get workImportDialogProcessing;
  String get workImportDialogSuccess;
  // Work Import Dialog
  String get workImportDialogTitle;
  // Navigation
  String get works;
  String get workStyleClerical;
  String get workStyleCursive;
  String get workStyleOther;
  // Work Style localization
  String get workStyleRegular;
  String get workStyleRunning;
  String get workStyleSeal;
  // Work Tool localization
  String get workToolBrush;
  String get workToolHardPen;
  String get workToolOther;
  String characterCollectionDeleteBatchConfirm(int count);
  String characterCollectionDeleteBatchMessage(int count);
  String characterCollectionError(String error);
  String characterCollectionFindSwitchFailed(String error);
  String characterEditCharacterUpdated(String character);
  String characterEditSaveConfirmMessage(String character);
  // Initialization
  String initializationFailed(String error);
  String workBrowseDeleteConfirmMessage(int count);
  String workBrowseDeleteSelected(int count);
  String workBrowseError(String message);
  String workBrowseSelectedCount(int count);
  String workImportDialogError(String error);

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
