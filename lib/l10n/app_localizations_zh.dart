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
  String get lineHeight => '行高';

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
}
