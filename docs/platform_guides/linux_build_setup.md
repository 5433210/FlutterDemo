# Linux 桌面平台构建环境搭建手册

## 文档信息
- **创建日期**: 2025年6月20日
- **文档版本**: 1.0.0
- **适用项目**: Flutter Demo 应用版本管理系统
- **平台**: Linux Desktop

## 目录
- [1. 环境要求](#1-环境要求)
- [2. 系统依赖安装](#2-系统依赖安装)
- [3. Flutter Linux配置](#3-flutter-linux配置)
- [4. 项目配置](#4-项目配置)
- [5. 多格式打包配置](#5-多格式打包配置)
- [6. 应用商店分发](#6-应用商店分发)
- [7. 验证配置](#7-验证配置)
- [8. 常见问题](#8-常见问题)

## 1. 环境要求

### 1.1 支持的发行版
- **Ubuntu**: 18.04 LTS 或更高版本
- **Debian**: 10 (Buster) 或更高版本
- **Fedora**: 32 或更高版本
- **openSUSE**: Leap 15.2 或更高版本
- **Arch Linux**: 滚动发布
- **CentOS/RHEL**: 8 或更高版本

### 1.2 硬件要求
- **内存**: 最少4GB RAM（推荐8GB）
- **存储**: 至少20GB可用空间
- **处理器**: x86_64 或 ARM64

### 1.3 必需软件版本
- **Flutter**: 3.13.0 或更高版本
- **CMake**: 3.10 或更高版本
- **Ninja**: 1.8 或更高版本
- **pkg-config**: 0.29 或更高版本
- **GTK**: 3.0 或更高版本

## 2. 系统依赖安装

### 2.1 Ubuntu/Debian系统

```bash
# 更新包管理器
sudo apt update && sudo apt upgrade -y

# 安装基础开发工具
sudo apt install -y \
    curl \
    git \
    unzip \
    xz-utils \
    zip \
    libglu1-mesa \
    build-essential

# 安装Flutter Linux依赖
sudo apt install -y \
    clang \
    cmake \
    ninja-build \
    pkg-config \
    libgtk-3-dev \
    liblzma-dev \
    libstdc++-12-dev

# 安装音视频支持（可选）
sudo apt install -y \
    libgstreamer1.0-dev \
    libgstreamer-plugins-base1.0-dev \
    libgstreamer-plugins-bad1.0-dev \
    gstreamer1.0-plugins-base \
    gstreamer1.0-plugins-good \
    gstreamer1.0-plugins-bad \
    gstreamer1.0-plugins-ugly \
    gstreamer1.0-libav
```

### 2.2 Fedora/RHEL/CentOS系统

```bash
# 更新包管理器
sudo dnf update -y

# 安装基础开发工具
sudo dnf groupinstall -y "Development Tools"
sudo dnf install -y \
    curl \
    git \
    unzip \
    xz \
    zip \
    mesa-libGLU \
    which

# 安装Flutter Linux依赖
sudo dnf install -y \
    clang \
    cmake \
    ninja-build \
    pkgconfig \
    gtk3-devel \
    xz-devel \
    libstdc++-devel

# 安装音视频支持（可选）
sudo dnf install -y \
    gstreamer1-devel \
    gstreamer1-plugins-base-devel \
    gstreamer1-plugins-bad-free-devel
```

### 2.3 Arch Linux系统

```bash
# 更新系统
sudo pacman -Syu

# 安装基础开发工具
sudo pacman -S --needed \
    base-devel \
    curl \
    git \
    unzip \
    xz \
    zip \
    glu

# 安装Flutter Linux依赖
sudo pacman -S --needed \
    clang \
    cmake \
    ninja \
    pkgconf \
    gtk3 \
    xz

# 安装音视频支持（可选）
sudo pacman -S --needed \
    gstreamer \
    gst-plugins-base \
    gst-plugins-good \
    gst-plugins-bad \
    gst-plugins-ugly
```

### 2.4 openSUSE系统

```bash
# 更新系统
sudo zypper refresh && sudo zypper update -y

# 安装基础开发工具
sudo zypper install -y \
    patterns-devel-base-devel_basis \
    curl \
    git \
    unzip \
    xz \
    zip \
    Mesa-libGLU1

# 安装Flutter Linux依赖
sudo zypper install -y \
    clang \
    cmake \
    ninja \
    pkgconfig \
    gtk3-devel \
    xz-devel \
    libstdc++-devel
```

## 3. Flutter Linux配置

### 3.1 启用Linux桌面支持

```bash
# 检查Flutter版本
flutter --version

# 启用Linux桌面支持
flutter config --enable-linux-desktop

# 验证Linux支持
flutter devices
# 应该看到 Linux 设备
```

### 3.2 检查Linux配置

```bash
# 检查Flutter配置
flutter doctor -v

# 检查Linux特定依赖
flutter doctor --verbose
```

### 3.3 为现有项目添加Linux支持

```bash
# 在项目根目录执行
flutter create --platforms linux .

# 或创建新项目
flutter create --platforms linux,android,ios,web demo_app
```

## 4. 项目配置

### 4.1 Linux目录结构

```
linux/
├── flutter/                    # Flutter引擎配置
│   ├── CMakeLists.txt          # Flutter构建配置
│   └── ephemeral/              # 临时生成文件
├── CMakeLists.txt              # 根构建配置
├── main.cc                     # 应用入口点
├── my_application.cc           # 应用实现
├── my_application.h            # 应用头文件
└── .gitignore
```

### 4.2 配置应用信息

编辑 `linux/my_application.cc` 设置窗口标题和图标：

```cpp
#include "my_application.h"

#include <flutter_linux/flutter_linux.h>
#ifdef GDK_WINDOWING_X11
#include <gdk/gdkx.h>
#endif

#include "flutter/generated_plugin_registrant.h"

struct _MyApplication {
  GtkApplication parent_instance;
  char** dart_entrypoint_arguments;
};

G_DEFINE_TYPE(MyApplication, my_application, GTK_TYPE_APPLICATION)

// 实现应用激活回调
static void my_application_activate(GApplication* application) {
  MyApplication* self = MY_APPLICATION(application);
  GtkWindow* window =
      GTK_WINDOW(gtk_application_window_new(GTK_APPLICATION(application)));

  // 设置窗口属性
  gtk_window_set_title(window, "Demo App");
  gtk_window_set_default_size(window, 1280, 720);
  gtk_window_set_resizable(window, TRUE);
  
  // 设置窗口图标
  GError* error = nullptr;
  GdkPixbuf* icon = gdk_pixbuf_new_from_file("data/flutter_assets/assets/images/app_icon.png", &error);
  if (icon != nullptr) {
    gtk_window_set_icon(window, icon);
    g_object_unref(icon);
  }

  gtk_widget_show(GTK_WIDGET(window));

  g_autoptr(FlDartProject) project = fl_dart_project_new();
  fl_dart_project_set_dart_entrypoint_arguments(project, self->dart_entrypoint_arguments);

  FlView* view = fl_view_new(project);
  gtk_widget_show(GTK_WIDGET(view));
  gtk_container_add(GTK_CONTAINER(window), GTK_WIDGET(view));

  fl_register_plugins(FL_PLUGIN_REGISTRY(view));

  gtk_widget_grab_focus(GTK_WIDGET(view));
}

// 实现应用初始化
static void my_application_init(MyApplication* self) {}

static void my_application_dispose(GObject* object) {
  MyApplication* self = MY_APPLICATION(object);
  g_clear_pointer(&self->dart_entrypoint_arguments, g_strfreev);
  G_OBJECT_CLASS(my_application_parent_class)->dispose(object);
}

static void my_application_class_init(MyApplicationClass* klass) {
  G_APPLICATION_CLASS(klass)->activate = my_application_activate;
  G_OBJECT_CLASS(klass)->dispose = my_application_dispose;
}

MyApplication* my_application_new() {
  return MY_APPLICATION(g_object_new(my_application_get_type(),
                                     "application-id", "com.example.demo",
                                     "flags", G_APPLICATION_NON_UNIQUE,
                                     nullptr));
}
```

### 4.3 配置CMake构建

编辑 `linux/CMakeLists.txt`:

```cmake
cmake_minimum_required(VERSION 3.10)
project(runner LANGUAGES CXX)

set(BINARY_NAME "demo")
set(APPLICATION_ID "com.example.demo")

cmake_policy(SET CMP0063 NEW)

set(CMAKE_INSTALL_RPATH "$ORIGIN/lib")

# 配置编译器
set(CMAKE_CXX_STANDARD 14)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# 系统依赖
find_package(PkgConfig REQUIRED)
pkg_check_modules(GTK REQUIRED IMPORTED_TARGET gtk+-3.0)

add_definitions(-DAPPLICATION_ID="${APPLICATION_ID}")

# Flutter配置
set(FLUTTER_MANAGED_DIR "${CMAKE_CURRENT_SOURCE_DIR}/flutter")

# 生成的插件构建规则
set(FLUTTER_EPHEMERAL_DIR "${CMAKE_CURRENT_SOURCE_DIR}/flutter/ephemeral")
add_subdirectory(${FLUTTER_MANAGED_DIR})

# 应用目标
add_executable(${BINARY_NAME}
  "main.cc"
  "my_application.cc"
  "${FLUTTER_MANAGED_DIR}/generated_plugin_registrant.cc"
)

# 应用属性
apply_standard_settings(${BINARY_NAME})
target_compile_definitions(${BINARY_NAME} PRIVATE FLUTTER_VERSION_MAJOR=1)
target_compile_definitions(${BINARY_NAME} PRIVATE FLUTTER_VERSION_MINOR=0)
target_compile_definitions(${BINARY_NAME} PRIVATE FLUTTER_VERSION_PATCH=0)
target_compile_definitions(${BINARY_NAME} PRIVATE FLUTTER_VERSION_BUILD=1)

# 链接库
target_link_libraries(${BINARY_NAME} PRIVATE flutter)
target_link_libraries(${BINARY_NAME} PRIVATE PkgConfig::GTK)

# 安装配置
include(GNUInstallDirs)
install(TARGETS ${BINARY_NAME}
  RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
  COMPONENT Runtime)

install(FILES "${FLUTTER_ICU_DATA_FILE}"
  DESTINATION "${CMAKE_INSTALL_LIBDIR}"
  COMPONENT Runtime)

install(FILES "${FLUTTER_LIBRARY}"
  DESTINATION "${CMAKE_INSTALL_LIBDIR}"
  COMPONENT Runtime)

if(CMAKE_BUILD_TYPE STREQUAL "Debug")
  install(FILES "${FLUTTER_LIBRARY_DEBUG}"
    DESTINATION "${CMAKE_INSTALL_LIBDIR}"
    COMPONENT Runtime)
endif()

# 插件安装
foreach(bundled_library ${PLUGIN_BUNDLED_LIBRARIES})
  install(FILES "${bundled_library}"
    DESTINATION "${CMAKE_INSTALL_LIBDIR}"
    COMPONENT Runtime)
endforeach(bundled_library)
```

### 4.4 创建桌面入口文件

创建 `linux/com.example.demo.desktop`:

```ini
[Desktop Entry]
Name=Demo App
Name[zh_CN]=演示应用
Comment=Flutter Demo Desktop Application
Comment[zh_CN]=Flutter桌面演示应用
Exec=demo
Icon=com.example.demo
Terminal=false
Type=Application
Categories=Office;Productivity;Utility;
StartupWMClass=demo
MimeType=
Keywords=demo;flutter;productivity;
```

## 5. 多格式打包配置

### 5.1 AppImage打包

安装AppImage工具：

```bash
# 下载工具
wget https://github.com/linuxdeploy/linuxdeploy/releases/download/continuous/linuxdeploy-x86_64.AppImage
wget https://github.com/AppImage/AppImageKit/releases/download/continuous/appimagetool-x86_64.AppImage
chmod +x linuxdeploy-x86_64.AppImage appimagetool-x86_64.AppImage
```

创建AppImage打包脚本 `scripts/build_appimage.sh`:

```bash
#!/bin/bash

APP_NAME="Demo App"
APP_ID="com.example.demo"
VERSION="1.0.0"
ARCH="x86_64"

# 构建Flutter应用
echo "构建Flutter应用..."
flutter build linux --release

# 创建AppDir结构
APP_DIR="Demo-App.AppDir"
rm -rf "$APP_DIR"
mkdir -p "$APP_DIR"

# 复制应用文件
cp -r build/linux/x64/release/bundle/* "$APP_DIR/"

# 创建桌面文件
cat > "$APP_DIR/$APP_ID.desktop" << EOF
[Desktop Entry]
Name=$APP_NAME
Comment=Flutter Demo Desktop Application
Exec=demo
Icon=$APP_ID
Terminal=false
Type=Application
Categories=Office;Productivity;
EOF

# 复制图标
mkdir -p "$APP_DIR/usr/share/icons/hicolor/256x256/apps/"
cp "assets/images/app_icon.png" "$APP_DIR/usr/share/icons/hicolor/256x256/apps/$APP_ID.png"
cp "assets/images/app_icon.png" "$APP_DIR/$APP_ID.png"

# 创建AppRun脚本
cat > "$APP_DIR/AppRun" << 'EOF'
#!/bin/bash
cd "$(dirname "$0")"
exec ./demo "$@"
EOF
chmod +x "$APP_DIR/AppRun"

# 使用linuxdeploy处理依赖
./linuxdeploy-x86_64.AppImage --appdir "$APP_DIR" --desktop-file "$APP_DIR/$APP_ID.desktop" --icon-file "$APP_DIR/$APP_ID.png"

# 创建AppImage
./appimagetool-x86_64.AppImage "$APP_DIR" "Demo-App-$VERSION-$ARCH.AppImage"

echo "AppImage创建完成: Demo-App-$VERSION-$ARCH.AppImage"
```

### 5.2 Snap打包

安装snapcraft：

```bash
# Ubuntu/Debian
sudo apt install snapcraft

# 或使用snap安装
sudo snap install snapcraft --classic
```

创建 `snap/snapcraft.yaml`:

```yaml
name: demo-app
version: '1.0.0'
summary: Flutter Demo Desktop Application
description: |
  A demo Flutter desktop application showcasing cross-platform development.

grade: stable
confinement: strict
base: core22

parts:
  demo-app:
    plugin: dump
    source: build/linux/x64/release/bundle/
    stage-packages:
      - libgtk-3-0
      - libglu1-mesa
      - libgstreamer1.0-0
      - libgstreamer-plugins-base1.0-0
    
apps:
  demo-app:
    command: demo
    desktop: snap/gui/demo-app.desktop
    plugs:
      - desktop
      - desktop-legacy
      - wayland
      - x11
      - home
      - network
      - audio-playback
      - camera
```

### 5.3 DEB打包

创建DEB打包脚本 `scripts/build_deb.sh`:

```bash
#!/bin/bash

APP_NAME="demo-app"
VERSION="1.0.0"
ARCH="amd64"
MAINTAINER="Demo Company <support@example.com>"

# 构建Flutter应用
flutter build linux --release

# 创建包目录结构
PACKAGE_DIR="${APP_NAME}_${VERSION}_${ARCH}"
rm -rf "$PACKAGE_DIR"
mkdir -p "$PACKAGE_DIR/DEBIAN"
mkdir -p "$PACKAGE_DIR/usr/bin"
mkdir -p "$PACKAGE_DIR/usr/share/applications"
mkdir -p "$PACKAGE_DIR/usr/share/icons/hicolor/256x256/apps"

# 复制应用文件
cp -r build/linux/x64/release/bundle/* "$PACKAGE_DIR/usr/bin/"

# 创建control文件
cat > "$PACKAGE_DIR/DEBIAN/control" << EOF
Package: $APP_NAME
Version: $VERSION
Section: misc
Priority: optional
Architecture: $ARCH
Depends: libgtk-3-0, libglu1-mesa
Maintainer: $MAINTAINER
Description: Flutter Demo Desktop Application
 A demo Flutter desktop application showcasing cross-platform development.
EOF

# 复制桌面文件和图标
cp linux/com.example.demo.desktop "$PACKAGE_DIR/usr/share/applications/"
cp assets/images/app_icon.png "$PACKAGE_DIR/usr/share/icons/hicolor/256x256/apps/com.example.demo.png"

# 设置权限
chmod 755 "$PACKAGE_DIR/usr/bin/demo"
chmod 644 "$PACKAGE_DIR/usr/share/applications/com.example.demo.desktop"

# 构建DEB包
dpkg-deb --build "$PACKAGE_DIR"

echo "DEB包创建完成: ${PACKAGE_DIR}.deb"
```

## 6. 应用商店分发

### 6.1 Snap Store

```bash
# 注册开发者账号
snapcraft register demo-app

# 上传应用
snapcraft upload demo-app_1.0.0_amd64.snap

# 发布到stable频道
snapcraft release demo-app 1 stable
```

### 6.2 Flathub

创建Flatpak配置并提交到Flathub：

```bash
# 1. Fork flathub仓库
# 2. 创建应用配置文件
# 3. 提交PR到flathub
```

## 7. 验证配置

### 7.1 构建测试

```bash
# 清理项目
flutter clean

# 获取依赖
flutter pub get

# 构建Debug版本
flutter build linux --debug

# 构建Release版本
flutter build linux --release

# 运行应用
./build/linux/x64/release/bundle/demo
```

### 7.2 依赖检查

```bash
# 检查动态链接依赖
ldd build/linux/x64/release/bundle/demo

# 检查系统库依赖
objdump -p build/linux/x64/release/bundle/demo | grep NEEDED
```

### 7.3 桌面集成测试

```bash
# 安装桌面文件
sudo cp linux/com.example.demo.desktop /usr/share/applications/
sudo cp assets/images/app_icon.png /usr/share/icons/hicolor/256x256/apps/com.example.demo.png

# 更新桌面数据库
sudo update-desktop-database
sudo gtk-update-icon-cache /usr/share/icons/hicolor/

# 测试应用启动器
gtk-launch com.example.demo
```

## 8. 常见问题

### 8.1 构建问题

**问题**: "GTK development headers not found"
```bash
# Ubuntu/Debian解决方案
sudo apt install libgtk-3-dev

# Fedora解决方案
sudo dnf install gtk3-devel

# Arch解决方案
sudo pacman -S gtk3
```

**问题**: "CMake not found"
```bash
# 解决方案
sudo apt install cmake  # Ubuntu/Debian
sudo dnf install cmake  # Fedora
sudo pacman -S cmake    # Arch
```

**问题**: "Ninja not found"
```bash
# 解决方案
sudo apt install ninja-build  # Ubuntu/Debian
sudo dnf install ninja-build  # Fedora
sudo pacman -S ninja          # Arch
```

### 8.2 运行时问题

**问题**: "libflutter_linux_gtk.so not found"
```bash
# 解决方案
export LD_LIBRARY_PATH="$LD_LIBRARY_PATH:$(pwd)/build/linux/x64/release/bundle/lib"
```

**问题**: "GTK themes not loading"
```bash
# 解决方案
sudo apt install gtk2-engines-murrine gtk2-engines-pixbuf
```

### 8.3 打包问题

**问题**: "AppImage not executable"
```bash
# 解决方案
chmod +x Demo-App-1.0.0-x86_64.AppImage
```

**问题**: "Snap confinement issues"
```bash
# 解决方案
sudo snap install demo-app_1.0.0_amd64.snap --devmode
```

## 相关资源

### 官方文档
- [Flutter Linux Documentation](https://docs.flutter.dev/platform-integration/desktop)
- [Building Linux apps with Flutter](https://docs.flutter.dev/deployment/linux)
- [GTK Documentation](https://docs.gtk.org/gtk3/)

### 打包工具
- [AppImage](https://appimage.org/)
- [Snapcraft](https://snapcraft.io/)
- [Flatpak](https://flatpak.org/)

### 分发平台
- [Snap Store](https://snapcraft.io/store)
- [Flathub](https://flathub.org/)
- [Ubuntu PPA](https://launchpad.net/ubuntu/+ppas)

---

*最后更新时间：2025年6月20日*  
*文档版本: 1.0.0* 