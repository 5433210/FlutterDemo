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
  /// In zh, this message translates to:
  /// **'A4 (210×297mm)'**
  String get a4Size;

  /// No description provided for @a5Size.
  ///
  /// In zh, this message translates to:
  /// **'A5 (148×210mm)'**
  String get a5Size;

  /// No description provided for @activated.
  ///
  /// In zh, this message translates to:
  /// **'激活'**
  String get activated;

  /// No description provided for @activatedDescription.
  ///
  /// In zh, this message translates to:
  /// **'激活 - 在选择器中显示'**
  String get activatedDescription;

  /// No description provided for @activeStatus.
  ///
  /// In zh, this message translates to:
  /// **'激活状态'**
  String get activeStatus;

  /// No description provided for @add.
  ///
  /// In zh, this message translates to:
  /// **'添加'**
  String get add;

  /// No description provided for @addCategory.
  ///
  /// In zh, this message translates to:
  /// **'添加分类'**
  String get addCategory;

  /// No description provided for @addCategoryItem.
  ///
  /// In zh, this message translates to:
  /// **'添加{category}'**
  String addCategoryItem(Object category);

  /// No description provided for @addConfigItem.
  ///
  /// In zh, this message translates to:
  /// **'添加配置项'**
  String get addConfigItem;

  /// No description provided for @addConfigItemHint.
  ///
  /// In zh, this message translates to:
  /// **'点击右下角的按钮添加{category}配置项'**
  String addConfigItemHint(Object category);

  /// No description provided for @addFavorite.
  ///
  /// In zh, this message translates to:
  /// **'添加到收藏'**
  String get addFavorite;

  /// No description provided for @addFromGalleryFailed.
  ///
  /// In zh, this message translates to:
  /// **'从图库添加图片失败: {error}'**
  String addFromGalleryFailed(Object error);

  /// No description provided for @addImage.
  ///
  /// In zh, this message translates to:
  /// **'添加图片'**
  String get addImage;

  /// No description provided for @addImageHint.
  ///
  /// In zh, this message translates to:
  /// **'点击添加图像'**
  String get addImageHint;

  /// No description provided for @addImages.
  ///
  /// In zh, this message translates to:
  /// **'添加图片'**
  String get addImages;

  /// No description provided for @addLayer.
  ///
  /// In zh, this message translates to:
  /// **'添加图层'**
  String get addLayer;

  /// No description provided for @addTag.
  ///
  /// In zh, this message translates to:
  /// **'添加标签'**
  String get addTag;

  /// No description provided for @addWork.
  ///
  /// In zh, this message translates to:
  /// **'添加作品'**
  String get addWork;

  /// No description provided for @addedToCategory.
  ///
  /// In zh, this message translates to:
  /// **'已添加到分类'**
  String get addedToCategory;

  /// No description provided for @adjust.
  ///
  /// In zh, this message translates to:
  /// **'调节'**
  String get adjust;

  /// No description provided for @adjustGridSize.
  ///
  /// In zh, this message translates to:
  /// **'调整网格大小'**
  String get adjustGridSize;

  /// No description provided for @afterDate.
  ///
  /// In zh, this message translates to:
  /// **'某个日期之后'**
  String get afterDate;

  /// No description provided for @alignBottom.
  ///
  /// In zh, this message translates to:
  /// **'底对齐'**
  String get alignBottom;

  /// No description provided for @alignCenter.
  ///
  /// In zh, this message translates to:
  /// **'居中'**
  String get alignCenter;

  /// No description provided for @alignHorizontalCenter.
  ///
  /// In zh, this message translates to:
  /// **'水平居中'**
  String get alignHorizontalCenter;

  /// No description provided for @alignLeft.
  ///
  /// In zh, this message translates to:
  /// **'左对齐'**
  String get alignLeft;

  /// No description provided for @alignMiddle.
  ///
  /// In zh, this message translates to:
  /// **'居中'**
  String get alignMiddle;

  /// No description provided for @alignRight.
  ///
  /// In zh, this message translates to:
  /// **'右对齐'**
  String get alignRight;

  /// No description provided for @alignTop.
  ///
  /// In zh, this message translates to:
  /// **'顶对齐'**
  String get alignTop;

  /// No description provided for @alignVerticalCenter.
  ///
  /// In zh, this message translates to:
  /// **'垂直居中'**
  String get alignVerticalCenter;

  /// No description provided for @alignmentAssist.
  ///
  /// In zh, this message translates to:
  /// **'对齐辅助'**
  String get alignmentAssist;

  /// No description provided for @alignmentGrid.
  ///
  /// In zh, this message translates to:
  /// **'网格贴附模式 - 点击切换到参考线对齐'**
  String get alignmentGrid;

  /// No description provided for @alignmentGuideline.
  ///
  /// In zh, this message translates to:
  /// **'参考线对齐模式 - 点击切换到无辅助'**
  String get alignmentGuideline;

  /// No description provided for @alignmentNone.
  ///
  /// In zh, this message translates to:
  /// **'无辅助对齐 - 点击启用网格贴附'**
  String get alignmentNone;

  /// No description provided for @alignmentOperations.
  ///
  /// In zh, this message translates to:
  /// **'对齐操作'**
  String get alignmentOperations;

  /// No description provided for @all.
  ///
  /// In zh, this message translates to:
  /// **'全部'**
  String get all;

  /// No description provided for @allCategories.
  ///
  /// In zh, this message translates to:
  /// **'所有分类'**
  String get allCategories;

  /// No description provided for @allPages.
  ///
  /// In zh, this message translates to:
  /// **'全部页面'**
  String get allPages;

  /// No description provided for @allTime.
  ///
  /// In zh, this message translates to:
  /// **'全部时间'**
  String get allTime;

  /// No description provided for @allTypes.
  ///
  /// In zh, this message translates to:
  /// **'所有类型'**
  String get allTypes;

  /// No description provided for @appRestartFailed.
  ///
  /// In zh, this message translates to:
  /// **'应用重启失败，请手动重启应用'**
  String get appRestartFailed;

  /// No description provided for @appRestarting.
  ///
  /// In zh, this message translates to:
  /// **'正在重启应用'**
  String get appRestarting;

  /// No description provided for @appRestartingMessage.
  ///
  /// In zh, this message translates to:
  /// **'数据恢复成功，正在重启应用...'**
  String get appRestartingMessage;

  /// No description provided for @appTitle.
  ///
  /// In zh, this message translates to:
  /// **'字字珠玑'**
  String get appTitle;

  /// No description provided for @appVersionInfo.
  ///
  /// In zh, this message translates to:
  /// **'应用版本信息'**
  String get appVersionInfo;

  /// No description provided for @apply.
  ///
  /// In zh, this message translates to:
  /// **'应用'**
  String get apply;

  /// No description provided for @applyFormatBrush.
  ///
  /// In zh, this message translates to:
  /// **'应用格式刷 (Alt+W)'**
  String get applyFormatBrush;

  /// No description provided for @applyTransform.
  ///
  /// In zh, this message translates to:
  /// **'应用变换'**
  String get applyTransform;

  /// No description provided for @ascending.
  ///
  /// In zh, this message translates to:
  /// **'升序'**
  String get ascending;

  /// No description provided for @author.
  ///
  /// In zh, this message translates to:
  /// **'作者'**
  String get author;

  /// No description provided for @autoBackup.
  ///
  /// In zh, this message translates to:
  /// **'自动备份'**
  String get autoBackup;

  /// No description provided for @autoBackupDescription.
  ///
  /// In zh, this message translates to:
  /// **'定期自动备份您的数据'**
  String get autoBackupDescription;

  /// No description provided for @autoBackupInterval.
  ///
  /// In zh, this message translates to:
  /// **'自动备份间隔'**
  String get autoBackupInterval;

  /// No description provided for @autoBackupIntervalDescription.
  ///
  /// In zh, this message translates to:
  /// **'自动备份的频率'**
  String get autoBackupIntervalDescription;

  /// No description provided for @autoCleanup.
  ///
  /// In zh, this message translates to:
  /// **'自动清理'**
  String get autoCleanup;

  /// No description provided for @autoCleanupDescription.
  ///
  /// In zh, this message translates to:
  /// **'自动清理旧的缓存文件'**
  String get autoCleanupDescription;

  /// No description provided for @autoCleanupInterval.
  ///
  /// In zh, this message translates to:
  /// **'自动清理间隔'**
  String get autoCleanupInterval;

  /// No description provided for @autoCleanupIntervalDescription.
  ///
  /// In zh, this message translates to:
  /// **'自动清理运行的频率'**
  String get autoCleanupIntervalDescription;

  /// No description provided for @autoDetect.
  ///
  /// In zh, this message translates to:
  /// **'自动检测'**
  String get autoDetect;

  /// No description provided for @autoDetectPageOrientation.
  ///
  /// In zh, this message translates to:
  /// **'自动检测页面方向'**
  String get autoDetectPageOrientation;

  /// No description provided for @autoLineBreak.
  ///
  /// In zh, this message translates to:
  /// **'自动换行'**
  String get autoLineBreak;

  /// No description provided for @autoLineBreakDisabled.
  ///
  /// In zh, this message translates to:
  /// **'已禁用自动换行'**
  String get autoLineBreakDisabled;

  /// No description provided for @autoLineBreakEnabled.
  ///
  /// In zh, this message translates to:
  /// **'已启用自动换行'**
  String get autoLineBreakEnabled;

  /// No description provided for @availableCharacters.
  ///
  /// In zh, this message translates to:
  /// **'可用字符'**
  String get availableCharacters;

  /// No description provided for @back.
  ///
  /// In zh, this message translates to:
  /// **'返回'**
  String get back;

  /// No description provided for @backgroundColor.
  ///
  /// In zh, this message translates to:
  /// **'背景颜色'**
  String get backgroundColor;

  /// No description provided for @backupDescription.
  ///
  /// In zh, this message translates to:
  /// **'描述（可选）'**
  String get backupDescription;

  /// No description provided for @backupDescriptionHint.
  ///
  /// In zh, this message translates to:
  /// **'输入此备份的描述'**
  String get backupDescriptionHint;

  /// No description provided for @backupFailure.
  ///
  /// In zh, this message translates to:
  /// **'创建备份失败'**
  String get backupFailure;

  /// No description provided for @backupList.
  ///
  /// In zh, this message translates to:
  /// **'备份列表'**
  String get backupList;

  /// No description provided for @backupSettings.
  ///
  /// In zh, this message translates to:
  /// **'备份与恢复'**
  String get backupSettings;

  /// No description provided for @backupSuccess.
  ///
  /// In zh, this message translates to:
  /// **'备份创建成功'**
  String get backupSuccess;

  /// No description provided for @backupRecommendation.
  ///
  /// In zh, this message translates to:
  /// **'建议导入前创建备份'**
  String get backupRecommendation;

  /// No description provided for @backupRecommendationDescription.
  ///
  /// In zh, this message translates to:
  /// **'为确保数据安全，建议在导入前手动创建备份'**
  String get backupRecommendationDescription;

  /// No description provided for @goToBackup.
  ///
  /// In zh, this message translates to:
  /// **'前往备份'**
  String get goToBackup;

  /// No description provided for @navigatedToBackupSettings.
  ///
  /// In zh, this message translates to:
  /// **'已跳转到备份设置页面'**
  String get navigatedToBackupSettings;

  /// No description provided for @basicInfo.
  ///
  /// In zh, this message translates to:
  /// **'基本信息'**
  String get basicInfo;

  /// No description provided for @batchDeleteMessage.
  ///
  /// In zh, this message translates to:
  /// **'即将删除{count}项，此操作无法撤消。'**
  String batchDeleteMessage(Object count);

  /// No description provided for @batchMode.
  ///
  /// In zh, this message translates to:
  /// **'批量模式'**
  String get batchMode;

  /// No description provided for @batchOperations.
  ///
  /// In zh, this message translates to:
  /// **'批量操作'**
  String get batchOperations;

  /// No description provided for @batchImport.
  ///
  /// In zh, this message translates to:
  /// **'批量导入'**
  String get batchImport;

  /// No description provided for @beforeDate.
  ///
  /// In zh, this message translates to:
  /// **'某个日期之前'**
  String get beforeDate;

  /// No description provided for @border.
  ///
  /// In zh, this message translates to:
  /// **'边框'**
  String get border;

  /// No description provided for @borderColor.
  ///
  /// In zh, this message translates to:
  /// **'边框颜色'**
  String get borderColor;

  /// No description provided for @borderWidth.
  ///
  /// In zh, this message translates to:
  /// **'边框宽度'**
  String get borderWidth;

  /// No description provided for @boxRegion.
  ///
  /// In zh, this message translates to:
  /// **'请在预览区域框选字符'**
  String get boxRegion;

  /// No description provided for @boxTool.
  ///
  /// In zh, this message translates to:
  /// **'框选工具'**
  String get boxTool;

  /// No description provided for @bringLayerToFront.
  ///
  /// In zh, this message translates to:
  /// **'图层置于顶层'**
  String get bringLayerToFront;

  /// No description provided for @bringToFront.
  ///
  /// In zh, this message translates to:
  /// **'置于顶层 (Ctrl+T)'**
  String get bringToFront;

  /// No description provided for @browse.
  ///
  /// In zh, this message translates to:
  /// **'浏览'**
  String get browse;

  /// No description provided for @brushSize.
  ///
  /// In zh, this message translates to:
  /// **'笔刷尺寸'**
  String get brushSize;

  /// No description provided for @cacheClearedMessage.
  ///
  /// In zh, this message translates to:
  /// **'缓存已成功清除'**
  String get cacheClearedMessage;

  /// No description provided for @cacheSettings.
  ///
  /// In zh, this message translates to:
  /// **'缓存设置'**
  String get cacheSettings;

  /// No description provided for @cacheSize.
  ///
  /// In zh, this message translates to:
  /// **'缓存大小'**
  String get cacheSize;

  /// No description provided for @calligraphyStyle.
  ///
  /// In zh, this message translates to:
  /// **'书法风格'**
  String get calligraphyStyle;

  /// No description provided for @calligraphyStyleText.
  ///
  /// In zh, this message translates to:
  /// **'书法风格'**
  String get calligraphyStyleText;

  /// No description provided for @canNotPreview.
  ///
  /// In zh, this message translates to:
  /// **'无法生成预览'**
  String get canNotPreview;

  /// No description provided for @cancel.
  ///
  /// In zh, this message translates to:
  /// **'取消'**
  String get cancel;

  /// No description provided for @cannotApplyNoImage.
  ///
  /// In zh, this message translates to:
  /// **'没有可用的图片'**
  String get cannotApplyNoImage;

  /// No description provided for @homePage.
  ///
  /// In zh, this message translates to:
  /// **'主页'**
  String get homePage;

  /// No description provided for @fontTester.
  ///
  /// In zh, this message translates to:
  /// **'字体测试工具'**
  String get fontTester;

  /// No description provided for @fontWeightTester.
  ///
  /// In zh, this message translates to:
  /// **'字体粗细测试工具'**
  String get fontWeightTester;

  /// No description provided for @backupTimeoutError.
  ///
  /// In zh, this message translates to:
  /// **'备份创建超时或失败，请检查存储空间是否足够'**
  String get backupTimeoutError;

  /// No description provided for @retry.
  ///
  /// In zh, this message translates to:
  /// **'重试'**
  String get retry;

  /// No description provided for @serviceNotReady.
  ///
  /// In zh, this message translates to:
  /// **'服务未就绪，请稍后再试'**
  String get serviceNotReady;

  /// No description provided for @exportFailed.
  ///
  /// In zh, this message translates to:
  /// **'导出失败'**
  String get exportFailed;

  /// No description provided for @exportFailedWith.
  ///
  /// In zh, this message translates to:
  /// **'导出失败: {error}'**
  String exportFailedWith(Object error);

  /// No description provided for @importError.
  ///
  /// In zh, this message translates to:
  /// **'导入错误'**
  String get importError;

  /// No description provided for @pageBuildError.
  ///
  /// In zh, this message translates to:
  /// **'页面构建错误'**
  String get pageBuildError;

  /// No description provided for @configInitFailed.
  ///
  /// In zh, this message translates to:
  /// **'配置数据初始化失败'**
  String get configInitFailed;

  /// No description provided for @sortFailed.
  ///
  /// In zh, this message translates to:
  /// **'排序失败'**
  String get sortFailed;

  /// No description provided for @selectPathFailed.
  ///
  /// In zh, this message translates to:
  /// **'选择路径失败'**
  String get selectPathFailed;

  /// No description provided for @importErrorCauses.
  ///
  /// In zh, this message translates to:
  /// **'该问题通常由以下原因引起：'**
  String get importErrorCauses;

  /// No description provided for @exportEncodingIssue.
  ///
  /// In zh, this message translates to:
  /// **'• 导出时存在特殊字符编码问题'**
  String get exportEncodingIssue;

  /// No description provided for @fileCorrupted.
  ///
  /// In zh, this message translates to:
  /// **'• 文件在传输过程中损坏'**
  String get fileCorrupted;

  /// No description provided for @incompatibleCharset.
  ///
  /// In zh, this message translates to:
  /// **'• 使用了不兼容的字符集'**
  String get incompatibleCharset;

  /// No description provided for @suggestedSolutions.
  ///
  /// In zh, this message translates to:
  /// **'建议解决方案：'**
  String get suggestedSolutions;

  /// No description provided for @reExportWork.
  ///
  /// In zh, this message translates to:
  /// **'• 重新导出该作品'**
  String get reExportWork;

  /// No description provided for @checkSpecialChars.
  ///
  /// In zh, this message translates to:
  /// **'• 检查作品标题是否包含特殊字符'**
  String get checkSpecialChars;

  /// No description provided for @ensureCompleteTransfer.
  ///
  /// In zh, this message translates to:
  /// **'• 确保文件完整传输'**
  String get ensureCompleteTransfer;

  /// No description provided for @reselectFile.
  ///
  /// In zh, this message translates to:
  /// **'重新选择文件'**
  String get reselectFile;

  /// No description provided for @validatingImportFile.
  ///
  /// In zh, this message translates to:
  /// **'正在验证导入文件...'**
  String get validatingImportFile;

  /// No description provided for @parsingImportData.
  ///
  /// In zh, this message translates to:
  /// **'正在解析导入数据...'**
  String get parsingImportData;

  /// No description provided for @executingImportOperation.
  ///
  /// In zh, this message translates to:
  /// **'正在执行导入操作...'**
  String get executingImportOperation;

  /// No description provided for @cannotApplyNoSizeInfo.
  ///
  /// In zh, this message translates to:
  /// **'无法获取图片尺寸信息'**
  String get cannotApplyNoSizeInfo;

  /// No description provided for @cannotCapturePageImage.
  ///
  /// In zh, this message translates to:
  /// **'无法捕获页面图像'**
  String get cannotCapturePageImage;

  /// No description provided for @cannotDeleteOnlyPage.
  ///
  /// In zh, this message translates to:
  /// **'无法删除唯一的页面'**
  String get cannotDeleteOnlyPage;

  /// No description provided for @cannotSaveMissingController.
  ///
  /// In zh, this message translates to:
  /// **'无法保存：缺少控制器'**
  String get cannotSaveMissingController;

  /// No description provided for @cannotSaveNoPages.
  ///
  /// In zh, this message translates to:
  /// **'无页面，无法保存'**
  String get cannotSaveNoPages;

  /// No description provided for @canvasPixelSize.
  ///
  /// In zh, this message translates to:
  /// **'画布像素大小'**
  String get canvasPixelSize;

  /// No description provided for @canvasResetViewTooltip.
  ///
  /// In zh, this message translates to:
  /// **'重置视图位置'**
  String get canvasResetViewTooltip;

  /// No description provided for @categories.
  ///
  /// In zh, this message translates to:
  /// **'分类'**
  String get categories;

  /// No description provided for @categoryManagement.
  ///
  /// In zh, this message translates to:
  /// **'分类管理'**
  String get categoryManagement;

  /// No description provided for @categoryName.
  ///
  /// In zh, this message translates to:
  /// **'分类名称'**
  String get categoryName;

  /// No description provided for @categoryNameCannotBeEmpty.
  ///
  /// In zh, this message translates to:
  /// **'分类名称不能为空'**
  String get categoryNameCannotBeEmpty;

  /// No description provided for @centimeter.
  ///
  /// In zh, this message translates to:
  /// **'厘米'**
  String get centimeter;

  /// No description provided for @characterCollection.
  ///
  /// In zh, this message translates to:
  /// **'集字'**
  String get characterCollection;

  /// No description provided for @characterCollectionFindSwitchFailed.
  ///
  /// In zh, this message translates to:
  /// **'查找并切换页面失败：{error}'**
  String characterCollectionFindSwitchFailed(Object error);

  /// No description provided for @characterCollectionPreviewTab.
  ///
  /// In zh, this message translates to:
  /// **'字符预览'**
  String get characterCollectionPreviewTab;

  /// No description provided for @characterCollectionResultsTab.
  ///
  /// In zh, this message translates to:
  /// **'采集结果'**
  String get characterCollectionResultsTab;

  /// No description provided for @characterCollectionSearchHint.
  ///
  /// In zh, this message translates to:
  /// **'搜索字符...'**
  String get characterCollectionSearchHint;

  /// No description provided for @characterCollectionTitle.
  ///
  /// In zh, this message translates to:
  /// **'字符采集'**
  String get characterCollectionTitle;

  /// No description provided for @characterCollectionToolBox.
  ///
  /// In zh, this message translates to:
  /// **'框选工具 (Ctrl+B)'**
  String get characterCollectionToolBox;

  /// No description provided for @characterCollectionToolPan.
  ///
  /// In zh, this message translates to:
  /// **'平移工具 (Ctrl+V)'**
  String get characterCollectionToolPan;

  /// No description provided for @characterCollectionUseBoxTool.
  ///
  /// In zh, this message translates to:
  /// **'使用框选工具从图像中提取字符'**
  String get characterCollectionUseBoxTool;

  /// No description provided for @characterCount.
  ///
  /// In zh, this message translates to:
  /// **'集字数量'**
  String get characterCount;

  /// No description provided for @characterDetailFormatBinary.
  ///
  /// In zh, this message translates to:
  /// **'二值化'**
  String get characterDetailFormatBinary;

  /// No description provided for @characterDetailFormatBinaryDesc.
  ///
  /// In zh, this message translates to:
  /// **'黑白二值化图像'**
  String get characterDetailFormatBinaryDesc;

  /// No description provided for @characterDetailFormatDescription.
  ///
  /// In zh, this message translates to:
  /// **'描述'**
  String get characterDetailFormatDescription;

  /// No description provided for @characterDetailFormatOutline.
  ///
  /// In zh, this message translates to:
  /// **'轮廓'**
  String get characterDetailFormatOutline;

  /// No description provided for @characterDetailFormatOutlineDesc.
  ///
  /// In zh, this message translates to:
  /// **'仅显示轮廓'**
  String get characterDetailFormatOutlineDesc;

  /// No description provided for @characterDetailFormatSquareBinary.
  ///
  /// In zh, this message translates to:
  /// **'方形二值化'**
  String get characterDetailFormatSquareBinary;

  /// No description provided for @characterDetailFormatSquareBinaryDesc.
  ///
  /// In zh, this message translates to:
  /// **'规整为正方形的二值化图像'**
  String get characterDetailFormatSquareBinaryDesc;

  /// No description provided for @characterDetailFormatSquareOutline.
  ///
  /// In zh, this message translates to:
  /// **'方形轮廓'**
  String get characterDetailFormatSquareOutline;

  /// No description provided for @characterDetailFormatSquareOutlineDesc.
  ///
  /// In zh, this message translates to:
  /// **'规整为正方形的轮廓图像'**
  String get characterDetailFormatSquareOutlineDesc;

  /// No description provided for @characterDetailFormatSquareTransparent.
  ///
  /// In zh, this message translates to:
  /// **'方形透明'**
  String get characterDetailFormatSquareTransparent;

  /// No description provided for @characterDetailFormatSquareTransparentDesc.
  ///
  /// In zh, this message translates to:
  /// **'规整为正方形的透明PNG图像'**
  String get characterDetailFormatSquareTransparentDesc;

  /// No description provided for @characterDetailFormatThumbnail.
  ///
  /// In zh, this message translates to:
  /// **'缩略图'**
  String get characterDetailFormatThumbnail;

  /// No description provided for @characterDetailFormatThumbnailDesc.
  ///
  /// In zh, this message translates to:
  /// **'缩略图'**
  String get characterDetailFormatThumbnailDesc;

  /// No description provided for @characterDetailFormatTransparent.
  ///
  /// In zh, this message translates to:
  /// **'透明'**
  String get characterDetailFormatTransparent;

  /// No description provided for @characterDetailFormatTransparentDesc.
  ///
  /// In zh, this message translates to:
  /// **'去背景的透明PNG图像'**
  String get characterDetailFormatTransparentDesc;

  /// No description provided for @characterDetailLoadError.
  ///
  /// In zh, this message translates to:
  /// **'加载字符详情失败'**
  String get characterDetailLoadError;

  /// No description provided for @characterDetailSimplifiedChar.
  ///
  /// In zh, this message translates to:
  /// **'简体字符'**
  String get characterDetailSimplifiedChar;

  /// No description provided for @characterDetailTitle.
  ///
  /// In zh, this message translates to:
  /// **'字符详情'**
  String get characterDetailTitle;

  /// No description provided for @characterEditSaveConfirmMessage.
  ///
  /// In zh, this message translates to:
  /// **'确认保存「{character}」？'**
  String characterEditSaveConfirmMessage(Object character);

  /// No description provided for @characterUpdated.
  ///
  /// In zh, this message translates to:
  /// **'字符已更新'**
  String get characterUpdated;

  /// No description provided for @charactersSelected.
  ///
  /// In zh, this message translates to:
  /// **'已选择 {count} 个字符'**
  String charactersSelected(Object count);

  /// No description provided for @charactersCount.
  ///
  /// In zh, this message translates to:
  /// **'{count} 个集字'**
  String charactersCount(Object count);

  /// No description provided for @clearCache.
  ///
  /// In zh, this message translates to:
  /// **'清除缓存'**
  String get clearCache;

  /// No description provided for @clearSelection.
  ///
  /// In zh, this message translates to:
  /// **'取消选择'**
  String get clearSelection;

  /// No description provided for @clearCacheConfirmMessage.
  ///
  /// In zh, this message translates to:
  /// **'确定要清除所有缓存数据吗？这将释放磁盘空间，但可能会暂时降低应用程序的速度。'**
  String get clearCacheConfirmMessage;

  /// No description provided for @close.
  ///
  /// In zh, this message translates to:
  /// **'关闭'**
  String get close;

  /// No description provided for @code.
  ///
  /// In zh, this message translates to:
  /// **'代码'**
  String get code;

  /// No description provided for @collapse.
  ///
  /// In zh, this message translates to:
  /// **'收起'**
  String get collapse;

  /// No description provided for @collectionDate.
  ///
  /// In zh, this message translates to:
  /// **'采集日期'**
  String get collectionDate;

  /// No description provided for @collectionTime.
  ///
  /// In zh, this message translates to:
  /// **'采集时间'**
  String get collectionTime;

  /// No description provided for @color.
  ///
  /// In zh, this message translates to:
  /// **'颜色'**
  String get color;

  /// No description provided for @colorCode.
  ///
  /// In zh, this message translates to:
  /// **'颜色代码'**
  String get colorCode;

  /// No description provided for @colorCodeHelp.
  ///
  /// In zh, this message translates to:
  /// **'输入6位十六进制颜色代码 (例如: FF5500)'**
  String get colorCodeHelp;

  /// No description provided for @colorCodeInvalid.
  ///
  /// In zh, this message translates to:
  /// **'无效的颜色代码'**
  String get colorCodeInvalid;

  /// No description provided for @colorInversion.
  ///
  /// In zh, this message translates to:
  /// **'颜色反转'**
  String get colorInversion;

  /// No description provided for @colorPicker.
  ///
  /// In zh, this message translates to:
  /// **'选择颜色'**
  String get colorPicker;

  /// No description provided for @colorSettings.
  ///
  /// In zh, this message translates to:
  /// **'颜色设置'**
  String get colorSettings;

  /// No description provided for @commonProperties.
  ///
  /// In zh, this message translates to:
  /// **'通用属性'**
  String get commonProperties;

  /// No description provided for @commonTags.
  ///
  /// In zh, this message translates to:
  /// **'常用标签:'**
  String get commonTags;

  /// No description provided for @completingSave.
  ///
  /// In zh, this message translates to:
  /// **'完成保存...'**
  String get completingSave;

  /// No description provided for @configKey.
  ///
  /// In zh, this message translates to:
  /// **'配置键'**
  String get configKey;

  /// No description provided for @configManagement.
  ///
  /// In zh, this message translates to:
  /// **'配置管理'**
  String get configManagement;

  /// No description provided for @configManagementDescription.
  ///
  /// In zh, this message translates to:
  /// **'管理书法风格和书写工具配置'**
  String get configManagementDescription;

  /// No description provided for @configManagementTitle.
  ///
  /// In zh, this message translates to:
  /// **'书法风格管理'**
  String get configManagementTitle;

  /// No description provided for @configInitializing.
  ///
  /// In zh, this message translates to:
  /// **'正在初始化配置...'**
  String get configInitializing;

  /// No description provided for @configInitializationFailed.
  ///
  /// In zh, this message translates to:
  /// **'配置初始化失败'**
  String get configInitializationFailed;

  /// No description provided for @itemsCount.
  ///
  /// In zh, this message translates to:
  /// **'{count} 个选项'**
  String itemsCount(Object count);

  /// No description provided for @writingToolManagement.
  ///
  /// In zh, this message translates to:
  /// **'书写工具管理'**
  String get writingToolManagement;

  /// No description provided for @confirm.
  ///
  /// In zh, this message translates to:
  /// **'确定'**
  String get confirm;

  /// No description provided for @confirmDelete.
  ///
  /// In zh, this message translates to:
  /// **'确认删除'**
  String get confirmDelete;

  /// No description provided for @confirmDeleteAll.
  ///
  /// In zh, this message translates to:
  /// **'确认删除所有'**
  String get confirmDeleteAll;

  /// No description provided for @confirmOverwrite.
  ///
  /// In zh, this message translates to:
  /// **'确认覆盖'**
  String get confirmOverwrite;

  /// No description provided for @confirmRemoveFromCategory.
  ///
  /// In zh, this message translates to:
  /// **'确定要将选中的{count}个项目从当前分类中移除吗？'**
  String confirmRemoveFromCategory(Object count);

  /// No description provided for @confirmShortcuts.
  ///
  /// In zh, this message translates to:
  /// **'快捷键：Enter 确认，Esc 取消'**
  String get confirmShortcuts;

  /// No description provided for @contentProperties.
  ///
  /// In zh, this message translates to:
  /// **'内容属性'**
  String get contentProperties;

  /// No description provided for @contentSettings.
  ///
  /// In zh, this message translates to:
  /// **'内容设置'**
  String get contentSettings;

  /// No description provided for @copy.
  ///
  /// In zh, this message translates to:
  /// **'复制 (Ctrl+Shift+C)'**
  String get copy;

  /// No description provided for @copyFormat.
  ///
  /// In zh, this message translates to:
  /// **'复制格式 (Alt+Q)'**
  String get copyFormat;

  /// No description provided for @copyVersionInfo.
  ///
  /// In zh, this message translates to:
  /// **'复制版本信息'**
  String get copyVersionInfo;

  /// No description provided for @copySelected.
  ///
  /// In zh, this message translates to:
  /// **'复制选中项目'**
  String get copySelected;

  /// No description provided for @couldNotGetFilePath.
  ///
  /// In zh, this message translates to:
  /// **'无法获取文件路径'**
  String get couldNotGetFilePath;

  /// No description provided for @create.
  ///
  /// In zh, this message translates to:
  /// **'创建'**
  String get create;

  /// No description provided for @createBackup.
  ///
  /// In zh, this message translates to:
  /// **'创建备份'**
  String get createBackup;

  /// No description provided for @createBackupDescription.
  ///
  /// In zh, this message translates to:
  /// **'导入前创建备份'**
  String get createBackupDescription;

  /// No description provided for @createExportDirectoryFailed.
  ///
  /// In zh, this message translates to:
  /// **'创建导出目录失败{error}'**
  String createExportDirectoryFailed(Object error);

  /// No description provided for @createTime.
  ///
  /// In zh, this message translates to:
  /// **'创建时间'**
  String get createTime;

  /// No description provided for @createdAt.
  ///
  /// In zh, this message translates to:
  /// **'创建时间'**
  String get createdAt;

  /// No description provided for @creatingBackup.
  ///
  /// In zh, this message translates to:
  /// **'正在创建备份...'**
  String get creatingBackup;

  /// No description provided for @creationDate.
  ///
  /// In zh, this message translates to:
  /// **'创作日期'**
  String get creationDate;

  /// No description provided for @cropBottom.
  ///
  /// In zh, this message translates to:
  /// **'底部裁剪'**
  String get cropBottom;

  /// No description provided for @cropLeft.
  ///
  /// In zh, this message translates to:
  /// **'左侧裁剪'**
  String get cropLeft;

  /// No description provided for @cropRight.
  ///
  /// In zh, this message translates to:
  /// **'右侧裁剪'**
  String get cropRight;

  /// No description provided for @cropTop.
  ///
  /// In zh, this message translates to:
  /// **'顶部裁剪'**
  String get cropTop;

  /// No description provided for @cropping.
  ///
  /// In zh, this message translates to:
  /// **'裁剪'**
  String get cropping;

  /// No description provided for @croppingApplied.
  ///
  /// In zh, this message translates to:
  /// **'(裁剪：左{left}px，上{top}px，右{right}px，下{bottom}px)'**
  String croppingApplied(Object bottom, Object left, Object right, Object top);

  /// No description provided for @currentCharInversion.
  ///
  /// In zh, this message translates to:
  /// **'当前字符反转'**
  String get currentCharInversion;

  /// No description provided for @currentPage.
  ///
  /// In zh, this message translates to:
  /// **'当前页面'**
  String get currentPage;

  /// No description provided for @custom.
  ///
  /// In zh, this message translates to:
  /// **'自定义'**
  String get custom;

  /// No description provided for @customRange.
  ///
  /// In zh, this message translates to:
  /// **'自定义范围'**
  String get customRange;

  /// No description provided for @customSize.
  ///
  /// In zh, this message translates to:
  /// **'自定义大小'**
  String get customSize;

  /// No description provided for @cutSelected.
  ///
  /// In zh, this message translates to:
  /// **'剪切选中项目'**
  String get cutSelected;

  /// No description provided for @dangerZone.
  ///
  /// In zh, this message translates to:
  /// **'危险区域'**
  String get dangerZone;

  /// No description provided for @dataEmpty.
  ///
  /// In zh, this message translates to:
  /// **'数据为空'**
  String get dataEmpty;

  /// No description provided for @dataIncomplete.
  ///
  /// In zh, this message translates to:
  /// **'数据不完整'**
  String get dataIncomplete;

  /// No description provided for @days.
  ///
  /// In zh, this message translates to:
  /// **'{count, plural, =1{1天} other{{count}天}}'**
  String days(num count);

  /// No description provided for @delete.
  ///
  /// In zh, this message translates to:
  /// **'删除 (Ctrl+D)'**
  String get delete;

  /// No description provided for @deleteAll.
  ///
  /// In zh, this message translates to:
  /// **'全部删除'**
  String get deleteAll;

  /// No description provided for @deleteBackup.
  ///
  /// In zh, this message translates to:
  /// **'删除备份'**
  String get deleteBackup;

  /// No description provided for @deleteCategory.
  ///
  /// In zh, this message translates to:
  /// **'删除分类'**
  String get deleteCategory;

  /// No description provided for @deleteCategoryOnly.
  ///
  /// In zh, this message translates to:
  /// **'仅删除分类'**
  String get deleteCategoryOnly;

  /// No description provided for @deleteCategoryWithFiles.
  ///
  /// In zh, this message translates to:
  /// **'删除分类及文件'**
  String get deleteCategoryWithFiles;

  /// No description provided for @deleteConfigItem.
  ///
  /// In zh, this message translates to:
  /// **'删除配置项'**
  String get deleteConfigItem;

  /// No description provided for @deleteConfigItemMessage.
  ///
  /// In zh, this message translates to:
  /// **'确定要删除这个配置项吗？此操作不可撤销。'**
  String get deleteConfigItemMessage;

  /// No description provided for @deleteConfirm.
  ///
  /// In zh, this message translates to:
  /// **'确认删除'**
  String get deleteConfirm;

  /// No description provided for @deleteElementConfirmMessage.
  ///
  /// In zh, this message translates to:
  /// **'确定要删除这些元素吗？'**
  String get deleteElementConfirmMessage;

  /// No description provided for @deleteFailed.
  ///
  /// In zh, this message translates to:
  /// **'删除失败：{error}'**
  String deleteFailed(Object error);

  /// No description provided for @deleteFailure.
  ///
  /// In zh, this message translates to:
  /// **'备份删除失败'**
  String get deleteFailure;

  /// No description provided for @deleteGroup.
  ///
  /// In zh, this message translates to:
  /// **'删除组'**
  String get deleteGroup;

  /// No description provided for @deleteGroupConfirm.
  ///
  /// In zh, this message translates to:
  /// **'确认删除组'**
  String get deleteGroupConfirm;

  /// No description provided for @deleteImage.
  ///
  /// In zh, this message translates to:
  /// **'删除图片'**
  String get deleteImage;

  /// No description provided for @deleteLastMessage.
  ///
  /// In zh, this message translates to:
  /// **'这是最后一项目。确定要删除吗？'**
  String get deleteLastMessage;

  /// No description provided for @deleteLayer.
  ///
  /// In zh, this message translates to:
  /// **'删除图层'**
  String get deleteLayer;

  /// No description provided for @deleteLayerConfirmMessage.
  ///
  /// In zh, this message translates to:
  /// **'确定要删除此图层吗？'**
  String get deleteLayerConfirmMessage;

  /// No description provided for @deleteLayerMessage.
  ///
  /// In zh, this message translates to:
  /// **'此图层上的所有元素将被删除。此操作无法撤消。'**
  String get deleteLayerMessage;

  /// No description provided for @deleteMessage.
  ///
  /// In zh, this message translates to:
  /// **'即将删除，此操作无法撤消。'**
  String get deleteMessage;

  /// No description provided for @deletePage.
  ///
  /// In zh, this message translates to:
  /// **'删除页面'**
  String get deletePage;

  /// No description provided for @deleteSelected.
  ///
  /// In zh, this message translates to:
  /// **'删除所选（Ctrl+D）'**
  String get deleteSelected;

  /// No description provided for @deleteSelectedArea.
  ///
  /// In zh, this message translates to:
  /// **'删除选中区域'**
  String get deleteSelectedArea;

  /// No description provided for @deleteSuccess.
  ///
  /// In zh, this message translates to:
  /// **'备份删除成功'**
  String get deleteSuccess;

  /// No description provided for @deleteText.
  ///
  /// In zh, this message translates to:
  /// **'删除'**
  String get deleteText;

  /// No description provided for @deleting.
  ///
  /// In zh, this message translates to:
  /// **'正在删除...'**
  String get deleting;

  /// No description provided for @descending.
  ///
  /// In zh, this message translates to:
  /// **'降序'**
  String get descending;

  /// No description provided for @deselectAll.
  ///
  /// In zh, this message translates to:
  /// **'取消选择'**
  String get deselectAll;

  /// No description provided for @detail.
  ///
  /// In zh, this message translates to:
  /// **'详情'**
  String get detail;

  /// No description provided for @dimensions.
  ///
  /// In zh, this message translates to:
  /// **'尺寸'**
  String get dimensions;

  /// No description provided for @disabled.
  ///
  /// In zh, this message translates to:
  /// **'已禁用'**
  String get disabled;

  /// No description provided for @disabledDescription.
  ///
  /// In zh, this message translates to:
  /// **'禁用 - 在选择器中隐藏'**
  String get disabledDescription;

  /// No description provided for @diskCacheSize.
  ///
  /// In zh, this message translates to:
  /// **'磁盘缓存大小'**
  String get diskCacheSize;

  /// No description provided for @diskCacheSizeDescription.
  ///
  /// In zh, this message translates to:
  /// **'磁盘缓存的最大大小'**
  String get diskCacheSizeDescription;

  /// No description provided for @diskCacheTtl.
  ///
  /// In zh, this message translates to:
  /// **'磁盘缓存生命周期'**
  String get diskCacheTtl;

  /// No description provided for @diskCacheTtlDescription.
  ///
  /// In zh, this message translates to:
  /// **'缓存文件在磁盘上保留的时间'**
  String get diskCacheTtlDescription;

  /// No description provided for @displayMode.
  ///
  /// In zh, this message translates to:
  /// **'显示模式'**
  String get displayMode;

  /// No description provided for @displayName.
  ///
  /// In zh, this message translates to:
  /// **'显示名称'**
  String get displayName;

  /// No description provided for @displayNameCannotBeEmpty.
  ///
  /// In zh, this message translates to:
  /// **'显示名称不能为空'**
  String get displayNameCannotBeEmpty;

  /// No description provided for @displayNameHint.
  ///
  /// In zh, this message translates to:
  /// **'用户界面中显示的名称'**
  String get displayNameHint;

  /// No description provided for @displayNameMaxLength.
  ///
  /// In zh, this message translates to:
  /// **'显示名称最多100个字符'**
  String get displayNameMaxLength;

  /// No description provided for @displayNameRequired.
  ///
  /// In zh, this message translates to:
  /// **'请输入显示名称'**
  String get displayNameRequired;

  /// No description provided for @distributeHorizontally.
  ///
  /// In zh, this message translates to:
  /// **'水平均匀分布'**
  String get distributeHorizontally;

  /// No description provided for @distributeVertically.
  ///
  /// In zh, this message translates to:
  /// **'垂直均匀分布'**
  String get distributeVertically;

  /// No description provided for @distribution.
  ///
  /// In zh, this message translates to:
  /// **'分布'**
  String get distribution;

  /// No description provided for @done.
  ///
  /// In zh, this message translates to:
  /// **'完成'**
  String get done;

  /// No description provided for @dropToImportImages.
  ///
  /// In zh, this message translates to:
  /// **'释放鼠标以导入图片'**
  String get dropToImportImages;

  /// No description provided for @dynasty.
  ///
  /// In zh, this message translates to:
  /// **'朝代'**
  String get dynasty;

  /// No description provided for @edit.
  ///
  /// In zh, this message translates to:
  /// **'编辑'**
  String get edit;

  /// No description provided for @editConfigItem.
  ///
  /// In zh, this message translates to:
  /// **'编辑配置项'**
  String get editConfigItem;

  /// No description provided for @editField.
  ///
  /// In zh, this message translates to:
  /// **'编辑{field}'**
  String editField(Object field);

  /// No description provided for @editGroupContents.
  ///
  /// In zh, this message translates to:
  /// **'编辑组内容'**
  String get editGroupContents;

  /// No description provided for @editGroupContentsDescription.
  ///
  /// In zh, this message translates to:
  /// **'编辑已选组的内容'**
  String get editGroupContentsDescription;

  /// No description provided for @editLabel.
  ///
  /// In zh, this message translates to:
  /// **'编辑{label}'**
  String editLabel(Object label);

  /// No description provided for @editOperations.
  ///
  /// In zh, this message translates to:
  /// **'编辑操作'**
  String get editOperations;

  /// No description provided for @editTitle.
  ///
  /// In zh, this message translates to:
  /// **'编辑标题'**
  String get editTitle;

  /// No description provided for @elementCopied.
  ///
  /// In zh, this message translates to:
  /// **'元素已复制到剪贴板'**
  String get elementCopied;

  /// No description provided for @elementCopiedToClipboard.
  ///
  /// In zh, this message translates to:
  /// **'元素已复制到剪贴板'**
  String get elementCopiedToClipboard;

  /// No description provided for @elementHeight.
  ///
  /// In zh, this message translates to:
  /// **'高'**
  String get elementHeight;

  /// No description provided for @elementId.
  ///
  /// In zh, this message translates to:
  /// **'元素ID'**
  String get elementId;

  /// No description provided for @elementSize.
  ///
  /// In zh, this message translates to:
  /// **'大小'**
  String get elementSize;

  /// No description provided for @elementWidth.
  ///
  /// In zh, this message translates to:
  /// **'宽'**
  String get elementWidth;

  /// No description provided for @elements.
  ///
  /// In zh, this message translates to:
  /// **'元素'**
  String get elements;

  /// No description provided for @empty.
  ///
  /// In zh, this message translates to:
  /// **'空'**
  String get empty;

  /// No description provided for @emptyGroup.
  ///
  /// In zh, this message translates to:
  /// **'空组合'**
  String get emptyGroup;

  /// No description provided for @emptyStateError.
  ///
  /// In zh, this message translates to:
  /// **'加载失败,请稍后再试'**
  String get emptyStateError;

  /// No description provided for @emptyStateNoCharacters.
  ///
  /// In zh, this message translates to:
  /// **'没有字形,从作品中提取字形后可在此查看'**
  String get emptyStateNoCharacters;

  /// No description provided for @emptyStateNoPractices.
  ///
  /// In zh, this message translates to:
  /// **'没有字帖，点击添加按钮创建新字帖'**
  String get emptyStateNoPractices;

  /// No description provided for @emptyStateNoResults.
  ///
  /// In zh, this message translates to:
  /// **'没有找到匹配的结果,尝试更改搜索条件'**
  String get emptyStateNoResults;

  /// No description provided for @emptyStateNoSelection.
  ///
  /// In zh, this message translates to:
  /// **'未选择任何项目,点击项目以选择'**
  String get emptyStateNoSelection;

  /// No description provided for @emptyStateNoWorks.
  ///
  /// In zh, this message translates to:
  /// **'没有作品，点击添加按钮导入作品'**
  String get emptyStateNoWorks;

  /// No description provided for @enabled.
  ///
  /// In zh, this message translates to:
  /// **'已启用'**
  String get enabled;

  /// No description provided for @endDate.
  ///
  /// In zh, this message translates to:
  /// **'结束日期'**
  String get endDate;

  /// No description provided for @enterCategoryName.
  ///
  /// In zh, this message translates to:
  /// **'请输入分类名称'**
  String get enterCategoryName;

  /// No description provided for @enterTagHint.
  ///
  /// In zh, this message translates to:
  /// **'输入标签并按Enter'**
  String get enterTagHint;

  /// No description provided for @error.
  ///
  /// In zh, this message translates to:
  /// **'错误：{message}'**
  String error(Object message);

  /// No description provided for @exit.
  ///
  /// In zh, this message translates to:
  /// **'退出'**
  String get exit;

  /// No description provided for @exitBatchMode.
  ///
  /// In zh, this message translates to:
  /// **'退出批量模式'**
  String get exitBatchMode;

  /// No description provided for @exitPreview.
  ///
  /// In zh, this message translates to:
  /// **'退出预览模式'**
  String get exitPreview;

  /// No description provided for @expand.
  ///
  /// In zh, this message translates to:
  /// **'展开'**
  String get expand;

  /// No description provided for @export.
  ///
  /// In zh, this message translates to:
  /// **'导出'**
  String get export;

  /// No description provided for @exportBackup.
  ///
  /// In zh, this message translates to:
  /// **'导出备份'**
  String get exportBackup;

  /// No description provided for @exportConfig.
  ///
  /// In zh, this message translates to:
  /// **'导出配置'**
  String get exportConfig;

  /// No description provided for @exportDialogRangeExample.
  ///
  /// In zh, this message translates to:
  /// **'例如: 1-3,5,7-9'**
  String get exportDialogRangeExample;

  /// No description provided for @exportDimensions.
  ///
  /// In zh, this message translates to:
  /// **'{width}厘米 × {height}厘米 ({orientation})'**
  String exportDimensions(Object height, Object orientation, Object width);

  /// No description provided for @exportFailure.
  ///
  /// In zh, this message translates to:
  /// **'备份导出失败'**
  String get exportFailure;

  /// No description provided for @exportNotImplemented.
  ///
  /// In zh, this message translates to:
  /// **'配置导出功能待实现'**
  String get exportNotImplemented;

  /// No description provided for @exportSuccess.
  ///
  /// In zh, this message translates to:
  /// **'备份导出成功'**
  String get exportSuccess;

  /// No description provided for @exportType.
  ///
  /// In zh, this message translates to:
  /// **'导出格式'**
  String get exportType;

  /// No description provided for @exportFormat.
  ///
  /// In zh, this message translates to:
  /// **'导出格式'**
  String get exportFormat;

  /// No description provided for @exportOptions.
  ///
  /// In zh, this message translates to:
  /// **'导出选项'**
  String get exportOptions;

  /// No description provided for @exportSummary.
  ///
  /// In zh, this message translates to:
  /// **'导出摘要'**
  String get exportSummary;

  /// No description provided for @selectedItems.
  ///
  /// In zh, this message translates to:
  /// **'选中项目'**
  String get selectedItems;

  /// No description provided for @exportLocation.
  ///
  /// In zh, this message translates to:
  /// **'导出位置'**
  String get exportLocation;

  /// No description provided for @selectExportLocationHint.
  ///
  /// In zh, this message translates to:
  /// **'选择导出位置...'**
  String get selectExportLocationHint;

  /// No description provided for @includeImages.
  ///
  /// In zh, this message translates to:
  /// **'包含图片'**
  String get includeImages;

  /// No description provided for @includeImagesDescription.
  ///
  /// In zh, this message translates to:
  /// **'导出相关的图片文件'**
  String get includeImagesDescription;

  /// No description provided for @includeMetadata.
  ///
  /// In zh, this message translates to:
  /// **'包含元数据'**
  String get includeMetadata;

  /// No description provided for @includeMetadataDescription.
  ///
  /// In zh, this message translates to:
  /// **'导出创建时间、标签等元数据'**
  String get includeMetadataDescription;

  /// No description provided for @compressData.
  ///
  /// In zh, this message translates to:
  /// **'压缩数据'**
  String get compressData;

  /// No description provided for @compressDataDescription.
  ///
  /// In zh, this message translates to:
  /// **'减小导出文件大小'**
  String get compressDataDescription;

  /// No description provided for @exportWorksOnly.
  ///
  /// In zh, this message translates to:
  /// **'仅导出作品'**
  String get exportWorksOnly;

  /// No description provided for @exportWorksWithCharacters.
  ///
  /// In zh, this message translates to:
  /// **'导出作品和关联集字（推荐）'**
  String get exportWorksWithCharacters;

  /// No description provided for @exportCharactersOnly.
  ///
  /// In zh, this message translates to:
  /// **'仅导出集字'**
  String get exportCharactersOnly;

  /// No description provided for @exportCharactersWithWorks.
  ///
  /// In zh, this message translates to:
  /// **'导出集字和来源作品（推荐）'**
  String get exportCharactersWithWorks;

  /// No description provided for @exportFullData.
  ///
  /// In zh, this message translates to:
  /// **'完整数据导出'**
  String get exportFullData;

  /// No description provided for @exportWorksOnlyDescription.
  ///
  /// In zh, this message translates to:
  /// **'仅包含选中的作品数据'**
  String get exportWorksOnlyDescription;

  /// No description provided for @exportWorksWithCharactersDescription.
  ///
  /// In zh, this message translates to:
  /// **'包含作品及其相关的集字数据'**
  String get exportWorksWithCharactersDescription;

  /// No description provided for @exportCharactersOnlyDescription.
  ///
  /// In zh, this message translates to:
  /// **'仅包含选中的集字数据'**
  String get exportCharactersOnlyDescription;

  /// No description provided for @exportCharactersWithWorksDescription.
  ///
  /// In zh, this message translates to:
  /// **'包含集字及其来源作品数据'**
  String get exportCharactersWithWorksDescription;

  /// No description provided for @exportFullDataDescription.
  ///
  /// In zh, this message translates to:
  /// **'包含所有相关数据'**
  String get exportFullDataDescription;

  /// No description provided for @jsonFile.
  ///
  /// In zh, this message translates to:
  /// **'JSON 文件'**
  String get jsonFile;

  /// No description provided for @zipFile.
  ///
  /// In zh, this message translates to:
  /// **'ZIP 压缩包'**
  String get zipFile;

  /// No description provided for @backupFile.
  ///
  /// In zh, this message translates to:
  /// **'备份文件'**
  String get backupFile;

  /// No description provided for @hideDetails.
  ///
  /// In zh, this message translates to:
  /// **'隐藏详情'**
  String get hideDetails;

  /// No description provided for @showDetails.
  ///
  /// In zh, this message translates to:
  /// **'显示详情'**
  String get showDetails;

  /// No description provided for @exportingDescription.
  ///
  /// In zh, this message translates to:
  /// **'正在导出数据，请稍候...'**
  String get exportingDescription;

  /// No description provided for @importingDescription.
  ///
  /// In zh, this message translates to:
  /// **'正在导入数据，请稍候...'**
  String get importingDescription;

  /// No description provided for @processing.
  ///
  /// In zh, this message translates to:
  /// **'处理中...'**
  String get processing;

  /// No description provided for @exporting.
  ///
  /// In zh, this message translates to:
  /// **'正在导出，请稍候...'**
  String get exporting;

  /// No description provided for @exportingBackup.
  ///
  /// In zh, this message translates to:
  /// **'导出备份中...'**
  String get exportingBackup;

  /// No description provided for @extract.
  ///
  /// In zh, this message translates to:
  /// **'提取'**
  String get extract;

  /// No description provided for @extractionError.
  ///
  /// In zh, this message translates to:
  /// **'提取发生错误'**
  String get extractionError;

  /// No description provided for @favorite.
  ///
  /// In zh, this message translates to:
  /// **'收藏'**
  String get favorite;

  /// No description provided for @favoritesOnly.
  ///
  /// In zh, this message translates to:
  /// **'仅显示收藏'**
  String get favoritesOnly;

  /// No description provided for @fileExtension.
  ///
  /// In zh, this message translates to:
  /// **'文件扩展名'**
  String get fileExtension;

  /// No description provided for @fileName.
  ///
  /// In zh, this message translates to:
  /// **'文件名称'**
  String get fileName;

  /// No description provided for @fileNotExist.
  ///
  /// In zh, this message translates to:
  /// **'文件不存在：{path}'**
  String fileNotExist(Object path);

  /// No description provided for @fileRestored.
  ///
  /// In zh, this message translates to:
  /// **'图片已从图库中恢复'**
  String get fileRestored;

  /// No description provided for @fileSize.
  ///
  /// In zh, this message translates to:
  /// **'文件大小'**
  String get fileSize;

  /// No description provided for @fileUpdatedAt.
  ///
  /// In zh, this message translates to:
  /// **'文件修改时间'**
  String get fileUpdatedAt;

  /// No description provided for @filenamePrefix.
  ///
  /// In zh, this message translates to:
  /// **'输入文件名前缀（将自动添加页码）'**
  String get filenamePrefix;

  /// No description provided for @files.
  ///
  /// In zh, this message translates to:
  /// **'文件数量'**
  String get files;

  /// No description provided for @filter.
  ///
  /// In zh, this message translates to:
  /// **'筛选'**
  String get filter;

  /// No description provided for @filterAndSort.
  ///
  /// In zh, this message translates to:
  /// **'筛选与排序'**
  String get filterAndSort;

  /// No description provided for @filterClear.
  ///
  /// In zh, this message translates to:
  /// **'清除'**
  String get filterClear;

  /// No description provided for @firstPage.
  ///
  /// In zh, this message translates to:
  /// **'第一页'**
  String get firstPage;

  /// No description provided for @fitContain.
  ///
  /// In zh, this message translates to:
  /// **'包含'**
  String get fitContain;

  /// No description provided for @fitCover.
  ///
  /// In zh, this message translates to:
  /// **'覆盖'**
  String get fitCover;

  /// No description provided for @fitFill.
  ///
  /// In zh, this message translates to:
  /// **'填充'**
  String get fitFill;

  /// No description provided for @fitHeight.
  ///
  /// In zh, this message translates to:
  /// **'适合高度'**
  String get fitHeight;

  /// No description provided for @fitMode.
  ///
  /// In zh, this message translates to:
  /// **'适配方式'**
  String get fitMode;

  /// No description provided for @fitWidth.
  ///
  /// In zh, this message translates to:
  /// **'适合宽度'**
  String get fitWidth;

  /// No description provided for @flip.
  ///
  /// In zh, this message translates to:
  /// **'翻转'**
  String get flip;

  /// No description provided for @flipHorizontal.
  ///
  /// In zh, this message translates to:
  /// **'水平翻转'**
  String get flipHorizontal;

  /// No description provided for @flipVertical.
  ///
  /// In zh, this message translates to:
  /// **'垂直翻转'**
  String get flipVertical;

  /// No description provided for @folderImportComplete.
  ///
  /// In zh, this message translates to:
  /// **'文件夹导入完成'**
  String get folderImportComplete;

  /// No description provided for @fontColor.
  ///
  /// In zh, this message translates to:
  /// **'文本颜色'**
  String get fontColor;

  /// No description provided for @fontFamily.
  ///
  /// In zh, this message translates to:
  /// **'字体'**
  String get fontFamily;

  /// No description provided for @fontSize.
  ///
  /// In zh, this message translates to:
  /// **'字体大小'**
  String get fontSize;

  /// No description provided for @fontStyle.
  ///
  /// In zh, this message translates to:
  /// **'字体样式'**
  String get fontStyle;

  /// No description provided for @fontWeight.
  ///
  /// In zh, this message translates to:
  /// **'字体粗细'**
  String get fontWeight;

  /// No description provided for @format.
  ///
  /// In zh, this message translates to:
  /// **'格式'**
  String get format;

  /// No description provided for @formatBrushActivated.
  ///
  /// In zh, this message translates to:
  /// **'格式刷已激活，点击目标元素应用样式'**
  String get formatBrushActivated;

  /// No description provided for @formatType.
  ///
  /// In zh, this message translates to:
  /// **'格式类型'**
  String get formatType;

  /// No description provided for @fromGallery.
  ///
  /// In zh, this message translates to:
  /// **'从图库选择'**
  String get fromGallery;

  /// No description provided for @fromLocal.
  ///
  /// In zh, this message translates to:
  /// **'从本地选择'**
  String get fromLocal;

  /// No description provided for @fullScreen.
  ///
  /// In zh, this message translates to:
  /// **'全屏显示'**
  String get fullScreen;

  /// No description provided for @geometryProperties.
  ///
  /// In zh, this message translates to:
  /// **'几何属性'**
  String get geometryProperties;

  /// No description provided for @getThumbnailSizeError.
  ///
  /// In zh, this message translates to:
  /// **'获取缩略图大小失败'**
  String get getThumbnailSizeError;

  /// No description provided for @gridSettings.
  ///
  /// In zh, this message translates to:
  /// **'网格设置'**
  String get gridSettings;

  /// No description provided for @gridSize.
  ///
  /// In zh, this message translates to:
  /// **'网格大小'**
  String get gridSize;

  /// No description provided for @gridSizeExtraLarge.
  ///
  /// In zh, this message translates to:
  /// **'特大'**
  String get gridSizeExtraLarge;

  /// No description provided for @gridSizeLarge.
  ///
  /// In zh, this message translates to:
  /// **'大'**
  String get gridSizeLarge;

  /// No description provided for @gridSizeMedium.
  ///
  /// In zh, this message translates to:
  /// **'中'**
  String get gridSizeMedium;

  /// No description provided for @gridSizeSmall.
  ///
  /// In zh, this message translates to:
  /// **'小'**
  String get gridSizeSmall;

  /// No description provided for @gridView.
  ///
  /// In zh, this message translates to:
  /// **'网格视图'**
  String get gridView;

  /// No description provided for @group.
  ///
  /// In zh, this message translates to:
  /// **'组合 (Ctrl+J)'**
  String get group;

  /// No description provided for @groupElements.
  ///
  /// In zh, this message translates to:
  /// **'组合元素'**
  String get groupElements;

  /// No description provided for @groupOperations.
  ///
  /// In zh, this message translates to:
  /// **'组合操作'**
  String get groupOperations;

  /// No description provided for @groupProperties.
  ///
  /// In zh, this message translates to:
  /// **'组属性'**
  String get groupProperties;

  /// No description provided for @height.
  ///
  /// In zh, this message translates to:
  /// **'高度'**
  String get height;

  /// No description provided for @help.
  ///
  /// In zh, this message translates to:
  /// **'帮助'**
  String get help;

  /// No description provided for @hideElement.
  ///
  /// In zh, this message translates to:
  /// **'隐藏元素'**
  String get hideElement;

  /// No description provided for @hideGrid.
  ///
  /// In zh, this message translates to:
  /// **'隐藏网格 (Ctrl+G)'**
  String get hideGrid;

  /// No description provided for @hideImagePreview.
  ///
  /// In zh, this message translates to:
  /// **'隐藏图片预览'**
  String get hideImagePreview;

  /// No description provided for @hideThumbnails.
  ///
  /// In zh, this message translates to:
  /// **'隐藏页面缩略图'**
  String get hideThumbnails;

  /// No description provided for @horizontalAlignment.
  ///
  /// In zh, this message translates to:
  /// **'水平对齐'**
  String get horizontalAlignment;

  /// No description provided for @horizontalLeftToRight.
  ///
  /// In zh, this message translates to:
  /// **'横排左起'**
  String get horizontalLeftToRight;

  /// No description provided for @horizontalRightToLeft.
  ///
  /// In zh, this message translates to:
  /// **'横排右起'**
  String get horizontalRightToLeft;

  /// No description provided for @hours.
  ///
  /// In zh, this message translates to:
  /// **'{count, plural, =1{1小时} other{{count}小时}}'**
  String hours(num count);

  /// No description provided for @image.
  ///
  /// In zh, this message translates to:
  /// **'图片'**
  String get image;

  /// No description provided for @imageCount.
  ///
  /// In zh, this message translates to:
  /// **'图像数量'**
  String get imageCount;

  /// No description provided for @imageExportFailed.
  ///
  /// In zh, this message translates to:
  /// **'图片导出失败'**
  String get imageExportFailed;

  /// No description provided for @imageFileNotExists.
  ///
  /// In zh, this message translates to:
  /// **'图片文件不存在'**
  String get imageFileNotExists;

  /// No description provided for @imageImportError.
  ///
  /// In zh, this message translates to:
  /// **'导入图像失败：{error}'**
  String imageImportError(Object error);

  /// No description provided for @imageImportSuccess.
  ///
  /// In zh, this message translates to:
  /// **'图像导入成功'**
  String get imageImportSuccess;

  /// No description provided for @imageIndexError.
  ///
  /// In zh, this message translates to:
  /// **'图片索引错误'**
  String get imageIndexError;

  /// No description provided for @imageInvalid.
  ///
  /// In zh, this message translates to:
  /// **'图像数据无效或已损坏'**
  String get imageInvalid;

  /// No description provided for @imageInvert.
  ///
  /// In zh, this message translates to:
  /// **'图像反转'**
  String get imageInvert;

  /// No description provided for @imageLoadError.
  ///
  /// In zh, this message translates to:
  /// **'加载图像失败：{error}...'**
  String imageLoadError(Object error);

  /// No description provided for @imageLoadFailed.
  ///
  /// In zh, this message translates to:
  /// **'图片加载失败'**
  String get imageLoadFailed;

  /// No description provided for @imageProcessingPathError.
  ///
  /// In zh, this message translates to:
  /// **'处理路径错误：{error}'**
  String imageProcessingPathError(Object error);

  /// No description provided for @imageProperties.
  ///
  /// In zh, this message translates to:
  /// **'图像属性'**
  String get imageProperties;

  /// No description provided for @imagePropertyPanelAutoImportNotice.
  ///
  /// In zh, this message translates to:
  /// **'所选图像将自动导入到您的图库中以便更好地管理'**
  String get imagePropertyPanelAutoImportNotice;

  /// No description provided for @imagePropertyPanelGeometryWarning.
  ///
  /// In zh, this message translates to:
  /// **'这些属性调整整个元素框，而不是图像内容本身'**
  String get imagePropertyPanelGeometryWarning;

  /// No description provided for @imagePropertyPanelPreviewNotice.
  ///
  /// In zh, this message translates to:
  /// **'注意：预览期间显示的重复日志是正常的'**
  String get imagePropertyPanelPreviewNotice;

  /// No description provided for @imagePropertyPanelTransformWarning.
  ///
  /// In zh, this message translates to:
  /// **'这些变换会修改图像内容本身，而不仅仅是元素框架'**
  String get imagePropertyPanelTransformWarning;

  /// No description provided for @imageResetSuccess.
  ///
  /// In zh, this message translates to:
  /// **'重置成功'**
  String get imageResetSuccess;

  /// No description provided for @imageRestoring.
  ///
  /// In zh, this message translates to:
  /// **'正在恢复图片数据...'**
  String get imageRestoring;

  /// No description provided for @imageSelection.
  ///
  /// In zh, this message translates to:
  /// **'图片选择'**
  String get imageSelection;

  /// No description provided for @imageTransform.
  ///
  /// In zh, this message translates to:
  /// **'图像变换'**
  String get imageTransform;

  /// No description provided for @imageTransformError.
  ///
  /// In zh, this message translates to:
  /// **'应用变换失败：{error}'**
  String imageTransformError(Object error);

  /// No description provided for @imageUpdated.
  ///
  /// In zh, this message translates to:
  /// **'图片已更新'**
  String get imageUpdated;

  /// No description provided for @implementationComingSoon.
  ///
  /// In zh, this message translates to:
  /// **'此功能正在开发中，敬请期待！'**
  String get implementationComingSoon;

  /// No description provided for @import.
  ///
  /// In zh, this message translates to:
  /// **'导入'**
  String get import;

  /// No description provided for @importBackup.
  ///
  /// In zh, this message translates to:
  /// **'导入备份'**
  String get importBackup;

  /// No description provided for @importConfig.
  ///
  /// In zh, this message translates to:
  /// **'导入配置'**
  String get importConfig;

  /// No description provided for @importFailed.
  ///
  /// In zh, this message translates to:
  /// **'导入失败: {error}'**
  String importFailed(Object error);

  /// No description provided for @importFailure.
  ///
  /// In zh, this message translates to:
  /// **'备份导入失败'**
  String get importFailure;

  /// No description provided for @importFileSuccess.
  ///
  /// In zh, this message translates to:
  /// **'成功导入文件'**
  String get importFileSuccess;

  /// No description provided for @importFiles.
  ///
  /// In zh, this message translates to:
  /// **'导入文件'**
  String get importFiles;

  /// No description provided for @importFolder.
  ///
  /// In zh, this message translates to:
  /// **'导入文件夹'**
  String get importFolder;

  /// No description provided for @importNotImplemented.
  ///
  /// In zh, this message translates to:
  /// **'配置导入功能待实现'**
  String get importNotImplemented;

  /// No description provided for @importPreview.
  ///
  /// In zh, this message translates to:
  /// **'导入预览'**
  String get importPreview;

  /// No description provided for @importRequirements.
  ///
  /// In zh, this message translates to:
  /// **'导入要求'**
  String get importRequirements;

  /// No description provided for @importSuccess.
  ///
  /// In zh, this message translates to:
  /// **'备份导入成功'**
  String get importSuccess;

  /// No description provided for @importSuccessMessage.
  ///
  /// In zh, this message translates to:
  /// **'成功导入 {count} 个文件'**
  String importSuccessMessage(Object count);

  /// No description provided for @importResultTitle.
  ///
  /// In zh, this message translates to:
  /// **'导入结果'**
  String get importResultTitle;

  /// No description provided for @importedWorks.
  ///
  /// In zh, this message translates to:
  /// **'导入作品'**
  String get importedWorks;

  /// No description provided for @importedCharacters.
  ///
  /// In zh, this message translates to:
  /// **'导入集字'**
  String get importedCharacters;

  /// No description provided for @importedImages.
  ///
  /// In zh, this message translates to:
  /// **'导入图片'**
  String get importedImages;

  /// No description provided for @importedFile.
  ///
  /// In zh, this message translates to:
  /// **'导入文件'**
  String get importedFile;

  /// No description provided for @importStatistics.
  ///
  /// In zh, this message translates to:
  /// **'导入统计'**
  String get importStatistics;

  /// No description provided for @processingDetails.
  ///
  /// In zh, this message translates to:
  /// **'处理详情'**
  String get processingDetails;

  /// No description provided for @skippedItems.
  ///
  /// In zh, this message translates to:
  /// **'跳过的项目'**
  String get skippedItems;

  /// No description provided for @overwrittenItems.
  ///
  /// In zh, this message translates to:
  /// **'覆盖的项目'**
  String get overwrittenItems;

  /// No description provided for @detailedReport.
  ///
  /// In zh, this message translates to:
  /// **'详细报告'**
  String get detailedReport;

  /// No description provided for @viewDetails.
  ///
  /// In zh, this message translates to:
  /// **'查看详情'**
  String get viewDetails;

  /// No description provided for @warnings.
  ///
  /// In zh, this message translates to:
  /// **'警告'**
  String get warnings;

  /// No description provided for @errors.
  ///
  /// In zh, this message translates to:
  /// **'错误'**
  String get errors;

  /// No description provided for @importing.
  ///
  /// In zh, this message translates to:
  /// **'导入中...'**
  String get importing;

  /// No description provided for @initializationFailed.
  ///
  /// In zh, this message translates to:
  /// **'初始化失败：{error}'**
  String initializationFailed(Object error);

  /// No description provided for @initializing.
  ///
  /// In zh, this message translates to:
  /// **'初始化中...'**
  String get initializing;

  /// No description provided for @inputCharacter.
  ///
  /// In zh, this message translates to:
  /// **'输入字符'**
  String get inputCharacter;

  /// No description provided for @inputChineseContent.
  ///
  /// In zh, this message translates to:
  /// **'请输入汉字内容'**
  String get inputChineseContent;

  /// No description provided for @inputFieldHint.
  ///
  /// In zh, this message translates to:
  /// **'请输入{field}'**
  String inputFieldHint(Object field);

  /// No description provided for @inputFileName.
  ///
  /// In zh, this message translates to:
  /// **'输入文件名'**
  String get inputFileName;

  /// No description provided for @inputHint.
  ///
  /// In zh, this message translates to:
  /// **'在此输入'**
  String get inputHint;

  /// No description provided for @inputNewTag.
  ///
  /// In zh, this message translates to:
  /// **'输入新标签...'**
  String get inputNewTag;

  /// No description provided for @inputTitle.
  ///
  /// In zh, this message translates to:
  /// **'请输入字帖标题'**
  String get inputTitle;

  /// No description provided for @invalidFilename.
  ///
  /// In zh, this message translates to:
  /// **'文件名不能包含以下字符: \\ / : * ? \" < > |'**
  String get invalidFilename;

  /// No description provided for @invalidNumber.
  ///
  /// In zh, this message translates to:
  /// **'请输入有效的数字'**
  String get invalidNumber;

  /// No description provided for @invertMode.
  ///
  /// In zh, this message translates to:
  /// **'反转模式'**
  String get invertMode;

  /// No description provided for @isActive.
  ///
  /// In zh, this message translates to:
  /// **'是否激活'**
  String get isActive;

  /// No description provided for @itemsPerPage.
  ///
  /// In zh, this message translates to:
  /// **'{count}项/页'**
  String itemsPerPage(Object count);

  /// No description provided for @keepBackupCount.
  ///
  /// In zh, this message translates to:
  /// **'保留备份数量'**
  String get keepBackupCount;

  /// No description provided for @keepBackupCountDescription.
  ///
  /// In zh, this message translates to:
  /// **'删除旧备份前保留的备份数量'**
  String get keepBackupCountDescription;

  /// No description provided for @key.
  ///
  /// In zh, this message translates to:
  /// **'键'**
  String get key;

  /// No description provided for @keyCannotBeEmpty.
  ///
  /// In zh, this message translates to:
  /// **'键不能为空'**
  String get keyCannotBeEmpty;

  /// No description provided for @keyExists.
  ///
  /// In zh, this message translates to:
  /// **'配置键已存在'**
  String get keyExists;

  /// No description provided for @keyHelperText.
  ///
  /// In zh, this message translates to:
  /// **'只能包含字母、数字、下划线和连字符'**
  String get keyHelperText;

  /// No description provided for @keyHint.
  ///
  /// In zh, this message translates to:
  /// **'配置项的唯一标识符'**
  String get keyHint;

  /// No description provided for @keyInvalidCharacters.
  ///
  /// In zh, this message translates to:
  /// **'键只能包含字母、数字、下划线和连字符'**
  String get keyInvalidCharacters;

  /// No description provided for @keyMaxLength.
  ///
  /// In zh, this message translates to:
  /// **'键最多50个字符'**
  String get keyMaxLength;

  /// No description provided for @keyMinLength.
  ///
  /// In zh, this message translates to:
  /// **'键至少需要2个字符'**
  String get keyMinLength;

  /// No description provided for @keyRequired.
  ///
  /// In zh, this message translates to:
  /// **'请输入配置键'**
  String get keyRequired;

  /// No description provided for @landscape.
  ///
  /// In zh, this message translates to:
  /// **'横向'**
  String get landscape;

  /// No description provided for @language.
  ///
  /// In zh, this message translates to:
  /// **'语言'**
  String get language;

  /// No description provided for @languageEn.
  ///
  /// In zh, this message translates to:
  /// **'English'**
  String get languageEn;

  /// No description provided for @languageSystem.
  ///
  /// In zh, this message translates to:
  /// **'系统'**
  String get languageSystem;

  /// No description provided for @languageZh.
  ///
  /// In zh, this message translates to:
  /// **'简体中文'**
  String get languageZh;

  /// No description provided for @last30Days.
  ///
  /// In zh, this message translates to:
  /// **'最近30天'**
  String get last30Days;

  /// No description provided for @last365Days.
  ///
  /// In zh, this message translates to:
  /// **'最近365天'**
  String get last365Days;

  /// No description provided for @last7Days.
  ///
  /// In zh, this message translates to:
  /// **'最近7天'**
  String get last7Days;

  /// No description provided for @last90Days.
  ///
  /// In zh, this message translates to:
  /// **'最近90天'**
  String get last90Days;

  /// No description provided for @lastBackupTime.
  ///
  /// In zh, this message translates to:
  /// **'上次备份时间'**
  String get lastBackupTime;

  /// No description provided for @lastMonth.
  ///
  /// In zh, this message translates to:
  /// **'上个月'**
  String get lastMonth;

  /// No description provided for @lastPage.
  ///
  /// In zh, this message translates to:
  /// **'最后一页'**
  String get lastPage;

  /// No description provided for @lastWeek.
  ///
  /// In zh, this message translates to:
  /// **'上周'**
  String get lastWeek;

  /// No description provided for @lastYear.
  ///
  /// In zh, this message translates to:
  /// **'去年'**
  String get lastYear;

  /// No description provided for @layer.
  ///
  /// In zh, this message translates to:
  /// **'图层'**
  String get layer;

  /// No description provided for @layer1.
  ///
  /// In zh, this message translates to:
  /// **'图层 1'**
  String get layer1;

  /// No description provided for @layerElements.
  ///
  /// In zh, this message translates to:
  /// **'图层元素'**
  String get layerElements;

  /// No description provided for @layerInfo.
  ///
  /// In zh, this message translates to:
  /// **'图层信息'**
  String get layerInfo;

  /// No description provided for @layerName.
  ///
  /// In zh, this message translates to:
  /// **'图层{index}'**
  String layerName(Object index);

  /// No description provided for @layerOperations.
  ///
  /// In zh, this message translates to:
  /// **'图层操作'**
  String get layerOperations;

  /// No description provided for @layerProperties.
  ///
  /// In zh, this message translates to:
  /// **'图层属性'**
  String get layerProperties;

  /// No description provided for @leave.
  ///
  /// In zh, this message translates to:
  /// **'离开'**
  String get leave;

  /// No description provided for @letterSpacing.
  ///
  /// In zh, this message translates to:
  /// **'字符间距'**
  String get letterSpacing;

  /// No description provided for @libraryCount.
  ///
  /// In zh, this message translates to:
  /// **'图库数量'**
  String get libraryCount;

  /// No description provided for @libraryManagement.
  ///
  /// In zh, this message translates to:
  /// **'图库'**
  String get libraryManagement;

  /// No description provided for @lineHeight.
  ///
  /// In zh, this message translates to:
  /// **'行高'**
  String get lineHeight;

  /// No description provided for @lineThrough.
  ///
  /// In zh, this message translates to:
  /// **'删除线'**
  String get lineThrough;

  /// No description provided for @listView.
  ///
  /// In zh, this message translates to:
  /// **'列表视图'**
  String get listView;

  /// No description provided for @loadConfigFailed.
  ///
  /// In zh, this message translates to:
  /// **'加载配置失败'**
  String get loadConfigFailed;

  /// No description provided for @loadFailed.
  ///
  /// In zh, this message translates to:
  /// **'加载失败'**
  String get loadFailed;

  /// No description provided for @loadPracticeSheetFailed.
  ///
  /// In zh, this message translates to:
  /// **'加载字帖失败'**
  String get loadPracticeSheetFailed;

  /// No description provided for @loading.
  ///
  /// In zh, this message translates to:
  /// **'加载中...'**
  String get loading;

  /// No description provided for @loadingImage.
  ///
  /// In zh, this message translates to:
  /// **'加载图像中...'**
  String get loadingImage;

  /// No description provided for @location.
  ///
  /// In zh, this message translates to:
  /// **'位置'**
  String get location;

  /// No description provided for @lock.
  ///
  /// In zh, this message translates to:
  /// **'锁定'**
  String get lock;

  /// No description provided for @lockElement.
  ///
  /// In zh, this message translates to:
  /// **'锁定元素'**
  String get lockElement;

  /// No description provided for @lockStatus.
  ///
  /// In zh, this message translates to:
  /// **'锁定状态'**
  String get lockStatus;

  /// No description provided for @lockUnlockAllElements.
  ///
  /// In zh, this message translates to:
  /// **'锁定/解锁所有元素'**
  String get lockUnlockAllElements;

  /// No description provided for @locked.
  ///
  /// In zh, this message translates to:
  /// **'已锁定'**
  String get locked;

  /// No description provided for @marginBottom.
  ///
  /// In zh, this message translates to:
  /// **'下'**
  String get marginBottom;

  /// No description provided for @marginLeft.
  ///
  /// In zh, this message translates to:
  /// **'左'**
  String get marginLeft;

  /// No description provided for @marginRight.
  ///
  /// In zh, this message translates to:
  /// **'右'**
  String get marginRight;

  /// No description provided for @marginTop.
  ///
  /// In zh, this message translates to:
  /// **'上'**
  String get marginTop;

  /// No description provided for @max.
  ///
  /// In zh, this message translates to:
  /// **'最大'**
  String get max;

  /// No description provided for @memoryDataCacheCapacity.
  ///
  /// In zh, this message translates to:
  /// **'内存数据缓存容量'**
  String get memoryDataCacheCapacity;

  /// No description provided for @memoryDataCacheCapacityDescription.
  ///
  /// In zh, this message translates to:
  /// **'内存中保留的数据项数量'**
  String get memoryDataCacheCapacityDescription;

  /// No description provided for @memoryImageCacheCapacity.
  ///
  /// In zh, this message translates to:
  /// **'内存图像缓存容量'**
  String get memoryImageCacheCapacity;

  /// No description provided for @memoryImageCacheCapacityDescription.
  ///
  /// In zh, this message translates to:
  /// **'内存中保留的图像数量'**
  String get memoryImageCacheCapacityDescription;

  /// No description provided for @metadata.
  ///
  /// In zh, this message translates to:
  /// **'元数据'**
  String get metadata;

  /// No description provided for @min.
  ///
  /// In zh, this message translates to:
  /// **'最小'**
  String get min;

  /// No description provided for @monospace.
  ///
  /// In zh, this message translates to:
  /// **'Monospace'**
  String get monospace;

  /// No description provided for @moveDown.
  ///
  /// In zh, this message translates to:
  /// **'下移 (Ctrl+Shift+B)'**
  String get moveDown;

  /// No description provided for @moveLayerDown.
  ///
  /// In zh, this message translates to:
  /// **'图层下移'**
  String get moveLayerDown;

  /// No description provided for @moveLayerUp.
  ///
  /// In zh, this message translates to:
  /// **'图层上移'**
  String get moveLayerUp;

  /// No description provided for @moveUp.
  ///
  /// In zh, this message translates to:
  /// **'上移 (Ctrl+Shift+T)'**
  String get moveUp;

  /// No description provided for @multiSelectTool.
  ///
  /// In zh, this message translates to:
  /// **'多选工具'**
  String get multiSelectTool;

  /// No description provided for @multipleFilesNote.
  ///
  /// In zh, this message translates to:
  /// **'注意: 将导出 {count} 个图片文件，文件名将自动添加页码。'**
  String multipleFilesNote(Object count);

  /// No description provided for @name.
  ///
  /// In zh, this message translates to:
  /// **'名称'**
  String get name;

  /// No description provided for @navCollapseSidebar.
  ///
  /// In zh, this message translates to:
  /// **'收起侧边栏'**
  String get navCollapseSidebar;

  /// No description provided for @navExpandSidebar.
  ///
  /// In zh, this message translates to:
  /// **'展开侧边栏'**
  String get navExpandSidebar;

  /// No description provided for @navigationBackToPrevious.
  ///
  /// In zh, this message translates to:
  /// **'返回到之前的页面'**
  String get navigationBackToPrevious;

  /// No description provided for @navigationNoHistory.
  ///
  /// In zh, this message translates to:
  /// **'无法返回'**
  String get navigationNoHistory;

  /// No description provided for @navigationNoHistoryMessage.
  ///
  /// In zh, this message translates to:
  /// **'已经到达当前功能区的最开始页面。'**
  String get navigationNoHistoryMessage;

  /// No description provided for @navigationSelectPage.
  ///
  /// In zh, this message translates to:
  /// **'您想返回到以下哪个页面？'**
  String get navigationSelectPage;

  /// No description provided for @newConfigItem.
  ///
  /// In zh, this message translates to:
  /// **'新增配置项'**
  String get newConfigItem;

  /// No description provided for @newItem.
  ///
  /// In zh, this message translates to:
  /// **'新建'**
  String get newItem;

  /// No description provided for @nextField.
  ///
  /// In zh, this message translates to:
  /// **'下一个字段'**
  String get nextField;

  /// No description provided for @nextPage.
  ///
  /// In zh, this message translates to:
  /// **'下一页'**
  String get nextPage;

  /// No description provided for @no.
  ///
  /// In zh, this message translates to:
  /// **'否'**
  String get no;

  /// No description provided for @noBackups.
  ///
  /// In zh, this message translates to:
  /// **'没有可用的备份'**
  String get noBackups;

  /// No description provided for @noCategories.
  ///
  /// In zh, this message translates to:
  /// **'无分类'**
  String get noCategories;

  /// No description provided for @noCharacters.
  ///
  /// In zh, this message translates to:
  /// **'未找到字符'**
  String get noCharacters;

  /// No description provided for @noCharactersFound.
  ///
  /// In zh, this message translates to:
  /// **'未找到匹配的字符'**
  String get noCharactersFound;

  /// No description provided for @noConfigItems.
  ///
  /// In zh, this message translates to:
  /// **'暂无{category}配置'**
  String noConfigItems(Object category);

  /// No description provided for @noCropping.
  ///
  /// In zh, this message translates to:
  /// **'（无裁剪）'**
  String get noCropping;

  /// No description provided for @noDisplayableImages.
  ///
  /// In zh, this message translates to:
  /// **'没有可显示的图片'**
  String get noDisplayableImages;

  /// No description provided for @noElementsInLayer.
  ///
  /// In zh, this message translates to:
  /// **'此图层中没有元素'**
  String get noElementsInLayer;

  /// No description provided for @noElementsSelected.
  ///
  /// In zh, this message translates to:
  /// **'未选择元素'**
  String get noElementsSelected;

  /// No description provided for @noImageSelected.
  ///
  /// In zh, this message translates to:
  /// **'未选择图片'**
  String get noImageSelected;

  /// No description provided for @noItemsSelected.
  ///
  /// In zh, this message translates to:
  /// **'未选择项目'**
  String get noItemsSelected;

  /// No description provided for @noImages.
  ///
  /// In zh, this message translates to:
  /// **'没有图片'**
  String get noImages;

  /// No description provided for @noLayers.
  ///
  /// In zh, this message translates to:
  /// **'无图层，请添加图层'**
  String get noLayers;

  /// No description provided for @noMatchingConfigItems.
  ///
  /// In zh, this message translates to:
  /// **'未找到匹配的配置项'**
  String get noMatchingConfigItems;

  /// No description provided for @noPageSelected.
  ///
  /// In zh, this message translates to:
  /// **'未选择页面'**
  String get noPageSelected;

  /// No description provided for @noPagesToExport.
  ///
  /// In zh, this message translates to:
  /// **'没有可导出的页面'**
  String get noPagesToExport;

  /// No description provided for @noPagesToPrint.
  ///
  /// In zh, this message translates to:
  /// **'没有可打印的页面'**
  String get noPagesToPrint;

  /// No description provided for @noPreviewAvailable.
  ///
  /// In zh, this message translates to:
  /// **'无有效预览'**
  String get noPreviewAvailable;

  /// No description provided for @noRegionBoxed.
  ///
  /// In zh, this message translates to:
  /// **'未选择区域'**
  String get noRegionBoxed;

  /// No description provided for @noRemarks.
  ///
  /// In zh, this message translates to:
  /// **'无备注'**
  String get noRemarks;

  /// No description provided for @noResults.
  ///
  /// In zh, this message translates to:
  /// **'未找到结果'**
  String get noResults;

  /// No description provided for @noTags.
  ///
  /// In zh, this message translates to:
  /// **'无标签'**
  String get noTags;

  /// No description provided for @noTexture.
  ///
  /// In zh, this message translates to:
  /// **'无纹理'**
  String get noTexture;

  /// No description provided for @noTopLevelCategory.
  ///
  /// In zh, this message translates to:
  /// **'无（顶级分类）'**
  String get noTopLevelCategory;

  /// No description provided for @noWorks.
  ///
  /// In zh, this message translates to:
  /// **'未找到作品'**
  String get noWorks;

  /// No description provided for @noWorksHint.
  ///
  /// In zh, this message translates to:
  /// **'尝试导入新作品或更改筛选条件'**
  String get noWorksHint;

  /// No description provided for @worksCount.
  ///
  /// In zh, this message translates to:
  /// **'{count} 个作品'**
  String worksCount(Object count);

  /// No description provided for @works.
  ///
  /// In zh, this message translates to:
  /// **'作品'**
  String get works;

  /// No description provided for @characters.
  ///
  /// In zh, this message translates to:
  /// **'集字'**
  String get characters;

  /// No description provided for @images.
  ///
  /// In zh, this message translates to:
  /// **'图片'**
  String get images;

  /// No description provided for @noiseReduction.
  ///
  /// In zh, this message translates to:
  /// **'降噪'**
  String get noiseReduction;

  /// No description provided for @none.
  ///
  /// In zh, this message translates to:
  /// **'无'**
  String get none;

  /// No description provided for @ok.
  ///
  /// In zh, this message translates to:
  /// **'确定'**
  String get ok;

  /// No description provided for @onlyOneCharacter.
  ///
  /// In zh, this message translates to:
  /// **'只允许一个字符'**
  String get onlyOneCharacter;

  /// No description provided for @opacity.
  ///
  /// In zh, this message translates to:
  /// **'不透明度'**
  String get opacity;

  /// No description provided for @openFolder.
  ///
  /// In zh, this message translates to:
  /// **'打开文件夹'**
  String get openFolder;

  /// No description provided for @openGalleryFailed.
  ///
  /// In zh, this message translates to:
  /// **'打开图库失败: {error}'**
  String openGalleryFailed(Object error);

  /// No description provided for @optional.
  ///
  /// In zh, this message translates to:
  /// **'可选'**
  String get optional;

  /// No description provided for @original.
  ///
  /// In zh, this message translates to:
  /// **'原始'**
  String get original;

  /// No description provided for @originalImageDesc.
  ///
  /// In zh, this message translates to:
  /// **'未经处理的原始图像'**
  String get originalImageDesc;

  /// No description provided for @outputQuality.
  ///
  /// In zh, this message translates to:
  /// **'输出质量'**
  String get outputQuality;

  /// No description provided for @overwrite.
  ///
  /// In zh, this message translates to:
  /// **'覆盖'**
  String get overwrite;

  /// No description provided for @overwriteConfirm.
  ///
  /// In zh, this message translates to:
  /// **'覆盖确认'**
  String get overwriteConfirm;

  /// No description provided for @overwriteExistingPractice.
  ///
  /// In zh, this message translates to:
  /// **'已存在名为\"{title}\"的字帖，是否覆盖？'**
  String overwriteExistingPractice(Object title);

  /// No description provided for @overwriteMessage.
  ///
  /// In zh, this message translates to:
  /// **'已存在标题为\"{title}\"的字帖，是否覆盖？'**
  String overwriteMessage(Object title);

  /// No description provided for @padding.
  ///
  /// In zh, this message translates to:
  /// **'内边距'**
  String get padding;

  /// No description provided for @pageMargins.
  ///
  /// In zh, this message translates to:
  /// **'页面边距 (厘米)'**
  String get pageMargins;

  /// No description provided for @pageNotImplemented.
  ///
  /// In zh, this message translates to:
  /// **'页面未实现'**
  String get pageNotImplemented;

  /// No description provided for @pageOrientation.
  ///
  /// In zh, this message translates to:
  /// **'页面方向'**
  String get pageOrientation;

  /// No description provided for @pageProperties.
  ///
  /// In zh, this message translates to:
  /// **'页面属性'**
  String get pageProperties;

  /// No description provided for @pageRange.
  ///
  /// In zh, this message translates to:
  /// **'页面范围'**
  String get pageRange;

  /// No description provided for @pageSize.
  ///
  /// In zh, this message translates to:
  /// **'页面大小'**
  String get pageSize;

  /// No description provided for @pages.
  ///
  /// In zh, this message translates to:
  /// **'页'**
  String get pages;

  /// No description provided for @parentCategory.
  ///
  /// In zh, this message translates to:
  /// **'父分类（可选）'**
  String get parentCategory;

  /// No description provided for @paste.
  ///
  /// In zh, this message translates to:
  /// **'粘贴 (Ctrl+Shift+V)'**
  String get paste;

  /// No description provided for @path.
  ///
  /// In zh, this message translates to:
  /// **'路径'**
  String get path;

  /// No description provided for @pdfExportFailed.
  ///
  /// In zh, this message translates to:
  /// **'PDF导出失败'**
  String get pdfExportFailed;

  /// No description provided for @pdfExportSuccess.
  ///
  /// In zh, this message translates to:
  /// **'PDF导出成功: {path}'**
  String pdfExportSuccess(Object path);

  /// No description provided for @pinyin.
  ///
  /// In zh, this message translates to:
  /// **'拼音'**
  String get pinyin;

  /// No description provided for @pixels.
  ///
  /// In zh, this message translates to:
  /// **'像素'**
  String get pixels;

  /// No description provided for @pleaseEnterValidNumber.
  ///
  /// In zh, this message translates to:
  /// **'请输入有效的数字'**
  String get pleaseEnterValidNumber;

  /// No description provided for @portrait.
  ///
  /// In zh, this message translates to:
  /// **'纵向'**
  String get portrait;

  /// No description provided for @position.
  ///
  /// In zh, this message translates to:
  /// **'位置'**
  String get position;

  /// No description provided for @ppiSetting.
  ///
  /// In zh, this message translates to:
  /// **'PPI设置（每英寸像素数）'**
  String get ppiSetting;

  /// No description provided for @practiceEditCollection.
  ///
  /// In zh, this message translates to:
  /// **'采集'**
  String get practiceEditCollection;

  /// No description provided for @practiceEditDefaultLayer.
  ///
  /// In zh, this message translates to:
  /// **'默认图层'**
  String get practiceEditDefaultLayer;

  /// No description provided for @practiceEditPracticeLoaded.
  ///
  /// In zh, this message translates to:
  /// **'字帖\"{title}\"加载成功'**
  String practiceEditPracticeLoaded(Object title);

  /// No description provided for @practiceEditTitle.
  ///
  /// In zh, this message translates to:
  /// **'字帖编辑'**
  String get practiceEditTitle;

  /// No description provided for @practiceListSearch.
  ///
  /// In zh, this message translates to:
  /// **'搜索字帖...'**
  String get practiceListSearch;

  /// No description provided for @practiceListTitle.
  ///
  /// In zh, this message translates to:
  /// **'字帖'**
  String get practiceListTitle;

  /// No description provided for @practiceSheetNotExists.
  ///
  /// In zh, this message translates to:
  /// **'字帖不存在'**
  String get practiceSheetNotExists;

  /// No description provided for @practiceSheetSaved.
  ///
  /// In zh, this message translates to:
  /// **'字帖 \"{title}\" 已保存'**
  String practiceSheetSaved(Object title);

  /// No description provided for @practices.
  ///
  /// In zh, this message translates to:
  /// **'字帖'**
  String get practices;

  /// No description provided for @preparingPrint.
  ///
  /// In zh, this message translates to:
  /// **'正在准备打印，请稍候...'**
  String get preparingPrint;

  /// No description provided for @preparingSave.
  ///
  /// In zh, this message translates to:
  /// **'准备保存...'**
  String get preparingSave;

  /// No description provided for @presetSize.
  ///
  /// In zh, this message translates to:
  /// **'预设大小'**
  String get presetSize;

  /// No description provided for @presets.
  ///
  /// In zh, this message translates to:
  /// **'预设'**
  String get presets;

  /// No description provided for @preview.
  ///
  /// In zh, this message translates to:
  /// **'预览'**
  String get preview;

  /// No description provided for @previewMode.
  ///
  /// In zh, this message translates to:
  /// **'预览模式'**
  String get previewMode;

  /// No description provided for @previewPage.
  ///
  /// In zh, this message translates to:
  /// **'(第 {current}/{total} 页)'**
  String previewPage(Object current, Object total);

  /// No description provided for @previousField.
  ///
  /// In zh, this message translates to:
  /// **'上一个字段'**
  String get previousField;

  /// No description provided for @previousPage.
  ///
  /// In zh, this message translates to:
  /// **'上一页'**
  String get previousPage;

  /// No description provided for @processingEraseData.
  ///
  /// In zh, this message translates to:
  /// **'处理擦除数据...'**
  String get processingEraseData;

  /// No description provided for @processingImage.
  ///
  /// In zh, this message translates to:
  /// **'处理图像中...'**
  String get processingImage;

  /// No description provided for @properties.
  ///
  /// In zh, this message translates to:
  /// **'属性'**
  String get properties;

  /// No description provided for @qualityHigh.
  ///
  /// In zh, this message translates to:
  /// **'高清 (2x)'**
  String get qualityHigh;

  /// No description provided for @qualityStandard.
  ///
  /// In zh, this message translates to:
  /// **'标准 (1x)'**
  String get qualityStandard;

  /// No description provided for @qualityUltra.
  ///
  /// In zh, this message translates to:
  /// **'超清 (3x)'**
  String get qualityUltra;

  /// No description provided for @recent.
  ///
  /// In zh, this message translates to:
  /// **'最近'**
  String get recent;

  /// No description provided for @redo.
  ///
  /// In zh, this message translates to:
  /// **'重做'**
  String get redo;

  /// No description provided for @refresh.
  ///
  /// In zh, this message translates to:
  /// **'刷新'**
  String get refresh;

  /// No description provided for @refreshDataFailed.
  ///
  /// In zh, this message translates to:
  /// **'刷新数据失败: {error}'**
  String refreshDataFailed(Object error);

  /// No description provided for @reload.
  ///
  /// In zh, this message translates to:
  /// **'重新加载'**
  String get reload;

  /// No description provided for @remarks.
  ///
  /// In zh, this message translates to:
  /// **'备注'**
  String get remarks;

  /// No description provided for @remarksHint.
  ///
  /// In zh, this message translates to:
  /// **'添加备注信息'**
  String get remarksHint;

  /// No description provided for @remove.
  ///
  /// In zh, this message translates to:
  /// **'移除'**
  String get remove;

  /// No description provided for @removeFavorite.
  ///
  /// In zh, this message translates to:
  /// **'从收藏中移除'**
  String get removeFavorite;

  /// No description provided for @removeFromCategory.
  ///
  /// In zh, this message translates to:
  /// **'从当前分类移除'**
  String get removeFromCategory;

  /// No description provided for @rename.
  ///
  /// In zh, this message translates to:
  /// **'重命名'**
  String get rename;

  /// No description provided for @renameLayer.
  ///
  /// In zh, this message translates to:
  /// **'重命名图层'**
  String get renameLayer;

  /// No description provided for @renderFailed.
  ///
  /// In zh, this message translates to:
  /// **'渲染失败'**
  String get renderFailed;

  /// No description provided for @reset.
  ///
  /// In zh, this message translates to:
  /// **'重置'**
  String get reset;

  /// No description provided for @resetCategoryConfig.
  ///
  /// In zh, this message translates to:
  /// **'重置{category}配置'**
  String resetCategoryConfig(Object category);

  /// No description provided for @resetCategoryConfigMessage.
  ///
  /// In zh, this message translates to:
  /// **'确定要将{category}配置重置为默认设置吗？此操作不可撤销。'**
  String resetCategoryConfigMessage(Object category);

  /// No description provided for @resetSettingsConfirmMessage.
  ///
  /// In zh, this message translates to:
  /// **'确定重置为默认值吗？'**
  String get resetSettingsConfirmMessage;

  /// No description provided for @resetSettingsConfirmTitle.
  ///
  /// In zh, this message translates to:
  /// **'重置设置'**
  String get resetSettingsConfirmTitle;

  /// No description provided for @resetToDefault.
  ///
  /// In zh, this message translates to:
  /// **'重置为默认'**
  String get resetToDefault;

  /// No description provided for @resetToDefaults.
  ///
  /// In zh, this message translates to:
  /// **'重置为默认值'**
  String get resetToDefaults;

  /// No description provided for @resetTransform.
  ///
  /// In zh, this message translates to:
  /// **'重置变换'**
  String get resetTransform;

  /// No description provided for @resetZoom.
  ///
  /// In zh, this message translates to:
  /// **'重置缩放'**
  String get resetZoom;

  /// No description provided for @resolution.
  ///
  /// In zh, this message translates to:
  /// **'分辨率'**
  String get resolution;

  /// No description provided for @restartAfterRestored.
  ///
  /// In zh, this message translates to:
  /// **'注意：恢复完成后应用将自动重启'**
  String get restartAfterRestored;

  /// No description provided for @restore.
  ///
  /// In zh, this message translates to:
  /// **'恢复'**
  String get restore;

  /// No description provided for @restoreBackup.
  ///
  /// In zh, this message translates to:
  /// **'恢复备份'**
  String get restoreBackup;

  /// No description provided for @restoreConfirmMessage.
  ///
  /// In zh, this message translates to:
  /// **'确定要从此备份恢复吗？这将替换您当前的所有数据。'**
  String get restoreConfirmMessage;

  /// No description provided for @restoreConfirmTitle.
  ///
  /// In zh, this message translates to:
  /// **'恢复确认'**
  String get restoreConfirmTitle;

  /// No description provided for @restoreFailure.
  ///
  /// In zh, this message translates to:
  /// **'恢复失败'**
  String get restoreFailure;

  /// No description provided for @restoringBackup.
  ///
  /// In zh, this message translates to:
  /// **'正在从备份恢复...'**
  String get restoringBackup;

  /// No description provided for @rotateLeft.
  ///
  /// In zh, this message translates to:
  /// **'向左旋转'**
  String get rotateLeft;

  /// No description provided for @rotateRight.
  ///
  /// In zh, this message translates to:
  /// **'向右旋转'**
  String get rotateRight;

  /// No description provided for @rotation.
  ///
  /// In zh, this message translates to:
  /// **'旋转'**
  String get rotation;

  /// No description provided for @sansSerif.
  ///
  /// In zh, this message translates to:
  /// **'Sans Serif'**
  String get sansSerif;

  /// No description provided for @save.
  ///
  /// In zh, this message translates to:
  /// **'保存'**
  String get save;

  /// No description provided for @saveAs.
  ///
  /// In zh, this message translates to:
  /// **'另存为'**
  String get saveAs;

  /// No description provided for @saveComplete.
  ///
  /// In zh, this message translates to:
  /// **'保存完成'**
  String get saveComplete;

  /// No description provided for @saveFailed.
  ///
  /// In zh, this message translates to:
  /// **'保存失败，请稍后重试'**
  String get saveFailed;

  /// No description provided for @saveFailedWithError.
  ///
  /// In zh, this message translates to:
  /// **'保存失败：{error}'**
  String saveFailedWithError(Object error);

  /// No description provided for @saveFailure.
  ///
  /// In zh, this message translates to:
  /// **'保存失败'**
  String get saveFailure;

  /// No description provided for @savePreview.
  ///
  /// In zh, this message translates to:
  /// **'字符预览：'**
  String get savePreview;

  /// No description provided for @saveSuccess.
  ///
  /// In zh, this message translates to:
  /// **'保存成功'**
  String get saveSuccess;

  /// No description provided for @saveTimeout.
  ///
  /// In zh, this message translates to:
  /// **'保存超时'**
  String get saveTimeout;

  /// No description provided for @savingToStorage.
  ///
  /// In zh, this message translates to:
  /// **'保存到存储中...'**
  String get savingToStorage;

  /// No description provided for @scale.
  ///
  /// In zh, this message translates to:
  /// **'缩放'**
  String get scale;

  /// No description provided for @search.
  ///
  /// In zh, this message translates to:
  /// **'搜索'**
  String get search;

  /// No description provided for @searchCategories.
  ///
  /// In zh, this message translates to:
  /// **'搜索分类...'**
  String get searchCategories;

  /// No description provided for @searchConfigDialogTitle.
  ///
  /// In zh, this message translates to:
  /// **'搜索配置项'**
  String get searchConfigDialogTitle;

  /// No description provided for @searchConfigHint.
  ///
  /// In zh, this message translates to:
  /// **'输入配置项名称或键'**
  String get searchConfigHint;

  /// No description provided for @searchConfigItems.
  ///
  /// In zh, this message translates to:
  /// **'搜索配置项'**
  String get searchConfigItems;

  /// No description provided for @searching.
  ///
  /// In zh, this message translates to:
  /// **'搜索中...'**
  String get searching;

  /// No description provided for @select.
  ///
  /// In zh, this message translates to:
  /// **'选择'**
  String get select;

  /// No description provided for @selectAll.
  ///
  /// In zh, this message translates to:
  /// **'全选 (Ctrl+Shift+A)'**
  String get selectAll;

  /// No description provided for @selectBackup.
  ///
  /// In zh, this message translates to:
  /// **'选择备份'**
  String get selectBackup;

  /// No description provided for @selectCategoryToApply.
  ///
  /// In zh, this message translates to:
  /// **'请选择要应用的分类:'**
  String get selectCategoryToApply;

  /// No description provided for @selectCharacterFirst.
  ///
  /// In zh, this message translates to:
  /// **'请先选择字符'**
  String get selectCharacterFirst;

  /// No description provided for @selectColor.
  ///
  /// In zh, this message translates to:
  /// **'选择{type}'**
  String selectColor(Object type);

  /// No description provided for @selectDate.
  ///
  /// In zh, this message translates to:
  /// **'选择日期'**
  String get selectDate;

  /// No description provided for @selectExportLocation.
  ///
  /// In zh, this message translates to:
  /// **'选择导出位置'**
  String get selectExportLocation;

  /// No description provided for @selectImage.
  ///
  /// In zh, this message translates to:
  /// **'选择图片'**
  String get selectImage;

  /// No description provided for @selectImportFile.
  ///
  /// In zh, this message translates to:
  /// **'选择备份文件'**
  String get selectImportFile;

  /// No description provided for @selectFileError.
  ///
  /// In zh, this message translates to:
  /// **'选择文件失败'**
  String get selectFileError;

  /// No description provided for @selectParentCategory.
  ///
  /// In zh, this message translates to:
  /// **'选择父分类'**
  String get selectParentCategory;

  /// No description provided for @selectTargetLayer.
  ///
  /// In zh, this message translates to:
  /// **'选择目标图层'**
  String get selectTargetLayer;

  /// No description provided for @selected.
  ///
  /// In zh, this message translates to:
  /// **'已选择'**
  String get selected;

  /// No description provided for @selectedCharacter.
  ///
  /// In zh, this message translates to:
  /// **'已选字符'**
  String get selectedCharacter;

  /// No description provided for @selectedCount.
  ///
  /// In zh, this message translates to:
  /// **'已选择{count}个'**
  String selectedCount(Object count);

  /// No description provided for @selectedElementNotFound.
  ///
  /// In zh, this message translates to:
  /// **'选中的元素未找到'**
  String get selectedElementNotFound;

  /// No description provided for @sendToBack.
  ///
  /// In zh, this message translates to:
  /// **'置于底层 (Ctrl+B)'**
  String get sendToBack;

  /// No description provided for @serif.
  ///
  /// In zh, this message translates to:
  /// **'Serif'**
  String get serif;

  /// No description provided for @setCategory.
  ///
  /// In zh, this message translates to:
  /// **'设置分类'**
  String get setCategory;

  /// No description provided for @setCategoryForItems.
  ///
  /// In zh, this message translates to:
  /// **'设置分类 ({count}个项目)'**
  String setCategoryForItems(Object count);

  /// No description provided for @settings.
  ///
  /// In zh, this message translates to:
  /// **'设置'**
  String get settings;

  /// No description provided for @settingsResetMessage.
  ///
  /// In zh, this message translates to:
  /// **'设置已重置为默认值'**
  String get settingsResetMessage;

  /// No description provided for @shortcuts.
  ///
  /// In zh, this message translates to:
  /// **'键盘快捷键'**
  String get shortcuts;

  /// No description provided for @showContour.
  ///
  /// In zh, this message translates to:
  /// **'显示轮廓'**
  String get showContour;

  /// No description provided for @showElement.
  ///
  /// In zh, this message translates to:
  /// **'显示元素'**
  String get showElement;

  /// No description provided for @showGrid.
  ///
  /// In zh, this message translates to:
  /// **'显示网格 (Ctrl+G)'**
  String get showGrid;

  /// No description provided for @showHideAllElements.
  ///
  /// In zh, this message translates to:
  /// **'显示/隐藏所有元素'**
  String get showHideAllElements;

  /// No description provided for @showImagePreview.
  ///
  /// In zh, this message translates to:
  /// **'显示图片预览'**
  String get showImagePreview;

  /// No description provided for @showThumbnails.
  ///
  /// In zh, this message translates to:
  /// **'显示页面缩略图'**
  String get showThumbnails;

  /// No description provided for @sort.
  ///
  /// In zh, this message translates to:
  /// **'排序'**
  String get sort;

  /// No description provided for @sortBy.
  ///
  /// In zh, this message translates to:
  /// **'排序方式'**
  String get sortBy;

  /// No description provided for @sortByCreateTime.
  ///
  /// In zh, this message translates to:
  /// **'按创建时间排序'**
  String get sortByCreateTime;

  /// No description provided for @sortByTitle.
  ///
  /// In zh, this message translates to:
  /// **'按标题排序'**
  String get sortByTitle;

  /// No description provided for @sortByUpdateTime.
  ///
  /// In zh, this message translates to:
  /// **'按更新时间排序'**
  String get sortByUpdateTime;

  /// No description provided for @sortOrder.
  ///
  /// In zh, this message translates to:
  /// **'排序'**
  String get sortOrder;

  /// No description provided for @sortOrderCannotBeEmpty.
  ///
  /// In zh, this message translates to:
  /// **'排序顺序不能为空'**
  String get sortOrderCannotBeEmpty;

  /// No description provided for @sortOrderHint.
  ///
  /// In zh, this message translates to:
  /// **'数字越小排序越靠前'**
  String get sortOrderHint;

  /// No description provided for @sortOrderLabel.
  ///
  /// In zh, this message translates to:
  /// **'排序顺序'**
  String get sortOrderLabel;

  /// No description provided for @sortOrderNumber.
  ///
  /// In zh, this message translates to:
  /// **'排序值必须是数字'**
  String get sortOrderNumber;

  /// No description provided for @sortOrderRange.
  ///
  /// In zh, this message translates to:
  /// **'排序顺序必须在1-999之间'**
  String get sortOrderRange;

  /// No description provided for @sortOrderRequired.
  ///
  /// In zh, this message translates to:
  /// **'请输入排序值'**
  String get sortOrderRequired;

  /// No description provided for @sourceHanSansFont.
  ///
  /// In zh, this message translates to:
  /// **'思源黑体 (Source Han Sans)'**
  String get sourceHanSansFont;

  /// No description provided for @sourceHanSerifFont.
  ///
  /// In zh, this message translates to:
  /// **'思源宋体 (Source Han Serif)'**
  String get sourceHanSerifFont;

  /// No description provided for @sourceInfo.
  ///
  /// In zh, this message translates to:
  /// **'出处信息'**
  String get sourceInfo;

  /// No description provided for @startDate.
  ///
  /// In zh, this message translates to:
  /// **'开始日期'**
  String get startDate;

  /// No description provided for @stateAndDisplay.
  ///
  /// In zh, this message translates to:
  /// **'状态与显示'**
  String get stateAndDisplay;

  /// No description provided for @status.
  ///
  /// In zh, this message translates to:
  /// **'状态'**
  String get status;

  /// No description provided for @storageDetails.
  ///
  /// In zh, this message translates to:
  /// **'存储详情'**
  String get storageDetails;

  /// No description provided for @storageLocation.
  ///
  /// In zh, this message translates to:
  /// **'存储位置'**
  String get storageLocation;

  /// No description provided for @storageSettings.
  ///
  /// In zh, this message translates to:
  /// **'存储设置'**
  String get storageSettings;

  /// No description provided for @storageUsed.
  ///
  /// In zh, this message translates to:
  /// **'已使用存储'**
  String get storageUsed;

  /// No description provided for @stretch.
  ///
  /// In zh, this message translates to:
  /// **'拉伸'**
  String get stretch;

  /// No description provided for @strokeCount.
  ///
  /// In zh, this message translates to:
  /// **'笔画'**
  String get strokeCount;

  /// No description provided for @submitFailed.
  ///
  /// In zh, this message translates to:
  /// **'提交失败：{error}'**
  String submitFailed(Object error);

  /// No description provided for @suggestedTags.
  ///
  /// In zh, this message translates to:
  /// **'建议标签'**
  String get suggestedTags;

  /// No description provided for @switchingPage.
  ///
  /// In zh, this message translates to:
  /// **'正在切换到字符页面...'**
  String get switchingPage;

  /// No description provided for @systemConfig.
  ///
  /// In zh, this message translates to:
  /// **'系统配置'**
  String get systemConfig;

  /// No description provided for @systemConfigItemNote.
  ///
  /// In zh, this message translates to:
  /// **'这是系统配置项，键值不可修改'**
  String get systemConfigItemNote;

  /// No description provided for @tabToNextField.
  ///
  /// In zh, this message translates to:
  /// **'按Tab导航到下一个字段'**
  String get tabToNextField;

  /// No description provided for @tagAddError.
  ///
  /// In zh, this message translates to:
  /// **'添加标签失败: {error}'**
  String tagAddError(Object error);

  /// No description provided for @tagHint.
  ///
  /// In zh, this message translates to:
  /// **'输入标签名称'**
  String get tagHint;

  /// No description provided for @tagRemoveError.
  ///
  /// In zh, this message translates to:
  /// **'移除标签失败, 错误: {error}'**
  String tagRemoveError(Object error);

  /// No description provided for @tags.
  ///
  /// In zh, this message translates to:
  /// **'标签'**
  String get tags;

  /// No description provided for @tagsAddHint.
  ///
  /// In zh, this message translates to:
  /// **'输入标签名称并按回车'**
  String get tagsAddHint;

  /// No description provided for @tagsHint.
  ///
  /// In zh, this message translates to:
  /// **'输入标签...'**
  String get tagsHint;

  /// No description provided for @tagsSelected.
  ///
  /// In zh, this message translates to:
  /// **'已选标签：'**
  String get tagsSelected;

  /// No description provided for @text.
  ///
  /// In zh, this message translates to:
  /// **'文本'**
  String get text;

  /// No description provided for @textAlign.
  ///
  /// In zh, this message translates to:
  /// **'文本对齐'**
  String get textAlign;

  /// No description provided for @textContent.
  ///
  /// In zh, this message translates to:
  /// **'文本内容'**
  String get textContent;

  /// No description provided for @textProperties.
  ///
  /// In zh, this message translates to:
  /// **'文本属性'**
  String get textProperties;

  /// No description provided for @textSettings.
  ///
  /// In zh, this message translates to:
  /// **'文本设置'**
  String get textSettings;

  /// No description provided for @textureFillMode.
  ///
  /// In zh, this message translates to:
  /// **'纹理填充模式'**
  String get textureFillMode;

  /// No description provided for @textureFillModeContain.
  ///
  /// In zh, this message translates to:
  /// **'包含'**
  String get textureFillModeContain;

  /// No description provided for @textureFillModeCover.
  ///
  /// In zh, this message translates to:
  /// **'覆盖'**
  String get textureFillModeCover;

  /// No description provided for @textureFillModeRepeat.
  ///
  /// In zh, this message translates to:
  /// **'重复'**
  String get textureFillModeRepeat;

  /// No description provided for @textureOpacity.
  ///
  /// In zh, this message translates to:
  /// **'纹理不透明度'**
  String get textureOpacity;

  /// No description provided for @themeMode.
  ///
  /// In zh, this message translates to:
  /// **'主题模式'**
  String get themeMode;

  /// No description provided for @themeModeDark.
  ///
  /// In zh, this message translates to:
  /// **'暗色'**
  String get themeModeDark;

  /// No description provided for @themeModeDescription.
  ///
  /// In zh, this message translates to:
  /// **'使用深色主题获得更好的夜间观看体验'**
  String get themeModeDescription;

  /// No description provided for @themeModeSystemDescription.
  ///
  /// In zh, this message translates to:
  /// **'根据系统设置自动切换深色/亮色主题'**
  String get themeModeSystemDescription;

  /// No description provided for @thisMonth.
  ///
  /// In zh, this message translates to:
  /// **'本月'**
  String get thisMonth;

  /// No description provided for @thisWeek.
  ///
  /// In zh, this message translates to:
  /// **'本周'**
  String get thisWeek;

  /// No description provided for @thisYear.
  ///
  /// In zh, this message translates to:
  /// **'今年'**
  String get thisYear;

  /// No description provided for @threshold.
  ///
  /// In zh, this message translates to:
  /// **'阈值'**
  String get threshold;

  /// No description provided for @thumbnailCheckFailed.
  ///
  /// In zh, this message translates to:
  /// **'缩略图检查失败'**
  String get thumbnailCheckFailed;

  /// No description provided for @thumbnailEmpty.
  ///
  /// In zh, this message translates to:
  /// **'缩略图文件为空'**
  String get thumbnailEmpty;

  /// No description provided for @thumbnailLoadError.
  ///
  /// In zh, this message translates to:
  /// **'加载缩略图失败'**
  String get thumbnailLoadError;

  /// No description provided for @thumbnailNotFound.
  ///
  /// In zh, this message translates to:
  /// **'未找到缩略图'**
  String get thumbnailNotFound;

  /// No description provided for @timeInfo.
  ///
  /// In zh, this message translates to:
  /// **'时间信息'**
  String get timeInfo;

  /// No description provided for @title.
  ///
  /// In zh, this message translates to:
  /// **'标题'**
  String get title;

  /// No description provided for @titleAlreadyExists.
  ///
  /// In zh, this message translates to:
  /// **'已存在相同标题的字帖，请使用其他标题'**
  String get titleAlreadyExists;

  /// No description provided for @titleCannotBeEmpty.
  ///
  /// In zh, this message translates to:
  /// **'标题不能为空'**
  String get titleCannotBeEmpty;

  /// No description provided for @titleExists.
  ///
  /// In zh, this message translates to:
  /// **'标题已存在'**
  String get titleExists;

  /// No description provided for @titleExistsMessage.
  ///
  /// In zh, this message translates to:
  /// **'已存在同名字帖。是否覆盖？'**
  String get titleExistsMessage;

  /// No description provided for @titleUpdated.
  ///
  /// In zh, this message translates to:
  /// **'标题已更新为\"{title}\"'**
  String titleUpdated(Object title);

  /// No description provided for @to.
  ///
  /// In zh, this message translates to:
  /// **'至'**
  String get to;

  /// No description provided for @today.
  ///
  /// In zh, this message translates to:
  /// **'今天'**
  String get today;

  /// No description provided for @toggleBackground.
  ///
  /// In zh, this message translates to:
  /// **'切换背景'**
  String get toggleBackground;

  /// No description provided for @toolModePanTooltip.
  ///
  /// In zh, this message translates to:
  /// **'拖拽工具 (Ctrl+V)'**
  String get toolModePanTooltip;

  /// No description provided for @toolModeSelectTooltip.
  ///
  /// In zh, this message translates to:
  /// **'框选工具 (Ctrl+B)'**
  String get toolModeSelectTooltip;

  /// No description provided for @total.
  ///
  /// In zh, this message translates to:
  /// **'总计'**
  String get total;

  /// No description provided for @totalItems.
  ///
  /// In zh, this message translates to:
  /// **'共 {count} 个'**
  String totalItems(Object count);

  /// No description provided for @transformApplied.
  ///
  /// In zh, this message translates to:
  /// **'变换已应用'**
  String get transformApplied;

  /// No description provided for @tryOtherKeywords.
  ///
  /// In zh, this message translates to:
  /// **'尝试使用其他关键词搜索'**
  String get tryOtherKeywords;

  /// No description provided for @type.
  ///
  /// In zh, this message translates to:
  /// **'类型'**
  String get type;

  /// No description provided for @underline.
  ///
  /// In zh, this message translates to:
  /// **'下划线'**
  String get underline;

  /// No description provided for @undo.
  ///
  /// In zh, this message translates to:
  /// **'撤销'**
  String get undo;

  /// No description provided for @ungroup.
  ///
  /// In zh, this message translates to:
  /// **'取消组合 (Ctrl+U)'**
  String get ungroup;

  /// No description provided for @ungroupConfirm.
  ///
  /// In zh, this message translates to:
  /// **'确认解组'**
  String get ungroupConfirm;

  /// No description provided for @ungroupDescription.
  ///
  /// In zh, this message translates to:
  /// **'确定要解散此组吗？'**
  String get ungroupDescription;

  /// No description provided for @unknown.
  ///
  /// In zh, this message translates to:
  /// **'未知'**
  String get unknown;

  /// No description provided for @unknownCategory.
  ///
  /// In zh, this message translates to:
  /// **'未知分类'**
  String get unknownCategory;

  /// No description provided for @unknownElementType.
  ///
  /// In zh, this message translates to:
  /// **'未知元素类型: {type}'**
  String unknownElementType(Object type);

  /// No description provided for @unknownError.
  ///
  /// In zh, this message translates to:
  /// **'未知错误'**
  String get unknownError;

  /// No description provided for @unlockElement.
  ///
  /// In zh, this message translates to:
  /// **'解锁元素'**
  String get unlockElement;

  /// No description provided for @unlocked.
  ///
  /// In zh, this message translates to:
  /// **'未锁定'**
  String get unlocked;

  /// No description provided for @unnamedElement.
  ///
  /// In zh, this message translates to:
  /// **'未命名元素'**
  String get unnamedElement;

  /// No description provided for @unnamedGroup.
  ///
  /// In zh, this message translates to:
  /// **'未命名组'**
  String get unnamedGroup;

  /// No description provided for @unnamedLayer.
  ///
  /// In zh, this message translates to:
  /// **'未命名图层'**
  String get unnamedLayer;

  /// No description provided for @unsavedChanges.
  ///
  /// In zh, this message translates to:
  /// **'有未保存的更改'**
  String get unsavedChanges;

  /// No description provided for @updateTime.
  ///
  /// In zh, this message translates to:
  /// **'更新时间'**
  String get updateTime;

  /// No description provided for @updatedAt.
  ///
  /// In zh, this message translates to:
  /// **'更新时间'**
  String get updatedAt;

  /// No description provided for @userConfig.
  ///
  /// In zh, this message translates to:
  /// **'用户配置'**
  String get userConfig;

  /// No description provided for @validChineseCharacter.
  ///
  /// In zh, this message translates to:
  /// **'请输入有效的汉字'**
  String get validChineseCharacter;

  /// No description provided for @valueTooLarge.
  ///
  /// In zh, this message translates to:
  /// **'{label}不能大于{max}'**
  String valueTooLarge(Object label, Object max);

  /// No description provided for @valueTooSmall.
  ///
  /// In zh, this message translates to:
  /// **'{label}不能小于{min}'**
  String valueTooSmall(Object label, Object min);

  /// No description provided for @verticalAlignment.
  ///
  /// In zh, this message translates to:
  /// **'垂直对齐'**
  String get verticalAlignment;

  /// No description provided for @verticalLeftToRight.
  ///
  /// In zh, this message translates to:
  /// **'竖排左起'**
  String get verticalLeftToRight;

  /// No description provided for @verticalRightToLeft.
  ///
  /// In zh, this message translates to:
  /// **'竖排右起'**
  String get verticalRightToLeft;

  /// No description provided for @visibility.
  ///
  /// In zh, this message translates to:
  /// **'可见性'**
  String get visibility;

  /// No description provided for @visible.
  ///
  /// In zh, this message translates to:
  /// **'可见'**
  String get visible;

  /// No description provided for @visualProperties.
  ///
  /// In zh, this message translates to:
  /// **'视觉属性'**
  String get visualProperties;

  /// No description provided for @visualSettings.
  ///
  /// In zh, this message translates to:
  /// **'视觉设置'**
  String get visualSettings;

  /// No description provided for @widgetRefRequired.
  ///
  /// In zh, this message translates to:
  /// **'需要WidgetRef才能创建CollectionPainter'**
  String get widgetRefRequired;

  /// No description provided for @width.
  ///
  /// In zh, this message translates to:
  /// **'宽度'**
  String get width;

  /// No description provided for @windowButtonMaximize.
  ///
  /// In zh, this message translates to:
  /// **'最大化'**
  String get windowButtonMaximize;

  /// No description provided for @windowButtonMinimize.
  ///
  /// In zh, this message translates to:
  /// **'最小化'**
  String get windowButtonMinimize;

  /// No description provided for @windowButtonRestore.
  ///
  /// In zh, this message translates to:
  /// **'还原'**
  String get windowButtonRestore;

  /// No description provided for @work.
  ///
  /// In zh, this message translates to:
  /// **'作品'**
  String get work;

  /// No description provided for @character.
  ///
  /// In zh, this message translates to:
  /// **'集字'**
  String get character;

  /// No description provided for @workBrowseSearch.
  ///
  /// In zh, this message translates to:
  /// **'搜索作品...'**
  String get workBrowseSearch;

  /// No description provided for @workBrowseTitle.
  ///
  /// In zh, this message translates to:
  /// **'作品'**
  String get workBrowseTitle;

  /// No description provided for @workCount.
  ///
  /// In zh, this message translates to:
  /// **'作品数量'**
  String get workCount;

  /// No description provided for @workDetailCharacters.
  ///
  /// In zh, this message translates to:
  /// **'字符'**
  String get workDetailCharacters;

  /// No description provided for @workDetailOtherInfo.
  ///
  /// In zh, this message translates to:
  /// **'其他信息'**
  String get workDetailOtherInfo;

  /// No description provided for @workDetailTitle.
  ///
  /// In zh, this message translates to:
  /// **'作品详情'**
  String get workDetailTitle;

  /// No description provided for @workFormAuthorHelp.
  ///
  /// In zh, this message translates to:
  /// **'可选，作品的创作者'**
  String get workFormAuthorHelp;

  /// No description provided for @workFormAuthorHint.
  ///
  /// In zh, this message translates to:
  /// **'输入作者名称'**
  String get workFormAuthorHint;

  /// No description provided for @workFormAuthorMaxLength.
  ///
  /// In zh, this message translates to:
  /// **'作者名称不能超过50个字符'**
  String get workFormAuthorMaxLength;

  /// No description provided for @workFormAuthorTooltip.
  ///
  /// In zh, this message translates to:
  /// **'按Ctrl+A快速跳转到作者字段'**
  String get workFormAuthorTooltip;

  /// No description provided for @workFormCreationDateError.
  ///
  /// In zh, this message translates to:
  /// **'创作日期不能超过当前日期'**
  String get workFormCreationDateError;

  /// No description provided for @workFormDateHelp.
  ///
  /// In zh, this message translates to:
  /// **'作品的完成日期'**
  String get workFormDateHelp;

  /// No description provided for @workFormRemarkHelp.
  ///
  /// In zh, this message translates to:
  /// **'可选，关于作品的附加信息'**
  String get workFormRemarkHelp;

  /// No description provided for @workFormRemarkMaxLength.
  ///
  /// In zh, this message translates to:
  /// **'备注不能超过500个字符'**
  String get workFormRemarkMaxLength;

  /// No description provided for @workFormRemarkTooltip.
  ///
  /// In zh, this message translates to:
  /// **'按Ctrl+R快速跳转到备注字段'**
  String get workFormRemarkTooltip;

  /// No description provided for @workFormStyleHelp.
  ///
  /// In zh, this message translates to:
  /// **'作品的主要风格类型'**
  String get workFormStyleHelp;

  /// No description provided for @workFormTitleHelp.
  ///
  /// In zh, this message translates to:
  /// **'作品的主标题，显示在作品列表中'**
  String get workFormTitleHelp;

  /// No description provided for @workFormTitleMaxLength.
  ///
  /// In zh, this message translates to:
  /// **'标题不能超过100个字符'**
  String get workFormTitleMaxLength;

  /// No description provided for @workFormTitleMinLength.
  ///
  /// In zh, this message translates to:
  /// **'标题必须至少2个字符'**
  String get workFormTitleMinLength;

  /// No description provided for @workFormTitleRequired.
  ///
  /// In zh, this message translates to:
  /// **'标题为必填项'**
  String get workFormTitleRequired;

  /// No description provided for @workFormTitleTooltip.
  ///
  /// In zh, this message translates to:
  /// **'按Ctrl+T快速跳转到标题字段'**
  String get workFormTitleTooltip;

  /// No description provided for @workFormToolHelp.
  ///
  /// In zh, this message translates to:
  /// **'创作此作品使用的主要工具'**
  String get workFormToolHelp;

  /// No description provided for @workInfo.
  ///
  /// In zh, this message translates to:
  /// **'作品信息'**
  String get workInfo;

  /// No description provided for @workStyleClerical.
  ///
  /// In zh, this message translates to:
  /// **'隶书'**
  String get workStyleClerical;

  /// No description provided for @workStyleCursive.
  ///
  /// In zh, this message translates to:
  /// **'草书'**
  String get workStyleCursive;

  /// No description provided for @workStyleRegular.
  ///
  /// In zh, this message translates to:
  /// **'楷书'**
  String get workStyleRegular;

  /// No description provided for @workStyleRunning.
  ///
  /// In zh, this message translates to:
  /// **'行书'**
  String get workStyleRunning;

  /// No description provided for @workStyleSeal.
  ///
  /// In zh, this message translates to:
  /// **'篆书'**
  String get workStyleSeal;

  /// No description provided for @workToolBrush.
  ///
  /// In zh, this message translates to:
  /// **'毛笔'**
  String get workToolBrush;

  /// No description provided for @workToolHardPen.
  ///
  /// In zh, this message translates to:
  /// **'硬笔'**
  String get workToolHardPen;

  /// No description provided for @workToolOther.
  ///
  /// In zh, this message translates to:
  /// **'其他'**
  String get workToolOther;

  /// No description provided for @writingMode.
  ///
  /// In zh, this message translates to:
  /// **'书写模式'**
  String get writingMode;

  /// No description provided for @writingTool.
  ///
  /// In zh, this message translates to:
  /// **'书写工具'**
  String get writingTool;

  /// No description provided for @writingToolText.
  ///
  /// In zh, this message translates to:
  /// **'书写工具'**
  String get writingToolText;

  /// No description provided for @yes.
  ///
  /// In zh, this message translates to:
  /// **'是'**
  String get yes;

  /// No description provided for @yesterday.
  ///
  /// In zh, this message translates to:
  /// **'昨天'**
  String get yesterday;

  /// No description provided for @importOptions.
  ///
  /// In zh, this message translates to:
  /// **'导入选项'**
  String get importOptions;

  /// No description provided for @validateData.
  ///
  /// In zh, this message translates to:
  /// **'验证数据'**
  String get validateData;

  /// No description provided for @validateDataDescription.
  ///
  /// In zh, this message translates to:
  /// **'导入前验证数据完整性'**
  String get validateDataDescription;

  /// No description provided for @validateDataMandatory.
  ///
  /// In zh, this message translates to:
  /// **'强制验证导入文件的完整性和格式，确保数据安全'**
  String get validateDataMandatory;

  /// No description provided for @preserveMetadata.
  ///
  /// In zh, this message translates to:
  /// **'保留元数据'**
  String get preserveMetadata;

  /// No description provided for @preserveMetadataDescription.
  ///
  /// In zh, this message translates to:
  /// **'保留原始创建时间和元数据'**
  String get preserveMetadataDescription;

  /// No description provided for @preserveMetadataMandatory.
  ///
  /// In zh, this message translates to:
  /// **'强制保留原始的创建时间、作者信息等元数据，确保数据一致性'**
  String get preserveMetadataMandatory;

  /// No description provided for @conflictResolution.
  ///
  /// In zh, this message translates to:
  /// **'冲突解决'**
  String get conflictResolution;

  /// No description provided for @skipConflicts.
  ///
  /// In zh, this message translates to:
  /// **'跳过冲突'**
  String get skipConflicts;

  /// No description provided for @skipConflictsDescription.
  ///
  /// In zh, this message translates to:
  /// **'跳过已存在的项目'**
  String get skipConflictsDescription;

  /// No description provided for @overwriteExisting.
  ///
  /// In zh, this message translates to:
  /// **'覆盖现有'**
  String get overwriteExisting;

  /// No description provided for @overwriteExistingDescription.
  ///
  /// In zh, this message translates to:
  /// **'用导入数据替换现有项目'**
  String get overwriteExistingDescription;

  /// No description provided for @conflictsFound.
  ///
  /// In zh, this message translates to:
  /// **'发现冲突'**
  String get conflictsFound;

  /// No description provided for @conflictsCount.
  ///
  /// In zh, this message translates to:
  /// **'发现 {count} 个冲突'**
  String conflictsCount(Object count);

  /// No description provided for @mergeData.
  ///
  /// In zh, this message translates to:
  /// **'合并数据'**
  String get mergeData;

  /// No description provided for @mergeDataDescription.
  ///
  /// In zh, this message translates to:
  /// **'合并现有数据和导入数据'**
  String get mergeDataDescription;

  /// No description provided for @renameDuplicates.
  ///
  /// In zh, this message translates to:
  /// **'重命名重复项'**
  String get renameDuplicates;

  /// No description provided for @renameDuplicatesDescription.
  ///
  /// In zh, this message translates to:
  /// **'重命名导入项目以避免冲突'**
  String get renameDuplicatesDescription;

  /// No description provided for @askUser.
  ///
  /// In zh, this message translates to:
  /// **'询问用户'**
  String get askUser;

  /// No description provided for @askUserDescription.
  ///
  /// In zh, this message translates to:
  /// **'对每个冲突询问用户'**
  String get askUserDescription;

  /// No description provided for @keepExisting.
  ///
  /// In zh, this message translates to:
  /// **'保留现有'**
  String get keepExisting;

  /// No description provided for @keepExistingDescription.
  ///
  /// In zh, this message translates to:
  /// **'保留现有数据，跳过导入'**
  String get keepExistingDescription;

  /// No description provided for @conflictDetailsTitle.
  ///
  /// In zh, this message translates to:
  /// **'冲突处理明细'**
  String get conflictDetailsTitle;

  /// No description provided for @skippedWorks.
  ///
  /// In zh, this message translates to:
  /// **'跳过的作品'**
  String get skippedWorks;

  /// No description provided for @overwrittenWorks.
  ///
  /// In zh, this message translates to:
  /// **'覆盖的作品'**
  String get overwrittenWorks;

  /// No description provided for @skippedCharacters.
  ///
  /// In zh, this message translates to:
  /// **'跳过的集字'**
  String get skippedCharacters;

  /// No description provided for @overwrittenCharacters.
  ///
  /// In zh, this message translates to:
  /// **'覆盖的集字'**
  String get overwrittenCharacters;

  /// No description provided for @conflictReason.
  ///
  /// In zh, this message translates to:
  /// **'冲突原因'**
  String get conflictReason;

  /// No description provided for @existingItem.
  ///
  /// In zh, this message translates to:
  /// **'现有项目'**
  String get existingItem;

  /// No description provided for @versionInfoCopied.
  ///
  /// In zh, this message translates to:
  /// **'版本信息已复制到剪贴板'**
  String get versionInfoCopied;

  /// No description provided for @appVersion.
  ///
  /// In zh, this message translates to:
  /// **'应用版本'**
  String get appVersion;

  /// No description provided for @buildNumber.
  ///
  /// In zh, this message translates to:
  /// **'构建号'**
  String get buildNumber;

  /// No description provided for @buildTime.
  ///
  /// In zh, this message translates to:
  /// **'构建时间'**
  String get buildTime;

  /// No description provided for @buildEnvironment.
  ///
  /// In zh, this message translates to:
  /// **'构建环境'**
  String get buildEnvironment;

  /// No description provided for @gitCommit.
  ///
  /// In zh, this message translates to:
  /// **'Git提交'**
  String get gitCommit;

  /// No description provided for @gitBranch.
  ///
  /// In zh, this message translates to:
  /// **'Git分支'**
  String get gitBranch;

  /// No description provided for @platformInfo.
  ///
  /// In zh, this message translates to:
  /// **'平台信息'**
  String get platformInfo;

  /// No description provided for @operatingSystem.
  ///
  /// In zh, this message translates to:
  /// **'操作系统'**
  String get operatingSystem;

  /// No description provided for @deviceInfo.
  ///
  /// In zh, this message translates to:
  /// **'设备信息'**
  String get deviceInfo;

  /// No description provided for @flutterVersion.
  ///
  /// In zh, this message translates to:
  /// **'Flutter版本'**
  String get flutterVersion;

  /// No description provided for @dartVersion.
  ///
  /// In zh, this message translates to:
  /// **'Dart版本'**
  String get dartVersion;

  /// No description provided for @versionDetails.
  ///
  /// In zh, this message translates to:
  /// **'版本详情'**
  String get versionDetails;

  /// No description provided for @systemInfo.
  ///
  /// In zh, this message translates to:
  /// **'系统信息'**
  String get systemInfo;

  /// No description provided for @about.
  ///
  /// In zh, this message translates to:
  /// **'关于'**
  String get about;

  /// No description provided for @appStartupFailed.
  ///
  /// In zh, this message translates to:
  /// **'应用启动失败'**
  String get appStartupFailed;

  /// No description provided for @criticalError.
  ///
  /// In zh, this message translates to:
  /// **'严重错误'**
  String get criticalError;

  /// No description provided for @appStartupFailedWith.
  ///
  /// In zh, this message translates to:
  /// **'应用启动失败: {error}'**
  String appStartupFailedWith(Object error);

  /// No description provided for @collectionElement.
  ///
  /// In zh, this message translates to:
  /// **'集字元素'**
  String get collectionElement;

  /// No description provided for @imageElement.
  ///
  /// In zh, this message translates to:
  /// **'图片元素'**
  String get imageElement;

  /// No description provided for @textElement.
  ///
  /// In zh, this message translates to:
  /// **'文本元素'**
  String get textElement;

  /// No description provided for @defaultEditableText.
  ///
  /// In zh, this message translates to:
  /// **'属性面板编辑文本'**
  String get defaultEditableText;

  /// No description provided for @defaultLayer.
  ///
  /// In zh, this message translates to:
  /// **'默认图层'**
  String get defaultLayer;

  /// No description provided for @currentTool.
  ///
  /// In zh, this message translates to:
  /// **'当前工具'**
  String get currentTool;

  /// No description provided for @selectionMode.
  ///
  /// In zh, this message translates to:
  /// **'选择模式'**
  String get selectionMode;

  /// No description provided for @defaultPage.
  ///
  /// In zh, this message translates to:
  /// **'默认页面'**
  String get defaultPage;

  /// No description provided for @dayBeforeYesterday.
  ///
  /// In zh, this message translates to:
  /// **'前天'**
  String get dayBeforeYesterday;

  /// No description provided for @defaultLayerName.
  ///
  /// In zh, this message translates to:
  /// **'图层{number}'**
  String defaultLayerName(Object number);

  /// No description provided for @defaultPageName.
  ///
  /// In zh, this message translates to:
  /// **'页面{number}'**
  String defaultPageName(Object number);

  /// No description provided for @importingWorks.
  ///
  /// In zh, this message translates to:
  /// **'正在导入作品...'**
  String get importingWorks;

  /// No description provided for @addingImagesToGallery.
  ///
  /// In zh, this message translates to:
  /// **'正在将 {count} 张本地图片添加到图库...'**
  String addingImagesToGallery(Object count);

  /// No description provided for @copyFailed.
  ///
  /// In zh, this message translates to:
  /// **'复制失败: {error}'**
  String copyFailed(Object error);

  /// No description provided for @selectImages.
  ///
  /// In zh, this message translates to:
  /// **'选择图片'**
  String get selectImages;

  /// No description provided for @selectImagesWithCtrl.
  ///
  /// In zh, this message translates to:
  /// **'选择图片 (可按住Ctrl多选)'**
  String get selectImagesWithCtrl;

  /// No description provided for @deleteCharacterFailed.
  ///
  /// In zh, this message translates to:
  /// **'删除字符失败：{error}'**
  String deleteCharacterFailed(Object error);

  /// No description provided for @loadCharacterDataFailed.
  ///
  /// In zh, this message translates to:
  /// **'加载字符数据失败：{error}'**
  String loadCharacterDataFailed(Object error);

  /// No description provided for @basicProperties.
  ///
  /// In zh, this message translates to:
  /// **'基础属性'**
  String get basicProperties;

  /// No description provided for @practiceSheetSavedMessage.
  ///
  /// In zh, this message translates to:
  /// **'字帖 \"{title}\" 保存成功'**
  String practiceSheetSavedMessage(Object title);

  /// No description provided for @workIdCannotBeEmpty.
  ///
  /// In zh, this message translates to:
  /// **'作品ID不能为空'**
  String get workIdCannotBeEmpty;

  /// No description provided for @collectionIdCannotBeEmpty.
  ///
  /// In zh, this message translates to:
  /// **'集字ID不能为空'**
  String get collectionIdCannotBeEmpty;

  /// No description provided for @editTags.
  ///
  /// In zh, this message translates to:
  /// **'编辑标签'**
  String get editTags;
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
