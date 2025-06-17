#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
最终优化的硬编码文本检测器
- 专注于UI文本检测，排除调试和日志信息
- 智能复用现有ARB键
- 生成符合项目习惯的驼峰命名键
"""

import os
import re
import json
from datetime import datetime
from difflib import SequenceMatcher
from collections import OrderedDict
import yaml

# 配置路径
WORKSPACE_ROOT = os.getcwd()
LIB_DIR = os.path.join(WORKSPACE_ROOT, 'lib')
ZH_ARB_PATH = os.path.join(WORKSPACE_ROOT, 'lib', 'l10n', 'app_zh.arb')
EN_ARB_PATH = os.path.join(WORKSPACE_ROOT, 'lib', 'l10n', 'app_en.arb')
REPORT_DIR = os.path.join(WORKSPACE_ROOT, 'final_hardcoded_report')

# 检测规则配置
DETECTION_PATTERNS = {
    # UI文本Widget - 只检测简单、明确的UI文本
    "ui_text": [
        # Text Widget (简单形式)
        r'Text\(\s*[\'\"]((?:[^\'\"\\]|\\.)*)[\'\"]',
        r'const\s+Text\(\s*[\'\"]((?:[^\'\"\\]|\\.)*)[\'\"]',
        
        # Button文本
        r'ElevatedButton\([^)]*child:\s*Text\(\s*[\'\"]((?:[^\'\"\\]|\\.)*)[\'\"]',
        r'TextButton\([^)]*child:\s*Text\(\s*[\'\"]((?:[^\'\"\\]|\\.)*)[\'\"]',
        r'OutlinedButton\([^)]*child:\s*Text\(\s*[\'\"]((?:[^\'\"\\]|\\.)*)[\'\"]',
        r'ElevatedButton\.icon\([^)]*label:\s*Text\(\s*[\'\"]((?:[^\'\"\\]|\\.)*)[\'\"]',
        
        # AppBar标题
        r'AppBar\([^)]*title:\s*Text\(\s*[\'\"]((?:[^\'\"\\]|\\.)*)[\'\"]',
        
        # ListTile标题
        r'ListTile\([^)]*title:\s*Text\(\s*[\'\"]((?:[^\'\"\\]|\\.)*)[\'\"]',
        
        # Tooltip
        r'tooltip:\s*[\'\"]((?:[^\'\"\\]|\\.)*)[\'\"]',
        
        # hintText
        r'hintText:\s*[\'\"]((?:[^\'\"\\]|\\.)*)[\'\"]',
        
        # labelText
        r'labelText:\s*[\'\"]((?:[^\'\"\\]|\\.)*)[\'\"]',
    ],
    
    # SnackBar和Dialog文本
    "ui_messages": [
        r'SnackBar\([^)]*content:\s*Text\(\s*[\'\"]((?:[^\'\"\\]|\\.)*)[\'\"]',
        r'AlertDialog\([^)]*title:\s*Text\(\s*[\'\"]((?:[^\'\"\\]|\\.)*)[\'\"]',
        r'AlertDialog\([^)]*content:\s*Text\(\s*[\'\"]((?:[^\'\"\\]|\\.)*)[\'\"]',
    ],
}

# 排除模式 - 明确排除日志和调试信息
EXCLUSION_PATTERNS = [
    # 日志调用
    r'debugPrint\s*\(',
    r'print\s*\(',
    r'log\s*\(',
    r'AppLogger\.',
    r'Logger\.',
    r'logger\.',
    
    # 错误处理
    r'throw\s+\w+Error',
    r'ArgumentError',
    r'StateError',
    
    # 文件路径和URL
    r'[\'\"]/\w+/',
    r'[\'\"]\w+://\w+',
    r'[\'\"]\w+\.\w+[\'\"]\s*[;,)]',  # 文件扩展名
    
    # API键和技术字符串
    r'[\'\"]\w{32,}[\'\"]\s*[;,)]',  # 长字符串（可能是密钥）
    r'package:\w+',
    
    # 变量名和类名
    r'[\'\"]\w+Provider[\'\"]\s*[;,)]',
    r'[\'\"]\w+Service[\'\"]\s*[;,)]',
    r'[\'\"]\w+Repository[\'\"]\s*[;,)]',
]

class FinalHardcodedDetector:
    def __init__(self):
        self.ensure_report_dir()
        self.existing_arb_keys = self.load_existing_arb_keys()
        self.generated_keys = set()
        
    def ensure_report_dir(self):
        """确保报告目录存在"""
        if not os.path.exists(REPORT_DIR):
            os.makedirs(REPORT_DIR)
    
    def load_existing_arb_keys(self):
        """加载现有ARB文件的所有键值对"""
        arb_data = {}
        for arb_path in [ZH_ARB_PATH, EN_ARB_PATH]:
            if os.path.exists(arb_path):
                try:
                    with open(arb_path, 'r', encoding='utf-8') as f:
                        data = json.load(f)
                    # 只加载中文ARB的值，因为我们要匹配中文文本
                    if arb_path == ZH_ARB_PATH:
                        for key, value in data.items():
                            if not key.startswith('@') and isinstance(value, str):
                                arb_data[key] = value
                except (json.JSONDecodeError, UnicodeDecodeError) as e:
                    print(f"Warning: Error loading {arb_path}: {e}")
        return arb_data
    
    def find_similar_arb_key(self, text, threshold=0.8):
        """查找相似的ARB键值，实现复用"""
        best_match = None
        best_ratio = 0
        
        # 清理文本：移除变量插值和特殊符号
        clean_text = re.sub(r'\$\{[^}]*\}|\{[^}]*\}', '', text)
        clean_text = re.sub(r'[：:{}$\(\)]', '', clean_text).strip()
        
        if len(clean_text) < 2:  # 太短的文本不值得复用
            return None, 0
        
        for key, value in self.existing_arb_keys.items():
            # 清理ARB值
            clean_value = re.sub(r'\{[^}]*\}', '', value)
            clean_value = re.sub(r'[：:{}$\(\)]', '', clean_value).strip()
            
            # 完全匹配优先
            if clean_text == clean_value:
                return key, 1.0
            
            # 计算文本相似度
            ratio = SequenceMatcher(None, clean_text, clean_value).ratio()
            if ratio > best_ratio and ratio >= threshold:
                best_match = key
                best_ratio = ratio
        
        return best_match, best_ratio
    
    def generate_smart_key(self, text, context):
        """智能生成键名，符合项目习惯"""
        # 中文到英文的映射
        word_map = {
            '添加': 'add', '删除': 'delete', '编辑': 'edit', '保存': 'save',
            '取消': 'cancel', '确认': 'confirm', '确定': 'ok', '关闭': 'close',
            '打开': 'open', '新建': 'new', '创建': 'create', '修改': 'modify',
            '搜索': 'search', '查找': 'find', '设置': 'settings', '帮助': 'help',
            '关于': 'about', '信息': 'info', '详情': 'details', '返回': 'back',
            '下一步': 'next', '上一步': 'previous', '完成': 'done', '跳过': 'skip',
            '重试': 'retry', '刷新': 'refresh', '更新': 'update', '清除': 'clear',
            '全部': 'all', '无': 'none', '是': 'yes', '否': 'no',
            '成功': 'success', '失败': 'failed', '错误': 'error', '警告': 'warning',
            '标题': 'title', '名称': 'name', '描述': 'description', '内容': 'content',
            '字体': 'font', '颜色': 'color', '大小': 'size', '样式': 'style',
            '页面': 'page', '首页': 'home', '主页': 'home', '菜单': 'menu',
            '列表': 'list', '项目': 'item', '选择': 'select', '已选择': 'selected',
            '测试': 'test', '工具': 'tool', '粗细': 'weight', '预览': 'preview',
        }
        
        # 移除特殊字符，分词
        clean_text = re.sub(r'[^\w\s\u4e00-\u9fff]', ' ', text)
        words = clean_text.split()
        
        # 转换为英文关键词
        keywords = []
        for word in words:
            if word in word_map:
                keywords.append(word_map[word])
            elif re.match(r'^[a-zA-Z]+$', word):
                keywords.append(word.lower())
            elif len(word) <= 4 and re.match(r'^[\u4e00-\u9fff]+$', word):
                # 短中文词转拼音（简化版）
                if word == '工具':
                    keywords.append('tool')
                elif word == '测试':
                    keywords.append('test')
                # 可以扩展更多拼音映射
        
        # 根据上下文添加前缀
        if context == 'ui_messages':
            if not any(k in ['message', 'dialog', 'alert'] for k in keywords):
                keywords.insert(0, 'message')
        
        # 生成键名
        if not keywords:
            keywords = ['text']
        
        if len(keywords) == 1:
            base_key = keywords[0]
        else:
            base_key = keywords[0] + ''.join(word.capitalize() for word in keywords[1:])
        
        # 确保键名唯一
        key = base_key
        counter = 1
        while key in self.existing_arb_keys or key in self.generated_keys:
            key = f"{base_key}{counter}"
            counter += 1
        
        self.generated_keys.add(key)
        return key
    
    def is_excluded_text(self, text, line, file_path):
        """检查文本是否应该被排除"""
        # 排除过长的文本（可能是多行检测错误）
        if len(text) > 100:
            return True
        
        # 排除只包含英文和数字的文本（除非很短）
        if re.match(r'^[a-zA-Z0-9\s\.\-_]+$', text) and len(text) > 20:
            return True
        
        # 排除不包含中文的文本
        if not re.search(r'[\u4e00-\u9fff]', text):
            return True
        
        # 检查行是否匹配排除模式
        for pattern in EXCLUSION_PATTERNS:
            if re.search(pattern, line):
                return True
        
        # 排除文件路径相关的文本
        if 'assets/' in text or 'fonts/' in text or '.dart' in text:
            return True
        
        # 排除包含大量变量插值的文本
        if text.count('$') > 2:
            return True
        
        return False
    
    def detect_in_file(self, file_path):
        """检测单个文件中的硬编码文本"""
        results = {
            'ui_text': [],
            'ui_messages': []
        }
        
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                content = f.read()
            
            lines = content.split('\n')
            
            for category, patterns in DETECTION_PATTERNS.items():
                for pattern in patterns:
                    for match in re.finditer(pattern, content, re.MULTILINE | re.DOTALL):
                        text = match.group(1)
                        
                        # 查找匹配位置所在的行号
                        line_start = content[:match.start()].count('\n') + 1
                        line_content = lines[line_start - 1] if line_start <= len(lines) else ""
                        
                        # 检查是否应该排除
                        if self.is_excluded_text(text, line_content, file_path):
                            continue
                        
                        # 检查是否可以复用现有ARB键
                        similar_key, similarity = self.find_similar_arb_key(text)
                        
                        result = {
                            'text': text,
                            'file': os.path.relpath(file_path, WORKSPACE_ROOT),
                            'line': line_start,
                            'code': line_content.strip(),
                            'category': category,
                            'similar_key': similar_key,
                            'similarity': similarity
                        }
                        
                        results[category].append(result)
        
        except Exception as e:
            print(f"Error processing {file_path}: {e}")
        
        return results
    
    def detect_all_files(self):
        """检测所有Dart文件"""
        all_results = {
            'ui_text': [],
            'ui_messages': []
        }
        
        for root, dirs, files in os.walk(LIB_DIR):
            # 跳过生成的文件目录
            if 'generated' in root or '.dart_tool' in root:
                continue
            
            for file in files:
                if file.endswith('.dart'):
                    file_path = os.path.join(root, file)
                    file_results = self.detect_in_file(file_path)
                    
                    for category in all_results:
                        all_results[category].extend(file_results[category])
        
        return all_results
    
    def remove_duplicates(self, results):
        """移除重复的检测结果"""
        seen = set()
        for category in results:
            unique_results = []
            for result in results[category]:
                # 使用文本和文件作为唯一标识
                key = (result['text'], result['file'])
                if key not in seen:
                    seen.add(key)
                    unique_results.append(result)
            results[category] = unique_results
        return results
    
    def generate_mapping(self, results):
        """生成映射文件"""
        mapping = OrderedDict()
        mapping['reuse_existing_keys'] = OrderedDict()
        mapping['create_new_keys'] = OrderedDict()
        
        reuse_count = 0
        new_count = 0
        
        for category, items in results.items():
            if not items:
                continue
            
            for item in items:
                if item['similar_key'] and item['similarity'] >= 0.8:
                    # 复用现有键
                    if category not in mapping['reuse_existing_keys']:
                        mapping['reuse_existing_keys'][category] = OrderedDict()
                    
                    key_name = item['similar_key']
                    mapping['reuse_existing_keys'][category][key_name] = {
                        'action': 'reuse_existing',
                        'existing_key': item['similar_key'],
                        'text_zh': item['text'],
                        'file': item['file'],
                        'line': item['line'],
                        'similarity': round(item['similarity'], 3),
                        'approved': False
                    }
                    reuse_count += 1
                else:
                    # 创建新键
                    if category not in mapping['create_new_keys']:
                        mapping['create_new_keys'][category] = OrderedDict()
                    
                    new_key = self.generate_smart_key(item['text'], category)
                    mapping['create_new_keys'][category][new_key] = {
                        'action': 'create_new',
                        'text_zh': item['text'],
                        'text_en': item['text'],  # 需要翻译
                        'file': item['file'],
                        'line': item['line'],
                        'similarity': round(item['similarity'], 3) if item['similar_key'] else 0,
                        'approved': False
                    }
                    new_count += 1
        
        return mapping, reuse_count, new_count
    
    def save_results(self, results, mapping, reuse_count, new_count):
        """保存检测结果"""
        timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
        
        # 保存汇总报告
        summary_path = os.path.join(REPORT_DIR, f'final_summary_{timestamp}.txt')
        with open(summary_path, 'w', encoding='utf-8') as f:
            f.write("=== 最终硬编码文本检测汇总报告 ===\n")
            f.write(f"检测时间: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n\n")
            
            total_count = sum(len(items) for items in results.values())
            f.write(f"检测到的硬编码文本总数: {total_count}\n")
            f.write(f"可复用现有ARB键: {reuse_count}\n")
            f.write(f"需新建ARB键: {new_count}\n\n")
            
            f.write("按类型分布:\n")
            for category, items in results.items():
                reuse_in_category = sum(1 for item in items if item['similar_key'] and item['similarity'] >= 0.8)
                new_in_category = len(items) - reuse_in_category
                f.write(f"  - {category}: {len(items)} 个 (复用: {reuse_in_category}, 新建: {new_in_category})\n")
        
        # 保存详细报告
        detail_path = os.path.join(REPORT_DIR, f'final_detail_{timestamp}.txt')
        with open(detail_path, 'w', encoding='utf-8') as f:
            f.write("=== 最终硬编码文本详细报告 ===\n\n")
            
            for category, items in results.items():
                if items:
                    f.write(f"--- {category.upper()} ({len(items)} 个) ---\n")
                    for item in items:
                        f.write(f"文件: {item['file']}, 行: {item['line']}\n")
                        f.write(f"硬编码文本: \"{item['text']}\"\n")
                        if item['similar_key']:
                            f.write(f"相似ARB键: {item['similar_key']} (相似度: {item['similarity']:.3f})\n")
                        f.write(f"代码行: {item['code']}\n")
                        f.write("-" * 40 + "\n")
                    f.write("\n")
        
        # 保存映射文件
        mapping_path = os.path.join(REPORT_DIR, f'final_mapping_{timestamp}.yaml')
        with open(mapping_path, 'w', encoding='utf-8') as f:
            f.write("# 最终硬编码文本映射文件\n")
            f.write("# 专注于UI文本，排除了调试和日志信息\n")
            f.write("# 请审核以下内容，并将 approved 设置为 true\n\n")
            yaml.dump(mapping, f, default_flow_style=False, allow_unicode=True, sort_keys=False)
        
        return summary_path, detail_path, mapping_path
    
    def run_detection(self):
        """运行完整的检测流程"""
        print("=== 最终硬编码文本检测器 ===")
        print("专注于UI文本检测，智能复用ARB键...")
        
        # 检测所有文件
        results = self.detect_all_files()
        
        # 移除重复项
        results = self.remove_duplicates(results)
        
        # 生成映射
        mapping, reuse_count, new_count = self.generate_mapping(results)
        
        # 保存结果
        summary_path, detail_path, mapping_path = self.save_results(results, mapping, reuse_count, new_count)
        
        # 打印统计信息
        total_count = sum(len(items) for items in results.values())
        print(f"\n检测完成！")
        print(f"总计发现硬编码文本: {total_count} 个")
        print(f"可复用现有ARB键: {reuse_count} 个")
        print(f"需新建ARB键: {new_count} 个")
        print(f"按类型分布:")
        for category, items in results.items():
            reuse_in_category = sum(1 for item in items if item['similar_key'] and item['similarity'] >= 0.8)
            new_in_category = len(items) - reuse_in_category
            print(f"  - {category}: {len(items)} 个 (复用: {reuse_in_category}, 新建: {new_in_category})")
        
        print(f"\n生成的文件:")
        print(f"  - 汇总报告: {os.path.relpath(summary_path, WORKSPACE_ROOT)}")
        print(f"  - 详细报告: {os.path.relpath(detail_path, WORKSPACE_ROOT)}")
        print(f"  - 映射文件: {os.path.relpath(mapping_path, WORKSPACE_ROOT)}")
        
        print(f"\n改进特性:")
        print(f"✅ 专注UI文本，排除调试日志")
        print(f"✅ 智能复用现有ARB键")
        print(f"✅ 生成语义化的键名")
        print(f"✅ 移除重复检测结果")
        print(f"✅ 更精确的文本分类")

def main():
    detector = FinalHardcodedDetector()
    detector.run_detection()

if __name__ == "__main__":
    main()
