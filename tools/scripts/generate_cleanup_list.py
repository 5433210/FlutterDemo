#!/usr/bin/env python3
"""
生成完整的待清理文件清单
分类显示79个需要人工处理的文件
"""

import os
import re
from pathlib import Path
from typing import Set, Dict, List

class CleanupListGenerator:
    def __init__(self, project_root: str):
        self.project_root = Path(project_root).resolve()
        self.lib_dir = self.project_root / 'lib'
        
        self.all_files: Set[str] = set()
        self.imports: Dict[str, Set[str]] = {}
        self.used_files: Set[str] = set()
        self.file_info: Dict[str, dict] = {}
        
        # 重要文件模式
        self.important_patterns = [
            r'provider.*\.dart$', r'.*_provider\.dart$',
            r'service.*\.dart$', r'.*_service\.dart$', 
            r'repository.*\.dart$', r'.*_repository\.dart$',
            r'route.*\.dart$', r'navigation.*\.dart$',
            r'mixin.*\.dart$', r'extension.*\.dart$',
            r'config.*\.dart$', r'constants?\.dart$'
        ]
    
    def scan_and_analyze(self):
        """扫描并分析文件"""
        print("🔍 扫描和分析文件...")
        
        # 扫描文件
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
        
        # 分析导入
        for rel_path in self.all_files:
            self.imports[rel_path] = self._extract_imports(rel_path)
        
        # 标记使用的文件
        self._mark_used_files()
    
    def _is_important(self, file_path: str) -> bool:
        file_lower = file_path.lower()
        return any(re.search(pattern, file_lower) for pattern in self.important_patterns)
    
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
            candidates = [f"lib/{import_str}", f"lib/{import_str}.dart"]
            for candidate in candidates:
                if candidate in self.all_files:
                    return candidate
        return None
    
    def _mark_used_files(self):
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
            
            if len(self.used_files) <= old_count:
                break
    
    def validate_and_classify(self):
        """验证并分类未使用文件"""
        lib_files = [f for f in self.all_files if f.startswith('lib/')]
        unused_files = [f for f in lib_files if f not in self.used_files]
        
        # 验证哪些可能被使用
        likely_used_files = []
        for file_path in unused_files:
            file_name = Path(file_path).stem.lower()
            
            for check_file in self.all_files:
                if check_file == file_path:
                    continue
                
                try:
                    with open(self.file_info[check_file]['path_obj'], 'r', encoding='utf-8') as f:
                        content = f.read().lower()
                    
                    if (file_name in content or file_path.lower() in content):
                        likely_used_files.append(file_path)
                        break
                except:
                    continue
        
        # 分类
        empty_files = []
        small_files = []
        large_files = []
        
        for file_path in unused_files:
            if file_path in likely_used_files:
                continue  # 跳过可能误报的文件
            
            info = self.file_info[file_path]
            file_data = {
                'path': file_path,
                'size_kb': info['size'] / 1024,
                'size_bytes': info['size']
            }
            
            if info['is_empty']:
                empty_files.append(file_data)
            elif info['size'] < 1000:
                small_files.append(file_data)
            else:
                large_files.append(file_data)
        
        return empty_files, small_files, large_files
    
    def generate_cleanup_list(self):
        """生成完整的清理清单"""
        empty_files, small_files, large_files = self.validate_and_classify()
        
        total_files = len(empty_files) + len(small_files) + len(large_files)
        
        print("=" * 80)
        print("🗑️  完整文件清理清单")
        print("=" * 80)
        print(f"📊 总计需要处理: {total_files} 个文件")
        print()
        
        # 1. 空文件 (立即删除)
        if empty_files:
            print("✅ 第一类：空文件 (立即删除)")
            print(f"   数量: {len(empty_files)} 个文件 (总大小: 0KB)")
            print("   风险: 无风险 - 这些文件为空或几乎为空")
            print()
            for i, file_data in enumerate(empty_files, 1):
                print(f"   {i:2d}. {file_data['path']} ({file_data['size_bytes']} bytes)")
            print()
        
        # 2. 小文件 (谨慎删除)
        if small_files:
            total_size = sum(f['size_kb'] for f in small_files)
            print("⚠️  第二类：小文件 (谨慎删除)")
            print(f"   数量: {len(small_files)} 个文件 (总大小: {total_size:.1f}KB)")
            print("   风险: 低风险 - 建议快速审查后删除")
            print()
            for i, file_data in enumerate(small_files, 1):
                print(f"   {i:2d}. {file_data['path']} ({file_data['size_kb']:.1f}KB)")
            print()
        
        # 3. 大文件 (人工审查)
        if large_files:
            total_size = sum(f['size_kb'] for f in large_files)
            print("🔍 第三类：大文件 (人工审查)")
            print(f"   数量: {len(large_files)} 个文件 (总大小: {total_size:.1f}KB)")
            print("   风险: 中等风险 - 需要仔细审查确认")
            print()
            for i, file_data in enumerate(large_files, 1):
                print(f"   {i:2d}. {file_data['path']} ({file_data['size_kb']:.1f}KB)")
            print()
        
        # 生成删除命令
        print("🚀 删除命令生成:")
        print()
        
        if empty_files:
            print("✅ 空文件删除命令 (可直接执行):")
            for file_data in empty_files:
                print(f'   rm "{file_data["path"]}"')
            print()
        
        if small_files:
            print("⚠️  小文件删除命令 (审查后执行):")
            for file_data in small_files:
                print(f'   # rm "{file_data["path"]}"  # {file_data["size_kb"]:.1f}KB')
            print()
        
        print("💡 建议操作顺序:")
        print("   1. 立即删除空文件 (无风险)")
        print("   2. 逐个审查小文件并删除")
        print("   3. 仔细审查大文件，确认后删除")
        print("   4. 删除后运行测试确保应用正常")
        
        # 保存到文件
        self._save_cleanup_script(empty_files, small_files, large_files)
    
    def _save_cleanup_script(self, empty_files, small_files, large_files):
        """生成删除脚本"""
        script_path = self.project_root / 'tools' / 'scripts' / 'cleanup_files.bat'
        
        with open(script_path, 'w', encoding='utf-8') as f:
            f.write("@echo off\n")
            f.write("REM 文件清理脚本\n")
            f.write("REM 生成时间: " + str(Path().resolve()) + "\n\n")
            
            f.write("echo 开始清理未使用的文件...\n\n")
            
            if empty_files:
                f.write("REM ===== 空文件删除 (安全) =====\n")
                for file_data in empty_files:
                    f.write(f'del "{file_data["path"]}"\n')
                f.write("echo 空文件删除完成\n\n")
            
            if small_files:
                f.write("REM ===== 小文件删除 (需确认) =====\n")
                for file_data in small_files:
                    f.write(f'REM del "{file_data["path"]}"  REM {file_data["size_kb"]:.1f}KB\n')
                f.write("echo 小文件需要手动确认删除\n\n")
            
            f.write("echo 文件清理脚本生成完成\n")
            f.write("pause\n")
        
        print(f"📄 删除脚本已生成: {script_path}")

def main():
    generator = CleanupListGenerator(os.getcwd())
    generator.scan_and_analyze()
    generator.generate_cleanup_list()

if __name__ == "__main__":
    main() 