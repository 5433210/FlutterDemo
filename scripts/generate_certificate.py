#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
字字珠玑 - MSIX 证书生成工具
为 MSIX 包生成自签名证书
"""

import os
import sys
import subprocess
from pathlib import Path
import yaml

class CertificateGenerator:
    """证书生成器"""
    
    def __init__(self):
        self.project_root = Path(__file__).parent.parent
        self.cert_dir = self.project_root / 'package' / 'windows' / 'msix'
        self.pubspec_file = self.project_root / 'pubspec.yaml'
        
    def load_msix_config(self):
        """加载 MSIX 配置"""
        try:
            with open(self.pubspec_file, 'r', encoding='utf-8') as f:
                config = yaml.safe_load(f)
                return config.get('msix_config', {})
        except Exception as e:
            print(f"❌ 读取 pubspec.yaml 失败: {e}")
            return None
    
    def generate_certificate(self):
        """生成新的自签名证书"""
        msix_config = self.load_msix_config()
        if not msix_config:
            return False
        
        # 从配置中获取信息
        publisher = msix_config.get('publisher', 'CN=DefaultPublisher')
        app_name = msix_config.get('display_name', 'MyApp')
        
        print(f"🔐 生成 MSIX 签名证书...")
        print(f"📋 发布者: {publisher}")
        print(f"📋 应用名称: {app_name}")
        print("="*60)
        
        # 确保证书目录存在
        self.cert_dir.mkdir(parents=True, exist_ok=True)
        
        # 证书文件路径
        cert_name = "CharAsGem"
        pfx_path = self.cert_dir / f"{cert_name}.pfx"
        cer_path = self.cert_dir / f"{cert_name}.cer"
        
        # 备份旧证书（如果存在）
        if pfx_path.exists():
            backup_pfx = self.cert_dir / f"{cert_name}_backup.pfx"
            pfx_path.rename(backup_pfx)
            print(f"📦 已备份旧证书: {backup_pfx}")
        
        if cer_path.exists():
            backup_cer = self.cert_dir / f"{cert_name}_backup.cer"
            cer_path.rename(backup_cer)
            print(f"📦 已备份旧证书: {backup_cer}")
        
        # 生成证书的 PowerShell 命令
        powershell_script = f'''
# 生成自签名证书
$cert = New-SelfSignedCertificate `
    -Type Custom `
    -Subject "{publisher}" `
    -KeyUsage DigitalSignature `
    -FriendlyName "{app_name} Certificate" `
    -CertStoreLocation "Cert:\\CurrentUser\\My" `
    -TextExtension @("2.5.29.37={{text}}1.3.6.1.5.5.7.3.3", "2.5.29.19={{text}}") `
    -NotAfter (Get-Date).AddYears(3)

# 导出为 PFX 文件（包含私钥）
$password = ConvertTo-SecureString -String "password" -Force -AsPlainText
Export-PfxCertificate -Cert $cert -FilePath "{pfx_path}" -Password $password

# 导出为 CER 文件（公钥）
Export-Certificate -Cert $cert -FilePath "{cer_path}"

# 从个人存储中删除证书（可选）
Remove-Item -Path "Cert:\\CurrentUser\\My\\$($cert.Thumbprint)" -Force

Write-Host "✅ 证书生成完成!"
Write-Host "📂 PFX 文件: {pfx_path}"
Write-Host "📂 CER 文件: {cer_path}"
Write-Host "🔑 密码: password"
'''
        
        try:
            # 执行 PowerShell 脚本
            print("🔄 正在生成证书...")
            result = subprocess.run([
                'powershell', '-ExecutionPolicy', 'Bypass', '-Command', powershell_script
            ], capture_output=True, text=True, cwd=self.project_root)
            
            if result.returncode == 0:
                print("✅ 证书生成成功!")
                print(f"📂 PFX 文件: {pfx_path}")
                print(f"📂 CER 文件: {cer_path}")
                print(f"🔑 密码: password")
                
                # 验证文件是否存在
                if pfx_path.exists() and cer_path.exists():
                    print("\n📋 证书文件验证:")
                    print(f"✅ PFX 文件大小: {pfx_path.stat().st_size} 字节")
                    print(f"✅ CER 文件大小: {cer_path.stat().st_size} 字节")
                    
                    # 显示证书信息
                    self.show_certificate_info(pfx_path)
                    
                    return True
                else:
                    print("❌ 证书文件生成失败")
                    return False
            else:
                print("❌ 证书生成失败!")
                print(f"错误信息: {result.stderr}")
                return False
                
        except Exception as e:
            print(f"❌ 证书生成过程出错: {e}")
            return False
    
    def show_certificate_info(self, pfx_path):
        """显示证书信息"""
        try:
            print("\n🔍 证书信息:")
            result = subprocess.run([
                'powershell', '-Command', 
                f'Get-PfxCertificate -FilePath "{pfx_path}" | Select-Object Subject, Issuer, NotAfter, Thumbprint | Format-List'
            ], capture_output=True, text=True)
            
            if result.returncode == 0:
                print(result.stdout)
            else:
                print("⚠️ 无法读取证书信息")
                
        except Exception as e:
            print(f"⚠️ 读取证书信息失败: {e}")
    
    def install_certificate(self):
        """安装证书到受信任的根证书颁发机构"""
        cer_path = self.cert_dir / "CharAsGem.cer"
        
        if not cer_path.exists():
            print("❌ 证书文件不存在，请先生成证书")
            return False
        
        print("🔐 安装证书到受信任的根证书颁发机构...")
        print("⚠️ 这需要管理员权限")
        
        try:
            # 使用 certlm.msc 或 PowerShell 安装证书
            powershell_script = f'''
# 安装证书到受信任的根证书颁发机构
Import-Certificate -FilePath "{cer_path}" -CertStoreLocation Cert:\\LocalMachine\\Root
Write-Host "✅ 证书已安装到受信任的根证书颁发机构"
'''
            
            result = subprocess.run([
                'powershell', '-ExecutionPolicy', 'Bypass', '-Command', powershell_script
            ], capture_output=True, text=True)
            
            if result.returncode == 0:
                print("✅ 证书安装成功!")
                print("💡 现在可以正常安装 MSIX 包了")
                return True
            else:
                print("❌ 证书安装失败!")
                print(f"错误信息: {result.stderr}")
                print("\n💡 手动安装方法:")
                print(f"1. 双击 {cer_path}")
                print("2. 点击 '安装证书'")
                print("3. 选择 '本地计算机'")
                print("4. 选择 '将所有的证书都放入下列存储'")
                print("5. 浏览并选择 '受信任的根证书颁发机构'")
                print("6. 点击 '确定' 完成安装")
                return False
                
        except Exception as e:
            print(f"❌ 证书安装过程出错: {e}")
            return False

def main():
    """主函数"""
    import argparse
    
    parser = argparse.ArgumentParser(description='字字珠玑 MSIX 证书生成工具')
    parser.add_argument('--generate', action='store_true', help='生成新证书')
    parser.add_argument('--install', action='store_true', help='安装证书到系统')
    parser.add_argument('--all', action='store_true', help='生成并安装证书')
    
    args = parser.parse_args()
    
    generator = CertificateGenerator()
    
    if args.all:
        # 生成并安装证书
        if generator.generate_certificate():
            print("\n" + "="*60)
            generator.install_certificate()
    elif args.generate:
        # 只生成证书
        generator.generate_certificate()
    elif args.install:
        # 只安装证书
        generator.install_certificate()
    else:
        # 交互式菜单
        print("🔐 字字珠玑 - MSIX 证书管理工具")
        print("="*60)
        print("1. 🔄 生成新证书")
        print("2. 📦 安装证书到系统")
        print("3. 🚀 生成并安装证书")
        print("0. 🚪 退出")
        
        choice = input("\n请选择操作 (0-3): ").strip()
        
        if choice == '1':
            generator.generate_certificate()
        elif choice == '2':
            generator.install_certificate()
        elif choice == '3':
            if generator.generate_certificate():
                print("\n" + "="*60)
                generator.install_certificate()
        elif choice == '0':
            print("👋 再见!")
        else:
            print("❌ 无效选择")

if __name__ == '__main__':
    main()
