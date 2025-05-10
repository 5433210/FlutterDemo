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
  /// **'Char As Gem'**
  String get appName;

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Char As Gem'**
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
  /// **'Filter & Sort'**
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

  /// No description provided for @days.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 day} other{{count} days}}'**
  String days(num count);

  /// No description provided for @hours.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 hour} other{{count} hours}}'**
  String hours(num count);

  /// No description provided for @backupSettings.
  ///
  /// In en, this message translates to:
  /// **'Backup & Restore'**
  String get backupSettings;

  /// No description provided for @autoBackup.
  ///
  /// In en, this message translates to:
  /// **'Auto Backup'**
  String get autoBackup;

  /// No description provided for @autoBackupDescription.
  ///
  /// In en, this message translates to:
  /// **'Automatically backup your data periodically'**
  String get autoBackupDescription;

  /// No description provided for @autoBackupInterval.
  ///
  /// In en, this message translates to:
  /// **'Auto Backup Interval'**
  String get autoBackupInterval;

  /// No description provided for @autoBackupIntervalDescription.
  ///
  /// In en, this message translates to:
  /// **'How often to create automatic backups'**
  String get autoBackupIntervalDescription;

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

  /// No description provided for @lastBackupTime.
  ///
  /// In en, this message translates to:
  /// **'Last Backup Time'**
  String get lastBackupTime;

  /// No description provided for @createBackup.
  ///
  /// In en, this message translates to:
  /// **'Create Backup'**
  String get createBackup;

  /// No description provided for @restoreBackup.
  ///
  /// In en, this message translates to:
  /// **'Restore Backup'**
  String get restoreBackup;

  /// No description provided for @backupList.
  ///
  /// In en, this message translates to:
  /// **'Backup List'**
  String get backupList;

  /// No description provided for @noBackups.
  ///
  /// In en, this message translates to:
  /// **'No backups available'**
  String get noBackups;

  /// No description provided for @loadingError.
  ///
  /// In en, this message translates to:
  /// **'Loading Error'**
  String get loadingError;

  /// No description provided for @restore.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get restore;

  /// No description provided for @deleteBackup.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get deleteBackup;

  /// No description provided for @restoreSuccess.
  ///
  /// In en, this message translates to:
  /// **'Restore completed successfully'**
  String get restoreSuccess;

  /// No description provided for @restoreFailure.
  ///
  /// In en, this message translates to:
  /// **'Failed to restore from backup'**
  String get restoreFailure;

  /// No description provided for @deleteSuccess.
  ///
  /// In en, this message translates to:
  /// **'Backup deleted successfully'**
  String get deleteSuccess;

  /// No description provided for @deleteFailure.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete backup'**
  String get deleteFailure;

  /// No description provided for @createBackupDescription.
  ///
  /// In en, this message translates to:
  /// **'Create a new backup of your data'**
  String get createBackupDescription;

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

  /// No description provided for @create.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get create;

  /// No description provided for @selectBackup.
  ///
  /// In en, this message translates to:
  /// **'Select Backup'**
  String get selectBackup;

  /// No description provided for @restoreConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Restore Confirmation'**
  String get restoreConfirmTitle;

  /// No description provided for @restoreConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to restore from this backup? This will replace all your current data.'**
  String get restoreConfirmMessage;

  /// No description provided for @deleteBackupConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Backup'**
  String get deleteBackupConfirmTitle;

  /// No description provided for @deleteBackupConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this backup? This action cannot be undone.'**
  String get deleteBackupConfirmMessage;

  /// No description provided for @creatingBackup.
  ///
  /// In en, this message translates to:
  /// **'Creating backup...'**
  String get creatingBackup;

  /// No description provided for @restoringBackup.
  ///
  /// In en, this message translates to:
  /// **'Restoring from backup...'**
  String get restoringBackup;

  /// No description provided for @backupSuccess.
  ///
  /// In en, this message translates to:
  /// **'Backup created successfully'**
  String get backupSuccess;

  /// No description provided for @backupFailure.
  ///
  /// In en, this message translates to:
  /// **'Failed to create backup'**
  String get backupFailure;

  /// No description provided for @exportBackup.
  ///
  /// In en, this message translates to:
  /// **'Export Backup'**
  String get exportBackup;

  /// No description provided for @importBackup.
  ///
  /// In en, this message translates to:
  /// **'Import Backup'**
  String get importBackup;

  /// No description provided for @exportBackupDescription.
  ///
  /// In en, this message translates to:
  /// **'Export a backup to an external location'**
  String get exportBackupDescription;

  /// No description provided for @importBackupDescription.
  ///
  /// In en, this message translates to:
  /// **'Import a backup from an external location'**
  String get importBackupDescription;

  /// No description provided for @selectExportLocation.
  ///
  /// In en, this message translates to:
  /// **'Select export location'**
  String get selectExportLocation;

  /// No description provided for @selectImportFile.
  ///
  /// In en, this message translates to:
  /// **'Select Backup File'**
  String get selectImportFile;

  /// No description provided for @exportSuccess.
  ///
  /// In en, this message translates to:
  /// **'Backup exported successfully'**
  String get exportSuccess;

  /// No description provided for @exportFailure.
  ///
  /// In en, this message translates to:
  /// **'Failed to export backup'**
  String get exportFailure;

  /// No description provided for @importSuccess.
  ///
  /// In en, this message translates to:
  /// **'Backup imported successfully'**
  String get importSuccess;

  /// No description provided for @importFailure.
  ///
  /// In en, this message translates to:
  /// **'Failed to import backup'**
  String get importFailure;

  /// No description provided for @invalidBackupFile.
  ///
  /// In en, this message translates to:
  /// **'Invalid backup file'**
  String get invalidBackupFile;

  /// No description provided for @exportingBackup.
  ///
  /// In en, this message translates to:
  /// **'Exporting backup...'**
  String get exportingBackup;

  /// No description provided for @importingBackup.
  ///
  /// In en, this message translates to:
  /// **'Importing backup...'**
  String get importingBackup;

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

  /// No description provided for @filterApply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get filterApply;

  /// No description provided for @filterClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get filterClear;

  /// No description provided for @filterCollapse.
  ///
  /// In en, this message translates to:
  /// **'Collapse Filter Panel'**
  String get filterCollapse;

  /// No description provided for @filterExpand.
  ///
  /// In en, this message translates to:
  /// **'Expand Filter Panel'**
  String get filterExpand;

  /// No description provided for @filterHeader.
  ///
  /// In en, this message translates to:
  /// **'Filter & Sort'**
  String get filterHeader;

  /// No description provided for @filterPanel.
  ///
  /// In en, this message translates to:
  /// **'Filter Panel'**
  String get filterPanel;

  /// No description provided for @filterReset.
  ///
  /// In en, this message translates to:
  /// **'Reset Filters'**
  String get filterReset;

  /// No description provided for @filterSection.
  ///
  /// In en, this message translates to:
  /// **'Filter Options'**
  String get filterSection;

  /// No description provided for @filterSearchPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Search...'**
  String get filterSearchPlaceholder;

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

  /// No description provided for @filterSortDirection.
  ///
  /// In en, this message translates to:
  /// **'Sort Direction'**
  String get filterSortDirection;

  /// No description provided for @filterSortField.
  ///
  /// In en, this message translates to:
  /// **'Sort By'**
  String get filterSortField;

  /// No description provided for @filterToggle.
  ///
  /// In en, this message translates to:
  /// **'Toggle Filters'**
  String get filterToggle;

  /// No description provided for @filterTagsSection.
  ///
  /// In en, this message translates to:
  /// **'Tags'**
  String get filterTagsSection;

  /// No description provided for @filterTagsSelected.
  ///
  /// In en, this message translates to:
  /// **'Selected Tags:'**
  String get filterTagsSelected;

  /// No description provided for @filterTagsAdd.
  ///
  /// In en, this message translates to:
  /// **'Add Tag'**
  String get filterTagsAdd;

  /// No description provided for @filterTagsAddHint.
  ///
  /// In en, this message translates to:
  /// **'Enter tag name and press Enter'**
  String get filterTagsAddHint;

  /// No description provided for @filterTagsNone.
  ///
  /// In en, this message translates to:
  /// **'No tags selected'**
  String get filterTagsNone;

  /// No description provided for @filterTagsSuggested.
  ///
  /// In en, this message translates to:
  /// **'Suggested tags:'**
  String get filterTagsSuggested;

  /// No description provided for @filterPresetSection.
  ///
  /// In en, this message translates to:
  /// **'Presets'**
  String get filterPresetSection;

  /// No description provided for @filterCustomRange.
  ///
  /// In en, this message translates to:
  /// **'Custom Range'**
  String get filterCustomRange;

  /// No description provided for @filterDateRange.
  ///
  /// In en, this message translates to:
  /// **'Date Range'**
  String get filterDateRange;

  /// No description provided for @filterStartDate.
  ///
  /// In en, this message translates to:
  /// **'Start Date'**
  String get filterStartDate;

  /// No description provided for @filterEndDate.
  ///
  /// In en, this message translates to:
  /// **'End Date'**
  String get filterEndDate;

  /// No description provided for @filterSelectDate.
  ///
  /// In en, this message translates to:
  /// **'Select Date'**
  String get filterSelectDate;

  /// No description provided for @filterFavoritesOnly.
  ///
  /// In en, this message translates to:
  /// **'Show favorites only'**
  String get filterFavoritesOnly;

  /// No description provided for @filterStyleSection.
  ///
  /// In en, this message translates to:
  /// **'Calligraphy Style'**
  String get filterStyleSection;

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

  /// No description provided for @filterStyleOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get filterStyleOther;

  /// No description provided for @filterToolSection.
  ///
  /// In en, this message translates to:
  /// **'Writing Tool'**
  String get filterToolSection;

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

  /// No description provided for @filterBatchSelection.
  ///
  /// In en, this message translates to:
  /// **'Selection'**
  String get filterBatchSelection;

  /// No description provided for @filterSelectAll.
  ///
  /// In en, this message translates to:
  /// **'Select All'**
  String get filterSelectAll;

  /// No description provided for @filterDeselectAll.
  ///
  /// In en, this message translates to:
  /// **'Deselect All'**
  String get filterDeselectAll;

  /// No description provided for @filterBatchActions.
  ///
  /// In en, this message translates to:
  /// **'Batch Actions'**
  String get filterBatchActions;

  /// No description provided for @filterItemsSelected.
  ///
  /// In en, this message translates to:
  /// **'{count} selected'**
  String filterItemsSelected(Object count);

  /// No description provided for @filterItemsPerPage.
  ///
  /// In en, this message translates to:
  /// **'{count} per page'**
  String filterItemsPerPage(Object count);

  /// No description provided for @filterTotalItems.
  ///
  /// In en, this message translates to:
  /// **'Total: {count} items'**
  String filterTotalItems(Object count);

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

  /// No description provided for @filterSortFieldFileName.
  ///
  /// In en, this message translates to:
  /// **'File Name'**
  String get filterSortFieldFileName;

  /// No description provided for @filterSortFieldFileUpdatedAt.
  ///
  /// In en, this message translates to:
  /// **'File Update Time'**
  String get filterSortFieldFileUpdatedAt;

  /// No description provided for @filterSortFieldFileSize.
  ///
  /// In en, this message translates to:
  /// **'File Size'**
  String get filterSortFieldFileSize;

  /// No description provided for @filterSortSection.
  ///
  /// In en, this message translates to:
  /// **'Sort'**
  String get filterSortSection;

  /// No description provided for @filterTitle.
  ///
  /// In en, this message translates to:
  /// **'Filter & Sort'**
  String get filterTitle;

  /// No description provided for @filterMin.
  ///
  /// In en, this message translates to:
  /// **'Min'**
  String get filterMin;

  /// No description provided for @filterMax.
  ///
  /// In en, this message translates to:
  /// **'Max'**
  String get filterMax;

  /// No description provided for @filterSelectDateRange.
  ///
  /// In en, this message translates to:
  /// **'Select date range'**
  String get filterSelectDateRange;

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

  /// No description provided for @cacheSettings.
  ///
  /// In en, this message translates to:
  /// **'Cache Settings'**
  String get cacheSettings;

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
  /// **'Disk Cache Lifetime'**
  String get diskCacheTtl;

  /// No description provided for @diskCacheTtlDescription.
  ///
  /// In en, this message translates to:
  /// **'How long to keep cached files on disk'**
  String get diskCacheTtlDescription;

  /// No description provided for @autoCleanup.
  ///
  /// In en, this message translates to:
  /// **'Auto Cleanup'**
  String get autoCleanup;

  /// No description provided for @autoCleanupDescription.
  ///
  /// In en, this message translates to:
  /// **'Automatically clean up old cache files'**
  String get autoCleanupDescription;

  /// No description provided for @autoCleanupInterval.
  ///
  /// In en, this message translates to:
  /// **'Auto Cleanup Interval'**
  String get autoCleanupInterval;

  /// No description provided for @autoCleanupIntervalDescription.
  ///
  /// In en, this message translates to:
  /// **'How often to run automatic cleanup'**
  String get autoCleanupIntervalDescription;

  /// No description provided for @clearCache.
  ///
  /// In en, this message translates to:
  /// **'Clear Cache'**
  String get clearCache;

  /// No description provided for @resetToDefaults.
  ///
  /// In en, this message translates to:
  /// **'Reset to Defaults'**
  String get resetToDefaults;

  /// No description provided for @clearCacheConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Clear Cache'**
  String get clearCacheConfirmTitle;

  /// No description provided for @clearCacheConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to clear all cached data? This will free up disk space but may slow down the application temporarily.'**
  String get clearCacheConfirmMessage;

  /// No description provided for @cacheClearedMessage.
  ///
  /// In en, this message translates to:
  /// **'Cache cleared successfully'**
  String get cacheClearedMessage;

  /// No description provided for @settingsResetMessage.
  ///
  /// In en, this message translates to:
  /// **'Settings reset to defaults'**
  String get settingsResetMessage;

  /// No description provided for @resetSettingsConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset Settings'**
  String get resetSettingsConfirmTitle;

  /// No description provided for @resetSettingsConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to reset all cache settings to default values?'**
  String get resetSettingsConfirmMessage;

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

  /// No description provided for @themeModeDescription.
  ///
  /// In en, this message translates to:
  /// **'Dark Theme'**
  String get themeModeDescription;

  /// No description provided for @themeModeSystemDescription.
  ///
  /// In en, this message translates to:
  /// **'Automatically switch between light/dark modes based on system settings'**
  String get themeModeSystemDescription;

  /// No description provided for @toggleTestText.
  ///
  /// In en, this message translates to:
  /// **'Toggle Test Text'**
  String get toggleTestText;

  /// No description provided for @characterDetailFormatName.
  ///
  /// In en, this message translates to:
  /// **'Format Name'**
  String get characterDetailFormatName;

  /// No description provided for @characterDetailFormatType.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get characterDetailFormatType;

  /// No description provided for @characterDetailFormatExtension.
  ///
  /// In en, this message translates to:
  /// **'File Format'**
  String get characterDetailFormatExtension;

  /// No description provided for @characterDetailFormatDescription.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get characterDetailFormatDescription;

  /// No description provided for @characterDetailFormatOriginal.
  ///
  /// In en, this message translates to:
  /// **'Original'**
  String get characterDetailFormatOriginal;

  /// No description provided for @characterDetailFormatBinary.
  ///
  /// In en, this message translates to:
  /// **'Binary'**
  String get characterDetailFormatBinary;

  /// No description provided for @characterDetailFormatThumbnail.
  ///
  /// In en, this message translates to:
  /// **'Thumbnail'**
  String get characterDetailFormatThumbnail;

  /// No description provided for @characterDetailFormatSquareBinary.
  ///
  /// In en, this message translates to:
  /// **'Square Binary'**
  String get characterDetailFormatSquareBinary;

  /// No description provided for @characterDetailFormatSquareTransparent.
  ///
  /// In en, this message translates to:
  /// **'Square Transparent'**
  String get characterDetailFormatSquareTransparent;

  /// No description provided for @characterDetailFormatTransparent.
  ///
  /// In en, this message translates to:
  /// **'Transparent'**
  String get characterDetailFormatTransparent;

  /// No description provided for @characterDetailFormatOutline.
  ///
  /// In en, this message translates to:
  /// **'Outline'**
  String get characterDetailFormatOutline;

  /// No description provided for @characterDetailFormatSquareOutline.
  ///
  /// In en, this message translates to:
  /// **'Square Outline'**
  String get characterDetailFormatSquareOutline;

  /// No description provided for @characterDetailFormatOriginalDesc.
  ///
  /// In en, this message translates to:
  /// **'Unprocessed original image'**
  String get characterDetailFormatOriginalDesc;

  /// No description provided for @characterDetailFormatBinaryDesc.
  ///
  /// In en, this message translates to:
  /// **'Black and white binary image'**
  String get characterDetailFormatBinaryDesc;

  /// No description provided for @characterDetailFormatThumbnailDesc.
  ///
  /// In en, this message translates to:
  /// **'Thumbnail image'**
  String get characterDetailFormatThumbnailDesc;

  /// No description provided for @characterDetailFormatSquareBinaryDesc.
  ///
  /// In en, this message translates to:
  /// **'Binary image normalized to square'**
  String get characterDetailFormatSquareBinaryDesc;

  /// No description provided for @characterDetailFormatSquareTransparentDesc.
  ///
  /// In en, this message translates to:
  /// **'Transparent PNG image normalized to square'**
  String get characterDetailFormatSquareTransparentDesc;

  /// No description provided for @characterDetailFormatTransparentDesc.
  ///
  /// In en, this message translates to:
  /// **'Transparent PNG image with background removed'**
  String get characterDetailFormatTransparentDesc;

  /// No description provided for @characterDetailFormatOutlineDesc.
  ///
  /// In en, this message translates to:
  /// **'Shows only the outline'**
  String get characterDetailFormatOutlineDesc;

  /// No description provided for @characterDetailFormatSquareOutlineDesc.
  ///
  /// In en, this message translates to:
  /// **'Outline image normalized to square'**
  String get characterDetailFormatSquareOutlineDesc;

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

  /// No description provided for @fileName.
  ///
  /// In en, this message translates to:
  /// **'File Name'**
  String get fileName;

  /// No description provided for @enterFileName.
  ///
  /// In en, this message translates to:
  /// **'Enter file name'**
  String get enterFileName;

  /// No description provided for @exportFormat.
  ///
  /// In en, this message translates to:
  /// **'Export Format'**
  String get exportFormat;

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
  /// **'Work Count'**
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
  /// **'{count} per page'**
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
  /// **'Delete Selected'**
  String get workBrowseDeleteSelected;

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

  /// No description provided for @horizontalLeftToRight.
  ///
  /// In en, this message translates to:
  /// **'Horizontal Left-to-Right'**
  String get horizontalLeftToRight;

  /// No description provided for @horizontalRightToLeft.
  ///
  /// In en, this message translates to:
  /// **'Horizontal Right-to-Left'**
  String get horizontalRightToLeft;

  /// No description provided for @verticalLeftToRight.
  ///
  /// In en, this message translates to:
  /// **'Vertical Left-to-Right'**
  String get verticalLeftToRight;

  /// No description provided for @verticalRightToLeft.
  ///
  /// In en, this message translates to:
  /// **'Vertical Right-to-Left'**
  String get verticalRightToLeft;

  /// No description provided for @collectionPropertyPanelAvailableCharacters.
  ///
  /// In en, this message translates to:
  /// **'Available Characters'**
  String get collectionPropertyPanelAvailableCharacters;

  /// No description provided for @exportDialogFitPolicy.
  ///
  /// In en, this message translates to:
  /// **'Fit Policy'**
  String get exportDialogFitPolicy;

  /// No description provided for @exportDialogFitWidth.
  ///
  /// In en, this message translates to:
  /// **'Fit to Width'**
  String get exportDialogFitWidth;

  /// No description provided for @exportDialogFitHeight.
  ///
  /// In en, this message translates to:
  /// **'Fit to Height'**
  String get exportDialogFitHeight;

  /// No description provided for @exportDialogFitContain.
  ///
  /// In en, this message translates to:
  /// **'Contain in Page'**
  String get exportDialogFitContain;

  /// No description provided for @exportDialogCentimeter.
  ///
  /// In en, this message translates to:
  /// **'cm'**
  String get exportDialogCentimeter;

  /// No description provided for @exportDialogMarginTop.
  ///
  /// In en, this message translates to:
  /// **'Top'**
  String get exportDialogMarginTop;

  /// No description provided for @exportDialogMarginRight.
  ///
  /// In en, this message translates to:
  /// **'Right'**
  String get exportDialogMarginRight;

  /// No description provided for @exportDialogMarginBottom.
  ///
  /// In en, this message translates to:
  /// **'Bottom'**
  String get exportDialogMarginBottom;

  /// No description provided for @exportDialogMarginLeft.
  ///
  /// In en, this message translates to:
  /// **'Left'**
  String get exportDialogMarginLeft;

  /// No description provided for @exportDialogPageMargins.
  ///
  /// In en, this message translates to:
  /// **'Page Margins (cm)'**
  String get exportDialogPageMargins;

  /// No description provided for @exportDialogPageOrientation.
  ///
  /// In en, this message translates to:
  /// **'Page Orientation'**
  String get exportDialogPageOrientation;

  /// No description provided for @exportDialogPortrait.
  ///
  /// In en, this message translates to:
  /// **'Portrait'**
  String get exportDialogPortrait;

  /// No description provided for @exportDialogLandscape.
  ///
  /// In en, this message translates to:
  /// **'Landscape'**
  String get exportDialogLandscape;

  /// No description provided for @exportDialogLocation.
  ///
  /// In en, this message translates to:
  /// **'Export Location'**
  String get exportDialogLocation;

  /// No description provided for @exportDialogSelectLocation.
  ///
  /// In en, this message translates to:
  /// **'Please select export location'**
  String get exportDialogSelectLocation;

  /// No description provided for @exportDialogBrowse.
  ///
  /// In en, this message translates to:
  /// **'Browse...'**
  String get exportDialogBrowse;

  /// No description provided for @exportDialogPageRange.
  ///
  /// In en, this message translates to:
  /// **'Page Range'**
  String get exportDialogPageRange;

  /// No description provided for @exportDialogAllPages.
  ///
  /// In en, this message translates to:
  /// **'All Pages'**
  String get exportDialogAllPages;

  /// No description provided for @exportDialogCurrentPage.
  ///
  /// In en, this message translates to:
  /// **'Current Page'**
  String get exportDialogCurrentPage;

  /// No description provided for @exportDialogCustomRange.
  ///
  /// In en, this message translates to:
  /// **'Custom Range'**
  String get exportDialogCustomRange;

  /// No description provided for @exportDialogRangeExample.
  ///
  /// In en, this message translates to:
  /// **'Example: 1-3,5,7-9'**
  String get exportDialogRangeExample;

  /// No description provided for @exportDialogPageSize.
  ///
  /// In en, this message translates to:
  /// **'Page Size'**
  String get exportDialogPageSize;

  /// No description provided for @exportDialogOutputQuality.
  ///
  /// In en, this message translates to:
  /// **'Output Quality'**
  String get exportDialogOutputQuality;

  /// No description provided for @exportDialogMultipleFilesNote.
  ///
  /// In en, this message translates to:
  /// **'Note: Will export {count} image files, filenames will be automatically numbered.'**
  String exportDialogMultipleFilesNote(Object count);

  /// No description provided for @exportDialogPreview.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get exportDialogPreview;

  /// No description provided for @exportDialogPreviewPage.
  ///
  /// In en, this message translates to:
  /// **' (Page {current}/{total})'**
  String exportDialogPreviewPage(Object current, Object total);

  /// No description provided for @exportDialogNoPreview.
  ///
  /// In en, this message translates to:
  /// **'Cannot generate preview'**
  String get exportDialogNoPreview;

  /// No description provided for @exportDialogDimensions.
  ///
  /// In en, this message translates to:
  /// **'{width}cm × {height}cm ({orientation})'**
  String exportDialogDimensions(Object height, Object orientation, Object width);

  /// No description provided for @exportDialogPreviousPage.
  ///
  /// In en, this message translates to:
  /// **'Previous Page'**
  String get exportDialogPreviousPage;

  /// No description provided for @exportDialogNextPage.
  ///
  /// In en, this message translates to:
  /// **'Next Page'**
  String get exportDialogNextPage;

  /// No description provided for @exportDialogEnterFilename.
  ///
  /// In en, this message translates to:
  /// **'Please enter a filename'**
  String get exportDialogEnterFilename;

  /// No description provided for @exportDialogInvalidFilename.
  ///
  /// In en, this message translates to:
  /// **'Filename cannot contain the following characters: \\ / : * ? \" < > |'**
  String get exportDialogInvalidFilename;

  /// No description provided for @exportDialogCreateDirectoryFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to create export directory'**
  String get exportDialogCreateDirectoryFailed;

  /// No description provided for @exportDialogQualityStandard.
  ///
  /// In en, this message translates to:
  /// **'Standard (1x)'**
  String get exportDialogQualityStandard;

  /// No description provided for @exportDialogQualityHigh.
  ///
  /// In en, this message translates to:
  /// **'High (2x)'**
  String get exportDialogQualityHigh;

  /// No description provided for @exportDialogQualityUltra.
  ///
  /// In en, this message translates to:
  /// **'Ultra (3x)'**
  String get exportDialogQualityUltra;

  /// No description provided for @exportDialogFilenamePrefix.
  ///
  /// In en, this message translates to:
  /// **'Enter filename prefix (page numbers will be added automatically)'**
  String get exportDialogFilenamePrefix;

  /// No description provided for @restartAppRequired.
  ///
  /// In en, this message translates to:
  /// **'The application needs to be restarted to complete the restore process.'**
  String get restartAppRequired;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @restartNow.
  ///
  /// In en, this message translates to:
  /// **'Restart Now'**
  String get restartNow;

  /// No description provided for @restartLater.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get restartLater;

  /// No description provided for @collectionPropertyPanelGlobalInversion.
  ///
  /// In en, this message translates to:
  /// **'Global Inversion'**
  String get collectionPropertyPanelGlobalInversion;

  /// No description provided for @collectionPropertyPanelCurrentCharInversion.
  ///
  /// In en, this message translates to:
  /// **'Current Character Inversion'**
  String get collectionPropertyPanelCurrentCharInversion;

  /// No description provided for @collectionPropertyPanelColorPicker.
  ///
  /// In en, this message translates to:
  /// **'Pick Color'**
  String get collectionPropertyPanelColorPicker;

  /// No description provided for @collectionPropertyPanelColorSettings.
  ///
  /// In en, this message translates to:
  /// **'Color Setting'**
  String get collectionPropertyPanelColorSettings;

  /// No description provided for @collectionPropertyPanelAutoLineBreak.
  ///
  /// In en, this message translates to:
  /// **'Auto Line Break'**
  String get collectionPropertyPanelAutoLineBreak;

  /// No description provided for @collectionPropertyPanelAutoLineBreakEnabled.
  ///
  /// In en, this message translates to:
  /// **'Enable'**
  String get collectionPropertyPanelAutoLineBreakEnabled;

  /// No description provided for @collectionPropertyPanelAutoLineBreakDisabled.
  ///
  /// In en, this message translates to:
  /// **'Disable'**
  String get collectionPropertyPanelAutoLineBreakDisabled;

  /// No description provided for @collectionPropertyPanelAutoLineBreakTooltip.
  ///
  /// In en, this message translates to:
  /// **'Auto Line Break'**
  String get collectionPropertyPanelAutoLineBreakTooltip;

  /// No description provided for @verticalTextModeEnabled.
  ///
  /// In en, this message translates to:
  /// **'Vertical text preview - Automatically flows to new columns when height exceeded, scroll horizontally'**
  String get verticalTextModeEnabled;

  /// No description provided for @groupOperations.
  ///
  /// In en, this message translates to:
  /// **'Group Operations'**
  String get groupOperations;

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

  /// No description provided for @ungroupDescription.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to ungroup this group?'**
  String get ungroupDescription;

  /// No description provided for @practiceEditDangerZone.
  ///
  /// In en, this message translates to:
  /// **'Danger Zone'**
  String get practiceEditDangerZone;

  /// No description provided for @deleteGroup.
  ///
  /// In en, this message translates to:
  /// **'Delete Group'**
  String get deleteGroup;

  /// No description provided for @groupElements.
  ///
  /// In en, this message translates to:
  /// **'Group Elements'**
  String get groupElements;

  /// No description provided for @deleteGroupConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm Delete Group'**
  String get deleteGroupConfirm;

  /// No description provided for @deleteGroupDescription.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this group? This action cannot be undone.'**
  String get deleteGroupDescription;

  /// No description provided for @deleteGroupElements.
  ///
  /// In en, this message translates to:
  /// **'Delete Group Elements'**
  String get deleteGroupElements;

  /// No description provided for @enterGroupEditMode.
  ///
  /// In en, this message translates to:
  /// **'Enter Group Edit Mode'**
  String get enterGroupEditMode;

  /// No description provided for @ungroupConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm Ungroup'**
  String get ungroupConfirm;

  /// No description provided for @alignHorizontalCenter.
  ///
  /// In en, this message translates to:
  /// **'Align Horizontal Center'**
  String get alignHorizontalCenter;

  /// No description provided for @alignVerticalCenter.
  ///
  /// In en, this message translates to:
  /// **'Align Vertical Center'**
  String get alignVerticalCenter;

  /// No description provided for @imagePropertyPanelCropping.
  ///
  /// In en, this message translates to:
  /// **'Cropping'**
  String get imagePropertyPanelCropping;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @batchOperations.
  ///
  /// In en, this message translates to:
  /// **'Batch Operations'**
  String get batchOperations;

  /// No description provided for @listView.
  ///
  /// In en, this message translates to:
  /// **'List View'**
  String get listView;

  /// No description provided for @gridView.
  ///
  /// In en, this message translates to:
  /// **'Grid View'**
  String get gridView;

  /// No description provided for @searchCharactersWorksAuthors.
  ///
  /// In en, this message translates to:
  /// **'Search characters, works, or authors'**
  String get searchCharactersWorksAuthors;

  /// No description provided for @exitBatchMode.
  ///
  /// In en, this message translates to:
  /// **'Exit Batch Mode'**
  String get exitBatchMode;

  /// No description provided for @selectedCount.
  ///
  /// In en, this message translates to:
  /// **'{count} selected'**
  String selectedCount(Object count);

  /// No description provided for @totalItems.
  ///
  /// In en, this message translates to:
  /// **'Total: {count}'**
  String totalItems(Object count);

  /// No description provided for @workBrowseItemsPerPage.
  ///
  /// In en, this message translates to:
  /// **'{count} per page'**
  String workBrowseItemsPerPage(Object count);

  /// No description provided for @windowButtonMinimize.
  ///
  /// In en, this message translates to:
  /// **'Minimize'**
  String get windowButtonMinimize;

  /// No description provided for @windowButtonMaximize.
  ///
  /// In en, this message translates to:
  /// **'Maximize'**
  String get windowButtonMaximize;

  /// No description provided for @windowButtonRestore.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get windowButtonRestore;

  /// No description provided for @windowButtonClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get windowButtonClose;

  /// No description provided for @restartAfterRestored.
  ///
  /// In en, this message translates to:
  /// **'Note: The application will automatically restart after restoration is complete'**
  String get restartAfterRestored;

  /// No description provided for @storageLocation.
  ///
  /// In en, this message translates to:
  /// **'Storage Location'**
  String get storageLocation;

  /// No description provided for @cacheSize.
  ///
  /// In en, this message translates to:
  /// **'Cache Size'**
  String get cacheSize;

  /// No description provided for @storageUsed.
  ///
  /// In en, this message translates to:
  /// **'Storage Used'**
  String get storageUsed;

  /// No description provided for @fileCount.
  ///
  /// In en, this message translates to:
  /// **'File Count'**
  String get fileCount;

  /// No description provided for @libraryCount.
  ///
  /// In en, this message translates to:
  /// **'Library Count'**
  String get libraryCount;

  /// No description provided for @characterCount.
  ///
  /// In en, this message translates to:
  /// **'Character Count'**
  String get characterCount;

  /// No description provided for @workCount.
  ///
  /// In en, this message translates to:
  /// **'Work Count'**
  String get workCount;

  /// No description provided for @loadFailed.
  ///
  /// In en, this message translates to:
  /// **'Load Failed'**
  String get loadFailed;

  /// No description provided for @libraryManagement.
  ///
  /// In en, this message translates to:
  /// **'Library'**
  String get libraryManagement;

  /// No description provided for @libraryManagementLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get libraryManagementLoading;

  /// No description provided for @libraryManagementError.
  ///
  /// In en, this message translates to:
  /// **'Failed to load: {message}'**
  String libraryManagementError(String message);

  /// No description provided for @libraryManagementNoItems.
  ///
  /// In en, this message translates to:
  /// **'No items'**
  String get libraryManagementNoItems;

  /// No description provided for @libraryManagementNoItemsHint.
  ///
  /// In en, this message translates to:
  /// **'Try adding some items or changing filters'**
  String get libraryManagementNoItemsHint;

  /// No description provided for @libraryManagementSearch.
  ///
  /// In en, this message translates to:
  /// **'Search items...'**
  String get libraryManagementSearch;

  /// No description provided for @libraryManagementEnterBatchMode.
  ///
  /// In en, this message translates to:
  /// **'Enter batch mode'**
  String get libraryManagementEnterBatchMode;

  /// No description provided for @libraryManagementExitBatchMode.
  ///
  /// In en, this message translates to:
  /// **'Exit batch mode'**
  String get libraryManagementExitBatchMode;

  /// No description provided for @libraryManagementDeleteSelected.
  ///
  /// In en, this message translates to:
  /// **'Delete selected items'**
  String get libraryManagementDeleteSelected;

  /// No description provided for @libraryManagementDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm deletion'**
  String get libraryManagementDeleteConfirm;

  /// No description provided for @libraryManagementDeleteMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete the selected items? This action cannot be undone.'**
  String get libraryManagementDeleteMessage;

  /// No description provided for @libraryManagementGridView.
  ///
  /// In en, this message translates to:
  /// **'Grid view'**
  String get libraryManagementGridView;

  /// No description provided for @libraryManagementListView.
  ///
  /// In en, this message translates to:
  /// **'List view'**
  String get libraryManagementListView;

  /// No description provided for @libraryManagementCategories.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get libraryManagementCategories;

  /// No description provided for @libraryManagementSortBy.
  ///
  /// In en, this message translates to:
  /// **'Sort by'**
  String get libraryManagementSortBy;

  /// No description provided for @libraryManagementSortByName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get libraryManagementSortByName;

  /// No description provided for @libraryManagementSortByDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get libraryManagementSortByDate;

  /// No description provided for @libraryManagementSortBySize.
  ///
  /// In en, this message translates to:
  /// **'File size'**
  String get libraryManagementSortBySize;

  /// No description provided for @libraryManagementBasicInfo.
  ///
  /// In en, this message translates to:
  /// **'Basic Information'**
  String get libraryManagementBasicInfo;

  /// No description provided for @libraryManagementName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get libraryManagementName;

  /// No description provided for @libraryManagementType.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get libraryManagementType;

  /// No description provided for @libraryManagementFormat.
  ///
  /// In en, this message translates to:
  /// **'Format'**
  String get libraryManagementFormat;

  /// No description provided for @libraryManagementSize.
  ///
  /// In en, this message translates to:
  /// **'Size'**
  String get libraryManagementSize;

  /// No description provided for @libraryManagementResolution.
  ///
  /// In en, this message translates to:
  /// **'Resolution'**
  String get libraryManagementResolution;

  /// No description provided for @libraryManagementFileSize.
  ///
  /// In en, this message translates to:
  /// **'File size'**
  String get libraryManagementFileSize;

  /// No description provided for @libraryManagementTags.
  ///
  /// In en, this message translates to:
  /// **'Tags'**
  String get libraryManagementTags;

  /// No description provided for @libraryManagementMetadata.
  ///
  /// In en, this message translates to:
  /// **'Metadata'**
  String get libraryManagementMetadata;

  /// No description provided for @libraryManagementTimeInfo.
  ///
  /// In en, this message translates to:
  /// **'Time Information'**
  String get libraryManagementTimeInfo;

  /// No description provided for @libraryManagementCreatedAt.
  ///
  /// In en, this message translates to:
  /// **'Created at'**
  String get libraryManagementCreatedAt;

  /// No description provided for @libraryManagementUpdatedAt.
  ///
  /// In en, this message translates to:
  /// **'Updated at'**
  String get libraryManagementUpdatedAt;

  /// No description provided for @libraryManagementDetail.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get libraryManagementDetail;

  /// No description provided for @libraryManagementImport.
  ///
  /// In en, this message translates to:
  /// **'Import'**
  String get libraryManagementImport;

  /// No description provided for @libraryManagementImportFiles.
  ///
  /// In en, this message translates to:
  /// **'Import Files'**
  String get libraryManagementImportFiles;

  /// No description provided for @libraryManagementImportFolder.
  ///
  /// In en, this message translates to:
  /// **'Import Folder'**
  String get libraryManagementImportFolder;

  /// No description provided for @libraryManagementRemarks.
  ///
  /// In en, this message translates to:
  /// **'Remarks'**
  String get libraryManagementRemarks;

  /// No description provided for @libraryManagementRemarksHint.
  ///
  /// In en, this message translates to:
  /// **'Add remarks'**
  String get libraryManagementRemarksHint;

  /// No description provided for @libraryManagementNoRemarks.
  ///
  /// In en, this message translates to:
  /// **'No remarks'**
  String get libraryManagementNoRemarks;

  /// No description provided for @sortAndFilter.
  ///
  /// In en, this message translates to:
  /// **'Sort & Filter'**
  String get sortAndFilter;

  /// No description provided for @categoryManagement.
  ///
  /// In en, this message translates to:
  /// **'Category Management'**
  String get categoryManagement;

  /// No description provided for @addCategory.
  ///
  /// In en, this message translates to:
  /// **'Add Category'**
  String get addCategory;

  /// No description provided for @searchCategories.
  ///
  /// In en, this message translates to:
  /// **'Search categories...'**
  String get searchCategories;

  /// No description provided for @allCategories.
  ///
  /// In en, this message translates to:
  /// **'All Categories'**
  String get allCategories;

  /// No description provided for @removedFromAllCategories.
  ///
  /// In en, this message translates to:
  /// **'Removed from all categories'**
  String get removedFromAllCategories;

  /// No description provided for @addedToCategory.
  ///
  /// In en, this message translates to:
  /// **'Added to category'**
  String get addedToCategory;

  /// No description provided for @newCategory.
  ///
  /// In en, this message translates to:
  /// **'New Category'**
  String get newCategory;

  /// No description provided for @deleteCategory.
  ///
  /// In en, this message translates to:
  /// **'Delete Category'**
  String get deleteCategory;

  /// No description provided for @categoryHasItems.
  ///
  /// In en, this message translates to:
  /// **'{count} items in this category'**
  String categoryHasItems(Object count);

  /// No description provided for @confirmDelete.
  ///
  /// In en, this message translates to:
  /// **'Do you want to delete?'**
  String get confirmDelete;

  /// No description provided for @confirmDeleteCategory.
  ///
  /// In en, this message translates to:
  /// **'Do you want to delete category'**
  String get confirmDeleteCategory;

  /// No description provided for @editCategory.
  ///
  /// In en, this message translates to:
  /// **'Edit Category'**
  String get editCategory;

  /// No description provided for @categories.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get categories;

  /// No description provided for @categoryPanelTitle.
  ///
  /// In en, this message translates to:
  /// **'Category Panel'**
  String get categoryPanelTitle;

  /// No description provided for @libraryManagementFavorite.
  ///
  /// In en, this message translates to:
  /// **'Favorite'**
  String get libraryManagementFavorite;

  /// No description provided for @libraryManagementFavorites.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get libraryManagementFavorites;

  /// No description provided for @libraryManagementFormats.
  ///
  /// In en, this message translates to:
  /// **'File Formats'**
  String get libraryManagementFormats;

  /// No description provided for @libraryManagementTypes.
  ///
  /// In en, this message translates to:
  /// **'Types'**
  String get libraryManagementTypes;

  /// No description provided for @libraryManagementSortDesc.
  ///
  /// In en, this message translates to:
  /// **'Sort Order'**
  String get libraryManagementSortDesc;

  /// No description provided for @allTypes.
  ///
  /// In en, this message translates to:
  /// **'All Types'**
  String get allTypes;

  /// No description provided for @yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @unknownCategory.
  ///
  /// In en, this message translates to:
  /// **'Unknown Category'**
  String get unknownCategory;

  /// No description provided for @noCategories.
  ///
  /// In en, this message translates to:
  /// **'No Categories'**
  String get noCategories;

  /// No description provided for @tagsHint.
  ///
  /// In en, this message translates to:
  /// **'Enter tags...'**
  String get tagsHint;

  /// No description provided for @noTags.
  ///
  /// In en, this message translates to:
  /// **'No Tags'**
  String get noTags;

  /// No description provided for @libraryManagementSortByFileSize.
  ///
  /// In en, this message translates to:
  /// **'File Size'**
  String get libraryManagementSortByFileSize;

  /// No description provided for @libraryManagementPath.
  ///
  /// In en, this message translates to:
  /// **'Path'**
  String get libraryManagementPath;

  /// No description provided for @storageDetails.
  ///
  /// In en, this message translates to:
  /// **'Storage Details'**
  String get storageDetails;

  /// No description provided for @files.
  ///
  /// In en, this message translates to:
  /// **'File Count'**
  String get files;
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
