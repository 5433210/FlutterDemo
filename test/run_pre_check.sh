#!/bin/bash

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}开始环境检查...${NC}"

# 1. 验证环境
dart run test/utils/environment_validator.dart
if [ $? -ne 0 ]; then
    echo -e "${RED}环境验证失败${NC}"
    echo -e "${YELLOW}尝试自动修复...${NC}"
    
    dart run test/utils/environment_validator.dart --fix
    if [ $? -ne 0 ]; then
        echo -e "${RED}自动修复失败，请手动检查环境配置${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}自动修复完成${NC}"
fi

# 2. 创建日志目录
mkdir -p test/logs/archive
mkdir -p test/reports
mkdir -p coverage/reports
mkdir -p test/benchmark/results

# 3. 归档旧日志
timestamp=$(date +%Y%m%d_%H%M%S)
if [ -f "test/logs/system_check.log" ]; then
    mv test/logs/system_check.log "test/logs/archive/system_check_$timestamp.log"
fi

# 4. 清理过期报告
find test/reports -type f -mtime +7 -exec rm {} \;
find coverage/reports -type f -mtime +7 -exec rm {} \;

# 5. 检查磁盘空间
disk_space=$(df -m . | tail -1 | awk '{print $4}')
if [ $disk_space -lt 1024 ]; then
    echo -e "${RED}警告: 可用磁盘空间不足 (${disk_space}MB)${NC}"
    echo -e "${YELLOW}建议至少保留 1GB 空间${NC}"
    read -p "是否继续? [y/N] " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# 6. 备份关键文件
backup_dir="test/backup/$(date +%Y%m%d)"
mkdir -p "$backup_dir"
for file in pubspec.yaml test/README.md .github/workflows/test.yml; do
    if [ -f "$file" ]; then
        cp "$file" "$backup_dir/"
    fi
done

# 7. 检查依赖项
echo -e "${YELLOW}检查依赖项...${NC}"
missing_deps=0

check_command() {
    if ! command -v $1 &> /dev/null; then
        echo -e "${RED}未找到命令: $1${NC}"
        missing_deps=$((missing_deps + 1))
    fi
}

check_command dart
check_command git
check_command lcov

if [ $missing_deps -gt 0 ]; then
    echo -e "${RED}缺少必要的依赖项${NC}"
    exit 1
fi

# 8. 验证 Dart 包
echo -e "${YELLOW}验证 Dart 包...${NC}"
dart pub get
if [ $? -ne 0 ]; then
    echo -e "${RED}包依赖验证失败${NC}"
    exit 1
fi

# 9. 检查代码格式
echo -e "${YELLOW}检查代码格式...${NC}"
dart format --output=none --set-exit-if-changed .
if [ $? -ne 0 ]; then
    echo -e "${RED}代码格式检查失败${NC}"
    read -p "是否自动格式化代码? [y/N] " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        dart format .
    else
        exit 1
    fi
fi

# 10. 运行静态分析
echo -e "${YELLOW}运行静态分析...${NC}"
dart analyze
if [ $? -ne 0 ]; then
    echo -e "${RED}静态分析发现问题${NC}"
    exit 1
fi

echo -e "${GREEN}预检查完成！${NC}"
echo "- 环境验证: 通过"
echo "- 日志归档: 完成"
echo "- 空间检查: 通过"
echo "- 依赖检查: 通过"
echo "- 代码检查: 通过"

exit 0