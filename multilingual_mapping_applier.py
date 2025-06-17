#!/usr/bin/env python3
"""
多语言映射文件应用器 - 支持干运行模式
基于映射文件应用代码替换和ARB更新
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
        self.mapping_file_path = mapping_file_path        self.dry_run = dry_run
        self.mapping_data = None
        self.zh_arb_data = OrderedDict()
        self.en_arb_data = OrderedDict()
        self.changes_preview = []
        
    def load_mapping_file(self):
        """加载映射文件"""
        try:
            with open(self.mapping_file_path, 'r', encoding='utf-8') as f:
                content = f.read()
            
            # 预处理内容，修复YAML语法问题（如模板语法 {xxx}）
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
        import re
        
        # 找到所有包含 {xxx} 的行并修复
        lines = content.split('\n')
        fixed_lines = []
        fixed_count = 0
        
        for line in lines:
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
        
        # 处理OrderedDict格式的数据结构
        if isinstance(self.mapping_data, OrderedDict):
            # OrderedDict格式: [(key, value), ...]
            for lang_key, lang_mappings in self.mapping_data.items():
                if isinstance(lang_mappings, OrderedDict):
                    for category_key, category_mappings in lang_mappings.items():
                        if isinstance(category_mappings, OrderedDict):
                            for key, mapping_info in category_mappings.items():
                                self._analyze_single_mapping(mapping_info, stats)
        else:
            # 标准字典格式
            for lang_mappings in self.mapping_data.values():
                for category_mappings in lang_mappings.values():
                    for key, mapping_info in category_mappings.items():
                        self._analyze_single_mapping(mapping_info, stats)
        
        return stats
    
    def _analyze_single_mapping(self, mapping_info, stats):
        """分析单个映射条目"""
        stats['total_items'] += 1
        
        if mapping_info.get('approved', False):
            stats['approved_items'] += 1
        
        if mapping_info.get('action') == 'reuse_existing':
            stats['reuse_items'] += 1
        elif mapping_info.get('action') == 'create_new':
            stats['create_items'] += 1
        
        # 通过键名或文本内容判断语言
        if re.search(r'[\u4e00-\u9fff]', mapping_info.get('text_zh', '')):
            stats['chinese_items'] += 1
        else:
            stats['english_items'] += 1
    
    def preview_arb_changes(self):
        """预览ARB文件的更改"""
        arb_changes = {'zh': {}, 'en': {}}
        
        # 遍历所有映射 - 支持OrderedDict格式
        def process_mappings(data):
            if isinstance(data, OrderedDict):
                # OrderedDict格式
                for lang_key, lang_mappings in data.items():
                    if isinstance(lang_mappings, OrderedDict):
                        for category_key, category_mappings in lang_mappings.items():
                            if isinstance(category_mappings, OrderedDict):
                                for key, mapping_info in category_mappings.items():
                                    if mapping_info.get('approved', False) and mapping_info.get('action') == 'create_new':
                                        arb_changes['zh'][key] = mapping_info.get('text_zh', '')
                                        arb_changes['en'][key] = mapping_info.get('text_en', '')
            else:
                # 标准字典格式
                for lang_mappings in data.values():
                    for category_mappings in lang_mappings.values():
                        for key, mapping_info in category_mappings.items():
                            if mapping_info.get('approved', False) and mapping_info.get('action') == 'create_new':
                                arb_changes['zh'][key] = mapping_info.get('text_zh', '')
                                arb_changes['en'][key] = mapping_info.get('text_en', '')
        
        process_mappings(self.mapping_data)
        return arb_changes
    
    def preview_code_changes(self):
        """预览代码文件的更改"""
        code_changes = []
        
        def process_mappings(data):
            if isinstance(data, OrderedDict):
                # OrderedDict格式
                for lang_key, lang_mappings in data.items():
                    if isinstance(lang_mappings, OrderedDict):
                        for category_key, category_mappings in lang_mappings.items():
                            if isinstance(category_mappings, OrderedDict):
                                for key, mapping_info in category_mappings.items():
                                    if mapping_info.get('approved', False):
                                        self._add_code_change(key, mapping_info, code_changes)
            else:
                # 标准字典格式
                for lang_mappings in data.values():
                    for category_mappings in lang_mappings.values():
                        for key, mapping_info in category_mappings.items():
                            if mapping_info.get('approved', False):
                                self._add_code_change(key, mapping_info, code_changes)
        
        process_mappings(self.mapping_data)
        return code_changes
    
    def _add_code_change(self, key, mapping_info, code_changes):
        """添加单个代码更改到列表"""
        file_path = mapping_info.get('file', '')
        line_num = mapping_info.get('line', 0)
        original_text = mapping_info.get('text_zh', '') or mapping_info.get('text_en', '')
        
        # 生成替换文本
        replacement = f"S.of(context).{key}"
        
        code_changes.append({
            'file': os.path.join(CODE_DIR, file_path),
            'line': line_num,
            'original': original_text,
            'replacement': replacement,
            'key': key
        })
    
    def run_preview(self):
        """运行预览模式"""
        print("🔍 === 映射文件应用预览 ===")
        
        if not self.load_mapping_file():
            return False
        
        self.load_arb_files()
        
        # 分析统计
        stats = self.analyze_mappings()
        print(f"\n📊 === 映射统计 ===")
        print(f"总条目数: {stats['total_items']}")
        print(f"已审核条目: {stats['approved_items']}")
        print(f"复用条目: {stats['reuse_items']}")
        print(f"新建条目: {stats['create_items']}")
        print(f"中文条目: {stats['chinese_items']}")
        print(f"英文条目: {stats['english_items']}")
        
        if stats['approved_items'] == 0:
            print("\n⚠️  没有已审核的条目，请先审核映射文件中的条目（设置 approved: true）")
            return False
        
        # 预览ARB更改
        arb_changes = self.preview_arb_changes()
        print(f"\n📝 === ARB文件更改预览 ===")
        print(f"将添加 {len(arb_changes['zh'])} 个新键到ARB文件:")
        
        for key in list(arb_changes['zh'].keys())[:5]:  # 只显示前5个
            print(f"  {key}:")
            print(f"    zh: {arb_changes['zh'][key]}")
            print(f"    en: {arb_changes['en'][key]}")
        
        if len(arb_changes['zh']) > 5:
            print(f"  ... 还有 {len(arb_changes['zh']) - 5} 个键")
        
        # 预览代码更改
        code_changes = self.preview_code_changes()
        print(f"\n🔧 === 代码更改预览 ===")
        print(f"将更改 {len(code_changes)} 处代码:")
        
        for change in code_changes[:5]:  # 只显示前5个
            print(f"  文件: {change['file']}")
            print(f"  行号: {change['line']}")
            print(f"  原文: \"{change['original']}\"")
            print(f"  替换: {change['replacement']}")
            print()
        
        if len(code_changes) > 5:
            print(f"  ... 还有 {len(code_changes) - 5} 处更改")
        
        return True
    
    def apply_changes(self):
        """实际应用更改"""
        print("⚡ === 开始应用更改 ===")
        
        if not self.load_mapping_file():
            return False
        
        self.load_arb_files()
        
        # 创建备份
        backup_dir = f"backup_{datetime.now().strftime('%Y%m%d_%H%M%S')}"
        os.makedirs(backup_dir, exist_ok=True)
        
        # 备份ARB文件
        if os.path.exists(ZH_ARB_PATH):
            import shutil
            shutil.copy2(ZH_ARB_PATH, os.path.join(backup_dir, "app_zh.arb"))
        if os.path.exists(EN_ARB_PATH):
            import shutil
            shutil.copy2(EN_ARB_PATH, os.path.join(backup_dir, "app_en.arb"))
        
        print(f"✅ 创建备份: {backup_dir}")
        
        # 应用ARB更改
        arb_changes = self.preview_arb_changes()
        self.zh_arb_data.update(arb_changes['zh'])
        self.en_arb_data.update(arb_changes['en'])
        
        # 保存ARB文件
        with open(ZH_ARB_PATH, 'w', encoding='utf-8') as f:
            json.dump(self.zh_arb_data, f, ensure_ascii=False, indent=2)
        
        with open(EN_ARB_PATH, 'w', encoding='utf-8') as f:
            json.dump(self.en_arb_data, f, ensure_ascii=False, indent=2)
        
        print(f"✅ 更新ARB文件: 添加了 {len(arb_changes['zh'])} 个键")
        
        # 应用代码更改
        code_changes = self.preview_code_changes()
        replaced_count = 0
        
        for change in code_changes:
            if self.replace_in_file(change):
                replaced_count += 1
        
        print(f"✅ 更新代码文件: 替换了 {replaced_count}/{len(code_changes)} 处")
        
        return True
    
    def replace_in_file(self, change):
        """在文件中执行替换"""
        try:
            if not os.path.exists(change['file']):
                return False
            
            with open(change['file'], 'r', encoding='utf-8') as f:
                content = f.read()
            
            # 构建搜索模式
            original_text = change['original']
            escaped_text = re.escape(original_text)
            
            # 替换模式：寻找引号中的文本
            pattern = rf'([\'"]){escaped_text}\1'
            replacement = f'S.of(context).{change["key"]}'
            
            new_content = re.sub(pattern, replacement, content)
            
            if new_content != content:
                with open(change['file'], 'w', encoding='utf-8') as f:
                    f.write(new_content)
                return True
            
            return False
        except Exception as e:
            print(f"替换失败 {change['file']}: {e}")
            return False

def find_latest_mapping_file():
    """查找最新的映射文件"""
    pattern = "multilingual_hardcoded_report/multilingual_mapping_*.yaml"
    files = glob.glob(pattern)
    if files:
        return max(files, key=os.path.getmtime)
    return None

def main():
    parser = argparse.ArgumentParser(description='多语言映射文件应用器')
    parser.add_argument('--input', '-i', help='映射文件路径')
    parser.add_argument('--dry-run', '-d', action='store_true', help='干运行模式，只预览更改')
    parser.add_argument('--auto-latest', '-a', action='store_true', help='自动使用最新映射文件')
    
    args = parser.parse_args()
    
    # 确定映射文件路径
    mapping_file = args.input
    if args.auto_latest or not mapping_file:
        latest_file = find_latest_mapping_file()
        if latest_file:
            mapping_file = latest_file
            print(f"使用最新映射文件: {mapping_file}")
        elif not mapping_file:
            print("❌ 未找到映射文件，请使用 --input 指定文件路径")
            return
    
    if not os.path.exists(mapping_file):
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
