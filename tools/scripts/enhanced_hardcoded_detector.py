#!/usr/bin/env python3
"""
增强的硬编码文本检测器 - 专注于UI界面文本和枚举值显示名称
支持生成通用的检测和替换方案，可重复执行
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
EN_ARB_PATH = os.path.join(ARB_DIR, "app_en.arb")
REPORT_DIR = "hardcoded_detection_report"

# 硬编码文本检测模式 - 分类更精确
DETECTION_PATTERNS = {
    # UI界面文本 - Widget中的直接文本
    "ui_text_widget": [
        r'Text\(\s*[\'\"](.*?[\u4e00-\u9fff].*?)[\'\"](?:\s*[,)])',
        r'Text\.rich.*?text:\s*[\'\"](.*?[\u4e00-\u9fff].*?)[\'\"]',
        r'SelectableText\(\s*[\'\"](.*?[\u4e00-\u9fff].*?)[\'\"]',
        r'RichText.*?text:\s*[\'\"](.*?[\u4e00-\u9fff].*?)[\'\"]',
    ],
    
    # UI属性文本 - 各种UI属性
    "ui_properties": [
        r'hintText:\s*[\'\"](.*?[\u4e00-\u9fff].*?)[\'\"]',
        r'labelText:\s*[\'\"](.*?[\u4e00-\u9fff].*?)[\'\"]',
        r'helperText:\s*[\'\"](.*?[\u4e00-\u9fff].*?)[\'\"]',
        r'errorText:\s*[\'\"](.*?[\u4e00-\u9fff].*?)[\'\"]',
        r'title:\s*[\'\"](.*?[\u4e00-\u9fff].*?)[\'\"]',
        r'subtitle:\s*[\'\"](.*?[\u4e00-\u9fff].*?)[\'\"]',
        r'tooltip:\s*[\'\"](.*?[\u4e00-\u9fff].*?)[\'\"]',
        r'semanticLabel:\s*[\'\"](.*?[\u4e00-\u9fff].*?)[\'\"]',
        r'placeholder:\s*[\'\"](.*?[\u4e00-\u9fff].*?)[\'\"]',
    ],
    
    # 按钮和标签文本
    "ui_buttons_labels": [
        r'ElevatedButton.*?child:\s*Text\(\s*[\'\"](.*?[\u4e00-\u9fff].*?)[\'\"]',
        r'TextButton.*?child:\s*Text\(\s*[\'\"](.*?[\u4e00-\u9fff].*?)[\'\"]',
        r'OutlinedButton.*?child:\s*Text\(\s*[\'\"](.*?[\u4e00-\u9fff].*?)[\'\"]',
        r'FilledButton.*?label:\s*Text\(\s*[\'\"](.*?[\u4e00-\u9fff].*?)[\'\"]',
        r'IconButton.*?tooltip:\s*[\'\"](.*?[\u4e00-\u9fff].*?)[\'\"]',
        r'FloatingActionButton.*?tooltip:\s*[\'\"](.*?[\u4e00-\u9fff].*?)[\'\"]',
    ],
    
    # 对话框和消息
    "ui_dialogs_messages": [
        r'AlertDialog.*?title:\s*Text\(\s*[\'\"](.*?[\u4e00-\u9fff].*?)[\'\"]',
        r'AlertDialog.*?content:\s*Text\(\s*[\'\"](.*?[\u4e00-\u9fff].*?)[\'\"]',
        r'SnackBar.*?content:\s*Text\(\s*[\'\"](.*?[\u4e00-\u9fff].*?)[\'\"]',
        r'showDialog.*?title:\s*[\'\"](.*?[\u4e00-\u9fff].*?)[\'\"]',
        r'ScaffoldMessenger.*?content:\s*Text\(\s*[\'\"](.*?[\u4e00-\u9fff].*?)[\'\"]',
    ],
    
    # 应用栏和导航
    "ui_appbar_navigation": [
        r'AppBar.*?title:\s*Text\(\s*[\'\"](.*?[\u4e00-\u9fff].*?)[\'\"]',
        r'TabBar.*?text:\s*[\'\"](.*?[\u4e00-\u9fff].*?)[\'\"]',
        r'Tab.*?text:\s*[\'\"](.*?[\u4e00-\u9fff].*?)[\'\"]',
        r'BottomNavigationBarItem.*?label:\s*[\'\"](.*?[\u4e00-\u9fff].*?)[\'\"]',
        r'NavigationDestination.*?label:\s*[\'\"](.*?[\u4e00-\u9fff].*?)[\'\"]',
    ],
    
    # 列表和卡片
    "ui_lists_cards": [
        r'ListTile.*?title:\s*Text\(\s*[\'\"](.*?[\u4e00-\u9fff].*?)[\'\"]',
        r'ListTile.*?subtitle:\s*Text\(\s*[\'\"](.*?[\u4e00-\u9fff].*?)[\'\"]',
        r'Card.*?title:\s*Text\(\s*[\'\"](.*?[\u4e00-\u9fff].*?)[\'\"]',
        r'ExpansionTile.*?title:\s*Text\(\s*[\'\"](.*?[\u4e00-\u9fff].*?)[\'\"]',
    ],
    
    # 枚举值显示名称 - 这是重点检测的内容
    "enum_display_names": [
        r'\.displayName\s*=>\s*[\'\"](.*?[\u4e00-\u9fff].*?)[\'\"]',
        r'displayName:\s*[\'\"](.*?[\u4e00-\u9fff].*?)[\'\"]',
        r'label:\s*[\'\"](.*?[\u4e00-\u9fff].*?)[\'\"]',
        r'name:\s*[\'\"](.*?[\u4e00-\u9fff].*?)[\'\"]',
        r'toString\(\)\s*=>\s*[\'\"](.*?[\u4e00-\u9fff].*?)[\'\"]',
        r'case\s+\w+:\s*return\s*[\'\"](.*?[\u4e00-\u9fff].*?)[\'\"]',
        r'when\s+\w+\s*=>\s*[\'\"](.*?[\u4e00-\u9fff].*?)[\'\"]',
    ],
    
    # 字符串常量和变量
    "string_constants": [
        r'static\s+const\s+String\s+\w+\s*=\s*[\'\"](.*?[\u4e00-\u9fff].*?)[\'\"]',
        r'final\s+String\s+\w+\s*=\s*[\'\"](.*?[\u4e00-\u9fff].*?)[\'\"]',
        r'const\s+String\s+\w+\s*=\s*[\'\"](.*?[\u4e00-\u9fff].*?)[\'\"]',
        r'String\s+\w+\s*=\s*[\'\"](.*?[\u4e00-\u9fff].*?)[\'\"]',
    ],
    
    # 异常和错误消息
    "error_messages": [
        r'throw\s+\w*Exception\(\s*[\'\"](.*?[\u4e00-\u9fff].*?)[\'\"]',
        r'throw\s+\w*Error\(\s*[\'\"](.*?[\u4e00-\u9fff].*?)[\'\"]',
        r'assert\(\s*[^,]+,\s*[\'\"](.*?[\u4e00-\u9fff].*?)[\'\"]',
        r'debugPrint\(\s*[\'\"](.*?[\u4e00-\u9fff].*?)[\'\"]',
    ],
}

# 排除模式 - 不检测的内容
EXCLUSION_PATTERNS = [
    r'^\s*//.*$',  # 单行注释
    r'/\*.*?\*/',  # 多行注释
    r'https?://\S+',  # URL
    r'file://\S+',  # 文件路径
    r'package:\S+',  # package引用
    r'import\s+[\'\"]\S+[\'\"]',  # import语句
    r'@\w+\([^)]*\)',  # 注解
]

class EnhancedHardcodedDetector:
    def __init__(self):
        self.ensure_report_dir()
        self.arb_values = self.load_existing_arb_values()
        
    def ensure_report_dir(self):
        """确保报告目录存在"""
        if not os.path.exists(REPORT_DIR):
            os.makedirs(REPORT_DIR)
    
    def load_existing_arb_values(self):
        """加载现有ARB文件中的所有中文值"""
        arb_values = set()
        for arb_path in [ZH_ARB_PATH, EN_ARB_PATH]:
            if os.path.exists(arb_path):
                try:
                    with open(arb_path, 'r', encoding='utf-8') as f:
                        data = json.load(f)
                    for key, value in data.items():
                        if not key.startswith('@') and isinstance(value, str):
                            arb_values.add(value)
                except (json.JSONDecodeError, UnicodeDecodeError) as e:
                    print(f"Warning: Error loading {arb_path}: {e}")
        return arb_values
    
    def is_excluded_line(self, line, match_start, match_end):
        """检查匹配是否在排除模式中"""
        for pattern in EXCLUSION_PATTERNS:
            for match in re.finditer(pattern, line, re.DOTALL):
                if match.start() <= match_start and match.end() >= match_end:
                    return True
        return False
    
    def clean_text_for_key(self, text):
        """清理文本用于生成键名"""
        # 移除特殊字符和空格
        cleaned = re.sub(r'[^\w\u4e00-\u9fff]', '', text)
        # 如果有中文，优先使用中文
        chinese_chars = re.findall(r'[\u4e00-\u9fff]+', cleaned)
        if chinese_chars:
            return ''.join(chinese_chars)[:10]  # 限制长度
        return cleaned[:10]
    
    def generate_arb_key(self, text, context, file_context):
        """根据上下文智能生成ARB键名"""
        # 获取文件上下文信息
        file_parts = file_context.replace('\\', '/').split('/')
        
        # 确定模块名
        module = "common"
        if 'pages' in file_parts:
            idx = file_parts.index('pages')
            if idx + 1 < len(file_parts):
                module = file_parts[idx + 1]
        elif 'widgets' in file_parts:
            module = "widget"
        elif 'components' in file_parts:
            module = "component"
        elif 'viewmodels' in file_parts:
            module = "viewmodel"
        
        # 根据上下文确定前缀
        prefix_map = {
            "ui_text_widget": "text",
            "ui_properties": "hint",
            "ui_buttons_labels": "btn",
            "ui_dialogs_messages": "msg",
            "ui_appbar_navigation": "nav",
            "ui_lists_cards": "list",
            "enum_display_names": "enum",
            "string_constants": "str",
            "error_messages": "error",
        }
        
        prefix = prefix_map.get(context, "text")
        
        # 生成基础键名
        text_part = self.clean_text_for_key(text)
        base_key = f"{module}_{prefix}_{text_part}".lower()
        
        # 移除连续的下划线和特殊字符
        base_key = re.sub(r'_+', '_', base_key)
        base_key = re.sub(r'[^a-z0-9_\u4e00-\u9fff]', '', base_key)
        
        return base_key
    
    def detect_hardcoded_text(self):
        """检测所有硬编码文本"""
        results = defaultdict(list)
        
        # 搜索所有Dart文件
        dart_files = glob.glob(os.path.join(CODE_DIR, "**/*.dart"), recursive=True)
        
        for dart_file in dart_files:
            try:
                with open(dart_file, 'r', encoding='utf-8') as f:
                    content = f.read()
                    lines = content.split('\n')
                
                for line_num, line in enumerate(lines, 1):
                    # 跳过纯英文行和纯符号行
                    if not re.search(r'[\u4e00-\u9fff]', line):
                        continue
                    
                    for context, patterns in DETECTION_PATTERNS.items():
                        for pattern in patterns:
                            for match in re.finditer(pattern, line):
                                if match.groups():
                                    chinese_text = match.group(1)
                                    
                                    # 检查是否包含中文
                                    if not re.search(r'[\u4e00-\u9fff]', chinese_text):
                                        continue
                                    
                                    # 检查是否在排除模式中
                                    if self.is_excluded_line(line, match.start(1), match.end(1)):
                                        continue
                                    
                                    # 检查是否已存在于ARB文件中
                                    if chinese_text in self.arb_values:
                                        continue
                                    
                                    # 清理文本（移除多余空格和特殊字符）
                                    cleaned_text = re.sub(r'\s+', ' ', chinese_text.strip())
                                    
                                    if len(cleaned_text) == 0:
                                        continue
                                    
                                    # 添加到结果
                                    file_path = os.path.relpath(dart_file, CODE_DIR)
                                    suggested_key = self.generate_arb_key(cleaned_text, context, file_path)
                                    
                                    results[context].append({
                                        'file': file_path,
                                        'line': line_num,
                                        'text': cleaned_text,
                                        'original_line': line.strip(),
                                        'suggested_key': suggested_key,
                                        'pattern_matched': pattern,
                                    })
                                    
            except (UnicodeDecodeError, FileNotFoundError) as e:
                print(f"Warning: Error reading {dart_file}: {e}")
        
        return results
    
    def generate_reports(self, detection_results):
        """生成检测报告"""
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        
        # 1. 生成汇总报告
        summary_path = os.path.join(REPORT_DIR, f"hardcoded_summary_{timestamp}.txt")
        with open(summary_path, 'w', encoding='utf-8') as f:
            f.write("=== 硬编码文本检测汇总报告 ===\n")
            f.write(f"检测时间: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n\n")
            
            total_count = sum(len(items) for items in detection_results.values())
            f.write(f"检测到的硬编码文本总数: {total_count}\n\n")
            
            f.write("按类型分布:\n")
            for context, items in detection_results.items():
                f.write(f"  - {context}: {len(items)} 个\n")
            
            f.write("\n" + "="*50 + "\n")
        
        # 2. 生成详细报告
        detail_path = os.path.join(REPORT_DIR, f"hardcoded_detail_{timestamp}.txt")
        with open(detail_path, 'w', encoding='utf-8') as f:
            f.write("=== 硬编码文本详细报告 ===\n\n")
            
            for context, items in detection_results.items():
                f.write(f"\n=== {context.upper()} ({len(items)} 个) ===\n")
                
                for i, item in enumerate(items, 1):
                    f.write(f"\n{i}. 文件: {item['file']}\n")
                    f.write(f"   行号: {item['line']}\n")
                    f.write(f"   文本: \"{item['text']}\"\n")
                    f.write(f"   建议键名: {item['suggested_key']}\n")
                    f.write(f"   代码行: {item['original_line']}\n")
                    f.write(f"   匹配模式: {item['pattern_matched']}\n")
                    f.write("   " + "-"*40 + "\n")
        
        # 3. 生成映射文件（YAML格式，便于用户审核和修改）
        mapping_path = os.path.join(REPORT_DIR, f"hardcoded_mapping_{timestamp}.yaml")
        mapping_data = OrderedDict()
        
        # 构建映射数据
        for context, items in detection_results.items():
            if items:  # 只有当有数据时才添加
                mapping_data[context] = OrderedDict()
                for item in items:
                    key = item['suggested_key']
                    # 避免键重复
                    counter = 1
                    original_key = key
                    while any(key in context_data for context_data in mapping_data.values() if isinstance(context_data, dict)):
                        key = f"{original_key}_{counter}"
                        counter += 1
                    
                    mapping_data[context][key] = {
                        'text_zh': item['text'],
                        'text_en': item['text'],  # 默认与中文相同，需要用户修改
                        'file': item['file'],
                        'line': item['line'],
                        'approved': False,  # 用户审核标志
                    }
        
        with open(mapping_path, 'w', encoding='utf-8') as f:
            f.write("# 硬编码文本映射文件\n")
            f.write("# 请审核以下内容，修改英文翻译，并将 approved 设置为 true\n")
            f.write("# 只有 approved: true 的条目会被处理\n\n")
            yaml.dump(mapping_data, f, default_flow_style=False, allow_unicode=True, sort_keys=False)
        
        # 4. 生成ARB条目预览
        arb_preview_path = os.path.join(REPORT_DIR, f"arb_entries_preview_{timestamp}.json")
        arb_entries = OrderedDict()
        
        for context, items in detection_results.items():
            for item in items:
                key = item['suggested_key']
                # 处理重复键
                counter = 1
                original_key = key
                while key in arb_entries:
                    key = f"{original_key}_{counter}"
                    counter += 1
                
                arb_entries[key] = item['text']
        
        with open(arb_preview_path, 'w', encoding='utf-8') as f:
            json.dump(arb_entries, f, ensure_ascii=False, indent=2)
        
        return {
            'summary': summary_path,
            'detail': detail_path,
            'mapping': mapping_path,
            'arb_preview': arb_preview_path,
            'total_count': sum(len(items) for items in detection_results.values())
        }
    
    def run_detection(self):
        """运行完整的检测流程"""
        print("=== 增强硬编码文本检测器 ===")
        print("正在检测硬编码文本...")
        
        # 执行检测
        results = self.detect_hardcoded_text()
        
        # 生成报告
        report_info = self.generate_reports(results)
        
        # 输出结果
        print(f"\n检测完成！共发现 {report_info['total_count']} 个硬编码文本")
        print("\n按类型分布:")
        for context, items in results.items():
            if items:
                print(f"  - {context}: {len(items)} 个")
        
        print(f"\n生成的文件:")
        print(f"  - 汇总报告: {report_info['summary']}")
        print(f"  - 详细报告: {report_info['detail']}")
        print(f"  - 映射文件: {report_info['mapping']}")
        print(f"  - ARB预览: {report_info['arb_preview']}")
        
        print(f"\n下一步操作:")
        print(f"1. 查看映射文件: {report_info['mapping']}")
        print("2. 审核并修改英文翻译")
        print("3. 将需要处理的条目的 approved 设置为 true")
        print("4. 运行 enhanced_arb_applier.py 执行替换")
        
        return report_info

def main():
    detector = EnhancedHardcodedDetector()
    detector.run_detection()

if __name__ == "__main__":
    main()
