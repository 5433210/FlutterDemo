#!/usr/bin/env python3
"""
Android开发环境配置脚本
自动检测并配置Android SDK环境变量
"""

import os
import sys
import subprocess
from pathlib import Path

def find_android_sdk():
    """查找Android SDK路径"""
    # 检查环境变量
    android_home = os.environ.get('ANDROID_HOME') or os.environ.get('ANDROID_SDK_ROOT')
    if android_home and Path(android_home).exists():
        return android_home
    
    # 常见的Android SDK安装路径
    potential_paths = [
        Path.home() / "AppData" / "Local" / "Android" / "Sdk",
        Path("C:/Android/Sdk"),
        Path("C:/Users") / os.environ.get('USERNAME', '') / "AppData" / "Local" / "Android" / "Sdk",
        Path.home() / "Android" / "Sdk",
    ]
    
    for path in potential_paths:
        if path.exists() and (path / "platform-tools").exists():
            return str(path)
    
    return None

def check_android_components(sdk_path):
    """检查Android SDK组件"""
    sdk = Path(sdk_path)
    components = {}
    
    # Platform Tools
    platform_tools = sdk / "platform-tools"
    components['platform_tools'] = platform_tools.exists()
    
    # Build Tools
    build_tools = sdk / "build-tools"
    if build_tools.exists():
        versions = [d.name for d in build_tools.iterdir() if d.is_dir()]
        components['build_tools'] = sorted(versions) if versions else []
    else:
        components['build_tools'] = []
    
    # Platforms
    platforms = sdk / "platforms"
    if platforms.exists():
        versions = [d.name for d in platforms.iterdir() if d.is_dir()]
        components['platforms'] = sorted(versions) if versions else []
    else:
        components['platforms'] = []
    
    # NDK
    ndk = sdk / "ndk"
    if ndk.exists():
        versions = [d.name for d in ndk.iterdir() if d.is_dir()]
        components['ndk'] = sorted(versions) if versions else []
    else:
        components['ndk'] = []
    
    return components

def generate_env_setup_script(sdk_path):
    """生成环境变量设置脚本"""
    
    # PowerShell脚本
    ps_script = f'''# Android SDK环境变量配置脚本
# 以管理员身份运行PowerShell，然后执行此脚本

# Android SDK路径
$androidSdkPath = "{sdk_path}"

# 设置ANDROID_HOME环境变量
[Environment]::SetEnvironmentVariable("ANDROID_HOME", $androidSdkPath, "Machine")
[Environment]::SetEnvironmentVariable("ANDROID_SDK_ROOT", $androidSdkPath, "Machine")

# 获取当前系统PATH
$currentPath = [Environment]::GetEnvironmentVariable("Path", "Machine")

# 要添加的路径
$platformToolsPath = "$androidSdkPath\\platform-tools"
$cmdlineToolsPath = "$androidSdkPath\\cmdline-tools\\latest\\bin"

# 添加platform-tools到PATH
if ($currentPath -notlike "*$platformToolsPath*") {{
    $updatedPath = $currentPath + ";" + $platformToolsPath
    [Environment]::SetEnvironmentVariable("Path", $updatedPath, "Machine")
    Write-Host "✅ 已添加 platform-tools 到PATH: $platformToolsPath" -ForegroundColor Green
}} else {{
    Write-Host "ℹ️ platform-tools 已存在于PATH中" -ForegroundColor Blue
}}

# 添加cmdline-tools到PATH
if (Test-Path $cmdlineToolsPath) {{
    if ($currentPath -notlike "*$cmdlineToolsPath*") {{
        $updatedPath = [Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + $cmdlineToolsPath
        [Environment]::SetEnvironmentVariable("Path", $updatedPath, "Machine")
        Write-Host "✅ 已添加 cmdline-tools 到PATH: $cmdlineToolsPath" -ForegroundColor Green
    }} else {{
        Write-Host "ℹ️ cmdline-tools 已存在于PATH中" -ForegroundColor Blue
    }}
}}

Write-Host "✅ Android SDK环境变量配置完成" -ForegroundColor Green
Write-Host "⚠️ 请重启PowerShell/命令提示符使设置生效" -ForegroundColor Yellow

# 验证设置
Write-Host "`n🔍 验证环境变量..."
Write-Host "ANDROID_HOME: $([Environment]::GetEnvironmentVariable('ANDROID_HOME', 'Machine'))"
Write-Host "ANDROID_SDK_ROOT: $([Environment]::GetEnvironmentVariable('ANDROID_SDK_ROOT', 'Machine'))"

# 验证工具可用性
Write-Host "`n🔍 验证工具可用性..."
try {{
    & "$platformToolsPath\\adb.exe" version
    Write-Host "✅ ADB 可用" -ForegroundColor Green
}} catch {{
    Write-Host "❌ ADB 不可用，请重启后再试" -ForegroundColor Red
}}
'''

    # 批处理脚本
    bat_script = f'''@echo off
echo Android SDK环境变量配置脚本
echo 正在配置Android SDK环境变量...

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

:: 设置Android SDK环境变量
setx ANDROID_HOME "{sdk_path}" /M
setx ANDROID_SDK_ROOT "{sdk_path}" /M

:: 添加到系统PATH
setx PATH "%PATH%;{sdk_path}\\platform-tools" /M

echo [OK] Android SDK环境变量配置完成
echo [WARNING] 请重启命令提示符使设置生效
echo.
echo [INFO] 验证环境变量:
echo ANDROID_HOME: {sdk_path}
echo.
echo [INFO] 验证工具...
"{sdk_path}\\platform-tools\\adb.exe" version >nul 2>&1 && echo [OK] ADB 可用 || echo [ERROR] ADB 需要重启生效

pause
'''
    
    return ps_script, bat_script

def main():
    print("🔍 Android SDK环境配置助手")
    print("=" * 50)
    
    # 查找Android SDK
    print("📋 查找Android SDK...")
    sdk_path = find_android_sdk()
    
    if not sdk_path:
        print("❌ 未找到Android SDK")
        print("请先安装Android Studio或Android SDK")
        return
    
    print(f"✅ 找到Android SDK: {sdk_path}")
    
    # 检查组件
    print("\\n🔍 检查Android SDK组件...")
    components = check_android_components(sdk_path)
    
    if components['platform_tools']:
        print("✅ Platform Tools: 可用")
    else:
        print("❌ Platform Tools: 未找到")
    
    if components['build_tools']:
        latest_build_tools = components['build_tools'][-1]
        print(f"✅ Build Tools: {latest_build_tools} (共{len(components['build_tools'])}个版本)")
    else:
        print("❌ Build Tools: 未找到")
    
    if components['platforms']:
        latest_platform = components['platforms'][-1]
        print(f"✅ Android Platforms: {latest_platform} (共{len(components['platforms'])}个版本)")
    else:
        print("❌ Android Platforms: 未找到")
    
    if components['ndk']:
        latest_ndk = components['ndk'][-1]
        print(f"✅ Android NDK: {latest_ndk} (共{len(components['ndk'])}个版本)")
    else:
        print("ℹ️ Android NDK: 未安装 (Flutter开发非必需)")
    
    # 检查环境变量
    current_android_home = os.environ.get('ANDROID_HOME')
    if current_android_home:
        if current_android_home == sdk_path:
            print(f"\\n✅ ANDROID_HOME已正确设置: {current_android_home}")
            print("Android环境已配置完成！")
            return
        else:
            print(f"\\n⚠️ ANDROID_HOME设置不正确:")
            print(f"   当前值: {current_android_home}")
            print(f"   应该是: {sdk_path}")
    else:
        print("\\n❌ ANDROID_HOME环境变量未设置")
    
    # 生成配置脚本
    print("\\n📝 生成环境配置脚本...")
    ps_script, bat_script = generate_env_setup_script(sdk_path)
    
    # 保存脚本
    scripts_dir = Path(__file__).parent
    ps_file = scripts_dir / "setup_android_env.ps1"
    bat_file = scripts_dir / "setup_android_env.bat"
    
    with open(ps_file, 'w', encoding='utf-8') as f:
        f.write(ps_script)
    
    with open(bat_file, 'w', encoding='utf-8') as f:
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
    print("   1. 右键点击setup_android_env.bat")
    print("   2. 选择'以管理员身份运行'")
    
    print("\\n方法3 - 手动设置:")
    print("   1. Win+R → sysdm.cpl → 高级 → 环境变量")
    print("   2. 新建系统变量:")
    print(f"      ANDROID_HOME = {sdk_path}")
    print(f"      ANDROID_SDK_ROOT = {sdk_path}")
    print("   3. 编辑系统PATH，添加:")
    print(f"      {sdk_path}\\platform-tools")
    
    print("\\n⚠️ 设置完成后请重启PowerShell/命令提示符")

if __name__ == "__main__":
    main() 