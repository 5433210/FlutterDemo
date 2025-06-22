#!/usr/bin/env python3
"""
最终高精度未使用文件分析工具
进一步提升准确性，减少误报
"""

import os
import re
import json
from pathlib import Path
from typing import Set, Dict, List, Optional, Tuple

class FinalPreciseAnalyzer:
    def __init__(self, project_root: str):
        self.project_root = Path(project_root).resolve()
        self.lib_dir = self.project_root / 'lib'
        
        # 数据存储
        self.all_files: Set[str] = set()
        self.imports: Dict[str, Set[str]] = {}
        self.exports: Dict[str, Set[str]] = {}  # 新增：跟踪export
        self.used_files: Set[str] = set()
        self.file_info: Dict[str, dict] = {}
        
        # 入口文件（严格识别）
        self.entry_files = [
            'lib/main.dart',
            'lib/app.dart',
            'lib/presentation/app.dart'
        ]
        
        # 重要的文件类型（保守标记为已使用）
        self.important_patterns = [
            r'provider.*\.dart$',
            r'.*_provider\.dart$',
            r'service.*\.dart$',
            r'.*_service\.dart$',
            r'repository.*\.dart$',
            r'.*_repository\.dart$',
            r'route.*\.dart$',
            r'.*_route.*\.dart$',
            r'navigation.*\.dart$',
            r'mixin.*\.dart$',
            r'extension.*\.dart$',
            r'config.*\.dart$',
            r'constants?\.dart$',
            r'theme.*\.dart$',
            r'style.*\.dart$'
        ]
        
        # 可能动态引用的文件模式
        self.dynamic_patterns = [
            r'.*_screen\.dart$',
            r'.*_page\.dart$',
            r'.*_dialog\.dart$',
            r'.*_widget\.dart$',
            r'.*model.*\.dart$',
            r'.*entity.*\.dart$'
        ]
    
    def scan_files(self):
        """扫描所有有效文件"""
        print("🔍 扫描Dart文件...")
        
        for dart_file in self.lib_dir.rglob('*.dart'):
            # 排除生成文件
            if dart_file.name.endswith(('.g.dart', '.freezed.dart')):
                continue
            
            rel_path = str(dart_file.relative_to(self.project_root)).replace('\\', '/')
            self.all_files.add(rel_path)
            
            stat = dart_file.stat()
            self.file_info[rel_path] = {
                'size': stat.st_size,
                'is_empty': stat.st_size < 50,
                'is_important': self._is_important_file(rel_path),
                'is_dynamic': self._is_dynamic_file(rel_path),
                'path_obj': dart_file
            }
        
        print(f"   发现 {len(self.all_files)} 个有效文件")
    
    def _is_important_file(self, file_path: str) -> bool:
        """检查是否为重要文件（通常被间接引用）"""
        file_lower = file_path.lower()
        return any(re.search(pattern, file_lower) for pattern in self.important_patterns)
    
    def _is_dynamic_file(self, file_path: str) -> bool:
        """检查是否可能被动态引用"""
        file_lower = file_path.lower()
        return any(re.search(pattern, file_lower) for pattern in self.dynamic_patterns)
    
    def analyze_dependencies(self):
        """分析文件依赖关系"""
        print("📚 分析文件依赖...")
        
        for rel_path in self.all_files:
            imports, exports = self._extract_dependencies(rel_path)
            self.imports[rel_path] = imports
            self.exports[rel_path] = exports
        
        total_imports = sum(len(imports) for imports in self.imports.values())
        total_exports = sum(len(exports) for exports in self.exports.values())
        print(f"   解析 {total_imports} 个导入，{total_exports} 个导出")
    
    def _extract_dependencies(self, rel_path: str) -> Tuple[Set[str], Set[str]]:
        """提取导入和导出依赖"""
        imports = set()
        exports = set()
        
        file_path = self.file_info[rel_path]['path_obj']
        
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                content = f.read()
        except Exception:
            return imports, exports
        
        # 清理注释
        content = self._clean_content(content)
        
        # 提取import
        import_pattern = r"import\s+['\"]([^'\"]+)['\"]"
        for match in re.findall(import_pattern, content):
            resolved = self._resolve_path(match, rel_path)
            if resolved:
                imports.add(resolved)
        
        # 提取export  
        export_pattern = r"export\s+['\"]([^'\"]+)['\"]"
        for match in re.findall(export_pattern, content):
            resolved = self._resolve_path(match, rel_path)
            if resolved:
                exports.add(resolved)
        
        # 提取part
        part_pattern = r"part\s+['\"]([^'\"]+)['\"]"
        for match in re.findall(part_pattern, content):
            resolved = self._resolve_path(match, rel_path)
            if resolved:
                imports.add(resolved)
        
        return imports, exports
    
    def _clean_content(self, content: str) -> str:
        """清理内容，移除注释和字符串字面量"""
        # 简化版清理
        lines = []
        in_multiline_comment = False
        
        for line in content.split('\n'):
            # 处理多行注释
            if '/*' in line and '*/' not in line:
                in_multiline_comment = True
                line = line[:line.find('/*')]
            elif '*/' in line and in_multiline_comment:
                in_multiline_comment = False
                line = line[line.find('*/') + 2:]
            elif in_multiline_comment:
                continue
            
            # 移除单行注释
            if '//' in line:
                line = line[:line.find('//')]
            
            lines.append(line)
        
        return '\n'.join(lines)
    
    def _resolve_path(self, import_str: str, current_file: str) -> Optional[str]:
        """解析导入路径"""
        # package:demo/ 导入
        if import_str.startswith('package:demo/'):
            target = import_str.replace('package:demo/', 'lib/')
            return target if target in self.all_files else None
        
        # 外部包导入（忽略）
        if import_str.startswith('package:') or import_str.startswith('dart:'):
            return None
        
        # 相对路径导入
        if import_str.startswith('.'):
            try:
                current_dir = Path(current_file).parent
                resolved_path = (current_dir / import_str).resolve()
                rel_target = str(resolved_path.relative_to(self.project_root)).replace('\\', '/')
                return rel_target if rel_target in self.all_files else None
            except:
                return None
        
        # 绝对路径（相对于lib）
        candidates = [
            f"lib/{import_str}",
            f"lib/{import_str}.dart"
        ]
        
        for candidate in candidates:
            if candidate in self.all_files:
                return candidate
        
        return None
    
    def mark_used_files(self):
        """标记被使用的文件"""
        print("🎯 标记使用的文件...")
        
        # 1. 标记入口文件
        entry_count = 0
        for entry in self.entry_files:
            if entry in self.all_files:
                self.used_files.add(entry)
                entry_count += 1
        print(f"   入口文件: {entry_count}个")
        
        # 2. 标记重要文件
        important_count = 0
        for file_path in self.all_files:
            if self.file_info[file_path]['is_important']:
                self.used_files.add(file_path)
                important_count += 1
        print(f"   重要文件: {important_count}个")
        
        # 3. 递归标记直接和间接依赖
        changed = True
        iteration = 0
        
        while changed and iteration < 50:
            changed = False
            iteration += 1
            old_count = len(self.used_files)
            
            for used_file in list(self.used_files):
                # 标记导入的文件
                for imported in self.imports.get(used_file, set()):
                    if imported not in self.used_files:
                        self.used_files.add(imported)
                        changed = True
                
                # 标记导出的文件
                for exported in self.exports.get(used_file, set()):
                    if exported not in self.used_files:
                        self.used_files.add(exported)
                        changed = True
            
            new_count = len(self.used_files)
            if new_count > old_count:
                print(f"     第{iteration}轮: +{new_count - old_count}个")
        
        lib_used = len([f for f in self.used_files if f.startswith('lib/')])
        print(f"   最终标记: {lib_used}个lib文件")
    
    def deep_validate_unused(self, unused_files: List[str]) -> Dict:
        """深度验证未使用文件"""
        print(f"🔬 深度验证 {len(unused_files)} 个未使用文件...")
        
        validation = {
            'total': len(unused_files),
            'confirmed_unused': 0,
            'likely_used': 0,
            'likely_used_files': []
        }
        
        for file_path in unused_files:
            is_likely_used = False
            reasons = []
            
            # 检查是否被字符串引用（动态导入）
            file_name = Path(file_path).stem
            base_name = file_name.lower()
            
            for check_file in self.all_files:
                if check_file == file_path:
                    continue
                
                try:
                    with open(self.file_info[check_file]['path_obj'], 'r', encoding='utf-8') as f:
                        content = f.read().lower()
                    
                    # 检查多种可能的引用方式
                    if (base_name in content or 
                        file_path.lower() in content or
                        f"'{file_path}'" in content.lower() or
                        f'"{file_path}"' in content.lower()):
                        is_likely_used = True
                        reasons.append(f"被{check_file}引用")
                        break
                        
                except:
                    continue
            
            # 检查文件名模式（可能被动态引用）
            if self.file_info[file_path]['is_dynamic']:
                is_likely_used = True
                reasons.append("可能被动态引用")
            
            if is_likely_used:
                validation['likely_used'] += 1
                validation['likely_used_files'].append({
                    'file': file_path,
                    'reasons': reasons
                })
            else:
                validation['confirmed_unused'] += 1
        
        return validation
    
    def classify_and_validate(self) -> Dict:
        """分类并验证未使用文件"""
        print("📊 分类和验证未使用文件...")
        
        categories = {
            'empty_files': [],
            'safe_delete': [],
            'needs_review': [],
            'likely_false_positive': []
        }
        
        lib_unused = [f for f in self.all_files if f.startswith('lib/') and f not in self.used_files]
        
        # 深度验证
        validation = self.deep_validate_unused(lib_unused)
        
        for file_path in lib_unused:
            info = self.file_info[file_path]
            
            file_data = {
                'path': file_path,
                'size_kb': info['size'] / 1024,
                'size_bytes': info['size']
            }
            
            # 检查是否在可能使用列表中
            is_likely_used = any(item['file'] == file_path for item in validation['likely_used_files'])
            
            if is_likely_used:
                categories['likely_false_positive'].append(file_data)
            elif info['is_empty']:
                categories['empty_files'].append(file_data)
            elif info['size'] < 1000:
                categories['safe_delete'].append(file_data)
            else:
                categories['needs_review'].append(file_data)
        
        return categories, validation
    
    def generate_final_report(self) -> str:
        """生成最终报告"""
        categories, validation = self.classify_and_validate()
        
        # 统计
        total_lib = len([f for f in self.all_files if f.startswith('lib/')])
        total_unused = sum(len(cat) for cat in categories.values())
        total_used = total_lib - total_unused
        
        # 计算实际未使用（排除误报）
        actual_unused = total_unused - len(categories['likely_false_positive'])
        
        lines = []
        lines.append("=" * 80)
        lines.append("📊 最终高精度未使用文件分析报告")
        lines.append("=" * 80)
        lines.append("")
        
        # 总体统计
        lines.append("📈 精确统计:")
        lines.append(f"   lib文件总数: {total_lib}")
        lines.append(f"   已使用文件: {total_used} ({total_used/total_lib*100:.1f}%)")
        lines.append(f"   报告未使用: {total_unused} ({total_unused/total_lib*100:.1f}%)")
        lines.append(f"   可能误报: {len(categories['likely_false_positive'])}")
        lines.append(f"   实际未使用: {actual_unused} ({actual_unused/total_lib*100:.1f}%)")
        lines.append("")
        
        # 验证结果
        if validation['total'] > 0:
            accuracy = validation['confirmed_unused'] / validation['total'] * 100
            lines.append("🔬 深度验证结果:")
            lines.append(f"   总验证文件: {validation['total']}")
            lines.append(f"   确认未使用: {validation['confirmed_unused']}")
            lines.append(f"   可能使用: {validation['likely_used']}")
            lines.append(f"   预估准确率: {accuracy:.1f}%")
            lines.append("")
        
        # 分类统计
        lines.append("📂 精确分类:")
        for category, files in categories.items():
            if files:
                total_size = sum(f['size_kb'] for f in files)
                lines.append(f"   {self._get_category_name(category)}: {len(files)}个 ({total_size:.1f}KB)")
        lines.append("")
        
        # 操作建议
        lines.append("🎯 精确建议:")
        if categories['empty_files']:
            lines.append(f"   ✅ 安全删除空文件: {len(categories['empty_files'])}个")
        if categories['safe_delete']:
            lines.append(f"   ⚠️  谨慎删除小文件: {len(categories['safe_delete'])}个")
        if categories['needs_review']:
            lines.append(f"   🔍 人工审查大文件: {len(categories['needs_review'])}个")
        if categories['likely_false_positive']:
            lines.append(f"   ❌ 忽略可能误报: {len(categories['likely_false_positive'])}个")
        lines.append("")
        
        # 空文件详情（可以立即删除）
        if categories['empty_files']:
            lines.append("🗑️  可立即删除的空文件:")
            for file_data in categories['empty_files']:
                lines.append(f"   - {file_data['path']}")
            lines.append("")
        
        return "\n".join(lines)
    
    def _get_category_name(self, category: str) -> str:
        """分类名称"""
        names = {
            'empty_files': '空文件',
            'safe_delete': '安全删除',
            'needs_review': '需要审查',
            'likely_false_positive': '可能误报'
        }
        return names.get(category, category)
    
    def run_final_analysis(self):
        """运行最终分析"""
        print("🚀 启动最终高精度分析")
        print(f"📁 项目: {self.project_root}")
        print()
        
        self.scan_files()
        self.analyze_dependencies()
        self.mark_used_files()
        
        report = self.generate_final_report()
        print(report)
        
        # 保存报告
        report_file = self.project_root / 'tools' / 'reports' / 'final_precise_analysis.txt'
        report_file.parent.mkdir(parents=True, exist_ok=True)
        
        with open(report_file, 'w', encoding='utf-8') as f:
            f.write(report)
        
        print(f"📄 最终报告: {report_file}")

def main():
    analyzer = FinalPreciseAnalyzer(os.getcwd())
    analyzer.run_final_analysis()

if __name__ == "__main__":
    main() 