#!/usr/bin/env python3
"""
智能ARB键值匹配器
用于为硬编码文本匹配现有ARB键值或生成新的键值建议
"""

import os
import json
import re
import argparse
from typing import Dict, List, Tuple, Optional
from difflib import SequenceMatcher
from collections import defaultdict
import jieba  # 需要安装: pip install jieba

class SmartARBMatcher:
    def __init__(self, arb_zh_path: str = "lib/l10n/app_zh.arb", arb_en_path: str = "lib/l10n/app_en.arb"):
        self.arb_zh_path = arb_zh_path
        self.arb_en_path = arb_en_path
        self.zh_entries = {}
        self.en_entries = {}
        self.load_arb_files()
        
        # 模块映射：路径关键词 -> 模块前缀
        self.module_mapping = {
            'auth': 'auth',
            'login': 'auth',
            'register': 'auth',
            'home': 'home',
            'main': 'home',
            'settings': 'settings',
            'profile': 'profile',
            'library': 'library',
            'practice': 'practice',
            'edit': 'edit',
            'dialog': 'dialog',
            'widget': 'widget',
            'component': 'component',
            'page': 'page',
        }
        
        # 组件类型映射
        self.component_mapping = {
            'text_widget': 'text',
            'button_text': 'button',
            'title_text': 'title',
            'hint_text': 'hint',
            'error_text': 'error',
            'label_text': 'label',
            'dialog_content': 'dialog',
            'snackbar_content': 'message',
            'tooltip': 'tooltip',
            'placeholder': 'placeholder',
        }
        
        # 语义关键词映射
        self.semantic_keywords = {
            '保存': 'save',
            '删除': 'delete',
            '取消': 'cancel',
            '确认': 'confirm',
            '提交': 'submit',
            '返回': 'back',
            '下一步': 'next',
            '上一步': 'previous',
            '完成': 'complete',
            '开始': 'start',
            '结束': 'end',
            '登录': 'login',
            '注册': 'register',
            '退出': 'logout',
            '搜索': 'search',
            '设置': 'settings',
            '帮助': 'help',
            '关于': 'about',
            '成功': 'success',
            '失败': 'failed',
            '错误': 'error',
            '警告': 'warning',
            '提示': 'tip',
            '消息': 'message',
        }
    
    def load_arb_files(self):
        """加载ARB文件"""
        try:
            with open(self.arb_zh_path, 'r', encoding='utf-8') as f:
                zh_data = json.load(f)
                self.zh_entries = {k: v for k, v in zh_data.items() if not k.startswith('@')}
            
            with open(self.arb_en_path, 'r', encoding='utf-8') as f:
                en_data = json.load(f)
                self.en_entries = {k: v for k, v in en_data.items() if not k.startswith('@')}
                
            print(f"✅ 已加载 {len(self.zh_entries)} 个ARB键值")
            
        except Exception as e:
            print(f"❌ 加载ARB文件失败: {e}")
    
    def calculate_text_similarity(self, text1: str, text2: str) -> float:
        """计算文本相似度"""
        # 去除标点符号和空格
        clean_text1 = re.sub(r'[^\w\u4e00-\u9fff]', '', text1)
        clean_text2 = re.sub(r'[^\w\u4e00-\u9fff]', '', text2)
        
        # 计算字符级相似度
        char_similarity = SequenceMatcher(None, clean_text1, clean_text2).ratio()
        
        # 计算词级相似度（针对中文）
        words1 = set(jieba.cut(clean_text1))
        words2 = set(jieba.cut(clean_text2))
        
        if words1 and words2:
            word_similarity = len(words1 & words2) / len(words1 | words2)
        else:
            word_similarity = 0
        
        # 综合相似度
        return (char_similarity * 0.6 + word_similarity * 0.4)
    
    def find_similar_keys(self, text: str, threshold: float = 0.7) -> List[Tuple[str, str, float]]:
        """查找相似的现有键值"""
        similar_keys = []
        
        for key, value in self.zh_entries.items():
            similarity = self.calculate_text_similarity(text, value)
            if similarity >= threshold:
                similar_keys.append((key, value, similarity))
        
        # 按相似度排序
        similar_keys.sort(key=lambda x: x[2], reverse=True)
        return similar_keys[:5]  # 返回前5个最相似的
    
    def extract_module_from_path(self, file_path: str) -> str:
        """从文件路径提取模块信息"""
        path_lower = file_path.lower().replace('\\', '/')
        
        for keyword, module in self.module_mapping.items():
            if keyword in path_lower:
                return module
        
        # 如果没有匹配到，使用父目录名
        parts = path_lower.split('/')
        if len(parts) >= 2:
            parent_dir = parts[-2]
            # 清理目录名
            clean_dir = re.sub(r'[^a-z]', '', parent_dir)
            if clean_dir:
                return clean_dir[:8]  # 限制长度
        
        return 'common'
    
    def extract_component_type(self, text_type: str) -> str:
        """提取组件类型"""
        return self.component_mapping.get(text_type, 'text')
    
    def extract_semantic_meaning(self, text: str) -> str:
        """提取语义含义"""
        text_clean = re.sub(r'[^\w\u4e00-\u9fff]', '', text)
        
        # 查找关键词
        for keyword, semantic in self.semantic_keywords.items():
            if keyword in text:
                return semantic
        
        # 使用分词提取主要词汇
        words = list(jieba.cut(text_clean))
        # 过滤停用词和单字符
        meaningful_words = [w for w in words if len(w) > 1 and w not in ['的', '了', '是', '在', '有', '和', '就', '都', '与']]
        
        if meaningful_words:
            # 选择最长的词作为语义标识
            main_word = max(meaningful_words, key=len)
            # 转换为拼音或英文（简化处理）
            return self.chinese_to_pinyin(main_word)
        
        return 'content'
    
    def chinese_to_pinyin(self, text: str) -> str:
        """简化的中文到拼音转换"""
        # 这里使用简单的映射，实际项目中可以使用 pypinyin 库
        pinyin_map = {
            '保存': 'save', '删除': 'delete', '取消': 'cancel', '确认': 'confirm',
            '提交': 'submit', '返回': 'back', '搜索': 'search', '设置': 'settings',
            '用户': 'user', '密码': 'password', '邮箱': 'email', '手机': 'phone',
            '姓名': 'name', '地址': 'address', '年龄': 'age', '性别': 'gender',
            '文件': 'file', '图片': 'image', '视频': 'video', '音频': 'audio',
            '标题': 'title', '内容': 'content', '描述': 'description',
            '时间': 'time', '日期': 'date', '位置': 'location',
            '页面': 'page', '菜单': 'menu', '按钮': 'button', '输入': 'input',
        }
        
        # 查找完全匹配
        if text in pinyin_map:
            return pinyin_map[text]
        
        # 查找部分匹配
        for chinese, english in pinyin_map.items():
            if chinese in text:
                return english
        
        # 如果没有匹配，使用数字作为后缀
        import hashlib
        hash_value = hashlib.md5(text.encode()).hexdigest()[:4]
        return f'text_{hash_value}'
    
    def suggest_key_name(self, text: str, file_path: str, text_type: str, context: str = '') -> str:
        """建议新的键名"""
        module = self.extract_module_from_path(file_path)
        component = self.extract_component_type(text_type)
        semantic = self.extract_semantic_meaning(text)
        
        # 构建键名
        key_parts = [module, component, semantic]
        
        # 从上下文中提取额外信息
        if context:
            context_lower = context.lower()
            if 'dialog' in context_lower:
                key_parts.insert(-1, 'dialog')
            elif 'form' in context_lower:
                key_parts.insert(-1, 'form')
        
        suggested_key = '_'.join(key_parts)
        
        # 确保键名唯一
        original_key = suggested_key
        counter = 1
        while suggested_key in self.zh_entries:
            suggested_key = f"{original_key}_{counter}"
            counter += 1
        
        return suggested_key
    
    def match_or_suggest(self, text: str, file_path: str, text_type: str, context: str = '') -> Dict:
        """匹配现有键值或建议新键值"""
        # 首先查找相似的现有键值
        similar_keys = self.find_similar_keys(text)
        
        result = {
            'text': text,
            'file_path': file_path,
            'text_type': text_type,
            'context': context,
            'similar_keys': similar_keys,
            'suggested_key': None,
            'action': 'unknown'
        }
        
        if similar_keys and similar_keys[0][2] > 0.85:
            # 高相似度，建议复用
            result['action'] = 'reuse'
            result['recommended_key'] = similar_keys[0][0]
            result['recommended_text'] = similar_keys[0][1]
            result['similarity'] = similar_keys[0][2]
        else:
            # 建议创建新键值
            result['action'] = 'create'
            result['suggested_key'] = self.suggest_key_name(text, file_path, text_type, context)
        
        return result
    
    def batch_match(self, hardcoded_texts: List[Dict]) -> List[Dict]:
        """批量匹配硬编码文本"""
        results = []
        
        print(f"🔍 开始匹配 {len(hardcoded_texts)} 个硬编码文本...")
        
        for i, item in enumerate(hardcoded_texts, 1):
            if i % 20 == 0:
                print(f"   进度: {i}/{len(hardcoded_texts)}")
            
            result = self.match_or_suggest(
                item['text_content'],
                item['file_path'],
                item['text_type'],
                item.get('context', '')
            )
            
            # 添加原始信息
            result.update({
                'line_number': item['line_number'],
                'line_content': item['line_content'],
                'confidence': item.get('confidence', 1.0)
            })
            
            results.append(result)
        
        return results
    
    def generate_arb_additions(self, results: List[Dict], output_file: str = "arb_additions.json"):
        """生成需要添加到ARB的新键值"""
        additions = {
            'zh': {},
            'en': {}
        }
        
        for result in results:
            if result['action'] == 'create' and result['suggested_key']:
                key = result['suggested_key']
                zh_text = result['text']
                
                # 简单的英文翻译（实际项目中应该使用专业翻译）
                en_text = self.simple_translate_to_english(zh_text)
                
                additions['zh'][key] = zh_text
                additions['en'][key] = en_text
        
        with open(output_file, 'w', encoding='utf-8') as f:
            json.dump(additions, f, ensure_ascii=False, indent=2)
        
        print(f"✅ ARB新增键值已生成: {output_file}")
        print(f"   需要添加 {len(additions['zh'])} 个新键值")
        
        return additions
    
    def simple_translate_to_english(self, chinese_text: str) -> str:
        """简单的中英文翻译（实际项目中应该使用专业翻译服务）"""
        # 简单的翻译映射
        translation_map = {
            '保存': 'Save',
            '删除': 'Delete',
            '取消': 'Cancel',
            '确认': 'Confirm',
            '提交': 'Submit',
            '返回': 'Back',
            '搜索': 'Search',
            '设置': 'Settings',
            '登录': 'Login',
            '注册': 'Register',
            '退出': 'Logout',
            '成功': 'Success',
            '失败': 'Failed',
            '错误': 'Error',
            '警告': 'Warning',
            '提示': 'Tip',
            '消息': 'Message',
            '开始': 'Start',
            '结束': 'End',
            '完成': 'Complete',
            '帮助': 'Help',
            '关于': 'About',
            '用户': 'User',
            '密码': 'Password',
            '邮箱': 'Email',
            '手机': 'Phone',
            '姓名': 'Name',
            '地址': 'Address',
            '文件': 'File',
            '图片': 'Image',
            '请输入': 'Please enter',
            '请选择': 'Please select',
            '加载中': 'Loading',
            '暂无数据': 'No data',
            '网络错误': 'Network error',
            '操作成功': 'Operation successful',
            '操作失败': 'Operation failed',
        }
        
        # 查找直接匹配
        if chinese_text in translation_map:
            return translation_map[chinese_text]
        
        # 查找部分匹配并替换
        result = chinese_text
        for chinese, english in translation_map.items():
            if chinese in result:
                result = result.replace(chinese, english)
        
        # 如果没有任何匹配，标记需要人工翻译
        if result == chinese_text:
            return f"[TODO: Translate '{chinese_text}']"
        
        return result
    
    def generate_match_report(self, results: List[Dict], output_file: str = "arb_match_report.md"):
        """生成匹配报告"""
        reuse_count = sum(1 for r in results if r['action'] == 'reuse')
        create_count = sum(1 for r in results if r['action'] == 'create')
        
        with open(output_file, 'w', encoding='utf-8') as f:
            f.write("# ARB键值匹配报告\n\n")
            f.write(f"生成时间: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n\n")
            
            # 统计信息
            f.write("## 统计信息\n\n")
            f.write(f"- 总计硬编码文本: {len(results)} 处\n")
            f.write(f"- 可复用现有键值: {reuse_count} 处\n")
            f.write(f"- 需要创建新键值: {create_count} 处\n")
            f.write(f"- 复用率: {reuse_count/len(results)*100:.1f}%\n\n")
            
            # 可复用的键值
            if reuse_count > 0:
                f.write("## 可复用现有键值\n\n")
                for result in results:
                    if result['action'] == 'reuse':
                        f.write(f"### {result['file_path']}:{result['line_number']}\n\n")
                        f.write(f"- **硬编码文本**: `{result['text']}`\n")
                        f.write(f"- **推荐键值**: `{result['recommended_key']}`\n")
                        f.write(f"- **键值文本**: `{result['recommended_text']}`\n")
                        f.write(f"- **相似度**: {result['similarity']:.2f}\n")
                        f.write(f"- **代码行**: `{result['line_content']}`\n\n")
            
            # 需要创建的新键值
            if create_count > 0:
                f.write("## 需要创建的新键值\n\n")
                for result in results:
                    if result['action'] == 'create':
                        f.write(f"### {result['file_path']}:{result['line_number']}\n\n")
                        f.write(f"- **硬编码文本**: `{result['text']}`\n")
                        f.write(f"- **建议键名**: `{result['suggested_key']}`\n")
                        f.write(f"- **代码行**: `{result['line_content']}`\n")
                        if result['similar_keys']:
                            f.write("- **相似的现有键值**:\n")
                            for key, text, sim in result['similar_keys'][:3]:
                                f.write(f"  - `{key}`: {text} (相似度: {sim:.2f})\n")
                        f.write("\n")
        
        print(f"✅ 匹配报告已生成: {output_file}")

def main():
    parser = argparse.ArgumentParser(description='智能ARB键值匹配器')
    parser.add_argument('--input', required=True, help='硬编码文本JSON文件')
    parser.add_argument('--arb-zh', default='lib/l10n/app_zh.arb', help='中文ARB文件路径')
    parser.add_argument('--arb-en', default='lib/l10n/app_en.arb', help='英文ARB文件路径')
    parser.add_argument('--report', default='arb_match_report.md', help='匹配报告输出文件')
    parser.add_argument('--additions', default='arb_additions.json', help='新键值输出文件')
    parser.add_argument('--threshold', type=float, default=0.7, help='相似度阈值')
    
    args = parser.parse_args()
    
    # 加载硬编码文本数据
    try:
        with open(args.input, 'r', encoding='utf-8') as f:
            hardcoded_texts = json.load(f)
        print(f"✅ 已加载 {len(hardcoded_texts)} 个硬编码文本")
    except Exception as e:
        print(f"❌ 加载硬编码文本文件失败: {e}")
        return
    
    # 创建匹配器
    matcher = SmartARBMatcher(args.arb_zh, args.arb_en)
    
    # 执行匹配
    results = matcher.batch_match(hardcoded_texts)
    
    # 生成报告
    matcher.generate_match_report(results, args.report)
    
    # 生成新键值
    matcher.generate_arb_additions(results, args.additions)
    
    # 输出统计
    reuse_count = sum(1 for r in results if r['action'] == 'reuse')
    create_count = sum(1 for r in results if r['action'] == 'create')
    
    print(f"\n📊 匹配结果:")
    print(f"   可复用现有键值: {reuse_count} 处")
    print(f"   需要创建新键值: {create_count} 处")
    print(f"   复用率: {reuse_count/len(results)*100:.1f}%")

if __name__ == "__main__":
    import datetime
    main()
