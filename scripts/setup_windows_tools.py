#!/usr/bin/env python3
"""
Windows开发工具配置脚本
自动检测并配置SignTool和MakeAppx到PATH环境变量
"""

import os
import sys
import subprocess
from pathlib import Path

def find_windows_sdk_tools():
    """查找Windows SDK工具路径"""
    tools = {}
    
    # 可能的SDK路径
    sdk_base_paths = [
        Path("C:/Program Files (x86)/Windows Kits/10/bin"),
        Path("C:/Program Files/Windows Kits/10/bin"),
    ]
    
    for sdk_base in sdk_base_paths:
        if not sdk_base.exists():
            continue
            
        # 查找版本目录
        for version_dir in sdk_base.iterdir():
            if version_dir.is_dir() and version_dir.name.startswith("10.0."):
                x64_dir = version_dir / "x64"
                if x64_dir.exists():
                    signtool = x64_dir / "signtool.exe"
                    makeappx = x64_dir / "makeappx.exe"
                    
                    if signtool.exists() and makeappx.exists():
                        tools['sdk_path'] = str(x64_dir)
                        tools['signtool'] = str(signtool)
                        tools['makeappx'] = str(makeappx)
                        tools['version'] = version_dir.name
                        break
        
        if tools:
            break
    
    # 额外检查App Certification Kit中的signtool
    cert_kit_path = Path("C:/Program Files (x86)/Windows Kits/10/App Certification Kit/signtool.exe")
    if cert_kit_path.exists():
        tools['cert_kit_signtool'] = str(cert_kit_path)
    
    return tools

def check_current_path():
    """检查当前PATH中是否已包含工具"""
    try:
        subprocess.run(['signtool'], capture_output=True, check=True)
        signtool_in_path = True
    except (subprocess.CalledProcessError, FileNotFoundError):
        signtool_in_path = False
        
    try:
        subprocess.run(['makeappx'], capture_output=True, check=True)
        makeappx_in_path = True
    except (subprocess.CalledProcessError, FileNotFoundError):
        makeappx_in_path = False
        
    return signtool_in_path, makeappx_in_path

def generate_path_setup_script(sdk_path):
    """生成PATH设置脚本"""
    
    # PowerShell脚本
    ps_script = f'''# Windows SDK工具PATH配置脚本
# 以管理员身份运行PowerShell，然后执行此脚本

# 获取当前系统PATH
$currentPath = [Environment]::GetEnvironmentVariable("Path", "Machine")

# 要添加的路径
$newPath = "{sdk_path}"

# 检查路径是否已存在
if ($currentPath -notlike "*$newPath*") {{
    # 添加新路径
    $updatedPath = $currentPath + ";" + $newPath
    [Environment]::SetEnvironmentVariable("Path", $updatedPath, "Machine")
    Write-Host "✅ 已添加 Windows SDK 工具到系统PATH: $newPath" -ForegroundColor Green
    Write-Host "⚠️ 请重启PowerShell/命令提示符使设置生效" -ForegroundColor Yellow
}} else {{
    Write-Host "ℹ️ Windows SDK 工具路径已存在于PATH中" -ForegroundColor Blue
}}

# 验证工具是否可用
Write-Host "`n🔍 验证工具可用性..."
try {{
    & signtool
    Write-Host "✅ SignTool 可用" -ForegroundColor Green
}} catch {{
    Write-Host "❌ SignTool 不可用" -ForegroundColor Red
}}

try {{
    & makeappx
    Write-Host "✅ MakeAppx 可用" -ForegroundColor Green
}} catch {{
    Write-Host "❌ MakeAppx 不可用" -ForegroundColor Red
}}
'''
    
    # 批处理脚本
    bat_script = f'''@echo off
echo Windows SDK工具PATH配置脚本
echo 正在添加Windows SDK工具到系统PATH...

:: 检查管理员权限
net session >nul 2>&1
if %errorLevel% == 0 (
    echo [OK] 检测到管理员权限
) else (
    echo [ERROR] 需要管理员权限！
    echo 请以管理员身份运行此脚本
    pause
    exit /b 1
)

:: 添加到系统PATH
setx PATH "%PATH%;{sdk_path}" /M

echo [OK] 已添加 Windows SDK 工具到系统PATH
echo [WARNING] 请重启命令提示符使设置生效
echo.
echo [INFO] 验证工具...
signtool >nul 2>&1 && echo [OK] SignTool 可用 || echo [ERROR] SignTool 需要重启生效
makeappx >nul 2>&1 && echo [OK] MakeAppx 可用 || echo [ERROR] MakeAppx 需要重启生效

pause
'''
    
    return ps_script, bat_script

def main():
    print("🔍 Windows SDK工具配置助手")
    print("=" * 50)
    
    # 检查当前状态
    print("📋 检查当前工具状态...")
    signtool_in_path, makeappx_in_path = check_current_path()
    
    if signtool_in_path and makeappx_in_path:
        print("✅ SignTool和MakeAppx都已在PATH中可用")
        return
    
    print(f"SignTool在PATH中: {'✅' if signtool_in_path else '❌'}")
    print(f"MakeAppx在PATH中: {'✅' if makeappx_in_path else '❌'}")
    
    # 查找工具
    print("\\n🔍 查找Windows SDK工具...")
    tools = find_windows_sdk_tools()
    
    if not tools:
        print("❌ 未找到Windows SDK工具")
        print("请安装Windows 10/11 SDK")
        return
    
    print(f"✅ 找到Windows SDK {tools['version']}")
    print(f"   路径: {tools['sdk_path']}")
    print(f"   SignTool: {tools['signtool']}")
    print(f"   MakeAppx: {tools['makeappx']}")
    
    # 生成配置脚本
    print("\\n📝 生成配置脚本...")
    ps_script, bat_script = generate_path_setup_script(tools['sdk_path'])
    
    # 保存脚本
    scripts_dir = Path(__file__).parent
    ps_file = scripts_dir / "setup_windows_sdk_path.ps1"
    bat_file = scripts_dir / "setup_windows_sdk_path.bat"
    
    with open(ps_file, 'w', encoding='utf-8') as f:
        f.write(ps_script)
    
    with open(bat_file, 'w', encoding='utf-8') as f:  # 使用UTF-8编码
        f.write(bat_script)
    
    print(f"✅ 已生成配置脚本:")
    print(f"   PowerShell: {ps_file}")
    print(f"   批处理: {bat_file}")
    
    print("\\n🚀 使用方法:")
    print("方法1 - PowerShell (推荐):")
    print("   1. 以管理员身份运行PowerShell")
    print("   2. 执行: Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser")
    print(f"   3. 执行: & '{ps_file}'")
    
    print("\\n方法2 - 批处理:")
    print("   1. 右键点击setup_windows_sdk_path.bat")
    print("   2. 选择'以管理员身份运行'")
    
    print("\\n方法3 - 手动添加:")
    print("   1. Win+R → sysdm.cpl → 高级 → 环境变量")
    print("   2. 编辑系统变量中的Path")
    print(f"   3. 添加: {tools['sdk_path']}")
    
    print("\\n⚠️ 设置完成后请重启PowerShell/命令提示符")

if __name__ == "__main__":
    main() 