#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
未使用代码文件检测器
检测Flutter项目中没有被引用的.dart文件
"""

import os
import re
import sys
from pathlib import Path
from typing import Set, Dict, List, Tuple
import json

class UnusedCodeDetector:
    def __init__(self, project_root: str):
        self.project_root = Path(project_root)
        self.lib_dir = self.project_root / "lib"
        self.test_dir = self.project_root / "test"
        
        # 存储所有文件路径和导入关系
        self.all_dart_files: Set[Path] = set()
        self.import_relationships: Dict[Path, Set[Path]] = {}
        self.used_files: Set[Path] = set()
        
        # 排除的文件模式
        self.exclude_patterns = [
            r'.*\.g\.dart$',  # 生成的文件
            r'.*\.freezed\.dart$',  # Freezed生成的文件
            r'.*\.config\.dart$',  # 配置文件
            r'.*/gen_l10n/.*',  # 国际化生成文件
        ]
        
        # 入口文件
        self.entry_files = [
            'main.dart',
            'providers.dart',
            'constants.dart',
        ]

    def find_all_dart_files(self) -> None:
        """找到所有.dart文件"""
        print("🔍 扫描所有Dart文件...")
        
        # 扫描lib目录
        if self.lib_dir.exists():
            for dart_file in self.lib_dir.rglob("*.dart"):
                if not self._should_exclude(dart_file):
                    self.all_dart_files.add(dart_file)
        
        # 扫描test目录
        if self.test_dir.exists():
            for dart_file in self.test_dir.rglob("*.dart"):
                if not self._should_exclude(dart_file):
                    self.all_dart_files.add(dart_file)
        
        print(f"   找到 {len(self.all_dart_files)} 个Dart文件")

    def _should_exclude(self, file_path: Path) -> bool:
        """检查文件是否应该被排除"""
        file_str = str(file_path)
        for pattern in self.exclude_patterns:
            if re.match(pattern, file_str):
                return True
        return False

    def analyze_imports(self) -> None:
        """分析所有文件的导入关系"""
        print("📚 分析导入关系...")
        
        for dart_file in self.all_dart_files:
            try:
                imports = self._extract_imports(dart_file)
                self.import_relationships[dart_file] = imports
            except Exception as e:
                print(f"   ⚠️  分析文件失败: {dart_file} - {e}")
        
        print(f"   分析了 {len(self.import_relationships)} 个文件的导入关系")

    def _extract_imports(self, file_path: Path) -> Set[Path]:
        """提取文件中的导入关系"""
        imports = set()
        
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                content = f.read()
        except Exception:
            return imports
        
        # 匹配import语句
        import_patterns = [
            r"import\s+['\"]([^'\"]+\.dart)['\"]",  # 普通import
            r"export\s+['\"]([^'\"]+\.dart)['\"]",  # export语句
            r"part\s+['\"]([^'\"]+\.dart)['\"]",    # part语句
        ]
        
        for pattern in import_patterns:
            matches = re.findall(pattern, content)
            for match in matches:
                # 解析导入路径
                imported_file = self._resolve_import_path(file_path, match)
                if imported_file and imported_file.exists():
                    imports.add(imported_file)
        
        return imports

    def _resolve_import_path(self, from_file: Path, import_path: str) -> Path:
        """解析导入路径为绝对路径"""
        if import_path.startswith('package:'):
            # package:imports - 跳过外部包
            if not import_path.startswith('package:demo/'):
                return None
            # 处理本项目的package import
            relative_path = import_path.replace('package:demo/', '')
            return self.lib_dir / relative_path
        
        # 相对路径
        if import_path.startswith('./') or import_path.startswith('../'):
            base_dir = from_file.parent
            return (base_dir / import_path).resolve()
        
        # 绝对路径（相对于lib目录）
        return self.lib_dir / import_path

    def mark_used_files(self) -> None:
        """从入口文件开始标记被使用的文件"""
        print("🎯 标记被使用的文件...")
        
        # 标记入口文件
        for entry_name in self.entry_files:
            entry_file = self.lib_dir / entry_name
            if entry_file.exists():
                self._mark_file_and_dependencies(entry_file)
        
        # 标记所有测试文件（测试文件本身都被认为是被使用的）
        for dart_file in self.all_dart_files:
            if str(dart_file).find('/test/') != -1 or str(dart_file).find('\\test\\') != -1:
                self._mark_file_and_dependencies(dart_file)
        
        print(f"   标记了 {len(self.used_files)} 个文件为已使用")

    def _mark_file_and_dependencies(self, file_path: Path) -> None:
        """递归标记文件及其依赖为已使用"""
        if file_path in self.used_files:
            return
        
        self.used_files.add(file_path)
        
        # 递归标记依赖
        if file_path in self.import_relationships:
            for imported_file in self.import_relationships[file_path]:
                self._mark_file_and_dependencies(imported_file)

    def find_unused_files(self) -> List[Path]:
        """找到未使用的文件"""
        unused_files = []
        
        for dart_file in self.all_dart_files:
            if dart_file not in self.used_files:
                # 额外检查：可能是通过字符串引用的文件
                if not self._is_referenced_by_string(dart_file):
                    unused_files.append(dart_file)
        
        return sorted(unused_files)

    def _is_referenced_by_string(self, file_path: Path) -> bool:
        """检查文件是否通过字符串引用（如路由、反射等）"""
        filename = file_path.stem  # 不带扩展名的文件名
        relative_path = file_path.relative_to(self.project_root)
        
        # 搜索可能的字符串引用
        search_patterns = [
            filename,
            str(relative_path).replace('\\', '/'),
            str(relative_path.with_suffix('')).replace('\\', '/'),
        ]
        
        for dart_file in self.all_dart_files:
            if dart_file == file_path:
                continue
                
            try:
                with open(dart_file, 'r', encoding='utf-8') as f:
                    content = f.read()
                    
                for pattern in search_patterns:
                    if pattern in content:
                        return True
            except Exception:
                continue
        
        return False

    def generate_report(self, unused_files: List[Path]) -> Dict:
        """生成详细报告"""
        report = {
            'summary': {
                'total_dart_files': len(self.all_dart_files),
                'used_files': len(self.used_files),
                'unused_files': len(unused_files),
                'usage_rate': f"{(len(self.used_files) / len(self.all_dart_files) * 100):.1f}%"
            },
            'unused_files': [],
            'categories': {
                'presentation': [],
                'domain': [],
                'infrastructure': [],
                'application': [],
                'utils': [],
                'widgets': [],
                'other': []
            }
        }
        
        for file_path in unused_files:
            relative_path = file_path.relative_to(self.project_root)
            file_info = {
                'path': str(relative_path).replace('\\', '/'),
                'size_kb': round(file_path.stat().st_size / 1024, 1),
                'lines': self._count_lines(file_path)
            }
            
            report['unused_files'].append(file_info)
            
            # 按类别分类
            path_str = str(relative_path)
            if '/presentation/' in path_str:
                report['categories']['presentation'].append(file_info)
            elif '/domain/' in path_str:
                report['categories']['domain'].append(file_info)
            elif '/infrastructure/' in path_str:
                report['categories']['infrastructure'].append(file_info)
            elif '/application/' in path_str:
                report['categories']['application'].append(file_info)
            elif '/utils/' in path_str:
                report['categories']['utils'].append(file_info)
            elif '/widgets/' in path_str:
                report['categories']['widgets'].append(file_info)
            else:
                report['categories']['other'].append(file_info)
        
        return report

    def _count_lines(self, file_path: Path) -> int:
        """计算文件行数"""
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                return len(f.readlines())
        except Exception:
            return 0

    def run_analysis(self) -> Dict:
        """运行完整分析"""
        print("🚀 开始未使用代码检测...")
        print(f"📁 项目根目录: {self.project_root}")
        print()
        
        # 步骤1：找到所有文件
        self.find_all_dart_files()
        print()
        
        # 步骤2：分析导入关系
        self.analyze_imports()
        print()
        
        # 步骤3：标记被使用的文件
        self.mark_used_files()
        print()
        
        # 步骤4：找到未使用的文件
        unused_files = self.find_unused_files()
        print(f"🗑️  发现 {len(unused_files)} 个可能未使用的文件")
        print()
        
        # 步骤5：生成报告
        report = self.generate_report(unused_files)
        
        return report

def print_report(report: Dict):
    """打印报告"""
    print("📊 未使用代码文件检测报告")
    print("=" * 50)
    print()
    
    # 概要信息
    summary = report['summary']
    print("📈 概要统计:")
    print(f"   总文件数: {summary['total_dart_files']}")
    print(f"   已使用: {summary['used_files']}")
    print(f"   未使用: {summary['unused_files']}")
    print(f"   使用率: {summary['usage_rate']}")
    print()
    
    if not report['unused_files']:
        print("🎉 恭喜！没有发现未使用的代码文件！")
        return
    
    # 按类别显示
    categories = report['categories']
    for category, files in categories.items():
        if files:
            print(f"📂 {category.upper()} 目录:")
            for file_info in files:
                print(f"   - {file_info['path']} ({file_info['size_kb']}KB, {file_info['lines']}行)")
            print()
    
    # 详细清单
    print("📋 详细清单:")
    for file_info in report['unused_files']:
        print(f"   {file_info['path']}")
    print()
    
    # 建议
    total_size = sum(f['size_kb'] for f in report['unused_files'])
    total_lines = sum(f['lines'] for f in report['unused_files'])
    
    print("💡 清理建议:")
    print(f"   删除这些文件可以节省 {total_size:.1f}KB 空间和 {total_lines} 行代码")
    print("   建议在删除前进行以下检查:")
    print("   1. 确认文件确实没有被使用")
    print("   2. 检查是否有动态引用（字符串路径、反射等）")
    print("   3. 检查是否是未来功能的预留代码")
    print("   4. 在版本控制中创建备份分支")

def main():
    """主函数"""
    project_root = os.getcwd()
    
    detector = UnusedCodeDetector(project_root)
    report = detector.run_analysis()
    
    # 保存报告
    report_file = Path(project_root) / "tools" / "reports" / "unused_code_report.json"
    report_file.parent.mkdir(parents=True, exist_ok=True)
    
    with open(report_file, 'w', encoding='utf-8') as f:
        json.dump(report, f, indent=2, ensure_ascii=False)
    
    print_report(report)
    print(f"📄 详细报告已保存到: {report_file}")

if __name__ == "__main__":
    main() 