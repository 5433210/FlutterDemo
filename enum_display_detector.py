#!/usr/bin/env python3
"""
智能枚举值检测器 - 专门检测和处理枚举类型的显示名称硬编码
"""

import os
import re
import json
import glob
import yaml
from collections import defaultdict, OrderedDict
from datetime import datetime

# 配置常量
CODE_DIR = "lib"
ARB_DIR = "lib/l10n"
ZH_ARB_PATH = os.path.join(ARB_DIR, "app_zh.arb")
REPORT_DIR = "enum_detection_report"

# 枚举检测模式
ENUM_PATTERNS = {
    # 枚举类定义中的显示名称
    "enum_class_methods": [
        r'String\s+get\s+displayName\s*=>\s*[\'\"](.*?[\u4e00-\u9fff].*?)[\'\"]',
        r'String\s+get\s+label\s*=>\s*[\'\"](.*?[\u4e00-\u9fff].*?)[\'\"]',
        r'String\s+get\s+name\s*=>\s*[\'\"](.*?[\u4e00-\u9fff].*?)[\'\"]',
        r'String\s+get\s+title\s*=>\s*[\'\"](.*?[\u4e00-\u9fff].*?)[\'\"]',
    ],
    
    # toString方法中的硬编码
    "enum_tostring": [
        r'String\s+toString\(\)\s*=>\s*[\'\"](.*?[\u4e00-\u9fff].*?)[\'\"]',
        r'@override\s+String\s+toString\(\)\s*=>\s*[\'\"](.*?[\u4e00-\u9fff].*?)[\'\"]',
    ],
    
    # switch语句中的枚举值处理
    "enum_switch_cases": [
        r'case\s+\w+\.\w+:\s*return\s*[\'\"](.*?[\u4e00-\u9fff].*?)[\'\"]',
        r'case\s+\w+:\s*return\s*[\'\"](.*?[\u4e00-\u9fff].*?)[\'\"]',
    ],
    
    # when表达式中的枚举值处理
    "enum_when_expressions": [
        r'\w+\.\w+\s*=>\s*[\'\"](.*?[\u4e00-\u9fff].*?)[\'\"]',
        r'when\s+\w+\s*=>\s*[\'\"](.*?[\u4e00-\u9fff].*?)[\'\"]',
    ],
    
    # 扩展方法中的枚举处理
    "enum_extensions": [
        r'extension\s+\w+\s+on\s+\w+.*?{.*?[\'\"](.*?[\u4e00-\u9fff].*?)[\'\"].*?}',
        r'String\s+get\s+\w+\s*=>\s*[\'\"](.*?[\u4e00-\u9fff].*?)[\'\"]',
    ],
    
    # Map或List中的枚举值映射
    "enum_mappings": [
        r'\w+\s*:\s*[\'\"](.*?[\u4e00-\u9fff].*?)[\'\"]',
        r'\[\s*[\'\"](.*?[\u4e00-\u9fff].*?)[\'\"].*?\]',
    ],
}

class EnumDisplayNameDetector:
    def __init__(self):
        self.ensure_report_dir()
        self.arb_values = self.load_existing_arb_values()
        self.enum_definitions = {}
        
    def ensure_report_dir(self):
        """确保报告目录存在"""
        if not os.path.exists(REPORT_DIR):
            os.makedirs(REPORT_DIR)
    
    def load_existing_arb_values(self):
        """加载现有ARB文件中的所有值"""
        arb_values = set()
        if os.path.exists(ZH_ARB_PATH):
            try:
                with open(ZH_ARB_PATH, 'r', encoding='utf-8') as f:
                    data = json.load(f)
                for key, value in data.items():
                    if not key.startswith('@') and isinstance(value, str):
                        arb_values.add(value)
            except (json.JSONDecodeError, UnicodeDecodeError) as e:
                print(f"Warning: Error loading {ZH_ARB_PATH}: {e}")
        return arb_values
    
    def find_enum_definitions(self):
        """查找所有枚举定义"""
        enum_pattern = r'enum\s+(\w+)\s*{'
        
        dart_files = glob.glob(os.path.join(CODE_DIR, "**/*.dart"), recursive=True)
        
        for dart_file in dart_files:
            try:
                with open(dart_file, 'r', encoding='utf-8') as f:
                    content = f.read()
                
                # 查找枚举定义
                for match in re.finditer(enum_pattern, content):
                    enum_name = match.group(1)
                    file_path = os.path.relpath(dart_file, CODE_DIR)
                    
                    # 提取枚举值
                    enum_content_start = match.end()
                    brace_count = 1
                    enum_content_end = enum_content_start
                    
                    for i, char in enumerate(content[enum_content_start:], enum_content_start):
                        if char == '{':
                            brace_count += 1
                        elif char == '}':
                            brace_count -= 1
                            if brace_count == 0:
                                enum_content_end = i
                                break
                    
                    enum_content = content[enum_content_start:enum_content_end]
                    enum_values = re.findall(r'(\w+)(?:\s*,|\s*;|\s*})', enum_content)
                    
                    self.enum_definitions[enum_name] = {
                        'file': file_path,
                        'values': enum_values,
                        'content': enum_content
                    }
                    
            except (UnicodeDecodeError, FileNotFoundError) as e:
                print(f"Warning: Error reading {dart_file}: {e}")
    
    def analyze_enum_usage(self, enum_name, enum_info):
        """分析特定枚举的使用情况"""
        usage_analysis = {
            'enum_name': enum_name,
            'file': enum_info['file'],
            'values': enum_info['values'],
            'hardcoded_displays': [],
            'potential_l10n_needed': []
        }
        
        # 在整个代码库中搜索此枚举的使用
        search_patterns = [
            f'{enum_name}\\.\\w+',  # 枚举值使用
            f'on\\s+{enum_name}',   # 扩展方法
            f'case\\s+{enum_name}\\.\\w+',  # switch case
        ]
        
        dart_files = glob.glob(os.path.join(CODE_DIR, "**/*.dart"), recursive=True)
        
        for dart_file in dart_files:
            try:
                with open(dart_file, 'r', encoding='utf-8') as f:
                    content = f.read()
                    lines = content.split('\n')
                
                file_path = os.path.relpath(dart_file, CODE_DIR)
                
                for line_num, line in enumerate(lines, 1):
                    # 检查是否包含此枚举的使用
                    for pattern in search_patterns:
                        if re.search(pattern, line):
                            # 检查这一行是否包含硬编码中文
                            chinese_matches = re.findall(r'[\'\"](.*?[\u4e00-\u9fff].*?)[\'\"]', line)
                            for chinese_text in chinese_matches:
                                if chinese_text not in self.arb_values:
                                    usage_analysis['hardcoded_displays'].append({
                                        'file': file_path,
                                        'line': line_num,
                                        'text': chinese_text,
                                        'context': line.strip(),
                                        'enum_value': self.extract_enum_value(line, enum_name)
                                    })
                
            except (UnicodeDecodeError, FileNotFoundError) as e:
                print(f"Warning: Error reading {dart_file}: {e}")
        
        return usage_analysis
    
    def extract_enum_value(self, line, enum_name):
        """从代码行中提取枚举值"""
        pattern = f'{enum_name}\\.(\w+)'
        match = re.search(pattern, line)
        return match.group(1) if match else None
    
    def generate_enum_arb_keys(self, enum_name, enum_value, display_text):
        """为枚举生成ARB键名"""
        # 使用枚举名和值生成键
        base_key = f"enum_{enum_name.lower()}_{enum_value.lower()}"
        
        # 清理键名
        base_key = re.sub(r'[^a-z0-9_]', '', base_key.lower())
        
        return base_key
    
    def detect_enum_hardcoded_text(self):
        """检测枚举相关的硬编码文本"""
        print("正在查找枚举定义...")
        self.find_enum_definitions()
        print(f"找到 {len(self.enum_definitions)} 个枚举定义")
        
        all_results = []
        
        # 分析每个枚举
        for enum_name, enum_info in self.enum_definitions.items():
            print(f"分析枚举: {enum_name}")
            usage_analysis = self.analyze_enum_usage(enum_name, enum_info)
            
            if usage_analysis['hardcoded_displays']:
                all_results.append(usage_analysis)
        
        # 直接模式检测（不依赖枚举定义）
        print("执行直接模式检测...")
        direct_results = self.direct_pattern_detection()
        
        return {
            'enum_based': all_results,
            'pattern_based': direct_results
        }
    
    def direct_pattern_detection(self):
        """直接模式检测"""
        results = defaultdict(list)
        
        dart_files = glob.glob(os.path.join(CODE_DIR, "**/*.dart"), recursive=True)
        
        for dart_file in dart_files:
            try:
                with open(dart_file, 'r', encoding='utf-8') as f:
                    content = f.read()
                    lines = content.split('\n')
                
                file_path = os.path.relpath(dart_file, CODE_DIR)
                
                for line_num, line in enumerate(lines, 1):
                    if not re.search(r'[\u4e00-\u9fff]', line):
                        continue
                    
                    for pattern_type, patterns in ENUM_PATTERNS.items():
                        for pattern in patterns:
                            for match in re.finditer(pattern, line):
                                if match.groups():
                                    chinese_text = match.group(1)
                                    
                                    if chinese_text in self.arb_values:
                                        continue
                                    
                                    cleaned_text = re.sub(r'\s+', ' ', chinese_text.strip())
                                    if len(cleaned_text) == 0:
                                        continue
                                    
                                    results[pattern_type].append({
                                        'file': file_path,
                                        'line': line_num,
                                        'text': cleaned_text,
                                        'context': line.strip(),
                                        'pattern': pattern
                                    })
                                    
            except (UnicodeDecodeError, FileNotFoundError) as e:
                print(f"Warning: Error reading {dart_file}: {e}")
        
        return results
    
    def generate_enum_reports(self, detection_results):
        """生成枚举检测报告"""
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        
        # 1. 枚举分析报告
        enum_report_path = os.path.join(REPORT_DIR, f"enum_analysis_{timestamp}.txt")
        with open(enum_report_path, 'w', encoding='utf-8') as f:
            f.write("=== 枚举显示名称分析报告 ===\n")
            f.write(f"生成时间: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n\n")
            
            f.write(f"枚举定义总数: {len(self.enum_definitions)}\n")
            f.write(f"有硬编码显示文本的枚举: {len(detection_results['enum_based'])}\n\n")
            
            # 枚举定义列表
            f.write("=== 所有枚举定义 ===\n")
            for enum_name, enum_info in self.enum_definitions.items():
                f.write(f"枚举名: {enum_name}\n")
                f.write(f"文件: {enum_info['file']}\n")
                f.write(f"值: {', '.join(enum_info['values'])}\n")
                f.write("-" * 40 + "\n")
            
            # 硬编码分析
            f.write("\n=== 硬编码显示文本分析 ===\n")
            for enum_analysis in detection_results['enum_based']:
                f.write(f"\n枚举: {enum_analysis['enum_name']}\n")
                f.write(f"文件: {enum_analysis['file']}\n")
                f.write(f"硬编码显示文本数量: {len(enum_analysis['hardcoded_displays'])}\n")
                
                for display in enum_analysis['hardcoded_displays']:
                    f.write(f"  - 文件: {display['file']}, 行: {display['line']}\n")
                    f.write(f"    文本: \"{display['text']}\"\n")
                    f.write(f"    枚举值: {display['enum_value']}\n")
                    f.write(f"    上下文: {display['context']}\n")
                
                f.write("-" * 50 + "\n")
        
        # 2. 模式检测报告
        pattern_report_path = os.path.join(REPORT_DIR, f"enum_pattern_detection_{timestamp}.txt")
        with open(pattern_report_path, 'w', encoding='utf-8') as f:
            f.write("=== 枚举模式检测报告 ===\n")
            f.write(f"生成时间: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n\n")
            
            total_pattern_matches = sum(len(items) for items in detection_results['pattern_based'].values())
            f.write(f"模式匹配总数: {total_pattern_matches}\n\n")
            
            for pattern_type, items in detection_results['pattern_based'].items():
                f.write(f"=== {pattern_type.upper()} ({len(items)} 个) ===\n")
                
                for item in items:
                    f.write(f"文件: {item['file']}\n")
                    f.write(f"行号: {item['line']}\n")
                    f.write(f"文本: \"{item['text']}\"\n")
                    f.write(f"上下文: {item['context']}\n")
                    f.write(f"匹配模式: {item['pattern']}\n")
                    f.write("-" * 30 + "\n")
                
                f.write("\n")
        
        # 3. 生成映射文件
        mapping_path = os.path.join(REPORT_DIR, f"enum_mapping_{timestamp}.yaml")
        mapping_data = OrderedDict()
        
        # 基于枚举的映射
        if detection_results['enum_based']:
            mapping_data['enum_based_mappings'] = OrderedDict()
            
            for enum_analysis in detection_results['enum_based']:
                enum_name = enum_analysis['enum_name']
                enum_mappings = OrderedDict()
                
                for display in enum_analysis['hardcoded_displays']:
                    enum_value = display['enum_value'] or 'unknown'
                    key = self.generate_enum_arb_keys(enum_name, enum_value, display['text'])
                    
                    enum_mappings[key] = {
                        'text_zh': display['text'],
                        'text_en': display['text'],  # 需要用户翻译
                        'enum_name': enum_name,
                        'enum_value': enum_value,
                        'file': display['file'],
                        'line': display['line'],
                        'approved': False
                    }
                
                if enum_mappings:
                    mapping_data['enum_based_mappings'][enum_name] = enum_mappings
        
        # 基于模式的映射
        if detection_results['pattern_based']:
            mapping_data['pattern_based_mappings'] = OrderedDict()
            
            for pattern_type, items in detection_results['pattern_based'].items():
                if items:
                    pattern_mappings = OrderedDict()
                    
                    for i, item in enumerate(items):
                        key = f"enum_{pattern_type}_{i+1}"
                        pattern_mappings[key] = {
                            'text_zh': item['text'],
                            'text_en': item['text'],  # 需要用户翻译
                            'pattern_type': pattern_type,
                            'file': item['file'],
                            'line': item['line'],
                            'approved': False
                        }
                    
                    mapping_data['pattern_based_mappings'][pattern_type] = pattern_mappings
        
        with open(mapping_path, 'w', encoding='utf-8') as f:
            f.write("# 枚举显示名称映射文件\n")
            f.write("# 请审核以下内容，修改英文翻译，并将 approved 设置为 true\n")
            f.write("# 只有 approved: true 的条目会被处理\n\n")
            yaml.dump(mapping_data, f, default_flow_style=False, allow_unicode=True, sort_keys=False)
        
        return {
            'enum_analysis': enum_report_path,
            'pattern_detection': pattern_report_path,
            'mapping': mapping_path,
            'total_enums': len(self.enum_definitions),
            'total_hardcoded': sum(len(enum_analysis['hardcoded_displays']) for enum_analysis in detection_results['enum_based']),
            'total_pattern_matches': sum(len(items) for items in detection_results['pattern_based'].values())
        }
    
    def run_detection(self):
        """运行完整的枚举检测流程"""
        print("=== 智能枚举值检测器 ===")
        print("正在检测枚举显示名称硬编码...")
        
        # 执行检测
        results = self.detect_enum_hardcoded_text()
        
        # 生成报告
        report_info = self.generate_enum_reports(results)
        
        # 输出结果
        print(f"\n检测完成！")
        print(f"枚举定义总数: {report_info['total_enums']}")
        print(f"基于枚举的硬编码文本: {report_info['total_hardcoded']} 个")
        print(f"基于模式的硬编码文本: {report_info['total_pattern_matches']} 个")
        
        print(f"\n生成的文件:")
        print(f"  - 枚举分析报告: {report_info['enum_analysis']}")
        print(f"  - 模式检测报告: {report_info['pattern_detection']}")
        print(f"  - 映射文件: {report_info['mapping']}")
        
        print(f"\n下一步操作:")
        print(f"1. 查看映射文件: {report_info['mapping']}")
        print("2. 审核并修改英文翻译")
        print("3. 将需要处理的条目的 approved 设置为 true")
        print("4. 运行 enhanced_arb_applier.py 执行替换")
        
        return report_info

def main():
    detector = EnumDisplayNameDetector()
    detector.run_detection()

if __name__ == "__main__":
    main()
