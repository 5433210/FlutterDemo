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
  String get activated => 'Activated';

  @override
  String get activatedDescription => 'Activated - Show in selector';

  @override
  String get activeStatus => 'Active Status';

  @override
  String get add => 'Add';

  @override
  String get addCategory => 'Add Category';

  @override
  String addCategoryItem(Object category) {
    return 'Add $category';
  }

  @override
  String get addConfigItem => 'Add Configuration Item';

  @override
  String addConfigItemHint(Object category) {
    return 'Tap the button in the bottom right corner to add $category configuration items';
  }

  @override
  String get addFavorite => 'Add to Favorites';

  @override
  String addFromGalleryFailed(Object error) {
    return 'Failed to add image from gallery: $error';
  }

  @override
  String get addImage => 'Add Image';

  @override
  String get addImageHint => 'Tap to add image';

  @override
  String get addImages => 'Add Images';

  @override
  String get addLayer => 'Add Layer';

  @override
  String get addTag => 'Add Tag';

  @override
  String get addWork => 'Add Work';

  @override
  String get addedToCategory => 'Added to Category';

  @override
  String addingImagesToGallery(Object count) {
    return 'Adding $count local images to gallery...';
  }

  @override
  String get adjust => 'Adjust';

  @override
  String get adjustGridSize => 'Adjust Grid Size';

  @override
  String get afterDate => 'After a Certain Date';

  @override
  String get alignBottom => 'Align Bottom';

  @override
  String get alignCenter => 'Align Center';

  @override
  String get alignHorizontalCenter => 'Align Horizontal Center';

  @override
  String get alignLeft => 'Align Left';

  @override
  String get alignMiddle => 'Align Middle';

  @override
  String get alignRight => 'Align Right';

  @override
  String get alignTop => 'Align Top';

  @override
  String get alignVerticalCenter => 'Align Vertical Center';

  @override
  String get alignmentAssist => 'Alignment Assist';

  @override
  String get alignmentGrid => 'Grid Snapping Mode - Tap to Switch to Guideline Alignment';

  @override
  String get alignmentGuideline => 'Guideline Alignment Mode - Tap to Switch to No Assist';

  @override
  String get alignmentNone => 'No Assist Alignment - Tap to Enable Grid Snapping';

  @override
  String get alignmentOperations => 'Alignment Operations';

  @override
  String get all => 'All';

  @override
  String get allBackupsDeleteWarning => 'This action cannot be undone! All backup data will be permanently lost.';

  @override
  String get allCategories => 'All Categories';

  @override
  String get allPages => 'All Pages';

  @override
  String get allTime => 'All Time';

  @override
  String get allTypes => 'All Types';

  @override
  String get analyzePathInfoFailed => 'Failed to analyze path information';

  @override
  String get appRestartFailed => 'App Restart Failed, Please Manually Restart the App';

  @override
  String get appRestarting => 'Restarting App';

  @override
  String get appRestartingMessage => 'Data Recovery Successful, Restarting App...';

  @override
  String get appStartupFailed => 'App Startup Failed';

  @override
  String appStartupFailedWith(Object error) {
    return 'App startup failed: $error';
  }

  @override
  String get appTitle => 'Char As Gem';

  @override
  String get appVersion => 'App Version';

  @override
  String get appVersionInfo => 'App Version Info';

  @override
  String get appWillRestartAfterRestore => 'The app will restart automatically after restore.';

  @override
  String appWillRestartInSeconds(Object message) {
    return '$message\nApp will restart automatically in 3 seconds...';
  }

  @override
  String get appWillRestartMessage => 'Application will restart automatically after restore.';

  @override
  String get apply => 'Apply';

  @override
  String get applyFormatBrush => 'Apply Format Brush (Alt+W)';

  @override
  String get applyNewPath => 'Apply New Path';

  @override
  String get applyTransform => 'Apply Transform';

  @override
  String get ascending => 'Ascending';

  @override
  String get askUser => 'Ask User';

  @override
  String get askUserDescription => 'Ask user for each conflict';

  @override
  String get author => 'Author';

  @override
  String get autoBackup => 'Auto Backup';

  @override
  String get autoBackupDescription => 'Regularly Automatically Back Up Your Data';

  @override
  String get autoBackupInterval => 'Auto Backup Interval';

  @override
  String get autoBackupIntervalDescription => 'Frequency of Auto Backups';

  @override
  String get autoCleanup => 'Auto Cleanup';

  @override
  String get autoCleanupDescription => 'Automatically Clean Up Old Cache Files';

  @override
  String get autoCleanupInterval => 'Auto Cleanup Interval';

  @override
  String get autoCleanupIntervalDescription => 'Frequency of Auto Cleanup';

  @override
  String get autoDetect => 'Auto Detect';

  @override
  String get autoDetectPageOrientation => 'Auto Detect Page Orientation';

  @override
  String get autoLineBreak => 'Auto Line Break';

  @override
  String get autoLineBreakDisabled => 'Auto Line Break Disabled';

  @override
  String get autoLineBreakEnabled => 'Auto Line Break Enabled';

  @override
  String get availableCharacters => 'Available Characters';

  @override
  String get back => 'Back';

  @override
  String get backgroundColor => 'Background Color';

  @override
  String get backupBeforeSwitchRecommendation => 'To ensure data safety, we recommend creating a backup before switching data paths:';

  @override
  String backupChecksum(Object checksum) {
    return 'Checksum: $checksum...';
  }

  @override
  String get backupCompleted => '✓ Backup Completed';

  @override
  String backupCount(Object count) {
    return '$count backups';
  }

  @override
  String backupCountFormat(Object count) {
    return '$count backups';
  }

  @override
  String get backupCreatedSuccessfully => 'Backup created successfully, you can safely proceed with path switching';

  @override
  String get backupCreationFailed => 'Backup Creation Failed';

  @override
  String backupCreationTime(Object time) {
    return 'Creation time: $time';
  }

  @override
  String get backupDeletedSuccessfully => 'Backup deleted successfully';

  @override
  String get backupDescription => 'Description (Optional)';

  @override
  String get backupDescriptionHint => 'Enter a description for this backup';

  @override
  String get backupDescriptionInputExample => 'e.g., Weekly backup, Pre-important update backup, etc.';

  @override
  String get backupDescriptionInputLabel => 'Backup Description';

  @override
  String backupDescriptionLabel(Object description) {
    return 'Description: $description';
  }

  @override
  String get backupEnsuresDataSafety => '• Backup ensures data safety';

  @override
  String backupExportedSuccessfully(Object filename) {
    return 'Backup exported successfully: $filename';
  }

  @override
  String get backupFailure => 'Failed to Create Backup';

  @override
  String get backupFile => 'Backup File';

  @override
  String get backupFileChecksumMismatchError => 'Backup file checksum mismatch';

  @override
  String get backupFileCreationFailed => 'Failed to create backup file';

  @override
  String get backupFileCreationFailedError => 'Backup file creation failed';

  @override
  String backupFileLabel(Object filename) {
    return 'Backup: $filename';
  }

  @override
  String backupFileListTitle(Object count) {
    return 'Backup File List ($count)';
  }

  @override
  String get backupFileMissingDirectoryStructureError => 'Backup file missing required directory structure';

  @override
  String backupFileNotExist(Object path) {
    return 'Backup file does not exist: $path';
  }

  @override
  String get backupFileNotExistError => 'Backup file does not exist';

  @override
  String get backupFileNotFound => '备份文件不存在';

  @override
  String get backupFileSizeMismatchError => 'Backup file size mismatch';

  @override
  String get backupFileVerificationFailedError => 'Backup file verification failed';

  @override
  String get backupFirst => 'Backup First';

  @override
  String get backupImportSuccessMessage => 'Backup imported successfully';

  @override
  String get backupImportedSuccessfully => 'Backup imported successfully';

  @override
  String get backupImportedToCurrentPath => 'Backup imported to current path';

  @override
  String get backupLabel => 'Backup';

  @override
  String get backupList => 'Backup List';

  @override
  String get backupLocationTips => '• Recommend choosing a disk with sufficient free space as backup location\\n• Backup location can be external storage devices (like external hard drives)\\n• After changing backup location, all backup information will be managed uniformly\\n• Historical backup files will not be moved automatically, but can be viewed in backup management';

  @override
  String get backupManagement => 'Backup Management';

  @override
  String get backupManagementSubtitle => 'Create, restore, import, export and manage all backup files';

  @override
  String get backupMayTakeMinutes => 'Backup may take several minutes, please keep the app running';

  @override
  String get backupNotAvailable => 'Backup Management Unavailable';

  @override
  String get backupNotAvailableMessage => 'Backup management requires database support.\n\nPossible reasons:\n• Database is initializing\n• Database initialization failed\n• Application is starting up\n\nPlease try again later or restart the app.';

  @override
  String backupNotFound(Object id) {
    return 'Backup not found: $id';
  }

  @override
  String backupNotFoundError(Object id) {
    return 'Backup not found: $id';
  }

  @override
  String get backupOperationTimeoutError => 'Backup operation timed out, please check available storage space and retry';

  @override
  String get backupOverview => 'Backup Overview';

  @override
  String get backupPathDeleted => 'Backup path deleted';

  @override
  String get backupPathDeletedMessage => 'Backup path has been deleted';

  @override
  String get backupPathNotSet => 'Please set backup path first';

  @override
  String get backupPathNotSetError => 'Please set backup path first';

  @override
  String get backupPathNotSetUp => 'Backup path is not set up';

  @override
  String get backupPathSetSuccessfully => 'Backup path set successfully';

  @override
  String get backupPathSettings => 'Backup Path Settings';

  @override
  String get backupPathSettingsSubtitle => 'Configure and manage backup storage paths';

  @override
  String backupPreCheckFailed(Object error) {
    return 'Backup pre-check failed: $error';
  }

  @override
  String get backupReadyRestartMessage => 'Backup file is ready, restart required to complete restore';

  @override
  String get backupRecommendation => 'Recommend creating backup before import';

  @override
  String get backupRecommendationDescription => 'For data safety, it\'s recommended to manually create a backup before importing';

  @override
  String get backupRestartWarning => 'Restart the app to apply changes';

  @override
  String backupRestoreFailedMessage(Object error) {
    return 'Failed to restore backup: $error';
  }

  @override
  String get backupRestoreSuccessMessage => 'Backup restored successfully, please restart the app to complete the restore';

  @override
  String get backupRestoreSuccessWithRestartMessage => 'Backup restored successfully, restart required to apply changes.';

  @override
  String get backupRestoredSuccessfully => 'Backup restored successfully, please restart the app to complete restoration';

  @override
  String get backupServiceInitializing => 'Backup service is initializing, please wait and try again';

  @override
  String get backupServiceNotAvailable => 'Backup service is temporarily unavailable';

  @override
  String get backupServiceNotInitialized => 'Backup service not initialized';

  @override
  String get backupServiceNotReady => 'Backup service is temporarily unavailable';

  @override
  String get backupSettings => 'Backup and Restore';

  @override
  String backupSize(Object size) {
    return 'Size: $size';
  }

  @override
  String get backupStatistics => 'Backup Statistics';

  @override
  String get backupStorageLocation => 'Backup Storage Location';

  @override
  String get backupSuccess => 'Backup Created Successfully';

  @override
  String get backupSuccessCanSwitchPath => 'Backup created successfully, it\'s safe to proceed with path switching';

  @override
  String backupTimeLabel(Object time) {
    return 'Time: $time';
  }

  @override
  String get backupTimeoutDetailedError => 'Backup operation timed out. Possible causes:\n• Large amount of data\n• Insufficient storage space\n• Slow disk read/write speed\n\nPlease check storage space and retry.';

  @override
  String get backupTimeoutError => 'Backup creation timeout or failed, please check if storage space is sufficient';

  @override
  String get backupVerificationFailed => 'Backup file verification failed';

  @override
  String get backups => 'Backups';

  @override
  String get backupsCount => 'backups';

  @override
  String get basicInfo => 'Basic Information';

  @override
  String get basicProperties => 'Basic Properties';

  @override
  String batchDeleteMessage(Object count) {
    return 'About to delete $count items. This action cannot be undone.';
  }

  @override
  String get batchExportFailed => 'Batch export failed';

  @override
  String batchExportFailedMessage(Object error) {
    return 'Batch export failed: $error';
  }

  @override
  String get batchImport => 'Batch Import';

  @override
  String get batchMode => 'Batch Mode';

  @override
  String get batchOperations => 'Batch Operations';

  @override
  String get beforeDate => 'Before a Certain Date';

  @override
  String get border => 'Border';

  @override
  String get borderColor => 'Border Color';

  @override
  String get borderWidth => 'Border Width';

  @override
  String get boxRegion => 'Please select characters in the preview area';

  @override
  String get boxTool => 'Box Tool';

  @override
  String get bringLayerToFront => 'Bring Layer to Front';

  @override
  String get bringToFront => 'Bring to Front (Ctrl+T)';

  @override
  String get browse => 'Browse';

  @override
  String get browsePath => 'Browse Path';

  @override
  String get brushSize => 'Brush Size';

  @override
  String get buildEnvironment => 'Build Environment';

  @override
  String get buildNumber => 'Build Number';

  @override
  String get buildTime => 'Build Time';

  @override
  String get cacheClearedMessage => 'Cache Cleared Successfully';

  @override
  String get cacheSettings => 'Cache Settings';

  @override
  String get cacheSize => 'Cache Size';

  @override
  String get calligraphyStyle => 'Calligraphy Style';

  @override
  String get calligraphyStyleText => 'Calligraphy Style';

  @override
  String get canChooseDirectSwitch => '• You can also choose to switch directly';

  @override
  String get canCleanOldDataLater => 'You can clean up old data later through \"Data Path Management\"';

  @override
  String get canCleanupLaterViaManagement => 'You can clean up old data later via Data Path Management';

  @override
  String get canManuallyCleanLater => '• You can manually clean up old path data later';

  @override
  String get canNotPreview => 'Cannot Generate Preview';

  @override
  String get cancel => 'Cancel';

  @override
  String get cancelAction => 'Cancel';

  @override
  String get cannotApplyNoImage => 'No Image Available';

  @override
  String get cannotApplyNoSizeInfo => 'Cannot Get Image Size Information';

  @override
  String get cannotCapturePageImage => 'Cannot Capture Page Image';

  @override
  String get cannotDeleteOnlyPage => 'Cannot Delete Only Page';

  @override
  String get cannotGetStorageInfo => 'Cannot get storage info';

  @override
  String get cannotReadPathContent => 'Cannot read path content';

  @override
  String get cannotReadPathFileInfo => 'Cannot read path file information';

  @override
  String get cannotSaveMissingController => 'Cannot Save: Missing Controller';

  @override
  String get cannotSaveNoPages => 'No Pages Available, Cannot Save';

  @override
  String get canvasPixelSize => 'Canvas Pixel Size';

  @override
  String get canvasResetViewTooltip => 'Reset View Position';

  @override
  String get categories => 'Categories';

  @override
  String get categoryManagement => 'Category Management';

  @override
  String get categoryName => 'Category Name';

  @override
  String get categoryNameCannotBeEmpty => 'Category name cannot be empty';

  @override
  String get centimeter => 'Centimeter';

  @override
  String get changeDataPathMessage => 'The application needs to restart after changing the data path to take effect.';

  @override
  String get changePath => 'Change Path';

  @override
  String get character => 'Character';

  @override
  String get characterCollection => 'Characters';

  @override
  String characterCollectionFindSwitchFailed(Object error) {
    return 'Failed to Find and Switch Page: $error';
  }

  @override
  String get characterCollectionPreviewTab => 'Character Preview';

  @override
  String get characterCollectionResultsTab => 'Collection Results';

  @override
  String get characterCollectionSearchHint => 'Search Characters...';

  @override
  String get characterCollectionTitle => 'Character Collection';

  @override
  String get characterCollectionToolBox => 'Box Selection Tool (Ctrl+B)';

  @override
  String get characterCollectionToolPan => 'Pan Tool (Ctrl+V)';

  @override
  String get characterCollectionUseBoxTool => 'Use Box Selection Tool to Extract Characters from Image';

  @override
  String get characterCount => 'Character Count';

  @override
  String get characterDetailFormatBinary => 'Binary';

  @override
  String get characterDetailFormatBinaryDesc => 'Black and White Binary Image';

  @override
  String get characterDetailFormatDescription => 'Description';

  @override
  String get characterDetailFormatOutline => 'Outline';

  @override
  String get characterDetailFormatOutlineDesc => 'Show Only Outline';

  @override
  String get characterDetailFormatSquareBinary => 'Square Binary';

  @override
  String get characterDetailFormatSquareBinaryDesc => 'Regularized Square Binary Image';

  @override
  String get characterDetailFormatSquareOutline => 'Square Outline';

  @override
  String get characterDetailFormatSquareOutlineDesc => 'Regularized Square Outline Image';

  @override
  String get characterDetailFormatSquareTransparent => 'Square Transparent';

  @override
  String get characterDetailFormatSquareTransparentDesc => 'Regularized Square Transparent Image';

  @override
  String get characterDetailFormatThumbnail => 'Thumbnail';

  @override
  String get characterDetailFormatThumbnailDesc => 'Thumbnail';

  @override
  String get characterDetailFormatTransparent => 'Transparent';

  @override
  String get characterDetailFormatTransparentDesc => 'Background Removed Transparent Image';

  @override
  String get characterDetailLoadError => 'Failed to Load Character Details';

  @override
  String get characterDetailSimplifiedChar => 'Simplified Character';

  @override
  String get characterDetailTitle => 'Character Details';

  @override
  String characterEditSaveConfirmMessage(Object character) {
    return 'Confirm Save \'$character\'?';
  }

  @override
  String get characterUpdated => 'Character Updated';

  @override
  String get characters => 'Characters';

  @override
  String charactersCount(Object count) {
    return '$count characters';
  }

  @override
  String charactersSelected(Object count) {
    return 'Selected $count Characters';
  }

  @override
  String get checkBackupRecommendationFailed => 'Failed to check backup recommendation';

  @override
  String get checkFailedRecommendBackup => 'Check failed, recommend creating backup first to ensure data safety';

  @override
  String get checkSpecialChars => '• Check if work title contains special characters';

  @override
  String get cleanDuplicateRecords => 'Clean Duplicate Records';

  @override
  String get cleanDuplicateRecordsDescription => 'This operation will clean duplicate backup records without deleting actual backup files.';

  @override
  String get cleanDuplicateRecordsTitle => 'Clean Duplicate Records';

  @override
  String cleanupCompleted(Object count) {
    return 'Cleanup completed, removed $count invalid paths';
  }

  @override
  String cleanupCompletedMessage(Object count) {
    return 'Cleanup completed, removed $count invalid paths';
  }

  @override
  String cleanupCompletedWithCount(Object count) {
    return 'Cleanup completed, removed $count duplicate records';
  }

  @override
  String get cleanupFailed => 'Cleanup failed';

  @override
  String cleanupFailedMessage(Object error) {
    return 'Cleanup failed: $error';
  }

  @override
  String get cleanupInvalidPaths => 'Cleanup Invalid Paths';

  @override
  String cleanupOperationFailed(Object error) {
    return 'Cleanup operation failed: $error';
  }

  @override
  String get clearCache => 'Clear Cache';

  @override
  String get clearCacheConfirmMessage => 'Are you sure you want to clear all cache data? This will free up disk space but may temporarily slow down the application.';

  @override
  String get clearSelection => 'Clear Selection';

  @override
  String get close => 'Close';

  @override
  String get code => 'Code';

  @override
  String get collapse => 'Collapse';

  @override
  String get collapseFileList => 'Click to collapse file list';

  @override
  String get collectionDate => 'Collection Date';

  @override
  String get collectionElement => 'Collection Element';

  @override
  String get collectionIdCannotBeEmpty => 'Collection ID cannot be empty';

  @override
  String get collectionTime => 'Collection Time';

  @override
  String get color => 'Color';

  @override
  String get colorCode => 'Color Code';

  @override
  String get colorCodeHelp => 'Enter 6-digit hexadecimal color code (e.g., FF5500)';

  @override
  String get colorCodeInvalid => 'Invalid Color Code';

  @override
  String get colorInversion => 'Color Inversion';

  @override
  String get colorPicker => 'Color Picker';

  @override
  String get colorSettings => 'Color Settings';

  @override
  String get commonProperties => 'Common Properties';

  @override
  String get commonTags => 'Common Tags:';

  @override
  String get completingSave => 'Completing Save...';

  @override
  String get compressData => 'Compress Data';

  @override
  String get compressDataDescription => 'Reduce export file size';

  @override
  String get configInitFailed => 'Configuration data initialization failed';

  @override
  String get configInitializationFailed => 'Configuration initialization failed';

  @override
  String get configInitializing => 'Initializing configuration...';

  @override
  String get configKey => 'Configuration Key';

  @override
  String get configManagement => 'Configuration Management';

  @override
  String get configManagementDescription => 'Manage calligraphy styles and writing tools configuration';

  @override
  String get configManagementTitle => 'Calligraphy Style Management';

  @override
  String get confirm => 'Confirm';

  @override
  String get confirmChangeDataPath => 'Confirm Change Data Path';

  @override
  String get confirmContinue => 'Are you sure you want to continue?';

  @override
  String get confirmDataNormalBeforeClean => '• Recommend confirming data is normal before cleaning old path';

  @override
  String get confirmDataPathSwitch => 'Confirm Data Path Switch';

  @override
  String get confirmDelete => 'Confirm Delete';

  @override
  String get confirmDeleteAction => 'Confirm Delete';

  @override
  String get confirmDeleteAll => 'Confirm Delete All';

  @override
  String get confirmDeleteAllBackups => 'Confirm Delete All Backups';

  @override
  String get confirmDeleteAllButton => 'Confirm Delete All';

  @override
  String confirmDeleteBackup(Object description, Object filename) {
    return 'Are you sure you want to delete this backup?\\n\\nBackup: $filename\\nDescription: $description\\n\\nThis operation cannot be undone!';
  }

  @override
  String confirmDeleteBackupPath(Object path) {
    return 'Are you sure you want to delete the entire backup path?\\n\\nPath: $path\\n\\nThis will:\\n• Delete all backup files in this path\\n• Remove the path from history\\n• This operation cannot be undone\\n\\nPlease proceed with caution!';
  }

  @override
  String get confirmDeleteButton => 'Confirm Delete';

  @override
  String get confirmDeleteHistoryPath => 'Are you sure you want to delete this history path record?';

  @override
  String get confirmDeleteTitle => 'Confirm Delete';

  @override
  String get confirmExitWizard => 'Are you sure you want to exit the data path switch wizard?';

  @override
  String get confirmImportAction => 'Confirm Import';

  @override
  String get confirmImportButton => 'Confirm Import';

  @override
  String get confirmOverwrite => 'Confirm Overwrite';

  @override
  String confirmRemoveFromCategory(Object count) {
    return 'Confirm Remove from Category';
  }

  @override
  String get confirmResetToDefaultPath => 'Confirm Reset to Default Path';

  @override
  String get confirmRestoreAction => 'Confirm Restore';

  @override
  String get confirmRestoreBackup => 'Are you sure you want to restore this backup?';

  @override
  String get confirmRestoreButton => 'Confirm Restore';

  @override
  String get confirmRestoreMessage => 'Are you sure you want to restore this backup?';

  @override
  String get confirmRestoreTitle => 'Confirm Restore';

  @override
  String get confirmShortcuts => 'Shortcuts: Enter Confirm, Esc Cancel';

  @override
  String get confirmSkip => 'Confirm Skip';

  @override
  String get confirmSkipAction => 'Confirm Skip';

  @override
  String get confirmSwitch => 'Confirm Switch';

  @override
  String get confirmSwitchButton => 'Confirm Switch';

  @override
  String get confirmSwitchToNewPath => 'Confirm switching to new data path';

  @override
  String get conflictDetailsTitle => 'Conflict Resolution Details';

  @override
  String get conflictReason => 'Conflict Reason';

  @override
  String get conflictResolution => 'Conflict Resolution';

  @override
  String conflictsCount(Object count) {
    return 'Found $count conflicts';
  }

  @override
  String get conflictsFound => 'Conflicts Found';

  @override
  String get contentProperties => 'Content Properties';

  @override
  String get contentSettings => 'Content Settings';

  @override
  String get continueDuplicateImport => 'Do you still want to continue importing this backup?';

  @override
  String get continueImport => 'Continue Import';

  @override
  String get continueQuestion => 'Continue?';

  @override
  String get copy => 'Copy (Ctrl+Shift+C)';

  @override
  String copyFailed(Object error) {
    return 'Copy failed: $error';
  }

  @override
  String get copyFormat => 'Copy Format (Alt+Q)';

  @override
  String get copySelected => 'Copy Selected Items';

  @override
  String get copyVersionInfo => 'Copy Version Info';

  @override
  String get couldNotGetFilePath => 'Could Not Get File Path';

  @override
  String get countUnit => '';

  @override
  String get create => 'Create';

  @override
  String get createBackup => 'Create Backup';

  @override
  String get createBackupBeforeImport => 'Create backup before import';

  @override
  String get createBackupDescription => 'Create a New Data Backup';

  @override
  String get createBackupFailed => 'Create backup failed';

  @override
  String createBackupFailedMessage(Object error) {
    return 'Failed to create backup: $error';
  }

  @override
  String createExportDirectoryFailed(Object error) {
    return 'Failed to Create Export Directory $error';
  }

  @override
  String get createFirstBackup => 'Create first backup';

  @override
  String get createTime => 'Creation Time';

  @override
  String get createdAt => 'Created At';

  @override
  String get creatingBackup => 'Creating Backup...';

  @override
  String get creatingBackupPleaseWaitMessage => 'This may take a few minutes, please be patient';

  @override
  String get creatingBackupProgressMessage => 'Creating backup...';

  @override
  String get creationDate => 'Creation Date';

  @override
  String get criticalError => 'Critical Error';

  @override
  String get cropBottom => 'Crop Bottom';

  @override
  String get cropLeft => 'Crop Left';

  @override
  String get cropRight => 'Crop Right';

  @override
  String get cropTop => 'Crop Top';

  @override
  String get cropping => 'Cropping';

  @override
  String croppingApplied(Object bottom, Object left, Object right, Object top) {
    return '(Cropping: Left ${left}px, Top ${top}px, Right ${right}px, Bottom ${bottom}px)';
  }

  @override
  String get currentBackupPathNotSet => 'Current backup path not set';

  @override
  String get currentCharInversion => 'Current Character Inversion';

  @override
  String get currentCustomPath => 'Currently using custom data path';

  @override
  String get currentDataPath => 'Current Data Path';

  @override
  String get currentDefaultPath => 'Currently using default data path';

  @override
  String get currentLabel => 'Current';

  @override
  String get currentLocation => 'Current Location';

  @override
  String get currentPage => 'Current Page';

  @override
  String get currentPath => 'Current Path';

  @override
  String get currentPathBackup => 'Current Path Backup';

  @override
  String get currentPathBackupDescription => 'Current path backup';

  @override
  String get currentPathFileExists => 'A backup file with the same name already exists in the current path:';

  @override
  String get currentPathFileExistsMessage => 'A backup file with the same name already exists in the current path:';

  @override
  String get currentStorageInfo => 'Current Storage Info';

  @override
  String get currentStorageInfoSubtitle => 'View current storage space usage';

  @override
  String get currentStorageInfoTitle => 'Current Storage Info';

  @override
  String get currentTool => 'Current Tool';

  @override
  String get custom => 'Custom';

  @override
  String get customPath => 'Custom Path';

  @override
  String get customRange => 'Custom Range';

  @override
  String get customSize => 'Custom Size';

  @override
  String get cutSelected => 'Cut Selected Items';

  @override
  String get dangerZone => 'Danger Zone';

  @override
  String get dangerousOperationConfirm => 'Dangerous Operation Confirmation';

  @override
  String get dangerousOperationConfirmTitle => 'Dangerous Operation Confirmation';

  @override
  String get dartVersion => 'Dart Version';

  @override
  String get dataBackup => 'Data Backup';

  @override
  String get dataEmpty => 'Data Empty';

  @override
  String get dataIncomplete => 'Data Incomplete';

  @override
  String get dataMergeOptions => 'Data Merge Options:';

  @override
  String get dataPath => 'Data Path';

  @override
  String get dataPathChangedMessage => 'Data path has been changed. Please restart the application for changes to take effect.';

  @override
  String get dataPathHint => 'Select data storage path';

  @override
  String get dataPathManagement => 'Data Path Management';

  @override
  String get dataPathManagementSubtitle => 'Manage current and historical data paths';

  @override
  String get dataPathManagementTitle => 'Data Path Management';

  @override
  String get dataPathSettings => 'Data Storage Path';

  @override
  String get dataPathSettingsDescription => 'Set the storage location for application data. Restart required after changes.';

  @override
  String get dataPathSettingsSubtitle => 'Configure application data storage location';

  @override
  String get dataPathSwitchOptions => 'Data Path Switch Options';

  @override
  String get dataPathSwitchWizard => 'Data Path Switch Wizard';

  @override
  String get dataSafetyRecommendation => 'Data Safety Recommendation';

  @override
  String get dataSafetySuggestion => 'Data Safety Suggestion';

  @override
  String get dataSafetySuggestions => 'Data Safety Suggestions';

  @override
  String get dataSize => 'Data Size';

  @override
  String get databaseSize => 'Database Size';

  @override
  String get dayBeforeYesterday => 'Day Before Yesterday';

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
  String get daysAgo => 'days ago';

  @override
  String get defaultEditableText => 'Editable Text in Property Panel';

  @override
  String get defaultLayer => 'Default Layer';

  @override
  String defaultLayerName(Object number) {
    return 'Layer $number';
  }

  @override
  String get defaultPage => 'Default Page';

  @override
  String defaultPageName(Object number) {
    return 'Page $number';
  }

  @override
  String get defaultPath => 'Default Path';

  @override
  String get defaultPathName => 'Default Path';

  @override
  String get delete => 'Delete (Ctrl+D)';

  @override
  String get deleteAll => 'Delete All';

  @override
  String get deleteAllBackups => 'Delete All Backups';

  @override
  String get deleteBackup => 'Delete Backup';

  @override
  String get deleteBackupFailed => 'Failed to delete backup';

  @override
  String deleteBackupsCountMessage(Object count) {
    return 'You are about to delete $count backup files.';
  }

  @override
  String get deleteCategory => 'Delete Category';

  @override
  String get deleteCategoryOnly => 'Delete Category Only';

  @override
  String get deleteCategoryWithFiles => 'Delete Category and Files';

  @override
  String deleteCharacterFailed(Object error) {
    return 'Failed to delete character: $error';
  }

  @override
  String get deleteCompleteTitle => 'Delete Complete';

  @override
  String get deleteConfigItem => 'Delete Configuration Item';

  @override
  String get deleteConfigItemMessage => 'Are you sure you want to delete this configuration item? This action cannot be undone.';

  @override
  String get deleteConfirm => 'Confirm Delete';

  @override
  String get deleteElementConfirmMessage => 'Confirm Delete These Elements?';

  @override
  String deleteFailCount(Object count) {
    return 'Failed to delete: $count files';
  }

  @override
  String get deleteFailDetails => 'Failure details:';

  @override
  String deleteFailed(Object error) {
    return 'Delete Failed: $error';
  }

  @override
  String deleteFailedMessage(Object error) {
    return 'Delete failed: $error';
  }

  @override
  String get deleteFailure => 'Backup Delete Failed';

  @override
  String get deleteGroup => 'Delete Group';

  @override
  String get deleteGroupConfirm => 'Confirm Delete Group';

  @override
  String get deleteHistoryPathNote => 'Note: This will only delete the record, not the actual folder and data.';

  @override
  String get deleteHistoryPathRecord => 'Delete History Path Record';

  @override
  String get deleteImage => 'Delete Image';

  @override
  String get deleteLastMessage => 'This is the last item. Are you sure you want to delete it?';

  @override
  String get deleteLayer => 'Delete Layer';

  @override
  String get deleteLayerConfirmMessage => 'Confirm Delete This Layer?';

  @override
  String get deleteLayerMessage => 'All elements on this layer will be deleted. This action cannot be undone.';

  @override
  String deleteMessage(Object count) {
    return 'Confirm Delete This Item?';
  }

  @override
  String get deletePage => 'Delete Page';

  @override
  String get deletePath => 'Delete Path';

  @override
  String get deletePathButton => 'Delete Path';

  @override
  String deletePathConfirmContent(Object path) {
    return 'Are you sure you want to delete the entire backup path?\\n\\nPath: $path\\n\\nThis will:\\n• Delete all backup files in this path\\n• Remove this path from history\\n• This operation cannot be undone\\n\\nPlease proceed with caution!';
  }

  @override
  String deleteRangeItem(Object count, Object path) {
    return '• $path: $count files';
  }

  @override
  String get deleteRangeTitle => 'Delete range includes:';

  @override
  String get deleteSelected => 'Delete Selected';

  @override
  String get deleteSelectedArea => 'Delete Selected Area';

  @override
  String get deleteSelectedWithShortcut => 'Delete Selected (Ctrl+D)';

  @override
  String get deleteSuccess => 'Backup Delete Successful';

  @override
  String deleteSuccessCount(Object count) {
    return 'Successfully deleted: $count files';
  }

  @override
  String get deleteText => 'Delete';

  @override
  String get deleting => 'Deleting...';

  @override
  String get deletingBackups => 'Deleting backups...';

  @override
  String get deletingBackupsProgress => 'Deleting backup files, please wait...';

  @override
  String get descending => 'Descending';

  @override
  String get descriptionLabel => 'Description';

  @override
  String get deselectAll => 'Deselect All';

  @override
  String get detail => 'Detail';

  @override
  String get detailedError => 'Detailed error';

  @override
  String get detailedReport => 'Detailed Report';

  @override
  String get deviceInfo => 'Device Info';

  @override
  String get dimensions => 'Dimensions';

  @override
  String get directSwitch => 'Switch Directly';

  @override
  String get disabled => 'Disabled';

  @override
  String get disabledDescription => 'Disabled - Hide in selector';

  @override
  String get diskCacheSize => 'Disk Cache Size';

  @override
  String get diskCacheSizeDescription => 'Maximum size of disk cache';

  @override
  String get diskCacheTtl => 'Disk Cache TTL';

  @override
  String get diskCacheTtlDescription => 'Time for cache files to be preserved on disk';

  @override
  String get displayMode => 'Display Mode';

  @override
  String get displayName => 'Display Name';

  @override
  String get displayNameCannotBeEmpty => 'Display name cannot be empty';

  @override
  String get displayNameHint => 'Name displayed in the user interface';

  @override
  String get displayNameMaxLength => 'Display name can be at most 100 characters';

  @override
  String get displayNameRequired => 'Please enter display name';

  @override
  String get distributeHorizontally => 'Distribute Horizontally';

  @override
  String get distributeVertically => 'Distribute Vertically';

  @override
  String get distribution => 'Distribution';

  @override
  String get doNotCloseApp => 'Please do not close the application...';

  @override
  String get doNotCloseAppMessage => 'Do not close the application';

  @override
  String get done => 'Done';

  @override
  String get dropToImportImages => 'Drop to Import Images';

  @override
  String get duplicateBackupFound => 'Duplicate Backup Found';

  @override
  String get duplicateBackupFoundDesc => 'The backup file you\'re importing is a duplicate of an existing backup:';

  @override
  String get duplicateFileImported => '(duplicate file imported)';

  @override
  String get dynasty => 'Dynasty';

  @override
  String get edit => 'Edit';

  @override
  String get editConfigItem => 'Edit Configuration Item';

  @override
  String editField(Object field) {
    return 'Edit $field';
  }

  @override
  String get editGroupContents => 'Edit Group Contents';

  @override
  String get editGroupContentsDescription => 'Edit the contents of the selected group';

  @override
  String editLabel(Object label) {
    return 'Edit $label';
  }

  @override
  String get editOperations => 'Edit Operations';

  @override
  String get editTags => 'Edit Tags';

  @override
  String get editTitle => 'Edit Title';

  @override
  String get elementCopied => 'Element Copied to Clipboard';

  @override
  String get elementCopiedToClipboard => 'Element Copied to Clipboard';

  @override
  String get elementHeight => 'Height';

  @override
  String get elementId => 'Element ID';

  @override
  String get elementSize => 'Size';

  @override
  String get elementWidth => 'Width';

  @override
  String get elements => 'Elements';

  @override
  String get empty => 'Empty';

  @override
  String get emptyGroup => 'Empty Group';

  @override
  String get emptyStateError => 'Load Failed, Please Try Again Later';

  @override
  String get emptyStateNoCharacters => 'No Characters Found, View Here After Extracting Characters from Works';

  @override
  String get emptyStateNoPractices => 'No Practices Found, Click Add Button to Create New Practice';

  @override
  String get emptyStateNoResults => 'No Matching Results Found, Try Changing Search Criteria';

  @override
  String get emptyStateNoSelection => 'No Items Selected, Click Item to Select';

  @override
  String get emptyStateNoWorks => 'No Works Found, Click Add Button to Import Works';

  @override
  String get enabled => 'Enabled';

  @override
  String get endDate => 'End Date';

  @override
  String get ensureCompleteTransfer => '• Ensure complete file transfer';

  @override
  String get ensureReadWritePermission => 'Ensure the new path has read/write permissions';

  @override
  String get enterBackupDescription => 'Enter backup description (optional):';

  @override
  String get enterCategoryName => 'Enter Category Name';

  @override
  String get enterTagHint => 'Enter Tag and Press Enter';

  @override
  String error(Object message) {
    return 'Error: $message';
  }

  @override
  String get errors => 'Errors';

  @override
  String get estimatedTime => 'Estimated Time';

  @override
  String get executingImportOperation => 'Executing import operation...';

  @override
  String existingBackupInfo(Object filename) {
    return 'Existing backup: $filename';
  }

  @override
  String get existingItem => 'Existing Item';

  @override
  String get exit => 'Exit';

  @override
  String get exitBatchMode => 'Exit Batch Mode';

  @override
  String get exitConfirm => 'Exit';

  @override
  String get exitPreview => 'Exit Preview Mode';

  @override
  String get exitWizard => 'Exit Wizard';

  @override
  String get expand => 'Expand';

  @override
  String expandFileList(Object count) {
    return 'Click to expand and view $count backup files';
  }

  @override
  String get export => 'Export';

  @override
  String get exportAllBackups => 'Export All Backups';

  @override
  String get exportAllBackupsButton => 'Export All Backups';

  @override
  String get exportBackup => 'Export Backup';

  @override
  String get exportBackupFailed => 'Failed to export backup';

  @override
  String exportBackupFailedMessage(Object error) {
    return 'Export failed: $error';
  }

  @override
  String get exportCharactersOnly => 'Export Characters Only';

  @override
  String get exportCharactersOnlyDescription => 'Contains only selected character data';

  @override
  String get exportCharactersWithWorks => 'Export Characters with Works (Recommended)';

  @override
  String get exportCharactersWithWorksDescription => 'Contains characters and their source works data';

  @override
  String exportCompleted(Object failed, Object success) {
    return 'Export completed: $success successful$failed';
  }

  @override
  String exportCompletedFormat(Object failedMessage, Object successCount) {
    return 'Export completed: $successCount successful$failedMessage';
  }

  @override
  String exportCompletedFormat2(Object failed, Object success) {
    return '导出完成，成功: $success$failed';
  }

  @override
  String get exportConfig => 'Export Configuration';

  @override
  String get exportDialogRangeExample => 'For Example: 1-3,5,7-9';

  @override
  String exportDimensions(Object height, Object orientation, Object width) {
    return '${width}cm × ${height}cm ($orientation)';
  }

  @override
  String get exportEncodingIssue => '• Special character encoding issues during export';

  @override
  String get exportFailed => 'Export failed';

  @override
  String exportFailedPartFormat(Object failCount) {
    return ', $failCount failed';
  }

  @override
  String exportFailedPartFormat2(Object count) {
    return ', 失败: $count';
  }

  @override
  String exportFailedWith(Object error) {
    return 'Export failed: $error';
  }

  @override
  String get exportFailure => 'Backup Export Failed';

  @override
  String get exportFormat => 'Export Format';

  @override
  String get exportFullData => 'Full Data Export';

  @override
  String get exportFullDataDescription => 'Contains all related data';

  @override
  String get exportLocation => 'Export Location';

  @override
  String get exportNotImplemented => 'Configuration export feature is under development';

  @override
  String get exportOptions => 'Export Options';

  @override
  String get exportSuccess => 'Backup Export Successful';

  @override
  String exportSuccessMessage(Object path) {
    return 'Export successful: $path';
  }

  @override
  String get exportSummary => 'Export Summary';

  @override
  String get exportType => 'Export Format';

  @override
  String get exportWorksOnly => 'Export Works Only';

  @override
  String get exportWorksOnlyDescription => 'Contains only selected works data';

  @override
  String get exportWorksWithCharacters => 'Export Works with Characters (Recommended)';

  @override
  String get exportWorksWithCharactersDescription => 'Contains works and their related character data';

  @override
  String get exporting => 'Exporting, Please Wait...';

  @override
  String get exportingBackup => 'Exporting Backup...';

  @override
  String get exportingBackupMessage => 'Exporting backup...';

  @override
  String exportingBackups(Object count) {
    return 'Exporting $count backups...';
  }

  @override
  String get exportingBackupsProgress => 'Exporting backups...';

  @override
  String exportingBackupsProgressFormat(Object count) {
    return 'Exporting $count backups...';
  }

  @override
  String get exportingDescription => 'Exporting data, please wait...';

  @override
  String get extract => 'Extract';

  @override
  String get extractionError => 'Extraction Error';

  @override
  String failedCount(Object count) {
    return ', $count failed';
  }

  @override
  String get favorite => 'Favorite';

  @override
  String get favoritesOnly => 'Favorites Only';

  @override
  String get fileCorrupted => '• File corrupted during transfer';

  @override
  String get fileCount => 'File Count';

  @override
  String get fileExistsTitle => 'File Already Exists';

  @override
  String get fileExtension => 'File Extension';

  @override
  String get fileMigrationWarning => 'When not migrating files, old path backup files remain in original location';

  @override
  String get fileName => 'File Name';

  @override
  String fileNotExist(Object path) {
    return 'File Not Found: $path';
  }

  @override
  String get fileRestored => 'Image Restored from Gallery';

  @override
  String get fileSize => 'File Size';

  @override
  String get fileUpdatedAt => 'File Modified Time';

  @override
  String get filenamePrefix => 'Enter Filename Prefix (Page Numbers Will Be Added Automatically)';

  @override
  String get files => 'Number of Files';

  @override
  String get filter => 'Filter';

  @override
  String get filterAndSort => 'Filter and Sort';

  @override
  String get filterClear => 'Clear';

  @override
  String get firstPage => 'First Page';

  @override
  String get fitContain => 'Contain';

  @override
  String get fitCover => 'Cover';

  @override
  String get fitFill => 'Fill';

  @override
  String get fitHeight => 'Fit Height';

  @override
  String get fitMode => 'Fit Mode';

  @override
  String get fitWidth => 'Fit Width';

  @override
  String get flip => 'Flip';

  @override
  String get flipHorizontal => 'Flip Horizontal';

  @override
  String get flipVertical => 'Flip Vertical';

  @override
  String get flipOptions => 'Flip Options';

  @override
  String get imagePropertyPanelFlipInfo => 'Flip effects are processed at the canvas rendering stage and take effect immediately without reprocessing image data. Flip is a pure visual transformation, independent of the image processing pipeline.';

  @override
  String get flutterVersion => 'Flutter Version';

  @override
  String get folderImportComplete => 'Folder Import Complete';

  @override
  String get fontColor => 'Font Color';

  @override
  String get fontFamily => 'Font Family';

  @override
  String get fontSize => 'Font Size';

  @override
  String get fontStyle => 'Font Style';

  @override
  String get fontTester => 'Font Tester';

  @override
  String get fontWeight => 'Font Weight';

  @override
  String get fontWeightTester => 'Font Weight Tester';

  @override
  String get format => 'Format';

  @override
  String get formatBrushActivated => 'Format Brush Activated, Click Target Element to Apply Style';

  @override
  String get formatType => 'Format Type';

  @override
  String get fromGallery => 'From Gallery';

  @override
  String get fromLocal => 'From Local';

  @override
  String get fullScreen => 'Full Screen';

  @override
  String get geometryProperties => 'Geometry Properties';

  @override
  String get getHistoryPathsFailed => 'Failed to get history paths';

  @override
  String get getPathInfoFailed => 'Failed to get path information';

  @override
  String get getPathUsageTimeFailed => 'Failed to get path usage time';

  @override
  String get getStorageInfoFailed => 'Failed to get storage info';

  @override
  String get getThumbnailSizeError => 'Get Thumbnail Size Error';

  @override
  String get gettingPathInfo => 'Getting path info...';

  @override
  String get gettingStorageInfo => 'Getting storage info...';

  @override
  String get gitBranch => 'Git Branch';

  @override
  String get gitCommit => 'Git Commit';

  @override
  String get goToBackup => 'Go to Backup';

  @override
  String get gridSettings => 'Grid Settings';

  @override
  String get gridSize => 'Grid Size';

  @override
  String get gridSizeExtraLarge => 'Extra Large';

  @override
  String get gridSizeLarge => 'Large';

  @override
  String get gridSizeMedium => 'Medium';

  @override
  String get gridSizeSmall => 'Small';

  @override
  String get gridView => 'Grid View';

  @override
  String get group => 'Group (Ctrl+J)';

  @override
  String get groupElements => 'Group Elements';

  @override
  String get groupOperations => 'Group Operations';

  @override
  String get groupProperties => 'Group Properties';

  @override
  String get height => 'Height';

  @override
  String get help => 'Help';

  @override
  String get hideDetails => 'Hide Details';

  @override
  String get hideElement => 'Hide Element';

  @override
  String get hideGrid => 'Hide Grid (Ctrl+G)';

  @override
  String get hideImagePreview => 'Hide Image Preview';

  @override
  String get hideThumbnails => 'Hide Page Thumbnails';

  @override
  String get historicalPaths => 'Historical Paths';

  @override
  String get historyDataPaths => 'Historical Data Paths';

  @override
  String get historyLabel => 'History';

  @override
  String get historyLocation => 'History Location';

  @override
  String get historyPath => 'History Path';

  @override
  String get historyPathBackup => 'Historical Path Backup';

  @override
  String get historyPathBackupDescription => 'Historical path backup';

  @override
  String get historyPathDeleted => 'History path record deleted';

  @override
  String get homePage => 'Home Page';

  @override
  String get horizontalAlignment => 'Horizontal Alignment';

  @override
  String get horizontalLeftToRight => 'Horizontal Left to Right';

  @override
  String get horizontalRightToLeft => 'Horizontal Right to Left';

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
  String get hoursAgo => 'hours ago';

  @override
  String get image => 'Image';

  @override
  String get imageCount => 'Image Count';

  @override
  String get imageElement => 'Image Element';

  @override
  String get imageExportFailed => 'Image Export Failed';

  @override
  String get imageFileNotExists => 'Image File Not Exists';

  @override
  String imageImportError(Object error) {
    return 'Image Import Error: $error';
  }

  @override
  String get imageImportSuccess => 'Image Import Success';

  @override
  String get imageIndexError => 'Image Index Error';

  @override
  String get imageInvalid => 'Image Invalid';

  @override
  String get imageInvert => 'Image Invert';

  @override
  String imageLoadError(Object error) {
    return 'Image Load Error: $error';
  }

  @override
  String get imageLoadFailed => 'Image Load Failed';

  @override
  String imageProcessingPathError(Object error) {
    return 'Image Processing Path Error: $error';
  }

  @override
  String get imageProperties => 'Image Properties';

  @override
  String get imagePropertyPanelAutoImportNotice => 'Selected images will be automatically imported into your gallery for better management';

  @override
  String get imagePropertyPanelGeometryWarning => 'These properties adjust the entire element box, not the image content itself';

  @override
  String get imagePropertyPanelPreviewNotice => 'Note: Duplicate logs displayed during preview are normal';

  @override
  String get imagePropertyPanelTransformWarning => 'These transformations modify the image content itself, not just the element frame';

  @override
  String get imageResetSuccess => 'Reset Successful';

  @override
  String get imageRestoring => 'Restoring Image Data...';

  @override
  String get imageSelection => 'Image Selection';

  @override
  String get imageTransform => 'Image Transform';

  @override
  String imageTransformError(Object error) {
    return 'Image Transform Error: $error';
  }

  @override
  String get imageUpdated => 'Image Updated';

  @override
  String get images => 'Images';

  @override
  String get implementationComingSoon => 'This feature is under development, please stay tuned!';

  @override
  String get import => 'Import';

  @override
  String get importBackup => 'Import Backup';

  @override
  String get importBackupFailed => 'Failed to import backup';

  @override
  String importBackupFailedMessage(Object error) {
    return 'Failed to import backup: $error';
  }

  @override
  String get importConfig => 'Import Configuration';

  @override
  String get importError => 'Import Error';

  @override
  String get importErrorCauses => 'This issue is usually caused by the following reasons:';

  @override
  String importFailed(Object error) {
    return 'Import Failed: $error';
  }

  @override
  String get importFailure => 'Backup Import Failed';

  @override
  String get importFileSuccess => 'Import File Success';

  @override
  String get importFiles => 'Import Files';

  @override
  String get importFolder => 'Import Folder';

  @override
  String get importNotImplemented => 'Configuration import feature is under development';

  @override
  String get importOptions => 'Import Options';

  @override
  String get importPreview => 'Import Preview';

  @override
  String get importRequirements => 'Import Requirements';

  @override
  String get importResultTitle => 'Import Result';

  @override
  String get importStatistics => 'Import Statistics';

  @override
  String get importSuccess => 'Backup Import Success';

  @override
  String importSuccessMessage(Object count) {
    return 'Successfully imported $count files';
  }

  @override
  String get importToCurrentPath => 'Import to Current Path';

  @override
  String get importToCurrentPathButton => 'Import to Current Path';

  @override
  String get importToCurrentPathDesc => 'This will copy the backup file to current path, original file remains unchanged.';

  @override
  String get importToCurrentPathDescription => 'This will copy the backup file to the current path, original file remains unchanged.';

  @override
  String get importToCurrentPathFailed => 'Failed to import backup to current path';

  @override
  String get importToCurrentPathMessage => 'Are you sure you want to import this backup to the current backup path?';

  @override
  String get importToCurrentPathSuccessMessage => 'Backup successfully imported to current path';

  @override
  String get importToCurrentPathTitle => 'Import to Current Path';

  @override
  String get importantReminder => 'Important Reminder';

  @override
  String get importedBackupDescription => 'Imported backup';

  @override
  String get importedCharacters => 'Imported Characters';

  @override
  String get importedFile => 'Imported File';

  @override
  String get importedImages => 'Imported Images';

  @override
  String get importedSuffix => 'Imported Backup';

  @override
  String get importedWorks => 'Imported Works';

  @override
  String get importing => 'Importing...';

  @override
  String get importingBackup => 'Importing backup...';

  @override
  String get importingBackupProgressMessage => 'Importing backup...';

  @override
  String get importingDescription => 'Importing data, please wait...';

  @override
  String get importingToCurrentPath => 'Importing to current path...';

  @override
  String get importingToCurrentPathMessage => 'Importing backup to current path...';

  @override
  String get importingWorks => 'Importing works...';

  @override
  String get includeImages => 'Include Images';

  @override
  String get includeImagesDescription => 'Export related image files';

  @override
  String get includeMetadata => 'Include Metadata';

  @override
  String get includeMetadataDescription => 'Export creation time, tags and other metadata';

  @override
  String get incompatibleCharset => '• Used incompatible character set';

  @override
  String initializationFailed(Object error) {
    return 'Initialization Failed: $error';
  }

  @override
  String get initializing => 'Initializing...';

  @override
  String get inputCharacter => 'Input Character';

  @override
  String get inputChineseContent => 'Please enter Chinese content';

  @override
  String inputFieldHint(Object field) {
    return 'Please enter $field';
  }

  @override
  String get inputFileName => 'Input File Name';

  @override
  String get inputHint => 'Input Hint';

  @override
  String get inputNewTag => 'Input New Tag...';

  @override
  String get inputTitle => 'Input Title';

  @override
  String get invalidFilename => 'Invalid Filename';

  @override
  String get invalidNumber => 'Please enter a valid number';

  @override
  String get invertMode => 'Invert Mode';

  @override
  String get isActive => 'Is Active';

  @override
  String itemsCount(Object count) {
    return '$count items';
  }

  @override
  String itemsPerPage(Object count) {
    return '$count items/page';
  }

  @override
  String get jsonFile => 'JSON File';

  @override
  String get justNow => 'just now';

  @override
  String get keepBackupCount => 'Keep Backup Count';

  @override
  String get keepBackupCountDescription => 'Number of backups to keep before deleting old ones';

  @override
  String get keepExisting => 'Keep Existing';

  @override
  String get keepExistingDescription => 'Keep existing data, skip import';

  @override
  String get key => 'Key';

  @override
  String get keyCannotBeEmpty => 'Key cannot be empty';

  @override
  String get keyExists => 'Configuration key already exists';

  @override
  String get keyHelperText => 'Can only contain letters, numbers, underscores and hyphens';

  @override
  String get keyHint => 'Unique identifier for the configuration item';

  @override
  String get keyInvalidCharacters => 'Key can only contain letters, numbers, underscores and hyphens';

  @override
  String get keyMaxLength => 'Key can be at most 50 characters';

  @override
  String get keyMinLength => 'Key must be at least 2 characters';

  @override
  String get keyRequired => 'Please enter configuration key';

  @override
  String get landscape => 'Landscape';

  @override
  String get language => 'Language';

  @override
  String get languageEn => 'English';

  @override
  String get languageJa => '日本語';

  @override
  String get languageKo => '한국어';

  @override
  String get languageSystem => 'System';

  @override
  String get languageZh => '简体中文';

  @override
  String get languageZhTw => '繁體中文';

  @override
  String get last30Days => 'Last 30 Days';

  @override
  String get last365Days => 'Last 365 Days';

  @override
  String get last7Days => 'Last 7 Days';

  @override
  String get last90Days => 'Last 90 Days';

  @override
  String get lastBackup => 'Last Backup';

  @override
  String get lastBackupTime => 'Last Backup Time';

  @override
  String get lastMonth => 'Last Month';

  @override
  String get lastPage => 'Last Page';

  @override
  String get lastUsed => 'Last Used';

  @override
  String get lastUsedTime => 'Last used';

  @override
  String get lastWeek => 'Last Week';

  @override
  String get lastYear => 'Last Year';

  @override
  String get layer => 'Layer';

  @override
  String get layer1 => 'Layer 1';

  @override
  String get layerElements => 'Layer Elements';

  @override
  String get layerInfo => 'Layer Info';

  @override
  String layerName(Object index) {
    return 'Layer $index';
  }

  @override
  String get layerOperations => 'Layer Operations';

  @override
  String get layerProperties => 'Layer Properties';

  @override
  String get leave => 'Leave';

  @override
  String get legacyBackupDescription => 'Legacy backup';

  @override
  String get legacyDataPathDescription => 'Legacy data path pending cleanup';

  @override
  String get letterSpacing => 'Letter Spacing';

  @override
  String get library => 'Library';

  @override
  String get libraryCount => 'Library Count';

  @override
  String get libraryManagement => 'Gallery';

  @override
  String get lineHeight => 'Line Spacing';

  @override
  String get lineThrough => 'Line Through';

  @override
  String get listView => 'List View';

  @override
  String get loadBackupRegistryFailed => 'Failed to load backup registry';

  @override
  String loadCharacterDataFailed(Object error) {
    return 'Failed to load character data: $error';
  }

  @override
  String get loadConfigFailed => 'Failed to load configuration';

  @override
  String get loadCurrentBackupPathFailed => 'Failed to load current backup path';

  @override
  String get loadDataFailed => 'Failed to load data';

  @override
  String get loadFailed => 'Load Failed';

  @override
  String get loadPathInfoFailed => 'Failed to load path information';

  @override
  String get loadPracticeSheetFailed => 'Load Practice Sheet Failed';

  @override
  String get loading => 'Loading...';

  @override
  String get loadingImage => 'Loading Image...';

  @override
  String get location => 'Location';

  @override
  String get lock => 'Lock';

  @override
  String get lockElement => 'Lock Element';

  @override
  String get lockStatus => 'Lock Status';

  @override
  String get lockUnlockAllElements => 'Lock/Unlock All Elements';

  @override
  String get locked => 'Locked';

  @override
  String get manualBackupDescription => 'Manually created backup';

  @override
  String get marginBottom => 'Bottom';

  @override
  String get marginLeft => 'Left';

  @override
  String get marginRight => 'Right';

  @override
  String get marginTop => 'Top';

  @override
  String get max => 'Max';

  @override
  String get memoryDataCacheCapacity => 'Memory Data Cache Capacity';

  @override
  String get memoryDataCacheCapacityDescription => 'Number of data items to keep in memory';

  @override
  String get memoryImageCacheCapacity => 'Memory Image Cache Capacity';

  @override
  String get memoryImageCacheCapacityDescription => 'Number of images to keep in memory';

  @override
  String get mergeAndMigrateFiles => 'Merge and Migrate Files';

  @override
  String get mergeBackupInfo => 'Merge Backup Info';

  @override
  String get mergeBackupInfoDesc => 'Merge old path backup info into new path registry';

  @override
  String get mergeData => 'Merge Data';

  @override
  String get mergeDataDescription => 'Combine existing and imported data';

  @override
  String get mergeOnlyBackupInfo => 'Merge Backup Info Only';

  @override
  String get metadata => 'Metadata';

  @override
  String get migrateBackupFiles => 'Migrate Backup Files';

  @override
  String get migrateBackupFilesDesc => 'Copy old path backup files to new path (recommended)';

  @override
  String get migratingData => 'Migrating Data';

  @override
  String get min => 'Min';

  @override
  String get monospace => 'Monospace';

  @override
  String get monthsAgo => 'months ago';

  @override
  String moreErrorsCount(Object count) {
    return '...and $count more errors';
  }

  @override
  String get moveDown => 'Move Down (Ctrl+Shift+B)';

  @override
  String get moveLayerDown => 'Move Layer Down';

  @override
  String get moveLayerUp => 'Move Layer Up';

  @override
  String get moveUp => 'Move Up (Ctrl+Shift+T)';

  @override
  String get multiSelectTool => 'Multi-Select Tool';

  @override
  String multipleFilesNote(Object count) {
    return 'Note: $count image files will be exported, and the filenames will be automatically numbered.';
  }

  @override
  String get name => 'Name';

  @override
  String get navCollapseSidebar => 'Collapse Sidebar';

  @override
  String get navExpandSidebar => 'Expand Sidebar';

  @override
  String get navigatedToBackupSettings => 'Navigated to backup settings page';

  @override
  String get navigationAttemptBack => '尝试返回上一个功能区';

  @override
  String get navigationAttemptToNewSection => '尝试导航到新功能区';

  @override
  String get navigationAttemptToSpecificItem => '尝试导航到特定历史记录项';

  @override
  String get navigationBackToPrevious => 'Back to Previous Page';

  @override
  String get navigationClearHistory => 'Clear Navigation History';

  @override
  String get navigationClearHistoryFailed => 'Failed to clear navigation history';

  @override
  String get navigationFailedBack => '返回导航失败';

  @override
  String get navigationFailedSection => '导航切换失败';

  @override
  String get navigationFailedToSpecificItem => 'Failed to navigate to specific history item';

  @override
  String get navigationHistoryCleared => '导航历史记录已清空';

  @override
  String get navigationItemNotFound => '历史记录中未找到目标项，直接导航到该功能区';

  @override
  String get navigationNoHistory => 'No History';

  @override
  String get navigationNoHistoryMessage => 'You have reached the beginning of the current functional area.';

  @override
  String get navigationRecordRoute => '记录功能区内路由变化';

  @override
  String get navigationRecordRouteFailed => '记录路由变化失败';

  @override
  String get navigationRestoreStateFailed => '恢复导航状态失败';

  @override
  String get navigationSaveState => '保存导航状态';

  @override
  String get navigationSaveStateFailed => '保存导航状态失败';

  @override
  String get navigationSectionCharacterManagement => 'Character Management';

  @override
  String get navigationSectionGalleryManagement => 'Gallery Management';

  @override
  String get navigationSectionPracticeList => 'Practice List';

  @override
  String get navigationSectionSettings => 'Settings';

  @override
  String get navigationSectionWorkBrowse => 'Work Browse';

  @override
  String get navigationSelectPage => 'Which page do you want to return to?';

  @override
  String get navigationStateRestored => '导航状态已从存储恢复';

  @override
  String get navigationStateSaved => '导航状态已保存';

  @override
  String get navigationSuccessBack => 'Successfully navigated back to previous section';

  @override
  String get navigationSuccessToNewSection => 'Successfully navigated to new section';

  @override
  String get navigationSuccessToSpecificItem => 'Successfully navigated to specific history item';

  @override
  String get navigationToggleExpanded => '切换导航栏展开状态';

  @override
  String get needRestartApp => 'Need to Restart App';

  @override
  String get newConfigItem => 'New Configuration Item';

  @override
  String get newDataPath => 'New data path:';

  @override
  String get newItem => 'New';

  @override
  String get nextField => 'Next Field';

  @override
  String get nextPage => 'Next Page';

  @override
  String get nextStep => 'Next';

  @override
  String get no => 'No';

  @override
  String get noBackupExistsRecommendCreate => 'No backup exists yet, recommend creating backup first to ensure data safety';

  @override
  String get noBackupFilesInPath => 'No backup files in this path';

  @override
  String get noBackupFilesInPathMessage => 'No backup files in this path';

  @override
  String get noBackupFilesToExport => 'No backup files to export in this path';

  @override
  String get noBackupFilesToExportMessage => 'No backup files to export in this path';

  @override
  String get noBackupPathSetRecommendCreateBackup => 'No backup path set, recommend setting backup path and creating backup first';

  @override
  String get noBackupPaths => 'No backup paths';

  @override
  String get noBackups => 'No Backups Available';

  @override
  String get noBackupsInPath => 'No backup files in this path';

  @override
  String get noBackupsToDelete => 'No backup files to delete';

  @override
  String get noCategories => 'No Categories';

  @override
  String get noCharacters => 'No Characters Found';

  @override
  String get noCharactersFound => 'No Matching Characters Found';

  @override
  String noConfigItems(Object category) {
    return 'No $category configurations';
  }

  @override
  String get noCropping => '(No Cropping)';

  @override
  String get noDisplayableImages => 'No Displayable Images';

  @override
  String get noElementsInLayer => 'No Elements in Layer';

  @override
  String get noElementsSelected => 'No Elements Selected';

  @override
  String get noHistoryPaths => 'No Historical Paths';

  @override
  String get noHistoryPathsDescription => 'No other data paths have been used yet';

  @override
  String get noImageSelected => 'No Image Selected';

  @override
  String get noImages => 'No Images';

  @override
  String get noItemsSelected => 'No Items Selected';

  @override
  String get noLayers => 'No Layers, Please Add a Layer';

  @override
  String get noMatchingConfigItems => 'No matching configuration items found';

  @override
  String get noPageSelected => 'No Page Selected';

  @override
  String get noPagesToExport => 'No Pages to Export';

  @override
  String get noPagesToPrint => 'No Pages to Print';

  @override
  String get noPreviewAvailable => 'No preview available';

  @override
  String get noRegionBoxed => 'No Region Selected';

  @override
  String get noRemarks => 'No Remarks';

  @override
  String get noResults => 'No Results Found';

  @override
  String get noTags => 'No Tags';

  @override
  String get noTexture => 'No Texture';

  @override
  String get noTopLevelCategory => 'No (Top Level Category)';

  @override
  String get noWorks => 'No Works Found';

  @override
  String get noWorksHint => 'Try importing new works or changing the filter criteria';

  @override
  String get noiseReduction => 'Noise Reduction';

  @override
  String get none => 'None';

  @override
  String get notSet => 'Not set';

  @override
  String get note => 'Note';

  @override
  String get notesTitle => 'Notes:';

  @override
  String get noticeTitle => 'Notice';

  @override
  String get ok => 'OK';

  @override
  String get oldBackupRecommendCreateNew => 'Last backup is over 24 hours old, recommend creating new backup';

  @override
  String get oldDataNotAutoDeleted => 'Old data will not be automatically deleted after path switching';

  @override
  String get oldDataNotDeleted => 'Old data will not be automatically deleted after path switching';

  @override
  String get oldDataWillNotBeDeleted => 'After switching, data in old path will not be automatically deleted';

  @override
  String get oldPathDataNotAutoDeleted => 'Old path data will not be automatically deleted after switching';

  @override
  String get onlyOneCharacter => 'Only one character is allowed';

  @override
  String get opacity => 'Opacity';

  @override
  String get openBackupManagementFailed => 'Failed to open backup management';

  @override
  String get openFolder => 'Open Folder';

  @override
  String openGalleryFailed(Object error) {
    return 'Open Gallery Failed: $error';
  }

  @override
  String get openPathFailed => 'Failed to open path';

  @override
  String get openPathSwitchWizardFailed => 'Failed to open data path switch wizard';

  @override
  String get operatingSystem => 'Operating System';

  @override
  String get operationCannotBeUndone => 'This operation cannot be undone, please confirm carefully';

  @override
  String get operationCannotUndo => 'This operation cannot be undone, please confirm carefully';

  @override
  String get optional => 'Optional';

  @override
  String get original => 'Original';

  @override
  String get originalImageDesc => 'Untreated Original Image';

  @override
  String get outputQuality => 'Output Quality';

  @override
  String get overwrite => 'Overwrite';

  @override
  String get overwriteConfirm => 'Overwrite Confirmation';

  @override
  String get overwriteExisting => 'Overwrite Existing';

  @override
  String get overwriteExistingDescription => 'Replace existing items with imported data';

  @override
  String overwriteExistingPractice(Object title) {
    return 'A practice sheet named \"$title\" already exists. Do you want to overwrite it?';
  }

  @override
  String get overwriteFile => 'Overwrite File';

  @override
  String get overwriteFileAction => 'Overwrite File';

  @override
  String overwriteMessage(Object title) {
    return 'A practice sheet with the title \"$title\" already exists. Do you want to overwrite it?';
  }

  @override
  String get overwrittenCharacters => 'Overwritten Characters';

  @override
  String get overwrittenItems => 'Overwritten Items';

  @override
  String get overwrittenWorks => 'Overwritten Works';

  @override
  String get padding => 'Padding';

  @override
  String get pageBuildError => 'Page Build Error';

  @override
  String get pageMargins => 'Page Margins (cm)';

  @override
  String get pageNotImplemented => 'Page not implemented';

  @override
  String get pageOrientation => 'Page Orientation';

  @override
  String get pageProperties => 'Page Properties';

  @override
  String get pageRange => 'Page Range';

  @override
  String get pageSize => 'Page Size';

  @override
  String get pages => 'Pages';

  @override
  String get parentCategory => 'Parent Category (Optional)';

  @override
  String get parsingImportData => 'Parsing import data...';

  @override
  String get paste => 'Paste (Ctrl+Shift+V)';

  @override
  String get path => 'Path';

  @override
  String get pathAnalysis => 'Path Analysis';

  @override
  String get pathConfigError => 'Path configuration error';

  @override
  String get pathInfo => 'Path Info';

  @override
  String get pathInvalid => 'Path Invalid';

  @override
  String get pathNotExists => 'Path does not exist';

  @override
  String get pathSettings => 'Path Settings';

  @override
  String get pathSize => 'Path Size';

  @override
  String get pathSwitchCompleted => 'Data path switching completed!\\n\\nYou can view and clean up old path data in \"Data Path Management\".';

  @override
  String get pathSwitchCompletedMessage => 'Data path switch completed!\\n\\nYou can view and clean up old path data in Data Path Management.';

  @override
  String get pathSwitchFailed => 'Path Switch Failed';

  @override
  String get pathSwitchFailedMessage => 'Path switching failed';

  @override
  String pathValidationFailed(Object error) {
    return 'Path validation failed: $error';
  }

  @override
  String get pathValidationFailedGeneric => 'Path validation failed. Please check if the path is valid';

  @override
  String get pdfExportFailed => 'PDF Export Failed';

  @override
  String pdfExportSuccess(Object path) {
    return 'PDF Export Success: $path';
  }

  @override
  String get pinyin => 'Pinyin';

  @override
  String get pixels => 'Pixels';

  @override
  String get platformInfo => 'Platform Info';

  @override
  String get pleaseEnterValidNumber => 'Please Enter Valid Number';

  @override
  String get pleaseSelectOperation => 'Please select an operation:';

  @override
  String get pleaseSetBackupPathFirst => 'Please set backup path first';

  @override
  String get pleaseWaitMessage => 'Please wait';

  @override
  String get portrait => 'Portrait';

  @override
  String get position => 'Position';

  @override
  String get ppiSetting => 'PPI Setting (Pixels Per Inch)';

  @override
  String get practiceEditCollection => 'Collection';

  @override
  String get practiceEditDefaultLayer => 'Default Layer';

  @override
  String practiceEditPracticeLoaded(Object title) {
    return 'Practice Sheet \"$title\" Loaded Successfully';
  }

  @override
  String get practiceEditTitle => 'Practice Sheet Editor';

  @override
  String get practiceListSearch => 'Search Practice Sheets...';

  @override
  String get practiceListTitle => 'Practice Sheets';

  @override
  String get practiceSheetNotExists => 'Practice Sheet Does Not Exist';

  @override
  String practiceSheetSaved(Object title) {
    return 'Practice Sheet \"$title\" Saved';
  }

  @override
  String practiceSheetSavedMessage(Object title) {
    return 'Practice sheet \"$title\" saved successfully';
  }

  @override
  String get practices => 'Practices';

  @override
  String get preparingPrint => 'Preparing to Print, Please Wait...';

  @override
  String get preparingSave => 'Preparing to Save...';

  @override
  String get preserveMetadata => 'Preserve Metadata';

  @override
  String get preserveMetadataDescription => 'Keep original creation time and metadata';

  @override
  String get preserveMetadataMandatory => 'Mandatory preservation of original creation time, author information and other metadata to ensure data consistency';

  @override
  String get presetSize => 'Preset Size';

  @override
  String get presets => 'Presets';

  @override
  String get preview => 'Preview';

  @override
  String get previewMode => 'Preview Mode';

  @override
  String previewPage(Object current, Object total) {
    return '(Page $current/$total)';
  }

  @override
  String get previousField => 'Previous Field';

  @override
  String get previousPage => 'Previous Page';

  @override
  String get previousStep => 'Previous';

  @override
  String processedCount(Object current, Object total) {
    return 'Processed: $current / $total';
  }

  @override
  String processedProgress(Object current, Object total) {
    return 'Processed: $current / $total';
  }

  @override
  String get processing => 'Processing...';

  @override
  String get processingDetails => 'Processing Details';

  @override
  String get processingEraseData => 'Processing Erase Data...';

  @override
  String get processingImage => 'Processing Image...';

  @override
  String get processingPleaseWait => 'Processing, please wait...';

  @override
  String get properties => 'Properties';

  @override
  String get qualityHigh => 'High Quality (2x)';

  @override
  String get qualityStandard => 'Standard (1x)';

  @override
  String get qualityUltra => 'Ultra Quality (3x)';

  @override
  String get quickRecoveryOnIssues => '• Quick recovery if issues occur during switching';

  @override
  String get reExportWork => '• Re-export the work';

  @override
  String get recent => 'Recent';

  @override
  String get recentBackupCanSwitch => 'Recent backup exists, safe to switch directly';

  @override
  String get recommendConfirmBeforeCleanup => 'Recommend confirming new path data is normal before cleaning up old path';

  @override
  String get recommendConfirmNewDataBeforeClean => 'Recommend confirming new path data is normal before cleaning old path';

  @override
  String get recommendSufficientSpace => 'Choose a disk with sufficient free space';

  @override
  String get redo => 'Redo';

  @override
  String get refresh => 'Refresh';

  @override
  String refreshDataFailed(Object error) {
    return 'Refresh Data Failed: $error';
  }

  @override
  String get reload => 'Reload';

  @override
  String get remarks => 'Remarks';

  @override
  String get remarksHint => 'Add Remarks Information';

  @override
  String get remove => 'Remove';

  @override
  String get removeFavorite => 'Remove from Favorites';

  @override
  String get removeFromCategory => 'Remove from Current Category';

  @override
  String get rename => 'Rename';

  @override
  String get renameDuplicates => 'Rename Duplicates';

  @override
  String get renameDuplicatesDescription => 'Rename imported items to avoid conflicts';

  @override
  String get renameLayer => 'Rename Layer';

  @override
  String get renderFailed => 'Render Failed';

  @override
  String get reselectFile => 'Reselect File';

  @override
  String get reset => 'Reset';

  @override
  String resetCategoryConfig(Object category) {
    return 'Reset $category Configuration';
  }

  @override
  String resetCategoryConfigMessage(Object category) {
    return 'Are you sure you want to reset $category configuration to default settings? This action cannot be undone.';
  }

  @override
  String get resetDataPathToDefault => 'Reset to Default';

  @override
  String get resetSettingsConfirmMessage => 'Are you sure you want to reset to default values?';

  @override
  String get resetSettingsConfirmTitle => 'Reset Settings';

  @override
  String get resetToDefault => 'Reset to Default';

  @override
  String get resetToDefaultFailed => 'Failed to reset to default path';

  @override
  String resetToDefaultFailedWithError(Object error) {
    return 'Failed to reset to default path: $error';
  }

  @override
  String get resetToDefaultPathMessage => 'This will reset the data path to the default location. The application needs to restart to take effect. Are you sure you want to continue?';

  @override
  String get resetToDefaults => 'Reset to Defaults';

  @override
  String get resetTransform => 'Reset Transform';

  @override
  String get resetZoom => 'Reset Zoom';

  @override
  String get resolution => 'Resolution';

  @override
  String get restartAfterRestored => 'Note: The application will restart automatically after recovery is complete';

  @override
  String get restartLaterButton => 'Later';

  @override
  String get restartNeeded => 'Restart Needed';

  @override
  String get restartNow => 'Restart Now';

  @override
  String get restartNowButton => 'Restart Now';

  @override
  String get restore => 'Restore';

  @override
  String get restoreBackup => 'Restore Backup';

  @override
  String get restoreBackupFailed => 'Failed to restore backup';

  @override
  String get restoreConfirmMessage => 'Are you sure you want to restore from this backup? This will replace all your current data.';

  @override
  String get restoreConfirmTitle => 'Restore Confirmation';

  @override
  String get restoreFailure => 'Restore Failed';

  @override
  String get restoreWarningMessage => 'Warning: Current data will be overwritten by backup data. This operation cannot be undone!';

  @override
  String get restoringBackup => 'Restoring from Backup...';

  @override
  String get restoringBackupMessage => 'Restoring backup...';

  @override
  String get retry => 'Retry';

  @override
  String get retryAction => 'Retry';

  @override
  String get rotateLeft => 'Rotate Left';

  @override
  String get rotateRight => 'Rotate Right';

  @override
  String get rotation => 'Rotation';

  @override
  String get safetyBackupBeforePathSwitch => 'Safety backup before data path switching';

  @override
  String get safetyBackupRecommendation => 'To ensure data safety, it\'s recommended to create a backup before switching data path:';

  @override
  String get safetyTip => '💡 Safety Tips:';

  @override
  String get sansSerif => 'Sans Serif';

  @override
  String get save => 'Save';

  @override
  String get saveAs => 'Save As';

  @override
  String get saveComplete => 'Save Complete';

  @override
  String get saveFailed => 'Save Failed, Please Try Again Later';

  @override
  String saveFailedWithError(Object error) {
    return 'Save Failed: $error';
  }

  @override
  String get saveFailure => 'Save Failed';

  @override
  String get savePreview => 'Character Preview:';

  @override
  String get saveSuccess => 'Save Successful';

  @override
  String get saveTimeout => 'Save Timeout';

  @override
  String get savingToStorage => 'Saving to Storage...';

  @override
  String get scale => 'Scale';

  @override
  String get scannedBackupFileDescription => 'Scanned backup file';

  @override
  String get search => 'Search';

  @override
  String get searchCategories => 'Search Categories...';

  @override
  String get searchConfigDialogTitle => 'Search Configuration Items';

  @override
  String get searchConfigHint => 'Enter configuration item name or key';

  @override
  String get searchConfigItems => 'Search Configuration Items';

  @override
  String get searching => 'Searching...';

  @override
  String get select => 'Select';

  @override
  String get selectAll => 'Select All';

  @override
  String get selectAllWithShortcut => 'Select All (Ctrl+Shift+A)';

  @override
  String get selectBackup => 'Select Backup';

  @override
  String get selectBackupFileToImportDialog => 'Select backup file to import';

  @override
  String get selectBackupStorageLocation => 'Select backup storage location';

  @override
  String get selectCategoryToApply => 'Please select a category to apply:';

  @override
  String get selectCharacterFirst => 'Please Select Character First';

  @override
  String selectColor(Object type) {
    return 'Select $type';
  }

  @override
  String get selectDate => 'Select Date';

  @override
  String get selectExportLocation => 'Select Export Location';

  @override
  String get selectExportLocationDialog => 'Select export location';

  @override
  String get selectExportLocationHint => 'Select export location...';

  @override
  String get selectFileError => 'Failed to select file';

  @override
  String get selectFolder => 'Select Folder';

  @override
  String get selectImage => 'Select Image';

  @override
  String get selectImages => 'Select Images';

  @override
  String get selectImagesWithCtrl => 'Select Images (Hold Ctrl for multiple selection)';

  @override
  String get selectImportFile => 'Select Backup File';

  @override
  String get selectNewDataPath => 'Select new data storage path:';

  @override
  String get selectNewDataPathDialog => 'Select new data storage path';

  @override
  String get selectNewDataPathTitle => 'Select new data storage path';

  @override
  String get selectNewPath => 'Select New Path';

  @override
  String get selectParentCategory => 'Select Parent Category';

  @override
  String get selectPath => 'Select Path';

  @override
  String get selectPathButton => 'Select Path';

  @override
  String get selectPathFailed => 'Path selection failed';

  @override
  String get selectSufficientSpaceDisk => 'Recommend choosing a disk with sufficient free space';

  @override
  String get selectTargetLayer => 'Select Target Layer';

  @override
  String get selected => 'Selected';

  @override
  String get selectedCharacter => 'Selected Character';

  @override
  String selectedCount(Object count) {
    return 'Selected $count';
  }

  @override
  String get selectedElementNotFound => 'Selected element not found';

  @override
  String get selectedItems => 'Selected Items';

  @override
  String get selectedPath => 'Selected Path:';

  @override
  String get selectionMode => 'Selection Mode';

  @override
  String get sendToBack => 'Send to Back (Ctrl+B)';

  @override
  String get serif => 'Serif';

  @override
  String get serviceNotReady => 'Service not ready, please try again later';

  @override
  String get setBackupPathFailed => 'Failed to set backup path';

  @override
  String get setCategory => 'Set Category';

  @override
  String setCategoryForItems(Object count) {
    return 'Set Category ($count items)';
  }

  @override
  String get setDataPathFailed => 'Failed to set data path. Please check path permissions and compatibility';

  @override
  String setDataPathFailedWithError(Object error) {
    return 'Failed to set data path: $error';
  }

  @override
  String get settings => 'Settings';

  @override
  String get settingsResetMessage => 'Settings have been reset to default values';

  @override
  String get shortcuts => 'Keyboard Shortcuts';

  @override
  String get showContour => 'Show Contour';

  @override
  String get showDetails => 'Show Details';

  @override
  String get showElement => 'Show Element';

  @override
  String get showGrid => 'Show Grid (Ctrl+G)';

  @override
  String get showHideAllElements => 'Show/Hide All Elements';

  @override
  String get showImagePreview => 'Show Image Preview';

  @override
  String get showThumbnails => 'Show Page Thumbnails';

  @override
  String get skipBackup => 'Skip Backup';

  @override
  String get skipBackupConfirm => 'Skip Backup';

  @override
  String get skipBackupWarning => 'Are you sure you want to skip backup and proceed with path switching?\\n\\nThis may pose a risk of data loss.';

  @override
  String get skipBackupWarningMessage => 'Are you sure you want to skip backup and proceed with path switching?\\n\\nThis may pose a risk of data loss.';

  @override
  String get skipConflicts => 'Skip Conflicts';

  @override
  String get skipConflictsDescription => 'Skip items that already exist';

  @override
  String get skippedCharacters => 'Skipped Characters';

  @override
  String get skippedItems => 'Skipped Items';

  @override
  String get skippedWorks => 'Skipped Works';

  @override
  String get sort => 'Sort';

  @override
  String get sortBy => 'Sort By';

  @override
  String get sortByCreateTime => 'Sort by Creation Time';

  @override
  String get sortByTitle => 'Sort by Title';

  @override
  String get sortByUpdateTime => 'Sort by Update Time';

  @override
  String get sortFailed => 'Sort failed';

  @override
  String get sortOrder => 'Sort Order';

  @override
  String get sortOrderCannotBeEmpty => 'Sort order cannot be empty';

  @override
  String get sortOrderHint => 'Smaller numbers appear first';

  @override
  String get sortOrderLabel => 'Sort Order';

  @override
  String get sortOrderNumber => 'Sort order must be a number';

  @override
  String get sortOrderRange => 'Sort order must be between 1-999';

  @override
  String get sortOrderRequired => 'Please enter sort order value';

  @override
  String get sourceBackupFileNotFound => '源备份文件不存在';

  @override
  String sourceFileNotFound(Object path) {
    return 'Source file not found: $path';
  }

  @override
  String sourceFileNotFoundError(Object path) {
    return 'Source file not found: $path';
  }

  @override
  String get sourceHanSansFont => 'Source Han Sans';

  @override
  String get sourceHanSerifFont => 'Source Han Serif';

  @override
  String get sourceInfo => 'Source Information';

  @override
  String get startBackup => 'Start Backup';

  @override
  String get startDate => 'Start Date';

  @override
  String get stateAndDisplay => 'State and Display';

  @override
  String get statisticsInProgress => 'Calculating...';

  @override
  String get status => 'Status';

  @override
  String get statusAvailable => 'Available';

  @override
  String get statusLabel => 'Status';

  @override
  String get statusUnavailable => 'Unavailable';

  @override
  String get storageDetails => 'Storage Details';

  @override
  String get storageLocation => 'Storage Location';

  @override
  String get storageSettings => 'Storage Settings';

  @override
  String get storageUsed => 'Storage Used';

  @override
  String get stretch => 'Stretch';

  @override
  String get strokeCount => 'Stroke Count';

  @override
  String submitFailed(Object error) {
    return 'Submit Failed: $error';
  }

  @override
  String successDeletedCount(Object count) {
    return 'Successfully deleted $count backup files';
  }

  @override
  String get suggestConfigureBackupPath => 'Suggestion: Configure backup path in settings first';

  @override
  String get suggestConfigureBackupPathFirst => 'Suggestion: Configure backup path in settings first';

  @override
  String get suggestRestartOrWait => 'Suggestion: Restart the app or wait for service initialization to complete';

  @override
  String get suggestRestartOrWaitService => 'Suggestion: Restart the app or wait for service initialization';

  @override
  String get suggestedSolutions => 'Suggested solutions:';

  @override
  String get suggestedTags => 'Suggested Tags';

  @override
  String get switchSuccessful => 'Switch Successful';

  @override
  String get switchingPage => 'Switching to Character Page...';

  @override
  String get systemConfig => 'System Configuration';

  @override
  String get systemConfigItemNote => 'This is a system configuration item, key value cannot be modified';

  @override
  String get systemInfo => 'System Info';

  @override
  String get tabToNextField => 'Press Tab to Navigate to Next Field';

  @override
  String tagAddError(Object error) {
    return 'Failed to Add Tag: $error';
  }

  @override
  String get tagHint => 'Enter Tag Name';

  @override
  String tagRemoveError(Object error) {
    return 'Failed to Remove Tag, Error: $error';
  }

  @override
  String get tags => 'Tags';

  @override
  String get tagsAddHint => 'Enter Tag Name and Press Enter';

  @override
  String get tagsHint => 'Enter Tags...';

  @override
  String get tagsSelected => 'Selected Tags:';

  @override
  String get targetLocationExists => 'A file with the same name already exists at the target location:';

  @override
  String get targetPathLabel => 'Please select an action:';

  @override
  String get text => 'Text';

  @override
  String get textAlign => 'Text Alignment';

  @override
  String get textContent => 'Text Content';

  @override
  String get textElement => 'Text Element';

  @override
  String get textProperties => 'Text Properties';

  @override
  String get textSettings => 'Text Settings';

  @override
  String get textureFillMode => 'Texture Fill Mode';

  @override
  String get textureFillModeContain => 'Contain';

  @override
  String get textureFillModeCover => 'Cover';

  @override
  String get textureFillModeRepeat => 'Repeat';

  @override
  String get textureOpacity => 'Texture Opacity';

  @override
  String get themeMode => 'Theme Mode';

  @override
  String get themeModeDark => 'Dark';

  @override
  String get themeModeDescription => 'Use dark theme for better night viewing experience';

  @override
  String get themeModeSystemDescription => 'Automatically switch between dark/light themes based on system settings';

  @override
  String get thisMonth => 'This Month';

  @override
  String get thisWeek => 'This Week';

  @override
  String get thisYear => 'This Year';

  @override
  String get threshold => 'Threshold';

  @override
  String get thumbnailCheckFailed => 'Thumbnail Check Failed';

  @override
  String get thumbnailEmpty => 'Thumbnail File is Empty';

  @override
  String get thumbnailLoadError => 'Failed to Load Thumbnail';

  @override
  String get thumbnailNotFound => 'Thumbnail Not Found';

  @override
  String get timeInfo => 'Time Information';

  @override
  String get timeLabel => 'Time';

  @override
  String get title => 'Title';

  @override
  String get titleAlreadyExists => 'A practice sheet with the same title already exists, please use a different title';

  @override
  String get titleCannotBeEmpty => 'Title Cannot Be Empty';

  @override
  String get titleExists => 'Title Already Exists';

  @override
  String get titleExistsMessage => 'A practice sheet with the same name already exists. Do you want to overwrite it?';

  @override
  String titleUpdated(Object title) {
    return 'Title Updated to \"$title\"';
  }

  @override
  String get to => 'To';

  @override
  String get today => 'Today';

  @override
  String get toggleBackground => 'Toggle Background';

  @override
  String get toolModePanTooltip => 'Pan Tool (Ctrl+V)';

  @override
  String get toolModeSelectTooltip => 'Box Selection Tool (Ctrl+B)';

  @override
  String get total => 'Total';

  @override
  String get totalBackups => 'Total Backups';

  @override
  String totalItems(Object count) {
    return 'Total $count Items';
  }

  @override
  String get totalSize => 'Total Size';

  @override
  String get transformApplied => 'Transform Applied';

  @override
  String get tryOtherKeywords => 'Try searching with other keywords';

  @override
  String get type => 'Type';

  @override
  String get underline => 'Underline';

  @override
  String get undo => 'Undo';

  @override
  String get ungroup => 'Ungroup (Ctrl+U)';

  @override
  String get ungroupConfirm => 'Confirm Ungroup';

  @override
  String get ungroupDescription => 'Are you sure you want to disband this group?';

  @override
  String get unknown => 'Unknown';

  @override
  String get unknownCategory => 'Unknown Category';

  @override
  String unknownElementType(Object type) {
    return 'Unknown Element Type: $type';
  }

  @override
  String get unknownError => 'Unknown Error';

  @override
  String get unlockElement => 'Unlock Element';

  @override
  String get unlocked => 'Unlocked';

  @override
  String get unnamedElement => 'Unnamed Element';

  @override
  String get unnamedGroup => 'Unnamed Group';

  @override
  String get unnamedLayer => 'Unnamed Layer';

  @override
  String get unsavedChanges => 'Unsaved Changes';

  @override
  String get updateTime => 'Update Time';

  @override
  String get updatedAt => 'Updated At';

  @override
  String get usageInstructions => 'Usage Instructions';

  @override
  String get useDefaultPath => 'Use default path';

  @override
  String get userConfig => 'User Configuration';

  @override
  String get validCharacter => 'Please Enter Valid Character';

  @override
  String get validPath => 'Valid path';

  @override
  String get validateData => 'Validate Data';

  @override
  String get validateDataDescription => 'Verify data integrity before import';

  @override
  String get validateDataMandatory => 'Mandatory validation of import file integrity and format to ensure data security';

  @override
  String get validatingImportFile => 'Validating import file...';

  @override
  String valueTooLarge(Object label, Object max) {
    return '$label Cannot Be Greater Than $max';
  }

  @override
  String valueTooSmall(Object label, Object min) {
    return '$label Cannot Be Less Than $min';
  }

  @override
  String get versionDetails => 'Version Details';

  @override
  String get versionInfoCopied => 'Version info copied to clipboard';

  @override
  String get verticalAlignment => 'Vertical Alignment';

  @override
  String get verticalLeftToRight => 'Vertical Left to Right';

  @override
  String get verticalRightToLeft => 'Vertical Right to Left';

  @override
  String get viewAction => 'View';

  @override
  String get viewDetails => 'View Details';

  @override
  String get viewExportResultsButton => 'View';

  @override
  String get visibility => 'Visibility';

  @override
  String get visible => 'Visible';

  @override
  String get visualProperties => 'Visual Properties';

  @override
  String get visualSettings => 'Visual Settings';

  @override
  String get warningOverwriteData => 'Warning: This will overwrite all current data!';

  @override
  String get warnings => 'Warnings';

  @override
  String get widgetRefRequired => 'WidgetRef Required to Create CollectionPainter';

  @override
  String get width => 'Width';

  @override
  String get windowButtonMaximize => 'Maximize';

  @override
  String get windowButtonMinimize => 'Minimize';

  @override
  String get windowButtonRestore => 'Restore';

  @override
  String get work => 'Work';

  @override
  String get workBrowseSearch => 'Search Works...';

  @override
  String get workBrowseTitle => 'Works';

  @override
  String get workCount => 'Work Count';

  @override
  String get workDetailCharacters => 'Characters';

  @override
  String get workDetailOtherInfo => 'Other Information';

  @override
  String get workDetailTitle => 'Work Details';

  @override
  String get workFormAuthorHelp => 'Optional, the creator of the work';

  @override
  String get workFormAuthorHint => 'Enter Author Name';

  @override
  String get workFormAuthorMaxLength => 'Author name cannot exceed 50 characters';

  @override
  String get workFormAuthorTooltip => 'Press Ctrl+A to quickly jump to author field';

  @override
  String get workFormCreationDateError => 'Creation date cannot exceed current date';

  @override
  String get workFormDateHelp => 'Completion date of the work';

  @override
  String get workFormRemarkHelp => 'Optional, additional information about the work';

  @override
  String get workFormRemarkMaxLength => 'Remarks cannot exceed 500 characters';

  @override
  String get workFormRemarkTooltip => 'Press Ctrl+R to quickly jump to remarks field';

  @override
  String get workFormStyleHelp => 'Primary style type of the work';

  @override
  String get workFormTitleHelp => 'Main title of the work, displayed in the work list';

  @override
  String get workFormTitleMaxLength => 'Title cannot exceed 100 characters';

  @override
  String get workFormTitleMinLength => 'Title must be at least 2 characters';

  @override
  String get workFormTitleRequired => 'Title is required';

  @override
  String get workFormTitleTooltip => 'Press Ctrl+T to quickly jump to title field';

  @override
  String get workFormToolHelp => 'Primary tool used to create this work';

  @override
  String get workIdCannotBeEmpty => 'Work ID cannot be empty';

  @override
  String get workInfo => 'Work Information';

  @override
  String get workStyleClerical => 'Clerical Script';

  @override
  String get workStyleCursive => 'Cursive Script';

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
  String get works => 'Works';

  @override
  String worksCount(Object count) {
    return '$count works';
  }

  @override
  String get writingMode => 'Writing Mode';

  @override
  String get writingTool => 'Writing Tool';

  @override
  String get writingToolManagement => 'Writing Tool Management';

  @override
  String get writingToolText => 'Writing Tool';

  @override
  String get yes => 'Yes';

  @override
  String get yesterday => 'Yesterday';

  @override
  String get zipFile => 'ZIP Archive';

  @override
  String get backgroundTexture => 'Background Texture';

  @override
  String get texturePreview => 'Texture Preview';

  @override
  String get textureSize => 'Texture Size';

  @override
  String get restoreDefaultSize => 'Restore Default Size';

  @override
  String get alignment => 'Alignment';

  @override
  String get imageAlignment => 'Image Alignment';

  @override
  String get imageSizeInfo => 'Image Size';

  @override
  String get imageNameInfo => 'Image Name';

  @override
  String get rotationFineControl => 'Fine Rotation Control';

  @override
  String get rotateClockwise => 'Rotate Clockwise';

  @override
  String get rotateCounterclockwise => 'Rotate Counterclockwise';

  @override
  String get degrees => 'Degrees';

  @override
  String get fineRotation => 'Fine Rotation';

  @override
  String get topLeft => 'Top Left';

  @override
  String get topCenter => 'Top Center';

  @override
  String get topRight => 'Top Right';

  @override
  String get centerLeft => 'Center Left';

  @override
  String get centerRight => 'Center Right';

  @override
  String get bottomLeft => 'Bottom Left';

  @override
  String get bottomCenter => 'Bottom Center';

  @override
  String get bottomRight => 'Bottom Right';

  @override
  String get alignmentCenter => 'Center';

  @override
  String get cropAdjustmentHint => 'Drag the selection box and control points in the preview above to adjust the crop area';

  @override
  String get binarizationProcessing => 'Binarization Processing';

  @override
  String get binarizationToggle => 'Binarization Toggle';

  @override
  String get binarizationParameters => 'Binarization Parameters';

  @override
  String get enableBinarization => 'Enable Binarization';

  @override
  String get binaryThreshold => 'Binary Threshold';

  @override
  String get noiseReductionToggle => 'Noise Reduction Toggle';

  @override
  String get noiseReductionLevel => 'Noise Reduction Level';
}
