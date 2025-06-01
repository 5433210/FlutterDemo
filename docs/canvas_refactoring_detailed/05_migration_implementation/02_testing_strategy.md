# Canvas重构测试策略

## 1. 概述

本文档详细描述Canvas重构项目的测试策略，包括测试类型、测试范围、自动化测试框架和测试流程。良好的测试策略对于确保重构过程中功能完整性、性能优化和代码质量至关重要。

## 2. 测试目标

1. **功能等价性**：确保重构后的系统功能与原系统完全一致
2. **性能改进**：验证重构后的性能指标达到或超过预定目标
3. **代码质量**：保证重构代码符合设计标准和最佳实践
4. **兼容性**：确保兼容层正确支持现有API调用
5. **可靠性**：验证系统在各种条件下的稳定性和鲁棒性

## 3. 测试类型与策略

### 3.1 单元测试

**目标**：验证各个组件的独立功能正确性

#### 测试范围
- 核心接口实现
- 状态管理器
- 命令执行器
- 元素渲染器
- 事件处理器

#### 测试策略
- 采用Flutter `test` 包进行单元测试
- 使用模拟对象隔离依赖
- 覆盖正常路径和异常路径
- 对边界条件进行特别测试

#### 代码示例

```dart
// 命令执行测试
void main() {
  group('AddElementCommand Tests', () {
    late MockCanvasStateManager stateManager;
    late ElementData testElement;
    
    setUp(() {
      stateManager = MockCanvasStateManager();
      testElement = TextElementData(
        id: 'test-id',
        bounds: Rect.fromLTWH(10, 10, 100, 50),
        text: 'Test Text',
      );
    });
    
    test('execute adds element to state', () {
      // 准备
      final command = AddElementCommand(element: testElement);
      
      // 执行
      command.execute(stateManager);
      
      // 验证
      verify(stateManager.elementState.addElement(testElement)).called(1);
    });
    
    test('undo removes added element', () {
      // 准备
      final command = AddElementCommand(element: testElement);
      
      // 执行
      command.execute(stateManager);
      command.undo(stateManager);
      
      // 验证
      verify(stateManager.elementState.removeElement(testElement.id)).called(1);
    });
  });
}
```

### 3.2 集成测试

**目标**：验证组件之间的交互和功能协作

#### 测试范围
- 状态管理与命令系统交互
- 渲染引擎与状态变更响应
- 交互引擎与命令生成
- 事件系统与状态更新

#### 测试策略
- 使用真实组件组合进行测试
- 关注组件间接口契约
- 验证数据流通路径
- 测试异步操作和事件序列

#### 代码示例

```dart
void main() {
  group('State and Command Integration Tests', () {
    late CanvasStateManager stateManager;
    late CommandManager commandManager;
    
    setUp(() {
      stateManager = CanvasStateManager();
      commandManager = CommandManager(stateManager);
    });
    
    test('adding element through command updates state', () async {
      // 准备
      final element = TextElementData(
        id: 'test-id',
        bounds: Rect.fromLTWH(10, 10, 100, 50),
        text: 'Test Text',
      );
      final command = AddElementCommand(element: element);
      
      // 执行
      commandManager.executeCommand(command);
      
      // 验证
      expect(stateManager.elementState.getElementById(element.id), equals(element));
      expect(commandManager.canUndo, isTrue);
    });
    
    test('undoing command reverts state', () async {
      // 准备
      final element = TextElementData(
        id: 'test-id',
        bounds: Rect.fromLTWH(10, 10, 100, 50),
        text: 'Test Text',
      );
      final command = AddElementCommand(element: element);
      commandManager.executeCommand(command);
      
      // 执行
      commandManager.undo();
      
      // 验证
      expect(stateManager.elementState.getElementById(element.id), isNull);
      expect(commandManager.canUndo, isFalse);
      expect(commandManager.canRedo, isTrue);
    });
  });
}
```

### 3.3 Widget测试

**目标**：验证UI组件渲染和交互行为

#### 测试范围
- Canvas组件渲染
- 交互响应
- 动画效果
- 视觉布局

#### 测试策略
- 使用Flutter `testWidgets`框架
- 模拟用户交互
- 验证组件结构和层次
- 测试响应式行为

#### 代码示例

```dart
void main() {
  testWidgets('Canvas renders elements correctly', (WidgetTester tester) async {
    // 准备
    final element = TextElementData(
      id: 'test-id',
      bounds: Rect.fromLTWH(10, 10, 100, 50),
      text: 'Test Text',
    );
    
    final configuration = CanvasConfiguration(
      size: Size(500, 500),
      initialElements: [element],
    );
    
    // 构建组件
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Canvas(
          configuration: configuration,
        ),
      ),
    ));
    
    // 允许异步操作完成
    await tester.pumpAndSettle();
    
    // 验证
    expect(find.byType(CustomPaint), findsOneWidget);
    
    // 验证元素渲染（需要特殊处理，这里简化）
    final customPaint = tester.widget<CustomPaint>(find.byType(CustomPaint));
    final painter = customPaint.painter as CanvasPainter;
    expect(painter.stateManager.elementState.elements.length, equals(1));
  });
  
  testWidgets('Canvas responds to tap gesture', (WidgetTester tester) async {
    // 准备
    final element = TextElementData(
      id: 'test-id',
      bounds: Rect.fromLTWH(10, 10, 100, 50),
      text: 'Test Text',
    );
    
    final configuration = CanvasConfiguration(
      size: Size(500, 500),
      initialElements: [element],
    );
    
    final controller = CanvasController();
    
    // 构建组件
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Canvas(
          configuration: configuration,
          controller: controller,
        ),
      ),
    ));
    
    await tester.pumpAndSettle();
    
    // 执行点击
    await tester.tapAt(Offset(50, 30)); // 点击元素位置
    await tester.pumpAndSettle();
    
    // 验证选择状态
    expect(controller.stateManager.selectionState.selectedElementIds.length, equals(1));
    expect(controller.stateManager.selectionState.selectedElementIds.contains(element.id), isTrue);
  });
}
```

### 3.4 性能测试

**目标**：验证系统性能指标达到要求

#### 测试范围
- 渲染性能
- 内存使用
- 响应时间
- 资源加载
- 大规模数据处理

#### 测试策略
- 建立性能基准
- 使用Flutter DevTools分析
- 自动化性能测试用例
- 设置性能预算和阈值

#### 代码示例

```dart
void main() {
  group('Canvas Rendering Performance', () {
    late PerformanceTracker tracker;
    
    setUp(() {
      tracker = PerformanceTracker();
    });
    
    test('renders 1000 elements within performance budget', () async {
      // 准备
      final elements = List.generate(1000, (index) => 
        TextElementData(
          id: 'element-$index',
          bounds: Rect.fromLTWH(
            (index % 50) * 20.0, 
            (index ~/ 50) * 20.0, 
            10, 
            10
          ),
          text: '$index',
        )
      );
      
      final configuration = CanvasConfiguration(
        size: Size(1000, 1000),
        initialElements: elements,
      );
      
      final stateManager = CanvasStateManager();
      stateManager.applyConfiguration(configuration);
      
      final renderingEngine = CanvasRenderingEngine(stateManager);
      
      // 执行性能测试
      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);
      
      tracker.start();
      renderingEngine.render(canvas, Size(1000, 1000));
      final duration = tracker.stop();
      
      // 验证性能在预算范围内
      expect(duration.inMilliseconds, lessThan(16)); // 60fps 要求
    });
    
    test('memory consumption stays within limits', () async {
      // 内存使用测试
      final memoryInfo = await getMemoryInfo();
      final startMemory = memoryInfo.usedHeap;
      
      // 创建和渲染大量元素
      final elements = List.generate(5000, (index) => 
        TextElementData(
          id: 'element-$index',
          bounds: Rect.fromLTWH(
            (index % 100) * 10.0, 
            (index ~/ 100) * 10.0, 
            8, 
            8
          ),
          text: '$index',
        )
      );
      
      final stateManager = CanvasStateManager();
      stateManager.elementState.addElements(elements);
      
      final memoryAfterElements = (await getMemoryInfo()).usedHeap;
      
      // 验证内存增长在合理范围内
      final memoryGrowth = memoryAfterElements - startMemory;
      expect(memoryGrowth, lessThan(50 * 1024 * 1024)); // 50MB 限制
    });
  });
}
```

### 3.5 端到端测试

**目标**：验证完整用户场景和工作流程

#### 测试范围
- 主要用户旅程
- 跨组件工作流
- 真实场景模拟
- UI和逻辑交互

#### 测试策略
- 使用Flutter Integration Test框架
- 自动化用户操作序列
- 验证结果和状态
- 跨设备测试

#### 代码示例

```dart
// integration_test/canvas_workflow_test.dart
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Complete drawing workflow test', (WidgetTester tester) async {
    // 启动应用
    app.main();
    await tester.pumpAndSettle();
    
    // 创建新画布
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();
    
    // 添加文本元素
    await tester.tap(find.byIcon(Icons.text_fields));
    await tester.pumpAndSettle();
    await tester.tapAt(Offset(100, 100));
    await tester.pumpAndSettle();
    
    // 输入文本
    await tester.enterText(find.byType(TextField), 'Hello Canvas');
    await tester.tap(find.text('确定'));
    await tester.pumpAndSettle();
    
    // 验证元素已创建
    expect(find.text('Hello Canvas'), findsOneWidget);
    
    // 选择元素
    await tester.tapAt(Offset(100, 100));
    await tester.pumpAndSettle();
    
    // 移动元素
    final startLocation = tester.getCenter(find.text('Hello Canvas'));
    final gesture = await tester.startGesture(startLocation);
    await gesture.moveBy(Offset(50, 50));
    await tester.pump(Duration(milliseconds: 100));
    await gesture.up();
    await tester.pumpAndSettle();
    
    // 验证元素已移动
    final newLocation = tester.getCenter(find.text('Hello Canvas'));
    expect(newLocation - startLocation, equals(Offset(50, 50)));
    
    // 保存画布
    await tester.tap(find.byIcon(Icons.save));
    await tester.pumpAndSettle();
    
    // 验证保存对话框
    expect(find.text('保存成功'), findsOneWidget);
  });
}
```

### 3.6 兼容性测试

**目标**：确保迁移过程中的API兼容性

#### 测试范围
- 旧API调用
- 兼容层函数
- 数据转换
- 行为一致性

#### 测试策略
- 创建旧API使用示例
- 验证通过兼容层的行为一致
- 测试边缘情况和复杂交互
- 对比旧系统和新系统结果

#### 代码示例

```dart
void main() {
  group('API Compatibility Tests', () {
    test('legacy canvas controller operations work through adapter', () {
      // 准备
      final legacyController = LegacyCanvasControllerAdapter();
      final element = TextElement(
        id: 'legacy-element',
        bounds: Rect.fromLTWH(10, 10, 100, 50),
        text: 'Legacy Text',
      );
      
      // 执行旧API调用
      legacyController.addElement(element);
      legacyController.selectElement(element.id);
      
      // 验证
      final stateManager = legacyController.getInternalStateManager();
      expect(stateManager.elementState.elements.length, equals(1));
      expect(stateManager.selectionState.selectedElementIds.contains(element.id), isTrue);
      
      // 测试旧API移动操作
      final originalBounds = element.bounds;
      legacyController.moveElement(element.id, Offset(20, 30));
      
      // 验证结果
      final updatedElement = stateManager.elementState.getElementById(element.id);
      expect(updatedElement!.bounds, equals(originalBounds.translate(20, 30)));
    });
    
    test('legacy canvas widget renders content correctly', () async {
      // 准备
      final elements = [
        TextElement(
          id: 'legacy-text',
          bounds: Rect.fromLTWH(10, 10, 100, 50),
          text: 'Legacy Text',
        ),
        RectangleElement(
          id: 'legacy-rect',
          bounds: Rect.fromLTWH(50, 50, 200, 100),
          color: Colors.blue,
        )
      ];
      
      // 使用适配器渲染
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: LegacyCanvasAdapter(
            elements: elements,
            size: Size(500, 500),
          ),
        ),
      ));
      
      await tester.pumpAndSettle();
      
      // 验证渲染结果（简化验证）
      final legacyAdapter = tester.widget<LegacyCanvasAdapter>(
        find.byType(LegacyCanvasAdapter)
      );
      final canvas = find.descendant(
        of: find.byWidget(legacyAdapter),
        matching: find.byType(Canvas),
      );
      
      expect(canvas, findsOneWidget);
      
      // 对比渲染结果
      final canvasState = tester.state<_CanvasState>(canvas);
      expect(canvasState.stateManager.elementState.elements.length, equals(2));
    });
  });
}
```

## 4. 测试环境与工具

### 4.1 测试环境配置

**开发环境测试**
- 本地开发机器
- Flutter SDK最新稳定版
- 模拟器和真机测试
- 各种屏幕尺寸配置

**持续集成环境**
- GitHub Actions / CircleCI
- 自动化测试管道
- 每次提交触发单元和集成测试
- 定期性能和压力测试

**生产前验证环境**
- 与生产环境配置相似
- 完整端到端测试
- 性能和负载测试
- 兼容性测试

### 4.2 测试工具

**测试框架**
- Flutter Test：单元和Widget测试
- Flutter Integration Test：端到端测试
- Flutter Driver：性能测试

**性能工具**
- Flutter DevTools：性能分析
- 自定义性能跟踪器
- 帧率监控工具
- 内存分析工具

**代码覆盖率**
- lcov：覆盖率数据收集
- Flutter Coverage：覆盖率报告生成
- 覆盖率门槛检查

**模拟和测试数据**
- Mockito：依赖模拟
- Fake实现：特定组件替换
- 测试数据生成器

## 5. 测试流程与规范

### 5.1 测试驱动开发流程

1. **需求分析与测试规划**
   - 基于功能需求确定测试范围
   - 定义验收标准
   - 设计测试用例

2. **测试编写**
   - 先编写测试用例
   - 确保测试初始失败
   - 明确测试预期结果

3. **功能实现**
   - 编写满足测试的最小代码
   - 重构以改进设计
   - 确保所有测试通过

4. **代码审查**
   - 审查测试覆盖率
   - 检查边界条件测试
   - 审查测试质量和可维护性

5. **持续集成**
   - 自动化测试执行
   - 每次提交运行测试
   - 验证测试稳定性

### 5.2 测试规范

**命名规范**
- 测试文件：`{target}_test.dart`
- 测试组：描述被测试的组件或功能
- 测试用例：描述预期行为和条件

**结构规范**
- 使用`group`组织相关测试
- 使用`setUp`和`tearDown`管理测试状态
- 测试用例结构：准备(Arrange)、执行(Act)、验证(Assert)

**断言规范**
- 每个测试应有明确断言
- 使用精确的断言消息
- 验证预期结果而非实现细节

**覆盖率标准**
- 代码覆盖率目标：80%以上
- 核心模块覆盖率目标：90%以上
- 包括正常路径和异常路径

## 6. 测试计划与里程碑

### 6.1 测试阶段

| 阶段 | 持续时间 | 测试类型 | 成功标准 |
|------|----------|----------|----------|
| 第一阶段 | 4周 | 单元测试、基础集成测试 | 核心接口测试覆盖率≥90% |
| 第二阶段 | 6周 | 渲染与状态测试、性能基准 | 渲染引擎测试覆盖率≥85%，性能达标 |
| 第三阶段 | 6周 | 交互测试、命令系统测试 | 交互引擎测试覆盖率≥85% |
| 第四阶段 | 4周 | 兼容性测试、端到端测试 | 兼容性测试通过率100%，总覆盖率≥80% |

### 6.2 测试里程碑

1. **测试框架搭建完成**
   - 单元测试基础架构
   - 模拟对象和测试工具
   - CI集成

2. **核心组件测试完成**
   - 状态管理器测试
   - 命令系统测试
   - 数据模型测试

3. **引擎层测试完成**
   - 渲染引擎测试
   - 交互引擎测试
   - 性能基准测试

4. **API与兼容层测试完成**
   - 兼容性适配器测试
   - 公共API测试
   - 端到端场景测试

5. **回归测试完成**
   - 全面功能回归
   - 性能验证
   - 用户体验确认

## 7. 测试成果与报告

### 7.1 测试文档

- 测试计划
- 测试用例文档
- 测试覆盖率报告
- 性能测试报告
- 兼容性测试报告

### 7.2 测试数据

- 测试覆盖率数据
- 性能测试数据
- 内存使用数据
- 兼容性测试矩阵

### 7.3 测试报告内容

- 测试执行摘要
- 测试覆盖率分析
- 未解决问题列表
- 性能测试结果
- 兼容性测试结果
- 测试建议和改进措施
