#!/usr/bin/env python3
"""
改进版未使用文件分析工具
提供更高精度的文件使用情况检测
"""

import os
import re
import json
from pathlib import Path
from typing import Set, Dict, List, Tuple, Optional
from urllib.parse import unquote

class ImprovedUnusedAnalyzer:
    def __init__(self, project_root: str):
        self.project_root = Path(project_root).resolve()
        self.lib_dir = self.project_root / 'lib'
        self.test_dir = self.project_root / 'test'
        
        # 存储分析结果
        self.all_files: Set[str] = set()
        self.import_relationships: Dict[str, Set[str]] = {}
        self.used_files: Set[str] = set()
        self.file_info: Dict[str, dict] = {}
        
        # 排除模式
        self.excluded_patterns = [
            r'\.g\.dart$',      # 代码生成文件
            r'\.freezed\.dart$', # Freezed生成文件
        ]
        
        # 入口文件模式
        self.entry_patterns = [
            'lib/main.dart',
            'lib/app.dart',
            'lib/presentation/app.dart',
            'lib/routes/app_routes.dart',
            'lib/providers.dart',
        ]
        
        # 特殊文件模式（通常被动态引用）
        self.special_patterns = [
            r'.*provider.*\.dart$',    # Provider文件
            r'.*route.*\.dart$',       # 路由文件
            r'.*navigation.*\.dart$',  # 导航文件
            r'.*service.*\.dart$',     # 服务文件
            r'.*repository.*\.dart$',  # 仓库文件
            r'.*mixin.*\.dart$',       # Mixin文件
            r'.*extension.*\.dart$',   # 扩展文件
        ]
    
    def scan_all_files(self) -> None:
        """扫描所有Dart文件并收集基本信息"""
        print("🔍 扫描所有Dart文件...")
        
        # 扫描lib目录
        lib_files = 0
        if self.lib_dir.exists():
            for dart_file in self.lib_dir.rglob('*.dart'):
                if not self._is_excluded_file(dart_file):
                    rel_path = str(dart_file.relative_to(self.project_root)).replace('\\', '/')
                    self.all_files.add(rel_path)
                    self.file_info[rel_path] = {
                        'size': dart_file.stat().st_size,
                        'is_empty': dart_file.stat().st_size < 50,  # 认为小于50字节的文件为空
                        'is_special': self._is_special_file(rel_path),
                        'absolute_path': dart_file
                    }
                    lib_files += 1
        
        # 扫描test目录
        test_files = 0
        if self.test_dir.exists():
            for dart_file in self.test_dir.rglob('*.dart'):
                rel_path = str(dart_file.relative_to(self.project_root)).replace('\\', '/')
                self.all_files.add(rel_path)
                self.file_info[rel_path] = {
                    'size': dart_file.stat().st_size,
                    'is_empty': dart_file.stat().st_size < 50,
                    'is_special': False,
                    'is_test': True,
                    'absolute_path': dart_file
                }
                test_files += 1
        
        print(f"   总有效文件数: {len(self.all_files)}")
        print(f"   lib文件: {lib_files}, test文件: {test_files}")
    
    def _is_excluded_file(self, file_path: Path) -> bool:
        """检查文件是否应该被排除"""
        file_str = str(file_path)
        return any(re.search(pattern, file_str) for pattern in self.excluded_patterns)
    
    def _is_special_file(self, file_path: str) -> bool:
        """检查是否为特殊文件（通常被动态引用）"""
        return any(re.search(pattern, file_path, re.IGNORECASE) for pattern in self.special_patterns)
    
    def analyze_imports(self) -> None:
        """分析所有文件的导入关系"""
        print("📚 分析导入关系...")
        
        for file_path in self.all_files:
            full_path = self.file_info[file_path]['absolute_path']
            imports = self._extract_imports_improved(full_path, file_path)
            self.import_relationships[file_path] = imports
        
        print(f"   分析了 {len(self.import_relationships)} 个文件的导入关系")
        
        # 统计导入数量
        total_imports = sum(len(imports) for imports in self.import_relationships.values())
        print(f"   发现 {total_imports} 个导入关系")
    
    def _extract_imports_improved(self, file_path: Path, relative_path: str) -> Set[str]:
        """改进的导入提取方法"""
        imports = set()
        
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                content = f.read()
        except Exception as e:
            print(f"   警告: 读取文件 {file_path} 时出错: {e}")
            return imports
        
        # 移除注释和字符串字面量，避免误检测
        content = self._remove_comments_and_strings(content)
        
        # 多种导入模式
        import_patterns = [
            r"import\s+['\"]([^'\"]+)['\"]",     # import 'path'
            r"export\s+['\"]([^'\"]+)['\"]",     # export 'path'
            r"part\s+['\"]([^'\"]+)['\"]",       # part 'path'
            r"part\s+of\s+['\"]([^'\"]+)['\"]",  # part of 'path'
        ]
        
        for pattern in import_patterns:
            matches = re.findall(pattern, content)
            for match in matches:
                resolved_import = self._resolve_import_path(match, relative_path)
                if resolved_import:
                    imports.add(resolved_import)
        
        return imports
    
    def _remove_comments_and_strings(self, content: str) -> str:
        """移除注释和字符串字面量，避免在注释中的import被误检测"""
        # 简单的注释和字符串移除（不完全精确，但足够用）
        lines = content.split('\n')
        cleaned_lines = []
        
        for line in lines:
            # 移除单行注释
            if '//' in line:
                line = line[:line.find('//')]
            
            # 移除多行注释（简单处理）
            if '/*' in line and '*/' in line:
                start = line.find('/*')
                end = line.find('*/', start) + 2
                line = line[:start] + line[end:]
            
            cleaned_lines.append(line)
        
        return '\n'.join(cleaned_lines)
    
    def _resolve_import_path(self, import_path: str, current_file: str) -> Optional[str]:
        """解析导入路径为项目内的相对路径"""
        try:
            # 处理package:导入
            if import_path.startswith('package:demo/'):
                lib_path = import_path.replace('package:demo/', 'lib/')
                if lib_path in self.all_files:
                    return lib_path
            
            # 处理dart:导入（忽略）
            elif import_path.startswith('dart:'):
                return None
            
            # 处理外部package导入（忽略）
            elif import_path.startswith('package:') and not import_path.startswith('package:demo/'):
                return None
            
            # 处理相对导入
            elif import_path.startswith('.'):
                current_dir = Path(current_file).parent
                target_path = (current_dir / import_path).resolve()
                
                # 转换为相对于项目根目录的路径
                try:
                    rel_target = str(target_path.relative_to(self.project_root)).replace('\\', '/')
                    if rel_target in self.all_files:
                        return rel_target
                except ValueError:
                    # 路径不在项目内
                    pass
            
            # 处理绝对导入（相对于lib目录）
            else:
                # 尝试作为lib目录下的文件
                lib_path = f"lib/{import_path}"
                if lib_path in self.all_files:
                    return lib_path
                
                # 尝试添加.dart扩展名
                if not import_path.endswith('.dart'):
                    lib_path_dart = f"lib/{import_path}.dart"
                    if lib_path_dart in self.all_files:
                        return lib_path_dart
        
        except Exception:
            pass
        
        return None
    
    def mark_used_files(self) -> None:
        """标记被使用的文件"""
        print("🎯 标记文件使用情况...")
        
        # 1. 标记入口文件
        entry_count = 0
        for entry_pattern in self.entry_patterns:
            if entry_pattern in self.all_files:
                self.used_files.add(entry_pattern)
                entry_count += 1
        print(f"   发现 {entry_count} 个入口文件")
        
        # 2. 标记所有测试文件为已使用
        test_count = 0
        for file_path in self.all_files:
            if file_path.startswith('test/'):
                self.used_files.add(file_path)
                test_count += 1
        print(f"   标记 {test_count} 个测试文件为已使用")
        
        # 3. 标记特殊文件
        special_count = 0
        for file_path in self.all_files:
            if self.file_info[file_path].get('is_special', False):
                self.used_files.add(file_path)
                special_count += 1
        print(f"   标记 {special_count} 个特殊文件为已使用")
        
        # 4. 递归标记被导入的文件
        initial_used = len(self.used_files)
        changed = True
        iterations = 0
        max_iterations = 100  # 防止无限循环
        
        while changed and iterations < max_iterations:
            changed = False
            iterations += 1
            old_count = len(self.used_files)
            
            # 遍历已使用的文件，标记它们导入的文件
            for used_file in list(self.used_files):
                if used_file in self.import_relationships:
                    for imported_file in self.import_relationships[used_file]:
                        if imported_file not in self.used_files:
                            self.used_files.add(imported_file)
                            changed = True
            
            new_count = len(self.used_files)
            if new_count > old_count:
                print(f"     第{iterations}轮: 新增 {new_count - old_count} 个使用文件")
        
        final_used = len(self.used_files)
        print(f"   经过 {iterations} 轮迭代，从 {initial_used} 增加到 {final_used} 个已使用文件")
    
    def analyze_unused_files(self) -> Dict[str, List[dict]]:
        """分析未使用的文件，按优先级分类"""
        print("📊 分析未使用文件...")
        
        unused_analysis = {
            'safe_to_delete': [],      # 安全删除
            'likely_unused': [],       # 可能未使用
            'review_needed': [],       # 需要人工审查
            'empty_files': []          # 空文件
        }
        
        for file_path in self.all_files:
            if file_path.startswith('lib/') and file_path not in self.used_files:
                file_info = self.file_info[file_path]
                
                file_data = {
                    'path': file_path,
                    'size_kb': file_info['size'] / 1024,
                    'size_bytes': file_info['size'],
                    'is_empty': file_info['is_empty'],
                    'is_special': file_info['is_special']
                }
                
                # 分类逻辑
                if file_info['is_empty']:
                    unused_analysis['empty_files'].append(file_data)
                elif file_info['is_special']:
                    unused_analysis['review_needed'].append(file_data)
                elif file_info['size'] < 1000:  # 小于1KB的文件
                    unused_analysis['likely_unused'].append(file_data)
                else:
                    unused_analysis['safe_to_delete'].append(file_data)
        
        # 按大小排序
        for category in unused_analysis.values():
            category.sort(key=lambda x: x['size_bytes'])
        
        return unused_analysis
    
    def cross_validate_sample(self, sample_files: List[str], sample_size: int = 20) -> Dict:
        """交叉验证样本文件"""
        print(f"🔬 交叉验证前{sample_size}个文件...")
        
        validation_results = {
            'checked': 0,
            'confirmed_unused': 0,
            'false_positives': 0,
            'false_positive_files': []
        }
        
        for i, file_path in enumerate(sample_files[:sample_size]):
            validation_results['checked'] += 1
            
            # 在所有文件中搜索对此文件的引用
            is_referenced = False
            references = []
            
            file_name = Path(file_path).stem
            
            for check_file in self.all_files:
                if check_file == file_path:
                    continue
                
                try:
                    with open(self.file_info[check_file]['absolute_path'], 'r', encoding='utf-8') as f:
                        content = f.read()
                    
                    # 检查多种引用方式
                    if (file_path in content or 
                        file_name in content or
                        f"'{file_path}'" in content or
                        f'"{file_path}"' in content):
                        is_referenced = True
                        references.append(check_file)
                        break
                        
                except Exception:
                    continue
            
            if is_referenced:
                validation_results['false_positives'] += 1
                validation_results['false_positive_files'].append({
                    'file': file_path,
                    'references': references[:3]  # 只保留前3个引用
                })
            else:
                validation_results['confirmed_unused'] += 1
        
        return validation_results
    
    def generate_detailed_report(self) -> str:
        """生成详细的分析报告"""
        unused_analysis = self.analyze_unused_files()
        
        # 统计信息
        total_lib_files = len([f for f in self.all_files if f.startswith('lib/')])
        total_unused = sum(len(category) for category in unused_analysis.values())
        used_files = total_lib_files - total_unused
        
        # 交叉验证
        all_unused = []
        for category in unused_analysis.values():
            all_unused.extend([item['path'] for item in category])
        
        validation = self.cross_validate_sample(all_unused, min(30, len(all_unused)))
        
        # 生成报告
        report_lines = []
        report_lines.append("=" * 80)
        report_lines.append("📊 改进版未使用文件分析报告")
        report_lines.append("=" * 80)
        report_lines.append("")
        
        # 总体统计
        report_lines.append("📈 总体统计:")
        report_lines.append(f"   总lib文件数: {total_lib_files}")
        report_lines.append(f"   已使用文件: {used_files} ({used_files/total_lib_files*100:.1f}%)")
        report_lines.append(f"   未使用文件: {total_unused} ({total_unused/total_lib_files*100:.1f}%)")
        report_lines.append("")
        
        # 交叉验证结果
        if validation['checked'] > 0:
            accuracy = (validation['confirmed_unused'] / validation['checked']) * 100
            report_lines.append("🔬 交叉验证结果:")
            report_lines.append(f"   验证样本: {validation['checked']}个文件")
            report_lines.append(f"   确认未使用: {validation['confirmed_unused']}个")
            report_lines.append(f"   误报: {validation['false_positives']}个")
            report_lines.append(f"   预估准确率: {accuracy:.1f}%")
            report_lines.append("")
        
        # 分类统计
        report_lines.append("📂 未使用文件分类:")
        for category, items in unused_analysis.items():
            if items:
                total_size = sum(item['size_kb'] for item in items)
                report_lines.append(f"   {self._get_category_name(category)}: {len(items)}个文件 ({total_size:.1f}KB)")
        report_lines.append("")
        
        # 删除建议
        report_lines.append("🎯 删除建议:")
        if unused_analysis['empty_files']:
            report_lines.append(f"   ✅ 立即删除空文件: {len(unused_analysis['empty_files'])}个")
        if unused_analysis['safe_to_delete']:
            report_lines.append(f"   ⚠️  审查后删除: {len(unused_analysis['safe_to_delete'])}个")
        if unused_analysis['likely_unused']:
            report_lines.append(f"   🔍 仔细检查: {len(unused_analysis['likely_unused'])}个")
        if unused_analysis['review_needed']:
            report_lines.append(f"   ❌ 需要人工审查: {len(unused_analysis['review_needed'])}个")
        report_lines.append("")
        
        # 详细列表（只显示部分）
        for category, items in unused_analysis.items():
            if items:
                report_lines.append(f"📋 {self._get_category_name(category)} (显示前10个):")
                for item in items[:10]:
                    report_lines.append(f"   - {item['path']} ({item['size_kb']:.1f}KB)")
                if len(items) > 10:
                    report_lines.append(f"   ... 还有{len(items)-10}个文件")
                report_lines.append("")
        
        return "\n".join(report_lines)
    
    def _get_category_name(self, category: str) -> str:
        """获取分类的中文名称"""
        names = {
            'safe_to_delete': '安全删除',
            'likely_unused': '可能未使用',
            'review_needed': '需要审查',
            'empty_files': '空文件'
        }
        return names.get(category, category)

def main():
    """主函数"""
    project_root = os.getcwd()
    print(f"🚀 启动改进版未使用文件分析器")
    print(f"📁 项目路径: {project_root}")
    print()
    
    analyzer = ImprovedUnusedAnalyzer(project_root)
    
    # 执行分析
    analyzer.scan_all_files()
    analyzer.analyze_imports()
    analyzer.mark_used_files()
    
    # 生成报告
    report = analyzer.generate_detailed_report()
    print(report)
    
    # 保存报告
    report_path = Path(project_root) / 'tools' / 'reports' / 'improved_unused_analysis.txt'
    report_path.parent.mkdir(parents=True, exist_ok=True)
    
    with open(report_path, 'w', encoding='utf-8') as f:
        f.write(report)
    
    # 保存详细数据
    unused_analysis = analyzer.analyze_unused_files()
    json_path = Path(project_root) / 'tools' / 'reports' / 'improved_unused_analysis.json'
    
    with open(json_path, 'w', encoding='utf-8') as f:
        json.dump({
            'summary': {
                'total_lib_files': len([f for f in analyzer.all_files if f.startswith('lib/')]),
                'used_files': len([f for f in analyzer.used_files if f.startswith('lib/')]),
                'unused_by_category': {cat: len(items) for cat, items in unused_analysis.items()}
            },
            'unused_analysis': unused_analysis,
            'validation': analyzer.cross_validate_sample([item['path'] for category in unused_analysis.values() for item in category], 30)
        }, f, indent=2, ensure_ascii=False)
    
    print(f"📄 详细报告已保存到: {report_path}")
    print(f"📄 JSON数据已保存到: {json_path}")

if __name__ == "__main__":
    main() 