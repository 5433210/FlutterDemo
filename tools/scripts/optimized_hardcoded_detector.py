#!/usr/bin/env python3
"""
优化的硬编码文本检测器 - 解决遗漏检测、ARB复用、命名规范问题
"""

import os
import re
import json
import glob
import yaml
from collections import defaultdict, OrderedDict
from datetime import datetime
from difflib import SequenceMatcher

# 配置常量
CODE_DIR = "lib"
ARB_DIR = "lib/l10n"
ZH_ARB_PATH = os.path.join(ARB_DIR, "app_zh.arb")
EN_ARB_PATH = os.path.join(ARB_DIR, "app_en.arb")
REPORT_DIR = "optimized_hardcoded_report"

# 优化的检测模式 - 更全面的正则表达式
ENHANCED_DETECTION_PATTERNS = {
    # UI文本 - 更全面的Text Widget检测
    "ui_text_widget": [
        # 基本Text构造函数
        r'Text\(\s*[\'\"](.*?[\u4e00-\u9fff].*?)[\'\"]',
        r'const\s+Text\(\s*[\'\"](.*?[\u4e00-\u9fff].*?)[\'\"]',
        
        # Text.rich 和其他构造函数
        r'Text\.rich\([^)]*text:\s*[\'\"](.*?[\u4e00-\u9fff].*?)[\'\"]',
        r'Text\.data\(\s*[\'\"](.*?[\u4e00-\u9fff].*?)[\'\"]',
        
        # SelectableText
        r'SelectableText\(\s*[\'\"](.*?[\u4e00-\u9fff].*?)[\'\"]',
        r'const\s+SelectableText\(\s*[\'\"](.*?[\u4e00-\u9fff].*?)[\'\"]',
        
        # RichText
        r'RichText\([^)]*text:\s*TextSpan\([^)]*text:\s*[\'\"](.*?[\u4e00-\u9fff].*?)[\'\"]',
        
        # TextSpan
        r'TextSpan\([^)]*text:\s*[\'\"](.*?[\u4e00-\u9fff].*?)[\'\"]',
        
        # 其他文本Widget
        r'AutoSizeText\(\s*[\'\"](.*?[\u4e00-\u9fff].*?)[\'\"]',
        r'FittedBox\([^)]*child:\s*Text\(\s*[\'\"](.*?[\u4e00-\u9fff].*?)[\'\"]',
    ],
    
    # UI属性 - 更全面的属性检测
    "ui_properties": [
        # 输入框相关
        r'hintText:\s*[\'\"](.*?[\u4e00-\u9fff].*?)[\'\"]',
        r'labelText:\s*[\'\"](.*?[\u4e00-\u9fff].*?)[\'\"]',
        r'helperText:\s*[\'\"](.*?[\u4e00-\u9fff].*?)[\'\"]',
        r'errorText:\s*[\'\"](.*?[\u4e00-\u9fff].*?)[\'\"]',
        r'counterText:\s*[\'\"](.*?[\u4e00-\u9fff].*?)[\'\"]',
        r'prefixText:\s*[\'\"](.*?[\u4e00-\u9fff].*?)[\'\"]',
        r'suffixText:\s*[\'\"](.*?[\u4e00-\u9fff].*?)[\'\"]',
        r'floatingLabelText:\s*[\'\"](.*?[\u4e00-\u9fff].*?)[\'\"]',
        
        # 通用属性
        r'title:\s*[\'\"](.*?[\u4e00-\u9fff].*?)[\'\"]',
        r'subtitle:\s*[\'\"](.*?[\u4e00-\u9fff].*?)[\'\"]',
        r'tooltip:\s*[\'\"](.*?[\u4e00-\u9fff].*?)[\'\"]',
        r'semanticLabel:\s*[\'\"](.*?[\u4e00-\u9fff].*?)[\'\"]',
        r'placeholder:\s*[\'\"](.*?[\u4e00-\u9fff].*?)[\'\"]',
        r'message:\s*[\'\"](.*?[\u4e00-\u9fff].*?)[\'\"]',
        r'description:\s*[\'\"](.*?[\u4e00-\u9fff].*?)[\'\"]',
    ],
    
    # 按钮和交互元素 - 包含更多按钮类型
    "ui_buttons_labels": [
        # 各种按钮类型
        r'ElevatedButton\([^)]*child:\s*Text\(\s*[\'\"](.*?[\u4e00-\u9fff].*?)[\'\"]',
        r'TextButton\([^)]*child:\s*Text\(\s*[\'\"](.*?[\u4e00-\u9fff].*?)[\'\"]',
        r'OutlinedButton\([^)]*child:\s*Text\(\s*[\'\"](.*?[\u4e00-\u9fff].*?)[\'\"]',
        r'FilledButton\([^)]*child:\s*Text\(\s*[\'\"](.*?[\u4e00-\u9fff].*?)[\'\"]',
        r'FilledButton\.tonal\([^)]*child:\s*Text\(\s*[\'\"](.*?[\u4e00-\u9fff].*?)[\'\"]',
        
        # 按钮的label参数
        r'ElevatedButton\.icon\([^)]*label:\s*Text\(\s*[\'\"](.*?[\u4e00-\u9fff].*?)[\'\"]',
        r'TextButton\.icon\([^)]*label:\s*Text\(\s*[\'\"](.*?[\u4e00-\u9fff].*?)[\'\"]',
        r'OutlinedButton\.icon\([^)]*label:\s*Text\(\s*[\'\"](.*?[\u4e00-\u9fff].*?)[\'\"]',
        r'FilledButton\.icon\([^)]*label:\s*Text\(\s*[\'\"](.*?[\u4e00-\u9fff].*?)[\'\"]',
        
        # IconButton和其他按钮
        r'IconButton\([^)]*tooltip:\s*[\'\"](.*?[\u4e00-\u9fff].*?)[\'\"]',
        r'FloatingActionButton\([^)]*tooltip:\s*[\'\"](.*?[\u4e00-\u9fff].*?)[\'\"]',
        r'PopupMenuButton\([^)]*tooltip:\s*[\'\"](.*?[\u4e00-\u9fff].*?)[\'\"]',
        
        # 菜单项
        r'PopupMenuItem\([^)]*child:\s*Text\(\s*[\'\"](.*?[\u4e00-\u9fff].*?)[\'\"]',
        r'DropdownMenuItem\([^)]*child:\s*Text\(\s*[\'\"](.*?[\u4e00-\u9fff].*?)[\'\"]',
        r'MenuAnchor\([^)]*child:\s*Text\(\s*[\'\"](.*?[\u4e00-\u9fff].*?)[\'\"]',
    ],
    
    # 对话框和消息 - 更全面的对话框检测
    "ui_dialogs_messages": [
        # AlertDialog
        r'AlertDialog\([^)]*title:\s*Text\(\s*[\'\"](.*?[\u4e00-\u9fff].*?)[\'\"]',
        r'AlertDialog\([^)]*content:\s*Text\(\s*[\'\"](.*?[\u4e00-\u9fff].*?)[\'\"]',
        
        # SnackBar
        r'SnackBar\([^)]*content:\s*Text\(\s*[\'\"](.*?[\u4e00-\u9fff].*?)[\'\"]',
        r'ScaffoldMessenger[^)]*SnackBar\([^)]*content:\s*Text\(\s*[\'\"](.*?[\u4e00-\u9fff].*?)[\'\"]',
        
        # 其他对话框
        r'SimpleDialog\([^)]*title:\s*Text\(\s*[\'\"](.*?[\u4e00-\u9fff].*?)[\'\"]',
        r'showDialog\([^)]*title:\s*[\'\"](.*?[\u4e00-\u9fff].*?)[\'\"]',
        r'CupertinoAlertDialog\([^)]*title:\s*Text\(\s*[\'\"](.*?[\u4e00-\u9fff].*?)[\'\"]',
        
        # Toast和其他消息
        r'Toast\.show\([^)]*[\'\"](.*?[\u4e00-\u9fff].*?)[\'\"]',
        r'showToast\([^)]*[\'\"](.*?[\u4e00-\u9fff].*?)[\'\"]',
    ],
    
    # 应用栏和导航 - 更全面的导航检测
    "ui_appbar_navigation": [
        # AppBar
        r'AppBar\([^)]*title:\s*Text\(\s*[\'\"](.*?[\u4e00-\u9fff].*?)[\'\"]',
        r'SliverAppBar\([^)]*title:\s*Text\(\s*[\'\"](.*?[\u4e00-\u9fff].*?)[\'\"]',
        r'CupertinoNavigationBar\([^)]*middle:\s*Text\(\s*[\'\"](.*?[\u4e00-\u9fff].*?)[\'\"]',
        
        # Tab相关
        r'Tab\([^)]*text:\s*[\'\"](.*?[\u4e00-\u9fff].*?)[\'\"]',
        r'Tab\([^)]*child:\s*Text\(\s*[\'\"](.*?[\u4e00-\u9fff].*?)[\'\"]',
        r'TabBar\([^)]*Tab\([^)]*text:\s*[\'\"](.*?[\u4e00-\u9fff].*?)[\'\"]',
        
        # 底部导航
        r'BottomNavigationBarItem\([^)]*label:\s*[\'\"](.*?[\u4e00-\u9fff].*?)[\'\"]',
        r'NavigationDestination\([^)]*label:\s*[\'\"](.*?[\u4e00-\u9fff].*?)[\'\"]',
        r'NavigationRailDestination\([^)]*label:\s*Text\(\s*[\'\"](.*?[\u4e00-\u9fff].*?)[\'\"]',
        
        # Drawer
        r'DrawerHeader\([^)]*child:\s*Text\(\s*[\'\"](.*?[\u4e00-\u9fff].*?)[\'\"]',
        r'UserAccountsDrawerHeader\([^)]*accountName:\s*Text\(\s*[\'\"](.*?[\u4e00-\u9fff].*?)[\'\"]',
    ],
    
    # 列表和卡片 - 更全面的列表检测
    "ui_lists_cards": [
        # ListTile
        r'ListTile\([^)]*title:\s*Text\(\s*[\'\"](.*?[\u4e00-\u9fff].*?)[\'\"]',
        r'ListTile\([^)]*subtitle:\s*Text\(\s*[\'\"](.*?[\u4e00-\u9fff].*?)[\'\"]',
        r'ListTile\([^)]*trailing:\s*Text\(\s*[\'\"](.*?[\u4e00-\u9fff].*?)[\'\"]',
        
        # Card
        r'Card\([^)]*child:[^}]*Text\(\s*[\'\"](.*?[\u4e00-\u9fff].*?)[\'\"]',
        
        # ExpansionTile
        r'ExpansionTile\([^)]*title:\s*Text\(\s*[\'\"](.*?[\u4e00-\u9fff].*?)[\'\"]',
        r'ExpansionTile\([^)]*subtitle:\s*Text\(\s*[\'\"](.*?[\u4e00-\u9fff].*?)[\'\"]',
        
        # 其他列表Widget
        r'CheckboxListTile\([^)]*title:\s*Text\(\s*[\'\"](.*?[\u4e00-\u9fff].*?)[\'\"]',
        r'RadioListTile\([^)]*title:\s*Text\(\s*[\'\"](.*?[\u4e00-\u9fff].*?)[\'\"]',
        r'SwitchListTile\([^)]*title:\s*Text\(\s*[\'\"](.*?[\u4e00-\u9fff].*?)[\'\"]',
    ],
    
    # 字符串常量和变量
    "string_constants": [
        r'static\s+const\s+String\s+\w+\s*=\s*[\'\"](.*?[\u4e00-\u9fff].*?)[\'\"]',
        r'final\s+String\s+\w+\s*=\s*[\'\"](.*?[\u4e00-\u9fff].*?)[\'\"]',
        r'const\s+String\s+\w+\s*=\s*[\'\"](.*?[\u4e00-\u9fff].*?)[\'\"]',
        r'String\s+\w+\s*=\s*[\'\"](.*?[\u4e00-\u9fff].*?)[\'\"]',
        r'var\s+\w+\s*=\s*[\'\"](.*?[\u4e00-\u9fff].*?)[\'\"]',
    ],
    
    # 异常和日志消息
    "error_messages": [
        r'throw\s+\w*Exception\(\s*[\'\"](.*?[\u4e00-\u9fff].*?)[\'\"]',
        r'throw\s+\w*Error\(\s*[\'\"](.*?[\u4e00-\u9fff].*?)[\'\"]',
        r'assert\(\s*[^,]+,\s*[\'\"](.*?[\u4e00-\u9fff].*?)[\'\"]',
        r'debugPrint\(\s*[\'\"](.*?[\u4e00-\u9fff].*?)[\'\"]',
        r'print\(\s*[\'\"](.*?[\u4e00-\u9fff].*?)[\'\"]',
        r'log\(\s*[\'\"](.*?[\u4e00-\u9fff].*?)[\'\"]',
        r'logger\.\w+\(\s*[\'\"](.*?[\u4e00-\u9fff].*?)[\'\"]',
    ],
}

# 更严格的排除模式
EXCLUSION_PATTERNS = [
    r'^\s*//.*$',  # 单行注释
    r'/\*.*?\*/',  # 多行注释
    r'https?://\S+',  # URL
    r'file://\S+',  # 文件路径
    r'package:\S+',  # package引用
    r'import\s+[\'\"]\S+[\'\"]',  # import语句
    r'@\w+\([^)]*\)',  # 注解
    r'assets/\S+',  # 资源路径
    r'fonts/\S+',  # 字体路径
]

class OptimizedHardcodedDetector:
    def __init__(self):
        self.ensure_report_dir()
        self.existing_arb_keys = self.load_existing_arb_keys()
        self.existing_arb_values = self.load_existing_arb_values()
        self.generated_keys = set()  # 跟踪已生成的键名，避免重复
        
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
                    for key, value in data.items():
                        if not key.startswith('@') and isinstance(value, str):
                            arb_data[key] = value
                except (json.JSONDecodeError, UnicodeDecodeError) as e:
                    print(f"Warning: Error loading {arb_path}: {e}")
        return arb_data    
    def load_existing_arb_values(self):
        """加载现有ARB文件中的所有值"""
        return set(self.existing_arb_keys.values())
    
    def find_similar_arb_key(self, text, threshold=0.7):
        """查找相似的ARB键值，实现复用"""
        best_match = None
        best_ratio = 0
        
        # 清理文本：移除变量插值和特殊符号
        clean_text = re.sub(r'\$\{[^}]*\}', '', text)
        clean_text = re.sub(r'[：:{}$\(\)]', '', clean_text).strip()
        
        for key, value in self.existing_arb_keys.items():
            # 清理ARB值
            clean_value = re.sub(r'\{[^}]*\}', '', value)
            clean_value = re.sub(r'[：:{}$\(\)]', '', clean_value).strip()
            
            # 计算文本相似度
            ratio = SequenceMatcher(None, clean_text, clean_value).ratio()
            if ratio > best_ratio and ratio >= threshold:
                best_match = key
                best_ratio = ratio        
        return best_match, best_ratio
    
    def generate_camelcase_key(self, text, context, file_context):
        """根据现有ARB习惯生成驼峰命名的键名"""
        # 移除特殊字符，保留中文和英文
        clean_text = re.sub(r'[^\w\s\u4e00-\u9fff]', ' ', text)
        
        # 扩展的中文-英文映射表，基于项目实际使用情况
        keyword_map = {
            # 基础操作
            '添加': 'add', '删除': 'delete', '移除': 'remove', '编辑': 'edit', '修改': 'edit',
            '保存': 'save', '取消': 'cancel', '确认': 'confirm', '确定': 'ok', 
            '关闭': 'close', '打开': 'open', '新建': 'new', '创建': 'create',
            '更新': 'update', '刷新': 'refresh', '重置': 'reset', '清除': 'clear',
            
            # 搜索和过滤
            '搜索': 'search', '查找': 'find', '过滤': 'filter', '排序': 'sort',
            
            # 系统设置
            '设置': 'settings', '配置': 'config', '选项': 'options', '首选项': 'preferences',
            
            # 界面元素
            '帮助': 'help', '关于': 'about', '信息': 'info', '详情': 'details',
            '标题': 'title', '名称': 'name', '标签': 'label', '描述': 'description',
            '内容': 'content', '文本': 'text', '消息': 'message', '提示': 'hint',
            
            # 状态和反馈
            '错误': 'error', '警告': 'warning', '成功': 'success', '失败': 'failed',
            '完成': 'completed', '进行中': 'inProgress', '等待': 'waiting',
            
            # 项目特定词汇
            '练习': 'practice', '集字': 'collection', '字符': 'character', '字体': 'font',
            '颜色': 'color', '尺寸': 'size', '位置': 'position', '样式': 'style',
            '页面': 'page', '图片': 'image', '图像': 'image', '照片': 'photo',
            '文件': 'file', '文档': 'document', '项目': 'project', '模板': 'template',
            '预览': 'preview', '导出': 'export', '导入': 'import', '备份': 'backup',
            
            # 界面组件
            '按钮': 'button', '菜单': 'menu', '列表': 'list', '表格': 'table',
            '对话框': 'dialog', '窗口': 'window', '面板': 'panel', '工具栏': 'toolbar',
            
            # 动作词汇
            '加载': 'loading', '载入': 'loading', '上传': 'upload', '下载': 'download',
            '同步': 'sync', '分享': 'share', '复制': 'copy', '粘贴': 'paste',
            '撤销': 'undo', '重做': 'redo', '选择': 'select', '选中': 'selected',
            
            # 方向和对齐
            '左': 'left', '右': 'right', '上': 'top', '下': 'bottom', '中': 'center',
            '居中': 'center', '对齐': 'align', '水平': 'horizontal', '垂直': 'vertical',
            
            # 常见词汇
            '是': 'yes', '否': 'no', '有': 'has', '无': 'none', '全部': 'all',
            '部分': 'partial', '详细': 'detail', '简单': 'simple', '高级': 'advanced',
        }
        
        # 提取关键词
        words = clean_text.split()
        keywords = []
        
        for word in words:
            if word in keyword_map:
                keywords.append(keyword_map[word])
            elif re.match(r'^[a-zA-Z]+$', word):
                keywords.append(word.lower())
            elif len(word) <= 2 and re.match(r'^[\u4e00-\u9fff]+$', word):
                # 对于短中文词，尝试直接使用拼音
                keywords.append(word)
        
        # 根据文件上下文添加前缀
        if 'error' in file_context.lower() or context == 'error_messages':
            if not any(k in ['error', 'failed', 'warning'] for k in keywords):
                keywords.insert(0, 'error')
        elif 'dialog' in file_context.lower():
            if not any(k in ['dialog', 'confirm', 'alert'] for k in keywords):
                keywords.insert(0, 'dialog')
        elif 'button' in file_context.lower():
            if not any(k in ['button', 'action'] for k in keywords):
                keywords.insert(0, 'button')
        
        # 如果没有找到合适的关键词，使用智能默认值
        if not keywords:
            if context == 'error_messages':
                keywords = ['message']
            elif context == 'ui_text_widget':
                keywords = ['text']
            elif context == 'ui_properties':
                keywords = ['property']
            else:
                # 尝试从文本长度推断类型
                if len(text) <= 10:
                    keywords = ['label']
                else:
                    keywords = ['message']
        
        # 生成驼峰命名
        if len(keywords) == 1:
            base_key = keywords[0]
        else:
            base_key = keywords[0] + ''.join(word.capitalize() for word in keywords[1:])
        
        # 确保键名符合项目规范（小写开头，驼峰）
        if base_key and base_key[0].isupper():
            base_key = base_key[0].lower() + base_key[1:]
        
        # 确保键名唯一
        key = base_key
        counter = 1
        while key in self.existing_arb_keys or key in self.generated_keys:
            key = f"{base_key}{counter}"
            counter += 1        
        # 记录已生成的键名
        self.generated_keys.add(key)
        
        return key
    
    def is_excluded_line(self, line, match_start, match_end):
        """检查匹配是否在排除模式中"""
        for pattern in EXCLUSION_PATTERNS:
            for match in re.finditer(pattern, line, re.DOTALL):
                if match.start() <= match_start and match.end() >= match_end:
                    return True
        return False
    
    def detect_hardcoded_text_with_multiline(self):
        """增强的硬编码文本检测，支持多行匹配"""
        results = defaultdict(list)
        
        # 搜索所有Dart文件
        dart_files = glob.glob(os.path.join(CODE_DIR, "**/*.dart"), recursive=True)
        
        for dart_file in dart_files:
            try:
                with open(dart_file, 'r', encoding='utf-8') as f:
                    content = f.read()
                    lines = content.split('\n')
                
                # 单行检测
                for line_num, line in enumerate(lines, 1):
                    # 跳过纯英文行和纯符号行
                    if not re.search(r'[\u4e00-\u9fff]', line):
                        continue
                    
                    self._process_line(line, line_num, dart_file, results)
                
                # 多行检测（处理跨行的Widget定义）
                self._process_multiline_patterns(content, dart_file, results)
                    
            except (UnicodeDecodeError, FileNotFoundError) as e:
                print(f"Warning: Error reading {dart_file}: {e}")
        
        return results
    
    def _process_line(self, line, line_num, dart_file, results):
        """处理单行文本检测"""
        for context, patterns in ENHANCED_DETECTION_PATTERNS.items():
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
                        
                        # 清理文本
                        cleaned_text = re.sub(r'\s+', ' ', chinese_text.strip())
                        if len(cleaned_text) == 0:
                            continue
                        
                        # 检查是否需要复用现有ARB键
                        similar_key, similarity = self.find_similar_arb_key(cleaned_text)
                        
                        file_path = os.path.relpath(dart_file, CODE_DIR)
                        
                        if similar_key and similarity >= 0.9:
                            # 高度相似，建议复用
                            results[context].append({
                                'file': file_path,
                                'line': line_num,
                                'text': cleaned_text,
                                'original_line': line.strip(),
                                'suggested_key': similar_key,
                                'reuse_existing': True,
                                'similarity': similarity,
                                'existing_value': self.existing_arb_keys[similar_key],
                                'pattern_matched': pattern,
                            })
                        elif cleaned_text in self.existing_arb_values:
                            # 完全匹配，跳过
                            continue
                        else:
                            # 需要新建键
                            suggested_key = self.generate_camelcase_key(cleaned_text, context, file_path)
                            
                            results[context].append({
                                'file': file_path,
                                'line': line_num,
                                'text': cleaned_text,
                                'original_line': line.strip(),
                                'suggested_key': suggested_key,
                                'reuse_existing': False,
                                'similar_key': similar_key if similarity >= 0.6 else None,
                                'similarity': similarity if similarity >= 0.6 else 0,
                                'pattern_matched': pattern,
                            })
    
    def _process_multiline_patterns(self, content, dart_file, results):
        """处理跨行的Widget定义"""
        # 移除注释以避免误匹配
        content_no_comments = re.sub(r'//.*$', '', content, flags=re.MULTILINE)
        content_no_comments = re.sub(r'/\*.*?\*/', '', content_no_comments, flags=re.DOTALL)
        
        # 多行Widget模式
        multiline_patterns = {
            'ui_text_widget': [
                r'Text\s*\(\s*[\'\"](.*?[\u4e00-\u9fff].*?)[\'\"]',
                r'const\s+Text\s*\(\s*[\'\"](.*?[\u4e00-\u9fff].*?)[\'\"]',
                r'SelectableText\s*\(\s*[\'\"](.*?[\u4e00-\u9fff].*?)[\'\"]',
            ],
            'ui_buttons_labels': [
                r'ElevatedButton\s*\([^}]*child:\s*Text\s*\(\s*[\'\"](.*?[\u4e00-\u9fff].*?)[\'\"]',
                r'TextButton\s*\([^}]*child:\s*Text\s*\(\s*[\'\"](.*?[\u4e00-\u9fff].*?)[\'\"]',
            ],
        }
        
        for context, patterns in multiline_patterns.items():
            for pattern in patterns:
                for match in re.finditer(pattern, content_no_comments, re.DOTALL):
                    chinese_text = match.group(1)
                    
                    if not re.search(r'[\u4e00-\u9fff]', chinese_text):
                        continue
                    
                    # 找到行号
                    line_num = content[:match.start()].count('\n') + 1
                    
                    # 清理文本
                    cleaned_text = re.sub(r'\s+', ' ', chinese_text.strip())
                    if len(cleaned_text) == 0:
                        continue
                    
                    # 检查是否已经在单行检测中处理过
                    file_path = os.path.relpath(dart_file, CODE_DIR)
                    already_processed = any(
                        item['file'] == file_path and 
                        item['line'] == line_num and 
                        item['text'] == cleaned_text
                        for items in results.values()
                        for item in items
                    )
                    
                    if already_processed:
                        continue
                    
                    # 处理新发现的硬编码文本
                    similar_key, similarity = self.find_similar_arb_key(cleaned_text)
                    
                    if similar_key and similarity >= 0.9:
                        results[context].append({
                            'file': file_path,
                            'line': line_num,
                            'text': cleaned_text,
                            'original_line': content.split('\n')[line_num-1].strip() if line_num <= len(content.split('\n')) else '',
                            'suggested_key': similar_key,
                            'reuse_existing': True,
                            'similarity': similarity,
                            'existing_value': self.existing_arb_keys[similar_key],
                            'pattern_matched': pattern,
                            'multiline_match': True,
                        })
                    elif cleaned_text not in self.existing_arb_values:
                        suggested_key = self.generate_camelcase_key(cleaned_text, context, file_path)
                        
                        results[context].append({
                            'file': file_path,
                            'line': line_num,
                            'text': cleaned_text,
                            'original_line': content.split('\n')[line_num-1].strip() if line_num <= len(content.split('\n')) else '',
                            'suggested_key': suggested_key,
                            'reuse_existing': False,
                            'similar_key': similar_key if similarity >= 0.6 else None,
                            'similarity': similarity if similarity >= 0.6 else 0,
                            'pattern_matched': pattern,
                            'multiline_match': True,
                        })
    
    def generate_optimized_reports(self, detection_results):
        """生成优化的检测报告"""
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        
        # 1. 生成汇总报告
        summary_path = os.path.join(REPORT_DIR, f"optimized_summary_{timestamp}.txt")
        with open(summary_path, 'w', encoding='utf-8') as f:
            f.write("=== 优化硬编码文本检测汇总报告 ===\n")
            f.write(f"检测时间: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n\n")
            
            total_count = sum(len(items) for items in detection_results.values())
            reuse_count = sum(
                len([item for item in items if item.get('reuse_existing', False)])
                for items in detection_results.values()
            )
            new_count = total_count - reuse_count
            
            f.write(f"检测到的硬编码文本总数: {total_count}\n")
            f.write(f"可复用现有ARB键: {reuse_count}\n")
            f.write(f"需新建ARB键: {new_count}\n\n")
            
            f.write("按类型分布:\n")
            for context, items in detection_results.items():
                if items:
                    reuse_in_context = len([item for item in items if item.get('reuse_existing', False)])
                    f.write(f"  - {context}: {len(items)} 个 (复用: {reuse_in_context}, 新建: {len(items) - reuse_in_context})\n")
        
        # 2. 生成详细报告（按复用和新建分类）
        detail_path = os.path.join(REPORT_DIR, f"optimized_detail_{timestamp}.txt")
        with open(detail_path, 'w', encoding='utf-8') as f:
            f.write("=== 优化硬编码文本详细报告 ===\n\n")
            
            f.write("=== 可复用现有ARB键的硬编码文本 ===\n")
            for context, items in detection_results.items():
                reuse_items = [item for item in items if item.get('reuse_existing', False)]
                if reuse_items:
                    f.write(f"\n--- {context.upper()} ({len(reuse_items)} 个) ---\n")
                    for item in reuse_items:
                        f.write(f"文件: {item['file']}, 行: {item['line']}\n")
                        f.write(f"硬编码文本: \"{item['text']}\"\n")
                        f.write(f"建议复用键: {item['suggested_key']}\n")
                        f.write(f"现有值: \"{item['existing_value']}\"\n")
                        f.write(f"相似度: {item['similarity']:.2f}\n")
                        f.write(f"代码行: {item['original_line']}\n")
                        f.write("-" * 40 + "\n")
            
            f.write("\n\n=== 需新建ARB键的硬编码文本 ===\n")
            for context, items in detection_results.items():
                new_items = [item for item in items if not item.get('reuse_existing', False)]
                if new_items:
                    f.write(f"\n--- {context.upper()} ({len(new_items)} 个) ---\n")
                    for item in new_items:
                        f.write(f"文件: {item['file']}, 行: {item['line']}\n")
                        f.write(f"硬编码文本: \"{item['text']}\"\n")
                        f.write(f"建议新键: {item['suggested_key']}\n")
                        if item.get('similar_key'):
                            f.write(f"相似键: {item['similar_key']} (相似度: {item['similarity']:.2f})\n")
                        f.write(f"代码行: {item['original_line']}\n")
                        f.write("-" * 40 + "\n")
        
        # 3. 生成优化的映射文件
        mapping_path = os.path.join(REPORT_DIR, f"optimized_mapping_{timestamp}.yaml")
        mapping_data = OrderedDict()
        
        # 复用现有键的映射
        reuse_mappings = OrderedDict()
        for context, items in detection_results.items():
            reuse_items = [item for item in items if item.get('reuse_existing', False)]
            if reuse_items:
                context_reuse = OrderedDict()
                for item in reuse_items:
                    context_reuse[item['suggested_key']] = {
                        'action': 'reuse_existing',
                        'hardcoded_text': item['text'],
                        'existing_key': item['suggested_key'],
                        'existing_value': item['existing_value'],
                        'similarity': item['similarity'],
                        'file': item['file'],
                        'line': item['line'],
                        'approved': False,  # 需要用户确认
                    }
                reuse_mappings[context] = context_reuse
        
        if reuse_mappings:
            mapping_data['reuse_existing_keys'] = reuse_mappings
        
        # 新建键的映射
        new_mappings = OrderedDict()
        for context, items in detection_results.items():
            new_items = [item for item in items if not item.get('reuse_existing', False)]
            if new_items:
                context_new = OrderedDict()
                for item in new_items:
                    context_new[item['suggested_key']] = {
                        'action': 'create_new',
                        'text_zh': item['text'],
                        'text_en': item['text'],  # 需要用户翻译
                        'file': item['file'],
                        'line': item['line'],
                        'context_type': context,
                        'similar_key': item.get('similar_key'),
                        'similarity': item.get('similarity', 0),
                        'approved': False,  # 需要用户确认
                    }
                new_mappings[context] = context_new
        
        if new_mappings:
            mapping_data['create_new_keys'] = new_mappings
        
        with open(mapping_path, 'w', encoding='utf-8') as f:
            f.write("# 优化的硬编码文本映射文件\n")
            f.write("# 包含ARB键复用和新建两种处理方式\n")
            f.write("# 请审核以下内容，并将 approved 设置为 true\n\n")
            f.write("# reuse_existing_keys: 复用现有ARB键的硬编码文本\n")
            f.write("# create_new_keys: 需要新建ARB键的硬编码文本\n\n")
            yaml.dump(mapping_data, f, default_flow_style=False, allow_unicode=True, sort_keys=False)
        
        return {
            'summary': summary_path,
            'detail': detail_path,
            'mapping': mapping_path,
            'total_count': total_count,
            'reuse_count': reuse_count,
            'new_count': new_count,
        }
    
    def run_optimized_detection(self):
        """运行优化的检测流程"""
        print("=== 优化硬编码文本检测器 ===")
        print("正在执行增强检测...")
        
        # 执行检测
        results = self.detect_hardcoded_text_with_multiline()
        
        # 生成报告
        report_info = self.generate_optimized_reports(results)
        
        # 输出结果
        print(f"\n检测完成！")
        print(f"总计发现硬编码文本: {report_info['total_count']} 个")
        print(f"可复用现有ARB键: {report_info['reuse_count']} 个")
        print(f"需新建ARB键: {report_info['new_count']} 个")
        
        print(f"\n按类型分布:")
        for context, items in results.items():
            if items:
                reuse_count = len([item for item in items if item.get('reuse_existing', False)])
                new_count = len(items) - reuse_count
                print(f"  - {context}: {len(items)} 个 (复用: {reuse_count}, 新建: {new_count})")
        
        print(f"\n生成的文件:")
        print(f"  - 汇总报告: {report_info['summary']}")
        print(f"  - 详细报告: {report_info['detail']}")
        print(f"  - 优化映射文件: {report_info['mapping']}")
        
        print(f"\n优化特性:")
        print("✅ 更全面的UI文本检测模式")
        print("✅ 智能复用现有ARB键")
        print("✅ 驼峰命名符合现有习惯")
        print("✅ 支持多行Widget检测")
        print("✅ 更严格的排除规则")
        
        return report_info

def main():
    detector = OptimizedHardcodedDetector()
    detector.run_optimized_detection()

if __name__ == "__main__":
    main()
