#!/bin/bash

# M3Canvas 性能优化项目启动脚本
# 使用方法: ./start_work.sh [task_number]

set -e

echo "🚀 M3Canvas 性能优化项目启动"
echo "================================"

# 检查参数
TASK_NUMBER=${1:-""}
if [ -z "$TASK_NUMBER" ]; then
    echo "❌ 请指定任务编号，例如: ./start_work.sh 1.1"
    echo ""
    echo "📋 可用任务:"
    echo "  1.1 - 元素级RepaintBoundary优化"
    echo "  1.2 - 拖拽状态分离系统" 
    echo "  1.3 - 性能监控系统"
    echo "  2.1 - 元素缓存管理器"
    echo "  2.2 - 视口优化系统"
    exit 1
fi

echo "🎯 启动任务: $TASK_NUMBER"
echo ""

# 1. 环境检查
echo "🔍 环境检查..."

# 检查Flutter
if ! command -v flutter &> /dev/null; then
    echo "❌ Flutter未安装或未在PATH中"
    exit 1
fi

FLUTTER_VERSION=$(flutter --version | head -n 1)
echo "✅ Flutter版本: $FLUTTER_VERSION"

# 检查项目目录
if [ ! -f "pubspec.yaml" ]; then
    echo "❌ 不在Flutter项目根目录"
    exit 1
fi

echo "✅ 项目目录正确"

# 2. 代码状态检查
echo ""
echo "📂 代码状态检查..."

# Git状态
GIT_STATUS=$(git status --porcelain)
if [ ! -z "$GIT_STATUS" ]; then
    echo "⚠️  有未提交的变更:"
    git status --short
    echo ""
    read -p "是否继续？ (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
else
    echo "✅ Git状态清洁"
fi

# 当前分支
CURRENT_BRANCH=$(git branch --show-current)
echo "✅ 当前分支: $CURRENT_BRANCH"

# 3. 依赖包检查
echo ""
echo "📦 依赖包检查..."
flutter pub get > /dev/null 2>&1
echo "✅ 依赖包更新完成"

# 4. 编译检查
echo ""
echo "🔨 编译检查..."
if flutter analyze --no-fatal-infos > /dev/null 2>&1; then
    echo "✅ 代码分析通过"
else
    echo "⚠️  代码分析发现问题:"
    flutter analyze --no-fatal-infos
    echo ""
    read -p "是否继续？ (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# 5. 基线数据收集
echo ""
echo "📊 收集基线数据..."

# 创建基线数据目录
mkdir -p docs/performance_data
BASELINE_FILE="docs/performance_data/baseline_$(date +%Y%m%d_%H%M%S).md"

cat > "$BASELINE_FILE" << EOF
# 性能基线数据

**采集时间**: $(date '+%Y-%m-%d %H:%M:%S')
**任务编号**: $TASK_NUMBER
**Git提交**: $(git rev-parse --short HEAD)
**Flutter版本**: $FLUTTER_VERSION

## 设备信息
- **设备**: [待填写]
- **系统版本**: [待填写]
- **内存**: [待填写]

## 性能数据
### 当前FPS
- **拖拽操作**: [待测量] fps
- **缩放操作**: [待测量] fps  
- **旋转操作**: [待测量] fps
- **选择操作**: [待测量] fps

### 内存使用
- **初始内存**: [待测量] MB
- **操作后内存**: [待测量] MB
- **峰值内存**: [待测量] MB

### 响应时间
- **点击响应**: [待测量] ms
- **拖拽开始**: [待测量] ms
- **属性更新**: [待测量] ms

## 测试步骤
1. 启动应用到编辑页面
2. 执行标准操作序列
3. 记录各项性能指标
4. 注意观察卡顿现象

## 备注
[记录任何特殊现象或问题]
EOF

echo "✅ 基线数据文件创建: $BASELINE_FILE"

# 6. 任务相关文件检查
echo ""
echo "📁 任务相关文件检查..."

case $TASK_NUMBER in
    "1.1")
        echo "🎯 任务1.1: 元素级RepaintBoundary优化"
        FILES=(
            "lib/presentation/pages/practices/widgets/content_render_layer.dart"
            "lib/presentation/pages/practices/widgets/m3_practice_edit_canvas.dart"
        )
        ;;
    "1.2")
        echo "🎯 任务1.2: 拖拽状态分离系统"
        FILES=(
            "lib/presentation/widgets/practice/practice_edit_controller.dart"
            "lib/presentation/pages/practices/widgets/m3_practice_edit_canvas.dart"
        )
        # 创建新文件占位符
        mkdir -p lib/presentation/widgets/practice
        if [ ! -f "lib/presentation/widgets/practice/drag_state_manager.dart" ]; then
            echo "// TODO: 实现DragStateManager" > lib/presentation/widgets/practice/drag_state_manager.dart
        fi
        ;;
    "1.3")
        echo "🎯 任务1.3: 性能监控系统"
        FILES=(
            "lib/presentation/pages/practices/widgets/m3_practice_edit_canvas.dart"
        )
        # 创建新文件占位符
        mkdir -p lib/presentation/widgets/practice
        if [ ! -f "lib/presentation/widgets/practice/performance_monitor.dart" ]; then
            echo "// TODO: 实现PerformanceMonitor" > lib/presentation/widgets/practice/performance_monitor.dart
        fi
        ;;
    *)
        echo "⚠️  未知任务编号: $TASK_NUMBER"
        FILES=()
        ;;
esac

for file in "${FILES[@]}"; do
    if [ -f "$file" ]; then
        echo "✅ 找到文件: $file"
    else
        echo "❌ 文件不存在: $file"
    fi
done

# 7. 开发环境准备
echo ""
echo "🛠️  开发环境准备..."

# 启动设备检查
DEVICES=$(flutter devices --machine 2>/dev/null | jq -r '.[] | select(.type != "web") | .name' 2>/dev/null || echo "")
if [ ! -z "$DEVICES" ]; then
    echo "✅ 发现测试设备:"
    echo "$DEVICES" | while read device; do
        echo "   - $device"
    done
else
    echo "⚠️  未发现可用测试设备"
fi

# 8. 性能工具准备
echo ""
echo "📈 性能工具准备..."

# 创建性能测试目录
mkdir -p test/performance

# 创建性能测试模板（如果不存在）
PERF_TEST_FILE="test/performance/task_${TASK_NUMBER//./_}_test.dart"
if [ ! -f "$PERF_TEST_FILE" ]; then
    cat > "$PERF_TEST_FILE" << EOF
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

/// 任务 $TASK_NUMBER 性能测试
/// 
/// 测试目标:
/// - 验证性能优化效果
/// - 确保功能正确性
/// - 记录性能指标
void main() {
  group('任务 $TASK_NUMBER 性能测试', () {
    testWidgets('基础性能测试', (WidgetTester tester) async {
      // TODO: 实现具体测试用例
      
      // 1. 构建测试环境
      
      // 2. 执行测试操作
      
      // 3. 验证性能指标
      
      // 4. 检查功能正确性
    });
    
    testWidgets('压力测试', (WidgetTester tester) async {
      // TODO: 实现压力测试用例
    });
    
    testWidgets('内存泄漏测试', (WidgetTester tester) async {
      // TODO: 实现内存测试用例
    });
  });
}
EOF
    echo "✅ 创建性能测试文件: $PERF_TEST_FILE"
fi

# 9. 创建工作日志
echo ""
echo "📝 创建工作日志..."

WORK_LOG_DIR="docs/work_logs"
mkdir -p "$WORK_LOG_DIR"
WORK_LOG_FILE="$WORK_LOG_DIR/task_${TASK_NUMBER//./_}_$(date +%Y%m%d).md"

cat > "$WORK_LOG_FILE" << EOF
# 任务 $TASK_NUMBER 工作日志

**日期**: $(date '+%Y-%m-%d')
**任务**: $TASK_NUMBER
**开始时间**: $(date '+%H:%M:%S')

## 🎯 任务目标
[描述具体要实现的功能和性能目标]

## 📋 工作计划
- [ ] [具体步骤1]
- [ ] [具体步骤2]
- [ ] [具体步骤3]

## 💻 实际进展

### $(date '+%H:%M') - 开始工作
- 环境检查完成
- 基线数据收集
- 准备工作完成

### [时间] - [阶段描述]
- [具体工作内容]
- [遇到的问题]
- [解决方案]

## 📊 性能数据记录
### 优化前基线
- FPS: [数据]
- 内存: [数据]
- 响应时间: [数据]

### 优化后结果
- FPS: [数据] (提升: [百分比])
- 内存: [数据] (优化: [百分比])
- 响应时间: [数据] (改善: [百分比])

## 🚨 问题记录
1. **[问题描述]**: [解决方案]
2. **[问题描述]**: [解决方案]

## ✅ 完成检查清单
- [ ] 功能实现完成
- [ ] 性能目标达成
- [ ] 测试用例通过
- [ ] 代码审查完成
- [ ] 文档更新完成

## 📝 总结和下一步
[工作总结和后续计划]

---
结束时间: [填写]
总耗时: [填写]
EOF

echo "✅ 创建工作日志: $WORK_LOG_FILE"

# 10. 最终准备
echo ""
echo "🎉 准备完成！"
echo ""
echo "📋 下一步操作:"
echo "1. 打开IDE或编辑器"
echo "2. 查看任务详情: docs/m3_canvas_task_tracker.md"
echo "3. 参考日常检查: docs/m3_canvas_daily_checklist.md"
echo "4. 开始编码实现"
echo "5. 记录工作日志: $WORK_LOG_FILE"
echo ""
echo "🔗 重要文件链接:"
echo "  - 任务跟踪: docs/m3_canvas_task_tracker.md"
echo "  - 工作日志: $WORK_LOG_FILE"
echo "  - 基线数据: $BASELINE_FILE"
echo "  - 性能测试: $PERF_TEST_FILE"
echo ""
echo "⚡ 快速启动命令:"
echo "  flutter run --profile  # 性能模式运行"
echo "  flutter test $PERF_TEST_FILE  # 运行性能测试"
echo "  flutter analyze  # 代码分析"
echo ""
echo "💡 记住: 每个小的改动都要及时测试和记录！"
echo ""
echo "🚀 开始工作吧！祝开发顺利！"
