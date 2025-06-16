#!/usr/bin/env python3
"""
ARB文件优化器
用于分析、优化ARB文件，删除重复键值，合并相似键值，清理无用键值
"""

import os
import json
import re
import argparse
import subprocess
from collections import OrderedDict, defaultdict
from difflib import SequenceMatcher
from datetime import datetime
import shutil

class ARBOptimizer:
    def __init__(self, l10n_dir="lib/l10n"):
        self.l10n_dir = l10n_dir
        self.zh_arb_path = os.path.join(l10n_dir, "app_zh.arb")
        self.en_arb_path = os.path.join(l10n_dir, "app_en.arb")
        self.backup_dir = f"arb_backup_{datetime.now().strftime('%Y%m%d_%H%M%S')}"
        
    def load_arb_files(self):
        """加载ARB文件"""
        try:
            with open(self.zh_arb_path, 'r', encoding='utf-8') as f:
                zh_data = json.load(f, object_pairs_hook=OrderedDict)
            
            with open(self.en_arb_path, 'r', encoding='utf-8') as f:
                en_data = json.load(f, object_pairs_hook=OrderedDict)
                
            return zh_data, en_data
        except Exception as e:
            print(f"❌ 加载ARB文件失败: {e}")
            return None, None
    
    def find_dart_files(self):
        """查找所有Dart文件"""
        dart_files = []
        for root, dirs, files in os.walk("lib"):
            for file in files:
                if file.endswith('.dart'):
                    dart_files.append(os.path.join(root, file))
        return dart_files
    
    def find_used_keys(self):
        """查找代码中使用的ARB键值"""
        used_keys = set()
        dart_files = self.find_dart_files()
        
        # 常见的本地化引用模式
        patterns = [
            r'AppLocalizations\.of\(context\)\.(\w+)',
            r'l10n\.(\w+)',
            r'localizations\.(\w+)',
            r'_localizations\.(\w+)',
        ]
        
        for file_path in dart_files:
            try:
                with open(file_path, 'r', encoding='utf-8', errors='ignore') as f:
                    content = f.read()
                    
                for pattern in patterns:
                    matches = re.findall(pattern, content)
                    used_keys.update(matches)
                    
            except Exception as e:
                print(f"⚠️  读取文件失败 {file_path}: {e}")
                
        return used_keys
    
    def calculate_similarity(self, text1, text2):
        """计算两个文本的相似度"""
        return SequenceMatcher(None, text1, text2).ratio()
    
    def find_duplicate_keys(self, zh_data, en_data):
        """查找重复或相似的键值"""
        duplicates = []
        keys = [k for k in zh_data.keys() if not k.startswith('@')]
        
        for i, key1 in enumerate(keys):
            for key2 in keys[i+1:]:
                zh_sim = self.calculate_similarity(zh_data[key1], zh_data[key2])
                en_sim = self.calculate_similarity(en_data.get(key2, ''), en_data.get(key1, ''))
                
                # 如果中文或英文相似度很高，认为是重复
                if zh_sim > 0.85 or en_sim > 0.85:
                    duplicates.append({
                        'key1': key1,
                        'key2': key2,
                        'zh_text1': zh_data[key1],
                        'zh_text2': zh_data[key2],
                        'en_text1': en_data.get(key1, ''),
                        'en_text2': en_data.get(key2, ''),
                        'zh_similarity': zh_sim,
                        'en_similarity': en_sim
                    })
        
        return duplicates
    
    def find_unused_keys(self, zh_data, used_keys):
        """查找未使用的键值"""
        all_keys = set(k for k in zh_data.keys() if not k.startswith('@'))
        unused_keys = all_keys - used_keys
        return unused_keys
    
    def find_poorly_named_keys(self, zh_data):
        """查找命名不规范的键值"""
        poorly_named = []
        
        # 不良命名模式
        bad_patterns = [
            r'^label\d*$',      # label, label1, label2
            r'^text\d*$',       # text, text1, text2
            r'^title\d*$',      # title1, title2 (但保留title)
            r'^msg\d*$',        # msg1, msg2
            r'^str\d*$',        # str1, str2
            r'^temp\w*$',       # temp, temporary
            r'^test\w*$',       # test相关
        ]
        
        for key in zh_data.keys():
            if key.startswith('@'):
                continue
                
            for pattern in bad_patterns:
                if re.match(pattern, key, re.IGNORECASE):
                    poorly_named.append({
                        'key': key,
                        'zh_text': zh_data[key],
                        'reason': f'匹配不良命名模式: {pattern}'
                    })
                    break
        
        return poorly_named
    
    def analyze_arb_files(self):
        """分析ARB文件，生成优化报告"""
        print("🔍 开始分析ARB文件...")
        
        zh_data, en_data = self.load_arb_files()
        if not zh_data or not en_data:
            return
        
        # 统计基本信息
        total_keys = len([k for k in zh_data.keys() if not k.startswith('@')])
        print(f"📊 总键值数量: {total_keys}")
        
        # 查找使用的键值
        print("🔍 查找代码中使用的键值...")
        used_keys = self.find_used_keys()
        print(f"📊 已使用键值: {len(used_keys)}")
        
        # 查找重复键值
        print("🔍 查找重复键值...")
        duplicates = self.find_duplicate_keys(zh_data, en_data)
        print(f"📊 疑似重复键值组: {len(duplicates)}")
        
        # 查找未使用键值
        print("🔍 查找未使用键值...")
        unused_keys = self.find_unused_keys(zh_data, used_keys)
        print(f"📊 未使用键值: {len(unused_keys)}")
        
        # 查找命名不规范键值
        print("🔍 查找命名不规范键值...")
        poorly_named = self.find_poorly_named_keys(zh_data)
        print(f"📊 命名不规范键值: {len(poorly_named)}")
        
        # 生成报告
        self.generate_analysis_report(zh_data, en_data, used_keys, duplicates, unused_keys, poorly_named)
    
    def generate_analysis_report(self, zh_data, en_data, used_keys, duplicates, unused_keys, poorly_named):
        """生成分析报告"""
        report_file = "arb_analysis_report.md"
        
        with open(report_file, 'w', encoding='utf-8') as f:
            f.write("# ARB文件分析报告\n\n")
            f.write(f"生成时间: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n\n")
            
            # 基本统计
            total_keys = len([k for k in zh_data.keys() if not k.startswith('@')])
            f.write("## 基本统计\n\n")
            f.write(f"- 总键值数量: {total_keys}\n")
            f.write(f"- 已使用键值: {len(used_keys)}\n")
            f.write(f"- 未使用键值: {len(unused_keys)}\n")
            f.write(f"- 疑似重复键值组: {len(duplicates)}\n")
            f.write(f"- 命名不规范键值: {len(poorly_named)}\n\n")
            
            # 重复键值详情
            if duplicates:
                f.write("## 疑似重复键值\n\n")
                for dup in duplicates[:20]:  # 只显示前20个
                    f.write(f"### {dup['key1']} vs {dup['key2']}\n\n")
                    f.write(f"- **中文相似度**: {dup['zh_similarity']:.2f}\n")
                    f.write(f"- **英文相似度**: {dup['en_similarity']:.2f}\n")
                    f.write(f"- **{dup['key1']}**: {dup['zh_text1']} / {dup['en_text1']}\n")
                    f.write(f"- **{dup['key2']}**: {dup['zh_text2']} / {dup['en_text2']}\n\n")
            
            # 未使用键值
            if unused_keys:
                f.write("## 未使用键值\n\n")
                for key in sorted(list(unused_keys))[:50]:  # 只显示前50个
                    f.write(f"- **{key}**: {zh_data[key]}\n")
                f.write("\n")
            
            # 命名不规范键值
            if poorly_named:
                f.write("## 命名不规范键值\n\n")
                for item in poorly_named:
                    f.write(f"- **{item['key']}**: {item['zh_text']} ({item['reason']})\n")
                f.write("\n")
        
        print(f"✅ 分析报告已生成: {report_file}")
    
    def create_backup(self):
        """创建ARB文件备份"""
        if not os.path.exists(self.backup_dir):
            os.makedirs(self.backup_dir)
        
        shutil.copy2(self.zh_arb_path, os.path.join(self.backup_dir, "app_zh.arb"))
        shutil.copy2(self.en_arb_path, os.path.join(self.backup_dir, "app_en.arb"))
        
        print(f"✅ 备份已创建: {self.backup_dir}")
    
    def generate_key_mapping(self, duplicates, unused_keys):
        """生成键值映射表"""
        mapping = {}
        
        # 处理重复键值 - 保留较短或更语义化的键名
        for dup in duplicates:
            key1, key2 = dup['key1'], dup['key2']
            
            # 简单策略：保留较短的键名，或者字母顺序较前的
            if len(key1) < len(key2) or (len(key1) == len(key2) and key1 < key2):
                mapping[key2] = key1  # key2 -> key1
            else:
                mapping[key1] = key2  # key1 -> key2
        
        # 处理未使用键值 - 标记为删除
        for key in unused_keys:
            mapping[key] = "DELETE"
        
        # 保存映射表
        with open("key_mappings.json", 'w', encoding='utf-8') as f:
            json.dump(mapping, f, ensure_ascii=False, indent=2)
        
        print(f"✅ 键值映射表已生成: key_mappings.json")
        print(f"   - 需要合并的键值: {len([k for k, v in mapping.items() if v != 'DELETE'])}")
        print(f"   - 需要删除的键值: {len([k for k, v in mapping.items() if v == 'DELETE'])}")
        
        return mapping
    
    def optimize_arb_files(self, mapping=None):
        """根据映射表优化ARB文件"""
        if not mapping:
            try:
                with open("key_mappings.json", 'r', encoding='utf-8') as f:
                    mapping = json.load(f)
            except FileNotFoundError:
                print("❌ 未找到映射表文件，请先运行分析")
                return
        
        zh_data, en_data = self.load_arb_files()
        if not zh_data or not en_data:
            return
        
        # 创建备份
        self.create_backup()
        
        # 应用映射
        new_zh_data = OrderedDict()
        new_en_data = OrderedDict()
        
        # 保留元数据
        for key in zh_data:
            if key.startswith('@'):
                new_zh_data[key] = zh_data[key]
                if key in en_data:
                    new_en_data[key] = en_data[key]
        
        # 处理普通键值
        for key in zh_data:
            if key.startswith('@'):
                continue
                
            if key in mapping:
                target = mapping[key]
                if target == "DELETE":
                    print(f"删除键值: {key}")
                    continue
                else:
                    print(f"合并键值: {key} -> {target}")
                    # 如果目标键不存在，使用当前键的值
                    if target not in new_zh_data:
                        new_zh_data[target] = zh_data[key]
                        new_en_data[target] = en_data.get(key, '')
            else:
                # 保留未映射的键值
                new_zh_data[key] = zh_data[key]
                new_en_data[key] = en_data.get(key, '')
        
        # 保存优化后的文件
        with open(self.zh_arb_path, 'w', encoding='utf-8') as f:
            json.dump(new_zh_data, f, ensure_ascii=False, indent=2)
        
        with open(self.en_arb_path, 'w', encoding='utf-8') as f:
            json.dump(new_en_data, f, ensure_ascii=False, indent=2)
        
        print("✅ ARB文件优化完成")
        print(f"   原键值数量: {len([k for k in zh_data.keys() if not k.startswith('@')])}")
        print(f"   新键值数量: {len([k for k in new_zh_data.keys() if not k.startswith('@')])}")

def main():
    parser = argparse.ArgumentParser(description='ARB文件优化器')
    parser.add_argument('--analyze', action='store_true', help='分析ARB文件')
    parser.add_argument('--optimize', action='store_true', help='优化ARB文件')
    parser.add_argument('--backup', action='store_true', help='创建备份')
    parser.add_argument('--generate-mapping', action='store_true', help='生成键值映射表')
    parser.add_argument('--l10n-dir', default='lib/l10n', help='本地化文件目录')
    
    args = parser.parse_args()
    
    optimizer = ARBOptimizer(args.l10n_dir)
    
    if args.analyze:
        optimizer.analyze_arb_files()
    elif args.generate_mapping:
        zh_data, en_data = optimizer.load_arb_files()
        if zh_data and en_data:
            used_keys = optimizer.find_used_keys()
            duplicates = optimizer.find_duplicate_keys(zh_data, en_data)
            unused_keys = optimizer.find_unused_keys(zh_data, used_keys)
            optimizer.generate_key_mapping(duplicates, unused_keys)
    elif args.optimize:
        if args.backup:
            optimizer.create_backup()
        optimizer.optimize_arb_files()
    else:
        print("请指定操作: --analyze, --optimize, --generate-mapping")
        print("使用 --help 查看详细说明")

if __name__ == "__main__":
    main()
