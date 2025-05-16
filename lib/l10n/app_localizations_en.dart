// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get a4Size => 'A4 (210×297mm)';

  @override
  String get a5Size => 'A5 (148×210mm)';

  @override
  String get about => 'About';

  @override
  String get addCategory => 'Add Category';

  @override
  String get addedToCategory => 'Added to category';

  @override
  String get alignBottom => 'Align Bottom';

  @override
  String get alignCenter => 'Align Center';

  @override
  String get alignHorizontalCenter => 'Align Horizontal Center';

  @override
  String get alignLeft => 'Align Left';

  @override
  String get alignmentOperations => 'Alignment Operations';

  @override
  String get alignmentRequiresMultipleElements => 'Alignment requires at least 2 elements';

  @override
  String get alignMiddle => 'Align Middle';

  @override
  String get alignRight => 'Align Right';

  @override
  String get alignTop => 'Align Top';

  @override
  String get alignVerticalCenter => 'Align Vertical Center';

  @override
  String get allCategories => 'All Categories';

  @override
  String get allTypes => 'All Types';

  @override
  String get appName => 'Char As Gem';

  @override
  String get appTitle => 'Char As Gem';

  @override
  String get autoBackup => 'Auto Backup';

  @override
  String get autoBackupDescription => 'Automatically backup your data periodically';

  @override
  String get autoBackupInterval => 'Auto Backup Interval';

  @override
  String get autoBackupIntervalDescription => 'How often to create automatic backups';

  @override
  String get autoCleanup => 'Auto Cleanup';

  @override
  String get autoCleanupDescription => 'Automatically clean up old cache files';

  @override
  String get autoCleanupInterval => 'Auto Cleanup Interval';

  @override
  String get autoCleanupIntervalDescription => 'How often to run automatic cleanup';

  @override
  String get back => 'Back';

  @override
  String get backgroundColor => 'Background Color';

  @override
  String get backupDescription => 'Description (Optional)';

  @override
  String get backupDescriptionHint => 'Enter a description for this backup';

  @override
  String get backupFailure => 'Failed to create backup';

  @override
  String get backupList => 'Backup List';

  @override
  String get backupSettings => 'Backup & Restore';

  @override
  String get backupSuccess => 'Backup created successfully';

  @override
  String get basicInfo => 'Basic Info';

  @override
  String get batchOperations => 'Batch Operations';

  @override
  String get bringLayerToFront => 'Bring Layer to Front';

  @override
  String get bringToFront => 'Bring to Front';

  @override
  String get cacheClearedMessage => 'Cache cleared successfully';

  @override
  String get cacheSettings => 'Cache Settings';

  @override
  String get cacheSize => 'Cache Size';

  @override
  String get cancel => 'Cancel';

  @override
  String get canvasPixelSize => 'Canvas Pixel Size';

  @override
  String get categories => 'Categories';

  @override
  String categoryHasItems(Object count) {
    return '$count items in this category';
  }

  @override
  String get categoryManagement => 'Category Management';

  @override
  String get categoryPanelTitle => 'Category Panel';

  @override
  String get center => 'Center';

  @override
  String get characterCollectionBack => 'Back';

  @override
  String characterCollectionDeleteBatchConfirm(Object count) {
    return 'Confirm deletion of $count saved regions?';
  }

  @override
  String characterCollectionDeleteBatchMessage(Object count) {
    return 'You are about to delete $count saved regions. This action cannot be undone.';
  }

  @override
  String get characterCollectionDeleteConfirm => 'Confirm Deletion';

  @override
  String get characterCollectionDeleteMessage => 'You are about to delete the selected region. This action cannot be undone.';

  @override
  String get characterCollectionDeleteShortcuts => 'Shortcuts: Enter to confirm, Esc to cancel';

  @override
  String characterCollectionError(Object error) {
    return 'Error: $error';
  }

  @override
  String get characterCollectionFilterAll => 'All';

  @override
  String get characterCollectionFilterFavorite => 'Favorite';

  @override
  String get characterCollectionFilterRecent => 'Recent';

  @override
  String characterCollectionFindSwitchFailed(Object error) {
    return 'Find and switch page failed: $error';
  }

  @override
  String get characterCollectionHelp => 'Help';

  @override
  String get characterCollectionHelpClose => 'Close';

  @override
  String get characterCollectionHelpExport => 'Export Help Document';

  @override
  String get characterCollectionHelpExportSoon => 'Help document export coming soon';

  @override
  String get characterCollectionHelpGuide => 'Character Collection Guide';

  @override
  String get characterCollectionHelpIntro => 'Character collection allows you to extract, edit, and manage characters from images. Here\'s a detailed guide:';

  @override
  String get characterCollectionHelpNotes => 'Notes';

  @override
  String get characterCollectionHelpSection1 => '1. Selection & Navigation';

  @override
  String get characterCollectionHelpSection2 => '2. Region Adjustment';

  @override
  String get characterCollectionHelpSection3 => '3. Eraser Tool';

  @override
  String get characterCollectionHelpSection4 => '4. Data Saving';

  @override
  String get characterCollectionHelpSection5 => '5. Keyboard Shortcuts';

  @override
  String get characterCollectionHelpTitle => 'Character Collection Help';

  @override
  String get characterCollectionImageInvalid => 'Image data is invalid or corrupted';

  @override
  String get characterCollectionImageLoadError => 'Failed to load image';

  @override
  String get characterCollectionLeave => 'Leave';

  @override
  String get characterCollectionLoadingImage => 'Loading image...';

  @override
  String get characterCollectionNextPage => 'Next Page';

  @override
  String get characterCollectionNoCharacter => 'No character';

  @override
  String get characterCollectionNoCharacters => 'No characters collected yet';

  @override
  String get characterCollectionPreviewTab => 'Character Preview';

  @override
  String get characterCollectionPreviousPage => 'Previous Page';

  @override
  String get characterCollectionProcessing => 'Processing...';

  @override
  String get characterCollectionResultsTab => 'Collection Results';

  @override
  String get characterCollectionRetry => 'Retry';

  @override
  String get characterCollectionReturnToDetails => 'Return to Work Details';

  @override
  String get characterCollectionSearchHint => 'Search characters...';

  @override
  String get characterCollectionSelectRegion => 'Please select character regions in the preview area';

  @override
  String get characterCollectionSwitchingPage => 'Switching to character page...';

  @override
  String get characterCollectionTitle => 'Character Collection';

  @override
  String get characterCollectionToolDelete => 'Delete selected (Ctrl+D)';

  @override
  String get characterCollectionToolPan => 'Pan tool (Ctrl+V)';

  @override
  String get characterCollectionToolSelect => 'Selection tool (Ctrl+B)';

  @override
  String get characterCollectionUnsavedChanges => 'Unsaved Changes';

  @override
  String get characterCollectionUnsavedChangesMessage => 'You have unsaved region modifications. Leaving will discard these changes.\n\nAre you sure you want to leave?';

  @override
  String get characterCollectionUseSelectionTool => 'Use the selection tool on the left to extract characters from the image';

  @override
  String get characterCount => 'Character Count';

  @override
  String get characterDetailAddTag => 'Add Tag';

  @override
  String get characterDetailAuthor => 'Author';

  @override
  String get characterDetailBasicInfo => 'Basic Information';

  @override
  String get characterDetailCalligraphyStyle => 'Calligraphy Style';

  @override
  String get characterDetailCollectionTime => 'Collection Time';

  @override
  String get characterDetailCreationTime => 'Creation Time';

  @override
  String get characterDetailFormatBinary => 'Binary';

  @override
  String get characterDetailFormatBinaryDesc => 'Black and white binary image';

  @override
  String get characterDetailFormatDescription => 'Description';

  @override
  String get characterDetailFormatExtension => 'File Format';

  @override
  String get characterDetailFormatName => 'Format Name';

  @override
  String get characterDetailFormatOriginal => 'Original';

  @override
  String get characterDetailFormatOriginalDesc => 'Unprocessed original image';

  @override
  String get characterDetailFormatOutline => 'Outline';

  @override
  String get characterDetailFormatOutlineDesc => 'Shows only the outline';

  @override
  String get characterDetailFormatSquareBinary => 'Square Binary';

  @override
  String get characterDetailFormatSquareBinaryDesc => 'Binary image normalized to square';

  @override
  String get characterDetailFormatSquareOutline => 'Square Outline';

  @override
  String get characterDetailFormatSquareOutlineDesc => 'Outline image normalized to square';

  @override
  String get characterDetailFormatSquareTransparent => 'Square Transparent';

  @override
  String get characterDetailFormatSquareTransparentDesc => 'Transparent PNG image normalized to square';

  @override
  String get characterDetailFormatThumbnail => 'Thumbnail';

  @override
  String get characterDetailFormatThumbnailDesc => 'Thumbnail image';

  @override
  String get characterDetailFormatTransparent => 'Transparent';

  @override
  String get characterDetailFormatTransparentDesc => 'Transparent PNG image with background removed';

  @override
  String get characterDetailFormatType => 'Type';

  @override
  String get characterDetailLoadError => 'Failed to load character details';

  @override
  String get characterDetailSimplifiedChar => 'Simplified Character';

  @override
  String characterDetailTagAddError(Object error) {
    return 'Failed to add tag, error: $error';
  }

  @override
  String get characterDetailTagHint => 'Enter tag name';

  @override
  String characterDetailTagRemoveError(Object error) {
    return 'Failed to remove tag, error: $error';
  }

  @override
  String get characterDetailTags => 'Tags';

  @override
  String get characterDetailUnknown => 'Unknown';

  @override
  String get characterDetailWorkInfo => 'Work Information';

  @override
  String get characterDetailWorkTitle => 'Work Title';

  @override
  String get characterDetailWritingTool => 'Writing Tool';

  @override
  String get characterEditCharacterUpdated => 'Character updated successfully';

  @override
  String get characterEditCompletingSave => 'Completing save...';

  @override
  String get characterEditImageInvert => 'Image Inversion';

  @override
  String get characterEditImageLoadError => 'Image Load Error';

  @override
  String get characterEditImageLoadFailed => 'Failed to load or process character image';

  @override
  String get characterEditInitializing => 'Initializing...';

  @override
  String get characterEditInputCharacter => 'Input Character';

  @override
  String get characterEditInputHint => 'Type here';

  @override
  String get characterEditInvertMode => 'Invert Mode';

  @override
  String get characterEditLoadingImage => 'Loading character image...';

  @override
  String get characterEditNoRegionSelected => 'No region selected';

  @override
  String get characterEditOnlyOneCharacter => 'Only one character allowed';

  @override
  String get characterEditPanImage => 'Pan image (hold Alt)';

  @override
  String get characterEditPleaseEnterCharacter => 'Please enter a character';

  @override
  String get characterEditPreparingSave => 'Preparing to save...';

  @override
  String get characterEditProcessingEraseData => 'Processing erase data...';

  @override
  String get characterEditProcessingImage => 'Processing image...';

  @override
  String get characterEditRedo => 'Redo';

  @override
  String get characterEditSaveComplete => 'Save complete';

  @override
  String characterEditSaveConfirmMessage(Object character) {
    return 'Confirm saving \"$character\"?';
  }

  @override
  String get characterEditSaveConfirmTitle => 'Save Character';

  @override
  String get characterEditSavePreview => 'Character preview:';

  @override
  String get characterEditSaveShortcuts => 'Press Enter to save, Esc to cancel';

  @override
  String get characterEditSaveTimeout => 'Save timed out';

  @override
  String get characterEditSavingToStorage => 'Saving to storage...';

  @override
  String get characterEditShowContour => 'Show Contour';

  @override
  String get characterEditThumbnailCheckFailed => 'Thumbnail check failed';

  @override
  String get characterEditThumbnailEmpty => 'Thumbnail file is empty';

  @override
  String get characterEditThumbnailLoadError => 'Failed to load thumbnail';

  @override
  String get characterEditThumbnailLoadFailed => 'Failed to load thumbnail';

  @override
  String get characterEditThumbnailNotFound => 'Thumbnail not found';

  @override
  String get characterEditThumbnailSizeError => 'Failed to get thumbnail size';

  @override
  String get characterEditUndo => 'Undo';

  @override
  String get characterEditUnknownError => 'Unknown error';

  @override
  String get characterEditValidChineseCharacter => 'Please enter a valid Chinese character';

  @override
  String get characterFilterAddTag => 'Add Tag';

  @override
  String get characterFilterAddTagHint => 'Enter tag name and press Enter';

  @override
  String get characterFilterCalligraphyStyle => 'Calligraphy Style';

  @override
  String get characterFilterCollapse => 'Collapse Filter Panel';

  @override
  String get characterFilterCollectionDate => 'Collection Date';

  @override
  String get characterFilterCreationDate => 'Creation Date';

  @override
  String get characterFilterExpand => 'Expand Filter Panel';

  @override
  String get characterFilterFavoritesOnly => 'Show favorites only';

  @override
  String get characterFilterSelectedTags => 'Selected Tags:';

  @override
  String get characterFilterSort => 'Sort';

  @override
  String get characterFilterTags => 'Tags';

  @override
  String get characterFilterTitle => 'Filter & Sort';

  @override
  String get characterFilterWritingTool => 'Writing Tool';

  @override
  String get characterManagementBatchDone => 'Done';

  @override
  String get characterManagementBatchMode => 'Batch Mode';

  @override
  String get characterManagementDeleteConfirm => 'Confirm Deletion';

  @override
  String get characterManagementDeleteMessage => 'Are you sure you want to delete the selected characters? This action cannot be undone.';

  @override
  String get characterManagementDeleteSelected => 'Delete selected';

  @override
  String characterManagementError(Object message) {
    return 'Error: $message';
  }

  @override
  String get characterManagementGridView => 'Grid View';

  @override
  String characterManagementItemsPerPage(Object count) {
    return '$count per page';
  }

  @override
  String get characterManagementListView => 'List View';

  @override
  String get characterManagementLoading => 'Loading characters...';

  @override
  String get characterManagementNoCharacters => 'No characters found';

  @override
  String get characterManagementNoCharactersHint => 'Try changing your search or filter criteria';

  @override
  String get characterManagementSearch => 'Search characters, works, or authors';

  @override
  String get characterManagementTitle => 'Character Management';

  @override
  String get characters => 'Characters';

  @override
  String get clearCache => 'Clear Cache';

  @override
  String get clearCacheConfirmMessage => 'Are you sure you want to clear all cached data? This will free up disk space but may slow down the application temporarily.';

  @override
  String get clearCacheConfirmTitle => 'Clear Cache';

  @override
  String get clearImageCache => 'Clear Image Cache';

  @override
  String get collection => 'Collection';

  @override
  String get collectionPropertyPanel => 'Collection Properties';

  @override
  String get collectionPropertyPanelAutoLineBreak => 'Auto Line Break';

  @override
  String get collectionPropertyPanelAutoLineBreakDisabled => 'Disable';

  @override
  String get collectionPropertyPanelAutoLineBreakEnabled => 'Enable';

  @override
  String get collectionPropertyPanelAutoLineBreakTooltip => 'Auto Line Break';

  @override
  String get collectionPropertyPanelAvailableCharacters => 'Available Characters';

  @override
  String get collectionPropertyPanelBackgroundColor => 'Background Color';

  @override
  String get collectionPropertyPanelBorder => 'Border';

  @override
  String get collectionPropertyPanelBorderColor => 'Border Color';

  @override
  String get collectionPropertyPanelBorderWidth => 'Border Width';

  @override
  String get collectionPropertyPanelCacheCleared => 'Image cache cleared';

  @override
  String get collectionPropertyPanelCacheClearFailed => 'Failed to clear image cache';

  @override
  String get collectionPropertyPanelCandidateCharacters => 'Candidate Characters';

  @override
  String get collectionPropertyPanelCharacter => 'Character';

  @override
  String get collectionPropertyPanelCharacterSettings => 'Character Settings';

  @override
  String get collectionPropertyPanelCharacterSource => 'Character Source';

  @override
  String get collectionPropertyPanelCharIndex => 'Character';

  @override
  String get collectionPropertyPanelClearImageCache => 'Clear Image Cache';

  @override
  String get collectionPropertyPanelColorInversion => 'Color Inversion';

  @override
  String get collectionPropertyPanelColorPicker => 'Pick Color';

  @override
  String get collectionPropertyPanelColorSettings => 'Color Setting';

  @override
  String get collectionPropertyPanelContent => 'Content Properties';

  @override
  String get collectionPropertyPanelCurrentCharInversion => 'Current Character Inversion';

  @override
  String get collectionPropertyPanelDisabled => 'Disabled';

  @override
  String get collectionPropertyPanelEnabled => 'Enabled';

  @override
  String get collectionPropertyPanelFlip => 'Flip';

  @override
  String get collectionPropertyPanelFlipHorizontally => 'Flip Horizontally';

  @override
  String get collectionPropertyPanelFlipVertically => 'Flip Vertically';

  @override
  String get collectionPropertyPanelFontSize => 'Font Size';

  @override
  String get collectionPropertyPanelGeometry => 'Geometry Properties';

  @override
  String get collectionPropertyPanelGlobalInversion => 'Global Inversion';

  @override
  String get collectionPropertyPanelHeaderContent => 'Content Properties';

  @override
  String get collectionPropertyPanelHeaderGeometry => 'Geometry Properties';

  @override
  String get collectionPropertyPanelHeaderVisual => 'Visual Properties';

  @override
  String get collectionPropertyPanelInvertDisplay => 'Invert Display Colors';

  @override
  String get collectionPropertyPanelNoCharacterSelected => 'No character selected';

  @override
  String get collectionPropertyPanelNoCharactersFound => 'No matching characters found';

  @override
  String get collectionPropertyPanelNoCharacterText => 'No character';

  @override
  String get collectionPropertyPanelOf => 'of';

  @override
  String get collectionPropertyPanelOpacity => 'Opacity';

  @override
  String get collectionPropertyPanelOriginal => 'Original';

  @override
  String get collectionPropertyPanelPadding => 'Padding';

  @override
  String get collectionPropertyPanelPropertyUpdated => 'Property updated';

  @override
  String get collectionPropertyPanelRender => 'Render Mode';

  @override
  String get collectionPropertyPanelReset => 'Reset';

  @override
  String get collectionPropertyPanelRotation => 'Rotation';

  @override
  String get collectionPropertyPanelScale => 'Scale';

  @override
  String get collectionPropertyPanelSearchInProgress => 'Searching characters...';

  @override
  String get collectionPropertyPanelSelectCharacter => 'Please select a character';

  @override
  String get collectionPropertyPanelSelectCharacterFirst => 'Please select a character first';

  @override
  String get collectionPropertyPanelSelectedCharacter => 'Selected Character';

  @override
  String get collectionPropertyPanelStyle => 'Style';

  @override
  String get collectionPropertyPanelStyled => 'Styled';

  @override
  String get collectionPropertyPanelTextSettings => 'Text Settings';

  @override
  String get collectionPropertyPanelUnknown => 'Unknown';

  @override
  String get collectionPropertyPanelVisual => 'Visual Settings';

  @override
  String get collectionPropertyPanelWorkSource => 'Work Source';

  @override
  String get commonProperties => 'Common Properties';

  @override
  String get confirm => 'Confirm';

  @override
  String get confirmDelete => 'Do you want to delete?';

  @override
  String get confirmDeleteCategory => 'Do you want to delete category';

  @override
  String get contains => 'Contains';

  @override
  String get contentSettings => 'Content Settings';

  @override
  String get create => 'Create';

  @override
  String get createBackup => 'Create Backup';

  @override
  String get createBackupDescription => 'Create a new backup of your data';

  @override
  String get creatingBackup => 'Creating backup...';

  @override
  String get customSize => 'Custom Size';

  @override
  String days(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days',
      one: '1 day',
    );
    return '$_temp0';
  }

  @override
  String get delete => 'Delete';

  @override
  String get deleteAll => 'Delete All';

  @override
  String get deleteBackup => 'Delete';

  @override
  String get deleteBackupConfirmMessage => 'Are you sure you want to delete this backup? This action cannot be undone.';

  @override
  String get deleteBackupConfirmTitle => 'Delete Backup';

  @override
  String get deleteCategory => 'Delete Category';

  @override
  String get deleteFailure => 'Failed to delete backup';

  @override
  String get deleteGroup => 'Delete Group';

  @override
  String get deleteGroupConfirm => 'Confirm Delete Group';

  @override
  String get deleteGroupDescription => 'Are you sure you want to delete this group? This action cannot be undone.';

  @override
  String get deleteGroupElements => 'Delete Group Elements';

  @override
  String get deletePage => 'Delete Page';

  @override
  String get deleteSuccess => 'Backup deleted successfully';

  @override
  String get dimensions => 'Dimensions';

  @override
  String get diskCacheSize => 'Disk Cache Size';

  @override
  String get diskCacheSizeDescription => 'Maximum size of disk cache';

  @override
  String get diskCacheTtl => 'Disk Cache Lifetime';

  @override
  String get diskCacheTtlDescription => 'How long to keep cached files on disk';

  @override
  String get distributeHorizontally => 'Distribute Horizontally';

  @override
  String get distributeVertically => 'Distribute Vertically';

  @override
  String get distribution => 'Distribution';

  @override
  String get distributionOperations => 'Distribution Operations';

  @override
  String get distributionRequiresThreeElements => 'Distribution requires at least 3 elements';

  @override
  String get dpiHelperText => 'Used to calculate canvas pixel size, default is 300dpi';

  @override
  String get dpiSetting => 'DPI Setting (dots per inch)';

  @override
  String get edit => 'Edit';

  @override
  String get editCategory => 'Edit Category';

  @override
  String get editGroupContents => 'Edit Group Contents';

  @override
  String get editGroupContentsDescription => 'Edit the contents of the selected group';

  @override
  String get elementDistribution => 'Element Distribution';

  @override
  String get elementId => 'Element ID';

  @override
  String get elements => 'Elements';

  @override
  String get elementType => 'Element Type';

  @override
  String get empty => 'Empty';

  @override
  String get enterFileName => 'Enter file name';

  @override
  String get enterGroupEditMode => 'Enter Group Edit Mode';

  @override
  String get exitBatchMode => 'Exit Batch Mode';

  @override
  String get export => 'Export';

  @override
  String get exportBackup => 'Export Backup';

  @override
  String get exportBackupDescription => 'Export a backup to an external location';

  @override
  String get exportDialogAllPages => 'All Pages';

  @override
  String get exportDialogBrowse => 'Browse...';

  @override
  String get exportDialogCentimeter => 'cm';

  @override
  String get exportDialogCreateDirectoryFailed => 'Failed to create export directory';

  @override
  String get exportDialogCurrentPage => 'Current Page';

  @override
  String get exportDialogCustomRange => 'Custom Range';

  @override
  String exportDialogDimensions(Object height, Object orientation, Object width) {
    return '${width}cm × ${height}cm ($orientation)';
  }

  @override
  String get exportDialogEnterFilename => 'Please enter a filename';

  @override
  String get exportDialogFilenamePrefix => 'Enter filename prefix (page numbers will be added automatically)';

  @override
  String get exportDialogFitContain => 'Contain in Page';

  @override
  String get exportDialogFitHeight => 'Fit to Height';

  @override
  String get exportDialogFitPolicy => 'Fit Policy';

  @override
  String get exportDialogFitWidth => 'Fit to Width';

  @override
  String get exportDialogInvalidFilename => 'Filename cannot contain the following characters: \\ / : * ? \" < > |';

  @override
  String get exportDialogLandscape => 'Landscape';

  @override
  String get exportDialogLocation => 'Export Location';

  @override
  String get exportDialogMarginBottom => 'Bottom';

  @override
  String get exportDialogMarginLeft => 'Left';

  @override
  String get exportDialogMarginRight => 'Right';

  @override
  String get exportDialogMarginTop => 'Top';

  @override
  String exportDialogMultipleFilesNote(Object count) {
    return 'Note: Will export $count image files, filenames will be automatically numbered.';
  }

  @override
  String get exportDialogNextPage => 'Next Page';

  @override
  String get exportDialogNoPreview => 'Cannot generate preview';

  @override
  String get exportDialogOutputQuality => 'Output Quality';

  @override
  String get exportDialogPageMargins => 'Page Margins (cm)';

  @override
  String get exportDialogPageOrientation => 'Page Orientation';

  @override
  String get exportDialogPageRange => 'Page Range';

  @override
  String get exportDialogPageSize => 'Page Size';

  @override
  String get exportDialogPortrait => 'Portrait';

  @override
  String get exportDialogPreview => 'Preview';

  @override
  String exportDialogPreviewPage(Object current, Object total) {
    return ' (Page $current/$total)';
  }

  @override
  String get exportDialogPreviousPage => 'Previous Page';

  @override
  String get exportDialogQualityHigh => 'High (2x)';

  @override
  String get exportDialogQualityStandard => 'Standard (1x)';

  @override
  String get exportDialogQualityUltra => 'Ultra (3x)';

  @override
  String get exportDialogRangeExample => 'Example: 1-3,5,7-9';

  @override
  String get exportDialogSelectLocation => 'Please select export location';

  @override
  String get exportFailure => 'Failed to export backup';

  @override
  String get exportFormat => 'Export Format';

  @override
  String get exportingBackup => 'Exporting backup...';

  @override
  String get exportSuccess => 'Backup exported successfully';

  @override
  String get fileCount => 'File Count';

  @override
  String get fileName => 'File Name';

  @override
  String get files => 'File Count';

  @override
  String get filterApply => 'Apply';

  @override
  String get filterBatchActions => 'Batch Actions';

  @override
  String get filterBatchSelection => 'Selection';

  @override
  String get filterClear => 'Clear';

  @override
  String get filterCollapse => 'Collapse Filter Panel';

  @override
  String get filterCustomRange => 'Custom Range';

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
  String get filterDateRange => 'Date Range';

  @override
  String get filterDateSection => 'Creation Time';

  @override
  String get filterDateSelectPrompt => 'Select Date';

  @override
  String get filterDateStartDate => 'Start Date';

  @override
  String get filterDeselectAll => 'Deselect All';

  @override
  String get filterEndDate => 'End Date';

  @override
  String get filterExpand => 'Expand Filter Panel';

  @override
  String get filterFavoritesOnly => 'Show favorites only';

  @override
  String get filterHeader => 'Filter & Sort';

  @override
  String filterItemsPerPage(Object count) {
    return '$count per page';
  }

  @override
  String filterItemsSelected(Object count) {
    return '$count selected';
  }

  @override
  String get filterMax => 'Max';

  @override
  String get filterMin => 'Min';

  @override
  String get filterPanel => 'Filter Panel';

  @override
  String get filterPresetSection => 'Presets';

  @override
  String get filterReset => 'Reset All Filters';

  @override
  String get filterSearchPlaceholder => 'Search...';

  @override
  String get filterSection => 'Filter Options';

  @override
  String get filterSelectAll => 'Select All';

  @override
  String get filterSelectDate => 'Select Date';

  @override
  String get filterSelectDateRange => 'Select date range';

  @override
  String get filterSortAscending => 'Ascending';

  @override
  String get filterSortDescending => 'Descending';

  @override
  String get filterSortDirection => 'Sort Direction';

  @override
  String get filterSortField => 'Sort By';

  @override
  String get filterSortFieldAuthor => 'Author';

  @override
  String get filterSortFieldCreateTime => 'Creation Time';

  @override
  String get filterSortFieldCreationDate => 'Creation Date';

  @override
  String get filterSortFieldFileName => 'File Name';

  @override
  String get filterSortFieldFileSize => 'File Size';

  @override
  String get filterSortFieldFileUpdatedAt => 'File Update Time';

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
  String get filterStartDate => 'Start Date';

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
  String get filterStyleSection => 'Style';

  @override
  String get filterTagsAdd => 'Add Tag';

  @override
  String get filterTagsAddHint => 'Enter tag name and press Enter';

  @override
  String get filterTagsNone => 'No tags selected';

  @override
  String get filterTagsSection => 'Tags';

  @override
  String get filterTagsSelected => 'Selected Tags:';

  @override
  String get filterTagsSuggested => 'Suggested tags:';

  @override
  String get filterTitle => 'Filter & Sort';

  @override
  String get filterToggle => 'Toggle Filters';

  @override
  String get filterToolBrush => 'Brush';

  @override
  String get filterToolHardPen => 'Hard Pen';

  @override
  String get filterToolOther => 'Other';

  @override
  String get filterToolSection => 'Tool';

  @override
  String filterTotalItems(Object count) {
    return 'Total: $count items';
  }

  @override
  String get generalSettings => 'General Settings';

  @override
  String get geometryProperties => 'Geometry Properties';

  @override
  String get gridSettings => 'Grid Settings';

  @override
  String get gridSize => 'Grid Size';

  @override
  String get gridView => 'Grid View';

  @override
  String get group => 'Group';

  @override
  String get groupElements => 'Group Elements';

  @override
  String get groupInfo => 'Group Info';

  @override
  String get groupOperations => 'Group Operations';

  @override
  String get height => 'Height';

  @override
  String get hideElement => 'Hide Element';

  @override
  String get horizontalAlignment => 'Horizontal Alignment';

  @override
  String get horizontalLeftToRight => 'Horizontal Left-to-Right';

  @override
  String get horizontalRightToLeft => 'Horizontal Right-to-Left';

  @override
  String hours(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count hours',
      one: '1 hour',
    );
    return '$_temp0';
  }

  @override
  String get image => 'Image';

  @override
  String get imageCacheCleared => 'Image cache cleared';

  @override
  String get imageCacheClearFailed => 'Failed to clear image cache';

  @override
  String get imagePropertyPanel => 'Image Properties';

  @override
  String get imagePropertyPanelApplyTransform => 'Apply Transform';

  @override
  String get imagePropertyPanelAutoImportNotice => 'The selected image will be automatically imported into your library for better management';

  @override
  String get imagePropertyPanelBorder => 'Border';

  @override
  String get imagePropertyPanelBorderColor => 'Border Color';

  @override
  String get imagePropertyPanelBorderWidth => 'Border Width';

  @override
  String get imagePropertyPanelBrightness => 'Brightness';

  @override
  String get imagePropertyPanelCannotApplyNoImage => 'Cannot apply transform: No image set';

  @override
  String get imagePropertyPanelCannotApplyNoSizeInfo => 'Cannot apply transform: Image size info not available';

  @override
  String get imagePropertyPanelContent => 'Content Properties';

  @override
  String get imagePropertyPanelContrast => 'Contrast';

  @override
  String get imagePropertyPanelCornerRadius => 'Corner Radius';

  @override
  String get imagePropertyPanelCropBottom => 'Bottom Crop';

  @override
  String get imagePropertyPanelCropLeft => 'Left Crop';

  @override
  String get imagePropertyPanelCropping => 'Cropping';

  @override
  String imagePropertyPanelCroppingApplied(Object bottom, Object left, Object right, Object top) {
    return ' (Cropping: Left ${left}px, Top ${top}px, Right ${right}px, Bottom ${bottom}px)';
  }

  @override
  String get imagePropertyPanelCroppingValueTooLarge => 'Cannot apply transform: Cropping values too large resulting in invalid crop region';

  @override
  String get imagePropertyPanelCropRight => 'Right Crop';

  @override
  String get imagePropertyPanelCropTop => 'Top Crop';

  @override
  String get imagePropertyPanelDimensions => 'Dimensions';

  @override
  String get imagePropertyPanelDisplay => 'Display Mode';

  @override
  String imagePropertyPanelFileNotExist(Object path) {
    return 'File does not exist: $path';
  }

  @override
  String get imagePropertyPanelFileNotRecovered => 'File could not be recovered';

  @override
  String get imagePropertyPanelFileRestored => 'File restored';

  @override
  String get imagePropertyPanelFilters => 'Image Filters';

  @override
  String get imagePropertyPanelFit => 'Fit';

  @override
  String get imagePropertyPanelFitContain => 'Contain';

  @override
  String get imagePropertyPanelFitCover => 'Cover';

  @override
  String get imagePropertyPanelFitFill => 'Fill';

  @override
  String get imagePropertyPanelFitMode => 'Fit Mode';

  @override
  String get imagePropertyPanelFitNone => 'None';

  @override
  String get imagePropertyPanelFitOriginal => 'Original';

  @override
  String get imagePropertyPanelFlip => 'Flip';

  @override
  String get imagePropertyPanelFlipHorizontal => 'Flip Horizontal';

  @override
  String get imagePropertyPanelFlipVertical => 'Flip Vertical';

  @override
  String get imagePropertyPanelGeometry => 'Geometry Properties';

  @override
  String get imagePropertyPanelGeometryWarning => 'These properties adjust the entire element box, not the image content itself';

  @override
  String get imagePropertyPanelImageSelection => 'Image Selection';

  @override
  String get imagePropertyPanelImageSize => 'Image Size';

  @override
  String get imagePropertyPanelImageTransform => 'Image Transform';

  @override
  String imagePropertyPanelImportError(Object error) {
    return 'Failed to import image: $error';
  }

  @override
  String get imagePropertyPanelImporting => 'Importing image...';

  @override
  String get imagePropertyPanelImportSuccess => 'Image imported successfully';

  @override
  String get imagePropertyPanelLibraryProcessing => 'Processing library...';

  @override
  String imagePropertyPanelLoadError(Object error) {
    return 'Failed to load image: $error...';
  }

  @override
  String get imagePropertyPanelNoCropping => ' (No cropping, other transforms applied)';

  @override
  String get imagePropertyPanelNoImage => 'No image selected';

  @override
  String get imagePropertyPanelNoImageSelected => 'No image selected';

  @override
  String get imagePropertyPanelOpacity => 'Opacity';

  @override
  String get imagePropertyPanelOriginalSize => 'Original Size';

  @override
  String get imagePropertyPanelPosition => 'Position';

  @override
  String get imagePropertyPanelPreserveRatio => 'Preserve Aspect Ratio';

  @override
  String get imagePropertyPanelPreview => 'Image Preview';

  @override
  String get imagePropertyPanelPreviewNotice => 'Note: Duplicate logs shown during preview are normal';

  @override
  String imagePropertyPanelProcessingPathError(Object error) {
    return 'Processing path error: $error';
  }

  @override
  String get imagePropertyPanelReset => 'Reset';

  @override
  String get imagePropertyPanelResetSuccess => 'All transforms reset';

  @override
  String get imagePropertyPanelResetTransform => 'Reset Transform';

  @override
  String get imagePropertyPanelRotation => 'Rotation';

  @override
  String get imagePropertyPanelSaturation => 'Saturation';

  @override
  String get imagePropertyPanelSelectFromLibrary => 'Select from Library';

  @override
  String get imagePropertyPanelSelectFromLocal => 'Select from Local';

  @override
  String get imagePropertyPanelTransformApplied => 'Transform applied';

  @override
  String imagePropertyPanelTransformError(Object error) {
    return 'Failed to apply transform: $error';
  }

  @override
  String get imagePropertyPanelTransformWarning => 'These transforms modify the image content itself, not just the element frame';

  @override
  String get imagePropertyPanelVisual => 'Visual Settings';

  @override
  String get import => 'Import';

  @override
  String get importBackup => 'Import Backup';

  @override
  String get importBackupDescription => 'Import a backup from an external location';

  @override
  String get importFailure => 'Failed to import backup';

  @override
  String get importingBackup => 'Importing backup...';

  @override
  String get importSuccess => 'Backup imported successfully';

  @override
  String initializationFailed(Object error) {
    return 'Initialization failed: $error';
  }

  @override
  String get invalidBackupFile => 'Invalid backup file';

  @override
  String get keepBackupCount => 'Keep Backup Count';

  @override
  String get keepBackupCountDescription => 'Number of backups to keep before deleting old ones';

  @override
  String get landscape => 'Landscape';

  @override
  String get language => 'Language';

  @override
  String get languageEn => 'English';

  @override
  String get languageSystem => 'System';

  @override
  String get languageZh => '简体中文';

  @override
  String get lastBackupTime => 'Last Backup Time';

  @override
  String get layer => 'Layer';

  @override
  String get layer1 => 'Layer 1';

  @override
  String get layerElements => 'Layer Elements';

  @override
  String get layerInfo => 'Layer Information';

  @override
  String get layerName => 'Layer Name';

  @override
  String get layerOperations => 'Layer Operations';

  @override
  String get libraryCount => 'Library Count';

  @override
  String get libraryManagement => 'Library';

  @override
  String get libraryManagementBasicInfo => 'Basic Information';

  @override
  String get libraryManagementCategories => 'Categories';

  @override
  String get libraryManagementCreatedAt => 'Created at';

  @override
  String get libraryManagementDeleteConfirm => 'Confirm deletion';

  @override
  String get libraryManagementDeleteMessage => 'Are you sure you want to delete the selected items? This action cannot be undone.';

  @override
  String get libraryManagementDeleteSelected => 'Delete selected items';

  @override
  String get libraryManagementDetail => 'Details';

  @override
  String get libraryManagementEnterBatchMode => 'Enter batch mode';

  @override
  String libraryManagementError(String message) {
    return 'Failed to load: $message';
  }

  @override
  String get libraryManagementExitBatchMode => 'Exit batch mode';

  @override
  String get libraryManagementFavorite => 'Favorite';

  @override
  String get libraryManagementFavorites => 'Favorites';

  @override
  String get libraryManagementFileSize => 'File size';

  @override
  String get libraryManagementFormat => 'Format';

  @override
  String get libraryManagementFormats => 'File Formats';

  @override
  String get libraryManagementGridView => 'Grid view';

  @override
  String get libraryManagementImport => 'Import';

  @override
  String get libraryManagementImportFiles => 'Import Files';

  @override
  String get libraryManagementImportFolder => 'Import Folder';

  @override
  String get libraryManagementListView => 'List view';

  @override
  String get libraryManagementLoading => 'Loading...';

  @override
  String get libraryManagementMetadata => 'Metadata';

  @override
  String get libraryManagementName => 'Name';

  @override
  String get libraryManagementNoItems => 'No items';

  @override
  String get libraryManagementNoItemsHint => 'Try adding some items or changing filters';

  @override
  String get libraryManagementNoRemarks => 'No remarks';

  @override
  String get libraryManagementPath => 'Path';

  @override
  String get libraryManagementRemarks => 'Remarks';

  @override
  String get libraryManagementRemarksHint => 'Add remarks';

  @override
  String get libraryManagementResolution => 'Resolution';

  @override
  String get libraryManagementSearch => 'Search items...';

  @override
  String get libraryManagementSize => 'Size';

  @override
  String get libraryManagementSortBy => 'Sort by';

  @override
  String get libraryManagementSortByDate => 'Date';

  @override
  String get libraryManagementSortByFileSize => 'File Size';

  @override
  String get libraryManagementSortByName => 'Name';

  @override
  String get libraryManagementSortBySize => 'File size';

  @override
  String get libraryManagementSortDesc => 'Sort Order';

  @override
  String get libraryManagementTags => 'Tags';

  @override
  String get libraryManagementTimeInfo => 'Time Information';

  @override
  String get libraryManagementType => 'Type';

  @override
  String get libraryManagementTypes => 'Types';

  @override
  String get libraryManagementUpdatedAt => 'Updated at';

  @override
  String get listView => 'List View';

  @override
  String get loadFailed => 'Load Failed';

  @override
  String get loadingError => 'Loading Error';

  @override
  String get locked => 'Locked';

  @override
  String get lockElement => 'Lock Element';

  @override
  String get lockStatus => 'Lock Status';

  @override
  String get lockUnlockAllElements => 'Lock/Unlock All Elements';

  @override
  String get memoryDataCacheCapacity => 'Memory Data Cache Capacity';

  @override
  String get memoryDataCacheCapacityDescription => 'Number of data items to keep in memory';

  @override
  String get memoryImageCacheCapacity => 'Memory Image Cache Capacity';

  @override
  String get memoryImageCacheCapacityDescription => 'Number of images to keep in memory';

  @override
  String get moveDown => 'Move Down';

  @override
  String get moveLayerDown => 'Move Layer Down';

  @override
  String get moveLayerUp => 'Move Layer Up';

  @override
  String get moveSelectedElementsToLayer => 'Move Selected Elements to Layer';

  @override
  String get moveUp => 'Move Up';

  @override
  String get name => 'Name';

  @override
  String get navCollapseSidebar => 'Collapse Sidebar';

  @override
  String get navExpandSidebar => 'Expand Sidebar';

  @override
  String get newCategory => 'New Category';

  @override
  String get no => 'No';

  @override
  String get noBackups => 'No backups available';

  @override
  String get noCategories => 'No Categories';

  @override
  String get noElementsInLayer => 'No elements in this layer';

  @override
  String get noElementsSelected => 'No elements selected';

  @override
  String get noPageSelected => 'No page selected';

  @override
  String get noTags => 'No Tags';

  @override
  String get ok => 'OK';

  @override
  String get opacity => 'Opacity';

  @override
  String get pageOrientation => 'Page Orientation';

  @override
  String get pageSize => 'Page Size';

  @override
  String get pixels => 'pixels';

  @override
  String get portrait => 'Portrait';

  @override
  String get position => 'Position';

  @override
  String get practiceEditAddElementTitle => 'Add Element';

  @override
  String get practiceEditAddLayer => 'Add Layer';

  @override
  String get practiceEditBackToHome => 'Back to Home';

  @override
  String get practiceEditBringToFront => 'Bring to Front (Ctrl+T)';

  @override
  String get practiceEditCannotSaveNoPages => 'Cannot save: Practice has no pages';

  @override
  String get practiceEditCollection => 'Collection';

  @override
  String get practiceEditCollectionProperties => 'Collection Properties';

  @override
  String get practiceEditConfirmDeleteMessage => 'Are you sure you want to delete these elements?';

  @override
  String get practiceEditConfirmDeleteTitle => 'Confirm Delete';

  @override
  String get practiceEditContentProperties => 'Content Properties';

  @override
  String get practiceEditContentTools => 'Content Tools';

  @override
  String get practiceEditCopy => 'Copy (Ctrl+Shift+C)';

  @override
  String get practiceEditDangerZone => 'Danger Zone';

  @override
  String get practiceEditDelete => 'Delete (Ctrl+D)';

  @override
  String get practiceEditDeleteLayer => 'Delete Layer';

  @override
  String get practiceEditDeleteLayerConfirm => 'Are you sure you want to delete this layer?';

  @override
  String get practiceEditDeleteLayerMessage => 'All elements on this layer will be deleted. This action cannot be undone.';

  @override
  String get practiceEditDisableSnap => 'Disable Snap (Ctrl+R)';

  @override
  String get practiceEditEditOperations => 'Edit Operations';

  @override
  String get practiceEditEditTitle => 'Edit Title';

  @override
  String get practiceEditElementProperties => 'Element Properties';

  @override
  String get practiceEditElements => 'Elements';

  @override
  String practiceEditElementSelectionInfo(Object count) {
    return '$count elements selected';
  }

  @override
  String get practiceEditEnableSnap => 'Enable Snap (Ctrl+R)';

  @override
  String get practiceEditEnterTitle => 'Please enter a practice title';

  @override
  String get practiceEditExit => 'Exit';

  @override
  String get practiceEditGeometryProperties => 'Geometry Properties';

  @override
  String get practiceEditGroup => 'Group (Ctrl+J)';

  @override
  String get practiceEditGroupProperties => 'Group Properties';

  @override
  String get practiceEditHelperFunctions => 'Helper Functions';

  @override
  String get practiceEditHideGrid => 'Hide Grid (Ctrl+G)';

  @override
  String get practiceEditImage => 'Image';

  @override
  String get practiceEditImageProperties => 'Image Properties';

  @override
  String get practiceEditLayerOperations => 'Layer Operations';

  @override
  String get practiceEditLayerPanel => 'Layers';

  @override
  String get practiceEditLayerProperties => 'Layer Properties';

  @override
  String get practiceEditLeave => 'Leave';

  @override
  String practiceEditLoadFailed(Object error) {
    return 'Failed to load practice: $error';
  }

  @override
  String get practiceEditMoveDown => 'Move Down (Ctrl+Shift+B)';

  @override
  String get practiceEditMoveUp => 'Move Up (Ctrl+Shift+T)';

  @override
  String get practiceEditMultiSelectionProperties => 'Multi-Selection Properties';

  @override
  String get practiceEditNoLayers => 'No layers, please add a layer';

  @override
  String get practiceEditOverwrite => 'Overwrite';

  @override
  String get practiceEditPageProperties => 'Page Properties';

  @override
  String get practiceEditPaste => 'Paste (Ctrl+Shift+V)';

  @override
  String practiceEditPracticeLoaded(Object title) {
    return 'Practice \"$title\" loaded successfully';
  }

  @override
  String get practiceEditPracticeLoadFailed => 'Failed to load practice: Practice does not exist or has been deleted';

  @override
  String get practiceEditPracticeTitle => 'Practice Title';

  @override
  String get practiceEditPropertyPanel => 'Properties';

  @override
  String get practiceEditSaveAndExit => 'Save & Exit';

  @override
  String get practiceEditSaveAndLeave => 'Save & Leave';

  @override
  String get practiceEditSaveFailed => 'Save failed';

  @override
  String get practiceEditSavePractice => 'Save Practice';

  @override
  String get practiceEditSaveSuccess => 'Save successful';

  @override
  String get practiceEditSelect => 'Select';

  @override
  String get practiceEditSendToBack => 'Send to Back (Ctrl+B)';

  @override
  String get practiceEditShowGrid => 'Show Grid (Ctrl+G)';

  @override
  String get practiceEditText => 'Text';

  @override
  String get practiceEditTextProperties => 'Text Properties';

  @override
  String get practiceEditTitle => 'Practice Edit';

  @override
  String get practiceEditTitleExists => 'Title Exists';

  @override
  String get practiceEditTitleExistsMessage => 'A practice with this title already exists. Do you want to overwrite it?';

  @override
  String practiceEditTitleUpdated(Object title) {
    return 'Title updated to \"$title\"';
  }

  @override
  String get practiceEditToolbar => 'Edit Toolbar';

  @override
  String get practiceEditTopNavBack => 'Back';

  @override
  String get practiceEditTopNavExitPreview => 'Exit Preview Mode';

  @override
  String get practiceEditTopNavExport => 'Export';

  @override
  String get practiceEditTopNavHideThumbnails => 'Hide Page Thumbnails';

  @override
  String get practiceEditTopNavPreviewMode => 'Preview Mode';

  @override
  String get practiceEditTopNavRedo => 'Redo';

  @override
  String get practiceEditTopNavSave => 'Save';

  @override
  String get practiceEditTopNavSaveAs => 'Save As';

  @override
  String get practiceEditTopNavShowThumbnails => 'Show Page Thumbnails';

  @override
  String get practiceEditTopNavUndo => 'Undo';

  @override
  String get practiceEditUngroup => 'Ungroup (Ctrl+U)';

  @override
  String get practiceEditUnsavedChanges => 'Unsaved Changes';

  @override
  String get practiceEditUnsavedChangesExitConfirmation => 'You have unsaved changes. Are you sure you want to exit?';

  @override
  String get practiceEditUnsavedChangesMessage => 'You have unsaved changes. Are you sure you want to leave?';

  @override
  String get practiceEditVisualProperties => 'Visual Properties';

  @override
  String get practiceListBatchDone => 'Done';

  @override
  String get practiceListBatchMode => 'Batch Mode';

  @override
  String get practiceListCollapseFilter => 'Collapse Filter Panel';

  @override
  String get practiceListDeleteConfirm => 'Confirm Deletion';

  @override
  String get practiceListDeleteMessage => 'Are you sure you want to delete the selected practice sheets? This action cannot be undone.';

  @override
  String get practiceListDeleteSelected => 'Delete Selected';

  @override
  String get practiceListError => 'Error loading practice sheets';

  @override
  String get practiceListExpandFilter => 'Expand Filter Panel';

  @override
  String get practiceListFilterFavorites => 'Favorites';

  @override
  String get practiceListFilterTitle => 'Filter & Sort ';

  @override
  String get practiceListGridView => 'Grid View';

  @override
  String practiceListItemsPerPage(Object count) {
    return '$count per page';
  }

  @override
  String get practiceListListView => 'List View';

  @override
  String get practiceListLoading => 'Loading practice sheets...';

  @override
  String get practiceListNewPractice => 'New Practice Sheet';

  @override
  String get practiceListNoResults => 'No practice sheets found';

  @override
  String get practiceListPages => 'pages';

  @override
  String get practiceListResetFilter => 'Reset Filter';

  @override
  String get practiceListSearch => 'Search practice sheets...';

  @override
  String get practiceListSortByCreateTime => 'Sort by Creation Time';

  @override
  String get practiceListSortByStatus => 'Sort by Status';

  @override
  String get practiceListSortByTitle => 'Sort by Title';

  @override
  String get practiceListSortByUpdateTime => 'Sort by Update Time';

  @override
  String get practiceListStatus => 'Status';

  @override
  String get practiceListStatusAll => 'All';

  @override
  String get practiceListStatusCompleted => 'Completed';

  @override
  String get practiceListStatusDraft => 'Draft';

  @override
  String get practiceListThumbnailError => 'Thumbnail load failed';

  @override
  String get practiceListTitle => 'Practice Sheets';

  @override
  String practiceListTotalItems(Object count) {
    return '$count practice sheets';
  }

  @override
  String get practicePageSettings => 'Page Settings';

  @override
  String get practices => 'Practices';

  @override
  String get presetSize => 'Preset Size';

  @override
  String get preview => 'Preview';

  @override
  String get previewText => 'Preview';

  @override
  String get print => 'Print';

  @override
  String get removedFromAllCategories => 'Removed from all categories';

  @override
  String get rename => 'Rename';

  @override
  String get resetSettingsConfirmMessage => 'Are you sure you want to reset all cache settings to default values?';

  @override
  String get resetSettingsConfirmTitle => 'Reset Settings';

  @override
  String get resetToDefaults => 'Reset to Defaults';

  @override
  String get restartAfterRestored => 'Note: The application will automatically restart after restoration is complete';

  @override
  String get restartAppRequired => 'The application needs to be restarted to complete the restore process.';

  @override
  String get restartLater => 'Later';

  @override
  String get restartNow => 'Restart Now';

  @override
  String get restore => 'Restore';

  @override
  String get restoreBackup => 'Restore Backup';

  @override
  String get restoreConfirmMessage => 'Are you sure you want to restore from this backup? This will replace all your current data.';

  @override
  String get restoreConfirmTitle => 'Restore Confirmation';

  @override
  String get restoreFailure => 'Failed to restore from backup';

  @override
  String get restoreSuccess => 'Restore completed successfully';

  @override
  String get restoringBackup => 'Restoring from backup...';

  @override
  String get rotation => 'Rotation';

  @override
  String get save => 'Save';

  @override
  String get searchCategories => 'Search categories...';

  @override
  String get searchCharactersWorksAuthors => 'Search characters, works, or authors';

  @override
  String get selectBackup => 'Select Backup';

  @override
  String get selectCollection => 'Select Collection';

  @override
  String get selected => 'Selected';

  @override
  String selectedCount(Object count) {
    return '$count selected';
  }

  @override
  String get selectExportLocation => 'Select Export Location';

  @override
  String get selectImportFile => 'Select Backup File';

  @override
  String get selectTargetLayer => 'Select Target Layer';

  @override
  String get sendLayerToBack => 'Send Layer to Back';

  @override
  String get sendToBack => 'Send to Back';

  @override
  String get settings => 'Settings';

  @override
  String get settingsResetMessage => 'Settings reset to defaults';

  @override
  String get showElement => 'Show Element';

  @override
  String get showGrid => 'Show Grid';

  @override
  String get showHideAllElements => 'Show/Hide All Elements';

  @override
  String get sortAndFilter => 'Sort & Filter';

  @override
  String get stateAndDisplay => 'State & Display';

  @override
  String get storageDetails => 'Storage Details';

  @override
  String get storageLocation => 'Storage Location';

  @override
  String get storageSettings => 'Storage Settings';

  @override
  String get storageUsed => 'Storage Used';

  @override
  String get tagEditorEnterTagHint => 'Type a tag and press Enter';

  @override
  String get tagEditorNoTags => 'No tags';

  @override
  String get tagEditorSuggestedTags => 'Suggested tags:';

  @override
  String get tagsHint => 'Enter tags...';

  @override
  String get text => 'Text';

  @override
  String get textPropertyPanel => 'Text Properties';

  @override
  String get textPropertyPanelBgColor => 'Background Color';

  @override
  String get textPropertyPanelDimensions => 'Dimensions';

  @override
  String get textPropertyPanelFontColor => 'Text Color';

  @override
  String get textPropertyPanelFontFamily => 'Font Family';

  @override
  String get textPropertyPanelFontSize => 'Font Size';

  @override
  String get textPropertyPanelFontStyle => 'Font Style';

  @override
  String get textPropertyPanelFontWeight => 'Font Weight';

  @override
  String get textPropertyPanelGeometry => 'Geometry Properties';

  @override
  String get textPropertyPanelHorizontal => 'Horizontal';

  @override
  String get textPropertyPanelLetterSpacing => 'Letter Spacing';

  @override
  String get textPropertyPanelLineHeight => 'Line Height';

  @override
  String get textPropertyPanelLineThrough => 'Line Through';

  @override
  String get textPropertyPanelOpacity => 'Opacity';

  @override
  String get textPropertyPanelPadding => 'Padding';

  @override
  String get textPropertyPanelPosition => 'Position';

  @override
  String get textPropertyPanelPreview => 'Preview';

  @override
  String get textPropertyPanelTextAlign => 'Text Align';

  @override
  String get textPropertyPanelTextContent => 'Text Content';

  @override
  String get textPropertyPanelTextSettings => 'Text Settings';

  @override
  String get textPropertyPanelUnderline => 'Underline';

  @override
  String get textPropertyPanelVertical => 'Vertical';

  @override
  String get textPropertyPanelVerticalAlign => 'Vertical Align';

  @override
  String get textPropertyPanelVisual => 'Visual Settings';

  @override
  String get textPropertyPanelWritingMode => 'Writing Mode';

  @override
  String get textureApplicationRange => 'Texture Application Range';

  @override
  String get textureFillMode => 'Fill Mode';

  @override
  String get textureFillModeContain => 'Contain';

  @override
  String get textureFillModeCover => 'Cover';

  @override
  String get textureFillModeNoRepeat => 'No Repeat';

  @override
  String get textureFillModeRepeat => 'Repeat';

  @override
  String get textureFillModeRepeatX => 'Repeat Horizontally';

  @override
  String get textureFillModeRepeatY => 'Repeat Vertically';

  @override
  String get textureOpacity => 'Texture Opacity';

  @override
  String get textureRangeBackground => 'Entire Background';

  @override
  String get textureRangeCharacter => 'Character Only';

  @override
  String get textureRemove => 'Remove';

  @override
  String get textureSelectFromLibrary => 'Select from Library';

  @override
  String get themeMode => 'Theme Mode';

  @override
  String get themeModeDark => 'Dark';

  @override
  String get themeModeDescription => 'Use dark theme for better night viewing';

  @override
  String get themeModeLight => 'Light';

  @override
  String get themeModeSystem => 'System';

  @override
  String get themeModeSystemDescription => 'Automatically switch between light/dark modes based on system settings';

  @override
  String get toggleTestText => 'Toggle Test Text';

  @override
  String get total => 'Total';

  @override
  String totalItems(Object count) {
    return 'Total: $count';
  }

  @override
  String get ungroup => 'Ungroup';

  @override
  String get ungroupConfirm => 'Confirm Ungroup';

  @override
  String get ungroupDescription => 'Ungroup the selected group';

  @override
  String get unknownCategory => 'Unknown Category';

  @override
  String get unlocked => 'Unlocked';

  @override
  String get unlockElement => 'Unlock Element';

  @override
  String get unnamedElement => 'Unnamed Element';

  @override
  String get unnamedGroup => 'Unnamed Group';

  @override
  String get unnamedLayer => 'Unnamed Layer';

  @override
  String get verticalAlignment => 'Vertical Alignment';

  @override
  String get verticalLeftToRight => 'Vertical Left-to-Right';

  @override
  String get verticalRightToLeft => 'Vertical Right-to-Left';

  @override
  String get verticalTextModeEnabled => 'Vertical text preview - Automatically flows to new columns when height exceeded, scroll horizontally';

  @override
  String get visibility => 'Visibility';

  @override
  String get visible => 'Visible';

  @override
  String get visualSettings => 'Visual Settings';

  @override
  String get width => 'Width';

  @override
  String get windowButtonClose => 'Close';

  @override
  String get windowButtonMaximize => 'Maximize';

  @override
  String get windowButtonMinimize => 'Minimize';

  @override
  String get windowButtonRestore => 'Restore';

  @override
  String get workBrowseAddFavorite => 'Add to Favorites';

  @override
  String get workBrowseBatchDone => 'Done';

  @override
  String get workBrowseBatchMode => 'Batch Mode';

  @override
  String get workBrowseCancel => 'Cancel';

  @override
  String get workBrowseDelete => 'Delete';

  @override
  String workBrowseDeleteConfirmMessage(Object count) {
    return 'Are you sure you want to delete $count selected works? This action cannot be undone.';
  }

  @override
  String get workBrowseDeleteConfirmTitle => 'Confirm Deletion';

  @override
  String workBrowseDeleteSelected(Object count) {
    return 'Delete $count';
  }

  @override
  String workBrowseError(Object message) {
    return 'Error: $message';
  }

  @override
  String get workBrowseGridView => 'Grid View';

  @override
  String get workBrowseImport => 'Import Work';

  @override
  String workBrowseItemsPerPage(Object count) {
    return '$count per page';
  }

  @override
  String get workBrowseListView => 'List View';

  @override
  String get workBrowseLoading => 'Loading works...';

  @override
  String get workBrowseNoWorks => 'No works found';

  @override
  String get workBrowseNoWorksHint => 'Try importing new works or changing filters';

  @override
  String get workBrowseReload => 'Reload';

  @override
  String get workBrowseRemoveFavorite => 'Remove from Favorites';

  @override
  String get workBrowseSearch => 'Search works...';

  @override
  String workBrowseSelectedCount(Object count) {
    return '$count selected';
  }

  @override
  String get workBrowseTitle => 'Works';

  @override
  String get workCount => 'Work Count';

  @override
  String get workDetailBack => 'Back';

  @override
  String get workDetailBasicInfo => 'Basic Information';

  @override
  String get workDetailCancel => 'Cancel';

  @override
  String get workDetailCharacters => 'Characters';

  @override
  String get workDetailCreateTime => 'Creation Time';

  @override
  String get workDetailEdit => 'Edit';

  @override
  String get workDetailExtract => 'Extract Characters';

  @override
  String get workDetailExtractionError => 'Unable to open character extraction';

  @override
  String get workDetailImageCount => 'Image Count';

  @override
  String get workDetailImageLoadError => 'The selected image failed to load, try reimporting the image';

  @override
  String get workDetailLoading => 'Loading work details...';

  @override
  String get workDetailNoCharacters => 'No characters yet';

  @override
  String get workDetailNoImages => 'No images to display';

  @override
  String get workDetailNoImagesForExtraction => 'Cannot extract characters: Work has no images';

  @override
  String get workDetailNoWork => 'Work doesn\'t exist or has been deleted';

  @override
  String get workDetailOtherInfo => 'Other Information';

  @override
  String get workDetailSave => 'Save';

  @override
  String get workDetailSaveFailure => 'Save failed';

  @override
  String get workDetailSaveSuccess => 'Save successful';

  @override
  String get workDetailTags => 'Tags';

  @override
  String get workDetailTitle => 'Work Details';

  @override
  String get workDetailUnsavedChanges => 'You have unsaved changes. Are you sure you want to discard them?';

  @override
  String get workDetailUpdateTime => 'Update Time';

  @override
  String get workDetailViewMore => 'View More';

  @override
  String get workFormAuthor => 'Author';

  @override
  String get workFormAuthorHelp => 'Optional, the creator of the work';

  @override
  String get workFormAuthorHint => 'Enter author name';

  @override
  String get workFormAuthorMaxLength => 'Author name cannot exceed 50 characters';

  @override
  String get workFormAuthorTooltip => 'Press Ctrl+A to quickly jump to the author field';

  @override
  String get workFormCreationDate => 'Creation Date';

  @override
  String get workFormDateHelp => 'The date when the work was completed';

  @override
  String get workFormDateTooltip => 'Press Tab to navigate to the next field';

  @override
  String get workFormHelp => 'Help';

  @override
  String get workFormNextField => 'Next Field';

  @override
  String get workFormPreviousField => 'Previous Field';

  @override
  String get workFormRemark => 'Remark';

  @override
  String get workFormRemarkHelp => 'Optional, additional information about the work';

  @override
  String get workFormRemarkHint => 'Optional';

  @override
  String get workFormRemarkMaxLength => 'Remark cannot exceed 500 characters';

  @override
  String get workFormRemarkTooltip => 'Press Ctrl+R to quickly jump to the remark field';

  @override
  String get workFormRequiredField => 'Required field';

  @override
  String get workFormSelectDate => 'Select Date';

  @override
  String get workFormShortcuts => 'Keyboard Shortcuts';

  @override
  String get workFormStyle => 'Style';

  @override
  String get workFormStyleHelp => 'The main style type of the work';

  @override
  String get workFormStyleTooltip => 'Press Tab to navigate to the next field';

  @override
  String get workFormTitle => 'Title';

  @override
  String get workFormTitleHelp => 'The main title of the work, displayed in the work list';

  @override
  String get workFormTitleHint => 'Enter title';

  @override
  String get workFormTitleMaxLength => 'Title cannot exceed 100 characters';

  @override
  String get workFormTitleMinLength => 'Title must be at least 2 characters';

  @override
  String get workFormTitleRequired => 'Title is required';

  @override
  String get workFormTitleTooltip => 'Press Ctrl+T to quickly jump to the title field';

  @override
  String get workFormTool => 'Tool';

  @override
  String get workFormToolHelp => 'The main tool used to create this work';

  @override
  String get workFormToolTooltip => 'Press Tab to navigate to the next field';

  @override
  String get workImportDialogAddImages => 'Add Images';

  @override
  String get workImportDialogCancel => 'Cancel';

  @override
  String get workImportDialogDeleteImage => 'Delete Image';

  @override
  String get workImportDialogDeleteImageConfirm => 'Are you sure you want to delete this image?';

  @override
  String workImportDialogError(Object error) {
    return 'Import failed: $error';
  }

  @override
  String get workImportDialogFromGallery => 'From Gallery';

  @override
  String get workImportDialogFromGalleryLong => 'Import images from your device\'s gallery';

  @override
  String get workImportDialogImport => 'Import';

  @override
  String get workImportDialogNoImages => 'No images selected';

  @override
  String get workImportDialogNoImagesHint => 'Click to add images';

  @override
  String get workImportDialogProcessing => 'Processing...';

  @override
  String get workImportDialogSuccess => 'Import successful';

  @override
  String get workImportDialogTitle => 'Import Work';

  @override
  String get works => 'Works';

  @override
  String get workStyleClerical => 'Clerical Script';

  @override
  String get workStyleCursive => 'Cursive Script';

  @override
  String get workStyleOther => 'Other';

  @override
  String get workStyleRegular => 'Regular Script';

  @override
  String get workStyleRunning => 'Running Script';

  @override
  String get workStyleSeal => 'Seal Script';

  @override
  String get workToolBrush => 'Brush';

  @override
  String get workToolHardPen => 'Hard Pen';

  @override
  String get workToolOther => 'Other';

  @override
  String get yes => 'Yes';
}
