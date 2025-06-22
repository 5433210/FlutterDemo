#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
完整文件分析器
分析所有Dart文件的分类和使用情况
"""

import os
import re
import sys
from pathlib import Path
from typing import Set, Dict, List, Tuple
import json

class CompleteFileAnalyzer:
    def __init__(self, project_root: str):
        self.project_root = Path(project_root)
        self.lib_dir = self.project_root / "lib"
        self.test_dir = self.project_root / "test"
        
        # 文件分类
        self.all_dart_files: Set[Path] = set()
        self.excluded_files: Set[Path] = set()
        self.test_files: Set[Path] = set()
        self.lib_files: Set[Path] = set()
        self.used_files: Set[Path] = set()
        self.unused_files: Set[Path] = set()
        
        # 导入关系
        self.import_relationships: Dict[Path, Set[Path]] = {}
        
        # 排除模式
        self.exclude_patterns = [
            r'.*\.g\.dart$',  # 生成的文件
            r'.*\.freezed\.dart$',  # Freezed生成的文件
            r'.*\.config\.dart$',  # 配置文件
            r'.*/gen_l10n/.*',  # 国际化生成文件
            r'.*\.gr\.dart$',  # Auto route生成文件
            r'.*\.part\.dart$',  # Part文件
        ]
        
        # 入口文件
        self.entry_files = [
            'main.dart',
            'providers.dart', 
            'constants.dart',
        ]

    def analyze_all_files(self) -> Dict:
        """分析所有文件"""
        print("🔍 开始完整文件分析...")
        print(f"📁 项目根目录: {self.project_root}")
        print()
        
        # 第一步：扫描所有文件
        self._scan_all_files()
        
        # 第二步：分析导入关系
        self._analyze_imports()
        
        # 第三步：标记使用情况
        self._mark_used_files()
        
        # 第四步：生成统计报告
        return self._generate_complete_report()

    def _scan_all_files(self):
        """扫描所有Dart文件并分类"""
        print("📂 扫描所有Dart文件...")
        
        # 扫描lib目录
        if self.lib_dir.exists():
            for dart_file in self.lib_dir.rglob("*.dart"):
                self.all_dart_files.add(dart_file)
                if self._should_exclude(dart_file):
                    self.excluded_files.add(dart_file)
                else:
                    self.lib_files.add(dart_file)
        
        # 扫描test目录
        if self.test_dir.exists():
            for dart_file in self.test_dir.rglob("*.dart"):
                self.all_dart_files.add(dart_file)
                if self._should_exclude(dart_file):
                    self.excluded_files.add(dart_file)
                else:
                    self.test_files.add(dart_file)
        
        print(f"   总文件数: {len(self.all_dart_files)}")
        print(f"   lib/目录: {len([f for f in self.all_dart_files if '/lib/' in str(f) or '\\lib\\' in str(f)])}")
        print(f"   test/目录: {len([f for f in self.all_dart_files if '/test/' in str(f) or '\\test\\' in str(f)])}")
        print(f"   排除文件: {len(self.excluded_files)}")
        print(f"   有效lib文件: {len(self.lib_files)}")
        print(f"   有效test文件: {len(self.test_files)}")

    def _should_exclude(self, file_path: Path) -> bool:
        """检查文件是否应该被排除"""
        file_str = str(file_path)
        for pattern in self.exclude_patterns:
            if re.match(pattern, file_str):
                return True
        return False

    def _analyze_imports(self):
        """分析导入关系"""
        print("\n📚 分析导入关系...")
        
        # 分析有效的lib文件
        for dart_file in self.lib_files:
            try:
                imports = self._extract_imports(dart_file)
                self.import_relationships[dart_file] = imports
            except Exception as e:
                print(f"   ⚠️  分析文件失败: {dart_file} - {e}")
        
        # 分析test文件
        for dart_file in self.test_files:
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
            r"import\s+['\"]([^'\"]+\.dart)['\"]",
            r"export\s+['\"]([^'\"]+\.dart)['\"]",
            r"part\s+['\"]([^'\"]+\.dart)['\"]",
        ]
        
        for pattern in import_patterns:
            matches = re.findall(pattern, content)
            for match in matches:
                imported_file = self._resolve_import_path(file_path, match)
                if imported_file and imported_file.exists() and imported_file not in self.excluded_files:
                    imports.add(imported_file)
        
        return imports

    def _resolve_import_path(self, from_file: Path, import_path: str) -> Path:
        """解析导入路径为绝对路径"""
        if import_path.startswith('package:'):
            if not import_path.startswith('package:demo/'):
                return None
            relative_path = import_path.replace('package:demo/', '')
            return self.lib_dir / relative_path
        
        if import_path.startswith('./') or import_path.startswith('../'):
            base_dir = from_file.parent
            return (base_dir / import_path).resolve()
        
        return self.lib_dir / import_path

    def _mark_used_files(self):
        """标记被使用的文件"""
        print("\n🎯 标记文件使用情况...")
        
        # 标记入口文件
        for entry_name in self.entry_files:
            entry_file = self.lib_dir / entry_name
            if entry_file.exists() and entry_file not in self.excluded_files:
                self._mark_file_and_dependencies(entry_file)
        
        # 所有测试文件都被认为是被使用的
        for test_file in self.test_files:
            self._mark_file_and_dependencies(test_file)
        
        # 计算未使用文件（只考虑lib文件）
        self.unused_files = self.lib_files - self.used_files
        
        print(f"   已使用文件: {len(self.used_files)}")
        print(f"   未使用文件: {len(self.unused_files)}")

    def _mark_file_and_dependencies(self, file_path: Path):
        """递归标记文件及其依赖为已使用"""
        if file_path in self.used_files:
            return
        
        self.used_files.add(file_path)
        
        if file_path in self.import_relationships:
            for imported_file in self.import_relationships[file_path]:
                self._mark_file_and_dependencies(imported_file)

    def _generate_complete_report(self) -> Dict:
        """生成完整报告"""
        print("\n📊 生成完整分析报告...")
        
        # 分析排除文件的类型
        excluded_by_type = {
            'generated': [],
            'freezed': [],
            'config': [],
            'l10n': [],
            'auto_route': [],
            'part': [],
            'other': []
        }
        
        for file_path in self.excluded_files:
            file_str = str(file_path)
            relative_path = file_path.relative_to(self.project_root)
            file_info = {
                'path': str(relative_path).replace('\\', '/'),
                'size_kb': round(file_path.stat().st_size / 1024, 1) if file_path.exists() else 0
            }
            
            if re.search(r'\.g\.dart$', file_str):
                excluded_by_type['generated'].append(file_info)
            elif re.search(r'\.freezed\.dart$', file_str):
                excluded_by_type['freezed'].append(file_info)
            elif re.search(r'\.config\.dart$', file_str):
                excluded_by_type['config'].append(file_info)
            elif '/gen_l10n/' in file_str:
                excluded_by_type['l10n'].append(file_info)
            elif re.search(r'\.gr\.dart$', file_str):
                excluded_by_type['auto_route'].append(file_info)
            elif re.search(r'\.part\.dart$', file_str):
                excluded_by_type['part'].append(file_info)
            else:
                excluded_by_type['other'].append(file_info)
        
        # 统计测试文件
        test_file_info = []
        for test_file in self.test_files:
            relative_path = test_file.relative_to(self.project_root)
            test_file_info.append({
                'path': str(relative_path).replace('\\', '/'),
                'size_kb': round(test_file.stat().st_size / 1024, 1) if test_file.exists() else 0
            })
        
        # 统计未使用文件
        unused_file_info = []
        for unused_file in self.unused_files:
            relative_path = unused_file.relative_to(self.project_root)
            unused_file_info.append({
                'path': str(relative_path).replace('\\', '/'),
                'size_kb': round(unused_file.stat().st_size / 1024, 1) if unused_file.exists() else 0
            })
        
        # 统计已使用文件
        used_file_info = []
        for used_file in self.used_files:
            if used_file in self.lib_files:  # 只统计lib文件
                relative_path = used_file.relative_to(self.project_root)
                used_file_info.append({
                    'path': str(relative_path).replace('\\', '/'),
                    'size_kb': round(used_file.stat().st_size / 1024, 1) if used_file.exists() else 0
                })
        
        report = {
            'summary': {
                'total_dart_files': len(self.all_dart_files),
                'lib_files': len(self.lib_files),
                'test_files': len(self.test_files),
                'excluded_files': len(self.excluded_files),
                'used_lib_files': len(used_file_info),
                'unused_lib_files': len(unused_file_info),
                'percentages': {
                    'lib_files': f"{(len(self.lib_files) / len(self.all_dart_files) * 100):.1f}%",
                    'test_files': f"{(len(self.test_files) / len(self.all_dart_files) * 100):.1f}%",
                    'excluded_files': f"{(len(self.excluded_files) / len(self.all_dart_files) * 100):.1f}%",
                    'used_lib_files': f"{(len(used_file_info) / len(self.lib_files) * 100):.1f}%" if self.lib_files else "0%",
                    'unused_lib_files': f"{(len(unused_file_info) / len(self.lib_files) * 100):.1f}%" if self.lib_files else "0%"
                }
            },
            'excluded_files': {
                'by_type': excluded_by_type,
                'total_count': {k: len(v) for k, v in excluded_by_type.items()}
            },
            'test_files': test_file_info,
            'used_lib_files': used_file_info,
            'unused_lib_files': unused_file_info
        }
        
        return report

def print_complete_report(report: Dict):
    """打印完整报告"""
    print("\n" + "="*60)
    print("📊 完整文件分析报告")
    print("="*60)
    
    summary = report['summary']
    percentages = summary['percentages']
    
    print(f"\n📈 总体统计:")
    print(f"   总Dart文件数: {summary['total_dart_files']}")
    print(f"   ├── lib/目录文件: {summary['lib_files']} ({percentages['lib_files']})")
    print(f"   ├── test/目录文件: {summary['test_files']} ({percentages['test_files']})")
    print(f"   └── 排除的文件: {summary['excluded_files']} ({percentages['excluded_files']})")
    
    print(f"\n📂 lib/目录文件分析:")
    print(f"   总lib文件: {summary['lib_files']}")
    print(f"   ├── 已使用: {summary['used_lib_files']} ({percentages['used_lib_files']})")
    print(f"   └── 未使用: {summary['unused_lib_files']} ({percentages['unused_lib_files']})")
    
    print(f"\n🚫 排除文件详情:")
    excluded = report['excluded_files']['total_count']
    for file_type, count in excluded.items():
        if count > 0:
            type_names = {
                'generated': '代码生成文件 (.g.dart)',
                'freezed': 'Freezed生成文件 (.freezed.dart)',
                'config': '配置文件 (.config.dart)',
                'l10n': '国际化生成文件',
                'auto_route': 'Auto Route文件 (.gr.dart)',
                'part': 'Part文件 (.part.dart)',
                'other': '其他排除文件'
            }
            print(f"   ├── {type_names.get(file_type, file_type)}: {count}个文件")
    
    # 显示排除文件的详细列表
    if excluded['generated'] > 0:
        print(f"\n🔧 代码生成文件 ({excluded['generated']}个):")
        for file_info in report['excluded_files']['by_type']['generated'][:10]:  # 只显示前10个
            print(f"   - {file_info['path']}")
        if excluded['generated'] > 10:
            print(f"   ... 还有 {excluded['generated'] - 10} 个文件")
    
    if excluded['l10n'] > 0:
        print(f"\n🌍 国际化生成文件 ({excluded['l10n']}个):")
        for file_info in report['excluded_files']['by_type']['l10n']:
            print(f"   - {file_info['path']}")
    
    print(f"\n🧪 测试文件 ({summary['test_files']}个):")
    print("   所有测试文件都被视为'已使用'")
    
    print(f"\n✅ 数学验证:")
    total_accounted = summary['lib_files'] + summary['test_files'] + summary['excluded_files']
    print(f"   lib文件 + test文件 + 排除文件 = {summary['lib_files']} + {summary['test_files']} + {summary['excluded_files']} = {total_accounted}")
    print(f"   总文件数: {summary['total_dart_files']}")
    if total_accounted == summary['total_dart_files']:
        print("   ✅ 文件统计正确!")
    else:
        print(f"   ❌ 统计不匹配，差异: {summary['total_dart_files'] - total_accounted}")

def main():
    """主函数"""
    project_root = os.getcwd()
    
    analyzer = CompleteFileAnalyzer(project_root)
    report = analyzer.analyze_all_files()
    
    # 保存报告
    report_file = Path(project_root) / "tools" / "reports" / "complete_file_analysis.json"
    report_file.parent.mkdir(parents=True, exist_ok=True)
    
    with open(report_file, 'w', encoding='utf-8') as f:
        json.dump(report, f, indent=2, ensure_ascii=False)
    
    print_complete_report(report)
    print(f"\n📄 详细报告已保存到: {report_file}")

if __name__ == "__main__":
    main() 