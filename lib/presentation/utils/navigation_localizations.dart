import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';

/// 导航相关的本地化工具类
class NavigationLocalizations {
  NavigationLocalizations._();

  /// 获取本地化的区域名称
  static String getSectionName(BuildContext context, int sectionIndex) {
    final l10n = AppLocalizations.of(context);
    switch (sectionIndex) {
      case 0:
        return l10n.navigationSectionWorkBrowse;
      case 1:
        return l10n.navigationSectionCharacterManagement;
      case 2:
        return l10n.navigationSectionPracticeList;
      case 3:
        return l10n.navigationSectionGalleryManagement;
      case 4:
        return l10n.navigationSectionSettings;
      default:
        return 'Unknown Section';
    }
  }

  /// 获取导航成功消息
  static String getNavigationSuccessMessage(
    BuildContext context,
    NavigationOperation operation,
  ) {
    final l10n = AppLocalizations.of(context);
    switch (operation) {
      case NavigationOperation.toSpecificItem:
        return l10n.navigationSuccessToSpecificItem;
      case NavigationOperation.back:
        return l10n.navigationSuccessBack;
      case NavigationOperation.toNewSection:
        return l10n.navigationSuccessToNewSection;
    }
  }

  /// 获取导航失败消息
  static String getNavigationFailedMessage(
    BuildContext context,
    NavigationOperation operation,
  ) {
    final l10n = AppLocalizations.of(context);
    switch (operation) {
      case NavigationOperation.toSpecificItem:
        return l10n.navigationFailedToSpecificItem;
      case NavigationOperation.back:
        return l10n.navigationFailedBack;
      case NavigationOperation.toNewSection:
        return l10n.navigationFailedSection;
    }
  }

  /// 获取清空历史记录失败消息
  static String getClearHistoryFailedMessage(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return l10n.navigationClearHistoryFailed;
  }
}

/// 导航操作类型
enum NavigationOperation {
  toSpecificItem,
  back,
  toNewSection,
}
