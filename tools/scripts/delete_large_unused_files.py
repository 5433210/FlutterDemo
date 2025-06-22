#!/usr/bin/env python3
"""
删除第三类（大文件）未使用文件
基于分析报告中size_kb >= 1.0的文件
"""

import os
import json
from pathlib import Path

def get_large_unused_files():
    """从分析报告中获取大文件列表"""
    project_root = Path.cwd()
    report_file = project_root / 'tools/reports/unused_code_report.json'
    
    if not report_file.exists():
        print("❌ 未找到分析报告文件")
        return []
    
    # 读取分析报告
    with open(report_file, 'r', encoding='utf-8') as f:
        report = json.load(f)
    
    # 筛选大文件 (>= 1.0KB)
    large_files = []
    for file_info in report.get('unused_files', []):
        if file_info.get('size_kb', 0) >= 1.0:
            large_files.append(file_info)
    
    return large_files

def delete_large_unused_files():
    """删除大型未使用文件"""
    project_root = Path.cwd()
    large_files = get_large_unused_files()
    
    if not large_files:
        print("❌ 没有找到大文件列表")
        return
    
    deleted_count = 0
    not_found_count = 0
    error_count = 0
    total_size_saved = 0
    total_lines_saved = 0
    
    print("=" * 80)
    print("🗑️  开始删除第三类：大文件（未使用）")
    print("=" * 80)
    print(f"📊 计划删除: {len(large_files)} 个大文件")
    print()
    
    # 按文件大小排序，先删除小的再删除大的
    large_files.sort(key=lambda x: x.get('size_kb', 0))
    
    for i, file_info in enumerate(large_files, 1):
        file_path = file_info.get('path', '')
        size_kb = file_info.get('size_kb', 0)
        lines = file_info.get('lines', 0)
        
        print(f"   {i:2d}. {file_path}")
        print(f"       📏 大小: {size_kb:.1f}KB, 行数: {lines}")
        
        full_path = project_root / file_path
        
        if full_path.exists():
            try:
                # 再次确认文件大小
                actual_size = full_path.stat().st_size
                actual_size_kb = actual_size / 1024
                
                if actual_size_kb < 1.0:
                    print(f"       ⚠️  跳过小文件 (实际: {actual_size_kb:.1f}KB)")
                    continue
                
                full_path.unlink()
                print(f"       ✓ 已删除")
                deleted_count += 1
                total_size_saved += size_kb
                total_lines_saved += lines
                
            except Exception as e:
                print(f"       ✗ 删除失败: {e}")
                error_count += 1
        else:
            print(f"       - 文件不存在")
            not_found_count += 1
        
        # 每删除10个文件暂停一下
        if i % 10 == 0:
            print(f"       ... 已处理 {i}/{len(large_files)} 个文件")
            print()
    
    print()
    print("=" * 80)
    print("📊 删除统计")
    print("=" * 80)
    print(f"✅ 成功删除: {deleted_count} 个文件")
    print(f"❌ 删除失败: {error_count} 个文件")
    print(f"🔍 文件不存在: {not_found_count} 个文件")
    print(f"📋 总计处理: {deleted_count + error_count + not_found_count} 个文件")
    print()
    print(f"💾 节省空间: {total_size_saved:.1f}KB ({total_size_saved/1024:.1f}MB)")
    print(f"📄 节省代码: {total_lines_saved:,} 行")
    
    if deleted_count > 0:
        print()
        print("💡 建议下一步操作:")
        print("   1. 运行 flutter clean")
        print("   2. 运行 flutter pub get")
        print("   3. 运行 flutter analyze 检查是否有问题")
        print("   4. 运行测试确保应用正常工作")
        print("   5. 如果有问题，使用 git checkout 恢复特定文件")
    
    # 清理空目录
    print()
    print("🧹 清理空目录...")
    _clean_empty_directories(project_root / 'lib')
    
    # 生成删除报告
    _generate_deletion_report(large_files, deleted_count, total_size_saved, total_lines_saved)

def _clean_empty_directories(root_dir):
    """清理空目录"""
    cleaned = 0
    
    # 递归查找空目录（从最深层开始）
    for dirpath, dirnames, filenames in os.walk(root_dir, topdown=False):
        if not dirnames and not filenames:  # 空目录
            try:
                os.rmdir(dirpath)
                rel_path = Path(dirpath).relative_to(Path.cwd())
                print(f"   🗂️  清理空目录: {rel_path}")
                cleaned += 1
            except:
                pass
    
    if cleaned > 0:
        print(f"   ✅ 清理了 {cleaned} 个空目录")
    else:
        print("   📁 没有发现空目录")

def _generate_deletion_report(large_files, deleted_count, total_size_saved, total_lines_saved):
    """生成删除报告"""
    project_root = Path.cwd()
    report_file = project_root / 'tools/reports/large_files_deletion_report.md'
    
    with open(report_file, 'w', encoding='utf-8') as f:
        f.write("# 第三类大文件删除报告\n\n")
        f.write(f"## 删除统计\n\n")
        f.write(f"- **成功删除**: {deleted_count} 个文件\n")
        f.write(f"- **节省空间**: {total_size_saved:.1f}KB ({total_size_saved/1024:.1f}MB)\n")
        f.write(f"- **节省代码**: {total_lines_saved:,} 行\n\n")
        
        f.write("## 已删除文件清单\n\n")
        deleted_files = [f for f in large_files if not (Path.cwd() / f.get('path', '')).exists()]
        
        for i, file_info in enumerate(deleted_files, 1):
            f.write(f"{i}. `{file_info.get('path', '')}` ({file_info.get('size_kb', 0):.1f}KB)\n")
        
        f.write(f"\n## 总计删除进度\n\n")
        f.write(f"第一类（空文件）: 6 个 ✅\n")
        f.write(f"第二类（小文件）: 16 个 ✅\n")
        f.write(f"第三类（大文件）: {deleted_count} 个 ✅\n")
        f.write(f"\n**总计删除**: {22 + deleted_count} 个文件\n")
    
    print(f"📄 删除报告已生成: {report_file}")

if __name__ == "__main__":
    delete_large_unused_files() 