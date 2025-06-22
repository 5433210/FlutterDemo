#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
最终硬编码文本应用器
配合final_hardcoded_detector.py使用，应用检测结果到代码和ARB文件
"""

import os
import re
import json
import yaml
import shutil
from datetime import datetime
from typing import Dict, List, Any

class FinalHardcodedApplier:
    def __init__(self, mapping_file: str):
        self.mapping_file = mapping_file
        self.workspace_root = os.getcwd()
        self.zh_arb_path = os.path.join(self.workspace_root, 'lib', 'l10n', 'app_zh.arb')
        self.en_arb_path = os.path.join(self.workspace_root, 'lib', 'l10n', 'app_en.arb')
        self.backup_dir = os.path.join(self.workspace_root, 'final_hardcoded_backup')
        
        self.load_mapping()
        self.ensure_backup_dir()
    
    def load_mapping(self):
        """加载映射文件"""
        try:
            with open(self.mapping_file, 'r', encoding='utf-8') as f:
                self.mapping = yaml.safe_load(f)
            print(f"✅ 成功加载映射文件: {self.mapping_file}")
        except Exception as e:
            raise Exception(f"❌ 无法加载映射文件: {e}")
    
    def ensure_backup_dir(self):
        """确保备份目录存在"""
        if not os.path.exists(self.backup_dir):
            os.makedirs(self.backup_dir)
    
    def create_backup(self):
        """创建备份"""
        timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
        backup_subdir = os.path.join(self.backup_dir, f'backup_{timestamp}')
        os.makedirs(backup_subdir)
        
        # 备份ARB文件
        for arb_path in [self.zh_arb_path, self.en_arb_path]:
            if os.path.exists(arb_path):
                backup_path = os.path.join(backup_subdir, os.path.basename(arb_path))
                shutil.copy2(arb_path, backup_path)
                print(f"📄 已备份: {os.path.basename(arb_path)}")
        
        # 备份修改的Dart文件
        dart_files = set()
        for action_type in ['reuse_existing_keys', 'create_new_keys']:
            if action_type in self.mapping:
                for category, items in self.mapping[action_type].items():
                    for key, data in items.items():
                        if data.get('approved', False):
                            file_path = os.path.join(self.workspace_root, data['file'])
                            if file_path not in dart_files:
                                dart_files.add(file_path)
                                backup_file_path = os.path.join(backup_subdir, f"{os.path.basename(file_path)}.backup")
                                if os.path.exists(file_path):
                                    shutil.copy2(file_path, backup_file_path)
        
        print(f"📁 备份目录: {backup_subdir}")
        return backup_subdir
    
    def get_approved_items(self):
        """获取已审核通过的项目"""
        approved_reuse = []
        approved_new = []
        
        if 'reuse_existing_keys' in self.mapping:
            for category, items in self.mapping['reuse_existing_keys'].items():
                for key, data in items.items():
                    if data.get('approved', False):
                        approved_reuse.append((key, data))
        
        if 'create_new_keys' in self.mapping:
            for category, items in self.mapping['create_new_keys'].items():
                for key, data in items.items():
                    if data.get('approved', False):
                        approved_new.append((key, data))
        
        return approved_reuse, approved_new
    
    def update_arb_files(self, new_keys: List[tuple]):
        """更新ARB文件，添加新键"""
        if not new_keys:
            print("📝 没有新键需要添加到ARB文件")
            return
        
        # 加载现有ARB文件
        zh_data = {}
        en_data = {}
        
        if os.path.exists(self.zh_arb_path):
            with open(self.zh_arb_path, 'r', encoding='utf-8') as f:
                zh_data = json.load(f)
        
        if os.path.exists(self.en_arb_path):
            with open(self.en_arb_path, 'r', encoding='utf-8') as f:
                en_data = json.load(f)
        
        # 添加新键
        added_count = 0
        for key, data in new_keys:
            if key not in zh_data:
                zh_data[key] = data['text_zh']
                en_data[key] = data.get('text_en', data['text_zh'])  # 如果没有英文翻译，使用中文
                added_count += 1
                print(f"➕ 添加新键: {key} = \"{data['text_zh']}\"")
        
        # 保存ARB文件
        if added_count > 0:
            with open(self.zh_arb_path, 'w', encoding='utf-8') as f:
                json.dump(zh_data, f, ensure_ascii=False, indent=2)
            
            with open(self.en_arb_path, 'w', encoding='utf-8') as f:
                json.dump(en_data, f, ensure_ascii=False, indent=2)
            
            print(f"✅ 已向ARB文件添加 {added_count} 个新键")
        else:
            print("📝 所有键已存在于ARB文件中")
    
    def replace_hardcoded_text(self, key: str, data: Dict[str, Any], is_reuse: bool = False):
        """替换单个硬编码文本"""
        file_path = os.path.join(self.workspace_root, data['file'])
        
        if not os.path.exists(file_path):
            print(f"❌ 文件不存在: {file_path}")
            return False
        
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                content = f.read()
            
            original_text = data['text_zh']
            line_number = data['line']
            
            # 构建替换模式
            # 转义特殊字符
            escaped_text = re.escape(original_text)
            
            # 替换策略：查找包含硬编码文本的完整Text()调用
            patterns = [
                # Text('硬编码文本')
                rf"Text\(\s*['\"]({escaped_text})['\"]\s*\)",
                # const Text('硬编码文本')
                rf"const\s+Text\(\s*['\"]({escaped_text})['\"]\s*\)",
                # child: Text('硬编码文本')
                rf"(child:\s*(?:const\s+)?Text\(\s*['\"])({escaped_text})(['\"])",
                # tooltip: '硬编码文本'
                rf"(tooltip:\s*['\"])({escaped_text})(['\"])",
                # hintText: '硬编码文本'
                rf"(hintText:\s*['\"])({escaped_text})(['\"])",
                # labelText: '硬编码文本'
                rf"(labelText:\s*['\"])({escaped_text})(['\"])",
                # content: Text('硬编码文本')
                rf"(content:\s*(?:const\s+)?Text\(\s*['\"])({escaped_text})(['\"])",
            ]
            
            replacement_made = False
            for pattern in patterns:
                if re.search(pattern, content):
                    if 'tooltip:' in pattern or 'hintText:' in pattern or 'labelText:' in pattern:
                        # 对于属性，直接替换为 l10n 调用
                        new_content = re.sub(pattern, rf"\\1{{l10n.{key}}}\\3", content)
                    else:
                        # 对于Text Widget，替换为 l10n 调用
                        if pattern.startswith(r"Text\("):
                            new_content = re.sub(pattern, f"Text(l10n.{key})", content)
                        elif "const Text" in pattern:
                            new_content = re.sub(pattern, f"Text(l10n.{key})", content)  # 移除const，因为l10n是运行时
                        else:
                            new_content = re.sub(pattern, rf"\\1{{l10n.{key}}}\\3", content)
                    
                    if new_content != content:
                        content = new_content
                        replacement_made = True
                        break
            
            if replacement_made:
                # 确保文件有 AppLocalizations 导入
                if 'import' in content and 'flutter_gen/gen_l10n/app_localizations.dart' not in content:
                    # 在其他导入后添加
                    import_pattern = r"(import\s+['\"]package:flutter/[^;]+;)\n"
                    import_match = re.search(import_pattern, content)
                    if import_match:
                        import_line = import_match.group(1)
                        new_import = f"{import_line}\nimport 'package:flutter_gen/gen_l10n/app_localizations.dart';"
                        content = content.replace(import_line, new_import)
                
                # 写入修改后的内容
                with open(file_path, 'w', encoding='utf-8') as f:
                    f.write(content)
                
                action = "复用" if is_reuse else "替换"
                print(f"✅ {action}成功: {data['file']}:{line_number} -> l10n.{key}")
                return True
            else:
                print(f"⚠️  未找到匹配的文本模式: {data['file']}:{line_number}")
                return False
                
        except Exception as e:
            print(f"❌ 处理文件失败 {file_path}: {e}")
            return False
    
    def apply_changes(self):
        """应用所有已审核的更改"""
        print("=== 开始应用硬编码文本替换 ===")
        
        # 获取已审核的项目
        approved_reuse, approved_new = self.get_approved_items()
        
        if not approved_reuse and not approved_new:
            print("❌ 没有找到已审核通过的项目")
            print("💡 请在映射文件中将需要应用的项目的 'approved' 设置为 true")
            return
        
        print(f"📊 找到 {len(approved_reuse)} 个复用项目和 {len(approved_new)} 个新建项目")
        
        # 创建备份
        backup_dir = self.create_backup()
        
        # 更新ARB文件（只处理新建的键）
        self.update_arb_files(approved_new)
        
        # 替换代码中的硬编码文本
        success_count = 0
        total_count = len(approved_reuse) + len(approved_new)
        
        print("\n🔄 开始替换代码中的硬编码文本...")
        
        # 处理复用的键
        for key, data in approved_reuse:
            if self.replace_hardcoded_text(key, data, is_reuse=True):
                success_count += 1
        
        # 处理新建的键
        for key, data in approved_new:
            if self.replace_hardcoded_text(key, data, is_reuse=False):
                success_count += 1
        
        print(f"\n📊 替换完成: {success_count}/{total_count} 成功")
        if success_count < total_count:
            print(f"⚠️  有 {total_count - success_count} 个项目替换失败，请手动检查")
        
        print(f"💾 备份位置: {backup_dir}")
        print("\n✅ 应用完成！请运行 'flutter gen-l10n' 重新生成本地化文件")

def main():
    import sys
    
    if len(sys.argv) != 2:
        print("用法: python final_hardcoded_applier.py <mapping_file>")
        print("示例: python final_hardcoded_applier.py final_hardcoded_report/final_mapping_20250617_030438.yaml")
        return
    
    mapping_file = sys.argv[1]
    
    if not os.path.exists(mapping_file):
        print(f"❌ 映射文件不存在: {mapping_file}")
        return
    
    try:
        applier = FinalHardcodedApplier(mapping_file)
        applier.apply_changes()
    except Exception as e:
        print(f"❌ 应用失败: {e}")

if __name__ == "__main__":
    main()
