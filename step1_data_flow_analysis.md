# 步驟1輸出物：關鍵方法數據流分析

## 1. _calculateCropRectForTransformedImage 方法詳細分析

### 方法簽名和位置
```dart
// 位置: interactive_crop_overlay.dart:888-926
Rect _calculateCropRectForTransformedImage(Size containerSize)
```

### 輸入數據
```dart
containerSize: Size(400, 300)           // 容器尺寸
widget.imageSize: Size(750, 1667)       // 原始圖像尺寸
widget.renderSize: Size(134.97, 300)    // 渲染尺寸 (基於contain模式實際計算)
widget.contentRotation: 90              // 旋轉角度(度)
_currentCropX: 0                        // 當前裁剪X座標
_currentCropY: 0                        // 當前裁剪Y座標  
_currentCropWidth: 750                  // 當前裁剪寬度
_currentCropHeight: 1667                // 當前裁剪高度
```

### renderSize的實際計算
```dart
根據_calculateRenderSize方法 (第901-918行):
imageRatio = 750 / 1667 = 0.4499
containerRatio = 400 / 300 = 1.3333

因為 imageRatio < containerRatio (0.4499 < 1.3333)，所以:
renderSize = Size(
  containerSize.height * imageRatio,  // 300 * 0.4499 = 134.97
  containerSize.height,               // 300
) = Size(134.97, 300)
```

### 計算步驟流程
```dart
步驟1: 計算圖像在容器中的居中位置
imageLeft = (containerSize.width - renderSize.width) / 2
         = (400 - 134.97) / 2 
         = 132.515

imageTop = (containerSize.height - renderSize.height) / 2  
        = (300 - 300) / 2
        = 0

步驟2: 計算裁剪區域在原始圖像中的比例
cropRatioX = _currentCropX / widget.imageSize.width
          = 0 / 750 
          = 0

cropRatioY = _currentCropY / widget.imageSize.height
          = 0 / 1667
          = 0

cropRatioWidth = _currentCropWidth / widget.imageSize.width
              = 750 / 750
              = 1.0

cropRatioHeight = _currentCropHeight / widget.imageSize.height  
               = 1667 / 1667
               = 1.0

步驟3: 將比例應用到renderSize上
cropLeft = imageLeft + (cropRatioX * renderSize.width)
        = 132.515 + (0 * 134.97)
        = 132.515

cropTop = imageTop + (cropRatioY * renderSize.height)
       = 0 + (0 * 300) 
       = 0

cropWidth = cropRatioWidth * renderSize.width
         = 1.0 * 134.97
         = 134.97

cropHeight = cropRatioHeight * renderSize.height
          = 1.0 * 300  
          = 300

步驟4: 返回結果
return Rect.fromLTWH(132.515, 0, 134.97, 300)
```

### 問題分析
**致命缺陷**: 整個計算過程**完全沒有考慮90度旋轉**！

結果是裁剪框位置為 (132.515, 0, 134.97, 300)，但實際圖像已經被Transform旋轉90度，視覺上應該是 300×134.97 的尺寸。

### 正確的旋轉後視覺效果
```dart
旋轉90度後的正確計算:
- 原始renderSize: 134.97×300 (寬×高)
- 旋轉後視覺尺寸: 300×134.97 (寬×高，寬高互換)
- 旋轉後正確居中位置:
  left = (400 - 300) / 2 = 50
  top = (300 - 134.97) / 2 = 82.515

正確的視覺位置應該是: Rect.fromLTWH(50, 82.515, 300, 134.97)
當前錯誤的裁剪框位置: Rect.fromLTWH(132.515, 0, 134.97, 300)
```

## 2. Transform變換數據流分析

### Transform矩陣構建
```dart
// 位置: image_property_panel_widgets.dart:614-622
Transform(
  transform: Matrix4.identity()
    ..translate(constraints.maxWidth / 2, constraints.maxHeight / 2)    // T1
    ..rotateZ(contentRotation * (math.pi / 180.0))                     // R  
    ..translate(-constraints.maxWidth / 2, -constraints.maxHeight / 2)  // T2
)
```

### 變換步驟分解
```dart
給定: 
- constraints.maxWidth = 400
- constraints.maxHeight = 300  
- contentRotation = 90度

變換矩陣計算:
T1: translate(200, 150)        // 移動到容器中心
R:  rotateZ(π/2)              // 旋轉90度 (π/2弧度)
T2: translate(-200, -150)     // 移回原始位置

組合效果: T2 * R * T1
```

### 對圖像四個角點的變換
```dart
原始圖像在容器中的位置 (未旋轉):
- 左上角: (110, 0)
- 右上角: (290, 0)  
- 右下角: (290, 300)
- 左下角: (110, 300)

經過Transform變換後 (旋轉90度):
設原始點為 (x, y)，變換步驟:

1. T1變換: (x, y) → (x+200, y+150)
2. R變換:  (x+200, y+150) → (-(y+150-150)+200, (x+200-200)+150) = (-y+200, x+150)
3. T2變換: (-y+200, x+150) → (-y+200-200, x+150-150) = (-y, x)

簡化公式: (x, y) → (-y+200, x-50)

變換後的四個角點:
- 原(110, 0)   → (-0+200, 110-50)   = (200, 60)
- 原(290, 0)   → (-0+200, 290-50)   = (200, 240)  
- 原(290, 300) → (-300+200, 290-50) = (-100, 240)
- 原(110, 300) → (-300+200, 110-50) = (-100, 60)

等等，這個計算有問題...讓我重新計算
```

### 正確的變換計算
```dart
Transform矩陣的正確理解:
代碼中的變換順序 (Matrix4是左乘)：
1. translate(cx, cy)     // 移動到旋轉中心
2. rotateZ(θ)           // 旋轉
3. translate(-cx, -cy)   // 移回原位

對於容器中心旋轉 (200, 150)，90度順時針旋轉:
最終效果是圖像繞容器中心順時針旋轉90度

實際變換結果分析:
- 原始圖像左上角在 (132.515, 0)
- 旋轉後該點移動到新位置
- 整體圖像尺寸從 134.97×300 視覺上變成 300×134.97
```

## 3. InteractiveCropPainter數據流分析

### 繪製流程
```dart
// 位置: interactive_crop_overlay.dart:1421-1482

步驟1: 創建坐標轉換器
final coordinator = ImageTransformCoordinator(
  originalImageSize: imageSize,
  rotation: contentRotation * (math.pi / 180.0),
  flipHorizontal: flipHorizontal,
  flipVertical: flipVertical,
);

步驟2: 轉換裁剪參數
final dynamicCropParams = coordinator.originalToDynamicCropParams(
  cropX: cropX,           // 0
  cropY: cropY,           // 0  
  cropWidth: cropWidth,   // 750
  cropHeight: cropHeight, // 1667
);

步驟3: 創建動態裁剪矩形
final dynamicCropRect = Rect.fromLTWH(
  dynamicCropParams['cropX']!,      // 轉換後的值
  dynamicCropParams['cropY']!,      
  dynamicCropParams['cropWidth']!,  
  dynamicCropParams['cropHeight']!, 
);

步驟4: 計算動態邊界
final dynamicBounds = coordinator.dynamicBounds;  // 1667×750 (旋轉後)

步驟5: 計算縮放和偏移
final scaleX = size.width / dynamicBounds.width;   // 400 / 1667
final scaleY = size.height / dynamicBounds.height; // 300 / 750  
final scale = math.min(scaleX, scaleY);            // 取較小值

final offsetX = (size.width - scaledDynamicWidth) / 2;
final offsetY = (size.height - scaledDynamicHeight) / 2;

步驟6: 轉換為顯示坐標
final displayCropRect = Rect.fromLTWH(
  offsetX + (clampedDynamicRect.left * scale),
  offsetY + (clampedDynamicRect.top * scale), 
  clampedDynamicRect.width * scale,
  clampedDynamicRect.height * scale,
);
```

### 與Transform的差異
InteractiveCropPainter使用的是**數學計算的動態邊界系統**，而Transform使用的是**視覺變換矩陣**，兩者的坐標系統完全不同。

## 4. 數據流對比分析

### 當前系統的兩條路徑

#### 路徑A: Transform視覺變換
```
原始圖像(750×1667) 
  → 縮放到renderSize(134.97×300)
  → 居中顯示在容器中(132.515, 0, 134.97, 300)
  → Transform矩陣旋轉90度  
  → 最終視覺效果: 300×134.97，居中顯示在(50, 82.515)
```

#### 路徑B: 裁剪框計算
```
原始裁剪坐標(0, 0, 750, 1667)
  → ImageTransformCoordinator轉換為動態邊界坐標
  → 動態邊界(1667×750)
  → 縮放並居中顯示在容器中
  → 最終裁剪框位置: 根據動態邊界計算
```

#### 路徑C: Widget中的Transform裁剪框計算
```
原始裁剪坐標(0, 0, 750, 1667)
  → 直接按比例映射到renderSize
  → 計算在容器中的位置(132.515, 0, 134.97, 300)
  → 完全忽略旋轉！
  → 錯誤的裁剪框位置
```

### 問題根源
**路徑A、B、C的最終結果都不同**，這就是問題的根源！

## 5. 關鍵發現總結

1. **Transform變換**正確地旋轉了視覺圖像
2. **InteractiveCropPainter**使用動態邊界系統，有自己的坐標邏輯  
3. **Widget裁剪框計算**完全忽略旋轉，導致位置錯誤
4. **三套不同的坐標系統**沒有統一的變換邏輯

## 6. 數值驗證示例

### 750×1667圖像，90度旋轉，400×300容器

#### Transform變換結果 (正確的視覺效果):
- 視覺尺寸: 300×134.97 (寬×高，因為旋轉了90度)
- 視覺位置: 在400×300容器中居中顯示
- 實際占用區域: Rect.fromLTWH(50, 82.515, 300, 134.97)

#### 當前裁剪框計算的錯誤結果:
- 計算尺寸: 134.97×300 (寬×高，按未旋轉計算)
- 計算位置: (132.515, 0, 134.97, 300)
- 問題: 與實際圖像位置完全不匹配！

#### 正確的裁剪框應該是:
- 尺寸: 300×134.97 (匹配旋轉後的視覺尺寸)
- 位置: 居中，與旋轉後圖像完全重合

這個分析清楚地解釋了為什麼用戶看到裁剪框"過大且位置錯誤"的問題。