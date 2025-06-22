#!/usr/bin/env python3
"""
验证未使用文件分析的准确性
通过多种方式交叉验证文件的使用情况
"""

import os
import re
import json
from pathlib import Path
from typing import Set, Dict, List, Tuple

class UnusedFilesVerifier:
    def __init__(self, project_root: str):
        self.project_root = Path(project_root)
        self.lib_dir = self.project_root / 'lib'
        self.test_dir = self.project_root / 'test'
        
        # 存储分析结果
        self.all_files = set()
        self.import_relationships = {}
        self.used_files = set()
        self.excluded_patterns = [
            r'\.g\.dart$',      # 代码生成文件
            r'\.freezed\.dart$', # Freezed生成文件
        ]
    
    def scan_all_files(self) -> None:
        """扫描所有Dart文件"""
        print("🔍 扫描所有Dart文件...")
        
        # 扫描lib目录
        if self.lib_dir.exists():
            for dart_file in self.lib_dir.rglob('*.dart'):
                if not self._is_excluded_file(dart_file):
                    rel_path = dart_file.relative_to(self.project_root)
                    self.all_files.add(str(rel_path))
        
        # 扫描test目录  
        if self.test_dir.exists():
            for dart_file in self.test_dir.rglob('*.dart'):
                rel_path = dart_file.relative_to(self.project_root)
                self.all_files.add(str(rel_path))
        
        print(f"   总有效文件数: {len(self.all_files)}")
    
    def _is_excluded_file(self, file_path: Path) -> bool:
        """检查文件是否应该被排除"""
        file_str = str(file_path)
        return any(re.search(pattern, file_str) for pattern in self.excluded_patterns)
    
    def analyze_imports(self) -> None:
        """分析所有文件的导入关系"""
        print("📚 分析导入关系...")
        
        for file_path_str in self.all_files:
            file_path = self.project_root / file_path_str
            if file_path.exists():
                imports = self._extract_imports(file_path)
                self.import_relationships[file_path_str] = imports
        
        print(f"   分析了 {len(self.import_relationships)} 个文件的导入关系")
    
    def _extract_imports(self, file_path: Path) -> List[str]:
        """提取文件中的所有导入"""
        imports = []
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                content = f.read()
                
            # 匹配import语句
            import_patterns = [
                r"import\s+['\"]([^'\"]+)['\"]",  # 基本import
                r"export\s+['\"]([^'\"]+)['\"]",  # export语句
                r"part\s+['\"]([^'\"]+)['\"]",    # part语句
            ]
            
            for pattern in import_patterns:
                matches = re.findall(pattern, content)
                for match in matches:
                    if match.startswith('package:'):
                        # 处理package导入
                        if match.startswith('package:demo/'):
                            lib_path = match.replace('package:demo/', 'lib/')
                            imports.append(lib_path)
                    elif match.startswith('.') or not match.startswith('dart:'):
                        # 处理相对路径导入
                        resolved_path = self._resolve_relative_import(file_path, match)
                        if resolved_path:
                            imports.append(resolved_path)
                            
        except Exception as e:
            print(f"警告: 读取文件 {file_path} 时出错: {e}")
            
        return imports
    
    def _resolve_relative_import(self, current_file: Path, import_path: str) -> str:
        """解析相对导入路径"""
        try:
            current_dir = current_file.parent
            target_path = (current_dir / import_path).resolve()
            
            # 确保目标文件存在且在项目内
            if target_path.exists() and target_path.is_relative_to(self.project_root):
                return str(target_path.relative_to(self.project_root))
                
        except Exception:
            pass
        return None
    
    def mark_used_files(self) -> None:
        """标记被使用的文件"""
        print("🎯 标记文件使用情况...")
        
        # 标记入口文件
        entry_points = [
            'lib/main.dart',
            'lib/app.dart', 
            'lib/presentation/app.dart'
        ]
        
        for entry in entry_points:
            if entry in self.all_files:
                self.used_files.add(entry)
        
        # 标记所有测试文件为已使用
        for file_path in self.all_files:
            if file_path.startswith('test/'):
                self.used_files.add(file_path)
        
        # 递归标记被导入的文件
        changed = True
        iterations = 0
        while changed and iterations < 50:  # 防止无限循环
            changed = False
            iterations += 1
            
            for file_path in list(self.used_files):
                if file_path in self.import_relationships:
                    for imported_file in self.import_relationships[file_path]:
                        if imported_file in self.all_files and imported_file not in self.used_files:
                            self.used_files.add(imported_file)
                            changed = True
        
        print(f"   经过 {iterations} 轮迭代，标记了 {len(self.used_files)} 个已使用文件")
    
    def get_unused_files(self) -> List[str]:
        """获取未使用的文件列表"""
        unused = []
        for file_path in self.all_files:
            if file_path.startswith('lib/') and file_path not in self.used_files:
                unused.append(file_path)
        return sorted(unused)
    
    def verify_sample_files(self, sample_files: List[str]) -> Dict[str, Dict]:
        """验证样本文件的使用情况"""
        print("🔬 验证样本文件...")
        results = {}
        
        for file_path in sample_files:
            result = {
                'exists': False,
                'imported_by': [],
                'imports': [],
                'likely_used': False
            }
            
            full_path = self.project_root / file_path
            if full_path.exists():
                result['exists'] = True
                result['imports'] = self.import_relationships.get(file_path, [])
                
                # 查找导入这个文件的其他文件
                for other_file, imports in self.import_relationships.items():
                    if file_path in imports:
                        result['imported_by'].append(other_file)
                
                # 判断是否可能被使用
                result['likely_used'] = (
                    len(result['imported_by']) > 0 or
                    file_path in self.used_files or
                    'main.dart' in file_path or
                    'app.dart' in file_path
                )
            
            results[file_path] = result
        
        return results
    
    def analyze_usage_patterns(self) -> Dict[str, int]:
        """分析文件使用模式"""
        patterns = {
            'widgets': 0,
            'providers': 0, 
            'services': 0,
            'models': 0,
            'repositories': 0,
            'pages': 0,
            'dialogs': 0,
            'utils': 0,
            'other': 0
        }
        
        unused_files = self.get_unused_files()
        
        for file_path in unused_files:
            file_lower = file_path.lower()
            categorized = False
            
            for pattern in patterns.keys():
                if pattern in file_lower:
                    patterns[pattern] += 1
                    categorized = True
                    break
            
            if not categorized:
                patterns['other'] += 1
        
        return patterns
    
    def generate_verification_report(self) -> str:
        """生成验证报告"""
        unused_files = self.get_unused_files()
        usage_patterns = self.analyze_usage_patterns()
        
        # 选择一些样本文件进行深度验证
        sample_size = min(20, len(unused_files))
        sample_files = unused_files[:sample_size] if sample_size > 0 else []
        sample_verification = self.verify_sample_files(sample_files)
        
        report = []
        report.append("=" * 60)
        report.append("📊 未使用文件验证报告")
        report.append("=" * 60)
        report.append("")
        
        # 总体统计
        report.append(f"📈 总体统计:")
        report.append(f"   总有效文件: {len(self.all_files)}")
        report.append(f"   已使用文件: {len(self.used_files)}")
        report.append(f"   未使用文件: {len(unused_files)}")
        report.append(f"   使用率: {len(self.used_files)/len(self.all_files)*100:.1f}%")
        report.append("")
        
        # 文件类型分布
        report.append("📂 未使用文件类型分布:")
        for pattern, count in usage_patterns.items():
            if count > 0:
                report.append(f"   {pattern}: {count}个")
        report.append("")
        
        # 样本验证结果
        if sample_verification:
            report.append(f"🔬 样本验证结果 (检查了{len(sample_verification)}个文件):")
            false_negatives = []
            
            for file_path, result in sample_verification.items():
                if result['likely_used']:
                    false_negatives.append(file_path)
                    report.append(f"   ❓ {file_path}")
                    report.append(f"      被导入: {len(result['imported_by'])}次")
                    if result['imported_by']:
                        report.append(f"      导入者: {result['imported_by'][:3]}")
            
            if false_negatives:
                report.append(f"   🚨 可能的误报: {len(false_negatives)}个")
                report.append(f"   准确率估计: {(sample_size-len(false_negatives))/sample_size*100:.1f}%")
            else:
                report.append(f"   ✅ 样本检查通过，未发现误报")
            report.append("")
        
        # 高风险删除文件（可能被动态引用）
        high_risk_patterns = ['main', 'app', 'route', 'provider', 'service']
        high_risk_files = []
        
        for file_path in unused_files:
            file_lower = file_path.lower()
            if any(pattern in file_lower for pattern in high_risk_patterns):
                high_risk_files.append(file_path)
        
        if high_risk_files:
            report.append("⚠️  高风险删除文件 (建议人工确认):")
            for file_path in high_risk_files[:10]:  # 只显示前10个
                report.append(f"   - {file_path}")
            if len(high_risk_files) > 10:
                report.append(f"   ... 还有{len(high_risk_files)-10}个文件")
            report.append("")
        
        return "\n".join(report)

def main():
    """主函数"""
    project_root = os.getcwd()
    print(f"🔍 验证项目: {project_root}")
    
    verifier = UnusedFilesVerifier(project_root)
    
    # 执行分析
    verifier.scan_all_files()
    verifier.analyze_imports()
    verifier.mark_used_files()
    
    # 生成验证报告
    report = verifier.generate_verification_report()
    print(report)
    
    # 保存报告
    report_path = Path(project_root) / 'tools' / 'reports' / 'unused_files_verification.txt'
    report_path.parent.mkdir(parents=True, exist_ok=True)
    
    with open(report_path, 'w', encoding='utf-8') as f:
        f.write(report)
    
    print(f"📄 详细验证报告已保存到: {report_path}")

if __name__ == "__main__":
    main() 