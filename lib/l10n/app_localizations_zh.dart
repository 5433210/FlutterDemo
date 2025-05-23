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
  String get addCategory => '添加分类';

  @override
  String get addedToCategory => '已添加到分类';

  @override
  String get adjustGridSize => '调整网格大小';

  @override
  String get alignBottom => '底对齐';

  @override
  String get alignCenter => '居中';

  @override
  String get alignHorizontalCenter => '水平居中';

  @override
  String get alignLeft => '左对齐';

  @override
  String get alignmentOperations => '对齐操作';

  @override
  String get alignmentRequiresMultipleElements => '对齐操作需要至少2个元素';

  @override
  String get alignMiddle => '居中';

  @override
  String get alignRight => '右对齐';

  @override
  String get alignTop => '顶对齐';

  @override
  String get alignVerticalCenter => '垂直居中';

  @override
  String get allCategories => '所有分类';

  @override
  String get allTypes => '所有类型';

  @override
  String get appName => '字字珠玑';

  @override
  String get appTitle => '字字珠玑';

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
  String get back => '返回';

  @override
  String get backgroundColor => '背景颜色';

  @override
  String get backupDescription => '描述（可选）';

  @override
  String get backupDescriptionHint => '输入此备份的描述';

  @override
  String get backupFailure => '创建备份失败';

  @override
  String get backupList => '备份列表';

  @override
  String get backupSettings => '备份与恢复';

  @override
  String get backupSuccess => '备份创建成功';

  @override
  String get basicInfo => '基本信息';

  @override
  String get batchOperations => '批量操作';

  @override
  String get bringLayerToFront => '图层置于顶层';

  @override
  String get bringToFront => '置于顶层';

  @override
  String get cacheClearedMessage => '缓存已成功清除';

  @override
  String get cacheSettings => '缓存设置';

  @override
  String get cacheSize => '缓存大小';

  @override
  String get cancel => '取消';

  @override
  String get canvasPixelSize => '画布像素大小';

  @override
  String get canvasResetView => '复位';

  @override
  String get canvasResetViewTooltip => '重置视图位置';

  @override
  String get categories => '分类';

  @override
  String categoryHasItems(Object count) {
    return '此分类下有 $count 个项目';
  }

  @override
  String get categoryManagement => '分类管理';

  @override
  String get categoryPanelTitle => '分类面板';

  @override
  String get center => '居中';

  @override
  String get characterCollectionBack => '返回';

  @override
  String characterCollectionDeleteBatchConfirm(Object count) {
    return '确认删除$count个已保存区域？';
  }

  @override
  String characterCollectionDeleteBatchMessage(Object count) {
    return '您即将删除$count个已保存区域。此操作无法撤消。';
  }

  @override
  String get characterCollectionDeleteConfirm => '确认删除';

  @override
  String get characterCollectionDeleteMessage => '您即将删除所选区域。此操作无法撤消。';

  @override
  String get characterCollectionDeleteShortcuts => '快捷键：Enter 确认，Esc 取消';

  @override
  String characterCollectionError(Object error) {
    return '错误：$error';
  }

  @override
  String get characterCollectionFilterAll => '全部';

  @override
  String get characterCollectionFilterFavorite => '收藏';

  @override
  String get characterCollectionFilterRecent => '最近';

  @override
  String characterCollectionFindSwitchFailed(Object error) {
    return '查找并切换页面失败：$error';
  }

  @override
  String get characterCollectionHelp => '帮助';

  @override
  String get characterCollectionHelpClose => '关闭';

  @override
  String get characterCollectionHelpExport => '导出帮助文档';

  @override
  String get characterCollectionHelpExportSoon => '帮助文档导出功能即将推出';

  @override
  String get characterCollectionHelpGuide => '字符采集指南';

  @override
  String get characterCollectionHelpIntro => '字符采集允许您从图像中提取、编辑和管理字符。以下是详细指南：';

  @override
  String get characterCollectionHelpNotes => '注意事项';

  @override
  String get characterCollectionHelpSection1 => '1. 选择与导航';

  @override
  String get characterCollectionHelpSection2 => '2. 区域调整';

  @override
  String get characterCollectionHelpSection3 => '3. 橡皮工具';

  @override
  String get characterCollectionHelpSection4 => '4. 数据保存';

  @override
  String get characterCollectionHelpSection5 => '5. 键盘快捷键';

  @override
  String get characterCollectionHelpTitle => '字符采集帮助';

  @override
  String get characterCollectionImageInvalid => '图像数据无效或已损坏';

  @override
  String get characterCollectionImageLoadError => '无法加载图像';

  @override
  String get characterCollectionLeave => '离开';

  @override
  String get characterCollectionLoadingImage => '加载图像中...';

  @override
  String get characterCollectionNextPage => '下一页';

  @override
  String get characterCollectionNoCharacter => '无字符';

  @override
  String get characterCollectionNoCharacters => '尚未采集字符';

  @override
  String get characterCollectionPreviewTab => '字符预览';

  @override
  String get characterCollectionPreviousPage => '上一页';

  @override
  String get characterCollectionProcessing => '处理中...';

  @override
  String get characterCollectionResultsTab => '采集结果';

  @override
  String get characterCollectionRetry => '重试';

  @override
  String get characterCollectionReturnToDetails => '返回作品详情';

  @override
  String get characterCollectionSearchHint => '搜索字符...';

  @override
  String get characterCollectionSelectRegion => '请在预览区域选择字符区域';

  @override
  String get characterCollectionSwitchingPage => '正在切换到字符页面...';

  @override
  String get characterCollectionTitle => '字符采集';

  @override
  String get characterCollectionToolDelete => '删除所选 (Ctrl+D)';

  @override
  String get characterCollectionToolPan => '平移工具 (Ctrl+V)';

  @override
  String get characterCollectionToolSelect => '选择工具 (Ctrl+B)';

  @override
  String get characterCollectionUnsavedChanges => '未保存的更改';

  @override
  String get characterCollectionUnsavedChangesMessage => '您有未保存的区域修改。离开将丢失这些更改。\n\n确定要离开吗？';

  @override
  String get characterCollectionUseSelectionTool => '使用左侧的选择工具从图像中提取字符';

  @override
  String get characterCount => '集字数量';

  @override
  String get characterDetailAddTag => '添加标签';

  @override
  String get characterDetailAuthor => '作者';

  @override
  String get characterDetailBasicInfo => '基本信息';

  @override
  String get characterDetailCalligraphyStyle => '书法风格';

  @override
  String get characterDetailCollectionTime => '采集时间';

  @override
  String get characterDetailCreationTime => '创作时间';

  @override
  String get characterDetailFormatBinary => '二值化';

  @override
  String get characterDetailFormatBinaryDesc => '黑白二值化图像';

  @override
  String get characterDetailFormatDescription => '描述';

  @override
  String get characterDetailFormatExtension => '文件格式';

  @override
  String get characterDetailFormatName => '格式名称';

  @override
  String get characterDetailFormatOriginal => '原始';

  @override
  String get characterDetailFormatOriginalDesc => '未经处理的原始图像';

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
  String get characterDetailFormatType => '类型';

  @override
  String get characterDetailLoadError => '加载字符详情失败';

  @override
  String get characterDetailSimplifiedChar => '简体字符';

  @override
  String characterDetailTagAddError(Object error) {
    return '添加标签失败: $error';
  }

  @override
  String get characterDetailTagHint => '输入标签名称';

  @override
  String characterDetailTagRemoveError(Object error) {
    return '移除标签失败, 错误: $error';
  }

  @override
  String get characterDetailTags => '标签';

  @override
  String get characterDetailUnknown => '未知';

  @override
  String get characterDetailWorkInfo => '作品信息';

  @override
  String get characterDetailWorkTitle => '作品标题';

  @override
  String get characterDetailWritingTool => '书写工具';

  @override
  String get characterEditBrushSize => '笔刷尺寸';

  @override
  String get characterEditCharacterUpdated => '「字符已更新';

  @override
  String get characterEditCompletingSave => '完成保存...';

  @override
  String get characterEditImageInvert => '图像反转';

  @override
  String get characterEditImageLoadError => '图像加载错误';

  @override
  String get characterEditImageLoadFailed => '加载或处理字符图像失败';

  @override
  String get characterEditInitializing => '初始化中...';

  @override
  String get characterEditInputCharacter => '输入字符';

  @override
  String get characterEditInputHint => '在此输入';

  @override
  String get characterEditInvertMode => '反转模式';

  @override
  String get characterEditLoadingImage => '加载字符图像中...';

  @override
  String get characterEditNoiseReduction => '降噪';

  @override
  String get characterEditNoRegionSelected => '未选择区域';

  @override
  String get characterEditOnlyOneCharacter => '只允许一个字符';

  @override
  String get characterEditPanImage => '平移图像（按住Alt）';

  @override
  String get characterEditPleaseEnterCharacter => '请输入字符';

  @override
  String get characterEditPreparingSave => '准备保存...';

  @override
  String get characterEditProcessingEraseData => '处理擦除数据...';

  @override
  String get characterEditProcessingImage => '处理图像中...';

  @override
  String get characterEditRedo => '重做';

  @override
  String get characterEditSaveComplete => '保存完成';

  @override
  String characterEditSaveConfirmMessage(Object character) {
    return '确认保存「$character」？';
  }

  @override
  String get characterEditSaveConfirmTitle => '保存字符';

  @override
  String get characterEditSavePreview => '字符预览：';

  @override
  String get characterEditSaveShortcuts => '按 Enter 保存，Esc 取消';

  @override
  String get characterEditSaveTimeout => '保存超时';

  @override
  String get characterEditSavingToStorage => '保存到存储中...';

  @override
  String get characterEditShowContour => '显示轮廓';

  @override
  String get characterEditThreshold => '阈值';

  @override
  String get characterEditThumbnailCheckFailed => '缩略图检查失败';

  @override
  String get characterEditThumbnailEmpty => '缩略图文件为空';

  @override
  String get characterEditThumbnailLoadError => '加载缩略图失败';

  @override
  String get characterEditThumbnailLoadFailed => '加载缩略图失败';

  @override
  String get characterEditThumbnailNotFound => '未找到缩略图';

  @override
  String get characterEditThumbnailSizeError => '获取缩略图大小失败';

  @override
  String get characterEditUndo => '撤销';

  @override
  String get characterEditUnknownError => '未知错误';

  @override
  String get characterEditValidChineseCharacter => '请输入有效的汉字';

  @override
  String get characterFilterAddTag => '添加标签';

  @override
  String get characterFilterAddTagHint => '输入标签名称并按 Enter';

  @override
  String get characterFilterCalligraphyStyle => '书法风格';

  @override
  String get characterFilterCollapse => '折叠筛选面板';

  @override
  String get characterFilterCollectionDate => '采集日期';

  @override
  String get characterFilterCreationDate => '创作日期';

  @override
  String get characterFilterExpand => '展开筛选面板';

  @override
  String get characterFilterFavoritesOnly => '仅显示收藏';

  @override
  String get characterFilterSelectedTags => '已选标签：';

  @override
  String get characterFilterSort => '排序';

  @override
  String get characterFilterTags => '标签';

  @override
  String get characterFilterTitle => '筛选与排序';

  @override
  String get characterFilterWritingTool => '书写工具';

  @override
  String get characterManagementBatchDone => '完成';

  @override
  String get characterManagementBatchMode => '批量模式';

  @override
  String get characterManagementDeleteConfirm => '确认删除';

  @override
  String get characterManagementDeleteMessage => '确定要删除选中的字符吗？此操作无法撤消。';

  @override
  String get characterManagementDeleteSelected => '删除所选';

  @override
  String characterManagementError(Object message) {
    return '错误：$message';
  }

  @override
  String get characterManagementGridView => '网格视图';

  @override
  String characterManagementItemsPerPage(Object count) {
    return '$count项/页';
  }

  @override
  String get characterManagementListView => '列表视图';

  @override
  String get characterManagementLoading => '加载字符中...';

  @override
  String get characterManagementNoCharacters => '未找到字符';

  @override
  String get characterManagementNoCharactersHint => '尝试更改搜索或筛选条件';

  @override
  String get characterManagementSearch => '搜索字符、作品或作者';

  @override
  String get characterManagementTitle => '集字';

  @override
  String get characters => '集字';

  @override
  String get clearCache => '清除缓存';

  @override
  String get clearCacheConfirmMessage => '确定要清除所有缓存数据吗？这将释放磁盘空间，但可能会暂时降低应用程序的速度。';

  @override
  String get clearCacheConfirmTitle => '清除缓存';

  @override
  String get clearImageCache => '清除图像缓存';

  @override
  String get clearSelection => '取消选择';

  @override
  String get collection => '集字';

  @override
  String get collectionPropertyPanel => '采集属性';

  @override
  String get collectionPropertyPanelAutoLineBreak => '自动换行';

  @override
  String get collectionPropertyPanelAutoLineBreakDisabled => '已禁用自动换行';

  @override
  String get collectionPropertyPanelAutoLineBreakEnabled => '已启用自动换行';

  @override
  String get collectionPropertyPanelAutoLineBreakTooltip => '自动换行';

  @override
  String get collectionPropertyPanelAvailableCharacters => '可用字符';

  @override
  String get collectionPropertyPanelBackgroundColor => '背景颜色';

  @override
  String get collectionPropertyPanelBorder => '边框';

  @override
  String get collectionPropertyPanelBorderColor => '边框颜色';

  @override
  String get collectionPropertyPanelBorderWidth => '边框宽度';

  @override
  String get collectionPropertyPanelCacheCleared => '图像缓存已清除';

  @override
  String get collectionPropertyPanelCacheClearFailed => '清除图像缓存失败';

  @override
  String get collectionPropertyPanelCandidateCharacters => '候选字符';

  @override
  String get collectionPropertyPanelCharacter => '集字';

  @override
  String get collectionPropertyPanelCharacterSettings => '字符设置';

  @override
  String get collectionPropertyPanelCharacterSource => '字符来源';

  @override
  String get collectionPropertyPanelCharIndex => '字符';

  @override
  String get collectionPropertyPanelClearImageCache => '清除图像缓存';

  @override
  String get collectionPropertyPanelColorInversion => '颜色反转';

  @override
  String get collectionPropertyPanelColorPicker => '颜色选择器';

  @override
  String get collectionPropertyPanelColorSettings => '颜色设置';

  @override
  String get collectionPropertyPanelContent => '内容属性';

  @override
  String get collectionPropertyPanelCurrentCharInversion => '当前字符反转';

  @override
  String get collectionPropertyPanelDisabled => '已禁用';

  @override
  String get collectionPropertyPanelEnabled => '已启用';

  @override
  String get collectionPropertyPanelFlip => '翻转';

  @override
  String get collectionPropertyPanelFlipHorizontally => '水平翻转';

  @override
  String get collectionPropertyPanelFlipVertically => '垂直翻转';

  @override
  String get collectionPropertyPanelFontSize => '字体大小';

  @override
  String get collectionPropertyPanelGeometry => '几何属性';

  @override
  String get collectionPropertyPanelGlobalInversion => '全局反转';

  @override
  String get collectionPropertyPanelHeaderContent => '内容属性';

  @override
  String get collectionPropertyPanelHeaderGeometry => '几何属性';

  @override
  String get collectionPropertyPanelHeaderVisual => '视觉属性';

  @override
  String get collectionPropertyPanelInvertDisplay => '反转显示颜色';

  @override
  String get collectionPropertyPanelNoCharacterSelected => '未选择字符';

  @override
  String get collectionPropertyPanelNoCharactersFound => '未找到匹配的字符';

  @override
  String get collectionPropertyPanelNoCharacterText => '无字符';

  @override
  String get collectionPropertyPanelOf => '/';

  @override
  String get collectionPropertyPanelOpacity => '不透明度';

  @override
  String get collectionPropertyPanelOriginal => '原始';

  @override
  String get collectionPropertyPanelPadding => '内边距';

  @override
  String get collectionPropertyPanelPropertyUpdated => '属性已更新';

  @override
  String get collectionPropertyPanelRender => '渲染模式';

  @override
  String get collectionPropertyPanelReset => '重置';

  @override
  String get collectionPropertyPanelRotation => '旋转';

  @override
  String get collectionPropertyPanelScale => '缩放';

  @override
  String get collectionPropertyPanelSearchInProgress => '搜索字符中...';

  @override
  String get collectionPropertyPanelSelectCharacter => '请选择字符';

  @override
  String get collectionPropertyPanelSelectCharacterFirst => '请先选择字符';

  @override
  String get collectionPropertyPanelSelectedCharacter => '已选字符';

  @override
  String get collectionPropertyPanelStyle => '样式';

  @override
  String get collectionPropertyPanelStyled => '样式化';

  @override
  String get collectionPropertyPanelTextSettings => '文本设置';

  @override
  String get collectionPropertyPanelUnknown => '未知';

  @override
  String get collectionPropertyPanelVisual => '视觉设置';

  @override
  String get collectionPropertyPanelWorkSource => '作品来源';

  @override
  String get commonProperties => '通用属性';

  @override
  String get confirm => '确认';

  @override
  String get confirmDelete => '确认删除？';

  @override
  String get confirmDeleteCategory => '确认删除分类';

  @override
  String get contains => '包含';

  @override
  String get contentSettings => '内容设置';

  @override
  String get create => '创建';

  @override
  String get createBackup => '创建备份';

  @override
  String get createBackupDescription => '创建新的数据备份';

  @override
  String get creatingBackup => '正在创建备份...';

  @override
  String get customSize => '自定义大小';

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
  String get delete => '删除';

  @override
  String get deleteAll => '删除全部';

  @override
  String get deleteBackup => '删除';

  @override
  String get deleteBackupConfirmMessage => '确定要删除此备份吗？此操作无法撤消。';

  @override
  String get deleteBackupConfirmTitle => '删除备份';

  @override
  String get deleteCategory => '删除分类';

  @override
  String get deleteCategoryOnly => '仅删除分类';

  @override
  String get deleteCategoryWithFiles => '删除分类及文件';

  @override
  String deleteCategoryWithFilesConfirmMessage(Object count, Object name) {
    return '确定要删除分类\"$name\"及其包含的$count个文件？此操作无法撤销！';
  }

  @override
  String get deleteCategoryWithFilesWarning => '警告';

  @override
  String get deleteFailure => '备份删除失败';

  @override
  String get deleteGroup => '删除组';

  @override
  String get deleteGroupConfirm => '确认删除组';

  @override
  String get deleteGroupDescription => '确定要删除此组吗？此操作无法撤消。';

  @override
  String get deleteGroupElements => '删除组内元素';

  @override
  String get deletePage => '删除页面';

  @override
  String get deleteSuccess => '备份删除成功';

  @override
  String get dimensions => '尺寸';

  @override
  String get diskCacheSize => '磁盘缓存大小';

  @override
  String get diskCacheSizeDescription => '磁盘缓存的最大大小';

  @override
  String get diskCacheTtl => '磁盘缓存生命周期';

  @override
  String get diskCacheTtlDescription => '缓存文件在磁盘上保留的时间';

  @override
  String get distributeHorizontally => '水平均匀分布';

  @override
  String get distributeVertically => '垂直均匀分布';

  @override
  String get distribution => '分布';

  @override
  String get distributionOperations => '分布操作';

  @override
  String get distributionRequiresThreeElements => '分布操作需要至少3个元素';

  @override
  String get edit => '编辑';

  @override
  String get editCategory => '编辑分类';

  @override
  String get editGroupContents => '编辑组内容';

  @override
  String get editGroupContentsDescription => '编辑已选组的内容';

  @override
  String get elementDistribution => '元素分布';

  @override
  String get elementId => '元素ID';

  @override
  String get elements => '元素';

  @override
  String get elementType => '元素类型';

  @override
  String get empty => '空';

  @override
  String get enterFileName => '输入文件名';

  @override
  String get enterGroupEditMode => '进入组编辑模式';

  @override
  String get exitBatchMode => '退出批量模式';

  @override
  String get export => '导出';

  @override
  String get exportBackup => '导出备份';

  @override
  String get exportBackupDescription => '将备份导出到外部位置';

  @override
  String get exportDialogAllPages => '全部页面';

  @override
  String get exportDialogBrowse => '浏览...';

  @override
  String get exportDialogCentimeter => '厘米';

  @override
  String get exportDialogCreateDirectoryFailed => '创建导出目录失败';

  @override
  String get exportDialogCurrentPage => '当前页面';

  @override
  String get exportDialogCustomRange => '自定义范围';

  @override
  String exportDialogDimensions(Object height, Object orientation, Object width) {
    return '$width厘米 × $height厘米 ($orientation)';
  }

  @override
  String get exportDialogEnterFilename => '请输入文件名';

  @override
  String get exportDialogFilenamePrefix => '输入文件名前缀（将自动添加页码）';

  @override
  String get exportDialogFitContain => '包含在页面内';

  @override
  String get exportDialogFitHeight => '适合高度';

  @override
  String get exportDialogFitPolicy => '适配方式';

  @override
  String get exportDialogFitWidth => '适合宽度';

  @override
  String get exportDialogInvalidFilename => '文件名不能包含以下字符: \\ / : * ? \" < > |';

  @override
  String get exportDialogLandscape => '横向';

  @override
  String get exportDialogLocation => '导出位置';

  @override
  String get exportDialogMarginBottom => '下';

  @override
  String get exportDialogMarginLeft => '左';

  @override
  String get exportDialogMarginRight => '右';

  @override
  String get exportDialogMarginTop => '上';

  @override
  String exportDialogMultipleFilesNote(Object count) {
    return '注意: 将导出 $count 个图片文件，文件名将自动添加页码。';
  }

  @override
  String get exportDialogNextPage => '下一页';

  @override
  String get exportDialogNoPreview => '无法生成预览';

  @override
  String get exportDialogOutputQuality => '输出质量';

  @override
  String get exportDialogPageMargins => '页面边距 (厘米)';

  @override
  String get exportDialogPageOrientation => '页面朝向';

  @override
  String get exportDialogPageRange => '页面范围';

  @override
  String get exportDialogPageSize => '页面大小';

  @override
  String get exportDialogPortrait => '纵向';

  @override
  String get exportDialogPreview => '预览';

  @override
  String exportDialogPreviewPage(Object current, Object total) {
    return ' (第 $current/$total 页)';
  }

  @override
  String get exportDialogPreviousPage => '上一页';

  @override
  String get exportDialogQualityHigh => '高清 (2x)';

  @override
  String get exportDialogQualityStandard => '标准 (1x)';

  @override
  String get exportDialogQualityUltra => '超清 (3x)';

  @override
  String get exportDialogRangeExample => '例如: 1-3,5,7-9';

  @override
  String get exportDialogSelectLocation => '请选择导出位置';

  @override
  String get exportFailure => '备份导出失败';

  @override
  String get exportFormat => '导出格式';

  @override
  String get exportingBackup => '导出备份中...';

  @override
  String get exportSuccess => '备份导出成功';

  @override
  String get fileCount => '文件数量';

  @override
  String get fileName => '文件名';

  @override
  String get files => '文件数量';

  @override
  String get filterApply => '应用';

  @override
  String get filterBatchActions => '批量操作';

  @override
  String get filterBatchSelection => '批量选择';

  @override
  String get filterClear => '清除';

  @override
  String get filterCollapse => '收起筛选面板';

  @override
  String get filterCustomRange => '自定义范围';

  @override
  String get filterDateApply => '应用';

  @override
  String get filterDateClear => '清除';

  @override
  String get filterDateCustom => '自定义';

  @override
  String get filterDateEndDate => '结束日期';

  @override
  String get filterDatePresetAll => '全部时间';

  @override
  String get filterDatePresetLast30Days => '最近30天';

  @override
  String get filterDatePresetLast365Days => '最近365天';

  @override
  String get filterDatePresetLast7Days => '最近7天';

  @override
  String get filterDatePresetLast90Days => '最近90天';

  @override
  String get filterDatePresetLastMonth => '上个月';

  @override
  String get filterDatePresetLastWeek => '上周';

  @override
  String get filterDatePresetLastYear => '去年';

  @override
  String get filterDatePresets => '预设';

  @override
  String get filterDatePresetThisMonth => '本月';

  @override
  String get filterDatePresetThisWeek => '本周';

  @override
  String get filterDatePresetThisYear => '今年';

  @override
  String get filterDatePresetToday => '今天';

  @override
  String get filterDatePresetYesterday => '昨天';

  @override
  String get filterDateRange => '日期范围';

  @override
  String get filterDateSection => '创建时间';

  @override
  String get filterDateSelectPrompt => '选择日期';

  @override
  String get filterDateStartDate => '开始日期';

  @override
  String get filterDeselectAll => '取消全选';

  @override
  String get filterEndDate => '结束日期';

  @override
  String get filterExpand => '展开筛选面板';

  @override
  String get filterFavoritesOnly => '仅显示收藏';

  @override
  String get filterHeader => '筛选';

  @override
  String filterItemsPerPage(Object count) {
    return '每页 $count 项';
  }

  @override
  String filterItemsSelected(Object count) {
    return '已选择 $count 项';
  }

  @override
  String get filterMax => '最大';

  @override
  String get filterMin => '最小';

  @override
  String get filterPanel => '筛选面板';

  @override
  String get filterPresetSection => '预设';

  @override
  String get filterReset => '重置筛选';

  @override
  String get filterSearchPlaceholder => '搜索...';

  @override
  String get filterSection => '筛选选项';

  @override
  String get filterSelectAll => '全选';

  @override
  String get filterSelectDate => '选择日期';

  @override
  String get filterSelectDateRange => '选择日期范围';

  @override
  String get filterSortAscending => '升序';

  @override
  String get filterSortDescending => '降序';

  @override
  String get filterSortDirection => '排序方向';

  @override
  String get filterSortField => '排序字段';

  @override
  String get filterSortFieldAuthor => '作者';

  @override
  String get filterSortFieldCreateTime => '创建时间';

  @override
  String get filterSortFieldCreationDate => '创作日期';

  @override
  String get filterSortFieldFileName => '文件名称';

  @override
  String get filterSortFieldFileSize => '文件大小';

  @override
  String get filterSortFieldFileUpdatedAt => '文件修改时间';

  @override
  String get filterSortFieldNone => '无';

  @override
  String get filterSortFieldStyle => '风格';

  @override
  String get filterSortFieldTitle => '标题';

  @override
  String get filterSortFieldTool => '工具';

  @override
  String get filterSortFieldUpdateTime => '更新时间';

  @override
  String get filterSortSection => '排序';

  @override
  String get filterStartDate => '开始日期';

  @override
  String get filterStyleClerical => '隶书';

  @override
  String get filterStyleCursive => '草书';

  @override
  String get filterStyleOther => '其他';

  @override
  String get filterStyleRegular => '楷书';

  @override
  String get filterStyleRunning => '行书';

  @override
  String get filterStyleSeal => '篆书';

  @override
  String get filterStyleSection => '书法风格';

  @override
  String get filterTagsAdd => '添加标签';

  @override
  String get filterTagsAddHint => '输入标签名称并按回车';

  @override
  String get filterTagsNone => '未选择标签';

  @override
  String get filterTagsSection => '标签';

  @override
  String get filterTagsSelected => '已选标签：';

  @override
  String get filterTagsSuggested => '推荐标签：';

  @override
  String get filterTitle => '筛选与排序';

  @override
  String get filterToggle => '切换筛选';

  @override
  String get filterToolBrush => '毛笔';

  @override
  String get filterToolHardPen => '硬笔';

  @override
  String get filterToolOther => '其他';

  @override
  String get filterToolSection => '书写工具';

  @override
  String filterTotalItems(Object count) {
    return '共计：$count 项';
  }

  @override
  String get generalSettings => '常规设置';

  @override
  String get geometryProperties => '几何属性';

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
  String get group => '组合';

  @override
  String get groupElements => '组合元素';

  @override
  String get groupInfo => '组信息';

  @override
  String get groupOperations => '组合操作';

  @override
  String get height => '高度';

  @override
  String get hideElement => '隐藏元素';

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
  String get image => '图片';

  @override
  String get imageCacheCleared => '图像缓存已清除';

  @override
  String get imageCacheClearFailed => '清除图像缓存失败';

  @override
  String get imagePropertyPanel => '图像属性';

  @override
  String get imagePropertyPanelApplyTransform => '应用变换';

  @override
  String get imagePropertyPanelAutoImportNotice => '所选图像将自动导入到您的图库中以便更好地管理';

  @override
  String get imagePropertyPanelBorder => '边框';

  @override
  String get imagePropertyPanelBorderColor => '边框颜色';

  @override
  String get imagePropertyPanelBorderWidth => '边框宽度';

  @override
  String get imagePropertyPanelBrightness => '亮度';

  @override
  String get imagePropertyPanelCannotApplyNoImage => '没有可用的图片';

  @override
  String get imagePropertyPanelCannotApplyNoSizeInfo => '无法获取图片尺寸信息';

  @override
  String get imagePropertyPanelContent => '内容属性';

  @override
  String get imagePropertyPanelContrast => '对比度';

  @override
  String get imagePropertyPanelCornerRadius => '圆角半径';

  @override
  String get imagePropertyPanelCropBottom => '底部裁剪';

  @override
  String get imagePropertyPanelCropLeft => '左侧裁剪';

  @override
  String get imagePropertyPanelCropping => '裁剪';

  @override
  String imagePropertyPanelCroppingApplied(Object bottom, Object left, Object right, Object top) {
    return ' (裁剪：左${left}px，上${top}px，右${right}px，下${bottom}px)';
  }

  @override
  String get imagePropertyPanelCroppingValueTooLarge => '无法应用变换：裁剪值过大，导致无效的裁剪区域';

  @override
  String get imagePropertyPanelCropRight => '右侧裁剪';

  @override
  String get imagePropertyPanelCropTop => '顶部裁剪';

  @override
  String get imagePropertyPanelDimensions => '尺寸';

  @override
  String get imagePropertyPanelDisplay => '显示模式';

  @override
  String imagePropertyPanelErrorMessage(Object error) {
    return '发生错误: $error';
  }

  @override
  String imagePropertyPanelFileLoadError(Object error) {
    return '文件加载失败';
  }

  @override
  String imagePropertyPanelFileNotExist(Object path) {
    return '文件不存在：$path';
  }

  @override
  String get imagePropertyPanelFileNotRecovered => '图片文件丢失且无法恢复';

  @override
  String get imagePropertyPanelFileRestored => '图片已从图库中恢复';

  @override
  String get imagePropertyPanelFilters => '图像滤镜';

  @override
  String get imagePropertyPanelFit => '适应';

  @override
  String get imagePropertyPanelFitContain => '包含';

  @override
  String get imagePropertyPanelFitCover => '覆盖';

  @override
  String get imagePropertyPanelFitFill => '填充';

  @override
  String get imagePropertyPanelFitMode => '适应模式';

  @override
  String get imagePropertyPanelFitNone => '无';

  @override
  String get imagePropertyPanelFitOriginal => '原始';

  @override
  String get imagePropertyPanelFlip => '翻转';

  @override
  String get imagePropertyPanelFlipHorizontal => '水平翻转';

  @override
  String get imagePropertyPanelFlipVertical => '垂直翻转';

  @override
  String get imagePropertyPanelGeometry => '几何属性';

  @override
  String get imagePropertyPanelGeometryWarning => '这些属性调整整个元素框，而不是图像内容本身';

  @override
  String get imagePropertyPanelImageSelection => '图片选择';

  @override
  String get imagePropertyPanelImageSize => '图像大小';

  @override
  String get imagePropertyPanelImageTransform => '图像变换';

  @override
  String imagePropertyPanelImportError(Object error) {
    return '导入图像失败：$error';
  }

  @override
  String get imagePropertyPanelImporting => '导入图像中...';

  @override
  String get imagePropertyPanelImportSuccess => '图像导入成功';

  @override
  String get imagePropertyPanelLibraryProcessing => '图库功能开发中...';

  @override
  String imagePropertyPanelLoadError(Object error) {
    return '加载图像失败：$error...';
  }

  @override
  String get imagePropertyPanelLoading => '加载中...';

  @override
  String get imagePropertyPanelNoCropping => '（无裁剪）';

  @override
  String get imagePropertyPanelNoImage => '未选择图像';

  @override
  String get imagePropertyPanelNoImageSelected => '未选择图片';

  @override
  String get imagePropertyPanelOpacity => '不透明度';

  @override
  String get imagePropertyPanelOriginalSize => '原始大小';

  @override
  String get imagePropertyPanelPosition => '位置';

  @override
  String get imagePropertyPanelPreserveRatio => '保持宽高比';

  @override
  String get imagePropertyPanelPreview => '图像预览';

  @override
  String get imagePropertyPanelPreviewNotice => '注意：预览期间显示的重复日志是正常的';

  @override
  String imagePropertyPanelProcessingPathError(Object error) {
    return '处理路径错误：$error';
  }

  @override
  String get imagePropertyPanelReset => '重置';

  @override
  String get imagePropertyPanelResetSuccess => '重置成功';

  @override
  String get imagePropertyPanelResetTransform => '重置变换';

  @override
  String get imagePropertyPanelRotation => '旋转';

  @override
  String get imagePropertyPanelSaturation => '饱和度';

  @override
  String get imagePropertyPanelSelectFromLibrary => '从图库选择';

  @override
  String get imagePropertyPanelSelectFromLocal => '从本地选择';

  @override
  String get imagePropertyPanelSelectFromLocalDescription => '选择的图片将会自动导入到图库';

  @override
  String get imagePropertyPanelTitle => '图片属性';

  @override
  String get imagePropertyPanelTransformApplied => '变换已应用';

  @override
  String imagePropertyPanelTransformError(Object error) {
    return '应用变换失败：$error';
  }

  @override
  String get imagePropertyPanelTransformWarning => '这些变换会修改图像内容本身，而不仅仅是元素框架';

  @override
  String get imagePropertyPanelVisual => '视觉设置';

  @override
  String get import => '导入';

  @override
  String get importBackup => '导入备份';

  @override
  String get importBackupDescription => '从外部位置导入备份';

  @override
  String get importFailure => '备份导入失败';

  @override
  String get importingBackup => '正在导入备份...';

  @override
  String get importSuccess => '备份导入成功';

  @override
  String initializationFailed(Object error) {
    return '初始化失败：$error';
  }

  @override
  String get invalidBackupFile => '无效的备份文件';

  @override
  String get keepBackupCount => '保留备份数量';

  @override
  String get keepBackupCountDescription => '删除旧备份前保留的备份数量';

  @override
  String get landscape => '横向';

  @override
  String get language => '语言';

  @override
  String get languageEn => 'English';

  @override
  String get languageSystem => '系统';

  @override
  String get languageZh => '简体中文';

  @override
  String get lastBackupTime => '上次备份时间';

  @override
  String get layer => '图层';

  @override
  String get layer1 => '图层 1';

  @override
  String get layerElements => '图层元素';

  @override
  String get layerInfo => '图层信息';

  @override
  String get layerName => '图层名称';

  @override
  String get layerOperations => '图层操作';

  @override
  String get libraryCount => '图库数量';

  @override
  String get libraryManagement => '图库';

  @override
  String get libraryManagementBasicInfo => '基本信息';

  @override
  String get libraryManagementCategories => '分类';

  @override
  String get libraryManagementCreatedAt => '创建时间';

  @override
  String get libraryManagementDeleteConfirm => '确认删除';

  @override
  String get libraryManagementDeleteMessage => '确定要删除选中的项目吗？此操作不可恢复。';

  @override
  String get libraryManagementDeleteSelected => '删除选中项目';

  @override
  String get libraryManagementDetail => '详情';

  @override
  String get libraryManagementEnterBatchMode => '进入批量选择模式';

  @override
  String libraryManagementError(Object message) {
    return '加载失败：$message';
  }

  @override
  String get libraryManagementExitBatchMode => '退出批量选择模式';

  @override
  String get libraryManagementFavorite => '收藏';

  @override
  String get libraryManagementFavorites => '收藏';

  @override
  String get libraryManagementFileSize => '文件大小';

  @override
  String get libraryManagementFormat => '格式';

  @override
  String get libraryManagementFormats => '格式';

  @override
  String get libraryManagementGridView => '网格视图';

  @override
  String get libraryManagementImport => '导入';

  @override
  String get libraryManagementImportFiles => '导入文件';

  @override
  String get libraryManagementImportFolder => '导入文件夹';

  @override
  String get libraryManagementListView => '列表视图';

  @override
  String get libraryManagementLoading => '加载中...';

  @override
  String get libraryManagementLocation => '位置';

  @override
  String get libraryManagementMetadata => '元数据';

  @override
  String get libraryManagementName => '名称';

  @override
  String get libraryManagementNoItems => '暂无项目';

  @override
  String get libraryManagementNoItemsHint => '尝试添加一些项目或更改筛选条件';

  @override
  String get libraryManagementNoRemarks => '无备注';

  @override
  String get libraryManagementPath => '路径';

  @override
  String get libraryManagementRemarks => '备注';

  @override
  String get libraryManagementRemarksHint => '添加备注信息';

  @override
  String get libraryManagementResolution => '分辨率';

  @override
  String get libraryManagementSearch => '搜索项目...';

  @override
  String get libraryManagementSize => '尺寸';

  @override
  String get libraryManagementSizeHeight => '高度';

  @override
  String get libraryManagementSizeWidth => '宽度';

  @override
  String get libraryManagementSortBy => '排序方式';

  @override
  String get libraryManagementSortByDate => '按日期';

  @override
  String get libraryManagementSortByFileSize => '按文件大小';

  @override
  String get libraryManagementSortByName => '按名称';

  @override
  String get libraryManagementSortBySize => '按文件大小';

  @override
  String get libraryManagementSortDesc => '降序';

  @override
  String get libraryManagementTags => '标签';

  @override
  String get libraryManagementTimeInfo => '时间信息';

  @override
  String get libraryManagementType => '类型';

  @override
  String get libraryManagementTypes => '类型';

  @override
  String get libraryManagementUpdatedAt => '更新时间';

  @override
  String get listView => '列表视图';

  @override
  String get loadFailed => '加载失败';

  @override
  String get loadingError => '加载错误';

  @override
  String get locked => '已锁定';

  @override
  String get lockElement => '锁定元素';

  @override
  String get lockStatus => '锁定状态';

  @override
  String get lockUnlockAllElements => '锁定/解锁所有元素';

  @override
  String get memoryDataCacheCapacity => '内存数据缓存容量';

  @override
  String get memoryDataCacheCapacityDescription => '内存中保留的数据项数量';

  @override
  String get memoryImageCacheCapacity => '内存图像缓存容量';

  @override
  String get memoryImageCacheCapacityDescription => '内存中保留的图像数量';

  @override
  String get moveDown => '下移';

  @override
  String get moveLayerDown => '图层下移';

  @override
  String get moveLayerUp => '图层上移';

  @override
  String get moveSelectedElementsToLayer => '移动选中元素到图层';

  @override
  String get moveUp => '上移';

  @override
  String get name => '名称';

  @override
  String get navCollapseSidebar => '收起侧边栏';

  @override
  String get navExpandSidebar => '展开侧边栏';

  @override
  String get newCategory => '新建分类';

  @override
  String get nextImage => '下一张图片';

  @override
  String get no => '否';

  @override
  String get noBackups => '没有可用的备份';

  @override
  String get noCategories => '无分类';

  @override
  String get noElementsInLayer => '此图层中没有元素';

  @override
  String get noElementsSelected => '未选择元素';

  @override
  String get noPageSelected => '未选择页面';

  @override
  String get noTags => '无标签';

  @override
  String get ok => '确定';

  @override
  String get opacity => '不透明度';

  @override
  String get pageOrientation => '页面方向';

  @override
  String get pageSize => '页面大小';

  @override
  String get pixels => '像素';

  @override
  String get portrait => '纵向';

  @override
  String get position => '位置';

  @override
  String get ppiHelperText => '用于计算画布像素大小，默认300ppi';

  @override
  String get ppiSetting => 'PPI设置（每英寸像素数）';

  @override
  String get practiceEditAddElementTitle => '添加元素';

  @override
  String get practiceEditAddLayer => '添加图层';

  @override
  String get practiceEditBackToHome => '返回首页';

  @override
  String get practiceEditBringToFront => '置于顶层 (Ctrl+T)';

  @override
  String get practiceEditCannotSaveNoPages => '无法保存：字帖无页面';

  @override
  String get practiceEditCollection => '采集';

  @override
  String get practiceEditCollectionProperties => '采集属性';

  @override
  String get practiceEditConfirmDeleteMessage => '确定要删除这些元素吗？';

  @override
  String get practiceEditConfirmDeleteTitle => '确认删除';

  @override
  String get practiceEditContentProperties => '内容属性';

  @override
  String get practiceEditContentTools => '内容工具';

  @override
  String get practiceEditCopy => '复制 (Ctrl+Shift+C)';

  @override
  String get practiceEditDangerZone => '危险区域';

  @override
  String get practiceEditDelete => '删除 (Ctrl+D)';

  @override
  String get practiceEditDeleteLayer => '删除图层';

  @override
  String get practiceEditDeleteLayerConfirm => '确定要删除此图层吗？';

  @override
  String get practiceEditDeleteLayerMessage => '此图层上的所有元素将被删除。此操作无法撤消。';

  @override
  String get practiceEditDisableSnap => '禁用对齐 (Ctrl+R)';

  @override
  String get practiceEditEditOperations => '编辑操作';

  @override
  String get practiceEditEditTitle => '编辑标题';

  @override
  String get practiceEditElementProperties => '元素属性';

  @override
  String get practiceEditElements => '元素';

  @override
  String practiceEditElementSelectionInfo(Object count) {
    return '已选择$count个元素';
  }

  @override
  String get practiceEditEnableSnap => '启用对齐 (Ctrl+R)';

  @override
  String get practiceEditEnterTitle => '请输入字帖标题';

  @override
  String get practiceEditExit => '退出';

  @override
  String get practiceEditGeometryProperties => '几何属性';

  @override
  String get practiceEditGroup => '组合 (Ctrl+J)';

  @override
  String get practiceEditGroupProperties => '组属性';

  @override
  String get practiceEditHelperFunctions => '辅助功能';

  @override
  String get practiceEditHideGrid => '隐藏网格 (Ctrl+G)';

  @override
  String get practiceEditImage => '图像';

  @override
  String get practiceEditImageProperties => '图像属性';

  @override
  String get practiceEditLayerOperations => '图层操作';

  @override
  String get practiceEditLayerPanel => '图层';

  @override
  String get practiceEditLayerProperties => '图层属性';

  @override
  String get practiceEditLeave => '离开';

  @override
  String practiceEditLoadFailed(Object error) {
    return '加载字帖失败：$error';
  }

  @override
  String get practiceEditMoveDown => '下移 (Ctrl+Shift+B)';

  @override
  String get practiceEditMoveUp => '上移 (Ctrl+Shift+T)';

  @override
  String get practiceEditMultiSelectionProperties => '多选属性';

  @override
  String get practiceEditNoLayers => '无图层，请添加图层';

  @override
  String get practiceEditOverwrite => '覆盖';

  @override
  String get practiceEditPageProperties => '页面属性';

  @override
  String get practiceEditPaste => '粘贴 (Ctrl+Shift+V)';

  @override
  String practiceEditPracticeLoaded(Object title) {
    return '字帖\"$title\"加载成功';
  }

  @override
  String get practiceEditPracticeLoadFailed => '加载字帖失败：字帖不存在或已被删除';

  @override
  String get practiceEditPracticeTitle => '字帖标题';

  @override
  String get practiceEditPropertyPanel => '属性';

  @override
  String get practiceEditSaveAndExit => '保存并退出';

  @override
  String get practiceEditSaveAndLeave => '保存并离开';

  @override
  String get practiceEditSaveFailed => '保存失败';

  @override
  String get practiceEditSavePractice => '保存字帖';

  @override
  String get practiceEditSaveSuccess => '保存成功';

  @override
  String get practiceEditSelect => '选择';

  @override
  String get practiceEditSendToBack => '置于底层 (Ctrl+B)';

  @override
  String get practiceEditShowGrid => '显示网格 (Ctrl+G)';

  @override
  String get practiceEditText => '文本';

  @override
  String get practiceEditTextProperties => '文本属性';

  @override
  String get practiceEditTitle => '字帖编辑';

  @override
  String get practiceEditTitleExists => '标题已存在';

  @override
  String get practiceEditTitleExistsMessage => '已存在同名字帖。是否覆盖？';

  @override
  String practiceEditTitleUpdated(Object title) {
    return '标题已更新为\"$title\"';
  }

  @override
  String get practiceEditToolbar => '编辑工具栏';

  @override
  String get practiceEditTopNavBack => '返回';

  @override
  String get practiceEditTopNavExitPreview => '退出预览模式';

  @override
  String get practiceEditTopNavExport => '导出';

  @override
  String get practiceEditTopNavHideThumbnails => '隐藏页面缩略图';

  @override
  String get practiceEditTopNavPreviewMode => '预览模式';

  @override
  String get practiceEditTopNavRedo => '重做';

  @override
  String get practiceEditTopNavSave => '保存';

  @override
  String get practiceEditTopNavSaveAs => '另存为';

  @override
  String get practiceEditTopNavShowThumbnails => '显示页面缩略图';

  @override
  String get practiceEditTopNavUndo => '撤销';

  @override
  String get practiceEditUngroup => '取消组合 (Ctrl+U)';

  @override
  String get practiceEditUnsavedChanges => '未保存的更改';

  @override
  String get practiceEditUnsavedChangesExitConfirmation => '您有未保存的更改。确定要退出吗？';

  @override
  String get practiceEditUnsavedChangesMessage => '您有未保存的更改。确定要离开吗？';

  @override
  String get practiceEditVisualProperties => '视觉属性';

  @override
  String get practiceListBatchDone => '完成';

  @override
  String get practiceListBatchMode => '批量模式';

  @override
  String get practiceListCollapseFilter => '折叠过滤面板';

  @override
  String get practiceListDeleteConfirm => '确认删除';

  @override
  String get practiceListDeleteMessage => '确定要删除选中的字帖吗？此操作无法撤消。';

  @override
  String get practiceListDeleteSelected => '删除所选';

  @override
  String get practiceListError => '加载字帖错误';

  @override
  String get practiceListExpandFilter => '展开过滤面板';

  @override
  String get practiceListFilterFavorites => '收藏';

  @override
  String get practiceListFilterTitle => '字帖过滤';

  @override
  String get practiceListGridView => '网格视图';

  @override
  String practiceListItemsPerPage(Object count) {
    return '每页$count个';
  }

  @override
  String get practiceListListView => '列表视图';

  @override
  String get practiceListLoading => '加载字帖中...';

  @override
  String get practiceListNewPractice => '新建字帖';

  @override
  String get practiceListNoResults => '未找到字帖';

  @override
  String get practiceListPages => '页';

  @override
  String get practiceListResetFilter => '重置过滤器';

  @override
  String get practiceListSearch => '搜索字帖...';

  @override
  String get practiceListSortByCreateTime => '按创建时间排序';

  @override
  String get practiceListSortByStatus => '按状态排序';

  @override
  String get practiceListSortByTitle => '按标题排序';

  @override
  String get practiceListSortByUpdateTime => '按更新时间排序';

  @override
  String get practiceListStatus => '状态';

  @override
  String get practiceListStatusAll => '全部';

  @override
  String get practiceListStatusCompleted => '已完成';

  @override
  String get practiceListStatusDraft => '草稿';

  @override
  String get practiceListThumbnailError => '缩略图加载失败';

  @override
  String get practiceListTitle => '字帖';

  @override
  String practiceListTotalItems(Object count) {
    return '$count张字帖';
  }

  @override
  String get practicePageSettings => '页面设置';

  @override
  String get practices => '字帖';

  @override
  String get presetSize => '预设大小';

  @override
  String get preview => '预览';

  @override
  String get previewText => '预览';

  @override
  String get previousImage => '上一张图片';

  @override
  String get print => '打印';

  @override
  String get removedFromAllCategories => '已从所有分类中移除';

  @override
  String get rename => '重命名';

  @override
  String get resetSettingsConfirmMessage => '确定要将所有缓存设置重置为默认值吗？';

  @override
  String get resetSettingsConfirmTitle => '重置设置';

  @override
  String get resetToDefaults => '重置为默认值';

  @override
  String get restartAfterRestored => '注意：恢复完成后应用将自动重启';

  @override
  String get restartAppRequired => '需要重启应用以完成恢复过程。';

  @override
  String get restartLater => '稍后';

  @override
  String get restartNow => '立即重启';

  @override
  String get restore => '恢复';

  @override
  String get restoreBackup => '恢复备份';

  @override
  String get restoreConfirmMessage => '确定要从此备份恢复吗？这将替换您当前的所有数据。';

  @override
  String get restoreConfirmTitle => '恢复确认';

  @override
  String get restoreFailure => '恢复失败';

  @override
  String get restoreSuccess => '恢复成功';

  @override
  String get restoringBackup => '正在从备份恢复...';

  @override
  String get rotation => '旋转';

  @override
  String get save => '保存';

  @override
  String get searchCategories => '搜索分类...';

  @override
  String get searchCharactersWorksAuthors => '搜索字符、作品或作者';

  @override
  String get selectBackup => '选择备份';

  @override
  String get selectCollection => '选择采集';

  @override
  String get selectDeleteOption => '选择删除选项：';

  @override
  String get selected => '已选择';

  @override
  String selectedCount(Object count) {
    return '已选择$count个';
  }

  @override
  String get selectExportLocation => '选择导出位置';

  @override
  String get selectImportFile => '选择备份文件';

  @override
  String get selectTargetLayer => '选择目标图层';

  @override
  String get sendLayerToBack => '图层置于底层';

  @override
  String get sendToBack => '置于底层';

  @override
  String get settings => '设置';

  @override
  String get settingsResetMessage => '设置已重置为默认值';

  @override
  String get showElement => '显示元素';

  @override
  String get showGrid => '显示网格';

  @override
  String get showHideAllElements => '显示/隐藏所有元素';

  @override
  String get sortAndFilter => '排序和筛选';

  @override
  String get stateAndDisplay => '状态与显示';

  @override
  String get storageCharacters => '集字';

  @override
  String get storageDetails => '存储详情';

  @override
  String get storageGallery => '图库';

  @override
  String get storageLocation => '存储位置';

  @override
  String get storageSettings => '存储设置';

  @override
  String get storageUsed => '已使用存储';

  @override
  String get storageWorks => '作品';

  @override
  String get tagEditorEnterTagHint => '输入标签并按Enter';

  @override
  String get tagEditorNoTags => '无标签';

  @override
  String get tagEditorSuggestedTags => '建议标签：';

  @override
  String get tagsHint => '输入标签...';

  @override
  String get text => '文本';

  @override
  String get textPropertyPanel => '文本属性';

  @override
  String get textPropertyPanelBgColor => '背景颜色';

  @override
  String get textPropertyPanelDimensions => '尺寸';

  @override
  String get textPropertyPanelFontColor => '文本颜色';

  @override
  String get textPropertyPanelFontFamily => '字体';

  @override
  String get textPropertyPanelFontSize => '字体大小';

  @override
  String get textPropertyPanelFontStyle => '字体样式';

  @override
  String get textPropertyPanelFontWeight => '字体粗细';

  @override
  String get textPropertyPanelGeometry => '几何属性';

  @override
  String get textPropertyPanelHorizontal => '水平';

  @override
  String get textPropertyPanelLetterSpacing => '字符间距';

  @override
  String get textPropertyPanelLineHeight => '行高';

  @override
  String get textPropertyPanelLineThrough => '删除线';

  @override
  String get textPropertyPanelOpacity => '不透明度';

  @override
  String get textPropertyPanelPadding => '内边距';

  @override
  String get textPropertyPanelPosition => '位置';

  @override
  String get textPropertyPanelPreview => '预览';

  @override
  String get textPropertyPanelTextAlign => '文本对齐';

  @override
  String get textPropertyPanelTextContent => '文本内容';

  @override
  String get textPropertyPanelTextSettings => '文本设置';

  @override
  String get textPropertyPanelUnderline => '下划线';

  @override
  String get textPropertyPanelVertical => '垂直';

  @override
  String get textPropertyPanelVerticalAlign => '垂直对齐';

  @override
  String get textPropertyPanelVisual => '视觉设置';

  @override
  String get textPropertyPanelWritingMode => '书写模式';

  @override
  String get textureApplicationRange => '纹理应用范围';

  @override
  String get textureFillMode => '纹理填充模式';

  @override
  String get textureFillModeContain => '包含';

  @override
  String get textureFillModeCover => '覆盖';

  @override
  String get textureFillModeNoRepeat => '不重复';

  @override
  String get textureFillModeRepeat => '重复';

  @override
  String get textureFillModeRepeatX => '水平重复';

  @override
  String get textureFillModeRepeatY => '垂直重复';

  @override
  String get textureOpacity => '纹理不透明度';

  @override
  String get textureRangeBackground => '整个背景';

  @override
  String get textureRangeCharacter => '仅字符';

  @override
  String get textureRemove => '移除';

  @override
  String get textureSelectFromLibrary => '从库中选择';

  @override
  String get themeMode => '主题模式';

  @override
  String get themeModeDark => '暗色';

  @override
  String get themeModeDescription => '使用深色主题获得更好的夜间观看体验';

  @override
  String get themeModeLight => '亮色';

  @override
  String get themeModeSystem => '系统';

  @override
  String get themeModeSystemDescription => '根据系统设置自动切换深色/亮色主题';

  @override
  String get toggleTestText => '切换测试文本';

  @override
  String get total => '总计';

  @override
  String totalItems(Object count) {
    return '共 $count 个';
  }

  @override
  String get ungroup => '取消组合';

  @override
  String get ungroupConfirm => '确认解组';

  @override
  String get ungroupDescription => '确定要解散此组吗？';

  @override
  String get unknownCategory => '未知分类';

  @override
  String get unlocked => '未锁定';

  @override
  String get unlockElement => '解锁元素';

  @override
  String get unnamedElement => '未命名元素';

  @override
  String get unnamedGroup => '未命名组';

  @override
  String get unnamedLayer => '未命名图层';

  @override
  String get verticalAlignment => '垂直对齐';

  @override
  String get verticalLeftToRight => '竖排左起';

  @override
  String get verticalRightToLeft => '竖排右起';

  @override
  String get verticalTextModeEnabled => '竖排文本预览 - 超出高度自动换列，可横向滚动';

  @override
  String get visibility => '可见性';

  @override
  String get visible => '可见';

  @override
  String get visualSettings => '视觉设置';

  @override
  String get width => '宽度';

  @override
  String get windowButtonClose => '关闭';

  @override
  String get windowButtonMaximize => '最大化';

  @override
  String get windowButtonMinimize => '最小化';

  @override
  String get windowButtonRestore => '还原';

  @override
  String get workBrowseAddFavorite => '添加到收藏';

  @override
  String get workBrowseBatchDone => '完成';

  @override
  String get workBrowseBatchMode => '批量模式';

  @override
  String get workBrowseCancel => '取消';

  @override
  String get workBrowseDelete => '删除';

  @override
  String workBrowseDeleteConfirmMessage(Object count) {
    return '确定要删除已选的$count个作品吗？此操作无法撤消。';
  }

  @override
  String get workBrowseDeleteConfirmTitle => '确认删除';

  @override
  String workBrowseDeleteSelected(Object count) {
    return '删除$count个';
  }

  @override
  String workBrowseError(Object message) {
    return '错误：$message';
  }

  @override
  String get workBrowseGridView => '网格视图';

  @override
  String get workBrowseImport => '导入作品';

  @override
  String workBrowseItemsPerPage(Object count) {
    return '$count项/页';
  }

  @override
  String get workBrowseListView => '列表视图';

  @override
  String get workBrowseLoading => '加载作品中...';

  @override
  String get workBrowseNoWorks => '未找到作品';

  @override
  String get workBrowseNoWorksHint => '尝试导入新作品或更改筛选条件';

  @override
  String get workBrowseReload => '重新加载';

  @override
  String get workBrowseRemoveFavorite => '从收藏中移除';

  @override
  String get workBrowseSearch => '搜索作品...';

  @override
  String workBrowseSelectedCount(Object count) {
    return '已选$count个';
  }

  @override
  String get workBrowseTitle => '作品';

  @override
  String get workCount => '作品数量';

  @override
  String get workDetailBack => '返回';

  @override
  String get workDetailBasicInfo => '基本信息';

  @override
  String get workDetailCancel => '取消';

  @override
  String get workDetailCharacters => '字符';

  @override
  String get workDetailCreateTime => '创建时间';

  @override
  String get workDetailEdit => '编辑';

  @override
  String get workDetailExtract => '提取字符';

  @override
  String get workDetailExtractionError => '无法打开字符提取';

  @override
  String get workDetailImageCount => '图像数量';

  @override
  String get workDetailImageLoadError => '选中的图像无法加载，请尝试重新导入图像';

  @override
  String get workDetailLoading => '加载作品详情中...';

  @override
  String get workDetailNoCharacters => '暂无字符';

  @override
  String get workDetailNoImages => '没有可显示的图像';

  @override
  String get workDetailNoImagesForExtraction => '无法提取字符：作品没有图像';

  @override
  String get workDetailNoWork => '作品不存在或已被删除';

  @override
  String get workDetailOtherInfo => '其他信息';

  @override
  String get workDetailSave => '保存';

  @override
  String get workDetailSaveFailure => '保存失败';

  @override
  String get workDetailSaveSuccess => '保存成功';

  @override
  String get workDetailTags => '标签';

  @override
  String get workDetailTitle => '作品详情';

  @override
  String get workDetailUnsavedChanges => '您有未保存的更改。确定要放弃它们吗？';

  @override
  String get workDetailUpdateTime => '更新时间';

  @override
  String get workDetailViewMore => '查看更多';

  @override
  String get workFormAuthor => '作者';

  @override
  String get workFormAuthorHelp => '可选，作品的创作者';

  @override
  String get workFormAuthorHint => '输入作者名称';

  @override
  String get workFormAuthorMaxLength => '作者名称不能超过50个字符';

  @override
  String get workFormAuthorTooltip => '按Ctrl+A快速跳转到作者字段';

  @override
  String get workFormCreationDate => '创作日期';

  @override
  String get workFormDateHelp => '作品的完成日期';

  @override
  String get workFormDateTooltip => '按Tab导航到下一个字段';

  @override
  String get workFormHelp => '帮助';

  @override
  String get workFormNextField => '下一个字段';

  @override
  String get workFormPreviousField => '上一个字段';

  @override
  String get workFormRemark => '备注';

  @override
  String get workFormRemarkHelp => '可选，关于作品的附加信息';

  @override
  String get workFormRemarkHint => '可选';

  @override
  String get workFormRemarkMaxLength => '备注不能超过500个字符';

  @override
  String get workFormRemarkTooltip => '按Ctrl+R快速跳转到备注字段';

  @override
  String get workFormRequiredField => '必填字段';

  @override
  String get workFormSelectDate => '选择日期';

  @override
  String get workFormShortcuts => '键盘快捷键';

  @override
  String get workFormStyle => '风格';

  @override
  String get workFormStyleHelp => '作品的主要风格类型';

  @override
  String get workFormStyleTooltip => '按Tab导航到下一个字段';

  @override
  String get workFormTitle => '标题';

  @override
  String get workFormTitleHelp => '作品的主标题，显示在作品列表中';

  @override
  String get workFormTitleHint => '输入标题';

  @override
  String get workFormTitleMaxLength => '标题不能超过100个字符';

  @override
  String get workFormTitleMinLength => '标题必须至少2个字符';

  @override
  String get workFormTitleRequired => '标题为必填项';

  @override
  String get workFormTitleTooltip => '按Ctrl+T快速跳转到标题字段';

  @override
  String get workFormTool => '工具';

  @override
  String get workFormToolHelp => '创作此作品使用的主要工具';

  @override
  String get workFormToolTooltip => '按Tab导航到下一个字段';

  @override
  String get workImportDialogAddImages => '添加图像';

  @override
  String get workImportDialogCancel => '取消';

  @override
  String get workImportDialogDeleteImage => '删除图像';

  @override
  String get workImportDialogDeleteImageConfirm => '确定要删除此图像吗？';

  @override
  String workImportDialogError(Object error) {
    return '导入失败：$error';
  }

  @override
  String get workImportDialogFromGallery => '从图库';

  @override
  String get workImportDialogFromGalleryLong => '从图库中选择图像';

  @override
  String get workImportDialogImport => '导入';

  @override
  String get workImportDialogNoImages => '未选择图像';

  @override
  String get workImportDialogNoImagesHint => '点击添加图像';

  @override
  String get workImportDialogProcessing => '处理中...';

  @override
  String get workImportDialogSuccess => '导入成功';

  @override
  String get workImportDialogTitle => '导入作品';

  @override
  String get works => '作品';

  @override
  String get workStyleClerical => '隶书';

  @override
  String get workStyleCursive => '草书';

  @override
  String get workStyleOther => '其他';

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
  String get hideImagePreview => '隐藏图片预览';

  @override
  String get showImagePreview => '显示图片预览';

  @override
  String get yes => '是';
}
