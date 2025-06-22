#!/usr/bin/env python3
"""
增强ARB应用器 - 基于审核后的映射文件执行代码替换和ARB文件更新
支持安全的代码替换和完整的ARB文件管理
"""

import os
import re
import json
import yaml
import glob
import shutil
from collections import OrderedDict
from datetime import datetime

# 配置常量
CODE_DIR = "lib"
ARB_DIR = "lib/l10n"
ZH_ARB_PATH = os.path.join(ARB_DIR, "app_zh.arb")
EN_ARB_PATH = os.path.join(ARB_DIR, "app_en.arb")
REPORT_DIR = "hardcoded_detection_report"
BACKUP_DIR = None  # 将在运行时设置

class EnhancedARBApplier:
    def __init__(self, mapping_file_path):
        self.mapping_file_path = mapping_file_path
        self.backup_dir = f"arb_backup_{datetime.now().strftime('%Y%m%d_%H%M%S')}"
        self.mapping_data = None
        self.zh_arb_data = OrderedDict()
        self.en_arb_data = OrderedDict()
        self.replaced_count = 0
        self.failed_replacements = []
        
    def load_mapping_file(self):
        """加载映射文件"""
        if not os.path.exists(self.mapping_file_path):
            raise FileNotFoundError(f"映射文件不存在: {self.mapping_file_path}")
        
        try:
            with open(self.mapping_file_path, 'r', encoding='utf-8') as f:
                self.mapping_data = yaml.safe_load(f)
            print(f"成功加载映射文件: {self.mapping_file_path}")
        except yaml.YAMLError as e:
            raise ValueError(f"映射文件格式错误: {e}")
    
    def create_backup(self):
        """创建备份"""
        os.makedirs(self.backup_dir, exist_ok=True)
        
        # 备份ARB文件
        for arb_path in [ZH_ARB_PATH, EN_ARB_PATH]:
            if os.path.exists(arb_path):
                backup_path = os.path.join(self.backup_dir, os.path.basename(arb_path))
                shutil.copy2(arb_path, backup_path)
                print(f"备份ARB文件: {arb_path} -> {backup_path}")
        
        # 备份即将修改的代码文件
        code_files_to_backup = set()
        for context_data in self.mapping_data.values():
            if isinstance(context_data, dict):
                for item_data in context_data.values():
                    if isinstance(item_data, dict) and item_data.get('approved', False):
                        file_path = os.path.join(CODE_DIR, item_data['file'])
                        code_files_to_backup.add(file_path)
        
        for file_path in code_files_to_backup:
            if os.path.exists(file_path):
                # 保持目录结构
                rel_path = os.path.relpath(file_path, CODE_DIR)
                backup_path = os.path.join(self.backup_dir, "code", rel_path)
                os.makedirs(os.path.dirname(backup_path), exist_ok=True)
                shutil.copy2(file_path, backup_path)
                print(f"备份代码文件: {file_path}")
    
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
    
    def update_arb_files(self):
        """更新ARB文件，添加新的键值对"""
        new_keys_count = 0
        
        for context, context_data in self.mapping_data.items():
            if not isinstance(context_data, dict):
                continue
                
            for key, item_data in context_data.items():
                if not isinstance(item_data, dict) or not item_data.get('approved', False):
                    continue
                
                # 检查键是否已存在
                if key in self.zh_arb_data:
                    print(f"警告: 键 '{key}' 已存在于中文ARB文件中，跳过")
                    continue
                
                # 添加到ARB数据
                self.zh_arb_data[key] = item_data['text_zh']
                self.en_arb_data[key] = item_data.get('text_en', item_data['text_zh'])
                new_keys_count += 1
                print(f"添加ARB键: {key} = \"{item_data['text_zh']}\"")
        
        # 保存更新后的ARB文件
        if new_keys_count > 0:
            with open(ZH_ARB_PATH, 'w', encoding='utf-8') as f:
                json.dump(self.zh_arb_data, f, ensure_ascii=False, indent=2)
            
            with open(EN_ARB_PATH, 'w', encoding='utf-8') as f:
                json.dump(self.en_arb_data, f, ensure_ascii=False, indent=2)
            
            print(f"成功更新ARB文件，添加了 {new_keys_count} 个新键")
        else:
            print("没有新的ARB键需要添加")
        
        return new_keys_count
    
    def build_replacement_patterns(self):
        """构建替换模式"""
        replacements = []
        
        for context, context_data in self.mapping_data.items():
            if not isinstance(context_data, dict):
                continue
                
            for key, item_data in context_data.items():
                if not isinstance(item_data, dict) or not item_data.get('approved', False):
                    continue
                
                text = item_data['text_zh']
                file_path = item_data['file']
                line_num = item_data['line']
                
                replacements.append({
                    'key': key,
                    'text': text,
                    'file': file_path,
                    'line': line_num,
                    'context': context
                })
        
        return replacements
    
    def safe_replace_in_file(self, file_path, text_to_replace, replacement_key, expected_line_num):
        """安全地在文件中执行替换"""
        full_file_path = os.path.join(CODE_DIR, file_path)
        
        if not os.path.exists(full_file_path):
            return False, f"文件不存在: {file_path}"
        
        try:
            with open(full_file_path, 'r', encoding='utf-8') as f:
                lines = f.readlines()
            
            # 检查指定行是否包含目标文本
            if expected_line_num <= len(lines):
                target_line = lines[expected_line_num - 1]
                if text_to_replace in target_line:
                    # 生成替换后的代码
                    l10n_call = f"l10n.{replacement_key}"
                    
                    # 智能替换：保持原有的代码结构
                    new_line = target_line.replace(f'"{text_to_replace}"', l10n_call)
                    new_line = new_line.replace(f"'{text_to_replace}'", l10n_call)
                    
                    lines[expected_line_num - 1] = new_line
                    
                    # 检查文件是否已导入l10n
                    needs_import = True
                    for line in lines[:20]:  # 检查前20行
                        if 'app_localizations.dart' in line or 'AppLocalizations' in line:
                            needs_import = False
                            break
                    
                    # 如果需要，添加导入语句
                    if needs_import:
                        import_line = "import '../../../l10n/app_localizations.dart';\n"
                        # 找到最后一个import语句之后插入
                        insert_index = 0
                        for i, line in enumerate(lines):
                            if line.strip().startswith('import'):
                                insert_index = i + 1
                        lines.insert(insert_index, import_line)
                        print(f"添加l10n导入到文件: {file_path}")
                    
                    # 写回文件
                    with open(full_file_path, 'w', encoding='utf-8') as f:
                        f.writelines(lines)
                    
                    return True, "替换成功"
                else:
                    return False, f"在第{expected_line_num}行未找到文本: {text_to_replace}"
            else:
                return False, f"文件行数不足，期望第{expected_line_num}行"
                
        except Exception as e:
            return False, f"文件操作错误: {str(e)}"
    
    def execute_replacements(self):
        """执行所有代码替换"""
        replacements = self.build_replacement_patterns()
        
        if not replacements:
            print("没有需要执行的替换操作")
            return
        
        print(f"开始执行 {len(replacements)} 个替换操作...")
        
        # 按文件分组，避免重复操作
        file_replacements = {}
        for replacement in replacements:
            file_path = replacement['file']
            if file_path not in file_replacements:
                file_replacements[file_path] = []
            file_replacements[file_path].append(replacement)
        
        # 逐文件执行替换
        for file_path, file_replacement_list in file_replacements.items():
            print(f"\n处理文件: {file_path}")
            
            # 按行号排序，从后往前替换避免行号变化
            file_replacement_list.sort(key=lambda x: x['line'], reverse=True)
            
            for replacement in file_replacement_list:
                success, message = self.safe_replace_in_file(
                    replacement['file'],
                    replacement['text'],
                    replacement['key'],
                    replacement['line']
                )
                
                if success:
                    print(f"  ✓ 替换成功: {replacement['key']}")
                    self.replaced_count += 1
                else:
                    print(f"  ✗ 替换失败: {replacement['key']} - {message}")
                    self.failed_replacements.append({
                        'replacement': replacement,
                        'error': message
                    })
    
    def generate_l10n_files(self):
        """重新生成l10n文件"""
        print("\n重新生成本地化文件...")
        
        # 使用flutter gen-l10n命令
        try:
            import subprocess
            result = subprocess.run(
                ['flutter', 'gen-l10n'],
                cwd=os.path.dirname(os.path.abspath(__file__)),
                capture_output=True,
                text=True
            )
            
            if result.returncode == 0:
                print("✓ 本地化文件生成成功")
                return True
            else:
                print(f"✗ 本地化文件生成失败: {result.stderr}")
                return False
        except FileNotFoundError:
            print("✗ Flutter命令未找到，请手动运行: flutter gen-l10n")
            return False
    
    def generate_report(self):
        """生成应用报告"""
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        report_path = os.path.join(REPORT_DIR, f"application_report_{timestamp}.txt")
        
        with open(report_path, 'w', encoding='utf-8') as f:
            f.write("=== ARB应用报告 ===\n")
            f.write(f"应用时间: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n")
            f.write(f"映射文件: {self.mapping_file_path}\n")
            f.write(f"备份目录: {self.backup_dir}\n\n")
            
            f.write(f"替换统计:\n")
            f.write(f"  - 成功替换: {self.replaced_count} 个\n")
            f.write(f"  - 失败替换: {len(self.failed_replacements)} 个\n\n")
            
            if self.failed_replacements:
                f.write("失败的替换:\n")
                for failed in self.failed_replacements:
                    replacement = failed['replacement']
                    f.write(f"  - 文件: {replacement['file']}\n")
                    f.write(f"    行号: {replacement['line']}\n")
                    f.write(f"    文本: {replacement['text']}\n")
                    f.write(f"    键名: {replacement['key']}\n")
                    f.write(f"    错误: {failed['error']}\n")
                    f.write("    " + "-"*30 + "\n")
        
        print(f"应用报告已生成: {report_path}")
        return report_path
    
    def run_application(self):
        """执行完整的应用流程"""
        print("=== 增强ARB应用器 ===")
        
        try:
            # 1. 加载映射文件
            self.load_mapping_file()
            
            # 2. 创建备份
            print("\n创建备份...")
            self.create_backup()
            
            # 3. 加载ARB文件
            print("\n加载ARB文件...")
            self.load_arb_files()
            
            # 4. 更新ARB文件
            print("\n更新ARB文件...")
            new_keys = self.update_arb_files()
            
            # 5. 执行代码替换
            print("\n执行代码替换...")
            self.execute_replacements()
            
            # 6. 重新生成l10n文件
            self.generate_l10n_files()
            
            # 7. 生成报告
            print("\n生成应用报告...")
            report_path = self.generate_report()
            
            # 8. 输出总结
            print(f"\n=== 应用完成 ===")
            print(f"成功替换: {self.replaced_count} 个")
            print(f"失败替换: {len(self.failed_replacements)} 个")
            print(f"新增ARB键: {new_keys} 个")
            print(f"备份目录: {self.backup_dir}")
            print(f"应用报告: {report_path}")
            
            if self.failed_replacements:
                print(f"\n注意：有 {len(self.failed_replacements)} 个替换失败，请查看报告了解详情")
            
            print("\n建议下一步操作:")
            print("1. 检查生成的代码是否正确")
            print("2. 运行 flutter gen-l10n 确保本地化文件最新")
            print("3. 测试应用功能是否正常")
            print("4. 如有问题，可从备份目录恢复文件")
            
        except Exception as e:
            print(f"应用过程中发生错误: {e}")
            print("请检查备份并手动恢复文件")
            raise

def find_latest_mapping_file():
    """查找最新的映射文件"""
    pattern = os.path.join(REPORT_DIR, "hardcoded_mapping_*.yaml")
    mapping_files = glob.glob(pattern)
    
    if not mapping_files:
        return None
    
    # 按文件名中的时间戳排序，返回最新的
    mapping_files.sort(reverse=True)
    return mapping_files[0]

def main():
    import argparse
    
    parser = argparse.ArgumentParser(description='增强ARB应用器')
    parser.add_argument('--mapping-file', '-f', help='映射文件路径')
    parser.add_argument('--auto-latest', '-a', action='store_true', help='自动使用最新的映射文件')
    parser.add_argument('--dry-run', '-d', action='store_true', help='干运行模式，只预览更改不实际执行')
    
    args = parser.parse_args()
    
    mapping_file_path = None
    
    if args.auto_latest:
        mapping_file_path = find_latest_mapping_file()
        if not mapping_file_path:
            print("未找到映射文件，请先运行 enhanced_hardcoded_detector.py")
            return
        print(f"使用最新映射文件: {mapping_file_path}")
    elif args.mapping_file:
        mapping_file_path = args.mapping_file
    else:
        # 交互式选择
        mapping_file_path = find_latest_mapping_file()
        if mapping_file_path:
            choice = input(f"找到映射文件: {mapping_file_path}\n是否使用此文件？(y/n): ")
            if choice.lower() != 'y':
                mapping_file_path = input("请输入映射文件路径: ")
        else:
            mapping_file_path = input("请输入映射文件路径: ")
    
    if not mapping_file_path or not os.path.exists(mapping_file_path):
        print("映射文件不存在")
        return
    
    applier = EnhancedARBApplier(mapping_file_path)
    applier.run_application()

if __name__ == "__main__":
    main()
