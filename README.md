# Scaner 项目

这是一个iOS扫描应用项目。

## 项目结构

```
scaner/
├── Views/           # SwiftUI视图文件
│   ├── ContentView.swift
│   ├── HomeView.swift
│   ├── ScanView.swift
│   ├── HistoryView.swift
│   └── SettingsView.swift
├── Models/          # 数据模型文件
├── Utils/           # 工具类和辅助函数
├── Resources/       # 项目资源文件
│   └── Assets.xcassets/
├── scanerApp.swift  # 应用入口文件
└── README.md        # 项目说明文件
```

## 文件夹说明

### Views/ 文件夹
包含所有的SwiftUI视图文件：
- `ContentView.swift` - 主内容视图
- `HomeView.swift` - 首页视图
- `ScanView.swift` - 扫描视图
- `HistoryView.swift` - 历史记录视图
- `SettingsView.swift` - 设置视图

### Models/ 文件夹
用于存放数据模型文件：
- 数据模型定义
- 数据结构
- 业务逻辑相关的模型类

### Utils/ 文件夹
用于存放工具类和辅助函数：
- 工具函数
- 扩展方法
- 辅助类
- 常量定义
- 工具类

### Resources/ 文件夹
用于存放项目资源文件：
- `Assets.xcassets/` - 应用图标和颜色资源
- 图片资源
- 颜色资源
- 字体文件
- 其他静态资源

## 开发规范

1. 新创建的视图文件请放在 `Views/` 文件夹中
2. 数据模型请放在 `Models/` 文件夹中
3. 工具函数和辅助类请放在 `Utils/` 文件夹中
4. 资源文件请放在 `Resources/` 文件夹中

这样的结构有助于保持项目的整洁和可维护性。 