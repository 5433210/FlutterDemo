#!/bin/bash

# 颜色定义
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# 检查状态并打印
check_status() {
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ $1${NC}"
    else
        echo -e "${RED}✗ $1${NC}"
        exit 1
    fi
}

echo -e "${YELLOW}检查测试环境...${NC}\n"

# 1. 检查Flutter环境
echo "检查 Flutter 安装..."
flutter --version > /dev/null 2>&1
check_status "Flutter 已安装"

# 2. 检查依赖
echo "检查项目依赖..."
flutter pub get
check_status "依赖安装正确"

# 3. 检查SQLite
echo "检查 SQLite..."
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
    brew list sqlite3 > /dev/null 2>&1 || brew install sqlite3
    check_status "SQLite 已安装 (macOS)"
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    # Linux
    which sqlite3 > /dev/null 2>&1 || sudo apt-get install -y sqlite3
    check_status "SQLite 已安装 (Linux)"
else
    # Windows (使用 sqflite_common_ffi)
    echo -e "${YELLOW}Windows 平台使用 sqflite_common_ffi，无需额外安装 SQLite${NC}"
fi

# 4. 创建测试数据目录
echo "创建测试数据目录..."
mkdir -p test/data
chmod 777 test/data
check_status "测试数据目录已创建"

# 5. 检查编译器
echo "检查 Dart 编译器..."
dart --version > /dev/null 2>&1
check_status "Dart 编译器正常"

# 6. 检查覆盖率工具
echo "检查覆盖率工具..."
if ! command -v genhtml &> /dev/null; then
    if [[ "$OSTYPE" == "darwin"* ]]; then
        brew install lcov
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        sudo apt-get install -y lcov
    fi
fi
check_status "覆盖率工具已安装"

# 7. 清理旧的测试数据
echo "清理旧的测试数据..."
rm -rf coverage/*
rm -rf test/data/*
check_status "测试数据已清理"

echo -e "\n${GREEN}环境检查完成，可以开始运行测试${NC}"