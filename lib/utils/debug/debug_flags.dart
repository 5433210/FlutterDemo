import 'dart:ui';

/// 应用程序调试标志工具
class DebugFlags {
  /// 是否启用擦除调试
  static bool enableEraseDebug = false;

  /// 是否启用坐标转换调试
  static bool enableCoordinateDebug = false;

  /// 是否启用性能监控
  static bool enablePerformanceMonitoring = false;

  /// 是否启用事件追踪
  static bool enableEventTracing = false;

  /// 启用模式状态跟踪
  static bool enableModeTracking = true;

  /// 添加当前应用中所有AltKey状态监控点
  static final Map<String, bool> _altKeyStates = {};

  /// 记录调试信息
  static void log(String tag, String message) {
    print('🔍 [$tag] $message');
  }

  /// 记录擦除事件
  static void logErase(String action, Offset position, [Offset? delta]) {
    if (!enableEraseDebug) return;

    String msg = '$action - 位置: $position';
    if (delta != null) {
      msg += ', delta: $delta';
    }
    log('擦除', msg);
  }

  /// 记录模式切换
  static void logModeChange(bool altKeyPressed) {
    if (!enableEraseDebug) return;

    final mode = altKeyPressed ? '平移模式' : '擦除模式';
    log('模式切换', '当前为$mode');
  }

  /// 记录平移事件
  static void logPan(Offset position, Offset delta) {
    if (!enableEraseDebug) return;

    log('平移', '位置: $position, 增量: $delta');
  }

  /// 记录AltKey状态变化
  static void trackAltKeyState(String source, bool isPressed) {
    if (!enableModeTracking) return;

    _altKeyStates[source] = isPressed;
    log('AltKey', '$source 设置为: ${isPressed ? "按下" : "释放"}');

    // 检查是否存在不一致的状态
    _checkConsistency();
  }

  /// 检查各处Alt状态是否一致
  static void _checkConsistency() {
    if (_altKeyStates.isEmpty || _altKeyStates.length < 2) return;

    // 获取第一个值作为参考
    final firstValue = _altKeyStates.values.first;

    // 检查是否所有值都与第一个值一致
    bool allConsistent = _altKeyStates.values.every((v) => v == firstValue);

    if (!allConsistent) {
      log('AltKey', '⚠️ 状态不一致: $_altKeyStates');
    }
  }
}
