#!/usr/bin/env python3
"""
多语言硬编码文本检测器 - 支持中文和英文硬编码检测
包含ARB键复用、智能命名和精确过滤功能
"""

import os
import re
import json
import yaml
import glob
from collections import defaultdict, OrderedDict
from datetime import datetime
from difflib import SequenceMatcher

# 配置常量
CODE_DIR = "lib"
ARB_DIR = "lib/l10n"
ZH_ARB_PATH = os.path.join(ARB_DIR, "app_zh.arb")
EN_ARB_PATH = os.path.join(ARB_DIR, "app_en.arb")
REPORT_DIR = "multilingual_hardcoded_report"

# 中文检测模式
CHINESE_PATTERNS = {
    # UI界面文本
    "ui_text_widget": [
        r'Text\(\s*[\'\"](.*?[\u4e00-\u9fff].*?)[\'\"](?:\s*[,)])',
        r'SelectableText\(\s*[\'\"](.*?[\u4e00-\u9fff].*?)[\'\"]',
        r'RichText.*?text:\s*[\'\"](.*?[\u4e00-\u9fff].*?)[\'\"]',
    ],
    
    # UI属性
    "ui_properties": [
        r'hintText:\s*[\'\"](.*?[\u4e00-\u9fff].*?)[\'\"]',
        r'labelText:\s*[\'\"](.*?[\u4e00-\u9fff].*?)[\'\"]',
        r'title:\s*[\'\"](.*?[\u4e00-\u9fff].*?)[\'\"]',
        r'subtitle:\s*[\'\"](.*?[\u4e00-\u9fff].*?)[\'\"]',
        r'tooltip:\s*[\'\"](.*?[\u4e00-\u9fff].*?)[\'\"]',
        r'semanticLabel:\s*[\'\"](.*?[\u4e00-\u9fff].*?)[\'\"]',
    ],
    
    # 按钮和标签
    "ui_buttons_labels": [
        r'ElevatedButton.*?child:\s*Text\(\s*[\'\"](.*?[\u4e00-\u9fff].*?)[\'\"]',
        r'TextButton.*?child:\s*Text\(\s*[\'\"](.*?[\u4e00-\u9fff].*?)[\'\"]',
        r'FilledButton.*?label:\s*Text\(\s*[\'\"](.*?[\u4e00-\u9fff].*?)[\'\"]',
        r'IconButton.*?tooltip:\s*[\'\"](.*?[\u4e00-\u9fff].*?)[\'\"]',
    ],
    
    # 对话框和消息
    "ui_dialogs_messages": [
        r'AlertDialog.*?title:\s*Text\(\s*[\'\"](.*?[\u4e00-\u9fff].*?)[\'\"]',
        r'AlertDialog.*?content:\s*Text\(\s*[\'\"](.*?[\u4e00-\u9fff].*?)[\'\"]',
        r'SnackBar.*?content:\s*Text\(\s*[\'\"](.*?[\u4e00-\u9fff].*?)[\'\"]',
    ],
    
    # 应用栏和导航
    "ui_appbar_navigation": [
        r'AppBar.*?title:\s*Text\(\s*[\'\"](.*?[\u4e00-\u9fff].*?)[\'\"]',
        r'Tab.*?text:\s*[\'\"](.*?[\u4e00-\u9fff].*?)[\'\"]',
        r'BottomNavigationBarItem.*?label:\s*[\'\"](.*?[\u4e00-\u9fff].*?)[\'\"]',
    ],
}

# 英文检测模式 - 简化版本，更稳定
ENGLISH_PATTERNS = {
    # UI界面文本 - 基本的Text Widget
    "ui_text_widget": [
        r"(?:const\s+)?Text\(\s*'([A-Z][A-Za-z\s]+)'\s*[,)]",
        r'(?:const\s+)?Text\(\s*"([A-Z][A-Za-z\s]+)"\s*[,)]',
        r"(?:const\s+)?SelectableText\(\s*'([A-Z][A-Za-z\s]+)'\s*[,)]",
        r'(?:const\s+)?SelectableText\(\s*"([A-Z][A-Za-z\s]+)"\s*[,)]',
    ],
    
    # UI属性
    "ui_properties": [
        r"hintText:\s*'([A-Z][A-Za-z\s]+)'",
        r'hintText:\s*"([A-Z][A-Za-z\s]+)"',
        r"labelText:\s*'([A-Z][A-Za-z\s]+)'",
        r'labelText:\s*"([A-Z][A-Za-z\s]+)"',
        r"title:\s*'([A-Z][A-Za-z\s]+)'",
        r'title:\s*"([A-Z][A-Za-z\s]+)"',
        r"subtitle:\s*'([A-Z][A-Za-z\s]+)'",
        r'subtitle:\s*"([A-Z][A-Za-z\s]+)"',
        r"tooltip:\s*'([A-Z][A-Za-z\s]+)'",
        r'tooltip:\s*"([A-Z][A-Za-z\s]+)"',
        r"semanticLabel:\s*'([A-Z][A-Za-z\s]+)'",
        r'semanticLabel:\s*"([A-Z][A-Za-z\s]+)"',
        r"placeholder:\s*'([A-Z][A-Za-z\s]+)'",
        r'placeholder:\s*"([A-Z][A-Za-z\s]+)"',
    ],
    
    # 按钮和标签
    "ui_buttons_labels": [
        r"child:\s*(?:const\s+)?Text\(\s*'([A-Z][A-Za-z\s]+)'\s*[,)]",
        r'child:\s*(?:const\s+)?Text\(\s*"([A-Z][A-Za-z\s]+)"\s*[,)]',
        r"label:\s*(?:const\s+)?Text\(\s*'([A-Z][A-Za-z\s]+)'\s*[,)]",
        r'label:\s*(?:const\s+)?Text\(\s*"([A-Z][A-Za-z\s]+)"\s*[,)]',
    ],
    
    # 对话框和消息
    "ui_dialogs_messages": [
        r"AlertDialog.*?title:\s*(?:const\s+)?Text\(\s*'([A-Z][A-Za-z\s]+)'\s*[,)]",
        r'AlertDialog.*?title:\s*(?:const\s+)?Text\(\s*"([A-Z][A-Za-z\s]+)"\s*[,)]',
        r"AlertDialog.*?content:\s*(?:const\s+)?Text\(\s*'([A-Z][A-Za-z\s]+)'\s*[,)]",
        r'AlertDialog.*?content:\s*(?:const\s+)?Text\(\s*"([A-Z][A-Za-z\s]+)"\s*[,)]',
        r"SnackBar.*?content:\s*(?:const\s+)?Text\(\s*'([A-Z][A-Za-z\s]+)'\s*[,)]",
        r'SnackBar.*?content:\s*(?:const\s+)?Text\(\s*"([A-Z][A-Za-z\s]+)"\s*[,)]',
    ],
    
    # 应用栏和导航
    "ui_appbar_navigation": [
        r"AppBar.*?title:\s*(?:const\s+)?Text\(\s*'([A-Z][A-Za-z\s]+)'\s*[,)]",
        r'AppBar.*?title:\s*(?:const\s+)?Text\(\s*"([A-Z][A-Za-z\s]+)"\s*[,)]',
        r"text:\s*'([A-Z][A-Za-z\s]+)'",
        r'text:\s*"([A-Z][A-Za-z\s]+)"',
        r"label:\s*'([A-Z][A-Za-z\s]+)'",
        r'label:\s*"([A-Z][A-Za-z\s]+)"',
    ],
    
    # 列表和卡片
    "ui_lists_cards": [
        r"ListTile.*?title:\s*(?:const\s+)?Text\(\s*'([A-Z][A-Za-z\s]+)'\s*[,)]",
        r'ListTile.*?title:\s*(?:const\s+)?Text\(\s*"([A-Z][A-Za-z\s]+)"\s*[,)]',
        r"ListTile.*?subtitle:\s*(?:const\s+)?Text\(\s*'([A-Z][A-Za-z\s]+)'\s*[,)]",
        r'ListTile.*?subtitle:\s*(?:const\s+)?Text\(\s*"([A-Z][A-Za-z\s]+)"\s*[,)]',
        r"ExpansionTile.*?title:\s*(?:const\s+)?Text\(\s*'([A-Z][A-Za-z\s]+)'\s*[,)]",
        r'ExpansionTile.*?title:\s*(?:const\s+)?Text\(\s*"([A-Z][A-Za-z\s]+)"\s*[,)]',
    ],
}

# 排除模式 - 不应该被检测的内容
EXCLUSION_PATTERNS = [
    r'^\s*//.*$',  # 单行注释
    r'/\*.*?\*/',  # 多行注释
    r'https?://[^\s]+',  # URL
    r'file://[^\s]+',  # 文件路径
    r'package:[^\s]+',  # package引用
    r'import\s+[\'"][^\'"]+[\'"]',  # import语句
    r'@\w+\([^)]*\)',  # 注解
    r'print\(\s*[\'"]',  # print语句
    r'debugPrint\(\s*[\'"]',  # debugPrint语句
    r'log\(\s*[\'"]',  # log语句
    r'logger\.\w+\(\s*[\'"]',  # logger语句
    r'throw\s+\w*Exception',  # 异常抛出
    r'assert\(\s*[^,]+,\s*[\'"]',  # 断言
]

# 英文排除词汇 - 这些不应该被检测为硬编码
ENGLISH_EXCLUSIONS = {
    # 单个字母或简短标识符
    'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 
    'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z',
    'Ok', 'No', 'On', 'Off', 'Up', 'Go', 'Do', 'Is', 'If', 'Or', 'At',
    
    # 技术术语
    'Debug', 'Error', 'Warning', 'Info', 'Trace', 'Fatal',
    'HTTP', 'HTTPS', 'JSON', 'XML', 'HTML', 'CSS', 'SQL',
    'UUID', 'API', 'URL', 'URI', 'TCP', 'UDP', 'FTP',
    
    # 编程相关
    'null', 'true', 'false', 'void', 'int', 'double', 'String', 'bool',
    'var', 'final', 'const', 'static', 'async', 'await',
    
    # 文件扩展名和路径
    'dart', 'json', 'yaml', 'xml', 'png', 'jpg', 'jpeg', 'gif', 'svg',
    'lib', 'src', 'test', 'build', 'assets', 'fonts',
    
    # 颜色和样式
    'Red', 'Green', 'Blue', 'Black', 'White', 'Gray', 'Yellow', 'Purple',
    'Bold', 'Italic', 'Normal', 'Left', 'Right', 'Center', 'Top', 'Bottom',
    
    # 数学和单位
    'px', 'dp', 'sp', 'em', 'rem', 'pt', 'mm', 'cm', 'in',
    'deg', 'rad', 'ms', 'sec', 'min', 'hour', 'day',
}

class MultilingualHardcodedDetector:
    def __init__(self):
        self.ensure_report_dir()
        self.zh_arb_data, self.en_arb_data = self.load_arb_files()
        self.generated_keys = set()
        
    def ensure_report_dir(self):
        """确保报告目录存在"""
        if not os.path.exists(REPORT_DIR):
            os.makedirs(REPORT_DIR)
    
    def load_arb_files(self):
        """加载ARB文件"""
        zh_data = {}
        en_data = {}
        
        if os.path.exists(ZH_ARB_PATH):
            try:
                with open(ZH_ARB_PATH, 'r', encoding='utf-8') as f:
                    zh_data = json.load(f)
            except Exception as e:
                print(f"Warning: Error loading {ZH_ARB_PATH}: {e}")
        
        if os.path.exists(EN_ARB_PATH):
            try:
                with open(EN_ARB_PATH, 'r', encoding='utf-8') as f:
                    en_data = json.load(f)
            except Exception as e:
                print(f"Warning: Error loading {EN_ARB_PATH}: {e}")
        
        return zh_data, en_data
    
    def is_excluded_content(self, line, match_start, match_end):
        """检查是否应该排除的内容"""
        for pattern in EXCLUSION_PATTERNS:
            if re.search(pattern, line):
                return True
        
        # 检查是否在注释中
        line_before_match = line[:match_start]
        if '//' in line_before_match:
            return True
        
        return False
    
    def is_valid_english_text(self, text):
        """验证是否为有效的英文UI文本"""
        # 去除前后空格
        text = text.strip()
        
        # 长度验证
        if len(text) < 2 or len(text) > 100:
            return False
        
        # 排除单个字母或短词
        if text in ENGLISH_EXCLUSIONS:
            return False
        
        # 排除全大写的技术术语（超过3个字符）
        if len(text) > 3 and text.isupper():
            return False
        
        # 排除包含数字的技术标识符
        if re.search(r'\d', text):
            return False
        
        # 排除包含下划线、点号等技术符号的文本
        if re.search(r'[._@$#%^&*()+=\[\]{}|\\:";\'<>?/]', text):
            return False
        
        # 排除驼峰命名的变量名（如 "myVariable"）
        if re.match(r'^[a-z][A-Za-z]+$', text) and any(c.isupper() for c in text[1:]):
            return False
        
        # 排除常见的编程术语
        programming_terms = {
            'Widget', 'State', 'Builder', 'Provider', 'Manager', 'Controller', 
            'Repository', 'Service', 'Factory', 'Singleton', 'Interface',
            'Abstract', 'Implementation', 'Extension', 'Exception', 'Handler',
            'Listener', 'Observer', 'Strategy', 'Factory', 'Decorator',
            'Adapter', 'Facade', 'Proxy', 'Command', 'Template'
        }
        if text in programming_terms:
            return False
        
        # 必须以大写字母开头，这是UI文本的常见特征
        if not text[0].isupper():
            return False
        
        # 包含至少一个完整单词（2个字符以上）
        words = re.findall(r'[A-Za-z]+', text)
        if not words or all(len(word) < 2 for word in words):
            return False
        
        return True
    
    def find_similar_arb_key(self, text, language='zh'):
        """查找相似的ARB键"""
        arb_data = self.zh_arb_data if language == 'zh' else self.en_arb_data
        
        best_key = None
        best_similarity = 0.8  # 最低相似度阈值
        
        for key, value in arb_data.items():
            if key.startswith('@') or not isinstance(value, str):
                continue
            
            # 精确匹配
            if value == text:
                return key, 1.0
            
            # 相似度匹配
            similarity = SequenceMatcher(None, text.lower(), value.lower()).ratio()
            if similarity > best_similarity:
                best_similarity = similarity
                best_key = key
        
        return (best_key, best_similarity) if best_key else (None, 0)
    
    def generate_smart_key(self, text, context, file_path, language='zh'):
        """智能生成ARB键名"""
        # 获取模块信息
        file_parts = file_path.replace('\\', '/').split('/')
        module = "common"
        
        if 'pages' in file_parts:
            idx = file_parts.index('pages')
            if idx + 1 < len(file_parts):
                module = file_parts[idx + 1]
        elif 'widgets' in file_parts:
            module = "widget"
        elif 'components' in file_parts:
            module = "component"
        
        # 上下文前缀
        context_prefixes = {
            "ui_text_widget": "",
            "ui_properties": "",
            "ui_buttons_labels": "",
            "ui_dialogs_messages": "",
            "ui_appbar_navigation": "",
            "ui_lists_cards": "",
        }
        
        prefix = context_prefixes.get(context, "")
        
        # 生成基础键名
        if language == 'zh':
            # 中文：提取关键词
            clean_text = re.sub(r'[^\w\u4e00-\u9fff]', '', text)
            chinese_chars = re.findall(r'[\u4e00-\u9fff]+', clean_text)
            if chinese_chars:
                key_part = ''.join(chinese_chars)[:8]
            else:
                key_part = clean_text[:8]
        else:
            # 英文：使用驼峰命名
            words = re.findall(r'[A-Za-z]+', text)
            if len(words) == 1:
                key_part = words[0].lower()
            elif len(words) <= 4:
                key_part = words[0].lower() + ''.join(word.capitalize() for word in words[1:])
            else:
                # 太多词，取前4个
                key_part = words[0].lower() + ''.join(word.capitalize() for word in words[1:4])
        
        # 组合键名
        if module == "common":
            base_key = f"{prefix}{key_part}" if prefix else key_part
        else:
            base_key = f"{module}{prefix.capitalize()}{key_part.capitalize()}" if prefix else f"{module}{key_part.capitalize()}"
        
        # 处理冲突
        final_key = base_key
        counter = 1
        while (final_key in self.generated_keys or 
               final_key in self.zh_arb_data or 
               final_key in self.en_arb_data):
            final_key = f"{base_key}{counter}"
            counter += 1
        
        self.generated_keys.add(final_key)
        return final_key
    
    def detect_hardcoded_text(self):
        """检测硬编码文本"""
        results = {
            'chinese': defaultdict(list),
            'english': defaultdict(list)
        }
        
        dart_files = glob.glob(os.path.join(CODE_DIR, "**/*.dart"), recursive=True)
        
        for dart_file in dart_files:
            try:
                with open(dart_file, 'r', encoding='utf-8') as f:
                    content = f.read()
                    lines = content.split('\n')
                
                file_path = os.path.relpath(dart_file, CODE_DIR)
                
                # 检测中文硬编码
                for line_num, line in enumerate(lines, 1):
                    if re.search(r'[\u4e00-\u9fff]', line):
                        self._detect_patterns(line, line_num, file_path, CHINESE_PATTERNS, 
                                           results['chinese'], 'zh')
                
                # 检测英文硬编码
                for line_num, line in enumerate(lines, 1):
                    if re.search(r'[A-Za-z]', line) and not re.search(r'[\u4e00-\u9fff]', line):
                        self._detect_patterns(line, line_num, file_path, ENGLISH_PATTERNS, 
                                           results['english'], 'en')
                                
            except Exception as e:
                print(f"Warning: Error reading {dart_file}: {e}")
        
        return results
    
    def _detect_patterns(self, line, line_num, file_path, patterns, results, language):
        """检测特定语言的模式"""
        for context, pattern_list in patterns.items():
            for pattern in pattern_list:
                for match in re.finditer(pattern, line):
                    if match.groups():
                        text = match.group(1).strip()
                        
                        # 排除检查
                        if self.is_excluded_content(line, match.start(1), match.end(1)):
                            continue
                        
                        # 语言特定验证
                        if language == 'en' and not self.is_valid_english_text(text):
                            continue
                        
                        if language == 'zh' and len(text) == 0:
                            continue
                        
                        # 查找相似ARB键
                        similar_key, similarity = self.find_similar_arb_key(text, language)
                        
                        if similar_key and similarity >= 0.9:
                            # 复用现有键
                            results[context].append({
                                'file': file_path,
                                'line': line_num,
                                'text': text,
                                'action': 'reuse',
                                'arb_key': similar_key,
                                'similarity': similarity,
                                'language': language,
                            })
                        else:
                            # 生成新键
                            new_key = self.generate_smart_key(text, context, file_path, language)
                            results[context].append({
                                'file': file_path,
                                'line': line_num,
                                'text': text,
                                'action': 'create',
                                'suggested_key': new_key,
                                'language': language,
                            })
    
    def generate_reports(self, results):
        """生成检测报告"""
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        
        # 统计
        chinese_total = sum(len(items) for items in results['chinese'].values())
        english_total = sum(len(items) for items in results['english'].values())
        
        chinese_reuse = sum(1 for items in results['chinese'].values() 
                          for item in items if item['action'] == 'reuse')
        english_reuse = sum(1 for items in results['english'].values() 
                          for item in items if item['action'] == 'reuse')
        
        # 汇总报告
        summary_path = os.path.join(REPORT_DIR, f"multilingual_summary_{timestamp}.txt")
        with open(summary_path, 'w', encoding='utf-8') as f:
            f.write("=== 多语言硬编码文本检测汇总报告 ===\n")
            f.write(f"检测时间: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n\n")
            
            f.write("=== 中文硬编码检测结果 ===\n")
            f.write(f"检测总数: {chinese_total}\n")
            f.write(f"复用ARB键: {chinese_reuse}\n")
            f.write(f"新建键: {chinese_total - chinese_reuse}\n\n")
            
            f.write("中文硬编码按类型分布:\n")
            for context, items in results['chinese'].items():
                if items:
                    f.write(f"  - {context}: {len(items)}\n")
            
            f.write("\n=== 英文硬编码检测结果 ===\n")
            f.write(f"检测总数: {english_total}\n")
            f.write(f"复用ARB键: {english_reuse}\n")
            f.write(f"新建键: {english_total - english_reuse}\n\n")
            
            f.write("英文硬编码按类型分布:\n")
            for context, items in results['english'].items():
                if items:
                    f.write(f"  - {context}: {len(items)}\n")
            
            f.write(f"\n=== 总体统计 ===\n")
            f.write(f"硬编码文本总数: {chinese_total + english_total}\n")
            f.write(f"ARB键复用总数: {chinese_reuse + english_reuse}\n")
            f.write(f"新建键总数: {(chinese_total - chinese_reuse) + (english_total - english_reuse)}\n")
        
        # 详细报告
        detail_path = os.path.join(REPORT_DIR, f"multilingual_detail_{timestamp}.txt")
        with open(detail_path, 'w', encoding='utf-8') as f:
            f.write("=== 多语言硬编码文本详细报告 ===\n\n")
            
            f.write("=== 中文硬编码详情 ===\n")
            for context, items in results['chinese'].items():
                if items:
                    f.write(f"\n--- {context.upper()} ({len(items)} 个) ---\n")
                    for item in items:
                        f.write(f"文件: {item['file']}, 行: {item['line']}\n")
                        f.write(f"文本: \"{item['text']}\"\n")
                        if item['action'] == 'reuse':
                            f.write(f"复用键: {item['arb_key']} (相似度: {item['similarity']:.2f})\n")
                        else:
                            f.write(f"建议键: {item['suggested_key']}\n")
                        f.write("\n")
            
            f.write("\n=== 英文硬编码详情 ===\n")
            for context, items in results['english'].items():
                if items:
                    f.write(f"\n--- {context.upper()} ({len(items)} 个) ---\n")
                    for item in items:
                        f.write(f"文件: {item['file']}, 行: {item['line']}\n")
                        f.write(f"文本: \"{item['text']}\"\n")
                        if item['action'] == 'reuse':
                            f.write(f"复用键: {item['arb_key']} (相似度: {item['similarity']:.2f})\n")
                        else:
                            f.write(f"建议键: {item['suggested_key']}\n")
                        f.write("\n")
        
        # 映射文件
        mapping_path = os.path.join(REPORT_DIR, f"multilingual_mapping_{timestamp}.yaml")
        mapping_data = OrderedDict()
        
        # 中文映射
        if any(results['chinese'].values()):
            mapping_data['chinese_mappings'] = OrderedDict()
            for context, items in results['chinese'].items():
                if items:
                    context_mappings = OrderedDict()
                    for item in items:
                        if item['action'] == 'reuse':
                            context_mappings[item['arb_key']] = {
                                'text_zh': item['text'],
                                'text_en': self.en_arb_data.get(item['arb_key'], item['text']),
                                'file': item['file'],
                                'line': item['line'],
                                'action': 'reuse_existing',
                                'similarity': item['similarity'],
                                'approved': True,  # 复用的直接批准
                            }
                        else:
                            context_mappings[item['suggested_key']] = {
                                'text_zh': item['text'],
                                'text_en': item['text'],  # 需要翻译
                                'file': item['file'],
                                'line': item['line'],
                                'action': 'create_new',
                                'approved': False,  # 需要审核
                            }
                    
                    if context_mappings:
                        mapping_data['chinese_mappings'][context] = context_mappings
        
        # 英文映射
        if any(results['english'].values()):
            mapping_data['english_mappings'] = OrderedDict()
            for context, items in results['english'].items():
                if items:
                    context_mappings = OrderedDict()
                    for item in items:
                        if item['action'] == 'reuse':
                            context_mappings[item['arb_key']] = {
                                'text_en': item['text'],
                                'text_zh': self.zh_arb_data.get(item['arb_key'], item['text']),
                                'file': item['file'],
                                'line': item['line'],
                                'action': 'reuse_existing',
                                'similarity': item['similarity'],
                                'approved': True,  # 复用的直接批准
                            }
                        else:
                            context_mappings[item['suggested_key']] = {
                                'text_en': item['text'],
                                'text_zh': item['text'],  # 需要翻译
                                'file': item['file'],
                                'line': item['line'],
                                'action': 'create_new',
                                'approved': False,  # 需要审核
                            }
                    
                    if context_mappings:
                        mapping_data['english_mappings'][context] = context_mappings
        
        with open(mapping_path, 'w', encoding='utf-8') as f:
            f.write("# 多语言硬编码文本映射文件\n")
            f.write("# 包含中文和英文硬编码检测结果\n")
            f.write("# 请审核新建条目，修改翻译，并将 approved 设置为 true\n")
            f.write("# 复用条目已自动批准\n\n")
            yaml.dump(mapping_data, f, default_flow_style=False, allow_unicode=True, sort_keys=False)
        
        return {
            'summary': summary_path,
            'detail': detail_path,
            'mapping': mapping_path,
            'chinese_total': chinese_total,
            'english_total': english_total,
            'chinese_reuse': chinese_reuse,
            'english_reuse': english_reuse,
        }
    
    def run_detection(self):
        """运行检测"""
        print("=== 多语言硬编码文本检测器 ===")
        print("正在检测中文和英文硬编码文本...")
        
        results = self.detect_hardcoded_text()
        report_info = self.generate_reports(results)
        
        print(f"\n检测完成！")
        print(f"中文硬编码: {report_info['chinese_total']} 个 (复用 {report_info['chinese_reuse']} 个)")
        print(f"英文硬编码: {report_info['english_total']} 个 (复用 {report_info['english_reuse']} 个)")
        print(f"总计: {report_info['chinese_total'] + report_info['english_total']} 个")
        
        print(f"\n生成的文件:")
        print(f"  - 汇总报告: {report_info['summary']}")
        print(f"  - 详细报告: {report_info['detail']}")
        print(f"  - 映射文件: {report_info['mapping']}")
        
        return report_info

def main():
    detector = MultilingualHardcodedDetector()
    detector.run_detection()

if __name__ == "__main__":
    main()
