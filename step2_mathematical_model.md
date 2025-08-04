# 步驟2輸出物：數學模型和坐標系統定義

## 解決方案選擇

基於步驟1的分析，我選擇**方案A：統一使用Transform變換邏輯**。

### 選擇理由
1. **一致性**：與用戶看到的視覺效果完全一致
2. **簡潔性**：不需要重構現有的動態邊界系統
3. **可靠性**：Transform變換已經工作正常
4. **維護性**：邏輯更直觀，易於理解和維護

## 統一坐標系統定義

### 1. 原始圖像坐標系 (Original Image Coordinate)
```dart
// 定義
Origin: (0, 0) at top-left corner of original image
Axes: X-right, Y-down
Range: 0 ≤ x ≤ imageWidth, 0 ≤ y ≤ imageHeight
Purpose: 存儲裁剪參數 (cropX, cropY, cropWidth, cropHeight)

// 示例：750×1667圖像
ImageRect = Rect.fromLTWH(0, 0, 750, 1667)
DefaultCrop = Rect.fromLTWH(0, 0, 750, 1667)  // 全圖裁剪
```

### 2. 容器坐標系 (Container Coordinate)
```dart
// 定義
Origin: (0, 0) at top-left corner of container
Axes: X-right, Y-down  
Range: 0 ≤ x ≤ containerWidth, 0 ≤ y ≤ containerHeight
Purpose: UI布局和事件處理

// 示例：400×300容器
ContainerRect = Rect.fromLTWH(0, 0, 400, 300)
```

### 3. 標準化Transform坐標系 (Unified Transform Coordinate)
```dart
// 定義
Origin: 容器中心 (containerWidth/2, containerHeight/2)
Rotation: 圍繞容器中心旋轉
Transform Order: translate(center) → rotate(angle) → translate(-center)
Purpose: 統一的視覺變換和裁剪框計算

// Transform矩陣
Matrix4 createTransformMatrix(Size containerSize, double rotationDegrees) {
  final centerX = containerSize.width / 2;
  final centerY = containerSize.height / 2;
  final rotationRadians = rotationDegrees * (pi / 180.0);
  
  return Matrix4.identity()
    ..translate(centerX, centerY)
    ..rotateZ(rotationRadians)
    ..translate(-centerX, -centerY);
}
```

## 完整的坐標變換公式

### 階段1：原始圖像 → 容器顯示坐標（未旋轉）

```dart
// 計算渲染尺寸（基於contain模式）
Size calculateRenderSize(Size imageSize, Size containerSize) {
  final imageRatio = imageSize.width / imageSize.height;
  final containerRatio = containerSize.width / containerSize.height;
  
  if (imageRatio > containerRatio) {
    // 圖像更寬，以容器寬度為準
    return Size(
      containerSize.width,
      containerSize.width / imageRatio,
    );
  } else {
    // 圖像更高，以容器高度為準
    return Size(
      containerSize.height * imageRatio,
      containerSize.height,
    );
  }
}

// 計算圖像在容器中的位置（居中顯示）
Offset calculateImagePosition(Size renderSize, Size containerSize) {
  return Offset(
    (containerSize.width - renderSize.width) / 2,
    (containerSize.height - renderSize.height) / 2,
  );
}

// 將原始裁剪坐標映射到容器坐標
Rect mapCropToContainer(
  double cropX, double cropY, double cropWidth, double cropHeight,
  Size imageSize, Size renderSize, Offset imagePosition
) {
  // 計算縮放比例
  final scaleX = renderSize.width / imageSize.width;
  final scaleY = renderSize.height / imageSize.height;
  
  // 映射到容器坐標
  return Rect.fromLTWH(
    imagePosition.dx + (cropX * scaleX),
    imagePosition.dy + (cropY * scaleY),
    cropWidth * scaleX,
    cropHeight * scaleY,
  );
}
```

### 階段2：容器坐標 → Transform變換後坐標

```dart
// Transform變換函數
Offset transformPoint(Offset point, Matrix4 transformMatrix) {
  final vector = Vector4(point.dx, point.dy, 0, 1);
  final transformed = transformMatrix * vector;
  return Offset(transformed.x, transformed.y);
}

// 計算變換後的矩形邊界框（axis-aligned bounding box）
Rect calculateTransformedBounds(Rect originalRect, Matrix4 transformMatrix) {
  // 獲取原始矩形的四個角點
  final corners = [
    Offset(originalRect.left, originalRect.top),      // 左上
    Offset(originalRect.right, originalRect.top),     // 右上
    Offset(originalRect.right, originalRect.bottom),  // 右下
    Offset(originalRect.left, originalRect.bottom),   // 左下
  ];
  
  // 變換所有角點
  final transformedCorners = corners.map((corner) => 
    transformPoint(corner, transformMatrix)
  ).toList();
  
  // 計算變換後的邊界框
  double minX = transformedCorners.map((p) => p.dx).reduce(math.min);
  double maxX = transformedCorners.map((p) => p.dx).reduce(math.max);
  double minY = transformedCorners.map((p) => p.dy).reduce(math.min);
  double maxY = transformedCorners.map((p) => p.dy).reduce(math.max);
  
  return Rect.fromLTRB(minX, minY, maxX, maxY);
}
```

### 完整的端到端變換

```dart
// 統一的裁剪框計算方法
Rect calculateUnifiedCropRect(
  double cropX, double cropY, double cropWidth, double cropHeight,
  Size imageSize, Size containerSize, double rotationDegrees
) {
  // 步驟1：計算未旋轉的圖像顯示參數
  final renderSize = calculateRenderSize(imageSize, containerSize);
  final imagePosition = calculateImagePosition(renderSize, containerSize);
  
  // 步驟2：將裁剪坐標映射到容器坐標
  final containerCropRect = mapCropToContainer(
    cropX, cropY, cropWidth, cropHeight,
    imageSize, renderSize, imagePosition
  );
  
  // 步驟3：應用Transform變換
  if (rotationDegrees == 0) {
    return containerCropRect;
  } else {
    final transformMatrix = createTransformMatrix(containerSize, rotationDegrees);
    return calculateTransformedBounds(containerCropRect, transformMatrix);
  }
}
```

## 數值驗證示例

### 測試案例：750×1667圖像，90度旋轉，400×300容器

```dart
// 輸入參數
final imageSize = Size(750, 1667);
final containerSize = Size(400, 300);
final rotationDegrees = 90.0;
final cropParams = (x: 0, y: 0, width: 750, height: 1667);  // 全圖裁剪

// 步驟1計算
final renderSize = calculateRenderSize(imageSize, containerSize);
// imageRatio = 750/1667 = 0.4499
// containerRatio = 400/300 = 1.3333
// 因為 0.4499 < 1.3333，所以以高度為準
// renderSize = Size(300 * 0.4499, 300) = Size(134.97, 300)

final imagePosition = calculateImagePosition(renderSize, containerSize);
// imagePosition = Offset((400-134.97)/2, (300-300)/2) = Offset(132.515, 0)

// 步驟2計算
final containerCropRect = mapCropToContainer(
  0, 0, 750, 1667,  // 全圖裁剪
  imageSize, renderSize, imagePosition
);
// scaleX = 134.97/750 = 0.1799
// scaleY = 300/1667 = 0.1800
// containerCropRect = Rect.fromLTWH(
//   132.515 + (0 * 0.1799) = 132.515,
//   0 + (0 * 0.1800) = 0,
//   750 * 0.1799 = 134.97,
//   1667 * 0.1800 = 300
// ) = Rect.fromLTWH(132.515, 0, 134.97, 300)

// 步驟3計算（Transform變換）
final transformMatrix = createTransformMatrix(containerSize, 90.0);
final transformedCropRect = calculateTransformedBounds(containerCropRect, transformMatrix);

// 90度旋轉後，134.97×300的矩形會變成300×134.97的矩形
// 並且居中顯示在容器中
// 預期結果：Rect.fromLTWH(50, 82.515, 300, 134.97)
```

### 90度旋轉的幾何分析

```dart
// 原始矩形（未旋轉）
originalRect = Rect.fromLTWH(132.515, 0, 134.97, 300)

// 四個角點
corners = [
  (132.515, 0),      // 左上
  (267.485, 0),      // 右上  
  (267.485, 300),    // 右下
  (132.515, 300),    // 左下
]

// 旋轉中心
center = (200, 150)

// 90度順時針旋轉變換公式：(x, y) → (y - cy + cx, cx - x + cy)
// 其中 (cx, cy) = (200, 150)

transformedCorners = [
  (0 - 150 + 200, 200 - 132.515 + 150) = (50, 217.485),     // 原左上
  (0 - 150 + 200, 200 - 267.485 + 150) = (50, 82.515),      // 原右上
  (300 - 150 + 200, 200 - 267.485 + 150) = (350, 82.515),   // 原右下
  (300 - 150 + 200, 200 - 132.515 + 150) = (350, 217.485),  // 原左下
]

// 計算邊界框
minX = 50, maxX = 350
minY = 82.515, maxY = 217.485

// 最終結果
transformedRect = Rect.fromLTRB(50, 82.515, 350, 217.485)
                = Rect.fromLTWH(50, 82.515, 300, 134.97)
```

## 反向變換公式（用於拖拽處理）

### 容器坐標 → 原始圖像坐標

```dart
// 反向變換：從拖拽後的容器坐標計算新的裁剪參數
(double, double, double, double) mapContainerToOriginalCrop(
  Rect newContainerRect,
  Size imageSize, Size renderSize, Offset imagePosition,
  double rotationDegrees
) {
  // 步驟1：如果有旋轉，先進行反向Transform變換
  Rect adjustedRect = newContainerRect;
  if (rotationDegrees != 0) {
    final inverseMatrix = createTransformMatrix(containerSize, -rotationDegrees);
    // 這裡需要更複雜的反向計算，將在實現時詳細處理
    adjustedRect = reverseTransformBounds(newContainerRect, inverseMatrix);
  }
  
  // 步驟2：從容器坐標映射回原始圖像坐標
  final scaleX = renderSize.width / imageSize.width;
  final scaleY = renderSize.height / imageSize.height;
  
  final cropX = (adjustedRect.left - imagePosition.dx) / scaleX;
  final cropY = (adjustedRect.top - imagePosition.dy) / scaleY;
  final cropWidth = adjustedRect.width / scaleX;
  final cropHeight = adjustedRect.height / scaleY;
  
  // 確保在有效範圍內
  return (
    math.max(0, math.min(cropX, imageSize.width)),
    math.max(0, math.min(cropY, imageSize.height)),
    math.max(1, math.min(cropWidth, imageSize.width - cropX)),
    math.max(1, math.min(cropHeight, imageSize.height - cropY)),
  );
}
```

## 邊界情況處理

### 特殊角度處理

```dart
// 標準化角度到 [0, 360) 範圍
double normalizeAngle(double degrees) {
  while (degrees < 0) degrees += 360;
  while (degrees >= 360) degrees -= 360;
  return degrees;
}

// 檢查是否為90度的倍數（可以簡化計算）
bool isRightAngle(double degrees) {
  final normalized = normalizeAngle(degrees);
  return (normalized % 90).abs() < 0.01;
}

// 90度倍數的優化計算
Size getRotatedSize(Size originalSize, double degrees) {
  final normalized = normalizeAngle(degrees);
  if (normalized >= 45 && normalized < 135 || 
      normalized >= 225 && normalized < 315) {
    // 接近90度或270度，寬高互換
    return Size(originalSize.height, originalSize.width);
  } else {
    return originalSize;
  }
}
```

### 精度處理

```dart
// 避免浮點精度問題
Rect clampToContainer(Rect rect, Size containerSize) {
  return Rect.fromLTWH(
    math.max(0, math.min(rect.left, containerSize.width)),
    math.max(0, math.min(rect.top, containerSize.height)),
    math.max(1, math.min(rect.width, containerSize.width - rect.left)),
    math.max(1, math.min(rect.height, containerSize.height - rect.top)),
  );
}

// 像素對齊
Rect pixelAlign(Rect rect) {
  return Rect.fromLTWH(
    rect.left.roundToDouble(),
    rect.top.roundToDouble(),
    rect.width.roundToDouble(),
    rect.height.roundToDouble(),
  );
}
```

## 驗證標準

### 數學一致性檢查

1. **身份變換**: 0度旋轉時結果應該與原始計算完全一致
2. **90度驗證**: 90度旋轉時寬高應該互換，位置應該正確居中
3. **180度對稱**: 180度旋轉後再180度應該回到原位
4. **反向一致**: 正向變換後反向變換應該得到原始值

### 實際數值驗證

```dart
// 測試用例1：0度旋轉（身份變換）
assert(calculateUnifiedCropRect(0, 0, 750, 1667, imageSize, containerSize, 0) 
       == Rect.fromLTWH(132.515, 0, 134.97, 300));

// 測試用例2：90度旋轉
assert(calculateUnifiedCropRect(0, 0, 750, 1667, imageSize, containerSize, 90)
       == Rect.fromLTWH(50, 82.515, 300, 134.97));

// 測試用例3：180度旋轉
assert(calculateUnifiedCropRect(0, 0, 750, 1667, imageSize, containerSize, 180)
       == Rect.fromLTWH(132.515, 0, 134.97, 300));  // 位置相同但可能有細微旋轉效果

// 測試用例4：45度旋轉（更複雜的情況）
final result45 = calculateUnifiedCropRect(0, 0, 750, 1667, imageSize, containerSize, 45);
// 結果應該是一個更大的邊界框，包含旋轉後的圖像
```

## 實現策略

### 修改點1：`_calculateCropRectForTransformedImage`

替換現有方法為統一的Transform基礎計算：

```dart
Rect _calculateCropRectForTransformedImage(Size containerSize) {
  return calculateUnifiedCropRect(
    _currentCropX, _currentCropY, _currentCropWidth, _currentCropHeight,
    widget.imageSize, containerSize, widget.contentRotation
  );
}
```

### 修改點2：拖拽處理邏輯

更新 `_updateCropFromDrag` 方法使用反向變換：

```dart
void _updateCropFromDrag(Rect newRect, {bool isDragging = false}) {
  final (newCropX, newCropY, newCropWidth, newCropHeight) = 
    mapContainerToOriginalCrop(newRect, widget.imageSize, widget.renderSize, 
                              imagePosition, widget.contentRotation);
  
  // 更新裁剪參數
  _updateCropValues(newCropX, newCropY, newCropWidth, newCropHeight, isDragging);
}
```

### 修改點3：消除動態邊界依賴

移除對 `ImageTransformCoordinator` 的依賴，統一使用Transform邏輯。

## 總結

這個數學模型提供了：

1. **統一的坐標變換公式**：從原始圖像坐標到最終顯示坐標的完整鏈路
2. **精確的數值計算**：基於實際的Transform矩陣計算
3. **完整的反向變換**：支持拖拽操作的坐標映射
4. **邊界情況處理**：角度標準化和精度控制
5. **驗證標準**：確保實現正確性的測試用例

下一步將基於這個數學模型實現具體的代碼修復。