#!/usr/bin/env python3
"""
最终高精度分析工具
"""
import os
import re
from pathlib import Path
from typing import Set, Dict, List

class FinalAnalyzer:
    def __init__(self, project_root: str):
        self.project_root = Path(project_root).resolve()
        self.lib_dir = self.project_root / 'lib'
        
        self.all_files: Set[str] = set()
        self.imports: Dict[str, Set[str]] = {}
        self.used_files: Set[str] = set()
        self.file_info: Dict[str, dict] = {}
        
        # 重要文件模式（保守标记）
        self.important_patterns = [
            r'provider.*\.dart$', r'.*_provider\.dart$',
            r'service.*\.dart$', r'.*_service\.dart$', 
            r'repository.*\.dart$', r'.*_repository\.dart$',
            r'route.*\.dart$', r'navigation.*\.dart$',
            r'mixin.*\.dart$', r'extension.*\.dart$',
            r'config.*\.dart$', r'constants?\.dart$'
        ]
    
    def scan_files(self):
        print("🔍 扫描文件...")
        for dart_file in self.lib_dir.rglob('*.dart'):
            if dart_file.name.endswith(('.g.dart', '.freezed.dart')):
                continue
            
            rel_path = str(dart_file.relative_to(self.project_root)).replace('\\', '/')
            self.all_files.add(rel_path)
            
            stat = dart_file.stat()
            self.file_info[rel_path] = {
                'size': stat.st_size,
                'is_empty': stat.st_size < 50,
                'is_important': self._is_important(rel_path),
                'path_obj': dart_file
            }
        
        print(f"   发现 {len(self.all_files)} 个文件")
    
    def _is_important(self, file_path: str) -> bool:
        file_lower = file_path.lower()
        return any(re.search(pattern, file_lower) for pattern in self.important_patterns)
    
    def analyze_imports(self):
        print("📚 分析导入...")
        for rel_path in self.all_files:
            self.imports[rel_path] = self._extract_imports(rel_path)
        
        total = sum(len(imports) for imports in self.imports.values())
        print(f"   解析 {total} 个导入")
    
    def _extract_imports(self, rel_path: str) -> Set[str]:
        imports = set()
        try:
            with open(self.file_info[rel_path]['path_obj'], 'r', encoding='utf-8') as f:
                content = f.read()
        except:
            return imports
        
        patterns = [
            r"import\s+['\"]([^'\"]+)['\"]",
            r"export\s+['\"]([^'\"]+)['\"]"
        ]
        
        for pattern in patterns:
            for match in re.findall(pattern, content):
                resolved = self._resolve_import(match, rel_path)
                if resolved:
                    imports.add(resolved)
        
        return imports
    
    def _resolve_import(self, import_str: str, current_file: str):
        if import_str.startswith('package:demo/'):
            target = import_str.replace('package:demo/', 'lib/')
            return target if target in self.all_files else None
        elif import_str.startswith(('package:', 'dart:')):
            return None
        elif import_str.startswith('.'):
            try:
                current_dir = Path(current_file).parent
                target_path = (current_dir / import_str).resolve()
                rel_target = str(target_path.relative_to(self.project_root)).replace('\\', '/')
                return rel_target if rel_target in self.all_files else None
            except:
                return None
        else:
            # 绝对路径
            candidates = [f"lib/{import_str}", f"lib/{import_str}.dart"]
            for candidate in candidates:
                if candidate in self.all_files:
                    return candidate
        return None
    
    def mark_used_files(self):
        print("🎯 标记使用文件...")
        
        # 入口文件
        entries = ['lib/main.dart', 'lib/app.dart', 'lib/presentation/app.dart']
        for entry in entries:
            if entry in self.all_files:
                self.used_files.add(entry)
        
        # 重要文件
        for file_path in self.all_files:
            if self.file_info[file_path]['is_important']:
                self.used_files.add(file_path)
        
        # 递归标记
        changed = True
        iteration = 0
        while changed and iteration < 50:
            changed = False
            iteration += 1
            old_count = len(self.used_files)
            
            for used_file in list(self.used_files):
                for imported in self.imports.get(used_file, set()):
                    if imported not in self.used_files:
                        self.used_files.add(imported)
                        changed = True
            
            if len(self.used_files) > old_count:
                print(f"     第{iteration}轮: +{len(self.used_files) - old_count}")
        
        lib_used = len([f for f in self.used_files if f.startswith('lib/')])
        print(f"   标记 {lib_used} 个使用文件")
    
    def validate_unused(self, unused_files: List[str]) -> dict:
        print(f"🔬 验证 {len(unused_files)} 个文件...")
        
        result = {'confirmed': 0, 'likely_used': 0, 'likely_used_files': []}
        
        for file_path in unused_files:
            is_referenced = False
            file_name = Path(file_path).stem.lower()
            
            for check_file in self.all_files:
                if check_file == file_path:
                    continue
                
                try:
                    with open(self.file_info[check_file]['path_obj'], 'r', encoding='utf-8') as f:
                        content = f.read().lower()
                    
                    if (file_name in content or 
                        file_path.lower() in content):
                        is_referenced = True
                        result['likely_used_files'].append(file_path)
                        break
                except:
                    continue
            
            if is_referenced:
                result['likely_used'] += 1
            else:
                result['confirmed'] += 1
        
        return result
    
    def generate_report(self):
        lib_files = [f for f in self.all_files if f.startswith('lib/')]
        unused_files = [f for f in lib_files if f not in self.used_files]
        
        validation = self.validate_unused(unused_files)
        
        # 分类
        empty_files = []
        safe_delete = []
        need_review = []
        likely_false_positive = validation['likely_used_files']
        
        for file_path in unused_files:
            if file_path in likely_false_positive:
                continue
            
            info = self.file_info[file_path]
            file_data = {'path': file_path, 'size_kb': info['size'] / 1024}
            
            if info['is_empty']:
                empty_files.append(file_data)
            elif info['size'] < 1000:
                safe_delete.append(file_data)
            else:
                need_review.append(file_data)
        
        # 生成报告
        total_lib = len(lib_files)
        total_unused = len(unused_files)
        total_used = total_lib - total_unused
        actual_unused = total_unused - len(likely_false_positive)
        
        lines = []
        lines.append("=" * 70)
        lines.append("📊 最终精确分析报告")
        lines.append("=" * 70)
        lines.append("")
        
        lines.append("📈 统计结果:")
        lines.append(f"   lib文件总数: {total_lib}")
        lines.append(f"   已使用文件: {total_used} ({total_used/total_lib*100:.1f}%)")
        lines.append(f"   报告未使用: {total_unused}")
        lines.append(f"   可能误报: {len(likely_false_positive)}")
        lines.append(f"   实际未使用: {actual_unused} ({actual_unused/total_lib*100:.1f}%)")
        lines.append("")
        
        if validation:
            accuracy = validation['confirmed'] / len(unused_files) * 100
            lines.append("🔬 验证结果:")
            lines.append(f"   确认未使用: {validation['confirmed']}")
            lines.append(f"   可能使用: {validation['likely_used']}")
            lines.append(f"   准确率: {accuracy:.1f}%")
            lines.append("")
        
        lines.append("📂 分类结果:")
        lines.append(f"   空文件: {len(empty_files)}个")
        lines.append(f"   安全删除: {len(safe_delete)}个")
        lines.append(f"   需要审查: {len(need_review)}个")
        lines.append(f"   可能误报: {len(likely_false_positive)}个")
        lines.append("")
        
        lines.append("🎯 操作建议:")
        if empty_files:
            lines.append(f"   ✅ 立即删除空文件: {len(empty_files)}个")
        if safe_delete:
            lines.append(f"   ⚠️  谨慎删除小文件: {len(safe_delete)}个")
        if need_review:
            lines.append(f"   🔍 人工审查: {len(need_review)}个")
        lines.append("")
        
        if empty_files:
            lines.append("🗑️  空文件列表:")
            for file_data in empty_files:
                lines.append(f"   - {file_data['path']}")
            lines.append("")
        
        return "\n".join(lines)
    
    def run(self):
        print("🚀 启动最终精确分析")
        print()
        
        self.scan_files()
        self.analyze_imports()
        self.mark_used_files()
        
        report = self.generate_report()
        print(report)
        
        # 保存报告
        report_file = self.project_root / 'tools' / 'reports' / 'final_analysis.txt'
        report_file.parent.mkdir(parents=True, exist_ok=True)
        
        with open(report_file, 'w', encoding='utf-8') as f:
            f.write(report)
        
        print(f"📄 报告已保存: {report_file}")

def main():
    analyzer = FinalAnalyzer(os.getcwd())
    analyzer.run()

if __name__ == "__main__":
    main() 