#!/usr/bin/env python3
"""
改进版未使用文件分析工具
主要改进：
1. 更精确的导入路径解析
2. 特殊文件识别（providers、services等）
3. 交叉验证减少误报
4. 按风险等级分类
"""

import os
import re
import json
from pathlib import Path
from typing import Set, Dict, List, Optional

class ImprovedAnalyzer:
    def __init__(self, project_root: str):
        self.project_root = Path(project_root).resolve()
        self.lib_dir = self.project_root / 'lib'
        
        # 数据存储
        self.all_files: Set[str] = set()
        self.import_map: Dict[str, Set[str]] = {}
        self.used_files: Set[str] = set()
        self.file_info: Dict[str, dict] = {}
        
        # 入口文件
        self.entry_files = [
            'lib/main.dart',
            'lib/app.dart', 
            'lib/presentation/app.dart',
            'lib/providers.dart',
            'lib/routes/app_routes.dart'
        ]
        
        # 特殊文件模式（通常被动态引用）
        self.special_patterns = [
            r'provider.*\.dart$',
            r'service.*\.dart$', 
            r'repository.*\.dart$',
            r'route.*\.dart$',
            r'navigation.*\.dart$',
            r'mixin.*\.dart$',
            r'extension.*\.dart$'
        ]
    
    def scan_files(self):
        """扫描所有有效的Dart文件"""
        print("🔍 扫描Dart文件...")
        
        for dart_file in self.lib_dir.rglob('*.dart'):
            # 排除生成的文件
            if dart_file.name.endswith('.g.dart') or dart_file.name.endswith('.freezed.dart'):
                continue
                
            rel_path = str(dart_file.relative_to(self.project_root)).replace('\\', '/')
            self.all_files.add(rel_path)
            
            # 收集文件信息
            stat = dart_file.stat()
            self.file_info[rel_path] = {
                'size': stat.st_size,
                'is_empty': stat.st_size < 50,
                'is_special': self._is_special_file(rel_path),
                'path_obj': dart_file
            }
        
        print(f"   发现 {len(self.all_files)} 个有效文件")
    
    def _is_special_file(self, file_path: str) -> bool:
        """检查是否为特殊文件"""
        file_lower = file_path.lower()
        return any(re.search(pattern, file_lower) for pattern in self.special_patterns)
    
    def analyze_imports(self):
        """分析导入关系"""
        print("📚 分析导入关系...")
        
        for rel_path in self.all_files:
            imports = self._extract_imports(rel_path)
            self.import_map[rel_path] = imports
        
        total_imports = sum(len(imports) for imports in self.import_map.values())
        print(f"   解析了 {total_imports} 个导入关系")
    
    def _extract_imports(self, rel_path: str) -> Set[str]:
        """提取文件的导入"""
        imports = set()
        file_path = self.file_info[rel_path]['path_obj']
        
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                content = f.read()
        except Exception:
            return imports
        
        # 清理内容，移除注释
        content = self._clean_content(content)
        
        # 提取import语句
        import_patterns = [
            r"import\s+['\"]([^'\"]+)['\"]",
            r"export\s+['\"]([^'\"]+)['\"]", 
            r"part\s+['\"]([^'\"]+)['\"]"
        ]
        
        for pattern in import_patterns:
            matches = re.findall(pattern, content)
            for match in matches:
                resolved = self._resolve_import(match, rel_path)
                if resolved:
                    imports.add(resolved)
        
        return imports
    
    def _clean_content(self, content: str) -> str:
        """清理内容，移除注释和字符串"""
        lines = []
        for line in content.split('\n'):
            # 移除单行注释
            if '//' in line:
                line = line[:line.find('//')]
            lines.append(line)
        return '\n'.join(lines)
    
    def _resolve_import(self, import_str: str, current_file: str) -> Optional[str]:
        """解析导入路径"""
        # package:demo/ 导入
        if import_str.startswith('package:demo/'):
            target = import_str.replace('package:demo/', 'lib/')
            return target if target in self.all_files else None
        
        # 忽略外部包和dart:
        if import_str.startswith('package:') or import_str.startswith('dart:'):
            return None
        
        # 相对路径导入
        if import_str.startswith('.'):
            try:
                current_dir = Path(current_file).parent
                target_path = (current_dir / import_str).resolve()
                rel_target = str(target_path.relative_to(self.project_root)).replace('\\', '/')
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
        for entry in self.entry_files:
            if entry in self.all_files:
                self.used_files.add(entry)
        
        # 2. 标记特殊文件（providers、services等）
        for file_path in self.all_files:
            if self.file_info[file_path]['is_special']:
                self.used_files.add(file_path)
        
        # 3. 递归标记被导入的文件
        changed = True
        iteration = 0
        
        while changed and iteration < 50:
            changed = False
            iteration += 1
            old_count = len(self.used_files)
            
            for used_file in list(self.used_files):
                for imported in self.import_map.get(used_file, set()):
                    if imported not in self.used_files:
                        self.used_files.add(imported)
                        changed = True
            
            new_count = len(self.used_files)
            if new_count > old_count:
                print(f"     第{iteration}轮: +{new_count - old_count}个文件")
        
        lib_used = len([f for f in self.used_files if f.startswith('lib/')])
        print(f"   最终标记 {lib_used} 个lib文件为已使用")
    
    def classify_unused_files(self) -> Dict[str, List[dict]]:
        """分类未使用的文件"""
        categories = {
            'empty_files': [],      # 空文件
            'safe_delete': [],      # 安全删除
            'need_review': [],      # 需要审查
            'special_files': []     # 特殊文件
        }
        
        for file_path in self.all_files:
            if file_path.startswith('lib/') and file_path not in self.used_files:
                info = self.file_info[file_path]
                
                file_data = {
                    'path': file_path,
                    'size_kb': info['size'] / 1024,
                    'size_bytes': info['size']
                }
                
                if info['is_empty']:
                    categories['empty_files'].append(file_data)
                elif info['is_special']:
                    categories['special_files'].append(file_data)
                elif info['size'] < 1000:
                    categories['safe_delete'].append(file_data)
                else:
                    categories['need_review'].append(file_data)
        
        return categories
    
    def cross_validate(self, unused_files: List[str], sample_size: int = 25) -> dict:
        """交叉验证未使用文件"""
        print(f"🔬 交叉验证{sample_size}个文件...")
        
        validation = {
            'total_checked': 0,
            'confirmed_unused': 0,
            'false_positives': 0,
            'false_positive_files': []
        }
        
        sample = unused_files[:sample_size]
        
        for file_path in sample:
            validation['total_checked'] += 1
            
            # 搜索文件引用
            is_referenced = False
            file_name = Path(file_path).stem
            
            for check_path in self.all_files:
                if check_path == file_path:
                    continue
                
                try:
                    with open(self.file_info[check_path]['path_obj'], 'r', encoding='utf-8') as f:
                        content = f.read()
                    
                    if (file_path in content or 
                        file_name in content or
                        f"'{file_path}'" in content):
                        is_referenced = True
                        validation['false_positive_files'].append(file_path)
                        break
                        
                except:
                    continue
            
            if is_referenced:
                validation['false_positives'] += 1
            else:
                validation['confirmed_unused'] += 1
        
        return validation
    
    def generate_report(self) -> str:
        """生成分析报告"""
        categories = self.classify_unused_files()
        
        # 获取所有未使用文件用于验证
        all_unused = []
        for cat_files in categories.values():
            all_unused.extend([f['path'] for f in cat_files])
        
        validation = self.cross_validate(all_unused)
        
        # 统计
        total_lib = len([f for f in self.all_files if f.startswith('lib/')])
        total_unused = len(all_unused)
        total_used = total_lib - total_unused
        
        # 生成报告
        lines = []
        lines.append("=" * 70)
        lines.append("📊 改进版未使用文件分析报告")
        lines.append("=" * 70)
        lines.append("")
        
        # 总体统计
        lines.append("📈 总体统计:")
        lines.append(f"   lib文件总数: {total_lib}")
        lines.append(f"   已使用文件: {total_used} ({total_used/total_lib*100:.1f}%)")
        lines.append(f"   未使用文件: {total_unused} ({total_unused/total_lib*100:.1f}%)")
        lines.append("")
        
        # 验证结果
        if validation['total_checked'] > 0:
            accuracy = validation['confirmed_unused'] / validation['total_checked'] * 100
            lines.append("🔬 交叉验证结果:")
            lines.append(f"   验证样本: {validation['total_checked']}个")
            lines.append(f"   确认未使用: {validation['confirmed_unused']}个")
            lines.append(f"   误报: {validation['false_positives']}个")
            lines.append(f"   准确率估计: {accuracy:.1f}%")
            lines.append("")
        
        # 分类统计
        lines.append("📂 文件分类:")
        for category, files in categories.items():
            if files:
                total_size = sum(f['size_kb'] for f in files)
                lines.append(f"   {self._category_name(category)}: {len(files)}个 ({total_size:.1f}KB)")
        lines.append("")
        
        # 删除建议
        lines.append("🎯 建议操作:")
        if categories['empty_files']:
            lines.append(f"   ✅ 立即删除空文件: {len(categories['empty_files'])}个")
        if categories['safe_delete']:
            lines.append(f"   ⚠️  谨慎删除小文件: {len(categories['safe_delete'])}个")
        if categories['need_review']:
            lines.append(f"   🔍 人工审查大文件: {len(categories['need_review'])}个")
        if categories['special_files']:
            lines.append(f"   ❌ 特殊文件需确认: {len(categories['special_files'])}个")
        lines.append("")
        
        # 详细列表（显示前5个）
        for category, files in categories.items():
            if files:
                lines.append(f"📋 {self._category_name(category)} (前5个):")
                for file_data in files[:5]:
                    lines.append(f"   - {file_data['path']} ({file_data['size_kb']:.1f}KB)")
                if len(files) > 5:
                    lines.append(f"   ... 还有{len(files)-5}个")
                lines.append("")
        
        return "\n".join(lines)
    
    def _category_name(self, category: str) -> str:
        """分类名称翻译"""
        names = {
            'empty_files': '空文件',
            'safe_delete': '安全删除',
            'need_review': '需要审查',
            'special_files': '特殊文件'
        }
        return names.get(category, category)
    
    def run_analysis(self):
        """执行完整分析"""
        print("🚀 启动改进版未使用文件分析")
        print(f"📁 项目: {self.project_root}")
        print()
        
        self.scan_files()
        self.analyze_imports()
        self.mark_used_files()
        
        report = self.generate_report()
        print(report)
        
        # 保存报告
        report_file = self.project_root / 'tools' / 'reports' / 'improved_analysis.txt'
        report_file.parent.mkdir(parents=True, exist_ok=True)
        
        with open(report_file, 'w', encoding='utf-8') as f:
            f.write(report)
        
        print(f"📄 报告已保存: {report_file}")

def main():
    analyzer = ImprovedAnalyzer(os.getcwd())
    analyzer.run_analysis()

if __name__ == "__main__":
    main() 