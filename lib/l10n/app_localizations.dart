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

  /// No description provided for @about.
  ///
  /// In zh, this message translates to:
  /// **'关于'**
  String get about;

  /// No description provided for @addCategory.
  ///
  /// In zh, this message translates to:
  /// **'添加分类'**
  String get addCategory;

  /// No description provided for @addedToCategory.
  ///
  /// In zh, this message translates to:
  /// **'已添加到分类'**
  String get addedToCategory;

  /// No description provided for @addElementName.
  ///
  /// In zh, this message translates to:
  /// **'添加{type}元素'**
  String addElementName(Object type);

  /// No description provided for @addLayer.
  ///
  /// In zh, this message translates to:
  /// **'添加图层'**
  String get addLayer;

  /// No description provided for @addPage.
  ///
  /// In zh, this message translates to:
  /// **'添加页面'**
  String get addPage;

  /// No description provided for @adjustGridSize.
  ///
  /// In zh, this message translates to:
  /// **'调整网格大小'**
  String get adjustGridSize;

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

  /// No description provided for @alignmentOperations.
  ///
  /// In zh, this message translates to:
  /// **'对齐操作'**
  String get alignmentOperations;

  /// No description provided for @alignmentRequiresMultipleElements.
  ///
  /// In zh, this message translates to:
  /// **'对齐操作需要至少2个元素'**
  String get alignmentRequiresMultipleElements;

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

  /// No description provided for @allCategories.
  ///
  /// In zh, this message translates to:
  /// **'所有分类'**
  String get allCategories;

  /// No description provided for @allTypes.
  ///
  /// In zh, this message translates to:
  /// **'所有类型'**
  String get allTypes;

  /// No description provided for @appName.
  ///
  /// In zh, this message translates to:
  /// **'字字珠玑'**
  String get appName;

  /// No description provided for @appTitle.
  ///
  /// In zh, this message translates to:
  /// **'字字珠玑'**
  String get appTitle;

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

  /// No description provided for @basicInfo.
  ///
  /// In zh, this message translates to:
  /// **'基本信息'**
  String get basicInfo;

  /// No description provided for @batchOperations.
  ///
  /// In zh, this message translates to:
  /// **'批量操作'**
  String get batchOperations;

  /// No description provided for @bringLayerToFront.
  ///
  /// In zh, this message translates to:
  /// **'图层置于顶层'**
  String get bringLayerToFront;

  /// No description provided for @bringToFront.
  ///
  /// In zh, this message translates to:
  /// **'置于顶层'**
  String get bringToFront;

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

  /// No description provided for @cancel.
  ///
  /// In zh, this message translates to:
  /// **'取消'**
  String get cancel;

  /// No description provided for @cannotDeleteOnlyPage.
  ///
  /// In zh, this message translates to:
  /// **'无法删除唯一的页面'**
  String get cannotDeleteOnlyPage;

  /// No description provided for @canvasPixelSize.
  ///
  /// In zh, this message translates to:
  /// **'画布像素大小'**
  String get canvasPixelSize;

  /// No description provided for @canvasResetView.
  ///
  /// In zh, this message translates to:
  /// **'复位'**
  String get canvasResetView;

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

  /// No description provided for @categoryHasItems.
  ///
  /// In zh, this message translates to:
  /// **'此分类下有 {count} 个项目'**
  String categoryHasItems(Object count);

  /// No description provided for @categoryManagement.
  ///
  /// In zh, this message translates to:
  /// **'分类管理'**
  String get categoryManagement;

  /// No description provided for @categoryPanelTitle.
  ///
  /// In zh, this message translates to:
  /// **'分类面板'**
  String get categoryPanelTitle;

  /// No description provided for @center.
  ///
  /// In zh, this message translates to:
  /// **'居中'**
  String get center;

  /// No description provided for @characterCollectionBack.
  ///
  /// In zh, this message translates to:
  /// **'返回'**
  String get characterCollectionBack;

  /// No description provided for @characterCollectionDeleteBatchConfirm.
  ///
  /// In zh, this message translates to:
  /// **'确认删除{count}个已保存区域？'**
  String characterCollectionDeleteBatchConfirm(Object count);

  /// No description provided for @characterCollectionDeleteBatchMessage.
  ///
  /// In zh, this message translates to:
  /// **'您即将删除{count}个已保存区域。此操作无法撤消。'**
  String characterCollectionDeleteBatchMessage(Object count);

  /// No description provided for @characterCollectionDeleteConfirm.
  ///
  /// In zh, this message translates to:
  /// **'确认删除'**
  String get characterCollectionDeleteConfirm;

  /// No description provided for @characterCollectionDeleteMessage.
  ///
  /// In zh, this message translates to:
  /// **'您即将删除所选区域。此操作无法撤消。'**
  String get characterCollectionDeleteMessage;

  /// No description provided for @characterCollectionDeleteShortcuts.
  ///
  /// In zh, this message translates to:
  /// **'快捷键：Enter 确认，Esc 取消'**
  String get characterCollectionDeleteShortcuts;

  /// No description provided for @characterCollectionError.
  ///
  /// In zh, this message translates to:
  /// **'错误：{error}'**
  String characterCollectionError(Object error);

  /// No description provided for @characterCollectionFilterAll.
  ///
  /// In zh, this message translates to:
  /// **'全部'**
  String get characterCollectionFilterAll;

  /// No description provided for @characterCollectionFilterFavorite.
  ///
  /// In zh, this message translates to:
  /// **'收藏'**
  String get characterCollectionFilterFavorite;

  /// No description provided for @characterCollectionFilterRecent.
  ///
  /// In zh, this message translates to:
  /// **'最近'**
  String get characterCollectionFilterRecent;

  /// No description provided for @characterCollectionFindSwitchFailed.
  ///
  /// In zh, this message translates to:
  /// **'查找并切换页面失败：{error}'**
  String characterCollectionFindSwitchFailed(Object error);

  /// No description provided for @characterCollectionHelp.
  ///
  /// In zh, this message translates to:
  /// **'帮助'**
  String get characterCollectionHelp;

  /// No description provided for @characterCollectionHelpClose.
  ///
  /// In zh, this message translates to:
  /// **'关闭'**
  String get characterCollectionHelpClose;

  /// No description provided for @characterCollectionHelpExport.
  ///
  /// In zh, this message translates to:
  /// **'导出帮助文档'**
  String get characterCollectionHelpExport;

  /// No description provided for @characterCollectionHelpExportSoon.
  ///
  /// In zh, this message translates to:
  /// **'帮助文档导出功能即将推出'**
  String get characterCollectionHelpExportSoon;

  /// No description provided for @characterCollectionHelpGuide.
  ///
  /// In zh, this message translates to:
  /// **'字符采集指南'**
  String get characterCollectionHelpGuide;

  /// No description provided for @characterCollectionHelpIntro.
  ///
  /// In zh, this message translates to:
  /// **'字符采集允许您从图像中提取、编辑和管理字符。以下是详细指南：'**
  String get characterCollectionHelpIntro;

  /// No description provided for @characterCollectionHelpNotes.
  ///
  /// In zh, this message translates to:
  /// **'注意事项'**
  String get characterCollectionHelpNotes;

  /// No description provided for @characterCollectionHelpSection1.
  ///
  /// In zh, this message translates to:
  /// **'1. 选择与导航'**
  String get characterCollectionHelpSection1;

  /// No description provided for @characterCollectionHelpSection2.
  ///
  /// In zh, this message translates to:
  /// **'2. 区域调整'**
  String get characterCollectionHelpSection2;

  /// No description provided for @characterCollectionHelpSection3.
  ///
  /// In zh, this message translates to:
  /// **'3. 橡皮工具'**
  String get characterCollectionHelpSection3;

  /// No description provided for @characterCollectionHelpSection4.
  ///
  /// In zh, this message translates to:
  /// **'4. 数据保存'**
  String get characterCollectionHelpSection4;

  /// No description provided for @characterCollectionHelpSection5.
  ///
  /// In zh, this message translates to:
  /// **'5. 键盘快捷键'**
  String get characterCollectionHelpSection5;

  /// No description provided for @characterCollectionHelpTitle.
  ///
  /// In zh, this message translates to:
  /// **'字符采集帮助'**
  String get characterCollectionHelpTitle;

  /// No description provided for @characterCollectionImageInvalid.
  ///
  /// In zh, this message translates to:
  /// **'图像数据无效或已损坏'**
  String get characterCollectionImageInvalid;

  /// No description provided for @characterCollectionImageLoadError.
  ///
  /// In zh, this message translates to:
  /// **'无法加载图像'**
  String get characterCollectionImageLoadError;

  /// No description provided for @characterCollectionLeave.
  ///
  /// In zh, this message translates to:
  /// **'离开'**
  String get characterCollectionLeave;

  /// No description provided for @characterCollectionLoadingImage.
  ///
  /// In zh, this message translates to:
  /// **'加载图像中...'**
  String get characterCollectionLoadingImage;

  /// No description provided for @characterCollectionNextPage.
  ///
  /// In zh, this message translates to:
  /// **'下一页'**
  String get characterCollectionNextPage;

  /// No description provided for @characterCollectionNoCharacter.
  ///
  /// In zh, this message translates to:
  /// **'无字符'**
  String get characterCollectionNoCharacter;

  /// No description provided for @characterCollectionNoCharacters.
  ///
  /// In zh, this message translates to:
  /// **'尚未采集字符'**
  String get characterCollectionNoCharacters;

  /// No description provided for @characterCollectionPreviewTab.
  ///
  /// In zh, this message translates to:
  /// **'字符预览'**
  String get characterCollectionPreviewTab;

  /// No description provided for @characterCollectionPreviousPage.
  ///
  /// In zh, this message translates to:
  /// **'上一页'**
  String get characterCollectionPreviousPage;

  /// No description provided for @characterCollectionProcessing.
  ///
  /// In zh, this message translates to:
  /// **'处理中...'**
  String get characterCollectionProcessing;

  /// No description provided for @characterCollectionResultsTab.
  ///
  /// In zh, this message translates to:
  /// **'采集结果'**
  String get characterCollectionResultsTab;

  /// No description provided for @characterCollectionRetry.
  ///
  /// In zh, this message translates to:
  /// **'重试'**
  String get characterCollectionRetry;

  /// No description provided for @characterCollectionReturnToDetails.
  ///
  /// In zh, this message translates to:
  /// **'返回作品详情'**
  String get characterCollectionReturnToDetails;

  /// No description provided for @characterCollectionSearchHint.
  ///
  /// In zh, this message translates to:
  /// **'搜索字符...'**
  String get characterCollectionSearchHint;

  /// No description provided for @characterCollectionSelectRegion.
  ///
  /// In zh, this message translates to:
  /// **'请在预览区域选择字符区域'**
  String get characterCollectionSelectRegion;

  /// No description provided for @characterCollectionSwitchingPage.
  ///
  /// In zh, this message translates to:
  /// **'正在切换到字符页面...'**
  String get characterCollectionSwitchingPage;

  /// No description provided for @characterCollectionTitle.
  ///
  /// In zh, this message translates to:
  /// **'字符采集'**
  String get characterCollectionTitle;

  /// No description provided for @characterCollectionToolDelete.
  ///
  /// In zh, this message translates to:
  /// **'删除所选 (Ctrl+D)'**
  String get characterCollectionToolDelete;

  /// No description provided for @characterCollectionToolPan.
  ///
  /// In zh, this message translates to:
  /// **'平移工具 (Ctrl+V)'**
  String get characterCollectionToolPan;

  /// No description provided for @characterCollectionToolSelect.
  ///
  /// In zh, this message translates to:
  /// **'选择工具 (Ctrl+B)'**
  String get characterCollectionToolSelect;

  /// No description provided for @characterCollectionUnsavedChanges.
  ///
  /// In zh, this message translates to:
  /// **'未保存的更改'**
  String get characterCollectionUnsavedChanges;

  /// No description provided for @characterCollectionUnsavedChangesMessage.
  ///
  /// In zh, this message translates to:
  /// **'您有未保存的区域修改。离开将丢失这些更改。\n\n确定要离开吗？'**
  String get characterCollectionUnsavedChangesMessage;

  /// No description provided for @characterCollectionUseSelectionTool.
  ///
  /// In zh, this message translates to:
  /// **'使用左侧的选择工具从图像中提取字符'**
  String get characterCollectionUseSelectionTool;

  /// No description provided for @characterCount.
  ///
  /// In zh, this message translates to:
  /// **'集字数量'**
  String get characterCount;

  /// No description provided for @characterDetailAddTag.
  ///
  /// In zh, this message translates to:
  /// **'添加标签'**
  String get characterDetailAddTag;

  /// No description provided for @characterDetailAuthor.
  ///
  /// In zh, this message translates to:
  /// **'作者'**
  String get characterDetailAuthor;

  /// No description provided for @characterDetailBasicInfo.
  ///
  /// In zh, this message translates to:
  /// **'基本信息'**
  String get characterDetailBasicInfo;

  /// No description provided for @characterDetailCalligraphyStyle.
  ///
  /// In zh, this message translates to:
  /// **'书法风格'**
  String get characterDetailCalligraphyStyle;

  /// No description provided for @characterDetailCollectionTime.
  ///
  /// In zh, this message translates to:
  /// **'采集时间'**
  String get characterDetailCollectionTime;

  /// No description provided for @characterDetailCreationTime.
  ///
  /// In zh, this message translates to:
  /// **'创作时间'**
  String get characterDetailCreationTime;

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

  /// No description provided for @characterDetailFormatExtension.
  ///
  /// In zh, this message translates to:
  /// **'文件格式'**
  String get characterDetailFormatExtension;

  /// No description provided for @characterDetailFormatName.
  ///
  /// In zh, this message translates to:
  /// **'格式名称'**
  String get characterDetailFormatName;

  /// No description provided for @characterDetailFormatOriginal.
  ///
  /// In zh, this message translates to:
  /// **'原始'**
  String get characterDetailFormatOriginal;

  /// No description provided for @characterDetailFormatOriginalDesc.
  ///
  /// In zh, this message translates to:
  /// **'未经处理的原始图像'**
  String get characterDetailFormatOriginalDesc;

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

  /// No description provided for @characterDetailFormatType.
  ///
  /// In zh, this message translates to:
  /// **'类型'**
  String get characterDetailFormatType;

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

  /// No description provided for @characterDetailTagAddError.
  ///
  /// In zh, this message translates to:
  /// **'添加标签失败: {error}'**
  String characterDetailTagAddError(Object error);

  /// No description provided for @characterDetailTagHint.
  ///
  /// In zh, this message translates to:
  /// **'输入标签名称'**
  String get characterDetailTagHint;

  /// No description provided for @characterDetailTagRemoveError.
  ///
  /// In zh, this message translates to:
  /// **'移除标签失败, 错误: {error}'**
  String characterDetailTagRemoveError(Object error);

  /// No description provided for @characterDetailTags.
  ///
  /// In zh, this message translates to:
  /// **'标签'**
  String get characterDetailTags;

  /// No description provided for @characterDetailUnknown.
  ///
  /// In zh, this message translates to:
  /// **'未知'**
  String get characterDetailUnknown;

  /// No description provided for @characterDetailWorkInfo.
  ///
  /// In zh, this message translates to:
  /// **'作品信息'**
  String get characterDetailWorkInfo;

  /// No description provided for @characterDetailWorkTitle.
  ///
  /// In zh, this message translates to:
  /// **'作品标题'**
  String get characterDetailWorkTitle;

  /// No description provided for @characterDetailWritingTool.
  ///
  /// In zh, this message translates to:
  /// **'书写工具'**
  String get characterDetailWritingTool;

  /// No description provided for @characterEditBrushSize.
  ///
  /// In zh, this message translates to:
  /// **'笔刷尺寸'**
  String get characterEditBrushSize;

  /// No description provided for @characterEditCharacterUpdated.
  ///
  /// In zh, this message translates to:
  /// **'「字符已更新'**
  String get characterEditCharacterUpdated;

  /// No description provided for @characterEditCompletingSave.
  ///
  /// In zh, this message translates to:
  /// **'完成保存...'**
  String get characterEditCompletingSave;

  /// No description provided for @characterEditDefaultsSaved.
  ///
  /// In zh, this message translates to:
  /// **'默认设置已保存'**
  String get characterEditDefaultsSaved;

  /// No description provided for @characterEditImageInvert.
  ///
  /// In zh, this message translates to:
  /// **'图像反转'**
  String get characterEditImageInvert;

  /// No description provided for @characterEditImageLoadError.
  ///
  /// In zh, this message translates to:
  /// **'图像加载错误'**
  String get characterEditImageLoadError;

  /// No description provided for @characterEditImageLoadFailed.
  ///
  /// In zh, this message translates to:
  /// **'加载或处理字符图像失败'**
  String get characterEditImageLoadFailed;

  /// No description provided for @characterEditInitializing.
  ///
  /// In zh, this message translates to:
  /// **'初始化中...'**
  String get characterEditInitializing;

  /// No description provided for @characterEditInputCharacter.
  ///
  /// In zh, this message translates to:
  /// **'输入字符'**
  String get characterEditInputCharacter;

  /// No description provided for @characterEditInputHint.
  ///
  /// In zh, this message translates to:
  /// **'在此输入'**
  String get characterEditInputHint;

  /// No description provided for @characterEditInvertMode.
  ///
  /// In zh, this message translates to:
  /// **'反转模式'**
  String get characterEditInvertMode;

  /// No description provided for @characterEditLoadingImage.
  ///
  /// In zh, this message translates to:
  /// **'加载字符图像中...'**
  String get characterEditLoadingImage;

  /// No description provided for @characterEditNoiseReduction.
  ///
  /// In zh, this message translates to:
  /// **'降噪'**
  String get characterEditNoiseReduction;

  /// No description provided for @characterEditNoRegionSelected.
  ///
  /// In zh, this message translates to:
  /// **'未选择区域'**
  String get characterEditNoRegionSelected;

  /// No description provided for @characterEditOnlyOneCharacter.
  ///
  /// In zh, this message translates to:
  /// **'只允许一个字符'**
  String get characterEditOnlyOneCharacter;

  /// No description provided for @characterEditPanImage.
  ///
  /// In zh, this message translates to:
  /// **'平移图像（按住Alt）'**
  String get characterEditPanImage;

  /// No description provided for @characterEditPleaseEnterCharacter.
  ///
  /// In zh, this message translates to:
  /// **'请输入字符'**
  String get characterEditPleaseEnterCharacter;

  /// No description provided for @characterEditPreparingSave.
  ///
  /// In zh, this message translates to:
  /// **'准备保存...'**
  String get characterEditPreparingSave;

  /// No description provided for @characterEditProcessingEraseData.
  ///
  /// In zh, this message translates to:
  /// **'处理擦除数据...'**
  String get characterEditProcessingEraseData;

  /// No description provided for @characterEditProcessingImage.
  ///
  /// In zh, this message translates to:
  /// **'处理图像中...'**
  String get characterEditProcessingImage;

  /// No description provided for @characterEditRedo.
  ///
  /// In zh, this message translates to:
  /// **'重做'**
  String get characterEditRedo;

  /// No description provided for @characterEditSaveComplete.
  ///
  /// In zh, this message translates to:
  /// **'保存完成'**
  String get characterEditSaveComplete;

  /// No description provided for @characterEditSaveConfirmMessage.
  ///
  /// In zh, this message translates to:
  /// **'确认保存「{character}」？'**
  String characterEditSaveConfirmMessage(Object character);

  /// No description provided for @characterEditSaveConfirmTitle.
  ///
  /// In zh, this message translates to:
  /// **'保存字符'**
  String get characterEditSaveConfirmTitle;

  /// No description provided for @characterEditSavePreview.
  ///
  /// In zh, this message translates to:
  /// **'字符预览：'**
  String get characterEditSavePreview;

  /// No description provided for @characterEditSaveShortcuts.
  ///
  /// In zh, this message translates to:
  /// **'按 Enter 保存，Esc 取消'**
  String get characterEditSaveShortcuts;

  /// No description provided for @characterEditSaveTimeout.
  ///
  /// In zh, this message translates to:
  /// **'保存超时'**
  String get characterEditSaveTimeout;

  /// No description provided for @characterEditSavingToStorage.
  ///
  /// In zh, this message translates to:
  /// **'保存到存储中...'**
  String get characterEditSavingToStorage;

  /// No description provided for @characterEditShowContour.
  ///
  /// In zh, this message translates to:
  /// **'显示轮廓'**
  String get characterEditShowContour;

  /// No description provided for @characterEditThreshold.
  ///
  /// In zh, this message translates to:
  /// **'阈值'**
  String get characterEditThreshold;

  /// No description provided for @characterEditThumbnailCheckFailed.
  ///
  /// In zh, this message translates to:
  /// **'缩略图检查失败'**
  String get characterEditThumbnailCheckFailed;

  /// No description provided for @characterEditThumbnailEmpty.
  ///
  /// In zh, this message translates to:
  /// **'缩略图文件为空'**
  String get characterEditThumbnailEmpty;

  /// No description provided for @characterEditThumbnailLoadError.
  ///
  /// In zh, this message translates to:
  /// **'加载缩略图失败'**
  String get characterEditThumbnailLoadError;

  /// No description provided for @characterEditThumbnailLoadFailed.
  ///
  /// In zh, this message translates to:
  /// **'加载缩略图失败'**
  String get characterEditThumbnailLoadFailed;

  /// No description provided for @characterEditThumbnailNotFound.
  ///
  /// In zh, this message translates to:
  /// **'未找到缩略图'**
  String get characterEditThumbnailNotFound;

  /// No description provided for @characterEditThumbnailSizeError.
  ///
  /// In zh, this message translates to:
  /// **'获取缩略图大小失败'**
  String get characterEditThumbnailSizeError;

  /// No description provided for @characterEditUndo.
  ///
  /// In zh, this message translates to:
  /// **'撤销'**
  String get characterEditUndo;

  /// No description provided for @characterEditUnknownError.
  ///
  /// In zh, this message translates to:
  /// **'未知错误'**
  String get characterEditUnknownError;

  /// No description provided for @characterEditValidChineseCharacter.
  ///
  /// In zh, this message translates to:
  /// **'请输入有效的汉字'**
  String get characterEditValidChineseCharacter;

  /// No description provided for @characterFilterAddTag.
  ///
  /// In zh, this message translates to:
  /// **'添加标签'**
  String get characterFilterAddTag;

  /// No description provided for @characterFilterAddTagHint.
  ///
  /// In zh, this message translates to:
  /// **'输入标签名称并按 Enter'**
  String get characterFilterAddTagHint;

  /// No description provided for @characterFilterCalligraphyStyle.
  ///
  /// In zh, this message translates to:
  /// **'书法风格'**
  String get characterFilterCalligraphyStyle;

  /// No description provided for @characterFilterCollapse.
  ///
  /// In zh, this message translates to:
  /// **'折叠筛选面板'**
  String get characterFilterCollapse;

  /// No description provided for @characterFilterCollectionDate.
  ///
  /// In zh, this message translates to:
  /// **'采集日期'**
  String get characterFilterCollectionDate;

  /// No description provided for @characterFilterCreationDate.
  ///
  /// In zh, this message translates to:
  /// **'创作日期'**
  String get characterFilterCreationDate;

  /// No description provided for @characterFilterExpand.
  ///
  /// In zh, this message translates to:
  /// **'展开筛选面板'**
  String get characterFilterExpand;

  /// No description provided for @characterFilterFavoritesOnly.
  ///
  /// In zh, this message translates to:
  /// **'仅显示收藏'**
  String get characterFilterFavoritesOnly;

  /// No description provided for @characterFilterSelectedTags.
  ///
  /// In zh, this message translates to:
  /// **'已选标签：'**
  String get characterFilterSelectedTags;

  /// No description provided for @characterFilterSort.
  ///
  /// In zh, this message translates to:
  /// **'排序'**
  String get characterFilterSort;

  /// No description provided for @characterFilterTags.
  ///
  /// In zh, this message translates to:
  /// **'标签'**
  String get characterFilterTags;

  /// No description provided for @characterFilterTitle.
  ///
  /// In zh, this message translates to:
  /// **'筛选与排序'**
  String get characterFilterTitle;

  /// No description provided for @characterFilterWritingTool.
  ///
  /// In zh, this message translates to:
  /// **'书写工具'**
  String get characterFilterWritingTool;

  /// No description provided for @characterManagementBatchDone.
  ///
  /// In zh, this message translates to:
  /// **'完成'**
  String get characterManagementBatchDone;

  /// No description provided for @characterManagementBatchMode.
  ///
  /// In zh, this message translates to:
  /// **'批量模式'**
  String get characterManagementBatchMode;

  /// No description provided for @characterManagementDeleteConfirm.
  ///
  /// In zh, this message translates to:
  /// **'确认删除'**
  String get characterManagementDeleteConfirm;

  /// No description provided for @characterManagementDeleteMessage.
  ///
  /// In zh, this message translates to:
  /// **'确定要删除选中的字符吗？此操作无法撤消。'**
  String get characterManagementDeleteMessage;

  /// No description provided for @characterManagementDeleteSelected.
  ///
  /// In zh, this message translates to:
  /// **'删除所选'**
  String get characterManagementDeleteSelected;

  /// No description provided for @characterManagementError.
  ///
  /// In zh, this message translates to:
  /// **'错误：{message}'**
  String characterManagementError(Object message);

  /// No description provided for @characterManagementGridView.
  ///
  /// In zh, this message translates to:
  /// **'网格视图'**
  String get characterManagementGridView;

  /// No description provided for @characterManagementItemsPerPage.
  ///
  /// In zh, this message translates to:
  /// **'{count}项/页'**
  String characterManagementItemsPerPage(Object count);

  /// No description provided for @characterManagementListView.
  ///
  /// In zh, this message translates to:
  /// **'列表视图'**
  String get characterManagementListView;

  /// No description provided for @characterManagementLoading.
  ///
  /// In zh, this message translates to:
  /// **'加载字符中...'**
  String get characterManagementLoading;

  /// No description provided for @characterManagementNoCharacters.
  ///
  /// In zh, this message translates to:
  /// **'未找到字符'**
  String get characterManagementNoCharacters;

  /// No description provided for @characterManagementNoCharactersHint.
  ///
  /// In zh, this message translates to:
  /// **'尝试更改搜索或筛选条件'**
  String get characterManagementNoCharactersHint;

  /// No description provided for @characterManagementSearch.
  ///
  /// In zh, this message translates to:
  /// **'搜索字符、作品或作者'**
  String get characterManagementSearch;

  /// No description provided for @characterManagementTitle.
  ///
  /// In zh, this message translates to:
  /// **'集字'**
  String get characterManagementTitle;

  /// No description provided for @characters.
  ///
  /// In zh, this message translates to:
  /// **'集字'**
  String get characters;

  /// No description provided for @clearCache.
  ///
  /// In zh, this message translates to:
  /// **'清除缓存'**
  String get clearCache;

  /// No description provided for @clearCacheConfirmMessage.
  ///
  /// In zh, this message translates to:
  /// **'确定要清除所有缓存数据吗？这将释放磁盘空间，但可能会暂时降低应用程序的速度。'**
  String get clearCacheConfirmMessage;

  /// No description provided for @clearCacheConfirmTitle.
  ///
  /// In zh, this message translates to:
  /// **'清除缓存'**
  String get clearCacheConfirmTitle;

  /// No description provided for @clearImageCache.
  ///
  /// In zh, this message translates to:
  /// **'清除图像缓存'**
  String get clearImageCache;

  /// No description provided for @clearSelection.
  ///
  /// In zh, this message translates to:
  /// **'取消选择'**
  String get clearSelection;

  /// No description provided for @collection.
  ///
  /// In zh, this message translates to:
  /// **'集字'**
  String get collection;

  /// No description provided for @collectionElement.
  ///
  /// In zh, this message translates to:
  /// **'集字元素'**
  String get collectionElement;

  /// No description provided for @collectionPropertyPanel.
  ///
  /// In zh, this message translates to:
  /// **'采集属性'**
  String get collectionPropertyPanel;

  /// No description provided for @collectionPropertyPanelAutoLineBreak.
  ///
  /// In zh, this message translates to:
  /// **'自动换行'**
  String get collectionPropertyPanelAutoLineBreak;

  /// No description provided for @collectionPropertyPanelAutoLineBreakDisabled.
  ///
  /// In zh, this message translates to:
  /// **'已禁用自动换行'**
  String get collectionPropertyPanelAutoLineBreakDisabled;

  /// No description provided for @collectionPropertyPanelAutoLineBreakEnabled.
  ///
  /// In zh, this message translates to:
  /// **'已启用自动换行'**
  String get collectionPropertyPanelAutoLineBreakEnabled;

  /// No description provided for @collectionPropertyPanelAutoLineBreakTooltip.
  ///
  /// In zh, this message translates to:
  /// **'自动换行'**
  String get collectionPropertyPanelAutoLineBreakTooltip;

  /// No description provided for @collectionPropertyPanelAvailableCharacters.
  ///
  /// In zh, this message translates to:
  /// **'可用字符'**
  String get collectionPropertyPanelAvailableCharacters;

  /// No description provided for @collectionPropertyPanelBackgroundColor.
  ///
  /// In zh, this message translates to:
  /// **'背景颜色'**
  String get collectionPropertyPanelBackgroundColor;

  /// No description provided for @collectionPropertyPanelBorder.
  ///
  /// In zh, this message translates to:
  /// **'边框'**
  String get collectionPropertyPanelBorder;

  /// No description provided for @collectionPropertyPanelBorderColor.
  ///
  /// In zh, this message translates to:
  /// **'边框颜色'**
  String get collectionPropertyPanelBorderColor;

  /// No description provided for @collectionPropertyPanelBorderWidth.
  ///
  /// In zh, this message translates to:
  /// **'边框宽度'**
  String get collectionPropertyPanelBorderWidth;

  /// No description provided for @collectionPropertyPanelCacheCleared.
  ///
  /// In zh, this message translates to:
  /// **'图像缓存已清除'**
  String get collectionPropertyPanelCacheCleared;

  /// No description provided for @collectionPropertyPanelCacheClearFailed.
  ///
  /// In zh, this message translates to:
  /// **'清除图像缓存失败'**
  String get collectionPropertyPanelCacheClearFailed;

  /// No description provided for @collectionPropertyPanelCandidateCharacters.
  ///
  /// In zh, this message translates to:
  /// **'候选字符'**
  String get collectionPropertyPanelCandidateCharacters;

  /// No description provided for @collectionPropertyPanelCharacter.
  ///
  /// In zh, this message translates to:
  /// **'集字'**
  String get collectionPropertyPanelCharacter;

  /// No description provided for @collectionPropertyPanelCharacterSettings.
  ///
  /// In zh, this message translates to:
  /// **'字符设置'**
  String get collectionPropertyPanelCharacterSettings;

  /// No description provided for @collectionPropertyPanelCharacterSource.
  ///
  /// In zh, this message translates to:
  /// **'字符来源'**
  String get collectionPropertyPanelCharacterSource;

  /// No description provided for @collectionPropertyPanelCharIndex.
  ///
  /// In zh, this message translates to:
  /// **'字符'**
  String get collectionPropertyPanelCharIndex;

  /// No description provided for @collectionPropertyPanelClearImageCache.
  ///
  /// In zh, this message translates to:
  /// **'清除图像缓存'**
  String get collectionPropertyPanelClearImageCache;

  /// No description provided for @collectionPropertyPanelColorInversion.
  ///
  /// In zh, this message translates to:
  /// **'颜色反转'**
  String get collectionPropertyPanelColorInversion;

  /// No description provided for @collectionPropertyPanelColorPicker.
  ///
  /// In zh, this message translates to:
  /// **'颜色选择器'**
  String get collectionPropertyPanelColorPicker;

  /// No description provided for @collectionPropertyPanelColorSettings.
  ///
  /// In zh, this message translates to:
  /// **'颜色设置'**
  String get collectionPropertyPanelColorSettings;

  /// No description provided for @collectionPropertyPanelContent.
  ///
  /// In zh, this message translates to:
  /// **'内容属性'**
  String get collectionPropertyPanelContent;

  /// No description provided for @collectionPropertyPanelCurrentCharInversion.
  ///
  /// In zh, this message translates to:
  /// **'当前字符反转'**
  String get collectionPropertyPanelCurrentCharInversion;

  /// No description provided for @collectionPropertyPanelDisabled.
  ///
  /// In zh, this message translates to:
  /// **'已禁用'**
  String get collectionPropertyPanelDisabled;

  /// No description provided for @collectionPropertyPanelEnabled.
  ///
  /// In zh, this message translates to:
  /// **'已启用'**
  String get collectionPropertyPanelEnabled;

  /// No description provided for @collectionPropertyPanelFlip.
  ///
  /// In zh, this message translates to:
  /// **'翻转'**
  String get collectionPropertyPanelFlip;

  /// No description provided for @collectionPropertyPanelFlipHorizontally.
  ///
  /// In zh, this message translates to:
  /// **'水平翻转'**
  String get collectionPropertyPanelFlipHorizontally;

  /// No description provided for @collectionPropertyPanelFlipVertically.
  ///
  /// In zh, this message translates to:
  /// **'垂直翻转'**
  String get collectionPropertyPanelFlipVertically;

  /// No description provided for @collectionPropertyPanelFontSize.
  ///
  /// In zh, this message translates to:
  /// **'字体大小'**
  String get collectionPropertyPanelFontSize;

  /// No description provided for @collectionPropertyPanelGeometry.
  ///
  /// In zh, this message translates to:
  /// **'几何属性'**
  String get collectionPropertyPanelGeometry;

  /// No description provided for @collectionPropertyPanelGlobalInversion.
  ///
  /// In zh, this message translates to:
  /// **'全局反转'**
  String get collectionPropertyPanelGlobalInversion;

  /// No description provided for @collectionPropertyPanelHeaderContent.
  ///
  /// In zh, this message translates to:
  /// **'内容属性'**
  String get collectionPropertyPanelHeaderContent;

  /// No description provided for @collectionPropertyPanelHeaderGeometry.
  ///
  /// In zh, this message translates to:
  /// **'几何属性'**
  String get collectionPropertyPanelHeaderGeometry;

  /// No description provided for @collectionPropertyPanelHeaderVisual.
  ///
  /// In zh, this message translates to:
  /// **'视觉属性'**
  String get collectionPropertyPanelHeaderVisual;

  /// No description provided for @collectionPropertyPanelInvertDisplay.
  ///
  /// In zh, this message translates to:
  /// **'反转显示颜色'**
  String get collectionPropertyPanelInvertDisplay;

  /// No description provided for @collectionPropertyPanelNoCharacterSelected.
  ///
  /// In zh, this message translates to:
  /// **'未选择字符'**
  String get collectionPropertyPanelNoCharacterSelected;

  /// No description provided for @collectionPropertyPanelNoCharactersFound.
  ///
  /// In zh, this message translates to:
  /// **'未找到匹配的字符'**
  String get collectionPropertyPanelNoCharactersFound;

  /// No description provided for @collectionPropertyPanelNoCharacterText.
  ///
  /// In zh, this message translates to:
  /// **'无字符'**
  String get collectionPropertyPanelNoCharacterText;

  /// No description provided for @collectionPropertyPanelOf.
  ///
  /// In zh, this message translates to:
  /// **'/'**
  String get collectionPropertyPanelOf;

  /// No description provided for @collectionPropertyPanelOpacity.
  ///
  /// In zh, this message translates to:
  /// **'不透明度'**
  String get collectionPropertyPanelOpacity;

  /// No description provided for @collectionPropertyPanelOriginal.
  ///
  /// In zh, this message translates to:
  /// **'原始'**
  String get collectionPropertyPanelOriginal;

  /// No description provided for @collectionPropertyPanelPadding.
  ///
  /// In zh, this message translates to:
  /// **'内边距'**
  String get collectionPropertyPanelPadding;

  /// No description provided for @collectionPropertyPanelPropertyUpdated.
  ///
  /// In zh, this message translates to:
  /// **'属性已更新'**
  String get collectionPropertyPanelPropertyUpdated;

  /// No description provided for @collectionPropertyPanelRender.
  ///
  /// In zh, this message translates to:
  /// **'渲染模式'**
  String get collectionPropertyPanelRender;

  /// No description provided for @collectionPropertyPanelReset.
  ///
  /// In zh, this message translates to:
  /// **'重置'**
  String get collectionPropertyPanelReset;

  /// No description provided for @collectionPropertyPanelRotation.
  ///
  /// In zh, this message translates to:
  /// **'旋转'**
  String get collectionPropertyPanelRotation;

  /// No description provided for @collectionPropertyPanelScale.
  ///
  /// In zh, this message translates to:
  /// **'缩放'**
  String get collectionPropertyPanelScale;

  /// No description provided for @collectionPropertyPanelSearchInProgress.
  ///
  /// In zh, this message translates to:
  /// **'搜索字符中...'**
  String get collectionPropertyPanelSearchInProgress;

  /// No description provided for @collectionPropertyPanelSelectCharacter.
  ///
  /// In zh, this message translates to:
  /// **'请选择字符'**
  String get collectionPropertyPanelSelectCharacter;

  /// No description provided for @collectionPropertyPanelSelectCharacterFirst.
  ///
  /// In zh, this message translates to:
  /// **'请先选择字符'**
  String get collectionPropertyPanelSelectCharacterFirst;

  /// No description provided for @collectionPropertyPanelSelectedCharacter.
  ///
  /// In zh, this message translates to:
  /// **'已选字符'**
  String get collectionPropertyPanelSelectedCharacter;

  /// No description provided for @collectionPropertyPanelStyle.
  ///
  /// In zh, this message translates to:
  /// **'样式'**
  String get collectionPropertyPanelStyle;

  /// No description provided for @collectionPropertyPanelStyled.
  ///
  /// In zh, this message translates to:
  /// **'样式化'**
  String get collectionPropertyPanelStyled;

  /// No description provided for @collectionPropertyPanelTextSettings.
  ///
  /// In zh, this message translates to:
  /// **'文本设置'**
  String get collectionPropertyPanelTextSettings;

  /// No description provided for @collectionPropertyPanelUnknown.
  ///
  /// In zh, this message translates to:
  /// **'未知'**
  String get collectionPropertyPanelUnknown;

  /// No description provided for @collectionPropertyPanelVisual.
  ///
  /// In zh, this message translates to:
  /// **'视觉设置'**
  String get collectionPropertyPanelVisual;

  /// No description provided for @collectionPropertyPanelWorkSource.
  ///
  /// In zh, this message translates to:
  /// **'作品来源'**
  String get collectionPropertyPanelWorkSource;

  /// No description provided for @commonProperties.
  ///
  /// In zh, this message translates to:
  /// **'通用属性'**
  String get commonProperties;

  /// No description provided for @confirm.
  ///
  /// In zh, this message translates to:
  /// **'确认'**
  String get confirm;

  /// No description provided for @confirmDelete.
  ///
  /// In zh, this message translates to:
  /// **'确认删除？'**
  String get confirmDelete;

  /// No description provided for @confirmDeleteCategory.
  ///
  /// In zh, this message translates to:
  /// **'确认删除分类'**
  String get confirmDeleteCategory;

  /// No description provided for @contains.
  ///
  /// In zh, this message translates to:
  /// **'包含'**
  String get contains;

  /// No description provided for @contentSettings.
  ///
  /// In zh, this message translates to:
  /// **'内容设置'**
  String get contentSettings;

  /// No description provided for @copyLayerName.
  ///
  /// In zh, this message translates to:
  /// **'{name} (复制)'**
  String copyLayerName(Object name);

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
  /// **'创建新的数据备份'**
  String get createBackupDescription;

  /// No description provided for @creatingBackup.
  ///
  /// In zh, this message translates to:
  /// **'正在创建备份...'**
  String get creatingBackup;

  /// No description provided for @customSize.
  ///
  /// In zh, this message translates to:
  /// **'自定义大小'**
  String get customSize;

  /// No description provided for @days.
  ///
  /// In zh, this message translates to:
  /// **'{count, plural, =1{1天} other{{count}天}}'**
  String days(num count);

  /// No description provided for @delete.
  ///
  /// In zh, this message translates to:
  /// **'删除'**
  String get delete;

  /// No description provided for @deleteAll.
  ///
  /// In zh, this message translates to:
  /// **'删除全部'**
  String get deleteAll;

  /// No description provided for @deleteBackup.
  ///
  /// In zh, this message translates to:
  /// **'删除'**
  String get deleteBackup;

  /// No description provided for @deleteBackupConfirmMessage.
  ///
  /// In zh, this message translates to:
  /// **'确定要删除此备份吗？此操作无法撤消。'**
  String get deleteBackupConfirmMessage;

  /// No description provided for @deleteBackupConfirmTitle.
  ///
  /// In zh, this message translates to:
  /// **'删除备份'**
  String get deleteBackupConfirmTitle;

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

  /// No description provided for @deleteCategoryWithFilesConfirmMessage.
  ///
  /// In zh, this message translates to:
  /// **'确定要删除分类\"{name}\"及其包含的{count}个文件？此操作无法撤销！'**
  String deleteCategoryWithFilesConfirmMessage(Object count, Object name);

  /// No description provided for @deleteCategoryWithFilesWarning.
  ///
  /// In zh, this message translates to:
  /// **'警告'**
  String get deleteCategoryWithFilesWarning;

  /// No description provided for @deleteElementName.
  ///
  /// In zh, this message translates to:
  /// **'删除{type}元素'**
  String deleteElementName(Object type);

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

  /// No description provided for @deleteGroupDescription.
  ///
  /// In zh, this message translates to:
  /// **'确定要删除此组吗？此操作无法撤消。'**
  String get deleteGroupDescription;

  /// No description provided for @deleteGroupElements.
  ///
  /// In zh, this message translates to:
  /// **'删除组内元素'**
  String get deleteGroupElements;

  /// No description provided for @deletePage.
  ///
  /// In zh, this message translates to:
  /// **'删除页面'**
  String get deletePage;

  /// No description provided for @deleteSuccess.
  ///
  /// In zh, this message translates to:
  /// **'备份删除成功'**
  String get deleteSuccess;

  /// No description provided for @dimensions.
  ///
  /// In zh, this message translates to:
  /// **'尺寸'**
  String get dimensions;

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

  /// No description provided for @distributionOperations.
  ///
  /// In zh, this message translates to:
  /// **'分布操作'**
  String get distributionOperations;

  /// No description provided for @distributionRequiresThreeElements.
  ///
  /// In zh, this message translates to:
  /// **'分布操作需要至少3个元素'**
  String get distributionRequiresThreeElements;

  /// No description provided for @doubleClickToEdit.
  ///
  /// In zh, this message translates to:
  /// **'双击编辑文本'**
  String get doubleClickToEdit;

  /// No description provided for @edit.
  ///
  /// In zh, this message translates to:
  /// **'编辑'**
  String get edit;

  /// No description provided for @editCategory.
  ///
  /// In zh, this message translates to:
  /// **'编辑分类'**
  String get editCategory;

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

  /// No description provided for @elementCopied.
  ///
  /// In zh, this message translates to:
  /// **'元素已复制到剪贴板'**
  String get elementCopied;

  /// No description provided for @elementDistribution.
  ///
  /// In zh, this message translates to:
  /// **'元素分布'**
  String get elementDistribution;

  /// No description provided for @elementId.
  ///
  /// In zh, this message translates to:
  /// **'元素ID'**
  String get elementId;

  /// No description provided for @elements.
  ///
  /// In zh, this message translates to:
  /// **'元素'**
  String get elements;

  /// No description provided for @elementsCopied.
  ///
  /// In zh, this message translates to:
  /// **'{count}个元素已复制到剪贴板'**
  String elementsCopied(Object count);

  /// No description provided for @elementType.
  ///
  /// In zh, this message translates to:
  /// **'元素类型'**
  String get elementType;

  /// No description provided for @empty.
  ///
  /// In zh, this message translates to:
  /// **'空'**
  String get empty;

  /// No description provided for @enterFileName.
  ///
  /// In zh, this message translates to:
  /// **'输入文件名'**
  String get enterFileName;

  /// No description provided for @enterGroupEditMode.
  ///
  /// In zh, this message translates to:
  /// **'进入组编辑模式'**
  String get enterGroupEditMode;

  /// No description provided for @errorSelectingImage.
  ///
  /// In zh, this message translates to:
  /// **'选择图片时出错：{error}'**
  String errorSelectingImage(Object error);

  /// No description provided for @exitBatchMode.
  ///
  /// In zh, this message translates to:
  /// **'退出批量模式'**
  String get exitBatchMode;

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

  /// No description provided for @exportBackupDescription.
  ///
  /// In zh, this message translates to:
  /// **'将备份导出到外部位置'**
  String get exportBackupDescription;

  /// No description provided for @exportDialogAllPages.
  ///
  /// In zh, this message translates to:
  /// **'全部页面'**
  String get exportDialogAllPages;

  /// No description provided for @exportDialogBrowse.
  ///
  /// In zh, this message translates to:
  /// **'浏览...'**
  String get exportDialogBrowse;

  /// No description provided for @exportDialogCentimeter.
  ///
  /// In zh, this message translates to:
  /// **'厘米'**
  String get exportDialogCentimeter;

  /// No description provided for @exportDialogCreateDirectoryFailed.
  ///
  /// In zh, this message translates to:
  /// **'创建导出目录失败'**
  String get exportDialogCreateDirectoryFailed;

  /// No description provided for @exportDialogCurrentPage.
  ///
  /// In zh, this message translates to:
  /// **'当前页面'**
  String get exportDialogCurrentPage;

  /// No description provided for @exportDialogCustomRange.
  ///
  /// In zh, this message translates to:
  /// **'自定义范围'**
  String get exportDialogCustomRange;

  /// No description provided for @exportDialogDimensions.
  ///
  /// In zh, this message translates to:
  /// **'{width}厘米 × {height}厘米 ({orientation})'**
  String exportDialogDimensions(Object height, Object orientation, Object width);

  /// No description provided for @exportDialogEnterFilename.
  ///
  /// In zh, this message translates to:
  /// **'请输入文件名'**
  String get exportDialogEnterFilename;

  /// No description provided for @exportDialogFilenamePrefix.
  ///
  /// In zh, this message translates to:
  /// **'输入文件名前缀（将自动添加页码）'**
  String get exportDialogFilenamePrefix;

  /// No description provided for @exportDialogFitContain.
  ///
  /// In zh, this message translates to:
  /// **'包含在页面内'**
  String get exportDialogFitContain;

  /// No description provided for @exportDialogFitHeight.
  ///
  /// In zh, this message translates to:
  /// **'适合高度'**
  String get exportDialogFitHeight;

  /// No description provided for @exportDialogFitPolicy.
  ///
  /// In zh, this message translates to:
  /// **'适配方式'**
  String get exportDialogFitPolicy;

  /// No description provided for @exportDialogFitWidth.
  ///
  /// In zh, this message translates to:
  /// **'适合宽度'**
  String get exportDialogFitWidth;

  /// No description provided for @exportDialogInvalidFilename.
  ///
  /// In zh, this message translates to:
  /// **'文件名不能包含以下字符: \\ / : * ? \" < > |'**
  String get exportDialogInvalidFilename;

  /// No description provided for @exportDialogLandscape.
  ///
  /// In zh, this message translates to:
  /// **'横向'**
  String get exportDialogLandscape;

  /// No description provided for @exportDialogLocation.
  ///
  /// In zh, this message translates to:
  /// **'导出位置'**
  String get exportDialogLocation;

  /// No description provided for @exportDialogMarginBottom.
  ///
  /// In zh, this message translates to:
  /// **'下'**
  String get exportDialogMarginBottom;

  /// No description provided for @exportDialogMarginLeft.
  ///
  /// In zh, this message translates to:
  /// **'左'**
  String get exportDialogMarginLeft;

  /// No description provided for @exportDialogMarginRight.
  ///
  /// In zh, this message translates to:
  /// **'右'**
  String get exportDialogMarginRight;

  /// No description provided for @exportDialogMarginTop.
  ///
  /// In zh, this message translates to:
  /// **'上'**
  String get exportDialogMarginTop;

  /// No description provided for @exportDialogMultipleFilesNote.
  ///
  /// In zh, this message translates to:
  /// **'注意: 将导出 {count} 个图片文件，文件名将自动添加页码。'**
  String exportDialogMultipleFilesNote(Object count);

  /// No description provided for @exportDialogNextPage.
  ///
  /// In zh, this message translates to:
  /// **'下一页'**
  String get exportDialogNextPage;

  /// No description provided for @exportDialogNoPreview.
  ///
  /// In zh, this message translates to:
  /// **'无法生成预览'**
  String get exportDialogNoPreview;

  /// No description provided for @exportDialogOutputQuality.
  ///
  /// In zh, this message translates to:
  /// **'输出质量'**
  String get exportDialogOutputQuality;

  /// No description provided for @exportDialogPageMargins.
  ///
  /// In zh, this message translates to:
  /// **'页面边距 (厘米)'**
  String get exportDialogPageMargins;

  /// No description provided for @exportDialogPageOrientation.
  ///
  /// In zh, this message translates to:
  /// **'页面朝向'**
  String get exportDialogPageOrientation;

  /// No description provided for @exportDialogPageRange.
  ///
  /// In zh, this message translates to:
  /// **'页面范围'**
  String get exportDialogPageRange;

  /// No description provided for @exportDialogPageSize.
  ///
  /// In zh, this message translates to:
  /// **'页面大小'**
  String get exportDialogPageSize;

  /// No description provided for @exportDialogPortrait.
  ///
  /// In zh, this message translates to:
  /// **'纵向'**
  String get exportDialogPortrait;

  /// No description provided for @exportDialogPreview.
  ///
  /// In zh, this message translates to:
  /// **'预览'**
  String get exportDialogPreview;

  /// No description provided for @exportDialogPreviewPage.
  ///
  /// In zh, this message translates to:
  /// **' (第 {current}/{total} 页)'**
  String exportDialogPreviewPage(Object current, Object total);

  /// No description provided for @exportDialogPreviousPage.
  ///
  /// In zh, this message translates to:
  /// **'上一页'**
  String get exportDialogPreviousPage;

  /// No description provided for @exportDialogQualityHigh.
  ///
  /// In zh, this message translates to:
  /// **'高清 (2x)'**
  String get exportDialogQualityHigh;

  /// No description provided for @exportDialogQualityStandard.
  ///
  /// In zh, this message translates to:
  /// **'标准 (1x)'**
  String get exportDialogQualityStandard;

  /// No description provided for @exportDialogQualityUltra.
  ///
  /// In zh, this message translates to:
  /// **'超清 (3x)'**
  String get exportDialogQualityUltra;

  /// No description provided for @exportDialogRangeExample.
  ///
  /// In zh, this message translates to:
  /// **'例如: 1-3,5,7-9'**
  String get exportDialogRangeExample;

  /// No description provided for @exportDialogSelectLocation.
  ///
  /// In zh, this message translates to:
  /// **'请选择导出位置'**
  String get exportDialogSelectLocation;

  /// No description provided for @exportFailure.
  ///
  /// In zh, this message translates to:
  /// **'备份导出失败'**
  String get exportFailure;

  /// No description provided for @exportFormat.
  ///
  /// In zh, this message translates to:
  /// **'导出格式'**
  String get exportFormat;

  /// No description provided for @exportingBackup.
  ///
  /// In zh, this message translates to:
  /// **'导出备份中...'**
  String get exportingBackup;

  /// No description provided for @exportSuccess.
  ///
  /// In zh, this message translates to:
  /// **'备份导出成功'**
  String get exportSuccess;

  /// No description provided for @fileCount.
  ///
  /// In zh, this message translates to:
  /// **'文件数量'**
  String get fileCount;

  /// No description provided for @fileName.
  ///
  /// In zh, this message translates to:
  /// **'文件名'**
  String get fileName;

  /// No description provided for @files.
  ///
  /// In zh, this message translates to:
  /// **'文件数量'**
  String get files;

  /// No description provided for @filterApply.
  ///
  /// In zh, this message translates to:
  /// **'应用'**
  String get filterApply;

  /// No description provided for @filterBatchActions.
  ///
  /// In zh, this message translates to:
  /// **'批量操作'**
  String get filterBatchActions;

  /// No description provided for @filterBatchSelection.
  ///
  /// In zh, this message translates to:
  /// **'批量选择'**
  String get filterBatchSelection;

  /// No description provided for @filterClear.
  ///
  /// In zh, this message translates to:
  /// **'清除'**
  String get filterClear;

  /// No description provided for @filterCollapse.
  ///
  /// In zh, this message translates to:
  /// **'收起筛选面板'**
  String get filterCollapse;

  /// No description provided for @filterCustomRange.
  ///
  /// In zh, this message translates to:
  /// **'自定义范围'**
  String get filterCustomRange;

  /// No description provided for @filterDateApply.
  ///
  /// In zh, this message translates to:
  /// **'应用'**
  String get filterDateApply;

  /// No description provided for @filterDateClear.
  ///
  /// In zh, this message translates to:
  /// **'清除'**
  String get filterDateClear;

  /// No description provided for @filterDateCustom.
  ///
  /// In zh, this message translates to:
  /// **'自定义'**
  String get filterDateCustom;

  /// No description provided for @filterDateEndDate.
  ///
  /// In zh, this message translates to:
  /// **'结束日期'**
  String get filterDateEndDate;

  /// No description provided for @filterDatePresetAll.
  ///
  /// In zh, this message translates to:
  /// **'全部时间'**
  String get filterDatePresetAll;

  /// No description provided for @filterDatePresetLast30Days.
  ///
  /// In zh, this message translates to:
  /// **'最近30天'**
  String get filterDatePresetLast30Days;

  /// No description provided for @filterDatePresetLast365Days.
  ///
  /// In zh, this message translates to:
  /// **'最近365天'**
  String get filterDatePresetLast365Days;

  /// No description provided for @filterDatePresetLast7Days.
  ///
  /// In zh, this message translates to:
  /// **'最近7天'**
  String get filterDatePresetLast7Days;

  /// No description provided for @filterDatePresetLast90Days.
  ///
  /// In zh, this message translates to:
  /// **'最近90天'**
  String get filterDatePresetLast90Days;

  /// No description provided for @filterDatePresetLastMonth.
  ///
  /// In zh, this message translates to:
  /// **'上个月'**
  String get filterDatePresetLastMonth;

  /// No description provided for @filterDatePresetLastWeek.
  ///
  /// In zh, this message translates to:
  /// **'上周'**
  String get filterDatePresetLastWeek;

  /// No description provided for @filterDatePresetLastYear.
  ///
  /// In zh, this message translates to:
  /// **'去年'**
  String get filterDatePresetLastYear;

  /// No description provided for @filterDatePresets.
  ///
  /// In zh, this message translates to:
  /// **'预设'**
  String get filterDatePresets;

  /// No description provided for @filterDatePresetThisMonth.
  ///
  /// In zh, this message translates to:
  /// **'本月'**
  String get filterDatePresetThisMonth;

  /// No description provided for @filterDatePresetThisWeek.
  ///
  /// In zh, this message translates to:
  /// **'本周'**
  String get filterDatePresetThisWeek;

  /// No description provided for @filterDatePresetThisYear.
  ///
  /// In zh, this message translates to:
  /// **'今年'**
  String get filterDatePresetThisYear;

  /// No description provided for @filterDatePresetToday.
  ///
  /// In zh, this message translates to:
  /// **'今天'**
  String get filterDatePresetToday;

  /// No description provided for @filterDatePresetYesterday.
  ///
  /// In zh, this message translates to:
  /// **'昨天'**
  String get filterDatePresetYesterday;

  /// No description provided for @filterDateRange.
  ///
  /// In zh, this message translates to:
  /// **'日期范围'**
  String get filterDateRange;

  /// No description provided for @filterDateSection.
  ///
  /// In zh, this message translates to:
  /// **'创建时间'**
  String get filterDateSection;

  /// No description provided for @filterDateSelectPrompt.
  ///
  /// In zh, this message translates to:
  /// **'选择日期'**
  String get filterDateSelectPrompt;

  /// No description provided for @filterDateStartDate.
  ///
  /// In zh, this message translates to:
  /// **'开始日期'**
  String get filterDateStartDate;

  /// No description provided for @filterDeselectAll.
  ///
  /// In zh, this message translates to:
  /// **'取消全选'**
  String get filterDeselectAll;

  /// No description provided for @filterEndDate.
  ///
  /// In zh, this message translates to:
  /// **'结束日期'**
  String get filterEndDate;

  /// No description provided for @filterExpand.
  ///
  /// In zh, this message translates to:
  /// **'展开筛选面板'**
  String get filterExpand;

  /// No description provided for @filterFavoritesOnly.
  ///
  /// In zh, this message translates to:
  /// **'仅显示收藏'**
  String get filterFavoritesOnly;

  /// No description provided for @filterHeader.
  ///
  /// In zh, this message translates to:
  /// **'筛选'**
  String get filterHeader;

  /// No description provided for @filterItemsPerPage.
  ///
  /// In zh, this message translates to:
  /// **'每页 {count} 项'**
  String filterItemsPerPage(Object count);

  /// No description provided for @filterItemsSelected.
  ///
  /// In zh, this message translates to:
  /// **'已选择 {count} 项'**
  String filterItemsSelected(Object count);

  /// No description provided for @filterMax.
  ///
  /// In zh, this message translates to:
  /// **'最大'**
  String get filterMax;

  /// No description provided for @filterMin.
  ///
  /// In zh, this message translates to:
  /// **'最小'**
  String get filterMin;

  /// No description provided for @filterPanel.
  ///
  /// In zh, this message translates to:
  /// **'筛选面板'**
  String get filterPanel;

  /// No description provided for @filterPresetSection.
  ///
  /// In zh, this message translates to:
  /// **'预设'**
  String get filterPresetSection;

  /// No description provided for @filterReset.
  ///
  /// In zh, this message translates to:
  /// **'重置筛选'**
  String get filterReset;

  /// No description provided for @filterSearchPlaceholder.
  ///
  /// In zh, this message translates to:
  /// **'搜索...'**
  String get filterSearchPlaceholder;

  /// No description provided for @filterSection.
  ///
  /// In zh, this message translates to:
  /// **'筛选选项'**
  String get filterSection;

  /// No description provided for @filterSelectAll.
  ///
  /// In zh, this message translates to:
  /// **'全选'**
  String get filterSelectAll;

  /// No description provided for @filterSelectDate.
  ///
  /// In zh, this message translates to:
  /// **'选择日期'**
  String get filterSelectDate;

  /// No description provided for @filterSelectDateRange.
  ///
  /// In zh, this message translates to:
  /// **'选择日期范围'**
  String get filterSelectDateRange;

  /// No description provided for @filterSortAscending.
  ///
  /// In zh, this message translates to:
  /// **'升序'**
  String get filterSortAscending;

  /// No description provided for @filterSortDescending.
  ///
  /// In zh, this message translates to:
  /// **'降序'**
  String get filterSortDescending;

  /// No description provided for @filterSortDirection.
  ///
  /// In zh, this message translates to:
  /// **'排序方向'**
  String get filterSortDirection;

  /// No description provided for @filterSortField.
  ///
  /// In zh, this message translates to:
  /// **'排序字段'**
  String get filterSortField;

  /// No description provided for @filterSortFieldAuthor.
  ///
  /// In zh, this message translates to:
  /// **'作者'**
  String get filterSortFieldAuthor;

  /// No description provided for @filterSortFieldCreateTime.
  ///
  /// In zh, this message translates to:
  /// **'创建时间'**
  String get filterSortFieldCreateTime;

  /// No description provided for @filterSortFieldCreationDate.
  ///
  /// In zh, this message translates to:
  /// **'创作日期'**
  String get filterSortFieldCreationDate;

  /// No description provided for @filterSortFieldFileName.
  ///
  /// In zh, this message translates to:
  /// **'文件名称'**
  String get filterSortFieldFileName;

  /// No description provided for @filterSortFieldFileSize.
  ///
  /// In zh, this message translates to:
  /// **'文件大小'**
  String get filterSortFieldFileSize;

  /// No description provided for @filterSortFieldFileUpdatedAt.
  ///
  /// In zh, this message translates to:
  /// **'文件修改时间'**
  String get filterSortFieldFileUpdatedAt;

  /// No description provided for @filterSortFieldNone.
  ///
  /// In zh, this message translates to:
  /// **'无'**
  String get filterSortFieldNone;

  /// No description provided for @filterSortFieldStyle.
  ///
  /// In zh, this message translates to:
  /// **'风格'**
  String get filterSortFieldStyle;

  /// No description provided for @filterSortFieldTitle.
  ///
  /// In zh, this message translates to:
  /// **'标题'**
  String get filterSortFieldTitle;

  /// No description provided for @filterSortFieldTool.
  ///
  /// In zh, this message translates to:
  /// **'工具'**
  String get filterSortFieldTool;

  /// No description provided for @filterSortFieldUpdateTime.
  ///
  /// In zh, this message translates to:
  /// **'更新时间'**
  String get filterSortFieldUpdateTime;

  /// No description provided for @filterSortSection.
  ///
  /// In zh, this message translates to:
  /// **'排序'**
  String get filterSortSection;

  /// No description provided for @filterStartDate.
  ///
  /// In zh, this message translates to:
  /// **'开始日期'**
  String get filterStartDate;

  /// No description provided for @filterStyleClerical.
  ///
  /// In zh, this message translates to:
  /// **'隶书'**
  String get filterStyleClerical;

  /// No description provided for @filterStyleCursive.
  ///
  /// In zh, this message translates to:
  /// **'草书'**
  String get filterStyleCursive;

  /// No description provided for @filterStyleOther.
  ///
  /// In zh, this message translates to:
  /// **'其他'**
  String get filterStyleOther;

  /// No description provided for @filterStyleRegular.
  ///
  /// In zh, this message translates to:
  /// **'楷书'**
  String get filterStyleRegular;

  /// No description provided for @filterStyleRunning.
  ///
  /// In zh, this message translates to:
  /// **'行书'**
  String get filterStyleRunning;

  /// No description provided for @filterStyleSeal.
  ///
  /// In zh, this message translates to:
  /// **'篆书'**
  String get filterStyleSeal;

  /// No description provided for @filterStyleSection.
  ///
  /// In zh, this message translates to:
  /// **'书法风格'**
  String get filterStyleSection;

  /// No description provided for @filterTagsAdd.
  ///
  /// In zh, this message translates to:
  /// **'添加标签'**
  String get filterTagsAdd;

  /// No description provided for @filterTagsAddHint.
  ///
  /// In zh, this message translates to:
  /// **'输入标签名称并按回车'**
  String get filterTagsAddHint;

  /// No description provided for @filterTagsNone.
  ///
  /// In zh, this message translates to:
  /// **'未选择标签'**
  String get filterTagsNone;

  /// No description provided for @filterTagsSection.
  ///
  /// In zh, this message translates to:
  /// **'标签'**
  String get filterTagsSection;

  /// No description provided for @filterTagsSelected.
  ///
  /// In zh, this message translates to:
  /// **'已选标签：'**
  String get filterTagsSelected;

  /// No description provided for @filterTagsSuggested.
  ///
  /// In zh, this message translates to:
  /// **'推荐标签：'**
  String get filterTagsSuggested;

  /// No description provided for @filterTitle.
  ///
  /// In zh, this message translates to:
  /// **'筛选与排序'**
  String get filterTitle;

  /// No description provided for @filterToggle.
  ///
  /// In zh, this message translates to:
  /// **'切换筛选'**
  String get filterToggle;

  /// No description provided for @filterToolBrush.
  ///
  /// In zh, this message translates to:
  /// **'毛笔'**
  String get filterToolBrush;

  /// No description provided for @filterToolHardPen.
  ///
  /// In zh, this message translates to:
  /// **'硬笔'**
  String get filterToolHardPen;

  /// No description provided for @filterToolOther.
  ///
  /// In zh, this message translates to:
  /// **'其他'**
  String get filterToolOther;

  /// No description provided for @filterToolSection.
  ///
  /// In zh, this message translates to:
  /// **'书写工具'**
  String get filterToolSection;

  /// No description provided for @filterTotalItems.
  ///
  /// In zh, this message translates to:
  /// **'共计：{count} 项'**
  String filterTotalItems(Object count);

  /// No description provided for @generalSettings.
  ///
  /// In zh, this message translates to:
  /// **'常规设置'**
  String get generalSettings;

  /// No description provided for @geometryProperties.
  ///
  /// In zh, this message translates to:
  /// **'几何属性'**
  String get geometryProperties;

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
  /// **'组合'**
  String get group;

  /// No description provided for @groupElement.
  ///
  /// In zh, this message translates to:
  /// **'组合元素'**
  String get groupElement;

  /// No description provided for @groupElements.
  ///
  /// In zh, this message translates to:
  /// **'组合元素'**
  String get groupElements;

  /// No description provided for @groupInfo.
  ///
  /// In zh, this message translates to:
  /// **'组信息'**
  String get groupInfo;

  /// No description provided for @groupOperations.
  ///
  /// In zh, this message translates to:
  /// **'组合操作'**
  String get groupOperations;

  /// No description provided for @height.
  ///
  /// In zh, this message translates to:
  /// **'高度'**
  String get height;

  /// No description provided for @hideElement.
  ///
  /// In zh, this message translates to:
  /// **'隐藏元素'**
  String get hideElement;

  /// No description provided for @hideImagePreview.
  ///
  /// In zh, this message translates to:
  /// **'隐藏图片预览'**
  String get hideImagePreview;

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

  /// No description provided for @imageCacheCleared.
  ///
  /// In zh, this message translates to:
  /// **'图像缓存已清除'**
  String get imageCacheCleared;

  /// No description provided for @imageCacheClearFailed.
  ///
  /// In zh, this message translates to:
  /// **'清除图像缓存失败'**
  String get imageCacheClearFailed;

  /// No description provided for @imageElement.
  ///
  /// In zh, this message translates to:
  /// **'图片元素'**
  String get imageElement;

  /// No description provided for @imagePropertyPanel.
  ///
  /// In zh, this message translates to:
  /// **'图像属性'**
  String get imagePropertyPanel;

  /// No description provided for @imagePropertyPanelApplyTransform.
  ///
  /// In zh, this message translates to:
  /// **'应用变换'**
  String get imagePropertyPanelApplyTransform;

  /// No description provided for @imagePropertyPanelAutoImportNotice.
  ///
  /// In zh, this message translates to:
  /// **'所选图像将自动导入到您的图库中以便更好地管理'**
  String get imagePropertyPanelAutoImportNotice;

  /// No description provided for @imagePropertyPanelBorder.
  ///
  /// In zh, this message translates to:
  /// **'边框'**
  String get imagePropertyPanelBorder;

  /// No description provided for @imagePropertyPanelBorderColor.
  ///
  /// In zh, this message translates to:
  /// **'边框颜色'**
  String get imagePropertyPanelBorderColor;

  /// No description provided for @imagePropertyPanelBorderWidth.
  ///
  /// In zh, this message translates to:
  /// **'边框宽度'**
  String get imagePropertyPanelBorderWidth;

  /// No description provided for @imagePropertyPanelBrightness.
  ///
  /// In zh, this message translates to:
  /// **'亮度'**
  String get imagePropertyPanelBrightness;

  /// No description provided for @imagePropertyPanelCannotApplyNoImage.
  ///
  /// In zh, this message translates to:
  /// **'没有可用的图片'**
  String get imagePropertyPanelCannotApplyNoImage;

  /// No description provided for @imagePropertyPanelCannotApplyNoSizeInfo.
  ///
  /// In zh, this message translates to:
  /// **'无法获取图片尺寸信息'**
  String get imagePropertyPanelCannotApplyNoSizeInfo;

  /// No description provided for @imagePropertyPanelContent.
  ///
  /// In zh, this message translates to:
  /// **'内容属性'**
  String get imagePropertyPanelContent;

  /// No description provided for @imagePropertyPanelContrast.
  ///
  /// In zh, this message translates to:
  /// **'对比度'**
  String get imagePropertyPanelContrast;

  /// No description provided for @imagePropertyPanelCornerRadius.
  ///
  /// In zh, this message translates to:
  /// **'圆角半径'**
  String get imagePropertyPanelCornerRadius;

  /// No description provided for @imagePropertyPanelCropBottom.
  ///
  /// In zh, this message translates to:
  /// **'底部裁剪'**
  String get imagePropertyPanelCropBottom;

  /// No description provided for @imagePropertyPanelCropLeft.
  ///
  /// In zh, this message translates to:
  /// **'左侧裁剪'**
  String get imagePropertyPanelCropLeft;

  /// No description provided for @imagePropertyPanelCropping.
  ///
  /// In zh, this message translates to:
  /// **'裁剪'**
  String get imagePropertyPanelCropping;

  /// No description provided for @imagePropertyPanelCroppingApplied.
  ///
  /// In zh, this message translates to:
  /// **' (裁剪：左{left}px，上{top}px，右{right}px，下{bottom}px)'**
  String imagePropertyPanelCroppingApplied(Object bottom, Object left, Object right, Object top);

  /// No description provided for @imagePropertyPanelCroppingValueTooLarge.
  ///
  /// In zh, this message translates to:
  /// **'无法应用变换：裁剪值过大，导致无效的裁剪区域'**
  String get imagePropertyPanelCroppingValueTooLarge;

  /// No description provided for @imagePropertyPanelCropRight.
  ///
  /// In zh, this message translates to:
  /// **'右侧裁剪'**
  String get imagePropertyPanelCropRight;

  /// No description provided for @imagePropertyPanelCropTop.
  ///
  /// In zh, this message translates to:
  /// **'顶部裁剪'**
  String get imagePropertyPanelCropTop;

  /// No description provided for @imagePropertyPanelDimensions.
  ///
  /// In zh, this message translates to:
  /// **'尺寸'**
  String get imagePropertyPanelDimensions;

  /// No description provided for @imagePropertyPanelDisplay.
  ///
  /// In zh, this message translates to:
  /// **'显示模式'**
  String get imagePropertyPanelDisplay;

  /// No description provided for @imagePropertyPanelErrorMessage.
  ///
  /// In zh, this message translates to:
  /// **'发生错误: {error}'**
  String imagePropertyPanelErrorMessage(Object error);

  /// No description provided for @imagePropertyPanelFileLoadError.
  ///
  /// In zh, this message translates to:
  /// **'文件加载失败'**
  String imagePropertyPanelFileLoadError(Object error);

  /// No description provided for @imagePropertyPanelFileNotExist.
  ///
  /// In zh, this message translates to:
  /// **'文件不存在：{path}'**
  String imagePropertyPanelFileNotExist(Object path);

  /// No description provided for @imagePropertyPanelFileNotRecovered.
  ///
  /// In zh, this message translates to:
  /// **'图片文件丢失且无法恢复'**
  String get imagePropertyPanelFileNotRecovered;

  /// No description provided for @imagePropertyPanelFileRestored.
  ///
  /// In zh, this message translates to:
  /// **'图片已从图库中恢复'**
  String get imagePropertyPanelFileRestored;

  /// No description provided for @imagePropertyPanelFilters.
  ///
  /// In zh, this message translates to:
  /// **'图像滤镜'**
  String get imagePropertyPanelFilters;

  /// No description provided for @imagePropertyPanelFit.
  ///
  /// In zh, this message translates to:
  /// **'适应'**
  String get imagePropertyPanelFit;

  /// No description provided for @imagePropertyPanelFitContain.
  ///
  /// In zh, this message translates to:
  /// **'包含'**
  String get imagePropertyPanelFitContain;

  /// No description provided for @imagePropertyPanelFitCover.
  ///
  /// In zh, this message translates to:
  /// **'覆盖'**
  String get imagePropertyPanelFitCover;

  /// No description provided for @imagePropertyPanelFitFill.
  ///
  /// In zh, this message translates to:
  /// **'填充'**
  String get imagePropertyPanelFitFill;

  /// No description provided for @imagePropertyPanelFitMode.
  ///
  /// In zh, this message translates to:
  /// **'适应模式'**
  String get imagePropertyPanelFitMode;

  /// No description provided for @imagePropertyPanelFitNone.
  ///
  /// In zh, this message translates to:
  /// **'无'**
  String get imagePropertyPanelFitNone;

  /// No description provided for @imagePropertyPanelFitOriginal.
  ///
  /// In zh, this message translates to:
  /// **'原始'**
  String get imagePropertyPanelFitOriginal;

  /// No description provided for @imagePropertyPanelFlip.
  ///
  /// In zh, this message translates to:
  /// **'翻转'**
  String get imagePropertyPanelFlip;

  /// No description provided for @imagePropertyPanelFlipHorizontal.
  ///
  /// In zh, this message translates to:
  /// **'水平翻转'**
  String get imagePropertyPanelFlipHorizontal;

  /// No description provided for @imagePropertyPanelFlipVertical.
  ///
  /// In zh, this message translates to:
  /// **'垂直翻转'**
  String get imagePropertyPanelFlipVertical;

  /// No description provided for @imagePropertyPanelGeometry.
  ///
  /// In zh, this message translates to:
  /// **'几何属性'**
  String get imagePropertyPanelGeometry;

  /// No description provided for @imagePropertyPanelGeometryWarning.
  ///
  /// In zh, this message translates to:
  /// **'这些属性调整整个元素框，而不是图像内容本身'**
  String get imagePropertyPanelGeometryWarning;

  /// No description provided for @imagePropertyPanelImageSelection.
  ///
  /// In zh, this message translates to:
  /// **'图片选择'**
  String get imagePropertyPanelImageSelection;

  /// No description provided for @imagePropertyPanelImageSize.
  ///
  /// In zh, this message translates to:
  /// **'图像大小'**
  String get imagePropertyPanelImageSize;

  /// No description provided for @imagePropertyPanelImageTransform.
  ///
  /// In zh, this message translates to:
  /// **'图像变换'**
  String get imagePropertyPanelImageTransform;

  /// No description provided for @imagePropertyPanelImportError.
  ///
  /// In zh, this message translates to:
  /// **'导入图像失败：{error}'**
  String imagePropertyPanelImportError(Object error);

  /// No description provided for @imagePropertyPanelImporting.
  ///
  /// In zh, this message translates to:
  /// **'导入图像中...'**
  String get imagePropertyPanelImporting;

  /// No description provided for @imagePropertyPanelImportSuccess.
  ///
  /// In zh, this message translates to:
  /// **'图像导入成功'**
  String get imagePropertyPanelImportSuccess;

  /// No description provided for @imagePropertyPanelLibraryProcessing.
  ///
  /// In zh, this message translates to:
  /// **'图库功能开发中...'**
  String get imagePropertyPanelLibraryProcessing;

  /// No description provided for @imagePropertyPanelLoadError.
  ///
  /// In zh, this message translates to:
  /// **'加载图像失败：{error}...'**
  String imagePropertyPanelLoadError(Object error);

  /// No description provided for @imagePropertyPanelLoading.
  ///
  /// In zh, this message translates to:
  /// **'加载中...'**
  String get imagePropertyPanelLoading;

  /// No description provided for @imagePropertyPanelNoCropping.
  ///
  /// In zh, this message translates to:
  /// **'（无裁剪）'**
  String get imagePropertyPanelNoCropping;

  /// No description provided for @imagePropertyPanelNoImage.
  ///
  /// In zh, this message translates to:
  /// **'未选择图像'**
  String get imagePropertyPanelNoImage;

  /// No description provided for @imagePropertyPanelNoImageSelected.
  ///
  /// In zh, this message translates to:
  /// **'未选择图片'**
  String get imagePropertyPanelNoImageSelected;

  /// No description provided for @imagePropertyPanelOpacity.
  ///
  /// In zh, this message translates to:
  /// **'不透明度'**
  String get imagePropertyPanelOpacity;

  /// No description provided for @imagePropertyPanelOriginalSize.
  ///
  /// In zh, this message translates to:
  /// **'原始大小'**
  String get imagePropertyPanelOriginalSize;

  /// No description provided for @imagePropertyPanelPosition.
  ///
  /// In zh, this message translates to:
  /// **'位置'**
  String get imagePropertyPanelPosition;

  /// No description provided for @imagePropertyPanelPreserveRatio.
  ///
  /// In zh, this message translates to:
  /// **'保持宽高比'**
  String get imagePropertyPanelPreserveRatio;

  /// No description provided for @imagePropertyPanelPreview.
  ///
  /// In zh, this message translates to:
  /// **'图像预览'**
  String get imagePropertyPanelPreview;

  /// No description provided for @imagePropertyPanelPreviewNotice.
  ///
  /// In zh, this message translates to:
  /// **'注意：预览期间显示的重复日志是正常的'**
  String get imagePropertyPanelPreviewNotice;

  /// No description provided for @imagePropertyPanelProcessingPathError.
  ///
  /// In zh, this message translates to:
  /// **'处理路径错误：{error}'**
  String imagePropertyPanelProcessingPathError(Object error);

  /// No description provided for @imagePropertyPanelReset.
  ///
  /// In zh, this message translates to:
  /// **'重置'**
  String get imagePropertyPanelReset;

  /// No description provided for @imagePropertyPanelResetSuccess.
  ///
  /// In zh, this message translates to:
  /// **'重置成功'**
  String get imagePropertyPanelResetSuccess;

  /// No description provided for @imagePropertyPanelResetTransform.
  ///
  /// In zh, this message translates to:
  /// **'重置变换'**
  String get imagePropertyPanelResetTransform;

  /// No description provided for @imagePropertyPanelRotation.
  ///
  /// In zh, this message translates to:
  /// **'旋转'**
  String get imagePropertyPanelRotation;

  /// No description provided for @imagePropertyPanelSaturation.
  ///
  /// In zh, this message translates to:
  /// **'饱和度'**
  String get imagePropertyPanelSaturation;

  /// No description provided for @imagePropertyPanelSelectFromLibrary.
  ///
  /// In zh, this message translates to:
  /// **'从图库选择'**
  String get imagePropertyPanelSelectFromLibrary;

  /// No description provided for @imagePropertyPanelSelectFromLocal.
  ///
  /// In zh, this message translates to:
  /// **'从本地选择'**
  String get imagePropertyPanelSelectFromLocal;

  /// No description provided for @imagePropertyPanelSelectFromLocalDescription.
  ///
  /// In zh, this message translates to:
  /// **'选择的图片将会自动导入到图库'**
  String get imagePropertyPanelSelectFromLocalDescription;

  /// No description provided for @imagePropertyPanelTitle.
  ///
  /// In zh, this message translates to:
  /// **'图片属性'**
  String get imagePropertyPanelTitle;

  /// No description provided for @imagePropertyPanelTransformApplied.
  ///
  /// In zh, this message translates to:
  /// **'变换已应用'**
  String get imagePropertyPanelTransformApplied;

  /// No description provided for @imagePropertyPanelTransformError.
  ///
  /// In zh, this message translates to:
  /// **'应用变换失败：{error}'**
  String imagePropertyPanelTransformError(Object error);

  /// No description provided for @imagePropertyPanelTransformWarning.
  ///
  /// In zh, this message translates to:
  /// **'这些变换会修改图像内容本身，而不仅仅是元素框架'**
  String get imagePropertyPanelTransformWarning;

  /// No description provided for @imagePropertyPanelVisual.
  ///
  /// In zh, this message translates to:
  /// **'视觉设置'**
  String get imagePropertyPanelVisual;

  /// No description provided for @imageUpdated.
  ///
  /// In zh, this message translates to:
  /// **'图片已更新'**
  String get imageUpdated;

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

  /// No description provided for @importBackupDescription.
  ///
  /// In zh, this message translates to:
  /// **'从外部位置导入备份'**
  String get importBackupDescription;

  /// No description provided for @importFailure.
  ///
  /// In zh, this message translates to:
  /// **'备份导入失败'**
  String get importFailure;

  /// No description provided for @importingBackup.
  ///
  /// In zh, this message translates to:
  /// **'正在导入备份...'**
  String get importingBackup;

  /// No description provided for @importSuccess.
  ///
  /// In zh, this message translates to:
  /// **'备份导入成功'**
  String get importSuccess;

  /// No description provided for @initializationFailed.
  ///
  /// In zh, this message translates to:
  /// **'初始化失败：{error}'**
  String initializationFailed(Object error);

  /// No description provided for @invalidBackupFile.
  ///
  /// In zh, this message translates to:
  /// **'无效的备份文件'**
  String get invalidBackupFile;

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

  /// No description provided for @lastBackupTime.
  ///
  /// In zh, this message translates to:
  /// **'上次备份时间'**
  String get lastBackupTime;

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

  /// No description provided for @libraryManagementBasicInfo.
  ///
  /// In zh, this message translates to:
  /// **'基本信息'**
  String get libraryManagementBasicInfo;

  /// No description provided for @libraryManagementCategories.
  ///
  /// In zh, this message translates to:
  /// **'分类'**
  String get libraryManagementCategories;

  /// No description provided for @libraryManagementCreatedAt.
  ///
  /// In zh, this message translates to:
  /// **'创建时间'**
  String get libraryManagementCreatedAt;

  /// No description provided for @libraryManagementDeleteConfirm.
  ///
  /// In zh, this message translates to:
  /// **'确认删除'**
  String get libraryManagementDeleteConfirm;

  /// No description provided for @libraryManagementDeleteMessage.
  ///
  /// In zh, this message translates to:
  /// **'确定要删除选中的项目吗？此操作不可恢复。'**
  String get libraryManagementDeleteMessage;

  /// No description provided for @libraryManagementDeleteSelected.
  ///
  /// In zh, this message translates to:
  /// **'删除选中项目'**
  String get libraryManagementDeleteSelected;

  /// No description provided for @libraryManagementDetail.
  ///
  /// In zh, this message translates to:
  /// **'详情'**
  String get libraryManagementDetail;

  /// No description provided for @libraryManagementEnterBatchMode.
  ///
  /// In zh, this message translates to:
  /// **'进入批量选择模式'**
  String get libraryManagementEnterBatchMode;

  /// No description provided for @libraryManagementError.
  ///
  /// In zh, this message translates to:
  /// **'加载失败：{message}'**
  String libraryManagementError(Object message);

  /// No description provided for @libraryManagementExitBatchMode.
  ///
  /// In zh, this message translates to:
  /// **'退出批量选择模式'**
  String get libraryManagementExitBatchMode;

  /// No description provided for @libraryManagementFavorite.
  ///
  /// In zh, this message translates to:
  /// **'收藏'**
  String get libraryManagementFavorite;

  /// No description provided for @libraryManagementFavorites.
  ///
  /// In zh, this message translates to:
  /// **'收藏'**
  String get libraryManagementFavorites;

  /// No description provided for @libraryManagementFileSize.
  ///
  /// In zh, this message translates to:
  /// **'文件大小'**
  String get libraryManagementFileSize;

  /// No description provided for @libraryManagementFormat.
  ///
  /// In zh, this message translates to:
  /// **'格式'**
  String get libraryManagementFormat;

  /// No description provided for @libraryManagementFormats.
  ///
  /// In zh, this message translates to:
  /// **'格式'**
  String get libraryManagementFormats;

  /// No description provided for @libraryManagementGridView.
  ///
  /// In zh, this message translates to:
  /// **'网格视图'**
  String get libraryManagementGridView;

  /// No description provided for @libraryManagementImport.
  ///
  /// In zh, this message translates to:
  /// **'导入'**
  String get libraryManagementImport;

  /// No description provided for @libraryManagementImportFiles.
  ///
  /// In zh, this message translates to:
  /// **'导入文件'**
  String get libraryManagementImportFiles;

  /// No description provided for @libraryManagementImportFolder.
  ///
  /// In zh, this message translates to:
  /// **'导入文件夹'**
  String get libraryManagementImportFolder;

  /// No description provided for @libraryManagementListView.
  ///
  /// In zh, this message translates to:
  /// **'列表视图'**
  String get libraryManagementListView;

  /// No description provided for @libraryManagementLoading.
  ///
  /// In zh, this message translates to:
  /// **'加载中...'**
  String get libraryManagementLoading;

  /// No description provided for @libraryManagementLocation.
  ///
  /// In zh, this message translates to:
  /// **'位置'**
  String get libraryManagementLocation;

  /// No description provided for @libraryManagementMetadata.
  ///
  /// In zh, this message translates to:
  /// **'元数据'**
  String get libraryManagementMetadata;

  /// No description provided for @libraryManagementName.
  ///
  /// In zh, this message translates to:
  /// **'名称'**
  String get libraryManagementName;

  /// No description provided for @libraryManagementNoItems.
  ///
  /// In zh, this message translates to:
  /// **'暂无项目'**
  String get libraryManagementNoItems;

  /// No description provided for @libraryManagementNoItemsHint.
  ///
  /// In zh, this message translates to:
  /// **'尝试添加一些项目或更改筛选条件'**
  String get libraryManagementNoItemsHint;

  /// No description provided for @libraryManagementNoRemarks.
  ///
  /// In zh, this message translates to:
  /// **'无备注'**
  String get libraryManagementNoRemarks;

  /// No description provided for @libraryManagementPath.
  ///
  /// In zh, this message translates to:
  /// **'路径'**
  String get libraryManagementPath;

  /// No description provided for @libraryManagementRemarks.
  ///
  /// In zh, this message translates to:
  /// **'备注'**
  String get libraryManagementRemarks;

  /// No description provided for @libraryManagementRemarksHint.
  ///
  /// In zh, this message translates to:
  /// **'添加备注信息'**
  String get libraryManagementRemarksHint;

  /// No description provided for @libraryManagementResolution.
  ///
  /// In zh, this message translates to:
  /// **'分辨率'**
  String get libraryManagementResolution;

  /// No description provided for @libraryManagementSearch.
  ///
  /// In zh, this message translates to:
  /// **'搜索项目...'**
  String get libraryManagementSearch;

  /// No description provided for @libraryManagementSize.
  ///
  /// In zh, this message translates to:
  /// **'尺寸'**
  String get libraryManagementSize;

  /// No description provided for @libraryManagementSizeHeight.
  ///
  /// In zh, this message translates to:
  /// **'高度'**
  String get libraryManagementSizeHeight;

  /// No description provided for @libraryManagementSizeWidth.
  ///
  /// In zh, this message translates to:
  /// **'宽度'**
  String get libraryManagementSizeWidth;

  /// No description provided for @libraryManagementSortBy.
  ///
  /// In zh, this message translates to:
  /// **'排序方式'**
  String get libraryManagementSortBy;

  /// No description provided for @libraryManagementSortByDate.
  ///
  /// In zh, this message translates to:
  /// **'按日期'**
  String get libraryManagementSortByDate;

  /// No description provided for @libraryManagementSortByFileSize.
  ///
  /// In zh, this message translates to:
  /// **'按文件大小'**
  String get libraryManagementSortByFileSize;

  /// No description provided for @libraryManagementSortByName.
  ///
  /// In zh, this message translates to:
  /// **'按名称'**
  String get libraryManagementSortByName;

  /// No description provided for @libraryManagementSortBySize.
  ///
  /// In zh, this message translates to:
  /// **'按文件大小'**
  String get libraryManagementSortBySize;

  /// No description provided for @libraryManagementSortDesc.
  ///
  /// In zh, this message translates to:
  /// **'降序'**
  String get libraryManagementSortDesc;

  /// No description provided for @libraryManagementTags.
  ///
  /// In zh, this message translates to:
  /// **'标签'**
  String get libraryManagementTags;

  /// No description provided for @libraryManagementTimeInfo.
  ///
  /// In zh, this message translates to:
  /// **'时间信息'**
  String get libraryManagementTimeInfo;

  /// No description provided for @libraryManagementType.
  ///
  /// In zh, this message translates to:
  /// **'类型'**
  String get libraryManagementType;

  /// No description provided for @libraryManagementTypes.
  ///
  /// In zh, this message translates to:
  /// **'类型'**
  String get libraryManagementTypes;

  /// No description provided for @libraryManagementUpdatedAt.
  ///
  /// In zh, this message translates to:
  /// **'更新时间'**
  String get libraryManagementUpdatedAt;

  /// No description provided for @listView.
  ///
  /// In zh, this message translates to:
  /// **'列表视图'**
  String get listView;

  /// No description provided for @loadFailed.
  ///
  /// In zh, this message translates to:
  /// **'加载失败'**
  String get loadFailed;

  /// No description provided for @loadingError.
  ///
  /// In zh, this message translates to:
  /// **'加载错误'**
  String get loadingError;

  /// No description provided for @locked.
  ///
  /// In zh, this message translates to:
  /// **'已锁定'**
  String get locked;

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

  /// No description provided for @moveDown.
  ///
  /// In zh, this message translates to:
  /// **'下移'**
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

  /// No description provided for @moveSelectedElementsToLayer.
  ///
  /// In zh, this message translates to:
  /// **'移动选中元素到图层'**
  String get moveSelectedElementsToLayer;

  /// No description provided for @moveUp.
  ///
  /// In zh, this message translates to:
  /// **'上移'**
  String get moveUp;

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

  /// No description provided for @newCategory.
  ///
  /// In zh, this message translates to:
  /// **'新建分类'**
  String get newCategory;

  /// No description provided for @nextImage.
  ///
  /// In zh, this message translates to:
  /// **'下一张图片'**
  String get nextImage;

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

  /// No description provided for @noPageSelected.
  ///
  /// In zh, this message translates to:
  /// **'未选择页面'**
  String get noPageSelected;

  /// No description provided for @noTags.
  ///
  /// In zh, this message translates to:
  /// **'无标签'**
  String get noTags;

  /// No description provided for @ok.
  ///
  /// In zh, this message translates to:
  /// **'确定'**
  String get ok;

  /// No description provided for @opacity.
  ///
  /// In zh, this message translates to:
  /// **'不透明度'**
  String get opacity;

  /// No description provided for @pageName.
  ///
  /// In zh, this message translates to:
  /// **'页面{index}'**
  String pageName(Object index);

  /// No description provided for @pageOrientation.
  ///
  /// In zh, this message translates to:
  /// **'页面方向'**
  String get pageOrientation;

  /// No description provided for @pageSize.
  ///
  /// In zh, this message translates to:
  /// **'页面大小'**
  String get pageSize;

  /// No description provided for @pixels.
  ///
  /// In zh, this message translates to:
  /// **'像素'**
  String get pixels;

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

  /// No description provided for @ppiHelperText.
  ///
  /// In zh, this message translates to:
  /// **'用于计算画布像素大小，默认300ppi'**
  String get ppiHelperText;

  /// No description provided for @ppiSetting.
  ///
  /// In zh, this message translates to:
  /// **'PPI设置（每英寸像素数）'**
  String get ppiSetting;

  /// No description provided for @practiceEditAddElementTitle.
  ///
  /// In zh, this message translates to:
  /// **'添加元素'**
  String get practiceEditAddElementTitle;

  /// No description provided for @practiceEditAddLayer.
  ///
  /// In zh, this message translates to:
  /// **'添加图层'**
  String get practiceEditAddLayer;

  /// No description provided for @practiceEditBackToHome.
  ///
  /// In zh, this message translates to:
  /// **'返回首页'**
  String get practiceEditBackToHome;

  /// No description provided for @practiceEditBringToFront.
  ///
  /// In zh, this message translates to:
  /// **'置于顶层 (Ctrl+T)'**
  String get practiceEditBringToFront;

  /// No description provided for @practiceEditCannotSaveNoPages.
  ///
  /// In zh, this message translates to:
  /// **'无法保存：字帖无页面'**
  String get practiceEditCannotSaveNoPages;

  /// No description provided for @practiceEditCollection.
  ///
  /// In zh, this message translates to:
  /// **'采集'**
  String get practiceEditCollection;

  /// No description provided for @practiceEditCollectionProperties.
  ///
  /// In zh, this message translates to:
  /// **'采集属性'**
  String get practiceEditCollectionProperties;

  /// No description provided for @practiceEditConfirmDeleteMessage.
  ///
  /// In zh, this message translates to:
  /// **'确定要删除这些元素吗？'**
  String get practiceEditConfirmDeleteMessage;

  /// No description provided for @practiceEditConfirmDeleteTitle.
  ///
  /// In zh, this message translates to:
  /// **'确认删除'**
  String get practiceEditConfirmDeleteTitle;

  /// No description provided for @practiceEditContentProperties.
  ///
  /// In zh, this message translates to:
  /// **'内容属性'**
  String get practiceEditContentProperties;

  /// No description provided for @practiceEditContentTools.
  ///
  /// In zh, this message translates to:
  /// **'内容工具'**
  String get practiceEditContentTools;

  /// No description provided for @practiceEditCopy.
  ///
  /// In zh, this message translates to:
  /// **'复制 (Ctrl+Shift+C)'**
  String get practiceEditCopy;

  /// No description provided for @practiceEditDangerZone.
  ///
  /// In zh, this message translates to:
  /// **'危险区域'**
  String get practiceEditDangerZone;

  /// No description provided for @practiceEditDefaultLayer.
  ///
  /// In zh, this message translates to:
  /// **'默认图层'**
  String get practiceEditDefaultLayer;

  /// No description provided for @practiceEditDelete.
  ///
  /// In zh, this message translates to:
  /// **'删除 (Ctrl+D)'**
  String get practiceEditDelete;

  /// No description provided for @practiceEditDeleteLayer.
  ///
  /// In zh, this message translates to:
  /// **'删除图层'**
  String get practiceEditDeleteLayer;

  /// No description provided for @practiceEditDeleteLayerConfirm.
  ///
  /// In zh, this message translates to:
  /// **'确定要删除此图层吗？'**
  String get practiceEditDeleteLayerConfirm;

  /// No description provided for @practiceEditDeleteLayerMessage.
  ///
  /// In zh, this message translates to:
  /// **'此图层上的所有元素将被删除。此操作无法撤消。'**
  String get practiceEditDeleteLayerMessage;

  /// No description provided for @practiceEditDisableSnap.
  ///
  /// In zh, this message translates to:
  /// **'禁用对齐 (Ctrl+R)'**
  String get practiceEditDisableSnap;

  /// No description provided for @practiceEditEditOperations.
  ///
  /// In zh, this message translates to:
  /// **'编辑操作'**
  String get practiceEditEditOperations;

  /// No description provided for @practiceEditEditTitle.
  ///
  /// In zh, this message translates to:
  /// **'编辑标题'**
  String get practiceEditEditTitle;

  /// No description provided for @practiceEditElementProperties.
  ///
  /// In zh, this message translates to:
  /// **'元素属性'**
  String get practiceEditElementProperties;

  /// No description provided for @practiceEditElements.
  ///
  /// In zh, this message translates to:
  /// **'元素'**
  String get practiceEditElements;

  /// No description provided for @practiceEditElementSelectionInfo.
  ///
  /// In zh, this message translates to:
  /// **'已选择{count}个元素'**
  String practiceEditElementSelectionInfo(Object count);

  /// No description provided for @practiceEditEnableSnap.
  ///
  /// In zh, this message translates to:
  /// **'启用对齐 (Ctrl+R)'**
  String get practiceEditEnableSnap;

  /// No description provided for @practiceEditEnterTitle.
  ///
  /// In zh, this message translates to:
  /// **'请输入字帖标题'**
  String get practiceEditEnterTitle;

  /// No description provided for @practiceEditExit.
  ///
  /// In zh, this message translates to:
  /// **'退出'**
  String get practiceEditExit;

  /// No description provided for @practiceEditGeometryProperties.
  ///
  /// In zh, this message translates to:
  /// **'几何属性'**
  String get practiceEditGeometryProperties;

  /// No description provided for @practiceEditGroup.
  ///
  /// In zh, this message translates to:
  /// **'组合 (Ctrl+J)'**
  String get practiceEditGroup;

  /// No description provided for @practiceEditGroupProperties.
  ///
  /// In zh, this message translates to:
  /// **'组属性'**
  String get practiceEditGroupProperties;

  /// No description provided for @practiceEditHelperFunctions.
  ///
  /// In zh, this message translates to:
  /// **'辅助功能'**
  String get practiceEditHelperFunctions;

  /// No description provided for @practiceEditHideGrid.
  ///
  /// In zh, this message translates to:
  /// **'隐藏网格 (Ctrl+G)'**
  String get practiceEditHideGrid;

  /// No description provided for @practiceEditImage.
  ///
  /// In zh, this message translates to:
  /// **'图像'**
  String get practiceEditImage;

  /// No description provided for @practiceEditImageProperties.
  ///
  /// In zh, this message translates to:
  /// **'图像属性'**
  String get practiceEditImageProperties;

  /// No description provided for @practiceEditLayerOperations.
  ///
  /// In zh, this message translates to:
  /// **'图层操作'**
  String get practiceEditLayerOperations;

  /// No description provided for @practiceEditLayerPanel.
  ///
  /// In zh, this message translates to:
  /// **'图层'**
  String get practiceEditLayerPanel;

  /// No description provided for @practiceEditLayerProperties.
  ///
  /// In zh, this message translates to:
  /// **'图层属性'**
  String get practiceEditLayerProperties;

  /// No description provided for @practiceEditLeave.
  ///
  /// In zh, this message translates to:
  /// **'离开'**
  String get practiceEditLeave;

  /// No description provided for @practiceEditLoadFailed.
  ///
  /// In zh, this message translates to:
  /// **'加载字帖失败：{error}'**
  String practiceEditLoadFailed(Object error);

  /// No description provided for @practiceEditMoveDown.
  ///
  /// In zh, this message translates to:
  /// **'下移 (Ctrl+Shift+B)'**
  String get practiceEditMoveDown;

  /// No description provided for @practiceEditMoveUp.
  ///
  /// In zh, this message translates to:
  /// **'上移 (Ctrl+Shift+T)'**
  String get practiceEditMoveUp;

  /// No description provided for @practiceEditMultiSelectionProperties.
  ///
  /// In zh, this message translates to:
  /// **'多选属性'**
  String get practiceEditMultiSelectionProperties;

  /// No description provided for @practiceEditNoLayers.
  ///
  /// In zh, this message translates to:
  /// **'无图层，请添加图层'**
  String get practiceEditNoLayers;

  /// No description provided for @practiceEditOverwrite.
  ///
  /// In zh, this message translates to:
  /// **'覆盖'**
  String get practiceEditOverwrite;

  /// No description provided for @practiceEditPageProperties.
  ///
  /// In zh, this message translates to:
  /// **'页面属性'**
  String get practiceEditPageProperties;

  /// No description provided for @practiceEditPaste.
  ///
  /// In zh, this message translates to:
  /// **'粘贴 (Ctrl+Shift+V)'**
  String get practiceEditPaste;

  /// No description provided for @practiceEditPracticeLoaded.
  ///
  /// In zh, this message translates to:
  /// **'字帖\"{title}\"加载成功'**
  String practiceEditPracticeLoaded(Object title);

  /// No description provided for @practiceEditPracticeLoadFailed.
  ///
  /// In zh, this message translates to:
  /// **'加载字帖失败：字帖不存在或已被删除'**
  String get practiceEditPracticeLoadFailed;

  /// No description provided for @practiceEditPracticeTitle.
  ///
  /// In zh, this message translates to:
  /// **'字帖标题'**
  String get practiceEditPracticeTitle;

  /// No description provided for @practiceEditPropertyPanel.
  ///
  /// In zh, this message translates to:
  /// **'属性'**
  String get practiceEditPropertyPanel;

  /// No description provided for @practiceEditSaveAndExit.
  ///
  /// In zh, this message translates to:
  /// **'保存并退出'**
  String get practiceEditSaveAndExit;

  /// No description provided for @practiceEditSaveAndLeave.
  ///
  /// In zh, this message translates to:
  /// **'保存并离开'**
  String get practiceEditSaveAndLeave;

  /// No description provided for @practiceEditSaveFailed.
  ///
  /// In zh, this message translates to:
  /// **'保存失败'**
  String get practiceEditSaveFailed;

  /// No description provided for @practiceEditSavePractice.
  ///
  /// In zh, this message translates to:
  /// **'保存字帖'**
  String get practiceEditSavePractice;

  /// No description provided for @practiceEditSaveSuccess.
  ///
  /// In zh, this message translates to:
  /// **'保存成功'**
  String get practiceEditSaveSuccess;

  /// No description provided for @practiceEditSelect.
  ///
  /// In zh, this message translates to:
  /// **'选择'**
  String get practiceEditSelect;

  /// No description provided for @practiceEditSendToBack.
  ///
  /// In zh, this message translates to:
  /// **'置于底层 (Ctrl+B)'**
  String get practiceEditSendToBack;

  /// No description provided for @practiceEditShowGrid.
  ///
  /// In zh, this message translates to:
  /// **'显示网格 (Ctrl+G)'**
  String get practiceEditShowGrid;

  /// No description provided for @practiceEditText.
  ///
  /// In zh, this message translates to:
  /// **'文本'**
  String get practiceEditText;

  /// No description provided for @practiceEditTextProperties.
  ///
  /// In zh, this message translates to:
  /// **'文本属性'**
  String get practiceEditTextProperties;

  /// No description provided for @practiceEditTitle.
  ///
  /// In zh, this message translates to:
  /// **'字帖编辑'**
  String get practiceEditTitle;

  /// No description provided for @practiceEditTitleExists.
  ///
  /// In zh, this message translates to:
  /// **'标题已存在'**
  String get practiceEditTitleExists;

  /// No description provided for @practiceEditTitleExistsMessage.
  ///
  /// In zh, this message translates to:
  /// **'已存在同名字帖。是否覆盖？'**
  String get practiceEditTitleExistsMessage;

  /// No description provided for @practiceEditTitleUpdated.
  ///
  /// In zh, this message translates to:
  /// **'标题已更新为\"{title}\"'**
  String practiceEditTitleUpdated(Object title);

  /// No description provided for @practiceEditToolbar.
  ///
  /// In zh, this message translates to:
  /// **'编辑工具栏'**
  String get practiceEditToolbar;

  /// No description provided for @practiceEditTopNavBack.
  ///
  /// In zh, this message translates to:
  /// **'返回'**
  String get practiceEditTopNavBack;

  /// No description provided for @practiceEditTopNavExitPreview.
  ///
  /// In zh, this message translates to:
  /// **'退出预览模式'**
  String get practiceEditTopNavExitPreview;

  /// No description provided for @practiceEditTopNavExport.
  ///
  /// In zh, this message translates to:
  /// **'导出'**
  String get practiceEditTopNavExport;

  /// No description provided for @practiceEditTopNavHideThumbnails.
  ///
  /// In zh, this message translates to:
  /// **'隐藏页面缩略图'**
  String get practiceEditTopNavHideThumbnails;

  /// No description provided for @practiceEditTopNavPreviewMode.
  ///
  /// In zh, this message translates to:
  /// **'预览模式'**
  String get practiceEditTopNavPreviewMode;

  /// No description provided for @practiceEditTopNavRedo.
  ///
  /// In zh, this message translates to:
  /// **'重做'**
  String get practiceEditTopNavRedo;

  /// No description provided for @practiceEditTopNavSave.
  ///
  /// In zh, this message translates to:
  /// **'保存'**
  String get practiceEditTopNavSave;

  /// No description provided for @practiceEditTopNavSaveAs.
  ///
  /// In zh, this message translates to:
  /// **'另存为'**
  String get practiceEditTopNavSaveAs;

  /// No description provided for @practiceEditTopNavShowThumbnails.
  ///
  /// In zh, this message translates to:
  /// **'显示页面缩略图'**
  String get practiceEditTopNavShowThumbnails;

  /// No description provided for @practiceEditTopNavUndo.
  ///
  /// In zh, this message translates to:
  /// **'撤销'**
  String get practiceEditTopNavUndo;

  /// No description provided for @practiceEditUngroup.
  ///
  /// In zh, this message translates to:
  /// **'取消组合 (Ctrl+U)'**
  String get practiceEditUngroup;

  /// No description provided for @practiceEditUnsavedChanges.
  ///
  /// In zh, this message translates to:
  /// **'未保存的更改'**
  String get practiceEditUnsavedChanges;

  /// No description provided for @practiceEditUnsavedChangesExitConfirmation.
  ///
  /// In zh, this message translates to:
  /// **'您有未保存的更改。确定要退出吗？'**
  String get practiceEditUnsavedChangesExitConfirmation;

  /// No description provided for @practiceEditUnsavedChangesMessage.
  ///
  /// In zh, this message translates to:
  /// **'您有未保存的更改。确定要离开吗？'**
  String get practiceEditUnsavedChangesMessage;

  /// No description provided for @practiceEditVisualProperties.
  ///
  /// In zh, this message translates to:
  /// **'视觉属性'**
  String get practiceEditVisualProperties;

  /// No description provided for @practiceEditCut.
  ///
  /// In zh, this message translates to:
  /// **'剪切 (Ctrl+X)'**
  String get practiceEditCut;

  /// No description provided for @practiceEditAlignLeft.
  ///
  /// In zh, this message translates to:
  /// **'左对齐 (Ctrl+Shift+L)'**
  String get practiceEditAlignLeft;

  /// No description provided for @practiceEditAlignCenter.
  ///
  /// In zh, this message translates to:
  /// **'居中对齐 (Ctrl+Shift+C)'**
  String get practiceEditAlignCenter;

  /// No description provided for @practiceEditAlignRight.
  ///
  /// In zh, this message translates to:
  /// **'右对齐 (Ctrl+Shift+R)'**
  String get practiceEditAlignRight;

  /// No description provided for @practiceEditAlignTop.
  ///
  /// In zh, this message translates to:
  /// **'顶部对齐 (Ctrl+Shift+T)'**
  String get practiceEditAlignTop;

  /// No description provided for @practiceEditAlignBottom.
  ///
  /// In zh, this message translates to:
  /// **'底部对齐 (Ctrl+Shift+B)'**
  String get practiceEditAlignBottom;

  /// No description provided for @practiceEditAlignMiddle.
  ///
  /// In zh, this message translates to:
  /// **'垂直居中'**
  String get practiceEditAlignMiddle;

  /// No description provided for @practiceEditDistributeHorizontal.
  ///
  /// In zh, this message translates to:
  /// **'水平分布'**
  String get practiceEditDistributeHorizontal;

  /// No description provided for @practiceEditDistributeVertical.
  ///
  /// In zh, this message translates to:
  /// **'垂直分布'**
  String get practiceEditDistributeVertical;

  /// No description provided for @practiceEditAlignment.
  ///
  /// In zh, this message translates to:
  /// **'对齐'**
  String get practiceEditAlignment;

  /// No description provided for @practiceEditLock.
  ///
  /// In zh, this message translates to:
  /// **'锁定元素 (Ctrl+L)'**
  String get practiceEditLock;

  /// No description provided for @practiceEditUnlock.
  ///
  /// In zh, this message translates to:
  /// **'解锁元素 (Ctrl+Shift+L)'**
  String get practiceEditUnlock;

  /// No description provided for @practiceEditHideElement.
  ///
  /// In zh, this message translates to:
  /// **'隐藏元素 (Ctrl+H)'**
  String get practiceEditHideElement;

  /// No description provided for @practiceEditShowElement.
  ///
  /// In zh, this message translates to:
  /// **'显示元素 (Ctrl+Shift+H)'**
  String get practiceEditShowElement;

  /// No description provided for @practiceEditElementState.
  ///
  /// In zh, this message translates to:
  /// **'元素状态'**
  String get practiceEditElementState;

  /// No description provided for @practiceEditFlipHorizontal.
  ///
  /// In zh, this message translates to:
  /// **'水平翻转'**
  String get practiceEditFlipHorizontal;

  /// No description provided for @practiceEditFlipVertical.
  ///
  /// In zh, this message translates to:
  /// **'垂直翻转'**
  String get practiceEditFlipVertical;

  /// No description provided for @practiceEditDuplicate.
  ///
  /// In zh, this message translates to:
  /// **'重复 (Ctrl+Shift+D)'**
  String get practiceEditDuplicate;

  /// No description provided for @practiceEditClone.
  ///
  /// In zh, this message translates to:
  /// **'克隆'**
  String get practiceEditClone;

  /// No description provided for @practiceEditTransform.
  ///
  /// In zh, this message translates to:
  /// **'变换'**
  String get practiceEditTransform;

  /// No description provided for @practiceEditZoomIn.
  ///
  /// In zh, this message translates to:
  /// **'放大 (Ctrl+=)'**
  String get practiceEditZoomIn;

  /// No description provided for @practiceEditZoomOut.
  ///
  /// In zh, this message translates to:
  /// **'缩小 (Ctrl+-)'**
  String get practiceEditZoomOut;

  /// No description provided for @practiceEditZoomFit.
  ///
  /// In zh, this message translates to:
  /// **'适应画布 (Ctrl+0)'**
  String get practiceEditZoomFit;

  /// No description provided for @practiceEditZoomActual.
  ///
  /// In zh, this message translates to:
  /// **'实际大小 (Ctrl+1)'**
  String get practiceEditZoomActual;

  /// No description provided for @practiceEditZoomControls.
  ///
  /// In zh, this message translates to:
  /// **'缩放控制'**
  String get practiceEditZoomControls;

  /// No description provided for @practiceEditFindReplace.
  ///
  /// In zh, this message translates to:
  /// **'查找替换 (Ctrl+F)'**
  String get practiceEditFindReplace;

  /// No description provided for @practiceEditFind.
  ///
  /// In zh, this message translates to:
  /// **'查找'**
  String get practiceEditFind;

  /// No description provided for @practiceEditToggleLayerPanel.
  ///
  /// In zh, this message translates to:
  /// **'切换图层面板 (F9)'**
  String get practiceEditToggleLayerPanel;

  /// No description provided for @practiceEditTogglePropertyPanel.
  ///
  /// In zh, this message translates to:
  /// **'切换属性面板 (F4)'**
  String get practiceEditTogglePropertyPanel;

  /// No description provided for @practiceEditPanels.
  ///
  /// In zh, this message translates to:
  /// **'面板'**
  String get practiceEditPanels;

  /// No description provided for @practiceListBatchDone.
  ///
  /// In zh, this message translates to:
  /// **'完成'**
  String get practiceListBatchDone;

  /// No description provided for @practiceListBatchMode.
  ///
  /// In zh, this message translates to:
  /// **'批量模式'**
  String get practiceListBatchMode;

  /// No description provided for @practiceListCollapseFilter.
  ///
  /// In zh, this message translates to:
  /// **'折叠过滤面板'**
  String get practiceListCollapseFilter;

  /// No description provided for @practiceListDeleteConfirm.
  ///
  /// In zh, this message translates to:
  /// **'确认删除'**
  String get practiceListDeleteConfirm;

  /// No description provided for @practiceListDeleteMessage.
  ///
  /// In zh, this message translates to:
  /// **'确定要删除选中的字帖吗？此操作无法撤消。'**
  String get practiceListDeleteMessage;

  /// No description provided for @practiceListDeleteSelected.
  ///
  /// In zh, this message translates to:
  /// **'删除所选'**
  String get practiceListDeleteSelected;

  /// No description provided for @practiceListError.
  ///
  /// In zh, this message translates to:
  /// **'加载字帖错误'**
  String get practiceListError;

  /// No description provided for @practiceListExpandFilter.
  ///
  /// In zh, this message translates to:
  /// **'展开过滤面板'**
  String get practiceListExpandFilter;

  /// No description provided for @practiceListFilterFavorites.
  ///
  /// In zh, this message translates to:
  /// **'收藏'**
  String get practiceListFilterFavorites;

  /// No description provided for @practiceListFilterTitle.
  ///
  /// In zh, this message translates to:
  /// **'字帖过滤'**
  String get practiceListFilterTitle;

  /// No description provided for @practiceListGridView.
  ///
  /// In zh, this message translates to:
  /// **'网格视图'**
  String get practiceListGridView;

  /// No description provided for @practiceListItemsPerPage.
  ///
  /// In zh, this message translates to:
  /// **'每页{count}个'**
  String practiceListItemsPerPage(Object count);

  /// No description provided for @practiceListListView.
  ///
  /// In zh, this message translates to:
  /// **'列表视图'**
  String get practiceListListView;

  /// No description provided for @practiceListLoading.
  ///
  /// In zh, this message translates to:
  /// **'加载字帖中...'**
  String get practiceListLoading;

  /// No description provided for @practiceListNewPractice.
  ///
  /// In zh, this message translates to:
  /// **'新建字帖'**
  String get practiceListNewPractice;

  /// No description provided for @practiceListNoResults.
  ///
  /// In zh, this message translates to:
  /// **'未找到字帖'**
  String get practiceListNoResults;

  /// No description provided for @practiceListPages.
  ///
  /// In zh, this message translates to:
  /// **'页'**
  String get practiceListPages;

  /// No description provided for @practiceListResetFilter.
  ///
  /// In zh, this message translates to:
  /// **'重置过滤器'**
  String get practiceListResetFilter;

  /// No description provided for @practiceListSearch.
  ///
  /// In zh, this message translates to:
  /// **'搜索字帖...'**
  String get practiceListSearch;

  /// No description provided for @practiceListSortByCreateTime.
  ///
  /// In zh, this message translates to:
  /// **'按创建时间排序'**
  String get practiceListSortByCreateTime;

  /// No description provided for @practiceListSortByStatus.
  ///
  /// In zh, this message translates to:
  /// **'按状态排序'**
  String get practiceListSortByStatus;

  /// No description provided for @practiceListSortByTitle.
  ///
  /// In zh, this message translates to:
  /// **'按标题排序'**
  String get practiceListSortByTitle;

  /// No description provided for @practiceListSortByUpdateTime.
  ///
  /// In zh, this message translates to:
  /// **'按更新时间排序'**
  String get practiceListSortByUpdateTime;

  /// No description provided for @practiceListStatus.
  ///
  /// In zh, this message translates to:
  /// **'状态'**
  String get practiceListStatus;

  /// No description provided for @practiceListStatusAll.
  ///
  /// In zh, this message translates to:
  /// **'全部'**
  String get practiceListStatusAll;

  /// No description provided for @practiceListStatusCompleted.
  ///
  /// In zh, this message translates to:
  /// **'已完成'**
  String get practiceListStatusCompleted;

  /// No description provided for @practiceListStatusDraft.
  ///
  /// In zh, this message translates to:
  /// **'草稿'**
  String get practiceListStatusDraft;

  /// No description provided for @practiceListThumbnailError.
  ///
  /// In zh, this message translates to:
  /// **'缩略图加载失败'**
  String get practiceListThumbnailError;

  /// No description provided for @practiceListTitle.
  ///
  /// In zh, this message translates to:
  /// **'字帖'**
  String get practiceListTitle;

  /// No description provided for @practiceListTotalItems.
  ///
  /// In zh, this message translates to:
  /// **'{count}张字帖'**
  String practiceListTotalItems(Object count);

  /// No description provided for @practicePageSettings.
  ///
  /// In zh, this message translates to:
  /// **'页面设置'**
  String get practicePageSettings;

  /// No description provided for @practices.
  ///
  /// In zh, this message translates to:
  /// **'字帖'**
  String get practices;

  /// No description provided for @presetSize.
  ///
  /// In zh, this message translates to:
  /// **'预设大小'**
  String get presetSize;

  /// No description provided for @preview.
  ///
  /// In zh, this message translates to:
  /// **'预览'**
  String get preview;

  /// No description provided for @previewText.
  ///
  /// In zh, this message translates to:
  /// **'预览'**
  String get previewText;

  /// No description provided for @previousImage.
  ///
  /// In zh, this message translates to:
  /// **'上一张图片'**
  String get previousImage;

  /// No description provided for @print.
  ///
  /// In zh, this message translates to:
  /// **'打印'**
  String get print;

  /// No description provided for @removedFromAllCategories.
  ///
  /// In zh, this message translates to:
  /// **'已从所有分类中移除'**
  String get removedFromAllCategories;

  /// No description provided for @rename.
  ///
  /// In zh, this message translates to:
  /// **'重命名'**
  String get rename;

  /// No description provided for @resetSettingsConfirmMessage.
  ///
  /// In zh, this message translates to:
  /// **'确定要将所有缓存设置重置为默认值吗？'**
  String get resetSettingsConfirmMessage;

  /// No description provided for @resetSettingsConfirmTitle.
  ///
  /// In zh, this message translates to:
  /// **'重置设置'**
  String get resetSettingsConfirmTitle;

  /// No description provided for @resetToDefaults.
  ///
  /// In zh, this message translates to:
  /// **'重置为默认值'**
  String get resetToDefaults;

  /// No description provided for @restartAfterRestored.
  ///
  /// In zh, this message translates to:
  /// **'注意：恢复完成后应用将自动重启'**
  String get restartAfterRestored;

  /// No description provided for @restartAppRequired.
  ///
  /// In zh, this message translates to:
  /// **'需要重启应用以完成恢复过程。'**
  String get restartAppRequired;

  /// No description provided for @restartLater.
  ///
  /// In zh, this message translates to:
  /// **'稍后'**
  String get restartLater;

  /// No description provided for @restartNow.
  ///
  /// In zh, this message translates to:
  /// **'立即重启'**
  String get restartNow;

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

  /// No description provided for @restoreSuccess.
  ///
  /// In zh, this message translates to:
  /// **'恢复成功'**
  String get restoreSuccess;

  /// No description provided for @restoringBackup.
  ///
  /// In zh, this message translates to:
  /// **'正在从备份恢复...'**
  String get restoringBackup;

  /// No description provided for @rotation.
  ///
  /// In zh, this message translates to:
  /// **'旋转'**
  String get rotation;

  /// No description provided for @save.
  ///
  /// In zh, this message translates to:
  /// **'保存'**
  String get save;

  /// No description provided for @searchCategories.
  ///
  /// In zh, this message translates to:
  /// **'搜索分类...'**
  String get searchCategories;

  /// No description provided for @searchCharactersWorksAuthors.
  ///
  /// In zh, this message translates to:
  /// **'搜索字符、作品或作者'**
  String get searchCharactersWorksAuthors;

  /// No description provided for @selectBackup.
  ///
  /// In zh, this message translates to:
  /// **'选择备份'**
  String get selectBackup;

  /// No description provided for @selectCollection.
  ///
  /// In zh, this message translates to:
  /// **'选择采集'**
  String get selectCollection;

  /// No description provided for @selectDeleteOption.
  ///
  /// In zh, this message translates to:
  /// **'选择删除选项：'**
  String get selectDeleteOption;

  /// No description provided for @selected.
  ///
  /// In zh, this message translates to:
  /// **'已选择'**
  String get selected;

  /// No description provided for @selectedCount.
  ///
  /// In zh, this message translates to:
  /// **'已选择{count}个'**
  String selectedCount(Object count);

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

  /// No description provided for @selectTargetLayer.
  ///
  /// In zh, this message translates to:
  /// **'选择目标图层'**
  String get selectTargetLayer;

  /// No description provided for @sendLayerToBack.
  ///
  /// In zh, this message translates to:
  /// **'图层置于底层'**
  String get sendLayerToBack;

  /// No description provided for @sendToBack.
  ///
  /// In zh, this message translates to:
  /// **'置于底层'**
  String get sendToBack;

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

  /// No description provided for @showElement.
  ///
  /// In zh, this message translates to:
  /// **'显示元素'**
  String get showElement;

  /// No description provided for @showGrid.
  ///
  /// In zh, this message translates to:
  /// **'显示网格'**
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

  /// No description provided for @sortAndFilter.
  ///
  /// In zh, this message translates to:
  /// **'排序和筛选'**
  String get sortAndFilter;

  /// No description provided for @stateAndDisplay.
  ///
  /// In zh, this message translates to:
  /// **'状态与显示'**
  String get stateAndDisplay;

  /// No description provided for @storageCharacters.
  ///
  /// In zh, this message translates to:
  /// **'集字'**
  String get storageCharacters;

  /// No description provided for @storageDetails.
  ///
  /// In zh, this message translates to:
  /// **'存储详情'**
  String get storageDetails;

  /// No description provided for @storageGallery.
  ///
  /// In zh, this message translates to:
  /// **'图库'**
  String get storageGallery;

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

  /// No description provided for @storageWorks.
  ///
  /// In zh, this message translates to:
  /// **'作品'**
  String get storageWorks;

  /// No description provided for @tagEditorEnterTagHint.
  ///
  /// In zh, this message translates to:
  /// **'输入标签并按Enter'**
  String get tagEditorEnterTagHint;

  /// No description provided for @tagEditorNoTags.
  ///
  /// In zh, this message translates to:
  /// **'无标签'**
  String get tagEditorNoTags;

  /// No description provided for @tagEditorSuggestedTags.
  ///
  /// In zh, this message translates to:
  /// **'建议标签：'**
  String get tagEditorSuggestedTags;

  /// No description provided for @tagsHint.
  ///
  /// In zh, this message translates to:
  /// **'输入标签...'**
  String get tagsHint;

  /// No description provided for @text.
  ///
  /// In zh, this message translates to:
  /// **'文本'**
  String get text;

  /// No description provided for @textElement.
  ///
  /// In zh, this message translates to:
  /// **'文本元素'**
  String get textElement;

  /// No description provided for @textPropertyPanel.
  ///
  /// In zh, this message translates to:
  /// **'文本属性'**
  String get textPropertyPanel;

  /// No description provided for @textPropertyPanelBgColor.
  ///
  /// In zh, this message translates to:
  /// **'背景颜色'**
  String get textPropertyPanelBgColor;

  /// No description provided for @textPropertyPanelDimensions.
  ///
  /// In zh, this message translates to:
  /// **'尺寸'**
  String get textPropertyPanelDimensions;

  /// No description provided for @textPropertyPanelFontColor.
  ///
  /// In zh, this message translates to:
  /// **'文本颜色'**
  String get textPropertyPanelFontColor;

  /// No description provided for @textPropertyPanelFontFamily.
  ///
  /// In zh, this message translates to:
  /// **'字体'**
  String get textPropertyPanelFontFamily;

  /// No description provided for @textPropertyPanelFontSize.
  ///
  /// In zh, this message translates to:
  /// **'字体大小'**
  String get textPropertyPanelFontSize;

  /// No description provided for @textPropertyPanelFontStyle.
  ///
  /// In zh, this message translates to:
  /// **'字体样式'**
  String get textPropertyPanelFontStyle;

  /// No description provided for @textPropertyPanelFontWeight.
  ///
  /// In zh, this message translates to:
  /// **'字体粗细'**
  String get textPropertyPanelFontWeight;

  /// No description provided for @textPropertyPanelGeometry.
  ///
  /// In zh, this message translates to:
  /// **'几何属性'**
  String get textPropertyPanelGeometry;

  /// No description provided for @textPropertyPanelHorizontal.
  ///
  /// In zh, this message translates to:
  /// **'水平'**
  String get textPropertyPanelHorizontal;

  /// No description provided for @textPropertyPanelLetterSpacing.
  ///
  /// In zh, this message translates to:
  /// **'字符间距'**
  String get textPropertyPanelLetterSpacing;

  /// No description provided for @textPropertyPanelLineHeight.
  ///
  /// In zh, this message translates to:
  /// **'行高'**
  String get textPropertyPanelLineHeight;

  /// No description provided for @textPropertyPanelLineThrough.
  ///
  /// In zh, this message translates to:
  /// **'删除线'**
  String get textPropertyPanelLineThrough;

  /// No description provided for @textPropertyPanelOpacity.
  ///
  /// In zh, this message translates to:
  /// **'不透明度'**
  String get textPropertyPanelOpacity;

  /// No description provided for @textPropertyPanelPadding.
  ///
  /// In zh, this message translates to:
  /// **'内边距'**
  String get textPropertyPanelPadding;

  /// No description provided for @textPropertyPanelPosition.
  ///
  /// In zh, this message translates to:
  /// **'位置'**
  String get textPropertyPanelPosition;

  /// No description provided for @textPropertyPanelPreview.
  ///
  /// In zh, this message translates to:
  /// **'预览'**
  String get textPropertyPanelPreview;

  /// No description provided for @textPropertyPanelTextAlign.
  ///
  /// In zh, this message translates to:
  /// **'文本对齐'**
  String get textPropertyPanelTextAlign;

  /// No description provided for @textPropertyPanelTextContent.
  ///
  /// In zh, this message translates to:
  /// **'文本内容'**
  String get textPropertyPanelTextContent;

  /// No description provided for @textPropertyPanelTextSettings.
  ///
  /// In zh, this message translates to:
  /// **'文本设置'**
  String get textPropertyPanelTextSettings;

  /// No description provided for @textPropertyPanelUnderline.
  ///
  /// In zh, this message translates to:
  /// **'下划线'**
  String get textPropertyPanelUnderline;

  /// No description provided for @textPropertyPanelVertical.
  ///
  /// In zh, this message translates to:
  /// **'垂直'**
  String get textPropertyPanelVertical;

  /// No description provided for @textPropertyPanelVerticalAlign.
  ///
  /// In zh, this message translates to:
  /// **'垂直对齐'**
  String get textPropertyPanelVerticalAlign;

  /// No description provided for @textPropertyPanelVisual.
  ///
  /// In zh, this message translates to:
  /// **'视觉设置'**
  String get textPropertyPanelVisual;

  /// No description provided for @textPropertyPanelWritingMode.
  ///
  /// In zh, this message translates to:
  /// **'书写模式'**
  String get textPropertyPanelWritingMode;

  /// No description provided for @textureApplicationRange.
  ///
  /// In zh, this message translates to:
  /// **'纹理应用范围'**
  String get textureApplicationRange;

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

  /// No description provided for @textureFillModeNoRepeat.
  ///
  /// In zh, this message translates to:
  /// **'不重复'**
  String get textureFillModeNoRepeat;

  /// No description provided for @textureFillModeRepeat.
  ///
  /// In zh, this message translates to:
  /// **'重复'**
  String get textureFillModeRepeat;

  /// No description provided for @textureFillModeRepeatX.
  ///
  /// In zh, this message translates to:
  /// **'水平重复'**
  String get textureFillModeRepeatX;

  /// No description provided for @textureFillModeRepeatY.
  ///
  /// In zh, this message translates to:
  /// **'垂直重复'**
  String get textureFillModeRepeatY;

  /// No description provided for @textureOpacity.
  ///
  /// In zh, this message translates to:
  /// **'纹理不透明度'**
  String get textureOpacity;

  /// No description provided for @textureRangeBackground.
  ///
  /// In zh, this message translates to:
  /// **'整个背景'**
  String get textureRangeBackground;

  /// No description provided for @textureRangeCharacter.
  ///
  /// In zh, this message translates to:
  /// **'仅字符'**
  String get textureRangeCharacter;

  /// No description provided for @textureRemove.
  ///
  /// In zh, this message translates to:
  /// **'移除'**
  String get textureRemove;

  /// No description provided for @textureSelectFromLibrary.
  ///
  /// In zh, this message translates to:
  /// **'从库中选择'**
  String get textureSelectFromLibrary;

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

  /// No description provided for @themeModeLight.
  ///
  /// In zh, this message translates to:
  /// **'亮色'**
  String get themeModeLight;

  /// No description provided for @themeModeSystem.
  ///
  /// In zh, this message translates to:
  /// **'系统'**
  String get themeModeSystem;

  /// No description provided for @themeModeSystemDescription.
  ///
  /// In zh, this message translates to:
  /// **'根据系统设置自动切换深色/亮色主题'**
  String get themeModeSystemDescription;

  /// No description provided for @toggleTestText.
  ///
  /// In zh, this message translates to:
  /// **'切换测试文本'**
  String get toggleTestText;

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

  /// No description provided for @ungroup.
  ///
  /// In zh, this message translates to:
  /// **'取消组合'**
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

  /// No description provided for @unknownCategory.
  ///
  /// In zh, this message translates to:
  /// **'未知分类'**
  String get unknownCategory;

  /// No description provided for @unlocked.
  ///
  /// In zh, this message translates to:
  /// **'未锁定'**
  String get unlocked;

  /// No description provided for @unlockElement.
  ///
  /// In zh, this message translates to:
  /// **'解锁元素'**
  String get unlockElement;

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

  /// No description provided for @verticalTextModeEnabled.
  ///
  /// In zh, this message translates to:
  /// **'竖排文本预览 - 超出高度自动换列，可横向滚动'**
  String get verticalTextModeEnabled;

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

  /// No description provided for @visualSettings.
  ///
  /// In zh, this message translates to:
  /// **'视觉设置'**
  String get visualSettings;

  /// No description provided for @width.
  ///
  /// In zh, this message translates to:
  /// **'宽度'**
  String get width;

  /// No description provided for @windowButtonClose.
  ///
  /// In zh, this message translates to:
  /// **'关闭'**
  String get windowButtonClose;

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

  /// No description provided for @workBrowseAddFavorite.
  ///
  /// In zh, this message translates to:
  /// **'添加到收藏'**
  String get workBrowseAddFavorite;

  /// No description provided for @workBrowseBatchDone.
  ///
  /// In zh, this message translates to:
  /// **'完成'**
  String get workBrowseBatchDone;

  /// No description provided for @workBrowseBatchMode.
  ///
  /// In zh, this message translates to:
  /// **'批量模式'**
  String get workBrowseBatchMode;

  /// No description provided for @workBrowseCancel.
  ///
  /// In zh, this message translates to:
  /// **'取消'**
  String get workBrowseCancel;

  /// No description provided for @workBrowseDelete.
  ///
  /// In zh, this message translates to:
  /// **'删除'**
  String get workBrowseDelete;

  /// No description provided for @workBrowseDeleteConfirmMessage.
  ///
  /// In zh, this message translates to:
  /// **'确定要删除已选的{count}个作品吗？此操作无法撤消。'**
  String workBrowseDeleteConfirmMessage(Object count);

  /// No description provided for @workBrowseDeleteConfirmTitle.
  ///
  /// In zh, this message translates to:
  /// **'确认删除'**
  String get workBrowseDeleteConfirmTitle;

  /// No description provided for @workBrowseDeleteSelected.
  ///
  /// In zh, this message translates to:
  /// **'删除{count}个'**
  String workBrowseDeleteSelected(Object count);

  /// No description provided for @workBrowseError.
  ///
  /// In zh, this message translates to:
  /// **'错误：{message}'**
  String workBrowseError(Object message);

  /// No description provided for @workBrowseGridView.
  ///
  /// In zh, this message translates to:
  /// **'网格视图'**
  String get workBrowseGridView;

  /// No description provided for @workBrowseImport.
  ///
  /// In zh, this message translates to:
  /// **'导入作品'**
  String get workBrowseImport;

  /// No description provided for @workBrowseItemsPerPage.
  ///
  /// In zh, this message translates to:
  /// **'{count}项/页'**
  String workBrowseItemsPerPage(Object count);

  /// No description provided for @workBrowseListView.
  ///
  /// In zh, this message translates to:
  /// **'列表视图'**
  String get workBrowseListView;

  /// No description provided for @workBrowseLoading.
  ///
  /// In zh, this message translates to:
  /// **'加载作品中...'**
  String get workBrowseLoading;

  /// No description provided for @workBrowseNoWorks.
  ///
  /// In zh, this message translates to:
  /// **'未找到作品'**
  String get workBrowseNoWorks;

  /// No description provided for @workBrowseNoWorksHint.
  ///
  /// In zh, this message translates to:
  /// **'尝试导入新作品或更改筛选条件'**
  String get workBrowseNoWorksHint;

  /// No description provided for @workBrowseReload.
  ///
  /// In zh, this message translates to:
  /// **'重新加载'**
  String get workBrowseReload;

  /// No description provided for @workBrowseRemoveFavorite.
  ///
  /// In zh, this message translates to:
  /// **'从收藏中移除'**
  String get workBrowseRemoveFavorite;

  /// No description provided for @workBrowseSearch.
  ///
  /// In zh, this message translates to:
  /// **'搜索作品...'**
  String get workBrowseSearch;

  /// No description provided for @workBrowseSelectedCount.
  ///
  /// In zh, this message translates to:
  /// **'已选{count}个'**
  String workBrowseSelectedCount(Object count);

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

  /// No description provided for @workDetailBack.
  ///
  /// In zh, this message translates to:
  /// **'返回'**
  String get workDetailBack;

  /// No description provided for @workDetailBasicInfo.
  ///
  /// In zh, this message translates to:
  /// **'基本信息'**
  String get workDetailBasicInfo;

  /// No description provided for @workDetailCancel.
  ///
  /// In zh, this message translates to:
  /// **'取消'**
  String get workDetailCancel;

  /// No description provided for @workDetailCharacters.
  ///
  /// In zh, this message translates to:
  /// **'字符'**
  String get workDetailCharacters;

  /// No description provided for @workDetailCreateTime.
  ///
  /// In zh, this message translates to:
  /// **'创建时间'**
  String get workDetailCreateTime;

  /// No description provided for @workDetailEdit.
  ///
  /// In zh, this message translates to:
  /// **'编辑'**
  String get workDetailEdit;

  /// No description provided for @workDetailExtract.
  ///
  /// In zh, this message translates to:
  /// **'提取字符'**
  String get workDetailExtract;

  /// No description provided for @workDetailExtractionError.
  ///
  /// In zh, this message translates to:
  /// **'无法打开字符提取'**
  String get workDetailExtractionError;

  /// No description provided for @workDetailImageCount.
  ///
  /// In zh, this message translates to:
  /// **'图像数量'**
  String get workDetailImageCount;

  /// No description provided for @workDetailImageLoadError.
  ///
  /// In zh, this message translates to:
  /// **'选中的图像无法加载，请尝试重新导入图像'**
  String get workDetailImageLoadError;

  /// No description provided for @workDetailLoading.
  ///
  /// In zh, this message translates to:
  /// **'加载作品详情中...'**
  String get workDetailLoading;

  /// No description provided for @workDetailNoCharacters.
  ///
  /// In zh, this message translates to:
  /// **'暂无字符'**
  String get workDetailNoCharacters;

  /// No description provided for @workDetailNoImages.
  ///
  /// In zh, this message translates to:
  /// **'没有可显示的图像'**
  String get workDetailNoImages;

  /// No description provided for @workDetailNoImagesForExtraction.
  ///
  /// In zh, this message translates to:
  /// **'无法提取字符：作品没有图像'**
  String get workDetailNoImagesForExtraction;

  /// No description provided for @workDetailNoWork.
  ///
  /// In zh, this message translates to:
  /// **'作品不存在或已被删除'**
  String get workDetailNoWork;

  /// No description provided for @workDetailOtherInfo.
  ///
  /// In zh, this message translates to:
  /// **'其他信息'**
  String get workDetailOtherInfo;

  /// No description provided for @workDetailSave.
  ///
  /// In zh, this message translates to:
  /// **'保存'**
  String get workDetailSave;

  /// No description provided for @workDetailSaveFailure.
  ///
  /// In zh, this message translates to:
  /// **'保存失败'**
  String get workDetailSaveFailure;

  /// No description provided for @workDetailSaveSuccess.
  ///
  /// In zh, this message translates to:
  /// **'保存成功'**
  String get workDetailSaveSuccess;

  /// No description provided for @workDetailTags.
  ///
  /// In zh, this message translates to:
  /// **'标签'**
  String get workDetailTags;

  /// No description provided for @workDetailTitle.
  ///
  /// In zh, this message translates to:
  /// **'作品详情'**
  String get workDetailTitle;

  /// No description provided for @workDetailUnsavedChanges.
  ///
  /// In zh, this message translates to:
  /// **'您有未保存的更改。确定要放弃它们吗？'**
  String get workDetailUnsavedChanges;

  /// No description provided for @workDetailUpdateTime.
  ///
  /// In zh, this message translates to:
  /// **'更新时间'**
  String get workDetailUpdateTime;

  /// No description provided for @workDetailViewMore.
  ///
  /// In zh, this message translates to:
  /// **'查看更多'**
  String get workDetailViewMore;

  /// No description provided for @workFormAuthor.
  ///
  /// In zh, this message translates to:
  /// **'作者'**
  String get workFormAuthor;

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

  /// No description provided for @workFormCreationDate.
  ///
  /// In zh, this message translates to:
  /// **'创作日期'**
  String get workFormCreationDate;

  /// No description provided for @workFormDateHelp.
  ///
  /// In zh, this message translates to:
  /// **'作品的完成日期'**
  String get workFormDateHelp;

  /// No description provided for @workFormDateTooltip.
  ///
  /// In zh, this message translates to:
  /// **'按Tab导航到下一个字段'**
  String get workFormDateTooltip;

  /// No description provided for @workFormHelp.
  ///
  /// In zh, this message translates to:
  /// **'帮助'**
  String get workFormHelp;

  /// No description provided for @workFormNextField.
  ///
  /// In zh, this message translates to:
  /// **'下一个字段'**
  String get workFormNextField;

  /// No description provided for @workFormPreviousField.
  ///
  /// In zh, this message translates to:
  /// **'上一个字段'**
  String get workFormPreviousField;

  /// No description provided for @workFormRemark.
  ///
  /// In zh, this message translates to:
  /// **'备注'**
  String get workFormRemark;

  /// No description provided for @workFormRemarkHelp.
  ///
  /// In zh, this message translates to:
  /// **'可选，关于作品的附加信息'**
  String get workFormRemarkHelp;

  /// No description provided for @workFormRemarkHint.
  ///
  /// In zh, this message translates to:
  /// **'可选'**
  String get workFormRemarkHint;

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

  /// No description provided for @workFormRequiredField.
  ///
  /// In zh, this message translates to:
  /// **'必填字段'**
  String get workFormRequiredField;

  /// No description provided for @workFormSelectDate.
  ///
  /// In zh, this message translates to:
  /// **'选择日期'**
  String get workFormSelectDate;

  /// No description provided for @workFormShortcuts.
  ///
  /// In zh, this message translates to:
  /// **'键盘快捷键'**
  String get workFormShortcuts;

  /// No description provided for @workFormStyle.
  ///
  /// In zh, this message translates to:
  /// **'风格'**
  String get workFormStyle;

  /// No description provided for @workFormStyleHelp.
  ///
  /// In zh, this message translates to:
  /// **'作品的主要风格类型'**
  String get workFormStyleHelp;

  /// No description provided for @workFormStyleTooltip.
  ///
  /// In zh, this message translates to:
  /// **'按Tab导航到下一个字段'**
  String get workFormStyleTooltip;

  /// No description provided for @workFormTitle.
  ///
  /// In zh, this message translates to:
  /// **'标题'**
  String get workFormTitle;

  /// No description provided for @workFormTitleHelp.
  ///
  /// In zh, this message translates to:
  /// **'作品的主标题，显示在作品列表中'**
  String get workFormTitleHelp;

  /// No description provided for @workFormTitleHint.
  ///
  /// In zh, this message translates to:
  /// **'输入标题'**
  String get workFormTitleHint;

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

  /// No description provided for @workFormTool.
  ///
  /// In zh, this message translates to:
  /// **'工具'**
  String get workFormTool;

  /// No description provided for @workFormToolHelp.
  ///
  /// In zh, this message translates to:
  /// **'创作此作品使用的主要工具'**
  String get workFormToolHelp;

  /// No description provided for @workFormToolTooltip.
  ///
  /// In zh, this message translates to:
  /// **'按Tab导航到下一个字段'**
  String get workFormToolTooltip;

  /// No description provided for @workImportDialogAddImages.
  ///
  /// In zh, this message translates to:
  /// **'添加图像'**
  String get workImportDialogAddImages;

  /// No description provided for @workImportDialogCancel.
  ///
  /// In zh, this message translates to:
  /// **'取消'**
  String get workImportDialogCancel;

  /// No description provided for @workImportDialogDeleteImage.
  ///
  /// In zh, this message translates to:
  /// **'删除图像'**
  String get workImportDialogDeleteImage;

  /// No description provided for @workImportDialogDeleteImageConfirm.
  ///
  /// In zh, this message translates to:
  /// **'确定要删除此图像吗？'**
  String get workImportDialogDeleteImageConfirm;

  /// No description provided for @workImportDialogError.
  ///
  /// In zh, this message translates to:
  /// **'导入失败：{error}'**
  String workImportDialogError(Object error);

  /// No description provided for @workImportDialogFromGallery.
  ///
  /// In zh, this message translates to:
  /// **'从图库'**
  String get workImportDialogFromGallery;

  /// No description provided for @workImportDialogFromGalleryLong.
  ///
  /// In zh, this message translates to:
  /// **'从图库中选择图像'**
  String get workImportDialogFromGalleryLong;

  /// No description provided for @workImportDialogImport.
  ///
  /// In zh, this message translates to:
  /// **'导入'**
  String get workImportDialogImport;

  /// No description provided for @workImportDialogNoImages.
  ///
  /// In zh, this message translates to:
  /// **'未选择图像'**
  String get workImportDialogNoImages;

  /// No description provided for @workImportDialogNoImagesHint.
  ///
  /// In zh, this message translates to:
  /// **'点击添加图像'**
  String get workImportDialogNoImagesHint;

  /// No description provided for @workImportDialogProcessing.
  ///
  /// In zh, this message translates to:
  /// **'处理中...'**
  String get workImportDialogProcessing;

  /// No description provided for @workImportDialogSuccess.
  ///
  /// In zh, this message translates to:
  /// **'导入成功'**
  String get workImportDialogSuccess;

  /// No description provided for @workImportDialogTitle.
  ///
  /// In zh, this message translates to:
  /// **'导入作品'**
  String get workImportDialogTitle;

  /// No description provided for @works.
  ///
  /// In zh, this message translates to:
  /// **'作品'**
  String get works;

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

  /// No description provided for @workStyleOther.
  ///
  /// In zh, this message translates to:
  /// **'其他'**
  String get workStyleOther;

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

  /// No description provided for @yes.
  ///
  /// In zh, this message translates to:
  /// **'是'**
  String get yes;
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
