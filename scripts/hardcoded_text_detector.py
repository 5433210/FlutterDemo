#!/usr/bin/env python3
"""
硬编码文本检测器
用于检测Flutter项目中的硬编码中文文本，支持多种文本模式识别
"""

import os
import re
import json
import argparse
from collections import defaultdict
from dataclasses import dataclass, asdict
from typing import List, Dict, Set
import difflib

@dataclass
class HardcodedText:
    file_path: str
    line_number: int
    line_content: str
    text_content: str
    text_type: str
    context: str
    confidence: float = 1.0

class HardcodedTextDetector:
    def __init__(self):
        # 检测模式：正则表达式 -> 文本类型
        self.detection_patterns = {
            # Text组件
            r'Text\s*\(\s*[\'\"](.*?[\u4e00-\u9fff].*?)[\'\"]\s*[\),]': 'text_widget',
            r'Text\s*\(\s*[\'\"](.*?[\u4e00-\u9fff].*?)[\'\"]\s*,': 'text_widget',
            
            # Text.rich
            r'TextSpan\s*\(\s*text\s*:\s*[\'\"](.*?[\u4e00-\u9fff].*?)[\'\"]\s*[\),]': 'text_span',
            
            # SelectableText
            r'SelectableText\s*\(\s*[\'\"](.*?[\u4e00-\u9fff].*?)[\'\"]\s*[\),]': 'selectable_text',
            
            # AutoSizeText
            r'AutoSizeText\s*\(\s*[\'\"](.*?[\u4e00-\u9fff].*?)[\'\"]\s*[\),]': 'auto_size_text',
            
            # 属性文本
            r'hintText\s*:\s*[\'\"](.*?[\u4e00-\u9fff].*?)[\'\"]\s*[,\)\}]': 'hint_text',
            r'labelText\s*:\s*[\'\"](.*?[\u4e00-\u9fff].*?)[\'\"]\s*[,\)\}]': 'label_text',
            r'helperText\s*:\s*[\'\"](.*?[\u4e00-\u9fff].*?)[\'\"]\s*[,\)\}]': 'helper_text',
            r'errorText\s*:\s*[\'\"](.*?[\u4e00-\u9fff].*?)[\'\"]\s*[,\)\}]': 'error_text',
            r'counterText\s*:\s*[\'\"](.*?[\u4e00-\u9fff].*?)[\'\"]\s*[,\)\}]': 'counter_text',
            r'placeholder\s*:\s*[\'\"](.*?[\u4e00-\u9fff].*?)[\'\"]\s*[,\)\}]': 'placeholder',
            r'tooltip\s*:\s*[\'\"](.*?[\u4e00-\u9fff].*?)[\'\"]\s*[,\)\}]': 'tooltip',
            r'semanticLabel\s*:\s*[\'\"](.*?[\u4e00-\u9fff].*?)[\'\"]\s*[,\)\}]': 'semantic_label',
            
            # title属性
            r'title\s*:\s*Text\s*\(\s*[\'\"](.*?[\u4e00-\u9fff].*?)[\'\"]\s*\)': 'title_text',
            r'title\s*:\s*[\'\"](.*?[\u4e00-\u9fff].*?)[\'\"]\s*[,\)\}]': 'title_string',
            
            # AppBar
            r'AppBar\s*\([^)]*title\s*:\s*Text\s*\(\s*[\'\"](.*?[\u4e00-\u9fff].*?)[\'\"]\s*\)': 'app_bar_title',
            
            # Button文本
            r'child\s*:\s*Text\s*\(\s*[\'\"](.*?[\u4e00-\u9fff].*?)[\'\"]\s*\)': 'button_text',
            r'label\s*:\s*Text\s*\(\s*[\'\"](.*?[\u4e00-\u9fff].*?)[\'\"]\s*\)': 'label_text_widget',
            
            # Dialog相关
            r'AlertDialog\s*\([^)]*title\s*:\s*Text\s*\(\s*[\'\"](.*?[\u4e00-\u9fff].*?)[\'\"]\s*\)': 'alert_dialog_title',
            r'content\s*:\s*Text\s*\(\s*[\'\"](.*?[\u4e00-\u9fff].*?)[\'\"]\s*\)': 'dialog_content',
            
            # SnackBar
            r'SnackBar\s*\([^)]*content\s*:\s*Text\s*\(\s*[\'\"](.*?[\u4e00-\u9fff].*?)[\'\"]\s*\)': 'snackbar_content',
            r'content\s*:\s*Text\s*\(\s*[\'\"](.*?[\u4e00-\u9fff].*?)[\'\"]\s*\)': 'snackbar_content_simple',
            
            # 消息和通知
            r'message\s*:\s*[\'\"](.*?[\u4e00-\u9fff].*?)[\'\"]\s*[,\)\}]': 'message',
            
            # 返回语句中的字符串
            r'return\s+[\'\"](.*?[\u4e00-\u9fff].*?)[\'\"]\s*;': 'return_string',
            
            # 异常和错误
            r'throw\s+\w+\s*\(\s*[\'\"](.*?[\u4e00-\u9fff].*?)[\'\"]\s*\)': 'exception_message',
            r'Exception\s*\(\s*[\'\"](.*?[\u4e00-\u9fff].*?)[\'\"]\s*\)': 'exception_constructor',
            
            # print和日志
            r'print\s*\(\s*[\'\"](.*?[\u4e00-\u9fff].*?)[\'\"]\s*\)': 'print_statement',
            r'log\s*\(\s*[\'\"](.*?[\u4e00-\u9fff].*?)[\'\"]\s*\)': 'log_statement',
            r'debugPrint\s*\(\s*[\'\"](.*?[\u4e00-\u9fff].*?)[\'\"]\s*\)': 'debug_print',
            
            # 字符串常量
            r'const\s+String\s+\w+\s*=\s*[\'\"](.*?[\u4e00-\u9fff].*?)[\'\"]\s*;': 'string_constant',
            r'final\s+String\s+\w+\s*=\s*[\'\"](.*?[\u4e00-\u9fff].*?)[\'\"]\s*;': 'string_final',
            r'String\s+\w+\s*=\s*[\'\"](.*?[\u4e00-\u9fff].*?)[\'\"]\s*;': 'string_variable',
            
            # 枚举显示名称相关
            r'case\s+\w+\.\w+\s*:\s*return\s+[\'\"](.*?[\u4e00-\u9fff].*?)[\'\"]\s*;': 'enum_display_name',
            
            # Map中的值
            r'[\'\"]\w*[\'\"]\s*:\s*[\'\"](.*?[\u4e00-\u9fff].*?)[\'\"]\s*[,\}]': 'map_value',
        }
        
        self.exclude_patterns = [
            r'//.*?[\u4e00-\u9fff].*',  # 注释
            r'/\*.*?[\u4e00-\u9fff].*?\*/',  # 多行注释
            r'TODO.*?[\u4e00-\u9fff].*',  # TODO注释
        ]
        
        self.exclude_files = [
            'generated',
            '.g.dart',
            '.freezed.dart',
            '.gr.dart',
            'app_localizations.dart',
            'app_localizations_',
        ]
    
    def should_exclude_file(self, file_path: str) -> bool:
        """判断是否应该排除文件"""
        for pattern in self.exclude_files:
            if pattern in file_path:
                return True
        return False
    
    def is_in_comment(self, line: str, match_start: int) -> bool:
        """判断匹配是否在注释中"""
        # 检查单行注释
        comment_pos = line.find('//')
        if comment_pos != -1 and comment_pos < match_start:
            return True
        
        # 简单检查是否在多行注释中（不完美，但基本够用）
        if '/*' in line[:match_start] and '*/' not in line[match_start:]:
            return True
            
        return False
    
    def extract_context(self, file_path: str, line_number: int, lines: List[str]) -> str:
        """提取上下文信息"""
        context_parts = []
        
        # 从文件路径提取模块信息
        path_parts = file_path.replace('\\', '/').split('/')
        if len(path_parts) > 2:
            context_parts.append(f"模块:{path_parts[-2]}")
        
        # 查找当前函数或类
        function_name = self.find_current_function(line_number, lines)
        if function_name:
            context_parts.append(f"函数:{function_name}")
        
        class_name = self.find_current_class(line_number, lines)
        if class_name:
            context_parts.append(f"类:{class_name}")
        
        return " ".join(context_parts)
    
    def find_current_function(self, line_number: int, lines: List[str]) -> str:
        """查找当前所在函数"""
        for i in range(line_number - 1, max(0, line_number - 20), -1):
            if i < len(lines):
                line = lines[i].strip()
                # 匹配函数定义
                func_match = re.search(r'(?:Future<.*?>|void|String|int|bool|Widget|\w+)\s+(\w+)\s*\(', line)
                if func_match:
                    return func_match.group(1)
        return ""
    
    def find_current_class(self, line_number: int, lines: List[str]) -> str:
        """查找当前所在类"""
        for i in range(line_number - 1, max(0, line_number - 50), -1):
            if i < len(lines):
                line = lines[i].strip()
                # 匹配类定义
                class_match = re.search(r'class\s+(\w+)', line)
                if class_match:
                    return class_match.group(1)
        return ""
    
    def detect_in_file(self, file_path: str) -> List[HardcodedText]:
        """检测单个文件中的硬编码文本"""
        if self.should_exclude_file(file_path):
            return []
        
        results = []
        
        try:
            with open(file_path, 'r', encoding='utf-8', errors='ignore') as f:
                lines = f.readlines()
            
            for line_num, line in enumerate(lines, 1):
                # 跳过空行和纯空白行
                if not line.strip():
                    continue
                
                for pattern, text_type in self.detection_patterns.items():
                    matches = re.finditer(pattern, line, re.DOTALL)
                    
                    for match in matches:
                        # 检查是否在注释中
                        if self.is_in_comment(line, match.start()):
                            continue
                        
                        text_content = match.group(1)
                        
                        # 过滤明显不是用户界面文本的内容
                        if self.should_skip_text(text_content):
                            continue
                        
                        context = self.extract_context(file_path, line_num, lines)
                        
                        hardcoded_text = HardcodedText(
                            file_path=file_path,
                            line_number=line_num,
                            line_content=line.strip(),
                            text_content=text_content,
                            text_type=text_type,
                            context=context,
                            confidence=self.calculate_confidence(text_content, text_type)
                        )
                        
                        results.append(hardcoded_text)
        
        except Exception as e:
            print(f"⚠️  处理文件失败 {file_path}: {e}")
        
        return results
    
    def should_skip_text(self, text: str) -> str:
        """判断是否应该跳过这个文本"""
        # 跳过过短的文本
        if len(text.strip()) < 2:
            return True
        
        # 跳过URL
        if text.startswith('http') or text.startswith('www'):
            return True
        
        # 跳过文件路径
        if '/' in text or '\\' in text:
            return True
        
        # 跳过包含特殊字符的技术性文本
        technical_chars = ['${', '}', '<', '>', '[', ']', '{', '}']
        if any(char in text for char in technical_chars):
            return True
        
        return False
    
    def calculate_confidence(self, text: str, text_type: str) -> float:
        """计算检测置信度"""
        confidence = 1.0
        
        # 根据文本类型调整置信度
        high_confidence_types = ['text_widget', 'button_text', 'title_text', 'hint_text']
        if text_type in high_confidence_types:
            confidence = 1.0
        elif text_type in ['print_statement', 'debug_print', 'log_statement']:
            confidence = 0.5  # 日志可能不需要国际化
        elif text_type == 'return_string':
            confidence = 0.8
        
        # 根据文本长度调整
        if len(text) < 3:
            confidence *= 0.6
        elif len(text) > 50:
            confidence *= 0.8
        
        return confidence
    
    def scan_all_files(self, root_dir: str = "lib") -> List[HardcodedText]:
        """扫描所有Dart文件"""
        all_results = []
        dart_files = []
        
        # 收集所有Dart文件
        for root, dirs, files in os.walk(root_dir):
            # 跳过生成的文件目录
            dirs[:] = [d for d in dirs if not d.startswith('.') and d != 'generated']
            
            for file in files:
                if file.endswith('.dart'):
                    dart_files.append(os.path.join(root, file))
        
        print(f"🔍 开始扫描 {len(dart_files)} 个Dart文件...")
        
        for i, file_path in enumerate(dart_files, 1):
            if i % 10 == 0:
                print(f"   进度: {i}/{len(dart_files)}")
            
            results = self.detect_in_file(file_path)
            all_results.extend(results)
        
        return all_results
    
    def group_by_file(self, results: List[HardcodedText]) -> Dict[str, List[HardcodedText]]:
        """按文件分组结果"""
        grouped = defaultdict(list)
        for result in results:
            grouped[result.file_path].append(result)
        return dict(grouped)
    
    def group_by_type(self, results: List[HardcodedText]) -> Dict[str, List[HardcodedText]]:
        """按类型分组结果"""
        grouped = defaultdict(list)
        for result in results:
            grouped[result.text_type].append(result)
        return dict(grouped)
    
    def generate_report(self, results: List[HardcodedText], output_file: str = "hardcoded_text_report.md"):
        """生成检测报告"""
        grouped_by_file = self.group_by_file(results)
        grouped_by_type = self.group_by_type(results)
        
        with open(output_file, 'w', encoding='utf-8') as f:
            f.write("# 硬编码文本检测报告\n\n")
            f.write(f"生成时间: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n\n")
            
            # 统计信息
            f.write("## 统计信息\n\n")
            f.write(f"- 检测到硬编码文本: {len(results)} 处\n")
            f.write(f"- 涉及文件: {len(grouped_by_file)} 个\n")
            f.write(f"- 文本类型: {len(grouped_by_type)} 种\n\n")
            
            # 按类型统计
            f.write("## 按类型统计\n\n")
            for text_type, items in sorted(grouped_by_type.items(), key=lambda x: len(x[1]), reverse=True):
                f.write(f"- **{text_type}**: {len(items)} 处\n")
            f.write("\n")
            
            # 按文件详情
            f.write("## 按文件详情\n\n")
            for file_path, items in sorted(grouped_by_file.items(), key=lambda x: len(x[1]), reverse=True):
                f.write(f"### {file_path} ({len(items)} 处)\n\n")
                
                for item in items:
                    f.write(f"**第 {item.line_number} 行** ({item.text_type}):\n")
                    f.write(f"- 文本: `{item.text_content}`\n")
                    f.write(f"- 代码: `{item.line_content}`\n")
                    if item.context:
                        f.write(f"- 上下文: {item.context}\n")
                    f.write(f"- 置信度: {item.confidence:.2f}\n\n")
        
        print(f"✅ 检测报告已生成: {output_file}")
    
    def export_json(self, results: List[HardcodedText], output_file: str = "hardcoded_texts.json"):
        """导出为JSON格式"""
        data = [asdict(result) for result in results]
        
        with open(output_file, 'w', encoding='utf-8') as f:
            json.dump(data, f, ensure_ascii=False, indent=2)
        
        print(f"✅ JSON数据已导出: {output_file}")

def main():
    parser = argparse.ArgumentParser(description='硬编码文本检测器')
    parser.add_argument('--scan', action='store_true', help='扫描硬编码文本')
    parser.add_argument('--root-dir', default='lib', help='扫描根目录')
    parser.add_argument('--output', default='hardcoded_text_report.md', help='报告输出文件')
    parser.add_argument('--json', action='store_true', help='同时导出JSON格式')
    parser.add_argument('--min-confidence', type=float, default=0.5, help='最小置信度阈值')
    
    args = parser.parse_args()
    
    if args.scan:
        detector = HardcodedTextDetector()
        results = detector.scan_all_files(args.root_dir)
        
        # 过滤低置信度结果
        filtered_results = [r for r in results if r.confidence >= args.min_confidence]
        
        print(f"\n📊 检测结果:")
        print(f"   总计: {len(results)} 处")
        print(f"   高置信度 (>={args.min_confidence}): {len(filtered_results)} 处")
        
        if filtered_results:
            detector.generate_report(filtered_results, args.output)
            
            if args.json:
                json_file = args.output.replace('.md', '.json')
                detector.export_json(filtered_results, json_file)
        else:
            print("✅ 未检测到需要处理的硬编码文本")
    else:
        print("请使用 --scan 开始扫描")
        print("使用 --help 查看详细说明")

if __name__ == "__main__":
    import datetime
    main()
