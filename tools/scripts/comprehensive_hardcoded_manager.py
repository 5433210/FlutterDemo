#!/usr/bin/env python3
"""
综合硬编码文本管理器 - 统一管理UI文本和枚举显示名称的检测与替换
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
REPORT_DIR = "comprehensive_hardcoded_report"

class ComprehensiveHardcodedManager:
    def __init__(self):
        self.ensure_report_dir()
        
    def ensure_report_dir(self):
        """确保报告目录存在"""
        if not os.path.exists(REPORT_DIR):
            os.makedirs(REPORT_DIR)
    
    def run_ui_detection(self):
        """运行UI文本检测"""
        print("=== 开始UI文本检测 ===")
        
        try:
            # 动态导入并运行UI检测器
            import sys
            if '.' not in sys.path:
                sys.path.insert(0, '.')
            
            from enhanced_hardcoded_detector import EnhancedHardcodedDetector
            
            detector = EnhancedHardcodedDetector()
            ui_results = detector.detect_hardcoded_text()
            ui_report = detector.generate_reports(ui_results)
            
            return {
                'success': True,
                'results': ui_results,
                'report_info': ui_report,
                'type': 'ui_text'
            }
            
        except Exception as e:
            print(f"UI文本检测失败: {e}")
            return {'success': False, 'error': str(e), 'type': 'ui_text'}
    
    def run_enum_detection(self):
        """运行枚举显示名称检测"""
        print("\n=== 开始枚举显示名称检测 ===")
        
        try:
            from enum_display_detector import EnumDisplayNameDetector
            
            detector = EnumDisplayNameDetector()
            enum_results = detector.detect_enum_hardcoded_text()
            enum_report = detector.generate_enum_reports(enum_results)
            
            return {
                'success': True,
                'results': enum_results,
                'report_info': enum_report,
                'type': 'enum_display'
            }
            
        except Exception as e:
            print(f"枚举显示名称检测失败: {e}")
            return {'success': False, 'error': str(e), 'type': 'enum_display'}
    
    def merge_detection_results(self, ui_result, enum_result):
        """合并检测结果"""
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        
        # 创建综合映射文件
        comprehensive_mapping = OrderedDict()
        
        # 添加UI文本结果
        if ui_result['success']:
            comprehensive_mapping['ui_text_mappings'] = OrderedDict()
            
            ui_results = ui_result['results']
            for context, items in ui_results.items():
                if items:
                    context_mappings = OrderedDict()
                    for item in items:
                        key = item['suggested_key']
                        # 避免键重复
                        counter = 1
                        original_key = key
                        while any(key in mapping for mapping in comprehensive_mapping.values() if isinstance(mapping, dict)):
                            key = f"{original_key}_{counter}"
                            counter += 1
                        
                        context_mappings[key] = {
                            'text_zh': item['text'],
                            'text_en': item['text'],  # 需要用户翻译
                            'file': item['file'],
                            'line': item['line'],
                            'context_type': context,
                            'detection_type': 'ui_text',
                            'approved': False
                        }
                    
                    if context_mappings:
                        comprehensive_mapping['ui_text_mappings'][context] = context_mappings
        
        # 添加枚举结果
        if enum_result['success']:
            comprehensive_mapping['enum_mappings'] = OrderedDict()
            
            enum_results = enum_result['results']
            
            # 基于枚举的结果
            if enum_results.get('enum_based'):
                enum_based_mappings = OrderedDict()
                for enum_analysis in enum_results['enum_based']:
                    enum_name = enum_analysis['enum_name']
                    enum_items = OrderedDict()
                    
                    for display in enum_analysis['hardcoded_displays']:
                        enum_value = display['enum_value'] or 'unknown'
                        key = f"enum_{enum_name.lower()}_{enum_value.lower()}"
                        key = re.sub(r'[^a-z0-9_]', '', key)
                        
                        enum_items[key] = {
                            'text_zh': display['text'],
                            'text_en': display['text'],
                            'enum_name': enum_name,
                            'enum_value': enum_value,
                            'file': display['file'],
                            'line': display['line'],
                            'detection_type': 'enum_based',
                            'approved': False
                        }
                    
                    if enum_items:
                        enum_based_mappings[enum_name] = enum_items
                
                if enum_based_mappings:
                    comprehensive_mapping['enum_mappings']['enum_based'] = enum_based_mappings
            
            # 基于模式的结果
            if enum_results.get('pattern_based'):
                pattern_based_mappings = OrderedDict()
                for pattern_type, items in enum_results['pattern_based'].items():
                    if items:
                        pattern_items = OrderedDict()
                        for i, item in enumerate(items):
                            key = f"enum_pattern_{pattern_type}_{i+1}"
                            pattern_items[key] = {
                                'text_zh': item['text'],
                                'text_en': item['text'],
                                'pattern_type': pattern_type,
                                'file': item['file'],
                                'line': item['line'],
                                'detection_type': 'enum_pattern',
                                'approved': False
                            }
                        
                        pattern_based_mappings[pattern_type] = pattern_items
                
                if pattern_based_mappings:
                    comprehensive_mapping['enum_mappings']['pattern_based'] = pattern_based_mappings
        
        # 保存综合映射文件
        comprehensive_mapping_path = os.path.join(REPORT_DIR, f"comprehensive_mapping_{timestamp}.yaml")
        with open(comprehensive_mapping_path, 'w', encoding='utf-8') as f:
            f.write("# 综合硬编码文本映射文件\n")
            f.write("# 包含UI界面文本和枚举显示名称的硬编码检测结果\n")
            f.write("# 请审核以下内容，修改英文翻译，并将 approved 设置为 true\n")
            f.write("# 只有 approved: true 的条目会被处理\n\n")
            yaml.dump(comprehensive_mapping, f, default_flow_style=False, allow_unicode=True, sort_keys=False)
        
        return {
            'mapping_file': comprehensive_mapping_path,
            'timestamp': timestamp
        }
    
    def generate_comprehensive_summary(self, ui_result, enum_result, merge_result):
        """生成综合汇总报告"""
        timestamp = merge_result['timestamp']
        summary_path = os.path.join(REPORT_DIR, f"comprehensive_summary_{timestamp}.txt")
        
        with open(summary_path, 'w', encoding='utf-8') as f:
            f.write("=== 综合硬编码文本检测汇总报告 ===\n")
            f.write(f"检测时间: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n\n")
            
            # UI文本检测结果
            f.write("=== UI文本检测结果 ===\n")
            if ui_result['success']:
                ui_total = sum(len(items) for items in ui_result['results'].values())
                f.write(f"检测到的UI硬编码文本总数: {ui_total}\n")
                f.write("按类型分布:\n")
                for context, items in ui_result['results'].items():
                    if items:
                        f.write(f"  - {context}: {len(items)} 个\n")
            else:
                f.write(f"检测失败: {ui_result['error']}\n")
            
            f.write("\n")
            
            # 枚举检测结果
            f.write("=== 枚举显示名称检测结果 ===\n")
            if enum_result['success']:
                enum_based_total = sum(len(enum_analysis['hardcoded_displays']) for enum_analysis in enum_result['results'].get('enum_based', []))
                pattern_based_total = sum(len(items) for items in enum_result['results'].get('pattern_based', {}).values())
                
                f.write(f"枚举定义总数: {enum_result['report_info']['total_enums']}\n")
                f.write(f"基于枚举的硬编码文本: {enum_based_total} 个\n")
                f.write(f"基于模式的硬编码文本: {pattern_based_total} 个\n")
            else:
                f.write(f"检测失败: {enum_result['error']}\n")
            
            f.write("\n")
            
            # 总体统计
            total_ui = sum(len(items) for items in ui_result['results'].values()) if ui_result['success'] else 0
            total_enum = (
                sum(len(enum_analysis['hardcoded_displays']) for enum_analysis in enum_result['results'].get('enum_based', [])) +
                sum(len(items) for items in enum_result['results'].get('pattern_based', {}).values())
            ) if enum_result['success'] else 0
            
            f.write("=== 总体统计 ===\n")
            f.write(f"UI文本硬编码: {total_ui} 个\n")
            f.write(f"枚举显示硬编码: {total_enum} 个\n")
            f.write(f"总计: {total_ui + total_enum} 个\n")
            
            f.write("\n=== 处理建议 ===\n")
            f.write("1. 优先处理UI文本硬编码，这些影响用户界面体验\n")
            f.write("2. 处理枚举显示名称，确保数据展示的一致性\n")
            f.write("3. 审核综合映射文件中的英文翻译\n")
            f.write("4. 将确认无误的条目标记为 approved: true\n")
            f.write("5. 运行应用工具执行替换\n")
        
        return summary_path
    
    def run_comprehensive_detection(self):
        """运行综合检测"""
        print("=== 综合硬编码文本检测器 ===")
        print("开始全面检测硬编码文本...")
        
        # 1. 运行UI文本检测
        ui_result = self.run_ui_detection()
        
        # 2. 运行枚举检测
        enum_result = self.run_enum_detection()
        
        # 3. 合并结果
        print("\n=== 合并检测结果 ===")
        merge_result = self.merge_detection_results(ui_result, enum_result)
        
        # 4. 生成综合汇总
        summary_path = self.generate_comprehensive_summary(ui_result, enum_result, merge_result)
        
        # 5. 输出结果
        print(f"\n=== 检测完成 ===")
        
        if ui_result['success']:
            ui_total = sum(len(items) for items in ui_result['results'].values())
            print(f"UI文本硬编码: {ui_total} 个")
        else:
            print(f"UI文本检测失败: {ui_result['error']}")
        
        if enum_result['success']:
            enum_total = (
                sum(len(enum_analysis['hardcoded_displays']) for enum_analysis in enum_result['results'].get('enum_based', [])) +
                sum(len(items) for items in enum_result['results'].get('pattern_based', {}).values())
            )
            print(f"枚举显示硬编码: {enum_total} 个")
        else:
            print(f"枚举检测失败: {enum_result['error']}")
        
        print(f"\n生成的文件:")
        print(f"  - 综合映射文件: {merge_result['mapping_file']}")
        print(f"  - 综合汇总报告: {summary_path}")
        
        if ui_result['success']:
            print(f"  - UI检测详细报告: {ui_result['report_info']['detail']}")
        
        if enum_result['success']:
            print(f"  - 枚举检测报告: {enum_result['report_info']['enum_analysis']}")
        
        print(f"\n下一步操作:")
        print(f"1. 查看综合映射文件: {merge_result['mapping_file']}")
        print("2. 审核并修改英文翻译")
        print("3. 将需要处理的条目的 approved 设置为 true")
        print("4. 运行 enhanced_arb_applier.py 执行替换")
        
        return {
            'ui_result': ui_result,
            'enum_result': enum_result,
            'mapping_file': merge_result['mapping_file'],
            'summary_file': summary_path
        }

def main():
    manager = ComprehensiveHardcodedManager()
    manager.run_comprehensive_detection()

if __name__ == "__main__":
    main()
