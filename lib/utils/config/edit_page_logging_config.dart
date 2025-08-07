import 'package:flutter/foundation.dart';

import '../../infrastructure/logging/log_level.dart';

/// 字帖编辑页日志配置 - 优化版
/// 提供精细化的日志控制，减少冗余输出，优化性能
class EditPageLoggingConfig {
  // ============ 组件标签常量 ============
  static const String tagEditPage = 'PracticeEdit';
  static const String tagCanvas = 'Canvas';
  static const String tagController = 'Controller';
  static const String tagTextPanel = 'TextPanel';
  static const String tagImagePanel = 'ImagePanel';
  static const String tagLayerPanel = 'LayerPanel';
  static const String tagCollectionPanel = 'CollectionPanel';
  static const String tagRenderer = 'Renderer';
  static const String tagFileOps = 'FileOps';
  static const String tagPerformance = 'Performance';
  static const String tagClipboard = 'Clipboard';
  static const String tagUserAction = 'UserAction';
  static const String tagBusiness = 'Business';

  // ============ 核心日志控制 ============
  
  // 主编辑页面日志控制 - 只记录关键业务操作
  static bool enableEditPageLogging = true;
  static LogLevel editPageMinLevel = LogLevel.info;

  // 画布渲染日志控制 - 高频操作，默认关闭，仅错误
  static bool enableCanvasLogging = false;
  static LogLevel canvasMinLevel = LogLevel.error;

  // 控制器日志控制 - 仅记录状态变化和错误
  static bool enableControllerLogging = true;
  static LogLevel controllerMinLevel = LogLevel.warning;

  // 属性面板日志控制 - 高频操作，默认关闭
  static bool enablePropertyPanelLogging = false;
  static LogLevel propertyPanelMinLevel = LogLevel.error;

  // 渲染器日志控制 - 性能敏感，默认关闭
  static bool enableRendererLogging = false;
  static LogLevel rendererMinLevel = LogLevel.warning;

  // 文件操作日志控制 - 重要操作，保持开启
  static bool enableFileOpsLogging = true;
  static LogLevel fileOpsMinLevel = LogLevel.info;

  // 性能监控日志控制 - 只记录超阈值的操作
  static bool enablePerformanceLogging = true;
  static LogLevel performanceMinLevel = LogLevel.warning;

  // ============ 防重复日志控制 ============
  
  // 剪贴板状态检查防重复（秒）
  static int clipboardStateDedupeInterval = 2;
  
  // 页面切换状态防重复（毫秒）
  static int pageStateDedupeInterval = 500;
  
  // 工具状态切换防重复（毫秒）
  static int toolStateDedupeInterval = 300;
  
  // 拖拽操作防重复（毫秒）
  static int dragOperationDedupeInterval = 100;

  // ============ 性能阈值设置（毫秒）============
  static int renderPerformanceThreshold = 16; // 一帧时间，超过则警告
  static int operationPerformanceThreshold = 200; // 用户操作阈值
  static int fileOperationPerformanceThreshold = 1000; // 文件操作阈值
  static int complexOperationThreshold = 500; // 复杂操作阈值（如格式刷）

  // ============ 批量日志控制 ============
  
  // 启用批量日志处理
  static bool enableBatchLogging = true;
  
  // 批量日志刷新间隔（毫秒）
  static int batchLogFlushInterval = 200;
  
  // 批量日志最大条目数
  static int maxBatchLogEntries = 50;

  /// 环境配置方法 - 优化版
  static void configureForDevelopment() {
    enableEditPageLogging = true;
    editPageMinLevel = LogLevel.info; // 开发环境只记录info以上
    enableControllerLogging = true;
    controllerMinLevel = LogLevel.info;
    enablePerformanceLogging = true;
    performanceMinLevel = LogLevel.warning; // 只记录性能问题
    enableFileOpsLogging = true;
    fileOpsMinLevel = LogLevel.info;
    
    // 高频日志保持关闭，避免日志洪流
    enableCanvasLogging = false;
    enablePropertyPanelLogging = false;
    enableRendererLogging = false;
  }

  static void configureForPerformanceDebugging() {
    // 专注于性能相关日志，其他最小化
    enablePerformanceLogging = true;
    performanceMinLevel = LogLevel.info;
    enableRendererLogging = true;
    rendererMinLevel = LogLevel.warning;
    enableCanvasLogging = false; // 即使性能调试也不开启画布日志
    
    // 其他日志级别提高，减少干扰
    editPageMinLevel = LogLevel.warning;
    controllerMinLevel = LogLevel.error;
    enablePropertyPanelLogging = false;
    
    // 降低性能阈值，捕获更多性能问题
    renderPerformanceThreshold = 8;
    operationPerformanceThreshold = 100;
  }

  static void configureForProduction() {
    // 生产环境只记录关键信息和错误
    enableEditPageLogging = true;
    editPageMinLevel = LogLevel.warning;
    enableControllerLogging = true;
    controllerMinLevel = LogLevel.error;
    enableFileOpsLogging = true;
    fileOpsMinLevel = LogLevel.warning;
    
    // 性能日志只记录严重问题
    enablePerformanceLogging = true;
    performanceMinLevel = LogLevel.error;
    
    // 所有高频日志关闭
    enableCanvasLogging = false;
    enablePropertyPanelLogging = false;
    enableRendererLogging = false;
    
    // 提高性能阈值，只记录严重性能问题
    renderPerformanceThreshold = 32;
    operationPerformanceThreshold = 500;
    fileOperationPerformanceThreshold = 2000;
  }

  static void configureForDebugging() {
    // 调试模式：开启关键组件的详细日志
    enableEditPageLogging = true;
    editPageMinLevel = LogLevel.debug;
    enableControllerLogging = true;
    controllerMinLevel = LogLevel.debug;
    enableFileOpsLogging = true;
    fileOpsMinLevel = LogLevel.debug;
    enablePerformanceLogging = true;
    performanceMinLevel = LogLevel.info;
    
    // 根据需要选择性开启高频日志
    enableCanvasLogging = kDebugMode;
    canvasMinLevel = LogLevel.warning;
    enablePropertyPanelLogging = kDebugMode;
    propertyPanelMinLevel = LogLevel.warning;
    enableRendererLogging = kDebugMode;
    rendererMinLevel = LogLevel.warning;
  }

  /// 运行时动态控制方法
  static void disableHighFrequencyLogs() {
    enableCanvasLogging = false;
    enablePropertyPanelLogging = false;
    enableRendererLogging = false;
    
    // 增加防重复间隔
    clipboardStateDedupeInterval = 5;
    pageStateDedupeInterval = 1000;
    toolStateDedupeInterval = 500;
  }

  static void enableMinimalLogging() {
    // 最小化日志模式：只记录错误和关键业务操作
    editPageMinLevel = LogLevel.error;
    controllerMinLevel = LogLevel.error;
    fileOpsMinLevel = LogLevel.warning;
    performanceMinLevel = LogLevel.error;
    disableHighFrequencyLogs();
  }

  static void enableBusinessLogging() {
    // 业务日志模式：专注于用户操作和业务流程
    enableEditPageLogging = true;
    editPageMinLevel = LogLevel.info;
    enableFileOpsLogging = true;
    fileOpsMinLevel = LogLevel.info;
    enablePerformanceLogging = false; // 不关心性能细节
    disableHighFrequencyLogs();
  }

  /// 获取当前配置摘要
  static Map<String, dynamic> getConfigSummary() {
    return {
      'editPage': {
        'enabled': enableEditPageLogging,
        'minLevel': editPageMinLevel.name,
      },
      'canvas': {
        'enabled': enableCanvasLogging,
        'minLevel': canvasMinLevel.name,
      },
      'controller': {
        'enabled': enableControllerLogging,
        'minLevel': controllerMinLevel.name,
      },
      'performance': {
        'enabled': enablePerformanceLogging,
        'minLevel': performanceMinLevel.name,
        'thresholds': {
          'render': renderPerformanceThreshold,
          'operation': operationPerformanceThreshold,
          'fileOp': fileOperationPerformanceThreshold,
        },
      },
      'deduplication': {
        'clipboard': clipboardStateDedupeInterval,
        'pageState': pageStateDedupeInterval,
        'toolState': toolStateDedupeInterval,
      },
      'batch': {
        'enabled': enableBatchLogging,
        'flushInterval': batchLogFlushInterval,
        'maxEntries': maxBatchLogEntries,
      },
    };
  }

  /// 根据性能模式调整配置
  static void adjustForPerformanceMode(bool highPerformanceMode) {
    if (highPerformanceMode) {
      // 高性能模式：最小化日志
      disableHighFrequencyLogs();
      editPageMinLevel = LogLevel.warning;
      controllerMinLevel = LogLevel.error;
      performanceMinLevel = LogLevel.error;
      
      // 增加防重复间隔
      clipboardStateDedupeInterval = 10;
      pageStateDedupeInterval = 2000;
      toolStateDedupeInterval = 1000;
      
      // 启用批量处理
      enableBatchLogging = true;
      batchLogFlushInterval = 500;
    } else {
      // 正常模式：标准配置
      configureForDevelopment();
    }
  }
}
