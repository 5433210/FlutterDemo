import 'package:flutter/material.dart';

/// 吸附管理器
class SnapManager {
  /// 网格大小
  final double gridSize;
  
  /// 吸附阈值（像素）
  final double snapThreshold;
  
  /// 是否启用吸附
  final bool enabled;
  
  /// 构造函数
  SnapManager({
    this.gridSize = 20.0,
    this.snapThreshold = 10.0,
    this.enabled = true,
  });
  
  /// 吸附到网格
  Offset snapToGrid(Offset position) {
    if (!enabled) return position;
    
    final snappedX = (position.dx / gridSize).round() * gridSize;
    final snappedY = (position.dy / gridSize).round() * gridSize;
    
    return Offset(snappedX, snappedY);
  }
  
  /// 吸附到其他元素
  Offset snapToElements(Offset position, List<Map<String, dynamic>> elements, String currentElementId) {
    if (!enabled) return position;
    
    // 找出除当前元素外的所有元素
    final otherElements = elements.where((e) => e['id'] != currentElementId).toList();
    
    // 如果没有其他元素，直接返回
    if (otherElements.isEmpty) return position;
    
    // 计算所有其他元素的边界
    final boundaries = <Rect>[];
    for (final element in otherElements) {
      final x = (element['x'] as num).toDouble();
      final y = (element['y'] as num).toDouble();
      final width = (element['width'] as num).toDouble();
      final height = (element['height'] as num).toDouble();
      
      boundaries.add(Rect.fromLTWH(x, y, width, height));
    }
    
    // 尝试吸附到其他元素的边界
    double closestX = position.dx;
    double closestY = position.dy;
    double minXDist = snapThreshold;
    double minYDist = snapThreshold;
    
    for (final boundary in boundaries) {
      // 检查X轴吸附
      final leftDist = (position.dx - boundary.left).abs();
      final rightDist = (position.dx - boundary.right).abs();
      final centerXDist = (position.dx - boundary.center.dx).abs();
      
      if (leftDist < minXDist) {
        minXDist = leftDist;
        closestX = boundary.left;
      }
      
      if (rightDist < minXDist) {
        minXDist = rightDist;
        closestX = boundary.right;
      }
      
      if (centerXDist < minXDist) {
        minXDist = centerXDist;
        closestX = boundary.center.dx;
      }
      
      // 检查Y轴吸附
      final topDist = (position.dy - boundary.top).abs();
      final bottomDist = (position.dy - boundary.bottom).abs();
      final centerYDist = (position.dy - boundary.center.dy).abs();
      
      if (topDist < minYDist) {
        minYDist = topDist;
        closestY = boundary.top;
      }
      
      if (bottomDist < minYDist) {
        minYDist = bottomDist;
        closestY = boundary.bottom;
      }
      
      if (centerYDist < minYDist) {
        minYDist = centerYDist;
        closestY = boundary.center.dy;
      }
    }
    
    // 如果找到了吸附点，返回吸附后的位置
    if (minXDist < snapThreshold || minYDist < snapThreshold) {
      return Offset(
        minXDist < snapThreshold ? closestX : position.dx,
        minYDist < snapThreshold ? closestY : position.dy,
      );
    }
    
    return position;
  }
  
  /// 吸附位置（先尝试吸附到其他元素，再尝试吸附到网格）
  Offset snapPosition(Offset position, List<Map<String, dynamic>> elements, String currentElementId) {
    if (!enabled) return position;
    
    // 先尝试吸附到其他元素
    final snappedToElements = snapToElements(position, elements, currentElementId);
    
    // 如果已经吸附到其他元素，直接返回
    if (snappedToElements != position) {
      return snappedToElements;
    }
    
    // 否则尝试吸附到网格
    return snapToGrid(position);
  }
}
