# 步驟3輸出物：標準測試案例

## 測試案例設計原則

### 覆蓋範圍
1. **角度覆蓋**：0°, 45°, 90°, 135°, 180°, 270°, 315°
2. **圖像比例**：橫向、縦向、正方形
3. **容器比例**：不同的容器尺寸比例
4. **裁剪區域**：全圖、部分裁剪、邊界裁剪
5. **邊界情況**：極小裁剪、極大裁剪、角落裁剪

### 驗證標準
1. **視覺一致性**：裁剪框必須與旋轉後圖像完全對齊（誤差 < 2px）
2. **控制點精度**：8個控制點位置準確（誤差 < 1px）
3. **拖拽響應**：拖拽控制點產生正確的坐標變化
4. **數值精度**：計算結果與預期值匹配（相對誤差 < 0.1%）

## 核心測試案例集

### 測試案例1：標準750×1667圖像，90度旋轉
```dart
TestCase test1_standard_90_rotation = TestCase(
  name: "標準750×1667圖像90度旋轉",
  description: "這是用戶報告問題的主要案例",
  
  // 輸入參數
  imageSize: Size(750, 1667),
  containerSize: Size(400, 300),
  rotationDegrees: 90.0,
  cropParams: CropParams(x: 0, y: 0, width: 750, height: 1667),
  
  // 預期輸出
  expectedCropRect: Rect.fromLTWH(50, 82.515, 300, 134.97),
  expectedRenderSize: Size(134.97, 300),
  
  // 驗證點
  verificationPoints: [
    // 裁剪框四個角點
    VerifyPoint(type: "crop_top_left", expected: Offset(50, 82.515), tolerance: 1.0),
    VerifyPoint(type: "crop_top_right", expected: Offset(350, 82.515), tolerance: 1.0),
    VerifyPoint(type: "crop_bottom_left", expected: Offset(50, 217.485), tolerance: 1.0),
    VerifyPoint(type: "crop_bottom_right", expected: Offset(350, 217.485), tolerance: 1.0),
    
    // 8個控制點位置
    VerifyPoint(type: "handle_tl", expected: Offset(50, 82.515), tolerance: 1.0),      // 左上
    VerifyPoint(type: "handle_tm", expected: Offset(200, 82.515), tolerance: 1.0),    // 上中
    VerifyPoint(type: "handle_tr", expected: Offset(350, 82.515), tolerance: 1.0),    // 右上
    VerifyPoint(type: "handle_mr", expected: Offset(350, 150), tolerance: 1.0),       // 右中
    VerifyPoint(type: "handle_br", expected: Offset(350, 217.485), tolerance: 1.0),   // 右下
    VerifyPoint(type: "handle_bm", expected: Offset(200, 217.485), tolerance: 1.0),   // 下中
    VerifyPoint(type: "handle_bl", expected: Offset(50, 217.485), tolerance: 1.0),    // 左下
    VerifyPoint(type: "handle_ml", expected: Offset(50, 150), tolerance: 1.0),        // 左中
  ],
  
  // 拖拽測試
  dragTests: [
    DragTest(
      description: "拖拽右下角控制點",
      fromPoint: Offset(350, 217.485),
      toPoint: Offset(330, 200),
      expectedNewCrop: CropParams(x: 0, y: 0, width: 700, height: 1600),
      tolerance: 5.0,
    ),
  ],
);
```

### 測試案例2：同樣圖像，0度旋轉（回歸測試）
```dart
TestCase test2_no_rotation = TestCase(
  name: "標準750×1667圖像無旋轉",
  description: "確保未旋轉情況下功能正常",
  
  imageSize: Size(750, 1667),
  containerSize: Size(400, 300),
  rotationDegrees: 0.0,
  cropParams: CropParams(x: 0, y: 0, width: 750, height: 1667),
  
  expectedCropRect: Rect.fromLTWH(132.515, 0, 134.97, 300),
  expectedRenderSize: Size(134.97, 300),
  
  verificationPoints: [
    VerifyPoint(type: "crop_bounds", expected: Rect.fromLTWH(132.515, 0, 134.97, 300), tolerance: 1.0),
  ],
);
```

### 測試案例3：45度旋轉（複雜角度）
```dart
TestCase test3_45_degree_rotation = TestCase(
  name: "750×1667圖像45度旋轉",
  description: "非直角旋轉的複雜情況",
  
  imageSize: Size(750, 1667),
  containerSize: Size(400, 300),
  rotationDegrees: 45.0,
  cropParams: CropParams(x: 0, y: 0, width: 750, height: 1667),
  
  // 45度旋轉的預期結果需要通過數學計算
  expectedBehavior: "裁剪框應該是包圍旋轉後圖像的最小矩形",
  
  verificationRules: [
    "裁剪框必須完全包含旋轉後的圖像",
    "裁剪框不應該超出容器邊界",
    "控制點應該響應拖拽操作",
  ],
);
```

### 測試案例4：橫向圖像
```dart
TestCase test4_landscape_image = TestCase(
  name: "橫向圖像1920×1080旋轉90度",
  description: "測試橫向圖像的旋轉行為",
  
  imageSize: Size(1920, 1080),
  containerSize: Size(400, 300),
  rotationDegrees: 90.0,
  cropParams: CropParams(x: 0, y: 0, width: 1920, height: 1080),
  
  // 計算邏輯：
  // imageRatio = 1920/1080 = 1.7778
  // containerRatio = 400/300 = 1.3333
  // 因為 1.7778 > 1.3333，所以以寬度為準
  expectedRenderSize: Size(400, 225),  // (400, 400/1.7778)
  
  calculationNotes: "橫向圖像旋轉90度後變成縦向顯示",
);
```

### 測試案例5：正方形圖像
```dart
TestCase test5_square_image = TestCase(
  name: "正方形圖像800×800旋轉90度",
  description: "正方形圖像旋轉應該保持形狀",
  
  imageSize: Size(800, 800),
  containerSize: Size(400, 300),
  rotationDegrees: 90.0,
  cropParams: CropParams(x: 0, y: 0, width: 800, height: 800),
  
  expectedRenderSize: Size(300, 300),  // 以容器較小邊為準
  expectedCropRect: Rect.fromLTWH(50, 0, 300, 300),  // 居中顯示
  
  verificationRules: [
    "旋轉前後裁剪框應該保持正方形",
    "裁剪框位置應該保持居中",
  ],
);
```

### 測試案例6：部分裁剪
```dart
TestCase test6_partial_crop = TestCase(
  name: "750×1667圖像部分裁剪90度旋轉",
  description: "測試非全圖裁剪的旋轉行為",
  
  imageSize: Size(750, 1667),
  containerSize: Size(400, 300),
  rotationDegrees: 90.0,
  cropParams: CropParams(x: 100, y: 200, width: 500, height: 1000),
  
  calculationSteps: [
    "1. 計算未旋轉時的容器位置",
    "2. 應用Transform變換",
    "3. 驗證裁剪框對應原始圖像的正確區域",
  ],
);
```

### 測試案例7：180度旋轉
```dart
TestCase test7_180_rotation = TestCase(
  name: "750×1667圖像180度旋轉",
  description: "測試180度旋轉的對稱性",
  
  imageSize: Size(750, 1667),
  containerSize: Size(400, 300),
  rotationDegrees: 180.0,
  cropParams: CropParams(x: 0, y: 0, width: 750, height: 1667),
  
  symmetryTest: true,
  verificationRules: [
    "圖像尺寸應該與0度時相同",
    "位置應該保持居中（可能有細微旋轉效果）",
    "兩次180度旋轉應該回到原始狀態",
  ],
);
```

## 邊界情況測試

### 邊界測試案例1：極小容器
```dart
TestCase boundary1_tiny_container = TestCase(
  name: "大圖像在極小容器中旋轉",
  description: "測試極端尺寸比例的處理",
  
  imageSize: Size(2000, 3000),
  containerSize: Size(100, 80),
  rotationDegrees: 90.0,
  cropParams: CropParams(x: 0, y: 0, width: 2000, height: 3000),
  
  verificationRules: [
    "裁剪框不應該超出容器邊界",
    "控制點應該可見且可操作",
    "縮放比例應該正確計算",
  ],
);
```

### 邊界測試案例2：極小裁剪區域
```dart
TestCase boundary2_tiny_crop = TestCase(
  name: "極小裁剪區域旋轉",
  description: "測試1×1像素裁剪區域的行為",
  
  imageSize: Size(750, 1667),
  containerSize: Size(400, 300),
  rotationDegrees: 90.0,
  cropParams: CropParams(x: 375, y: 833, width: 1, height: 1),
  
  verificationRules: [
    "極小裁剪框應該可見",
    "控制點不應該重疊",
    "拖拽應該能夠擴大裁剪區域",
  ],
);
```

### 邊界測試案例3：角落裁剪
```dart
TestCase boundary3_corner_crop = TestCase(
  name: "角落裁剪區域旋轉",
  description: "測試圖像角落小區域的旋轉",
  
  imageSize: Size(750, 1667),
  containerSize: Size(400, 300),
  rotationDegrees: 90.0,
  cropParams: CropParams(x: 650, y: 1567, width: 100, height: 100),
  
  verificationRules: [
    "角落裁剪區域應該正確映射",
    "旋轉後位置應該對應原始位置的變換",
    "不應該超出有效範圍",
  ],
);
```

## 性能測試案例

### 性能測試1：大圖像
```dart
TestCase perf1_large_image = TestCase(
  name: "超大圖像4K旋轉性能",
  description: "測試大圖像的計算性能",
  
  imageSize: Size(3840, 2160),
  containerSize: Size(800, 600),
  rotationDegrees: 45.0,
  
  performanceRequirements: [
    "裁剪框計算時間 < 16ms（60fps）",
    "拖拽響應延遲 < 50ms",
    "內存使用增長 < 10%",
  ],
);
```

### 性能測試2：快速角度變化
```dart
TestCase perf2_rapid_rotation = TestCase(
  name: "快速角度變化性能",
  description: "測試角度快速變化時的性能",
  
  testSequence: [
    // 0度 → 90度 → 180度 → 270度 → 360度
    for (int angle = 0; angle <= 360; angle += 1) 
      RotationStep(angle: angle.toDouble(), maxDuration: Duration(milliseconds: 5)),
  ],
  
  performanceRequirements: [
    "每次角度變化計算 < 5ms",
    "無內存洩漏",
    "UI保持流暢",
  ],
);
```

## 測試執行框架

### 自動化測試工具
```dart
class CropOverlayTestRunner {
  static Future<TestResults> runAllTests() async {
    final results = TestResults();
    
    // 核心功能測試
    results.addResult(await runTest(test1_standard_90_rotation));
    results.addResult(await runTest(test2_no_rotation));
    results.addResult(await runTest(test3_45_degree_rotation));
    results.addResult(await runTest(test4_landscape_image));
    results.addResult(await runTest(test5_square_image));
    results.addResult(await runTest(test6_partial_crop));
    results.addResult(await runTest(test7_180_rotation));
    
    // 邊界情況測試
    results.addResult(await runTest(boundary1_tiny_container));
    results.addResult(await runTest(boundary2_tiny_crop));
    results.addResult(await runTest(boundary3_corner_crop));
    
    // 性能測試
    results.addResult(await runTest(perf1_large_image));
    results.addResult(await runTest(perf2_rapid_rotation));
    
    return results;
  }
  
  static Future<TestResult> runTest(TestCase testCase) async {
    try {
      // 執行計算
      final actualResult = calculateUnifiedCropRect(
        testCase.cropParams.x,
        testCase.cropParams.y,
        testCase.cropParams.width,
        testCase.cropParams.height,
        testCase.imageSize,
        testCase.containerSize,
        testCase.rotationDegrees,
      );
      
      // 驗證結果
      final verification = verifyResult(actualResult, testCase);
      
      return TestResult(
        testCase: testCase,
        actualResult: actualResult,
        verification: verification,
        passed: verification.allPassed,
      );
    } catch (e) {
      return TestResult(
        testCase: testCase,
        error: e,
        passed: false,
      );
    }
  }
}
```

### 手工測試清單

#### 視覺驗證清單
1. **載入750×1667圖像並旋轉90度**
   - [ ] 裁剪框緊貼圖像邊界
   - [ ] 8個控制點位置正確
   - [ ] 控制點可見且不重疊

2. **拖拽測試**
   - [ ] 拖拽右下角控制點，裁剪框正確調整
   - [ ] 拖拽頂部中間控制點，只有高度變化
   - [ ] 拖拽左側中間控制點，只有寬度變化

3. **角度變化測試**
   - [ ] 從90度緩慢旋轉到0度，裁剪框平滑變化
   - [ ] 快速點擊90度按鈕，裁剪框立即跳轉到正確位置

4. **不同圖像測試**
   - [ ] 載入橫向圖像（1920×1080），旋轉90度
   - [ ] 載入正方形圖像（800×800），旋轉45度

#### 數值驗證清單
1. **添加日誌輸出驗證**
   - [ ] renderSize計算結果：134.97×300
   - [ ] imagePosition計算結果：(132.515, 0)
   - [ ] 旋轉後裁剪框：(50, 82.515, 300, 134.97)

2. **控制點位置驗證**
   - [ ] 左上控制點：(50, 82.515)
   - [ ] 右下控制點：(350, 217.485)
   - [ ] 中心點：(200, 150)

## 成功標準定義

### 必須通過的標準
1. **核心案例**：test1_standard_90_rotation 必須100%通過
2. **回歸測試**：test2_no_rotation 必須保持原有功能
3. **視覺一致性**：所有角度的裁剪框都與圖像完美對齊
4. **操作響應**：拖拽控制點產生正確的坐標變化

### 可選通過的標準
1. **性能指標**：在合理範圍內，但不是阻塞條件
2. **極端邊界**：邊界情況可以有合理的降級處理
3. **精度要求**：小於1像素的誤差可以接受

### 測試報告格式
```
=== 裁剪框旋轉修復測試報告 ===

核心功能測試: 
✓ 標準90度旋轉: PASS (誤差 < 0.5px)
✓ 無旋轉回歸: PASS  
✓ 45度旋轉: PASS
✓ 橫向圖像: PASS
✓ 正方形圖像: PASS
✓ 部分裁剪: PASS
✓ 180度旋轉: PASS

邊界情況測試:
✓ 極小容器: PASS
⚠ 極小裁剪: PASS (控制點略小)
✓ 角落裁剪: PASS

性能測試:
✓ 大圖像性能: PASS (平均8ms)
✓ 快速角度變化: PASS

總結: 11/12 測試通過，1個警告
修復成功，可以交付用戶測試。
```

這套測試案例提供了完整的驗證框架，確保修復後的功能在各種情況下都能正常工作。