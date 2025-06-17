#!/usr/bin/env python3
"""
专用映射应用器 - 处理OrderedDict格式并正确添加本地化导入
"""

import os
import re
import json
import yaml
from collections import OrderedDict
from datetime import datetime

# 配置常量
CODE_DIR = "lib"
ARB_DIR = "lib/l10n"
ZH_ARB_PATH = os.path.join(ARB_DIR, "app_zh.arb")
EN_ARB_PATH = os.path.join(ARB_DIR, "app_en.arb")

class SpecializedMappingApplier:
    def __init__(self, mapping_file_path, dry_run=True):
        self.mapping_file_path = mapping_file_path
        self.dry_run = dry_run
        self.mapping_data = None
        self.zh_arb_data = OrderedDict()
        self.en_arb_data = OrderedDict()
        
    def load_mapping_file(self):
        """加载复杂格式的映射文件"""
        try:
            with open(self.mapping_file_path, 'r', encoding='utf-8') as f:
                content = f.read()
            
            # 预处理YAML内容，修复语法问题
            content = self.preprocess_yaml_content(content)
            
            # 使用unsafe_load处理OrderedDict格式
            self.mapping_data = yaml.unsafe_load(content)
            print(f"✅ 成功加载映射文件: {self.mapping_file_path}")
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
            # 修复包含 ${...} 和 {...} 的行
            if re.search(r'\$?\{[^}]+\}', line) and ':' in line:
                if ': ' in line and not line.strip().endswith('"') and not line.strip().endswith("'"):
                    key_part, value_part = line.split(': ', 1)
                    # 为包含模板语法的值添加引号
                    if re.search(r'\$?\{[^}]+\}', value_part):
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
    
    def extract_mappings(self):
        """从OrderedDict结构中提取映射"""
        mappings = []
        
        def process_ordered_dict(data, level=0):
            if isinstance(data, OrderedDict):
                for key, value in data.items():
                    if isinstance(value, OrderedDict):
                        process_ordered_dict(value, level + 1)
                    elif isinstance(value, dict) and all(k in value for k in ['text_zh', 'file', 'approved']):
                        # 这是一个映射项
                        mappings.append({
                            'arb_key': key,
                            'text_zh': value.get('text_zh'),
                            'text_en': value.get('text_en'),
                            'file': value.get('file'),
                            'line': value.get('line', 0),
                            'action': value.get('action'),
                            'approved': value.get('approved', False)
                        })
            elif isinstance(data, list):
                for item in data:
                    process_ordered_dict(item, level)
        
        process_ordered_dict(self.mapping_data)
        return mappings
    
    def analyze_dart_file(self, file_path):
        """分析Dart文件，检查本地化状态"""
        if not os.path.exists(file_path):
            return None
        
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()
        
        return {
            'has_material_import': 'package:flutter/material.dart' in content,
            'has_l10n_import': any([
                'package:flutter_gen/gen_l10n/app_localizations.dart' in content,
                'generated/l10n/l10n.dart' in content,
                '../../../generated/l10n.dart' in content
            ]),
            'uses_s_of_context': 'S.of(context)' in content,
            'is_widget_class': 'extends StatelessWidget' in content or 'extends StatefulWidget' in content,
            'content': content
        }
    
    def add_l10n_import(self, content):
        """添加本地化导入"""
        lines = content.split('\n')
        
        # 查找导入插入位置
        last_import_index = -1
        for i, line in enumerate(lines):
            if line.strip().startswith('import '):
                last_import_index = i
        
        # 检查是否已有l10n导入
        has_l10n = any(
            'app_localizations' in line.lower() or 
            'generated/l10n' in line or
            'flutter_gen/gen_l10n' in line
            for line in lines
        )
        
        if not has_l10n:
            # 添加本地化导入
            import_line = "import '../../../generated/l10n.dart';"
            insert_pos = last_import_index + 1 if last_import_index >= 0 else 0
            lines.insert(insert_pos, import_line)
            print(f"  📦 添加本地化导入: {import_line}")
        
        return '\n'.join(lines)
    
    def process_mappings(self):
        """处理映射，生成代码更改"""
        mappings = self.extract_mappings()
        
        # 过滤已批准的映射
        approved_mappings = [m for m in mappings if m['approved']]
        
        print(f"\n📊 映射统计:")
        print(f"  总映射数: {len(mappings)}")
        print(f"  已批准数: {len(approved_mappings)}")
        
        if not approved_mappings:
            print("⚠️  没有已批准的映射项，请在映射文件中设置 approved: true")
            return [], {}
        
        # 按文件分组
        files_to_process = {}
        arb_updates = {'zh': {}, 'en': {}}
        
        for mapping in approved_mappings:
            file_path = mapping['file']
            
            # 标准化文件路径
            if '\\' in file_path:
                file_path = file_path.replace('\\', '/')
            if not file_path.startswith('lib/'):
                file_path = 'lib/' + file_path.lstrip('/')
            
            if file_path not in files_to_process:
                files_to_process[file_path] = []
            
            files_to_process[file_path].append(mapping)
            
            # 收集ARB更新
            if 'create' in mapping.get('action', ''):
                arb_key = mapping['arb_key']
                if mapping['text_zh'] and arb_key not in self.zh_arb_data:
                    arb_updates['zh'][arb_key] = mapping['text_zh']
                if mapping['text_en'] and arb_key not in self.en_arb_data:
                    arb_updates['en'][arb_key] = mapping['text_en']
        
        return files_to_process, arb_updates
    
    def preview_changes(self):
        """预览所有更改"""
        print("\n🔍 === 专用映射应用预览 ===")
        
        files_to_process, arb_updates = self.process_mappings()
        
        if not files_to_process:
            return False
        
        # 预览文件更改
        print(f"\n📝 === 代码文件更改预览 ===")
        print(f"将处理 {len(files_to_process)} 个文件:")
        
        for file_path, mappings in files_to_process.items():
            print(f"\n  📁 文件: {file_path}")
            
            # 分析文件
            analysis = self.analyze_dart_file(file_path)
            if analysis:
                print(f"     本地化导入: {'✅' if analysis['has_l10n_import'] else '❌ 需要添加'}")
                print(f"     Widget类: {'✅' if analysis['is_widget_class'] else '⚠️'}")
                print(f"     使用S.of(context): {'✅' if analysis['uses_s_of_context'] else '⚠️'}")
            else:
                print(f"     ⚠️  文件不存在")
                continue
            
            print(f"     将替换 {len(mappings)} 个硬编码文本:")
            for mapping in mappings:
                original = mapping['text_zh'] or mapping['text_en']
                replacement = f"S.of(context).{mapping['arb_key']}"
                print(f"       第 {mapping['line']} 行: \"{original}\" -> {replacement}")
        
        # 预览ARB更新
        total_arb_updates = len(arb_updates['zh']) + len(arb_updates['en'])
        if total_arb_updates > 0:
            print(f"\n🌐 === ARB文件更新预览 ===")
            print(f"将添加 {total_arb_updates} 个新键:")
            
            all_keys = set(arb_updates['zh'].keys()) | set(arb_updates['en'].keys())
            for key in sorted(all_keys):
                print(f"  {key}:")
                if key in arb_updates['zh']:
                    print(f"    zh: {arb_updates['zh'][key]}")
                if key in arb_updates['en']:
                    print(f"    en: {arb_updates['en'][key]}")
        
        return True
    
    def apply_changes(self):
        """应用所有更改"""
        print("\n🚀 === 应用更改 ===")
        
        files_to_process, arb_updates = self.process_mappings()
        
        if not files_to_process:
            return False
        
        files_changed = 0
        
        # 处理每个文件
        for file_path, mappings in files_to_process.items():
            print(f"\n📝 处理文件: {file_path}")
            
            # 分析文件
            analysis = self.analyze_dart_file(file_path)
            if not analysis:
                print(f"  ⚠️  跳过：文件不存在")
                continue
            
            content = analysis['content']
            
            # 添加导入（如果需要）
            if not analysis['has_l10n_import']:
                content = self.add_l10n_import(content)
            
            # 替换硬编码文本
            changes_made = 0
            for mapping in mappings:
                original_text = mapping['text_zh'] or mapping['text_en']
                arb_key = mapping['arb_key']
                replacement = f"S.of(context).{arb_key}"
                
                # 尝试不同的引号格式
                patterns = [f'"{original_text}"', f"'{original_text}'"]
                
                for pattern in patterns:
                    if pattern in content:
                        content = content.replace(pattern, replacement)
                        print(f"  ✅ 替换: {pattern} -> {replacement}")
                        changes_made += 1
                        break
                else:
                    print(f"  ⚠️  未找到: {original_text}")
            
            # 保存文件
            if changes_made > 0 or not analysis['has_l10n_import']:
                if not self.dry_run:
                    # 备份原文件
                    backup_path = f"{file_path}.backup.{datetime.now().strftime('%Y%m%d_%H%M%S')}"
                    with open(backup_path, 'w', encoding='utf-8') as f:
                        f.write(analysis['content'])
                    
                    # 写入新内容
                    with open(file_path, 'w', encoding='utf-8') as f:
                        f.write(content)
                
                files_changed += 1
                print(f"  ✅ 文件已{'预览' if self.dry_run else '更新'}")
        
        # 处理ARB文件更新
        if arb_updates['zh'] or arb_updates['en']:
            print(f"\n🌐 更新ARB文件:")
            
            if arb_updates['zh']:
                print(f"  中文ARB: 添加 {len(arb_updates['zh'])} 个键")
                if not self.dry_run:
                    self.zh_arb_data.update(arb_updates['zh'])
                    with open(ZH_ARB_PATH, 'w', encoding='utf-8') as f:
                        json.dump(dict(self.zh_arb_data), f, ensure_ascii=False, indent=2)
            
            if arb_updates['en']:
                print(f"  英文ARB: 添加 {len(arb_updates['en'])} 个键")
                if not self.dry_run:
                    self.en_arb_data.update(arb_updates['en'])
                    with open(EN_ARB_PATH, 'w', encoding='utf-8') as f:
                        json.dump(dict(self.en_arb_data), f, ensure_ascii=False, indent=2)
        
        print(f"\n✅ 处理完成！{'预览了' if self.dry_run else '修改了'} {files_changed} 个文件")
        return True
    
    def run(self):
        """运行应用器"""
        if not self.load_mapping_file():
            return False
        
        self.load_arb_files()
        
        if self.dry_run:
            success = self.preview_changes()
            if success:
                print("\n✅ 预览完成！如果确认无误，请移除 --dry-run 参数正式应用更改。")
        else:
            success = self.apply_changes()
        
        return success

def main():
    import argparse
    
    parser = argparse.ArgumentParser(description='专用映射应用器')
    parser.add_argument('--input', '-i', required=True, help='映射文件路径')
    parser.add_argument('--dry-run', '-d', action='store_true', default=True, help='干运行模式（默认）')
    parser.add_argument('--apply', action='store_true', help='实际应用更改')
    
    args = parser.parse_args()
    
    if not os.path.exists(args.input):
        print(f"❌ 映射文件不存在: {args.input}")
        return
    
    # 确定是否为干运行
    dry_run = not args.apply
    if dry_run:
        print("🔍 运行预览模式")
    else:
        print("⚠️  运行实际应用模式")
    
    applier = SpecializedMappingApplier(args.input, dry_run=dry_run)
    
    if not dry_run:
        confirm = input("确认要应用更改吗？(y/N): ")
        if confirm.lower() != 'y':
            print("已取消操作")
            return
    
    applier.run()

if __name__ == "__main__":
    main()
