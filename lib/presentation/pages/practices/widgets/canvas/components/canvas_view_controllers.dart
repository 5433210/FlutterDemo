import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart';

import '../../../../../../infrastructure/logging/edit_page_logger_extension.dart';
import '../../../../../../infrastructure/logging/logger.dart';
import '../../../../../widgets/practice/practice_edit_controller.dart';
import '../../../helpers/element_utils.dart';

/// 画布视图控制器 mixin
/// 负责处理画布视图相关的逻辑，如缩放、重置、坐标转换等
mixin CanvasViewControllers {
  /// 获取控制器（由使用此mixin的类实现）
  PracticeEditController get controller;

  /// 获取转换控制器（由使用此mixin的类实现）
  TransformationController get transformationController;

  /// 获取BuildContext（由使用此mixin的类实现）
  BuildContext get context;

  /// 获取mounted状态（由使用此mixin的类实现）
  bool get mounted;

  /// 重置画布位置到适合屏幕的状态
  void resetCanvasPosition() {
    AppLogger.info('重置画布位置', tag: 'Canvas');
    fitPageToScreen();
  }

  /// 将页面内容适应屏幕，具有合适的缩放和居中
  void fitPageToScreen() {
    AppLogger.debug('开始适应页面到屏幕', tag: 'Canvas');

    // 确保有当前页面
    final currentPage = controller.state.currentPage;
    if (currentPage == null) {
      AppLogger.warning('没有当前页面，无法重置视图', tag: 'Canvas');
      return;
    }

    // 获取视口大小
    if (!mounted) {
      AppLogger.warning('组件未挂载，无法重置视图', tag: 'Canvas');
      return;
    }

    final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) {
      AppLogger.warning('无法获取渲染框，无法重置视图', tag: 'Canvas');
      return;
    }

    final Size viewportSize = renderBox.size;

    // 获取页面大小（画布内容边界）
    final Size pageSize = ElementUtils.calculatePixelSize(currentPage);

    AppLogger.debug(
      '重置视图计算信息',
      tag: 'Canvas',
      data: {
        'currentPageSize': '${currentPage['width']}x${currentPage['height']}',
        'calculatedPageSize': '${pageSize.width}x${pageSize.height}',
        'viewportSize': '${viewportSize.width}x${viewportSize.height}',
      },
    );

    // 在页面周围添加一些填充（每边5%用于更好的内容可见性）
    const double paddingFactor = 0.95; // 使用95%的视口用于内容，5%用于填充 - 最大化内容显示
    final double availableWidth = viewportSize.width * paddingFactor;
    final double availableHeight = viewportSize.height * paddingFactor;

    // 计算缩放以使页面适合可用视口区域
    final double scaleX = availableWidth / pageSize.width;
    final double scaleY = availableHeight / pageSize.height;
    final double scale = scaleX < scaleY ? scaleX : scaleY; // 使用较小的缩放完全适应

    // 计算平移以使缩放后的页面在视口中居中
    final double scaledPageWidth = pageSize.width * scale;
    final double scaledPageHeight = pageSize.height * scale;
    final double dx = (viewportSize.width - scaledPageWidth) / 2;
    final double dy = (viewportSize.height - scaledPageHeight) / 2;

    // 创建变换矩阵
    final Matrix4 matrix = Matrix4.identity()
      ..translate(dx, dy)
      ..scale(scale, scale);

    AppLogger.debug(
      '应用变换矩阵',
      tag: 'Canvas',
      data: {
        'scale': scale,
        'translation': '($dx, $dy)',
        'scaledPageSize': '${scaledPageWidth}x$scaledPageHeight',
      },
    );

    // 应用变换
    transformationController.value = matrix;

    // 验证变换应用是否正确
    final appliedMatrix = transformationController.value;
    final appliedScale = appliedMatrix.getMaxScaleOnAxis();

    if ((appliedScale - scale).abs() < 0.001) {
      AppLogger.debug('变换应用正确', tag: 'Canvas');
    } else {
      AppLogger.warning(
        '变换应用可能有误',
        tag: 'Canvas',
        data: {
          'expectedScale': scale,
          'appliedScale': appliedScale,
          'scaleDifference': (appliedScale - scale).abs(),
        },
      );
    }

    // 更新控制器的缩放值
    controller.zoomTo(scale);

    AppLogger.info(
      '视图重置完成',
      tag: 'Canvas',
      data: {
        'finalScale': scale,
        'availableSize': '${availableWidth}x$availableHeight',
        'scaledContentSize': '${scaledPageWidth}x$scaledPageHeight',
        'centerOffset': '($dx, $dy)',
      },
    );
  }

  /// 切换性能监控覆盖层显示
  void togglePerformanceOverlay() {
    // 由于DragConfig可能在其他文件中定义，这里只提供接口
    // 具体实现由使用此mixin的类完成
    AppLogger.debug('切换性能覆盖层显示', tag: 'Canvas');
  }

  /// 将屏幕坐标转换为画布坐标
  Offset screenToCanvas(Offset screenPoint) {
    try {
      final Matrix4 matrix = transformationController.value;

      // 检查矩阵是否有效
      if (!_isValidMatrix(matrix)) {
        EditPageLogger.editPageError(
          '无效的变换矩阵',
          data: {
            'matrix': matrix.toString(),
            'determinant': matrix.determinant(),
          },
        );
        return screenPoint; // 返回原始点作为回退
      }

      Matrix4 invertedMatrix;
      try {
        invertedMatrix = Matrix4.inverted(matrix);
      } catch (e) {
        // 如果矩阵不可逆，使用恒等矩阵作为回退
        EditPageLogger.editPageError(
          '矩阵不可逆',
          error: e,
          data: {
            'matrix': matrix.toString(),
            'determinant': matrix.determinant(),
          },
        );

        // 重置变换控制器
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            transformationController.value = Matrix4.identity();
          }
        });

        return screenPoint; // 返回原始点作为回退
      }

      final Vector3 transformed = invertedMatrix.transform3(Vector3(
        screenPoint.dx,
        screenPoint.dy,
        0,
      ));

      final canvasPoint = Offset(transformed.x, transformed.y);

      AppLogger.debug(
        '坐标转换：屏幕到画布',
        tag: 'Canvas',
        data: {
          'screenPoint': '$screenPoint',
          'canvasPoint': '$canvasPoint',
        },
      );

      return canvasPoint;
    } catch (e) {
      EditPageLogger.editPageError(
        '屏幕到画布坐标转换失败',
        error: e,
      );
      return screenPoint; // 返回原始点作为回退
    }
  }

  /// 检查矩阵是否有效
  bool _isValidMatrix(Matrix4 matrix) {
    // 检查矩阵中是否有NaN或Infinity值
    for (int i = 0; i < 16; i++) {
      final value = matrix.storage[i];
      if (value.isNaN || value.isInfinite) {
        return false;
      }
    }

    // 检查行列式是否接近0（不可逆）
    final determinant = matrix.determinant();
    if (determinant.abs() < 1e-10) {
      return false;
    }

    return true;
  }

  /// 将画布坐标转换为屏幕坐标
  Offset canvasToScreen(Offset canvasPoint) {
    try {
      final Matrix4 matrix = transformationController.value;

      // 检查矩阵是否有效
      if (!_isValidMatrix(matrix)) {
        EditPageLogger.editPageError(
          '无效的变换矩阵',
          data: {
            'matrix': matrix.toString(),
            'determinant': matrix.determinant(),
          },
        );
        return canvasPoint; // 返回原始点作为回退
      }

      final Vector3 transformed = matrix.transform3(Vector3(
        canvasPoint.dx,
        canvasPoint.dy,
        0,
      ));

      final screenPoint = Offset(transformed.x, transformed.y);

      AppLogger.debug(
        '坐标转换：画布到屏幕',
        tag: 'Canvas',
        data: {
          'canvasPoint': '$canvasPoint',
          'screenPoint': '$screenPoint',
        },
      );

      return screenPoint;
    } catch (e) {
      EditPageLogger.editPageError(
        '画布到屏幕坐标转换失败',
        error: e,
      );
      return canvasPoint; // 返回原始点作为回退
    }
  }

  /// 获取当前缩放级别
  double getCurrentScale() {
    final scale = transformationController.value.getMaxScaleOnAxis();
    AppLogger.debug(
      '获取当前缩放级别',
      tag: 'Canvas',
      data: {'scale': scale},
    );
    return scale;
  }

  /// 设置缩放级别（以画布中心为基准）
  void setScale(double scale, {Offset? focalPoint}) {
    AppLogger.debug(
      '设置缩放级别',
      tag: 'Canvas',
      data: {
        'targetScale': scale,
        'focalPoint': focalPoint != null ? '$focalPoint' : 'center',
      },
    );

    // 获取当前变换
    final Matrix4 currentMatrix = transformationController.value;
    final double currentScale = currentMatrix.getMaxScaleOnAxis();
    final Vector3 currentTranslation = currentMatrix.getTranslation();

    // 如果没有指定焦点，使用视口中心
    Offset focal = focalPoint ?? _getViewportCenter();

    // 计算缩放差异
    final double scaleDelta = scale / currentScale;

    // 计算新的平移量以保持焦点位置不变
    final double newTranslationX =
        focal.dx - (focal.dx - currentTranslation.x) * scaleDelta;
    final double newTranslationY =
        focal.dy - (focal.dy - currentTranslation.y) * scaleDelta;

    // 创建新的变换矩阵
    final Matrix4 newMatrix = Matrix4.identity()
      ..translate(newTranslationX, newTranslationY)
      ..scale(scale);

    transformationController.value = newMatrix;
    controller.zoomTo(scale);

    AppLogger.info(
      '缩放级别设置完成',
      tag: 'Canvas',
      data: {
        'newScale': scale,
        'newTranslation': '($newTranslationX, $newTranslationY)',
      },
    );
  }

  /// 获取视口中心点
  Offset _getViewportCenter() {
    if (!mounted) return Offset.zero;

    final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return Offset.zero;

    final Size viewportSize = renderBox.size;
    return Offset(viewportSize.width / 2, viewportSize.height / 2);
  }

  /// 平移画布到指定位置
  void panTo(Offset offset) {
    AppLogger.debug(
      '平移画布',
      tag: 'Canvas',
      data: {'targetOffset': '$offset'},
    );

    final Matrix4 currentMatrix = transformationController.value;
    final double currentScale = currentMatrix.getMaxScaleOnAxis();

    final Matrix4 newMatrix = Matrix4.identity()
      ..translate(offset.dx, offset.dy)
      ..scale(currentScale);

    transformationController.value = newMatrix;

    AppLogger.info(
      '画布平移完成',
      tag: 'Canvas',
      data: {'newOffset': '$offset'},
    );
  }

  /// 获取当前平移量
  Offset getCurrentTranslation() {
    final Vector3 translation = transformationController.value.getTranslation();
    final offset = Offset(translation.x, translation.y);

    AppLogger.debug(
      '获取当前平移量',
      tag: 'Canvas',
      data: {'translation': '$offset'},
    );

    return offset;
  }

  /// 计算页面在当前变换下的可见区域
  Rect getVisiblePageArea() {
    final currentPage = controller.state.currentPage;
    if (currentPage == null) return Rect.zero;

    final Size pageSize = ElementUtils.calculatePixelSize(currentPage);
    final Matrix4 matrix = transformationController.value;
    final double scale = matrix.getMaxScaleOnAxis();
    final Vector3 translation = matrix.getTranslation();

    // 计算页面在屏幕上的位置和大小
    final double scaledWidth = pageSize.width * scale;
    final double scaledHeight = pageSize.height * scale;

    final Rect visibleArea = Rect.fromLTWH(
      translation.x,
      translation.y,
      scaledWidth,
      scaledHeight,
    );

    AppLogger.debug(
      '计算可见页面区域',
      tag: 'Canvas',
      data: {
        'pageSize': '${pageSize.width}x${pageSize.height}',
        'scale': scale,
        'visibleArea': '$visibleArea',
      },
    );

    return visibleArea;
  }
}
