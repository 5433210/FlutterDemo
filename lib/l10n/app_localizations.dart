import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
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
    Locale('zh')
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

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'Calligraphy Collection'**
  String get appName;

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Calligraphy Collection'**
  String get appTitle;

  /// No description provided for @backgroundColor.
  ///
  /// In en, this message translates to:
  /// **'Background Color'**
  String get backgroundColor;

  /// No description provided for @basicInfo.
  ///
  /// In en, this message translates to:
  /// **'Basic Info'**
  String get basicInfo;

  /// No description provided for @bringLayerToFront.
  ///
  /// In en, this message translates to:
  /// **'Bring Layer to Front'**
  String get bringLayerToFront;

  /// No description provided for @bringToFront.
  ///
  /// In en, this message translates to:
  /// **'Bring to Front'**
  String get bringToFront;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @canvasPixelSize.
  ///
  /// In en, this message translates to:
  /// **'Canvas Pixel Size'**
  String get canvasPixelSize;

  /// No description provided for @characterCollectionBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get characterCollectionBack;

  /// No description provided for @characterCollectionDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm Deletion'**
  String get characterCollectionDeleteConfirm;

  /// No description provided for @characterCollectionDeleteMessage.
  ///
  /// In en, this message translates to:
  /// **'You are about to delete the selected region. This action cannot be undone.'**
  String get characterCollectionDeleteMessage;

  /// No description provided for @characterCollectionDeleteShortcuts.
  ///
  /// In en, this message translates to:
  /// **'Shortcuts: Enter to confirm, Esc to cancel'**
  String get characterCollectionDeleteShortcuts;

  /// No description provided for @characterCollectionFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get characterCollectionFilterAll;

  /// No description provided for @characterCollectionFilterFavorite.
  ///
  /// In en, this message translates to:
  /// **'Favorite'**
  String get characterCollectionFilterFavorite;

  /// No description provided for @characterCollectionFilterRecent.
  ///
  /// In en, this message translates to:
  /// **'Recent'**
  String get characterCollectionFilterRecent;

  /// No description provided for @characterCollectionHelp.
  ///
  /// In en, this message translates to:
  /// **'Help'**
  String get characterCollectionHelp;

  /// No description provided for @characterCollectionHelpClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get characterCollectionHelpClose;

  /// No description provided for @characterCollectionHelpExport.
  ///
  /// In en, this message translates to:
  /// **'Export Help Document'**
  String get characterCollectionHelpExport;

  /// No description provided for @characterCollectionHelpExportSoon.
  ///
  /// In en, this message translates to:
  /// **'Help document export coming soon'**
  String get characterCollectionHelpExportSoon;

  /// No description provided for @characterCollectionHelpGuide.
  ///
  /// In en, this message translates to:
  /// **'Character Collection Guide'**
  String get characterCollectionHelpGuide;

  /// No description provided for @characterCollectionHelpIntro.
  ///
  /// In en, this message translates to:
  /// **'Character collection allows you to extract, edit, and manage characters from images. Here\'s a detailed guide:'**
  String get characterCollectionHelpIntro;

  /// No description provided for @characterCollectionHelpNotes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get characterCollectionHelpNotes;

  /// No description provided for @characterCollectionHelpSection1.
  ///
  /// In en, this message translates to:
  /// **'1. Selection & Navigation'**
  String get characterCollectionHelpSection1;

  /// No description provided for @characterCollectionHelpSection2.
  ///
  /// In en, this message translates to:
  /// **'2. Region Adjustment'**
  String get characterCollectionHelpSection2;

  /// No description provided for @characterCollectionHelpSection3.
  ///
  /// In en, this message translates to:
  /// **'3. Eraser Tool'**
  String get characterCollectionHelpSection3;

  /// No description provided for @characterCollectionHelpSection4.
  ///
  /// In en, this message translates to:
  /// **'4. Data Saving'**
  String get characterCollectionHelpSection4;

  /// No description provided for @characterCollectionHelpSection5.
  ///
  /// In en, this message translates to:
  /// **'5. Keyboard Shortcuts'**
  String get characterCollectionHelpSection5;

  /// No description provided for @characterCollectionHelpTitle.
  ///
  /// In en, this message translates to:
  /// **'Character Collection Help'**
  String get characterCollectionHelpTitle;

  /// No description provided for @characterCollectionImageInvalid.
  ///
  /// In en, this message translates to:
  /// **'Image data is invalid or corrupted'**
  String get characterCollectionImageInvalid;

  /// No description provided for @characterCollectionImageLoadError.
  ///
  /// In en, this message translates to:
  /// **'Failed to load image'**
  String get characterCollectionImageLoadError;

  /// No description provided for @characterCollectionLeave.
  ///
  /// In en, this message translates to:
  /// **'Leave'**
  String get characterCollectionLeave;

  /// No description provided for @characterCollectionLoadingImage.
  ///
  /// In en, this message translates to:
  /// **'Loading image...'**
  String get characterCollectionLoadingImage;

  /// No description provided for @characterCollectionNextPage.
  ///
  /// In en, this message translates to:
  /// **'Next Page'**
  String get characterCollectionNextPage;

  /// No description provided for @characterCollectionNoCharacter.
  ///
  /// In en, this message translates to:
  /// **'No character'**
  String get characterCollectionNoCharacter;

  /// No description provided for @characterCollectionNoCharacters.
  ///
  /// In en, this message translates to:
  /// **'No characters collected yet'**
  String get characterCollectionNoCharacters;

  /// No description provided for @characterCollectionPreviewTab.
  ///
  /// In en, this message translates to:
  /// **'Character Preview'**
  String get characterCollectionPreviewTab;

  /// No description provided for @characterCollectionPreviousPage.
  ///
  /// In en, this message translates to:
  /// **'Previous Page'**
  String get characterCollectionPreviousPage;

  /// No description provided for @characterCollectionProcessing.
  ///
  /// In en, this message translates to:
  /// **'Processing...'**
  String get characterCollectionProcessing;

  /// No description provided for @characterCollectionResultsTab.
  ///
  /// In en, this message translates to:
  /// **'Collection Results'**
  String get characterCollectionResultsTab;

  /// No description provided for @characterCollectionRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get characterCollectionRetry;

  /// No description provided for @characterCollectionReturnToDetails.
  ///
  /// In en, this message translates to:
  /// **'Return to Work Details'**
  String get characterCollectionReturnToDetails;

  /// No description provided for @characterCollectionSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search characters...'**
  String get characterCollectionSearchHint;

  /// No description provided for @characterCollectionSelectRegion.
  ///
  /// In en, this message translates to:
  /// **'Please select character regions in the preview area'**
  String get characterCollectionSelectRegion;

  /// No description provided for @characterCollectionSwitchingPage.
  ///
  /// In en, this message translates to:
  /// **'Switching to character page...'**
  String get characterCollectionSwitchingPage;

  /// No description provided for @characterCollectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Character Collection'**
  String get characterCollectionTitle;

  /// No description provided for @characterCollectionToolDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete selected (Ctrl+D)'**
  String get characterCollectionToolDelete;

  /// No description provided for @characterCollectionToolPan.
  ///
  /// In en, this message translates to:
  /// **'Pan tool (Ctrl+V)'**
  String get characterCollectionToolPan;

  /// No description provided for @characterCollectionToolSelect.
  ///
  /// In en, this message translates to:
  /// **'Selection tool (Ctrl+B)'**
  String get characterCollectionToolSelect;

  /// No description provided for @characterCollectionUnsavedChanges.
  ///
  /// In en, this message translates to:
  /// **'Unsaved Changes'**
  String get characterCollectionUnsavedChanges;

  /// No description provided for @characterCollectionUnsavedChangesMessage.
  ///
  /// In en, this message translates to:
  /// **'You have unsaved region modifications. Leaving will discard these changes.\n\nAre you sure you want to leave?'**
  String get characterCollectionUnsavedChangesMessage;

  /// No description provided for @characterCollectionUseSelectionTool.
  ///
  /// In en, this message translates to:
  /// **'Use the selection tool on the left to extract characters from the image'**
  String get characterCollectionUseSelectionTool;

  /// No description provided for @characterDetailAuthor.
  ///
  /// In en, this message translates to:
  /// **'Author'**
  String get characterDetailAuthor;

  /// No description provided for @characterDetailBasicInfo.
  ///
  /// In en, this message translates to:
  /// **'Basic Information'**
  String get characterDetailBasicInfo;

  /// No description provided for @characterDetailCalligraphyStyle.
  ///
  /// In en, this message translates to:
  /// **'Calligraphy Style'**
  String get characterDetailCalligraphyStyle;

  /// No description provided for @characterDetailCollectionTime.
  ///
  /// In en, this message translates to:
  /// **'Collection Time'**
  String get characterDetailCollectionTime;

  /// No description provided for @characterDetailCreationTime.
  ///
  /// In en, this message translates to:
  /// **'Creation Time'**
  String get characterDetailCreationTime;

  /// No description provided for @characterDetailLoadError.
  ///
  /// In en, this message translates to:
  /// **'Failed to load character details'**
  String get characterDetailLoadError;

  /// No description provided for @characterDetailSimplifiedChar.
  ///
  /// In en, this message translates to:
  /// **'Simplified Character'**
  String get characterDetailSimplifiedChar;

  /// No description provided for @characterDetailTags.
  ///
  /// In en, this message translates to:
  /// **'Tags'**
  String get characterDetailTags;

  /// No description provided for @characterDetailUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get characterDetailUnknown;

  /// No description provided for @characterDetailWorkInfo.
  ///
  /// In en, this message translates to:
  /// **'Work Information'**
  String get characterDetailWorkInfo;

  /// No description provided for @characterDetailWorkTitle.
  ///
  /// In en, this message translates to:
  /// **'Work Title'**
  String get characterDetailWorkTitle;

  /// No description provided for @characterDetailWritingTool.
  ///
  /// In en, this message translates to:
  /// **'Writing Tool'**
  String get characterDetailWritingTool;

  /// No description provided for @characterEditCompletingSave.
  ///
  /// In en, this message translates to:
  /// **'Completing save...'**
  String get characterEditCompletingSave;

  /// No description provided for @characterEditImageInvert.
  ///
  /// In en, this message translates to:
  /// **'Image Inversion'**
  String get characterEditImageInvert;

  /// No description provided for @characterEditImageLoadError.
  ///
  /// In en, this message translates to:
  /// **'Image Load Error'**
  String get characterEditImageLoadError;

  /// No description provided for @characterEditImageLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load or process character image'**
  String get characterEditImageLoadFailed;

  /// No description provided for @characterEditInitializing.
  ///
  /// In en, this message translates to:
  /// **'Initializing...'**
  String get characterEditInitializing;

  /// No description provided for @characterEditInputCharacter.
  ///
  /// In en, this message translates to:
  /// **'Input Character'**
  String get characterEditInputCharacter;

  /// No description provided for @characterEditInputHint.
  ///
  /// In en, this message translates to:
  /// **'Type here'**
  String get characterEditInputHint;

  /// No description provided for @characterEditInvertMode.
  ///
  /// In en, this message translates to:
  /// **'Invert Mode'**
  String get characterEditInvertMode;

  /// No description provided for @characterEditLoadingImage.
  ///
  /// In en, this message translates to:
  /// **'Loading character image...'**
  String get characterEditLoadingImage;

  /// No description provided for @characterEditNoRegionSelected.
  ///
  /// In en, this message translates to:
  /// **'No region selected'**
  String get characterEditNoRegionSelected;

  /// No description provided for @characterEditOnlyOneCharacter.
  ///
  /// In en, this message translates to:
  /// **'Only one character allowed'**
  String get characterEditOnlyOneCharacter;

  /// No description provided for @characterEditPanImage.
  ///
  /// In en, this message translates to:
  /// **'Pan image (hold Alt)'**
  String get characterEditPanImage;

  /// No description provided for @characterEditPleaseEnterCharacter.
  ///
  /// In en, this message translates to:
  /// **'Please enter a character'**
  String get characterEditPleaseEnterCharacter;

  /// No description provided for @characterEditPreparingSave.
  ///
  /// In en, this message translates to:
  /// **'Preparing to save...'**
  String get characterEditPreparingSave;

  /// No description provided for @characterEditProcessingEraseData.
  ///
  /// In en, this message translates to:
  /// **'Processing erase data...'**
  String get characterEditProcessingEraseData;

  /// No description provided for @characterEditProcessingImage.
  ///
  /// In en, this message translates to:
  /// **'Processing image...'**
  String get characterEditProcessingImage;

  /// No description provided for @characterEditRedo.
  ///
  /// In en, this message translates to:
  /// **'Redo'**
  String get characterEditRedo;

  /// No description provided for @characterEditSaveComplete.
  ///
  /// In en, this message translates to:
  /// **'Save complete'**
  String get characterEditSaveComplete;

  /// No description provided for @characterEditSaveConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Save Character'**
  String get characterEditSaveConfirmTitle;

  /// No description provided for @characterEditSavePreview.
  ///
  /// In en, this message translates to:
  /// **'Character preview:'**
  String get characterEditSavePreview;

  /// No description provided for @characterEditSaveShortcuts.
  ///
  /// In en, this message translates to:
  /// **'Press Enter to save, Esc to cancel'**
  String get characterEditSaveShortcuts;

  /// No description provided for @characterEditSaveTimeout.
  ///
  /// In en, this message translates to:
  /// **'Save timed out'**
  String get characterEditSaveTimeout;

  /// No description provided for @characterEditSavingToStorage.
  ///
  /// In en, this message translates to:
  /// **'Saving to storage...'**
  String get characterEditSavingToStorage;

  /// No description provided for @characterEditShowContour.
  ///
  /// In en, this message translates to:
  /// **'Show Contour'**
  String get characterEditShowContour;

  /// No description provided for @characterEditThumbnailCheckFailed.
  ///
  /// In en, this message translates to:
  /// **'Thumbnail check failed'**
  String get characterEditThumbnailCheckFailed;

  /// No description provided for @characterEditThumbnailEmpty.
  ///
  /// In en, this message translates to:
  /// **'Thumbnail file is empty'**
  String get characterEditThumbnailEmpty;

  /// No description provided for @characterEditThumbnailLoadError.
  ///
  /// In en, this message translates to:
  /// **'Failed to load thumbnail'**
  String get characterEditThumbnailLoadError;

  /// No description provided for @characterEditThumbnailLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load thumbnail'**
  String get characterEditThumbnailLoadFailed;

  /// No description provided for @characterEditThumbnailNotFound.
  ///
  /// In en, this message translates to:
  /// **'Thumbnail not found'**
  String get characterEditThumbnailNotFound;

  /// No description provided for @characterEditThumbnailSizeError.
  ///
  /// In en, this message translates to:
  /// **'Failed to get thumbnail size'**
  String get characterEditThumbnailSizeError;

  /// No description provided for @characterEditUndo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get characterEditUndo;

  /// No description provided for @characterEditUnknownError.
  ///
  /// In en, this message translates to:
  /// **'Unknown error'**
  String get characterEditUnknownError;

  /// No description provided for @characterEditValidChineseCharacter.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid Chinese character'**
  String get characterEditValidChineseCharacter;

  /// No description provided for @characterFilterAddTag.
  ///
  /// In en, this message translates to:
  /// **'Add Tag'**
  String get characterFilterAddTag;

  /// No description provided for @characterFilterAddTagHint.
  ///
  /// In en, this message translates to:
  /// **'Enter tag name and press Enter'**
  String get characterFilterAddTagHint;

  /// No description provided for @characterFilterCalligraphyStyle.
  ///
  /// In en, this message translates to:
  /// **'Calligraphy Style'**
  String get characterFilterCalligraphyStyle;

  /// No description provided for @characterFilterCollapse.
  ///
  /// In en, this message translates to:
  /// **'Collapse Filter Panel'**
  String get characterFilterCollapse;

  /// No description provided for @characterFilterCollectionDate.
  ///
  /// In en, this message translates to:
  /// **'Collection Date'**
  String get characterFilterCollectionDate;

  /// No description provided for @characterFilterCreationDate.
  ///
  /// In en, this message translates to:
  /// **'Creation Date'**
  String get characterFilterCreationDate;

  /// No description provided for @characterFilterExpand.
  ///
  /// In en, this message translates to:
  /// **'Expand Filter Panel'**
  String get characterFilterExpand;

  /// No description provided for @characterFilterFavoritesOnly.
  ///
  /// In en, this message translates to:
  /// **'Show favorites only'**
  String get characterFilterFavoritesOnly;

  /// No description provided for @characterFilterSelectedTags.
  ///
  /// In en, this message translates to:
  /// **'Selected Tags:'**
  String get characterFilterSelectedTags;

  /// No description provided for @characterFilterSort.
  ///
  /// In en, this message translates to:
  /// **'Sort'**
  String get characterFilterSort;

  /// No description provided for @characterFilterTags.
  ///
  /// In en, this message translates to:
  /// **'Tags'**
  String get characterFilterTags;

  /// No description provided for @characterFilterTitle.
  ///
  /// In en, this message translates to:
  /// **'Filter Options'**
  String get characterFilterTitle;

  /// No description provided for @characterFilterWritingTool.
  ///
  /// In en, this message translates to:
  /// **'Writing Tool'**
  String get characterFilterWritingTool;

  /// No description provided for @characterManagementBatchDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get characterManagementBatchDone;

  /// No description provided for @characterManagementBatchMode.
  ///
  /// In en, this message translates to:
  /// **'Batch Mode'**
  String get characterManagementBatchMode;

  /// No description provided for @characterManagementDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm Deletion'**
  String get characterManagementDeleteConfirm;

  /// No description provided for @characterManagementDeleteMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete the selected characters? This action cannot be undone.'**
  String get characterManagementDeleteMessage;

  /// No description provided for @characterManagementDeleteSelected.
  ///
  /// In en, this message translates to:
  /// **'Delete selected'**
  String get characterManagementDeleteSelected;

  /// No description provided for @characterManagementGridView.
  ///
  /// In en, this message translates to:
  /// **'Grid View'**
  String get characterManagementGridView;

  /// No description provided for @characterManagementListView.
  ///
  /// In en, this message translates to:
  /// **'List View'**
  String get characterManagementListView;

  /// No description provided for @characterManagementLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading characters...'**
  String get characterManagementLoading;

  /// No description provided for @characterManagementNoCharacters.
  ///
  /// In en, this message translates to:
  /// **'No characters found'**
  String get characterManagementNoCharacters;

  /// No description provided for @characterManagementNoCharactersHint.
  ///
  /// In en, this message translates to:
  /// **'Try changing your search or filter criteria'**
  String get characterManagementNoCharactersHint;

  /// No description provided for @characterManagementSearch.
  ///
  /// In en, this message translates to:
  /// **'Search characters, works, or authors'**
  String get characterManagementSearch;

  /// No description provided for @characterManagementTitle.
  ///
  /// In en, this message translates to:
  /// **'Character Management'**
  String get characterManagementTitle;

  /// No description provided for @characters.
  ///
  /// In en, this message translates to:
  /// **'Characters'**
  String get characters;

  /// No description provided for @clearImageCache.
  ///
  /// In en, this message translates to:
  /// **'Clear Image Cache'**
  String get clearImageCache;

  /// No description provided for @collectionPropertyPanel.
  ///
  /// In en, this message translates to:
  /// **'Collection Properties'**
  String get collectionPropertyPanel;

  /// No description provided for @collectionPropertyPanelBackgroundColor.
  ///
  /// In en, this message translates to:
  /// **'Background Color'**
  String get collectionPropertyPanelBackgroundColor;

  /// No description provided for @collectionPropertyPanelBorder.
  ///
  /// In en, this message translates to:
  /// **'Border'**
  String get collectionPropertyPanelBorder;

  /// No description provided for @collectionPropertyPanelBorderColor.
  ///
  /// In en, this message translates to:
  /// **'Border Color'**
  String get collectionPropertyPanelBorderColor;

  /// No description provided for @collectionPropertyPanelBorderWidth.
  ///
  /// In en, this message translates to:
  /// **'Border Width'**
  String get collectionPropertyPanelBorderWidth;

  /// No description provided for @collectionPropertyPanelCacheCleared.
  ///
  /// In en, this message translates to:
  /// **'Image cache cleared'**
  String get collectionPropertyPanelCacheCleared;

  /// No description provided for @collectionPropertyPanelCacheClearFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to clear image cache'**
  String get collectionPropertyPanelCacheClearFailed;

  /// No description provided for @collectionPropertyPanelCandidateCharacters.
  ///
  /// In en, this message translates to:
  /// **'Candidate Characters'**
  String get collectionPropertyPanelCandidateCharacters;

  /// No description provided for @collectionPropertyPanelCharacter.
  ///
  /// In en, this message translates to:
  /// **'Character'**
  String get collectionPropertyPanelCharacter;

  /// No description provided for @collectionPropertyPanelCharacterSettings.
  ///
  /// In en, this message translates to:
  /// **'Character Settings'**
  String get collectionPropertyPanelCharacterSettings;

  /// No description provided for @collectionPropertyPanelCharacterSource.
  ///
  /// In en, this message translates to:
  /// **'Character Source'**
  String get collectionPropertyPanelCharacterSource;

  /// No description provided for @collectionPropertyPanelCharIndex.
  ///
  /// In en, this message translates to:
  /// **'Character'**
  String get collectionPropertyPanelCharIndex;

  /// No description provided for @collectionPropertyPanelClearImageCache.
  ///
  /// In en, this message translates to:
  /// **'Clear Image Cache'**
  String get collectionPropertyPanelClearImageCache;

  /// No description provided for @collectionPropertyPanelColorInversion.
  ///
  /// In en, this message translates to:
  /// **'Color Inversion'**
  String get collectionPropertyPanelColorInversion;

  /// No description provided for @collectionPropertyPanelContent.
  ///
  /// In en, this message translates to:
  /// **'Content Properties'**
  String get collectionPropertyPanelContent;

  /// No description provided for @collectionPropertyPanelDisabled.
  ///
  /// In en, this message translates to:
  /// **'Disabled'**
  String get collectionPropertyPanelDisabled;

  /// No description provided for @collectionPropertyPanelEnabled.
  ///
  /// In en, this message translates to:
  /// **'Enabled'**
  String get collectionPropertyPanelEnabled;

  /// No description provided for @collectionPropertyPanelFlip.
  ///
  /// In en, this message translates to:
  /// **'Flip'**
  String get collectionPropertyPanelFlip;

  /// No description provided for @collectionPropertyPanelFlipHorizontally.
  ///
  /// In en, this message translates to:
  /// **'Flip Horizontally'**
  String get collectionPropertyPanelFlipHorizontally;

  /// No description provided for @collectionPropertyPanelFlipVertically.
  ///
  /// In en, this message translates to:
  /// **'Flip Vertically'**
  String get collectionPropertyPanelFlipVertically;

  /// No description provided for @collectionPropertyPanelFontSize.
  ///
  /// In en, this message translates to:
  /// **'Font Size'**
  String get collectionPropertyPanelFontSize;

  /// No description provided for @collectionPropertyPanelGeometry.
  ///
  /// In en, this message translates to:
  /// **'Geometry Properties'**
  String get collectionPropertyPanelGeometry;

  /// No description provided for @collectionPropertyPanelHeaderContent.
  ///
  /// In en, this message translates to:
  /// **'Content Properties'**
  String get collectionPropertyPanelHeaderContent;

  /// No description provided for @collectionPropertyPanelHeaderGeometry.
  ///
  /// In en, this message translates to:
  /// **'Geometry Properties'**
  String get collectionPropertyPanelHeaderGeometry;

  /// No description provided for @collectionPropertyPanelHeaderVisual.
  ///
  /// In en, this message translates to:
  /// **'Visual Properties'**
  String get collectionPropertyPanelHeaderVisual;

  /// No description provided for @collectionPropertyPanelInvertDisplay.
  ///
  /// In en, this message translates to:
  /// **'Invert Display Colors'**
  String get collectionPropertyPanelInvertDisplay;

  /// No description provided for @collectionPropertyPanelNoCharacterSelected.
  ///
  /// In en, this message translates to:
  /// **'No character selected'**
  String get collectionPropertyPanelNoCharacterSelected;

  /// No description provided for @collectionPropertyPanelNoCharactersFound.
  ///
  /// In en, this message translates to:
  /// **'No matching characters found'**
  String get collectionPropertyPanelNoCharactersFound;

  /// No description provided for @collectionPropertyPanelNoCharacterText.
  ///
  /// In en, this message translates to:
  /// **'No character'**
  String get collectionPropertyPanelNoCharacterText;

  /// No description provided for @collectionPropertyPanelOf.
  ///
  /// In en, this message translates to:
  /// **'of'**
  String get collectionPropertyPanelOf;

  /// No description provided for @collectionPropertyPanelOpacity.
  ///
  /// In en, this message translates to:
  /// **'Opacity'**
  String get collectionPropertyPanelOpacity;

  /// No description provided for @collectionPropertyPanelOriginal.
  ///
  /// In en, this message translates to:
  /// **'Original'**
  String get collectionPropertyPanelOriginal;

  /// No description provided for @collectionPropertyPanelPadding.
  ///
  /// In en, this message translates to:
  /// **'Padding'**
  String get collectionPropertyPanelPadding;

  /// No description provided for @collectionPropertyPanelPropertyUpdated.
  ///
  /// In en, this message translates to:
  /// **'Property updated'**
  String get collectionPropertyPanelPropertyUpdated;

  /// No description provided for @collectionPropertyPanelRender.
  ///
  /// In en, this message translates to:
  /// **'Render Mode'**
  String get collectionPropertyPanelRender;

  /// No description provided for @collectionPropertyPanelReset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get collectionPropertyPanelReset;

  /// No description provided for @collectionPropertyPanelRotation.
  ///
  /// In en, this message translates to:
  /// **'Rotation'**
  String get collectionPropertyPanelRotation;

  /// No description provided for @collectionPropertyPanelScale.
  ///
  /// In en, this message translates to:
  /// **'Scale'**
  String get collectionPropertyPanelScale;

  /// No description provided for @collectionPropertyPanelSearchInProgress.
  ///
  /// In en, this message translates to:
  /// **'Searching characters...'**
  String get collectionPropertyPanelSearchInProgress;

  /// No description provided for @collectionPropertyPanelSelectCharacter.
  ///
  /// In en, this message translates to:
  /// **'Please select a character'**
  String get collectionPropertyPanelSelectCharacter;

  /// No description provided for @collectionPropertyPanelSelectCharacterFirst.
  ///
  /// In en, this message translates to:
  /// **'Please select a character first'**
  String get collectionPropertyPanelSelectCharacterFirst;

  /// No description provided for @collectionPropertyPanelSelectedCharacter.
  ///
  /// In en, this message translates to:
  /// **'Selected Character'**
  String get collectionPropertyPanelSelectedCharacter;

  /// No description provided for @collectionPropertyPanelStyle.
  ///
  /// In en, this message translates to:
  /// **'Style'**
  String get collectionPropertyPanelStyle;

  /// No description provided for @collectionPropertyPanelStyled.
  ///
  /// In en, this message translates to:
  /// **'Styled'**
  String get collectionPropertyPanelStyled;

  /// No description provided for @collectionPropertyPanelTextSettings.
  ///
  /// In en, this message translates to:
  /// **'Text Settings'**
  String get collectionPropertyPanelTextSettings;

  /// No description provided for @collectionPropertyPanelUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get collectionPropertyPanelUnknown;

  /// No description provided for @collectionPropertyPanelVisual.
  ///
  /// In en, this message translates to:
  /// **'Visual Settings'**
  String get collectionPropertyPanelVisual;

  /// No description provided for @collectionPropertyPanelWorkSource.
  ///
  /// In en, this message translates to:
  /// **'Work Source'**
  String get collectionPropertyPanelWorkSource;

  /// No description provided for @commonProperties.
  ///
  /// In en, this message translates to:
  /// **'Common Properties'**
  String get commonProperties;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @contains.
  ///
  /// In en, this message translates to:
  /// **'Contains'**
  String get contains;

  /// No description provided for @contentSettings.
  ///
  /// In en, this message translates to:
  /// **'Content Settings'**
  String get contentSettings;

  /// No description provided for @customSize.
  ///
  /// In en, this message translates to:
  /// **'Custom Size'**
  String get customSize;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @deleteAll.
  ///
  /// In en, this message translates to:
  /// **'Delete All'**
  String get deleteAll;

  /// No description provided for @deletePage.
  ///
  /// In en, this message translates to:
  /// **'Delete Page'**
  String get deletePage;

  /// No description provided for @dimensions.
  ///
  /// In en, this message translates to:
  /// **'Dimensions'**
  String get dimensions;

  /// No description provided for @dpiHelperText.
  ///
  /// In en, this message translates to:
  /// **'Used to calculate canvas pixel size, default is 300dpi'**
  String get dpiHelperText;

  /// No description provided for @dpiSetting.
  ///
  /// In en, this message translates to:
  /// **'DPI Setting (dots per inch)'**
  String get dpiSetting;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

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

  /// No description provided for @export.
  ///
  /// In en, this message translates to:
  /// **'Export'**
  String get export;

  /// No description provided for @filterDateApply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get filterDateApply;

  /// No description provided for @filterDateClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get filterDateClear;

  /// No description provided for @filterDateCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get filterDateCustom;

  /// No description provided for @filterDateEndDate.
  ///
  /// In en, this message translates to:
  /// **'End Date'**
  String get filterDateEndDate;

  /// No description provided for @filterDatePresetAll.
  ///
  /// In en, this message translates to:
  /// **'All Time'**
  String get filterDatePresetAll;

  /// No description provided for @filterDatePresetLast30Days.
  ///
  /// In en, this message translates to:
  /// **'Last 30 Days'**
  String get filterDatePresetLast30Days;

  /// No description provided for @filterDatePresetLast365Days.
  ///
  /// In en, this message translates to:
  /// **'Last 365 Days'**
  String get filterDatePresetLast365Days;

  /// No description provided for @filterDatePresetLast7Days.
  ///
  /// In en, this message translates to:
  /// **'Last 7 Days'**
  String get filterDatePresetLast7Days;

  /// No description provided for @filterDatePresetLast90Days.
  ///
  /// In en, this message translates to:
  /// **'Last 90 Days'**
  String get filterDatePresetLast90Days;

  /// No description provided for @filterDatePresetLastMonth.
  ///
  /// In en, this message translates to:
  /// **'Last Month'**
  String get filterDatePresetLastMonth;

  /// No description provided for @filterDatePresetLastWeek.
  ///
  /// In en, this message translates to:
  /// **'Last Week'**
  String get filterDatePresetLastWeek;

  /// No description provided for @filterDatePresetLastYear.
  ///
  /// In en, this message translates to:
  /// **'Last Year'**
  String get filterDatePresetLastYear;

  /// No description provided for @filterDatePresets.
  ///
  /// In en, this message translates to:
  /// **'Presets'**
  String get filterDatePresets;

  /// No description provided for @filterDatePresetThisMonth.
  ///
  /// In en, this message translates to:
  /// **'This Month'**
  String get filterDatePresetThisMonth;

  /// No description provided for @filterDatePresetThisWeek.
  ///
  /// In en, this message translates to:
  /// **'This Week'**
  String get filterDatePresetThisWeek;

  /// No description provided for @filterDatePresetThisYear.
  ///
  /// In en, this message translates to:
  /// **'This Year'**
  String get filterDatePresetThisYear;

  /// No description provided for @filterDatePresetToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get filterDatePresetToday;

  /// No description provided for @filterDatePresetYesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get filterDatePresetYesterday;

  /// No description provided for @filterDateSection.
  ///
  /// In en, this message translates to:
  /// **'Creation Time'**
  String get filterDateSection;

  /// No description provided for @filterDateSelectPrompt.
  ///
  /// In en, this message translates to:
  /// **'Select Date'**
  String get filterDateSelectPrompt;

  /// No description provided for @filterDateStartDate.
  ///
  /// In en, this message translates to:
  /// **'Start Date'**
  String get filterDateStartDate;

  /// No description provided for @filterReset.
  ///
  /// In en, this message translates to:
  /// **'Reset Filters'**
  String get filterReset;

  /// No description provided for @filterSortAscending.
  ///
  /// In en, this message translates to:
  /// **'Ascending'**
  String get filterSortAscending;

  /// No description provided for @filterSortDescending.
  ///
  /// In en, this message translates to:
  /// **'Descending'**
  String get filterSortDescending;

  /// No description provided for @filterSortFieldAuthor.
  ///
  /// In en, this message translates to:
  /// **'Author'**
  String get filterSortFieldAuthor;

  /// No description provided for @filterSortFieldCreateTime.
  ///
  /// In en, this message translates to:
  /// **'Creation Time'**
  String get filterSortFieldCreateTime;

  /// No description provided for @filterSortFieldCreationDate.
  ///
  /// In en, this message translates to:
  /// **'Creation Date'**
  String get filterSortFieldCreationDate;

  /// No description provided for @filterSortFieldNone.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get filterSortFieldNone;

  /// No description provided for @filterSortFieldStyle.
  ///
  /// In en, this message translates to:
  /// **'Style'**
  String get filterSortFieldStyle;

  /// No description provided for @filterSortFieldTitle.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get filterSortFieldTitle;

  /// No description provided for @filterSortFieldTool.
  ///
  /// In en, this message translates to:
  /// **'Tool'**
  String get filterSortFieldTool;

  /// No description provided for @filterSortFieldUpdateTime.
  ///
  /// In en, this message translates to:
  /// **'Update Time'**
  String get filterSortFieldUpdateTime;

  /// No description provided for @filterSortSection.
  ///
  /// In en, this message translates to:
  /// **'Sort'**
  String get filterSortSection;

  /// No description provided for @filterStyleClerical.
  ///
  /// In en, this message translates to:
  /// **'Clerical Script'**
  String get filterStyleClerical;

  /// No description provided for @filterStyleCursive.
  ///
  /// In en, this message translates to:
  /// **'Cursive Script'**
  String get filterStyleCursive;

  /// No description provided for @filterStyleOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get filterStyleOther;

  /// No description provided for @filterStyleRegular.
  ///
  /// In en, this message translates to:
  /// **'Regular Script'**
  String get filterStyleRegular;

  /// No description provided for @filterStyleRunning.
  ///
  /// In en, this message translates to:
  /// **'Running Script'**
  String get filterStyleRunning;

  /// No description provided for @filterStyleSeal.
  ///
  /// In en, this message translates to:
  /// **'Seal Script'**
  String get filterStyleSeal;

  /// No description provided for @filterStyleSection.
  ///
  /// In en, this message translates to:
  /// **'Calligraphy Style'**
  String get filterStyleSection;

  /// No description provided for @filterTitle.
  ///
  /// In en, this message translates to:
  /// **'Filter & Sort'**
  String get filterTitle;

  /// No description provided for @filterToolBrush.
  ///
  /// In en, this message translates to:
  /// **'Brush'**
  String get filterToolBrush;

  /// No description provided for @filterToolHardPen.
  ///
  /// In en, this message translates to:
  /// **'Hard Pen'**
  String get filterToolHardPen;

  /// No description provided for @filterToolOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get filterToolOther;

  /// No description provided for @filterToolSection.
  ///
  /// In en, this message translates to:
  /// **'Writing Tool'**
  String get filterToolSection;

  /// No description provided for @generalSettings.
  ///
  /// In en, this message translates to:
  /// **'General Settings'**
  String get generalSettings;

  /// No description provided for @geometryProperties.
  ///
  /// In en, this message translates to:
  /// **'Geometry Properties'**
  String get geometryProperties;

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

  /// No description provided for @group.
  ///
  /// In en, this message translates to:
  /// **'Group'**
  String get group;

  /// No description provided for @groupInfo.
  ///
  /// In en, this message translates to:
  /// **'Group Info'**
  String get groupInfo;

  /// No description provided for @height.
  ///
  /// In en, this message translates to:
  /// **'Height'**
  String get height;

  /// No description provided for @hideElement.
  ///
  /// In en, this message translates to:
  /// **'Hide Element'**
  String get hideElement;

  /// No description provided for @imageCacheCleared.
  ///
  /// In en, this message translates to:
  /// **'Image cache cleared'**
  String get imageCacheCleared;

  /// No description provided for @imageCacheClearFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to clear image cache'**
  String get imageCacheClearFailed;

  /// No description provided for @imagePropertyPanel.
  ///
  /// In en, this message translates to:
  /// **'Image Properties'**
  String get imagePropertyPanel;

  /// No description provided for @imagePropertyPanelApplyTransform.
  ///
  /// In en, this message translates to:
  /// **'Apply Transform'**
  String get imagePropertyPanelApplyTransform;

  /// No description provided for @imagePropertyPanelBorder.
  ///
  /// In en, this message translates to:
  /// **'Border'**
  String get imagePropertyPanelBorder;

  /// No description provided for @imagePropertyPanelBorderColor.
  ///
  /// In en, this message translates to:
  /// **'Border Color'**
  String get imagePropertyPanelBorderColor;

  /// No description provided for @imagePropertyPanelBorderWidth.
  ///
  /// In en, this message translates to:
  /// **'Border Width'**
  String get imagePropertyPanelBorderWidth;

  /// No description provided for @imagePropertyPanelBrightness.
  ///
  /// In en, this message translates to:
  /// **'Brightness'**
  String get imagePropertyPanelBrightness;

  /// No description provided for @imagePropertyPanelCannotApplyNoImage.
  ///
  /// In en, this message translates to:
  /// **'Cannot apply transform: No image set'**
  String get imagePropertyPanelCannotApplyNoImage;

  /// No description provided for @imagePropertyPanelCannotApplyNoSizeInfo.
  ///
  /// In en, this message translates to:
  /// **'Cannot apply transform: Image size info not available'**
  String get imagePropertyPanelCannotApplyNoSizeInfo;

  /// No description provided for @imagePropertyPanelContent.
  ///
  /// In en, this message translates to:
  /// **'Content Properties'**
  String get imagePropertyPanelContent;

  /// No description provided for @imagePropertyPanelContrast.
  ///
  /// In en, this message translates to:
  /// **'Contrast'**
  String get imagePropertyPanelContrast;

  /// No description provided for @imagePropertyPanelCornerRadius.
  ///
  /// In en, this message translates to:
  /// **'Corner Radius'**
  String get imagePropertyPanelCornerRadius;

  /// No description provided for @imagePropertyPanelCropBottom.
  ///
  /// In en, this message translates to:
  /// **'Bottom Crop'**
  String get imagePropertyPanelCropBottom;

  /// No description provided for @imagePropertyPanelCropLeft.
  ///
  /// In en, this message translates to:
  /// **'Left Crop'**
  String get imagePropertyPanelCropLeft;

  /// No description provided for @imagePropertyPanelCroppingValueTooLarge.
  ///
  /// In en, this message translates to:
  /// **'Cannot apply transform: Cropping values too large resulting in invalid crop region'**
  String get imagePropertyPanelCroppingValueTooLarge;

  /// No description provided for @imagePropertyPanelCropRight.
  ///
  /// In en, this message translates to:
  /// **'Right Crop'**
  String get imagePropertyPanelCropRight;

  /// No description provided for @imagePropertyPanelCropTop.
  ///
  /// In en, this message translates to:
  /// **'Top Crop'**
  String get imagePropertyPanelCropTop;

  /// No description provided for @imagePropertyPanelDimensions.
  ///
  /// In en, this message translates to:
  /// **'Dimensions'**
  String get imagePropertyPanelDimensions;

  /// No description provided for @imagePropertyPanelDisplay.
  ///
  /// In en, this message translates to:
  /// **'Display Mode'**
  String get imagePropertyPanelDisplay;

  /// No description provided for @imagePropertyPanelFilters.
  ///
  /// In en, this message translates to:
  /// **'Image Filters'**
  String get imagePropertyPanelFilters;

  /// No description provided for @imagePropertyPanelFit.
  ///
  /// In en, this message translates to:
  /// **'Fit'**
  String get imagePropertyPanelFit;

  /// No description provided for @imagePropertyPanelFitContain.
  ///
  /// In en, this message translates to:
  /// **'Contain'**
  String get imagePropertyPanelFitContain;

  /// No description provided for @imagePropertyPanelFitCover.
  ///
  /// In en, this message translates to:
  /// **'Cover'**
  String get imagePropertyPanelFitCover;

  /// No description provided for @imagePropertyPanelFitFill.
  ///
  /// In en, this message translates to:
  /// **'Fill'**
  String get imagePropertyPanelFitFill;

  /// No description provided for @imagePropertyPanelFitMode.
  ///
  /// In en, this message translates to:
  /// **'Fit Mode'**
  String get imagePropertyPanelFitMode;

  /// No description provided for @imagePropertyPanelFitNone.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get imagePropertyPanelFitNone;

  /// No description provided for @imagePropertyPanelFitOriginal.
  ///
  /// In en, this message translates to:
  /// **'Original'**
  String get imagePropertyPanelFitOriginal;

  /// No description provided for @imagePropertyPanelFlip.
  ///
  /// In en, this message translates to:
  /// **'Flip'**
  String get imagePropertyPanelFlip;

  /// No description provided for @imagePropertyPanelFlipHorizontal.
  ///
  /// In en, this message translates to:
  /// **'Flip Horizontal'**
  String get imagePropertyPanelFlipHorizontal;

  /// No description provided for @imagePropertyPanelFlipVertical.
  ///
  /// In en, this message translates to:
  /// **'Flip Vertical'**
  String get imagePropertyPanelFlipVertical;

  /// No description provided for @imagePropertyPanelGeometry.
  ///
  /// In en, this message translates to:
  /// **'Geometry Properties'**
  String get imagePropertyPanelGeometry;

  /// No description provided for @imagePropertyPanelGeometryWarning.
  ///
  /// In en, this message translates to:
  /// **'These properties adjust the entire element box, not the image content itself'**
  String get imagePropertyPanelGeometryWarning;

  /// No description provided for @imagePropertyPanelImageSelection.
  ///
  /// In en, this message translates to:
  /// **'Image Selection'**
  String get imagePropertyPanelImageSelection;

  /// No description provided for @imagePropertyPanelImageSize.
  ///
  /// In en, this message translates to:
  /// **'Image Size'**
  String get imagePropertyPanelImageSize;

  /// No description provided for @imagePropertyPanelImageTransform.
  ///
  /// In en, this message translates to:
  /// **'Image Transform'**
  String get imagePropertyPanelImageTransform;

  /// No description provided for @imagePropertyPanelNoCropping.
  ///
  /// In en, this message translates to:
  /// **' (No cropping, other transforms applied)'**
  String get imagePropertyPanelNoCropping;

  /// No description provided for @imagePropertyPanelNoImage.
  ///
  /// In en, this message translates to:
  /// **'No image selected'**
  String get imagePropertyPanelNoImage;

  /// No description provided for @imagePropertyPanelNoImageSelected.
  ///
  /// In en, this message translates to:
  /// **'No image selected'**
  String get imagePropertyPanelNoImageSelected;

  /// No description provided for @imagePropertyPanelOpacity.
  ///
  /// In en, this message translates to:
  /// **'Opacity'**
  String get imagePropertyPanelOpacity;

  /// No description provided for @imagePropertyPanelOriginalSize.
  ///
  /// In en, this message translates to:
  /// **'Original Size'**
  String get imagePropertyPanelOriginalSize;

  /// No description provided for @imagePropertyPanelPosition.
  ///
  /// In en, this message translates to:
  /// **'Position'**
  String get imagePropertyPanelPosition;

  /// No description provided for @imagePropertyPanelPreserveRatio.
  ///
  /// In en, this message translates to:
  /// **'Preserve Aspect Ratio'**
  String get imagePropertyPanelPreserveRatio;

  /// No description provided for @imagePropertyPanelPreview.
  ///
  /// In en, this message translates to:
  /// **'Image Preview'**
  String get imagePropertyPanelPreview;

  /// No description provided for @imagePropertyPanelPreviewNotice.
  ///
  /// In en, this message translates to:
  /// **'Note: Duplicate logs shown during preview are normal'**
  String get imagePropertyPanelPreviewNotice;

  /// No description provided for @imagePropertyPanelReset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get imagePropertyPanelReset;

  /// No description provided for @imagePropertyPanelResetSuccess.
  ///
  /// In en, this message translates to:
  /// **'All transforms reset'**
  String get imagePropertyPanelResetSuccess;

  /// No description provided for @imagePropertyPanelResetTransform.
  ///
  /// In en, this message translates to:
  /// **'Reset Transform'**
  String get imagePropertyPanelResetTransform;

  /// No description provided for @imagePropertyPanelRotation.
  ///
  /// In en, this message translates to:
  /// **'Rotation'**
  String get imagePropertyPanelRotation;

  /// No description provided for @imagePropertyPanelSaturation.
  ///
  /// In en, this message translates to:
  /// **'Saturation'**
  String get imagePropertyPanelSaturation;

  /// No description provided for @imagePropertyPanelSelectFromLocal.
  ///
  /// In en, this message translates to:
  /// **'Select from Local'**
  String get imagePropertyPanelSelectFromLocal;

  /// No description provided for @imagePropertyPanelTransformApplied.
  ///
  /// In en, this message translates to:
  /// **'Transform applied'**
  String get imagePropertyPanelTransformApplied;

  /// No description provided for @imagePropertyPanelTransformWarning.
  ///
  /// In en, this message translates to:
  /// **'These transforms modify the image content itself, not just the element frame'**
  String get imagePropertyPanelTransformWarning;

  /// No description provided for @imagePropertyPanelVisual.
  ///
  /// In en, this message translates to:
  /// **'Visual Settings'**
  String get imagePropertyPanelVisual;

  /// No description provided for @import.
  ///
  /// In en, this message translates to:
  /// **'Import'**
  String get import;

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

  /// No description provided for @layerOperations.
  ///
  /// In en, this message translates to:
  /// **'Layer Operations'**
  String get layerOperations;

  /// No description provided for @locked.
  ///
  /// In en, this message translates to:
  /// **'Locked'**
  String get locked;

  /// No description provided for @lockElement.
  ///
  /// In en, this message translates to:
  /// **'Lock Element'**
  String get lockElement;

  /// No description provided for @lockUnlockAllElements.
  ///
  /// In en, this message translates to:
  /// **'Lock/Unlock All Elements'**
  String get lockUnlockAllElements;

  /// No description provided for @moveDown.
  ///
  /// In en, this message translates to:
  /// **'Move Down'**
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
  /// **'Move Up'**
  String get moveUp;

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

  /// No description provided for @noElementsInLayer.
  ///
  /// In en, this message translates to:
  /// **'No elements in this layer'**
  String get noElementsInLayer;

  /// No description provided for @noElementsSelected.
  ///
  /// In en, this message translates to:
  /// **'No elements selected'**
  String get noElementsSelected;

  /// No description provided for @noPageSelected.
  ///
  /// In en, this message translates to:
  /// **'No page selected'**
  String get noPageSelected;

  /// No description provided for @opacity.
  ///
  /// In en, this message translates to:
  /// **'Opacity'**
  String get opacity;

  /// No description provided for @pageOrientation.
  ///
  /// In en, this message translates to:
  /// **'Page Orientation'**
  String get pageOrientation;

  /// No description provided for @pageSize.
  ///
  /// In en, this message translates to:
  /// **'Page Size'**
  String get pageSize;

  /// No description provided for @pixels.
  ///
  /// In en, this message translates to:
  /// **'pixels'**
  String get pixels;

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

  /// No description provided for @practiceEditAddElementTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Element'**
  String get practiceEditAddElementTitle;

  /// No description provided for @practiceEditAddLayer.
  ///
  /// In en, this message translates to:
  /// **'Add Layer'**
  String get practiceEditAddLayer;

  /// No description provided for @practiceEditBackToHome.
  ///
  /// In en, this message translates to:
  /// **'Back to Home'**
  String get practiceEditBackToHome;

  /// No description provided for @practiceEditBringToFront.
  ///
  /// In en, this message translates to:
  /// **'Bring to Front (Ctrl+T)'**
  String get practiceEditBringToFront;

  /// No description provided for @practiceEditCannotSaveNoPages.
  ///
  /// In en, this message translates to:
  /// **'Cannot save: Practice has no pages'**
  String get practiceEditCannotSaveNoPages;

  /// No description provided for @practiceEditCollection.
  ///
  /// In en, this message translates to:
  /// **'Collection'**
  String get practiceEditCollection;

  /// No description provided for @practiceEditCollectionProperties.
  ///
  /// In en, this message translates to:
  /// **'Collection Properties'**
  String get practiceEditCollectionProperties;

  /// No description provided for @practiceEditConfirmDeleteMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete these elements?'**
  String get practiceEditConfirmDeleteMessage;

  /// No description provided for @practiceEditConfirmDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm Delete'**
  String get practiceEditConfirmDeleteTitle;

  /// No description provided for @practiceEditContentProperties.
  ///
  /// In en, this message translates to:
  /// **'Content Properties'**
  String get practiceEditContentProperties;

  /// No description provided for @practiceEditContentTools.
  ///
  /// In en, this message translates to:
  /// **'Content Tools'**
  String get practiceEditContentTools;

  /// No description provided for @practiceEditCopy.
  ///
  /// In en, this message translates to:
  /// **'Copy (Ctrl+Shift+C)'**
  String get practiceEditCopy;

  /// No description provided for @practiceEditDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete (Ctrl+D)'**
  String get practiceEditDelete;

  /// No description provided for @practiceEditDeleteLayer.
  ///
  /// In en, this message translates to:
  /// **'Delete Layer'**
  String get practiceEditDeleteLayer;

  /// No description provided for @practiceEditDeleteLayerConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this layer?'**
  String get practiceEditDeleteLayerConfirm;

  /// No description provided for @practiceEditDeleteLayerMessage.
  ///
  /// In en, this message translates to:
  /// **'All elements on this layer will be deleted. This action cannot be undone.'**
  String get practiceEditDeleteLayerMessage;

  /// No description provided for @practiceEditDisableSnap.
  ///
  /// In en, this message translates to:
  /// **'Disable Snap (Ctrl+R)'**
  String get practiceEditDisableSnap;

  /// No description provided for @practiceEditEditOperations.
  ///
  /// In en, this message translates to:
  /// **'Edit Operations'**
  String get practiceEditEditOperations;

  /// No description provided for @practiceEditEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Title'**
  String get practiceEditEditTitle;

  /// No description provided for @practiceEditElementProperties.
  ///
  /// In en, this message translates to:
  /// **'Element Properties'**
  String get practiceEditElementProperties;

  /// No description provided for @practiceEditElements.
  ///
  /// In en, this message translates to:
  /// **'Elements'**
  String get practiceEditElements;

  /// No description provided for @practiceEditEnableSnap.
  ///
  /// In en, this message translates to:
  /// **'Enable Snap (Ctrl+R)'**
  String get practiceEditEnableSnap;

  /// No description provided for @practiceEditEnterTitle.
  ///
  /// In en, this message translates to:
  /// **'Please enter a practice title'**
  String get practiceEditEnterTitle;

  /// No description provided for @practiceEditExit.
  ///
  /// In en, this message translates to:
  /// **'Exit'**
  String get practiceEditExit;

  /// No description provided for @practiceEditGeometryProperties.
  ///
  /// In en, this message translates to:
  /// **'Geometry Properties'**
  String get practiceEditGeometryProperties;

  /// No description provided for @practiceEditGroup.
  ///
  /// In en, this message translates to:
  /// **'Group (Ctrl+J)'**
  String get practiceEditGroup;

  /// No description provided for @practiceEditGroupProperties.
  ///
  /// In en, this message translates to:
  /// **'Group Properties'**
  String get practiceEditGroupProperties;

  /// No description provided for @practiceEditHelperFunctions.
  ///
  /// In en, this message translates to:
  /// **'Helper Functions'**
  String get practiceEditHelperFunctions;

  /// No description provided for @practiceEditHideGrid.
  ///
  /// In en, this message translates to:
  /// **'Hide Grid (Ctrl+G)'**
  String get practiceEditHideGrid;

  /// No description provided for @practiceEditImage.
  ///
  /// In en, this message translates to:
  /// **'Image'**
  String get practiceEditImage;

  /// No description provided for @practiceEditImageProperties.
  ///
  /// In en, this message translates to:
  /// **'Image Properties'**
  String get practiceEditImageProperties;

  /// No description provided for @practiceEditLayerOperations.
  ///
  /// In en, this message translates to:
  /// **'Layer Operations'**
  String get practiceEditLayerOperations;

  /// No description provided for @practiceEditLayerPanel.
  ///
  /// In en, this message translates to:
  /// **'Layers'**
  String get practiceEditLayerPanel;

  /// No description provided for @practiceEditLayerProperties.
  ///
  /// In en, this message translates to:
  /// **'Layer Properties'**
  String get practiceEditLayerProperties;

  /// No description provided for @practiceEditLeave.
  ///
  /// In en, this message translates to:
  /// **'Leave'**
  String get practiceEditLeave;

  /// No description provided for @practiceEditMoveDown.
  ///
  /// In en, this message translates to:
  /// **'Move Down (Ctrl+Shift+B)'**
  String get practiceEditMoveDown;

  /// No description provided for @practiceEditMoveUp.
  ///
  /// In en, this message translates to:
  /// **'Move Up (Ctrl+Shift+T)'**
  String get practiceEditMoveUp;

  /// No description provided for @practiceEditMultiSelectionProperties.
  ///
  /// In en, this message translates to:
  /// **'Multi-Selection Properties'**
  String get practiceEditMultiSelectionProperties;

  /// No description provided for @practiceEditNoLayers.
  ///
  /// In en, this message translates to:
  /// **'No layers, please add a layer'**
  String get practiceEditNoLayers;

  /// No description provided for @practiceEditOverwrite.
  ///
  /// In en, this message translates to:
  /// **'Overwrite'**
  String get practiceEditOverwrite;

  /// No description provided for @practiceEditPageProperties.
  ///
  /// In en, this message translates to:
  /// **'Page Properties'**
  String get practiceEditPageProperties;

  /// No description provided for @practiceEditPaste.
  ///
  /// In en, this message translates to:
  /// **'Paste (Ctrl+Shift+V)'**
  String get practiceEditPaste;

  /// No description provided for @practiceEditPracticeLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load practice: Practice does not exist or has been deleted'**
  String get practiceEditPracticeLoadFailed;

  /// No description provided for @practiceEditPracticeTitle.
  ///
  /// In en, this message translates to:
  /// **'Practice Title'**
  String get practiceEditPracticeTitle;

  /// No description provided for @practiceEditPropertyPanel.
  ///
  /// In en, this message translates to:
  /// **'Properties'**
  String get practiceEditPropertyPanel;

  /// No description provided for @practiceEditSaveAndExit.
  ///
  /// In en, this message translates to:
  /// **'Save & Exit'**
  String get practiceEditSaveAndExit;

  /// No description provided for @practiceEditSaveAndLeave.
  ///
  /// In en, this message translates to:
  /// **'Save & Leave'**
  String get practiceEditSaveAndLeave;

  /// No description provided for @practiceEditSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Save failed'**
  String get practiceEditSaveFailed;

  /// No description provided for @practiceEditSavePractice.
  ///
  /// In en, this message translates to:
  /// **'Save Practice'**
  String get practiceEditSavePractice;

  /// No description provided for @practiceEditSaveSuccess.
  ///
  /// In en, this message translates to:
  /// **'Save successful'**
  String get practiceEditSaveSuccess;

  /// No description provided for @practiceEditSelect.
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get practiceEditSelect;

  /// No description provided for @practiceEditSendToBack.
  ///
  /// In en, this message translates to:
  /// **'Send to Back (Ctrl+B)'**
  String get practiceEditSendToBack;

  /// No description provided for @practiceEditShowGrid.
  ///
  /// In en, this message translates to:
  /// **'Show Grid (Ctrl+G)'**
  String get practiceEditShowGrid;

  /// No description provided for @practiceEditText.
  ///
  /// In en, this message translates to:
  /// **'Text'**
  String get practiceEditText;

  /// No description provided for @practiceEditTextProperties.
  ///
  /// In en, this message translates to:
  /// **'Text Properties'**
  String get practiceEditTextProperties;

  /// No description provided for @practiceEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Practice Edit'**
  String get practiceEditTitle;

  /// No description provided for @practiceEditTitleExists.
  ///
  /// In en, this message translates to:
  /// **'Title Exists'**
  String get practiceEditTitleExists;

  /// No description provided for @practiceEditTitleExistsMessage.
  ///
  /// In en, this message translates to:
  /// **'A practice with this title already exists. Do you want to overwrite it?'**
  String get practiceEditTitleExistsMessage;

  /// No description provided for @practiceEditToolbar.
  ///
  /// In en, this message translates to:
  /// **'Edit Toolbar'**
  String get practiceEditToolbar;

  /// No description provided for @practiceEditTopNavBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get practiceEditTopNavBack;

  /// No description provided for @practiceEditTopNavExitPreview.
  ///
  /// In en, this message translates to:
  /// **'Exit Preview Mode'**
  String get practiceEditTopNavExitPreview;

  /// No description provided for @practiceEditTopNavExport.
  ///
  /// In en, this message translates to:
  /// **'Export'**
  String get practiceEditTopNavExport;

  /// No description provided for @practiceEditTopNavHideThumbnails.
  ///
  /// In en, this message translates to:
  /// **'Hide Page Thumbnails'**
  String get practiceEditTopNavHideThumbnails;

  /// No description provided for @practiceEditTopNavPreviewMode.
  ///
  /// In en, this message translates to:
  /// **'Preview Mode'**
  String get practiceEditTopNavPreviewMode;

  /// No description provided for @practiceEditTopNavRedo.
  ///
  /// In en, this message translates to:
  /// **'Redo'**
  String get practiceEditTopNavRedo;

  /// No description provided for @practiceEditTopNavSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get practiceEditTopNavSave;

  /// No description provided for @practiceEditTopNavSaveAs.
  ///
  /// In en, this message translates to:
  /// **'Save As'**
  String get practiceEditTopNavSaveAs;

  /// No description provided for @practiceEditTopNavShowThumbnails.
  ///
  /// In en, this message translates to:
  /// **'Show Page Thumbnails'**
  String get practiceEditTopNavShowThumbnails;

  /// No description provided for @practiceEditTopNavUndo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get practiceEditTopNavUndo;

  /// No description provided for @practiceEditUngroup.
  ///
  /// In en, this message translates to:
  /// **'Ungroup (Ctrl+U)'**
  String get practiceEditUngroup;

  /// No description provided for @practiceEditUnsavedChanges.
  ///
  /// In en, this message translates to:
  /// **'Unsaved Changes'**
  String get practiceEditUnsavedChanges;

  /// No description provided for @practiceEditUnsavedChangesExitConfirmation.
  ///
  /// In en, this message translates to:
  /// **'You have unsaved changes. Are you sure you want to exit?'**
  String get practiceEditUnsavedChangesExitConfirmation;

  /// No description provided for @practiceEditUnsavedChangesMessage.
  ///
  /// In en, this message translates to:
  /// **'You have unsaved changes. Are you sure you want to leave?'**
  String get practiceEditUnsavedChangesMessage;

  /// No description provided for @practiceEditVisualProperties.
  ///
  /// In en, this message translates to:
  /// **'Visual Properties'**
  String get practiceEditVisualProperties;

  /// No description provided for @practiceListBatchDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get practiceListBatchDone;

  /// No description provided for @practiceListBatchMode.
  ///
  /// In en, this message translates to:
  /// **'Batch Mode'**
  String get practiceListBatchMode;

  /// No description provided for @practiceListDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm Deletion'**
  String get practiceListDeleteConfirm;

  /// No description provided for @practiceListDeleteMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete the selected practice sheets? This action cannot be undone.'**
  String get practiceListDeleteMessage;

  /// No description provided for @practiceListDeleteSelected.
  ///
  /// In en, this message translates to:
  /// **'Delete Selected'**
  String get practiceListDeleteSelected;

  /// No description provided for @practiceListError.
  ///
  /// In en, this message translates to:
  /// **'Error loading practice sheets'**
  String get practiceListError;

  /// No description provided for @practiceListGridView.
  ///
  /// In en, this message translates to:
  /// **'Grid View'**
  String get practiceListGridView;

  /// No description provided for @practiceListListView.
  ///
  /// In en, this message translates to:
  /// **'List View'**
  String get practiceListListView;

  /// No description provided for @practiceListLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading practice sheets...'**
  String get practiceListLoading;

  /// No description provided for @practiceListNewPractice.
  ///
  /// In en, this message translates to:
  /// **'New Practice Sheet'**
  String get practiceListNewPractice;

  /// No description provided for @practiceListNoResults.
  ///
  /// In en, this message translates to:
  /// **'No practice sheets found'**
  String get practiceListNoResults;

  /// No description provided for @practiceListPages.
  ///
  /// In en, this message translates to:
  /// **'pages'**
  String get practiceListPages;

  /// No description provided for @practiceListSearch.
  ///
  /// In en, this message translates to:
  /// **'Search practice sheets...'**
  String get practiceListSearch;

  /// No description provided for @practiceListSortByCreateTime.
  ///
  /// In en, this message translates to:
  /// **'Sort by Creation Time'**
  String get practiceListSortByCreateTime;

  /// No description provided for @practiceListSortByTitle.
  ///
  /// In en, this message translates to:
  /// **'Sort by Title'**
  String get practiceListSortByTitle;

  /// No description provided for @practiceListSortByUpdateTime.
  ///
  /// In en, this message translates to:
  /// **'Sort by Update Time'**
  String get practiceListSortByUpdateTime;

  /// No description provided for @practiceListThumbnailError.
  ///
  /// In en, this message translates to:
  /// **'Thumbnail load failed'**
  String get practiceListThumbnailError;

  /// No description provided for @practiceListTitle.
  ///
  /// In en, this message translates to:
  /// **'Practice Sheets'**
  String get practiceListTitle;

  /// No description provided for @practicePageSettings.
  ///
  /// In en, this message translates to:
  /// **'Page Settings'**
  String get practicePageSettings;

  /// No description provided for @practices.
  ///
  /// In en, this message translates to:
  /// **'Practices'**
  String get practices;

  /// No description provided for @presetSize.
  ///
  /// In en, this message translates to:
  /// **'Preset Size'**
  String get presetSize;

  /// No description provided for @preview.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get preview;

  /// No description provided for @previewText.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get previewText;

  /// No description provided for @print.
  ///
  /// In en, this message translates to:
  /// **'Print'**
  String get print;

  /// No description provided for @rename.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get rename;

  /// No description provided for @rotation.
  ///
  /// In en, this message translates to:
  /// **'Rotation'**
  String get rotation;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @selectCollection.
  ///
  /// In en, this message translates to:
  /// **'Select Collection'**
  String get selectCollection;

  /// No description provided for @selected.
  ///
  /// In en, this message translates to:
  /// **'Selected'**
  String get selected;

  /// No description provided for @sendLayerToBack.
  ///
  /// In en, this message translates to:
  /// **'Send Layer to Back'**
  String get sendLayerToBack;

  /// No description provided for @sendToBack.
  ///
  /// In en, this message translates to:
  /// **'Send to Back'**
  String get sendToBack;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @showElement.
  ///
  /// In en, this message translates to:
  /// **'Show Element'**
  String get showElement;

  /// No description provided for @showGrid.
  ///
  /// In en, this message translates to:
  /// **'Show Grid'**
  String get showGrid;

  /// No description provided for @showHideAllElements.
  ///
  /// In en, this message translates to:
  /// **'Show/Hide All Elements'**
  String get showHideAllElements;

  /// No description provided for @stateAndDisplay.
  ///
  /// In en, this message translates to:
  /// **'State & Display'**
  String get stateAndDisplay;

  /// No description provided for @storageSettings.
  ///
  /// In en, this message translates to:
  /// **'Storage Settings'**
  String get storageSettings;

  /// No description provided for @tagEditorEnterTagHint.
  ///
  /// In en, this message translates to:
  /// **'Type a tag and press Enter'**
  String get tagEditorEnterTagHint;

  /// No description provided for @tagEditorNoTags.
  ///
  /// In en, this message translates to:
  /// **'No tags'**
  String get tagEditorNoTags;

  /// No description provided for @tagEditorSuggestedTags.
  ///
  /// In en, this message translates to:
  /// **'Suggested tags:'**
  String get tagEditorSuggestedTags;

  /// No description provided for @textPropertyPanel.
  ///
  /// In en, this message translates to:
  /// **'Text Properties'**
  String get textPropertyPanel;

  /// No description provided for @textPropertyPanelBgColor.
  ///
  /// In en, this message translates to:
  /// **'Background Color'**
  String get textPropertyPanelBgColor;

  /// No description provided for @textPropertyPanelDimensions.
  ///
  /// In en, this message translates to:
  /// **'Dimensions'**
  String get textPropertyPanelDimensions;

  /// No description provided for @textPropertyPanelFontColor.
  ///
  /// In en, this message translates to:
  /// **'Text Color'**
  String get textPropertyPanelFontColor;

  /// No description provided for @textPropertyPanelFontFamily.
  ///
  /// In en, this message translates to:
  /// **'Font Family'**
  String get textPropertyPanelFontFamily;

  /// No description provided for @textPropertyPanelFontSize.
  ///
  /// In en, this message translates to:
  /// **'Font Size'**
  String get textPropertyPanelFontSize;

  /// No description provided for @textPropertyPanelFontStyle.
  ///
  /// In en, this message translates to:
  /// **'Font Style'**
  String get textPropertyPanelFontStyle;

  /// No description provided for @textPropertyPanelFontWeight.
  ///
  /// In en, this message translates to:
  /// **'Font Weight'**
  String get textPropertyPanelFontWeight;

  /// No description provided for @textPropertyPanelGeometry.
  ///
  /// In en, this message translates to:
  /// **'Geometry Properties'**
  String get textPropertyPanelGeometry;

  /// No description provided for @textPropertyPanelHorizontal.
  ///
  /// In en, this message translates to:
  /// **'Horizontal'**
  String get textPropertyPanelHorizontal;

  /// No description provided for @textPropertyPanelLetterSpacing.
  ///
  /// In en, this message translates to:
  /// **'Letter Spacing'**
  String get textPropertyPanelLetterSpacing;

  /// No description provided for @textPropertyPanelLineHeight.
  ///
  /// In en, this message translates to:
  /// **'Line Height'**
  String get textPropertyPanelLineHeight;

  /// No description provided for @textPropertyPanelLineThrough.
  ///
  /// In en, this message translates to:
  /// **'Line Through'**
  String get textPropertyPanelLineThrough;

  /// No description provided for @textPropertyPanelOpacity.
  ///
  /// In en, this message translates to:
  /// **'Opacity'**
  String get textPropertyPanelOpacity;

  /// No description provided for @textPropertyPanelPadding.
  ///
  /// In en, this message translates to:
  /// **'Padding'**
  String get textPropertyPanelPadding;

  /// No description provided for @textPropertyPanelPosition.
  ///
  /// In en, this message translates to:
  /// **'Position'**
  String get textPropertyPanelPosition;

  /// No description provided for @textPropertyPanelPreview.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get textPropertyPanelPreview;

  /// No description provided for @textPropertyPanelTextAlign.
  ///
  /// In en, this message translates to:
  /// **'Text Align'**
  String get textPropertyPanelTextAlign;

  /// No description provided for @textPropertyPanelTextContent.
  ///
  /// In en, this message translates to:
  /// **'Text Content'**
  String get textPropertyPanelTextContent;

  /// No description provided for @textPropertyPanelTextSettings.
  ///
  /// In en, this message translates to:
  /// **'Text Settings'**
  String get textPropertyPanelTextSettings;

  /// No description provided for @textPropertyPanelUnderline.
  ///
  /// In en, this message translates to:
  /// **'Underline'**
  String get textPropertyPanelUnderline;

  /// No description provided for @textPropertyPanelVertical.
  ///
  /// In en, this message translates to:
  /// **'Vertical'**
  String get textPropertyPanelVertical;

  /// No description provided for @textPropertyPanelVerticalAlign.
  ///
  /// In en, this message translates to:
  /// **'Vertical Align'**
  String get textPropertyPanelVerticalAlign;

  /// No description provided for @textPropertyPanelVisual.
  ///
  /// In en, this message translates to:
  /// **'Visual Settings'**
  String get textPropertyPanelVisual;

  /// No description provided for @textPropertyPanelWritingMode.
  ///
  /// In en, this message translates to:
  /// **'Writing Mode'**
  String get textPropertyPanelWritingMode;

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

  /// No description provided for @themeModeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeModeLight;

  /// No description provided for @themeModeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeModeSystem;

  /// No description provided for @toggleTestText.
  ///
  /// In en, this message translates to:
  /// **'Toggle Test Text'**
  String get toggleTestText;

  /// No description provided for @total.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get total;

  /// No description provided for @ungroup.
  ///
  /// In en, this message translates to:
  /// **'Ungroup'**
  String get ungroup;

  /// No description provided for @unlockElement.
  ///
  /// In en, this message translates to:
  /// **'Unlock Element'**
  String get unlockElement;

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

  /// No description provided for @visible.
  ///
  /// In en, this message translates to:
  /// **'Visible'**
  String get visible;

  /// No description provided for @visualSettings.
  ///
  /// In en, this message translates to:
  /// **'Visual Settings'**
  String get visualSettings;

  /// No description provided for @width.
  ///
  /// In en, this message translates to:
  /// **'Width'**
  String get width;

  /// No description provided for @alignmentOperations.
  ///
  /// In en, this message translates to:
  /// **'Alignment Operations'**
  String get alignmentOperations;

  /// No description provided for @horizontalAlignment.
  ///
  /// In en, this message translates to:
  /// **'Horizontal Alignment'**
  String get horizontalAlignment;

  /// No description provided for @alignLeft.
  ///
  /// In en, this message translates to:
  /// **'Align Left'**
  String get alignLeft;

  /// No description provided for @alignCenter.
  ///
  /// In en, this message translates to:
  /// **'Align Center'**
  String get alignCenter;

  /// No description provided for @alignRight.
  ///
  /// In en, this message translates to:
  /// **'Align Right'**
  String get alignRight;

  /// No description provided for @verticalAlignment.
  ///
  /// In en, this message translates to:
  /// **'Vertical Alignment'**
  String get verticalAlignment;

  /// No description provided for @alignTop.
  ///
  /// In en, this message translates to:
  /// **'Align Top'**
  String get alignTop;

  /// No description provided for @alignMiddle.
  ///
  /// In en, this message translates to:
  /// **'Align Middle'**
  String get alignMiddle;

  /// No description provided for @alignBottom.
  ///
  /// In en, this message translates to:
  /// **'Align Bottom'**
  String get alignBottom;

  /// No description provided for @distributionOperations.
  ///
  /// In en, this message translates to:
  /// **'Distribution Operations'**
  String get distributionOperations;

  /// No description provided for @elementDistribution.
  ///
  /// In en, this message translates to:
  /// **'Element Distribution'**
  String get elementDistribution;

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

  /// No description provided for @alignmentRequiresMultipleElements.
  ///
  /// In en, this message translates to:
  /// **'Alignment requires at least 2 elements'**
  String get alignmentRequiresMultipleElements;

  /// No description provided for @distributionRequiresThreeElements.
  ///
  /// In en, this message translates to:
  /// **'Distribution requires at least 3 elements'**
  String get distributionRequiresThreeElements;

  /// No description provided for @distribution.
  ///
  /// In en, this message translates to:
  /// **'Distribution'**
  String get distribution;

  /// No description provided for @center.
  ///
  /// In en, this message translates to:
  /// **'Center'**
  String get center;

  /// No description provided for @moveSelectedElementsToLayer.
  ///
  /// In en, this message translates to:
  /// **'Move Selected Elements to Layer'**
  String get moveSelectedElementsToLayer;

  /// No description provided for @selectTargetLayer.
  ///
  /// In en, this message translates to:
  /// **'Select Target Layer'**
  String get selectTargetLayer;

  /// No description provided for @layerInfo.
  ///
  /// In en, this message translates to:
  /// **'Layer Information'**
  String get layerInfo;

  /// No description provided for @layerName.
  ///
  /// In en, this message translates to:
  /// **'Layer Name'**
  String get layerName;

  /// No description provided for @visibility.
  ///
  /// In en, this message translates to:
  /// **'Visibility'**
  String get visibility;

  /// No description provided for @lockStatus.
  ///
  /// In en, this message translates to:
  /// **'Lock Status'**
  String get lockStatus;

  /// No description provided for @unlocked.
  ///
  /// In en, this message translates to:
  /// **'Unlocked'**
  String get unlocked;

  /// No description provided for @elementType.
  ///
  /// In en, this message translates to:
  /// **'Element Type'**
  String get elementType;

  /// No description provided for @elementId.
  ///
  /// In en, this message translates to:
  /// **'Element ID'**
  String get elementId;

  /// No description provided for @text.
  ///
  /// In en, this message translates to:
  /// **'Text'**
  String get text;

  /// No description provided for @image.
  ///
  /// In en, this message translates to:
  /// **'Image'**
  String get image;

  /// No description provided for @collection.
  ///
  /// In en, this message translates to:
  /// **'Collection'**
  String get collection;

  /// No description provided for @workBrowseAddFavorite.
  ///
  /// In en, this message translates to:
  /// **'Add to Favorites'**
  String get workBrowseAddFavorite;

  /// No description provided for @workBrowseBatchDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get workBrowseBatchDone;

  /// No description provided for @workBrowseBatchMode.
  ///
  /// In en, this message translates to:
  /// **'Batch Mode'**
  String get workBrowseBatchMode;

  /// No description provided for @workBrowseCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get workBrowseCancel;

  /// No description provided for @workBrowseDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get workBrowseDelete;

  /// No description provided for @workBrowseDeleteConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm Deletion'**
  String get workBrowseDeleteConfirmTitle;

  /// No description provided for @workBrowseGridView.
  ///
  /// In en, this message translates to:
  /// **'Grid View'**
  String get workBrowseGridView;

  /// No description provided for @workBrowseImport.
  ///
  /// In en, this message translates to:
  /// **'Import Work'**
  String get workBrowseImport;

  /// No description provided for @workBrowseListView.
  ///
  /// In en, this message translates to:
  /// **'List View'**
  String get workBrowseListView;

  /// No description provided for @workBrowseLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading works...'**
  String get workBrowseLoading;

  /// No description provided for @workBrowseNoWorks.
  ///
  /// In en, this message translates to:
  /// **'No works found'**
  String get workBrowseNoWorks;

  /// No description provided for @workBrowseNoWorksHint.
  ///
  /// In en, this message translates to:
  /// **'Try importing new works or changing filters'**
  String get workBrowseNoWorksHint;

  /// No description provided for @workBrowseReload.
  ///
  /// In en, this message translates to:
  /// **'Reload'**
  String get workBrowseReload;

  /// No description provided for @workBrowseRemoveFavorite.
  ///
  /// In en, this message translates to:
  /// **'Remove from Favorites'**
  String get workBrowseRemoveFavorite;

  /// No description provided for @workBrowseSearch.
  ///
  /// In en, this message translates to:
  /// **'Search works...'**
  String get workBrowseSearch;

  /// No description provided for @workBrowseTitle.
  ///
  /// In en, this message translates to:
  /// **'Works'**
  String get workBrowseTitle;

  /// No description provided for @workDetailBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get workDetailBack;

  /// No description provided for @workDetailBasicInfo.
  ///
  /// In en, this message translates to:
  /// **'Basic Information'**
  String get workDetailBasicInfo;

  /// No description provided for @workDetailCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get workDetailCancel;

  /// No description provided for @workDetailCharacters.
  ///
  /// In en, this message translates to:
  /// **'Characters'**
  String get workDetailCharacters;

  /// No description provided for @workDetailCreateTime.
  ///
  /// In en, this message translates to:
  /// **'Creation Time'**
  String get workDetailCreateTime;

  /// No description provided for @workDetailEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get workDetailEdit;

  /// No description provided for @workDetailExtract.
  ///
  /// In en, this message translates to:
  /// **'Extract Characters'**
  String get workDetailExtract;

  /// No description provided for @workDetailExtractionError.
  ///
  /// In en, this message translates to:
  /// **'Unable to open character extraction'**
  String get workDetailExtractionError;

  /// No description provided for @workDetailImageCount.
  ///
  /// In en, this message translates to:
  /// **'Image Count'**
  String get workDetailImageCount;

  /// No description provided for @workDetailImageLoadError.
  ///
  /// In en, this message translates to:
  /// **'The selected image failed to load, try reimporting the image'**
  String get workDetailImageLoadError;

  /// No description provided for @workDetailLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading work details...'**
  String get workDetailLoading;

  /// No description provided for @workDetailNoCharacters.
  ///
  /// In en, this message translates to:
  /// **'No characters yet'**
  String get workDetailNoCharacters;

  /// No description provided for @workDetailNoImages.
  ///
  /// In en, this message translates to:
  /// **'No images to display'**
  String get workDetailNoImages;

  /// No description provided for @workDetailNoImagesForExtraction.
  ///
  /// In en, this message translates to:
  /// **'Cannot extract characters: Work has no images'**
  String get workDetailNoImagesForExtraction;

  /// No description provided for @workDetailNoWork.
  ///
  /// In en, this message translates to:
  /// **'Work doesn\'t exist or has been deleted'**
  String get workDetailNoWork;

  /// No description provided for @workDetailOtherInfo.
  ///
  /// In en, this message translates to:
  /// **'Other Information'**
  String get workDetailOtherInfo;

  /// No description provided for @workDetailSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get workDetailSave;

  /// No description provided for @workDetailSaveFailure.
  ///
  /// In en, this message translates to:
  /// **'Save failed'**
  String get workDetailSaveFailure;

  /// No description provided for @workDetailSaveSuccess.
  ///
  /// In en, this message translates to:
  /// **'Save successful'**
  String get workDetailSaveSuccess;

  /// No description provided for @workDetailTags.
  ///
  /// In en, this message translates to:
  /// **'Tags'**
  String get workDetailTags;

  /// No description provided for @workDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Work Details'**
  String get workDetailTitle;

  /// No description provided for @workDetailUnsavedChanges.
  ///
  /// In en, this message translates to:
  /// **'You have unsaved changes. Are you sure you want to discard them?'**
  String get workDetailUnsavedChanges;

  /// No description provided for @workDetailUpdateTime.
  ///
  /// In en, this message translates to:
  /// **'Update Time'**
  String get workDetailUpdateTime;

  /// No description provided for @workDetailViewMore.
  ///
  /// In en, this message translates to:
  /// **'View More'**
  String get workDetailViewMore;

  /// No description provided for @workFormAuthor.
  ///
  /// In en, this message translates to:
  /// **'Author'**
  String get workFormAuthor;

  /// No description provided for @workFormAuthorHelp.
  ///
  /// In en, this message translates to:
  /// **'Optional, the creator of the work'**
  String get workFormAuthorHelp;

  /// No description provided for @workFormAuthorHint.
  ///
  /// In en, this message translates to:
  /// **'Enter author name'**
  String get workFormAuthorHint;

  /// No description provided for @workFormAuthorMaxLength.
  ///
  /// In en, this message translates to:
  /// **'Author name cannot exceed 50 characters'**
  String get workFormAuthorMaxLength;

  /// No description provided for @workFormAuthorTooltip.
  ///
  /// In en, this message translates to:
  /// **'Press Ctrl+A to quickly jump to the author field'**
  String get workFormAuthorTooltip;

  /// No description provided for @workFormCreationDate.
  ///
  /// In en, this message translates to:
  /// **'Creation Date'**
  String get workFormCreationDate;

  /// No description provided for @workFormDateHelp.
  ///
  /// In en, this message translates to:
  /// **'The date when the work was completed'**
  String get workFormDateHelp;

  /// No description provided for @workFormDateTooltip.
  ///
  /// In en, this message translates to:
  /// **'Press Tab to navigate to the next field'**
  String get workFormDateTooltip;

  /// No description provided for @workFormHelp.
  ///
  /// In en, this message translates to:
  /// **'Help'**
  String get workFormHelp;

  /// No description provided for @workFormNextField.
  ///
  /// In en, this message translates to:
  /// **'Next Field'**
  String get workFormNextField;

  /// No description provided for @workFormPreviousField.
  ///
  /// In en, this message translates to:
  /// **'Previous Field'**
  String get workFormPreviousField;

  /// No description provided for @workFormRemark.
  ///
  /// In en, this message translates to:
  /// **'Remark'**
  String get workFormRemark;

  /// No description provided for @workFormRemarkHelp.
  ///
  /// In en, this message translates to:
  /// **'Optional, additional information about the work'**
  String get workFormRemarkHelp;

  /// No description provided for @workFormRemarkHint.
  ///
  /// In en, this message translates to:
  /// **'Optional'**
  String get workFormRemarkHint;

  /// No description provided for @workFormRemarkMaxLength.
  ///
  /// In en, this message translates to:
  /// **'Remark cannot exceed 500 characters'**
  String get workFormRemarkMaxLength;

  /// No description provided for @workFormRemarkTooltip.
  ///
  /// In en, this message translates to:
  /// **'Press Ctrl+R to quickly jump to the remark field'**
  String get workFormRemarkTooltip;

  /// No description provided for @workFormRequiredField.
  ///
  /// In en, this message translates to:
  /// **'Required field'**
  String get workFormRequiredField;

  /// No description provided for @workFormSelectDate.
  ///
  /// In en, this message translates to:
  /// **'Select Date'**
  String get workFormSelectDate;

  /// No description provided for @workFormShortcuts.
  ///
  /// In en, this message translates to:
  /// **'Keyboard Shortcuts'**
  String get workFormShortcuts;

  /// No description provided for @workFormStyle.
  ///
  /// In en, this message translates to:
  /// **'Style'**
  String get workFormStyle;

  /// No description provided for @workFormStyleHelp.
  ///
  /// In en, this message translates to:
  /// **'The main style type of the work'**
  String get workFormStyleHelp;

  /// No description provided for @workFormStyleTooltip.
  ///
  /// In en, this message translates to:
  /// **'Press Tab to navigate to the next field'**
  String get workFormStyleTooltip;

  /// No description provided for @workFormTitle.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get workFormTitle;

  /// No description provided for @workFormTitleHelp.
  ///
  /// In en, this message translates to:
  /// **'The main title of the work, displayed in the work list'**
  String get workFormTitleHelp;

  /// No description provided for @workFormTitleHint.
  ///
  /// In en, this message translates to:
  /// **'Enter title'**
  String get workFormTitleHint;

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
  /// **'Press Ctrl+T to quickly jump to the title field'**
  String get workFormTitleTooltip;

  /// No description provided for @workFormTool.
  ///
  /// In en, this message translates to:
  /// **'Tool'**
  String get workFormTool;

  /// No description provided for @workFormToolHelp.
  ///
  /// In en, this message translates to:
  /// **'The main tool used to create this work'**
  String get workFormToolHelp;

  /// No description provided for @workFormToolTooltip.
  ///
  /// In en, this message translates to:
  /// **'Press Tab to navigate to the next field'**
  String get workFormToolTooltip;

  /// No description provided for @workImportDialogAddImages.
  ///
  /// In en, this message translates to:
  /// **'Add Images'**
  String get workImportDialogAddImages;

  /// No description provided for @workImportDialogCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get workImportDialogCancel;

  /// No description provided for @workImportDialogDeleteImage.
  ///
  /// In en, this message translates to:
  /// **'Delete Image'**
  String get workImportDialogDeleteImage;

  /// No description provided for @workImportDialogDeleteImageConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this image?'**
  String get workImportDialogDeleteImageConfirm;

  /// No description provided for @workImportDialogImport.
  ///
  /// In en, this message translates to:
  /// **'Import'**
  String get workImportDialogImport;

  /// No description provided for @workImportDialogNoImages.
  ///
  /// In en, this message translates to:
  /// **'No images selected'**
  String get workImportDialogNoImages;

  /// No description provided for @workImportDialogNoImagesHint.
  ///
  /// In en, this message translates to:
  /// **'Click to add images'**
  String get workImportDialogNoImagesHint;

  /// No description provided for @workImportDialogProcessing.
  ///
  /// In en, this message translates to:
  /// **'Processing...'**
  String get workImportDialogProcessing;

  /// No description provided for @workImportDialogSuccess.
  ///
  /// In en, this message translates to:
  /// **'Import successful'**
  String get workImportDialogSuccess;

  /// No description provided for @workImportDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Import Work'**
  String get workImportDialogTitle;

  /// No description provided for @works.
  ///
  /// In en, this message translates to:
  /// **'Works'**
  String get works;

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

  /// No description provided for @workStyleOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get workStyleOther;

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

  /// No description provided for @characterCollectionDeleteBatchConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm deletion of {count} saved regions?'**
  String characterCollectionDeleteBatchConfirm(Object count);

  /// No description provided for @characterCollectionDeleteBatchMessage.
  ///
  /// In en, this message translates to:
  /// **'You are about to delete {count} saved regions. This action cannot be undone.'**
  String characterCollectionDeleteBatchMessage(Object count);

  /// No description provided for @characterCollectionError.
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String characterCollectionError(Object error);

  /// No description provided for @characterCollectionFindSwitchFailed.
  ///
  /// In en, this message translates to:
  /// **'Find and switch page failed: {error}'**
  String characterCollectionFindSwitchFailed(Object error);

  /// No description provided for @characterEditCharacterUpdated.
  ///
  /// In en, this message translates to:
  /// **'\"{character}\" updated'**
  String characterEditCharacterUpdated(Object character);

  /// No description provided for @characterEditSaveConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'Confirm saving \"{character}\"?'**
  String characterEditSaveConfirmMessage(Object character);

  /// No description provided for @characterManagementError.
  ///
  /// In en, this message translates to:
  /// **'Error: {message}'**
  String characterManagementError(Object message);

  /// No description provided for @characterManagementItemsPerPage.
  ///
  /// In en, this message translates to:
  /// **'{count} items per page'**
  String characterManagementItemsPerPage(Object count);

  /// No description provided for @imagePropertyPanelCroppingApplied.
  ///
  /// In en, this message translates to:
  /// **' (Cropping: Left {left}px, Top {top}px, Right {right}px, Bottom {bottom}px)'**
  String imagePropertyPanelCroppingApplied(Object bottom, Object left, Object right, Object top);

  /// No description provided for @imagePropertyPanelFileNotExist.
  ///
  /// In en, this message translates to:
  /// **'File does not exist: {path}'**
  String imagePropertyPanelFileNotExist(Object path);

  /// No description provided for @imagePropertyPanelLoadError.
  ///
  /// In en, this message translates to:
  /// **'Failed to load image: {error}...'**
  String imagePropertyPanelLoadError(Object error);

  /// No description provided for @imagePropertyPanelProcessingPathError.
  ///
  /// In en, this message translates to:
  /// **'Processing path error: {error}'**
  String imagePropertyPanelProcessingPathError(Object error);

  /// No description provided for @imagePropertyPanelTransformError.
  ///
  /// In en, this message translates to:
  /// **'Failed to apply transform: {error}'**
  String imagePropertyPanelTransformError(Object error);

  /// No description provided for @initializationFailed.
  ///
  /// In en, this message translates to:
  /// **'Initialization failed: {error}'**
  String initializationFailed(Object error);

  /// No description provided for @practiceEditElementSelectionInfo.
  ///
  /// In en, this message translates to:
  /// **'{count} elements selected'**
  String practiceEditElementSelectionInfo(Object count);

  /// No description provided for @practiceEditLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load practice: {error}'**
  String practiceEditLoadFailed(Object error);

  /// No description provided for @practiceEditPracticeLoaded.
  ///
  /// In en, this message translates to:
  /// **'Practice \"{title}\" loaded successfully'**
  String practiceEditPracticeLoaded(Object title);

  /// No description provided for @practiceEditTitleUpdated.
  ///
  /// In en, this message translates to:
  /// **'Title updated to \"{title}\"'**
  String practiceEditTitleUpdated(Object title);

  /// No description provided for @practiceListItemsPerPage.
  ///
  /// In en, this message translates to:
  /// **'{count} per page'**
  String practiceListItemsPerPage(Object count);

  /// No description provided for @practiceListTotalItems.
  ///
  /// In en, this message translates to:
  /// **'{count} practice sheets'**
  String practiceListTotalItems(Object count);

  /// No description provided for @workBrowseDeleteConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete {count} selected works? This action cannot be undone.'**
  String workBrowseDeleteConfirmMessage(Object count);

  /// No description provided for @workBrowseDeleteSelected.
  ///
  /// In en, this message translates to:
  /// **'Delete {count}'**
  String workBrowseDeleteSelected(Object count);

  /// No description provided for @workBrowseError.
  ///
  /// In en, this message translates to:
  /// **'Error: {message}'**
  String workBrowseError(Object message);

  /// No description provided for @workBrowseSelectedCount.
  ///
  /// In en, this message translates to:
  /// **'{count} selected'**
  String workBrowseSelectedCount(Object count);

  /// No description provided for @workImportDialogError.
  ///
  /// In en, this message translates to:
  /// **'Import failed: {error}'**
  String workImportDialogError(Object error);
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en': return AppLocalizationsEn();
    case 'zh': return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
