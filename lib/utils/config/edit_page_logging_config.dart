import '../../infrastructure/logging/log_level.dart';

/// 字帖编辑页日志配置
/// 提供精细化的日志控制，优化性能
class EditPageLoggingConfig {
  // 组件标签常量
  static const String TAG_EDIT_PAGE = 'EditPage';
  static const String TAG_CANVAS = 'Canvas';
  static const String TAG_CONTROLLER = 'Controller';
  static const String TAG_TEXT_PANEL = 'TextPanel';
  static const String TAG_IMAGE_PANEL = 'ImagePanel';
  static const String TAG_LAYER_PANEL = 'LayerPanel';
  static const String TAG_COLLECTION_PANEL = 'CollectionPanel';
  static const String TAG_RENDERER = 'Renderer';
  static const String TAG_FILE_OPS = 'FileOps';
  static const String TAG_PERFORMANCE = 'Performance';

  // 主编辑页面日志控制
  static bool enableEditPageLogging = true;
  static LogLevel editPageMinLevel = LogLevel.info;

  // 画布渲染日志控制 (高频操作，默认关闭)
  static bool enableCanvasLogging = true;
  static LogLevel canvasMinLevel = LogLevel.debug; // 🔧 临时启用debug级别以调试元素隐藏问题

  // 控制器日志控制
  static bool enableControllerLogging = true;
  static LogLevel controllerMinLevel = LogLevel.warning;

  // 属性面板日志控制 (高频操作，默认关闭)
  static bool enablePropertyPanelLogging = false;
  static LogLevel propertyPanelMinLevel = LogLevel.error;

  // 渲染器日志控制 (高频操作，默认关闭)
  static bool enableRendererLogging = true;
  static LogLevel rendererMinLevel = LogLevel.debug;

  // 文件操作日志控制
  static bool enableFileOpsLogging = true;
  static LogLevel fileOpsMinLevel = LogLevel.info;

  // 性能监控日志控制
  static bool enablePerformanceLogging = true;
  static LogLevel performanceMinLevel = LogLevel.info;

  // 性能阈值设置（毫秒）
  static int renderPerformanceThreshold = 16; // 一帧时间
  static int operationPerformanceThreshold = 100; // 一般操作阈值
  static int fileOperationPerformanceThreshold = 500; // 文件操作阈值

  /// 环境配置方法
  static void configureForDevelopment() {
    enableEditPageLogging = true;
    editPageMinLevel = LogLevel.debug;
    enableControllerLogging = true;
    controllerMinLevel = LogLevel.debug;
    enablePerformanceLogging = true;
    performanceMinLevel = LogLevel.info;
    // 高频日志保持关闭
    enableCanvasLogging = false;
    enablePropertyPanelLogging = false;
    enableRendererLogging = false;
  }

  static void configureForPerformanceDebugging() {
    // 专注于性能相关日志
    enablePerformanceLogging = true;
    performanceMinLevel = LogLevel.debug;
    enableRendererLogging = true;
    rendererMinLevel = LogLevel.info;
    // 其他日志级别提高
    editPageMinLevel = LogLevel.warning;
    controllerMinLevel = LogLevel.warning;
    // 高频UI日志关闭
    enableCanvasLogging = false;
    enablePropertyPanelLogging = false;
  }

  static void configureForProduction() {
    enableEditPageLogging = true;
    editPageMinLevel = LogLevel.warning;
    enableControllerLogging = true;
    controllerMinLevel = LogLevel.error;
    enablePerformanceLogging = false;
    // 所有高频日志关闭
    enableCanvasLogging = false;
    enablePropertyPanelLogging = false;
    enableRendererLogging = false;
  }

  /// 运行时动态控制方法
  static void disableHighFrequencyLogs() {
    enableCanvasLogging = false;
    enablePropertyPanelLogging = false;
    enableRendererLogging = false;
  }

  static void enableDebugMode() {
    enableEditPageLogging = true;
    enableControllerLogging = true;
    enablePerformanceLogging = true;
    editPageMinLevel = LogLevel.debug;
    controllerMinLevel = LogLevel.debug;
    performanceMinLevel = LogLevel.debug;
  }

  static void enableOnlyErrors() {
    editPageMinLevel = LogLevel.error;
    controllerMinLevel = LogLevel.error;
    fileOpsMinLevel = LogLevel.error;
    performanceMinLevel = LogLevel.error;
    disableHighFrequencyLogs();
  }
}
