#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
构建号更新脚本
实现构建号自动递增机制
"""

import os
import sys
import json
import yaml
import argparse
from pathlib import Path
from datetime import datetime

class BuildNumberUpdater:
    """构建号更新器"""
    
    def __init__(self, project_root=None):
        """初始化构建号更新器
        
        Args:
            project_root: 项目根目录路径
        """
        self.project_root = Path(project_root) if project_root else Path(__file__).parent.parent
        self.version_config_file = self.project_root / 'version.yaml'
        self.history_file = self.project_root / 'build_history.json'
        
    def load_version_config(self):
        """加载版本配置文件"""
        try:
            with open(self.version_config_file, 'r', encoding='utf-8') as f:
                return yaml.safe_load(f)
        except FileNotFoundError:
            print(f"错误: 版本配置文件不存在: {self.version_config_file}")
            return None
        except yaml.YAMLError as e:
            print(f"错误: 解析版本配置文件失败: {e}")
            return None
    
    def save_version_config(self, config):
        """保存版本配置文件"""
        try:
            with open(self.version_config_file, 'w', encoding='utf-8') as f:
                yaml.dump(config, f, default_flow_style=False, allow_unicode=True)
            return True
        except Exception as e:
            print(f"错误: 保存版本配置文件失败: {e}")
            return False
    
    def load_build_history(self):
        """加载构建历史"""
        try:
            if self.history_file.exists():
                with open(self.history_file, 'r', encoding='utf-8') as f:
                    return json.load(f)
            else:
                return {'builds': []}
        except Exception as e:
            print(f"警告: 加载构建历史失败: {e}")
            return {'builds': []}
    
    def save_build_history(self, history):
        """保存构建历史"""
        try:
            with open(self.history_file, 'w', encoding='utf-8') as f:
                json.dump(history, f, indent=2, ensure_ascii=False)
            return True
        except Exception as e:
            print(f"警告: 保存构建历史失败: {e}")
            return False
    
    def generate_build_number(self, strategy='auto'):
        """生成构建号
        
        Args:
            strategy: 构建号生成策略
                - 'auto': 自动生成（YYYYMMDDXXX格式）
                - 'increment': 基于上次构建号递增
                - 'timestamp': 基于时间戳
        
        Returns:
            str: 新的构建号
        """
        if strategy == 'auto':
            # YYYYMMDDXXX格式
            now = datetime.now()
            date_part = now.strftime('%Y%m%d')
            
            # 查找当天已有的构建号
            history = self.load_build_history()
            today_builds = [
                build for build in history.get('builds', [])
                if build.get('build_number', '').startswith(date_part)
            ]
            
            if today_builds:
                # 获取当天最大的序号
                max_seq = 0
                for build in today_builds:
                    build_num = build.get('build_number', '')
                    if len(build_num) >= 11:
                        try:
                            seq = int(build_num[-3:])
                            max_seq = max(max_seq, seq)
                        except ValueError:
                            continue
                next_seq = max_seq + 1
            else:
                next_seq = 1
                
            return f"{date_part}{next_seq:03d}"
            
        elif strategy == 'increment':
            # 基于上次构建号递增
            history = self.load_build_history()
            builds = history.get('builds', [])
            
            if builds:
                last_build = builds[-1]
                last_build_num = last_build.get('build_number', '20250620001')
                try:
                    return str(int(last_build_num) + 1)
                except ValueError:
                    # 如果解析失败，回退到auto策略
                    return self.generate_build_number('auto')
            else:
                return self.generate_build_number('auto')
                
        elif strategy == 'timestamp':
            # 基于时间戳
            return str(int(datetime.now().timestamp()))
            
        else:
            raise ValueError(f"不支持的构建号生成策略: {strategy}")
    
    def update_build_number(self, new_build_number=None, strategy='auto'):
        """更新构建号
        
        Args:
            new_build_number: 指定的新构建号，如果为None则自动生成
            strategy: 构建号生成策略
            
        Returns:
            tuple: (是否成功, 新构建号)
        """
        config = self.load_version_config()
        if not config:
            return False, None
            
        # 获取当前构建号
        current_build = config.get('version', {}).get('build', '20250620001')
        
        # 生成或使用指定的新构建号
        if new_build_number:
            build_number = str(new_build_number)
        else:
            build_number = self.generate_build_number(strategy)
        
        # 更新配置
        if 'version' not in config:
            config['version'] = {}
        config['version']['build'] = build_number
        
        # 保存配置
        if not self.save_version_config(config):
            return False, None
        
        # 记录构建历史
        history = self.load_build_history()
        build_record = {
            'build_number': build_number,
            'previous_build': current_build,
            'timestamp': datetime.now().isoformat(),
            'strategy': strategy
        }
        history['builds'].append(build_record)
        
        # 保持历史记录不超过100条
        if len(history['builds']) > 100:
            history['builds'] = history['builds'][-100:]
        
        self.save_build_history(history)
        
        print(f"√ 构建号已更新: {current_build} -> {build_number}")
        return True, build_number
    
    def rollback_build_number(self, steps=1):
        """回滚构建号
        
        Args:
            steps: 回滚步数，默认回滚1步
            
        Returns:
            tuple: (是否成功, 回滚后的构建号)
        """
        history = self.load_build_history()
        builds = history.get('builds', [])
        
        if len(builds) < steps:
            print(f"错误: 构建历史不足，无法回滚 {steps} 步")
            return False, None
        
        # 获取回滚目标
        target_build = builds[-(steps + 1)]
        target_build_number = target_build['build_number']
        
        # 更新配置
        config = self.load_version_config()
        if not config:
            return False, None
            
        if 'version' not in config:
            config['version'] = {}
        config['version']['build'] = target_build_number
        
        if not self.save_version_config(config):
            return False, None
        
        # 更新历史记录（移除回滚的记录）
        history['builds'] = builds[:-steps]
        self.save_build_history(history)
        
        print(f"√ 构建号已回滚 {steps} 步: -> {target_build_number}")
        return True, target_build_number
    
    def show_build_history(self, limit=10):
        """显示构建历史
        
        Args:
            limit: 显示的记录数量限制
        """
        history = self.load_build_history()
        builds = history.get('builds', [])
        
        if not builds:
            print("没有构建历史记录")
            return
        
        print(f"最近 {min(limit, len(builds))} 次构建历史:")
        print("-" * 80)
        print(f"{'序号':<4} {'构建号':<12} {'时间':<20} {'策略':<10} {'前一版本':<12}")
        print("-" * 80)
        
        for i, build in enumerate(builds[-limit:], 1):
            timestamp = build.get('timestamp', '')
            if timestamp:
                try:
                    dt = datetime.fromisoformat(timestamp.replace('Z', '+00:00'))
                    time_str = dt.strftime('%Y-%m-%d %H:%M')
                except:
                    time_str = timestamp[:16]
            else:
                time_str = 'Unknown'
                
            print(f"{i:<4} {build.get('build_number', ''):<12} {time_str:<20} "
                  f"{build.get('strategy', 'unknown'):<10} {build.get('previous_build', ''):<12}")
    
    def get_current_build_info(self):
        """获取当前构建信息"""
        config = self.load_version_config()
        if not config:
            return None
            
        version = config.get('version', {})
        return {
            'major': version.get('major', 1),
            'minor': version.get('minor', 0),
            'patch': version.get('patch', 0),
            'build': version.get('build', '20250620001'),
            'prerelease': version.get('prerelease', '')
        }


def main():
    """主函数"""
    parser = argparse.ArgumentParser(description='构建号更新脚本')
    parser.add_argument('--project-root', help='项目根目录')
    parser.add_argument('--strategy', choices=['auto', 'increment', 'timestamp'], 
                       default='auto', help='构建号生成策略')
    parser.add_argument('--build-number', help='手动指定构建号')
    parser.add_argument('--rollback', type=int, help='回滚构建号，指定回滚步数')
    parser.add_argument('--history', action='store_true', help='显示构建历史')
    parser.add_argument('--history-limit', type=int, default=10, help='历史记录显示数量')
    parser.add_argument('--info', action='store_true', help='显示当前构建信息')
    
    args = parser.parse_args()
    
    # 初始化更新器
    updater = BuildNumberUpdater(args.project_root)
    
    # 处理不同的操作
    if args.info:
        # 显示当前构建信息
        info = updater.get_current_build_info()
        if info:
            print("当前版本信息:")
            print(f"  版本号: {info['major']}.{info['minor']}.{info['patch']}")
            if info['prerelease']:
                print(f"  预发布: {info['prerelease']}")
            print(f"  构建号: {info['build']}")
        else:
            print("无法获取版本信息")
            sys.exit(1)
            
    elif args.history:
        # 显示构建历史
        updater.show_build_history(args.history_limit)
        
    elif args.rollback:
        # 回滚构建号
        success, build_number = updater.rollback_build_number(args.rollback)
        if not success:
            sys.exit(1)
            
    else:
        # 更新构建号
        success, build_number = updater.update_build_number(
            args.build_number, args.strategy
        )
        if not success:
            sys.exit(1)
            
        # 调用版本生成脚本更新所有平台
        try:
            import subprocess
            script_path = Path(__file__).parent / 'generate_version_info.py'
            result = subprocess.run([
                sys.executable, str(script_path)
            ], capture_output=True, text=True, cwd=updater.project_root)
            
            if result.returncode == 0:
                print("√ 所有平台版本信息已同步更新")
            else:
                print("警告: 平台版本同步更新失败")
                print(result.stderr)
        except Exception as e:
            print(f"警告: 无法调用版本生成脚本: {e}")


if __name__ == '__main__':
    main() 