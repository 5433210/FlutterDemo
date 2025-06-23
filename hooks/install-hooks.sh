#!/bin/bash
# Git钩子安装脚本
# 将项目中的钩子文件安装到.git/hooks目录

set -e

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔧 安装Git钩子...${NC}"

# 检查是否在Git仓库中
if [ ! -d ".git" ]; then
    echo -e "${RED}❌ 错误: 不在Git仓库根目录${NC}"
    exit 1
fi

# 检查hooks目录是否存在
if [ ! -d "hooks" ]; then
    echo -e "${RED}❌ 错误: hooks目录不存在${NC}"
    exit 1
fi

# 创建.git/hooks目录（如果不存在）
mkdir -p .git/hooks

# 钩子文件列表
HOOKS=("pre-commit" "pre-push")

# 安装钩子
for hook in "${HOOKS[@]}"; do
    if [ -f "hooks/$hook" ]; then
        echo -e "${BLUE}📋 安装钩子: $hook${NC}"
        
        # 备份现有钩子（如果存在）
        if [ -f ".git/hooks/$hook" ]; then
            echo -e "${YELLOW}⚠️ 备份现有钩子: $hook.backup${NC}"
            cp ".git/hooks/$hook" ".git/hooks/$hook.backup"
        fi
        
        # 复制钩子文件
        cp "hooks/$hook" ".git/hooks/$hook"
        
        # 设置执行权限
        chmod +x ".git/hooks/$hook"
        
        echo -e "${GREEN}✅ 钩子 $hook 安装成功${NC}"
    else
        echo -e "${YELLOW}⚠️ 警告: 钩子文件 hooks/$hook 不存在${NC}"
    fi
done

# 验证安装
echo -e "${BLUE}🔍 验证钩子安装...${NC}"
for hook in "${HOOKS[@]}"; do
    if [ -f ".git/hooks/$hook" ] && [ -x ".git/hooks/$hook" ]; then
        echo -e "${GREEN}✅ $hook: 已安装且可执行${NC}"
    else
        echo -e "${RED}❌ $hook: 安装失败或不可执行${NC}"
    fi
done

# 显示使用说明
echo -e "${BLUE}📋 Git钩子使用说明:${NC}"
echo -e "${BLUE}  - pre-commit: 在每次提交前自动运行版本检查${NC}"
echo -e "${BLUE}  - pre-push: 在推送前运行版本验证和构建测试${NC}"
echo -e "${BLUE}  - 如需跳过钩子检查，可使用 --no-verify 参数${NC}"
echo -e "${BLUE}    例如: git commit --no-verify${NC}"

# 测试钩子是否能正常运行
echo -e "${BLUE}🧪 测试钩子环境...${NC}"

# 检查Python环境
if command -v python &> /dev/null; then
    echo -e "${GREEN}✅ Python环境: $(python --version)${NC}"
else
    echo -e "${RED}❌ Python环境未找到${NC}"
fi

# 检查Flutter环境
if command -v flutter &> /dev/null; then
    echo -e "${GREEN}✅ Flutter环境: $(flutter --version | head -1)${NC}"
else
    echo -e "${YELLOW}⚠️ Flutter环境未找到（部分钩子功能可能受限）${NC}"
fi

# 检查版本管理脚本
if [ -f "scripts/check_version_consistency.py" ]; then
    echo -e "${GREEN}✅ 版本检查脚本存在${NC}"
else
    echo -e "${YELLOW}⚠️ 版本检查脚本不存在${NC}"
fi

echo -e "${GREEN}🎉 Git钩子安装完成！${NC}"
echo -e "${BLUE}💡 提示: 团队成员需要运行此脚本来安装钩子${NC}" 