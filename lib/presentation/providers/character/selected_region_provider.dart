import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/models/character/character_region.dart';
import '../../../domain/models/character/processing_options.dart';

final selectedRegionProvider =
    StateNotifierProvider<SelectedRegionNotifier, CharacterRegion?>((ref) {
  return SelectedRegionNotifier();
});

class SelectedRegionNotifier extends StateNotifier<CharacterRegion?> {
  SelectedRegionNotifier() : super(null);

  // 添加擦除点
  void addErasePoints(List<Offset> points) {
    if (state == null) return;

    final currentPoints = state!.erasePoints ?? [];
    final updatedPoints = [...currentPoints, ...points];

    state = state!.copyWith(erasePoints: updatedPoints);
  }

  // 清除所有擦除点
  void clearErasePoints() {
    if (state == null) return;
    state = state!.copyWith(erasePoints: null);
  }

  void clearRegion() {
    state = null;
  }

  CharacterRegion? getCurrentRegion() {
    return state;
  }

  // 根据ID获取区域
  bool isSelected(String id) {
    return state?.id == id;
  }

  void setRegion(CharacterRegion region) {
    state = region;
  }

  // 更新旋转角度
  void updateAngle(double angle) {
    if (state == null) return;
    state = state!.copyWith(rotation: angle);
  }

  // 更新字符
  void updateCharacter(String character) {
    if (state == null) return;
    state = state!.copyWith(character: character);
  }

  // 更新处理选项
  void updateOptions(ProcessingOptions options) {
    if (state == null) return;
    state = state!.copyWith(options: options);
  }

  // 更新区域尺寸和位置
  void updateRect(Rect rect) {
    if (state == null) return;
    state = state!.copyWith(rect: rect);
  }
}
