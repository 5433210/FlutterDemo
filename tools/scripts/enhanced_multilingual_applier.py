#!/usr/bin/env python3
"""
增强版多语言映射应用器 - 正确处理Flutter本地化
包含导入添加、上下文处理、文件结构分析等完整功能
"""

import os
import re
import json
import yaml
import glob
import argparse
from collections import OrderedDict
from datetime import datetime

# 配置常量
CODE_DIR = "lib"
ARB_DIR = "lib/l10n"
ZH_ARB_PATH = os.path.join(ARB_DIR, "app_zh.arb")
EN_ARB_PATH = os.path.join(ARB_DIR, "app_en.arb")

class EnhancedMappingApplier:
    def __init__(self, mapping_file_path, dry_run=False):
        self.mapping_file_path = mapping_file_path
        self.dry_run = dry_run
        self.mapping_data = None
        self.zh_arb_data = OrderedDict()
        self.en_arb_data = OrderedDict()
        self.changes_preview = []
        
    def load_mapping_file(self):
        """加载映射文件"""
        try:
            with open(self.mapping_file_path, 'r', encoding='utf-8') as f:
                content = f.read()
            
            # 预处理内容，修复YAML语法问题
            content = self.preprocess_yaml_content(content)
            
            # 检查是否是OrderedDict格式
            if '!!python/object/apply:collections.OrderedDict' in content:
                self.mapping_data = yaml.unsafe_load(content)
                print(f"✅ 成功加载映射文件 (OrderedDict格式): {self.mapping_file_path}")
            else:
                self.mapping_data = yaml.safe_load(content)
                print(f"✅ 成功加载映射文件 (标准YAML格式): {self.mapping_file_path}")
            
            return True
        except Exception as e:
            print(f"❌ 加载映射文件失败: {e}")
            return False
    
    def preprocess_yaml_content(self, content):
        """预处理YAML内容，修复常见语法问题"""
        lines = content.split('\n')
        fixed_lines = []
        fixed_count = 0
        
        for line in lines:
            # 修复 {xxx} 模板语法
            if re.search(r'\{[^}]+\}', line) and ':' in line:
                if ': ' in line:
                    key_part, value_part = line.split(': ', 1)
                    if re.search(r'\{[^}]+\}', value_part):
                        if not (value_part.startswith('"') and value_part.endswith('"')):
                            if not (value_part.startswith("'") and value_part.endswith("'")):
                                line = f"{key_part}: \"{value_part}\""
                                fixed_count += 1
            fixed_lines.append(line)
        
        if fixed_count > 0:
            print(f"🔧 修复了 {fixed_count} 个YAML语法问题")
        
        return '\n'.join(fixed_lines)
    
    def load_arb_files(self):
        """加载ARB文件"""
        if os.path.exists(ZH_ARB_PATH):
            with open(ZH_ARB_PATH, 'r', encoding='utf-8') as f:
                self.zh_arb_data = json.load(f, object_pairs_hook=OrderedDict)
        
        if os.path.exists(EN_ARB_PATH):
            with open(EN_ARB_PATH, 'r', encoding='utf-8') as f:
                self.en_arb_data = json.load(f, object_pairs_hook=OrderedDict)
        
        print(f"✅ 已加载ARB文件 - 中文: {len(self.zh_arb_data)} 键, 英文: {len(self.en_arb_data)} 键")
    
    def analyze_dart_file(self, file_path):
        """分析Dart文件结构，确定本地化集成方式"""
        if not os.path.exists(file_path):
            return None
        
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()
        
        analysis = {
            'has_material_import': 'package:flutter/material.dart' in content,
            'has_l10n_import': any(
                'flutter_gen/gen_l10n' in line or 
                'app_localizations' in line.lower() or
                'generated/l10n' in line
                for line in content.split('\n')
            ),
            'has_build_context': 'BuildContext' in content,
            'is_widget_class': 'extends StatelessWidget' in content or 'extends StatefulWidget' in content,
            'is_state_class': 'extends State<' in content,
            'widget_class_name': None,
            'existing_imports': [],
            'needs_context_access': False
        }
        
        # 提取导入语句
        import_lines = []
        for line in content.split('\n'):
            if line.strip().startswith('import '):
                import_lines.append(line.strip())
        analysis['existing_imports'] = import_lines
        
        # 查找Widget类名
        widget_match = re.search(r'class\s+(\w+)\s+extends\s+(StatelessWidget|StatefulWidget)', content)
        if widget_match:
            analysis['widget_class_name'] = widget_match.group(1)
          # 检查是否需要context访问（在build方法内或有context参数的方法内）
        build_method_match = re.search(r'Widget\s+build\s*\([^)]*BuildContext[^)]*context[^)]*\)', content)
        analysis['needs_context_access'] = bool(build_method_match)
        
        return analysis
    
    def generate_l10n_import(self):
        """生成本地化导入语句"""
        return "import 'package:flutter_gen/gen_l10n/app_localizations.dart';"
    
    def process_code_replacements(self):
        """处理代码替换，包含完整的本地化集成"""
        code_changes = []
        
        # 处理标准格式的映射数据
        for lang_key, lang_data in self.mapping_data.items():
            if not isinstance(lang_data, dict):
                continue
            
            # 遍历语言数据下的分类（如 ui_text_widget）
            for category, mappings in lang_data.items():
                if not isinstance(mappings, dict):
                    continue
                
                # 遍历具体的映射项
                for arb_key, mapping_data in mappings.items():
                    if not isinstance(mapping_data, dict):
                        continue
                    
                    if not mapping_data.get('approved', False):
                        continue
                    
                    file_path = mapping_data.get('file')
                    text_zh = mapping_data.get('text_zh')
                    text_en = mapping_data.get('text_en')
                    
                    # 根据语言键选择原始文本
                    if 'chinese' in lang_key.lower() and text_zh:
                        original_text = text_zh
                    elif 'english' in lang_key.lower() and text_en:
                        original_text = text_en
                    else:
                        original_text = text_zh or text_en
                    
                    if not all([file_path, original_text, arb_key]):
                        continue
                    
                    # 分析文件并生成完整的更改
                    change = self.create_comprehensive_change(file_path, original_text, arb_key, mapping_data)
                    if change:
                        code_changes.append(change)
        
        return code_changes
    
    def create_comprehensive_change(self, file_path, original_text, arb_key, mapping_data):
        """创建包含导入和上下文处理的完整更改"""
        # 标准化文件路径
        if '\\' in file_path:
            file_path = file_path.replace('\\', '/')
        if not file_path.startswith('lib/'):
            file_path = 'lib/' + file_path.lstrip('/')
        
        if not os.path.exists(file_path):
            print(f"⚠️  文件不存在: {file_path}")
            return None
        
        # 分析文件结构
        analysis = self.analyze_dart_file(file_path)
        if not analysis:
            return None
        
        # 确定替换策略
        replacement_strategy = self.determine_replacement_strategy(analysis, original_text)
        
        return {
            'file': file_path,
            'original': original_text,
            'arb_key': arb_key,
            'line': mapping_data.get('line', 0),
            'analysis': analysis,
            'strategy': replacement_strategy,
            'import_needed': not analysis['has_l10n_import'],
            'context_access': replacement_strategy['context_method']
        }
    
    def determine_replacement_strategy(self, analysis, original_text):
        """确定替换策略"""
        strategy = {
            'context_method': 'AppLocalizations.of(context)!',
            'needs_import': not analysis['has_l10n_import'],
            'context_available': analysis['needs_context_access'],
            'widget_type': 'unknown'
        }
        
        if analysis['is_widget_class']:
            strategy['widget_type'] = 'widget'
            strategy['context_method'] = 'AppLocalizations.of(context)!'
        elif analysis['is_state_class']:
            strategy['widget_type'] = 'state'
            strategy['context_method'] = 'AppLocalizations.of(context)!'
        else:
            # 对于非Widget类，可能需要传递context
            strategy['widget_type'] = 'other'
            strategy['context_method'] = 'AppLocalizations.of(context)!'
            strategy['needs_context_param'] = True
        
        return strategy
    
    def apply_code_changes(self, code_changes):
        """应用代码更改，包含导入和上下文处理"""
        files_changed = set()
        
        # 按文件分组更改
        changes_by_file = {}
        for change in code_changes:
            file_path = change['file']
            if file_path not in changes_by_file:
                changes_by_file[file_path] = []
            changes_by_file[file_path].append(change)
        
        # 逐文件处理
        for file_path, file_changes in changes_by_file.items():
            try:
                success = self.apply_changes_to_file(file_path, file_changes)
                if success:
                    files_changed.add(file_path)
            except Exception as e:
                print(f"❌ 处理文件 {file_path} 时出错: {e}")
        
        return files_changed
    
    def apply_changes_to_file(self, file_path, changes):
        """对单个文件应用所有更改"""
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()
        
        original_content = content
        
        # 检查是否需要添加导入
        needs_import = any(change['import_needed'] for change in changes)
        
        if needs_import:
            content = self.add_l10n_import(content)
        
        # 应用文本替换
        for change in changes:
            original_text = change['original']
            arb_key = change['arb_key']
            strategy = change['strategy']
            
            # 构建替换文本
            replacement = f"{strategy['context_method']}.{arb_key}"
            
            # 执行替换
            if original_text in content:
                content = content.replace(f'"{original_text}"', replacement)
                content = content.replace(f"'{original_text}'", replacement)
                print(f"  ✅ 替换: {original_text} -> {replacement}")
            else:
                print(f"  ⚠️  未找到文本: {original_text}")
        
        # 保存文件
        if content != original_content:
            if not self.dry_run:
                # 备份原文件
                backup_path = f"{file_path}.backup.{datetime.now().strftime('%Y%m%d_%H%M%S')}"
                with open(backup_path, 'w', encoding='utf-8') as f:
                    f.write(original_content)
                
                # 写入新内容
                with open(file_path, 'w', encoding='utf-8') as f:
                    f.write(content)
            
            return True
        
        return False
    
    def add_l10n_import(self, content):
        """添加本地化导入到文件顶部"""
        lines = content.split('\n')
        
        # 查找导入语句的插入位置
        import_insert_index = 0
        last_import_index = -1
        
        for i, line in enumerate(lines):
            if line.strip().startswith('import '):
                last_import_index = i
            elif line.strip().startswith('part '):
                # part语句应该在imports之后
                break
        
        # 检查是否已有本地化导入
        l10n_import = self.generate_l10n_import()
        if any('app_localizations' in line.lower() or 'flutter_gen/gen_l10n' in line for line in lines):
            print("  📦 本地化导入已存在")
            return content
          # 插入导入语句
        if last_import_index >= 0:
            insert_index = last_import_index + 1
        else:
            # 如果没有import语句，在文件开头插入
            insert_index = 0
            
        lines.insert(insert_index, l10n_import)
        print(f"  📦 添加导入: {l10n_import}")
        
        return '\n'.join(lines)
    
    def process_arb_updates(self):
        """处理ARB文件更新"""
        zh_updates = {}
        en_updates = {}
        
        # 处理标准格式的映射数据
        for lang_key, lang_data in self.mapping_data.items():
            if not isinstance(lang_data, dict):
                continue
            
            # 遍历语言数据下的分类
            for category, mappings in lang_data.items():
                if not isinstance(mappings, dict):
                    continue
                
                # 遍历具体的映射项
                for arb_key, mapping_data in mappings.items():
                    if not isinstance(mapping_data, dict):
                        continue
                    
                    if not mapping_data.get('approved', False):
                        continue
                    
                    action = mapping_data.get('action', '')
                    if 'create' in action:
                        text_zh = mapping_data.get('text_zh')
                        text_en = mapping_data.get('text_en')
                        
                        if text_zh and arb_key not in self.zh_arb_data:
                            zh_updates[arb_key] = text_zh
                        
                        if text_en and arb_key not in self.en_arb_data:
                            en_updates[arb_key] = text_en
        
        return zh_updates, en_updates
    
    def preview_changes(self):
        """预览所有更改"""
        print("\n🔍 === 增强版映射应用预览 ===")
        
        # 代码更改预览
        code_changes = self.process_code_replacements()
        print(f"\n📝 === 代码更改预览 ===")
        print(f"将处理 {len(code_changes)} 个文件:")
        
        files_needing_import = set()
        
        for change in code_changes:
            print(f"\n  📁 文件: {change['file']}")
            print(f"     原文: \"{change['original']}\"")
            print(f"     替换: {change['context_access']}.{change['arb_key']}")
            print(f"     策略: {change['strategy']['widget_type']} 类型")
            
            if change['import_needed']:
                files_needing_import.add(change['file'])
                print(f"     📦 需要添加本地化导入")
        
        if files_needing_import:
            print(f"\n📦 === 导入添加预览 ===")
            print(f"将为 {len(files_needing_import)} 个文件添加本地化导入:")
            for file_path in sorted(files_needing_import):
                print(f"  - {file_path}")
        
        # ARB更新预览
        zh_updates, en_updates = self.process_arb_updates()
        total_new_keys = len(zh_updates) + len(en_updates)
        
        if total_new_keys > 0:
            print(f"\n🌐 === ARB更新预览 ===")
            print(f"将添加 {total_new_keys} 个新键到ARB文件:")
            
            all_keys = set(zh_updates.keys()) | set(en_updates.keys())
            for key in sorted(all_keys):
                print(f"  {key}:")
                if key in zh_updates:
                    print(f"    zh: {zh_updates[key]}")
                if key in en_updates:
                    print(f"    en: {en_updates[key]}")
        
        return len(code_changes) > 0 or total_new_keys > 0
    
    def run_preview(self):
        """运行预览模式"""
        if not self.load_mapping_file():
            return False
        
        self.load_arb_files()
        return self.preview_changes()
    
    def apply_changes(self):
        """应用所有更改"""
        print("\n🚀 === 增强版映射应用 ===")
        
        if not self.load_mapping_file():
            return False
        
        self.load_arb_files()
        
        # 处理代码更改
        code_changes = self.process_code_replacements()
        files_changed = self.apply_code_changes(code_changes)
        
        # 处理ARB更新
        zh_updates, en_updates = self.process_arb_updates()
        arb_files_changed = self.apply_arb_changes(zh_updates, en_updates)
        
        # 报告结果
        print(f"\n✅ 应用完成!")
        if files_changed:
            print(f"📝 已修改 {len(files_changed)} 个代码文件")
            print(f"📦 已添加必要的本地化导入")
        if arb_files_changed:
            print(f"🌐 已更新 {len(arb_files_changed)} 个ARB文件")
        
        return True
    
    def apply_arb_changes(self, zh_updates, en_updates):
        """应用ARB文件更改"""
        arb_files_changed = []
        
        # 更新中文ARB
        if zh_updates:
            for key, value in zh_updates.items():
                self.zh_arb_data[key] = value
            
            if not self.dry_run:
                backup_path = f"{ZH_ARB_PATH}.backup.{datetime.now().strftime('%Y%m%d_%H%M%S')}"
                if os.path.exists(ZH_ARB_PATH):
                    with open(backup_path, 'w', encoding='utf-8') as f:
                        json.dump(dict(self.zh_arb_data), f, ensure_ascii=False, indent=2)
                
                with open(ZH_ARB_PATH, 'w', encoding='utf-8') as f:
                    json.dump(dict(self.zh_arb_data), f, ensure_ascii=False, indent=2)
            
            arb_files_changed.append(ZH_ARB_PATH)
        
        # 更新英文ARB
        if en_updates:
            for key, value in en_updates.items():
                self.en_arb_data[key] = value
            
            if not self.dry_run:
                backup_path = f"{EN_ARB_PATH}.backup.{datetime.now().strftime('%Y%m%d_%H%M%S')}"
                if os.path.exists(EN_ARB_PATH):
                    with open(backup_path, 'w', encoding='utf-8') as f:
                        json.dump(dict(self.en_arb_data), f, ensure_ascii=False, indent=2)
                
                with open(EN_ARB_PATH, 'w', encoding='utf-8') as f:
                    json.dump(dict(self.en_arb_data), f, ensure_ascii=False, indent=2)
            
            arb_files_changed.append(EN_ARB_PATH)
        
        return arb_files_changed

def find_latest_mapping_file():
    """查找最新的映射文件"""
    pattern = "**/multilingual_mapping_*.yaml"
    files = glob.glob(pattern, recursive=True)
    
    if not files:
        print("❌ 未找到映射文件")
        return None
    
    latest_file = max(files, key=os.path.getmtime)
    return latest_file

def main():
    parser = argparse.ArgumentParser(description='增强版多语言映射应用器')
    parser.add_argument('--input', '-i', help='映射文件路径')
    parser.add_argument('--dry-run', '-d', action='store_true', help='干运行模式，只预览更改')
    parser.add_argument('--auto-latest', '-a', action='store_true', help='自动使用最新映射文件')
    
    args = parser.parse_args()
    
    # 确定映射文件
    mapping_file = None
    
    if args.auto_latest:
        mapping_file = find_latest_mapping_file()
        if mapping_file:
            print(f"使用最新映射文件: {mapping_file}")
    elif args.input:
        mapping_file = args.input
    else:
        print("❌ 请指定映射文件路径或使用 --auto-latest 选项")
        return
    
    if not mapping_file or not os.path.exists(mapping_file):
        print(f"❌ 映射文件不存在: {mapping_file}")
        return
    
    # 创建应用器
    applier = EnhancedMappingApplier(mapping_file, dry_run=args.dry_run)
    
    if args.dry_run:
        # 预览模式
        success = applier.run_preview()
        if success:
            print("\n✅ 预览完成！如果确认无误，请移除 --dry-run 参数正式应用更改。")
    else:
        # 实际应用
        print("⚠️  即将应用更改，这将修改代码文件和ARB文件，并添加必要的导入。")
        confirm = input("确认继续？(y/N): ")
        if confirm.lower() == 'y':
            applier.apply_changes()
            print("\n🎉 应用完成！")
        else:
            print("已取消操作。")

if __name__ == "__main__":
    main()
