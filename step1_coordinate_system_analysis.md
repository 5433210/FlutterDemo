# 步驟1輸出物：坐標系統分析

## 坐標系統關係圖

### 1. 原始圖像坐標系 (Original Image Coordinate)
```
原點: (0, 0) 圖像左上角
軸向: X軸向右，Y軸向下  
範圍: 0 ≤ x ≤ imageWidth, 0 ≤ y ≤ imageHeight
用途: 存儲裁剪坐標 (cropX, cropY, cropWidth, cropHeight)

示例: 750×1667圖像
┌─────────────────┐ (750, 0)
│                 │
│    Original     │
│    Image        │
│                 │
│                 │
└─────────────────┘ (750, 1667)
(0, 0)
```

### 2. 容器坐標系 (Container Coordinate)
```
原點: (0, 0) 容器左上角
軸向: X軸向右，Y軸向下
範圍: 0 ≤ x ≤ containerWidth, 0 ≤ y ≤ containerHeight
用途: 布局計算和事件處理

示例: 400×300容器
┌───────────────┐ (400, 0)
│   Container   │
│               │
└───────────────┘ (400, 300)
(0, 0)
```

### 3. Transform坐標系 (Transform Coordinate)
```
原點: Transform變換作用點
旋轉中心: 容器中心 (containerWidth/2, containerHeight/2)
變換順序: T1(移到中心) → R(旋轉) → T2(移回原位)
用途: 視覺圖像旋轉顯示

Transform矩陣:
Matrix4.identity()
  ..translate(200, 150)     // 移到容器中心 (400/2, 300/2)
  ..rotateZ(90° * π/180)    // 旋轉90度
  ..translate(-200, -150)   // 移回原位
```

### 4. 動態邊界坐標系 (Dynamic Boundary Coordinate)
```
原點: 動態邊界左上角
軸向: 考慮旋轉後的邊界
範圍: 基於旋轉後的包圍盒計算
用途: ImageTransformCoordinator 中的坐標轉換

750×1667圖像旋轉90度後的動態邊界: 1667×750
```

## 坐標系統變換關係圖

```
當前系統的兩條並行路徑（問題所在）：

路徑A - Transform視覺變換:
原始圖像坐標 (cropX, cropY, cropWidth, cropHeight)
    ↓ (縮放 + 居中)
容器顯示坐標 (imageLeft + cropX*scale, imageTop + cropY*scale)
    ↓ (Transform矩陣變換)
最終視覺位置 (旋轉後的顯示位置)

路徑B - 裁剪框計算:
原始圖像坐標 (cropX, cropY, cropWidth, cropHeight)
    ↓ (ImageTransformCoordinator)
動態邊界坐標
    ↓ (縮放 + 居中)
容器顯示坐標 (裁剪框顯示位置)

問題: 路徑A和路徑B的最終結果不匹配！
```

## 關鍵方法數據流分析

### `_calculateCropRectForTransformedImage` 方法分析

**位置**: `interactive_crop_overlay.dart:888-926`

**數據流程**:
```
輸入參數:
- containerSize: Size(400, 300)
- widget.imageSize: Size(750, 1667) 
- widget.renderSize: Size(180, 300)  // 基於contain計算
- _currentCropX: 0
- _currentCropY: 0  
- _currentCropWidth: 750
- _currentCropHeight: 1667
- widget.contentRotation: 90

計算步驟:
1. imageLeft = (400 - 180) / 2 = 110
   imageTop = (300 - 300) / 2 = 0

2. cropRatioX = 0 / 750 = 0
   cropRatioY = 0 / 1667 = 0
   cropRatioWidth = 750 / 750 = 1.0
   cropRatioHeight = 1667 / 1667 = 1.0

3. cropLeft = 110 + (0 * 180) = 110
   cropTop = 0 + (0 * 300) = 0
   cropWidth = 1.0 * 180 = 180
   cropHeight = 1.0 * 300 = 300

輸出: Rect.fromLTWH(110, 0, 180, 300)
```

**問題**: 這個計算完全沒有考慮90度旋轉！實際上圖像已經被Transform旋轉了，但裁剪框還是按未旋轉的位置計算。

### Transform變換分析

**位置**: `image_property_panel_widgets.dart:614-622`

**Transform矩陣計算**:
```
contentRotation = 90度

Matrix4變換順序:
1. translate(200, 150)           // 移到容器中心
2. rotateZ(90 * π/180)          // 繞Z軸旋轉90度  
3. translate(-200, -150)        // 移回原位

等效效果: 圖像繞容器中心順時針旋轉90度
```

**旋轉效果分析**:
- 原始圖像: 180×300 (寬×高)
- 旋轉90度後視覺效果: 300×180 (寬×高)
- 但裁剪框計算還是按180×300計算位置

### InteractiveCropPainter分析

**位置**: `interactive_crop_overlay.dart:1421-1482`

**繪製流程**:
```
1. 創建ImageTransformCoordinator
2. 將原始裁剪坐標轉換為動態邊界坐標
3. 計算動態邊界在容器中的縮放和位置
4. 繪製裁剪框和控制點
```

**問題**: Painter使用動態邊界系統，但Widget中的Transform使用不同的變換邏輯，兩者不同步。

## 問題根源總結

### 核心問題
系統中存在**兩套不同的坐標變換邏輯**，導致視覺圖像和裁剪框計算不匹配：

1. **Transform變換** (用於圖像顯示):
   - 圍繞容器中心旋轉
   - 使用Matrix4變換
   - 影響視覺顯示效果

2. **動態邊界變換** (用於裁剪框):
   - 使用ImageTransformCoordinator
   - 基於數學計算的動態邊界
   - 有自己的坐標轉換邏輯

### 具體問題位置

1. **`_calculateCropRectForTransformedImage`** (第888-926行)
   - 完全忽略Transform旋轉效果
   - 按未旋轉圖像計算裁剪框位置

2. **坐標系統不統一**
   - Transform在容器坐標系中操作
   - 動態邊界有自己的坐標系
   - 兩者沒有統一的變換邏輯

### 為什麼90度旋轉時裁剪框位置錯誤

**具體數值解釋**:
```
750×1667圖像在400×300容器中，旋轉90度:

Transform變換後的視覺效果:
- 圖像實際顯示為300×180 (高×寬)
- 位置: 居中顯示

但裁剪框計算:
- 還是按180×300計算 (寬×高)
- 位置: imageLeft=110, imageTop=0
- 結果: 裁剪框出現在錯誤位置，大小也不對

正確的裁剪框應該:
- 大小: 300×180 (匹配旋轉後的視覺尺寸)
- 位置: 居中，與旋轉後圖像對齊
```

### 解決方案方向

需要建立**統一的坐標變換系統**，讓裁剪框計算完全跟隨Transform變換邏輯，或者讓Transform變換跟隨動態邊界系統。

## 下一步行動

基於這個分析，步驟2需要建立統一的數學模型，確定採用哪種坐標變換方案，並給出精確的變換公式。