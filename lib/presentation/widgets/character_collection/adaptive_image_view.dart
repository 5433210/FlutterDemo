import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../infrastructure/logging/logger.dart';
import '../../../utils/platform/platform_detector.dart';
import 'desktop_image_view.dart';
import 'mobile_image_view.dart';

/// 智能图片预览组件选择器
/// 根据平台和设备特性自动选择最合适的实现
class AdaptiveImageView extends ConsumerWidget {
  const AdaptiveImageView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 根据平台检测结果选择合适的实现
    final shouldUseMobileUI = PlatformDetector.shouldUseMobileUI;
    
    // 正常使用平台检测结果
    final finalUseMobileUI = shouldUseMobileUI;
    
    AppLogger.debug('AdaptiveImageView组件选择', data: {
      'platform': PlatformDetector.platform.toString(),
      'isMobile': PlatformDetector.isMobile,
      'hasTouchSupport': PlatformDetector.hasTouchSupport,
      'shouldUseMobileUI': shouldUseMobileUI,
      'finalUseMobileUI': finalUseMobileUI,
      'selectedImplementation': finalUseMobileUI ? 'MobileImageView' : 'DesktopImageView',
    });

    if (finalUseMobileUI) {
      // 使用移动端优化的实现
      return const MobileImageView();
    } else {
      // 使用桌面端优化的实现  
      return const DesktopImageView();
    }
  }
}

/// Provider for accessing the current image view implementation type
final imageViewTypeProvider = Provider<ImageViewType>((ref) {
  return PlatformDetector.shouldUseMobileUI 
      ? ImageViewType.mobile 
      : ImageViewType.desktop;
});

/// 图片预览实现类型
enum ImageViewType {
  /// 移动端实现（触摸优化）
  mobile,
  
  /// 桌面端实现（鼠标和键盘优化）
  desktop,
}

extension ImageViewTypeExtension on ImageViewType {
  /// 获取类型的描述文本
  String get description {
    switch (this) {
      case ImageViewType.mobile:
        return '移动端触摸优化实现';
      case ImageViewType.desktop:
        return '桌面端鼠标键盘优化实现';
    }
  }

  /// 检查是否支持触摸手势
  bool get supportsTouchGestures {
    switch (this) {
      case ImageViewType.mobile:
        return true;
      case ImageViewType.desktop:
        return false;
    }
  }

  /// 检查是否支持键盘快捷键
  bool get supportsKeyboardShortcuts {
    switch (this) {
      case ImageViewType.mobile:
        return false;
      case ImageViewType.desktop:
        return true;
    }
  }

  /// 获取推荐的手势配置
  Map<String, dynamic> get gestureConfig {
    return PlatformDetector.getGestureConfig();
  }

  /// 获取交互阈值
  Map<String, double> get interactionThresholds {
    return PlatformDetector.getInteractionThresholds();
  }
}