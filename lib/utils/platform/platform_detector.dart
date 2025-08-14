import 'dart:io' as io;

import 'package:flutter/foundation.dart';

/// 平台检测工具类，用于判断运行环境并选择适当的UI实现
class PlatformDetector {
  // 缓存平台类型，避免重复计算
  static TargetPlatform? _cachedPlatform;
  static bool? _cachedIsMobile;
  static bool? _cachedHasTouchSupport;

  /// 获取当前平台
  static TargetPlatform get platform {
    return _cachedPlatform ??= _determinePlatform();
  }

  /// 判断是否为移动端平台（手机、平板）
  static bool get isMobile {
    return _cachedIsMobile ??= _determineMobile();
  }

  /// 判断是否为桌面端平台
  static bool get isDesktop {
    return !isMobile;
  }

  /// 判断是否支持触摸操作
  static bool get hasTouchSupport {
    return _cachedHasTouchSupport ??= _determineTouchSupport();
  }

  /// 判断是否应该使用移动端UI实现
  /// 优先考虑平台类型，只有在真正的移动设备上才使用移动端UI
  static bool get shouldUseMobileUI {
    // 只有真正的移动端平台才使用移动端UI
    // 即使桌面设备支持触摸，也优先使用桌面端UI以获得更好的精确操作体验
    return isMobile;
  }

  /// 判断是否应该使用桌面端UI实现
  static bool get shouldUseDesktopUI {
    return !shouldUseMobileUI;
  }

  /// 获取平台特定的手势检测器配置
  static Map<String, dynamic> getGestureConfig() {
    if (shouldUseMobileUI) {
      return {
        'enableTapGestures': true,
        'enablePanGestures': true,
        'enableScaleGestures': true,
        'enableRotationGestures': false, // 暂时禁用旋转手势避免冲突
        'touchSlop': 8.0,
        'scaleFactor': 1.2,
        'minimumTouchTargetSize': 44.0,
      };
    } else {
      return {
        'enableTapGestures': true,
        'enablePanGestures': false, // 桌面端主要使用鼠标操作
        'enableScaleGestures': false,
        'enableRotationGestures': false,
        'touchSlop': 4.0,
        'scaleFactor': 1.0,
        'minimumTouchTargetSize': 24.0,
      };
    }
  }

  /// 获取平台特定的交互阈值
  static Map<String, double> getInteractionThresholds() {
    if (shouldUseMobileUI) {
      return {
        'tapTimeout': 150.0, // 触摸点击超时时间（毫秒）
        'longPressTimeout': 500.0, // 长按超时时间（毫秒）
        'panThreshold': 18.0, // 拖拽开始的最小距离（像素）
        'scaleThreshold': 0.1, // 缩放开始的最小比例变化
        'velocityThreshold': 50.0, // 速度阈值（像素/秒）
        'handleSize': 24.0, // 控制手柄大小（像素）
        'minSelectionSize': 40.0, // 最小选区大小（像素）
      };
    } else {
      return {
        'tapTimeout': 100.0,
        'longPressTimeout': 300.0,
        'panThreshold': 4.0,
        'scaleThreshold': 0.05,
        'velocityThreshold': 20.0,
        'handleSize': 12.0,
        'minSelectionSize': 20.0,
      };
    }
  }

  /// 清除缓存，重新检测平台
  static void clearCache() {
    _cachedPlatform = null;
    _cachedIsMobile = null;
    _cachedHasTouchSupport = null;
  }

  // 私有方法：确定平台类型
  static TargetPlatform _determinePlatform() {
    return defaultTargetPlatform;
  }

  // 私有方法：判断是否为移动端
  static bool _determineMobile() {
    switch (platform) {
      case TargetPlatform.android:
      case TargetPlatform.iOS:
        return true;
      case TargetPlatform.windows:
      case TargetPlatform.macOS:
      case TargetPlatform.linux:
        return false;
      default:
        // Web端需要额外判断用户代理
        return kIsWeb ? _isWebMobile() : false;
    }
  }

  // 私有方法：判断是否支持触摸
  static bool _determineTouchSupport() {
    if (isMobile) {
      return true;
    }

    // 对于桌面端，检查是否有触摸支持
    // 这是一个简化的实现，实际情况可能需要更复杂的检测
    if (platform == TargetPlatform.windows) {
      // Windows 设备可能支持触摸
      return _hasWindowsTouchSupport();
    }

    return false;
  }

  // 私有方法：检测Web端是否为移动设备
  static bool _isWebMobile() {
    if (!kIsWeb) return false;

    // 在Web环境中，可以通过用户代理字符串判断
    // 这里提供一个基础实现，实际项目中可能需要更精确的检测
    try {
      final userAgent = io.Platform.operatingSystem;
      return userAgent.toLowerCase().contains('mobile') ||
             userAgent.toLowerCase().contains('android') ||
             userAgent.toLowerCase().contains('iphone') ||
             userAgent.toLowerCase().contains('ipad');
    } catch (e) {
      // 如果无法获取用户代理，假设不是移动端
      return false;
    }
  }

  // 私有方法：检测Windows是否支持触摸
  static bool _hasWindowsTouchSupport() {
    // 这是一个简化的实现
    // 实际项目中可能需要通过平台通道查询系统信息
    return false; // 默认假设Windows桌面不支持触摸
  }
}