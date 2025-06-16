#!/usr/bin/env python3
"""
ARB优化与国际化主控制脚本
提供统一的入口点来执行所有国际化相关任务
"""

import os
import sys
import argparse
import subprocess
from datetime import datetime

def run_command(command: str, description: str = "") -> bool:
    """运行命令并显示结果"""
    if description:
        print(f"🔄 {description}...")
    
    try:
        result = subprocess.run(command, shell=True, check=False)
        if result.returncode == 0:
            print(f"✅ 完成")
            return True
        else:
            print(f"❌ 失败 (退出码: {result.returncode})")
            return False
    except Exception as e:
        print(f"❌ 执行错误: {e}")
        return False

def ensure_dependencies():
    """确保必要的依赖已安装"""
    print("🔍 检查依赖...")
    
    try:
        import jieba
        print("✅ jieba 已安装")
    except ImportError:
        print("⚠️  jieba 未安装，正在安装...")
        if not run_command("pip install jieba", "安装 jieba"):
            return False
    
    return True

def phase1_arb_optimization():
    """阶段1: ARB文件优化"""
    print("\n" + "="*50)
    print("📋 阶段1: ARB文件分析与优化")
    print("="*50)
    
    # 1. 分析现有ARB文件
    if not run_command("python scripts/arb_optimizer.py --analyze", "分析ARB文件"):
        return False
    
    # 2. 生成键值映射表
    if not run_command("python scripts/arb_optimizer.py --generate-mapping", "生成键值映射表"):
        return False
    
    # 3. 询问是否执行优化
    print("\n📋 分析完成，请查看 'arb_analysis_report.md' 了解详情")
    confirm = input("是否执行ARB文件优化？(y/N): ").lower().strip()
    
    if confirm == 'y':
        if not run_command("python scripts/arb_optimizer.py --optimize --backup", "优化ARB文件"):
            return False
        
        # 重新生成本地化文件
        if not run_command("flutter gen-l10n", "重新生成本地化文件"):
            return False
        
        print("✅ ARB优化完成")
    else:
        print("⏭️  跳过ARB优化")
    
    return True

def phase2_hardcoded_detection():
    """阶段2: 硬编码文本检测"""
    print("\n" + "="*50)
    print("🔍 阶段2: 硬编码文本检测")
    print("="*50)
    
    if not run_command("python scripts/hardcoded_text_detector.py --scan --json", "检测硬编码文本"):
        return False
    
    print("✅ 硬编码文本检测完成")
    print("📄 详细报告: hardcoded_text_report.md")
    print("📄 JSON数据: hardcoded_text_report.json")
    
    return True

def phase3_interactive_replacement():
    """阶段3: 交互式替换"""
    print("\n" + "="*50)
    print("🔄 阶段3: 交互式文本替换")
    print("="*50)
    
    # 检查硬编码文本文件是否存在
    if not os.path.exists("hardcoded_text_report.json"):
        print("❌ 硬编码文本数据文件不存在，请先运行检测")
        return False
    
    if not run_command("python scripts/interactive_i18n_tool.py --full", "运行交互式替换工具"):
        return False
    
    return True

def verification_phase():
    """验证阶段"""
    print("\n" + "="*50)
    print("✅ 验证阶段")
    print("="*50)
    
    # 运行静态分析
    print("🔍 运行静态分析...")
    run_command("flutter analyze", "Flutter 静态分析")
    
    # 尝试编译
    print("🔍 尝试编译...")
    run_command("flutter build apk --debug", "Debug 编译测试")
    
    # 检查剩余硬编码文本
    print("🔍 检查剩余硬编码文本...")
    run_command("python scripts/hardcoded_text_detector.py --scan --min-confidence 0.8", "剩余硬编码检测")
    
    print("\n🎉 验证完成！请查看上述结果")

def full_workflow():
    """完整工作流程"""
    print("🚀 开始完整的ARB优化与国际化流程")
    print(f"⏰ 开始时间: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    
    # 检查依赖
    if not ensure_dependencies():
        return False
    
    # 阶段1: ARB优化
    if not phase1_arb_optimization():
        print("❌ ARB优化阶段失败")
        return False
    
    # 阶段2: 硬编码检测
    if not phase2_hardcoded_detection():
        print("❌ 硬编码检测阶段失败")
        return False
    
    # 阶段3: 交互式替换
    if not phase3_interactive_replacement():
        print("❌ 交互式替换阶段失败")
        return False
    
    # 验证阶段
    verification_phase()
    
    print(f"\n🎉 全部流程完成！")
    print(f"⏰ 结束时间: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    
    return True

def quick_scan():
    """快速扫描模式"""
    print("⚡ 快速扫描模式")
    
    if not ensure_dependencies():
        return False
    
    print("\n🔍 检测硬编码文本...")
    run_command("python scripts/hardcoded_text_detector.py --scan", "硬编码文本检测")
    
    print("\n📊 统计现有ARB使用情况...")
    # 使用现有VS Code任务
    run_command('powershell -Command "Select-String -Path lib\\**\\*.dart -Pattern \'AppLocalizations\\.of\\(context\\)\' | Measure-Object | Select-Object -ExpandProperty Count"', "ARB使用统计")

def interactive_mode():
    """交互式模式"""
    print("🎯 交互式模式")
    print("请选择要执行的操作:")
    print("1. ARB文件分析")
    print("2. ARB文件优化")
    print("3. 硬编码文本检测")
    print("4. 交互式文本替换")
    print("5. 完整流程")
    print("6. 快速扫描")
    print("0. 退出")
    
    while True:
        choice = input("\n请输入选项 (0-6): ").strip()
        
        if choice == '0':
            print("👋 再见！")
            break
        elif choice == '1':
            run_command("python scripts/arb_optimizer.py --analyze", "ARB文件分析")
        elif choice == '2':
            run_command("python scripts/arb_optimizer.py --optimize --backup", "ARB文件优化")
        elif choice == '3':
            phase2_hardcoded_detection()
        elif choice == '4':
            phase3_interactive_replacement()
        elif choice == '5':
            full_workflow()
            break
        elif choice == '6':
            quick_scan()
        else:
            print("❌ 无效选项，请重新输入")

def main():
    parser = argparse.ArgumentParser(description='ARB优化与国际化主控制器')
    parser.add_argument('--full', action='store_true', help='运行完整流程')
    parser.add_argument('--scan', action='store_true', help='快速扫描模式')
    parser.add_argument('--interactive', action='store_true', help='交互式模式')
    parser.add_argument('--arb-only', action='store_true', help='仅ARB优化')
    parser.add_argument('--hardcoded-only', action='store_true', help='仅硬编码检测')
    parser.add_argument('--verify', action='store_true', help='仅验证')
    
    args = parser.parse_args()
    
    # 确保scripts目录存在
    os.makedirs('scripts', exist_ok=True)
    
    if args.full:
        success = full_workflow()
        sys.exit(0 if success else 1)
    elif args.scan:
        quick_scan()
    elif args.interactive:
        interactive_mode()
    elif args.arb_only:
        success = phase1_arb_optimization()
        sys.exit(0 if success else 1)
    elif args.hardcoded_only:
        success = phase2_hardcoded_detection()
        sys.exit(0 if success else 1)
    elif args.verify:
        verification_phase()
    else:
        print("🎯 ARB优化与国际化工具")
        print("\n可用选项:")
        print("  --full          运行完整流程")
        print("  --scan          快速扫描")
        print("  --interactive   交互式模式")
        print("  --arb-only      仅ARB优化")
        print("  --hardcoded-only 仅硬编码检测")
        print("  --verify        仅验证")
        print("\n或运行 --interactive 进入交互式菜单")

if __name__ == "__main__":
    main()
