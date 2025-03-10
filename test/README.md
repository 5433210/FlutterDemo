# 测试指南

## 测试架构

本项目包含以下测试层级：

1. 单元测试
   - 警报系统测试
   - 配置测试
   - 工具类测试

2. 集成测试
   - 系统集成测试
   - 模块交互测试

3. 性能测试
   - 基准测试
   - 压力测试

## 运行测试

### Linux/MacOS

```bash
# 运行所有测试
./test/run_tests.sh

# 只运行单元测试
dart test test/utils/

# 只运行集成测试
dart test test/integration/
```

### Windows

```batch
# 运行所有测试
test\run_tests.bat

# 只运行单元测试
dart test test\utils\

# 只运行集成测试
dart test test\integration\
```

## 覆盖率要求

- 单元测试覆盖率：>=80%
- 集成测试覆盖率：>=60%
- 总体覆盖率：>=75%

## 测试报告

测试完成后会生成以下报告：

1. 覆盖率报告
   - 位置：`coverage/reports/`
   - 格式：HTML和LCOV
   - 包含：每个文件的详细覆盖率信息

2. 测试结果报告
   - 位置：`test/reports/`
   - 格式：JSON和文本
   - 包含：测试用例执行结果和错误信息

3. 性能测试报告
   - 位置：`test/benchmark/results/`
   - 格式：JSON
   - 包含：性能指标和基准测试结果

## 持续集成

项目使用GitHub Actions进行持续集成，配置文件位于：`.github/workflows/test.yml`

每次提交会自动运行：

- 代码分析
- 单元测试
- 集成测试
- 覆盖率检查
- 性能回归测试

## 调试测试

### VSCode中调试

1. 打开测试文件
2. 在测试用例旁边点击"运行测试"或"调试测试"按钮
3. 使用断点进行调试

### 命令行调试

```bash
# 开启观察模式
dart test --pause-on-failure

# 打印详细日志
dart test -r expanded --verbose
```

## 编写测试

### 目录结构

```
test/
├── utils/            # 单元测试
├── integration/      # 集成测试
├── benchmark/        # 性能测试
├── coverage/        # 覆盖率报告
└── reports/         # 测试报告
```

### 测试命名约定

- 单元测试：`*_test.dart`
- 集成测试：`*_integration_test.dart`
- 性能测试：`*_benchmark_test.dart`

### 辅助工具

- `test/utils/check_logger.dart` - 日志记录
- `test/utils/test_data_helper.dart` - 测试数据管理
- `test/coverage/coverage_helper.dart` - 覆盖率分析

## 常见问题

1. 测试失败时获取更多信息

```bash
dart test --verbose test/failing_test.dart
```

2. 清理测试状态

```bash
# 清理测试缓存
rm -rf .dart_tool/test
# 清理覆盖率数据
rm -rf coverage/
```

3. 更新测试快照

```bash
dart test --update-goldens
```

## 参与贡献

1. Fork 项目
2. 创建特性分支
3. 编写测试用例
4. 提交变更
5. 创建Pull Request

请确保：

- 所有测试都通过
- 覆盖率符合要求
- 遵循代码规范
- 更新相关文档
