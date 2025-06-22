#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Markdown报告生成器
生成详细的文件分析markdown报告
"""

import os
import re
import sys
from pathlib import Path
from typing import Set, Dict, List, Tuple
import json
from datetime import datetime

class MarkdownReportGenerator:
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

    def generate_full_report(self) -> str:
        """生成完整的markdown报告"""
        print("🚀 开始生成详细markdown报告...")
        
        # 分析所有文件
        self._scan_all_files()
        self._analyze_imports()
        self._mark_used_files()
        
        # 生成markdown内容
        markdown_content = self._build_markdown_report()
        
        return markdown_content

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

    def _should_exclude(self, file_path: Path) -> bool:
        """检查文件是否应该被排除"""
        file_str = str(file_path)
        for pattern in self.exclude_patterns:
            if re.match(pattern, file_str):
                return True
        return False

    def _analyze_imports(self):
        """分析导入关系"""
        print("📚 分析导入关系...")
        
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
        print("🎯 标记文件使用情况...")
        
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

    def _mark_file_and_dependencies(self, file_path: Path):
        """递归标记文件及其依赖为已使用"""
        if file_path in self.used_files:
            return
        
        self.used_files.add(file_path)
        
        if file_path in self.import_relationships:
            for imported_file in self.import_relationships[file_path]:
                self._mark_file_and_dependencies(imported_file)

    def _get_file_info(self, file_path: Path) -> Dict:
        """获取文件信息"""
        try:
            stat = file_path.stat()
            size_kb = round(stat.st_size / 1024, 1)
            
            # 计算行数
            lines = 0
            try:
                with open(file_path, 'r', encoding='utf-8') as f:
                    lines = len(f.readlines())
            except:
                lines = 0
            
            return {
                'path': str(file_path.relative_to(self.project_root)).replace('\\', '/'),
                'size_kb': size_kb,
                'lines': lines
            }
        except:
            return {
                'path': str(file_path.relative_to(self.project_root)).replace('\\', '/'),
                'size_kb': 0,
                'lines': 0
            }

    def _categorize_files(self, files: Set[Path]) -> Dict[str, List[Dict]]:
        """按目录结构分类文件"""
        categories = {
            'application': [],
            'domain': [],
            'infrastructure': [],
            'presentation': [],
            'canvas': [],
            'utils': [],
            'tools': [],
            'widgets': [],
            'extensions': [],
            'theme': [],
            'routes': [],
            'providers': [],
            'scripts': [],
            'l10n': [],
            'test': [],
            'other': []
        }
        
        for file_path in sorted(files):
            file_info = self._get_file_info(file_path)
            path_str = file_info['path'].lower()
            
            categorized = False
            for category in categories.keys():
                if f'/{category}/' in path_str or f'\\{category}\\' in path_str:
                    categories[category].append(file_info)
                    categorized = True
                    break
            
            if not categorized:
                categories['other'].append(file_info)
        
        # 移除空分类
        return {k: v for k, v in categories.items() if v}

    def _build_markdown_report(self) -> str:
        """构建markdown报告"""
        print("📝 生成markdown内容...")
        
        # 计算统计数据
        total_files = len(self.all_dart_files)
        lib_files_count = len(self.lib_files)
        test_files_count = len(self.test_files)
        excluded_count = len(self.excluded_files)
        used_count = len([f for f in self.used_files if f in self.lib_files])
        unused_count = len(self.unused_files)
        
        # 分类文件
        excluded_categorized = self._categorize_excluded_files()
        used_categorized = self._categorize_files(self.used_files & self.lib_files)
        unused_categorized = self._categorize_files(self.unused_files)
        test_categorized = self._categorize_files(self.test_files)
        
        # 生成markdown内容
        md = []
        
        # 标题和概要
        md.extend([
            "# 📊 Flutter项目文件分析详细报告\n",
            f"**生成时间**: {datetime.now().strftime('%Y年%m月%d日 %H:%M:%S')}\n",
            f"**项目路径**: `{self.project_root}`\n",
            f"**分析工具**: markdown_report_generator.py\n",
            "\n---\n",
            
            "## 📈 总体统计\n",
            f"- **总Dart文件数**: {total_files}个",
            f"- **lib/目录文件**: {lib_files_count}个 ({lib_files_count/total_files*100:.1f}%)",
            f"- **test/目录文件**: {test_files_count}个 ({test_files_count/total_files*100:.1f}%)",
            f"- **排除的文件**: {excluded_count}个 ({excluded_count/total_files*100:.1f}%)",
            "",
            "### 📂 lib/目录文件详情",
            f"- **已使用文件**: {used_count}个 ({used_count/lib_files_count*100:.1f}%)",
            f"- **未使用文件**: {unused_count}个 ({unused_count/lib_files_count*100:.1f}%)",
            "",
            "### ✅ 数学验证",
            f"```",
            f"总文件 = lib文件 + test文件 + 排除文件",
            f"{total_files} = {lib_files_count} + {test_files_count} + {excluded_count}",
            f"lib文件 = 已使用 + 未使用",
            f"{lib_files_count} = {used_count} + {unused_count}",
            f"```\n"
        ])
        
        # 排除文件详情
        if excluded_categorized:
            md.extend([
                "## 🚫 排除的文件 (自动生成/系统文件)\n",
                f"总计: {excluded_count}个文件\n"
            ])
            
            for category, files in excluded_categorized.items():
                if files:
                    category_names = {
                        'generated': '🔧 代码生成文件 (.g.dart)',
                        'freezed': '❄️ Freezed生成文件 (.freezed.dart)',
                        'config': '⚙️ 配置文件 (.config.dart)',
                        'l10n': '🌍 国际化生成文件',
                        'auto_route': '🛣️ Auto Route文件 (.gr.dart)',
                        'part': '📄 Part文件 (.part.dart)',
                        'other': '❓ 其他排除文件'
                    }
                    
                    md.extend([
                        f"### {category_names.get(category, category)} ({len(files)}个)\n",
                        "<details>",
                        f"<summary>点击展开查看详细列表</summary>\n"
                    ])
                    
                    for file_info in files:
                        md.append(f"- `{file_info['path']}` ({file_info['size_kb']}KB)")
                    
                    md.extend(["", "</details>\n"])
        
        # 已使用文件详情
        if used_categorized:
            md.extend([
                f"## ✅ 已使用的文件 (lib目录)\n",
                f"总计: {used_count}个文件\n"
            ])
            
            for category, files in used_categorized.items():
                if files:
                    total_size = sum(f['size_kb'] for f in files)
                    total_lines = sum(f['lines'] for f in files)
                    
                    md.extend([
                        f"### 📁 {category.title()} ({len(files)}个文件, {total_size:.1f}KB, {total_lines}行)\n",
                        "<details>",
                        f"<summary>点击展开查看详细列表</summary>\n"
                    ])
                    
                    for file_info in files:
                        md.append(f"- `{file_info['path']}` ({file_info['size_kb']}KB, {file_info['lines']}行)")
                    
                    md.extend(["", "</details>\n"])
        
        # 未使用文件详情
        if unused_categorized:
            md.extend([
                f"## ❌ 未使用的文件 (lib目录)\n",
                f"总计: {unused_count}个文件\n"
            ])
            
            # 按优先级分类
            high_priority = []
            medium_priority = []
            low_priority = []
            
            for category, files in unused_categorized.items():
                for file_info in files:
                    if file_info['size_kb'] == 0 or file_info['lines'] <= 1:
                        high_priority.append(file_info)
                    elif 'example' in file_info['path'].lower() or 'test' in file_info['path'].lower():
                        medium_priority.append(file_info)
                    else:
                        low_priority.append(file_info)
            
            # 高优先级清理
            if high_priority:
                md.extend([
                    "### 🔴 高优先级清理 (空文件/单行文件)\n",
                    f"**可立即删除**: {len(high_priority)}个文件\n",
                    "<details>",
                    "<summary>点击展开查看详细列表</summary>\n"
                ])
                
                for file_info in high_priority:
                    md.append(f"- `{file_info['path']}` ({file_info['size_kb']}KB, {file_info['lines']}行)")
                
                md.extend(["", "</details>\n"])
            
            # 按目录分类显示其他未使用文件
            for category, files in unused_categorized.items():
                if files:
                    # 过滤掉已在高优先级中显示的文件
                    filtered_files = [f for f in files if f not in high_priority]
                    if not filtered_files:
                        continue
                    
                    total_size = sum(f['size_kb'] for f in filtered_files)
                    total_lines = sum(f['lines'] for f in filtered_files)
                    
                    md.extend([
                        f"### 📂 {category.title()} ({len(filtered_files)}个文件, {total_size:.1f}KB, {total_lines}行)\n",
                        "<details>",
                        f"<summary>点击展开查看详细列表</summary>\n"
                    ])
                    
                    for file_info in filtered_files:
                        md.append(f"- `{file_info['path']}` ({file_info['size_kb']}KB, {file_info['lines']}行)")
                    
                    md.extend(["", "</details>\n"])
        
        # 测试文件详情
        if test_categorized:
            md.extend([
                f"## 🧪 测试文件\n",
                f"总计: {test_files_count}个文件 (所有测试文件都被视为已使用)\n"
            ])
            
            for category, files in test_categorized.items():
                if files:
                    total_size = sum(f['size_kb'] for f in files)
                    total_lines = sum(f['lines'] for f in files)
                    
                    md.extend([
                        f"### 📁 {category.title()} ({len(files)}个文件, {total_size:.1f}KB, {total_lines}行)\n",
                        "<details>",
                        f"<summary>点击展开查看详细列表</summary>\n"
                    ])
                    
                    for file_info in files:
                        md.append(f"- `{file_info['path']}` ({file_info['size_kb']}KB, {file_info['lines']}行)")
                    
                    md.extend(["", "</details>\n"])
        
        # 清理建议
        unused_size = sum(self._get_file_info(f)['size_kb'] for f in self.unused_files)
        unused_lines = sum(self._get_file_info(f)['lines'] for f in self.unused_files)
        
        md.extend([
            "## 💡 清理建议\n",
            f"### 📊 清理收益预估",
            f"- **可节省空间**: {unused_size:.1f}KB",
            f"- **可减少代码**: {unused_lines}行",
            f"- **减少文件数**: {unused_count}个",
            "",
            "### 🚀 建议的清理步骤",
            "",
            "#### 第一步: 安全清理 (立即执行)",
            "删除所有空文件和单行文件:",
            "```bash",
            "# 删除空文件和单行文件"
        ])
        
        for file_info in high_priority:
            md.append(f"rm \"{file_info['path']}\"")
        
        md.extend([
            "```",
            "",
            "#### 第二步: 确认清理 (需要验证)",
            "1. 检查示例文件是否还需要",
            "2. 确认重复组件哪个在使用",
            "3. 验证业务逻辑文件是否为未来功能",
            "",
            "#### 第三步: 验证构建",
            "```bash",
            "flutter analyze",
            "flutter test", 
            "flutter build apk --debug",
            "```",
            "",
            "### ⚠️ 注意事项",
            "- 清理前务必创建Git备份分支",
            "- 某些文件可能通过字符串路径动态引用",
            "- 部分文件可能是未来功能的预留代码",
            "- 性能优化相关文件可能是实验性功能",
            "",
            "---",
            "",
            f"**报告生成完成**: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}"
        ])
        
        return '\n'.join(md)

    def _categorize_excluded_files(self) -> Dict[str, List[Dict]]:
        """分类排除的文件"""
        categories = {
            'generated': [],
            'freezed': [],
            'config': [],
            'l10n': [],
            'auto_route': [],
            'part': [],
            'other': []
        }
        
        for file_path in sorted(self.excluded_files):
            file_info = self._get_file_info(file_path)
            file_str = str(file_path)
            
            if re.search(r'\.g\.dart$', file_str):
                categories['generated'].append(file_info)
            elif re.search(r'\.freezed\.dart$', file_str):
                categories['freezed'].append(file_info)
            elif re.search(r'\.config\.dart$', file_str):
                categories['config'].append(file_info)
            elif '/gen_l10n/' in file_str or '\\gen_l10n\\' in file_str:
                categories['l10n'].append(file_info)
            elif re.search(r'\.gr\.dart$', file_str):
                categories['auto_route'].append(file_info)
            elif re.search(r'\.part\.dart$', file_str):
                categories['part'].append(file_info)
            else:
                categories['other'].append(file_info)
        
        return {k: v for k, v in categories.items() if v}

def main():
    """主函数"""
    project_root = os.getcwd()
    
    generator = MarkdownReportGenerator(project_root)
    markdown_content = generator.generate_full_report()
    
    # 保存markdown报告
    report_file = Path(project_root) / "tools" / "reports" / "detailed_file_analysis_report.md"
    report_file.parent.mkdir(parents=True, exist_ok=True)
    
    with open(report_file, 'w', encoding='utf-8') as f:
        f.write(markdown_content)
    
    print(f"\n📄 详细markdown报告已生成: {report_file}")
    print(f"📊 报告包含所有文件的完整清单和分类")

if __name__ == "__main__":
    main() 