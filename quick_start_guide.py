#!/usr/bin/env python3
"""
硬编码文本系统快速上手指南
"""

import os
import sys

def print_header():
    print("=" * 60)
    print("      硬编码文本检测和替换系统 - 快速上手指南")
    print("=" * 60)
    print()

def print_system_overview():
    print("🎯 系统功能概述")
    print("-" * 30)
    print("1. 自动检测Flutter项目中的硬编码中文文本")
    print("2. 检测范围包括：")
    print("   • UI界面文本：Widget中的文本、按钮标签、对话框等")
    print("   • 枚举显示名称：枚举的displayName、toString等")
    print("3. 智能生成ARB国际化键值")
    print("4. 安全替换硬编码文本为l10n调用")
    print()

def print_quick_start():
    print("🚀 快速开始")
    print("-" * 30)
    print("1. 运行检测：")
    print("   方式一：双击 hardcoded_text_manager.bat")
    print("   方式二：python comprehensive_hardcoded_manager.py")
    print()
    print("2. 查看结果：")
    print("   检测完成后会生成映射文件和报告")
    print("   映射文件路径：comprehensive_hardcoded_report/comprehensive_mapping_*.yaml")
    print()
    print("3. 审核映射：")
    print("   • 打开映射文件")
    print("   • 修改英文翻译")
    print("   • 将approved设置为true")
    print()
    print("4. 执行替换：")
    print("   运行：python enhanced_arb_applier.py --auto-latest")
    print()

def print_file_structure():
    print("📁 生成的文件结构")
    print("-" * 30)
    print("comprehensive_hardcoded_report/     # 综合检测报告")
    print("├── comprehensive_mapping_*.yaml    # 📋 主要文件：映射配置")
    print("├── comprehensive_summary_*.txt     # 📊 汇总报告")
    print("hardcoded_detection_report/         # UI文本检测详情")
    print("├── hardcoded_detail_*.txt         # 详细检测结果")
    print("enum_detection_report/              # 枚举检测详情")
    print("├── enum_analysis_*.txt            # 枚举分析报告")
    print("arb_backup_*/                      # 🔒 自动备份")
    print()

def print_mapping_example():
    print("📝 映射文件示例")
    print("-" * 30)
    print("""审核前的条目：
ui_text_mappings:
  ui_text_widget:
    works_text_添加作品:
      text_zh: "添加作品"
      text_en: "添加作品"          # ⚠️ 需要修改为英文
      file: "pages/works/add.dart"
      line: 25
      approved: false            # ⚠️ 需要改为true

审核后的条目：
ui_text_mappings:
  ui_text_widget:
    works_text_添加作品:
      text_zh: "添加作品"
      text_en: "Add Work"         # ✅ 已修改为英文
      file: "pages/works/add.dart"
      line: 25
      approved: true             # ✅ 已确认处理
""")

def print_safety_features():
    print("🛡️ 安全特性")
    print("-" * 30)
    print("• 自动备份：每次替换前备份ARB文件和代码文件")
    print("• 精确替换：基于文件名和行号精确定位")
    print("• 用户审核：只处理用户确认的条目")
    print("• 错误处理：详细的失败报告和恢复建议")
    print("• 回滚支持：可从备份目录恢复文件")
    print()

def print_best_practices():
    print("💡 最佳实践")
    print("-" * 30)
    print("1. 翻译建议：")
    print("   • 确保英文翻译准确传达中文含义")
    print("   • 考虑UI界面的空间限制")
    print("   • 保持专业术语的一致性")
    print()
    print("2. 批量处理：")
    print("   • 分批处理，先处理重要的UI文本")
    print("   • 逐步验证，确保应用功能正常")
    print("   • 建立翻译词汇表")
    print()
    print("3. 键名规范：")
    print("   • 使用描述性名称：msg_delete_confirm")
    print("   • 添加模块前缀：works_btn_add")
    print("   • 避免通用词汇：label1, text2")
    print()

def check_environment():
    print("🔍 环境检查")
    print("-" * 30)
    
    # 检查Python版本
    python_version = sys.version_info
    if python_version >= (3, 6):
        print(f"✅ Python版本: {python_version.major}.{python_version.minor}")
    else:
        print(f"❌ Python版本过低: {python_version.major}.{python_version.minor} (需要3.6+)")
    
    # 检查必要的模块
    required_modules = ['yaml', 'json', 're', 'glob', 'datetime']
    for module in required_modules:
        try:
            __import__(module)
            print(f"✅ {module} 模块可用")
        except ImportError:
            print(f"❌ {module} 模块缺失")
    
    # 检查项目结构
    required_dirs = ['lib', 'lib/l10n']
    for dir_path in required_dirs:
        if os.path.exists(dir_path):
            print(f"✅ 目录存在: {dir_path}")
        else:
            print(f"❌ 目录缺失: {dir_path}")
    
    # 检查ARB文件
    arb_files = ['lib/l10n/app_zh.arb', 'lib/l10n/app_en.arb']
    for arb_file in arb_files:
        if os.path.exists(arb_file):
            print(f"✅ ARB文件存在: {arb_file}")
        else:
            print(f"⚠️ ARB文件缺失: {arb_file}")
    
    print()

def print_next_steps():
    print("▶️ 下一步操作")
    print("-" * 30)
    print("1. 如果环境检查通过，直接开始使用")
    print("2. 如果有问题，请先解决环境配置")
    print("3. 建议先在测试分支上运行，验证效果")
    print("4. 遇到问题可查看 HARDCODED_TEXT_SYSTEM_README.md")
    print()

def main():
    print_header()
    print_system_overview()
    print_quick_start()
    print_file_structure()
    print_mapping_example()
    print_safety_features()
    print_best_practices()
    check_environment()
    print_next_steps()
    
    print("🎉 准备就绪！现在可以开始使用硬编码文本检测和替换系统了。")
    print()
    
    # 询问是否立即开始
    choice = input("是否立即运行综合检测？(y/n): ")
    if choice.lower() == 'y':
        print("\n正在启动综合检测...")
        os.system("python comprehensive_hardcoded_manager.py")
    else:
        print("您可以稍后手动运行检测。")

if __name__ == "__main__":
    main()
