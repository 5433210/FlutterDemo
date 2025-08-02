// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get a4Size => 'A4 (210×297mm)';

  @override
  String get a5Size => 'A5 (148×210mm)';

  @override
  String get about => '关于';

  @override
  String get activated => '激活';

  @override
  String get activatedDescription => '激活 - 在选择器中显示';

  @override
  String get activeStatus => '激活状态';

  @override
  String get add => '添加';

  @override
  String get addCategory => '添加分类';

  @override
  String addCategoryItem(Object category) {
    return '添加$category';
  }

  @override
  String get addConfigItem => '添加配置项';

  @override
  String addConfigItemHint(Object category) {
    return '点击右下角的按钮添加$category配置项';
  }

  @override
  String get addFavorite => '添加到收藏';

  @override
  String addFromGalleryFailed(Object error) {
    return '从图库添加图片失败: $error';
  }

  @override
  String get addImage => '添加图片';

  @override
  String get addImageHint => '点击添加图像';

  @override
  String get addImages => '添加图片';

  @override
  String get addLayer => '添加图层';

  @override
  String get addTag => '添加标签';

  @override
  String get addWork => '添加作品';

  @override
  String get addedToCategory => '已添加到分类';

  @override
  String addingImagesToGallery(Object count) {
    return '正在将 $count 张本地图片添加到图库...';
  }

  @override
  String get adjust => '调节';

  @override
  String get adjustGridSize => '调整网格大小';

  @override
  String get afterDate => '某个日期之后';

  @override
  String get alignBottom => '底对齐';

  @override
  String get alignCenter => '居中';

  @override
  String get alignHorizontalCenter => '水平居中';

  @override
  String get alignLeft => '左对齐';

  @override
  String get alignMiddle => '居中';

  @override
  String get alignRight => '右对齐';

  @override
  String get alignTop => '顶对齐';

  @override
  String get alignVerticalCenter => '垂直居中';

  @override
  String get alignmentAssist => '对齐辅助';

  @override
  String get alignmentGrid => '网格贴附模式 - 点击切换到参考线对齐';

  @override
  String get alignmentGuideline => '参考线对齐模式 - 点击切换到无辅助';

  @override
  String get alignmentNone => '无辅助对齐 - 点击启用网格贴附';

  @override
  String get alignmentOperations => '对齐操作';

  @override
  String get all => '全部';

  @override
  String get allBackupsDeleteWarning => '此操作不可撤销！所有备份数据将永久丢失。';

  @override
  String get allCategories => '所有分类';

  @override
  String get allPages => '全部页面';

  @override
  String get allTime => '全部时间';

  @override
  String get allTypes => '所有类型';

  @override
  String get analyzePathInfoFailed => '分析路径信息失败';

  @override
  String get appRestartFailed => '应用重启失败，请手动重启应用';

  @override
  String get appRestarting => '正在重启应用';

  @override
  String get appRestartingMessage => '数据恢复成功，正在重启应用...';

  @override
  String get appStartupFailed => '应用启动失败';

  @override
  String appStartupFailedWith(Object error) {
    return '应用启动失败: $error';
  }

  @override
  String get appTitle => '字字珠玑';

  @override
  String get appVersion => '应用版本';

  @override
  String get appVersionInfo => '应用版本信息';

  @override
  String get appWillRestartAfterRestore => '恢复后应用将自动重启。';

  @override
  String appWillRestartInSeconds(Object message) {
    return '$message\n应用将在3秒后自动重启...';
  }

  @override
  String get appWillRestartMessage => '恢复完成后应用将自动重启';

  @override
  String get apply => '应用';

  @override
  String get applyFormatBrush => '应用格式刷 (Alt+W)';

  @override
  String get applyNewPath => '应用新路径';

  @override
  String get applyTransform => '应用变换';

  @override
  String get ascending => '升序';

  @override
  String get askUser => '询问用户';

  @override
  String get askUserDescription => '对每个冲突询问用户';

  @override
  String get author => '作者';

  @override
  String get autoBackup => '自动备份';

  @override
  String get autoBackupDescription => '定期自动备份您的数据';

  @override
  String get autoBackupInterval => '自动备份间隔';

  @override
  String get autoBackupIntervalDescription => '自动备份的频率';

  @override
  String get autoCleanup => '自动清理';

  @override
  String get autoCleanupDescription => '自动清理旧的缓存文件';

  @override
  String get autoCleanupInterval => '自动清理间隔';

  @override
  String get autoCleanupIntervalDescription => '自动清理运行的频率';

  @override
  String get autoDetect => '自动检测';

  @override
  String get autoDetectPageOrientation => '自动检测页面方向';

  @override
  String get autoLineBreak => '自动换行';

  @override
  String get autoLineBreakDisabled => '已禁用自动换行';

  @override
  String get autoLineBreakEnabled => '已启用自动换行';

  @override
  String get availableCharacters => '可用字符';

  @override
  String get back => '返回';

  @override
  String get backgroundColor => '背景颜色';

  @override
  String get backupBeforeSwitchRecommendation => '为了确保数据安全，建议在切换数据路径前先创建备份：';

  @override
  String backupChecksum(Object checksum) {
    return '校验和: $checksum...';
  }

  @override
  String get backupCompleted => '✓ 备份已完成';

  @override
  String backupCount(Object count) {
    return '$count 个备份';
  }

  @override
  String backupCountFormat(Object count) {
    return '$count 个备份';
  }

  @override
  String get backupCreatedSuccessfully => '备份创建成功，可以安全进行路径切换';

  @override
  String get backupCreationFailed => '备份创建失败';

  @override
  String backupCreationTime(Object time) {
    return '创建时间: $time';
  }

  @override
  String get backupDeletedSuccessfully => '备份已成功删除';

  @override
  String get backupDescription => '描述（可选）';

  @override
  String get backupDescriptionHint => '输入此备份的描述';

  @override
  String get backupDescriptionInputExample => '例如：每周备份、重要更新前备份等';

  @override
  String get backupDescriptionInputLabel => '备份描述';

  @override
  String backupDescriptionLabel(Object description) {
    return '备份描述: $description';
  }

  @override
  String get backupEnsuresDataSafety => '• 备份可以确保数据安全';

  @override
  String backupExportedSuccessfully(Object filename) {
    return '备份导出成功: $filename';
  }

  @override
  String get backupFailure => '创建备份失败';

  @override
  String get backupFile => '备份文件';

  @override
  String get backupFileChecksumMismatchError => '备份文件校验和不匹配';

  @override
  String get backupFileCreationFailed => '备份文件创建失败';

  @override
  String get backupFileCreationFailedError => '备份文件创建失败';

  @override
  String backupFileLabel(Object filename) {
    return '备份文件: $filename';
  }

  @override
  String backupFileListTitle(Object count) {
    return '备份文件列表 ($count 个)';
  }

  @override
  String get backupFileMissingDirectoryStructureError => '备份文件缺少必要的目录结构';

  @override
  String backupFileNotExist(Object path) {
    return '备份文件不存在: $path';
  }

  @override
  String get backupFileNotExistError => '备份文件不存在';

  @override
  String get backupFileNotFound => '备份文件不存在';

  @override
  String get backupFileSizeMismatchError => '备份文件大小不匹配';

  @override
  String get backupFileVerificationFailedError => '备份文件核验失败';

  @override
  String get backupFirst => '先备份';

  @override
  String get backupImportSuccessMessage => '备份导入成功';

  @override
  String get backupImportedSuccessfully => '备份导入成功';

  @override
  String get backupImportedToCurrentPath => '备份已导入到当前路径';

  @override
  String get backupLabel => '备份';

  @override
  String get backupList => '备份列表';

  @override
  String get backupLocationTips => '• 建议选择剩余空间充足的磁盘作为备份位置\n• 备份位置可以是外部存储设备（如移动硬盘）\n• 更换备份位置后，所有备份信息将统一管理\n• 历史备份文件不会自动移动，但可以在备份管理中查看';

  @override
  String get backupManagement => '备份管理';

  @override
  String get backupManagementSubtitle => '创建、恢复、导入、导出和管理所有备份文件';

  @override
  String get backupMayTakeMinutes => '备份可能需要几分钟时间，请保持应用运行';

  @override
  String get backupNotAvailable => '备份管理暂不可用';

  @override
  String get backupNotAvailableMessage => '备份管理功能需要数据库支持。\n\n可能的原因：\n• 数据库正在初始化中\n• 数据库初始化失败\n• 应用正在启动中\n\n请稍后再试，或重启应用。';

  @override
  String backupNotFound(Object id) {
    return '备份不存在: $id';
  }

  @override
  String backupNotFoundError(Object id) {
    return '备份不存在: $id';
  }

  @override
  String get backupOperationTimeoutError => '备份操作超时，请检查存储空间并重试';

  @override
  String get backupOverview => '备份概览';

  @override
  String get backupPathDeleted => '备份路径已删除';

  @override
  String get backupPathDeletedMessage => '备份路径已删除';

  @override
  String get backupPathNotSet => '请先设置备份路径';

  @override
  String get backupPathNotSetError => '请先设置备份路径';

  @override
  String get backupPathNotSetUp => '尚未设置备份路径';

  @override
  String get backupPathSetSuccessfully => '备份路径设置成功';

  @override
  String get backupPathSettings => '备份路径设置';

  @override
  String get backupPathSettingsSubtitle => '配置和管理备份存储路径';

  @override
  String backupPreCheckFailed(Object error) {
    return '备份前检查失败：$error';
  }

  @override
  String get backupReadyRestartMessage => '备份文件已准备就绪，需要重启应用完成恢复';

  @override
  String get backupRecommendation => '建议导入前创建备份';

  @override
  String get backupRecommendationDescription => '为确保数据安全，建议在导入前手动创建备份';

  @override
  String get backupRestartWarning => '重启应用以应用更改';

  @override
  String backupRestoreFailedMessage(Object error) {
    return '备份恢复失败: $error';
  }

  @override
  String get backupRestoreSuccessMessage => '备份恢复成功，请重启应用以完成恢复';

  @override
  String get backupRestoreSuccessWithRestartMessage => '备份恢复成功，需要重启应用以应用更改。';

  @override
  String get backupRestoredSuccessfully => '备份恢复成功，请重启应用以完成恢复';

  @override
  String get backupServiceInitializing => '备份服务正在初始化中，请稍等片刻后重试';

  @override
  String get backupServiceNotAvailable => '备份服务暂时不可用';

  @override
  String get backupServiceNotInitialized => '备份服务未初始化';

  @override
  String get backupServiceNotReady => '备份服务暂时不可用';

  @override
  String get backupSettings => '备份与恢复';

  @override
  String backupSize(Object size) {
    return '大小: $size';
  }

  @override
  String get backupStatistics => '备份统计';

  @override
  String get backupStorageLocation => '备份存储位置';

  @override
  String get backupSuccess => '备份创建成功';

  @override
  String get backupSuccessCanSwitchPath => '备份创建成功，可以安全进行路径切换';

  @override
  String backupTimeLabel(Object time) {
    return '备份时间: $time';
  }

  @override
  String get backupTimeoutDetailedError => '备份操作超时。可能的原因：\n• 数据量过大\n• 存储空间不足\n• 磁盘读写速度慢\n\n请检查存储空间并重试。';

  @override
  String get backupTimeoutError => '备份创建超时或失败，请检查存储空间是否足够';

  @override
  String get backupVerificationFailed => '备份文件核验失败';

  @override
  String get backups => '备份';

  @override
  String get backupsCount => '个备份';

  @override
  String get basicInfo => '基本信息';

  @override
  String get basicProperties => '基础属性';

  @override
  String batchDeleteMessage(Object count) {
    return '即将删除$count项，此操作无法撤消。';
  }

  @override
  String get batchExportFailed => '批量导出失败';

  @override
  String batchExportFailedMessage(Object error) {
    return '批量导出失败: $error';
  }

  @override
  String get batchImport => '批量导入';

  @override
  String get batchMode => '批量模式';

  @override
  String get batchOperations => '批量操作';

  @override
  String get beforeDate => '某个日期之前';

  @override
  String get border => '边框';

  @override
  String get borderColor => '边框颜色';

  @override
  String get borderWidth => '边框宽度';

  @override
  String get boxRegion => '请在预览区域框选字符';

  @override
  String get boxTool => '框选工具';

  @override
  String get bringLayerToFront => '图层置于顶层';

  @override
  String get bringToFront => '置于顶层 (Ctrl+T)';

  @override
  String get browse => '浏览';

  @override
  String get browsePath => '浏览路径';

  @override
  String get brushSize => '笔刷尺寸';

  @override
  String get buildEnvironment => '构建环境';

  @override
  String get buildNumber => '构建号';

  @override
  String get buildTime => '构建时间';

  @override
  String get cacheClearedMessage => '缓存已成功清除';

  @override
  String get cacheSettings => '缓存设置';

  @override
  String get cacheSize => '缓存大小';

  @override
  String get calligraphyStyle => '书法风格';

  @override
  String get calligraphyStyleText => '书法风格';

  @override
  String get canChooseDirectSwitch => '• 您也可以选择直接切换';

  @override
  String get canCleanOldDataLater => '您可以稍后通过\"数据路径管理\"清理旧数据';

  @override
  String get canCleanupLaterViaManagement => '您可以稍后通过数据路径管理清理旧数据';

  @override
  String get canManuallyCleanLater => '• 您可以稍后手动清理旧路径的数据';

  @override
  String get canNotPreview => '无法生成预览';

  @override
  String get cancel => '取消';

  @override
  String get cancelAction => '取消';

  @override
  String get cannotApplyNoImage => '没有可用的图片';

  @override
  String get cannotApplyNoSizeInfo => '无法获取图片尺寸信息';

  @override
  String get cannotCapturePageImage => '无法捕获页面图像';

  @override
  String get cannotDeleteOnlyPage => '无法删除唯一的页面';

  @override
  String get cannotGetStorageInfo => '无法获取存储信息';

  @override
  String get cannotReadPathContent => '无法读取路径内容';

  @override
  String get cannotReadPathFileInfo => '无法读取路径文件信息';

  @override
  String get cannotSaveMissingController => '无法保存：缺少控制器';

  @override
  String get cannotSaveNoPages => '无页面，无法保存';

  @override
  String get canvasPixelSize => '画布像素大小';

  @override
  String get canvasResetViewTooltip => '重置视图位置';

  @override
  String get categories => '分类';

  @override
  String get categoryManagement => '分类管理';

  @override
  String get categoryName => '分类名称';

  @override
  String get categoryNameCannotBeEmpty => '分类名称不能为空';

  @override
  String get centimeter => '厘米';

  @override
  String get changeDataPathMessage => '更改数据路径后，应用程序需要重启才能生效。';

  @override
  String get changePath => '更换路径';

  @override
  String get character => '集字';

  @override
  String get characterCollection => '集字';

  @override
  String characterCollectionFindSwitchFailed(Object error) {
    return '查找并切换页面失败：$error';
  }

  @override
  String get characterCollectionPreviewTab => '字符预览';

  @override
  String get characterCollectionResultsTab => '采集结果';

  @override
  String get characterCollectionSearchHint => '搜索字符...';

  @override
  String get characterCollectionTitle => '字符采集';

  @override
  String get characterCollectionToolBox => '框选工具 (Ctrl+B)';

  @override
  String get characterCollectionToolPan => '平移工具 (Ctrl+V)';

  @override
  String get characterCollectionUseBoxTool => '使用框选工具从图像中提取字符';

  @override
  String get characterCount => '集字数量';

  @override
  String get characterDetailFormatBinary => '二值化';

  @override
  String get characterDetailFormatBinaryDesc => '黑白二值化图像';

  @override
  String get characterDetailFormatDescription => '描述';

  @override
  String get characterDetailFormatOutline => '轮廓';

  @override
  String get characterDetailFormatOutlineDesc => '仅显示轮廓';

  @override
  String get characterDetailFormatSquareBinary => '方形二值化';

  @override
  String get characterDetailFormatSquareBinaryDesc => '规整为正方形的二值化图像';

  @override
  String get characterDetailFormatSquareOutline => '方形轮廓';

  @override
  String get characterDetailFormatSquareOutlineDesc => '规整为正方形的轮廓图像';

  @override
  String get characterDetailFormatSquareTransparent => '方形透明';

  @override
  String get characterDetailFormatSquareTransparentDesc => '规整为正方形的透明PNG图像';

  @override
  String get characterDetailFormatThumbnail => '缩略图';

  @override
  String get characterDetailFormatThumbnailDesc => '缩略图';

  @override
  String get characterDetailFormatTransparent => '透明';

  @override
  String get characterDetailFormatTransparentDesc => '去背景的透明PNG图像';

  @override
  String get characterDetailLoadError => '加载字符详情失败';

  @override
  String get characterDetailSimplifiedChar => '简体字符';

  @override
  String get characterDetailTitle => '字符详情';

  @override
  String characterEditSaveConfirmMessage(Object character) {
    return '确认保存「$character」？';
  }

  @override
  String get characterUpdated => '字符已更新';

  @override
  String get characters => '集字';

  @override
  String charactersCount(Object count) {
    return '$count 个集字';
  }

  @override
  String charactersSelected(Object count) {
    return '已选择 $count 个字符';
  }

  @override
  String get checkBackupRecommendationFailed => '检查备份建议失败';

  @override
  String get checkFailedRecommendBackup => '检查失败，建议先创建备份以确保数据安全';

  @override
  String get checkSpecialChars => '• 检查作品标题是否包含特殊字符';

  @override
  String get cleanDuplicateRecords => '清理重复记录';

  @override
  String get cleanDuplicateRecordsDescription => '此操作将清理重复的备份记录，不会删除实际的备份文件。';

  @override
  String get cleanDuplicateRecordsTitle => '清理重复记录';

  @override
  String cleanupCompleted(Object count) {
    return '清理完成，移除了 $count 个无效路径';
  }

  @override
  String cleanupCompletedMessage(Object count) {
    return '清理完成，移除了 $count 个无效路径';
  }

  @override
  String cleanupCompletedWithCount(Object count) {
    return '清理完成，移除了 $count 个重复记录';
  }

  @override
  String get cleanupFailed => '清理失败';

  @override
  String cleanupFailedMessage(Object error) {
    return '清理失败: $error';
  }

  @override
  String get cleanupInvalidPaths => '清理无效路径';

  @override
  String cleanupOperationFailed(Object error) {
    return '清理操作失败: $error';
  }

  @override
  String get clearCache => '清除缓存';

  @override
  String get clearCacheConfirmMessage => '确定要清除所有缓存数据吗？这将释放磁盘空间，但可能会暂时降低应用程序的速度。';

  @override
  String get clearSelection => '取消选择';

  @override
  String get close => '关闭';

  @override
  String get code => '代码';

  @override
  String get collapse => '收起';

  @override
  String get collapseFileList => '点击收起文件列表';

  @override
  String get collectionDate => '采集日期';

  @override
  String get collectionElement => '集字元素';

  @override
  String get collectionIdCannotBeEmpty => '集字ID不能为空';

  @override
  String get collectionTime => '采集时间';

  @override
  String get color => '颜色';

  @override
  String get colorCode => '颜色代码';

  @override
  String get colorCodeHelp => '输入6位十六进制颜色代码 (例如: FF5500)';

  @override
  String get colorCodeInvalid => '无效的颜色代码';

  @override
  String get colorInversion => '颜色反转';

  @override
  String get colorPicker => '选择颜色';

  @override
  String get colorSettings => '颜色设置';

  @override
  String get commonProperties => '通用属性';

  @override
  String get commonTags => '常用标签:';

  @override
  String get completingSave => '完成保存...';

  @override
  String get compressData => '压缩数据';

  @override
  String get compressDataDescription => '减小导出文件大小';

  @override
  String get configInitFailed => '配置数据初始化失败';

  @override
  String get configInitializationFailed => '配置初始化失败';

  @override
  String get configInitializing => '正在初始化配置...';

  @override
  String get configKey => '配置键';

  @override
  String get configManagement => '配置管理';

  @override
  String get configManagementDescription => '管理书法风格和书写工具配置';

  @override
  String get configManagementTitle => '书法风格管理';

  @override
  String get confirm => '确定';

  @override
  String get confirmChangeDataPath => '确认更改数据路径';

  @override
  String get confirmContinue => '确定要继续吗？';

  @override
  String get confirmDataNormalBeforeClean => '• 建议确认数据正常后再清理旧路径';

  @override
  String get confirmDataPathSwitch => '确认数据路径切换';

  @override
  String get confirmDelete => '确认删除';

  @override
  String get confirmDeleteAction => '确认删除';

  @override
  String get confirmDeleteAll => '确认删除所有';

  @override
  String get confirmDeleteAllBackups => '确认删除所有备份';

  @override
  String get confirmDeleteAllButton => '确认删除全部';

  @override
  String confirmDeleteBackup(Object description, Object filename) {
    return '确定要删除备份文件\"$filename\"（$description）吗？\n此操作不可撤销。';
  }

  @override
  String confirmDeleteBackupPath(Object path) {
    return '确定要删除整个备份路径吗？\n\n路径：$path\n\n这将会：\n• 删除该路径下的所有备份文件\n• 从历史记录中移除该路径\n• 此操作不可恢复\n\n请谨慎操作！';
  }

  @override
  String get confirmDeleteButton => '确认删除';

  @override
  String get confirmDeleteHistoryPath => '确定要删除此历史路径记录吗？';

  @override
  String get confirmDeleteTitle => '确认删除';

  @override
  String get confirmExitWizard => '确定要退出数据路径切换向导吗？';

  @override
  String get confirmImportAction => '确定导入';

  @override
  String get confirmImportButton => '确认导入';

  @override
  String get confirmOverwrite => '确认覆盖';

  @override
  String confirmRemoveFromCategory(Object count) {
    return '确定要将选中的$count个项目从当前分类中移除吗？';
  }

  @override
  String get confirmResetToDefaultPath => '确认重置为默认路径';

  @override
  String get confirmRestoreAction => '确定恢复';

  @override
  String get confirmRestoreBackup => '确定要恢复这个备份吗？';

  @override
  String get confirmRestoreButton => '确认恢复';

  @override
  String get confirmRestoreMessage => '您即将恢复以下备份：';

  @override
  String get confirmRestoreTitle => '确认恢复';

  @override
  String get confirmShortcuts => '快捷键：Enter 确认，Esc 取消';

  @override
  String get confirmSkip => '确定跳过';

  @override
  String get confirmSkipAction => '确定跳过';

  @override
  String get confirmSwitch => '确认切换';

  @override
  String get confirmSwitchButton => '确认切换';

  @override
  String get confirmSwitchToNewPath => '确认切换到新的数据路径';

  @override
  String get conflictDetailsTitle => '冲突处理明细';

  @override
  String get conflictReason => '冲突原因';

  @override
  String get conflictResolution => '冲突解决';

  @override
  String conflictsCount(Object count) {
    return '发现 $count 个冲突';
  }

  @override
  String get conflictsFound => '发现冲突';

  @override
  String get contentProperties => '内容属性';

  @override
  String get contentSettings => '内容设置';

  @override
  String get continueDuplicateImport => '是否仍要继续导入此备份？';

  @override
  String get continueImport => '继续导入';

  @override
  String get continueQuestion => '是否继续？';

  @override
  String get copy => '复制 (Ctrl+Shift+C)';

  @override
  String copyFailed(Object error) {
    return '复制失败: $error';
  }

  @override
  String get copyFormat => '复制格式 (Alt+Q)';

  @override
  String get copySelected => '复制选中项目';

  @override
  String get copyVersionInfo => '复制版本信息';

  @override
  String get couldNotGetFilePath => '无法获取文件路径';

  @override
  String get countUnit => '个';

  @override
  String get create => '创建';

  @override
  String get createBackup => '创建备份';

  @override
  String get createBackupBeforeImport => '导入前创建备份';

  @override
  String get createBackupDescription => '创建新的数据备份';

  @override
  String get createBackupFailed => '创建备份失败';

  @override
  String createBackupFailedMessage(Object error) {
    return '创建备份失败: $error';
  }

  @override
  String createExportDirectoryFailed(Object error) {
    return '创建导出目录失败$error';
  }

  @override
  String get createFirstBackup => '创建第一个备份';

  @override
  String get createTime => '创建时间';

  @override
  String get createdAt => '创建时间';

  @override
  String get creatingBackup => '正在创建备份...';

  @override
  String get creatingBackupPleaseWaitMessage => '这可能需要几分钟时间，请耐心等待';

  @override
  String get creatingBackupProgressMessage => '正在创建备份...';

  @override
  String get creationDate => '创作日期';

  @override
  String get criticalError => '严重错误';

  @override
  String get cropBottom => '底部裁剪';

  @override
  String get cropLeft => '左侧裁剪';

  @override
  String get cropRight => '右侧裁剪';

  @override
  String get cropTop => '顶部裁剪';

  @override
  String get cropping => '裁剪';

  @override
  String croppingApplied(Object bottom, Object left, Object right, Object top) {
    return '(裁剪：左${left}px，上${top}px，右${right}px，下${bottom}px)';
  }

  @override
  String get currentBackupPathNotSet => '当前备份路径未设置';

  @override
  String get currentCharInversion => '当前字符反转';

  @override
  String get currentCustomPath => '当前使用自定义数据路径';

  @override
  String get currentDataPath => '当前数据路径';

  @override
  String get currentDefaultPath => '当前使用默认数据路径';

  @override
  String get currentLabel => '当前';

  @override
  String get currentLocation => '当前位置';

  @override
  String get currentPage => '当前页面';

  @override
  String get currentPath => '当前路径';

  @override
  String get currentPathBackup => '当前路径备份';

  @override
  String get currentPathBackupDescription => '当前路径备份';

  @override
  String get currentPathFileExists => '当前路径下已存在同名备份文件：';

  @override
  String get currentPathFileExistsMessage => '当前路径下已存在同名备份文件：';

  @override
  String get currentStorageInfo => '当前存储信息';

  @override
  String get currentStorageInfoSubtitle => '查看当前存储空间使用情况';

  @override
  String get currentStorageInfoTitle => '当前存储信息';

  @override
  String get currentTool => '当前工具';

  @override
  String get custom => '自定义';

  @override
  String get customPath => '自定义路径';

  @override
  String get customRange => '自定义范围';

  @override
  String get customSize => '自定义大小';

  @override
  String get cutSelected => '剪切选中项目';

  @override
  String get dangerZone => '危险区域';

  @override
  String get dangerousOperationConfirm => '危险操作确认';

  @override
  String get dangerousOperationConfirmTitle => '危险操作确认';

  @override
  String get dartVersion => 'Dart版本';

  @override
  String get dataBackup => '数据备份';

  @override
  String get dataEmpty => '数据为空';

  @override
  String get dataIncomplete => '数据不完整';

  @override
  String get dataMergeOptions => '数据合并选项：';

  @override
  String get dataPath => '数据路径';

  @override
  String get dataPathChangedMessage => '数据路径已更改，请重启应用程序以使更改生效。';

  @override
  String get dataPathHint => '选择数据存储路径';

  @override
  String get dataPathManagement => '数据路径管理';

  @override
  String get dataPathManagementSubtitle => '管理当前和历史数据路径';

  @override
  String get dataPathManagementTitle => '数据路径管理';

  @override
  String get dataPathSettings => '数据存储路径';

  @override
  String get dataPathSettingsDescription => '设置应用数据的存储位置。更改后需要重启应用程序。';

  @override
  String get dataPathSettingsSubtitle => '配置应用数据的存储位置';

  @override
  String get dataPathSwitchOptions => '数据路径切换选项';

  @override
  String get dataPathSwitchWizard => '数据路径切换向导';

  @override
  String get dataSafetyRecommendation => '数据安全建议';

  @override
  String get dataSafetySuggestion => '数据安全建议';

  @override
  String get dataSafetySuggestions => '数据安全建议';

  @override
  String get dataSize => '数据大小';

  @override
  String get databaseSize => '数据库大小';

  @override
  String get dayBeforeYesterday => '前天';

  @override
  String days(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count天',
      one: '1天',
    );
    return '$_temp0';
  }

  @override
  String get daysAgo => '天前';

  @override
  String get defaultEditableText => '属性面板编辑文本';

  @override
  String get defaultLayer => '默认图层';

  @override
  String defaultLayerName(Object number) {
    return '图层$number';
  }

  @override
  String get defaultPage => '默认页面';

  @override
  String defaultPageName(Object number) {
    return '页面$number';
  }

  @override
  String get defaultPath => '默认路径';

  @override
  String get defaultPathName => '默认路径';

  @override
  String get delete => '删除 (Ctrl+D)';

  @override
  String get deleteAll => '全部删除';

  @override
  String get deleteAllBackups => '删除所有备份';

  @override
  String get deleteBackup => '删除备份';

  @override
  String get deleteBackupFailed => '删除备份失败';

  @override
  String deleteBackupsCountMessage(Object count) {
    return '您即将删除 $count 个备份文件。';
  }

  @override
  String get deleteCategory => '删除分类';

  @override
  String get deleteCategoryOnly => '仅删除分类';

  @override
  String get deleteCategoryWithFiles => '删除分类及文件';

  @override
  String deleteCharacterFailed(Object error) {
    return '删除字符失败：$error';
  }

  @override
  String get deleteCompleteTitle => '删除完成';

  @override
  String get deleteConfigItem => '删除配置项';

  @override
  String get deleteConfigItemMessage => '确定要删除这个配置项吗？此操作不可撤销。';

  @override
  String get deleteConfirm => '确认删除';

  @override
  String get deleteElementConfirmMessage => '确定要删除这些元素吗？';

  @override
  String deleteFailCount(Object count) {
    return '删除失败: $count 个文件';
  }

  @override
  String get deleteFailDetails => '失败详情:';

  @override
  String deleteFailed(Object error) {
    return '删除失败：$error';
  }

  @override
  String deleteFailedMessage(Object error) {
    return '删除失败: $error';
  }

  @override
  String get deleteFailure => '备份删除失败';

  @override
  String get deleteGroup => '删除组';

  @override
  String get deleteGroupConfirm => '确认删除组';

  @override
  String get deleteHistoryPathNote => '注意：这只会删除记录，不会删除实际的文件夹和数据。';

  @override
  String get deleteHistoryPathRecord => '删除历史路径记录';

  @override
  String get deleteImage => '删除图片';

  @override
  String get deleteLastMessage => '这是最后一项目。确定要删除吗？';

  @override
  String get deleteLayer => '删除图层';

  @override
  String get deleteLayerConfirmMessage => '确定要删除此图层吗？';

  @override
  String get deleteLayerMessage => '此图层上的所有元素将被删除。此操作无法撤消。';

  @override
  String deleteMessage(Object count) {
    return '即将删除，此操作无法撤消。';
  }

  @override
  String get deletePage => '删除页面';

  @override
  String get deletePath => '删除路径';

  @override
  String get deletePathButton => '删除路径';

  @override
  String deletePathConfirmContent(Object path) {
    return '确定要删除备份路径 $path 吗？此操作不可撤销，将删除该路径下的所有备份文件。';
  }

  @override
  String deleteRangeItem(Object count, Object path) {
    return '• $path: $count 个文件';
  }

  @override
  String get deleteRangeTitle => '删除范围包括：';

  @override
  String get deleteSelected => '删除所选';

  @override
  String get deleteSelectedArea => '删除选中区域';

  @override
  String get deleteSelectedWithShortcut => '删除所选（Ctrl+D）';

  @override
  String get deleteSuccess => '备份删除成功';

  @override
  String deleteSuccessCount(Object count) {
    return '成功删除: $count 个文件';
  }

  @override
  String get deleteText => '删除';

  @override
  String get deleting => '正在删除...';

  @override
  String get deletingBackups => '正在删除备份...';

  @override
  String get deletingBackupsProgress => '正在删除备份文件，请稍候...';

  @override
  String get descending => '降序';

  @override
  String get descriptionLabel => '描述';

  @override
  String get deselectAll => '取消选择';

  @override
  String get detail => '详情';

  @override
  String get detailedError => '详细错误';

  @override
  String get detailedReport => '详细报告';

  @override
  String get deviceInfo => '设备信息';

  @override
  String get dimensions => '尺寸';

  @override
  String get directSwitch => '直接切换';

  @override
  String get disabled => '已禁用';

  @override
  String get disabledDescription => '禁用 - 在选择器中隐藏';

  @override
  String get diskCacheSize => '磁盘缓存大小';

  @override
  String get diskCacheSizeDescription => '磁盘缓存的最大大小';

  @override
  String get diskCacheTtl => '磁盘缓存生命周期';

  @override
  String get diskCacheTtlDescription => '缓存文件在磁盘上保留的时间';

  @override
  String get displayMode => '显示模式';

  @override
  String get displayName => '显示名称';

  @override
  String get displayNameCannotBeEmpty => '显示名称不能为空';

  @override
  String get displayNameHint => '用户界面中显示的名称';

  @override
  String get displayNameMaxLength => '显示名称最多100个字符';

  @override
  String get displayNameRequired => '请输入显示名称';

  @override
  String get distributeHorizontally => '水平均匀分布';

  @override
  String get distributeVertically => '垂直均匀分布';

  @override
  String get distribution => '分布';

  @override
  String get doNotCloseApp => '请不要关闭应用程序...';

  @override
  String get doNotCloseAppMessage => '请勿关闭应用，恢复过程可能需要几分钟';

  @override
  String get done => '确定';

  @override
  String get dropToImportImages => '释放鼠标以导入图片';

  @override
  String get duplicateBackupFound => '发现重复备份';

  @override
  String get duplicateBackupFoundDesc => '检测到要导入的备份文件与现有备份重复：';

  @override
  String get duplicateFileImported => '(重复文件已导入)';

  @override
  String get dynasty => '朝代';

  @override
  String get edit => '编辑';

  @override
  String get editConfigItem => '编辑配置项';

  @override
  String editField(Object field) {
    return '编辑$field';
  }

  @override
  String get editGroupContents => '编辑组内容';

  @override
  String get editGroupContentsDescription => '编辑已选组的内容';

  @override
  String editLabel(Object label) {
    return '编辑$label';
  }

  @override
  String get editOperations => '编辑操作';

  @override
  String get editTags => '编辑标签';

  @override
  String get editTitle => '编辑标题';

  @override
  String get elementCopied => '元素已复制到剪贴板';

  @override
  String get elementCopiedToClipboard => '元素已复制到剪贴板';

  @override
  String get elementHeight => '高';

  @override
  String get elementId => '元素ID';

  @override
  String get elementSize => '大小';

  @override
  String get elementWidth => '宽';

  @override
  String get elements => '元素';

  @override
  String get empty => '空';

  @override
  String get emptyGroup => '空组合';

  @override
  String get emptyStateError => '加载失败,请稍后再试';

  @override
  String get emptyStateNoCharacters => '没有字形,从作品中提取字形后可在此查看';

  @override
  String get emptyStateNoPractices => '没有字帖，点击添加按钮创建新字帖';

  @override
  String get emptyStateNoResults => '没有找到匹配的结果,尝试更改搜索条件';

  @override
  String get emptyStateNoSelection => '未选择任何项目,点击项目以选择';

  @override
  String get emptyStateNoWorks => '没有作品，点击添加按钮导入作品';

  @override
  String get enabled => '已启用';

  @override
  String get endDate => '结束日期';

  @override
  String get ensureCompleteTransfer => '• 确保文件完整传输';

  @override
  String get ensureReadWritePermission => '确保新路径有读写权限';

  @override
  String get enterBackupDescription => '请输入备份描述（可选）：';

  @override
  String get enterCategoryName => '请输入分类名称';

  @override
  String get enterTagHint => '输入标签并按Enter';

  @override
  String error(Object message) {
    return '错误：$message';
  }

  @override
  String get errors => '错误';

  @override
  String get estimatedTime => '预计时间';

  @override
  String get executingImportOperation => '正在执行导入操作...';

  @override
  String existingBackupInfo(Object filename) {
    return '现有备份: $filename';
  }

  @override
  String get existingItem => '现有项目';

  @override
  String get exit => '退出';

  @override
  String get exitBatchMode => '退出批量模式';

  @override
  String get exitConfirm => '退出';

  @override
  String get exitPreview => '退出预览模式';

  @override
  String get exitWizard => '退出向导';

  @override
  String get expand => '展开';

  @override
  String expandFileList(Object count) {
    return '点击展开查看 $count 个备份文件';
  }

  @override
  String get export => '导出';

  @override
  String get exportAllBackups => '导出所有备份';

  @override
  String get exportAllBackupsButton => '导出全部备份';

  @override
  String get exportBackup => '导出备份';

  @override
  String get exportBackupFailed => '导出备份失败';

  @override
  String exportBackupFailedMessage(Object error) {
    return '导出备份失败: $error';
  }

  @override
  String get exportCharactersOnly => '仅导出集字';

  @override
  String get exportCharactersOnlyDescription => '仅包含选中的集字数据';

  @override
  String get exportCharactersWithWorks => '导出集字和来源作品（推荐）';

  @override
  String get exportCharactersWithWorksDescription => '包含集字及其来源作品数据';

  @override
  String exportCompleted(Object failed, Object success) {
    return '导出完成: 成功 $success 个$failed';
  }

  @override
  String exportCompletedFormat(Object failedMessage, Object successCount) {
    return '导出完成: 成功 $successCount 个$failedMessage';
  }

  @override
  String exportCompletedFormat2(Object failed, Object success) {
    return '导出完成，成功: $success$failed';
  }

  @override
  String get exportConfig => '导出配置';

  @override
  String get exportDialogRangeExample => '例如: 1-3,5,7-9';

  @override
  String exportDimensions(Object height, Object orientation, Object width) {
    return '$width厘米 × $height厘米 ($orientation)';
  }

  @override
  String get exportEncodingIssue => '• 导出时存在特殊字符编码问题';

  @override
  String get exportFailed => '导出失败';

  @override
  String exportFailedPartFormat(Object failCount) {
    return '，失败 $failCount 个';
  }

  @override
  String exportFailedPartFormat2(Object count) {
    return ', 失败: $count';
  }

  @override
  String exportFailedWith(Object error) {
    return '导出失败: $error';
  }

  @override
  String get exportFailure => '备份导出失败';

  @override
  String get exportFormat => '导出格式';

  @override
  String get exportFullData => '完整数据导出';

  @override
  String get exportFullDataDescription => '包含所有相关数据';

  @override
  String get exportLocation => '导出位置';

  @override
  String get exportNotImplemented => '配置导出功能待实现';

  @override
  String get exportOptions => '导出选项';

  @override
  String get exportSuccess => '备份导出成功';

  @override
  String exportSuccessMessage(Object path) {
    return '备份导出成功: $path';
  }

  @override
  String get exportSummary => '导出摘要';

  @override
  String get exportType => '导出格式';

  @override
  String get exportWorksOnly => '仅导出作品';

  @override
  String get exportWorksOnlyDescription => '仅包含选中的作品数据';

  @override
  String get exportWorksWithCharacters => '导出作品和关联集字（推荐）';

  @override
  String get exportWorksWithCharactersDescription => '包含作品及其相关的集字数据';

  @override
  String get exporting => '正在导出，请稍候...';

  @override
  String get exportingBackup => '导出备份中...';

  @override
  String get exportingBackupMessage => '正在导出备份...';

  @override
  String exportingBackups(Object count) {
    return '正在导出 $count 个备份...';
  }

  @override
  String get exportingBackupsProgress => '正在导出备份...';

  @override
  String exportingBackupsProgressFormat(Object count) {
    return '正在导出 $count 个备份文件...';
  }

  @override
  String get exportingDescription => '正在导出数据，请稍候...';

  @override
  String get extract => '提取';

  @override
  String get extractionError => '提取发生错误';

  @override
  String failedCount(Object count) {
    return ', 失败 $count 个';
  }

  @override
  String get favorite => '收藏';

  @override
  String get favoritesOnly => '仅显示收藏';

  @override
  String get fileCorrupted => '• 文件在传输过程中损坏';

  @override
  String get fileCount => '文件数量';

  @override
  String get fileExistsTitle => '文件已存在';

  @override
  String get fileExtension => '文件扩展名';

  @override
  String get fileMigrationWarning => '不迁移文件时，旧路径的备份文件仍保留在原位置';

  @override
  String get fileName => '文件名称';

  @override
  String fileNotExist(Object path) {
    return '文件不存在：$path';
  }

  @override
  String get fileRestored => '图片已从图库中恢复';

  @override
  String get fileSize => '文件大小';

  @override
  String get fileUpdatedAt => '文件修改时间';

  @override
  String get filenamePrefix => '输入文件名前缀（将自动添加页码）';

  @override
  String get files => '文件数量';

  @override
  String get filter => '筛选';

  @override
  String get filterAndSort => '筛选与排序';

  @override
  String get filterClear => '清除';

  @override
  String get firstPage => '第一页';

  @override
  String get fitContain => '包含';

  @override
  String get fitCover => '覆盖';

  @override
  String get fitFill => '填充';

  @override
  String get fitHeight => '适合高度';

  @override
  String get fitMode => '适配方式';

  @override
  String get fitWidth => '适合宽度';

  @override
  String get flip => '翻转';

  @override
  String get flipHorizontal => '水平翻转';

  @override
  String get flipVertical => '垂直翻转';

  @override
  String get flutterVersion => 'Flutter版本';

  @override
  String get folderImportComplete => '文件夹导入完成';

  @override
  String get fontColor => '文本颜色';

  @override
  String get fontFamily => '字体';

  @override
  String get fontSize => '字体大小';

  @override
  String get fontStyle => '字体样式';

  @override
  String get fontTester => '字体测试工具';

  @override
  String get fontWeight => '字体粗细';

  @override
  String get fontWeightTester => '字体粗细测试工具';

  @override
  String get format => '格式';

  @override
  String get formatBrushActivated => '格式刷已激活，点击目标元素应用样式';

  @override
  String get formatType => '格式类型';

  @override
  String get fromGallery => '从图库选择';

  @override
  String get fromLocal => '从本地选择';

  @override
  String get fullScreen => '全屏显示';

  @override
  String get geometryProperties => '几何属性';

  @override
  String get getHistoryPathsFailed => '获取历史路径失败';

  @override
  String get getPathInfoFailed => '无法获取路径信息';

  @override
  String get getPathUsageTimeFailed => '获取路径使用时间失败';

  @override
  String get getStorageInfoFailed => '获取存储信息失败';

  @override
  String get getThumbnailSizeError => '获取缩略图大小失败';

  @override
  String get gettingPathInfo => '获取路径信息中...';

  @override
  String get gettingStorageInfo => '正在获取存储信息...';

  @override
  String get gitBranch => 'Git分支';

  @override
  String get gitCommit => 'Git提交';

  @override
  String get goToBackup => '前往备份';

  @override
  String get gridSettings => '网格设置';

  @override
  String get gridSize => '网格大小';

  @override
  String get gridSizeExtraLarge => '特大';

  @override
  String get gridSizeLarge => '大';

  @override
  String get gridSizeMedium => '中';

  @override
  String get gridSizeSmall => '小';

  @override
  String get gridView => '网格视图';

  @override
  String get group => '组合 (Ctrl+J)';

  @override
  String get groupElements => '组合元素';

  @override
  String get groupOperations => '组合操作';

  @override
  String get groupProperties => '组属性';

  @override
  String get height => '高度';

  @override
  String get help => '帮助';

  @override
  String get hideDetails => '隐藏详情';

  @override
  String get hideElement => '隐藏元素';

  @override
  String get hideGrid => '隐藏网格 (Ctrl+G)';

  @override
  String get hideImagePreview => '隐藏图片预览';

  @override
  String get hideThumbnails => '隐藏页面缩略图';

  @override
  String get historicalPaths => '历史路径';

  @override
  String get historyDataPaths => '历史数据路径';

  @override
  String get historyLabel => '历史';

  @override
  String get historyLocation => '历史位置';

  @override
  String get historyPath => '历史路径';

  @override
  String get historyPathBackup => '历史路径备份';

  @override
  String get historyPathBackupDescription => '历史路径备份';

  @override
  String get historyPathDeleted => '历史路径记录已删除';

  @override
  String get homePage => '主页';

  @override
  String get horizontalAlignment => '水平对齐';

  @override
  String get horizontalLeftToRight => '横排左起';

  @override
  String get horizontalRightToLeft => '横排右起';

  @override
  String hours(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count小时',
      one: '1小时',
    );
    return '$_temp0';
  }

  @override
  String get hoursAgo => '小时前';

  @override
  String get image => '图片';

  @override
  String get imageCount => '图像数量';

  @override
  String get imageElement => '图片元素';

  @override
  String get imageExportFailed => '图片导出失败';

  @override
  String get imageFileNotExists => '图片文件不存在';

  @override
  String imageImportError(Object error) {
    return '导入图像失败：$error';
  }

  @override
  String get imageImportSuccess => '图像导入成功';

  @override
  String get imageIndexError => '图片索引错误';

  @override
  String get imageInvalid => '图像数据无效或已损坏';

  @override
  String get imageInvert => '图像反转';

  @override
  String imageLoadError(Object error) {
    return '加载图像失败：$error...';
  }

  @override
  String get imageLoadFailed => '图片加载失败';

  @override
  String imageProcessingPathError(Object error) {
    return '处理路径错误：$error';
  }

  @override
  String get imageProperties => '图像属性';

  @override
  String get imagePropertyPanelAutoImportNotice => '所选图像将自动导入到您的图库中以便更好地管理';

  @override
  String get imagePropertyPanelGeometryWarning => '这些属性调整整个元素框，而不是图像内容本身';

  @override
  String get imagePropertyPanelPreviewNotice => '注意：预览期间显示的重复日志是正常的';

  @override
  String get imagePropertyPanelTransformWarning => '这些变换会修改图像内容本身，而不仅仅是元素框架';

  @override
  String get imageResetSuccess => '重置成功';

  @override
  String get imageRestoring => '正在恢复图片数据...';

  @override
  String get imageSelection => '图片选择';

  @override
  String get imageTransform => '图像变换';

  @override
  String imageTransformError(Object error) {
    return '应用变换失败：$error';
  }

  @override
  String get imageUpdated => '图片已更新';

  @override
  String get images => '图片';

  @override
  String get implementationComingSoon => '此功能正在开发中，敬请期待！';

  @override
  String get import => '导入';

  @override
  String get importBackup => '导入备份';

  @override
  String get importBackupFailed => '导入备份失败';

  @override
  String importBackupFailedMessage(Object error) {
    return '导入备份失败: $error';
  }

  @override
  String get importConfig => '导入配置';

  @override
  String get importError => '导入错误';

  @override
  String get importErrorCauses => '该问题通常由以下原因引起：';

  @override
  String importFailed(Object error) {
    return '导入失败: $error';
  }

  @override
  String get importFailure => '备份导入失败';

  @override
  String get importFileSuccess => '成功导入文件';

  @override
  String get importFiles => '导入文件';

  @override
  String get importFolder => '导入文件夹';

  @override
  String get importNotImplemented => '配置导入功能待实现';

  @override
  String get importOptions => '导入选项';

  @override
  String get importPreview => '导入预览';

  @override
  String get importRequirements => '导入要求';

  @override
  String get importResultTitle => '导入结果';

  @override
  String get importStatistics => '导入统计';

  @override
  String get importSuccess => '备份导入成功';

  @override
  String importSuccessMessage(Object count) {
    return '成功导入 $count 个文件';
  }

  @override
  String get importToCurrentPath => '导入到当前路径';

  @override
  String get importToCurrentPathButton => '导入到当前路径';

  @override
  String get importToCurrentPathDesc => '这将复制备份文件到当前路径，原文件保持不变。';

  @override
  String get importToCurrentPathDescription => '导入后，此备份将出现在当前路径的备份列表中';

  @override
  String get importToCurrentPathFailed => '导入备份到当前路径失败';

  @override
  String get importToCurrentPathMessage => '您即将将此备份文件导入到当前备份路径：';

  @override
  String get importToCurrentPathSuccessMessage => '备份已成功导入到当前路径';

  @override
  String get importToCurrentPathTitle => '导入到当前路径';

  @override
  String get importantReminder => '重要提醒';

  @override
  String get importedBackupDescription => '导入的备份';

  @override
  String get importedCharacters => '导入集字';

  @override
  String get importedFile => '导入文件';

  @override
  String get importedImages => '导入图片';

  @override
  String get importedSuffix => '导入的备份';

  @override
  String get importedWorks => '导入作品';

  @override
  String get importing => '导入中...';

  @override
  String get importingBackup => '正在导入备份...';

  @override
  String get importingBackupProgressMessage => '正在导入备份...';

  @override
  String get importingDescription => '正在导入数据，请稍候...';

  @override
  String get importingToCurrentPath => '正在导入到当前路径...';

  @override
  String get importingToCurrentPathMessage => '正在导入到当前路径...';

  @override
  String get importingWorks => '正在导入作品...';

  @override
  String get includeImages => '包含图片';

  @override
  String get includeImagesDescription => '导出相关的图片文件';

  @override
  String get includeMetadata => '包含元数据';

  @override
  String get includeMetadataDescription => '导出创建时间、标签等元数据';

  @override
  String get incompatibleCharset => '• 使用了不兼容的字符集';

  @override
  String initializationFailed(Object error) {
    return '初始化失败：$error';
  }

  @override
  String get initializing => '初始化中...';

  @override
  String get inputCharacter => '输入字符';

  @override
  String get inputChineseContent => '请输入汉字内容';

  @override
  String inputFieldHint(Object field) {
    return '请输入$field';
  }

  @override
  String get inputFileName => '输入文件名';

  @override
  String get inputHint => '在此输入';

  @override
  String get inputNewTag => '输入新标签...';

  @override
  String get inputTitle => '请输入字帖标题';

  @override
  String get invalidFilename => '文件名不能包含以下字符: \\ / : * ? \" < > |';

  @override
  String get invalidNumber => '请输入有效的数字';

  @override
  String get invertMode => '反转模式';

  @override
  String get isActive => '是否激活';

  @override
  String itemsCount(Object count) {
    return '$count 个选项';
  }

  @override
  String itemsPerPage(Object count) {
    return '$count项/页';
  }

  @override
  String get jsonFile => 'JSON 文件';

  @override
  String get justNow => '刚刚';

  @override
  String get keepBackupCount => '保留备份数量';

  @override
  String get keepBackupCountDescription => '删除旧备份前保留的备份数量';

  @override
  String get keepExisting => '保留现有';

  @override
  String get keepExistingDescription => '保留现有数据，跳过导入';

  @override
  String get key => '键';

  @override
  String get keyCannotBeEmpty => '键不能为空';

  @override
  String get keyExists => '配置键已存在';

  @override
  String get keyHelperText => '只能包含字母、数字、下划线和连字符';

  @override
  String get keyHint => '配置项的唯一标识符';

  @override
  String get keyInvalidCharacters => '键只能包含字母、数字、下划线和连字符';

  @override
  String get keyMaxLength => '键最多50个字符';

  @override
  String get keyMinLength => '键至少需要2个字符';

  @override
  String get keyRequired => '请输入配置键';

  @override
  String get landscape => '横向';

  @override
  String get language => '语言';

  @override
  String get languageEn => 'English';

  @override
  String get languageJa => '日本語';

  @override
  String get languageKo => '한국어';

  @override
  String get languageSystem => '系统';

  @override
  String get languageZh => '简体中文';

  @override
  String get languageZhTw => '繁體中文';

  @override
  String get last30Days => '最近30天';

  @override
  String get last365Days => '最近365天';

  @override
  String get last7Days => '最近7天';

  @override
  String get last90Days => '最近90天';

  @override
  String get lastBackup => '最后备份';

  @override
  String get lastBackupTime => '上次备份时间';

  @override
  String get lastMonth => '上个月';

  @override
  String get lastPage => '最后一页';

  @override
  String get lastUsed => '最后使用';

  @override
  String get lastUsedTime => '上次使用';

  @override
  String get lastWeek => '上周';

  @override
  String get lastYear => '去年';

  @override
  String get layer => '图层';

  @override
  String get layer1 => '图层 1';

  @override
  String get layerElements => '图层元素';

  @override
  String get layerInfo => '图层信息';

  @override
  String layerName(Object index) {
    return '图层$index';
  }

  @override
  String get layerOperations => '图层操作';

  @override
  String get layerProperties => '图层属性';

  @override
  String get leave => '离开';

  @override
  String get legacyBackupDescription => '历史备份';

  @override
  String get legacyDataPathDescription => '需要清理的旧数据路径';

  @override
  String get letterSpacing => '字符间距';

  @override
  String get library => '图库';

  @override
  String get libraryCount => '图库数量';

  @override
  String get libraryManagement => '图库';

  @override
  String get lineHeight => '行间距';

  @override
  String get lineThrough => '删除线';

  @override
  String get listView => '列表视图';

  @override
  String get loadBackupRegistryFailed => '加载备份注册表失败';

  @override
  String loadCharacterDataFailed(Object error) {
    return '加载字符数据失败：$error';
  }

  @override
  String get loadConfigFailed => '加载配置失败';

  @override
  String get loadCurrentBackupPathFailed => '加载当前备份路径失败';

  @override
  String get loadDataFailed => '加载数据失败';

  @override
  String get loadFailed => '加载失败';

  @override
  String get loadPathInfoFailed => '加载路径信息失败';

  @override
  String get loadPracticeSheetFailed => '加载字帖失败';

  @override
  String get loading => '加载中...';

  @override
  String get loadingImage => '加载图像中...';

  @override
  String get location => '位置';

  @override
  String get lock => '锁定';

  @override
  String get lockElement => '锁定元素';

  @override
  String get lockStatus => '锁定状态';

  @override
  String get lockUnlockAllElements => '锁定/解锁所有元素';

  @override
  String get locked => '已锁定';

  @override
  String get manualBackupDescription => '手动创建的备份';

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
  String get memoryDataCacheCapacity => '内存数据缓存容量';

  @override
  String get memoryDataCacheCapacityDescription => '内存中保留的数据项数量';

  @override
  String get memoryImageCacheCapacity => '内存图像缓存容量';

  @override
  String get memoryImageCacheCapacityDescription => '内存中保留的图像数量';

  @override
  String get mergeAndMigrateFiles => '合并并迁移文件';

  @override
  String get mergeBackupInfo => '合并备份信息';

  @override
  String get mergeBackupInfoDesc => '将旧路径的备份信息合并到新路径的注册表中';

  @override
  String get mergeData => '合并数据';

  @override
  String get mergeDataDescription => '合并现有数据和导入数据';

  @override
  String get mergeOnlyBackupInfo => '仅合并备份信息';

  @override
  String get metadata => '元数据';

  @override
  String get migrateBackupFiles => '迁移备份文件';

  @override
  String get migrateBackupFilesDesc => '将旧路径的备份文件复制到新路径（推荐）';

  @override
  String get migratingData => '正在迁移数据';

  @override
  String get min => '最小';

  @override
  String get monospace => 'Monospace';

  @override
  String get monthsAgo => '个月前';

  @override
  String moreErrorsCount(Object count) {
    return '...还有 $count 个错误';
  }

  @override
  String get moveDown => '下移 (Ctrl+Shift+B)';

  @override
  String get moveLayerDown => '图层下移';

  @override
  String get moveLayerUp => '图层上移';

  @override
  String get moveUp => '上移 (Ctrl+Shift+T)';

  @override
  String get multiSelectTool => '多选工具';

  @override
  String multipleFilesNote(Object count) {
    return '注意: 将导出 $count 个图片文件，文件名将自动添加页码。';
  }

  @override
  String get name => '名称';

  @override
  String get navCollapseSidebar => '收起侧边栏';

  @override
  String get navExpandSidebar => '展开侧边栏';

  @override
  String get navigatedToBackupSettings => '已跳转到备份设置页面';

  @override
  String get navigationAttemptBack => '尝试返回上一个功能区';

  @override
  String get navigationAttemptToNewSection => '尝试导航到新功能区';

  @override
  String get navigationAttemptToSpecificItem => '尝试导航到特定历史记录项';

  @override
  String get navigationBackToPrevious => '返回到之前的页面';

  @override
  String get navigationClearHistory => '清空导航历史记录';

  @override
  String get navigationClearHistoryFailed => '清空导航历史记录失败';

  @override
  String get navigationFailedBack => '返回导航失败';

  @override
  String get navigationFailedSection => '导航切换失败';

  @override
  String get navigationFailedToSpecificItem => '导航到特定历史记录项失败';

  @override
  String get navigationHistoryCleared => '导航历史记录已清空';

  @override
  String get navigationItemNotFound => '历史记录中未找到目标项，直接导航到该功能区';

  @override
  String get navigationNoHistory => '无法返回';

  @override
  String get navigationNoHistoryMessage => '已经到达当前功能区的最开始页面。';

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
  String get navigationSectionCharacterManagement => '字符管理';

  @override
  String get navigationSectionGalleryManagement => '图库管理';

  @override
  String get navigationSectionPracticeList => '字帖列表';

  @override
  String get navigationSectionSettings => '设置';

  @override
  String get navigationSectionWorkBrowse => '作品浏览';

  @override
  String get navigationSelectPage => '您想返回到以下哪个页面？';

  @override
  String get navigationStateRestored => '导航状态已从存储恢复';

  @override
  String get navigationStateSaved => '导航状态已保存';

  @override
  String get navigationSuccessBack => '成功返回到上一个功能区';

  @override
  String get navigationSuccessToNewSection => '成功导航到新功能区';

  @override
  String get navigationSuccessToSpecificItem => '成功导航到特定历史记录项';

  @override
  String get navigationToggleExpanded => '切换导航栏展开状态';

  @override
  String get needRestartApp => '需要重启应用';

  @override
  String get newConfigItem => '新增配置项';

  @override
  String get newDataPath => '新的数据路径：';

  @override
  String get newItem => '新建';

  @override
  String get nextField => '下一个字段';

  @override
  String get nextPage => '下一页';

  @override
  String get nextStep => '下一步';

  @override
  String get no => '否';

  @override
  String get noBackupExistsRecommendCreate => '尚未创建任何备份，建议先创建备份以确保数据安全';

  @override
  String get noBackupFilesInPath => '此路径下没有备份文件';

  @override
  String get noBackupFilesInPathMessage => '此路径下没有备份文件';

  @override
  String get noBackupFilesToExport => '此路径下没有备份文件可导出';

  @override
  String get noBackupFilesToExportMessage => '没有备份文件可导出';

  @override
  String get noBackupPathSetRecommendCreateBackup => '未设置备份路径，建议先设置备份路径并创建备份';

  @override
  String get noBackupPaths => '没有备份路径';

  @override
  String get noBackups => '没有可用的备份';

  @override
  String get noBackupsInPath => '此路径下没有备份文件';

  @override
  String get noBackupsToDelete => '没有备份文件可删除';

  @override
  String get noCategories => '无分类';

  @override
  String get noCharacters => '未找到字符';

  @override
  String get noCharactersFound => '未找到匹配的字符';

  @override
  String noConfigItems(Object category) {
    return '暂无$category配置';
  }

  @override
  String get noCropping => '（无裁剪）';

  @override
  String get noDisplayableImages => '没有可显示的图片';

  @override
  String get noElementsInLayer => '此图层中没有元素';

  @override
  String get noElementsSelected => '未选择元素';

  @override
  String get noHistoryPaths => '没有历史路径';

  @override
  String get noHistoryPathsDescription => '尚未使用过其他数据路径';

  @override
  String get noImageSelected => '未选择图片';

  @override
  String get noImages => '没有图片';

  @override
  String get noItemsSelected => '未选择项目';

  @override
  String get noLayers => '无图层，请添加图层';

  @override
  String get noMatchingConfigItems => '未找到匹配的配置项';

  @override
  String get noPageSelected => '未选择页面';

  @override
  String get noPagesToExport => '没有可导出的页面';

  @override
  String get noPagesToPrint => '没有可打印的页面';

  @override
  String get noPreviewAvailable => '无有效预览';

  @override
  String get noRegionBoxed => '未选择区域';

  @override
  String get noRemarks => '无备注';

  @override
  String get noResults => '未找到结果';

  @override
  String get noTags => '无标签';

  @override
  String get noTexture => '无纹理';

  @override
  String get noTopLevelCategory => '无（顶级分类）';

  @override
  String get noWorks => '未找到作品';

  @override
  String get noWorksHint => '尝试导入新作品或更改筛选条件';

  @override
  String get noiseReduction => '降噪';

  @override
  String get none => '无';

  @override
  String get notSet => '未设置';

  @override
  String get note => '注意';

  @override
  String get notesTitle => '注意事项：';

  @override
  String get noticeTitle => '注意事项';

  @override
  String get ok => '确定';

  @override
  String get oldBackupRecommendCreateNew => '最近备份时间超过24小时，建议创建新备份';

  @override
  String get oldDataNotAutoDeleted => '路径切换后，旧数据不会自动删除';

  @override
  String get oldDataNotDeleted => '路径切换后，旧数据不会自动删除';

  @override
  String get oldDataWillNotBeDeleted => '切换后，旧路径的数据不会自动删除';

  @override
  String get oldPathDataNotAutoDeleted => '切换后，旧路径的数据不会自动删除';

  @override
  String get onlyOneCharacter => '只允许一个字符';

  @override
  String get opacity => '不透明度';

  @override
  String get openBackupManagementFailed => '打开备份管理失败';

  @override
  String get openFolder => '打开文件夹';

  @override
  String openGalleryFailed(Object error) {
    return '打开图库失败: $error';
  }

  @override
  String get openPathFailed => '打开路径失败';

  @override
  String get openPathSwitchWizardFailed => '打开数据路径切换向导失败';

  @override
  String get operatingSystem => '操作系统';

  @override
  String get operationCannotBeUndone => '此操作无法撤销，请谨慎确认';

  @override
  String get operationCannotUndo => '此操作无法撤销，请谨慎确认';

  @override
  String get optional => '可选';

  @override
  String get original => '原始';

  @override
  String get originalImageDesc => '未经处理的原始图像';

  @override
  String get outputQuality => '输出质量';

  @override
  String get overwrite => '覆盖';

  @override
  String get overwriteConfirm => '覆盖确认';

  @override
  String get overwriteExisting => '覆盖现有';

  @override
  String get overwriteExistingDescription => '用导入数据替换现有项目';

  @override
  String overwriteExistingPractice(Object title) {
    return '已存在名为\"$title\"的字帖，是否覆盖？';
  }

  @override
  String get overwriteFile => '覆盖文件';

  @override
  String get overwriteFileAction => '覆盖文件';

  @override
  String overwriteMessage(Object title) {
    return '已存在标题为\"$title\"的字帖，是否覆盖？';
  }

  @override
  String get overwrittenCharacters => '覆盖的集字';

  @override
  String get overwrittenItems => '覆盖的项目';

  @override
  String get overwrittenWorks => '覆盖的作品';

  @override
  String get padding => '内边距';

  @override
  String get pageBuildError => '页面构建错误';

  @override
  String get pageMargins => '页面边距 (厘米)';

  @override
  String get pageNotImplemented => '页面未实现';

  @override
  String get pageOrientation => '页面方向';

  @override
  String get pageProperties => '页面属性';

  @override
  String get pageRange => '页面范围';

  @override
  String get pageSize => '页面大小';

  @override
  String get pages => '页';

  @override
  String get parentCategory => '父分类（可选）';

  @override
  String get parsingImportData => '正在解析导入数据...';

  @override
  String get paste => '粘贴 (Ctrl+Shift+V)';

  @override
  String get path => '路径';

  @override
  String get pathAnalysis => '路径分析';

  @override
  String get pathConfigError => '路径配置错误';

  @override
  String get pathInfo => '路径信息';

  @override
  String get pathInvalid => '路径无效';

  @override
  String get pathNotExists => '路径不存在';

  @override
  String get pathSettings => '路径设置';

  @override
  String get pathSize => '路径大小';

  @override
  String get pathSwitchCompleted => '数据路径切换完成！\n\n您可以在\"数据路径管理\"中查看和清理旧路径的数据。';

  @override
  String get pathSwitchCompletedMessage => '数据路径切换完成！\n\n您可以在数据路径管理中查看和清理旧路径的数据。';

  @override
  String get pathSwitchFailed => '路径切换失败';

  @override
  String get pathSwitchFailedMessage => '路径切换失败';

  @override
  String pathValidationFailed(Object error) {
    return '路径验证失败: $error';
  }

  @override
  String get pathValidationFailedGeneric => '路径验证失败，请检查路径是否有效';

  @override
  String get pdfExportFailed => 'PDF导出失败';

  @override
  String pdfExportSuccess(Object path) {
    return 'PDF导出成功: $path';
  }

  @override
  String get pinyin => '拼音';

  @override
  String get pixels => '像素';

  @override
  String get platformInfo => '平台信息';

  @override
  String get pleaseEnterValidNumber => '请输入有效的数字';

  @override
  String get pleaseSelectOperation => '请选择操作：';

  @override
  String get pleaseSetBackupPathFirst => '请先设置备份路径';

  @override
  String get pleaseWaitMessage => '请稍候';

  @override
  String get portrait => '纵向';

  @override
  String get position => '位置';

  @override
  String get ppiSetting => 'PPI设置（每英寸像素数）';

  @override
  String get practiceEditCollection => '采集';

  @override
  String get practiceEditDefaultLayer => '默认图层';

  @override
  String practiceEditPracticeLoaded(Object title) {
    return '字帖\"$title\"加载成功';
  }

  @override
  String get practiceEditTitle => '字帖编辑';

  @override
  String get practiceListSearch => '搜索字帖...';

  @override
  String get practiceListTitle => '字帖';

  @override
  String get practiceSheetNotExists => '字帖不存在';

  @override
  String practiceSheetSaved(Object title) {
    return '字帖 \"$title\" 已保存';
  }

  @override
  String practiceSheetSavedMessage(Object title) {
    return '字帖 \"$title\" 保存成功';
  }

  @override
  String get practices => '字帖';

  @override
  String get preparingPrint => '正在准备打印，请稍候...';

  @override
  String get preparingSave => '准备保存...';

  @override
  String get preserveMetadata => '保留元数据';

  @override
  String get preserveMetadataDescription => '保留原始创建时间和元数据';

  @override
  String get preserveMetadataMandatory => '强制保留原始的创建时间、作者信息等元数据，确保数据一致性';

  @override
  String get presetSize => '预设大小';

  @override
  String get presets => '预设';

  @override
  String get preview => '预览';

  @override
  String get previewMode => '预览模式';

  @override
  String previewPage(Object current, Object total) {
    return '(第 $current/$total 页)';
  }

  @override
  String get previousField => '上一个字段';

  @override
  String get previousPage => '上一页';

  @override
  String get previousStep => '上一步';

  @override
  String processedCount(Object current, Object total) {
    return '已处理: $current / $total';
  }

  @override
  String processedProgress(Object current, Object total) {
    return '已处理: $current / $total';
  }

  @override
  String get processing => '处理中...';

  @override
  String get processingDetails => '处理详情';

  @override
  String get processingEraseData => '处理擦除数据...';

  @override
  String get processingImage => '处理图像中...';

  @override
  String get processingPleaseWait => '正在处理中，请稍候...';

  @override
  String get properties => '属性';

  @override
  String get qualityHigh => '高清 (2x)';

  @override
  String get qualityStandard => '标准 (1x)';

  @override
  String get qualityUltra => '超清 (3x)';

  @override
  String get quickRecoveryOnIssues => '• 切换过程中如遇问题可快速恢复';

  @override
  String get reExportWork => '• 重新导出该作品';

  @override
  String get recent => '最近';

  @override
  String get recentBackupCanSwitch => '最近已有备份，可以直接切换';

  @override
  String get recommendConfirmBeforeCleanup => '建议确认新路径数据正常后再清理旧路径';

  @override
  String get recommendConfirmNewDataBeforeClean => '建议确认新路径数据正常后再清理旧路径';

  @override
  String get recommendSufficientSpace => '建议选择剩余空间充足的磁盘';

  @override
  String get redo => '重做';

  @override
  String get refresh => '刷新';

  @override
  String refreshDataFailed(Object error) {
    return '刷新数据失败: $error';
  }

  @override
  String get reload => '重新加载';

  @override
  String get remarks => '备注';

  @override
  String get remarksHint => '添加备注信息';

  @override
  String get remove => '移除';

  @override
  String get removeFavorite => '从收藏中移除';

  @override
  String get removeFromCategory => '从当前分类移除';

  @override
  String get rename => '重命名';

  @override
  String get renameDuplicates => '重命名重复项';

  @override
  String get renameDuplicatesDescription => '重命名导入项目以避免冲突';

  @override
  String get renameLayer => '重命名图层';

  @override
  String get renderFailed => '渲染失败';

  @override
  String get reselectFile => '重新选择文件';

  @override
  String get reset => '重置';

  @override
  String resetCategoryConfig(Object category) {
    return '重置$category配置';
  }

  @override
  String resetCategoryConfigMessage(Object category) {
    return '确定要将$category配置重置为默认设置吗？此操作不可撤销。';
  }

  @override
  String get resetDataPathToDefault => '重置为默认';

  @override
  String get resetSettingsConfirmMessage => '确定重置为默认值吗？';

  @override
  String get resetSettingsConfirmTitle => '重置设置';

  @override
  String get resetToDefault => '重置为默认';

  @override
  String get resetToDefaultFailed => '重置为默认路径失败';

  @override
  String resetToDefaultFailedWithError(Object error) {
    return '重置为默认路径失败: $error';
  }

  @override
  String get resetToDefaultPathMessage => '这将把数据路径重置为默认位置，应用程序需要重启才能生效。确定要继续吗？';

  @override
  String get resetToDefaults => '重置为默认值';

  @override
  String get resetTransform => '重置变换';

  @override
  String get resetZoom => '重置缩放';

  @override
  String get resolution => '分辨率';

  @override
  String get restartAfterRestored => '注意：恢复完成后应用将自动重启';

  @override
  String get restartLaterButton => '稍后';

  @override
  String get restartNeeded => '需要重启';

  @override
  String get restartNow => '立即重启';

  @override
  String get restartNowButton => '立即重启';

  @override
  String get restore => '恢复';

  @override
  String get restoreBackup => '恢复备份';

  @override
  String get restoreBackupFailed => '恢复备份失败';

  @override
  String get restoreConfirmMessage => '确定要从此备份恢复吗？这将替换您当前的所有数据。';

  @override
  String get restoreConfirmTitle => '恢复确认';

  @override
  String get restoreFailure => '恢复失败';

  @override
  String get restoreWarningMessage => '警告：此操作将覆盖当前所有数据！';

  @override
  String get restoringBackup => '正在从备份恢复...';

  @override
  String get restoringBackupMessage => '正在恢复备份...';

  @override
  String get retry => '重试';

  @override
  String get retryAction => '重试';

  @override
  String get rotateLeft => '向左旋转';

  @override
  String get rotateRight => '向右旋转';

  @override
  String get rotation => '旋转';

  @override
  String get safetyBackupBeforePathSwitch => '数据路径切换前的安全备份';

  @override
  String get safetyBackupRecommendation => '为了确保数据安全，建议在切换数据路径前先创建备份：';

  @override
  String get safetyTip => '💡 安全建议：';

  @override
  String get sansSerif => 'Sans Serif';

  @override
  String get save => '保存';

  @override
  String get saveAs => '另存为';

  @override
  String get saveComplete => '保存完成';

  @override
  String get saveFailed => '保存失败，请稍后重试';

  @override
  String saveFailedWithError(Object error) {
    return '保存失败：$error';
  }

  @override
  String get saveFailure => '保存失败';

  @override
  String get savePreview => '字符预览：';

  @override
  String get saveSuccess => '保存成功';

  @override
  String get saveTimeout => '保存超时';

  @override
  String get savingToStorage => '保存到存储中...';

  @override
  String get scale => '缩放';

  @override
  String get scannedBackupFileDescription => '扫描发现的备份文件';

  @override
  String get search => '搜索';

  @override
  String get searchCategories => '搜索分类...';

  @override
  String get searchConfigDialogTitle => '搜索配置项';

  @override
  String get searchConfigHint => '输入配置项名称或键';

  @override
  String get searchConfigItems => '搜索配置项';

  @override
  String get searching => '搜索中...';

  @override
  String get select => '选择';

  @override
  String get selectAll => '全选';

  @override
  String get selectAllWithShortcut => '全选 (Ctrl+Shift+A)';

  @override
  String get selectBackup => '选择备份';

  @override
  String get selectBackupFileToImportDialog => '选择要导入的备份文件';

  @override
  String get selectBackupStorageLocation => '选择备份存储位置';

  @override
  String get selectCategoryToApply => '请选择要应用的分类:';

  @override
  String get selectCharacterFirst => '请先选择字符';

  @override
  String selectColor(Object type) {
    return '选择$type';
  }

  @override
  String get selectDate => '选择日期';

  @override
  String get selectExportLocation => '选择导出位置';

  @override
  String get selectExportLocationDialog => '选择导出位置';

  @override
  String get selectExportLocationHint => '选择导出位置...';

  @override
  String get selectFileError => '选择文件失败';

  @override
  String get selectFolder => '选择文件夹';

  @override
  String get selectImage => '选择图片';

  @override
  String get selectImages => '选择图片';

  @override
  String get selectImagesWithCtrl => '选择图片 (可按住Ctrl多选)';

  @override
  String get selectImportFile => '选择备份文件';

  @override
  String get selectNewDataPath => '选择新的数据存储路径：';

  @override
  String get selectNewDataPathDialog => '选择新的数据存储路径';

  @override
  String get selectNewDataPathTitle => '选择新的数据存储路径';

  @override
  String get selectNewPath => '选择新路径';

  @override
  String get selectParentCategory => '选择父分类';

  @override
  String get selectPath => '选择路径';

  @override
  String get selectPathButton => '选择路径';

  @override
  String get selectPathFailed => '选择路径失败';

  @override
  String get selectSufficientSpaceDisk => '建议选择剩余空间充足的磁盘';

  @override
  String get selectTargetLayer => '选择目标图层';

  @override
  String get selected => '已选择';

  @override
  String get selectedCharacter => '已选字符';

  @override
  String selectedCount(Object count) {
    return '已选择$count个';
  }

  @override
  String get selectedElementNotFound => '选中的元素未找到';

  @override
  String get selectedItems => '选中项目';

  @override
  String get selectedPath => '已选择的路径：';

  @override
  String get selectionMode => '选择模式';

  @override
  String get sendToBack => '置于底层 (Ctrl+B)';

  @override
  String get serif => 'Serif';

  @override
  String get serviceNotReady => '服务未就绪，请稍后再试';

  @override
  String get setBackupPathFailed => '设置备份路径失败';

  @override
  String get setCategory => '设置分类';

  @override
  String setCategoryForItems(Object count) {
    return '设置分类 ($count个项目)';
  }

  @override
  String get setDataPathFailed => '设置数据路径失败，请检查路径权限和兼容性';

  @override
  String setDataPathFailedWithError(Object error) {
    return '设置数据路径失败: $error';
  }

  @override
  String get settings => '设置';

  @override
  String get settingsResetMessage => '设置已重置为默认值';

  @override
  String get shortcuts => '键盘快捷键';

  @override
  String get showContour => '显示轮廓';

  @override
  String get showDetails => '显示详情';

  @override
  String get showElement => '显示元素';

  @override
  String get showGrid => '显示网格 (Ctrl+G)';

  @override
  String get showHideAllElements => '显示/隐藏所有元素';

  @override
  String get showImagePreview => '显示图片预览';

  @override
  String get showThumbnails => '显示页面缩略图';

  @override
  String get skipBackup => '跳过备份';

  @override
  String get skipBackupConfirm => '跳过备份';

  @override
  String get skipBackupWarning => '确定要跳过备份直接进行路径切换吗？\n\n这可能存在数据丢失的风险。';

  @override
  String get skipBackupWarningMessage => '确定要跳过备份直接进行路径切换吗？\n\n这可能存在数据丢失的风险。';

  @override
  String get skipConflicts => '跳过冲突';

  @override
  String get skipConflictsDescription => '跳过已存在的项目';

  @override
  String get skippedCharacters => '跳过的集字';

  @override
  String get skippedItems => '跳过的项目';

  @override
  String get skippedWorks => '跳过的作品';

  @override
  String get sort => '排序';

  @override
  String get sortBy => '排序方式';

  @override
  String get sortByCreateTime => '按创建时间排序';

  @override
  String get sortByTitle => '按标题排序';

  @override
  String get sortByUpdateTime => '按更新时间排序';

  @override
  String get sortFailed => '排序失败';

  @override
  String get sortOrder => '排序';

  @override
  String get sortOrderCannotBeEmpty => '排序顺序不能为空';

  @override
  String get sortOrderHint => '数字越小排序越靠前';

  @override
  String get sortOrderLabel => '排序顺序';

  @override
  String get sortOrderNumber => '排序值必须是数字';

  @override
  String get sortOrderRange => '排序顺序必须在1-999之间';

  @override
  String get sortOrderRequired => '请输入排序值';

  @override
  String get sourceBackupFileNotFound => '源备份文件不存在';

  @override
  String sourceFileNotFound(Object path) {
    return '源文件不存在: $path';
  }

  @override
  String sourceFileNotFoundError(Object path) {
    return '源文件不存在: $path';
  }

  @override
  String get sourceHanSansFont => '思源黑体 (Source Han Sans)';

  @override
  String get sourceHanSerifFont => '思源宋体 (Source Han Serif)';

  @override
  String get sourceInfo => '出处信息';

  @override
  String get startBackup => '开始备份';

  @override
  String get startDate => '开始日期';

  @override
  String get stateAndDisplay => '状态与显示';

  @override
  String get statisticsInProgress => '统计中...';

  @override
  String get status => '状态';

  @override
  String get statusAvailable => '可用';

  @override
  String get statusLabel => '状态';

  @override
  String get statusUnavailable => '不可用';

  @override
  String get storageDetails => '存储详情';

  @override
  String get storageLocation => '存储位置';

  @override
  String get storageSettings => '存储设置';

  @override
  String get storageUsed => '已使用存储';

  @override
  String get stretch => '拉伸';

  @override
  String get strokeCount => '笔画';

  @override
  String submitFailed(Object error) {
    return '提交失败：$error';
  }

  @override
  String successDeletedCount(Object count) {
    return '成功删除 $count 个备份文件';
  }

  @override
  String get suggestConfigureBackupPath => '建议：先在设置中配置备份路径';

  @override
  String get suggestConfigureBackupPathFirst => '建议：先在设置中配置备份路径';

  @override
  String get suggestRestartOrWait => '建议：重启应用或等待服务初始化完成后重试';

  @override
  String get suggestRestartOrWaitService => '建议：重启应用或等待服务初始化完成后重试';

  @override
  String get suggestedSolutions => '建议解决方案：';

  @override
  String get suggestedTags => '建议标签';

  @override
  String get switchSuccessful => '切换成功';

  @override
  String get switchingPage => '正在切换到字符页面...';

  @override
  String get systemConfig => '系统配置';

  @override
  String get systemConfigItemNote => '这是系统配置项，键值不可修改';

  @override
  String get systemInfo => '系统信息';

  @override
  String get tabToNextField => '按Tab导航到下一个字段';

  @override
  String tagAddError(Object error) {
    return '添加标签失败: $error';
  }

  @override
  String get tagHint => '输入标签名称';

  @override
  String tagRemoveError(Object error) {
    return '移除标签失败, 错误: $error';
  }

  @override
  String get tags => '标签';

  @override
  String get tagsAddHint => '输入标签名称并按回车';

  @override
  String get tagsHint => '输入标签...';

  @override
  String get tagsSelected => '已选标签：';

  @override
  String get targetLocationExists => '目标位置已存在同名文件：';

  @override
  String get targetPathLabel => '请选择操作：';

  @override
  String get text => '文本';

  @override
  String get textAlign => '文本对齐';

  @override
  String get textContent => '文本内容';

  @override
  String get textElement => '文本元素';

  @override
  String get textProperties => '文本属性';

  @override
  String get textSettings => '文本设置';

  @override
  String get textureFillMode => '纹理填充模式';

  @override
  String get textureFillModeContain => '包含';

  @override
  String get textureFillModeCover => '覆盖';

  @override
  String get textureFillModeRepeat => '重复';

  @override
  String get textureOpacity => '纹理不透明度';

  @override
  String get themeMode => '主题模式';

  @override
  String get themeModeDark => '暗色';

  @override
  String get themeModeDescription => '使用深色主题获得更好的夜间观看体验';

  @override
  String get themeModeSystemDescription => '根据系统设置自动切换深色/亮色主题';

  @override
  String get thisMonth => '本月';

  @override
  String get thisWeek => '本周';

  @override
  String get thisYear => '今年';

  @override
  String get threshold => '阈值';

  @override
  String get thumbnailCheckFailed => '缩略图检查失败';

  @override
  String get thumbnailEmpty => '缩略图文件为空';

  @override
  String get thumbnailLoadError => '加载缩略图失败';

  @override
  String get thumbnailNotFound => '未找到缩略图';

  @override
  String get timeInfo => '时间信息';

  @override
  String get timeLabel => '时间';

  @override
  String get title => '标题';

  @override
  String get titleAlreadyExists => '已存在相同标题的字帖，请使用其他标题';

  @override
  String get titleCannotBeEmpty => '标题不能为空';

  @override
  String get titleExists => '标题已存在';

  @override
  String get titleExistsMessage => '已存在同名字帖。是否覆盖？';

  @override
  String titleUpdated(Object title) {
    return '标题已更新为\"$title\"';
  }

  @override
  String get to => '至';

  @override
  String get today => '今天';

  @override
  String get toggleBackground => '切换背景';

  @override
  String get toolModePanTooltip => '拖拽工具 (Ctrl+V)';

  @override
  String get toolModeSelectTooltip => '框选工具 (Ctrl+B)';

  @override
  String get total => '总计';

  @override
  String get totalBackups => '总备份数';

  @override
  String totalItems(Object count) {
    return '共 $count 个';
  }

  @override
  String get totalSize => '总大小';

  @override
  String get transformApplied => '变换已应用';

  @override
  String get tryOtherKeywords => '尝试使用其他关键词搜索';

  @override
  String get type => '类型';

  @override
  String get underline => '下划线';

  @override
  String get undo => '撤销';

  @override
  String get ungroup => '取消组合 (Ctrl+U)';

  @override
  String get ungroupConfirm => '确认解组';

  @override
  String get ungroupDescription => '确定要解散此组吗？';

  @override
  String get unknown => '未知';

  @override
  String get unknownCategory => '未知分类';

  @override
  String unknownElementType(Object type) {
    return '未知元素类型: $type';
  }

  @override
  String get unknownError => '未知错误';

  @override
  String get unlockElement => '解锁元素';

  @override
  String get unlocked => '未锁定';

  @override
  String get unnamedElement => '未命名元素';

  @override
  String get unnamedGroup => '未命名组';

  @override
  String get unnamedLayer => '未命名图层';

  @override
  String get unsavedChanges => '有未保存的更改';

  @override
  String get updateTime => '更新时间';

  @override
  String get updatedAt => '更新时间';

  @override
  String get usageInstructions => '使用说明';

  @override
  String get useDefaultPath => '使用默认路径';

  @override
  String get userConfig => '用户配置';

  @override
  String get validCharacter => '请输入有效的字符';

  @override
  String get validPath => '有效路径';

  @override
  String get validateData => '验证数据';

  @override
  String get validateDataDescription => '导入前验证数据完整性';

  @override
  String get validateDataMandatory => '强制验证导入文件的完整性和格式，确保数据安全';

  @override
  String get validatingImportFile => '正在验证导入文件...';

  @override
  String valueTooLarge(Object label, Object max) {
    return '$label不能大于$max';
  }

  @override
  String valueTooSmall(Object label, Object min) {
    return '$label不能小于$min';
  }

  @override
  String get versionDetails => '版本详情';

  @override
  String get versionInfoCopied => '版本信息已复制到剪贴板';

  @override
  String get verticalAlignment => '垂直对齐';

  @override
  String get verticalLeftToRight => '竖排左起';

  @override
  String get verticalRightToLeft => '竖排右起';

  @override
  String get viewAction => '查看';

  @override
  String get viewDetails => '查看详情';

  @override
  String get viewExportResultsButton => '查看';

  @override
  String get visibility => '可见性';

  @override
  String get visible => '可见';

  @override
  String get visualProperties => '视觉属性';

  @override
  String get visualSettings => '视觉设置';

  @override
  String get warningOverwriteData => '警告：这将覆盖当前所有数据！';

  @override
  String get warnings => '警告';

  @override
  String get widgetRefRequired => '需要WidgetRef才能创建CollectionPainter';

  @override
  String get width => '宽度';

  @override
  String get windowButtonMaximize => '最大化';

  @override
  String get windowButtonMinimize => '最小化';

  @override
  String get windowButtonRestore => '还原';

  @override
  String get work => '作品';

  @override
  String get workBrowseSearch => '搜索作品...';

  @override
  String get workBrowseTitle => '作品';

  @override
  String get workCount => '作品数量';

  @override
  String get workDetailCharacters => '字符';

  @override
  String get workDetailOtherInfo => '其他信息';

  @override
  String get workDetailTitle => '作品详情';

  @override
  String get workFormAuthorHelp => '可选，作品的创作者';

  @override
  String get workFormAuthorHint => '输入作者名称';

  @override
  String get workFormAuthorMaxLength => '作者名称不能超过50个字符';

  @override
  String get workFormAuthorTooltip => '按Ctrl+A快速跳转到作者字段';

  @override
  String get workFormCreationDateError => '创作日期不能超过当前日期';

  @override
  String get workFormDateHelp => '作品的完成日期';

  @override
  String get workFormRemarkHelp => '可选，关于作品的附加信息';

  @override
  String get workFormRemarkMaxLength => '备注不能超过500个字符';

  @override
  String get workFormRemarkTooltip => '按Ctrl+R快速跳转到备注字段';

  @override
  String get workFormStyleHelp => '作品的主要风格类型';

  @override
  String get workFormTitleHelp => '作品的主标题，显示在作品列表中';

  @override
  String get workFormTitleMaxLength => '标题不能超过100个字符';

  @override
  String get workFormTitleMinLength => '标题必须至少2个字符';

  @override
  String get workFormTitleRequired => '标题为必填项';

  @override
  String get workFormTitleTooltip => '按Ctrl+T快速跳转到标题字段';

  @override
  String get workFormToolHelp => '创作此作品使用的主要工具';

  @override
  String get workIdCannotBeEmpty => '作品ID不能为空';

  @override
  String get workInfo => '作品信息';

  @override
  String get workStyleClerical => '隶书';

  @override
  String get workStyleCursive => '草书';

  @override
  String get workStyleRegular => '楷书';

  @override
  String get workStyleRunning => '行书';

  @override
  String get workStyleSeal => '篆书';

  @override
  String get workToolBrush => '毛笔';

  @override
  String get workToolHardPen => '硬笔';

  @override
  String get workToolOther => '其他';

  @override
  String get works => '作品';

  @override
  String worksCount(Object count) {
    return '$count 个作品';
  }

  @override
  String get writingMode => '书写模式';

  @override
  String get writingTool => '书写工具';

  @override
  String get writingToolManagement => '书写工具管理';

  @override
  String get writingToolText => '书写工具';

  @override
  String get yes => '是';

  @override
  String get yesterday => '昨天';

  @override
  String get zipFile => 'ZIP 压缩包';

  @override
  String get backgroundTexture => '背景纹理';

  @override
  String get texturePreview => '纹理预览';

  @override
  String get textureSize => '纹理尺寸';

  @override
  String get restoreDefaultSize => '恢复默认尺寸';

  @override
  String get alignment => '对齐方式';

  @override
  String get imageAlignment => '图像对齐';

  @override
  String get imageSizeInfo => '图像尺寸';

  @override
  String get imageNameInfo => '图像名称';

  @override
  String get rotationFineControl => '角度微调';

  @override
  String get rotateClockwise => '顺时针旋转';

  @override
  String get rotateCounterclockwise => '逆时针旋转';

  @override
  String get degrees => '度';

  @override
  String get fineRotation => '精细旋转';

  @override
  String get topLeft => '左上角';

  @override
  String get topCenter => '顶部居中';

  @override
  String get topRight => '右上角';

  @override
  String get centerLeft => '左侧居中';

  @override
  String get centerRight => '右侧居中';

  @override
  String get bottomLeft => '左下角';

  @override
  String get bottomCenter => '底部居中';

  @override
  String get bottomRight => '右下角';

  @override
  String get alignmentCenter => '中心';

  @override
  String get cropAdjustmentHint => '在上方预览图中拖动选框和控制点来调整裁剪区域';

  @override
  String get binarizationProcessing => '二值化处理';

  @override
  String get binarizationToggle => '二值化开关';

  @override
  String get binarizationParameters => '二值化参数';

  @override
  String get enableBinarization => '启用二值化';

  @override
  String get binaryThreshold => '二值化阈值';

  @override
  String get noiseReductionToggle => '降噪开关';

  @override
  String get noiseReductionLevel => '降噪强度';
}

/// The translations for Chinese, as used in Taiwan (`zh_TW`).
class AppLocalizationsZhTw extends AppLocalizationsZh {
  AppLocalizationsZhTw(): super('zh_TW');

  @override
  String get a4Size => 'A4 (210×297mm)';

  @override
  String get a5Size => 'A5 (148×210mm)';

  @override
  String get about => '關於';

  @override
  String get activated => '啟用';

  @override
  String get activatedDescription => '啟用 - 在選擇器中顯示';

  @override
  String get activeStatus => '啟用狀態';

  @override
  String get add => '新增';

  @override
  String get addCategory => '新增分類';

  @override
  String addCategoryItem(Object category) {
    return '新增$category';
  }

  @override
  String get addConfigItem => '新增設定項';

  @override
  String addConfigItemHint(Object category) {
    return '點擊右下角的按鈕新增$category設定項';
  }

  @override
  String get addFavorite => '新增至我的最愛';

  @override
  String addFromGalleryFailed(Object error) {
    return '從圖庫新增圖片失敗：$error';
  }

  @override
  String get addImage => '新增圖片';

  @override
  String get addImageHint => '點擊以新增圖片';

  @override
  String get addImages => '新增圖片';

  @override
  String get addLayer => '新增圖層';

  @override
  String get addTag => '新增標籤';

  @override
  String get addWork => '新增作品';

  @override
  String get addedToCategory => '已新增至分類';

  @override
  String addingImagesToGallery(Object count) {
    return '正在將 $count 張本機圖片新增至圖庫...';
  }

  @override
  String get adjust => '調整';

  @override
  String get adjustGridSize => '調整網格大小';

  @override
  String get afterDate => '在某個日期之後';

  @override
  String get alignBottom => '靠下對齊';

  @override
  String get alignCenter => '置中';

  @override
  String get alignHorizontalCenter => '水平置中';

  @override
  String get alignLeft => '靠左對齊';

  @override
  String get alignMiddle => '置中';

  @override
  String get alignRight => '靠右對齊';

  @override
  String get alignTop => '靠上對齊';

  @override
  String get alignVerticalCenter => '垂直置中';

  @override
  String get alignmentAssist => '對齊輔助';

  @override
  String get alignmentGrid => '網格貼齊模式 - 點擊切換至參考線對齊';

  @override
  String get alignmentGuideline => '參考線對齊模式 - 點擊切換至無輔助';

  @override
  String get alignmentNone => '無輔助對齊 - 點擊啟用網格貼齊';

  @override
  String get alignmentOperations => '對齊操作';

  @override
  String get all => '全部';

  @override
  String get allBackupsDeleteWarning => '此操作無法復原！所有備份資料將永久遺失。';

  @override
  String get allCategories => '所有分類';

  @override
  String get allPages => '全部頁面';

  @override
  String get allTime => '所有時間';

  @override
  String get allTypes => '所有類型';

  @override
  String get analyzePathInfoFailed => '分析路徑資訊失敗';

  @override
  String get appRestartFailed => '應用程式重啟失敗，請手動重啟應用程式';

  @override
  String get appRestarting => '正在重新啟動應用程式';

  @override
  String get appRestartingMessage => '資料恢復成功，正在重新啟動應用程式...';

  @override
  String get appStartupFailed => '應用程式啟動失敗';

  @override
  String appStartupFailedWith(Object error) {
    return '應用程式啟動失敗：$error';
  }

  @override
  String get appTitle => '字字珠璣';

  @override
  String get appVersion => '應用程式版本';

  @override
  String get appVersionInfo => '應用程式版本資訊';

  @override
  String get appWillRestartAfterRestore => '還原後應用程式將自動重新啟動。';

  @override
  String appWillRestartInSeconds(Object message) {
    return '$message\n應用程式將在 3 秒後自動重新啟動...';
  }

  @override
  String get appWillRestartMessage => '還原完成後應用程式將自動重新啟動';

  @override
  String get apply => '套用';

  @override
  String get applyFormatBrush => '套用格式刷 (Alt+W)';

  @override
  String get applyNewPath => '套用新路徑';

  @override
  String get applyTransform => '套用變形';

  @override
  String get ascending => '升序';

  @override
  String get askUser => '詢問使用者';

  @override
  String get askUserDescription => '為每個衝突詢問使用者';

  @override
  String get author => '作者';

  @override
  String get autoBackup => '自動備份';

  @override
  String get autoBackupDescription => '定期自動備份您的資料';

  @override
  String get autoBackupInterval => '自動備份間隔';

  @override
  String get autoBackupIntervalDescription => '自動備份的頻率';

  @override
  String get autoCleanup => '自動清理';

  @override
  String get autoCleanupDescription => '自動清理舊的快取檔案';

  @override
  String get autoCleanupInterval => '自動清理間隔';

  @override
  String get autoCleanupIntervalDescription => '自動清理的執行頻率';

  @override
  String get autoDetect => '自動偵測';

  @override
  String get autoDetectPageOrientation => '自動偵測頁面方向';

  @override
  String get autoLineBreak => '自動換行';

  @override
  String get autoLineBreakDisabled => '已停用自動換行';

  @override
  String get autoLineBreakEnabled => '已啟用自動換行';

  @override
  String get availableCharacters => '可用字元';

  @override
  String get back => '返回';

  @override
  String get backgroundColor => '背景顏色';

  @override
  String get backupBeforeSwitchRecommendation => '為確保資料安全，建議在切換資料路徑前先建立備份：';

  @override
  String backupChecksum(Object checksum) {
    return '校驗和：$checksum...';
  }

  @override
  String get backupCompleted => '✓ 備份已完成';

  @override
  String backupCount(Object count) {
    return '$count 個備份';
  }

  @override
  String backupCountFormat(Object count) {
    return '$count 個備份';
  }

  @override
  String get backupCreatedSuccessfully => '備份建立成功，可以安全地進行路徑切換';

  @override
  String get backupCreationFailed => '備份建立失敗';

  @override
  String backupCreationTime(Object time) {
    return '建立時間：$time';
  }

  @override
  String get backupDeletedSuccessfully => '備份已成功刪除';

  @override
  String get backupDescription => '描述（可選）';

  @override
  String get backupDescriptionHint => '輸入此備份的描述';

  @override
  String get backupDescriptionInputExample => '例如：每週備份、重要更新前備份等';

  @override
  String get backupDescriptionInputLabel => '備份描述';

  @override
  String backupDescriptionLabel(Object description) {
    return '備份描述：$description';
  }

  @override
  String get backupEnsuresDataSafety => '• 備份可以確保資料安全';

  @override
  String backupExportedSuccessfully(Object filename) {
    return '備份匯出成功：$filename';
  }

  @override
  String get backupFailure => '建立備份失敗';

  @override
  String get backupFile => '備份檔案';

  @override
  String get backupFileChecksumMismatchError => '備份檔案校驗和不符';

  @override
  String get backupFileCreationFailed => '備份檔案建立失敗';

  @override
  String get backupFileCreationFailedError => '備份檔案建立失敗';

  @override
  String backupFileLabel(Object filename) {
    return '備份檔案：$filename';
  }

  @override
  String backupFileListTitle(Object count) {
    return '備份檔案清單（$count 個）';
  }

  @override
  String get backupFileMissingDirectoryStructureError => '備份檔案缺少必要的目錄結構';

  @override
  String backupFileNotExist(Object path) {
    return '備份檔案不存在：$path';
  }

  @override
  String get backupFileNotExistError => '備份檔案不存在';

  @override
  String get backupFileNotFound => '找不到備份檔案';

  @override
  String get backupFileSizeMismatchError => '備份檔案大小不符';

  @override
  String get backupFileVerificationFailedError => '備份檔案驗證失敗';

  @override
  String get backupFirst => '先備份';

  @override
  String get backupImportSuccessMessage => '備份匯入成功';

  @override
  String get backupImportedSuccessfully => '備份匯入成功';

  @override
  String get backupImportedToCurrentPath => '備份已匯入至目前路徑';

  @override
  String get backupLabel => '備份';

  @override
  String get backupList => '備份清單';

  @override
  String get backupLocationTips => '• 建議選擇剩餘空間充足的磁碟作為備份位置\n• 備份位置可以是外部儲存裝置（如行動硬碟）\n• 更換備份位置後，所有備份資訊將統一管理\n• 歷史備份檔案不會自動移動，但可以在備份管理中查看';

  @override
  String get backupManagement => '備份管理';

  @override
  String get backupManagementSubtitle => '建立、還原、匯入、匯出和管理所有備份檔案';

  @override
  String get backupMayTakeMinutes => '備份可能需要幾分鐘時間，請保持應用程式執行';

  @override
  String get backupNotAvailable => '備份管理暫時無法使用';

  @override
  String get backupNotAvailableMessage => '備份管理功能需要資料庫支援。\n\n可能原因：\n• 資料庫正在初始化中\n• 資料庫初始化失敗\n• 應用程式正在啟動中\n\n請稍後再試，或重新啟動應用程式。';

  @override
  String backupNotFound(Object id) {
    return '找不到備份：$id';
  }

  @override
  String backupNotFoundError(Object id) {
    return '找不到備份：$id';
  }

  @override
  String get backupOperationTimeoutError => '備份操作逾時，請檢查儲存空間並重試';

  @override
  String get backupOverview => '備份概覽';

  @override
  String get backupPathDeleted => '備份路徑已刪除';

  @override
  String get backupPathDeletedMessage => '備份路徑已刪除';

  @override
  String get backupPathNotSet => '請先設定備份路徑';

  @override
  String get backupPathNotSetError => '請先設定備份路徑';

  @override
  String get backupPathNotSetUp => '尚未設定備份路徑';

  @override
  String get backupPathSetSuccessfully => '備份路徑設定成功';

  @override
  String get backupPathSettings => '備份路徑設定';

  @override
  String get backupPathSettingsSubtitle => '設定和管理備份儲存路徑';

  @override
  String backupPreCheckFailed(Object error) {
    return '備份前檢查失敗：$error';
  }

  @override
  String get backupReadyRestartMessage => '備份檔案已準備就緒，需要重新啟動應用程式以完成還原';

  @override
  String get backupRecommendation => '建議在匯入前建立備份';

  @override
  String get backupRecommendationDescription => '為確保資料安全，建議在匯入前手動建立備份';

  @override
  String get backupRestartWarning => '重新啟動應用程式以套用變更';

  @override
  String backupRestoreFailedMessage(Object error) {
    return '備份還原失敗：$error';
  }

  @override
  String get backupRestoreSuccessMessage => '備份還原成功，請重新啟動應用程式以完成還原';

  @override
  String get backupRestoreSuccessWithRestartMessage => '備份還原成功，需要重新啟動應用程式以套用變更。';

  @override
  String get backupRestoredSuccessfully => '備份還原成功，請重新啟動應用程式以完成還原';

  @override
  String get backupServiceInitializing => '備份服務正在初始化中，請稍後再試';

  @override
  String get backupServiceNotAvailable => '備份服務暫時無法使用';

  @override
  String get backupServiceNotInitialized => '備份服務未初始化';

  @override
  String get backupServiceNotReady => '備份服務暫時無法使用';

  @override
  String get backupSettings => '備份與還原';

  @override
  String backupSize(Object size) {
    return '大小：$size';
  }

  @override
  String get backupStatistics => '備份統計';

  @override
  String get backupStorageLocation => '備份儲存位置';

  @override
  String get backupSuccess => '備份建立成功';

  @override
  String get backupSuccessCanSwitchPath => '備份建立成功，可以安全地進行路徑切換';

  @override
  String backupTimeLabel(Object time) {
    return '備份時間：$time';
  }

  @override
  String get backupTimeoutDetailedError => '備份操作逾時。可能原因：\n• 資料量過大\n• 儲存空間不足\n• 磁碟讀寫速度慢\n\n請檢查儲存空間並重試。';

  @override
  String get backupTimeoutError => '備份建立逾時或失敗，請檢查儲存空間是否足夠';

  @override
  String get backupVerificationFailed => '備份檔案驗證失敗';

  @override
  String get backups => '備份';

  @override
  String get backupsCount => '個備份';

  @override
  String get basicInfo => '基本資訊';

  @override
  String get basicProperties => '基本屬性';

  @override
  String batchDeleteMessage(Object count) {
    return '即將刪除 $count 個項目，此操作無法復原。';
  }

  @override
  String get batchExportFailed => '批次匯出失敗';

  @override
  String batchExportFailedMessage(Object error) {
    return '批次匯出失敗：$error';
  }

  @override
  String get batchImport => '批次匯入';

  @override
  String get batchMode => '批次模式';

  @override
  String get batchOperations => '批次操作';

  @override
  String get beforeDate => '在某個日期之前';

  @override
  String get border => '邊框';

  @override
  String get borderColor => '邊框顏色';

  @override
  String get borderWidth => '邊框寬度';

  @override
  String get boxRegion => '請在預覽區域框選字元';

  @override
  String get boxTool => '框選工具';

  @override
  String get bringLayerToFront => '圖層置於頂層';

  @override
  String get bringToFront => '置於頂層 (Ctrl+T)';

  @override
  String get browse => '瀏覽';

  @override
  String get browsePath => '瀏覽路徑';

  @override
  String get brushSize => '筆刷尺寸';

  @override
  String get buildEnvironment => '建置環境';

  @override
  String get buildNumber => '建置編號';

  @override
  String get buildTime => '建置時間';

  @override
  String get cacheClearedMessage => '快取已成功清除';

  @override
  String get cacheSettings => '快取設定';

  @override
  String get cacheSize => '快取大小';

  @override
  String get calligraphyStyle => '書法風格';

  @override
  String get calligraphyStyleText => '書法風格';

  @override
  String get canChooseDirectSwitch => '• 您也可以選擇直接切換';

  @override
  String get canCleanOldDataLater => '您可以稍後透過「資料路徑管理」清理舊資料';

  @override
  String get canCleanupLaterViaManagement => '您可以稍後透過資料路徑管理清理舊資料';

  @override
  String get canManuallyCleanLater => '• 您可以稍後手動清理舊路徑的資料';

  @override
  String get canNotPreview => '無法產生預覽';

  @override
  String get cancel => '取消';

  @override
  String get cancelAction => '取消';

  @override
  String get cannotApplyNoImage => '沒有可用的圖片';

  @override
  String get cannotApplyNoSizeInfo => '無法取得圖片尺寸資訊';

  @override
  String get cannotCapturePageImage => '無法擷取頁面影像';

  @override
  String get cannotDeleteOnlyPage => '無法刪除唯一的頁面';

  @override
  String get cannotGetStorageInfo => '無法取得儲存資訊';

  @override
  String get cannotReadPathContent => '無法讀取路徑內容';

  @override
  String get cannotReadPathFileInfo => '無法讀取路徑檔案資訊';

  @override
  String get cannotSaveMissingController => '無法儲存：缺少控制器';

  @override
  String get cannotSaveNoPages => '沒有頁面，無法儲存';

  @override
  String get canvasPixelSize => '畫布像素大小';

  @override
  String get canvasResetViewTooltip => '重設檢視位置';

  @override
  String get categories => '分類';

  @override
  String get categoryManagement => '分類管理';

  @override
  String get categoryName => '分類名稱';

  @override
  String get categoryNameCannotBeEmpty => '分類名稱不能為空';

  @override
  String get centimeter => '公分';

  @override
  String get changeDataPathMessage => '變更資料路徑後，應用程式需要重新啟動才能生效。';

  @override
  String get changePath => '更換路徑';

  @override
  String get character => '集字';

  @override
  String get characterCollection => '集字';

  @override
  String characterCollectionFindSwitchFailed(Object error) {
    return '尋找並切換頁面失敗：$error';
  }

  @override
  String get characterCollectionPreviewTab => '字元預覽';

  @override
  String get characterCollectionResultsTab => '擷取結果';

  @override
  String get characterCollectionSearchHint => '搜尋字元...';

  @override
  String get characterCollectionTitle => '字元擷取';

  @override
  String get characterCollectionToolBox => '框選工具 (Ctrl+B)';

  @override
  String get characterCollectionToolPan => '平移工具 (Ctrl+V)';

  @override
  String get characterCollectionUseBoxTool => '使用框選工具從影像中擷取字元';

  @override
  String get characterCount => '集字數量';

  @override
  String get characterDetailFormatBinary => '二值化';

  @override
  String get characterDetailFormatBinaryDesc => '黑白二值化影像';

  @override
  String get characterDetailFormatDescription => '描述';

  @override
  String get characterDetailFormatOutline => '輪廓';

  @override
  String get characterDetailFormatOutlineDesc => '僅顯示輪廓';

  @override
  String get characterDetailFormatSquareBinary => '方形二值化';

  @override
  String get characterDetailFormatSquareBinaryDesc => '規整為正方形的二值化影像';

  @override
  String get characterDetailFormatSquareOutline => '方形輪廓';

  @override
  String get characterDetailFormatSquareOutlineDesc => '規整為正方形的輪廓影像';

  @override
  String get characterDetailFormatSquareTransparent => '方形透明';

  @override
  String get characterDetailFormatSquareTransparentDesc => '規整為正方形的透明 PNG 影像';

  @override
  String get characterDetailFormatThumbnail => '縮圖';

  @override
  String get characterDetailFormatThumbnailDesc => '縮圖';

  @override
  String get characterDetailFormatTransparent => '透明';

  @override
  String get characterDetailFormatTransparentDesc => '去背景的透明 PNG 影像';

  @override
  String get characterDetailLoadError => '載入字元詳情失敗';

  @override
  String get characterDetailSimplifiedChar => '簡體字元';

  @override
  String get characterDetailTitle => '字元詳情';

  @override
  String characterEditSaveConfirmMessage(Object character) {
    return '確認儲存「$character」？';
  }

  @override
  String get characterUpdated => '字元已更新';

  @override
  String get characters => '集字';

  @override
  String charactersCount(Object count) {
    return '$count 個集字';
  }

  @override
  String charactersSelected(Object count) {
    return '已選擇 $count 個字元';
  }

  @override
  String get checkBackupRecommendationFailed => '檢查備份建議失敗';

  @override
  String get checkFailedRecommendBackup => '檢查失敗，建議先建立備份以確保資料安全';

  @override
  String get checkSpecialChars => '• 檢查作品標題是否包含特殊字元';

  @override
  String get cleanDuplicateRecords => '清理重複記錄';

  @override
  String get cleanDuplicateRecordsDescription => '此操作將清理重複的備份記錄，不會刪除實際的備份檔案。';

  @override
  String get cleanDuplicateRecordsTitle => '清理重複記錄';

  @override
  String cleanupCompleted(Object count) {
    return '清理完成，移除了 $count 個無效路徑';
  }

  @override
  String cleanupCompletedMessage(Object count) {
    return '清理完成，移除了 $count 個無效路徑';
  }

  @override
  String cleanupCompletedWithCount(Object count) {
    return '清理完成，移除了 $count 個重複記錄';
  }

  @override
  String get cleanupFailed => '清理失敗';

  @override
  String cleanupFailedMessage(Object error) {
    return '清理失敗：$error';
  }

  @override
  String get cleanupInvalidPaths => '清理無效路徑';

  @override
  String cleanupOperationFailed(Object error) {
    return '清理操作失敗：$error';
  }

  @override
  String get clearCache => '清除快取';

  @override
  String get clearCacheConfirmMessage => '確定要清除所有快取資料嗎？這將釋放磁碟空間，但可能會暫時降低應用程式的速度。';

  @override
  String get clearSelection => '取消選擇';

  @override
  String get close => '關閉';

  @override
  String get code => '程式碼';

  @override
  String get collapse => '收合';

  @override
  String get collapseFileList => '點擊以收合檔案清單';

  @override
  String get collectionDate => '擷取日期';

  @override
  String get collectionElement => '集字元素';

  @override
  String get collectionIdCannotBeEmpty => '集字 ID 不能為空';

  @override
  String get collectionTime => '擷取時間';

  @override
  String get color => '顏色';

  @override
  String get colorCode => '顏色代碼';

  @override
  String get colorCodeHelp => '輸入 6 位十六進位顏色代碼（例如：FF5500）';

  @override
  String get colorCodeInvalid => '無效的顏色代碼';

  @override
  String get colorInversion => '顏色反轉';

  @override
  String get colorPicker => '選擇顏色';

  @override
  String get colorSettings => '顏色設定';

  @override
  String get commonProperties => '通用屬性';

  @override
  String get commonTags => '常用標籤：';

  @override
  String get completingSave => '完成儲存...';

  @override
  String get compressData => '壓縮資料';

  @override
  String get compressDataDescription => '縮小匯出檔案大小';

  @override
  String get configInitFailed => '設定資料初始化失敗';

  @override
  String get configInitializationFailed => '設定初始化失敗';

  @override
  String get configInitializing => '正在初始化設定...';

  @override
  String get configKey => '設定金鑰';

  @override
  String get configManagement => '設定管理';

  @override
  String get configManagementDescription => '管理書法風格和書寫工具設定';

  @override
  String get configManagementTitle => '書法風格管理';

  @override
  String get confirm => '確定';

  @override
  String get confirmChangeDataPath => '確認變更資料路徑';

  @override
  String get confirmContinue => '確定要繼續嗎？';

  @override
  String get confirmDataNormalBeforeClean => '• 建議在清理舊路徑前確認資料是否正常';

  @override
  String get confirmDataPathSwitch => '確認資料路徑切換';

  @override
  String get confirmDelete => '確認刪除';

  @override
  String get confirmDeleteAction => '確認刪除';

  @override
  String get confirmDeleteAll => '確認全部刪除';

  @override
  String get confirmDeleteAllBackups => '確認刪除所有備份';

  @override
  String get confirmDeleteAllButton => '確認全部刪除';

  @override
  String confirmDeleteBackup(Object description, Object filename) {
    return '確定要刪除備份檔案「$filename」（$description）嗎？\n此操作無法復原。';
  }

  @override
  String confirmDeleteBackupPath(Object path) {
    return '確定要刪除整個備份路徑嗎？\n\n路徑：$path\n\n這將會：\n• 刪除該路徑下的所有備份檔案\n• 從歷史記錄中移除該路徑\n• 此操作無法復原\n\n請謹慎操作！';
  }

  @override
  String get confirmDeleteButton => '確認刪除';

  @override
  String get confirmDeleteHistoryPath => '確定要刪除此歷史路徑記錄嗎？';

  @override
  String get confirmDeleteTitle => '確認刪除';

  @override
  String get confirmExitWizard => '確定要退出資料路徑切換精靈嗎？';

  @override
  String get confirmImportAction => '確定匯入';

  @override
  String get confirmImportButton => '確認匯入';

  @override
  String get confirmOverwrite => '確認覆寫';

  @override
  String confirmRemoveFromCategory(Object count) {
    return '確定要將選取的 $count 個項目從目前分類中移除嗎？';
  }

  @override
  String get confirmResetToDefaultPath => '確認重設為預設路徑';

  @override
  String get confirmRestoreAction => '確定還原';

  @override
  String get confirmRestoreBackup => '確定要還原此備份嗎？';

  @override
  String get confirmRestoreButton => '確認還原';

  @override
  String get confirmRestoreMessage => '您即將還原以下備份：';

  @override
  String get confirmRestoreTitle => '確認還原';

  @override
  String get confirmShortcuts => '快捷鍵：Enter 確認，Esc 取消';

  @override
  String get confirmSkip => '確定略過';

  @override
  String get confirmSkipAction => '確定略過';

  @override
  String get confirmSwitch => '確認切換';

  @override
  String get confirmSwitchButton => '確認切換';

  @override
  String get confirmSwitchToNewPath => '確認切換至新的資料路徑';

  @override
  String get conflictDetailsTitle => '衝突處理明細';

  @override
  String get conflictReason => '衝突原因';

  @override
  String get conflictResolution => '衝突解決';

  @override
  String conflictsCount(Object count) {
    return '發現 $count 個衝突';
  }

  @override
  String get conflictsFound => '發現衝突';

  @override
  String get contentProperties => '內容屬性';

  @override
  String get contentSettings => '內容設定';

  @override
  String get continueDuplicateImport => '是否仍要繼續匯入此備份？';

  @override
  String get continueImport => '繼續匯入';

  @override
  String get continueQuestion => '是否繼續？';

  @override
  String get copy => '複製 (Ctrl+Shift+C)';

  @override
  String copyFailed(Object error) {
    return '複製失敗：$error';
  }

  @override
  String get copyFormat => '複製格式 (Alt+Q)';

  @override
  String get copySelected => '複製選取項目';

  @override
  String get copyVersionInfo => '複製版本資訊';

  @override
  String get couldNotGetFilePath => '無法取得檔案路徑';

  @override
  String get countUnit => '個';

  @override
  String get create => '建立';

  @override
  String get createBackup => '建立備份';

  @override
  String get createBackupBeforeImport => '匯入前建立備份';

  @override
  String get createBackupDescription => '建立新的資料備份';

  @override
  String get createBackupFailed => '建立備份失敗';

  @override
  String createBackupFailedMessage(Object error) {
    return '建立備份失敗：$error';
  }

  @override
  String createExportDirectoryFailed(Object error) {
    return '建立匯出目錄失敗$error';
  }

  @override
  String get createFirstBackup => '建立第一個備份';

  @override
  String get createTime => '建立時間';

  @override
  String get createdAt => '建立時間';

  @override
  String get creatingBackup => '正在建立備份...';

  @override
  String get creatingBackupPleaseWaitMessage => '這可能需要幾分鐘時間，請耐心等候';

  @override
  String get creatingBackupProgressMessage => '正在建立備份...';

  @override
  String get creationDate => '創作日期';

  @override
  String get criticalError => '嚴重錯誤';

  @override
  String get cropBottom => '底部裁剪';

  @override
  String get cropLeft => '左側裁剪';

  @override
  String get cropRight => '右側裁剪';

  @override
  String get cropTop => '頂部裁剪';

  @override
  String get cropping => '裁剪';

  @override
  String croppingApplied(Object bottom, Object left, Object right, Object top) {
    return '（裁剪：左 ${left}px，上 ${top}px，右 ${right}px，下 ${bottom}px）';
  }

  @override
  String get currentBackupPathNotSet => '目前備份路徑未設定';

  @override
  String get currentCharInversion => '目前字元反轉';

  @override
  String get currentCustomPath => '目前使用自訂資料路徑';

  @override
  String get currentDataPath => '目前資料路徑';

  @override
  String get currentDefaultPath => '目前使用預設資料路徑';

  @override
  String get currentLabel => '目前';

  @override
  String get currentLocation => '目前位置';

  @override
  String get currentPage => '目前頁面';

  @override
  String get currentPath => '目前路徑';

  @override
  String get currentPathBackup => '目前路徑備份';

  @override
  String get currentPathBackupDescription => '目前路徑備份';

  @override
  String get currentPathFileExists => '目前路徑下已存在同名備份檔案：';

  @override
  String get currentPathFileExistsMessage => '目前路徑下已存在同名備份檔案：';

  @override
  String get currentStorageInfo => '目前儲存資訊';

  @override
  String get currentStorageInfoSubtitle => '檢視目前儲存空間使用情況';

  @override
  String get currentStorageInfoTitle => '目前儲存資訊';

  @override
  String get currentTool => '目前工具';

  @override
  String get custom => '自訂';

  @override
  String get customPath => '自訂路徑';

  @override
  String get customRange => '自訂範圍';

  @override
  String get customSize => '自訂大小';

  @override
  String get cutSelected => '剪下選取項目';

  @override
  String get dangerZone => '危險區域';

  @override
  String get dangerousOperationConfirm => '危險操作確認';

  @override
  String get dangerousOperationConfirmTitle => '危險操作確認';

  @override
  String get dartVersion => 'Dart 版本';

  @override
  String get dataBackup => '資料備份';

  @override
  String get dataEmpty => '資料為空';

  @override
  String get dataIncomplete => '資料不完整';

  @override
  String get dataMergeOptions => '資料合併選項：';

  @override
  String get dataPath => '資料路徑';

  @override
  String get dataPathChangedMessage => '資料路徑已變更，請重新啟動應用程式以使變更生效。';

  @override
  String get dataPathHint => '選擇資料儲存路徑';

  @override
  String get dataPathManagement => '資料路徑管理';

  @override
  String get dataPathManagementSubtitle => '管理目前和歷史資料路徑';

  @override
  String get dataPathManagementTitle => '資料路徑管理';

  @override
  String get dataPathSettings => '資料儲存路徑';

  @override
  String get dataPathSettingsDescription => '設定應用程式資料的儲存位置。變更後需要重新啟動應用程式。';

  @override
  String get dataPathSettingsSubtitle => '設定應用程式資料的儲存位置';

  @override
  String get dataPathSwitchOptions => '資料路徑切換選項';

  @override
  String get dataPathSwitchWizard => '資料路徑切換精靈';

  @override
  String get dataSafetyRecommendation => '資料安全建議';

  @override
  String get dataSafetySuggestion => '資料安全建議';

  @override
  String get dataSafetySuggestions => '資料安全建議';

  @override
  String get dataSize => '資料大小';

  @override
  String get databaseSize => '資料庫大小';

  @override
  String get dayBeforeYesterday => '前天';

  @override
  String days(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 天',
      one: '1 天',
    );
    return '$_temp0';
  }

  @override
  String get daysAgo => '天前';

  @override
  String get defaultEditableText => '屬性面板編輯文字';

  @override
  String get defaultLayer => '預設圖層';

  @override
  String defaultLayerName(Object number) {
    return '圖層 $number';
  }

  @override
  String get defaultPage => '預設頁面';

  @override
  String defaultPageName(Object number) {
    return '頁面 $number';
  }

  @override
  String get defaultPath => '預設路徑';

  @override
  String get defaultPathName => '預設路徑';

  @override
  String get delete => '刪除 (Ctrl+D)';

  @override
  String get deleteAll => '全部刪除';

  @override
  String get deleteAllBackups => '刪除所有備份';

  @override
  String get deleteBackup => '刪除備份';

  @override
  String get deleteBackupFailed => '刪除備份失敗';

  @override
  String deleteBackupsCountMessage(Object count) {
    return '您即將刪除 $count 個備份檔案。';
  }

  @override
  String get deleteCategory => '刪除分類';

  @override
  String get deleteCategoryOnly => '僅刪除分類';

  @override
  String get deleteCategoryWithFiles => '刪除分類及檔案';

  @override
  String deleteCharacterFailed(Object error) {
    return '刪除字元失敗：$error';
  }

  @override
  String get deleteCompleteTitle => '刪除完成';

  @override
  String get deleteConfigItem => '刪除設定項';

  @override
  String get deleteConfigItemMessage => '確定要刪除此設定項嗎？此操作無法復原。';

  @override
  String get deleteConfirm => '確認刪除';

  @override
  String get deleteElementConfirmMessage => '確定要刪除這些元素嗎？';

  @override
  String deleteFailCount(Object count) {
    return '刪除失敗：$count 個檔案';
  }

  @override
  String get deleteFailDetails => '失敗詳情：';

  @override
  String deleteFailed(Object error) {
    return '刪除失敗：$error';
  }

  @override
  String deleteFailedMessage(Object error) {
    return '刪除失敗：$error';
  }

  @override
  String get deleteFailure => '備份刪除失敗';

  @override
  String get deleteGroup => '刪除群組';

  @override
  String get deleteGroupConfirm => '確認刪除群組';

  @override
  String get deleteHistoryPathNote => '注意：這只會刪除記錄，不會刪除實際的資料夾和資料。';

  @override
  String get deleteHistoryPathRecord => '刪除歷史路徑記錄';

  @override
  String get deleteImage => '刪除圖片';

  @override
  String get deleteLastMessage => '這是最後一個項目。確定要刪除嗎？';

  @override
  String get deleteLayer => '刪除圖層';

  @override
  String get deleteLayerConfirmMessage => '確定要刪除此圖層嗎？';

  @override
  String get deleteLayerMessage => '此圖層上的所有元素將被刪除。此操作無法復原。';

  @override
  String deleteMessage(Object count) {
    return '即將刪除，此操作無法復原。';
  }

  @override
  String get deletePage => '刪除頁面';

  @override
  String get deletePath => '刪除路徑';

  @override
  String get deletePathButton => '刪除路徑';

  @override
  String deletePathConfirmContent(Object path) {
    return '確定要刪除備份路徑 $path 嗎？此操作無法復原，將刪除該路徑下的所有備份檔案。';
  }

  @override
  String deleteRangeItem(Object count, Object path) {
    return '• $path：$count 個檔案';
  }

  @override
  String get deleteRangeTitle => '刪除範圍包括：';

  @override
  String get deleteSelected => '刪除所選';

  @override
  String get deleteSelectedArea => '刪除選取區域';

  @override
  String get deleteSelectedWithShortcut => '刪除所選 (Ctrl+D)';

  @override
  String get deleteSuccess => '備份刪除成功';

  @override
  String deleteSuccessCount(Object count) {
    return '成功刪除：$count 個檔案';
  }

  @override
  String get deleteText => '刪除';

  @override
  String get deleting => '正在刪除...';

  @override
  String get deletingBackups => '正在刪除備份...';

  @override
  String get deletingBackupsProgress => '正在刪除備份檔案，請稍候...';

  @override
  String get descending => '降序';

  @override
  String get descriptionLabel => '描述';

  @override
  String get deselectAll => '取消選擇';

  @override
  String get detail => '詳情';

  @override
  String get detailedError => '詳細錯誤';

  @override
  String get detailedReport => '詳細報告';

  @override
  String get deviceInfo => '裝置資訊';

  @override
  String get dimensions => '尺寸';

  @override
  String get directSwitch => '直接切換';

  @override
  String get disabled => '已停用';

  @override
  String get disabledDescription => '停用 - 在選擇器中隱藏';

  @override
  String get diskCacheSize => '磁碟快取大小';

  @override
  String get diskCacheSizeDescription => '磁碟快取的最大大小';

  @override
  String get diskCacheTtl => '磁碟快取生命週期';

  @override
  String get diskCacheTtlDescription => '快取檔案在磁碟上保留的時間';

  @override
  String get displayMode => '顯示模式';

  @override
  String get displayName => '顯示名稱';

  @override
  String get displayNameCannotBeEmpty => '顯示名稱不能為空';

  @override
  String get displayNameHint => '使用者介面中顯示的名稱';

  @override
  String get displayNameMaxLength => '顯示名稱最多 100 個字元';

  @override
  String get displayNameRequired => '請輸入顯示名稱';

  @override
  String get distributeHorizontally => '水平均分';

  @override
  String get distributeVertically => '垂直均分';

  @override
  String get distribution => '分佈';

  @override
  String get doNotCloseApp => '請不要關閉應用程式...';

  @override
  String get doNotCloseAppMessage => '請勿關閉應用程式，還原過程可能需要幾分鐘';

  @override
  String get done => '確定';

  @override
  String get dropToImportImages => '釋放滑鼠以匯入圖片';

  @override
  String get duplicateBackupFound => '發現重複備份';

  @override
  String get duplicateBackupFoundDesc => '偵測到要匯入的備份檔案與現有備份重複：';

  @override
  String get duplicateFileImported => '（重複檔案已匯入）';

  @override
  String get dynasty => '朝代';

  @override
  String get edit => '編輯';

  @override
  String get editConfigItem => '編輯設定項';

  @override
  String editField(Object field) {
    return '編輯 $field';
  }

  @override
  String get editGroupContents => '編輯群組內容';

  @override
  String get editGroupContentsDescription => '編輯所選群組的內容';

  @override
  String editLabel(Object label) {
    return '編輯 $label';
  }

  @override
  String get editOperations => '編輯操作';

  @override
  String get editTags => '編輯標籤';

  @override
  String get editTitle => '編輯標題';

  @override
  String get elementCopied => '元素已複製到剪貼簿';

  @override
  String get elementCopiedToClipboard => '元素已複製到剪貼簿';

  @override
  String get elementHeight => '高';

  @override
  String get elementId => '元素 ID';

  @override
  String get elementSize => '大小';

  @override
  String get elementWidth => '寬';

  @override
  String get elements => '元素';

  @override
  String get empty => '空';

  @override
  String get emptyGroup => '空群組';

  @override
  String get emptyStateError => '載入失敗，請稍後再試';

  @override
  String get emptyStateNoCharacters => '沒有字體，從作品中擷取字體後可在此處檢視';

  @override
  String get emptyStateNoPractices => '沒有字帖，點擊新增按鈕建立新字帖';

  @override
  String get emptyStateNoResults => '找不到符合的結果，請嘗試變更搜尋條件';

  @override
  String get emptyStateNoSelection => '未選擇任何項目，點擊項目以選擇';

  @override
  String get emptyStateNoWorks => '沒有作品，點擊新增按鈕匯入作品';

  @override
  String get enabled => '已啟用';

  @override
  String get endDate => '結束日期';

  @override
  String get ensureCompleteTransfer => '• 確保檔案完整傳輸';

  @override
  String get ensureReadWritePermission => '確保新路徑有讀寫權限';

  @override
  String get enterBackupDescription => '請輸入備份描述（可選）：';

  @override
  String get enterCategoryName => '請輸入分類名稱';

  @override
  String get enterTagHint => '輸入標籤並按 Enter';

  @override
  String error(Object message) {
    return '錯誤：$message';
  }

  @override
  String get errors => '錯誤';

  @override
  String get estimatedTime => '預計時間';

  @override
  String get executingImportOperation => '正在執行匯入操作...';

  @override
  String existingBackupInfo(Object filename) {
    return '現有備份：$filename';
  }

  @override
  String get existingItem => '現有項目';

  @override
  String get exit => '退出';

  @override
  String get exitBatchMode => '退出批次模式';

  @override
  String get exitConfirm => '退出';

  @override
  String get exitPreview => '退出預覽模式';

  @override
  String get exitWizard => '退出精靈';

  @override
  String get expand => '展開';

  @override
  String expandFileList(Object count) {
    return '點擊展開以檢視 $count 個備份檔案';
  }

  @override
  String get export => '匯出';

  @override
  String get exportAllBackups => '匯出所有備份';

  @override
  String get exportAllBackupsButton => '匯出全部備份';

  @override
  String get exportBackup => '匯出備份';

  @override
  String get exportBackupFailed => '匯出備份失敗';

  @override
  String exportBackupFailedMessage(Object error) {
    return '匯出備份失敗：$error';
  }

  @override
  String get exportCharactersOnly => '僅匯出集字';

  @override
  String get exportCharactersOnlyDescription => '僅包含選取的集字資料';

  @override
  String get exportCharactersWithWorks => '匯出集字和來源作品（建議）';

  @override
  String get exportCharactersWithWorksDescription => '包含集字及其來源作品資料';

  @override
  String exportCompleted(Object failed, Object success) {
    return '匯出完成：成功 $success 個$failed';
  }

  @override
  String exportCompletedFormat(Object failedMessage, Object successCount) {
    return '匯出完成：成功 $successCount 個$failedMessage';
  }

  @override
  String exportCompletedFormat2(Object failed, Object success) {
    return '匯出完成，成功：$success$failed';
  }

  @override
  String get exportConfig => '匯出設定';

  @override
  String get exportDialogRangeExample => '例如：1-3,5,7-9';

  @override
  String exportDimensions(Object height, Object orientation, Object width) {
    return '$width 公分 × $height 公分 ($orientation)';
  }

  @override
  String get exportEncodingIssue => '• 匯出時存在特殊字元編碼問題';

  @override
  String get exportFailed => '匯出失敗';

  @override
  String exportFailedPartFormat(Object failCount) {
    return '，失敗 $failCount 個';
  }

  @override
  String exportFailedPartFormat2(Object count) {
    return '，失敗：$count';
  }

  @override
  String exportFailedWith(Object error) {
    return '匯出失敗：$error';
  }

  @override
  String get exportFailure => '備份匯出失敗';

  @override
  String get exportFormat => '匯出格式';

  @override
  String get exportFullData => '完整資料匯出';

  @override
  String get exportFullDataDescription => '包含所有相關資料';

  @override
  String get exportLocation => '匯出位置';

  @override
  String get exportNotImplemented => '設定匯出功能尚待實作';

  @override
  String get exportOptions => '匯出選項';

  @override
  String get exportSuccess => '備份匯出成功';

  @override
  String exportSuccessMessage(Object path) {
    return '備份匯出成功：$path';
  }

  @override
  String get exportSummary => '匯出摘要';

  @override
  String get exportType => '匯出格式';

  @override
  String get exportWorksOnly => '僅匯出作品';

  @override
  String get exportWorksOnlyDescription => '僅包含選取的作品資料';

  @override
  String get exportWorksWithCharacters => '匯出作品和關聯集字（建議）';

  @override
  String get exportWorksWithCharactersDescription => '包含作品及其相關的集字資料';

  @override
  String get exporting => '正在匯出，請稍候...';

  @override
  String get exportingBackup => '正在匯出備份...';

  @override
  String get exportingBackupMessage => '正在匯出備份...';

  @override
  String exportingBackups(Object count) {
    return '正在匯出 $count 個備份...';
  }

  @override
  String get exportingBackupsProgress => '正在匯出備份...';

  @override
  String exportingBackupsProgressFormat(Object count) {
    return '正在匯出 $count 個備份檔案...';
  }

  @override
  String get exportingDescription => '正在匯出資料，請稍候...';

  @override
  String get extract => '擷取';

  @override
  String get extractionError => '擷取時發生錯誤';

  @override
  String failedCount(Object count) {
    return '，失敗 $count 個';
  }

  @override
  String get favorite => '我的最愛';

  @override
  String get favoritesOnly => '僅顯示我的最愛';

  @override
  String get fileCorrupted => '• 檔案在傳輸過程中損毀';

  @override
  String get fileCount => '檔案數量';

  @override
  String get fileExistsTitle => '檔案已存在';

  @override
  String get fileExtension => '副檔名';

  @override
  String get fileMigrationWarning => '不遷移檔案時，舊路徑的備份檔案仍保留在原位置';

  @override
  String get fileName => '檔案名稱';

  @override
  String fileNotExist(Object path) {
    return '檔案不存在：$path';
  }

  @override
  String get fileRestored => '圖片已從圖庫中還原';

  @override
  String get fileSize => '檔案大小';

  @override
  String get fileUpdatedAt => '檔案修改時間';

  @override
  String get filenamePrefix => '輸入檔案名前綴（將自動新增頁碼）';

  @override
  String get files => '檔案數量';

  @override
  String get filter => '篩選';

  @override
  String get filterAndSort => '篩選與排序';

  @override
  String get filterClear => '清除';

  @override
  String get firstPage => '第一頁';

  @override
  String get fitContain => '包含';

  @override
  String get fitCover => '覆蓋';

  @override
  String get fitFill => '填滿';

  @override
  String get fitHeight => '符合高度';

  @override
  String get fitMode => '調整模式';

  @override
  String get fitWidth => '符合寬度';

  @override
  String get flip => '翻轉';

  @override
  String get flipHorizontal => '水平翻轉';

  @override
  String get flipVertical => '垂直翻轉';

  @override
  String get flutterVersion => 'Flutter 版本';

  @override
  String get folderImportComplete => '資料夾匯入完成';

  @override
  String get fontColor => '文字顏色';

  @override
  String get fontFamily => '字體';

  @override
  String get fontSize => '字體大小';

  @override
  String get fontStyle => '字體樣式';

  @override
  String get fontTester => '字體測試工具';

  @override
  String get fontWeight => '字體粗細';

  @override
  String get fontWeightTester => '字體粗細測試工具';

  @override
  String get format => '格式';

  @override
  String get formatBrushActivated => '格式刷已啟用，點擊目標元素以套用樣式';

  @override
  String get formatType => '格式類型';

  @override
  String get fromGallery => '從圖庫選擇';

  @override
  String get fromLocal => '從本機選擇';

  @override
  String get fullScreen => '全螢幕顯示';

  @override
  String get geometryProperties => '幾何屬性';

  @override
  String get getHistoryPathsFailed => '取得歷史路徑失敗';

  @override
  String get getPathInfoFailed => '無法取得路徑資訊';

  @override
  String get getPathUsageTimeFailed => '取得路徑使用時間失敗';

  @override
  String get getStorageInfoFailed => '取得儲存資訊失敗';

  @override
  String get getThumbnailSizeError => '取得縮圖大小失敗';

  @override
  String get gettingPathInfo => '正在取得路徑資訊...';

  @override
  String get gettingStorageInfo => '正在取得儲存資訊...';

  @override
  String get gitBranch => 'Git 分支';

  @override
  String get gitCommit => 'Git 提交';

  @override
  String get goToBackup => '前往備份';

  @override
  String get gridSettings => '網格設定';

  @override
  String get gridSize => '網格大小';

  @override
  String get gridSizeExtraLarge => '特大';

  @override
  String get gridSizeLarge => '大';

  @override
  String get gridSizeMedium => '中';

  @override
  String get gridSizeSmall => '小';

  @override
  String get gridView => '網格檢視';

  @override
  String get group => '群組 (Ctrl+J)';

  @override
  String get groupElements => '群組元素';

  @override
  String get groupOperations => '群組操作';

  @override
  String get groupProperties => '群組屬性';

  @override
  String get height => '高度';

  @override
  String get help => '說明';

  @override
  String get hideDetails => '隱藏詳情';

  @override
  String get hideElement => '隱藏元素';

  @override
  String get hideGrid => '隱藏網格 (Ctrl+G)';

  @override
  String get hideImagePreview => '隱藏圖片預覽';

  @override
  String get hideThumbnails => '隱藏頁面縮圖';

  @override
  String get historicalPaths => '歷史路徑';

  @override
  String get historyDataPaths => '歷史資料路徑';

  @override
  String get historyLabel => '歷史';

  @override
  String get historyLocation => '歷史位置';

  @override
  String get historyPath => '歷史路徑';

  @override
  String get historyPathBackup => '歷史路徑備份';

  @override
  String get historyPathBackupDescription => '歷史路徑備份';

  @override
  String get historyPathDeleted => '歷史路徑記錄已刪除';

  @override
  String get homePage => '首頁';

  @override
  String get horizontalAlignment => '水平對齊';

  @override
  String get horizontalLeftToRight => '橫排由左至右';

  @override
  String get horizontalRightToLeft => '橫排由右至左';

  @override
  String hours(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 小時',
      one: '1 小時',
    );
    return '$_temp0';
  }

  @override
  String get hoursAgo => '小時前';

  @override
  String get image => '圖片';

  @override
  String get imageCount => '影像數量';

  @override
  String get imageElement => '圖片元素';

  @override
  String get imageExportFailed => '圖片匯出失敗';

  @override
  String get imageFileNotExists => '圖片檔案不存在';

  @override
  String imageImportError(Object error) {
    return '匯入影像失敗：$error';
  }

  @override
  String get imageImportSuccess => '影像匯入成功';

  @override
  String get imageIndexError => '圖片索引錯誤';

  @override
  String get imageInvalid => '影像資料無效或已損毀';

  @override
  String get imageInvert => '影像反轉';

  @override
  String imageLoadError(Object error) {
    return '載入影像失敗：$error...';
  }

  @override
  String get imageLoadFailed => '圖片載入失敗';

  @override
  String imageProcessingPathError(Object error) {
    return '處理路徑錯誤：$error';
  }

  @override
  String get imageProperties => '影像屬性';

  @override
  String get imagePropertyPanelAutoImportNotice => '所選影像將自動匯入至您的圖庫以便更好地管理';

  @override
  String get imagePropertyPanelGeometryWarning => '這些屬性會調整整個元素框，而不是影像內容本身';

  @override
  String get imagePropertyPanelPreviewNotice => '注意：預覽期間顯示的重複日誌是正常的';

  @override
  String get imagePropertyPanelTransformWarning => '這些變形會修改影像內容本身，而不僅僅是元素框架';

  @override
  String get imageResetSuccess => '重設成功';

  @override
  String get imageRestoring => '正在還原圖片資料...';

  @override
  String get imageSelection => '圖片選擇';

  @override
  String get imageTransform => '影像變形';

  @override
  String imageTransformError(Object error) {
    return '套用變形失敗：$error';
  }

  @override
  String get imageUpdated => '圖片已更新';

  @override
  String get images => '圖片';

  @override
  String get implementationComingSoon => '此功能正在開發中，敬請期待！';

  @override
  String get import => '匯入';

  @override
  String get importBackup => '匯入備份';

  @override
  String get importBackupFailed => '匯入備份失敗';

  @override
  String importBackupFailedMessage(Object error) {
    return '匯入備份失敗：$error';
  }

  @override
  String get importConfig => '匯入設定';

  @override
  String get importError => '匯入錯誤';

  @override
  String get importErrorCauses => '此問題通常由以下原因引起：';

  @override
  String importFailed(Object error) {
    return '匯入失敗：$error';
  }

  @override
  String get importFailure => '備份匯入失敗';

  @override
  String get importFileSuccess => '成功匯入檔案';

  @override
  String get importFiles => '匯入檔案';

  @override
  String get importFolder => '匯入資料夾';

  @override
  String get importNotImplemented => '設定匯入功能尚待實作';

  @override
  String get importOptions => '匯入選項';

  @override
  String get importPreview => '匯入預覽';

  @override
  String get importRequirements => '匯入要求';

  @override
  String get importResultTitle => '匯入結果';

  @override
  String get importStatistics => '匯入統計';

  @override
  String get importSuccess => '備份匯入成功';

  @override
  String importSuccessMessage(Object count) {
    return '成功匯入 $count 個檔案';
  }

  @override
  String get importToCurrentPath => '匯入至目前路徑';

  @override
  String get importToCurrentPathButton => '匯入至目前路徑';

  @override
  String get importToCurrentPathDesc => '這會將備份檔案複製到目前路徑，原始檔案保持不變。';

  @override
  String get importToCurrentPathDescription => '匯入後，此備份將出現在目前路徑的備份清單中';

  @override
  String get importToCurrentPathFailed => '匯入備份至目前路徑失敗';

  @override
  String get importToCurrentPathMessage => '您即將將此備份檔案匯入至目前備份路徑：';

  @override
  String get importToCurrentPathSuccessMessage => '備份已成功匯入至目前路徑';

  @override
  String get importToCurrentPathTitle => '匯入至目前路徑';

  @override
  String get importantReminder => '重要提醒';

  @override
  String get importedBackupDescription => '匯入的備份';

  @override
  String get importedCharacters => '匯入的集字';

  @override
  String get importedFile => '匯入的檔案';

  @override
  String get importedImages => '匯入的圖片';

  @override
  String get importedSuffix => '匯入的備份';

  @override
  String get importedWorks => '匯入的作品';

  @override
  String get importing => '正在匯入...';

  @override
  String get importingBackup => '正在匯入備份...';

  @override
  String get importingBackupProgressMessage => '正在匯入備份...';

  @override
  String get importingDescription => '正在匯入資料，請稍候...';

  @override
  String get importingToCurrentPath => '正在匯入至目前路徑...';

  @override
  String get importingToCurrentPathMessage => '正在匯入至目前路徑...';

  @override
  String get importingWorks => '正在匯入作品...';

  @override
  String get includeImages => '包含圖片';

  @override
  String get includeImagesDescription => '匯出相關的圖片檔案';

  @override
  String get includeMetadata => '包含中繼資料';

  @override
  String get includeMetadataDescription => '匯出建立時間、標籤等中繼資料';

  @override
  String get incompatibleCharset => '• 使用了不相容的字元集';

  @override
  String initializationFailed(Object error) {
    return '初始化失敗：$error';
  }

  @override
  String get initializing => '正在初始化...';

  @override
  String get inputCharacter => '輸入字元';

  @override
  String get inputChineseContent => '請輸入漢字內容';

  @override
  String inputFieldHint(Object field) {
    return '請輸入 $field';
  }

  @override
  String get inputFileName => '輸入檔案名';

  @override
  String get inputHint => '在此輸入';

  @override
  String get inputNewTag => '輸入新標籤...';

  @override
  String get inputTitle => '請輸入字帖標題';

  @override
  String get invalidFilename => '檔案名稱不能包含以下字元：\\ / : * ? \" < > |';

  @override
  String get invalidNumber => '請輸入有效的數字';

  @override
  String get invertMode => '反轉模式';

  @override
  String get isActive => '是否啟用';

  @override
  String itemsCount(Object count) {
    return '$count 個選項';
  }

  @override
  String itemsPerPage(Object count) {
    return '$count 項/頁';
  }

  @override
  String get jsonFile => 'JSON 檔案';

  @override
  String get justNow => '剛剛';

  @override
  String get keepBackupCount => '保留備份數量';

  @override
  String get keepBackupCountDescription => '刪除舊備份前保留的備份數量';

  @override
  String get keepExisting => '保留現有';

  @override
  String get keepExistingDescription => '保留現有資料，略過匯入';

  @override
  String get key => '鍵';

  @override
  String get keyCannotBeEmpty => '鍵不能為空';

  @override
  String get keyExists => '設定金鑰已存在';

  @override
  String get keyHelperText => '只能包含字母、數字、底線和連字號';

  @override
  String get keyHint => '設定項的唯一識別碼';

  @override
  String get keyInvalidCharacters => '鍵只能包含字母、數字、底線和連字號';

  @override
  String get keyMaxLength => '鍵最多 50 個字元';

  @override
  String get keyMinLength => '鍵至少需要 2 個字元';

  @override
  String get keyRequired => '請輸入設定金鑰';

  @override
  String get landscape => '橫向';

  @override
  String get language => '語言';

  @override
  String get languageEn => 'English';

  @override
  String get languageJa => '日本語';

  @override
  String get languageKo => '한국어';

  @override
  String get languageSystem => '系統';

  @override
  String get languageZh => '簡體中文';

  @override
  String get languageZhTw => '繁體中文';

  @override
  String get last30Days => '最近 30 天';

  @override
  String get last365Days => '最近 365 天';

  @override
  String get last7Days => '最近 7 天';

  @override
  String get last90Days => '最近 90 天';

  @override
  String get lastBackup => '上次備份';

  @override
  String get lastBackupTime => '上次備份時間';

  @override
  String get lastMonth => '上個月';

  @override
  String get lastPage => '最後一頁';

  @override
  String get lastUsed => '上次使用';

  @override
  String get lastUsedTime => '上次使用時間';

  @override
  String get lastWeek => '上週';

  @override
  String get lastYear => '去年';

  @override
  String get layer => '圖層';

  @override
  String get layer1 => '圖層 1';

  @override
  String get layerElements => '圖層元素';

  @override
  String get layerInfo => '圖層資訊';

  @override
  String layerName(Object index) {
    return '圖層 $index';
  }

  @override
  String get layerOperations => '圖層操作';

  @override
  String get layerProperties => '圖層屬性';

  @override
  String get leave => '離開';

  @override
  String get legacyBackupDescription => '歷史備份';

  @override
  String get legacyDataPathDescription => '需要清理的舊資料路徑';

  @override
  String get letterSpacing => '字元間距';

  @override
  String get library => '圖庫';

  @override
  String get libraryCount => '圖庫數量';

  @override
  String get libraryManagement => '圖庫';

  @override
  String get lineHeight => '行間距';

  @override
  String get lineThrough => '刪除線';

  @override
  String get listView => '清單檢視';

  @override
  String get loadBackupRegistryFailed => '載入備份登錄檔失敗';

  @override
  String loadCharacterDataFailed(Object error) {
    return '載入字元資料失敗：$error';
  }

  @override
  String get loadConfigFailed => '載入設定失敗';

  @override
  String get loadCurrentBackupPathFailed => '載入目前備份路徑失敗';

  @override
  String get loadDataFailed => '載入資料失敗';

  @override
  String get loadFailed => '載入失敗';

  @override
  String get loadPathInfoFailed => '載入路徑資訊失敗';

  @override
  String get loadPracticeSheetFailed => '載入字帖失敗';

  @override
  String get loading => '載入中...';

  @override
  String get loadingImage => '正在載入影像...';

  @override
  String get location => '位置';

  @override
  String get lock => '鎖定';

  @override
  String get lockElement => '鎖定元素';

  @override
  String get lockStatus => '鎖定狀態';

  @override
  String get lockUnlockAllElements => '鎖定/解鎖所有元素';

  @override
  String get locked => '已鎖定';

  @override
  String get manualBackupDescription => '手動建立的備份';

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
  String get memoryDataCacheCapacity => '記憶體資料快取容量';

  @override
  String get memoryDataCacheCapacityDescription => '記憶體中保留的資料項目數量';

  @override
  String get memoryImageCacheCapacity => '記憶體影像快取容量';

  @override
  String get memoryImageCacheCapacityDescription => '記憶體中保留的影像數量';

  @override
  String get mergeAndMigrateFiles => '合併並遷移檔案';

  @override
  String get mergeBackupInfo => '合併備份資訊';

  @override
  String get mergeBackupInfoDesc => '將舊路徑的備份資訊合併到新路徑的登錄檔中';

  @override
  String get mergeData => '合併資料';

  @override
  String get mergeDataDescription => '合併現有資料和匯入資料';

  @override
  String get mergeOnlyBackupInfo => '僅合併備份資訊';

  @override
  String get metadata => '中繼資料';

  @override
  String get migrateBackupFiles => '遷移備份檔案';

  @override
  String get migrateBackupFilesDesc => '將舊路徑的備份檔案複製到新路徑（建議）';

  @override
  String get migratingData => '正在遷移資料';

  @override
  String get min => '最小';

  @override
  String get monospace => 'Monospace';

  @override
  String get monthsAgo => '個月前';

  @override
  String moreErrorsCount(Object count) {
    return '...還有 $count 個錯誤';
  }

  @override
  String get moveDown => '下移 (Ctrl+Shift+B)';

  @override
  String get moveLayerDown => '圖層下移';

  @override
  String get moveLayerUp => '圖層上移';

  @override
  String get moveUp => '上移 (Ctrl+Shift+T)';

  @override
  String get multiSelectTool => '多選工具';

  @override
  String multipleFilesNote(Object count) {
    return '注意：將匯出 $count 個圖片檔案，檔案名稱將自動新增頁碼。';
  }

  @override
  String get name => '名稱';

  @override
  String get navCollapseSidebar => '收合側邊欄';

  @override
  String get navExpandSidebar => '展開側邊欄';

  @override
  String get navigatedToBackupSettings => '已跳轉至備份設定頁面';

  @override
  String get navigationAttemptBack => '嘗試返回上一個功能區';

  @override
  String get navigationAttemptToNewSection => '嘗試導覽至新功能區';

  @override
  String get navigationAttemptToSpecificItem => '嘗試導覽至特定歷史記錄項目';

  @override
  String get navigationBackToPrevious => '返回上一頁';

  @override
  String get navigationClearHistory => '清除導覽歷史記錄';

  @override
  String get navigationClearHistoryFailed => '清除導覽歷史記錄失敗';

  @override
  String get navigationFailedBack => '返回導覽失敗';

  @override
  String get navigationFailedSection => '導覽切換失敗';

  @override
  String get navigationFailedToSpecificItem => '導覽至特定歷史記錄項目失敗';

  @override
  String get navigationHistoryCleared => '導覽歷史記錄已清除';

  @override
  String get navigationItemNotFound => '在歷史記錄中找不到目標項目，直接導覽至該功能區';

  @override
  String get navigationNoHistory => '無法返回';

  @override
  String get navigationNoHistoryMessage => '已到達目前功能區的起始頁面。';

  @override
  String get navigationRecordRoute => '記錄功能區內的路由變化';

  @override
  String get navigationRecordRouteFailed => '記錄路由變化失敗';

  @override
  String get navigationRestoreStateFailed => '還原導覽狀態失敗';

  @override
  String get navigationSaveState => '儲存導覽狀態';

  @override
  String get navigationSaveStateFailed => '儲存導覽狀態失敗';

  @override
  String get navigationSectionCharacterManagement => '字元管理';

  @override
  String get navigationSectionGalleryManagement => '圖庫管理';

  @override
  String get navigationSectionPracticeList => '字帖清單';

  @override
  String get navigationSectionSettings => '設定';

  @override
  String get navigationSectionWorkBrowse => '作品瀏覽';

  @override
  String get navigationSelectPage => '您想返回以下哪個頁面？';

  @override
  String get navigationStateRestored => '導覽狀態已從儲存空間還原';

  @override
  String get navigationStateSaved => '導覽狀態已儲存';

  @override
  String get navigationSuccessBack => '成功返回上一個功能區';

  @override
  String get navigationSuccessToNewSection => '成功導覽至新功能區';

  @override
  String get navigationSuccessToSpecificItem => '成功導覽至特定歷史記錄項目';

  @override
  String get navigationToggleExpanded => '切換導覽列展開狀態';

  @override
  String get needRestartApp => '需要重新啟動應用程式';

  @override
  String get newConfigItem => '新增設定項';

  @override
  String get newDataPath => '新的資料路徑：';

  @override
  String get newItem => '新增';

  @override
  String get nextField => '下一個欄位';

  @override
  String get nextPage => '下一頁';

  @override
  String get nextStep => '下一步';

  @override
  String get no => '否';

  @override
  String get noBackupExistsRecommendCreate => '尚未建立任何備份，建議先建立備份以確保資料安全';

  @override
  String get noBackupFilesInPath => '此路徑下沒有備份檔案';

  @override
  String get noBackupFilesInPathMessage => '此路徑下沒有備份檔案';

  @override
  String get noBackupFilesToExport => '此路徑下沒有可匯出的備份檔案';

  @override
  String get noBackupFilesToExportMessage => '沒有可匯出的備份檔案';

  @override
  String get noBackupPathSetRecommendCreateBackup => '未設定備份路徑，建議先設定備份路徑並建立備份';

  @override
  String get noBackupPaths => '沒有備份路徑';

  @override
  String get noBackups => '沒有可用的備份';

  @override
  String get noBackupsInPath => '此路徑下沒有備份檔案';

  @override
  String get noBackupsToDelete => '沒有可刪除的備份檔案';

  @override
  String get noCategories => '無分類';

  @override
  String get noCharacters => '找不到字元';

  @override
  String get noCharactersFound => '找不到符合的字元';

  @override
  String noConfigItems(Object category) {
    return '暫無 $category 設定';
  }

  @override
  String get noCropping => '（無裁剪）';

  @override
  String get noDisplayableImages => '沒有可顯示的圖片';

  @override
  String get noElementsInLayer => '此圖層中沒有元素';

  @override
  String get noElementsSelected => '未選擇元素';

  @override
  String get noHistoryPaths => '沒有歷史路徑';

  @override
  String get noHistoryPathsDescription => '尚未使用過其他資料路徑';

  @override
  String get noImageSelected => '未選擇圖片';

  @override
  String get noImages => '沒有圖片';

  @override
  String get noItemsSelected => '未選擇項目';

  @override
  String get noLayers => '無圖層，請新增圖層';

  @override
  String get noMatchingConfigItems => '找不到符合的設定項';

  @override
  String get noPageSelected => '未選擇頁面';

  @override
  String get noPagesToExport => '沒有可匯出的頁面';

  @override
  String get noPagesToPrint => '沒有可列印的頁面';

  @override
  String get noPreviewAvailable => '無有效預覽';

  @override
  String get noRegionBoxed => '未選擇區域';

  @override
  String get noRemarks => '無備註';

  @override
  String get noResults => '找不到結果';

  @override
  String get noTags => '無標籤';

  @override
  String get noTexture => '無紋理';

  @override
  String get noTopLevelCategory => '無（頂層分類）';

  @override
  String get noWorks => '找不到作品';

  @override
  String get noWorksHint => '嘗試匯入新作品或變更篩選條件';

  @override
  String get noiseReduction => '降噪';

  @override
  String get none => '無';

  @override
  String get notSet => '未設定';

  @override
  String get note => '注意';

  @override
  String get notesTitle => '注意事項：';

  @override
  String get noticeTitle => '注意事項';

  @override
  String get ok => '確定';

  @override
  String get oldBackupRecommendCreateNew => '上次備份時間超過 24 小時，建議建立新備份';

  @override
  String get oldDataNotAutoDeleted => '路徑切換後，舊資料不會自動刪除';

  @override
  String get oldDataNotDeleted => '路徑切換後，舊資料不會自動刪除';

  @override
  String get oldDataWillNotBeDeleted => '切換後，舊路徑的資料不會自動刪除';

  @override
  String get oldPathDataNotAutoDeleted => '切換後，舊路徑的資料不會自動刪除';

  @override
  String get onlyOneCharacter => '只允許一個字元';

  @override
  String get opacity => '不透明度';

  @override
  String get openBackupManagementFailed => '開啟備份管理失敗';

  @override
  String get openFolder => '開啟資料夾';

  @override
  String openGalleryFailed(Object error) {
    return '開啟圖庫失敗：$error';
  }

  @override
  String get openPathFailed => '開啟路徑失敗';

  @override
  String get openPathSwitchWizardFailed => '開啟資料路徑切換精靈失敗';

  @override
  String get operatingSystem => '作業系統';

  @override
  String get operationCannotBeUndone => '此操作無法復原，請謹慎確認';

  @override
  String get operationCannotUndo => '此操作無法復原，請謹慎確認';

  @override
  String get optional => '可選';

  @override
  String get original => '原始';

  @override
  String get originalImageDesc => '未經處理的原始影像';

  @override
  String get outputQuality => '輸出品質';

  @override
  String get overwrite => '覆寫';

  @override
  String get overwriteConfirm => '確認覆寫';

  @override
  String get overwriteExisting => '覆寫現有';

  @override
  String get overwriteExistingDescription => '用匯入資料取代現有項目';

  @override
  String overwriteExistingPractice(Object title) {
    return '已存在名為「$title」的字帖，是否覆寫？';
  }

  @override
  String get overwriteFile => '覆寫檔案';

  @override
  String get overwriteFileAction => '覆寫檔案';

  @override
  String overwriteMessage(Object title) {
    return '已存在標題為「$title」的字帖，是否覆寫？';
  }

  @override
  String get overwrittenCharacters => '覆寫的集字';

  @override
  String get overwrittenItems => '覆寫的項目';

  @override
  String get overwrittenWorks => '覆寫的作品';

  @override
  String get padding => '內邊距';

  @override
  String get pageBuildError => '頁面建置錯誤';

  @override
  String get pageMargins => '頁面邊距（公分）';

  @override
  String get pageNotImplemented => '頁面未實作';

  @override
  String get pageOrientation => '頁面方向';

  @override
  String get pageProperties => '頁面屬性';

  @override
  String get pageRange => '頁面範圍';

  @override
  String get pageSize => '頁面大小';

  @override
  String get pages => '頁';

  @override
  String get parentCategory => '父分類（可選）';

  @override
  String get parsingImportData => '正在解析匯入資料...';

  @override
  String get paste => '貼上 (Ctrl+Shift+V)';

  @override
  String get path => '路徑';

  @override
  String get pathAnalysis => '路徑分析';

  @override
  String get pathConfigError => '路徑設定錯誤';

  @override
  String get pathInfo => '路徑資訊';

  @override
  String get pathInvalid => '路徑無效';

  @override
  String get pathNotExists => '路徑不存在';

  @override
  String get pathSettings => '路徑設定';

  @override
  String get pathSize => '路徑大小';

  @override
  String get pathSwitchCompleted => '資料路徑切換完成！\n\n您可以在「資料路徑管理」中檢視和清理舊路徑的資料。';

  @override
  String get pathSwitchCompletedMessage => '資料路徑切換完成！\n\n您可以在資料路徑管理中檢視和清理舊路徑的資料。';

  @override
  String get pathSwitchFailed => '路徑切換失敗';

  @override
  String get pathSwitchFailedMessage => '路徑切換失敗';

  @override
  String pathValidationFailed(Object error) {
    return '路徑驗證失敗：$error';
  }

  @override
  String get pathValidationFailedGeneric => '路徑驗證失敗，請檢查路徑是否有效';

  @override
  String get pdfExportFailed => 'PDF 匯出失敗';

  @override
  String pdfExportSuccess(Object path) {
    return 'PDF 匯出成功：$path';
  }

  @override
  String get pinyin => '拼音';

  @override
  String get pixels => '像素';

  @override
  String get platformInfo => '平台資訊';

  @override
  String get pleaseEnterValidNumber => '請輸入有效的數字';

  @override
  String get pleaseSelectOperation => '請選擇操作：';

  @override
  String get pleaseSetBackupPathFirst => '請先設定備份路徑';

  @override
  String get pleaseWaitMessage => '請稍候';

  @override
  String get portrait => '縱向';

  @override
  String get position => '位置';

  @override
  String get ppiSetting => 'PPI 設定（每英吋像素數）';

  @override
  String get practiceEditCollection => '擷取';

  @override
  String get practiceEditDefaultLayer => '預設圖層';

  @override
  String practiceEditPracticeLoaded(Object title) {
    return '字帖「$title」載入成功';
  }

  @override
  String get practiceEditTitle => '字帖編輯';

  @override
  String get practiceListSearch => '搜尋字帖...';

  @override
  String get practiceListTitle => '字帖';

  @override
  String get practiceSheetNotExists => '字帖不存在';

  @override
  String practiceSheetSaved(Object title) {
    return '字帖「$title」已儲存';
  }

  @override
  String practiceSheetSavedMessage(Object title) {
    return '字帖「$title」儲存成功';
  }

  @override
  String get practices => '字帖';

  @override
  String get preparingPrint => '正在準備列印，請稍候...';

  @override
  String get preparingSave => '準備儲存...';

  @override
  String get preserveMetadata => '保留中繼資料';

  @override
  String get preserveMetadataDescription => '保留原始建立時間和中繼資料';

  @override
  String get preserveMetadataMandatory => '強制保留原始的建立時間、作者資訊等中繼資料，以確保資料一致性';

  @override
  String get presetSize => '預設大小';

  @override
  String get presets => '預設集';

  @override
  String get preview => '預覽';

  @override
  String get previewMode => '預覽模式';

  @override
  String previewPage(Object current, Object total) {
    return '（第 $current/$total 頁）';
  }

  @override
  String get previousField => '上一個欄位';

  @override
  String get previousPage => '上一頁';

  @override
  String get previousStep => '上一步';

  @override
  String processedCount(Object current, Object total) {
    return '已處理：$current / $total';
  }

  @override
  String processedProgress(Object current, Object total) {
    return '已處理：$current / $total';
  }

  @override
  String get processing => '處理中...';

  @override
  String get processingDetails => '處理詳情';

  @override
  String get processingEraseData => '正在處理清除資料...';

  @override
  String get processingImage => '正在處理影像...';

  @override
  String get processingPleaseWait => '正在處理中，請稍候...';

  @override
  String get properties => '屬性';

  @override
  String get qualityHigh => '高畫質 (2x)';

  @override
  String get qualityStandard => '標準 (1x)';

  @override
  String get qualityUltra => '超高畫質 (3x)';

  @override
  String get quickRecoveryOnIssues => '• 切換過程中如遇問題可快速還原';

  @override
  String get reExportWork => '• 重新匯出該作品';

  @override
  String get recent => '最近';

  @override
  String get recentBackupCanSwitch => '最近已有備份，可以直接切換';

  @override
  String get recommendConfirmBeforeCleanup => '建議在清理旧路徑前確認新路徑資料是否正常';

  @override
  String get recommendConfirmNewDataBeforeClean => '建議在清理旧路徑前確認新路徑資料是否正常';

  @override
  String get recommendSufficientSpace => '建議選擇剩餘空間充足的磁碟';

  @override
  String get redo => '重做';

  @override
  String get refresh => '重新整理';

  @override
  String refreshDataFailed(Object error) {
    return '重新整理資料失敗：$error';
  }

  @override
  String get reload => '重新載入';

  @override
  String get remarks => '備註';

  @override
  String get remarksHint => '新增備註資訊';

  @override
  String get remove => '移除';

  @override
  String get removeFavorite => '從我的最愛中移除';

  @override
  String get removeFromCategory => '從目前分類中移除';

  @override
  String get rename => '重新命名';

  @override
  String get renameDuplicates => '重新命名重複項目';

  @override
  String get renameDuplicatesDescription => '重新命名匯入項目以避免衝突';

  @override
  String get renameLayer => '重新命名圖層';

  @override
  String get renderFailed => '渲染失敗';

  @override
  String get reselectFile => '重新選擇檔案';

  @override
  String get reset => '重設';

  @override
  String resetCategoryConfig(Object category) {
    return '重設 $category 設定';
  }

  @override
  String resetCategoryConfigMessage(Object category) {
    return '確定要將 $category 設定重設為預設值嗎？此操作無法復原。';
  }

  @override
  String get resetDataPathToDefault => '重設為預設';

  @override
  String get resetSettingsConfirmMessage => '確定重設為預設值嗎？';

  @override
  String get resetSettingsConfirmTitle => '重設設定';

  @override
  String get resetToDefault => '重設為預設';

  @override
  String get resetToDefaultFailed => '重設為預設路徑失敗';

  @override
  String resetToDefaultFailedWithError(Object error) {
    return '重設為預設路徑失敗：$error';
  }

  @override
  String get resetToDefaultPathMessage => '這會將資料路徑重設為預設位置，應用程式需要重新啟動才能生效。確定要繼續嗎？';

  @override
  String get resetToDefaults => '重設為預設值';

  @override
  String get resetTransform => '重設變形';

  @override
  String get resetZoom => '重設縮放';

  @override
  String get resolution => '解析度';

  @override
  String get restartAfterRestored => '注意：還原完成後應用程式將自動重新啟動';

  @override
  String get restartLaterButton => '稍後';

  @override
  String get restartNeeded => '需要重新啟動';

  @override
  String get restartNow => '立即重新啟動';

  @override
  String get restartNowButton => '立即重新啟動';

  @override
  String get restore => '還原';

  @override
  String get restoreBackup => '還原備份';

  @override
  String get restoreBackupFailed => '還原備份失敗';

  @override
  String get restoreConfirmMessage => '確定要從此備份還原嗎？這將取代您目前的所有資料。';

  @override
  String get restoreConfirmTitle => '確認還原';

  @override
  String get restoreFailure => '還原失敗';

  @override
  String get restoreWarningMessage => '警告：此操作將覆寫目前所有資料！';

  @override
  String get restoringBackup => '正在從備份還原...';

  @override
  String get restoringBackupMessage => '正在還原備份...';

  @override
  String get retry => '重試';

  @override
  String get retryAction => '重試';

  @override
  String get rotateLeft => '向左旋轉';

  @override
  String get rotateRight => '向右旋轉';

  @override
  String get rotation => '旋轉';

  @override
  String get safetyBackupBeforePathSwitch => '資料路徑切換前的安全備份';

  @override
  String get safetyBackupRecommendation => '為確保資料安全，建議在切換資料路徑前先建立備份：';

  @override
  String get safetyTip => '💡 安全建議：';

  @override
  String get sansSerif => 'Sans Serif';

  @override
  String get save => '儲存';

  @override
  String get saveAs => '另存新檔';

  @override
  String get saveComplete => '儲存完成';

  @override
  String get saveFailed => '儲存失敗，請稍後重試';

  @override
  String saveFailedWithError(Object error) {
    return '儲存失敗：$error';
  }

  @override
  String get saveFailure => '儲存失敗';

  @override
  String get savePreview => '字元預覽：';

  @override
  String get saveSuccess => '儲存成功';

  @override
  String get saveTimeout => '儲存逾時';

  @override
  String get savingToStorage => '正在儲存至儲存空間...';

  @override
  String get scale => '縮放';

  @override
  String get scannedBackupFileDescription => '掃描發現的備份檔案';

  @override
  String get search => '搜尋';

  @override
  String get searchCategories => '搜尋分類...';

  @override
  String get searchConfigDialogTitle => '搜尋設定項';

  @override
  String get searchConfigHint => '輸入設定項名稱或鍵';

  @override
  String get searchConfigItems => '搜尋設定項';

  @override
  String get searching => '正在搜尋...';

  @override
  String get select => '選擇';

  @override
  String get selectAll => '全選';

  @override
  String get selectAllWithShortcut => '全選 (Ctrl+Shift+A)';

  @override
  String get selectBackup => '選擇備份';

  @override
  String get selectBackupFileToImportDialog => '選擇要匯入的備份檔案';

  @override
  String get selectBackupStorageLocation => '選擇備份儲存位置';

  @override
  String get selectCategoryToApply => '請選擇要套用的分類：';

  @override
  String get selectCharacterFirst => '請先選擇字元';

  @override
  String selectColor(Object type) {
    return '選擇 $type';
  }

  @override
  String get selectDate => '選擇日期';

  @override
  String get selectExportLocation => '選擇匯出位置';

  @override
  String get selectExportLocationDialog => '選擇匯出位置';

  @override
  String get selectExportLocationHint => '選擇匯出位置...';

  @override
  String get selectFileError => '選擇檔案失敗';

  @override
  String get selectFolder => '選擇資料夾';

  @override
  String get selectImage => '選擇圖片';

  @override
  String get selectImages => '選擇圖片';

  @override
  String get selectImagesWithCtrl => '選擇圖片（可按住 Ctrl 多選）';

  @override
  String get selectImportFile => '選擇備份檔案';

  @override
  String get selectNewDataPath => '選擇新的資料儲存路徑：';

  @override
  String get selectNewDataPathDialog => '選擇新的資料儲存路徑';

  @override
  String get selectNewDataPathTitle => '選擇新的資料儲存路徑';

  @override
  String get selectNewPath => '選擇新路徑';

  @override
  String get selectParentCategory => '選擇父分類';

  @override
  String get selectPath => '選擇路徑';

  @override
  String get selectPathButton => '選擇路徑';

  @override
  String get selectPathFailed => '選擇路徑失敗';

  @override
  String get selectSufficientSpaceDisk => '建議選擇剩餘空間充足的磁碟';

  @override
  String get selectTargetLayer => '選擇目標圖層';

  @override
  String get selected => '已選擇';

  @override
  String get selectedCharacter => '已選字元';

  @override
  String selectedCount(Object count) {
    return '已選擇 $count 個';
  }

  @override
  String get selectedElementNotFound => '找不到選取的元素';

  @override
  String get selectedItems => '選取項目';

  @override
  String get selectedPath => '已選擇的路徑：';

  @override
  String get selectionMode => '選擇模式';

  @override
  String get sendToBack => '置於底層 (Ctrl+B)';

  @override
  String get serif => 'Serif';

  @override
  String get serviceNotReady => '服務尚未就緒，請稍後再試';

  @override
  String get setBackupPathFailed => '設定備份路徑失敗';

  @override
  String get setCategory => '設定分類';

  @override
  String setCategoryForItems(Object count) {
    return '設定分類（$count 個項目）';
  }

  @override
  String get setDataPathFailed => '設定資料路徑失敗，請檢查路徑權限和相容性';

  @override
  String setDataPathFailedWithError(Object error) {
    return '設定資料路徑失敗：$error';
  }

  @override
  String get settings => '設定';

  @override
  String get settingsResetMessage => '設定已重設為預設值';

  @override
  String get shortcuts => '鍵盤快捷鍵';

  @override
  String get showContour => '顯示輪廓';

  @override
  String get showDetails => '顯示詳情';

  @override
  String get showElement => '顯示元素';

  @override
  String get showGrid => '顯示網格 (Ctrl+G)';

  @override
  String get showHideAllElements => '顯示/隱藏所有元素';

  @override
  String get showImagePreview => '顯示圖片預覽';

  @override
  String get showThumbnails => '顯示頁面縮圖';

  @override
  String get skipBackup => '略過備份';

  @override
  String get skipBackupConfirm => '略過備份';

  @override
  String get skipBackupWarning => '確定要略過備份直接進行路徑切換嗎？\n\n這可能存在資料遺失的風險。';

  @override
  String get skipBackupWarningMessage => '確定要略過備份直接進行路徑切換嗎？\n\n這可能存在資料遺失的風險。';

  @override
  String get skipConflicts => '略過衝突';

  @override
  String get skipConflictsDescription => '略過已存在的項目';

  @override
  String get skippedCharacters => '略過的集字';

  @override
  String get skippedItems => '略過的項目';

  @override
  String get skippedWorks => '略過的作品';

  @override
  String get sort => '排序';

  @override
  String get sortBy => '排序方式';

  @override
  String get sortByCreateTime => '按建立時間排序';

  @override
  String get sortByTitle => '按標題排序';

  @override
  String get sortByUpdateTime => '按更新時間排序';

  @override
  String get sortFailed => '排序失敗';

  @override
  String get sortOrder => '排序';

  @override
  String get sortOrderCannotBeEmpty => '排序順序不能為空';

  @override
  String get sortOrderHint => '數字越小排序越靠前';

  @override
  String get sortOrderLabel => '排序順序';

  @override
  String get sortOrderNumber => '排序值必須是數字';

  @override
  String get sortOrderRange => '排序順序必須介於 1-999 之間';

  @override
  String get sortOrderRequired => '請輸入排序值';

  @override
  String get sourceBackupFileNotFound => '找不到來源備份檔案';

  @override
  String sourceFileNotFound(Object path) {
    return '找不到來源檔案：$path';
  }

  @override
  String sourceFileNotFoundError(Object path) {
    return '找不到來源檔案：$path';
  }

  @override
  String get sourceHanSansFont => '思源黑體 (Source Han Sans)';

  @override
  String get sourceHanSerifFont => '思源宋體 (Source Han Serif)';

  @override
  String get sourceInfo => '出處資訊';

  @override
  String get startBackup => '開始備份';

  @override
  String get startDate => '開始日期';

  @override
  String get stateAndDisplay => '狀態與顯示';

  @override
  String get statisticsInProgress => '統計中...';

  @override
  String get status => '狀態';

  @override
  String get statusAvailable => '可用';

  @override
  String get statusLabel => '狀態';

  @override
  String get statusUnavailable => '不可用';

  @override
  String get storageDetails => '儲存詳情';

  @override
  String get storageLocation => '儲存位置';

  @override
  String get storageSettings => '儲存設定';

  @override
  String get storageUsed => '已使用儲存空間';

  @override
  String get stretch => '拉伸';

  @override
  String get strokeCount => '筆劃';

  @override
  String submitFailed(Object error) {
    return '提交失敗：$error';
  }

  @override
  String successDeletedCount(Object count) {
    return '成功刪除 $count 個備份檔案';
  }

  @override
  String get suggestConfigureBackupPath => '建議：先在設定中設定備份路徑';

  @override
  String get suggestConfigureBackupPathFirst => '建議：先在設定中設定備份路徑';

  @override
  String get suggestRestartOrWait => '建議：重新啟動應用程式或等待服務初始化完成後重試';

  @override
  String get suggestRestartOrWaitService => '建議：重新啟動應用程式或等待服務初始化完成後重試';

  @override
  String get suggestedSolutions => '建議解決方案：';

  @override
  String get suggestedTags => '建議標籤';

  @override
  String get switchSuccessful => '切換成功';

  @override
  String get switchingPage => '正在切換至字元頁面...';

  @override
  String get systemConfig => '系統設定';

  @override
  String get systemConfigItemNote => '這是系統設定項，鍵值不可修改';

  @override
  String get systemInfo => '系統資訊';

  @override
  String get tabToNextField => '按 Tab 導覽至下一個欄位';

  @override
  String tagAddError(Object error) {
    return '新增標籤失敗：$error';
  }

  @override
  String get tagHint => '輸入標籤名稱';

  @override
  String tagRemoveError(Object error) {
    return '移除標籤失敗，錯誤：$error';
  }

  @override
  String get tags => '標籤';

  @override
  String get tagsAddHint => '輸入標籤名稱並按 Enter';

  @override
  String get tagsHint => '輸入標籤...';

  @override
  String get tagsSelected => '已選標籤：';

  @override
  String get targetLocationExists => '目標位置已存在同名檔案：';

  @override
  String get targetPathLabel => '請選擇操作：';

  @override
  String get text => '文字';

  @override
  String get textAlign => '文字對齊';

  @override
  String get textContent => '文字內容';

  @override
  String get textElement => '文字元素';

  @override
  String get textProperties => '文字屬性';

  @override
  String get textSettings => '文字設定';

  @override
  String get textureFillMode => '紋理填滿模式';

  @override
  String get textureFillModeContain => '包含';

  @override
  String get textureFillModeCover => '覆蓋';

  @override
  String get textureFillModeRepeat => '重複';

  @override
  String get textureOpacity => '紋理不透明度';

  @override
  String get themeMode => '主題模式';

  @override
  String get themeModeDark => '深色';

  @override
  String get themeModeDescription => '使用深色主題以獲得更好的夜間觀看體驗';

  @override
  String get themeModeSystemDescription => '根據系統設定自動切換深色/淺色主題';

  @override
  String get thisMonth => '本月';

  @override
  String get thisWeek => '本週';

  @override
  String get thisYear => '今年';

  @override
  String get threshold => '閾值';

  @override
  String get thumbnailCheckFailed => '縮圖檢查失敗';

  @override
  String get thumbnailEmpty => '縮圖檔案為空';

  @override
  String get thumbnailLoadError => '載入縮圖失敗';

  @override
  String get thumbnailNotFound => '找不到縮圖';

  @override
  String get timeInfo => '時間資訊';

  @override
  String get timeLabel => '時間';

  @override
  String get title => '標題';

  @override
  String get titleAlreadyExists => '已存在相同標題的字帖，請使用其他標題';

  @override
  String get titleCannotBeEmpty => '標題不能為空';

  @override
  String get titleExists => '標題已存在';

  @override
  String get titleExistsMessage => '已存在同名字帖。是否覆寫？';

  @override
  String titleUpdated(Object title) {
    return '標題已更新為「$title」';
  }

  @override
  String get to => '至';

  @override
  String get today => '今天';

  @override
  String get toggleBackground => '切換背景';

  @override
  String get toolModePanTooltip => '拖曳工具 (Ctrl+V)';

  @override
  String get toolModeSelectTooltip => '框選工具 (Ctrl+B)';

  @override
  String get total => '總計';

  @override
  String get totalBackups => '總備份數';

  @override
  String totalItems(Object count) {
    return '共 $count 個';
  }

  @override
  String get totalSize => '總大小';

  @override
  String get transformApplied => '變形已套用';

  @override
  String get tryOtherKeywords => '嘗試使用其他關鍵詞搜尋';

  @override
  String get type => '類型';

  @override
  String get underline => '底線';

  @override
  String get undo => '復原';

  @override
  String get ungroup => '取消群組 (Ctrl+U)';

  @override
  String get ungroupConfirm => '確認解散群組';

  @override
  String get ungroupDescription => '確定要解散此群組嗎？';

  @override
  String get unknown => '未知';

  @override
  String get unknownCategory => '未知分類';

  @override
  String unknownElementType(Object type) {
    return '未知元素類型：$type';
  }

  @override
  String get unknownError => '未知錯誤';

  @override
  String get unlockElement => '解鎖元素';

  @override
  String get unlocked => '未鎖定';

  @override
  String get unnamedElement => '未命名元素';

  @override
  String get unnamedGroup => '未命名群組';

  @override
  String get unnamedLayer => '未命名圖層';

  @override
  String get unsavedChanges => '有未儲存的變更';

  @override
  String get updateTime => '更新時間';

  @override
  String get updatedAt => '更新時間';

  @override
  String get usageInstructions => '使用說明';

  @override
  String get useDefaultPath => '使用預設路徑';

  @override
  String get userConfig => '使用者設定';

  @override
  String get validCharacter => '請輸入有效的字元';

  @override
  String get validPath => '有效路徑';

  @override
  String get validateData => '驗證資料';

  @override
  String get validateDataDescription => '匯入前驗證資料完整性';

  @override
  String get validateDataMandatory => '強制驗證匯入檔案的完整性和格式，以確保資料安全';

  @override
  String get validatingImportFile => '正在驗證匯入檔案...';

  @override
  String valueTooLarge(Object label, Object max) {
    return '$label 不能大於 $max';
  }

  @override
  String valueTooSmall(Object label, Object min) {
    return '$label 不能小於 $min';
  }

  @override
  String get versionDetails => '版本詳情';

  @override
  String get versionInfoCopied => '版本資訊已複製到剪貼簿';

  @override
  String get verticalAlignment => '垂直對齊';

  @override
  String get verticalLeftToRight => '豎排由左至右';

  @override
  String get verticalRightToLeft => '豎排由右至左';

  @override
  String get viewAction => '檢視';

  @override
  String get viewDetails => '檢視詳情';

  @override
  String get viewExportResultsButton => '檢視';

  @override
  String get visibility => '可見性';

  @override
  String get visible => '可見';

  @override
  String get visualProperties => '視覺屬性';

  @override
  String get visualSettings => '視覺設定';

  @override
  String get warningOverwriteData => '警告：這將覆寫目前所有資料！';

  @override
  String get warnings => '警告';

  @override
  String get widgetRefRequired => '需要 WidgetRef 才能建立 CollectionPainter';

  @override
  String get width => '寬度';

  @override
  String get windowButtonMaximize => '最大化';

  @override
  String get windowButtonMinimize => '最小化';

  @override
  String get windowButtonRestore => '還原';

  @override
  String get work => '作品';

  @override
  String get workBrowseSearch => '搜尋作品...';

  @override
  String get workBrowseTitle => '作品';

  @override
  String get workCount => '作品數量';

  @override
  String get workDetailCharacters => '字元';

  @override
  String get workDetailOtherInfo => '其他資訊';

  @override
  String get workDetailTitle => '作品詳情';

  @override
  String get workFormAuthorHelp => '可選，作品的創作者';

  @override
  String get workFormAuthorHint => '輸入作者名稱';

  @override
  String get workFormAuthorMaxLength => '作者名稱不能超過 50 個字元';

  @override
  String get workFormAuthorTooltip => '按 Ctrl+A 快速跳轉至作者欄位';

  @override
  String get workFormCreationDateError => '創作日期不能超過目前日期';

  @override
  String get workFormDateHelp => '作品的完成日期';

  @override
  String get workFormRemarkHelp => '可選，關於作品的附加資訊';

  @override
  String get workFormRemarkMaxLength => '備註不能超過 500 個字元';

  @override
  String get workFormRemarkTooltip => '按 Ctrl+R 快速跳轉至備註欄位';

  @override
  String get workFormStyleHelp => '作品的主要風格類型';

  @override
  String get workFormTitleHelp => '作品的主標題，顯示在作品清單中';

  @override
  String get workFormTitleMaxLength => '標題不能超過 100 個字元';

  @override
  String get workFormTitleMinLength => '標題必須至少 2 個字元';

  @override
  String get workFormTitleRequired => '標題為必填項';

  @override
  String get workFormTitleTooltip => '按 Ctrl+T 快速跳轉至標題欄位';

  @override
  String get workFormToolHelp => '創作此作品使用的主要工具';

  @override
  String get workIdCannotBeEmpty => '作品 ID 不能為空';

  @override
  String get workInfo => '作品資訊';

  @override
  String get workStyleClerical => '隸書';

  @override
  String get workStyleCursive => '草書';

  @override
  String get workStyleRegular => '楷書';

  @override
  String get workStyleRunning => '行書';

  @override
  String get workStyleSeal => '篆書';

  @override
  String get workToolBrush => '毛筆';

  @override
  String get workToolHardPen => '硬筆';

  @override
  String get workToolOther => '其他';

  @override
  String get works => '作品';

  @override
  String worksCount(Object count) {
    return '$count 個作品';
  }

  @override
  String get writingMode => '書寫模式';

  @override
  String get writingTool => '書寫工具';

  @override
  String get writingToolManagement => '書寫工具管理';

  @override
  String get writingToolText => '書寫工具';

  @override
  String get yes => '是';

  @override
  String get yesterday => '昨天';

  @override
  String get zipFile => 'ZIP 壓縮檔';

  @override
  String get backgroundTexture => '背景紋理';

  @override
  String get texturePreview => '紋理預覽';

  @override
  String get textureSize => '紋理尺寸';

  @override
  String get restoreDefaultSize => '恢復預設尺寸';

  @override
  String get alignment => '對齊方式';

  @override
  String get imageAlignment => '圖像對齊';

  @override
  String get imageSizeInfo => '圖像尺寸';

  @override
  String get imageNameInfo => '圖像名稱';

  @override
  String get rotationFineControl => '角度微調';

  @override
  String get rotateClockwise => '順時針旋轉';

  @override
  String get rotateCounterclockwise => '逆時針旋轉';

  @override
  String get degrees => '度';

  @override
  String get fineRotation => '精細旋轉';

  @override
  String get topLeft => '左上角';

  @override
  String get topCenter => '頂部置中';

  @override
  String get topRight => '右上角';

  @override
  String get centerLeft => '左側置中';

  @override
  String get centerRight => '右側置中';

  @override
  String get bottomLeft => '左下角';

  @override
  String get bottomCenter => '底部置中';

  @override
  String get bottomRight => '右下角';

  @override
  String get alignmentCenter => '中心';

  @override
  String get cropAdjustmentHint => '在上方預覽圖中拖拉選取框和控制點來調整裁剪區域';

  @override
  String get binarizationProcessing => '二值化處理';

  @override
  String get binarizationToggle => '二值化開關';

  @override
  String get binarizationParameters => '二值化參數';

  @override
  String get enableBinarization => '啟用二值化';

  @override
  String get binaryThreshold => '二值化閾值';

  @override
  String get noiseReductionToggle => '降噪開關';

  @override
  String get noiseReductionLevel => '降噪強度';
}
