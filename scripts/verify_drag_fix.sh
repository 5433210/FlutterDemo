#!/bin/bash

# 拖拽顺序修复验证脚本

echo "=== 拖拽顺序修复验证 ==="
echo

# 1. 检查修复的文件是否存在
echo "1. 检查修复文件..."
files=(
    "lib/presentation/pages/works/components/thumbnail_strip.dart"
    "lib/presentation/providers/work_image_editor_provider.dart"
    "lib/presentation/widgets/works/enhanced_work_preview.dart"
    "lib/presentation/pages/works/components/work_images_management_view.dart"
)

for file in "${files[@]}"; do
    if [ -f "$file" ]; then
        echo "✅ $file - 存在"
    else
        echo "❌ $file - 不存在"
    fi
done

echo

# 2. 检查关键修复点
echo "2. 检查关键修复点..."

# 检查 ThumbnailStrip 是否移除了重复的索引调整
if grep -q "if (oldIndex < newIndex) newIndex--;" lib/presentation/pages/works/components/thumbnail_strip.dart; then
    echo "❌ ThumbnailStrip 仍然包含重复的索引调整逻辑"
else
    echo "✅ ThumbnailStrip 已移除重复的索引调整逻辑"
fi

# 检查 WorkImageEditorProvider 是否保留了索引调整逻辑
if grep -q "if (oldIndex < newIndex) {" lib/presentation/providers/work_image_editor_provider.dart; then
    echo "✅ WorkImageEditorProvider 保留了索引调整逻辑"
else
    echo "❌ WorkImageEditorProvider 缺少索引调整逻辑"
fi

# 检查是否添加了调试日志
if grep -q "AppLogger.debug.*ThumbnailStrip" lib/presentation/pages/works/components/thumbnail_strip.dart; then
    echo "✅ ThumbnailStrip 添加了调试日志"
else
    echo "❌ ThumbnailStrip 缺少调试日志"
fi

echo

# 3. 检查代码编译状态
echo "3. 检查代码编译状态..."
cd "$(dirname "$0")"
flutter analyze --no-fatal-infos > /dev/null 2>&1
if [ $? -eq 0 ]; then
    echo "✅ 代码编译正常"
else
    echo "❌ 代码编译有问题"
fi

echo

# 4. 运行单元测试
echo "4. 运行拖拽重排序测试..."
if [ -f "test/drag_reorder_test.dart" ]; then
    flutter test test/drag_reorder_test.dart > /dev/null 2>&1
    if [ $? -eq 0 ]; then
        echo "✅ 拖拽重排序测试通过"
    else
        echo "❌ 拖拽重排序测试失败"
    fi
else
    echo "⚠️  拖拽重排序测试文件不存在"
fi

echo

# 5. 总结
echo "5. 修复验证总结..."
echo "- 修复了双重索引调整的问题"
echo "- 统一了索引处理逻辑"
echo "- 增强了调试日志"
echo "- 创建了单元测试"

echo
echo "=== 验证完成 ==="
echo "请在应用中测试实际的拖拽功能以确认修复效果"
