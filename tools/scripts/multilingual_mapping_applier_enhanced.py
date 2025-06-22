#!/usr/bin/env python3
"""
多语言映射文件应用器 - 支持干运行模式
基于映射文件应用代码替换和ARB更新
增强版本：支持YAML语法修复和模板语法处理
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

class MultilingualMappingApplier:
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
            
            # 预处理内容，处理模板语法和特殊字符
            content = self.preprocess_yaml_content(content)
            
            # 检查是否是OrderedDict格式
            if '!!python/object/apply:collections.OrderedDict' in content:
                # 使用unsafe_load处理OrderedDict格式
                self.mapping_data = yaml.unsafe_load(content)
                print(f"✅ 成功加载映射文件 (OrderedDict格式): {self.mapping_file_path}")
            else:
                # 标准YAML格式
                self.mapping_data = yaml.safe_load(content)
                print(f"✅ 成功加载映射文件 (标准YAML格式): {self.mapping_file_path}")
            
            return True
        except Exception as e:
            print(f"❌ 加载映射文件失败: {e}")
            print(f"文件路径: {self.mapping_file_path}")
            return False
    
    def preprocess_yaml_content(self, content):
        """预处理YAML内容，修复常见的语法问题"""
        # 找到所有包含 {xxx} 的行并修复
        lines = content.split('\n')
        fixed_lines = []
        fixed_count = 0
        
        for line in lines:
            original_line = line
            # 检查是否包含 {xxx} 模式且不在引号内
            if re.search(r'\{[^}]+\}', line) and ':' in line:
                # 如果行包含冒号和大括号，确保值部分被正确引用
                if ': ' in line:
                    key_part, value_part = line.split(': ', 1)
                    # 如果值部分包含 {xxx} 且没有被引号包围，添加引号
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
        """加载现有ARB文件"""
        # 加载中文ARB
        if os.path.exists(ZH_ARB_PATH):
            with open(ZH_ARB_PATH, 'r', encoding='utf-8') as f:
                self.zh_arb_data = json.load(f, object_pairs_hook=OrderedDict)
        
        # 加载英文ARB
        if os.path.exists(EN_ARB_PATH):
            with open(EN_ARB_PATH, 'r', encoding='utf-8') as f:
                self.en_arb_data = json.load(f, object_pairs_hook=OrderedDict)
        
        print(f"✅ 已加载ARB文件 - 中文: {len(self.zh_arb_data)} 键, 英文: {len(self.en_arb_data)} 键")
    
    def analyze_mappings(self):
        """分析映射数据，统计各种操作"""
        stats = {
            'total_items': 0,
            'approved_items': 0,
            'reuse_items': 0,
            'create_items': 0,
            'chinese_items': 0,
            'english_items': 0
        }
        
        # Debug: 打印映射数据结构
        print(f"🔍 映射数据类型: {type(self.mapping_data)}")
        if isinstance(self.mapping_data, dict):
            print(f"🔍 映射数据键: {list(self.mapping_data.keys())}")
            for key, value in list(self.mapping_data.items())[:2]:  # 只显示前2个
                print(f"🔍 {key}: {type(value)} - {len(value) if isinstance(value, (list, dict)) else 'N/A'}")
          # 处理OrderedDict格式的数据结构
        if isinstance(self.mapping_data, OrderedDict):
            # OrderedDict格式: [(key, value), ...]
            for lang_key, lang_mappings in self.mapping_data.items():
                if isinstance(lang_mappings, OrderedDict):
                    for arb_key, mapping_data in lang_mappings.items():
                        stats['total_items'] += 1
                        if mapping_data.get('approved', False):
                            stats['approved_items'] += 1
                        if 'reuse' in mapping_data.get('action', ''):
                            stats['reuse_items'] += 1
                        elif 'create' in mapping_data.get('action', ''):
                            stats['create_items'] += 1
                        if 'chinese' in lang_key.lower():
                            stats['chinese_items'] += 1
                        elif 'english' in lang_key.lower():
                            stats['english_items'] += 1
        else:
            # 标准字典格式
            for lang_key, lang_mappings in self.mapping_data.items():
                if isinstance(lang_mappings, list):
                    for item in lang_mappings:
                        stats['total_items'] += 1
                        if item.get('approved', False):
                            stats['approved_items'] += 1
                        if item.get('action') == 'reuse':
                            stats['reuse_items'] += 1
                        elif item.get('action') == 'create':
                            stats['create_items'] += 1
                        if lang_key == 'chinese':
                            stats['chinese_items'] += 1
                        elif lang_key == 'english':
                            stats['english_items'] += 1
          return stats
    
    def process_code_replacements(self):
        """处理代码替换"""
        code_changes = []
        
        # 处理映射数据
        for lang_key, lang_mappings in self.mapping_data.items():
            if not isinstance(lang_mappings, (list, OrderedDict)):
                continue
            
            # 处理OrderedDict结构
            if isinstance(lang_mappings, OrderedDict):
                for arb_key, mapping_data in lang_mappings.items():
                    if not mapping_data.get('approved', False):
                        continue
                    
                    file_path = mapping_data.get('file')
                    original_text = mapping_data.get('text_zh') or mapping_data.get('text_en') or mapping_data.get('original')
                    
                    if not all([file_path, original_text, arb_key]):
                        continue
                    
                    # 生成替换文本
                    replacement = f"S.of(context).{arb_key}"
                    
                    code_changes.append({
                        'file': file_path,
                        'original': original_text,
                        'replacement': replacement,
                        'arb_key': arb_key,
                        'language': lang_key,
                        'line': mapping_data.get('line', 0)
                    })
            else:
                # 处理列表结构（原有逻辑）
                for item in lang_mappings:
                    mapping_data = item
                    
                    # 处理OrderedDict格式
                    if isinstance(item, list) and len(item) > 1:
                        mapping_data = item[1]
                    
                    if not mapping_data.get('approved', False):
                        continue
                    
                    file_path = mapping_data.get('file')
                    original_text = mapping_data.get('text_zh') or mapping_data.get('text_en') or mapping_data.get('original')
                    arb_key = item[0] if isinstance(item, list) else mapping_data.get('arb_key')
                    
                    if not all([file_path, original_text, arb_key]):
                        continue
                    
                    # 生成替换文本
                    replacement = f"S.of(context).{arb_key}"
                    
                    code_changes.append({
                        'file': file_path,
                        'original': original_text,
                        'replacement': replacement,
                        'arb_key': arb_key,
                        'language': lang_key,
                        'line': mapping_data.get('line', 0)
                    })
        
        return code_changes
      def process_arb_updates(self):
        """处理ARB文件更新"""
        zh_updates = {}
        en_updates = {}
        
        for lang_key, lang_mappings in self.mapping_data.items():
            if not isinstance(lang_mappings, (list, OrderedDict)):
                continue
            
            # 处理OrderedDict结构
            if isinstance(lang_mappings, OrderedDict):
                for arb_key, mapping_data in lang_mappings.items():
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
            else:
                # 处理列表结构（原有逻辑）
                for item in lang_mappings:
                    mapping_data = item
                    
                    # 处理OrderedDict格式
                    if isinstance(item, list) and len(item) > 1:
                        arb_key = item[0]
                        mapping_data = item[1]
                    else:
                        arb_key = mapping_data.get('arb_key')
                    
                    if not mapping_data.get('approved', False):
                        continue
                    
                    action = mapping_data.get('action', '')
                    
                    if 'create' in action and arb_key:
                        text_zh = mapping_data.get('text_zh')
                        text_en = mapping_data.get('text_en')
                        
                        if text_zh and arb_key not in self.zh_arb_data:
                            zh_updates[arb_key] = text_zh
                        
                        if text_en and arb_key not in self.en_arb_data:
                            en_updates[arb_key] = text_en
        
        return zh_updates, en_updates
    
    def preview_changes(self):
        """预览所有更改"""
        print("\n🔍 === 映射文件应用预览 ===")
        
        # 分析映射
        stats = self.analyze_mappings()
        print(f"\n📊 === 映射统计 ===")
        print(f"总条目数: {stats['total_items']}")
        print(f"已审核条目: {stats['approved_items']}")
        print(f"复用条目: {stats['reuse_items']}")
        print(f"新建条目: {stats['create_items']}")
        print(f"中文条目: {stats['chinese_items']}")
        print(f"英文条目: {stats['english_items']}")
        
        # ARB更新预览
        zh_updates, en_updates = self.process_arb_updates()
        print(f"\n📝 === ARB文件更改预览 ===")
        
        total_new_keys = len(zh_updates) + len(en_updates)
        print(f"将添加 {total_new_keys} 个新键到ARB文件:")
        
        # 合并显示中英文键
        all_keys = set(zh_updates.keys()) | set(en_updates.keys())
        for key in sorted(all_keys):
            print(f"  {key}:")
            if key in zh_updates:
                print(f"    zh: {zh_updates[key]}")
            if key in en_updates:
                print(f"    en: {en_updates[key]}")
        
        # 代码替换预览
        code_changes = self.process_code_replacements()
        print(f"\n🔧 === 代码更改预览 ===")
        print(f"将更改 {len(code_changes)} 处代码:")
        
        for i, change in enumerate(code_changes):
            print(f"  文件: {change['file']}")
            print(f"  行号: {change['line']}")
            print(f"  原文: \"{change['original']}\"")
            print(f"  替换: {change['replacement']}")
            if i < len(code_changes) - 1:
                print()
        
        return len(code_changes) > 0 or total_new_keys > 0
    
    def apply_code_changes(self, code_changes):
        """应用代码更改"""
        files_changed = set()
        
        for change in code_changes:
            file_path = change['file']
            original = change['original']
            replacement = change['replacement']
            
            # 转换路径格式
            if '\\' in file_path and not file_path.startswith('lib'):
                file_path = file_path.replace('\\', '/')
            if not file_path.startswith('lib/'):
                file_path = 'lib/' + file_path.lstrip('/')
            
            if not os.path.exists(file_path):
                print(f"⚠️  文件不存在: {file_path}")
                continue
            
            try:
                # 读取文件
                with open(file_path, 'r', encoding='utf-8') as f:
                    content = f.read()
                
                # 确保原文存在于文件中
                if original not in content:
                    print(f"⚠️  在 {file_path} 中找不到原文: {original[:30]}...")
                    continue
                
                # 替换文本
                new_content = content.replace(original, replacement)
                
                if not self.dry_run:
                    # 备份原文件
                    backup_path = f"{file_path}.backup.{datetime.now().strftime('%Y%m%d_%H%M%S')}"
                    with open(backup_path, 'w', encoding='utf-8') as f:
                        f.write(content)
                    
                    # 写入新内容
                    with open(file_path, 'w', encoding='utf-8') as f:
                        f.write(new_content)
                
                files_changed.add(file_path)
                
            except Exception as e:
                print(f"❌ 处理文件 {file_path} 时出错: {e}")
        
        return files_changed
    
    def apply_arb_changes(self, zh_updates, en_updates):
        """应用ARB文件更改"""
        arb_files_changed = []
        
        # 更新中文ARB
        if zh_updates:
            for key, value in zh_updates.items():
                self.zh_arb_data[key] = value
            
            if not self.dry_run:
                # 备份
                backup_path = f"{ZH_ARB_PATH}.backup.{datetime.now().strftime('%Y%m%d_%H%M%S')}"
                if os.path.exists(ZH_ARB_PATH):
                    with open(backup_path, 'w', encoding='utf-8') as f:
                        json.dump(dict(self.zh_arb_data), f, ensure_ascii=False, indent=2)
                
                # 写入更新
                with open(ZH_ARB_PATH, 'w', encoding='utf-8') as f:
                    json.dump(dict(self.zh_arb_data), f, ensure_ascii=False, indent=2)
            
            arb_files_changed.append(ZH_ARB_PATH)
        
        # 更新英文ARB
        if en_updates:
            for key, value in en_updates.items():
                self.en_arb_data[key] = value
            
            if not self.dry_run:
                # 备份
                backup_path = f"{EN_ARB_PATH}.backup.{datetime.now().strftime('%Y%m%d_%H%M%S')}"
                if os.path.exists(EN_ARB_PATH):
                    with open(backup_path, 'w', encoding='utf-8') as f:
                        json.dump(dict(self.en_arb_data), f, ensure_ascii=False, indent=2)
                
                # 写入更新
                with open(EN_ARB_PATH, 'w', encoding='utf-8') as f:
                    json.dump(dict(self.en_arb_data), f, ensure_ascii=False, indent=2)
            
            arb_files_changed.append(EN_ARB_PATH)
        
        return arb_files_changed
    
    def run_preview(self):
        """运行预览模式"""
        if not self.load_mapping_file():
            return False
        
        self.load_arb_files()
        return self.preview_changes()
    
    def apply_changes(self):
        """应用所有更改"""
        print("\n=== 🚀 正式应用更改 ===")
        
        if not self.load_mapping_file():
            return False
        
        self.load_arb_files()
        
        # 处理代码替换
        code_changes = self.process_code_replacements()
        files_changed = self.apply_code_changes(code_changes)
        
        # 处理ARB更新
        zh_updates, en_updates = self.process_arb_updates()
        arb_files_changed = self.apply_arb_changes(zh_updates, en_updates)
        
        # 报告结果
        print(f"\n✅ 应用完成!")
        if files_changed:
            print(f"📝 已修改 {len(files_changed)} 个代码文件")
        if arb_files_changed:
            print(f"🌐 已更新 {len(arb_files_changed)} 个ARB文件")
        
        return True

def find_latest_mapping_file():
    """查找最新的映射文件"""
    pattern = "**/multilingual_mapping_*.yaml"
    files = glob.glob(pattern, recursive=True)
    
    if not files:
        print("❌ 未找到映射文件")
        return None
    
    # 按修改时间排序，返回最新的
    latest_file = max(files, key=os.path.getmtime)
    return latest_file

def main():
    parser = argparse.ArgumentParser(description='多语言映射文件应用器')
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
    applier = MultilingualMappingApplier(mapping_file, dry_run=args.dry_run)
    
    if args.dry_run:
        # 预览模式
        success = applier.run_preview()
        if success:
            print("\n✅ 预览完成！如果确认无误，请移除 --dry-run 参数正式应用更改。")
    else:
        # 实际应用
        print("⚠️  即将应用更改，这将修改代码文件和ARB文件。")
        confirm = input("确认继续？(y/N): ")
        if confirm.lower() == 'y':
            applier.apply_changes()
            print("\n🎉 应用完成！")
        else:
            print("已取消操作。")

if __name__ == "__main__":
    main()
