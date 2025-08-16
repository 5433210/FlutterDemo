import 'package:flutter/material.dart';

import '../../../domain/models/character/character_region_state.dart';
import '../../providers/character/tool_mode_provider.dart';

/// 区域状态工具类
/// 提供获取区域状态和对应颜色的方法
class RegionStateUtils {
  /// 获取区域边框颜色
  /// 根据区域状态、保存状态、悬停状态和多选状态确定边框颜色
  static Color getBorderColor({
    required CharacterRegionState state,
    required bool isSaved,
    bool isHovered = false,
    bool isMultiSelected = false,
  }) {
    // 根据状态和保存状态确定颜色
    Color result;

    switch (state) {
      case CharacterRegionState.adjusting:
        result = const Color(CharacterRegionColorScheme.adjusting);
        break;
      case CharacterRegionState.selected:
        // 多选工具模式下，多選和單選使用相同顏色
        result = const Color(CharacterRegionColorScheme.selected);
        break;
      case CharacterRegionState.normal:
        result = isSaved
            ? const Color(CharacterRegionColorScheme.normalSaved)
            : const Color(CharacterRegionColorScheme.normalUnsaved);
        break;
    }

    return result;
  }

  /// 获取区域边框宽度
  /// 根据区域状态和多选状态确定边框宽度
  static double getBorderWidth({
    required CharacterRegionState state,
    bool isMultiSelected = false,
  }) {
    switch (state) {
      case CharacterRegionState.adjusting:
        return CharacterRegionColorScheme.adjustingBorderWidth;
      case CharacterRegionState.selected:
        // 多选工具模式下，多選和單選使用相同邊框寬度
        return CharacterRegionColorScheme.selectedBorderWidth;
      case CharacterRegionState.normal:
        return CharacterRegionColorScheme.normalBorderWidth;
    }
  }

  /// 获取区域填充颜色
  /// 根据区域状态、保存状态、悬停状态和多选状态确定填充颜色
  static Color getFillColor({
    required CharacterRegionState state,
    required bool isSaved,
    bool isHovered = false,
    bool isMultiSelected = false,
  }) {
    // 基础颜色
    final baseColor = getBorderColor(
      state: state,
      isSaved: isSaved,
      isHovered: isHovered,
      isMultiSelected: isMultiSelected,
    );

    // 透明度
    double opacity;
    switch (state) {
      case CharacterRegionState.adjusting:
        opacity = CharacterRegionColorScheme.adjustingOpacity;
        break;
      case CharacterRegionState.selected:
        // 多选工具模式下，多選和單選使用相同透明度
        opacity = CharacterRegionColorScheme.selectedOpacity;
        break;
      case CharacterRegionState.normal:
        opacity = isSaved
            ? CharacterRegionColorScheme.normalSavedOpacity
            : CharacterRegionColorScheme.normalUnsavedOpacity;
        break;
    }

    // 悬停状态增加透明度
    if (isHovered) {
      opacity = opacity * 1.2; // 减少倍数以避免过度饱和
    }

    return baseColor.withValues(alpha: opacity);
  }

  /// 获取区域的状态
  /// 根据当前工具模式和区域的选中、调整状态确定区域状态
  static CharacterRegionState getRegionState({
    required Tool currentTool,
    required bool isSelected,
    required bool isAdjusting,
  }) {
    // AppLogger.debug('获取区域状态', data: {
    //   'currentTool': currentTool.toString(),
    //   'isSelected': isSelected,
    //   'isAdjusting': isAdjusting,
    // });

    // 如果正在调整，返回调整状态
    if (isAdjusting) {
      // AppLogger.debug('区域状态: adjusting');
      return CharacterRegionState.adjusting;
    }

    // 如果被选中，統一使用selected状态（不再區分工具模式）
    if (isSelected) {
      // AppLogger.debug('区域状态: selected');
      return CharacterRegionState.selected;
    }

    // 其他情况返回正常状态
    // AppLogger.debug('区域状态: normal');
    return CharacterRegionState.normal;
  }
}
