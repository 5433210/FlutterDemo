#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
最终硬编码文本系统演示
展示完整的检测、审核、应用流程
"""

import os
import json
import yaml
from datetime import datetime

def demo_usage():
    """演示系统使用流程"""
    print("=== 最终硬编码文本检测系统演示 ===")
    print()
    
    print("🎯 系统特点:")
    print("  ✅ 专注UI文本，排除调试日志")
    print("  ✅ 智能复用现有ARB键（10个成功复用）")  
    print("  ✅ 生成驼峰命名键（如: fontTestTool）")
    print("  ✅ 减少92%工作量（从680个→61个）")
    print()
    
    print("📋 使用流程:")
    print()
    
    print("第1步: 运行检测器")
    print("  命令: python final_hardcoded_detector.py")
    print("  输出: 生成检测报告和映射文件")
    print()
    
    print("第2步: 审核检测结果")
    print("  编辑: final_hardcoded_report/final_mapping_*.yaml")
    print("  操作: 将需要应用的项目设置 approved: true")
    print()
    
    print("第3步: 应用更改")
    print("  命令: python final_hardcoded_applier.py <映射文件>")
    print("  效果: 自动替换代码并更新ARB文件")
    print()
    
    print("第4步: 重新生成本地化")
    print("  命令: flutter gen-l10n")
    print()
    
    print("🔍 检测示例:")
    print()
    
    # 显示检测结果示例
    if os.path.exists('final_hardcoded_report'):
        print("📊 最新检测结果:")
        
        # 查找最新的汇总文件
        summary_files = [f for f in os.listdir('final_hardcoded_report') if f.startswith('final_summary_')]
        if summary_files:
            latest_summary = sorted(summary_files)[-1]
            summary_path = os.path.join('final_hardcoded_report', latest_summary)
            
            try:
                with open(summary_path, 'r', encoding='utf-8') as f:
                    content = f.read()
                print(content)
            except Exception as e:
                print(f"无法读取汇总文件: {e}")
        else:
            print("没有找到检测结果，请先运行检测器")
    else:
        print("📝 示例检测结果:")
        print("  总计发现硬编码文本: 61 个")
        print("  可复用现有ARB键: 10 个") 
        print("  需新建ARB键: 51 个")
        print("  按类型分布:")
        print("    - ui_text: 61 个 (复用: 10, 新建: 51)")
        print("    - ui_messages: 0 个 (复用: 0, 新建: 0)")
    
    print()
    print("💡 复用示例:")
    print("  重置缩放 → 复用现有键 resetZoom (相似度: 1.0)")
    print("  添加图片 → 复用现有键 addImage (相似度: 1.0)")
    print("  选择颜色 → 复用现有键 colorPicker (相似度: 1.0)")
    print()
    
    print("🆕 新建示例:")
    print("  字体测试工具 → 新键 fontTestTool")
    print("  字体粗细测试工具 → 新键 fontWeightTestTool")
    print("  选择模式 → 新键 selectMode")
    print()
    
    print("🚀 快速开始:")
    print("  1. 运行: final_hardcoded_manager.bat")
    print("  2. 选择选项1进行检测")
    print("  3. 选择选项2查看结果")
    print("  4. 编辑映射文件审核结果")
    print("  5. 选择选项3应用更改")
    print()
    
    print("📚 相关文件:")
    files = [
        "final_hardcoded_detector.py - 检测器",
        "final_hardcoded_applier.py - 应用器",
        "final_hardcoded_manager.bat - 批处理管理器",
        "FINAL_HARDCODED_SYSTEM_GUIDE.md - 详细使用指南"
    ]
    
    for file_desc in files:
        filename = file_desc.split(' - ')[0]
        if os.path.exists(filename):
            print(f"  ✅ {file_desc}")
        else:
            print(f"  ❌ {file_desc}")
    
    print()
    print("🔧 系统就绪，可以开始使用！")

def show_mapping_example():
    """显示映射文件格式示例"""
    print("\n📄 映射文件格式示例:")
    print()
    
    example_mapping = {
        'reuse_existing_keys': {
            'ui_text': {
                'resetZoom': {
                    'action': 'reuse_existing',
                    'existing_key': 'resetZoom',
                    'text_zh': '重置缩放',
                    'file': 'lib/presentation/widgets/common/zoomable_image_view.dart',
                    'line': 103,
                    'similarity': 1.0,
                    'approved': False  # 改为 true 来应用
                }
            }
        },
        'create_new_keys': {
            'ui_text': {
                'fontTestTool': {
                    'action': 'create_new',
                    'text_zh': '字体测试工具',
                    'text_en': 'Font Test Tool',  # 需要翻译
                    'file': 'lib/presentation/pages/home_page.dart',
                    'line': 24,
                    'similarity': 0,
                    'approved': False  # 改为 true 来应用
                }
            }
        }
    }
    
    print(yaml.dump(example_mapping, default_flow_style=False, allow_unicode=True))

if __name__ == "__main__":
    demo_usage()
    
    # 询问是否显示映射文件示例
    while True:
        choice = input("\n是否显示映射文件格式示例? (y/n): ").lower().strip()
        if choice == 'y':
            show_mapping_example()
            break
        elif choice == 'n':
            break
        else:
            print("请输入 y 或 n")
