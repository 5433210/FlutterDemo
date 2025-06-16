#!/usr/bin/env python3
"""
交互式国际化工具
整合硬编码检测、ARB匹配、代码替换的完整工具链
"""

import os
import json
import re
import argparse
import subprocess
from typing import Dict, List, Tuple
from collections import defaultdict

class InteractiveI18nTool:
    def __init__(self):
        self.scripts_dir = "scripts"
        self.temp_dir = "temp_i18n"
        self.ensure_directories()
    
    def ensure_directories(self):
        """确保必要的目录存在"""
        os.makedirs(self.scripts_dir, exist_ok=True)
        os.makedirs(self.temp_dir, exist_ok=True)
    
    def run_command(self, command: str, capture_output: bool = True) -> Tuple[bool, str]:
        """运行命令并返回结果"""
        try:
            if capture_output:
                result = subprocess.run(command, shell=True, capture_output=True, text=True, encoding='utf-8')
                return result.returncode == 0, result.stdout + result.stderr
            else:
                result = subprocess.run(command, shell=True)
                return result.returncode == 0, ""
        except Exception as e:
            return False, str(e)
    
    def detect_hardcoded_texts(self) -> bool:
        """步骤1: 检测硬编码文本"""
        print("🔍 步骤1: 检测硬编码文本...")
        
        command = f"python {self.scripts_dir}/hardcoded_text_detector.py --scan --json --output {self.temp_dir}/hardcoded_report.md"
        success, output = self.run_command(command)
        
        if success:
            print("✅ 硬编码文本检测完成")
            print(output)
            return True
        else:
            print("❌ 硬编码文本检测失败")
            print(output)
            return False
    
    def match_arb_keys(self) -> bool:
        """步骤2: 匹配ARB键值"""
        print("🔍 步骤2: 匹配ARB键值...")
        
        json_file = f"{self.temp_dir}/hardcoded_report.json"
        if not os.path.exists(json_file):
            print(f"❌ 硬编码文本JSON文件不存在: {json_file}")
            return False
        
        command = f"python {self.scripts_dir}/smart_arb_matcher.py --input {json_file} --report {self.temp_dir}/match_report.md --additions {self.temp_dir}/arb_additions.json"
        success, output = self.run_command(command)
        
        if success:
            print("✅ ARB键值匹配完成")
            print(output)
            return True
        else:
            print("❌ ARB键值匹配失败")
            print(output)
            return False
    
    def interactive_review(self) -> bool:
        """步骤3: 交互式审查和确认"""
        print("🔍 步骤3: 交互式审查...")
        
        try:
            # 加载匹配结果
            with open(f"{self.temp_dir}/hardcoded_report.json", 'r', encoding='utf-8') as f:
                hardcoded_data = json.load(f)
            
            with open(f"{self.temp_dir}/arb_additions.json", 'r', encoding='utf-8') as f:
                arb_additions = json.load(f)
            
            # 重新运行匹配来获取详细结果
            from smart_arb_matcher import SmartARBMatcher
            matcher = SmartARBMatcher()
            match_results = matcher.batch_match(hardcoded_data)
            
            return self.review_and_confirm(match_results, arb_additions)
            
        except Exception as e:
            print(f"❌ 交互式审查失败: {e}")
            return False
    
    def review_and_confirm(self, match_results: List[Dict], arb_additions: Dict) -> bool:
        """审查和确认替换操作"""
        print(f"\n📋 需要处理的硬编码文本: {len(match_results)} 处")
        
        # 按文件分组
        grouped_by_file = defaultdict(list)
        for result in match_results:
            grouped_by_file[result['file_path']].append(result)
        
        confirmed_replacements = []
        confirmed_additions = {'zh': {}, 'en': {}}
        
        print("\n请逐一确认处理方案（输入 'q' 退出，'s' 跳过，'a' 全部确认）:")
        
        for file_path, items in grouped_by_file.items():
            print(f"\n📁 文件: {file_path} ({len(items)} 处)")
            
            for i, item in enumerate(items, 1):
                print(f"\n  {i}. 第 {item['line_number']} 行:")
                print(f"     文本: '{item['text']}'")
                print(f"     代码: {item['line_content']}")
                print(f"     类型: {item['text_type']}")
                
                if item['action'] == 'reuse':
                    print(f"     💡 建议复用键值: {item['recommended_key']}")
                    print(f"     📝 键值文本: {item['recommended_text']}")
                    print(f"     🎯 相似度: {item['similarity']:.2f}")
                    
                    choice = input("     确认复用？(y/n/s/q/a): ").lower().strip()
                    
                elif item['action'] == 'create':
                    print(f"     💡 建议新键名: {item['suggested_key']}")
                    suggested_en = arb_additions['en'].get(item['suggested_key'], '[需要翻译]')
                    print(f"     🌐 英文翻译: {suggested_en}")
                    
                    choice = input("     确认创建？(y/n/s/q/a): ").lower().strip()
                
                else:
                    choice = input("     跳过此项？(y/s/q/a): ").lower().strip()
                
                if choice == 'q':
                    print("用户退出")
                    return False
                elif choice == 'a':
                    print("确认所有剩余项目")
                    # 确认当前项目
                    self.confirm_single_item(item, arb_additions, confirmed_replacements, confirmed_additions)
                    # 确认所有剩余项目
                    for remaining_file, remaining_items in list(grouped_by_file.items())[list(grouped_by_file.keys()).index(file_path):]:
                        start_idx = items.index(item) + 1 if remaining_file == file_path else 0
                        for remaining_item in remaining_items[start_idx:]:
                            self.confirm_single_item(remaining_item, arb_additions, confirmed_replacements, confirmed_additions)
                    return self.execute_replacements(confirmed_replacements, confirmed_additions)
                elif choice == 's':
                    print("     跳过")
                    continue
                elif choice == 'y' or choice == '':
                    self.confirm_single_item(item, arb_additions, confirmed_replacements, confirmed_additions)
                else:
                    print("     取消")
        
        if confirmed_replacements:
            return self.execute_replacements(confirmed_replacements, confirmed_additions)
        else:
            print("没有确认的替换操作")
            return True
    
    def confirm_single_item(self, item: Dict, arb_additions: Dict, confirmed_replacements: List, confirmed_additions: Dict):
        """确认单个项目"""
        if item['action'] == 'reuse':
            confirmed_replacements.append({
                'file_path': item['file_path'],
                'line_number': item['line_number'],
                'original_text': item['text'],
                'arb_key': item['recommended_key'],
                'line_content': item['line_content'],
                'text_type': item['text_type']
            })
            print("     ✅ 已确认复用")
            
        elif item['action'] == 'create':
            key = item['suggested_key']
            confirmed_replacements.append({
                'file_path': item['file_path'],
                'line_number': item['line_number'],
                'original_text': item['text'],
                'arb_key': key,
                'line_content': item['line_content'],
                'text_type': item['text_type']
            })
            confirmed_additions['zh'][key] = item['text']
            confirmed_additions['en'][key] = arb_additions['en'].get(key, f"[TODO: Translate '{item['text']}']")
            print("     ✅ 已确认创建")
    
    def execute_replacements(self, confirmed_replacements: List, confirmed_additions: Dict) -> bool:
        """执行实际的替换操作"""
        print(f"\n🔄 开始执行替换操作...")
        print(f"   替换项目: {len(confirmed_replacements)} 个")
        print(f"   新增键值: {len(confirmed_additions['zh'])} 个")
        
        # 1. 更新ARB文件
        if confirmed_additions['zh']:
            success = self.update_arb_files(confirmed_additions)
            if not success:
                return False
        
        # 2. 执行代码替换
        success = self.replace_code(confirmed_replacements)
        if not success:
            return False
        
        # 3. 重新生成本地化文件
        print("🔄 重新生成本地化文件...")
        success, output = self.run_command("flutter gen-l10n")
        if success:
            print("✅ 本地化文件生成成功")
        else:
            print("❌ 本地化文件生成失败")
            print(output)
            return False
        
        # 4. 运行编译检查
        print("🔄 运行编译检查...")
        success, output = self.run_command("flutter analyze")
        if success:
            print("✅ 编译检查通过")
        else:
            print("⚠️  编译检查发现问题:")
            print(output)
        
        return True
    
    def update_arb_files(self, additions: Dict) -> bool:
        """更新ARB文件"""
        try:
            # 加载现有ARB文件
            zh_path = "lib/l10n/app_zh.arb"
            en_path = "lib/l10n/app_en.arb"
            
            with open(zh_path, 'r', encoding='utf-8') as f:
                zh_data = json.load(f)
            
            with open(en_path, 'r', encoding='utf-8') as f:
                en_data = json.load(f)
            
            # 添加新键值
            for key, value in additions['zh'].items():
                zh_data[key] = value
                en_data[key] = additions['en'].get(key, f"[TODO: Translate '{value}']")
            
            # 保存更新后的文件
            with open(zh_path, 'w', encoding='utf-8') as f:
                json.dump(zh_data, f, ensure_ascii=False, indent=2)
            
            with open(en_path, 'w', encoding='utf-8') as f:
                json.dump(en_data, f, ensure_ascii=False, indent=2)
            
            print(f"✅ ARB文件已更新，新增 {len(additions['zh'])} 个键值")
            return True
            
        except Exception as e:
            print(f"❌ 更新ARB文件失败: {e}")
            return False
    
    def replace_code(self, replacements: List[Dict]) -> bool:
        """执行代码替换"""
        # 按文件分组
        files_to_update = defaultdict(list)
        for replacement in replacements:
            files_to_update[replacement['file_path']].append(replacement)
        
        success_count = 0
        
        for file_path, file_replacements in files_to_update.items():
            if self.replace_in_file(file_path, file_replacements):
                success_count += 1
            else:
                print(f"❌ 文件 {file_path} 替换失败")
        
        print(f"✅ 成功更新 {success_count}/{len(files_to_update)} 个文件")
        return success_count == len(files_to_update)
    
    def replace_in_file(self, file_path: str, replacements: List[Dict]) -> bool:
        """在单个文件中执行替换"""
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                lines = f.readlines()
            
            modified = False
            
            # 按行号倒序排序，避免行号变化影响后续替换
            replacements.sort(key=lambda x: x['line_number'], reverse=True)
            
            for replacement in replacements:
                line_idx = replacement['line_number'] - 1
                if 0 <= line_idx < len(lines):
                    original_line = lines[line_idx]
                    new_line = self.perform_replacement(
                        original_line,
                        replacement['original_text'],
                        replacement['arb_key'],
                        replacement['text_type']
                    )
                    
                    if new_line != original_line:
                        lines[line_idx] = new_line
                        modified = True
                        print(f"   第 {replacement['line_number']} 行: {replacement['original_text']} → {replacement['arb_key']}")
            
            if modified:
                # 确保文件有AppLocalizations导入
                self.ensure_localization_import(lines)
                
                with open(file_path, 'w', encoding='utf-8') as f:
                    f.writelines(lines)
                
                print(f"✅ 文件 {file_path} 更新完成")
            
            return True
            
        except Exception as e:
            print(f"❌ 替换文件 {file_path} 失败: {e}")
            return False
    
    def perform_replacement(self, line: str, original_text: str, arb_key: str, text_type: str) -> str:
        """执行单行替换"""
        # 根据文本类型选择合适的替换模式
        replacements = {
            'text_widget': (
                f"Text('{original_text}')",
                f"Text(l10n.{arb_key})"
            ),
            'hint_text': (
                f"hintText: '{original_text}'",
                f"hintText: l10n.{arb_key}"
            ),
            'title_text': (
                f"title: Text('{original_text}')",
                f"title: Text(l10n.{arb_key})"
            ),
            'snackbar_content': (
                f"content: Text('{original_text}')",
                f"content: Text(l10n.{arb_key})"
            )
        }
        
        # 通用替换：直接替换引号内的文本
        if text_type in replacements:
            old_pattern, new_pattern = replacements[text_type]
            if old_pattern in line:
                return line.replace(old_pattern, new_pattern)
        
        # 通用模式：查找并替换引号内的文本
        patterns = [
            (f"'{original_text}'", f"l10n.{arb_key}"),
            (f'"{original_text}"', f"l10n.{arb_key}"),
        ]
        
        for old, new in patterns:
            if old in line:
                return line.replace(old, new)
        
        return line
    
    def ensure_localization_import(self, lines: List[str]):
        """确保文件有本地化导入"""
        has_import = any('app_localizations.dart' in line or 'AppLocalizations' in line for line in lines[:20])
        has_l10n_variable = any('l10n = AppLocalizations.of(context)' in line for line in lines)
        
        if not has_import:
            # 查找合适的位置插入导入
            import_line = "import 'package:flutter_gen/gen_l10n/app_localizations.dart';\n"
            
            # 在最后一个import后插入
            insert_idx = 0
            for i, line in enumerate(lines):
                if line.strip().startswith('import '):
                    insert_idx = i + 1
                elif line.strip() == '':
                    continue
                else:
                    break
            
            lines.insert(insert_idx, import_line)
        
        # 在build方法中添加l10n变量（如果没有的话）
        if not has_l10n_variable:
            for i, line in enumerate(lines):
                if 'Widget build(' in line and '{' in line:
                    # 在build方法开始后添加l10n变量
                    lines.insert(i + 1, "    final l10n = AppLocalizations.of(context);\n")
                    break
    
    def run_full_process(self) -> bool:
        """运行完整的国际化处理流程"""
        print("🚀 开始完整国际化处理流程...\n")
        
        # 步骤1: 检测硬编码文本
        if not self.detect_hardcoded_texts():
            return False
        
        # 步骤2: 匹配ARB键值
        if not self.match_arb_keys():
            return False
        
        # 步骤3: 交互式审查和确认
        if not self.interactive_review():
            return False
        
        print("\n🎉 国际化处理完成！")
        print("\n建议后续操作:")
        print("1. 运行 'flutter test' 确保测试通过")
        print("2. 手动检查翻译质量，特别是标记为 [TODO] 的英文翻译")
        print("3. 在不同语言环境下测试应用")
        
        return True

def main():
    parser = argparse.ArgumentParser(description='交互式国际化工具')
    parser.add_argument('--detect-only', action='store_true', help='仅检测硬编码文本')
    parser.add_argument('--match-only', action='store_true', help='仅执行ARB匹配')
    parser.add_argument('--full', action='store_true', help='运行完整流程')
    
    args = parser.parse_args()
    
    tool = InteractiveI18nTool()
    
    if args.detect_only:
        tool.detect_hardcoded_texts()
    elif args.match_only:
        tool.match_arb_keys()
    elif args.full:
        tool.run_full_process()
    else:
        print("请指定操作模式:")
        print("  --detect-only: 仅检测硬编码文本")
        print("  --match-only: 仅执行ARB匹配")
        print("  --full: 运行完整流程")

if __name__ == "__main__":
    main()
