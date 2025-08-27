// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get a4Size => 'A4 (210×297mm)';

  @override
  String get a5Size => 'A5 (148×210mm)';

  @override
  String get about => 'について';

  @override
  String get activated => 'アクティブ化';

  @override
  String get activatedDescription => 'アクティブ化 - セレクターに表示';

  @override
  String get activeStatus => 'アクティブ状態';

  @override
  String get add => '追加';

  @override
  String get addCategory => 'カテゴリを追加';

  @override
  String addCategoryItem(Object category) {
    return '$categoryを追加';
  }

  @override
  String get addConfigItem => '設定項目を追加';

  @override
  String addConfigItemHint(Object category) {
    return '右下のボタンをクリックして$category設定項目を追加';
  }

  @override
  String get addFavorite => 'お気に入りに追加';

  @override
  String addFromGalleryFailed(Object error) {
    return 'ギャラリーからの画像追加に失敗しました: $error';
  }

  @override
  String get addImage => '画像を追加';

  @override
  String get addImageHint => 'クリックして画像を追加';

  @override
  String get addImages => '画像を追加';

  @override
  String get addLayer => 'レイヤーを追加';

  @override
  String get addTag => 'タグを追加';

  @override
  String get addWork => '作品を追加';

  @override
  String get addedToCategory => 'カテゴリに追加済み';

  @override
  String addingImagesToGallery(Object count) {
    return '$count枚のローカル画像をギャラリーに追加中...';
  }

  @override
  String get adjust => '調整';

  @override
  String get adjustGridSize => 'グリッドサイズを調整';

  @override
  String get afterDate => '特定の日付以降';

  @override
  String get alignBottom => '下揃え';

  @override
  String get alignCenter => '中央揃え';

  @override
  String get alignHorizontalCenter => '水平方向中央揃え';

  @override
  String get alignLeft => '左揃え';

  @override
  String get alignMiddle => '中央揃え';

  @override
  String get alignRight => '右揃え';

  @override
  String get alignTop => '上揃え';

  @override
  String get alignVerticalCenter => '垂直方向中央揃え';

  @override
  String get alignment => '配置';

  @override
  String get alignmentAssist => '整列補助';

  @override
  String get alignmentCenter => '中央';

  @override
  String get alignmentGrid => 'グリッドスナップモード - クリックでガイドライン整列に切り替え';

  @override
  String get alignmentGuideline => 'ガイドライン整列モード - クリックで補助なしに切り替え';

  @override
  String get alignmentNone => '補助なし整列 - クリックでグリッドスナップを有効化';

  @override
  String get alignmentOperations => '整列操作';

  @override
  String get all => 'すべて';

  @override
  String get allBackupsDeleteWarning => 'この操作は元に戻せません！すべてのバックアップデータが完全に失われます。';

  @override
  String get allCategories => 'すべてのカテゴリ';

  @override
  String get allPages => 'すべてのページ';

  @override
  String get allTime => '全期間';

  @override
  String get allTypes => 'すべてのタイプ';

  @override
  String get analyzePathInfoFailed => 'パス情報の分析に失敗しました';

  @override
  String get appRestartFailed => 'アプリの再起動に失敗しました。手動で再起動してください';

  @override
  String get appRestarting => 'アプリを再起動しています';

  @override
  String get appRestartingMessage => 'データの復元に成功しました。アプリを再起動しています...';

  @override
  String get appStartupFailed => 'アプリの起動に失敗しました';

  @override
  String appStartupFailedWith(Object error) {
    return 'アプリの起動に失敗しました: $error';
  }

  @override
  String get appTitle => '字字珠玉';

  @override
  String get appVersion => 'アプリバージョン';

  @override
  String get appVersionInfo => 'アプリバージョン情報';

  @override
  String get appWillRestartAfterRestore => '復元後、アプリは自動的に再起動します。';

  @override
  String appWillRestartInSeconds(Object message) {
    return '$message\nアプリは3秒後に自動的に再起動します...';
  }

  @override
  String get appWillRestartMessage => '復元完了後、アプリは自動的に再起動します';

  @override
  String get apply => '適用';

  @override
  String get applyFormatBrush => '書式ブラシを適用 (Alt+W)';

  @override
  String get applyNewPath => '新しいパスを適用';

  @override
  String get applyTransform => '変換を適用';

  @override
  String get ascending => '昇順';

  @override
  String get askUser => 'ユーザーに問い合わせる';

  @override
  String get askUserDescription => '各競合についてユーザーに問い合わせる';

  @override
  String get author => '作者';

  @override
  String get autoBackup => '自動バックアップ';

  @override
  String get autoBackupDescription => '定期的にデータを自動バックアップします';

  @override
  String get autoBackupInterval => '自動バックアップ間隔';

  @override
  String get autoBackupIntervalDescription => '自動バックアップの頻度';

  @override
  String get autoCleanup => '自動クリーンアップ';

  @override
  String get autoCleanupDescription => '古いキャッシュファイルを自動的にクリーンアップします';

  @override
  String get autoCleanupInterval => '自動クリーンアップ間隔';

  @override
  String get autoCleanupIntervalDescription => '自動クリーンアップの実行頻度';

  @override
  String get autoDetect => '自動検出';

  @override
  String get autoDetectPageOrientation => 'ページの向きを自動検出';

  @override
  String get autoLineBreak => '自動改行';

  @override
  String get autoLineBreakDisabled => '自動改行が無効になりました';

  @override
  String get autoLineBreakEnabled => '自動改行が有効になりました';

  @override
  String get availableCharacters => '利用可能な文字';

  @override
  String get back => '戻る';

  @override
  String get backgroundColor => '背景色';

  @override
  String get backgroundTexture => '背景テクスチャ';

  @override
  String get backupBeforeSwitchRecommendation => 'データの安全を確保するため、データパスを切り替える前にバックアップを作成することをお勧めします：';

  @override
  String backupChecksum(Object checksum) {
    return 'チェックサム: $checksum...';
  }

  @override
  String get backupCompleted => '✓ バックアップが完了しました';

  @override
  String backupCount(Object count) {
    return '$count個のバックアップ';
  }

  @override
  String backupCountFormat(Object count) {
    return '$count個のバックアップ';
  }

  @override
  String get backupCreatedSuccessfully => 'バックアップが正常に作成され、安全にパスを切り替えることができます';

  @override
  String get backupCreationFailed => 'バックアップの作成に失敗しました';

  @override
  String backupCreationTime(Object time) {
    return '作成日時: $time';
  }

  @override
  String get backupDeletedSuccessfully => 'バックアップは正常に削除されました';

  @override
  String get backupDescription => 'バックアップの説明';

  @override
  String get backupDescriptionHint => 'このバックアップの説明を入力してください';

  @override
  String get backupDescriptionInputExample => '例：週間バックアップ、重要な更新前のバックアップなど';

  @override
  String get backupDescriptionInputLabel => 'バックアップの説明';

  @override
  String backupDescriptionLabel(Object description) {
    return 'バックアップの説明: $description';
  }

  @override
  String get backupEnsuresDataSafety => '• バックアップはデータの安全を確保します';

  @override
  String backupExportedSuccessfully(Object filename) {
    return 'バックアップのエクスポートに成功しました: $filename';
  }

  @override
  String get backupFailure => 'バックアップの作成に失敗しました';

  @override
  String get backupFile => 'バックアップファイル';

  @override
  String get backupFileChecksumMismatchError => 'バックアップファイルのチェックサムが一致しません';

  @override
  String get backupFileCreationFailed => 'バックアップファイルの作成に失敗しました';

  @override
  String get backupFileCreationFailedError => 'バックアップファイルの作成に失敗しました';

  @override
  String backupFileLabel(Object filename) {
    return 'バックアップファイル: $filename';
  }

  @override
  String backupFileListTitle(Object count) {
    return 'バックアップファイルリスト ($count個)';
  }

  @override
  String get backupFileMissingDirectoryStructureError => 'バックアップファイルに必要なディレクトリ構造がありません';

  @override
  String backupFileNotExist(Object path) {
    return 'バックアップファイルが存在しません: $path';
  }

  @override
  String get backupFileNotExistError => 'バックアップファイルが存在しません';

  @override
  String get backupFileNotFound => 'バックアップファイルが見つかりません';

  @override
  String get backupFileSizeMismatchError => 'バックアップファイルのサイズが一致しません';

  @override
  String get backupFileVerificationFailedError => 'バックアップファイルの検証に失敗しました';

  @override
  String get backupFirst => 'まずバックアップ';

  @override
  String get backupImportSuccessMessage => 'バックアップのインポートに成功しました';

  @override
  String get backupImportedSuccessfully => 'バックアップが正常にインポートされました';

  @override
  String get backupImportedToCurrentPath => 'バックアップが現在のパスにインポートされました';

  @override
  String get backupLabel => 'バックアップ';

  @override
  String get backupList => 'バックアップリスト';

  @override
  String get backupLocationTips => '• バックアップ場所として、十分な空き容量のあるディスクを選択することをお勧めします\n• バックアップ場所は、外部ストレージデバイス（例：ポータブルハードディスク）にすることができます\n• バックアップ場所を変更すると、すべてのバックアップ情報が一元管理されます\n• 過去のバックアップファイルは自動的に移動されませんが、バックアップ管理で確認できます';

  @override
  String get backupManagement => 'バックアップ管理';

  @override
  String get backupManagementSubtitle => 'すべてのバックアップファイルの作成、復元、インポート、エクスポート、管理';

  @override
  String get backupMayTakeMinutes => 'バックアップには数分かかる場合があります。アプリを実行し続けてください';

  @override
  String get backupNotAvailable => 'バックアップ管理は現在利用できません';

  @override
  String get backupNotAvailableMessage => 'バックアップ管理機能にはデータベースのサポートが必要です。\n\n考えられる原因：\n• データベースの初期化中\n• データベースの初期化に失敗\n• アプリの起動中\n\nしばらくしてから再試行するか、アプリを再起動してください。';

  @override
  String backupNotFound(Object id) {
    return 'バックアップが見つかりません: $id';
  }

  @override
  String backupNotFoundError(Object id) {
    return 'バックアップが見つかりません: $id';
  }

  @override
  String get backupOperationTimeoutError => 'バックアップ操作がタイムアウトしました。ストレージスペースを確認して再試行してください';

  @override
  String get backupOverview => 'バックアップの概要';

  @override
  String get backupPathDeleted => 'バックアップパスが削除されました';

  @override
  String get backupPathDeletedMessage => 'バックアップパスが削除されました';

  @override
  String get backupPathNotSet => 'まずバックアップパスを設定してください';

  @override
  String get backupPathNotSetError => 'まずバックアップパスを設定してください';

  @override
  String get backupPathNotSetUp => 'バックアップパスがまだ設定されていません';

  @override
  String get backupPathSetSuccessfully => 'バックアップパスが正常に設定されました';

  @override
  String get backupPathSettings => 'バックアップパスの設定';

  @override
  String get backupPathSettingsSubtitle => 'バックアップストレージパスの構成と管理';

  @override
  String backupPreCheckFailed(Object error) {
    return 'バックアップ前のチェックに失敗しました：$error';
  }

  @override
  String get backupReadyRestartMessage => 'バックアップファイルの準備ができました。復元を完了するにはアプリを再起動する必要があります';

  @override
  String get backupRecommendation => 'インポートする前にバックアップを作成することをお勧めします';

  @override
  String get backupRecommendationDescription => 'データの安全を確保するため、インポートする前に手動でバックアップを作成することをお勧めします';

  @override
  String get backupRestartWarning => '変更を適用するにはアプリを再起動してください';

  @override
  String backupRestoreFailedMessage(Object error) {
    return 'バックアップの復元に失敗しました: $error';
  }

  @override
  String get backupRestoreSuccessMessage => 'バックアップの復元に成功しました。復元を完了するにはアプリを再起動してください';

  @override
  String get backupRestoreSuccessWithRestartMessage => 'バックアップの復元に成功しました。変更を適用するにはアプリを再起動する必要があります。';

  @override
  String get backupRestoredSuccessfully => 'バックアップの復元に成功しました。復元を完了するにはアプリを再起動してください';

  @override
  String get backupServiceInitializing => 'バックアップサービスを初期化しています。しばらくしてから再試行してください';

  @override
  String get backupServiceNotAvailable => 'バックアップサービスは現在利用できません';

  @override
  String get backupServiceNotInitialized => 'バックアップサービスが初期化されていません';

  @override
  String get backupServiceNotReady => 'バックアップサービスは現在利用できません';

  @override
  String get backupSettings => 'バックアップ設定';

  @override
  String backupSize(Object size) {
    return 'サイズ: $size';
  }

  @override
  String get backupStatistics => 'バックアップ統計';

  @override
  String get backupStorageLocation => 'バックアップ保存場所';

  @override
  String get backupSuccess => 'バックアップが作成されました';

  @override
  String get backupSuccessCanSwitchPath => 'バックアップが正常に作成され、安全にパスを切り替えることができます';

  @override
  String backupTimeLabel(Object time) {
    return 'バックアップ時刻: $time';
  }

  @override
  String get backupTimeoutDetailedError => 'バックアップ操作がタイムアウトしました。考えられる原因：\n• データ量が多すぎる\n• ストレージ容量が不足している\n• ディスクの読み書き速度が遅い\n\nストレージ容量を確認して再試行してください。';

  @override
  String get backupTimeoutError => 'バックアップの作成がタイムアウトまたは失敗しました。ストレージ容量が十分か確認してください';

  @override
  String get backupVerificationFailed => 'バックアップファイルの検証に失敗しました';

  @override
  String get backups => 'バックアップ';

  @override
  String get backupsCount => '個のバックアップ';

  @override
  String get basicInfo => '基本情報';

  @override
  String get basicProperties => '基本プロパティ';

  @override
  String batchDeleteMessage(Object count) {
    return '$count項目を削除します。この操作は元に戻せません。';
  }

  @override
  String get batchExportFailed => '一括エクスポートに失敗しました';

  @override
  String batchExportFailedMessage(Object error) {
    return '一括エクスポートに失敗しました: $error';
  }

  @override
  String get batchImport => '一括インポート';

  @override
  String get batchMode => 'バッチモード';

  @override
  String get batchOperations => 'バッチ操作';

  @override
  String get beforeDate => '特定の日付以前';

  @override
  String get binarizationParameters => '二値化パラメータ';

  @override
  String get binarizationProcessing => '二値化処理';

  @override
  String get binarizationToggle => '二値化切り替え';

  @override
  String get binaryThreshold => '二値化しきい値';

  @override
  String get border => '境界線';

  @override
  String get borderColor => '境界線の色';

  @override
  String get borderWidth => '境界線の幅';

  @override
  String get bottomCenter => '下中央';

  @override
  String get bottomLeft => '左下';

  @override
  String get bottomRight => '右下';

  @override
  String get boxRegion => 'プレビュー領域で文字を囲んで選択してください';

  @override
  String get boxTool => '収集ツール';

  @override
  String get bringLayerToFront => 'レイヤーを最前面へ';

  @override
  String get bringToFront => '最前面へ移動 (Ctrl+T)';

  @override
  String get browse => '参照';

  @override
  String get browsePath => 'パスを参照';

  @override
  String get brushSize => 'ブラシサイズ';

  @override
  String get buildEnvironment => 'ビルド環境';

  @override
  String get buildNumber => 'ビルド番号';

  @override
  String get buildTime => 'ビルド時間';

  @override
  String get cacheClearedMessage => 'キャッシュが正常にクリアされました';

  @override
  String get cacheSettings => 'キャッシュ設定';

  @override
  String get cacheSize => 'キャッシュサイズ';

  @override
  String get calligraphyStyle => '書道スタイル';

  @override
  String get calligraphyStyleText => '書道スタイル';

  @override
  String get canChooseDirectSwitch => '• 直接切り替えることもできます';

  @override
  String get canCleanOldDataLater => '後で「データパス管理」で古いデータをクリーンアップできます';

  @override
  String get canCleanupLaterViaManagement => '後でデータパス管理を通じて古いデータをクリーンアップできます';

  @override
  String get canManuallyCleanLater => '• 後で古いパスのデータを手動でクリーンアップできます';

  @override
  String get canNotPreview => 'プレビューを生成できません';

  @override
  String get cancel => 'キャンセル';

  @override
  String get cancelAction => 'キャンセル';

  @override
  String get cannotApplyNoImage => '利用可能な画像がありません';

  @override
  String get cannotApplyNoSizeInfo => '画像サイズ情報を取得できません';

  @override
  String get cannotCapturePageImage => 'ページ画像をキャプチャできません';

  @override
  String get cannotDeleteOnlyPage => '唯一のページは削除できません';

  @override
  String get cannotGetStorageInfo => 'ストレージ情報を取得できません';

  @override
  String get cannotReadPathContent => 'パスの内容を読み取れません';

  @override
  String get cannotReadPathFileInfo => 'パスファイル情報を読み取れません';

  @override
  String get cannotSaveMissingController => '保存できません：コントローラーがありません';

  @override
  String get cannotSaveNoPages => 'ページがないため保存できません';

  @override
  String get canvasPixelSize => 'キャンバスのピクセルサイズ';

  @override
  String get canvasResetViewTooltip => 'ビューの位置をリセット';

  @override
  String get categories => 'カテゴリ';

  @override
  String get categoryManagement => 'カテゴリ管理';

  @override
  String get categoryName => 'カテゴリ名';

  @override
  String get categoryNameCannotBeEmpty => 'カテゴリ名は空にできません';

  @override
  String get centerLeft => '左中央';

  @override
  String get centerRight => '右中央';

  @override
  String get centimeter => 'センチメートル';

  @override
  String get changeDataPathMessage => 'データパスを変更した後、変更を有効にするにはアプリケーションを再起動する必要があります。';

  @override
  String get changePath => 'パスを変更';

  @override
  String get character => '文字';

  @override
  String get characterCollection => '文字収集';

  @override
  String characterCollectionFindSwitchFailed(Object error) {
    return 'ページの検索と切り替えに失敗しました：$error';
  }

  @override
  String get characterCollectionPreviewTab => '文字プレビュー';

  @override
  String get characterCollectionResultsTab => '収集結果';

  @override
  String get characterCollectionSearchHint => '文字を検索...';

  @override
  String get characterCollectionTitle => '文字収集';

  @override
  String get characterCollectionToolBox => '収集ツール (Ctrl+B)';

  @override
  String get characterCollectionToolPan => '複数選択ツール (Ctrl+V)';

  @override
  String get characterCollectionUseBoxTool => '矩形選択ツールを使用して画像から文字を抽出します';

  @override
  String get characterCount => '収集文字数';

  @override
  String characterDisplayFormat(Object character) {
    return '文字：$character';
  }

  @override
  String get characterDetailFormatBinary => '二値化';

  @override
  String get characterDetailFormatBinaryDesc => '白黒二値化画像';

  @override
  String get characterDetailFormatDescription => '説明';

  @override
  String get characterDetailFormatOutline => '輪郭';

  @override
  String get characterDetailFormatOutlineDesc => '輪郭のみ表示';

  @override
  String get characterDetailFormatSquareBinary => '正方形二値化';

  @override
  String get characterDetailFormatSquareBinaryDesc => '正方形に整形された二値化画像';

  @override
  String get characterDetailFormatSquareOutline => '正方形輪郭';

  @override
  String get characterDetailFormatSquareOutlineDesc => '正方形に整形された輪郭画像';

  @override
  String get characterDetailFormatSquareTransparent => '正方形透明';

  @override
  String get characterDetailFormatSquareTransparentDesc => '正方形に整形された透明PNG画像';

  @override
  String get characterDetailFormatThumbnail => 'サムネイル';

  @override
  String get characterDetailFormatThumbnailDesc => 'サムネイル';

  @override
  String get characterDetailFormatTransparent => '透明';

  @override
  String get characterDetailFormatTransparentDesc => '背景を除去した透明PNG画像';

  @override
  String get characterDetailLoadError => '文字詳細の読み込みに失敗しました';

  @override
  String get characterDetailSimplifiedChar => '文字';

  @override
  String get characterDetailTitle => '文字詳細';

  @override
  String characterEditSaveConfirmMessage(Object character) {
    return '「$character」を保存しますか？';
  }

  @override
  String get characterUpdated => '文字が更新されました';

  @override
  String get characters => '文字';

  @override
  String charactersCount(Object count) {
    return '$count個の収集文字';
  }

  @override
  String charactersSelected(Object count) {
    return '$count個の文字が選択されました';
  }

  @override
  String get checkBackupRecommendationFailed => 'バックアップ推奨の確認に失敗しました';

  @override
  String get checkFailedRecommendBackup => 'チェックに失敗しました。データの安全を確保するために、まずバックアップを作成することをお勧めします';

  @override
  String get checkSpecialChars => '• 作品のタイトルに特殊文字が含まれていないか確認してください';

  @override
  String get cleanDuplicateRecords => '重複レコードのクリーンアップ';

  @override
  String get cleanDuplicateRecordsDescription => 'この操作は重複したバックアップレコードをクリーンアップしますが、実際のバックアップファイルは削除しません。';

  @override
  String get cleanDuplicateRecordsTitle => '重複レコードのクリーンアップ';

  @override
  String cleanupCompleted(Object count) {
    return 'クリーンアップが完了し、$count個の無効なパスが削除されました';
  }

  @override
  String cleanupCompletedMessage(Object count) {
    return 'クリーンアップが完了し、$count個の無効なパスが削除されました';
  }

  @override
  String cleanupCompletedWithCount(Object count) {
    return 'クリーンアップが完了し、$count個の重複レコードが削除されました';
  }

  @override
  String get cleanupFailed => 'クリーンアップに失敗しました';

  @override
  String cleanupFailedMessage(Object error) {
    return 'クリーンアップに失敗しました: $error';
  }

  @override
  String get cleanupInvalidPaths => '無効なパスのクリーンアップ';

  @override
  String cleanupOperationFailed(Object error) {
    return 'クリーンアップ操作に失敗しました: $error';
  }

  @override
  String get clearCache => 'キャッシュをクリア';

  @override
  String get clearCacheConfirmMessage => 'すべてのキャッシュデータをクリアしますか？これによりディスクスペースが解放されますが、一時的にアプリケーションの速度が低下する可能性があります。';

  @override
  String get clearSelection => '選択をクリア';

  @override
  String get close => '閉じる';

  @override
  String get code => 'コード';

  @override
  String get collapse => '折りたたむ';

  @override
  String get collapseFileList => 'クリックしてファイルリストを折りたたむ';

  @override
  String get collectionDate => '収集日';

  @override
  String get collectionElement => '収集要素';

  @override
  String get collectionTextElement => 'テキスト';

  @override
  String get candidateCharacters => '候補文字';

  @override
  String get characterScale => '文字スケール';

  @override
  String get positionOffset => '位置オフセット';

  @override
  String get scale => '拡大縮小';

  @override
  String get xOffset => 'Xオフセット';

  @override
  String get yOffset => 'Yオフセット';

  @override
  String get reset => 'リセット';

  @override
  String get collectionIdCannotBeEmpty => '収集IDは空にできません';

  @override
  String get collectionTime => '収集時間';

  @override
  String get color => '色';

  @override
  String get colorCode => 'カラーコード';

  @override
  String get colorCodeHelp => '6桁の16進数カラーコードを入力してください (例: FF5500)';

  @override
  String get colorCodeInvalid => '無効なカラーコード';

  @override
  String get colorInversion => '色反転';

  @override
  String get colorPicker => '色を選択';

  @override
  String get colorSettings => '色の設定';

  @override
  String get commonProperties => '共通プロパティ';

  @override
  String get commonTags => 'よく使うタグ:';

  @override
  String get completingSave => '保存を完了しています...';

  @override
  String get compressData => 'データを圧縮';

  @override
  String get compressDataDescription => 'エクスポートファイルのサイズを縮小';

  @override
  String get configInitFailed => '設定データの初期化に失敗しました';

  @override
  String get configInitializationFailed => '設定の初期化に失敗しました';

  @override
  String get configInitializing => '設定を初期化しています...';

  @override
  String get configKey => '設定キー';

  @override
  String get configManagement => '設定管理';

  @override
  String get configManagementDescription => '書道スタイルと筆記具の設定を管理';

  @override
  String get configManagementTitle => '書道スタイル管理';

  @override
  String get confirm => '確認';

  @override
  String get confirmChangeDataPath => 'データパスの変更を確認';

  @override
  String get confirmContinue => '続行しますか？';

  @override
  String get confirmDataNormalBeforeClean => '• データをクリーンアップする前に、データが正常であることを確認することをお勧めします';

  @override
  String get confirmDataPathSwitch => 'データパスの切り替えを確認';

  @override
  String get confirmDelete => '削除の確認';

  @override
  String get confirmDeleteAction => '削除の確認';

  @override
  String get confirmDeleteAll => 'すべて削除の確認';

  @override
  String get confirmDeleteAllBackups => 'すべてのバックアップの削除を確認';

  @override
  String get confirmDeleteAllButton => 'すべて削除を確認';

  @override
  String confirmDeleteBackup(Object description, Object filename) {
    return 'バックアップファイル「$filename」（$description）を削除しますか？\nこの操作は元に戻せません。';
  }

  @override
  String confirmDeleteBackupPath(Object path) {
    return 'バックアップパス全体を削除しますか？\n\nパス：$path\n\nこれにより、以下のようになります：\n• このパス内のすべてのバックアップファイルが削除されます\n• 履歴からこのパスが削除されます\n• この操作は元に戻せません\n\n慎重に操作してください！';
  }

  @override
  String get confirmDeleteButton => '削除を確認';

  @override
  String get confirmDeleteHistoryPath => 'この履歴パスレコードを削除しますか？';

  @override
  String get confirmDeleteTitle => '削除の確認';

  @override
  String get confirmExitWizard => 'データパス切り替えウィザードを終了しますか？';

  @override
  String get confirmImportAction => 'インポートの確認';

  @override
  String get confirmImportButton => 'インポートの確認';

  @override
  String get confirmOverwrite => '上書きの確認';

  @override
  String confirmRemoveFromCategory(Object count) {
    return '選択した$count個の項目を現在のカテゴリから削除しますか？';
  }

  @override
  String get confirmResetToDefaultPath => 'デフォルトパスへのリセットを確認';

  @override
  String get confirmRestoreAction => '復元の確認';

  @override
  String get confirmRestoreBackup => 'このバックアップを復元しますか？';

  @override
  String get confirmRestoreButton => '復元の確認';

  @override
  String get confirmRestoreMessage => '以下のバックアップを復元しようとしています：';

  @override
  String get confirmRestoreTitle => '復元の確認';

  @override
  String get confirmShortcuts => 'ショートカット：Enterで確認、Escでキャンセル';

  @override
  String get confirmSkip => 'スキップの確認';

  @override
  String get confirmSkipAction => 'スキップの確認';

  @override
  String get confirmSwitch => '切り替えの確認';

  @override
  String get confirmSwitchButton => '切り替えの確認';

  @override
  String get confirmSwitchToNewPath => '新しいデータパスへの切り替えを確認';

  @override
  String get conflictDetailsTitle => '競合処理の詳細';

  @override
  String get conflictReason => '競合の理由';

  @override
  String get conflictResolution => '競合の解決';

  @override
  String conflictsCount(Object count) {
    return '$count個の競合が見つかりました';
  }

  @override
  String get conflictsFound => '競合が見つかりました';

  @override
  String get contentProperties => 'コンテンツのプロパティ';

  @override
  String get contentSettings => 'コンテンツの設定';

  @override
  String get continueDuplicateImport => 'このバックアップをインポートし続けますか？';

  @override
  String get continueImport => 'インポートを続行';

  @override
  String get continueQuestion => '続行しますか？';

  @override
  String get copy => 'コピー';

  @override
  String copyFailed(Object error) {
    return 'コピーに失敗しました: $error';
  }

  @override
  String get copyFormat => '書式をコピー (Alt+Q)';

  @override
  String get copySelected => '選択項目をコピー';

  @override
  String get copyVersionInfo => 'バージョン情報をコピー';

  @override
  String get couldNotGetFilePath => 'ファイルパスを取得できませんでした';

  @override
  String get countUnit => '個';

  @override
  String get create => '作成';

  @override
  String get createBackup => 'バックアップを作成';

  @override
  String get createBackupBeforeImport => 'インポート前にバックアップを作成';

  @override
  String get createBackupDescription => '新しいデータバックアップを作成';

  @override
  String get createBackupFailed => 'バックアップの作成に失敗しました';

  @override
  String createBackupFailedMessage(Object error) {
    return 'バックアップの作成に失敗しました: $error';
  }

  @override
  String createExportDirectoryFailed(Object error) {
    return 'エクスポートディレクトリの作成に失敗しました$error';
  }

  @override
  String get createFirstBackup => '最初のバックアップを作成';

  @override
  String get createTime => '作成日時';

  @override
  String get createdAt => '作成日時';

  @override
  String get creatingBackup => 'バックアップを作成中...';

  @override
  String get creatingBackupPleaseWaitMessage => 'これには数分かかる場合があります。しばらくお待ちください';

  @override
  String get creatingBackupProgressMessage => 'バックアップを作成中...';

  @override
  String get creationDate => '作成日';

  @override
  String get criticalError => '重大なエラー';

  @override
  String get cropAdjustmentHint => '上のプレビュー画像で選択ボックスとコントロールポイントをドラッグしてクロップ領域を調整してください';

  @override
  String get cropBottom => '下をトリミング';

  @override
  String get cropLeft => '左をトリミング';

  @override
  String get cropRight => '右をトリミング';

  @override
  String get cropTop => '上をトリミング';

  @override
  String get cropping => 'トリミング';

  @override
  String croppingApplied(Object bottom, Object left, Object right, Object top) {
    return '(トリミング：左${left}px、上${top}px、右${right}px、下${bottom}px)';
  }

  @override
  String get crossPagePasteSuccess => 'ページ間ペースト成功';

  @override
  String get currentBackupPathNotSet => '現在のバックアップパスが設定されていません';

  @override
  String get currentCharInversion => '現在の文字反転';

  @override
  String get currentCustomPath => '現在、カスタムデータパスを使用しています';

  @override
  String get currentDataPath => '現在のデータパス';

  @override
  String get currentDefaultPath => '現在、デフォルトのデータパスを使用しています';

  @override
  String get currentLabel => '現在';

  @override
  String get currentLocation => '現在の場所';

  @override
  String get currentPage => '現在のページ';

  @override
  String get currentPath => '現在のパス';

  @override
  String get currentPathBackup => '現在のパスのバックアップ';

  @override
  String get currentPathBackupDescription => '現在のパスのバックアップ';

  @override
  String get currentPathFileExists => '現在のパスに同名のバックアップファイルが既に存在します：';

  @override
  String get currentPathFileExistsMessage => '現在のパスに同名のバックアップファイルが既に存在します：';

  @override
  String get currentStorageInfo => '現在のストレージ情報';

  @override
  String get currentStorageInfoSubtitle => '現在のストレージ使用状況を表示';

  @override
  String get currentStorageInfoTitle => '現在のストレージ情報';

  @override
  String get currentTool => '現在のツール';

  @override
  String get pageInfo => 'ページ';

  @override
  String get custom => 'カスタム';

  @override
  String get customPath => 'カスタムパス';

  @override
  String get customRange => 'カスタム範囲';

  @override
  String get customSize => 'カスタムサイズ';

  @override
  String get cutSelected => '選択項目を切り取り';

  @override
  String get dangerZone => '危険区域';

  @override
  String get dangerousOperationConfirm => '危険な操作の確認';

  @override
  String get dangerousOperationConfirmTitle => '危険な操作の確認';

  @override
  String get dartVersion => 'Dartバージョン';

  @override
  String get dataBackup => 'データバックアップ';

  @override
  String get dataEmpty => 'データが空です';

  @override
  String get dataIncomplete => 'データが不完全です';

  @override
  String get dataMergeOptions => 'データ結合オプション：';

  @override
  String get dataPath => 'データパス';

  @override
  String get dataPathChangedMessage => 'データパスが変更されました。変更を有効にするにはアプリケーションを再起動してください。';

  @override
  String get dataPathHint => 'データ保存パスを選択';

  @override
  String get dataPathManagement => 'データパス管理';

  @override
  String get dataPathManagementSubtitle => '現在および過去のデータパスを管理';

  @override
  String get dataPathManagementTitle => 'データパス管理';

  @override
  String get dataPathSettings => 'データパス設定';

  @override
  String get dataPathSettingsDescription => 'アプリデータの保存場所を設定します。変更後はアプリケーションの再起動が必要です。';

  @override
  String get dataPathSettingsSubtitle => 'アプリデータの保存場所を設定';

  @override
  String get dataPathSwitchOptions => 'データパス切り替えオプション';

  @override
  String get dataPathSwitchWizard => 'データパス切り替えウィザード';

  @override
  String get dataSafetyRecommendation => 'データ安全に関する推奨事項';

  @override
  String get dataSafetySuggestion => 'データ安全に関する提案';

  @override
  String get dataSafetySuggestions => 'データ安全に関する提案';

  @override
  String get dataSize => 'データサイズ';

  @override
  String get databaseSize => 'データベースサイズ';

  @override
  String get dayBeforeYesterday => '一昨日';

  @override
  String days(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count日',
      one: '1日',
    );
    return '$_temp0';
  }

  @override
  String get daysAgo => '日前';

  @override
  String get defaultEditableText => 'プロパティパネルの編集テキスト';

  @override
  String get defaultLayer => 'デフォルトレイヤー';

  @override
  String defaultLayerName(Object number) {
    return 'レイヤー$number';
  }

  @override
  String get defaultPage => 'デフォルトページ';

  @override
  String defaultPageName(Object number) {
    return 'ページ$number';
  }

  @override
  String get defaultPath => 'デフォルトパス';

  @override
  String get defaultPathName => 'デフォルトパス';

  @override
  String get degrees => '度';

  @override
  String get delete => '削除';

  @override
  String get deleteAll => 'すべて削除';

  @override
  String get deleteAllBackups => 'すべてのバックアップを削除';

  @override
  String get deleteBackup => 'バックアップを削除';

  @override
  String get deleteBackupFailed => 'バックアップの削除に失敗しました';

  @override
  String deleteBackupsCountMessage(Object count) {
    return '$count個のバックアップファイルを削除しようとしています。';
  }

  @override
  String get deleteCategory => 'カテゴリを削除';

  @override
  String get deleteCategoryOnly => 'カテゴリのみ削除';

  @override
  String get deleteCategoryWithFiles => 'カテゴリとファイルを削除';

  @override
  String deleteCharacterFailed(Object error) {
    return '文字の削除に失敗しました：$error';
  }

  @override
  String get deleteCompleteTitle => '削除完了';

  @override
  String get deleteConfigItem => '設定項目を削除';

  @override
  String get deleteConfigItemMessage => 'この設定項目を削除しますか？この操作は元に戻せません。';

  @override
  String get deleteConfirm => '削除の確認';

  @override
  String get deleteElementConfirmMessage => 'これらの要素を削除しますか？';

  @override
  String deleteFailCount(Object count) {
    return '削除失敗: $count個のファイル';
  }

  @override
  String get deleteFailDetails => '失敗の詳細:';

  @override
  String deleteFailed(Object error) {
    return '削除に失敗しました：$error';
  }

  @override
  String deleteFailedMessage(Object error) {
    return '削除に失敗しました: $error';
  }

  @override
  String get deleteFailure => 'バックアップの削除に失敗しました';

  @override
  String get deleteGroup => 'グループを削除';

  @override
  String get deleteGroupConfirm => 'グループの削除を確認';

  @override
  String get deleteHistoryPathNote => '注意：これはレコードのみを削除し、実際のフォルダとデータは削除しません。';

  @override
  String get deleteHistoryPathRecord => '履歴パスレコードを削除';

  @override
  String get deleteImage => '画像を削除';

  @override
  String get deleteLastMessage => 'これが最後の項目です。削除しますか？';

  @override
  String get deleteLayer => 'レイヤーを削除';

  @override
  String get deleteLayerConfirmMessage => 'このレイヤーを削除しますか？';

  @override
  String get deleteLayerMessage => 'このレイヤー上のすべての要素が削除されます。この操作は元に戻せません。';

  @override
  String deleteMessage(Object count) {
    return '$count項目を削除します。この操作は元に戻せません。';
  }

  @override
  String get deletePage => 'ページを削除';

  @override
  String get deletePath => 'パスを削除';

  @override
  String get deletePathButton => 'パスを削除';

  @override
  String deletePathConfirmContent(Object path) {
    return 'バックアップパス $path を削除しますか？この操作は元に戻せず、このパス内のすべてのバックアップファイルが削除されます。';
  }

  @override
  String deleteRangeItem(Object count, Object path) {
    return '• $path: $count個のファイル';
  }

  @override
  String get deleteRangeTitle => '削除範囲には以下が含まれます：';

  @override
  String get deleteSelected => '選択項目を削除';

  @override
  String get deleteSelectedArea => '選択範囲を削除';

  @override
  String get deleteSelectedWithShortcut => '選択項目を削除 (Ctrl+D)';

  @override
  String get deleteSuccess => '削除が完了しました';

  @override
  String deleteSuccessCount(Object count) {
    return '正常に削除: $count個のファイル';
  }

  @override
  String get deleteText => '削除';

  @override
  String get deleting => '削除中...';

  @override
  String get deletingBackups => 'バックアップを削除中...';

  @override
  String get deletingBackupsProgress => 'バックアップファイルを削除しています。しばらくお待ちください...';

  @override
  String get descending => '降順';

  @override
  String get descriptionLabel => '説明';

  @override
  String get deselectAll => '選択をすべて解除';

  @override
  String get detail => '詳細';

  @override
  String get detailedError => '詳細なエラー';

  @override
  String get detailedReport => '詳細レポート';

  @override
  String get deviceInfo => 'デバイス情報';

  @override
  String get dimensions => '寸法';

  @override
  String get directSwitch => '直接切り替え';

  @override
  String get disabled => '無効';

  @override
  String get disabledDescription => '無効 - セレクターで非表示';

  @override
  String get diskCacheSize => 'ディスクキャッシュサイズ';

  @override
  String get diskCacheSizeDescription => 'ディスクキャッシュの最大サイズ';

  @override
  String get diskCacheTtl => 'ディスクキャッシュの有効期間';

  @override
  String get diskCacheTtlDescription => 'キャッシュファイルがディスクに保持される時間';

  @override
  String get displayMode => '表示モード';

  @override
  String get displayName => '表示名';

  @override
  String get displayNameCannotBeEmpty => '表示名は空にできません';

  @override
  String get displayNameHint => 'ユーザーインターフェースに表示される名前';

  @override
  String get displayNameMaxLength => '表示名は最大100文字です';

  @override
  String get displayNameRequired => '表示名を入力してください';

  @override
  String get distributeHorizontally => '水平方向に均等に配置';

  @override
  String get distributeVertically => '垂直方向に均等に配置';

  @override
  String get distribution => '配置';

  @override
  String get doNotCloseApp => 'アプリケーションを閉じないでください...';

  @override
  String get doNotCloseAppMessage => 'アプリを閉じないでください。復元プロセスには数分かかる場合があります';

  @override
  String get done => '完了';

  @override
  String get dropToImportImages => 'マウスを離して画像をインポート';

  @override
  String get duplicateBackupFound => '重複したバックアップが見つかりました';

  @override
  String get duplicateBackupFoundDesc => 'インポートしようとしているバックアップファイルが、既存のバックアップと重複していることが検出されました：';

  @override
  String get duplicateFileImported => '（重複ファイルをインポートしました）';

  @override
  String get dynasty => '王朝';

  @override
  String get edit => '編集';

  @override
  String get editConfigItem => '設定項目を編集';

  @override
  String editField(Object field) {
    return '$fieldを編集';
  }

  @override
  String get editGroupContents => 'グループの内容を編集';

  @override
  String get editGroupContentsDescription => '選択したグループの内容を編集';

  @override
  String editLabel(Object label) {
    return '$labelを編集';
  }

  @override
  String get editOperations => '編集操作';

  @override
  String get editTags => 'タグを編集';

  @override
  String get editTitle => 'タイトルを編集';

  @override
  String get elementCopied => '要素がクリップボードにコピーされました';

  @override
  String get elementCopiedToClipboard => '要素がクリップボードにコピーされました';

  @override
  String get elementHeight => '高さ';

  @override
  String get elementId => '要素ID';

  @override
  String get elementSize => 'サイズ';

  @override
  String get elementWidth => '幅';

  @override
  String get elements => '要素';

  @override
  String get empty => '空';

  @override
  String get emptyGroup => '空のグループ';

  @override
  String get emptyStateError => '読み込みに失敗しました。後でもう一度お試しください';

  @override
  String get emptyStateNoCharacters => 'グリフがありません。作品からグリフを抽出すると、ここで表示できます';

  @override
  String get emptyStateNoPractices => '練習帳がありません。追加ボタンをクリックして新しい練習帳を作成してください';

  @override
  String get emptyStateNoResults => '一致する結果が見つかりませんでした。検索条件を変更してみてください';

  @override
  String get emptyStateNoSelection => '何も選択されていません。項目をクリックして選択してください';

  @override
  String get emptyStateNoWorks => '作品がありません。追加ボタンをクリックして作品をインポートしてください';

  @override
  String get enableBinarization => '二値化を有効にする';

  @override
  String get enabled => '有効';

  @override
  String get endDate => '終了日';

  @override
  String get ensureCompleteTransfer => '• ファイルが完全に転送されたことを確認してください';

  @override
  String get ensureReadWritePermission => '新しいパスに読み取り/書き込み権限があることを確認してください';

  @override
  String get enterBackupDescription => 'バックアップの説明を入力してください（オプション）：';

  @override
  String get enterCategoryName => 'カテゴリ名を入力してください';

  @override
  String get enterTagHint => 'タグを入力してEnterキーを押してください';

  @override
  String error(Object message) {
    return 'エラー：$message';
  }

  @override
  String get errors => 'エラー';

  @override
  String get estimatedTime => '推定時間';

  @override
  String get executingImportOperation => 'インポート操作を実行中...';

  @override
  String existingBackupInfo(Object filename) {
    return '既存のバックアップ: $filename';
  }

  @override
  String get existingItem => '既存の項目';

  @override
  String get exit => '終了';

  @override
  String get exitBatchMode => 'バッチモードを終了';

  @override
  String get exitConfirm => '終了';

  @override
  String get exitPreview => 'プレビューモードを終了';

  @override
  String get exitWizard => 'ウィザードを終了';

  @override
  String get expand => '展開';

  @override
  String expandFileList(Object count) {
    return 'クリックして$count個のバックアップファイルを表示';
  }

  @override
  String get export => 'エクスポート';

  @override
  String get exportAllBackups => 'すべてのバックアップをエクスポート';

  @override
  String get exportAllBackupsButton => 'すべてのバックアップをエクスポート';

  @override
  String get exportBackup => 'バックアップをエクスポート';

  @override
  String get exportBackupFailed => 'バックアップのエクスポートに失敗しました';

  @override
  String exportBackupFailedMessage(Object error) {
    return 'バックアップのエクスポートに失敗しました: $error';
  }

  @override
  String get exportCharactersOnly => '収集文字のみエクスポート';

  @override
  String get exportCharactersOnlyDescription => '選択した収集文字データのみを含む';

  @override
  String get exportCharactersWithWorks => '収集文字と出典作品をエクスポート（推奨）';

  @override
  String get exportCharactersWithWorksDescription => '収集文字とその出典作品データを含む';

  @override
  String exportCompleted(Object failed, Object success) {
    return 'エクスポート完了: 成功 $success個$failed';
  }

  @override
  String exportCompletedFormat(Object failedMessage, Object successCount) {
    return 'エクスポート完了: 成功 $successCount個$failedMessage';
  }

  @override
  String exportCompletedFormat2(Object failed, Object success) {
    return 'エクスポート完了、成功: $success$failed';
  }

  @override
  String get exportConfig => '設定をエクスポート';

  @override
  String get exportDialogRangeExample => '例: 1-3,5,7-9';

  @override
  String exportDimensions(Object height, Object orientation, Object width) {
    return '$widthセンチ × $heightセンチ ($orientation)';
  }

  @override
  String get exportEncodingIssue => '• エクスポート時に特殊文字のエンコーディング問題が発生';

  @override
  String get exportFailed => 'エクスポートに失敗しました';

  @override
  String exportFailedPartFormat(Object failCount) {
    return '、失敗 $failCount個';
  }

  @override
  String exportFailedPartFormat2(Object count) {
    return '、失敗: $count';
  }

  @override
  String exportFailedWith(Object error) {
    return 'エクスポートに失敗しました: $error';
  }

  @override
  String get exportFailure => 'バックアップのエクスポートに失敗しました';

  @override
  String get exportFormat => 'エクスポート形式';

  @override
  String get exportFullData => '完全なデータのエクスポート';

  @override
  String get exportFullDataDescription => '関連するすべてのデータを含む';

  @override
  String get exportLocation => 'エクスポート先';

  @override
  String get exportNotImplemented => '設定のエクスポート機能は未実装です';

  @override
  String get exportOptions => 'エクスポートオプション';

  @override
  String get exportSuccess => 'エクスポートが完了しました';

  @override
  String exportSuccessMessage(Object path) {
    return 'バックアップのエクスポートに成功しました: $path';
  }

  @override
  String get exportSummary => 'エクスポートの概要';

  @override
  String get exportType => 'エクスポート形式';

  @override
  String get exportWorksOnly => '作品のみエクスポート';

  @override
  String get exportWorksOnlyDescription => '選択した作品データのみを含む';

  @override
  String get exportWorksWithCharacters => '作品と関連する収集文字をエクスポート（推奨）';

  @override
  String get exportWorksWithCharactersDescription => '作品とそれに関連する収集文字データを含む';

  @override
  String get exporting => 'エクスポート中です、しばらくお待ちください...';

  @override
  String get exportingBackup => 'バックアップをエクスポート中...';

  @override
  String get exportingBackupMessage => 'バックアップをエクスポート中...';

  @override
  String exportingBackups(Object count) {
    return '$count個のバックアップをエクスポート中...';
  }

  @override
  String get exportingBackupsProgress => 'バックアップをエクスポート中...';

  @override
  String exportingBackupsProgressFormat(Object count) {
    return '$count個のバックアップファイルをエクスポート中...';
  }

  @override
  String get exportingDescription => 'データをエクスポート中です、しばらくお待ちください...';

  @override
  String get extract => '抽出';

  @override
  String get extractionError => '抽出中にエラーが発生しました';

  @override
  String failedCount(Object count) {
    return '、失敗 $count個';
  }

  @override
  String get favorite => 'お気に入り';

  @override
  String get favoritesOnly => 'お気に入りのみ表示';

  @override
  String get fileCorrupted => '• 転送中にファイルが破損しました';

  @override
  String get fileCount => 'ファイル数';

  @override
  String get fileExistsTitle => 'ファイルは既に存在します';

  @override
  String get fileExtension => 'ファイル拡張子';

  @override
  String get fileMigrationWarning => 'ファイルを移行しない場合、古いパスのバックアップファイルは元の場所に残ります';

  @override
  String get fileName => 'ファイル名';

  @override
  String fileNotExist(Object path) {
    return 'ファイルが存在しません：$path';
  }

  @override
  String get fileRestored => '画像がギャラリーから復元されました';

  @override
  String get fileSize => 'ファイルサイズ';

  @override
  String get fileUpdatedAt => 'ファイル更新日時';

  @override
  String get filenamePrefix => 'ファイル名のプレフィックスを入力（ページ番号が自動的に追加されます）';

  @override
  String get files => 'ファイル';

  @override
  String get filter => 'フィルター';

  @override
  String get filterAndSort => 'フィルタリングと並べ替え';

  @override
  String get filterClear => 'クリア';

  @override
  String get fineRotation => '微細回転';

  @override
  String get firstPage => '最初のページ';

  @override
  String get fitContain => '含む';

  @override
  String get fitCover => 'カバー';

  @override
  String get fitFill => 'フィル';

  @override
  String get fitHeight => '高さに合わせる';

  @override
  String get fitMode => 'フィットモード';

  @override
  String get fitWidth => '幅に合わせる';

  @override
  String get flip => '反転';

  @override
  String get flipHorizontal => '水平反転';

  @override
  String get flipOptions => '反転オプション';

  @override
  String get flipVertical => '垂直反転';

  @override
  String get flutterVersion => 'Flutterバージョン';

  @override
  String get folderImportComplete => 'フォルダのインポートが完了しました';

  @override
  String get fontColor => 'テキストの色';

  @override
  String get fontFamily => 'フォント';

  @override
  String get fontSize => 'フォントサイズ';

  @override
  String get fontStyle => 'フォントスタイル';

  @override
  String get fontTester => 'フォントテストツール';

  @override
  String get fontWeight => 'フォントの太さ';

  @override
  String get fontWeightTester => 'フォントの太さテストツール';

  @override
  String get format => 'フォーマット';

  @override
  String get formatBrushActivated => 'フォーマットブラシが有効になりました。対象の要素をクリックしてスタイルを適用してください';

  @override
  String get formatType => 'フォーマットタイプ';

  @override
  String get fromGallery => 'ギャラリーから選択';

  @override
  String get fromLocal => 'ローカルから選択';

  @override
  String get fullScreen => '全画面表示';

  @override
  String get geometryProperties => 'ジオメトリプロパティ';

  @override
  String get getHistoryPathsFailed => '履歴パスの取得に失敗しました';

  @override
  String get getPathInfoFailed => 'パス情報の取得に失敗しました';

  @override
  String get getPathUsageTimeFailed => 'パス使用時間の取得に失敗しました';

  @override
  String get getStorageInfoFailed => 'ストレージ情報の取得に失敗しました';

  @override
  String get getThumbnailSizeError => 'サムネイルサイズの取得に失敗しました';

  @override
  String get gettingPathInfo => 'パス情報を取得中...';

  @override
  String get gettingStorageInfo => 'ストレージ情報を取得中...';

  @override
  String get gitBranch => 'Gitブランチ';

  @override
  String get gitCommit => 'Gitコミット';

  @override
  String get goToBackup => 'バックアップへ移動';

  @override
  String get gridSettings => 'グリッド設定';

  @override
  String get gridSize => 'グリッドサイズ';

  @override
  String get gridSizeExtraLarge => '特大';

  @override
  String get gridSizeLarge => '大';

  @override
  String get gridSizeMedium => '中';

  @override
  String get gridSizeSmall => '小';

  @override
  String get gridView => 'グリッドビュー';

  @override
  String get group => 'グループ化 (Ctrl+J)';

  @override
  String get groupElements => '要素をグループ化';

  @override
  String get groupOperations => 'グループ操作';

  @override
  String get groupProperties => 'グループプロパティ';

  @override
  String get height => '高さ';

  @override
  String get help => 'ヘルプ';

  @override
  String get hideDetails => '詳細を隠す';

  @override
  String get hideElement => '要素を隠す';

  @override
  String get hideGrid => 'グリッドを非表示 (Ctrl+G)';

  @override
  String get hideImagePreview => '画像プレビューを非表示';

  @override
  String get hideThumbnails => 'ページサムネイルを非表示';

  @override
  String get hideToolbar => 'ツールバーを非表示';

  @override
  String get historicalPaths => '履歴パス';

  @override
  String get historyDataPaths => '履歴データパス';

  @override
  String get historyLabel => '履歴';

  @override
  String get historyLocation => '履歴の場所';

  @override
  String get historyPath => '履歴パス';

  @override
  String get historyPathBackup => '履歴パスのバックアップ';

  @override
  String get historyPathBackupDescription => '履歴パスのバックアップ';

  @override
  String get historyPathDeleted => '履歴パスの記録が削除されました';

  @override
  String get homePage => 'ホーム';

  @override
  String get horizontalAlignment => '水平方向の配置';

  @override
  String get horizontalLeftToRight => '横書き（左から右へ）';

  @override
  String get horizontalRightToLeft => '横書き（右から左へ）';

  @override
  String hours(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count時間',
      one: '1時間',
    );
    return '$_temp0';
  }

  @override
  String get hoursAgo => '時間前';

  @override
  String get image => '画像';

  @override
  String get imageAlignment => '画像配置';

  @override
  String get imageCount => '画像数';

  @override
  String get imageElement => '画像要素';

  @override
  String get imageExportFailed => '画像のエクスポートに失敗しました';

  @override
  String get imageFileNotExists => '画像ファイルが存在しません';

  @override
  String imageImportError(Object error) {
    return '画像のインポートに失敗しました：$error';
  }

  @override
  String get imageImportSuccess => '画像のインポートに成功しました';

  @override
  String get imageIndexError => '画像のインデックスエラー';

  @override
  String get imageInvalid => '画像データが無効または破損しています';

  @override
  String get imageInvert => '画像の反転';

  @override
  String imageLoadError(Object error) {
    return '画像の読み込みに失敗しました：$error...';
  }

  @override
  String get imageLoadFailed => '画像の読み込みに失敗しました';

  @override
  String get imageNameInfo => '画像名';

  @override
  String imageProcessingPathError(Object error) {
    return '処理パスエラー：$error';
  }

  @override
  String get imageProperties => '画像のプロパティ';

  @override
  String get imagePropertyPanelAutoImportNotice => '選択した画像は、より良い管理のために自動的にギャラリーにインポートされます';

  @override
  String get imagePropertyPanelFlipInfo => '反転効果はキャンバスレンダリング段階で処理され、画像データを再処理することなく即座に有効になります。反転は純粋な視覚変換で、画像処理パイプラインから独立しています。';

  @override
  String get imagePropertyPanelGeometryWarning => 'これらのプロパティは、画像コンテンツ自体ではなく、要素ボックス全体を調整します';

  @override
  String get imagePropertyPanelPreviewNotice => '注意：プレビュー中に表示される重複ログは正常です';

  @override
  String get imagePropertyPanelTransformWarning => 'これらの変換は、要素フレームだけでなく、画像コンテンツ自体を変更します';

  @override
  String get imageResetSuccess => 'リセットに成功しました';

  @override
  String get imageRestoring => '画像データを復元中...';

  @override
  String get imageSelection => '画像の選択';

  @override
  String get imageSizeInfo => '画像サイズ';

  @override
  String get imageTransform => '画像の変換';

  @override
  String imageTransformError(Object error) {
    return '変換の適用に失敗しました：$error';
  }

  @override
  String get imageUpdated => '画像が更新されました';

  @override
  String get images => '画像';

  @override
  String get implementationComingSoon => 'この機能は開発中です。ご期待ください！';

  @override
  String get import => 'インポート';

  @override
  String get importBackup => 'バックアップをインポート';

  @override
  String get importBackupFailed => 'バックアップのインポートに失敗しました';

  @override
  String importBackupFailedMessage(Object error) {
    return 'バックアップのインポートに失敗しました: $error';
  }

  @override
  String get importBackupProgressDialog => '現在のパスにバックアップをインポート中...';

  @override
  String get importBackupSuccessMessage => '現在のパスにバックアップが正常にインポートされました';

  @override
  String get importConfig => '設定をインポート';

  @override
  String get importError => 'インポートエラー';

  @override
  String get importErrorCauses => 'この問題は通常、以下の原因によって引き起こされます：';

  @override
  String importFailed(Object error) {
    return 'インポートに失敗しました：$error';
  }

  @override
  String get importFailure => 'バックアップのインポートに失敗しました';

  @override
  String get importFileSuccess => 'ファイルのインポートに成功しました';

  @override
  String get importFiles => 'ファイルをインポート';

  @override
  String get importFolder => 'フォルダをインポート';

  @override
  String get importNotImplemented => '設定のインポート機能は未実装です';

  @override
  String get importOptions => 'インポートオプション';

  @override
  String get importPreview => 'インポートプレビュー';

  @override
  String get importRequirements => 'インポート要件';

  @override
  String get importResultTitle => 'インポート結果';

  @override
  String get importStatistics => 'インポート統計';

  @override
  String get importSuccess => 'インポートが完了しました';

  @override
  String importSuccessMessage(Object count) {
    return '$count個のファイルを正常にインポートしました';
  }

  @override
  String get importToCurrentPath => '現在のパスにインポート';

  @override
  String get importToCurrentPathButton => '現在のパスにインポート';

  @override
  String get importToCurrentPathConfirm => '現在のパスにインポート';

  @override
  String get importToCurrentPathDesc => 'これにより、バックアップファイルが現在のパスにコピーされ、元のファイルは変更されません。';

  @override
  String get importToCurrentPathDescription => 'インポート後、このバックアップは現在のパスのバックアップリストに表示されます';

  @override
  String get importToCurrentPathDialogContent => 'これによりバックアップが現在のバックアップパスにインポートされます。続行してもよろしいですか？';

  @override
  String get importToCurrentPathFailed => '現在のパスへのバックアップのインポートに失敗しました';

  @override
  String get importToCurrentPathMessage => 'このバックアップファイルを現在のバックアップパスにインポートしようとしています：';

  @override
  String get importToCurrentPathSuccessMessage => 'バックアップが現在のパスに正常にインポートされました';

  @override
  String get importToCurrentPathTitle => '現在のパスにインポート';

  @override
  String get importantReminder => '重要なお知らせ';

  @override
  String get importedBackupDescription => 'インポートされたバックアップ';

  @override
  String get importedCharacters => 'インポートされた収集文字';

  @override
  String get importedFile => 'インポートされたファイル';

  @override
  String get importedImages => 'インポートされた画像';

  @override
  String get importedSuffix => 'インポートされたバックアップ';

  @override
  String get importedWorks => 'インポートされた作品';

  @override
  String get importing => 'インポート中...';

  @override
  String get importingBackup => 'バックアップをインポート中...';

  @override
  String get importingBackupProgressMessage => 'バックアップをインポート中...';

  @override
  String get importingDescription => 'データをインポート中です、しばらくお待ちください...';

  @override
  String get importingToCurrentPath => '現在のパスにインポート中...';

  @override
  String get importingToCurrentPathMessage => '現在のパスにインポート中...';

  @override
  String get importingWorks => '作品をインポート中...';

  @override
  String get includeImages => '画像を含む';

  @override
  String get includeImagesDescription => '関連する画像ファイルをエクスポート';

  @override
  String get includeMetadata => 'メタデータを含む';

  @override
  String get includeMetadataDescription => '作成日時、タグなどのメタデータをエクスポート';

  @override
  String get incompatibleCharset => '• 互換性のない文字セットが使用されています';

  @override
  String initializationFailed(Object error) {
    return '初期化に失敗しました：$error';
  }

  @override
  String get initializing => '初期化中...';

  @override
  String get inputCharacter => '文字を入力';

  @override
  String get inputChineseContent => '漢字の内容を入力してください';

  @override
  String inputFieldHint(Object field) {
    return '$fieldを入力してください';
  }

  @override
  String get inputFileName => 'ファイル名を入力';

  @override
  String get inputHint => 'ここに入力';

  @override
  String get inputNewTag => '新しいタグを入力...';

  @override
  String get inputTitle => '練習帳のタイトルを入力してください';

  @override
  String get invalidFilename => 'ファイル名に次の文字を含めることはできません: \\ / : * ? \" < > |';

  @override
  String get invalidNumber => '有効な数値を入力してください';

  @override
  String get invertMode => '反転モード';

  @override
  String get isActive => 'アクティブかどうか';

  @override
  String itemsCount(Object count) {
    return '$count個のオプション';
  }

  @override
  String itemsPerPage(Object count) {
    return 'ページあたり$count項目';
  }

  @override
  String get jsonFile => 'JSONファイル';

  @override
  String get justNow => 'たった今';

  @override
  String get keepBackupCount => '保持するバックアップ数';

  @override
  String get keepBackupCountDescription => '古いバックアップを削除する前に保持するバックアップの数';

  @override
  String get keepExisting => '既存のものを保持';

  @override
  String get keepExistingDescription => '既存のデータを保持し、インポートをスキップ';

  @override
  String get key => 'キー';

  @override
  String get keyCannotBeEmpty => 'キーは空にできません';

  @override
  String get keyExists => '設定キーは既に存在します';

  @override
  String get keyHelperText => '英字、数字、アンダースコア、ハイフンのみ使用できます';

  @override
  String get keyHint => '設定項目の一意の識別子';

  @override
  String get keyInvalidCharacters => 'キーには英字、数字、アンダースコア、ハイフンのみ使用できます';

  @override
  String get keyMaxLength => 'キーは最大50文字です';

  @override
  String get keyMinLength => 'キーは少なくとも2文字必要です';

  @override
  String get keyRequired => '設定キーを入力してください';

  @override
  String get landscape => '横向き';

  @override
  String get language => '言語';

  @override
  String get languageEn => 'English';

  @override
  String get languageJa => '日本語';

  @override
  String get languageKo => '한국어';

  @override
  String get languageSystem => 'システム';

  @override
  String get languageZh => '简体中文';

  @override
  String get languageZhTw => '繁体中文';

  @override
  String get last30Days => '過去30日間';

  @override
  String get last365Days => '過去365日間';

  @override
  String get last7Days => '過去7日間';

  @override
  String get last90Days => '過去90日間';

  @override
  String get lastBackup => '最後のバックアップ';

  @override
  String get lastBackupTime => '前回のバックアップ日時';

  @override
  String get lastMonth => '先月';

  @override
  String get lastPage => '最後のページ';

  @override
  String get lastUsed => '最終使用';

  @override
  String get lastUsedTime => '最終使用日時';

  @override
  String get lastWeek => '先週';

  @override
  String get lastYear => '昨年';

  @override
  String get layer => 'レイヤー';

  @override
  String get layer1 => 'レイヤー 1';

  @override
  String get layerElements => 'レイヤー要素';

  @override
  String get layerInfo => 'レイヤー情報';

  @override
  String layerName(Object index) {
    return 'レイヤー$index';
  }

  @override
  String get layerOperations => 'レイヤー操作';

  @override
  String get layerProperties => 'レイヤープロパティ';

  @override
  String get leave => '退出';

  @override
  String get legacyBackupDescription => '過去のバックアップ';

  @override
  String get legacyDataPathDescription => 'クリーンアップが必要な古いデータパス';

  @override
  String get letterSpacing => '文字間隔';

  @override
  String get library => 'ライブラリ';

  @override
  String get libraryCount => 'ライブラリ数';

  @override
  String get libraryManagement => 'ライブラリ';

  @override
  String get lineHeight => '行間隔';

  @override
  String get lineThrough => '取り消し線';

  @override
  String get listView => 'リストビュー';

  @override
  String get loadBackupRegistryFailed => 'バックアップレジストリの読み込みに失敗しました';

  @override
  String loadCharacterDataFailed(Object error) {
    return '文字データの読み込みに失敗しました：$error';
  }

  @override
  String get loadConfigFailed => '設定の読み込みに失敗しました';

  @override
  String get loadCurrentBackupPathFailed => '現在のバックアップパスの読み込みに失敗しました';

  @override
  String get loadDataFailed => 'データの読み込みに失敗しました';

  @override
  String get loadFailed => '読み込みに失敗しました';

  @override
  String get loadPathInfoFailed => 'パス情報の読み込みに失敗しました';

  @override
  String get loadPracticeSheetFailed => '練習帳の読み込みに失敗しました';

  @override
  String get loading => '読み込み中...';

  @override
  String get loadingImage => '画像を読み込み中...';

  @override
  String get location => '場所';

  @override
  String get lock => 'ロック';

  @override
  String get lockElement => '要素をロック';

  @override
  String get lockStatus => 'ロック状態';

  @override
  String get lockUnlockAllElements => 'すべての要素をロック/ロック解除';

  @override
  String get locked => 'ロック済み';

  @override
  String get manualBackupDescription => '手動で作成されたバックアップ';

  @override
  String get marginBottom => '下';

  @override
  String get marginLeft => '左';

  @override
  String get marginRight => '右';

  @override
  String get marginTop => '上';

  @override
  String get max => '最大';

  @override
  String get memoryDataCacheCapacity => 'メモリデータキャッシュ容量';

  @override
  String get memoryDataCacheCapacityDescription => 'メモリに保持されるデータ項目数';

  @override
  String get memoryImageCacheCapacity => 'メモリ画像キャッシュ容量';

  @override
  String get memoryImageCacheCapacityDescription => 'メモリに保持される画像数';

  @override
  String get mergeAndMigrateFiles => 'ファイルを結合して移行';

  @override
  String get mergeBackupInfo => 'バックアップ情報を結合';

  @override
  String get mergeBackupInfoDesc => '古いパスのバックアップ情報を新しいパスのレジストリに結合します';

  @override
  String get mergeData => 'データを結合';

  @override
  String get mergeDataDescription => '既存のデータとインポートされたデータを結合';

  @override
  String get mergeOnlyBackupInfo => 'バックアップ情報のみを結合';

  @override
  String get metadata => 'メタデータ';

  @override
  String get migrateBackupFiles => 'バックアップファイルを移行';

  @override
  String get migrateBackupFilesDesc => '古いパスのバックアップファイルを新しいパスにコピーします（推奨）';

  @override
  String get migratingData => 'データを移行中';

  @override
  String get min => '最小';

  @override
  String get monospace => 'Monospace';

  @override
  String get monthsAgo => 'ヶ月前';

  @override
  String moreErrorsCount(Object count) {
    return '...さらに$count個のエラー';
  }

  @override
  String get moveDown => '下に移動 (Ctrl+Shift+B)';

  @override
  String get moveLayerDown => 'レイヤーを下に移動';

  @override
  String get moveLayerUp => 'レイヤーを上に移動';

  @override
  String get moveUp => '上に移動 (Ctrl+Shift+T)';

  @override
  String get multiSelectTool => '複数選択ツール';

  @override
  String multipleFilesNote(Object count) {
    return '注意: $count枚の画像ファイルをエクスポートします。ファイル名には自動的にページ番号が追加されます。';
  }

  @override
  String get name => '名前';

  @override
  String get navCollapseSidebar => 'サイドバーを折りたたむ';

  @override
  String get navExpandSidebar => 'サイドバーを展開';

  @override
  String get navigatedToBackupSettings => 'バックアップ設定ページに移動しました';

  @override
  String get navigationAttemptBack => '前の機能エリアに戻ろうとしています';

  @override
  String get navigationAttemptToNewSection => '新しい機能エリアにナビゲートしようとしています';

  @override
  String get navigationAttemptToSpecificItem => '特定の履歴項目にナビゲートしようとしています';

  @override
  String get navigationBackToPrevious => '前のページに戻る';

  @override
  String get navigationClearHistory => 'ナビゲーション履歴をクリア';

  @override
  String get navigationClearHistoryFailed => 'ナビゲーション履歴のクリアに失敗しました';

  @override
  String get navigationClearHistorySuccess => 'ナビゲーション履歴の消去が正常に完了しました';

  @override
  String get navigationFailedBack => 'ナビゲーションの復帰に失敗しました';

  @override
  String get navigationFailedInvalidHistoryItem => 'ナビゲーション失敗：無効な履歴項目';

  @override
  String get navigationFailedNoHistory => '戻れません：利用可能な履歴がありません';

  @override
  String get navigationFailedNoValidSection => 'ナビゲーション失敗：有効なセクションがありません';

  @override
  String get navigationFailedSection => 'ナビゲーションの切り替えに失敗しました';

  @override
  String get navigationFailedToBack => 'ナビゲーション失敗：前のセクションに戻れません';

  @override
  String get navigationFailedToGoBack => 'ナビゲーション失敗：戻れません';

  @override
  String get navigationFailedToNewSection => 'ナビゲーション失敗：新しいセクションに移動できません';

  @override
  String get navigationFailedToSpecificItem => '特定の履歴項目へのナビゲーションに失敗しました';

  @override
  String get navigationHistoryCleared => 'ナビゲーション履歴がクリアされました';

  @override
  String get navigationItemNotFound => '履歴にターゲット項目が見つかりませんでした。その機能エリアに直接ナビゲートします';

  @override
  String get navigationNoHistory => '履歴がありません';

  @override
  String get navigationNoHistoryMessage => '現在の機能エリアの最初のページに到達しました。';

  @override
  String get navigationRecordRoute => '機能エリア内のルート変更を記録';

  @override
  String get navigationRecordRouteFailed => 'ルート変更の記録に失敗しました';

  @override
  String get navigationRestoreStateFailed => 'ナビゲーション状態の復元に失敗しました';

  @override
  String get navigationSaveState => 'ナビゲーション状態を保存';

  @override
  String get navigationSaveStateFailed => 'ナビゲーション状態の保存に失敗しました';

  @override
  String get navigationSectionCharacterManagement => '文字管理';

  @override
  String get navigationSectionGalleryManagement => 'ギャラリー管理';

  @override
  String get navigationSectionPracticeList => '練習帳リスト';

  @override
  String get navigationSectionSettings => '設定';

  @override
  String get navigationSectionWorkBrowse => '作品閲覧';

  @override
  String get navigationSelectPage => 'どのページに戻りますか？';

  @override
  String get navigationStateRestored => 'ナビゲーション状態がストレージから復元されました';

  @override
  String get navigationStateSaved => 'ナビゲーション状態が保存されました';

  @override
  String get navigationSuccessBack => '前の機能エリアに正常に戻りました';

  @override
  String get navigationSuccessToNewSection => '新しい機能エリアに正常にナビゲートしました';

  @override
  String get navigationSuccessToSpecificItem => '特定の履歴項目に正常にナビゲートしました';

  @override
  String get navigationToggleExpanded => 'ナビゲーションバーの展開状態を切り替え';

  @override
  String get needRestartApp => 'アプリの再起動が必要です';

  @override
  String get newConfigItem => '新しい設定項目';

  @override
  String get newDataPath => '新しいデータパス：';

  @override
  String get newItem => '新規作成';

  @override
  String get nextField => '次のフィールド';

  @override
  String get nextPage => '次のページ';

  @override
  String get nextStep => '次のステップ';

  @override
  String get no => 'いいえ';

  @override
  String get noBackupExistsRecommendCreate => 'まだバックアップが作成されていません。データの安全を確保するために、まずバックアップを作成することをお勧めします';

  @override
  String get noBackupFilesInPath => 'このパスにはバックアップファイルがありません';

  @override
  String get noBackupFilesInPathMessage => 'このパスにはバックアップファイルがありません';

  @override
  String get noBackupFilesToExport => 'このパスにはエクスポートするバックアップファイルがありません';

  @override
  String get noBackupFilesToExportMessage => 'エクスポートするバックアップファイルがありません';

  @override
  String get noBackupPathSetRecommendCreateBackup => 'バックアップパスが設定されていません。まずバックアップパスを設定し、バックアップを作成することをお勧めします';

  @override
  String get noBackupPaths => 'バックアップパスがありません';

  @override
  String get noBackups => '利用可能なバックアップがありません';

  @override
  String get noBackupsInPath => 'このパスにはバックアップファイルがありません';

  @override
  String get noBackupsToDelete => '削除するバックアップファイルがありません';

  @override
  String get noCategories => 'カテゴリなし';

  @override
  String get noCharacters => '文字が見つかりません';

  @override
  String get noCharactersFound => '一致する文字が見つかりませんでした';

  @override
  String noConfigItems(Object category) {
    return '$categoryの設定がありません';
  }

  @override
  String get noCropping => '（トリミングなし）';

  @override
  String get noDisplayableImages => '表示可能な画像がありません';

  @override
  String get noElementsInLayer => 'このレイヤーには要素がありません';

  @override
  String get noElementsSelected => '要素が選択されていません';

  @override
  String get noHistoryPaths => '履歴パスがありません';

  @override
  String get noHistoryPathsDescription => 'まだ他のデータパスを使用したことがありません';

  @override
  String get noImageSelected => '画像が選択されていません';

  @override
  String get noImages => '画像がありません';

  @override
  String get noItemsSelected => '項目が選択されていません';

  @override
  String get noLayers => 'レイヤーがありません。レイヤーを追加してください';

  @override
  String get noMatchingConfigItems => '一致する設定項目が見つかりませんでした';

  @override
  String get noPageSelected => 'ページが選択されていません';

  @override
  String get noPagesToExport => 'エクスポートするページがありません';

  @override
  String get noPagesToPrint => '印刷するページがありません';

  @override
  String get noPreviewAvailable => '有効なプレビューがありません';

  @override
  String get noRegionBoxed => '領域が選択されていません';

  @override
  String get noRemarks => '備考なし';

  @override
  String get noResults => '結果が見つかりません';

  @override
  String get noTags => 'タグなし';

  @override
  String get noTexture => 'テクスチャなし';

  @override
  String get noTopLevelCategory => 'なし（トップレベルカテゴリ）';

  @override
  String get noWorks => '作品が見つかりません';

  @override
  String get noWorksHint => '新しい作品をインポートするか、フィルタリング条件を変更してみてください';

  @override
  String get noiseReduction => 'ノイズリダクション';

  @override
  String get noiseReductionAdjustment => 'ノイズ調整';

  @override
  String get noiseReductionLevel => 'ノイズリダクションレベル';

  @override
  String get noiseReductionToggle => 'ノイズリダクション切り替え';

  @override
  String get none => 'なし';

  @override
  String get notSet => '未設定';

  @override
  String get note => '注意';

  @override
  String get notesTitle => '注意事項：';

  @override
  String get noticeTitle => '注意事項';

  @override
  String get ok => 'OK';

  @override
  String get oldBackupRecommendCreateNew => '最後のバックアップから24時間以上経過しています。新しいバックアップの作成をお勧めします';

  @override
  String get oldDataNotAutoDeleted => 'パスを切り替えた後、古いデータは自動的に削除されません';

  @override
  String get oldDataNotDeleted => 'パスを切り替えた後、古いデータは自動的に削除されません';

  @override
  String get oldDataWillNotBeDeleted => '切り替え後、古いパスのデータは自動的に削除されません';

  @override
  String get oldPathDataNotAutoDeleted => '切り替え後、古いパスのデータは自動的に削除されません';

  @override
  String get onlyOneCharacter => '1文字のみ許可されています';

  @override
  String get opacity => '不透明度';

  @override
  String get openBackupManagementFailed => 'バックアップ管理を開けませんでした';

  @override
  String get openFolder => 'フォルダを開く';

  @override
  String openGalleryFailed(Object error) {
    return 'ギャラリーを開けませんでした: $error';
  }

  @override
  String get openPathFailed => 'パスを開けませんでした';

  @override
  String get openPathSwitchWizardFailed => 'データパス切り替えウィザードを開けませんでした';

  @override
  String get operatingSystem => 'オペレーティングシステム';

  @override
  String get operationCannotBeUndone => 'この操作は元に戻せません。慎重に確認してください';

  @override
  String get operationCannotUndo => 'この操作は元に戻せません。慎重に確認してください';

  @override
  String get optional => 'オプション';

  @override
  String get original => 'オリジナル';

  @override
  String get originalImageDesc => '未処理のオリジナル画像';

  @override
  String get outputQuality => '出力品質';

  @override
  String get overwrite => '上書き';

  @override
  String get overwriteConfirm => '上書きの確認';

  @override
  String get overwriteExisting => '既存のものを上書き';

  @override
  String get overwriteExistingDescription => 'インポートデータで既存の項目を置き換える';

  @override
  String overwriteExistingPractice(Object title) {
    return '「$title」という名前の練習帳が既に存在します。上書きしますか？';
  }

  @override
  String get overwriteFile => 'ファイルを上書き';

  @override
  String get overwriteFileAction => 'ファイルを上書き';

  @override
  String overwriteMessage(Object title) {
    return '「$title」というタイトルの練習帳が既に存在します。上書きしますか？';
  }

  @override
  String get overwrittenCharacters => '上書きされた収集文字';

  @override
  String get overwrittenItems => '上書きされた項目';

  @override
  String get overwrittenWorks => '上書きされた作品';

  @override
  String get padding => 'パディング';

  @override
  String get pageBuildError => 'ページビルドエラー';

  @override
  String get pageMargins => 'ページ余白（センチメートル）';

  @override
  String get pageNotImplemented => 'ページは実装されていません';

  @override
  String get pageOrientation => 'ページの向き';

  @override
  String get pageProperties => 'ページのプロパティ';

  @override
  String get pageRange => 'ページ範囲';

  @override
  String get pageSize => 'ページサイズ';

  @override
  String get pages => 'ページ';

  @override
  String get parentCategory => '親カテゴリ（オプション）';

  @override
  String get parsingImportData => 'インポートデータを解析中...';

  @override
  String get paste => '貼り付け';

  @override
  String get path => 'パス';

  @override
  String get pathAnalysis => 'パス分析';

  @override
  String get pathConfigError => 'パス設定エラー';

  @override
  String get pathInfo => 'パス情報';

  @override
  String get pathInvalid => '無効なパス';

  @override
  String get pathNotExists => 'パスが存在しません';

  @override
  String get pathSettings => 'パス設定';

  @override
  String get pathSize => 'パスサイズ';

  @override
  String get pathSwitchCompleted => 'データパスの切り替えが完了しました！\n\n「データパス管理」で古いパスのデータを確認し、クリーンアップできます。';

  @override
  String get pathSwitchCompletedMessage => 'データパスの切り替えが完了しました！\n\nデータパス管理で古いパスのデータを確認し、クリーンアップできます。';

  @override
  String get pathSwitchFailed => 'パスの切り替えに失敗しました';

  @override
  String get pathSwitchFailedMessage => 'パスの切り替えに失敗しました';

  @override
  String pathValidationFailed(Object error) {
    return 'パスの検証に失敗しました: $error';
  }

  @override
  String get pathValidationFailedGeneric => 'パスの検証に失敗しました。パスが有効か確認してください';

  @override
  String get pdfExportFailed => 'PDFのエクスポートに失敗しました';

  @override
  String pdfExportSuccess(Object path) {
    return 'PDFのエクスポートに成功しました: $path';
  }

  @override
  String get pinyin => 'ピンイン';

  @override
  String get pixels => 'ピクセル';

  @override
  String get platformInfo => 'プラットフォーム情報';

  @override
  String get pleaseEnterValidNumber => '有効な数値を入力してください';

  @override
  String get pleaseSelectOperation => '操作を選択してください：';

  @override
  String get pleaseSetBackupPathFirst => 'まずバックアップパスを設定してください';

  @override
  String get pleaseWaitMessage => 'しばらくお待ちください';

  @override
  String get portrait => '縦向き';

  @override
  String get position => '位置';

  @override
  String get ppiSetting => 'PPI設定（1インチあたりのピクセル数）';

  @override
  String get practiceEditCollection => '収集';

  @override
  String get practiceEditDefaultLayer => 'デフォルトレイヤー';

  @override
  String practiceEditPracticeLoaded(Object title) {
    return '練習帳「$title」の読み込みに成功しました';
  }

  @override
  String get practiceEditTitle => '練習帳の編集';

  @override
  String get practiceListSearch => '練習帳を検索...';

  @override
  String get practiceListTitle => '練習帳';

  @override
  String get practiceSheetNotExists => '練習帳が存在しません';

  @override
  String practiceSheetSaved(Object title) {
    return '練習帳「$title」が保存されました';
  }

  @override
  String practiceSheetSavedMessage(Object title) {
    return '練習帳「$title」の保存に成功しました';
  }

  @override
  String get practices => '練習';

  @override
  String get preparingPrint => '印刷準備中です、しばらくお待ちください...';

  @override
  String get preparingSave => '保存準備中...';

  @override
  String get preserveMetadata => 'メタデータを保持';

  @override
  String get preserveMetadataDescription => '元の作成日時とメタデータを保持';

  @override
  String get preserveMetadataMandatory => 'データの整合性を確保するため、元の作成日時、作者情報などのメタデータを強制的に保持します';

  @override
  String get presetSize => 'プリセットサイズ';

  @override
  String get presets => 'プリセット';

  @override
  String get preview => 'プレビュー';

  @override
  String get previewMode => 'プレビューモード';

  @override
  String previewPage(Object current, Object total) {
    return '($current/$totalページ)';
  }

  @override
  String get previousField => '前のフィールド';

  @override
  String get previousPage => '前のページ';

  @override
  String get previousStep => '前のステップ';

  @override
  String processedCount(Object current, Object total) {
    return '処理済み: $current / $total';
  }

  @override
  String processedProgress(Object current, Object total) {
    return '処理済み: $current / $total';
  }

  @override
  String get processing => '処理中...';

  @override
  String get processingDetails => '処理詳細';

  @override
  String get processingEraseData => '消去データを処理中...';

  @override
  String get processingImage => '画像を処理中...';

  @override
  String get processingPleaseWait => '処理中です、しばらくお待ちください...';

  @override
  String get properties => 'プロパティ';

  @override
  String get qualityHigh => '高画質 (2x)';

  @override
  String get qualityStandard => '標準 (1x)';

  @override
  String get qualityUltra => '超高画質 (3x)';

  @override
  String get quickRecoveryOnIssues => '• 切り替え中に問題が発生した場合、迅速に回復できます';

  @override
  String get reExportWork => '• この作品を再エクスポート';

  @override
  String get recent => '最近';

  @override
  String get recentBackupCanSwitch => '最近のバックアップがあるため、直接切り替え可能です';

  @override
  String get recommendConfirmBeforeCleanup => '新しいパスのデータが正常であることを確認してから、古いパスをクリーンアップすることをお勧めします';

  @override
  String get recommendConfirmNewDataBeforeClean => '新しいパスのデータが正常であることを確認してから、古いパスをクリーンアップすることをお勧めします';

  @override
  String get recommendSufficientSpace => '十分な空き容量のあるディスクを選択することをお勧めします';

  @override
  String get redo => 'やり直し';

  @override
  String get refresh => '更新';

  @override
  String refreshDataFailed(Object error) {
    return 'データの更新に失敗しました: $error';
  }

  @override
  String get reload => '再読み込み';

  @override
  String get remarks => '備考';

  @override
  String get remarksHint => '備考情報を追加';

  @override
  String get remove => '削除';

  @override
  String get removeFavorite => 'お気に入りから削除';

  @override
  String get removeFromCategory => '現在のカテゴリから削除';

  @override
  String get rename => '名前の変更';

  @override
  String get renameDuplicates => '重複項目の名前を変更';

  @override
  String get renameDuplicatesDescription => '競合を避けるためにインポートされた項目の名前を変更';

  @override
  String get renameLayer => 'レイヤーの名前を変更';

  @override
  String get renderFailed => 'レンダリングに失敗しました';

  @override
  String get reselectFile => 'ファイルを再選択';

  @override
  String resetCategoryConfig(Object category) {
    return '$categoryの設定をリセット';
  }

  @override
  String resetCategoryConfigMessage(Object category) {
    return '$categoryの設定をデフォルトに戻しますか？この操作は元に戻せません。';
  }

  @override
  String get resetDataPathToDefault => 'デフォルトにリセット';

  @override
  String get resetSettingsConfirmMessage => 'デフォルト値にリセットしますか？';

  @override
  String get resetSettingsConfirmTitle => '設定をリセット';

  @override
  String get resetToDefault => 'デフォルトにリセット';

  @override
  String get resetToDefaultFailed => 'デフォルトパスへのリセットに失敗しました';

  @override
  String resetToDefaultFailedWithError(Object error) {
    return 'デフォルトパスへのリセットに失敗しました: $error';
  }

  @override
  String get resetToDefaultPathMessage => 'これにより、データパスがデフォルトの場所にリセットされます。変更を有効にするには、アプリケーションを再起動する必要があります。続行しますか？';

  @override
  String get resetToDefaults => 'デフォルトにリセット';

  @override
  String get resetTransform => '変換をリセット';

  @override
  String get resetZoom => 'ズームをリセット';

  @override
  String get resolution => '解像度';

  @override
  String get restartAfterRestored => '注意：復元完了後、アプリは自動的に再起動します';

  @override
  String get restartLaterButton => '後で';

  @override
  String get restartNeeded => '再起動が必要です';

  @override
  String get restartNow => '今すぐ再起動';

  @override
  String get restartNowButton => '今すぐ再起動';

  @override
  String get restore => '復元';

  @override
  String get restoreBackup => 'バックアップから復元';

  @override
  String get restoreBackupFailed => 'バックアップの復元に失敗しました';

  @override
  String get restoreConfirmMessage => 'このバックアップから復元しますか？現在のすべてのデータが置き換えられます。';

  @override
  String get restoreConfirmTitle => '復元の確認';

  @override
  String get restoreDefaultSize => 'デフォルトサイズに戻す';

  @override
  String get restoreFailure => '復元に失敗しました';

  @override
  String get restoreWarningMessage => '警告：この操作は現在のすべてのデータを上書きします！';

  @override
  String get restoringBackup => 'バックアップから復元中...';

  @override
  String get restoringBackupMessage => 'バックアップを復元中...';

  @override
  String get retry => '再試行';

  @override
  String get retryAction => '再試行';

  @override
  String get rotateClockwise => '時計回り';

  @override
  String get rotateCounterclockwise => '反時計回り';

  @override
  String get rotateLeft => '左に回転';

  @override
  String get rotateRight => '右に回転';

  @override
  String get rotation => '回転';

  @override
  String get rotationFineControl => '角度微調整';

  @override
  String get safetyBackupBeforePathSwitch => 'データパス切り替え前の安全バックアップ';

  @override
  String get safetyBackupRecommendation => 'データの安全を確保するため、データパスを切り替える前にバックアップを作成することをお勧めします：';

  @override
  String get safetyTip => '💡 安全のためのヒント：';

  @override
  String get sansSerif => 'Sans Serif';

  @override
  String get save => '保存';

  @override
  String get saveAs => '名前を付けて保存';

  @override
  String get saveComplete => '保存が完了しました';

  @override
  String get saveFailed => '保存に失敗しました';

  @override
  String saveFailedWithError(Object error) {
    return '保存に失敗しました：$error';
  }

  @override
  String get saveFailure => '保存に失敗しました';

  @override
  String get savePreview => '文字プレビュー：';

  @override
  String get saveSuccess => '保存が完了しました';

  @override
  String get saveTimeout => '保存がタイムアウトしました';

  @override
  String get savingToStorage => 'ストレージに保存中...';

  @override
  String get scannedBackupFileDescription => 'スキャンで検出されたバックアップファイル';

  @override
  String get search => '検索';

  @override
  String get searchCategories => 'カテゴリを検索...';

  @override
  String get searchConfigDialogTitle => '設定項目を検索';

  @override
  String get searchConfigHint => '設定項目の名前またはキーを入力';

  @override
  String get searchConfigItems => '設定項目を検索';

  @override
  String get searching => '検索中...';

  @override
  String get select => '選択';

  @override
  String get selectAll => 'すべて選択';

  @override
  String get selectAllWithShortcut => 'すべて選択 (Ctrl+Shift+A)';

  @override
  String get selectBackup => 'バックアップを選択';

  @override
  String get selectBackupFileToImportDialog => 'インポートするバックアップファイルを選択';

  @override
  String get selectBackupStorageLocation => 'バックアップ保存場所を選択';

  @override
  String get selectCategoryToApply => '適用するカテゴリを選択してください:';

  @override
  String get selectCharacterFirst => 'まず文字を選択してください';

  @override
  String selectColor(Object type) {
    return '$typeを選択';
  }

  @override
  String get selectDate => '日付を選択';

  @override
  String get selectExportLocation => 'エクスポート先を選択';

  @override
  String get selectExportLocationDialog => 'エクスポート先を選択';

  @override
  String get selectExportLocationHint => 'エクスポート先を選択...';

  @override
  String get selectFileError => 'ファイルの選択に失敗しました';

  @override
  String get selectFolder => 'フォルダを選択';

  @override
  String get selectImage => '画像を選択';

  @override
  String get selectImages => '画像を選択';

  @override
  String get selectImagesWithCtrl => '画像を選択（Ctrlキーを押しながら複数選択可能）';

  @override
  String get selectImportFile => 'バックアップファイルを選択';

  @override
  String get selectNewDataPath => '新しいデータ保存パスを選択：';

  @override
  String get selectNewDataPathDialog => '新しいデータ保存パスを選択';

  @override
  String get selectNewDataPathTitle => '新しいデータ保存パスを選択';

  @override
  String get selectNewPath => '新しいパスを選択';

  @override
  String get selectParentCategory => '親カテゴリを選択';

  @override
  String get selectPath => 'パスを選択';

  @override
  String get selectPathButton => 'パスを選択';

  @override
  String get selectPathFailed => 'パスの選択に失敗しました';

  @override
  String get selectSufficientSpaceDisk => '十分な空き容量のあるディスクを選択することをお勧めします';

  @override
  String get selectTargetLayer => 'ターゲットレイヤーを選択';

  @override
  String get selected => '選択済み';

  @override
  String get selectedCharacter => '選択された文字';

  @override
  String selectedCount(Object count) {
    return '$count個選択済み';
  }

  @override
  String get selectedElementNotFound => '選択された要素が見つかりませんでした';

  @override
  String get selectedItems => '選択された項目';

  @override
  String get selectedPath => '選択されたパス：';

  @override
  String get selectionMode => '選択モード';

  @override
  String get sendToBack => '最背面へ移動 (Ctrl+B)';

  @override
  String get serif => 'Serif';

  @override
  String get serviceNotReady => 'サービスが準備できていません。後でもう一度お試しください';

  @override
  String get setBackupPathFailed => 'バックアップパスの設定に失敗しました';

  @override
  String get setCategory => 'カテゴリを設定';

  @override
  String setCategoryForItems(Object count) {
    return 'カテゴリを設定（$count項目）';
  }

  @override
  String get setDataPathFailed => 'データパスの設定に失敗しました。パスの権限と互換性を確認してください';

  @override
  String setDataPathFailedWithError(Object error) {
    return 'データパスの設定に失敗しました: $error';
  }

  @override
  String get settings => '設定';

  @override
  String get settingsResetMessage => '設定がデフォルト値にリセットされました';

  @override
  String get shortcuts => 'キーボードショートカット';

  @override
  String get showContour => '輪郭を表示';

  @override
  String get showDetails => '詳細を表示';

  @override
  String get showElement => '要素を表示';

  @override
  String get showGrid => 'グリッドを表示 (Ctrl+G)';

  @override
  String get showHideAllElements => 'すべての要素を表示/非表示';

  @override
  String get showImagePreview => '画像プレビューを表示';

  @override
  String get showThumbnails => 'ページサムネイルを表示';

  @override
  String get showToolbar => 'ツールバーを表示';

  @override
  String get skipBackup => 'バックアップをスキップ';

  @override
  String get skipBackupConfirm => 'バックアップをスキップ';

  @override
  String get skipBackupWarning => 'バックアップをスキップしてパスの切り替えを直接行いますか？\n\nデータ損失のリスクがあります。';

  @override
  String get skipBackupWarningMessage => 'バックアップをスキップしてパスの切り替えを直接行いますか？\n\nデータ損失のリスクがあります。';

  @override
  String get skipConflicts => '競合をスキップ';

  @override
  String get skipConflictsDescription => '既存の項目をスキップ';

  @override
  String get skippedCharacters => 'スキップされた収集文字';

  @override
  String get skippedItems => 'スキップされた項目';

  @override
  String get skippedWorks => 'スキップされた作品';

  @override
  String get sort => '並び替え';

  @override
  String get sortBy => '並べ替え基準';

  @override
  String get sortByCreateTime => '作成日時順に並べ替え';

  @override
  String get sortByTitle => 'タイトル順に並べ替え';

  @override
  String get sortByUpdateTime => '更新日時順に並べ替え';

  @override
  String get sortFailed => '並べ替えに失敗しました';

  @override
  String get sortOrder => '並べ替え';

  @override
  String get sortOrderCannotBeEmpty => '並べ替え順序は空にできません';

  @override
  String get sortOrderHint => '数値が小さいほど前に表示されます';

  @override
  String get sortOrderLabel => '並べ替え順序';

  @override
  String get sortOrderNumber => '並べ替え値は数値でなければなりません';

  @override
  String get sortOrderRange => '並べ替え順序は1～999の間でなければなりません';

  @override
  String get sortOrderRequired => '並べ替え値を入力してください';

  @override
  String get sourceBackupFileNotFound => '元のバックアップファイルが見つかりません';

  @override
  String sourceFileNotFound(Object path) {
    return '元のファイルが見つかりません: $path';
  }

  @override
  String sourceFileNotFoundError(Object path) {
    return '元のファイルが見つかりません: $path';
  }

  @override
  String get sourceHanSansFont => '源ノ角ゴシック (Source Han Sans)';

  @override
  String get sourceHanSerifFont => '源ノ明朝 (Source Han Serif)';

  @override
  String get sourceInfo => '出典情報';

  @override
  String get startBackup => 'バックアップを開始';

  @override
  String get startDate => '開始日';

  @override
  String get stateAndDisplay => '状態と表示';

  @override
  String get statisticsInProgress => '統計中...';

  @override
  String get status => '状態';

  @override
  String get statusAvailable => '利用可能';

  @override
  String get statusLabel => '状態';

  @override
  String get statusUnavailable => '利用不可';

  @override
  String get storageDetails => 'ストレージ詳細';

  @override
  String get storageLocation => '保存場所';

  @override
  String get storageSettings => 'ストレージ設定';

  @override
  String get storageUsed => '使用済みストレージ';

  @override
  String get stretch => '引き伸ばし';

  @override
  String get strokeCount => '画数';

  @override
  String submitFailed(Object error) {
    return '送信に失敗しました：$error';
  }

  @override
  String successDeletedCount(Object count) {
    return '$count個のバックアップファイルを正常に削除しました';
  }

  @override
  String get suggestConfigureBackupPath => '推奨：まず設定でバックアップパスを構成してください';

  @override
  String get suggestConfigureBackupPathFirst => '推奨：まず設定でバックアップパスを構成してください';

  @override
  String get suggestRestartOrWait => '推奨：アプリを再起動するか、サービスの初期化が完了するのを待ってから再試行してください';

  @override
  String get suggestRestartOrWaitService => '推奨：アプリを再起動するか、サービスの初期化が完了するのを待ってから再試行してください';

  @override
  String get suggestedSolutions => '推奨される解決策：';

  @override
  String get suggestedTags => '推奨タグ';

  @override
  String get switchSuccessful => '切り替えに成功しました';

  @override
  String get switchingPage => '文字ページに切り替え中...';

  @override
  String get systemConfig => 'システム設定';

  @override
  String get systemConfigItemNote => 'これはシステム設定項目であり、キー値は変更できません';

  @override
  String get systemInfo => 'システム情報';

  @override
  String get tabToNextField => 'Tabキーで次のフィールドに移動';

  @override
  String tagAddError(Object error) {
    return 'タグの追加に失敗しました: $error';
  }

  @override
  String get tagHint => 'タグ名を入力';

  @override
  String tagRemoveError(Object error) {
    return 'タグの削除に失敗しました、エラー: $error';
  }

  @override
  String get tags => 'タグ';

  @override
  String get tagsAddHint => 'タグ名を入力してEnterキーを押してください';

  @override
  String get tagsHint => 'タグを入力...';

  @override
  String get tagsSelected => '選択されたタグ：';

  @override
  String get targetLocationExists => 'ターゲットの場所に同名のファイルが既に存在します：';

  @override
  String get targetPathLabel => '操作を選択してください：';

  @override
  String get text => 'テキスト';

  @override
  String get textAlign => 'テキストの配置';

  @override
  String get textContent => 'テキストの内容';

  @override
  String get textElement => 'テキスト要素';

  @override
  String get textProperties => 'テキストのプロパティ';

  @override
  String get textSettings => 'テキストの設定';

  @override
  String get textureFillMode => 'テクスチャ塗りつぶしモード';

  @override
  String get textureFillModeContain => '含む';

  @override
  String get textureFillModeCover => 'カバー';

  @override
  String get textureFillModeRepeat => '繰り返し';

  @override
  String get textureOpacity => 'テクスチャの不透明度';

  @override
  String get texturePreview => 'テクスチャプレビュー';

  @override
  String get textureSize => 'テクスチャサイズ';

  @override
  String get themeMode => 'テーマモード';

  @override
  String get themeModeDark => 'ダークモード';

  @override
  String get themeModeDescription => 'ダークテーマを使用して、夜間の視聴体験を向上させます';

  @override
  String get themeModeSystemDescription => 'システム設定に応じてダーク/ライトテーマを自動的に切り替えます';

  @override
  String get thisMonth => '今月';

  @override
  String get thisWeek => '今週';

  @override
  String get thisYear => '今年';

  @override
  String get threshold => 'しきい値';

  @override
  String get grayThreshold => 'グレースケール閾値';

  @override
  String get thumbnailCheckFailed => 'サムネイルのチェックに失敗しました';

  @override
  String get thumbnailEmpty => 'サムネイルファイルが空です';

  @override
  String get thumbnailLoadError => 'サムネイルの読み込みに失敗しました';

  @override
  String get thumbnailNotFound => 'サムネイルが見つかりません';

  @override
  String get timeInfo => '時間情報';

  @override
  String get timeLabel => '時間';

  @override
  String get title => 'タイトル';

  @override
  String get titleAlreadyExists => '同じタイトルの練習帳が既に存在します。別のタイトルを使用してください';

  @override
  String get titleCannotBeEmpty => 'タイトルは空にできません';

  @override
  String get titleExists => 'タイトルは既に存在します';

  @override
  String get titleExistsMessage => '同じ名前の練習帳が既に存在します。上書きしますか？';

  @override
  String titleUpdated(Object title) {
    return 'タイトルが「$title」に更新されました';
  }

  @override
  String get to => '～';

  @override
  String get today => '今日';

  @override
  String get toggleBackground => '背景を切り替え';

  @override
  String get toolModePanTooltip => '複数選択ツール (Ctrl+V)';

  @override
  String get toolModeSelectTooltip => '収集ツール (Ctrl+B)';

  @override
  String get toolModePanShort => '複数選択';

  @override
  String get toolModeSelectShort => '収集';

  @override
  String get resultShort => '結果';

  @override
  String get topCenter => '上中央';

  @override
  String get topLeft => '左上';

  @override
  String get topRight => '右上';

  @override
  String get total => '合計';

  @override
  String get totalBackups => '総バックアップ数';

  @override
  String totalItems(Object count) {
    return '合計$count個';
  }

  @override
  String get totalSize => '合計サイズ';

  @override
  String get transformApplied => '変換が適用されました';

  @override
  String get tryOtherKeywords => '他のキーワードで検索してみてください';

  @override
  String get type => '種類';

  @override
  String get underline => '下線';

  @override
  String get undo => '元に戻す';

  @override
  String get ungroup => 'グループ解除 (Ctrl+U)';

  @override
  String get ungroupConfirm => 'グループ解除の確認';

  @override
  String get ungroupDescription => 'このグループを解除しますか？';

  @override
  String get unknown => '不明';

  @override
  String get unknownCategory => '不明なカテゴリ';

  @override
  String unknownElementType(Object type) {
    return '不明な要素タイプ: $type';
  }

  @override
  String get unknownError => '不明なエラー';

  @override
  String get unlockElement => '要素のロックを解除';

  @override
  String get unlocked => 'ロック解除済み';

  @override
  String get unnamedElement => '無名の要素';

  @override
  String get unnamedGroup => '無名のグループ';

  @override
  String get unnamedLayer => '無名のレイヤー';

  @override
  String get unsavedChanges => '未保存の変更があります';

  @override
  String get updateTime => '更新日時';

  @override
  String get updatedAt => '更新日時';

  @override
  String get usageInstructions => '使用方法';

  @override
  String get useDefaultPath => 'デフォルトパスを使用';

  @override
  String get userConfig => 'ユーザー設定';

  @override
  String get validCharacter => '有効な文字を入力してください';

  @override
  String get validPath => '有効なパス';

  @override
  String get validateData => 'データを検証';

  @override
  String get validateDataDescription => 'インポート前にデータの完全性を検証';

  @override
  String get validateDataMandatory => 'データの安全性を確保するため、インポートファイルの完全性と形式を強制的に検証します';

  @override
  String get validatingImportFile => 'インポートファイルを検証中...';

  @override
  String valueTooLarge(Object label, Object max) {
    return '$labelは$maxより大きくすることはできません';
  }

  @override
  String valueTooSmall(Object label, Object min) {
    return '$labelは$minより小さくすることはできません';
  }

  @override
  String get versionDetails => 'バージョンの詳細';

  @override
  String get versionInfoCopied => 'バージョン情報がクリップボードにコピーされました';

  @override
  String get verticalAlignment => '垂直方向の配置';

  @override
  String get verticalLeftToRight => '縦書き（左から右へ）';

  @override
  String get verticalRightToLeft => '縦書き（右から左へ）';

  @override
  String get viewAction => '表示';

  @override
  String get viewDetails => '詳細を表示';

  @override
  String get viewExportResultsButton => '表示';

  @override
  String get visibility => '可視性';

  @override
  String get visible => '表示';

  @override
  String get visualProperties => '視覚的プロパティ';

  @override
  String get visualSettings => '視覚的設定';

  @override
  String get warningOverwriteData => '警告：これにより、現在のすべてのデータが上書きされます！';

  @override
  String get warnings => '警告';

  @override
  String get widgetRefRequired => 'CollectionPainterを作成するにはWidgetRefが必要です';

  @override
  String get width => '幅';

  @override
  String get windowButtonMaximize => '最大化';

  @override
  String get windowButtonMinimize => '最小化';

  @override
  String get windowButtonRestore => '元に戻す';

  @override
  String get work => '作品';

  @override
  String get workBrowseSearch => '作品を検索...';

  @override
  String get workBrowseTitle => '作品';

  @override
  String get workCount => '作品数';

  @override
  String get workDetailCharacters => '文字';

  @override
  String get workDetailOtherInfo => 'その他の情報';

  @override
  String get workDetailTitle => '作品詳細';

  @override
  String get workFormAuthorHelp => 'オプション、作品の作者';

  @override
  String get workFormAuthorHint => '作者名を入力';

  @override
  String get workFormAuthorMaxLength => '作者名は50文字を超えることはできません';

  @override
  String get workFormAuthorTooltip => 'Ctrl+Aで作者フィールドにすばやく移動';

  @override
  String get workFormCreationDateError => '作成日は現在の日付を超えることはできません';

  @override
  String get workFormDateHelp => '作品の完成日';

  @override
  String get workFormRemarkHelp => 'オプション、作品に関する追加情報';

  @override
  String get workFormRemarkMaxLength => '備考は500文字を超えることはできません';

  @override
  String get workFormRemarkTooltip => 'Ctrl+Rで備考フィールドにすばやく移動';

  @override
  String get workFormStyleHelp => '作品の主なスタイルタイプ';

  @override
  String get workFormTitleHelp => '作品のメインタイトル、作品リストに表示されます';

  @override
  String get workFormTitleMaxLength => 'タイトルは100文字を超えることはできません';

  @override
  String get workFormTitleMinLength => 'タイトルは少なくとも2文字必要です';

  @override
  String get workFormTitleRequired => 'タイトルは必須です';

  @override
  String get workFormTitleTooltip => 'Ctrl+Tでタイトルフィールドにすばやく移動';

  @override
  String get workFormToolHelp => 'この作品の作成に使用された主な道具';

  @override
  String get workIdCannotBeEmpty => '作品IDは空にできません';

  @override
  String get workInfo => '作品情報';

  @override
  String get workStyleClerical => '隷書';

  @override
  String get workStyleCursive => '草書';

  @override
  String get workStyleRegular => '楷書';

  @override
  String get workStyleRunning => '行書';

  @override
  String get workStyleSeal => '篆書';

  @override
  String get workToolBrush => '筆';

  @override
  String get workToolHardPen => '硬筆';

  @override
  String get workToolOther => 'その他';

  @override
  String get works => '作品';

  @override
  String worksCount(Object count) {
    return '$count個の作品';
  }

  @override
  String get writingMode => '筆記モード';

  @override
  String get writingTool => '書道具';

  @override
  String get writingToolManagement => '筆記具管理';

  @override
  String get writingToolText => '筆記具';

  @override
  String get hardwareInfo => 'ハードウェア情報';

  @override
  String get runtimeEnvironment => 'ランタイム環境';

  @override
  String get platform => 'プラットフォーム';

  @override
  String get deviceModel => 'デバイスモデル';

  @override
  String get manufacturer => '製造元';

  @override
  String get deviceId => 'デバイスID';

  @override
  String get physicalDevice => '物理デバイス';

  @override
  String get architecture => 'アーキテクチャ';

  @override
  String get screenInfo => '画面情報';

  @override
  String get screenSize => '画面サイズ';

  @override
  String get pixelDensity => 'ピクセル密度';

  @override
  String get screenSizeCategory => '画面サイズカテゴリ';

  @override
  String get memoryInfo => 'メモリ情報';

  @override
  String get totalMemory => '総メモリ';

  @override
  String get availableMemory => '利用可能メモリ';

  @override
  String get applicationInfo => 'アプリケーション情報';

  @override
  String get applicationName => 'アプリケーション名';

  @override
  String get buildMode => 'ビルドモード';

  @override
  String get debugMode => 'デバッグモード';

  @override
  String get runtimeInfo => 'ランタイム情報';

  @override
  String get flutterVersionLabel => 'Flutterバージョン';

  @override
  String get dartVersionLabel => 'Dartバージョン';

  @override
  String get yes => 'はい';

  @override
  String get yesterday => '昨日';

  @override
  String get zipFile => 'ZIP圧縮ファイル';

  @override
  String get zoomPreview => 'ズーム プレビュー';

  @override
  String get imagePreview => '画像プレビュー';

  @override
  String get resetView => 'ビューリセット';

  @override
  String get fitToWindow => 'ウィンドウに合わせる';

  @override
  String get actualSize => '実際のサイズ';

  @override
  String get modified => '変更済み';

  @override
  String get resetCropArea => 'クロップエリアリセット';
}
