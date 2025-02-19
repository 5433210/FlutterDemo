# 界面组件列表清单

## 1. 总体结构

### 1.1 主窗口 (MainWindow)

- 构成：
  - 标题栏 (TitleBar)
  - 侧边导航栏 (SideNavigationBar)
  - 内容区域 (ContentArea)
  - 底部状态栏 (StatusBar)

### 1.2 标题栏 (TitleBar)

- 构成：
  - 应用图标 (AppIcon)
  - 应用标题 (AppTitle)
  - 窗口控制按钮 (WindowButtons)
- 功能：
  - 显示应用图标和标题
  - 提供窗口最小化、最大化和关闭功能

### 1.3 侧边导航栏 (SideNavigationBar)

- 构成：
  - 导航项列表 (NavigationItemList)
- 功能：
  - 提供应用主要模块的导航入口
- 导航项：
  - 作品管理 (navigateToWorks)
  - 集字管理 (navigateToCharacters)
  - 字帖管理 (navigateToPractices)
  - 设置 (navigateToSettings)

### 1.4 内容区域 (ContentArea)

- 构成：
  - 顶部工具栏 (DynamicToolbar)
  - 主内容区 (MainContent)
- 功能：
  - 根据当前模块动态显示工具栏
  - 显示主要内容

### 1.5 底部状态栏 (StatusBar)

- 构成：
  - 提示信息 (HintText)
  - 进度指示器 (ProgressIndicator)
- 功能：
  - 显示操作提示信息
  - 显示后台任务进度

## 2. 作品管理模块

### 2.1 作品列表视图 (WorkListView)

- 构成：
  - 顶部操作栏 (WorkListToolbar)
  - 作品列表 (WorkGrid/WorkList)
- 功能：
  - 显示作品列表
  - 支持网格/列表视图切换
  - 支持搜索和筛选
- 跳转关系：
  - 点击作品项 -> 作品详情视图 (WorkDetailView)

### 2.2 作品详情视图 (WorkDetailView)

- 构成：
  - 顶部工具栏 (WorkDetailToolbar)
  - 主区域 (WorkPreview)
  - 信息面板 (WorkInfoPanel)
- 功能：
  - 显示作品详情信息
  - 提供集字操作入口
- 跳转关系：
  - 点击集字操作 -> 集字操作面板 (CharacterOperationPanel)

### 2.3 作品导入对话框 (WorkImportDialog)

- 构成：
  - 图片列表区 (ImageListArea)
  - 预览区 (PreviewArea)
  - 信息面板 (WorkInfoPanel)
  - 底部按钮区 (DialogButtons)
- 功能：
  - 导入作品图片
  - 填写作品信息

## 3. 集字管理模块

### 3.1 集字操作面板 (CharacterOperationPanel)

- 构成：
  - 顶部工具栏 (CharacterOperationToolbar)
  - 左侧工具面板 (CharacterToolPanel)
  - 中央预览区 (CharacterPreviewArea)
  - 右侧信息面板 (CharacterInfoPanel)
- 功能：
  - 提取和编辑集字
  - 登记集字信息

### 3.2 集字管理列表 (CharacterListView)

- 构成：
  - 顶部工具栏 (CharacterListToolbar)
  - 集字列表 (CharacterGrid/CharacterList)
- 功能：
  - 显示集字列表
  - 支持网格/列表视图切换
  - 支持搜索和筛选
- 跳转关系：
  - 点击集字项 -> 集字详情视图 (CharacterDetailView)

### 3.3 集字详情视图 (CharacterDetailView)

- 构成：
  - 顶部工具栏 (CharacterDetailToolbar)
  - 集字预览区 (CharacterPreview)
  - 信息面板 (CharacterInfoPanel)
- 功能：
  - 显示集字详情信息
  - 提供编辑和导出功能
- 跳转关系：
  - 点击查看原作 -> 作品详情视图 (WorkDetailView)

## 4. 字帖管理模块

### 4.1 字帖列表视图 (PracticeListView)

- 构成：
  - 顶部工具栏 (PracticeListToolbar)
  - 字帖列表 (PracticeGrid/PracticeList)
- 功能：
  - 显示字帖列表
  - 支持网格/列表视图切换
  - 支持搜索和筛选
- 跳转关系：
  - 点击字帖项 -> 字帖详情视图 (PracticeDetailView)

### 4.2 字帖详情视图 (PracticeDetailView)

- 构成：
  - 顶部工具栏 (PracticeDetailToolbar)
  - 字帖预览区 (PracticePreviewArea)
  - 信息面板 (PracticeInfoPanel)
- 功能：
  - 显示字帖详情信息
  - 提供编辑和导出功能
- 跳转关系：
  - 点击编辑 -> 字帖编辑界面 (PracticeEditView)

### 4.3 字帖编辑界面 (PracticeEditView)

- 构成：
  - 顶部工具栏 (PracticeEditToolbar)
  - 左侧面板 (PracticeToolPanel)
  - 中央编辑区 (PracticeCanvas)
  - 右侧属性面板 (PracticePropertyPanel)
- 功能：
  - 设计和编辑字帖
  - 拖拽、调整元素
  - 设置属性

## 5. 设置模块

### 5.1 设置页面 (SettingsPage)

- 构成：
  - 设置导航栏 (SettingsNavigationBar)
  - 设置内容区 (SettingsContentArea)
- 功能：
  - 提供应用配置功能

## 6. 公共组件

### 6.1 列表组件 (DataList)

- 功能：
  - 用于展示列表数据
  - 支持网格/列表视图切换
  - 支持分页加载

### 6.2 卡片组件 (DataCard)

- 功能：
  - 用于展示实体信息
  - 支持编辑模式

### 6.3 对话框 (BaseDialog)

- 功能：
  - 模态对话框
  - 支持自定义内容和操作按钮

### 6.4 工具栏 (BaseToolbar)

- 功能：
  - 提供操作按钮
  - 根据上下文动态显示

### 6.5 状态提示 (StatusIndicator)

- 功能：
  - 显示操作状态
  - 提供成功、警告、错误等提示

### 6.6 进度条 (ProgressBar)

- 功能：
  - 显示任务进度
  - 支持确定和不确定模式

### 6.7 图片预览 (ImageViewer)

- 功能：
  - 支持图片缩放、平移、旋转
  - 支持多图切换

### 6.8 文本输入框 (TextInput)

- 功能：
  - 支持单行和多行文本输入
  - 支持校验和提示

### 6.9 下拉选择框 (DropdownSelect)

- 功能：
  - 提供单选和多选功能
  - 支持自定义选项

### 6.10 日期选择器 (DatePicker)

- 功能：
  - 选择日期和时间
  - 支持自定义格式

### 6.11 开关 (Switch)

- 功能：
  - 启用或禁用某个功能

### 6.12 颜色选择器 (ColorPicker)

- 功能：
  - 选择颜色
  - 支持预设颜色和自定义颜色

### 6.13 滑块 (Slider)

- 功能：
  - 调整数值
  - 支持自定义范围和步长
