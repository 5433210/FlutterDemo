# 软件架构设计文档

## 1. 架构概述

### 1.1 设计目标

- 跨平台桌面应用优先（Windows/macOS/Linux）
- 清晰的分层架构，便于维护和扩展
- 支持离线优先，后续可扩展云存储
- 高性能图像处理和渲染
- 支持多图作品
- 可扩展到移动平台

### 1.2 技术选型

- UI框架：Flutter
- 状态管理：Riverpod
- 本地存储：SQLite + 文件系统
- 图像处理：FFI接口调用原生库
- 序列化：json_serializable
- 依赖注入：Riverpod

## 2. 系统分层

### 2.1 表现层 (Presentation)

```
/lib/presentation/
  ├── pages/              // 页面
  ├── widgets/            // 可复用组件
  ├── dialogs/            // 对话框
  ├── theme/              // 主题定义
  └── viewmodels/         // 视图模型
```

### 2.2 应用层 (Application)

```
/lib/application/
  ├── services/           // 应用服务
  │   ├── work/          // 作品服务
  │   ├── character/     // 集字服务
  │   └── practice/      // 字帖服务
  │   └── settings/      // 配置服务
  ├── commands/          // 命令处理
  └── events/           // 事件处理
```

### 2.3 领域层 (Domain)

```
/lib/domain/
  ├── entities/          // 领域实体
  ├── repositories/      // 仓库接口
  ├── value_objects/     // 值对象
  └── services/         // 领域服务
```

### 2.4 基础设施层 (Infrastructure)

```
/lib/infrastructure/
  ├── persistence/       // 持久化实现
  │   ├── sqlite/       // SQLite实现
  │   └── file/         // 文件系统实现
  ├── image/            // 图像处理
  ├── platform/         // 平台服务
  └── cloud/           // 云服务（预留）
```

## 3. 核心模块设计

### 3.1 作品管理模块

- 职责：作品的导入、存储、检索和管理，支持多图作品
- 关键组件：
  - WorkRepository: 作品数据访问
  - ImageProcessor: 图像处理服务
  - WorkService: 作品业务逻辑
  - WorkViewModel: 作品视图状态管理

### 3.2 集字管理模块

- 职责：汉字识别、提取、存储和检索
- 关键组件：
  - CharacterRecognizer: 笔画识别
  - CharacterRepository: 集字数据访问
  - CharacterService: 集字业务逻辑
  - CharacterViewModel: 集字视图状态管理

### 3.3 字帖设计模块

- 职责：字帖设计、渲染和导出
- 关键组件：
  - PracticeRenderer: 字帖渲染引擎
  - PracticeRepository: 字帖数据访问
  - PracticeService: 字帖业务逻辑
  - PracticeViewModel: 字帖视图状态管理

## 4. 关键技术实现

### 4.1 存储设计

```
SQLite数据库:
  - works              // 作品元数据
  - characters         // 集字元数据
  - practices          // 字帖元数据
  - tags              // 标签数据
  - settings          // 应用配置

文件系统:
  /storage
    /works            // 作品存储
      /{workId}/
        metadata.json
        thumbnail.jpg
        pictures/{index}/
          original.{ext}
          imported.png
    /chars            // 集字图片
    /practices        // 字帖资源
    /temp            // 临时文件
    /backup          // 备份文件
```

### 4.2 图像处理

- 采用FFI调用原生图像处理库
- 实现图像预处理、笔画识别等功能
- 异步处理避免阻塞UI
- 缓存优化提升性能

### 4.3 状态管理

- 采用Riverpod管理全局状态
- 实现响应式数据流
- 支持状态持久化
- 支持撤销/重做

## 5. 扩展性设计

### 5.1 移动端扩展

- UI适配响应式布局
- 性能优化考虑设备限制
- 手势操作优化
- 存储策略调整

### 5.2 云存储扩展

```
/lib/infrastructure/cloud/
  ├── repositories/     // 云存储实现
  ├── sync/            // 同步服务
  └── auth/            // 认证服务
```

## 6. 安全性设计

### 6.1 本地安全

- 文件访问权限控制
- 数据完整性校验
- 备份和恢复机制

### 6.2 云端安全（预留）

- 用户认证授权
- 数据加密传输
- 访问控制策略

## 7. 性能优化

### 7.1 资源管理

- 图片资源池化
- 内存使用监控
- 大文件分块加载

### 7.2 渲染优化

- 图层缓存机制
- 按需渲染策略
- 硬件加速支持
