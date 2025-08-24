import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_ko.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

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
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
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
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

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
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ja'),
    Locale('ko'),
    Locale('zh'),
    Locale('zh', 'TW')
  ];

  /// No description provided for @a4Size.
  ///
  /// In en, this message translates to:
  /// **'A4 (210×297mm)'**
  String get a4Size;

  /// No description provided for @a5Size.
  ///
  /// In en, this message translates to:
  /// **'A5 (148×210mm)'**
  String get a5Size;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @activated.
  ///
  /// In en, this message translates to:
  /// **'Activated'**
  String get activated;

  /// No description provided for @activatedDescription.
  ///
  /// In en, this message translates to:
  /// **'Activated - Show in selector'**
  String get activatedDescription;

  /// No description provided for @activeStatus.
  ///
  /// In en, this message translates to:
  /// **'Active Status'**
  String get activeStatus;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @addCategory.
  ///
  /// In en, this message translates to:
  /// **'Add Category'**
  String get addCategory;

  /// No description provided for @addCategoryItem.
  ///
  /// In en, this message translates to:
  /// **'Add {category}'**
  String addCategoryItem(Object category);

  /// No description provided for @addConfigItem.
  ///
  /// In en, this message translates to:
  /// **'Add Configuration Item'**
  String get addConfigItem;

  /// No description provided for @addConfigItemHint.
  ///
  /// In en, this message translates to:
  /// **'Tap the button in the bottom right corner to add {category} configuration items'**
  String addConfigItemHint(Object category);

  /// No description provided for @addFavorite.
  ///
  /// In en, this message translates to:
  /// **'Add to Favorites'**
  String get addFavorite;

  /// No description provided for @addFromGalleryFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to add image from gallery: {error}'**
  String addFromGalleryFailed(Object error);

  /// No description provided for @addImage.
  ///
  /// In en, this message translates to:
  /// **'Add Image'**
  String get addImage;

  /// No description provided for @addImageHint.
  ///
  /// In en, this message translates to:
  /// **'Tap to add image'**
  String get addImageHint;

  /// No description provided for @addImages.
  ///
  /// In en, this message translates to:
  /// **'Add Images'**
  String get addImages;

  /// No description provided for @addLayer.
  ///
  /// In en, this message translates to:
  /// **'Add Layer'**
  String get addLayer;

  /// No description provided for @addTag.
  ///
  /// In en, this message translates to:
  /// **'Add Tag'**
  String get addTag;

  /// No description provided for @addWork.
  ///
  /// In en, this message translates to:
  /// **'Add Work'**
  String get addWork;

  /// No description provided for @addedToCategory.
  ///
  /// In en, this message translates to:
  /// **'Added to Category'**
  String get addedToCategory;

  /// No description provided for @addingImagesToGallery.
  ///
  /// In en, this message translates to:
  /// **'Adding {count} local images to gallery...'**
  String addingImagesToGallery(Object count);

  /// No description provided for @adjust.
  ///
  /// In en, this message translates to:
  /// **'Adjust'**
  String get adjust;

  /// No description provided for @adjustGridSize.
  ///
  /// In en, this message translates to:
  /// **'Adjust Grid Size'**
  String get adjustGridSize;

  /// No description provided for @afterDate.
  ///
  /// In en, this message translates to:
  /// **'After a Certain Date'**
  String get afterDate;

  /// No description provided for @alignBottom.
  ///
  /// In en, this message translates to:
  /// **'Align Bottom'**
  String get alignBottom;

  /// No description provided for @alignCenter.
  ///
  /// In en, this message translates to:
  /// **'Align Center'**
  String get alignCenter;

  /// No description provided for @alignHorizontalCenter.
  ///
  /// In en, this message translates to:
  /// **'Align Horizontal Center'**
  String get alignHorizontalCenter;

  /// No description provided for @alignLeft.
  ///
  /// In en, this message translates to:
  /// **'Align Left'**
  String get alignLeft;

  /// No description provided for @alignMiddle.
  ///
  /// In en, this message translates to:
  /// **'Align Middle'**
  String get alignMiddle;

  /// No description provided for @alignRight.
  ///
  /// In en, this message translates to:
  /// **'Align Right'**
  String get alignRight;

  /// No description provided for @alignTop.
  ///
  /// In en, this message translates to:
  /// **'Align Top'**
  String get alignTop;

  /// No description provided for @alignVerticalCenter.
  ///
  /// In en, this message translates to:
  /// **'Align Vertical Center'**
  String get alignVerticalCenter;

  /// No description provided for @alignment.
  ///
  /// In en, this message translates to:
  /// **'Alignment'**
  String get alignment;

  /// No description provided for @alignmentAssist.
  ///
  /// In en, this message translates to:
  /// **'Alignment Assist'**
  String get alignmentAssist;

  /// No description provided for @alignmentCenter.
  ///
  /// In en, this message translates to:
  /// **'Center'**
  String get alignmentCenter;

  /// No description provided for @alignmentGrid.
  ///
  /// In en, this message translates to:
  /// **'Grid Snapping Mode - Tap to Switch to Guideline Alignment'**
  String get alignmentGrid;

  /// No description provided for @alignmentGuideline.
  ///
  /// In en, this message translates to:
  /// **'Guideline Alignment Mode - Tap to Switch to No Assist'**
  String get alignmentGuideline;

  /// No description provided for @alignmentNone.
  ///
  /// In en, this message translates to:
  /// **'No Assist Alignment - Tap to Enable Grid Snapping'**
  String get alignmentNone;

  /// No description provided for @alignmentOperations.
  ///
  /// In en, this message translates to:
  /// **'Alignment Operations'**
  String get alignmentOperations;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @allBackupsDeleteWarning.
  ///
  /// In en, this message translates to:
  /// **'This action cannot be undone! All backup data will be permanently lost.'**
  String get allBackupsDeleteWarning;

  /// No description provided for @allCategories.
  ///
  /// In en, this message translates to:
  /// **'All Categories'**
  String get allCategories;

  /// No description provided for @allPages.
  ///
  /// In en, this message translates to:
  /// **'All Pages'**
  String get allPages;

  /// No description provided for @allTime.
  ///
  /// In en, this message translates to:
  /// **'All Time'**
  String get allTime;

  /// No description provided for @allTypes.
  ///
  /// In en, this message translates to:
  /// **'All Types'**
  String get allTypes;

  /// No description provided for @analyzePathInfoFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to analyze path information'**
  String get analyzePathInfoFailed;

  /// No description provided for @appRestartFailed.
  ///
  /// In en, this message translates to:
  /// **'App Restart Failed, Please Manually Restart the App'**
  String get appRestartFailed;

  /// No description provided for @appRestarting.
  ///
  /// In en, this message translates to:
  /// **'Restarting App'**
  String get appRestarting;

  /// No description provided for @appRestartingMessage.
  ///
  /// In en, this message translates to:
  /// **'Data Recovery Successful, Restarting App...'**
  String get appRestartingMessage;

  /// No description provided for @appStartupFailed.
  ///
  /// In en, this message translates to:
  /// **'App Startup Failed'**
  String get appStartupFailed;

  /// No description provided for @appStartupFailedWith.
  ///
  /// In en, this message translates to:
  /// **'App startup failed: {error}'**
  String appStartupFailedWith(Object error);

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Char As Gem'**
  String get appTitle;

  /// No description provided for @appVersion.
  ///
  /// In en, this message translates to:
  /// **'App Version'**
  String get appVersion;

  /// No description provided for @appVersionInfo.
  ///
  /// In en, this message translates to:
  /// **'App Version Info'**
  String get appVersionInfo;

  /// No description provided for @appWillRestartAfterRestore.
  ///
  /// In en, this message translates to:
  /// **'The app will restart automatically after restore.'**
  String get appWillRestartAfterRestore;

  /// No description provided for @appWillRestartInSeconds.
  ///
  /// In en, this message translates to:
  /// **'{message}\nApp will restart automatically in 3 seconds...'**
  String appWillRestartInSeconds(Object message);

  /// No description provided for @appWillRestartMessage.
  ///
  /// In en, this message translates to:
  /// **'Application will restart automatically after restore.'**
  String get appWillRestartMessage;

  /// No description provided for @apply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get apply;

  /// No description provided for @applyFormatBrush.
  ///
  /// In en, this message translates to:
  /// **'Apply Format Brush (Alt+W)'**
  String get applyFormatBrush;

  /// No description provided for @applyNewPath.
  ///
  /// In en, this message translates to:
  /// **'Apply New Path'**
  String get applyNewPath;

  /// No description provided for @applyTransform.
  ///
  /// In en, this message translates to:
  /// **'Apply Transform'**
  String get applyTransform;

  /// No description provided for @ascending.
  ///
  /// In en, this message translates to:
  /// **'Ascending'**
  String get ascending;

  /// No description provided for @askUser.
  ///
  /// In en, this message translates to:
  /// **'Ask User'**
  String get askUser;

  /// No description provided for @askUserDescription.
  ///
  /// In en, this message translates to:
  /// **'Ask user for each conflict'**
  String get askUserDescription;

  /// No description provided for @author.
  ///
  /// In en, this message translates to:
  /// **'Author'**
  String get author;

  /// No description provided for @autoBackup.
  ///
  /// In en, this message translates to:
  /// **'Auto Backup'**
  String get autoBackup;

  /// No description provided for @autoBackupDescription.
  ///
  /// In en, this message translates to:
  /// **'Regularly Automatically Back Up Your Data'**
  String get autoBackupDescription;

  /// No description provided for @autoBackupInterval.
  ///
  /// In en, this message translates to:
  /// **'Auto Backup Interval'**
  String get autoBackupInterval;

  /// No description provided for @autoBackupIntervalDescription.
  ///
  /// In en, this message translates to:
  /// **'Frequency of Auto Backups'**
  String get autoBackupIntervalDescription;

  /// No description provided for @autoCleanup.
  ///
  /// In en, this message translates to:
  /// **'Auto Cleanup'**
  String get autoCleanup;

  /// No description provided for @autoCleanupDescription.
  ///
  /// In en, this message translates to:
  /// **'Automatically Clean Up Old Cache Files'**
  String get autoCleanupDescription;

  /// No description provided for @autoCleanupInterval.
  ///
  /// In en, this message translates to:
  /// **'Auto Cleanup Interval'**
  String get autoCleanupInterval;

  /// No description provided for @autoCleanupIntervalDescription.
  ///
  /// In en, this message translates to:
  /// **'Frequency of Auto Cleanup'**
  String get autoCleanupIntervalDescription;

  /// No description provided for @autoDetect.
  ///
  /// In en, this message translates to:
  /// **'Auto Detect'**
  String get autoDetect;

  /// No description provided for @autoDetectPageOrientation.
  ///
  /// In en, this message translates to:
  /// **'Auto Detect Page Orientation'**
  String get autoDetectPageOrientation;

  /// No description provided for @autoLineBreak.
  ///
  /// In en, this message translates to:
  /// **'Auto Line Break'**
  String get autoLineBreak;

  /// No description provided for @autoLineBreakDisabled.
  ///
  /// In en, this message translates to:
  /// **'Auto Line Break Disabled'**
  String get autoLineBreakDisabled;

  /// No description provided for @autoLineBreakEnabled.
  ///
  /// In en, this message translates to:
  /// **'Auto Line Break Enabled'**
  String get autoLineBreakEnabled;

  /// No description provided for @availableCharacters.
  ///
  /// In en, this message translates to:
  /// **'Available Characters'**
  String get availableCharacters;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @backgroundColor.
  ///
  /// In en, this message translates to:
  /// **'Background Color'**
  String get backgroundColor;

  /// No description provided for @backgroundTexture.
  ///
  /// In en, this message translates to:
  /// **'Background Texture'**
  String get backgroundTexture;

  /// No description provided for @backupBeforeSwitchRecommendation.
  ///
  /// In en, this message translates to:
  /// **'To ensure data safety, we recommend creating a backup before switching data paths:'**
  String get backupBeforeSwitchRecommendation;

  /// No description provided for @backupChecksum.
  ///
  /// In en, this message translates to:
  /// **'Checksum: {checksum}...'**
  String backupChecksum(Object checksum);

  /// No description provided for @backupCompleted.
  ///
  /// In en, this message translates to:
  /// **'✓ Backup Completed'**
  String get backupCompleted;

  /// No description provided for @backupCount.
  ///
  /// In en, this message translates to:
  /// **'{count} backups'**
  String backupCount(Object count);

  /// No description provided for @backupCountFormat.
  ///
  /// In en, this message translates to:
  /// **'{count} backups'**
  String backupCountFormat(Object count);

  /// No description provided for @backupCreatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Backup created successfully, you can safely proceed with path switching'**
  String get backupCreatedSuccessfully;

  /// No description provided for @backupCreationFailed.
  ///
  /// In en, this message translates to:
  /// **'Backup Creation Failed'**
  String get backupCreationFailed;

  /// No description provided for @backupCreationTime.
  ///
  /// In en, this message translates to:
  /// **'Creation time: {time}'**
  String backupCreationTime(Object time);

  /// No description provided for @backupDeletedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Backup deleted successfully'**
  String get backupDeletedSuccessfully;

  /// No description provided for @backupDescription.
  ///
  /// In en, this message translates to:
  /// **'Description (Optional)'**
  String get backupDescription;

  /// No description provided for @backupDescriptionHint.
  ///
  /// In en, this message translates to:
  /// **'Enter a description for this backup'**
  String get backupDescriptionHint;

  /// No description provided for @backupDescriptionInputExample.
  ///
  /// In en, this message translates to:
  /// **'e.g., Weekly backup, Pre-important update backup, etc.'**
  String get backupDescriptionInputExample;

  /// No description provided for @backupDescriptionInputLabel.
  ///
  /// In en, this message translates to:
  /// **'Backup Description'**
  String get backupDescriptionInputLabel;

  /// No description provided for @backupDescriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Description: {description}'**
  String backupDescriptionLabel(Object description);

  /// No description provided for @backupEnsuresDataSafety.
  ///
  /// In en, this message translates to:
  /// **'• Backup ensures data safety'**
  String get backupEnsuresDataSafety;

  /// No description provided for @backupExportedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Backup exported successfully: {filename}'**
  String backupExportedSuccessfully(Object filename);

  /// No description provided for @backupFailure.
  ///
  /// In en, this message translates to:
  /// **'Failed to Create Backup'**
  String get backupFailure;

  /// No description provided for @backupFile.
  ///
  /// In en, this message translates to:
  /// **'Backup File'**
  String get backupFile;

  /// No description provided for @backupFileChecksumMismatchError.
  ///
  /// In en, this message translates to:
  /// **'Backup file checksum mismatch'**
  String get backupFileChecksumMismatchError;

  /// No description provided for @backupFileCreationFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to create backup file'**
  String get backupFileCreationFailed;

  /// No description provided for @backupFileCreationFailedError.
  ///
  /// In en, this message translates to:
  /// **'Backup file creation failed'**
  String get backupFileCreationFailedError;

  /// No description provided for @backupFileLabel.
  ///
  /// In en, this message translates to:
  /// **'Backup: {filename}'**
  String backupFileLabel(Object filename);

  /// No description provided for @backupFileListTitle.
  ///
  /// In en, this message translates to:
  /// **'Backup File List ({count})'**
  String backupFileListTitle(Object count);

  /// No description provided for @backupFileMissingDirectoryStructureError.
  ///
  /// In en, this message translates to:
  /// **'Backup file missing required directory structure'**
  String get backupFileMissingDirectoryStructureError;

  /// No description provided for @backupFileNotExist.
  ///
  /// In en, this message translates to:
  /// **'Backup file does not exist: {path}'**
  String backupFileNotExist(Object path);

  /// No description provided for @backupFileNotExistError.
  ///
  /// In en, this message translates to:
  /// **'Backup file does not exist'**
  String get backupFileNotExistError;

  /// No description provided for @backupFileNotFound.
  ///
  /// In en, this message translates to:
  /// **'Backup file not found'**
  String get backupFileNotFound;

  /// No description provided for @backupFileSizeMismatchError.
  ///
  /// In en, this message translates to:
  /// **'Backup file size mismatch'**
  String get backupFileSizeMismatchError;

  /// No description provided for @backupFileVerificationFailedError.
  ///
  /// In en, this message translates to:
  /// **'Backup file verification failed'**
  String get backupFileVerificationFailedError;

  /// No description provided for @backupFirst.
  ///
  /// In en, this message translates to:
  /// **'Backup First'**
  String get backupFirst;

  /// No description provided for @backupImportSuccessMessage.
  ///
  /// In en, this message translates to:
  /// **'Backup imported successfully'**
  String get backupImportSuccessMessage;

  /// No description provided for @backupImportedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Backup imported successfully'**
  String get backupImportedSuccessfully;

  /// No description provided for @backupImportedToCurrentPath.
  ///
  /// In en, this message translates to:
  /// **'Backup imported to current path'**
  String get backupImportedToCurrentPath;

  /// No description provided for @backupLabel.
  ///
  /// In en, this message translates to:
  /// **'Backup'**
  String get backupLabel;

  /// No description provided for @backupList.
  ///
  /// In en, this message translates to:
  /// **'Backup List'**
  String get backupList;

  /// No description provided for @backupLocationTips.
  ///
  /// In en, this message translates to:
  /// **'• Recommend choosing a disk with sufficient free space as backup location\\n• Backup location can be external storage devices (like external hard drives)\\n• After changing backup location, all backup information will be managed uniformly\\n• Historical backup files will not be moved automatically, but can be viewed in backup management'**
  String get backupLocationTips;

  /// No description provided for @backupManagement.
  ///
  /// In en, this message translates to:
  /// **'Backup Management'**
  String get backupManagement;

  /// No description provided for @backupManagementSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Create, restore, import, export and manage all backup files'**
  String get backupManagementSubtitle;

  /// No description provided for @backupMayTakeMinutes.
  ///
  /// In en, this message translates to:
  /// **'Backup may take several minutes, please keep the app running'**
  String get backupMayTakeMinutes;

  /// No description provided for @backupNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Backup Management Unavailable'**
  String get backupNotAvailable;

  /// No description provided for @backupNotAvailableMessage.
  ///
  /// In en, this message translates to:
  /// **'Backup management requires database support.\n\nPossible reasons:\n• Database is initializing\n• Database initialization failed\n• Application is starting up\n\nPlease try again later or restart the app.'**
  String get backupNotAvailableMessage;

  /// No description provided for @backupNotFound.
  ///
  /// In en, this message translates to:
  /// **'Backup not found: {id}'**
  String backupNotFound(Object id);

  /// No description provided for @backupNotFoundError.
  ///
  /// In en, this message translates to:
  /// **'Backup not found: {id}'**
  String backupNotFoundError(Object id);

  /// No description provided for @backupOperationTimeoutError.
  ///
  /// In en, this message translates to:
  /// **'Backup operation timed out, please check available storage space and retry'**
  String get backupOperationTimeoutError;

  /// No description provided for @backupOverview.
  ///
  /// In en, this message translates to:
  /// **'Backup Overview'**
  String get backupOverview;

  /// No description provided for @backupPathDeleted.
  ///
  /// In en, this message translates to:
  /// **'Backup path deleted'**
  String get backupPathDeleted;

  /// No description provided for @backupPathDeletedMessage.
  ///
  /// In en, this message translates to:
  /// **'Backup path has been deleted'**
  String get backupPathDeletedMessage;

  /// No description provided for @backupPathNotSet.
  ///
  /// In en, this message translates to:
  /// **'Please set backup path first'**
  String get backupPathNotSet;

  /// No description provided for @backupPathNotSetError.
  ///
  /// In en, this message translates to:
  /// **'Please set backup path first'**
  String get backupPathNotSetError;

  /// No description provided for @backupPathNotSetUp.
  ///
  /// In en, this message translates to:
  /// **'Backup path is not set up'**
  String get backupPathNotSetUp;

  /// No description provided for @backupPathSetSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Backup path set successfully'**
  String get backupPathSetSuccessfully;

  /// No description provided for @backupPathSettings.
  ///
  /// In en, this message translates to:
  /// **'Backup Path Settings'**
  String get backupPathSettings;

  /// No description provided for @backupPathSettingsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Configure and manage backup storage paths'**
  String get backupPathSettingsSubtitle;

  /// No description provided for @backupPreCheckFailed.
  ///
  /// In en, this message translates to:
  /// **'Backup pre-check failed: {error}'**
  String backupPreCheckFailed(Object error);

  /// No description provided for @backupReadyRestartMessage.
  ///
  /// In en, this message translates to:
  /// **'Backup file is ready, restart required to complete restore'**
  String get backupReadyRestartMessage;

  /// No description provided for @backupRecommendation.
  ///
  /// In en, this message translates to:
  /// **'Recommend creating backup before import'**
  String get backupRecommendation;

  /// No description provided for @backupRecommendationDescription.
  ///
  /// In en, this message translates to:
  /// **'For data safety, it\'s recommended to manually create a backup before importing'**
  String get backupRecommendationDescription;

  /// No description provided for @backupRestartWarning.
  ///
  /// In en, this message translates to:
  /// **'Restart the app to apply changes'**
  String get backupRestartWarning;

  /// No description provided for @backupRestoreFailedMessage.
  ///
  /// In en, this message translates to:
  /// **'Failed to restore backup: {error}'**
  String backupRestoreFailedMessage(Object error);

  /// No description provided for @backupRestoreSuccessMessage.
  ///
  /// In en, this message translates to:
  /// **'Backup restored successfully, please restart the app to complete the restore'**
  String get backupRestoreSuccessMessage;

  /// No description provided for @backupRestoreSuccessWithRestartMessage.
  ///
  /// In en, this message translates to:
  /// **'Backup restored successfully, restart required to apply changes.'**
  String get backupRestoreSuccessWithRestartMessage;

  /// No description provided for @backupRestoredSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Backup restored successfully, please restart the app to complete restoration'**
  String get backupRestoredSuccessfully;

  /// No description provided for @backupServiceInitializing.
  ///
  /// In en, this message translates to:
  /// **'Backup service is initializing, please wait and try again'**
  String get backupServiceInitializing;

  /// No description provided for @backupServiceNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Backup service is temporarily unavailable'**
  String get backupServiceNotAvailable;

  /// No description provided for @backupServiceNotInitialized.
  ///
  /// In en, this message translates to:
  /// **'Backup service not initialized'**
  String get backupServiceNotInitialized;

  /// No description provided for @backupServiceNotReady.
  ///
  /// In en, this message translates to:
  /// **'Backup service is temporarily unavailable'**
  String get backupServiceNotReady;

  /// No description provided for @backupSettings.
  ///
  /// In en, this message translates to:
  /// **'Backup and Restore'**
  String get backupSettings;

  /// No description provided for @backupSize.
  ///
  /// In en, this message translates to:
  /// **'Size: {size}'**
  String backupSize(Object size);

  /// No description provided for @backupStatistics.
  ///
  /// In en, this message translates to:
  /// **'Backup Statistics'**
  String get backupStatistics;

  /// No description provided for @backupStorageLocation.
  ///
  /// In en, this message translates to:
  /// **'Backup Storage Location'**
  String get backupStorageLocation;

  /// No description provided for @backupSuccess.
  ///
  /// In en, this message translates to:
  /// **'Backup Created Successfully'**
  String get backupSuccess;

  /// No description provided for @backupSuccessCanSwitchPath.
  ///
  /// In en, this message translates to:
  /// **'Backup created successfully, it\'s safe to proceed with path switching'**
  String get backupSuccessCanSwitchPath;

  /// No description provided for @backupTimeLabel.
  ///
  /// In en, this message translates to:
  /// **'Time: {time}'**
  String backupTimeLabel(Object time);

  /// No description provided for @backupTimeoutDetailedError.
  ///
  /// In en, this message translates to:
  /// **'Backup operation timed out. Possible causes:\n• Large amount of data\n• Insufficient storage space\n• Slow disk read/write speed\n\nPlease check storage space and retry.'**
  String get backupTimeoutDetailedError;

  /// No description provided for @backupTimeoutError.
  ///
  /// In en, this message translates to:
  /// **'Backup creation timeout or failed, please check if storage space is sufficient'**
  String get backupTimeoutError;

  /// No description provided for @backupVerificationFailed.
  ///
  /// In en, this message translates to:
  /// **'Backup file verification failed'**
  String get backupVerificationFailed;

  /// No description provided for @backups.
  ///
  /// In en, this message translates to:
  /// **'Backups'**
  String get backups;

  /// No description provided for @backupsCount.
  ///
  /// In en, this message translates to:
  /// **'backups'**
  String get backupsCount;

  /// No description provided for @basicInfo.
  ///
  /// In en, this message translates to:
  /// **'Basic Information'**
  String get basicInfo;

  /// No description provided for @basicProperties.
  ///
  /// In en, this message translates to:
  /// **'Basic Properties'**
  String get basicProperties;

  /// No description provided for @batchDeleteMessage.
  ///
  /// In en, this message translates to:
  /// **'About to delete {count} items. This action cannot be undone.'**
  String batchDeleteMessage(Object count);

  /// No description provided for @batchExportFailed.
  ///
  /// In en, this message translates to:
  /// **'Batch export failed'**
  String get batchExportFailed;

  /// No description provided for @batchExportFailedMessage.
  ///
  /// In en, this message translates to:
  /// **'Batch export failed: {error}'**
  String batchExportFailedMessage(Object error);

  /// No description provided for @batchImport.
  ///
  /// In en, this message translates to:
  /// **'Batch Import'**
  String get batchImport;

  /// No description provided for @batchMode.
  ///
  /// In en, this message translates to:
  /// **'Batch Mode'**
  String get batchMode;

  /// No description provided for @batchOperations.
  ///
  /// In en, this message translates to:
  /// **'Batch Operations'**
  String get batchOperations;

  /// No description provided for @beforeDate.
  ///
  /// In en, this message translates to:
  /// **'Before a Certain Date'**
  String get beforeDate;

  /// No description provided for @binarizationParameters.
  ///
  /// In en, this message translates to:
  /// **'Binarization Parameters'**
  String get binarizationParameters;

  /// No description provided for @binarizationProcessing.
  ///
  /// In en, this message translates to:
  /// **'Binarization Processing'**
  String get binarizationProcessing;

  /// No description provided for @binarizationToggle.
  ///
  /// In en, this message translates to:
  /// **'Binarization Toggle'**
  String get binarizationToggle;

  /// No description provided for @binaryThreshold.
  ///
  /// In en, this message translates to:
  /// **'Binary Threshold'**
  String get binaryThreshold;

  /// No description provided for @border.
  ///
  /// In en, this message translates to:
  /// **'Border'**
  String get border;

  /// No description provided for @borderColor.
  ///
  /// In en, this message translates to:
  /// **'Border Color'**
  String get borderColor;

  /// No description provided for @borderWidth.
  ///
  /// In en, this message translates to:
  /// **'Border Width'**
  String get borderWidth;

  /// No description provided for @bottomCenter.
  ///
  /// In en, this message translates to:
  /// **'Bottom Center'**
  String get bottomCenter;

  /// No description provided for @bottomLeft.
  ///
  /// In en, this message translates to:
  /// **'Bottom Left'**
  String get bottomLeft;

  /// No description provided for @bottomRight.
  ///
  /// In en, this message translates to:
  /// **'Bottom Right'**
  String get bottomRight;

  /// No description provided for @boxRegion.
  ///
  /// In en, this message translates to:
  /// **'Please select characters in the preview area'**
  String get boxRegion;

  /// No description provided for @boxTool.
  ///
  /// In en, this message translates to:
  /// **'Collection Tool'**
  String get boxTool;

  /// No description provided for @bringLayerToFront.
  ///
  /// In en, this message translates to:
  /// **'Bring Layer to Front'**
  String get bringLayerToFront;

  /// No description provided for @bringToFront.
  ///
  /// In en, this message translates to:
  /// **'Bring to Front (Ctrl+T)'**
  String get bringToFront;

  /// No description provided for @browse.
  ///
  /// In en, this message translates to:
  /// **'Browse'**
  String get browse;

  /// No description provided for @browsePath.
  ///
  /// In en, this message translates to:
  /// **'Browse Path'**
  String get browsePath;

  /// No description provided for @brushSize.
  ///
  /// In en, this message translates to:
  /// **'Brush Size'**
  String get brushSize;

  /// No description provided for @buildEnvironment.
  ///
  /// In en, this message translates to:
  /// **'Build Environment'**
  String get buildEnvironment;

  /// No description provided for @buildNumber.
  ///
  /// In en, this message translates to:
  /// **'Build Number'**
  String get buildNumber;

  /// No description provided for @buildTime.
  ///
  /// In en, this message translates to:
  /// **'Build Time'**
  String get buildTime;

  /// No description provided for @cacheClearedMessage.
  ///
  /// In en, this message translates to:
  /// **'Cache Cleared Successfully'**
  String get cacheClearedMessage;

  /// No description provided for @cacheSettings.
  ///
  /// In en, this message translates to:
  /// **'Cache Settings'**
  String get cacheSettings;

  /// No description provided for @cacheSize.
  ///
  /// In en, this message translates to:
  /// **'Cache Size'**
  String get cacheSize;

  /// No description provided for @calligraphyStyle.
  ///
  /// In en, this message translates to:
  /// **'Calligraphy Style'**
  String get calligraphyStyle;

  /// No description provided for @calligraphyStyleText.
  ///
  /// In en, this message translates to:
  /// **'Calligraphy Style'**
  String get calligraphyStyleText;

  /// No description provided for @canChooseDirectSwitch.
  ///
  /// In en, this message translates to:
  /// **'• You can also choose to switch directly'**
  String get canChooseDirectSwitch;

  /// No description provided for @canCleanOldDataLater.
  ///
  /// In en, this message translates to:
  /// **'You can clean up old data later through \"Data Path Management\"'**
  String get canCleanOldDataLater;

  /// No description provided for @canCleanupLaterViaManagement.
  ///
  /// In en, this message translates to:
  /// **'You can clean up old data later via Data Path Management'**
  String get canCleanupLaterViaManagement;

  /// No description provided for @canManuallyCleanLater.
  ///
  /// In en, this message translates to:
  /// **'• You can manually clean up old path data later'**
  String get canManuallyCleanLater;

  /// No description provided for @canNotPreview.
  ///
  /// In en, this message translates to:
  /// **'Cannot Generate Preview'**
  String get canNotPreview;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @cancelAction.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancelAction;

  /// No description provided for @cannotApplyNoImage.
  ///
  /// In en, this message translates to:
  /// **'No Image Available'**
  String get cannotApplyNoImage;

  /// No description provided for @cannotApplyNoSizeInfo.
  ///
  /// In en, this message translates to:
  /// **'Cannot Get Image Size Information'**
  String get cannotApplyNoSizeInfo;

  /// No description provided for @cannotCapturePageImage.
  ///
  /// In en, this message translates to:
  /// **'Cannot Capture Page Image'**
  String get cannotCapturePageImage;

  /// No description provided for @cannotDeleteOnlyPage.
  ///
  /// In en, this message translates to:
  /// **'Cannot Delete Only Page'**
  String get cannotDeleteOnlyPage;

  /// No description provided for @cannotGetStorageInfo.
  ///
  /// In en, this message translates to:
  /// **'Cannot get storage info'**
  String get cannotGetStorageInfo;

  /// No description provided for @cannotReadPathContent.
  ///
  /// In en, this message translates to:
  /// **'Cannot read path content'**
  String get cannotReadPathContent;

  /// No description provided for @cannotReadPathFileInfo.
  ///
  /// In en, this message translates to:
  /// **'Cannot read path file information'**
  String get cannotReadPathFileInfo;

  /// No description provided for @cannotSaveMissingController.
  ///
  /// In en, this message translates to:
  /// **'Cannot Save: Missing Controller'**
  String get cannotSaveMissingController;

  /// No description provided for @cannotSaveNoPages.
  ///
  /// In en, this message translates to:
  /// **'No Pages Available, Cannot Save'**
  String get cannotSaveNoPages;

  /// No description provided for @canvasPixelSize.
  ///
  /// In en, this message translates to:
  /// **'Canvas Pixel Size'**
  String get canvasPixelSize;

  /// No description provided for @canvasResetViewTooltip.
  ///
  /// In en, this message translates to:
  /// **'Reset View Position'**
  String get canvasResetViewTooltip;

  /// No description provided for @categories.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get categories;

  /// No description provided for @categoryManagement.
  ///
  /// In en, this message translates to:
  /// **'Category Management'**
  String get categoryManagement;

  /// No description provided for @categoryName.
  ///
  /// In en, this message translates to:
  /// **'Category Name'**
  String get categoryName;

  /// No description provided for @categoryNameCannotBeEmpty.
  ///
  /// In en, this message translates to:
  /// **'Category name cannot be empty'**
  String get categoryNameCannotBeEmpty;

  /// No description provided for @centerLeft.
  ///
  /// In en, this message translates to:
  /// **'Center Left'**
  String get centerLeft;

  /// No description provided for @centerRight.
  ///
  /// In en, this message translates to:
  /// **'Center Right'**
  String get centerRight;

  /// No description provided for @centimeter.
  ///
  /// In en, this message translates to:
  /// **'Centimeter'**
  String get centimeter;

  /// No description provided for @changeDataPathMessage.
  ///
  /// In en, this message translates to:
  /// **'The application needs to restart after changing the data path to take effect.'**
  String get changeDataPathMessage;

  /// No description provided for @changePath.
  ///
  /// In en, this message translates to:
  /// **'Change Path'**
  String get changePath;

  /// No description provided for @character.
  ///
  /// In en, this message translates to:
  /// **'Character'**
  String get character;

  /// No description provided for @characterCollection.
  ///
  /// In en, this message translates to:
  /// **'Characters'**
  String get characterCollection;

  /// No description provided for @characterCollectionFindSwitchFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to Find and Switch Page: {error}'**
  String characterCollectionFindSwitchFailed(Object error);

  /// No description provided for @characterCollectionPreviewTab.
  ///
  /// In en, this message translates to:
  /// **'Character Preview'**
  String get characterCollectionPreviewTab;

  /// No description provided for @characterCollectionResultsTab.
  ///
  /// In en, this message translates to:
  /// **'Collection Results'**
  String get characterCollectionResultsTab;

  /// No description provided for @characterCollectionSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search Characters...'**
  String get characterCollectionSearchHint;

  /// No description provided for @characterCollectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Character Collection'**
  String get characterCollectionTitle;

  /// No description provided for @characterCollectionToolBox.
  ///
  /// In en, this message translates to:
  /// **'Collection Tool (Ctrl+B)'**
  String get characterCollectionToolBox;

  /// No description provided for @characterCollectionToolPan.
  ///
  /// In en, this message translates to:
  /// **'Multi-Select Tool (Ctrl+V)'**
  String get characterCollectionToolPan;

  /// No description provided for @characterCollectionUseBoxTool.
  ///
  /// In en, this message translates to:
  /// **'Use collection tool to extract characters from image'**
  String get characterCollectionUseBoxTool;

  /// No description provided for @characterCount.
  ///
  /// In en, this message translates to:
  /// **'Character Count'**
  String get characterCount;

  /// No description provided for @characterDisplayFormat.
  ///
  /// In en, this message translates to:
  /// **'Character: {character}'**
  String characterDisplayFormat(Object character);

  /// No description provided for @characterDetailFormatBinary.
  ///
  /// In en, this message translates to:
  /// **'Binary'**
  String get characterDetailFormatBinary;

  /// No description provided for @characterDetailFormatBinaryDesc.
  ///
  /// In en, this message translates to:
  /// **'Black and White Binary Image'**
  String get characterDetailFormatBinaryDesc;

  /// No description provided for @characterDetailFormatDescription.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get characterDetailFormatDescription;

  /// No description provided for @characterDetailFormatOutline.
  ///
  /// In en, this message translates to:
  /// **'Outline'**
  String get characterDetailFormatOutline;

  /// No description provided for @characterDetailFormatOutlineDesc.
  ///
  /// In en, this message translates to:
  /// **'Show Only Outline'**
  String get characterDetailFormatOutlineDesc;

  /// No description provided for @characterDetailFormatSquareBinary.
  ///
  /// In en, this message translates to:
  /// **'Square Binary'**
  String get characterDetailFormatSquareBinary;

  /// No description provided for @characterDetailFormatSquareBinaryDesc.
  ///
  /// In en, this message translates to:
  /// **'Regularized Square Binary Image'**
  String get characterDetailFormatSquareBinaryDesc;

  /// No description provided for @characterDetailFormatSquareOutline.
  ///
  /// In en, this message translates to:
  /// **'Square Outline'**
  String get characterDetailFormatSquareOutline;

  /// No description provided for @characterDetailFormatSquareOutlineDesc.
  ///
  /// In en, this message translates to:
  /// **'Regularized Square Outline Image'**
  String get characterDetailFormatSquareOutlineDesc;

  /// No description provided for @characterDetailFormatSquareTransparent.
  ///
  /// In en, this message translates to:
  /// **'Square Transparent'**
  String get characterDetailFormatSquareTransparent;

  /// No description provided for @characterDetailFormatSquareTransparentDesc.
  ///
  /// In en, this message translates to:
  /// **'Regularized Square Transparent Image'**
  String get characterDetailFormatSquareTransparentDesc;

  /// No description provided for @characterDetailFormatThumbnail.
  ///
  /// In en, this message translates to:
  /// **'Thumbnail'**
  String get characterDetailFormatThumbnail;

  /// No description provided for @characterDetailFormatThumbnailDesc.
  ///
  /// In en, this message translates to:
  /// **'Thumbnail'**
  String get characterDetailFormatThumbnailDesc;

  /// No description provided for @characterDetailFormatTransparent.
  ///
  /// In en, this message translates to:
  /// **'Transparent'**
  String get characterDetailFormatTransparent;

  /// No description provided for @characterDetailFormatTransparentDesc.
  ///
  /// In en, this message translates to:
  /// **'Background Removed Transparent Image'**
  String get characterDetailFormatTransparentDesc;

  /// No description provided for @characterDetailLoadError.
  ///
  /// In en, this message translates to:
  /// **'Failed to Load Character Details'**
  String get characterDetailLoadError;

  /// No description provided for @characterDetailSimplifiedChar.
  ///
  /// In en, this message translates to:
  /// **'Simplified Character'**
  String get characterDetailSimplifiedChar;

  /// No description provided for @characterDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Character Details'**
  String get characterDetailTitle;

  /// No description provided for @characterEditSaveConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'Confirm Save \'{character}\'?'**
  String characterEditSaveConfirmMessage(Object character);

  /// No description provided for @characterUpdated.
  ///
  /// In en, this message translates to:
  /// **'Character Updated'**
  String get characterUpdated;

  /// No description provided for @characters.
  ///
  /// In en, this message translates to:
  /// **'Characters'**
  String get characters;

  /// No description provided for @charactersCount.
  ///
  /// In en, this message translates to:
  /// **'{count} characters'**
  String charactersCount(Object count);

  /// No description provided for @charactersSelected.
  ///
  /// In en, this message translates to:
  /// **'Selected {count} Characters'**
  String charactersSelected(Object count);

  /// No description provided for @checkBackupRecommendationFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to check backup recommendation'**
  String get checkBackupRecommendationFailed;

  /// No description provided for @checkFailedRecommendBackup.
  ///
  /// In en, this message translates to:
  /// **'Check failed, recommend creating backup first to ensure data safety'**
  String get checkFailedRecommendBackup;

  /// No description provided for @checkSpecialChars.
  ///
  /// In en, this message translates to:
  /// **'• Check if work title contains special characters'**
  String get checkSpecialChars;

  /// No description provided for @cleanDuplicateRecords.
  ///
  /// In en, this message translates to:
  /// **'Clean Duplicate Records'**
  String get cleanDuplicateRecords;

  /// No description provided for @cleanDuplicateRecordsDescription.
  ///
  /// In en, this message translates to:
  /// **'This operation will clean duplicate backup records without deleting actual backup files.'**
  String get cleanDuplicateRecordsDescription;

  /// No description provided for @cleanDuplicateRecordsTitle.
  ///
  /// In en, this message translates to:
  /// **'Clean Duplicate Records'**
  String get cleanDuplicateRecordsTitle;

  /// No description provided for @cleanupCompleted.
  ///
  /// In en, this message translates to:
  /// **'Cleanup completed, removed {count} invalid paths'**
  String cleanupCompleted(Object count);

  /// No description provided for @cleanupCompletedMessage.
  ///
  /// In en, this message translates to:
  /// **'Cleanup completed, removed {count} invalid paths'**
  String cleanupCompletedMessage(Object count);

  /// No description provided for @cleanupCompletedWithCount.
  ///
  /// In en, this message translates to:
  /// **'Cleanup completed, removed {count} duplicate records'**
  String cleanupCompletedWithCount(Object count);

  /// No description provided for @cleanupFailed.
  ///
  /// In en, this message translates to:
  /// **'Cleanup failed'**
  String get cleanupFailed;

  /// No description provided for @cleanupFailedMessage.
  ///
  /// In en, this message translates to:
  /// **'Cleanup failed: {error}'**
  String cleanupFailedMessage(Object error);

  /// No description provided for @cleanupInvalidPaths.
  ///
  /// In en, this message translates to:
  /// **'Cleanup Invalid Paths'**
  String get cleanupInvalidPaths;

  /// No description provided for @cleanupOperationFailed.
  ///
  /// In en, this message translates to:
  /// **'Cleanup operation failed: {error}'**
  String cleanupOperationFailed(Object error);

  /// No description provided for @clearCache.
  ///
  /// In en, this message translates to:
  /// **'Clear Cache'**
  String get clearCache;

  /// No description provided for @clearCacheConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to clear all cache data? This will free up disk space but may temporarily slow down the application.'**
  String get clearCacheConfirmMessage;

  /// No description provided for @clearSelection.
  ///
  /// In en, this message translates to:
  /// **'Clear Selection'**
  String get clearSelection;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @code.
  ///
  /// In en, this message translates to:
  /// **'Code'**
  String get code;

  /// No description provided for @collapse.
  ///
  /// In en, this message translates to:
  /// **'Collapse'**
  String get collapse;

  /// No description provided for @collapseFileList.
  ///
  /// In en, this message translates to:
  /// **'Click to collapse file list'**
  String get collapseFileList;

  /// No description provided for @collectionDate.
  ///
  /// In en, this message translates to:
  /// **'Collection Date'**
  String get collectionDate;

  /// No description provided for @collectionElement.
  ///
  /// In en, this message translates to:
  /// **'Collection Element'**
  String get collectionElement;

  /// No description provided for @collectionTextElement.
  ///
  /// In en, this message translates to:
  /// **'Text'**
  String get collectionTextElement;

  /// No description provided for @candidateCharacters.
  ///
  /// In en, this message translates to:
  /// **'Candidate Characters'**
  String get candidateCharacters;

  /// No description provided for @characterScale.
  ///
  /// In en, this message translates to:
  /// **'Character Scale'**
  String get characterScale;

  /// No description provided for @positionOffset.
  ///
  /// In en, this message translates to:
  /// **'Position Offset'**
  String get positionOffset;

  /// No description provided for @scale.
  ///
  /// In en, this message translates to:
  /// **'Scale'**
  String get scale;

  /// No description provided for @xOffset.
  ///
  /// In en, this message translates to:
  /// **'X Offset'**
  String get xOffset;

  /// No description provided for @yOffset.
  ///
  /// In en, this message translates to:
  /// **'Y Offset'**
  String get yOffset;

  /// No description provided for @reset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get reset;

  /// No description provided for @collectionIdCannotBeEmpty.
  ///
  /// In en, this message translates to:
  /// **'Collection ID cannot be empty'**
  String get collectionIdCannotBeEmpty;

  /// No description provided for @collectionTime.
  ///
  /// In en, this message translates to:
  /// **'Collection Time'**
  String get collectionTime;

  /// No description provided for @color.
  ///
  /// In en, this message translates to:
  /// **'Color'**
  String get color;

  /// No description provided for @colorCode.
  ///
  /// In en, this message translates to:
  /// **'Color Code'**
  String get colorCode;

  /// No description provided for @colorCodeHelp.
  ///
  /// In en, this message translates to:
  /// **'Enter 6-digit hexadecimal color code (e.g., FF5500)'**
  String get colorCodeHelp;

  /// No description provided for @colorCodeInvalid.
  ///
  /// In en, this message translates to:
  /// **'Invalid Color Code'**
  String get colorCodeInvalid;

  /// No description provided for @colorInversion.
  ///
  /// In en, this message translates to:
  /// **'Color Inversion'**
  String get colorInversion;

  /// No description provided for @colorPicker.
  ///
  /// In en, this message translates to:
  /// **'Color Picker'**
  String get colorPicker;

  /// No description provided for @colorSettings.
  ///
  /// In en, this message translates to:
  /// **'Color Settings'**
  String get colorSettings;

  /// No description provided for @commonProperties.
  ///
  /// In en, this message translates to:
  /// **'Common Properties'**
  String get commonProperties;

  /// No description provided for @commonTags.
  ///
  /// In en, this message translates to:
  /// **'Common Tags:'**
  String get commonTags;

  /// No description provided for @completingSave.
  ///
  /// In en, this message translates to:
  /// **'Completing Save...'**
  String get completingSave;

  /// No description provided for @compressData.
  ///
  /// In en, this message translates to:
  /// **'Compress Data'**
  String get compressData;

  /// No description provided for @compressDataDescription.
  ///
  /// In en, this message translates to:
  /// **'Reduce export file size'**
  String get compressDataDescription;

  /// No description provided for @configInitFailed.
  ///
  /// In en, this message translates to:
  /// **'Configuration data initialization failed'**
  String get configInitFailed;

  /// No description provided for @configInitializationFailed.
  ///
  /// In en, this message translates to:
  /// **'Configuration initialization failed'**
  String get configInitializationFailed;

  /// No description provided for @configInitializing.
  ///
  /// In en, this message translates to:
  /// **'Initializing configuration...'**
  String get configInitializing;

  /// No description provided for @configKey.
  ///
  /// In en, this message translates to:
  /// **'Configuration Key'**
  String get configKey;

  /// No description provided for @configManagement.
  ///
  /// In en, this message translates to:
  /// **'Configuration Management'**
  String get configManagement;

  /// No description provided for @configManagementDescription.
  ///
  /// In en, this message translates to:
  /// **'Manage calligraphy styles and writing tools configuration'**
  String get configManagementDescription;

  /// No description provided for @configManagementTitle.
  ///
  /// In en, this message translates to:
  /// **'Calligraphy Style Management'**
  String get configManagementTitle;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @confirmChangeDataPath.
  ///
  /// In en, this message translates to:
  /// **'Confirm Change Data Path'**
  String get confirmChangeDataPath;

  /// No description provided for @confirmContinue.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to continue?'**
  String get confirmContinue;

  /// No description provided for @confirmDataNormalBeforeClean.
  ///
  /// In en, this message translates to:
  /// **'• Recommend confirming data is normal before cleaning old path'**
  String get confirmDataNormalBeforeClean;

  /// No description provided for @confirmDataPathSwitch.
  ///
  /// In en, this message translates to:
  /// **'Confirm Data Path Switch'**
  String get confirmDataPathSwitch;

  /// No description provided for @confirmDelete.
  ///
  /// In en, this message translates to:
  /// **'Confirm Delete'**
  String get confirmDelete;

  /// No description provided for @confirmDeleteAction.
  ///
  /// In en, this message translates to:
  /// **'Confirm Delete'**
  String get confirmDeleteAction;

  /// No description provided for @confirmDeleteAll.
  ///
  /// In en, this message translates to:
  /// **'Confirm Delete All'**
  String get confirmDeleteAll;

  /// No description provided for @confirmDeleteAllBackups.
  ///
  /// In en, this message translates to:
  /// **'Confirm Delete All Backups'**
  String get confirmDeleteAllBackups;

  /// No description provided for @confirmDeleteAllButton.
  ///
  /// In en, this message translates to:
  /// **'Confirm Delete All'**
  String get confirmDeleteAllButton;

  /// No description provided for @confirmDeleteBackup.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this backup?\\n\\nBackup: {filename}\\nDescription: {description}\\n\\nThis operation cannot be undone!'**
  String confirmDeleteBackup(Object description, Object filename);

  /// No description provided for @confirmDeleteBackupPath.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete the entire backup path?\\n\\nPath: {path}\\n\\nThis will:\\n• Delete all backup files in this path\\n• Remove the path from history\\n• This operation cannot be undone\\n\\nPlease proceed with caution!'**
  String confirmDeleteBackupPath(Object path);

  /// No description provided for @confirmDeleteButton.
  ///
  /// In en, this message translates to:
  /// **'Confirm Delete'**
  String get confirmDeleteButton;

  /// No description provided for @confirmDeleteHistoryPath.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this history path record?'**
  String get confirmDeleteHistoryPath;

  /// No description provided for @confirmDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm Delete'**
  String get confirmDeleteTitle;

  /// No description provided for @confirmExitWizard.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to exit the data path switch wizard?'**
  String get confirmExitWizard;

  /// No description provided for @confirmImportAction.
  ///
  /// In en, this message translates to:
  /// **'Confirm Import'**
  String get confirmImportAction;

  /// No description provided for @confirmImportButton.
  ///
  /// In en, this message translates to:
  /// **'Confirm Import'**
  String get confirmImportButton;

  /// No description provided for @confirmOverwrite.
  ///
  /// In en, this message translates to:
  /// **'Confirm Overwrite'**
  String get confirmOverwrite;

  /// No description provided for @confirmRemoveFromCategory.
  ///
  /// In en, this message translates to:
  /// **'Confirm Remove from Category'**
  String confirmRemoveFromCategory(Object count);

  /// No description provided for @confirmResetToDefaultPath.
  ///
  /// In en, this message translates to:
  /// **'Confirm Reset to Default Path'**
  String get confirmResetToDefaultPath;

  /// No description provided for @confirmRestoreAction.
  ///
  /// In en, this message translates to:
  /// **'Confirm Restore'**
  String get confirmRestoreAction;

  /// No description provided for @confirmRestoreBackup.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to restore this backup?'**
  String get confirmRestoreBackup;

  /// No description provided for @confirmRestoreButton.
  ///
  /// In en, this message translates to:
  /// **'Confirm Restore'**
  String get confirmRestoreButton;

  /// No description provided for @confirmRestoreMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to restore this backup?'**
  String get confirmRestoreMessage;

  /// No description provided for @confirmRestoreTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm Restore'**
  String get confirmRestoreTitle;

  /// No description provided for @confirmShortcuts.
  ///
  /// In en, this message translates to:
  /// **'Shortcuts: Enter Confirm, Esc Cancel'**
  String get confirmShortcuts;

  /// No description provided for @confirmSkip.
  ///
  /// In en, this message translates to:
  /// **'Confirm Skip'**
  String get confirmSkip;

  /// No description provided for @confirmSkipAction.
  ///
  /// In en, this message translates to:
  /// **'Confirm Skip'**
  String get confirmSkipAction;

  /// No description provided for @confirmSwitch.
  ///
  /// In en, this message translates to:
  /// **'Confirm Switch'**
  String get confirmSwitch;

  /// No description provided for @confirmSwitchButton.
  ///
  /// In en, this message translates to:
  /// **'Confirm Switch'**
  String get confirmSwitchButton;

  /// No description provided for @confirmSwitchToNewPath.
  ///
  /// In en, this message translates to:
  /// **'Confirm switching to new data path'**
  String get confirmSwitchToNewPath;

  /// No description provided for @conflictDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Conflict Resolution Details'**
  String get conflictDetailsTitle;

  /// No description provided for @conflictReason.
  ///
  /// In en, this message translates to:
  /// **'Conflict Reason'**
  String get conflictReason;

  /// No description provided for @conflictResolution.
  ///
  /// In en, this message translates to:
  /// **'Conflict Resolution'**
  String get conflictResolution;

  /// No description provided for @conflictsCount.
  ///
  /// In en, this message translates to:
  /// **'Found {count} conflicts'**
  String conflictsCount(Object count);

  /// No description provided for @conflictsFound.
  ///
  /// In en, this message translates to:
  /// **'Conflicts Found'**
  String get conflictsFound;

  /// No description provided for @contentProperties.
  ///
  /// In en, this message translates to:
  /// **'Content Properties'**
  String get contentProperties;

  /// No description provided for @contentSettings.
  ///
  /// In en, this message translates to:
  /// **'Content Settings'**
  String get contentSettings;

  /// No description provided for @continueDuplicateImport.
  ///
  /// In en, this message translates to:
  /// **'Do you still want to continue importing this backup?'**
  String get continueDuplicateImport;

  /// No description provided for @continueImport.
  ///
  /// In en, this message translates to:
  /// **'Continue Import'**
  String get continueImport;

  /// No description provided for @continueQuestion.
  ///
  /// In en, this message translates to:
  /// **'Continue?'**
  String get continueQuestion;

  /// No description provided for @copy.
  ///
  /// In en, this message translates to:
  /// **'Copy (Ctrl+Shift+C)'**
  String get copy;

  /// No description provided for @copyFailed.
  ///
  /// In en, this message translates to:
  /// **'Copy failed: {error}'**
  String copyFailed(Object error);

  /// No description provided for @copyFormat.
  ///
  /// In en, this message translates to:
  /// **'Copy Format (Alt+Q)'**
  String get copyFormat;

  /// No description provided for @copySelected.
  ///
  /// In en, this message translates to:
  /// **'Copy Selected Items'**
  String get copySelected;

  /// No description provided for @copyVersionInfo.
  ///
  /// In en, this message translates to:
  /// **'Copy Version Info'**
  String get copyVersionInfo;

  /// No description provided for @couldNotGetFilePath.
  ///
  /// In en, this message translates to:
  /// **'Could Not Get File Path'**
  String get couldNotGetFilePath;

  /// No description provided for @countUnit.
  ///
  /// In en, this message translates to:
  /// **''**
  String get countUnit;

  /// No description provided for @create.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get create;

  /// No description provided for @createBackup.
  ///
  /// In en, this message translates to:
  /// **'Create Backup'**
  String get createBackup;

  /// No description provided for @createBackupBeforeImport.
  ///
  /// In en, this message translates to:
  /// **'Create backup before import'**
  String get createBackupBeforeImport;

  /// No description provided for @createBackupDescription.
  ///
  /// In en, this message translates to:
  /// **'Create a New Data Backup'**
  String get createBackupDescription;

  /// No description provided for @createBackupFailed.
  ///
  /// In en, this message translates to:
  /// **'Create backup failed'**
  String get createBackupFailed;

  /// No description provided for @createBackupFailedMessage.
  ///
  /// In en, this message translates to:
  /// **'Failed to create backup: {error}'**
  String createBackupFailedMessage(Object error);

  /// No description provided for @createExportDirectoryFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to Create Export Directory {error}'**
  String createExportDirectoryFailed(Object error);

  /// No description provided for @createFirstBackup.
  ///
  /// In en, this message translates to:
  /// **'Create first backup'**
  String get createFirstBackup;

  /// No description provided for @createTime.
  ///
  /// In en, this message translates to:
  /// **'Creation Time'**
  String get createTime;

  /// No description provided for @createdAt.
  ///
  /// In en, this message translates to:
  /// **'Created At'**
  String get createdAt;

  /// No description provided for @creatingBackup.
  ///
  /// In en, this message translates to:
  /// **'Creating Backup...'**
  String get creatingBackup;

  /// No description provided for @creatingBackupPleaseWaitMessage.
  ///
  /// In en, this message translates to:
  /// **'This may take a few minutes, please be patient'**
  String get creatingBackupPleaseWaitMessage;

  /// No description provided for @creatingBackupProgressMessage.
  ///
  /// In en, this message translates to:
  /// **'Creating backup...'**
  String get creatingBackupProgressMessage;

  /// No description provided for @creationDate.
  ///
  /// In en, this message translates to:
  /// **'Creation Date'**
  String get creationDate;

  /// No description provided for @criticalError.
  ///
  /// In en, this message translates to:
  /// **'Critical Error'**
  String get criticalError;

  /// No description provided for @cropAdjustmentHint.
  ///
  /// In en, this message translates to:
  /// **'Drag the selection box and control points in the preview above to adjust the crop area'**
  String get cropAdjustmentHint;

  /// No description provided for @cropBottom.
  ///
  /// In en, this message translates to:
  /// **'Crop Bottom'**
  String get cropBottom;

  /// No description provided for @cropLeft.
  ///
  /// In en, this message translates to:
  /// **'Crop Left'**
  String get cropLeft;

  /// No description provided for @cropRight.
  ///
  /// In en, this message translates to:
  /// **'Crop Right'**
  String get cropRight;

  /// No description provided for @cropTop.
  ///
  /// In en, this message translates to:
  /// **'Crop Top'**
  String get cropTop;

  /// No description provided for @cropping.
  ///
  /// In en, this message translates to:
  /// **'Cropping'**
  String get cropping;

  /// No description provided for @croppingApplied.
  ///
  /// In en, this message translates to:
  /// **'(Cropping: Left {left}px, Top {top}px, Right {right}px, Bottom {bottom}px)'**
  String croppingApplied(Object bottom, Object left, Object right, Object top);

  /// No description provided for @crossPagePasteSuccess.
  ///
  /// In en, this message translates to:
  /// **'Cross-page paste successful'**
  String get crossPagePasteSuccess;

  /// No description provided for @currentBackupPathNotSet.
  ///
  /// In en, this message translates to:
  /// **'Current backup path not set'**
  String get currentBackupPathNotSet;

  /// No description provided for @currentCharInversion.
  ///
  /// In en, this message translates to:
  /// **'Current Character Inversion'**
  String get currentCharInversion;

  /// No description provided for @currentCustomPath.
  ///
  /// In en, this message translates to:
  /// **'Currently using custom data path'**
  String get currentCustomPath;

  /// No description provided for @currentDataPath.
  ///
  /// In en, this message translates to:
  /// **'Current Data Path'**
  String get currentDataPath;

  /// No description provided for @currentDefaultPath.
  ///
  /// In en, this message translates to:
  /// **'Currently using default data path'**
  String get currentDefaultPath;

  /// No description provided for @currentLabel.
  ///
  /// In en, this message translates to:
  /// **'Current'**
  String get currentLabel;

  /// No description provided for @currentLocation.
  ///
  /// In en, this message translates to:
  /// **'Current Location'**
  String get currentLocation;

  /// No description provided for @currentPage.
  ///
  /// In en, this message translates to:
  /// **'Current Page'**
  String get currentPage;

  /// No description provided for @currentPath.
  ///
  /// In en, this message translates to:
  /// **'Current Path'**
  String get currentPath;

  /// No description provided for @currentPathBackup.
  ///
  /// In en, this message translates to:
  /// **'Current Path Backup'**
  String get currentPathBackup;

  /// No description provided for @currentPathBackupDescription.
  ///
  /// In en, this message translates to:
  /// **'Current path backup'**
  String get currentPathBackupDescription;

  /// No description provided for @currentPathFileExists.
  ///
  /// In en, this message translates to:
  /// **'A backup file with the same name already exists in the current path:'**
  String get currentPathFileExists;

  /// No description provided for @currentPathFileExistsMessage.
  ///
  /// In en, this message translates to:
  /// **'A backup file with the same name already exists in the current path:'**
  String get currentPathFileExistsMessage;

  /// No description provided for @currentStorageInfo.
  ///
  /// In en, this message translates to:
  /// **'Current Storage Info'**
  String get currentStorageInfo;

  /// No description provided for @currentStorageInfoSubtitle.
  ///
  /// In en, this message translates to:
  /// **'View current storage space usage'**
  String get currentStorageInfoSubtitle;

  /// No description provided for @currentStorageInfoTitle.
  ///
  /// In en, this message translates to:
  /// **'Current Storage Info'**
  String get currentStorageInfoTitle;

  /// No description provided for @currentTool.
  ///
  /// In en, this message translates to:
  /// **'Current Tool'**
  String get currentTool;

  /// No description provided for @pageInfo.
  ///
  /// In en, this message translates to:
  /// **'Page'**
  String get pageInfo;

  /// No description provided for @custom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get custom;

  /// No description provided for @customPath.
  ///
  /// In en, this message translates to:
  /// **'Custom Path'**
  String get customPath;

  /// No description provided for @customRange.
  ///
  /// In en, this message translates to:
  /// **'Custom Range'**
  String get customRange;

  /// No description provided for @customSize.
  ///
  /// In en, this message translates to:
  /// **'Custom Size'**
  String get customSize;

  /// No description provided for @cutSelected.
  ///
  /// In en, this message translates to:
  /// **'Cut Selected Items'**
  String get cutSelected;

  /// No description provided for @dangerZone.
  ///
  /// In en, this message translates to:
  /// **'Danger Zone'**
  String get dangerZone;

  /// No description provided for @dangerousOperationConfirm.
  ///
  /// In en, this message translates to:
  /// **'Dangerous Operation Confirmation'**
  String get dangerousOperationConfirm;

  /// No description provided for @dangerousOperationConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Dangerous Operation Confirmation'**
  String get dangerousOperationConfirmTitle;

  /// No description provided for @dartVersion.
  ///
  /// In en, this message translates to:
  /// **'Dart Version'**
  String get dartVersion;

  /// No description provided for @dataBackup.
  ///
  /// In en, this message translates to:
  /// **'Data Backup'**
  String get dataBackup;

  /// No description provided for @dataEmpty.
  ///
  /// In en, this message translates to:
  /// **'Data Empty'**
  String get dataEmpty;

  /// No description provided for @dataIncomplete.
  ///
  /// In en, this message translates to:
  /// **'Data Incomplete'**
  String get dataIncomplete;

  /// No description provided for @dataMergeOptions.
  ///
  /// In en, this message translates to:
  /// **'Data Merge Options:'**
  String get dataMergeOptions;

  /// No description provided for @dataPath.
  ///
  /// In en, this message translates to:
  /// **'Data Path'**
  String get dataPath;

  /// No description provided for @dataPathChangedMessage.
  ///
  /// In en, this message translates to:
  /// **'Data path has been changed. Please restart the application for changes to take effect.'**
  String get dataPathChangedMessage;

  /// No description provided for @dataPathHint.
  ///
  /// In en, this message translates to:
  /// **'Select data storage path'**
  String get dataPathHint;

  /// No description provided for @dataPathManagement.
  ///
  /// In en, this message translates to:
  /// **'Data Path Management'**
  String get dataPathManagement;

  /// No description provided for @dataPathManagementSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage current and historical data paths'**
  String get dataPathManagementSubtitle;

  /// No description provided for @dataPathManagementTitle.
  ///
  /// In en, this message translates to:
  /// **'Data Path Management'**
  String get dataPathManagementTitle;

  /// No description provided for @dataPathSettings.
  ///
  /// In en, this message translates to:
  /// **'Data Storage Path'**
  String get dataPathSettings;

  /// No description provided for @dataPathSettingsDescription.
  ///
  /// In en, this message translates to:
  /// **'Set the storage location for application data. Restart required after changes.'**
  String get dataPathSettingsDescription;

  /// No description provided for @dataPathSettingsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Configure application data storage location'**
  String get dataPathSettingsSubtitle;

  /// No description provided for @dataPathSwitchOptions.
  ///
  /// In en, this message translates to:
  /// **'Data Path Switch Options'**
  String get dataPathSwitchOptions;

  /// No description provided for @dataPathSwitchWizard.
  ///
  /// In en, this message translates to:
  /// **'Data Path Switch Wizard'**
  String get dataPathSwitchWizard;

  /// No description provided for @dataSafetyRecommendation.
  ///
  /// In en, this message translates to:
  /// **'Data Safety Recommendation'**
  String get dataSafetyRecommendation;

  /// No description provided for @dataSafetySuggestion.
  ///
  /// In en, this message translates to:
  /// **'Data Safety Suggestion'**
  String get dataSafetySuggestion;

  /// No description provided for @dataSafetySuggestions.
  ///
  /// In en, this message translates to:
  /// **'Data Safety Suggestions'**
  String get dataSafetySuggestions;

  /// No description provided for @dataSize.
  ///
  /// In en, this message translates to:
  /// **'Data Size'**
  String get dataSize;

  /// No description provided for @databaseSize.
  ///
  /// In en, this message translates to:
  /// **'Database Size'**
  String get databaseSize;

  /// No description provided for @dayBeforeYesterday.
  ///
  /// In en, this message translates to:
  /// **'Day Before Yesterday'**
  String get dayBeforeYesterday;

  /// No description provided for @days.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 day} other{{count} days}}'**
  String days(num count);

  /// No description provided for @daysAgo.
  ///
  /// In en, this message translates to:
  /// **'days ago'**
  String get daysAgo;

  /// No description provided for @defaultEditableText.
  ///
  /// In en, this message translates to:
  /// **'Editable Text in Property Panel'**
  String get defaultEditableText;

  /// No description provided for @defaultLayer.
  ///
  /// In en, this message translates to:
  /// **'Default Layer'**
  String get defaultLayer;

  /// No description provided for @defaultLayerName.
  ///
  /// In en, this message translates to:
  /// **'Layer {number}'**
  String defaultLayerName(Object number);

  /// No description provided for @defaultPage.
  ///
  /// In en, this message translates to:
  /// **'Default Page'**
  String get defaultPage;

  /// No description provided for @defaultPageName.
  ///
  /// In en, this message translates to:
  /// **'Page {number}'**
  String defaultPageName(Object number);

  /// No description provided for @defaultPath.
  ///
  /// In en, this message translates to:
  /// **'Default Path'**
  String get defaultPath;

  /// No description provided for @defaultPathName.
  ///
  /// In en, this message translates to:
  /// **'Default Path'**
  String get defaultPathName;

  /// No description provided for @degrees.
  ///
  /// In en, this message translates to:
  /// **'Degrees'**
  String get degrees;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete (Ctrl+D)'**
  String get delete;

  /// No description provided for @deleteAll.
  ///
  /// In en, this message translates to:
  /// **'Delete All'**
  String get deleteAll;

  /// No description provided for @deleteAllBackups.
  ///
  /// In en, this message translates to:
  /// **'Delete All Backups'**
  String get deleteAllBackups;

  /// No description provided for @deleteBackup.
  ///
  /// In en, this message translates to:
  /// **'Delete Backup'**
  String get deleteBackup;

  /// No description provided for @deleteBackupFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete backup'**
  String get deleteBackupFailed;

  /// No description provided for @deleteBackupsCountMessage.
  ///
  /// In en, this message translates to:
  /// **'You are about to delete {count} backup files.'**
  String deleteBackupsCountMessage(Object count);

  /// No description provided for @deleteCategory.
  ///
  /// In en, this message translates to:
  /// **'Delete Category'**
  String get deleteCategory;

  /// No description provided for @deleteCategoryOnly.
  ///
  /// In en, this message translates to:
  /// **'Delete Category Only'**
  String get deleteCategoryOnly;

  /// No description provided for @deleteCategoryWithFiles.
  ///
  /// In en, this message translates to:
  /// **'Delete Category and Files'**
  String get deleteCategoryWithFiles;

  /// No description provided for @deleteCharacterFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete character: {error}'**
  String deleteCharacterFailed(Object error);

  /// No description provided for @deleteCompleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Complete'**
  String get deleteCompleteTitle;

  /// No description provided for @deleteConfigItem.
  ///
  /// In en, this message translates to:
  /// **'Delete Configuration Item'**
  String get deleteConfigItem;

  /// No description provided for @deleteConfigItemMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this configuration item? This action cannot be undone.'**
  String get deleteConfigItemMessage;

  /// No description provided for @deleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm Delete'**
  String get deleteConfirm;

  /// No description provided for @deleteElementConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'Confirm Delete These Elements?'**
  String get deleteElementConfirmMessage;

  /// No description provided for @deleteFailCount.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete: {count} files'**
  String deleteFailCount(Object count);

  /// No description provided for @deleteFailDetails.
  ///
  /// In en, this message translates to:
  /// **'Failure details:'**
  String get deleteFailDetails;

  /// No description provided for @deleteFailed.
  ///
  /// In en, this message translates to:
  /// **'Delete Failed: {error}'**
  String deleteFailed(Object error);

  /// No description provided for @deleteFailedMessage.
  ///
  /// In en, this message translates to:
  /// **'Delete failed: {error}'**
  String deleteFailedMessage(Object error);

  /// No description provided for @deleteFailure.
  ///
  /// In en, this message translates to:
  /// **'Backup Delete Failed'**
  String get deleteFailure;

  /// No description provided for @deleteGroup.
  ///
  /// In en, this message translates to:
  /// **'Delete Group'**
  String get deleteGroup;

  /// No description provided for @deleteGroupConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm Delete Group'**
  String get deleteGroupConfirm;

  /// No description provided for @deleteHistoryPathNote.
  ///
  /// In en, this message translates to:
  /// **'Note: This will only delete the record, not the actual folder and data.'**
  String get deleteHistoryPathNote;

  /// No description provided for @deleteHistoryPathRecord.
  ///
  /// In en, this message translates to:
  /// **'Delete History Path Record'**
  String get deleteHistoryPathRecord;

  /// No description provided for @deleteImage.
  ///
  /// In en, this message translates to:
  /// **'Delete Image'**
  String get deleteImage;

  /// No description provided for @deleteLastMessage.
  ///
  /// In en, this message translates to:
  /// **'This is the last item. Are you sure you want to delete it?'**
  String get deleteLastMessage;

  /// No description provided for @deleteLayer.
  ///
  /// In en, this message translates to:
  /// **'Delete Layer'**
  String get deleteLayer;

  /// No description provided for @deleteLayerConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'Confirm Delete This Layer?'**
  String get deleteLayerConfirmMessage;

  /// No description provided for @deleteLayerMessage.
  ///
  /// In en, this message translates to:
  /// **'All elements on this layer will be deleted. This action cannot be undone.'**
  String get deleteLayerMessage;

  /// No description provided for @deleteMessage.
  ///
  /// In en, this message translates to:
  /// **'Confirm Delete This Item?'**
  String deleteMessage(Object count);

  /// No description provided for @deletePage.
  ///
  /// In en, this message translates to:
  /// **'Delete Page'**
  String get deletePage;

  /// No description provided for @deletePath.
  ///
  /// In en, this message translates to:
  /// **'Delete Path'**
  String get deletePath;

  /// No description provided for @deletePathButton.
  ///
  /// In en, this message translates to:
  /// **'Delete Path'**
  String get deletePathButton;

  /// No description provided for @deletePathConfirmContent.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete the entire backup path?\\n\\nPath: {path}\\n\\nThis will:\\n• Delete all backup files in this path\\n• Remove this path from history\\n• This operation cannot be undone\\n\\nPlease proceed with caution!'**
  String deletePathConfirmContent(Object path);

  /// No description provided for @deleteRangeItem.
  ///
  /// In en, this message translates to:
  /// **'• {path}: {count} files'**
  String deleteRangeItem(Object count, Object path);

  /// No description provided for @deleteRangeTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete range includes:'**
  String get deleteRangeTitle;

  /// No description provided for @deleteSelected.
  ///
  /// In en, this message translates to:
  /// **'Delete Selected'**
  String get deleteSelected;

  /// No description provided for @deleteSelectedArea.
  ///
  /// In en, this message translates to:
  /// **'Delete Selected Area'**
  String get deleteSelectedArea;

  /// No description provided for @deleteSelectedWithShortcut.
  ///
  /// In en, this message translates to:
  /// **'Delete Selected (Ctrl+D)'**
  String get deleteSelectedWithShortcut;

  /// No description provided for @deleteSuccess.
  ///
  /// In en, this message translates to:
  /// **'Backup Delete Successful'**
  String get deleteSuccess;

  /// No description provided for @deleteSuccessCount.
  ///
  /// In en, this message translates to:
  /// **'Successfully deleted: {count} files'**
  String deleteSuccessCount(Object count);

  /// No description provided for @deleteText.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get deleteText;

  /// No description provided for @deleting.
  ///
  /// In en, this message translates to:
  /// **'Deleting...'**
  String get deleting;

  /// No description provided for @deletingBackups.
  ///
  /// In en, this message translates to:
  /// **'Deleting backups...'**
  String get deletingBackups;

  /// No description provided for @deletingBackupsProgress.
  ///
  /// In en, this message translates to:
  /// **'Deleting backup files, please wait...'**
  String get deletingBackupsProgress;

  /// No description provided for @descending.
  ///
  /// In en, this message translates to:
  /// **'Descending'**
  String get descending;

  /// No description provided for @descriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get descriptionLabel;

  /// No description provided for @deselectAll.
  ///
  /// In en, this message translates to:
  /// **'Deselect All'**
  String get deselectAll;

  /// No description provided for @detail.
  ///
  /// In en, this message translates to:
  /// **'Detail'**
  String get detail;

  /// No description provided for @detailedError.
  ///
  /// In en, this message translates to:
  /// **'Detailed error'**
  String get detailedError;

  /// No description provided for @detailedReport.
  ///
  /// In en, this message translates to:
  /// **'Detailed Report'**
  String get detailedReport;

  /// No description provided for @deviceInfo.
  ///
  /// In en, this message translates to:
  /// **'Device Info'**
  String get deviceInfo;

  /// No description provided for @dimensions.
  ///
  /// In en, this message translates to:
  /// **'Dimensions'**
  String get dimensions;

  /// No description provided for @directSwitch.
  ///
  /// In en, this message translates to:
  /// **'Switch Directly'**
  String get directSwitch;

  /// No description provided for @disabled.
  ///
  /// In en, this message translates to:
  /// **'Disabled'**
  String get disabled;

  /// No description provided for @disabledDescription.
  ///
  /// In en, this message translates to:
  /// **'Disabled - Hide in selector'**
  String get disabledDescription;

  /// No description provided for @diskCacheSize.
  ///
  /// In en, this message translates to:
  /// **'Disk Cache Size'**
  String get diskCacheSize;

  /// No description provided for @diskCacheSizeDescription.
  ///
  /// In en, this message translates to:
  /// **'Maximum size of disk cache'**
  String get diskCacheSizeDescription;

  /// No description provided for @diskCacheTtl.
  ///
  /// In en, this message translates to:
  /// **'Disk Cache TTL'**
  String get diskCacheTtl;

  /// No description provided for @diskCacheTtlDescription.
  ///
  /// In en, this message translates to:
  /// **'Time for cache files to be preserved on disk'**
  String get diskCacheTtlDescription;

  /// No description provided for @displayMode.
  ///
  /// In en, this message translates to:
  /// **'Display Mode'**
  String get displayMode;

  /// No description provided for @displayName.
  ///
  /// In en, this message translates to:
  /// **'Display Name'**
  String get displayName;

  /// No description provided for @displayNameCannotBeEmpty.
  ///
  /// In en, this message translates to:
  /// **'Display name cannot be empty'**
  String get displayNameCannotBeEmpty;

  /// No description provided for @displayNameHint.
  ///
  /// In en, this message translates to:
  /// **'Name displayed in the user interface'**
  String get displayNameHint;

  /// No description provided for @displayNameMaxLength.
  ///
  /// In en, this message translates to:
  /// **'Display name can be at most 100 characters'**
  String get displayNameMaxLength;

  /// No description provided for @displayNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter display name'**
  String get displayNameRequired;

  /// No description provided for @distributeHorizontally.
  ///
  /// In en, this message translates to:
  /// **'Distribute Horizontally'**
  String get distributeHorizontally;

  /// No description provided for @distributeVertically.
  ///
  /// In en, this message translates to:
  /// **'Distribute Vertically'**
  String get distributeVertically;

  /// No description provided for @distribution.
  ///
  /// In en, this message translates to:
  /// **'Distribution'**
  String get distribution;

  /// No description provided for @doNotCloseApp.
  ///
  /// In en, this message translates to:
  /// **'Please do not close the application...'**
  String get doNotCloseApp;

  /// No description provided for @doNotCloseAppMessage.
  ///
  /// In en, this message translates to:
  /// **'Do not close the application'**
  String get doNotCloseAppMessage;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @dropToImportImages.
  ///
  /// In en, this message translates to:
  /// **'Drop to Import Images'**
  String get dropToImportImages;

  /// No description provided for @duplicateBackupFound.
  ///
  /// In en, this message translates to:
  /// **'Duplicate Backup Found'**
  String get duplicateBackupFound;

  /// No description provided for @duplicateBackupFoundDesc.
  ///
  /// In en, this message translates to:
  /// **'The backup file you\'re importing is a duplicate of an existing backup:'**
  String get duplicateBackupFoundDesc;

  /// No description provided for @duplicateFileImported.
  ///
  /// In en, this message translates to:
  /// **'(duplicate file imported)'**
  String get duplicateFileImported;

  /// No description provided for @dynasty.
  ///
  /// In en, this message translates to:
  /// **'Dynasty'**
  String get dynasty;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @editConfigItem.
  ///
  /// In en, this message translates to:
  /// **'Edit Configuration Item'**
  String get editConfigItem;

  /// No description provided for @editField.
  ///
  /// In en, this message translates to:
  /// **'Edit {field}'**
  String editField(Object field);

  /// No description provided for @editGroupContents.
  ///
  /// In en, this message translates to:
  /// **'Edit Group Contents'**
  String get editGroupContents;

  /// No description provided for @editGroupContentsDescription.
  ///
  /// In en, this message translates to:
  /// **'Edit the contents of the selected group'**
  String get editGroupContentsDescription;

  /// No description provided for @editLabel.
  ///
  /// In en, this message translates to:
  /// **'Edit {label}'**
  String editLabel(Object label);

  /// No description provided for @editOperations.
  ///
  /// In en, this message translates to:
  /// **'Edit Operations'**
  String get editOperations;

  /// No description provided for @editTags.
  ///
  /// In en, this message translates to:
  /// **'Edit Tags'**
  String get editTags;

  /// No description provided for @editTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Title'**
  String get editTitle;

  /// No description provided for @elementCopied.
  ///
  /// In en, this message translates to:
  /// **'Element Copied to Clipboard'**
  String get elementCopied;

  /// No description provided for @elementCopiedToClipboard.
  ///
  /// In en, this message translates to:
  /// **'Element Copied to Clipboard'**
  String get elementCopiedToClipboard;

  /// No description provided for @elementHeight.
  ///
  /// In en, this message translates to:
  /// **'Height'**
  String get elementHeight;

  /// No description provided for @elementId.
  ///
  /// In en, this message translates to:
  /// **'Element ID'**
  String get elementId;

  /// No description provided for @elementSize.
  ///
  /// In en, this message translates to:
  /// **'Size'**
  String get elementSize;

  /// No description provided for @elementWidth.
  ///
  /// In en, this message translates to:
  /// **'Width'**
  String get elementWidth;

  /// No description provided for @elements.
  ///
  /// In en, this message translates to:
  /// **'Elements'**
  String get elements;

  /// No description provided for @empty.
  ///
  /// In en, this message translates to:
  /// **'Empty'**
  String get empty;

  /// No description provided for @emptyGroup.
  ///
  /// In en, this message translates to:
  /// **'Empty Group'**
  String get emptyGroup;

  /// No description provided for @emptyStateError.
  ///
  /// In en, this message translates to:
  /// **'Load Failed, Please Try Again Later'**
  String get emptyStateError;

  /// No description provided for @emptyStateNoCharacters.
  ///
  /// In en, this message translates to:
  /// **'No Characters Found, View Here After Extracting Characters from Works'**
  String get emptyStateNoCharacters;

  /// No description provided for @emptyStateNoPractices.
  ///
  /// In en, this message translates to:
  /// **'No Practices Found, Click Add Button to Create New Practice'**
  String get emptyStateNoPractices;

  /// No description provided for @emptyStateNoResults.
  ///
  /// In en, this message translates to:
  /// **'No Matching Results Found, Try Changing Search Criteria'**
  String get emptyStateNoResults;

  /// No description provided for @emptyStateNoSelection.
  ///
  /// In en, this message translates to:
  /// **'No Items Selected, Click Item to Select'**
  String get emptyStateNoSelection;

  /// No description provided for @emptyStateNoWorks.
  ///
  /// In en, this message translates to:
  /// **'No Works Found, Click Add Button to Import Works'**
  String get emptyStateNoWorks;

  /// No description provided for @enableBinarization.
  ///
  /// In en, this message translates to:
  /// **'Enable Binarization'**
  String get enableBinarization;

  /// No description provided for @enabled.
  ///
  /// In en, this message translates to:
  /// **'Enabled'**
  String get enabled;

  /// No description provided for @endDate.
  ///
  /// In en, this message translates to:
  /// **'End Date'**
  String get endDate;

  /// No description provided for @ensureCompleteTransfer.
  ///
  /// In en, this message translates to:
  /// **'• Ensure complete file transfer'**
  String get ensureCompleteTransfer;

  /// No description provided for @ensureReadWritePermission.
  ///
  /// In en, this message translates to:
  /// **'Ensure the new path has read/write permissions'**
  String get ensureReadWritePermission;

  /// No description provided for @enterBackupDescription.
  ///
  /// In en, this message translates to:
  /// **'Enter backup description (optional):'**
  String get enterBackupDescription;

  /// No description provided for @enterCategoryName.
  ///
  /// In en, this message translates to:
  /// **'Enter Category Name'**
  String get enterCategoryName;

  /// No description provided for @enterTagHint.
  ///
  /// In en, this message translates to:
  /// **'Enter Tag and Press Enter'**
  String get enterTagHint;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error: {message}'**
  String error(Object message);

  /// No description provided for @errors.
  ///
  /// In en, this message translates to:
  /// **'Errors'**
  String get errors;

  /// No description provided for @estimatedTime.
  ///
  /// In en, this message translates to:
  /// **'Estimated Time'**
  String get estimatedTime;

  /// No description provided for @executingImportOperation.
  ///
  /// In en, this message translates to:
  /// **'Executing import operation...'**
  String get executingImportOperation;

  /// No description provided for @existingBackupInfo.
  ///
  /// In en, this message translates to:
  /// **'Existing backup: {filename}'**
  String existingBackupInfo(Object filename);

  /// No description provided for @existingItem.
  ///
  /// In en, this message translates to:
  /// **'Existing Item'**
  String get existingItem;

  /// No description provided for @exit.
  ///
  /// In en, this message translates to:
  /// **'Exit'**
  String get exit;

  /// No description provided for @exitBatchMode.
  ///
  /// In en, this message translates to:
  /// **'Exit Batch Mode'**
  String get exitBatchMode;

  /// No description provided for @exitConfirm.
  ///
  /// In en, this message translates to:
  /// **'Exit'**
  String get exitConfirm;

  /// No description provided for @exitPreview.
  ///
  /// In en, this message translates to:
  /// **'Exit Preview Mode'**
  String get exitPreview;

  /// No description provided for @exitWizard.
  ///
  /// In en, this message translates to:
  /// **'Exit Wizard'**
  String get exitWizard;

  /// No description provided for @expand.
  ///
  /// In en, this message translates to:
  /// **'Expand'**
  String get expand;

  /// No description provided for @expandFileList.
  ///
  /// In en, this message translates to:
  /// **'Click to expand and view {count} backup files'**
  String expandFileList(Object count);

  /// No description provided for @export.
  ///
  /// In en, this message translates to:
  /// **'Export'**
  String get export;

  /// No description provided for @exportAllBackups.
  ///
  /// In en, this message translates to:
  /// **'Export All Backups'**
  String get exportAllBackups;

  /// No description provided for @exportAllBackupsButton.
  ///
  /// In en, this message translates to:
  /// **'Export All Backups'**
  String get exportAllBackupsButton;

  /// No description provided for @exportBackup.
  ///
  /// In en, this message translates to:
  /// **'Export Backup'**
  String get exportBackup;

  /// No description provided for @exportBackupFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to export backup'**
  String get exportBackupFailed;

  /// No description provided for @exportBackupFailedMessage.
  ///
  /// In en, this message translates to:
  /// **'Export failed: {error}'**
  String exportBackupFailedMessage(Object error);

  /// No description provided for @exportCharactersOnly.
  ///
  /// In en, this message translates to:
  /// **'Export Characters Only'**
  String get exportCharactersOnly;

  /// No description provided for @exportCharactersOnlyDescription.
  ///
  /// In en, this message translates to:
  /// **'Contains only selected character data'**
  String get exportCharactersOnlyDescription;

  /// No description provided for @exportCharactersWithWorks.
  ///
  /// In en, this message translates to:
  /// **'Export Characters with Works (Recommended)'**
  String get exportCharactersWithWorks;

  /// No description provided for @exportCharactersWithWorksDescription.
  ///
  /// In en, this message translates to:
  /// **'Contains characters and their source works data'**
  String get exportCharactersWithWorksDescription;

  /// No description provided for @exportCompleted.
  ///
  /// In en, this message translates to:
  /// **'Export completed: {success} successful{failed}'**
  String exportCompleted(Object failed, Object success);

  /// No description provided for @exportCompletedFormat.
  ///
  /// In en, this message translates to:
  /// **'Export completed: {successCount} successful{failedMessage}'**
  String exportCompletedFormat(Object failedMessage, Object successCount);

  /// No description provided for @exportCompletedFormat2.
  ///
  /// In en, this message translates to:
  /// **'Export completed, successful: {success}{failed}'**
  String exportCompletedFormat2(Object failed, Object success);

  /// No description provided for @exportConfig.
  ///
  /// In en, this message translates to:
  /// **'Export Configuration'**
  String get exportConfig;

  /// No description provided for @exportDialogRangeExample.
  ///
  /// In en, this message translates to:
  /// **'For Example: 1-3,5,7-9'**
  String get exportDialogRangeExample;

  /// No description provided for @exportDimensions.
  ///
  /// In en, this message translates to:
  /// **'{width}cm × {height}cm ({orientation})'**
  String exportDimensions(Object height, Object orientation, Object width);

  /// No description provided for @exportEncodingIssue.
  ///
  /// In en, this message translates to:
  /// **'• Special character encoding issues during export'**
  String get exportEncodingIssue;

  /// No description provided for @exportFailed.
  ///
  /// In en, this message translates to:
  /// **'Export failed'**
  String get exportFailed;

  /// No description provided for @exportFailedPartFormat.
  ///
  /// In en, this message translates to:
  /// **', {failCount} failed'**
  String exportFailedPartFormat(Object failCount);

  /// No description provided for @exportFailedPartFormat2.
  ///
  /// In en, this message translates to:
  /// **', failed: {count}'**
  String exportFailedPartFormat2(Object count);

  /// No description provided for @exportFailedWith.
  ///
  /// In en, this message translates to:
  /// **'Export failed: {error}'**
  String exportFailedWith(Object error);

  /// No description provided for @exportFailure.
  ///
  /// In en, this message translates to:
  /// **'Backup Export Failed'**
  String get exportFailure;

  /// No description provided for @exportFormat.
  ///
  /// In en, this message translates to:
  /// **'Export Format'**
  String get exportFormat;

  /// No description provided for @exportFullData.
  ///
  /// In en, this message translates to:
  /// **'Full Data Export'**
  String get exportFullData;

  /// No description provided for @exportFullDataDescription.
  ///
  /// In en, this message translates to:
  /// **'Contains all related data'**
  String get exportFullDataDescription;

  /// No description provided for @exportLocation.
  ///
  /// In en, this message translates to:
  /// **'Export Location'**
  String get exportLocation;

  /// No description provided for @exportNotImplemented.
  ///
  /// In en, this message translates to:
  /// **'Configuration export feature is under development'**
  String get exportNotImplemented;

  /// No description provided for @exportOptions.
  ///
  /// In en, this message translates to:
  /// **'Export Options'**
  String get exportOptions;

  /// No description provided for @exportSuccess.
  ///
  /// In en, this message translates to:
  /// **'Backup Export Successful'**
  String get exportSuccess;

  /// No description provided for @exportSuccessMessage.
  ///
  /// In en, this message translates to:
  /// **'Export successful: {path}'**
  String exportSuccessMessage(Object path);

  /// No description provided for @exportSummary.
  ///
  /// In en, this message translates to:
  /// **'Export Summary'**
  String get exportSummary;

  /// No description provided for @exportType.
  ///
  /// In en, this message translates to:
  /// **'Export Format'**
  String get exportType;

  /// No description provided for @exportWorksOnly.
  ///
  /// In en, this message translates to:
  /// **'Export Works Only'**
  String get exportWorksOnly;

  /// No description provided for @exportWorksOnlyDescription.
  ///
  /// In en, this message translates to:
  /// **'Contains only selected works data'**
  String get exportWorksOnlyDescription;

  /// No description provided for @exportWorksWithCharacters.
  ///
  /// In en, this message translates to:
  /// **'Export Works with Characters (Recommended)'**
  String get exportWorksWithCharacters;

  /// No description provided for @exportWorksWithCharactersDescription.
  ///
  /// In en, this message translates to:
  /// **'Contains works and their related character data'**
  String get exportWorksWithCharactersDescription;

  /// No description provided for @exporting.
  ///
  /// In en, this message translates to:
  /// **'Exporting, Please Wait...'**
  String get exporting;

  /// No description provided for @exportingBackup.
  ///
  /// In en, this message translates to:
  /// **'Exporting Backup...'**
  String get exportingBackup;

  /// No description provided for @exportingBackupMessage.
  ///
  /// In en, this message translates to:
  /// **'Exporting backup...'**
  String get exportingBackupMessage;

  /// No description provided for @exportingBackups.
  ///
  /// In en, this message translates to:
  /// **'Exporting {count} backups...'**
  String exportingBackups(Object count);

  /// No description provided for @exportingBackupsProgress.
  ///
  /// In en, this message translates to:
  /// **'Exporting backups...'**
  String get exportingBackupsProgress;

  /// No description provided for @exportingBackupsProgressFormat.
  ///
  /// In en, this message translates to:
  /// **'Exporting {count} backups...'**
  String exportingBackupsProgressFormat(Object count);

  /// No description provided for @exportingDescription.
  ///
  /// In en, this message translates to:
  /// **'Exporting data, please wait...'**
  String get exportingDescription;

  /// No description provided for @extract.
  ///
  /// In en, this message translates to:
  /// **'Extract'**
  String get extract;

  /// No description provided for @extractionError.
  ///
  /// In en, this message translates to:
  /// **'Extraction Error'**
  String get extractionError;

  /// No description provided for @failedCount.
  ///
  /// In en, this message translates to:
  /// **', {count} failed'**
  String failedCount(Object count);

  /// No description provided for @favorite.
  ///
  /// In en, this message translates to:
  /// **'Favorite'**
  String get favorite;

  /// No description provided for @favoritesOnly.
  ///
  /// In en, this message translates to:
  /// **'Favorites Only'**
  String get favoritesOnly;

  /// No description provided for @fileCorrupted.
  ///
  /// In en, this message translates to:
  /// **'• File corrupted during transfer'**
  String get fileCorrupted;

  /// No description provided for @fileCount.
  ///
  /// In en, this message translates to:
  /// **'File Count'**
  String get fileCount;

  /// No description provided for @fileExistsTitle.
  ///
  /// In en, this message translates to:
  /// **'File Already Exists'**
  String get fileExistsTitle;

  /// No description provided for @fileExtension.
  ///
  /// In en, this message translates to:
  /// **'File Extension'**
  String get fileExtension;

  /// No description provided for @fileMigrationWarning.
  ///
  /// In en, this message translates to:
  /// **'When not migrating files, old path backup files remain in original location'**
  String get fileMigrationWarning;

  /// No description provided for @fileName.
  ///
  /// In en, this message translates to:
  /// **'File Name'**
  String get fileName;

  /// No description provided for @fileNotExist.
  ///
  /// In en, this message translates to:
  /// **'File Not Found: {path}'**
  String fileNotExist(Object path);

  /// No description provided for @fileRestored.
  ///
  /// In en, this message translates to:
  /// **'Image Restored from Gallery'**
  String get fileRestored;

  /// No description provided for @fileSize.
  ///
  /// In en, this message translates to:
  /// **'File Size'**
  String get fileSize;

  /// No description provided for @fileUpdatedAt.
  ///
  /// In en, this message translates to:
  /// **'File Modified Time'**
  String get fileUpdatedAt;

  /// No description provided for @filenamePrefix.
  ///
  /// In en, this message translates to:
  /// **'Enter Filename Prefix (Page Numbers Will Be Added Automatically)'**
  String get filenamePrefix;

  /// No description provided for @files.
  ///
  /// In en, this message translates to:
  /// **'Number of Files'**
  String get files;

  /// No description provided for @filter.
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get filter;

  /// No description provided for @filterAndSort.
  ///
  /// In en, this message translates to:
  /// **'Filter and Sort'**
  String get filterAndSort;

  /// No description provided for @filterClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get filterClear;

  /// No description provided for @fineRotation.
  ///
  /// In en, this message translates to:
  /// **'Fine Rotation'**
  String get fineRotation;

  /// No description provided for @firstPage.
  ///
  /// In en, this message translates to:
  /// **'First Page'**
  String get firstPage;

  /// No description provided for @fitContain.
  ///
  /// In en, this message translates to:
  /// **'Contain'**
  String get fitContain;

  /// No description provided for @fitCover.
  ///
  /// In en, this message translates to:
  /// **'Cover'**
  String get fitCover;

  /// No description provided for @fitFill.
  ///
  /// In en, this message translates to:
  /// **'Fill'**
  String get fitFill;

  /// No description provided for @fitHeight.
  ///
  /// In en, this message translates to:
  /// **'Fit Height'**
  String get fitHeight;

  /// No description provided for @fitMode.
  ///
  /// In en, this message translates to:
  /// **'Fit Mode'**
  String get fitMode;

  /// No description provided for @fitWidth.
  ///
  /// In en, this message translates to:
  /// **'Fit Width'**
  String get fitWidth;

  /// No description provided for @flip.
  ///
  /// In en, this message translates to:
  /// **'Flip'**
  String get flip;

  /// No description provided for @flipHorizontal.
  ///
  /// In en, this message translates to:
  /// **'Flip Horizontal'**
  String get flipHorizontal;

  /// No description provided for @flipOptions.
  ///
  /// In en, this message translates to:
  /// **'Flip Options'**
  String get flipOptions;

  /// No description provided for @flipVertical.
  ///
  /// In en, this message translates to:
  /// **'Flip Vertical'**
  String get flipVertical;

  /// No description provided for @flutterVersion.
  ///
  /// In en, this message translates to:
  /// **'Flutter Version'**
  String get flutterVersion;

  /// No description provided for @folderImportComplete.
  ///
  /// In en, this message translates to:
  /// **'Folder Import Complete'**
  String get folderImportComplete;

  /// No description provided for @fontColor.
  ///
  /// In en, this message translates to:
  /// **'Font Color'**
  String get fontColor;

  /// No description provided for @fontFamily.
  ///
  /// In en, this message translates to:
  /// **'Font Family'**
  String get fontFamily;

  /// No description provided for @fontSize.
  ///
  /// In en, this message translates to:
  /// **'Font Size'**
  String get fontSize;

  /// No description provided for @fontStyle.
  ///
  /// In en, this message translates to:
  /// **'Font Style'**
  String get fontStyle;

  /// No description provided for @fontTester.
  ///
  /// In en, this message translates to:
  /// **'Font Tester'**
  String get fontTester;

  /// No description provided for @fontWeight.
  ///
  /// In en, this message translates to:
  /// **'Font Weight'**
  String get fontWeight;

  /// No description provided for @fontWeightTester.
  ///
  /// In en, this message translates to:
  /// **'Font Weight Tester'**
  String get fontWeightTester;

  /// No description provided for @format.
  ///
  /// In en, this message translates to:
  /// **'Format'**
  String get format;

  /// No description provided for @formatBrushActivated.
  ///
  /// In en, this message translates to:
  /// **'Format Brush Activated, Click Target Element to Apply Style'**
  String get formatBrushActivated;

  /// No description provided for @formatType.
  ///
  /// In en, this message translates to:
  /// **'Format Type'**
  String get formatType;

  /// No description provided for @fromGallery.
  ///
  /// In en, this message translates to:
  /// **'From Gallery'**
  String get fromGallery;

  /// No description provided for @fromLocal.
  ///
  /// In en, this message translates to:
  /// **'From Local'**
  String get fromLocal;

  /// No description provided for @fullScreen.
  ///
  /// In en, this message translates to:
  /// **'Full Screen'**
  String get fullScreen;

  /// No description provided for @geometryProperties.
  ///
  /// In en, this message translates to:
  /// **'Geometry Properties'**
  String get geometryProperties;

  /// No description provided for @getHistoryPathsFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to get history paths'**
  String get getHistoryPathsFailed;

  /// No description provided for @getPathInfoFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to get path information'**
  String get getPathInfoFailed;

  /// No description provided for @getPathUsageTimeFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to get path usage time'**
  String get getPathUsageTimeFailed;

  /// No description provided for @getStorageInfoFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to get storage info'**
  String get getStorageInfoFailed;

  /// No description provided for @getThumbnailSizeError.
  ///
  /// In en, this message translates to:
  /// **'Get Thumbnail Size Error'**
  String get getThumbnailSizeError;

  /// No description provided for @gettingPathInfo.
  ///
  /// In en, this message translates to:
  /// **'Getting path info...'**
  String get gettingPathInfo;

  /// No description provided for @gettingStorageInfo.
  ///
  /// In en, this message translates to:
  /// **'Getting storage info...'**
  String get gettingStorageInfo;

  /// No description provided for @gitBranch.
  ///
  /// In en, this message translates to:
  /// **'Git Branch'**
  String get gitBranch;

  /// No description provided for @gitCommit.
  ///
  /// In en, this message translates to:
  /// **'Git Commit'**
  String get gitCommit;

  /// No description provided for @goToBackup.
  ///
  /// In en, this message translates to:
  /// **'Go to Backup'**
  String get goToBackup;

  /// No description provided for @gridSettings.
  ///
  /// In en, this message translates to:
  /// **'Grid Settings'**
  String get gridSettings;

  /// No description provided for @gridSize.
  ///
  /// In en, this message translates to:
  /// **'Grid Size'**
  String get gridSize;

  /// No description provided for @gridSizeExtraLarge.
  ///
  /// In en, this message translates to:
  /// **'Extra Large'**
  String get gridSizeExtraLarge;

  /// No description provided for @gridSizeLarge.
  ///
  /// In en, this message translates to:
  /// **'Large'**
  String get gridSizeLarge;

  /// No description provided for @gridSizeMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get gridSizeMedium;

  /// No description provided for @gridSizeSmall.
  ///
  /// In en, this message translates to:
  /// **'Small'**
  String get gridSizeSmall;

  /// No description provided for @gridView.
  ///
  /// In en, this message translates to:
  /// **'Grid View'**
  String get gridView;

  /// No description provided for @group.
  ///
  /// In en, this message translates to:
  /// **'Group (Ctrl+J)'**
  String get group;

  /// No description provided for @groupElements.
  ///
  /// In en, this message translates to:
  /// **'Group Elements'**
  String get groupElements;

  /// No description provided for @groupOperations.
  ///
  /// In en, this message translates to:
  /// **'Group Operations'**
  String get groupOperations;

  /// No description provided for @groupProperties.
  ///
  /// In en, this message translates to:
  /// **'Group Properties'**
  String get groupProperties;

  /// No description provided for @height.
  ///
  /// In en, this message translates to:
  /// **'Height'**
  String get height;

  /// No description provided for @help.
  ///
  /// In en, this message translates to:
  /// **'Help'**
  String get help;

  /// No description provided for @hideDetails.
  ///
  /// In en, this message translates to:
  /// **'Hide Details'**
  String get hideDetails;

  /// No description provided for @hideElement.
  ///
  /// In en, this message translates to:
  /// **'Hide Element'**
  String get hideElement;

  /// No description provided for @hideGrid.
  ///
  /// In en, this message translates to:
  /// **'Hide Grid (Ctrl+G)'**
  String get hideGrid;

  /// No description provided for @hideImagePreview.
  ///
  /// In en, this message translates to:
  /// **'Hide Image Preview'**
  String get hideImagePreview;

  /// No description provided for @hideThumbnails.
  ///
  /// In en, this message translates to:
  /// **'Hide Page Thumbnails'**
  String get hideThumbnails;

  /// No description provided for @hideToolbar.
  ///
  /// In en, this message translates to:
  /// **'Hide Toolbar'**
  String get hideToolbar;

  /// No description provided for @historicalPaths.
  ///
  /// In en, this message translates to:
  /// **'Historical Paths'**
  String get historicalPaths;

  /// No description provided for @historyDataPaths.
  ///
  /// In en, this message translates to:
  /// **'Historical Data Paths'**
  String get historyDataPaths;

  /// No description provided for @historyLabel.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get historyLabel;

  /// No description provided for @historyLocation.
  ///
  /// In en, this message translates to:
  /// **'History Location'**
  String get historyLocation;

  /// No description provided for @historyPath.
  ///
  /// In en, this message translates to:
  /// **'History Path'**
  String get historyPath;

  /// No description provided for @historyPathBackup.
  ///
  /// In en, this message translates to:
  /// **'Historical Path Backup'**
  String get historyPathBackup;

  /// No description provided for @historyPathBackupDescription.
  ///
  /// In en, this message translates to:
  /// **'Historical path backup'**
  String get historyPathBackupDescription;

  /// No description provided for @historyPathDeleted.
  ///
  /// In en, this message translates to:
  /// **'History path record deleted'**
  String get historyPathDeleted;

  /// No description provided for @homePage.
  ///
  /// In en, this message translates to:
  /// **'Home Page'**
  String get homePage;

  /// No description provided for @horizontalAlignment.
  ///
  /// In en, this message translates to:
  /// **'Horizontal Alignment'**
  String get horizontalAlignment;

  /// No description provided for @horizontalLeftToRight.
  ///
  /// In en, this message translates to:
  /// **'Horizontal Left to Right'**
  String get horizontalLeftToRight;

  /// No description provided for @horizontalRightToLeft.
  ///
  /// In en, this message translates to:
  /// **'Horizontal Right to Left'**
  String get horizontalRightToLeft;

  /// No description provided for @hours.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 hour} other{{count} hours}}'**
  String hours(num count);

  /// No description provided for @hoursAgo.
  ///
  /// In en, this message translates to:
  /// **'hours ago'**
  String get hoursAgo;

  /// No description provided for @image.
  ///
  /// In en, this message translates to:
  /// **'Image'**
  String get image;

  /// No description provided for @imageAlignment.
  ///
  /// In en, this message translates to:
  /// **'Image Alignment'**
  String get imageAlignment;

  /// No description provided for @imageCount.
  ///
  /// In en, this message translates to:
  /// **'Image Count'**
  String get imageCount;

  /// No description provided for @imageElement.
  ///
  /// In en, this message translates to:
  /// **'Image Element'**
  String get imageElement;

  /// No description provided for @imageExportFailed.
  ///
  /// In en, this message translates to:
  /// **'Image Export Failed'**
  String get imageExportFailed;

  /// No description provided for @imageFileNotExists.
  ///
  /// In en, this message translates to:
  /// **'Image File Not Exists'**
  String get imageFileNotExists;

  /// No description provided for @imageImportError.
  ///
  /// In en, this message translates to:
  /// **'Image Import Error: {error}'**
  String imageImportError(Object error);

  /// No description provided for @imageImportSuccess.
  ///
  /// In en, this message translates to:
  /// **'Image Import Success'**
  String get imageImportSuccess;

  /// No description provided for @imageIndexError.
  ///
  /// In en, this message translates to:
  /// **'Image Index Error'**
  String get imageIndexError;

  /// No description provided for @imageInvalid.
  ///
  /// In en, this message translates to:
  /// **'Image Invalid'**
  String get imageInvalid;

  /// No description provided for @imageInvert.
  ///
  /// In en, this message translates to:
  /// **'Image Invert'**
  String get imageInvert;

  /// No description provided for @imageLoadError.
  ///
  /// In en, this message translates to:
  /// **'Image Load Error: {error}'**
  String imageLoadError(Object error);

  /// No description provided for @imageLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Image Load Failed'**
  String get imageLoadFailed;

  /// No description provided for @imageNameInfo.
  ///
  /// In en, this message translates to:
  /// **'Image Name'**
  String get imageNameInfo;

  /// No description provided for @imageProcessingPathError.
  ///
  /// In en, this message translates to:
  /// **'Image Processing Path Error: {error}'**
  String imageProcessingPathError(Object error);

  /// No description provided for @imageProperties.
  ///
  /// In en, this message translates to:
  /// **'Image Properties'**
  String get imageProperties;

  /// No description provided for @imagePropertyPanelAutoImportNotice.
  ///
  /// In en, this message translates to:
  /// **'Selected images will be automatically imported into your gallery for better management'**
  String get imagePropertyPanelAutoImportNotice;

  /// No description provided for @imagePropertyPanelFlipInfo.
  ///
  /// In en, this message translates to:
  /// **'Flip effects are processed at the canvas rendering stage and take effect immediately without reprocessing image data. Flip is a pure visual transformation, independent of the image processing pipeline.'**
  String get imagePropertyPanelFlipInfo;

  /// No description provided for @imagePropertyPanelGeometryWarning.
  ///
  /// In en, this message translates to:
  /// **'These properties adjust the entire element box, not the image content itself'**
  String get imagePropertyPanelGeometryWarning;

  /// No description provided for @imagePropertyPanelPreviewNotice.
  ///
  /// In en, this message translates to:
  /// **'Note: Duplicate logs displayed during preview are normal'**
  String get imagePropertyPanelPreviewNotice;

  /// No description provided for @imagePropertyPanelTransformWarning.
  ///
  /// In en, this message translates to:
  /// **'These transformations modify the image content itself, not just the element frame'**
  String get imagePropertyPanelTransformWarning;

  /// No description provided for @imageResetSuccess.
  ///
  /// In en, this message translates to:
  /// **'Reset Successful'**
  String get imageResetSuccess;

  /// No description provided for @imageRestoring.
  ///
  /// In en, this message translates to:
  /// **'Restoring Image Data...'**
  String get imageRestoring;

  /// No description provided for @imageSelection.
  ///
  /// In en, this message translates to:
  /// **'Image Selection'**
  String get imageSelection;

  /// No description provided for @imageSizeInfo.
  ///
  /// In en, this message translates to:
  /// **'Image Size'**
  String get imageSizeInfo;

  /// No description provided for @imageTransform.
  ///
  /// In en, this message translates to:
  /// **'Image Transform'**
  String get imageTransform;

  /// No description provided for @imageTransformError.
  ///
  /// In en, this message translates to:
  /// **'Image Transform Error: {error}'**
  String imageTransformError(Object error);

  /// No description provided for @imageUpdated.
  ///
  /// In en, this message translates to:
  /// **'Image Updated'**
  String get imageUpdated;

  /// No description provided for @images.
  ///
  /// In en, this message translates to:
  /// **'Images'**
  String get images;

  /// No description provided for @implementationComingSoon.
  ///
  /// In en, this message translates to:
  /// **'This feature is under development, please stay tuned!'**
  String get implementationComingSoon;

  /// No description provided for @import.
  ///
  /// In en, this message translates to:
  /// **'Import'**
  String get import;

  /// No description provided for @importBackup.
  ///
  /// In en, this message translates to:
  /// **'Import Backup'**
  String get importBackup;

  /// No description provided for @importBackupFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to import backup'**
  String get importBackupFailed;

  /// No description provided for @importBackupFailedMessage.
  ///
  /// In en, this message translates to:
  /// **'Failed to import backup: {error}'**
  String importBackupFailedMessage(Object error);

  /// No description provided for @importBackupProgressDialog.
  ///
  /// In en, this message translates to:
  /// **'Importing backup to current path...'**
  String get importBackupProgressDialog;

  /// No description provided for @importBackupSuccessMessage.
  ///
  /// In en, this message translates to:
  /// **'Backup imported to current path successfully'**
  String get importBackupSuccessMessage;

  /// No description provided for @importConfig.
  ///
  /// In en, this message translates to:
  /// **'Import Configuration'**
  String get importConfig;

  /// No description provided for @importError.
  ///
  /// In en, this message translates to:
  /// **'Import Error'**
  String get importError;

  /// No description provided for @importErrorCauses.
  ///
  /// In en, this message translates to:
  /// **'This issue is usually caused by the following reasons:'**
  String get importErrorCauses;

  /// No description provided for @importFailed.
  ///
  /// In en, this message translates to:
  /// **'Import Failed: {error}'**
  String importFailed(Object error);

  /// No description provided for @importFailure.
  ///
  /// In en, this message translates to:
  /// **'Backup Import Failed'**
  String get importFailure;

  /// No description provided for @importFileSuccess.
  ///
  /// In en, this message translates to:
  /// **'Import File Success'**
  String get importFileSuccess;

  /// No description provided for @importFiles.
  ///
  /// In en, this message translates to:
  /// **'Import Files'**
  String get importFiles;

  /// No description provided for @importFolder.
  ///
  /// In en, this message translates to:
  /// **'Import Folder'**
  String get importFolder;

  /// No description provided for @importNotImplemented.
  ///
  /// In en, this message translates to:
  /// **'Configuration import feature is under development'**
  String get importNotImplemented;

  /// No description provided for @importOptions.
  ///
  /// In en, this message translates to:
  /// **'Import Options'**
  String get importOptions;

  /// No description provided for @importPreview.
  ///
  /// In en, this message translates to:
  /// **'Import Preview'**
  String get importPreview;

  /// No description provided for @importRequirements.
  ///
  /// In en, this message translates to:
  /// **'Import Requirements'**
  String get importRequirements;

  /// No description provided for @importResultTitle.
  ///
  /// In en, this message translates to:
  /// **'Import Result'**
  String get importResultTitle;

  /// No description provided for @importStatistics.
  ///
  /// In en, this message translates to:
  /// **'Import Statistics'**
  String get importStatistics;

  /// No description provided for @importSuccess.
  ///
  /// In en, this message translates to:
  /// **'Backup Import Success'**
  String get importSuccess;

  /// No description provided for @importSuccessMessage.
  ///
  /// In en, this message translates to:
  /// **'Successfully imported {count} files'**
  String importSuccessMessage(Object count);

  /// No description provided for @importToCurrentPath.
  ///
  /// In en, this message translates to:
  /// **'Import to Current Path'**
  String get importToCurrentPath;

  /// No description provided for @importToCurrentPathButton.
  ///
  /// In en, this message translates to:
  /// **'Import to Current Path'**
  String get importToCurrentPathButton;

  /// No description provided for @importToCurrentPathConfirm.
  ///
  /// In en, this message translates to:
  /// **'Import to Current Path'**
  String get importToCurrentPathConfirm;

  /// No description provided for @importToCurrentPathDesc.
  ///
  /// In en, this message translates to:
  /// **'This will copy the backup file to current path, original file remains unchanged.'**
  String get importToCurrentPathDesc;

  /// No description provided for @importToCurrentPathDescription.
  ///
  /// In en, this message translates to:
  /// **'This will copy the backup file to the current path, original file remains unchanged.'**
  String get importToCurrentPathDescription;

  /// No description provided for @importToCurrentPathDialogContent.
  ///
  /// In en, this message translates to:
  /// **'This will import the backup to the current backup path. Are you sure you want to continue?'**
  String get importToCurrentPathDialogContent;

  /// No description provided for @importToCurrentPathFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to import backup to current path'**
  String get importToCurrentPathFailed;

  /// No description provided for @importToCurrentPathMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to import this backup to the current backup path?'**
  String get importToCurrentPathMessage;

  /// No description provided for @importToCurrentPathSuccessMessage.
  ///
  /// In en, this message translates to:
  /// **'Backup successfully imported to current path'**
  String get importToCurrentPathSuccessMessage;

  /// No description provided for @importToCurrentPathTitle.
  ///
  /// In en, this message translates to:
  /// **'Import to Current Path'**
  String get importToCurrentPathTitle;

  /// No description provided for @importantReminder.
  ///
  /// In en, this message translates to:
  /// **'Important Reminder'**
  String get importantReminder;

  /// No description provided for @importedBackupDescription.
  ///
  /// In en, this message translates to:
  /// **'Imported backup'**
  String get importedBackupDescription;

  /// No description provided for @importedCharacters.
  ///
  /// In en, this message translates to:
  /// **'Imported Characters'**
  String get importedCharacters;

  /// No description provided for @importedFile.
  ///
  /// In en, this message translates to:
  /// **'Imported File'**
  String get importedFile;

  /// No description provided for @importedImages.
  ///
  /// In en, this message translates to:
  /// **'Imported Images'**
  String get importedImages;

  /// No description provided for @importedSuffix.
  ///
  /// In en, this message translates to:
  /// **'Imported Backup'**
  String get importedSuffix;

  /// No description provided for @importedWorks.
  ///
  /// In en, this message translates to:
  /// **'Imported Works'**
  String get importedWorks;

  /// No description provided for @importing.
  ///
  /// In en, this message translates to:
  /// **'Importing...'**
  String get importing;

  /// No description provided for @importingBackup.
  ///
  /// In en, this message translates to:
  /// **'Importing backup...'**
  String get importingBackup;

  /// No description provided for @importingBackupProgressMessage.
  ///
  /// In en, this message translates to:
  /// **'Importing backup...'**
  String get importingBackupProgressMessage;

  /// No description provided for @importingDescription.
  ///
  /// In en, this message translates to:
  /// **'Importing data, please wait...'**
  String get importingDescription;

  /// No description provided for @importingToCurrentPath.
  ///
  /// In en, this message translates to:
  /// **'Importing to current path...'**
  String get importingToCurrentPath;

  /// No description provided for @importingToCurrentPathMessage.
  ///
  /// In en, this message translates to:
  /// **'Importing backup to current path...'**
  String get importingToCurrentPathMessage;

  /// No description provided for @importingWorks.
  ///
  /// In en, this message translates to:
  /// **'Importing works...'**
  String get importingWorks;

  /// No description provided for @includeImages.
  ///
  /// In en, this message translates to:
  /// **'Include Images'**
  String get includeImages;

  /// No description provided for @includeImagesDescription.
  ///
  /// In en, this message translates to:
  /// **'Export related image files'**
  String get includeImagesDescription;

  /// No description provided for @includeMetadata.
  ///
  /// In en, this message translates to:
  /// **'Include Metadata'**
  String get includeMetadata;

  /// No description provided for @includeMetadataDescription.
  ///
  /// In en, this message translates to:
  /// **'Export creation time, tags and other metadata'**
  String get includeMetadataDescription;

  /// No description provided for @incompatibleCharset.
  ///
  /// In en, this message translates to:
  /// **'• Used incompatible character set'**
  String get incompatibleCharset;

  /// No description provided for @initializationFailed.
  ///
  /// In en, this message translates to:
  /// **'Initialization Failed: {error}'**
  String initializationFailed(Object error);

  /// No description provided for @initializing.
  ///
  /// In en, this message translates to:
  /// **'Initializing...'**
  String get initializing;

  /// No description provided for @inputCharacter.
  ///
  /// In en, this message translates to:
  /// **'Input Character'**
  String get inputCharacter;

  /// No description provided for @inputChineseContent.
  ///
  /// In en, this message translates to:
  /// **'Please enter Chinese content'**
  String get inputChineseContent;

  /// No description provided for @inputFieldHint.
  ///
  /// In en, this message translates to:
  /// **'Please enter {field}'**
  String inputFieldHint(Object field);

  /// No description provided for @inputFileName.
  ///
  /// In en, this message translates to:
  /// **'Input File Name'**
  String get inputFileName;

  /// No description provided for @inputHint.
  ///
  /// In en, this message translates to:
  /// **'Input Hint'**
  String get inputHint;

  /// No description provided for @inputNewTag.
  ///
  /// In en, this message translates to:
  /// **'Input New Tag...'**
  String get inputNewTag;

  /// No description provided for @inputTitle.
  ///
  /// In en, this message translates to:
  /// **'Input Title'**
  String get inputTitle;

  /// No description provided for @invalidFilename.
  ///
  /// In en, this message translates to:
  /// **'Invalid Filename'**
  String get invalidFilename;

  /// No description provided for @invalidNumber.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid number'**
  String get invalidNumber;

  /// No description provided for @invertMode.
  ///
  /// In en, this message translates to:
  /// **'Invert Mode'**
  String get invertMode;

  /// No description provided for @isActive.
  ///
  /// In en, this message translates to:
  /// **'Is Active'**
  String get isActive;

  /// No description provided for @itemsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} items'**
  String itemsCount(Object count);

  /// No description provided for @itemsPerPage.
  ///
  /// In en, this message translates to:
  /// **'{count} items/page'**
  String itemsPerPage(Object count);

  /// No description provided for @jsonFile.
  ///
  /// In en, this message translates to:
  /// **'JSON File'**
  String get jsonFile;

  /// No description provided for @justNow.
  ///
  /// In en, this message translates to:
  /// **'just now'**
  String get justNow;

  /// No description provided for @keepBackupCount.
  ///
  /// In en, this message translates to:
  /// **'Keep Backup Count'**
  String get keepBackupCount;

  /// No description provided for @keepBackupCountDescription.
  ///
  /// In en, this message translates to:
  /// **'Number of backups to keep before deleting old ones'**
  String get keepBackupCountDescription;

  /// No description provided for @keepExisting.
  ///
  /// In en, this message translates to:
  /// **'Keep Existing'**
  String get keepExisting;

  /// No description provided for @keepExistingDescription.
  ///
  /// In en, this message translates to:
  /// **'Keep existing data, skip import'**
  String get keepExistingDescription;

  /// No description provided for @key.
  ///
  /// In en, this message translates to:
  /// **'Key'**
  String get key;

  /// No description provided for @keyCannotBeEmpty.
  ///
  /// In en, this message translates to:
  /// **'Key cannot be empty'**
  String get keyCannotBeEmpty;

  /// No description provided for @keyExists.
  ///
  /// In en, this message translates to:
  /// **'Configuration key already exists'**
  String get keyExists;

  /// No description provided for @keyHelperText.
  ///
  /// In en, this message translates to:
  /// **'Can only contain letters, numbers, underscores and hyphens'**
  String get keyHelperText;

  /// No description provided for @keyHint.
  ///
  /// In en, this message translates to:
  /// **'Unique identifier for the configuration item'**
  String get keyHint;

  /// No description provided for @keyInvalidCharacters.
  ///
  /// In en, this message translates to:
  /// **'Key can only contain letters, numbers, underscores and hyphens'**
  String get keyInvalidCharacters;

  /// No description provided for @keyMaxLength.
  ///
  /// In en, this message translates to:
  /// **'Key can be at most 50 characters'**
  String get keyMaxLength;

  /// No description provided for @keyMinLength.
  ///
  /// In en, this message translates to:
  /// **'Key must be at least 2 characters'**
  String get keyMinLength;

  /// No description provided for @keyRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter configuration key'**
  String get keyRequired;

  /// No description provided for @landscape.
  ///
  /// In en, this message translates to:
  /// **'Landscape'**
  String get landscape;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @languageEn.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEn;

  /// No description provided for @languageJa.
  ///
  /// In en, this message translates to:
  /// **'日本語'**
  String get languageJa;

  /// No description provided for @languageKo.
  ///
  /// In en, this message translates to:
  /// **'한국어'**
  String get languageKo;

  /// No description provided for @languageSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get languageSystem;

  /// No description provided for @languageZh.
  ///
  /// In en, this message translates to:
  /// **'简体中文'**
  String get languageZh;

  /// No description provided for @languageZhTw.
  ///
  /// In en, this message translates to:
  /// **'繁體中文'**
  String get languageZhTw;

  /// No description provided for @last30Days.
  ///
  /// In en, this message translates to:
  /// **'Last 30 Days'**
  String get last30Days;

  /// No description provided for @last365Days.
  ///
  /// In en, this message translates to:
  /// **'Last 365 Days'**
  String get last365Days;

  /// No description provided for @last7Days.
  ///
  /// In en, this message translates to:
  /// **'Last 7 Days'**
  String get last7Days;

  /// No description provided for @last90Days.
  ///
  /// In en, this message translates to:
  /// **'Last 90 Days'**
  String get last90Days;

  /// No description provided for @lastBackup.
  ///
  /// In en, this message translates to:
  /// **'Last Backup'**
  String get lastBackup;

  /// No description provided for @lastBackupTime.
  ///
  /// In en, this message translates to:
  /// **'Last Backup Time'**
  String get lastBackupTime;

  /// No description provided for @lastMonth.
  ///
  /// In en, this message translates to:
  /// **'Last Month'**
  String get lastMonth;

  /// No description provided for @lastPage.
  ///
  /// In en, this message translates to:
  /// **'Last Page'**
  String get lastPage;

  /// No description provided for @lastUsed.
  ///
  /// In en, this message translates to:
  /// **'Last Used'**
  String get lastUsed;

  /// No description provided for @lastUsedTime.
  ///
  /// In en, this message translates to:
  /// **'Last used'**
  String get lastUsedTime;

  /// No description provided for @lastWeek.
  ///
  /// In en, this message translates to:
  /// **'Last Week'**
  String get lastWeek;

  /// No description provided for @lastYear.
  ///
  /// In en, this message translates to:
  /// **'Last Year'**
  String get lastYear;

  /// No description provided for @layer.
  ///
  /// In en, this message translates to:
  /// **'Layer'**
  String get layer;

  /// No description provided for @layer1.
  ///
  /// In en, this message translates to:
  /// **'Layer 1'**
  String get layer1;

  /// No description provided for @layerElements.
  ///
  /// In en, this message translates to:
  /// **'Layer Elements'**
  String get layerElements;

  /// No description provided for @layerInfo.
  ///
  /// In en, this message translates to:
  /// **'Layer Info'**
  String get layerInfo;

  /// No description provided for @layerName.
  ///
  /// In en, this message translates to:
  /// **'Layer {index}'**
  String layerName(Object index);

  /// No description provided for @layerOperations.
  ///
  /// In en, this message translates to:
  /// **'Layer Operations'**
  String get layerOperations;

  /// No description provided for @layerProperties.
  ///
  /// In en, this message translates to:
  /// **'Layer Properties'**
  String get layerProperties;

  /// No description provided for @leave.
  ///
  /// In en, this message translates to:
  /// **'Leave'**
  String get leave;

  /// No description provided for @legacyBackupDescription.
  ///
  /// In en, this message translates to:
  /// **'Legacy backup'**
  String get legacyBackupDescription;

  /// No description provided for @legacyDataPathDescription.
  ///
  /// In en, this message translates to:
  /// **'Legacy data path pending cleanup'**
  String get legacyDataPathDescription;

  /// No description provided for @letterSpacing.
  ///
  /// In en, this message translates to:
  /// **'Letter Spacing'**
  String get letterSpacing;

  /// No description provided for @library.
  ///
  /// In en, this message translates to:
  /// **'Library'**
  String get library;

  /// No description provided for @libraryCount.
  ///
  /// In en, this message translates to:
  /// **'Library Count'**
  String get libraryCount;

  /// No description provided for @libraryManagement.
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get libraryManagement;

  /// No description provided for @lineHeight.
  ///
  /// In en, this message translates to:
  /// **'Line Spacing'**
  String get lineHeight;

  /// No description provided for @lineThrough.
  ///
  /// In en, this message translates to:
  /// **'Line Through'**
  String get lineThrough;

  /// No description provided for @listView.
  ///
  /// In en, this message translates to:
  /// **'List View'**
  String get listView;

  /// No description provided for @loadBackupRegistryFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load backup registry'**
  String get loadBackupRegistryFailed;

  /// No description provided for @loadCharacterDataFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load character data: {error}'**
  String loadCharacterDataFailed(Object error);

  /// No description provided for @loadConfigFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load configuration'**
  String get loadConfigFailed;

  /// No description provided for @loadCurrentBackupPathFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load current backup path'**
  String get loadCurrentBackupPathFailed;

  /// No description provided for @loadDataFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load data'**
  String get loadDataFailed;

  /// No description provided for @loadFailed.
  ///
  /// In en, this message translates to:
  /// **'Load Failed'**
  String get loadFailed;

  /// No description provided for @loadPathInfoFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load path information'**
  String get loadPathInfoFailed;

  /// No description provided for @loadPracticeSheetFailed.
  ///
  /// In en, this message translates to:
  /// **'Load Practice Sheet Failed'**
  String get loadPracticeSheetFailed;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @loadingImage.
  ///
  /// In en, this message translates to:
  /// **'Loading Image...'**
  String get loadingImage;

  /// No description provided for @location.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get location;

  /// No description provided for @lock.
  ///
  /// In en, this message translates to:
  /// **'Lock'**
  String get lock;

  /// No description provided for @lockElement.
  ///
  /// In en, this message translates to:
  /// **'Lock Element'**
  String get lockElement;

  /// No description provided for @lockStatus.
  ///
  /// In en, this message translates to:
  /// **'Lock Status'**
  String get lockStatus;

  /// No description provided for @lockUnlockAllElements.
  ///
  /// In en, this message translates to:
  /// **'Lock/Unlock All Elements'**
  String get lockUnlockAllElements;

  /// No description provided for @locked.
  ///
  /// In en, this message translates to:
  /// **'Locked'**
  String get locked;

  /// No description provided for @manualBackupDescription.
  ///
  /// In en, this message translates to:
  /// **'Manually created backup'**
  String get manualBackupDescription;

  /// No description provided for @marginBottom.
  ///
  /// In en, this message translates to:
  /// **'Bottom'**
  String get marginBottom;

  /// No description provided for @marginLeft.
  ///
  /// In en, this message translates to:
  /// **'Left'**
  String get marginLeft;

  /// No description provided for @marginRight.
  ///
  /// In en, this message translates to:
  /// **'Right'**
  String get marginRight;

  /// No description provided for @marginTop.
  ///
  /// In en, this message translates to:
  /// **'Top'**
  String get marginTop;

  /// No description provided for @max.
  ///
  /// In en, this message translates to:
  /// **'Max'**
  String get max;

  /// No description provided for @memoryDataCacheCapacity.
  ///
  /// In en, this message translates to:
  /// **'Memory Data Cache Capacity'**
  String get memoryDataCacheCapacity;

  /// No description provided for @memoryDataCacheCapacityDescription.
  ///
  /// In en, this message translates to:
  /// **'Number of data items to keep in memory'**
  String get memoryDataCacheCapacityDescription;

  /// No description provided for @memoryImageCacheCapacity.
  ///
  /// In en, this message translates to:
  /// **'Memory Image Cache Capacity'**
  String get memoryImageCacheCapacity;

  /// No description provided for @memoryImageCacheCapacityDescription.
  ///
  /// In en, this message translates to:
  /// **'Number of images to keep in memory'**
  String get memoryImageCacheCapacityDescription;

  /// No description provided for @mergeAndMigrateFiles.
  ///
  /// In en, this message translates to:
  /// **'Merge and Migrate Files'**
  String get mergeAndMigrateFiles;

  /// No description provided for @mergeBackupInfo.
  ///
  /// In en, this message translates to:
  /// **'Merge Backup Info'**
  String get mergeBackupInfo;

  /// No description provided for @mergeBackupInfoDesc.
  ///
  /// In en, this message translates to:
  /// **'Merge old path backup info into new path registry'**
  String get mergeBackupInfoDesc;

  /// No description provided for @mergeData.
  ///
  /// In en, this message translates to:
  /// **'Merge Data'**
  String get mergeData;

  /// No description provided for @mergeDataDescription.
  ///
  /// In en, this message translates to:
  /// **'Combine existing and imported data'**
  String get mergeDataDescription;

  /// No description provided for @mergeOnlyBackupInfo.
  ///
  /// In en, this message translates to:
  /// **'Merge Backup Info Only'**
  String get mergeOnlyBackupInfo;

  /// No description provided for @metadata.
  ///
  /// In en, this message translates to:
  /// **'Metadata'**
  String get metadata;

  /// No description provided for @migrateBackupFiles.
  ///
  /// In en, this message translates to:
  /// **'Migrate Backup Files'**
  String get migrateBackupFiles;

  /// No description provided for @migrateBackupFilesDesc.
  ///
  /// In en, this message translates to:
  /// **'Copy old path backup files to new path (recommended)'**
  String get migrateBackupFilesDesc;

  /// No description provided for @migratingData.
  ///
  /// In en, this message translates to:
  /// **'Migrating Data'**
  String get migratingData;

  /// No description provided for @min.
  ///
  /// In en, this message translates to:
  /// **'Min'**
  String get min;

  /// No description provided for @monospace.
  ///
  /// In en, this message translates to:
  /// **'Monospace'**
  String get monospace;

  /// No description provided for @monthsAgo.
  ///
  /// In en, this message translates to:
  /// **'months ago'**
  String get monthsAgo;

  /// No description provided for @moreErrorsCount.
  ///
  /// In en, this message translates to:
  /// **'...and {count} more errors'**
  String moreErrorsCount(Object count);

  /// No description provided for @moveDown.
  ///
  /// In en, this message translates to:
  /// **'Move Down (Ctrl+Shift+B)'**
  String get moveDown;

  /// No description provided for @moveLayerDown.
  ///
  /// In en, this message translates to:
  /// **'Move Layer Down'**
  String get moveLayerDown;

  /// No description provided for @moveLayerUp.
  ///
  /// In en, this message translates to:
  /// **'Move Layer Up'**
  String get moveLayerUp;

  /// No description provided for @moveUp.
  ///
  /// In en, this message translates to:
  /// **'Move Up (Ctrl+Shift+T)'**
  String get moveUp;

  /// No description provided for @multiSelectTool.
  ///
  /// In en, this message translates to:
  /// **'Multi-Select Tool'**
  String get multiSelectTool;

  /// No description provided for @multipleFilesNote.
  ///
  /// In en, this message translates to:
  /// **'Note: {count} image files will be exported, and the filenames will be automatically numbered.'**
  String multipleFilesNote(Object count);

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @navCollapseSidebar.
  ///
  /// In en, this message translates to:
  /// **'Collapse Sidebar'**
  String get navCollapseSidebar;

  /// No description provided for @navExpandSidebar.
  ///
  /// In en, this message translates to:
  /// **'Expand Sidebar'**
  String get navExpandSidebar;

  /// No description provided for @navigatedToBackupSettings.
  ///
  /// In en, this message translates to:
  /// **'Navigated to backup settings page'**
  String get navigatedToBackupSettings;

  /// No description provided for @navigationAttemptBack.
  ///
  /// In en, this message translates to:
  /// **'Attempting to return to previous functional area'**
  String get navigationAttemptBack;

  /// No description provided for @navigationAttemptToNewSection.
  ///
  /// In en, this message translates to:
  /// **'Attempting to navigate to new functional area'**
  String get navigationAttemptToNewSection;

  /// No description provided for @navigationAttemptToSpecificItem.
  ///
  /// In en, this message translates to:
  /// **'Attempting to navigate to specific history item'**
  String get navigationAttemptToSpecificItem;

  /// No description provided for @navigationBackToPrevious.
  ///
  /// In en, this message translates to:
  /// **'Back to Previous Page'**
  String get navigationBackToPrevious;

  /// No description provided for @navigationClearHistory.
  ///
  /// In en, this message translates to:
  /// **'Clear Navigation History'**
  String get navigationClearHistory;

  /// No description provided for @navigationClearHistoryFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to clear navigation history'**
  String get navigationClearHistoryFailed;

  /// No description provided for @navigationClearHistorySuccess.
  ///
  /// In en, this message translates to:
  /// **'Navigation history cleared successfully'**
  String get navigationClearHistorySuccess;

  /// No description provided for @navigationFailedBack.
  ///
  /// In en, this message translates to:
  /// **'Failed to navigate back'**
  String get navigationFailedBack;

  /// No description provided for @navigationFailedInvalidHistoryItem.
  ///
  /// In en, this message translates to:
  /// **'Failed to navigate: invalid history item'**
  String get navigationFailedInvalidHistoryItem;

  /// No description provided for @navigationFailedNoHistory.
  ///
  /// In en, this message translates to:
  /// **'Cannot navigate back: no history available'**
  String get navigationFailedNoHistory;

  /// No description provided for @navigationFailedNoValidSection.
  ///
  /// In en, this message translates to:
  /// **'Failed to navigate: no valid section available'**
  String get navigationFailedNoValidSection;

  /// No description provided for @navigationFailedSection.
  ///
  /// In en, this message translates to:
  /// **'Failed to switch navigation'**
  String get navigationFailedSection;

  /// No description provided for @navigationFailedToBack.
  ///
  /// In en, this message translates to:
  /// **'Failed to navigate back to previous section'**
  String get navigationFailedToBack;

  /// No description provided for @navigationFailedToGoBack.
  ///
  /// In en, this message translates to:
  /// **'Failed to navigate back'**
  String get navigationFailedToGoBack;

  /// No description provided for @navigationFailedToNewSection.
  ///
  /// In en, this message translates to:
  /// **'Failed to navigate to new section'**
  String get navigationFailedToNewSection;

  /// No description provided for @navigationFailedToSpecificItem.
  ///
  /// In en, this message translates to:
  /// **'Failed to navigate to specific history item'**
  String get navigationFailedToSpecificItem;

  /// No description provided for @navigationHistoryCleared.
  ///
  /// In en, this message translates to:
  /// **'Navigation history has been cleared'**
  String get navigationHistoryCleared;

  /// No description provided for @navigationItemNotFound.
  ///
  /// In en, this message translates to:
  /// **'Target item not found in history, navigating directly to that functional area'**
  String get navigationItemNotFound;

  /// No description provided for @navigationNoHistory.
  ///
  /// In en, this message translates to:
  /// **'No History'**
  String get navigationNoHistory;

  /// No description provided for @navigationNoHistoryMessage.
  ///
  /// In en, this message translates to:
  /// **'You have reached the beginning of the current functional area.'**
  String get navigationNoHistoryMessage;

  /// No description provided for @navigationRecordRoute.
  ///
  /// In en, this message translates to:
  /// **'Recording route changes within functional area'**
  String get navigationRecordRoute;

  /// No description provided for @navigationRecordRouteFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to record route changes'**
  String get navigationRecordRouteFailed;

  /// No description provided for @navigationRestoreStateFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to restore navigation state'**
  String get navigationRestoreStateFailed;

  /// No description provided for @navigationSaveState.
  ///
  /// In en, this message translates to:
  /// **'Saving navigation state'**
  String get navigationSaveState;

  /// No description provided for @navigationSaveStateFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to save navigation state'**
  String get navigationSaveStateFailed;

  /// No description provided for @navigationSectionCharacterManagement.
  ///
  /// In en, this message translates to:
  /// **'Character Management'**
  String get navigationSectionCharacterManagement;

  /// No description provided for @navigationSectionGalleryManagement.
  ///
  /// In en, this message translates to:
  /// **'Gallery Management'**
  String get navigationSectionGalleryManagement;

  /// No description provided for @navigationSectionPracticeList.
  ///
  /// In en, this message translates to:
  /// **'Practice List'**
  String get navigationSectionPracticeList;

  /// No description provided for @navigationSectionSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navigationSectionSettings;

  /// No description provided for @navigationSectionWorkBrowse.
  ///
  /// In en, this message translates to:
  /// **'Work Browse'**
  String get navigationSectionWorkBrowse;

  /// No description provided for @navigationSelectPage.
  ///
  /// In en, this message translates to:
  /// **'Which page do you want to return to?'**
  String get navigationSelectPage;

  /// No description provided for @navigationStateRestored.
  ///
  /// In en, this message translates to:
  /// **'Navigation state has been restored from storage'**
  String get navigationStateRestored;

  /// No description provided for @navigationStateSaved.
  ///
  /// In en, this message translates to:
  /// **'Navigation state has been saved'**
  String get navigationStateSaved;

  /// No description provided for @navigationSuccessBack.
  ///
  /// In en, this message translates to:
  /// **'Successfully navigated back to previous section'**
  String get navigationSuccessBack;

  /// No description provided for @navigationSuccessToNewSection.
  ///
  /// In en, this message translates to:
  /// **'Successfully navigated to new section'**
  String get navigationSuccessToNewSection;

  /// No description provided for @navigationSuccessToSpecificItem.
  ///
  /// In en, this message translates to:
  /// **'Successfully navigated to specific history item'**
  String get navigationSuccessToSpecificItem;

  /// No description provided for @navigationToggleExpanded.
  ///
  /// In en, this message translates to:
  /// **'Toggle navigation bar expanded state'**
  String get navigationToggleExpanded;

  /// No description provided for @needRestartApp.
  ///
  /// In en, this message translates to:
  /// **'Need to Restart App'**
  String get needRestartApp;

  /// No description provided for @newConfigItem.
  ///
  /// In en, this message translates to:
  /// **'New Configuration Item'**
  String get newConfigItem;

  /// No description provided for @newDataPath.
  ///
  /// In en, this message translates to:
  /// **'New data path:'**
  String get newDataPath;

  /// No description provided for @newItem.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get newItem;

  /// No description provided for @nextField.
  ///
  /// In en, this message translates to:
  /// **'Next Field'**
  String get nextField;

  /// No description provided for @nextPage.
  ///
  /// In en, this message translates to:
  /// **'Next Page'**
  String get nextPage;

  /// No description provided for @nextStep.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get nextStep;

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @noBackupExistsRecommendCreate.
  ///
  /// In en, this message translates to:
  /// **'No backup exists yet, recommend creating backup first to ensure data safety'**
  String get noBackupExistsRecommendCreate;

  /// No description provided for @noBackupFilesInPath.
  ///
  /// In en, this message translates to:
  /// **'No backup files in this path'**
  String get noBackupFilesInPath;

  /// No description provided for @noBackupFilesInPathMessage.
  ///
  /// In en, this message translates to:
  /// **'No backup files in this path'**
  String get noBackupFilesInPathMessage;

  /// No description provided for @noBackupFilesToExport.
  ///
  /// In en, this message translates to:
  /// **'No backup files to export in this path'**
  String get noBackupFilesToExport;

  /// No description provided for @noBackupFilesToExportMessage.
  ///
  /// In en, this message translates to:
  /// **'No backup files to export in this path'**
  String get noBackupFilesToExportMessage;

  /// No description provided for @noBackupPathSetRecommendCreateBackup.
  ///
  /// In en, this message translates to:
  /// **'No backup path set, recommend setting backup path and creating backup first'**
  String get noBackupPathSetRecommendCreateBackup;

  /// No description provided for @noBackupPaths.
  ///
  /// In en, this message translates to:
  /// **'No backup paths'**
  String get noBackupPaths;

  /// No description provided for @noBackups.
  ///
  /// In en, this message translates to:
  /// **'No Backups Available'**
  String get noBackups;

  /// No description provided for @noBackupsInPath.
  ///
  /// In en, this message translates to:
  /// **'No backup files in this path'**
  String get noBackupsInPath;

  /// No description provided for @noBackupsToDelete.
  ///
  /// In en, this message translates to:
  /// **'No backup files to delete'**
  String get noBackupsToDelete;

  /// No description provided for @noCategories.
  ///
  /// In en, this message translates to:
  /// **'No Categories'**
  String get noCategories;

  /// No description provided for @noCharacters.
  ///
  /// In en, this message translates to:
  /// **'No Characters Found'**
  String get noCharacters;

  /// No description provided for @noCharactersFound.
  ///
  /// In en, this message translates to:
  /// **'No Matching Characters Found'**
  String get noCharactersFound;

  /// No description provided for @noConfigItems.
  ///
  /// In en, this message translates to:
  /// **'No {category} configurations'**
  String noConfigItems(Object category);

  /// No description provided for @noCropping.
  ///
  /// In en, this message translates to:
  /// **'(No Cropping)'**
  String get noCropping;

  /// No description provided for @noDisplayableImages.
  ///
  /// In en, this message translates to:
  /// **'No Displayable Images'**
  String get noDisplayableImages;

  /// No description provided for @noElementsInLayer.
  ///
  /// In en, this message translates to:
  /// **'No Elements in Layer'**
  String get noElementsInLayer;

  /// No description provided for @noElementsSelected.
  ///
  /// In en, this message translates to:
  /// **'No Elements Selected'**
  String get noElementsSelected;

  /// No description provided for @noHistoryPaths.
  ///
  /// In en, this message translates to:
  /// **'No Historical Paths'**
  String get noHistoryPaths;

  /// No description provided for @noHistoryPathsDescription.
  ///
  /// In en, this message translates to:
  /// **'No other data paths have been used yet'**
  String get noHistoryPathsDescription;

  /// No description provided for @noImageSelected.
  ///
  /// In en, this message translates to:
  /// **'No Image Selected'**
  String get noImageSelected;

  /// No description provided for @noImages.
  ///
  /// In en, this message translates to:
  /// **'No Images'**
  String get noImages;

  /// No description provided for @noItemsSelected.
  ///
  /// In en, this message translates to:
  /// **'No Items Selected'**
  String get noItemsSelected;

  /// No description provided for @noLayers.
  ///
  /// In en, this message translates to:
  /// **'No Layers, Please Add a Layer'**
  String get noLayers;

  /// No description provided for @noMatchingConfigItems.
  ///
  /// In en, this message translates to:
  /// **'No matching configuration items found'**
  String get noMatchingConfigItems;

  /// No description provided for @noPageSelected.
  ///
  /// In en, this message translates to:
  /// **'No Page Selected'**
  String get noPageSelected;

  /// No description provided for @noPagesToExport.
  ///
  /// In en, this message translates to:
  /// **'No Pages to Export'**
  String get noPagesToExport;

  /// No description provided for @noPagesToPrint.
  ///
  /// In en, this message translates to:
  /// **'No Pages to Print'**
  String get noPagesToPrint;

  /// No description provided for @noPreviewAvailable.
  ///
  /// In en, this message translates to:
  /// **'No preview available'**
  String get noPreviewAvailable;

  /// No description provided for @noRegionBoxed.
  ///
  /// In en, this message translates to:
  /// **'No Region Selected'**
  String get noRegionBoxed;

  /// No description provided for @noRemarks.
  ///
  /// In en, this message translates to:
  /// **'No Remarks'**
  String get noRemarks;

  /// No description provided for @noResults.
  ///
  /// In en, this message translates to:
  /// **'No Results Found'**
  String get noResults;

  /// No description provided for @noTags.
  ///
  /// In en, this message translates to:
  /// **'No Tags'**
  String get noTags;

  /// No description provided for @noTexture.
  ///
  /// In en, this message translates to:
  /// **'No Texture'**
  String get noTexture;

  /// No description provided for @noTopLevelCategory.
  ///
  /// In en, this message translates to:
  /// **'No (Top Level Category)'**
  String get noTopLevelCategory;

  /// No description provided for @noWorks.
  ///
  /// In en, this message translates to:
  /// **'No Works Found'**
  String get noWorks;

  /// No description provided for @noWorksHint.
  ///
  /// In en, this message translates to:
  /// **'Try importing new works or changing the filter criteria'**
  String get noWorksHint;

  /// No description provided for @noiseReduction.
  ///
  /// In en, this message translates to:
  /// **'Noise Reduction'**
  String get noiseReduction;

  /// No description provided for @noiseReductionLevel.
  ///
  /// In en, this message translates to:
  /// **'Noise Reduction Level'**
  String get noiseReductionLevel;

  /// No description provided for @noiseReductionToggle.
  ///
  /// In en, this message translates to:
  /// **'Noise Reduction Toggle'**
  String get noiseReductionToggle;

  /// No description provided for @none.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get none;

  /// No description provided for @notSet.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get notSet;

  /// No description provided for @note.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get note;

  /// No description provided for @notesTitle.
  ///
  /// In en, this message translates to:
  /// **'Notes:'**
  String get notesTitle;

  /// No description provided for @noticeTitle.
  ///
  /// In en, this message translates to:
  /// **'Notice'**
  String get noticeTitle;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @oldBackupRecommendCreateNew.
  ///
  /// In en, this message translates to:
  /// **'Last backup is over 24 hours old, recommend creating new backup'**
  String get oldBackupRecommendCreateNew;

  /// No description provided for @oldDataNotAutoDeleted.
  ///
  /// In en, this message translates to:
  /// **'Old data will not be automatically deleted after path switching'**
  String get oldDataNotAutoDeleted;

  /// No description provided for @oldDataNotDeleted.
  ///
  /// In en, this message translates to:
  /// **'Old data will not be automatically deleted after path switching'**
  String get oldDataNotDeleted;

  /// No description provided for @oldDataWillNotBeDeleted.
  ///
  /// In en, this message translates to:
  /// **'After switching, data in old path will not be automatically deleted'**
  String get oldDataWillNotBeDeleted;

  /// No description provided for @oldPathDataNotAutoDeleted.
  ///
  /// In en, this message translates to:
  /// **'Old path data will not be automatically deleted after switching'**
  String get oldPathDataNotAutoDeleted;

  /// No description provided for @onlyOneCharacter.
  ///
  /// In en, this message translates to:
  /// **'Only one character is allowed'**
  String get onlyOneCharacter;

  /// No description provided for @opacity.
  ///
  /// In en, this message translates to:
  /// **'Opacity'**
  String get opacity;

  /// No description provided for @openBackupManagementFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to open backup management'**
  String get openBackupManagementFailed;

  /// No description provided for @openFolder.
  ///
  /// In en, this message translates to:
  /// **'Open Folder'**
  String get openFolder;

  /// No description provided for @openGalleryFailed.
  ///
  /// In en, this message translates to:
  /// **'Open Gallery Failed: {error}'**
  String openGalleryFailed(Object error);

  /// No description provided for @openPathFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to open path'**
  String get openPathFailed;

  /// No description provided for @openPathSwitchWizardFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to open data path switch wizard'**
  String get openPathSwitchWizardFailed;

  /// No description provided for @operatingSystem.
  ///
  /// In en, this message translates to:
  /// **'Operating System'**
  String get operatingSystem;

  /// No description provided for @operationCannotBeUndone.
  ///
  /// In en, this message translates to:
  /// **'This operation cannot be undone, please confirm carefully'**
  String get operationCannotBeUndone;

  /// No description provided for @operationCannotUndo.
  ///
  /// In en, this message translates to:
  /// **'This operation cannot be undone, please confirm carefully'**
  String get operationCannotUndo;

  /// No description provided for @optional.
  ///
  /// In en, this message translates to:
  /// **'Optional'**
  String get optional;

  /// No description provided for @original.
  ///
  /// In en, this message translates to:
  /// **'Original'**
  String get original;

  /// No description provided for @originalImageDesc.
  ///
  /// In en, this message translates to:
  /// **'Untreated Original Image'**
  String get originalImageDesc;

  /// No description provided for @outputQuality.
  ///
  /// In en, this message translates to:
  /// **'Output Quality'**
  String get outputQuality;

  /// No description provided for @overwrite.
  ///
  /// In en, this message translates to:
  /// **'Overwrite'**
  String get overwrite;

  /// No description provided for @overwriteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Overwrite Confirmation'**
  String get overwriteConfirm;

  /// No description provided for @overwriteExisting.
  ///
  /// In en, this message translates to:
  /// **'Overwrite Existing'**
  String get overwriteExisting;

  /// No description provided for @overwriteExistingDescription.
  ///
  /// In en, this message translates to:
  /// **'Replace existing items with imported data'**
  String get overwriteExistingDescription;

  /// No description provided for @overwriteExistingPractice.
  ///
  /// In en, this message translates to:
  /// **'A practice sheet named \"{title}\" already exists. Do you want to overwrite it?'**
  String overwriteExistingPractice(Object title);

  /// No description provided for @overwriteFile.
  ///
  /// In en, this message translates to:
  /// **'Overwrite File'**
  String get overwriteFile;

  /// No description provided for @overwriteFileAction.
  ///
  /// In en, this message translates to:
  /// **'Overwrite File'**
  String get overwriteFileAction;

  /// No description provided for @overwriteMessage.
  ///
  /// In en, this message translates to:
  /// **'A practice sheet with the title \"{title}\" already exists. Do you want to overwrite it?'**
  String overwriteMessage(Object title);

  /// No description provided for @overwrittenCharacters.
  ///
  /// In en, this message translates to:
  /// **'Overwritten Characters'**
  String get overwrittenCharacters;

  /// No description provided for @overwrittenItems.
  ///
  /// In en, this message translates to:
  /// **'Overwritten Items'**
  String get overwrittenItems;

  /// No description provided for @overwrittenWorks.
  ///
  /// In en, this message translates to:
  /// **'Overwritten Works'**
  String get overwrittenWorks;

  /// No description provided for @padding.
  ///
  /// In en, this message translates to:
  /// **'Padding'**
  String get padding;

  /// No description provided for @pageBuildError.
  ///
  /// In en, this message translates to:
  /// **'Page Build Error'**
  String get pageBuildError;

  /// No description provided for @pageMargins.
  ///
  /// In en, this message translates to:
  /// **'Page Margins (cm)'**
  String get pageMargins;

  /// No description provided for @pageNotImplemented.
  ///
  /// In en, this message translates to:
  /// **'Page not implemented'**
  String get pageNotImplemented;

  /// No description provided for @pageOrientation.
  ///
  /// In en, this message translates to:
  /// **'Page Orientation'**
  String get pageOrientation;

  /// No description provided for @pageProperties.
  ///
  /// In en, this message translates to:
  /// **'Page Properties'**
  String get pageProperties;

  /// No description provided for @pageRange.
  ///
  /// In en, this message translates to:
  /// **'Page Range'**
  String get pageRange;

  /// No description provided for @pageSize.
  ///
  /// In en, this message translates to:
  /// **'Page Size'**
  String get pageSize;

  /// No description provided for @pages.
  ///
  /// In en, this message translates to:
  /// **'Pages'**
  String get pages;

  /// No description provided for @parentCategory.
  ///
  /// In en, this message translates to:
  /// **'Parent Category (Optional)'**
  String get parentCategory;

  /// No description provided for @parsingImportData.
  ///
  /// In en, this message translates to:
  /// **'Parsing import data...'**
  String get parsingImportData;

  /// No description provided for @paste.
  ///
  /// In en, this message translates to:
  /// **'Paste (Ctrl+Shift+V)'**
  String get paste;

  /// No description provided for @path.
  ///
  /// In en, this message translates to:
  /// **'Path'**
  String get path;

  /// No description provided for @pathAnalysis.
  ///
  /// In en, this message translates to:
  /// **'Path Analysis'**
  String get pathAnalysis;

  /// No description provided for @pathConfigError.
  ///
  /// In en, this message translates to:
  /// **'Path configuration error'**
  String get pathConfigError;

  /// No description provided for @pathInfo.
  ///
  /// In en, this message translates to:
  /// **'Path Info'**
  String get pathInfo;

  /// No description provided for @pathInvalid.
  ///
  /// In en, this message translates to:
  /// **'Path Invalid'**
  String get pathInvalid;

  /// No description provided for @pathNotExists.
  ///
  /// In en, this message translates to:
  /// **'Path does not exist'**
  String get pathNotExists;

  /// No description provided for @pathSettings.
  ///
  /// In en, this message translates to:
  /// **'Path Settings'**
  String get pathSettings;

  /// No description provided for @pathSize.
  ///
  /// In en, this message translates to:
  /// **'Path Size'**
  String get pathSize;

  /// No description provided for @pathSwitchCompleted.
  ///
  /// In en, this message translates to:
  /// **'Data path switching completed!\\n\\nYou can view and clean up old path data in \"Data Path Management\".'**
  String get pathSwitchCompleted;

  /// No description provided for @pathSwitchCompletedMessage.
  ///
  /// In en, this message translates to:
  /// **'Data path switch completed!\\n\\nYou can view and clean up old path data in Data Path Management.'**
  String get pathSwitchCompletedMessage;

  /// No description provided for @pathSwitchFailed.
  ///
  /// In en, this message translates to:
  /// **'Path Switch Failed'**
  String get pathSwitchFailed;

  /// No description provided for @pathSwitchFailedMessage.
  ///
  /// In en, this message translates to:
  /// **'Path switching failed'**
  String get pathSwitchFailedMessage;

  /// No description provided for @pathValidationFailed.
  ///
  /// In en, this message translates to:
  /// **'Path validation failed: {error}'**
  String pathValidationFailed(Object error);

  /// No description provided for @pathValidationFailedGeneric.
  ///
  /// In en, this message translates to:
  /// **'Path validation failed. Please check if the path is valid'**
  String get pathValidationFailedGeneric;

  /// No description provided for @pdfExportFailed.
  ///
  /// In en, this message translates to:
  /// **'PDF Export Failed'**
  String get pdfExportFailed;

  /// No description provided for @pdfExportSuccess.
  ///
  /// In en, this message translates to:
  /// **'PDF Export Success: {path}'**
  String pdfExportSuccess(Object path);

  /// No description provided for @pinyin.
  ///
  /// In en, this message translates to:
  /// **'Pinyin'**
  String get pinyin;

  /// No description provided for @pixels.
  ///
  /// In en, this message translates to:
  /// **'Pixels'**
  String get pixels;

  /// No description provided for @platformInfo.
  ///
  /// In en, this message translates to:
  /// **'Platform Info'**
  String get platformInfo;

  /// No description provided for @pleaseEnterValidNumber.
  ///
  /// In en, this message translates to:
  /// **'Please Enter Valid Number'**
  String get pleaseEnterValidNumber;

  /// No description provided for @pleaseSelectOperation.
  ///
  /// In en, this message translates to:
  /// **'Please select an operation:'**
  String get pleaseSelectOperation;

  /// No description provided for @pleaseSetBackupPathFirst.
  ///
  /// In en, this message translates to:
  /// **'Please set backup path first'**
  String get pleaseSetBackupPathFirst;

  /// No description provided for @pleaseWaitMessage.
  ///
  /// In en, this message translates to:
  /// **'Please wait'**
  String get pleaseWaitMessage;

  /// No description provided for @portrait.
  ///
  /// In en, this message translates to:
  /// **'Portrait'**
  String get portrait;

  /// No description provided for @position.
  ///
  /// In en, this message translates to:
  /// **'Position'**
  String get position;

  /// No description provided for @ppiSetting.
  ///
  /// In en, this message translates to:
  /// **'PPI Setting (Pixels Per Inch)'**
  String get ppiSetting;

  /// No description provided for @practiceEditCollection.
  ///
  /// In en, this message translates to:
  /// **'Collection'**
  String get practiceEditCollection;

  /// No description provided for @practiceEditDefaultLayer.
  ///
  /// In en, this message translates to:
  /// **'Default Layer'**
  String get practiceEditDefaultLayer;

  /// No description provided for @practiceEditPracticeLoaded.
  ///
  /// In en, this message translates to:
  /// **'Practice Sheet \"{title}\" Loaded Successfully'**
  String practiceEditPracticeLoaded(Object title);

  /// No description provided for @practiceEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Practice Sheet Editor'**
  String get practiceEditTitle;

  /// No description provided for @practiceListSearch.
  ///
  /// In en, this message translates to:
  /// **'Search Practice Sheets...'**
  String get practiceListSearch;

  /// No description provided for @practiceListTitle.
  ///
  /// In en, this message translates to:
  /// **'Practice Sheets'**
  String get practiceListTitle;

  /// No description provided for @practiceSheetNotExists.
  ///
  /// In en, this message translates to:
  /// **'Practice Sheet Does Not Exist'**
  String get practiceSheetNotExists;

  /// No description provided for @practiceSheetSaved.
  ///
  /// In en, this message translates to:
  /// **'Practice Sheet \"{title}\" Saved'**
  String practiceSheetSaved(Object title);

  /// No description provided for @practiceSheetSavedMessage.
  ///
  /// In en, this message translates to:
  /// **'Practice sheet \"{title}\" saved successfully'**
  String practiceSheetSavedMessage(Object title);

  /// No description provided for @practices.
  ///
  /// In en, this message translates to:
  /// **'Practices'**
  String get practices;

  /// No description provided for @preparingPrint.
  ///
  /// In en, this message translates to:
  /// **'Preparing to Print, Please Wait...'**
  String get preparingPrint;

  /// No description provided for @preparingSave.
  ///
  /// In en, this message translates to:
  /// **'Preparing to Save...'**
  String get preparingSave;

  /// No description provided for @preserveMetadata.
  ///
  /// In en, this message translates to:
  /// **'Preserve Metadata'**
  String get preserveMetadata;

  /// No description provided for @preserveMetadataDescription.
  ///
  /// In en, this message translates to:
  /// **'Keep original creation time and metadata'**
  String get preserveMetadataDescription;

  /// No description provided for @preserveMetadataMandatory.
  ///
  /// In en, this message translates to:
  /// **'Mandatory preservation of original creation time, author information and other metadata to ensure data consistency'**
  String get preserveMetadataMandatory;

  /// No description provided for @presetSize.
  ///
  /// In en, this message translates to:
  /// **'Preset Size'**
  String get presetSize;

  /// No description provided for @presets.
  ///
  /// In en, this message translates to:
  /// **'Presets'**
  String get presets;

  /// No description provided for @preview.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get preview;

  /// No description provided for @previewMode.
  ///
  /// In en, this message translates to:
  /// **'Preview Mode'**
  String get previewMode;

  /// No description provided for @previewPage.
  ///
  /// In en, this message translates to:
  /// **'(Page {current}/{total})'**
  String previewPage(Object current, Object total);

  /// No description provided for @previousField.
  ///
  /// In en, this message translates to:
  /// **'Previous Field'**
  String get previousField;

  /// No description provided for @previousPage.
  ///
  /// In en, this message translates to:
  /// **'Previous Page'**
  String get previousPage;

  /// No description provided for @previousStep.
  ///
  /// In en, this message translates to:
  /// **'Previous'**
  String get previousStep;

  /// No description provided for @processedCount.
  ///
  /// In en, this message translates to:
  /// **'Processed: {current} / {total}'**
  String processedCount(Object current, Object total);

  /// No description provided for @processedProgress.
  ///
  /// In en, this message translates to:
  /// **'Processed: {current} / {total}'**
  String processedProgress(Object current, Object total);

  /// No description provided for @processing.
  ///
  /// In en, this message translates to:
  /// **'Processing...'**
  String get processing;

  /// No description provided for @processingDetails.
  ///
  /// In en, this message translates to:
  /// **'Processing Details'**
  String get processingDetails;

  /// No description provided for @processingEraseData.
  ///
  /// In en, this message translates to:
  /// **'Processing Erase Data...'**
  String get processingEraseData;

  /// No description provided for @processingImage.
  ///
  /// In en, this message translates to:
  /// **'Processing Image...'**
  String get processingImage;

  /// No description provided for @processingPleaseWait.
  ///
  /// In en, this message translates to:
  /// **'Processing, please wait...'**
  String get processingPleaseWait;

  /// No description provided for @properties.
  ///
  /// In en, this message translates to:
  /// **'Properties'**
  String get properties;

  /// No description provided for @qualityHigh.
  ///
  /// In en, this message translates to:
  /// **'High Quality (2x)'**
  String get qualityHigh;

  /// No description provided for @qualityStandard.
  ///
  /// In en, this message translates to:
  /// **'Standard (1x)'**
  String get qualityStandard;

  /// No description provided for @qualityUltra.
  ///
  /// In en, this message translates to:
  /// **'Ultra Quality (3x)'**
  String get qualityUltra;

  /// No description provided for @quickRecoveryOnIssues.
  ///
  /// In en, this message translates to:
  /// **'• Quick recovery if issues occur during switching'**
  String get quickRecoveryOnIssues;

  /// No description provided for @reExportWork.
  ///
  /// In en, this message translates to:
  /// **'• Re-export the work'**
  String get reExportWork;

  /// No description provided for @recent.
  ///
  /// In en, this message translates to:
  /// **'Recent'**
  String get recent;

  /// No description provided for @recentBackupCanSwitch.
  ///
  /// In en, this message translates to:
  /// **'Recent backup exists, safe to switch directly'**
  String get recentBackupCanSwitch;

  /// No description provided for @recommendConfirmBeforeCleanup.
  ///
  /// In en, this message translates to:
  /// **'Recommend confirming new path data is normal before cleaning up old path'**
  String get recommendConfirmBeforeCleanup;

  /// No description provided for @recommendConfirmNewDataBeforeClean.
  ///
  /// In en, this message translates to:
  /// **'Recommend confirming new path data is normal before cleaning old path'**
  String get recommendConfirmNewDataBeforeClean;

  /// No description provided for @recommendSufficientSpace.
  ///
  /// In en, this message translates to:
  /// **'Choose a disk with sufficient free space'**
  String get recommendSufficientSpace;

  /// No description provided for @redo.
  ///
  /// In en, this message translates to:
  /// **'Redo'**
  String get redo;

  /// No description provided for @refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// No description provided for @refreshDataFailed.
  ///
  /// In en, this message translates to:
  /// **'Refresh Data Failed: {error}'**
  String refreshDataFailed(Object error);

  /// No description provided for @reload.
  ///
  /// In en, this message translates to:
  /// **'Reload'**
  String get reload;

  /// No description provided for @remarks.
  ///
  /// In en, this message translates to:
  /// **'Remarks'**
  String get remarks;

  /// No description provided for @remarksHint.
  ///
  /// In en, this message translates to:
  /// **'Add Remarks Information'**
  String get remarksHint;

  /// No description provided for @remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// No description provided for @removeFavorite.
  ///
  /// In en, this message translates to:
  /// **'Remove from Favorites'**
  String get removeFavorite;

  /// No description provided for @removeFromCategory.
  ///
  /// In en, this message translates to:
  /// **'Remove from Current Category'**
  String get removeFromCategory;

  /// No description provided for @rename.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get rename;

  /// No description provided for @renameDuplicates.
  ///
  /// In en, this message translates to:
  /// **'Rename Duplicates'**
  String get renameDuplicates;

  /// No description provided for @renameDuplicatesDescription.
  ///
  /// In en, this message translates to:
  /// **'Rename imported items to avoid conflicts'**
  String get renameDuplicatesDescription;

  /// No description provided for @renameLayer.
  ///
  /// In en, this message translates to:
  /// **'Rename Layer'**
  String get renameLayer;

  /// No description provided for @renderFailed.
  ///
  /// In en, this message translates to:
  /// **'Render Failed'**
  String get renderFailed;

  /// No description provided for @reselectFile.
  ///
  /// In en, this message translates to:
  /// **'Reselect File'**
  String get reselectFile;

  /// No description provided for @resetCategoryConfig.
  ///
  /// In en, this message translates to:
  /// **'Reset {category} Configuration'**
  String resetCategoryConfig(Object category);

  /// No description provided for @resetCategoryConfigMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to reset {category} configuration to default settings? This action cannot be undone.'**
  String resetCategoryConfigMessage(Object category);

  /// No description provided for @resetDataPathToDefault.
  ///
  /// In en, this message translates to:
  /// **'Reset to Default'**
  String get resetDataPathToDefault;

  /// No description provided for @resetSettingsConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to reset to default values?'**
  String get resetSettingsConfirmMessage;

  /// No description provided for @resetSettingsConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset Settings'**
  String get resetSettingsConfirmTitle;

  /// No description provided for @resetToDefault.
  ///
  /// In en, this message translates to:
  /// **'Reset to Default'**
  String get resetToDefault;

  /// No description provided for @resetToDefaultFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to reset to default path'**
  String get resetToDefaultFailed;

  /// No description provided for @resetToDefaultFailedWithError.
  ///
  /// In en, this message translates to:
  /// **'Failed to reset to default path: {error}'**
  String resetToDefaultFailedWithError(Object error);

  /// No description provided for @resetToDefaultPathMessage.
  ///
  /// In en, this message translates to:
  /// **'This will reset the data path to the default location. The application needs to restart to take effect. Are you sure you want to continue?'**
  String get resetToDefaultPathMessage;

  /// No description provided for @resetToDefaults.
  ///
  /// In en, this message translates to:
  /// **'Reset to Defaults'**
  String get resetToDefaults;

  /// No description provided for @resetTransform.
  ///
  /// In en, this message translates to:
  /// **'Reset Transform'**
  String get resetTransform;

  /// No description provided for @resetZoom.
  ///
  /// In en, this message translates to:
  /// **'Reset Zoom'**
  String get resetZoom;

  /// No description provided for @resolution.
  ///
  /// In en, this message translates to:
  /// **'Resolution'**
  String get resolution;

  /// No description provided for @restartAfterRestored.
  ///
  /// In en, this message translates to:
  /// **'Note: The application will restart automatically after recovery is complete'**
  String get restartAfterRestored;

  /// No description provided for @restartLaterButton.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get restartLaterButton;

  /// No description provided for @restartNeeded.
  ///
  /// In en, this message translates to:
  /// **'Restart Needed'**
  String get restartNeeded;

  /// No description provided for @restartNow.
  ///
  /// In en, this message translates to:
  /// **'Restart Now'**
  String get restartNow;

  /// No description provided for @restartNowButton.
  ///
  /// In en, this message translates to:
  /// **'Restart Now'**
  String get restartNowButton;

  /// No description provided for @restore.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get restore;

  /// No description provided for @restoreBackup.
  ///
  /// In en, this message translates to:
  /// **'Restore Backup'**
  String get restoreBackup;

  /// No description provided for @restoreBackupFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to restore backup'**
  String get restoreBackupFailed;

  /// No description provided for @restoreConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to restore from this backup? This will replace all your current data.'**
  String get restoreConfirmMessage;

  /// No description provided for @restoreConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Restore Confirmation'**
  String get restoreConfirmTitle;

  /// No description provided for @restoreDefaultSize.
  ///
  /// In en, this message translates to:
  /// **'Restore Default Size'**
  String get restoreDefaultSize;

  /// No description provided for @restoreFailure.
  ///
  /// In en, this message translates to:
  /// **'Restore Failed'**
  String get restoreFailure;

  /// No description provided for @restoreWarningMessage.
  ///
  /// In en, this message translates to:
  /// **'Warning: Current data will be overwritten by backup data. This operation cannot be undone!'**
  String get restoreWarningMessage;

  /// No description provided for @restoringBackup.
  ///
  /// In en, this message translates to:
  /// **'Restoring from Backup...'**
  String get restoringBackup;

  /// No description provided for @restoringBackupMessage.
  ///
  /// In en, this message translates to:
  /// **'Restoring backup...'**
  String get restoringBackupMessage;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @retryAction.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retryAction;

  /// No description provided for @rotateClockwise.
  ///
  /// In en, this message translates to:
  /// **'Rotate Clockwise'**
  String get rotateClockwise;

  /// No description provided for @rotateCounterclockwise.
  ///
  /// In en, this message translates to:
  /// **'Rotate Counterclockwise'**
  String get rotateCounterclockwise;

  /// No description provided for @rotateLeft.
  ///
  /// In en, this message translates to:
  /// **'Rotate Left'**
  String get rotateLeft;

  /// No description provided for @rotateRight.
  ///
  /// In en, this message translates to:
  /// **'Rotate Right'**
  String get rotateRight;

  /// No description provided for @rotation.
  ///
  /// In en, this message translates to:
  /// **'Rotation'**
  String get rotation;

  /// No description provided for @rotationFineControl.
  ///
  /// In en, this message translates to:
  /// **'Fine Rotation Control'**
  String get rotationFineControl;

  /// No description provided for @safetyBackupBeforePathSwitch.
  ///
  /// In en, this message translates to:
  /// **'Safety backup before data path switching'**
  String get safetyBackupBeforePathSwitch;

  /// No description provided for @safetyBackupRecommendation.
  ///
  /// In en, this message translates to:
  /// **'To ensure data safety, it\'s recommended to create a backup before switching data path:'**
  String get safetyBackupRecommendation;

  /// No description provided for @safetyTip.
  ///
  /// In en, this message translates to:
  /// **'💡 Safety Tips:'**
  String get safetyTip;

  /// No description provided for @sansSerif.
  ///
  /// In en, this message translates to:
  /// **'Sans Serif'**
  String get sansSerif;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @saveAs.
  ///
  /// In en, this message translates to:
  /// **'Save As'**
  String get saveAs;

  /// No description provided for @saveComplete.
  ///
  /// In en, this message translates to:
  /// **'Save Complete'**
  String get saveComplete;

  /// No description provided for @saveFailed.
  ///
  /// In en, this message translates to:
  /// **'Save Failed, Please Try Again Later'**
  String get saveFailed;

  /// No description provided for @saveFailedWithError.
  ///
  /// In en, this message translates to:
  /// **'Save Failed: {error}'**
  String saveFailedWithError(Object error);

  /// No description provided for @saveFailure.
  ///
  /// In en, this message translates to:
  /// **'Save Failed'**
  String get saveFailure;

  /// No description provided for @savePreview.
  ///
  /// In en, this message translates to:
  /// **'Character Preview:'**
  String get savePreview;

  /// No description provided for @saveSuccess.
  ///
  /// In en, this message translates to:
  /// **'Save Successful'**
  String get saveSuccess;

  /// No description provided for @saveTimeout.
  ///
  /// In en, this message translates to:
  /// **'Save Timeout'**
  String get saveTimeout;

  /// No description provided for @savingToStorage.
  ///
  /// In en, this message translates to:
  /// **'Saving to Storage...'**
  String get savingToStorage;

  /// No description provided for @scannedBackupFileDescription.
  ///
  /// In en, this message translates to:
  /// **'Scanned backup file'**
  String get scannedBackupFileDescription;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @searchCategories.
  ///
  /// In en, this message translates to:
  /// **'Search Categories...'**
  String get searchCategories;

  /// No description provided for @searchConfigDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Search Configuration Items'**
  String get searchConfigDialogTitle;

  /// No description provided for @searchConfigHint.
  ///
  /// In en, this message translates to:
  /// **'Enter configuration item name or key'**
  String get searchConfigHint;

  /// No description provided for @searchConfigItems.
  ///
  /// In en, this message translates to:
  /// **'Search Configuration Items'**
  String get searchConfigItems;

  /// No description provided for @searching.
  ///
  /// In en, this message translates to:
  /// **'Searching...'**
  String get searching;

  /// No description provided for @select.
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get select;

  /// No description provided for @selectAll.
  ///
  /// In en, this message translates to:
  /// **'Select All'**
  String get selectAll;

  /// No description provided for @selectAllWithShortcut.
  ///
  /// In en, this message translates to:
  /// **'Select All (Ctrl+Shift+A)'**
  String get selectAllWithShortcut;

  /// No description provided for @selectBackup.
  ///
  /// In en, this message translates to:
  /// **'Select Backup'**
  String get selectBackup;

  /// No description provided for @selectBackupFileToImportDialog.
  ///
  /// In en, this message translates to:
  /// **'Select backup file to import'**
  String get selectBackupFileToImportDialog;

  /// No description provided for @selectBackupStorageLocation.
  ///
  /// In en, this message translates to:
  /// **'Select backup storage location'**
  String get selectBackupStorageLocation;

  /// No description provided for @selectCategoryToApply.
  ///
  /// In en, this message translates to:
  /// **'Please select a category to apply:'**
  String get selectCategoryToApply;

  /// No description provided for @selectCharacterFirst.
  ///
  /// In en, this message translates to:
  /// **'Please Select Character First'**
  String get selectCharacterFirst;

  /// No description provided for @selectColor.
  ///
  /// In en, this message translates to:
  /// **'Select {type}'**
  String selectColor(Object type);

  /// No description provided for @selectDate.
  ///
  /// In en, this message translates to:
  /// **'Select Date'**
  String get selectDate;

  /// No description provided for @selectExportLocation.
  ///
  /// In en, this message translates to:
  /// **'Select Export Location'**
  String get selectExportLocation;

  /// No description provided for @selectExportLocationDialog.
  ///
  /// In en, this message translates to:
  /// **'Select export location'**
  String get selectExportLocationDialog;

  /// No description provided for @selectExportLocationHint.
  ///
  /// In en, this message translates to:
  /// **'Select export location...'**
  String get selectExportLocationHint;

  /// No description provided for @selectFileError.
  ///
  /// In en, this message translates to:
  /// **'Failed to select file'**
  String get selectFileError;

  /// No description provided for @selectFolder.
  ///
  /// In en, this message translates to:
  /// **'Select Folder'**
  String get selectFolder;

  /// No description provided for @selectImage.
  ///
  /// In en, this message translates to:
  /// **'Select Image'**
  String get selectImage;

  /// No description provided for @selectImages.
  ///
  /// In en, this message translates to:
  /// **'Select Images'**
  String get selectImages;

  /// No description provided for @selectImagesWithCtrl.
  ///
  /// In en, this message translates to:
  /// **'Select Images (Hold Ctrl for multiple selection)'**
  String get selectImagesWithCtrl;

  /// No description provided for @selectImportFile.
  ///
  /// In en, this message translates to:
  /// **'Select Backup File'**
  String get selectImportFile;

  /// No description provided for @selectNewDataPath.
  ///
  /// In en, this message translates to:
  /// **'Select new data storage path:'**
  String get selectNewDataPath;

  /// No description provided for @selectNewDataPathDialog.
  ///
  /// In en, this message translates to:
  /// **'Select new data storage path'**
  String get selectNewDataPathDialog;

  /// No description provided for @selectNewDataPathTitle.
  ///
  /// In en, this message translates to:
  /// **'Select new data storage path'**
  String get selectNewDataPathTitle;

  /// No description provided for @selectNewPath.
  ///
  /// In en, this message translates to:
  /// **'Select New Path'**
  String get selectNewPath;

  /// No description provided for @selectParentCategory.
  ///
  /// In en, this message translates to:
  /// **'Select Parent Category'**
  String get selectParentCategory;

  /// No description provided for @selectPath.
  ///
  /// In en, this message translates to:
  /// **'Select Path'**
  String get selectPath;

  /// No description provided for @selectPathButton.
  ///
  /// In en, this message translates to:
  /// **'Select Path'**
  String get selectPathButton;

  /// No description provided for @selectPathFailed.
  ///
  /// In en, this message translates to:
  /// **'Path selection failed'**
  String get selectPathFailed;

  /// No description provided for @selectSufficientSpaceDisk.
  ///
  /// In en, this message translates to:
  /// **'Recommend choosing a disk with sufficient free space'**
  String get selectSufficientSpaceDisk;

  /// No description provided for @selectTargetLayer.
  ///
  /// In en, this message translates to:
  /// **'Select Target Layer'**
  String get selectTargetLayer;

  /// No description provided for @selected.
  ///
  /// In en, this message translates to:
  /// **'Selected'**
  String get selected;

  /// No description provided for @selectedCharacter.
  ///
  /// In en, this message translates to:
  /// **'Selected Character'**
  String get selectedCharacter;

  /// No description provided for @selectedCount.
  ///
  /// In en, this message translates to:
  /// **'Selected {count}'**
  String selectedCount(Object count);

  /// No description provided for @selectedElementNotFound.
  ///
  /// In en, this message translates to:
  /// **'Selected element not found'**
  String get selectedElementNotFound;

  /// No description provided for @selectedItems.
  ///
  /// In en, this message translates to:
  /// **'Selected Items'**
  String get selectedItems;

  /// No description provided for @selectedPath.
  ///
  /// In en, this message translates to:
  /// **'Selected Path:'**
  String get selectedPath;

  /// No description provided for @selectionMode.
  ///
  /// In en, this message translates to:
  /// **'Selection Mode'**
  String get selectionMode;

  /// No description provided for @sendToBack.
  ///
  /// In en, this message translates to:
  /// **'Send to Back (Ctrl+B)'**
  String get sendToBack;

  /// No description provided for @serif.
  ///
  /// In en, this message translates to:
  /// **'Serif'**
  String get serif;

  /// No description provided for @serviceNotReady.
  ///
  /// In en, this message translates to:
  /// **'Service not ready, please try again later'**
  String get serviceNotReady;

  /// No description provided for @setBackupPathFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to set backup path'**
  String get setBackupPathFailed;

  /// No description provided for @setCategory.
  ///
  /// In en, this message translates to:
  /// **'Set Category'**
  String get setCategory;

  /// No description provided for @setCategoryForItems.
  ///
  /// In en, this message translates to:
  /// **'Set Category ({count} items)'**
  String setCategoryForItems(Object count);

  /// No description provided for @setDataPathFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to set data path. Please check path permissions and compatibility'**
  String get setDataPathFailed;

  /// No description provided for @setDataPathFailedWithError.
  ///
  /// In en, this message translates to:
  /// **'Failed to set data path: {error}'**
  String setDataPathFailedWithError(Object error);

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @settingsResetMessage.
  ///
  /// In en, this message translates to:
  /// **'Settings have been reset to default values'**
  String get settingsResetMessage;

  /// No description provided for @shortcuts.
  ///
  /// In en, this message translates to:
  /// **'Keyboard Shortcuts'**
  String get shortcuts;

  /// No description provided for @showContour.
  ///
  /// In en, this message translates to:
  /// **'Show Contour'**
  String get showContour;

  /// No description provided for @showDetails.
  ///
  /// In en, this message translates to:
  /// **'Show Details'**
  String get showDetails;

  /// No description provided for @showElement.
  ///
  /// In en, this message translates to:
  /// **'Show Element'**
  String get showElement;

  /// No description provided for @showGrid.
  ///
  /// In en, this message translates to:
  /// **'Show Grid (Ctrl+G)'**
  String get showGrid;

  /// No description provided for @showHideAllElements.
  ///
  /// In en, this message translates to:
  /// **'Show/Hide All Elements'**
  String get showHideAllElements;

  /// No description provided for @showImagePreview.
  ///
  /// In en, this message translates to:
  /// **'Show Image Preview'**
  String get showImagePreview;

  /// No description provided for @showThumbnails.
  ///
  /// In en, this message translates to:
  /// **'Show Page Thumbnails'**
  String get showThumbnails;

  /// No description provided for @showToolbar.
  ///
  /// In en, this message translates to:
  /// **'Show Toolbar'**
  String get showToolbar;

  /// No description provided for @skipBackup.
  ///
  /// In en, this message translates to:
  /// **'Skip Backup'**
  String get skipBackup;

  /// No description provided for @skipBackupConfirm.
  ///
  /// In en, this message translates to:
  /// **'Skip Backup'**
  String get skipBackupConfirm;

  /// No description provided for @skipBackupWarning.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to skip backup and proceed with path switching?\\n\\nThis may pose a risk of data loss.'**
  String get skipBackupWarning;

  /// No description provided for @skipBackupWarningMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to skip backup and proceed with path switching?\\n\\nThis may pose a risk of data loss.'**
  String get skipBackupWarningMessage;

  /// No description provided for @skipConflicts.
  ///
  /// In en, this message translates to:
  /// **'Skip Conflicts'**
  String get skipConflicts;

  /// No description provided for @skipConflictsDescription.
  ///
  /// In en, this message translates to:
  /// **'Skip items that already exist'**
  String get skipConflictsDescription;

  /// No description provided for @skippedCharacters.
  ///
  /// In en, this message translates to:
  /// **'Skipped Characters'**
  String get skippedCharacters;

  /// No description provided for @skippedItems.
  ///
  /// In en, this message translates to:
  /// **'Skipped Items'**
  String get skippedItems;

  /// No description provided for @skippedWorks.
  ///
  /// In en, this message translates to:
  /// **'Skipped Works'**
  String get skippedWorks;

  /// No description provided for @sort.
  ///
  /// In en, this message translates to:
  /// **'Sort'**
  String get sort;

  /// No description provided for @sortBy.
  ///
  /// In en, this message translates to:
  /// **'Sort By'**
  String get sortBy;

  /// No description provided for @sortByCreateTime.
  ///
  /// In en, this message translates to:
  /// **'Sort by Creation Time'**
  String get sortByCreateTime;

  /// No description provided for @sortByTitle.
  ///
  /// In en, this message translates to:
  /// **'Sort by Title'**
  String get sortByTitle;

  /// No description provided for @sortByUpdateTime.
  ///
  /// In en, this message translates to:
  /// **'Sort by Update Time'**
  String get sortByUpdateTime;

  /// No description provided for @sortFailed.
  ///
  /// In en, this message translates to:
  /// **'Sort failed'**
  String get sortFailed;

  /// No description provided for @sortOrder.
  ///
  /// In en, this message translates to:
  /// **'Sort Order'**
  String get sortOrder;

  /// No description provided for @sortOrderCannotBeEmpty.
  ///
  /// In en, this message translates to:
  /// **'Sort order cannot be empty'**
  String get sortOrderCannotBeEmpty;

  /// No description provided for @sortOrderHint.
  ///
  /// In en, this message translates to:
  /// **'Smaller numbers appear first'**
  String get sortOrderHint;

  /// No description provided for @sortOrderLabel.
  ///
  /// In en, this message translates to:
  /// **'Sort Order'**
  String get sortOrderLabel;

  /// No description provided for @sortOrderNumber.
  ///
  /// In en, this message translates to:
  /// **'Sort order must be a number'**
  String get sortOrderNumber;

  /// No description provided for @sortOrderRange.
  ///
  /// In en, this message translates to:
  /// **'Sort order must be between 1-999'**
  String get sortOrderRange;

  /// No description provided for @sortOrderRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter sort order value'**
  String get sortOrderRequired;

  /// No description provided for @sourceBackupFileNotFound.
  ///
  /// In en, this message translates to:
  /// **'Source backup file not found'**
  String get sourceBackupFileNotFound;

  /// No description provided for @sourceFileNotFound.
  ///
  /// In en, this message translates to:
  /// **'Source file not found: {path}'**
  String sourceFileNotFound(Object path);

  /// No description provided for @sourceFileNotFoundError.
  ///
  /// In en, this message translates to:
  /// **'Source file not found: {path}'**
  String sourceFileNotFoundError(Object path);

  /// No description provided for @sourceHanSansFont.
  ///
  /// In en, this message translates to:
  /// **'Source Han Sans'**
  String get sourceHanSansFont;

  /// No description provided for @sourceHanSerifFont.
  ///
  /// In en, this message translates to:
  /// **'Source Han Serif'**
  String get sourceHanSerifFont;

  /// No description provided for @sourceInfo.
  ///
  /// In en, this message translates to:
  /// **'Source Information'**
  String get sourceInfo;

  /// No description provided for @startBackup.
  ///
  /// In en, this message translates to:
  /// **'Start Backup'**
  String get startBackup;

  /// No description provided for @startDate.
  ///
  /// In en, this message translates to:
  /// **'Start Date'**
  String get startDate;

  /// No description provided for @stateAndDisplay.
  ///
  /// In en, this message translates to:
  /// **'State and Display'**
  String get stateAndDisplay;

  /// No description provided for @statisticsInProgress.
  ///
  /// In en, this message translates to:
  /// **'Calculating...'**
  String get statisticsInProgress;

  /// No description provided for @status.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get status;

  /// No description provided for @statusAvailable.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get statusAvailable;

  /// No description provided for @statusLabel.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get statusLabel;

  /// No description provided for @statusUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Unavailable'**
  String get statusUnavailable;

  /// No description provided for @storageDetails.
  ///
  /// In en, this message translates to:
  /// **'Storage Details'**
  String get storageDetails;

  /// No description provided for @storageLocation.
  ///
  /// In en, this message translates to:
  /// **'Storage Location'**
  String get storageLocation;

  /// No description provided for @storageSettings.
  ///
  /// In en, this message translates to:
  /// **'Storage Settings'**
  String get storageSettings;

  /// No description provided for @storageUsed.
  ///
  /// In en, this message translates to:
  /// **'Storage Used'**
  String get storageUsed;

  /// No description provided for @stretch.
  ///
  /// In en, this message translates to:
  /// **'Stretch'**
  String get stretch;

  /// No description provided for @strokeCount.
  ///
  /// In en, this message translates to:
  /// **'Stroke Count'**
  String get strokeCount;

  /// No description provided for @submitFailed.
  ///
  /// In en, this message translates to:
  /// **'Submit Failed: {error}'**
  String submitFailed(Object error);

  /// No description provided for @successDeletedCount.
  ///
  /// In en, this message translates to:
  /// **'Successfully deleted {count} backup files'**
  String successDeletedCount(Object count);

  /// No description provided for @suggestConfigureBackupPath.
  ///
  /// In en, this message translates to:
  /// **'Suggestion: Configure backup path in settings first'**
  String get suggestConfigureBackupPath;

  /// No description provided for @suggestConfigureBackupPathFirst.
  ///
  /// In en, this message translates to:
  /// **'Suggestion: Configure backup path in settings first'**
  String get suggestConfigureBackupPathFirst;

  /// No description provided for @suggestRestartOrWait.
  ///
  /// In en, this message translates to:
  /// **'Suggestion: Restart the app or wait for service initialization to complete'**
  String get suggestRestartOrWait;

  /// No description provided for @suggestRestartOrWaitService.
  ///
  /// In en, this message translates to:
  /// **'Suggestion: Restart the app or wait for service initialization'**
  String get suggestRestartOrWaitService;

  /// No description provided for @suggestedSolutions.
  ///
  /// In en, this message translates to:
  /// **'Suggested solutions:'**
  String get suggestedSolutions;

  /// No description provided for @suggestedTags.
  ///
  /// In en, this message translates to:
  /// **'Suggested Tags'**
  String get suggestedTags;

  /// No description provided for @switchSuccessful.
  ///
  /// In en, this message translates to:
  /// **'Switch Successful'**
  String get switchSuccessful;

  /// No description provided for @switchingPage.
  ///
  /// In en, this message translates to:
  /// **'Switching to Character Page...'**
  String get switchingPage;

  /// No description provided for @systemConfig.
  ///
  /// In en, this message translates to:
  /// **'System Configuration'**
  String get systemConfig;

  /// No description provided for @systemConfigItemNote.
  ///
  /// In en, this message translates to:
  /// **'This is a system configuration item, key value cannot be modified'**
  String get systemConfigItemNote;

  /// No description provided for @systemInfo.
  ///
  /// In en, this message translates to:
  /// **'System Info'**
  String get systemInfo;

  /// No description provided for @tabToNextField.
  ///
  /// In en, this message translates to:
  /// **'Press Tab to Navigate to Next Field'**
  String get tabToNextField;

  /// No description provided for @tagAddError.
  ///
  /// In en, this message translates to:
  /// **'Failed to Add Tag: {error}'**
  String tagAddError(Object error);

  /// No description provided for @tagHint.
  ///
  /// In en, this message translates to:
  /// **'Enter Tag Name'**
  String get tagHint;

  /// No description provided for @tagRemoveError.
  ///
  /// In en, this message translates to:
  /// **'Failed to Remove Tag, Error: {error}'**
  String tagRemoveError(Object error);

  /// No description provided for @tags.
  ///
  /// In en, this message translates to:
  /// **'Tags'**
  String get tags;

  /// No description provided for @tagsAddHint.
  ///
  /// In en, this message translates to:
  /// **'Enter Tag Name and Press Enter'**
  String get tagsAddHint;

  /// No description provided for @tagsHint.
  ///
  /// In en, this message translates to:
  /// **'Enter Tags...'**
  String get tagsHint;

  /// No description provided for @tagsSelected.
  ///
  /// In en, this message translates to:
  /// **'Selected Tags:'**
  String get tagsSelected;

  /// No description provided for @targetLocationExists.
  ///
  /// In en, this message translates to:
  /// **'A file with the same name already exists at the target location:'**
  String get targetLocationExists;

  /// No description provided for @targetPathLabel.
  ///
  /// In en, this message translates to:
  /// **'Please select an action:'**
  String get targetPathLabel;

  /// No description provided for @text.
  ///
  /// In en, this message translates to:
  /// **'Text'**
  String get text;

  /// No description provided for @textAlign.
  ///
  /// In en, this message translates to:
  /// **'Text Alignment'**
  String get textAlign;

  /// No description provided for @textContent.
  ///
  /// In en, this message translates to:
  /// **'Text Content'**
  String get textContent;

  /// No description provided for @textElement.
  ///
  /// In en, this message translates to:
  /// **'Text Element'**
  String get textElement;

  /// No description provided for @textProperties.
  ///
  /// In en, this message translates to:
  /// **'Text Properties'**
  String get textProperties;

  /// No description provided for @textSettings.
  ///
  /// In en, this message translates to:
  /// **'Text Settings'**
  String get textSettings;

  /// No description provided for @textureFillMode.
  ///
  /// In en, this message translates to:
  /// **'Texture Fill Mode'**
  String get textureFillMode;

  /// No description provided for @textureFillModeContain.
  ///
  /// In en, this message translates to:
  /// **'Contain'**
  String get textureFillModeContain;

  /// No description provided for @textureFillModeCover.
  ///
  /// In en, this message translates to:
  /// **'Cover'**
  String get textureFillModeCover;

  /// No description provided for @textureFillModeRepeat.
  ///
  /// In en, this message translates to:
  /// **'Repeat'**
  String get textureFillModeRepeat;

  /// No description provided for @textureOpacity.
  ///
  /// In en, this message translates to:
  /// **'Texture Opacity'**
  String get textureOpacity;

  /// No description provided for @texturePreview.
  ///
  /// In en, this message translates to:
  /// **'Texture Preview'**
  String get texturePreview;

  /// No description provided for @textureSize.
  ///
  /// In en, this message translates to:
  /// **'Texture Size'**
  String get textureSize;

  /// No description provided for @themeMode.
  ///
  /// In en, this message translates to:
  /// **'Theme Mode'**
  String get themeMode;

  /// No description provided for @themeModeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeModeDark;

  /// No description provided for @themeModeDescription.
  ///
  /// In en, this message translates to:
  /// **'Use dark theme for better night viewing experience'**
  String get themeModeDescription;

  /// No description provided for @themeModeSystemDescription.
  ///
  /// In en, this message translates to:
  /// **'Automatically switch between dark/light themes based on system settings'**
  String get themeModeSystemDescription;

  /// No description provided for @thisMonth.
  ///
  /// In en, this message translates to:
  /// **'This Month'**
  String get thisMonth;

  /// No description provided for @thisWeek.
  ///
  /// In en, this message translates to:
  /// **'This Week'**
  String get thisWeek;

  /// No description provided for @thisYear.
  ///
  /// In en, this message translates to:
  /// **'This Year'**
  String get thisYear;

  /// No description provided for @threshold.
  ///
  /// In en, this message translates to:
  /// **'Threshold'**
  String get threshold;

  /// No description provided for @thumbnailCheckFailed.
  ///
  /// In en, this message translates to:
  /// **'Thumbnail Check Failed'**
  String get thumbnailCheckFailed;

  /// No description provided for @thumbnailEmpty.
  ///
  /// In en, this message translates to:
  /// **'Thumbnail File is Empty'**
  String get thumbnailEmpty;

  /// No description provided for @thumbnailLoadError.
  ///
  /// In en, this message translates to:
  /// **'Failed to Load Thumbnail'**
  String get thumbnailLoadError;

  /// No description provided for @thumbnailNotFound.
  ///
  /// In en, this message translates to:
  /// **'Thumbnail Not Found'**
  String get thumbnailNotFound;

  /// No description provided for @timeInfo.
  ///
  /// In en, this message translates to:
  /// **'Time Information'**
  String get timeInfo;

  /// No description provided for @timeLabel.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get timeLabel;

  /// No description provided for @title.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get title;

  /// No description provided for @titleAlreadyExists.
  ///
  /// In en, this message translates to:
  /// **'A practice sheet with the same title already exists, please use a different title'**
  String get titleAlreadyExists;

  /// No description provided for @titleCannotBeEmpty.
  ///
  /// In en, this message translates to:
  /// **'Title Cannot Be Empty'**
  String get titleCannotBeEmpty;

  /// No description provided for @titleExists.
  ///
  /// In en, this message translates to:
  /// **'Title Already Exists'**
  String get titleExists;

  /// No description provided for @titleExistsMessage.
  ///
  /// In en, this message translates to:
  /// **'A practice sheet with the same name already exists. Do you want to overwrite it?'**
  String get titleExistsMessage;

  /// No description provided for @titleUpdated.
  ///
  /// In en, this message translates to:
  /// **'Title Updated to \"{title}\"'**
  String titleUpdated(Object title);

  /// No description provided for @to.
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get to;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @toggleBackground.
  ///
  /// In en, this message translates to:
  /// **'Toggle Background'**
  String get toggleBackground;

  /// No description provided for @toolModePanTooltip.
  ///
  /// In en, this message translates to:
  /// **'Multi-Select Tool (Ctrl+V)'**
  String get toolModePanTooltip;

  /// No description provided for @toolModeSelectTooltip.
  ///
  /// In en, this message translates to:
  /// **'Collection Tool (Ctrl+B)'**
  String get toolModeSelectTooltip;

  /// No description provided for @toolModePanShort.
  ///
  /// In en, this message translates to:
  /// **'Multi'**
  String get toolModePanShort;

  /// No description provided for @toolModeSelectShort.
  ///
  /// In en, this message translates to:
  /// **'Collect'**
  String get toolModeSelectShort;

  /// No description provided for @resultShort.
  ///
  /// In en, this message translates to:
  /// **'Results'**
  String get resultShort;

  /// No description provided for @topCenter.
  ///
  /// In en, this message translates to:
  /// **'Top Center'**
  String get topCenter;

  /// No description provided for @topLeft.
  ///
  /// In en, this message translates to:
  /// **'Top Left'**
  String get topLeft;

  /// No description provided for @topRight.
  ///
  /// In en, this message translates to:
  /// **'Top Right'**
  String get topRight;

  /// No description provided for @total.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get total;

  /// No description provided for @totalBackups.
  ///
  /// In en, this message translates to:
  /// **'Total Backups'**
  String get totalBackups;

  /// No description provided for @totalItems.
  ///
  /// In en, this message translates to:
  /// **'Total {count} Items'**
  String totalItems(Object count);

  /// No description provided for @totalSize.
  ///
  /// In en, this message translates to:
  /// **'Total Size'**
  String get totalSize;

  /// No description provided for @transformApplied.
  ///
  /// In en, this message translates to:
  /// **'Transform Applied'**
  String get transformApplied;

  /// No description provided for @tryOtherKeywords.
  ///
  /// In en, this message translates to:
  /// **'Try searching with other keywords'**
  String get tryOtherKeywords;

  /// No description provided for @type.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get type;

  /// No description provided for @underline.
  ///
  /// In en, this message translates to:
  /// **'Underline'**
  String get underline;

  /// No description provided for @undo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get undo;

  /// No description provided for @ungroup.
  ///
  /// In en, this message translates to:
  /// **'Ungroup (Ctrl+U)'**
  String get ungroup;

  /// No description provided for @ungroupConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm Ungroup'**
  String get ungroupConfirm;

  /// No description provided for @ungroupDescription.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to disband this group?'**
  String get ungroupDescription;

  /// No description provided for @unknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get unknown;

  /// No description provided for @unknownCategory.
  ///
  /// In en, this message translates to:
  /// **'Unknown Category'**
  String get unknownCategory;

  /// No description provided for @unknownElementType.
  ///
  /// In en, this message translates to:
  /// **'Unknown Element Type: {type}'**
  String unknownElementType(Object type);

  /// No description provided for @unknownError.
  ///
  /// In en, this message translates to:
  /// **'Unknown Error'**
  String get unknownError;

  /// No description provided for @unlockElement.
  ///
  /// In en, this message translates to:
  /// **'Unlock Element'**
  String get unlockElement;

  /// No description provided for @unlocked.
  ///
  /// In en, this message translates to:
  /// **'Unlocked'**
  String get unlocked;

  /// No description provided for @unnamedElement.
  ///
  /// In en, this message translates to:
  /// **'Unnamed Element'**
  String get unnamedElement;

  /// No description provided for @unnamedGroup.
  ///
  /// In en, this message translates to:
  /// **'Unnamed Group'**
  String get unnamedGroup;

  /// No description provided for @unnamedLayer.
  ///
  /// In en, this message translates to:
  /// **'Unnamed Layer'**
  String get unnamedLayer;

  /// No description provided for @unsavedChanges.
  ///
  /// In en, this message translates to:
  /// **'Unsaved Changes'**
  String get unsavedChanges;

  /// No description provided for @updateTime.
  ///
  /// In en, this message translates to:
  /// **'Update Time'**
  String get updateTime;

  /// No description provided for @updatedAt.
  ///
  /// In en, this message translates to:
  /// **'Updated At'**
  String get updatedAt;

  /// No description provided for @usageInstructions.
  ///
  /// In en, this message translates to:
  /// **'Usage Instructions'**
  String get usageInstructions;

  /// No description provided for @useDefaultPath.
  ///
  /// In en, this message translates to:
  /// **'Use default path'**
  String get useDefaultPath;

  /// No description provided for @userConfig.
  ///
  /// In en, this message translates to:
  /// **'User Configuration'**
  String get userConfig;

  /// No description provided for @validCharacter.
  ///
  /// In en, this message translates to:
  /// **'Please Enter Valid Character'**
  String get validCharacter;

  /// No description provided for @validPath.
  ///
  /// In en, this message translates to:
  /// **'Valid path'**
  String get validPath;

  /// No description provided for @validateData.
  ///
  /// In en, this message translates to:
  /// **'Validate Data'**
  String get validateData;

  /// No description provided for @validateDataDescription.
  ///
  /// In en, this message translates to:
  /// **'Verify data integrity before import'**
  String get validateDataDescription;

  /// No description provided for @validateDataMandatory.
  ///
  /// In en, this message translates to:
  /// **'Mandatory validation of import file integrity and format to ensure data security'**
  String get validateDataMandatory;

  /// No description provided for @validatingImportFile.
  ///
  /// In en, this message translates to:
  /// **'Validating import file...'**
  String get validatingImportFile;

  /// No description provided for @valueTooLarge.
  ///
  /// In en, this message translates to:
  /// **'{label} Cannot Be Greater Than {max}'**
  String valueTooLarge(Object label, Object max);

  /// No description provided for @valueTooSmall.
  ///
  /// In en, this message translates to:
  /// **'{label} Cannot Be Less Than {min}'**
  String valueTooSmall(Object label, Object min);

  /// No description provided for @versionDetails.
  ///
  /// In en, this message translates to:
  /// **'Version Details'**
  String get versionDetails;

  /// No description provided for @versionInfoCopied.
  ///
  /// In en, this message translates to:
  /// **'Version info copied to clipboard'**
  String get versionInfoCopied;

  /// No description provided for @verticalAlignment.
  ///
  /// In en, this message translates to:
  /// **'Vertical Alignment'**
  String get verticalAlignment;

  /// No description provided for @verticalLeftToRight.
  ///
  /// In en, this message translates to:
  /// **'Vertical Left to Right'**
  String get verticalLeftToRight;

  /// No description provided for @verticalRightToLeft.
  ///
  /// In en, this message translates to:
  /// **'Vertical Right to Left'**
  String get verticalRightToLeft;

  /// No description provided for @viewAction.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get viewAction;

  /// No description provided for @viewDetails.
  ///
  /// In en, this message translates to:
  /// **'View Details'**
  String get viewDetails;

  /// No description provided for @viewExportResultsButton.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get viewExportResultsButton;

  /// No description provided for @visibility.
  ///
  /// In en, this message translates to:
  /// **'Visibility'**
  String get visibility;

  /// No description provided for @visible.
  ///
  /// In en, this message translates to:
  /// **'Visible'**
  String get visible;

  /// No description provided for @visualProperties.
  ///
  /// In en, this message translates to:
  /// **'Visual Properties'**
  String get visualProperties;

  /// No description provided for @visualSettings.
  ///
  /// In en, this message translates to:
  /// **'Visual Settings'**
  String get visualSettings;

  /// No description provided for @warningOverwriteData.
  ///
  /// In en, this message translates to:
  /// **'Warning: This will overwrite all current data!'**
  String get warningOverwriteData;

  /// No description provided for @warnings.
  ///
  /// In en, this message translates to:
  /// **'Warnings'**
  String get warnings;

  /// No description provided for @widgetRefRequired.
  ///
  /// In en, this message translates to:
  /// **'WidgetRef Required to Create CollectionPainter'**
  String get widgetRefRequired;

  /// No description provided for @width.
  ///
  /// In en, this message translates to:
  /// **'Width'**
  String get width;

  /// No description provided for @windowButtonMaximize.
  ///
  /// In en, this message translates to:
  /// **'Maximize'**
  String get windowButtonMaximize;

  /// No description provided for @windowButtonMinimize.
  ///
  /// In en, this message translates to:
  /// **'Minimize'**
  String get windowButtonMinimize;

  /// No description provided for @windowButtonRestore.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get windowButtonRestore;

  /// No description provided for @work.
  ///
  /// In en, this message translates to:
  /// **'Work'**
  String get work;

  /// No description provided for @workBrowseSearch.
  ///
  /// In en, this message translates to:
  /// **'Search Works...'**
  String get workBrowseSearch;

  /// No description provided for @workBrowseTitle.
  ///
  /// In en, this message translates to:
  /// **'Works'**
  String get workBrowseTitle;

  /// No description provided for @workCount.
  ///
  /// In en, this message translates to:
  /// **'Work Count'**
  String get workCount;

  /// No description provided for @workDetailCharacters.
  ///
  /// In en, this message translates to:
  /// **'Characters'**
  String get workDetailCharacters;

  /// No description provided for @workDetailOtherInfo.
  ///
  /// In en, this message translates to:
  /// **'Other Information'**
  String get workDetailOtherInfo;

  /// No description provided for @workDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Work Details'**
  String get workDetailTitle;

  /// No description provided for @workFormAuthorHelp.
  ///
  /// In en, this message translates to:
  /// **'Optional, the creator of the work'**
  String get workFormAuthorHelp;

  /// No description provided for @workFormAuthorHint.
  ///
  /// In en, this message translates to:
  /// **'Enter Author Name'**
  String get workFormAuthorHint;

  /// No description provided for @workFormAuthorMaxLength.
  ///
  /// In en, this message translates to:
  /// **'Author name cannot exceed 50 characters'**
  String get workFormAuthorMaxLength;

  /// No description provided for @workFormAuthorTooltip.
  ///
  /// In en, this message translates to:
  /// **'Press Ctrl+A to quickly jump to author field'**
  String get workFormAuthorTooltip;

  /// No description provided for @workFormCreationDateError.
  ///
  /// In en, this message translates to:
  /// **'Creation date cannot exceed current date'**
  String get workFormCreationDateError;

  /// No description provided for @workFormDateHelp.
  ///
  /// In en, this message translates to:
  /// **'Completion date of the work'**
  String get workFormDateHelp;

  /// No description provided for @workFormRemarkHelp.
  ///
  /// In en, this message translates to:
  /// **'Optional, additional information about the work'**
  String get workFormRemarkHelp;

  /// No description provided for @workFormRemarkMaxLength.
  ///
  /// In en, this message translates to:
  /// **'Remarks cannot exceed 500 characters'**
  String get workFormRemarkMaxLength;

  /// No description provided for @workFormRemarkTooltip.
  ///
  /// In en, this message translates to:
  /// **'Press Ctrl+R to quickly jump to remarks field'**
  String get workFormRemarkTooltip;

  /// No description provided for @workFormStyleHelp.
  ///
  /// In en, this message translates to:
  /// **'Primary style type of the work'**
  String get workFormStyleHelp;

  /// No description provided for @workFormTitleHelp.
  ///
  /// In en, this message translates to:
  /// **'Main title of the work, displayed in the work list'**
  String get workFormTitleHelp;

  /// No description provided for @workFormTitleMaxLength.
  ///
  /// In en, this message translates to:
  /// **'Title cannot exceed 100 characters'**
  String get workFormTitleMaxLength;

  /// No description provided for @workFormTitleMinLength.
  ///
  /// In en, this message translates to:
  /// **'Title must be at least 2 characters'**
  String get workFormTitleMinLength;

  /// No description provided for @workFormTitleRequired.
  ///
  /// In en, this message translates to:
  /// **'Title is required'**
  String get workFormTitleRequired;

  /// No description provided for @workFormTitleTooltip.
  ///
  /// In en, this message translates to:
  /// **'Press Ctrl+T to quickly jump to title field'**
  String get workFormTitleTooltip;

  /// No description provided for @workFormToolHelp.
  ///
  /// In en, this message translates to:
  /// **'Primary tool used to create this work'**
  String get workFormToolHelp;

  /// No description provided for @workIdCannotBeEmpty.
  ///
  /// In en, this message translates to:
  /// **'Work ID cannot be empty'**
  String get workIdCannotBeEmpty;

  /// No description provided for @workInfo.
  ///
  /// In en, this message translates to:
  /// **'Work Information'**
  String get workInfo;

  /// No description provided for @workStyleClerical.
  ///
  /// In en, this message translates to:
  /// **'Clerical Script'**
  String get workStyleClerical;

  /// No description provided for @workStyleCursive.
  ///
  /// In en, this message translates to:
  /// **'Cursive Script'**
  String get workStyleCursive;

  /// No description provided for @workStyleRegular.
  ///
  /// In en, this message translates to:
  /// **'Regular Script'**
  String get workStyleRegular;

  /// No description provided for @workStyleRunning.
  ///
  /// In en, this message translates to:
  /// **'Running Script'**
  String get workStyleRunning;

  /// No description provided for @workStyleSeal.
  ///
  /// In en, this message translates to:
  /// **'Seal Script'**
  String get workStyleSeal;

  /// No description provided for @workToolBrush.
  ///
  /// In en, this message translates to:
  /// **'Brush'**
  String get workToolBrush;

  /// No description provided for @workToolHardPen.
  ///
  /// In en, this message translates to:
  /// **'Hard Pen'**
  String get workToolHardPen;

  /// No description provided for @workToolOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get workToolOther;

  /// No description provided for @works.
  ///
  /// In en, this message translates to:
  /// **'Works'**
  String get works;

  /// No description provided for @worksCount.
  ///
  /// In en, this message translates to:
  /// **'{count} works'**
  String worksCount(Object count);

  /// No description provided for @writingMode.
  ///
  /// In en, this message translates to:
  /// **'Writing Mode'**
  String get writingMode;

  /// No description provided for @writingTool.
  ///
  /// In en, this message translates to:
  /// **'Writing Tool'**
  String get writingTool;

  /// No description provided for @writingToolManagement.
  ///
  /// In en, this message translates to:
  /// **'Writing Tool Management'**
  String get writingToolManagement;

  /// No description provided for @writingToolText.
  ///
  /// In en, this message translates to:
  /// **'Writing Tool'**
  String get writingToolText;

  /// No description provided for @yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No description provided for @yesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get yesterday;

  /// No description provided for @zipFile.
  ///
  /// In en, this message translates to:
  /// **'ZIP Archive'**
  String get zipFile;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'ja', 'ko', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {

  // Lookup logic when language+country codes are specified.
  switch (locale.languageCode) {
    case 'zh': {
  switch (locale.countryCode) {
    case 'TW': return AppLocalizationsZhTw();
   }
  break;
   }
  }

  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en': return AppLocalizationsEn();
    case 'ja': return AppLocalizationsJa();
    case 'ko': return AppLocalizationsKo();
    case 'zh': return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
