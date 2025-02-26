import 'package:flutter/material.dart';
import '../../theme/app_sizes.dart';

class WorkCardStyles {
  static const cardAspectRatio = 0.8;  // 卡片宽高比
  static const imageAspectRatio = 4/3;  // 图片宽高比
  static const thumbnailSize = Size(240, 180); // 缩略图尺寸
  
  static const gridCardConstraints = BoxConstraints(
    maxWidth: AppSizes.gridCardWidth,
    minHeight: AppSizes.gridCardImageHeight + AppSizes.gridCardInfoHeight,
  );
  
  static const listItemConstraints = BoxConstraints(
    minHeight: 120,
    maxHeight: 120,
  );
}
