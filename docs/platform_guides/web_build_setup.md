# Web 平台构建环境搭建手册

## 文档信息
- **创建日期**: 2025年6月20日
- **文档版本**: 1.0.0
- **适用项目**: Flutter Demo 应用版本管理系统
- **平台**: Web

## 目录
- [1. 环境要求](#1-环境要求)
- [2. Flutter Web配置](#2-flutter-web配置)
- [3. 项目配置](#3-项目配置)
- [4. PWA配置](#4-pwa配置)
- [5. 构建优化](#5-构建优化)
- [6. 部署配置](#6-部署配置)
- [7. CDN和缓存策略](#7-cdn和缓存策略)
- [8. 验证配置](#8-验证配置)
- [9. 常见问题](#9-常见问题)

## 1. 环境要求

### 1.1 系统要求
- **操作系统**: Windows 10+、macOS 10.14+、Ubuntu 18.04+
- **网络**: 稳定的网络连接用于下载依赖和部署

### 1.2 必需软件版本
- **Flutter**: 3.13.0 或更高版本（启用Web支持）
- **Chrome**: 最新版本（用于调试和测试）
- **Node.js**: 16+ （用于构建工具，可选）
- **Web服务器**: Apache/Nginx/Firebase Hosting等

### 1.3 浏览器兼容性
- **桌面浏览器**: Chrome 84+, Firefox 72+, Safari 14+, Edge 84+
- **移动浏览器**: Mobile Chrome 84+, Mobile Safari 14+

## 2. Flutter Web配置

### 2.1 启用Web支持

```bash
# 检查Flutter版本
flutter --version

# 启用Web支持
flutter config --enable-web

# 验证Web支持
flutter devices
# 应该看到 Chrome 和 Web Server 设备
```

### 2.2 创建或添加Web支持

```bash
# 为现有项目添加Web支持
flutter create --platforms web .

# 或创建新的支持Web的项目
flutter create --platforms web,android,ios demo_app
```

### 2.3 检查Web配置

```bash
# 检查Flutter配置
flutter doctor

# 运行Web版本测试
flutter run -d chrome
```

## 3. 项目配置

### 3.1 Web目录结构

```
web/
├── favicon.png              # 网站图标
├── icons/                   # 各种尺寸的图标
│   ├── Icon-192.png
│   ├── Icon-512.png
│   └── Icon-maskable-192.png
├── index.html              # 主HTML文件
├── manifest.json           # PWA配置文件
└── flutter_service_worker.js  # Service Worker（自动生成）
```

### 3.2 配置 index.html

编辑 `web/index.html`:

```html
<!DOCTYPE html>
<html>
<head>
  <!-- 基础meta标签 -->
  <meta charset="UTF-8">
  <meta content="IE=Edge" http-equiv="X-UA-Compatible">
  <meta name="description" content="Flutter Demo 应用">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">

  <!-- PWA配置 -->
  <meta name="apple-mobile-web-app-capable" content="yes">
  <meta name="apple-mobile-web-app-status-bar-style" content="black">
  <meta name="apple-mobile-web-app-title" content="demo">
  
  <!-- 图标配置 -->
  <link rel="apple-touch-icon" href="icons/Icon-192.png">
  <link rel="icon" type="image/png" href="favicon.png"/>
  <link rel="manifest" href="manifest.json">

  <title>Demo App</title>
</head>
<body>
  <!-- 加载指示器 -->
  <div id="loading">
    <style>
      #loading {
        display: flex;
        justify-content: center;
        align-items: center;
        height: 100vh;
        font-family: Arial, sans-serif;
      }
    </style>
    加载中...
  </div>

  <script>
    // Flutter Web配置
    window.addEventListener('load', function(ev) {
      // 下载主要的dart2js运行时
      _flutter.loader.loadEntrypoint({
        serviceWorker: {
          serviceWorkerVersion: {{flutter_service_worker_version}},
        },
        onEntrypointLoaded: function(engineInitializer) {
          engineInitializer.initializeEngine().then(function(appRunner) {
            appRunner.runApp();
            // 隐藏加载指示器
            document.getElementById('loading').style.display = 'none';
          });
        }
      });
    });
  </script>
</body>
</html>
```

### 3.3 配置 Web Assets

```bash
# 确保web目录有必要的资源文件
# 复制应用图标到web/icons/目录
cp assets/images/app_icon.png web/icons/Icon-192.png
cp assets/images/app_icon.png web/icons/Icon-512.png
cp assets/images/app_icon.png web/favicon.png
```

## 4. PWA配置

### 4.1 配置 manifest.json

编辑 `web/manifest.json`:

```json
{
  "name": "Demo App",
  "short_name": "Demo",
  "start_url": ".",
  "display": "standalone",
  "background_color": "#ffffff",
  "theme_color": "#2196F3",
  "description": "Flutter Demo 应用",
  "orientation": "portrait-primary",
  "prefer_related_applications": false,
  "icons": [
    {
      "src": "icons/Icon-192.png",
      "sizes": "192x192",
      "type": "image/png"
    },
    {
      "src": "icons/Icon-512.png",
      "sizes": "512x512",
      "type": "image/png"
    },
    {
      "src": "icons/Icon-maskable-192.png",
      "sizes": "192x192",
      "type": "image/png",
      "purpose": "maskable"
    }
  ],
  "categories": ["productivity", "utilities"],
  "lang": "zh-CN",
  "dir": "ltr"
}
```

### 4.2 Service Worker配置

Flutter会自动生成Service Worker，但可以自定义：

创建 `web/sw.js`（可选）:

```javascript
// 自定义Service Worker
const CACHE_NAME = 'demo-app-v1';
const CACHE_URLS = [
  '/',
  '/main.dart.js',
  '/manifest.json',
  '/favicon.png',
  '/icons/Icon-192.png',
  '/icons/Icon-512.png'
];

// 安装Service Worker
self.addEventListener('install', (event) => {
  event.waitUntil(
    caches.open(CACHE_NAME).then((cache) => {
      return cache.addAll(CACHE_URLS);
    })
  );
});

// 激活Service Worker
self.addEventListener('activate', (event) => {
  event.waitUntil(
    caches.keys().then((cacheNames) => {
      return Promise.all(
        cacheNames.map((cacheName) => {
          if (cacheName !== CACHE_NAME) {
            return caches.delete(cacheName);
          }
        })
      );
    })
  );
});

// 拦截网络请求
self.addEventListener('fetch', (event) => {
  event.respondWith(
    caches.match(event.request).then((response) => {
      return response || fetch(event.request);
    })
  );
});
```

## 5. 构建优化

### 5.1 构建配置

```bash
# 开发构建
flutter build web --debug

# 生产构建（优化）
flutter build web --release

# 指定Web渲染器
flutter build web --web-renderer canvaskit  # 高质量渲染
flutter build web --web-renderer html       # 更小的包体积

# 启用分包加载
flutter build web --split-debug-info=build/web-symbols

# 优化包大小
flutter build web --dart-define=FLUTTER_WEB_USE_SKIA=false
```

### 5.2 性能优化配置

在 `lib/main.dart` 中添加Web特定优化：

```dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

void main() {
  // Web平台特定配置
  if (kIsWeb) {
    // 启用Web性能优化
    WidgetsFlutterBinding.ensureInitialized();
  }
  
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Demo App',
      // Web特定配置
      debugShowCheckedModeBanner: false,
      
      // 路由配置
      initialRoute: '/',
      routes: {
        '/': (context) => HomePage(),
      },
      
      theme: ThemeData(
        primarySwatch: Colors.blue,
        // 优化Web字体渲染
        fontFamily: 'Roboto',
      ),
    );
  }
}
```

### 5.3 资源优化

```yaml
# 在pubspec.yaml中优化Web资源
flutter:
  assets:
    - assets/images/
    - assets/fonts/
  
  fonts:
    - family: Roboto
      fonts:
        - asset: assets/fonts/Roboto-Regular.ttf
        - asset: assets/fonts/Roboto-Bold.ttf
          weight: 700
```

## 6. 部署配置

### 6.1 Firebase Hosting部署

```bash
# 安装Firebase CLI
npm install -g firebase-tools

# 登录Firebase
firebase login

# 初始化项目
firebase init hosting

# 配置firebase.json
```

创建 `firebase.json`:

```json
{
  "hosting": {
    "public": "build/web",
    "ignore": [
      "firebase.json",
      "**/.*",
      "**/node_modules/**"
    ],
    "rewrites": [
      {
        "source": "**",
        "destination": "/index.html"
      }
    ],
    "headers": [
      {
        "source": "**/*.@(js|css|woff2)",
        "headers": [
          {
            "key": "Cache-Control",
            "value": "max-age=31536000"
          }
        ]
      }
    ]
  }
}
```

部署命令：

```bash
# 构建并部署
flutter build web --release
firebase deploy --only hosting
```

### 6.2 GitHub Pages部署

创建 `.github/workflows/deploy.yml`:

```yaml
name: Deploy to GitHub Pages

on:
  push:
    branches: [ main ]

jobs:
  build-and-deploy:
    runs-on: ubuntu-latest
    
    steps:
    - uses: actions/checkout@v3
    
    - uses: subosito/flutter-action@v2
      with:
        flutter-version: '3.13.0'
        
    - name: Enable web
      run: flutter config --enable-web
      
    - name: Install dependencies
      run: flutter pub get
      
    - name: Build web
      run: flutter build web --release --base-href /demo/
      
    - name: Deploy
      uses: peaceiris/actions-gh-pages@v3
      with:
        github_token: ${{ secrets.GITHUB_TOKEN }}
        publish_dir: ./build/web
```

### 6.3 Nginx配置

创建 `nginx.conf`:

```nginx
server {
    listen 80;
    server_name demo.example.com;
    
    # 启用gzip压缩
    gzip on;
    gzip_types text/plain text/css application/json application/javascript text/xml application/xml;
    
    # 静态文件缓存
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
    
    # Flutter Web应用
    location / {
        root /var/www/demo/build/web;
        try_files $uri $uri/ /index.html;
        
        # 安全头
        add_header X-Frame-Options "SAMEORIGIN";
        add_header X-Content-Type-Options "nosniff";
        add_header X-XSS-Protection "1; mode=block";
    }
}
```

## 7. CDN和缓存策略

### 7.1 CDN配置

```bash
# 上传到CDN（以阿里云OSS为例）
ossutil cp -r build/web/ oss://your-bucket/demo/ --include "*.js" --include "*.css" --include "*.html"

# 设置缓存头
ossutil set-meta oss://your-bucket/demo/ Cache-Control:max-age=31536000 --include "*.js" --include "*.css"
```

### 7.2 缓存策略配置

在 `web/index.html` 中添加缓存配置：

```html
<head>
  <!-- 缓存控制 -->
  <meta http-equiv="Cache-Control" content="no-cache, no-store, must-revalidate">
  <meta http-equiv="Pragma" content="no-cache">
  <meta http-equiv="Expires" content="0">
  
  <!-- 预加载关键资源 -->
  <link rel="preload" href="main.dart.js" as="script">
  <link rel="prefetch" href="assets/fonts/MaterialIcons-Regular.otf">
</head>
```

## 8. 验证配置

### 8.1 本地测试

```bash
# 开发模式运行
flutter run -d chrome --web-port 8080

# 使用特定浏览器测试
flutter run -d chrome --web-browser-flag="--disable-web-security"

# 热重载测试
# 在浏览器中按 r 重新加载
# 按 R 进行热重启
```

### 8.2 构建测试

```bash
# 构建生产版本
flutter build web --release

# 本地预览生产构建
cd build/web
python3 -m http.server 8000
# 或使用Node.js
npx serve -s . -p 8000

# 在浏览器中访问 http://localhost:8000
```

### 8.3 PWA功能测试

```bash
# 检查PWA特性
# 1. 在Chrome中打开应用
# 2. 开发者工具 -> Application -> Manifest
# 3. 检查Service Worker状态
# 4. 测试离线功能
# 5. 测试"添加到主屏幕"功能
```

### 8.4 性能测试

```bash
# 使用Lighthouse分析
# 1. Chrome开发者工具 -> Lighthouse
# 2. 选择Performance、PWA、SEO等类别
# 3. 运行分析并查看报告
# 4. 根据建议优化性能

# 网络测试
# 1. 开发者工具 -> Network
# 2. 模拟慢速网络
# 3. 测试应用加载时间
```

## 9. 常见问题

### 9.1 构建问题

**问题**: "Web support not enabled"
```bash
# 解决方案
flutter config --enable-web
flutter create --platforms web .
```

**问题**: "Chrome not found"
```bash
# 解决方案 - 指定Chrome路径
export CHROME_EXECUTABLE=/path/to/chrome
# 或
flutter run -d web-server --web-port 8080
```

**问题**: "Build failed with Dart2JS errors"
```bash
# 解决方案
flutter clean
flutter pub get
flutter build web --verbose
```

### 9.2 运行时问题

**问题**: "CORS errors"
```bash
# 解决方案
# 1. 在开发时使用 --web-browser-flag="--disable-web-security"
# 2. 生产环境配置正确的CORS头
# 3. 使用代理服务器处理跨域请求
```

**问题**: "Font loading issues"
```bash
# 解决方案
# 1. 确保字体文件在assets目录中
# 2. 在pubspec.yaml中正确声明字体
# 3. 使用Web安全字体作为fallback
```

**问题**: "Service Worker caching issues"
```bash
# 解决方案
# 1. 在Chrome中按F12 -> Application -> Storage -> Clear storage
# 2. 更新Service Worker版本号
# 3. 在开发模式下禁用缓存
```

### 9.3 性能问题

**问题**: "Large bundle size"
```bash
# 解决方案
flutter build web --split-debug-info=symbols
flutter build web --tree-shake-icons
# 使用deferred loading分包加载
```

**问题**: "Slow initial loading"
```bash
# 解决方案
# 1. 启用代码分割
# 2. 优化图片资源
# 3. 使用CDN加速
# 4. 配置HTTP/2服务器推送
```

## 相关资源

### 官方文档
- [Flutter Web Documentation](https://docs.flutter.dev/platform-integration/web)
- [Building a web application with Flutter](https://docs.flutter.dev/get-started/web)
- [PWA with Flutter](https://docs.flutter.dev/platform-integration/web/pwa)

### 部署平台
- [Firebase Hosting](https://firebase.google.com/docs/hosting)
- [GitHub Pages](https://pages.github.com/)
- [Netlify](https://www.netlify.com/)
- [Vercel](https://vercel.com/)

### 性能工具
- [Lighthouse](https://developers.google.com/web/tools/lighthouse)
- [Web.dev](https://web.dev/)
- [Chrome DevTools](https://developers.google.com/web/tools/chrome-devtools)

---

*最后更新时间：2025年6月20日*  
*文档版本: 1.0.0* 