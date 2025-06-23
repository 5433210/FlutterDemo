# 鸿蒙OS平台适配计划

## 概述

本文档描述了如何将现有的版本管理系统适配到鸿蒙OS平台，确保多平台版本管理的一致性。

## 适配阶段

### 阶段1：准备阶段（当前）
- ✅ 在版本管理设计中预留鸿蒙支持
- ✅ 在版本生成脚本中包含鸿蒙配置模板
- ✅ 在文档中说明鸿蒙适配策略

### 阶段2：基础适配（Flutter鸿蒙支持就绪后）
- [ ] 添加鸿蒙平台到Flutter项目
- [ ] 配置鸿蒙版本管理文件
- [ ] 集成到现有构建流程

### 阶段3：完整集成
- [ ] 鸿蒙应用商店集成
- [ ] 签名和发布流程
- [ ] 监控和分析集成

## 技术实施详情

### 1. 项目结构适配

当Flutter支持鸿蒙后，项目结构将包含：

```
project/
├── ohos/                    # 鸿蒙平台目录
│   ├── app/
│   │   ├── app.json5       # 应用配置文件
│   │   └── build-profile.json5
│   ├── entry/
│   │   ├── src/main/
│   │   │   ├── config.json # 版本配置位置
│   │   │   └── ets/        # ArkTS代码
│   │   └── build-profile.json5
│   ├── build-profile.json5
│   └── hvigorfile.ts       # 构建脚本
├── android/                # 现有Android目录
├── ios/                    # 现有iOS目录
└── ...
```

### 2. 版本配置文件

#### 主配置文件：`ohos/entry/src/main/config.json`
```json
{
  "app": {
    "bundleName": "com.charasgem.app",
    "versionCode": 20250620001,
    "versionName": "1.0.0",
    "minCompatibleVersionCode": 20250620001,
    "debug": false,
    "icon": "$media:icon",
    "label": "$string:app_name"
  }
}
```

#### 应用级配置：`ohos/app/app.json5`
```json5
{
  "app": {
    "bundleName": "com.charasgem.app",
    "versionCode": 20250620001,
    "versionName": "1.0.0",
    "minAPIVersion": 9,
    "targetAPIVersion": 12
  }
}
```

### 3. 版本管理脚本适配

#### 更新 `scripts/generate_version_info.py`

我们的脚本已经包含了鸿蒙支持：

```python
# 在 _generate_platform_versions 方法中
'ohos': {
    'versionName': version_string,
    'versionCode': int(build)
}
```

#### 新增鸿蒙特定脚本：`scripts/platform/update_ohos_version.py`

```python
#!/usr/bin/env python3
"""
更新鸿蒙OS平台版本信息
"""

import json
import json5
from pathlib import Path

def update_ohos_version(project_root, version_info):
    """更新鸿蒙平台版本信息"""
    ohos_dir = Path(project_root) / 'ohos'
    
    if not ohos_dir.exists():
        print("警告: 鸿蒙平台目录不存在")
        return False
    
    # 更新 app.json5
    app_config_file = ohos_dir / 'app' / 'app.json5'
    if app_config_file.exists():
        update_json5_version(app_config_file, version_info)
    
    # 更新 config.json
    entry_config_file = ohos_dir / 'entry' / 'src' / 'main' / 'config.json'
    if entry_config_file.exists():
        update_json_version(entry_config_file, version_info)
    
    return True

def update_json5_version(file_path, version_info):
    """更新JSON5格式的版本信息"""
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            config = json5.load(f)
        
        config['app']['versionCode'] = version_info['versionCode']
        config['app']['versionName'] = version_info['versionName']
        
        with open(file_path, 'w', encoding='utf-8') as f:
            json5.dump(config, f, indent=2, ensure_ascii=False)
            
        print(f"已更新 {file_path}")
        
    except Exception as e:
        print(f"更新 {file_path} 失败: {e}")

def update_json_version(file_path, version_info):
    """更新JSON格式的版本信息"""
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            config = json.load(f)
        
        config['app']['versionCode'] = version_info['versionCode']
        config['app']['versionName'] = version_info['versionName']
        
        with open(file_path, 'w', encoding='utf-8') as f:
            json.dump(config, f, indent=2, ensure_ascii=False)
            
        print(f"已更新 {file_path}")
        
    except Exception as e:
        print(f"更新 {file_path} 失败: {e}")
```

### 4. CI/CD集成

#### GitHub Actions工作流适配

```yaml
# .github/workflows/build_harmonyos.yml
name: Build HarmonyOS

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]

jobs:
  build-harmonyos:
    runs-on: ubuntu-latest
    
    steps:
    - uses: actions/checkout@v4
    
    - name: Setup HarmonyOS SDK
      uses: harmony-os/setup-harmonyos@v1
      with:
        api-level: 12
    
    - name: Setup Flutter
      uses: subosito/flutter-action@v2
      with:
        flutter-version: '3.24.0'
        channel: 'stable'
    
    - name: Update Version
      run: python scripts/generate_version_info.py
    
    - name: Build HarmonyOS HAP
      run: |
        cd ohos
        hvigor clean
        hvigor build --mode release
    
    - name: Upload HAP
      uses: actions/upload-artifact@v4
      with:
        name: harmonyos-hap
        path: ohos/entry/build/default/outputs/default/entry-default-release.hap
```

### 5. 构建和发布流程

#### 构建脚本：`scripts/build_harmonyos.py`

```python
#!/usr/bin/env python3
"""
鸿蒙OS平台构建脚本
"""

import subprocess
import os
from pathlib import Path

class HarmonyOSBuilder:
    def __init__(self, project_root):
        self.project_root = Path(project_root)
        self.ohos_dir = self.project_root / 'ohos'
    
    def build(self, mode='release'):
        """构建鸿蒙应用"""
        if not self.ohos_dir.exists():
            raise Exception("鸿蒙项目目录不存在")
        
        # 清理构建
        subprocess.run(['hvigor', 'clean'], cwd=self.ohos_dir, check=True)
        
        # 构建HAP
        cmd = ['hvigor', 'build', f'--mode={mode}']
        result = subprocess.run(cmd, cwd=self.ohos_dir, check=True)
        
        return result.returncode == 0
    
    def sign_hap(self, hap_path, keystore_path, password):
        """签名HAP文件"""
        cmd = [
            'hap-sign-tool', 'sign-app',
            '--keystore', keystore_path,
            '--storepasswd', password,
            '--inFile', hap_path,
            '--outFile', hap_path.replace('.hap', '-signed.hap')
        ]
        
        result = subprocess.run(cmd, check=True)
        return result.returncode == 0
```

### 6. 应用商店集成

#### AppGallery Connect API集成

```python
# scripts/publish_to_appgallery.py
class AppGalleryPublisher:
    def __init__(self, client_id, client_secret):
        self.client_id = client_id
        self.client_secret = client_secret
        self.access_token = None
    
    def upload_hap(self, app_id, hap_path):
        """上传HAP到AppGallery Connect"""
        # 获取访问令牌
        self._get_access_token()
        
        # 上传HAP文件
        with open(hap_path, 'rb') as f:
            files = {'file': f}
            response = requests.post(
                f'https://connect-api.cloud.huawei.com/api/publish/v2/upload-url?appId={app_id}',
                headers={'Authorization': f'Bearer {self.access_token}'},
                files=files
            )
        
        return response.status_code == 200
```

## 适配时间线

### 短期（1-3个月）
- 监控Flutter鸿蒙支持进展
- 完善现有版本管理系统的鸿蒙预留功能
- 准备鸿蒙开发环境

### 中期（3-6个月）
- 当Flutter支持就绪时，立即开始适配
- 集成鸿蒙到现有构建流程
- 完成基础版本管理功能

### 长期（6-12个月）
- 完整的鸿蒙应用商店集成
- 鸿蒙特定功能适配
- 性能优化和用户体验改进

## 风险和缓解措施

### 技术风险
- **Flutter鸿蒙支持延迟**
  - 缓解：准备原生鸿蒙开发方案
  - 缓解：考虑第三方解决方案

- **API兼容性问题**
  - 缓解：抽象层设计，隔离平台差异
  - 缓解：渐进式迁移策略

### 业务风险
- **开发成本增加**
  - 缓解：复用现有架构和工具
  - 缓解：分阶段实施

- **维护复杂度上升**
  - 缓解：统一的版本管理系统
  - 缓解：自动化测试和CI/CD

## 监控指标

### 技术指标
- 构建成功率
- 版本同步准确性
- 发布流程自动化程度

### 业务指标
- 鸿蒙平台用户增长
- 应用商店表现
- 用户反馈质量

---

**更新时间**: 2025年6月20日  
**版本**: 1.0.0  
**状态**: 计划中 