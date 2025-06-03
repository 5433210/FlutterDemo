// 渲染引擎导出文件
// 该文件用于保持向后兼容性，导出主要的渲染引擎类

import 'canvas_rendering_engine.dart';

export 'canvas_rendering_engine.dart' show CanvasRenderingEngine;

// 为了向后兼容，提供RenderingEngine类型别名
typedef RenderingEngine = CanvasRenderingEngine;
