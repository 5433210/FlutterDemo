import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
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
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

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

  /// No description provided for @backgroundColor.
  ///
  /// In en, this message translates to:
  /// **'Background Color'**
  String get backgroundColor;

  /// No description provided for @basicInfo.
  ///
  /// In en, this message translates to:
  /// **'Basic Information'**
  String get basicInfo;

  /// No description provided for @bringLayerToFront.
  ///
  /// In en, this message translates to:
  /// **'Bring layer to the front'**
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
  /// **'Favorites'**
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
  /// **'Character Collection allows you to extract, edit, and manage characters from images. Here\'s a detailed guide:'**
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
  /// **'Cannot load image'**
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
  /// **'Please select a character region in the preview area'**
  String get characterCollectionSelectRegion;

  /// No description provided for @characterCollectionSwitchingPage.
  ///
  /// In en, this message translates to:
  /// **'Switching to character\'s page...'**
  String get characterCollectionSwitchingPage;

  /// No description provided for @characterCollectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Character Collection'**
  String get characterCollectionTitle;

  /// No description provided for @characterCollectionToolDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete Selected (Ctrl+D)'**
  String get characterCollectionToolDelete;

  /// No description provided for @characterCollectionToolPan.
  ///
  /// In en, this message translates to:
  /// **'Pan Tool (Ctrl+V)'**
  String get characterCollectionToolPan;

  /// No description provided for @characterCollectionToolSelect.
  ///
  /// In en, this message translates to:
  /// **'Selection Tool (Ctrl+B)'**
  String get characterCollectionToolSelect;

  /// No description provided for @characterCollectionUnsavedChanges.
  ///
  /// In en, this message translates to:
  /// **'Unsaved Changes'**
  String get characterCollectionUnsavedChanges;

  /// No description provided for @characterCollectionUnsavedChangesMessage.
  ///
  /// In en, this message translates to:
  /// **'You have unsaved region modifications. Leaving will lose these changes.\n\nAre you sure you want to leave?'**
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
  /// **'Show Favorites Only'**
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
  /// **'Are you sure you want to delete the selected character(s)? This action cannot be undone.'**
  String get characterManagementDeleteMessage;

  /// No description provided for @characterManagementDeleteSelected.
  ///
  /// In en, this message translates to:
  /// **'Delete Selected'**
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
  /// **'Search characters, works or authors'**
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

  String get collectionPropertyPanelCacheCleared;

  String get collectionPropertyPanelCacheClearFailed;

  String get collectionPropertyPanelCandidateCharacters;

  /// No description provided for @collectionPropertyPanelCharacter.
  ///
  /// In en, this message translates to:
  /// **'Character'**
  String get collectionPropertyPanelCharacter;

  String get collectionPropertyPanelCharacterSettings;

  /// No description provided for @collectionPropertyPanelCharacterSource.
  ///
  /// In en, this message translates to:
  /// **'Character Source'**
  String get collectionPropertyPanelCharacterSource;

  String get collectionPropertyPanelCharIndex;

  String get collectionPropertyPanelClearImageCache;

  String get collectionPropertyPanelColorInversion;

  /// No description provided for @collectionPropertyPanelContent.
  ///
  /// In en, this message translates to:
  /// **'Content Properties'**
  String get collectionPropertyPanelContent;

  String get collectionPropertyPanelDisabled;

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

  String get collectionPropertyPanelHeaderContent;

  String get collectionPropertyPanelHeaderGeometry;

  String get collectionPropertyPanelHeaderVisual;

  String get collectionPropertyPanelInvertDisplay;

  /// No description provided for @collectionPropertyPanelNoCharacterSelected.
  ///
  /// In en, this message translates to:
  /// **'No character selected'**
  String get collectionPropertyPanelNoCharacterSelected;

  String get collectionPropertyPanelNoCharactersFound;

  String get collectionPropertyPanelNoCharacterText;

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

  String get collectionPropertyPanelSearchInProgress;

  /// No description provided for @collectionPropertyPanelSelectCharacter.
  ///
  /// In en, this message translates to:
  /// **'Please select a character'**
  String get collectionPropertyPanelSelectCharacter;

  String get collectionPropertyPanelSelectCharacterFirst;

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

  String get collectionPropertyPanelTextSettings;

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
  /// **'Delete page'**
  String get deletePage;

  /// No description provided for @dimensions.
  ///
  /// In en, this message translates to:
  /// **'Dimensions'**
  String get dimensions;

  /// No description provided for @dpiHelperText.
  ///
  /// In en, this message translates to:
  /// **'Used to calculate canvas pixel size, default 300dpi'**
  String get dpiHelperText;

  /// No description provided for @dpiSetting.
  ///
  /// In en, this message translates to:
  /// **'DPI Setting (Dots Per Inch)'**
  String get dpiSetting;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @elements.
  ///
  /// In en, this message translates to:
  /// **'elements'**
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
  /// **'Create Time'**
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
  /// **'Group Information'**
  String get groupInfo;

  /// No description provided for @height.
  ///
  /// In en, this message translates to:
  /// **'Height'**
  String get height;

  /// No description provided for @hideElement.
  ///
  /// In en, this message translates to:
  /// **'Hide element'**
  String get hideElement;

  String get imageCacheCleared;

  String get imageCacheClearFailed;

  /// No description provided for @imagePropertyPanel.
  ///
  /// In en, this message translates to:
  /// **'Image Properties'**
  String get imagePropertyPanel;

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

  String get imagePropertyPanelCannotApplyNoImage;

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

  String get imagePropertyPanelCropBottom;

  String get imagePropertyPanelCropLeft;

  String get imagePropertyPanelCroppingApplied;

  String get imagePropertyPanelCroppingValueTooLarge;

  String get imagePropertyPanelCropRight;

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

  String get imagePropertyPanelFileNotExist;

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

  String get imagePropertyPanelFitMode;

  /// No description provided for @imagePropertyPanelFitNone.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get imagePropertyPanelFitNone;

  String get imagePropertyPanelFitOriginal;

  String get imagePropertyPanelFlip;

  String get imagePropertyPanelFlipHorizontal;

  String get imagePropertyPanelFlipVertical;

  /// No description provided for @imagePropertyPanelGeometry.
  ///
  /// In en, this message translates to:
  /// **'Geometry Properties'**
  String get imagePropertyPanelGeometry;

  String get imagePropertyPanelGeometryWarning;

  String get imagePropertyPanelImageSelection;

  /// No description provided for @imagePropertyPanelImageSize.
  ///
  /// In en, this message translates to:
  /// **'Image Size'**
  String get imagePropertyPanelImageSize;

  String get imagePropertyPanelImageTransform;

  String get imagePropertyPanelLoadError;

  String get imagePropertyPanelNoCropping;

  /// No description provided for @imagePropertyPanelNoImage.
  ///
  /// In en, this message translates to:
  /// **'No image selected'**
  String get imagePropertyPanelNoImage;

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

  String get imagePropertyPanelPreview;

  String get imagePropertyPanelPreviewNotice;

  String get imagePropertyPanelProcessingPathError;

  /// No description provided for @imagePropertyPanelReset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get imagePropertyPanelReset;

  String get imagePropertyPanelResetSuccess;

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

  String get imagePropertyPanelSelectFromLocal;

  String get imagePropertyPanelTransformApplied;

  String get imagePropertyPanelTransformError;

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

  /// Get the localized language name for English
  String get languageEn;

  /// Get the localized language name for the system language
  String get languageSystem;

  /// Get the localized language name for Chinese
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
  /// **'Lock element'**
  String get lockElement;

  /// No description provided for @lockUnlockAllElements.
  ///
  /// In en, this message translates to:
  /// **'Lock/Unlock all elements'**
  String get lockUnlockAllElements;

  /// No description provided for @moveDown.
  ///
  /// In en, this message translates to:
  /// **'Move Down'**
  String get moveDown;

  /// No description provided for @moveLayerDown.
  ///
  /// In en, this message translates to:
  /// **'Move layer down'**
  String get moveLayerDown;

  /// No description provided for @moveLayerUp.
  ///
  /// In en, this message translates to:
  /// **'Move layer up'**
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

  /// No description provided for @practiceEditElementSelectionInfo.
  ///
  /// In en, this message translates to:
  /// **'{count} elements selected'**
  String get practiceEditElementSelectionInfo;

  /// No description provided for @practiceEditEnableSnap.
  ///
  /// In en, this message translates to:
  /// **'Enable Snap (Ctrl+R)'**
  String get practiceEditEnableSnap;

  /// No description provided for @practiceEditEnterTitle.
  ///
  /// In en, this message translates to:
  /// **'Please enter practice title'**
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
  /// **'Multiple Selection Properties'**
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
  /// **'Save and Exit'**
  String get practiceEditSaveAndExit;

  /// No description provided for @practiceEditSaveAndLeave.
  ///
  /// In en, this message translates to:
  /// **'Save and Leave'**
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
  /// **'Title Already Exists'**
  String get practiceEditTitleExists;

  /// No description provided for @practiceEditTitleExistsMessage.
  ///
  /// In en, this message translates to:
  /// **'A practice with this title already exists. Overwrite?'**
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
  /// **'You have unsaved changes. Do you want to exit?'**
  String get practiceEditUnsavedChangesExitConfirmation;

  /// No description provided for @practiceEditUnsavedChangesMessage.
  ///
  /// In en, this message translates to:
  /// **'You have unsaved changes. Do you want to leave?'**
  String get practiceEditUnsavedChangesMessage;

  /// No description provided for @practiceEditVisualProperties.
  ///
  /// In en, this message translates to:
  /// **'Visual Properties'**
  String get practiceEditVisualProperties;

  String get practiceListBatchDone;

  String get practiceListBatchMode;

  String get practiceListDeleteConfirm;

  String get practiceListDeleteMessage;

  String get practiceListDeleteSelected;

  String get practiceListError;

  String get practiceListGridView;
  String get practiceListItemsPerPage;
  String get practiceListListView;
  String get practiceListLoading;
  String get practiceListNewPractice;
  String get practiceListNoResults;
  String get practiceListPages;
  String get practiceListSearch;
  String get practiceListSortByCreateTime;
  String get practiceListSortByTitle;
  String get practiceListSortByUpdateTime;
  String get practiceListThumbnailError;
  String get practiceListTitle;
  String get practiceListTotalItems;
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

  String get selectCollection;

  /// No description provided for @selected.
  ///
  /// In en, this message translates to:
  /// **'Selected'**
  String get selected;

  /// No description provided for @sendLayerToBack.
  ///
  /// In en, this message translates to:
  /// **'Send layer to the back'**
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
  /// **'Show element'**
  String get showElement;

  /// No description provided for @showGrid.
  ///
  /// In en, this message translates to:
  /// **'Show Grid'**
  String get showGrid;

  /// No description provided for @showHideAllElements.
  ///
  /// In en, this message translates to:
  /// **'Show/Hide all elements'**
  String get showHideAllElements;

  /// No description provided for @stateAndDisplay.
  ///
  /// In en, this message translates to:
  /// **'State and Display'**
  String get stateAndDisplay;

  /// No description provided for @storageSettings.
  ///
  /// In en, this message translates to:
  /// **'Storage Settings'**
  String get storageSettings;

  /// No description provided for @tagEditorEnterTagHint.
  ///
  /// In en, this message translates to:
  /// **'Enter tag and press Enter'**
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
  /// **'Unlock element'**
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

  String get visualSettings;

  /// No description provided for @width.
  ///
  /// In en, this message translates to:
  /// **'Width'**
  String get width;

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

  /// No description provided for @characterCollectionDeleteBatchConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm Deletion of {count} Regions'**
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
  /// **'Failed to find and switch page: {error}'**
  String characterCollectionFindSwitchFailed(Object error);

  String characterEditCharacterUpdated(Object character);

  String characterEditSaveConfirmMessage(Object character);

  /// No description provided for @characterManagementError.
  ///
  /// In en, this message translates to:
  /// **'Error: {message}'**
  String characterManagementError(Object message);

  /// No description provided for @characterManagementItemsPerPage.
  ///
  /// In en, this message translates to:
  /// **'{count} items/page'**
  String characterManagementItemsPerPage(Object count);

  /// No description provided for @initializationFailed.
  ///
  /// In en, this message translates to:
  /// **'Initialization failed: {error}'**
  String initializationFailed(Object error);

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
  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
