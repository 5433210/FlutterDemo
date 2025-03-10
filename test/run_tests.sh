#!/bin/bash

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# 记录开始时间
start_time=$(date +%s)

# 创建必要的目录
mkdir -p test/reports
mkdir -p coverage/reports
mkdir -p test/benchmark/results

echo -e "${YELLOW}开始运行测试套件...${NC}"

# 1. 运行前检查
echo -e "\n${YELLOW}1. 运行前检查${NC}"
dart test/run_pre_check.dart
if [ $? -ne 0 ]; then
    echo -e "${RED}前置检查失败，终止测试${NC}"
    exit 1
fi

# 2. 运行单元测试
echo -e "\n${YELLOW}2. 运行单元测试${NC}"
dart test --coverage=coverage --reporter=json test/utils/alerts/ > test/reports/unit_test_results.json
if [ $? -ne 0 ]; then
    echo -e "${RED}单元测试失败${NC}"
    exit 1
fi

# 3. 生成覆盖率报告
echo -e "\n${YELLOW}3. 生成覆盖率报告${NC}"
dart run coverage:format_coverage \
    --lcov \
    --in=coverage \
    --out=coverage/lcov.info \
    --packages=.packages \
    --report-on=lib

# 4. 检查覆盖率
echo -e "\n${YELLOW}4. 检查覆盖率${NC}"
dart run test/coverage/check_coverage.dart
if [ $? -ne 0 ]; then
    echo -e "${RED}覆盖率不足${NC}"
    exit 1
fi

# 5. 运行性能基准测试
echo -e "\n${YELLOW}5. 运行性能基准测试${NC}"
dart run test/utils/alerts/alert_benchmark_test.dart
if [ $? -ne 0 ]; then
    echo -e "${RED}性能测试失败${NC}"
    exit 1
fi

# 6. 运行集成测试
echo -e "\n${YELLOW}6. 运行集成测试${NC}"
dart test test/integration/
if [ $? -ne 0 ]; then
    echo -e "${RED}集成测试失败${NC}"
    exit 1
fi

# 7. 生成测试报告
echo -e "\n${YELLOW}7. 生成测试报告${NC}"
dart run test/integration/generate_report.dart

# 计算总耗时
end_time=$(date +%s)
duration=$((end_time - start_time))
minutes=$((duration / 60))
seconds=$((duration % 60))

# 输出总结
echo -e "\n${GREEN}测试完成!${NC}"
echo -e "总耗时: ${minutes}分${seconds}秒"
echo -e "测试报告位置: test/reports/"
echo -e "覆盖率报告: coverage/reports/"
echo -e "基准测试结果: test/benchmark/results/"

# 检查是否有失败的测试
if grep -q '"failed":true' test/reports/*.json; then
    echo -e "${RED}存在失败的测试用例${NC}"
    exit 1
else
    echo -e "${GREEN}所有测试通过${NC}"
    exit 0
fi