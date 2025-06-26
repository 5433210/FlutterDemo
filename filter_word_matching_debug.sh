#!/bin/bash
# 词匹配模式调试日志过滤脚本
# 使用方法: flutter run -d windows --debug 2>&1 | bash filter_word_matching_debug.sh

echo "=== 词匹配模式调试日志过滤器 ==="
echo "正在监听包含 [WORD_MATCHING_DEBUG] 的日志..."
echo "==========================================="

# 使用grep过滤包含关键字的行，并添加时间戳
while IFS= read -r line; do
    if [[ "$line" == *"[WORD_MATCHING_DEBUG]"* ]]; then
        timestamp=$(date "+%H:%M:%S")
        echo "[$timestamp] $line"
    fi
done
