# MindFlow - iOS Swift 应用

这是一个使用 Swift 和 SwiftUI 构建的原生 iOS 应用。

## 项目结构

```
MindFlow/
├── MindFlow/
│   ├── MindFlowApp.swift            # 应用入口
│   ├── Models/
│   │   └── Models.swift              # 数据模型
│   ├── Services/
│   │   └── APIClient.swift           # API 客户端
│   ├── Views/
│   │   ├── ContentView.swift         # 主视图
│   │   ├── DashboardView.swift       # 分类列表视图
│   │   └── CategoryDetailView.swift  # 商品详情视图
│   ├── Assets.xcassets/              # 资源文件
│   └── Info.plist                    # 应用配置
└── MindFlow.xcodeproj/              # Xcode 项目文件
```

## 功能特性

- ✅ 分类管理（创建、查看、删除）
- ✅ 商品管理（添加、编辑、删除）
- ✅ 商品排名（拖拽排序）
- ✅ 颜色等级系统（完美、优秀、普通、劣质）
- ✅ 下拉刷新
- ✅ 美观的 SwiftUI 界面

## 配置 API 地址

在 `MindFlow/Services/APIClient.swift` 中配置 API 基础 URL：

```swift
private let baseURL: String = {
    #if DEBUG
    // 开发环境：iOS 模拟器可以使用 localhost
    // 真机测试需要替换为你的电脑 IP 地址（例如: http://192.168.1.100:5000）
    return "http://localhost:5000"
    #else
    // 生产环境
    return "https://your-server.com"
    #endif
}()
```

**重要提示：**
- iOS 模拟器可以使用 `localhost`
- 真机测试必须使用电脑的实际 IP 地址
- 确保手机和电脑在同一 Wi-Fi 网络
- 确保防火墙允许 5000 端口的连接

## 在 Xcode 中打开项目

1. 双击 `MindFlow.xcodeproj` 文件
2. 或者使用命令行：
   ```bash
   open /Users/lihuaze/Desktop/MindFlow/MindFlow.xcodeproj
   ```

## 运行应用

1. 确保后端服务器正在运行（如果有的话）

2. 在 Xcode 中：
   - 选择目标设备（模拟器或真机）
   - 点击运行按钮（▶️）或按 `Cmd + R`

## 系统要求

- iOS 17.0+
- Xcode 15.0+
- Swift 5.9+

## 注意事项

1. **网络权限**：应用需要网络权限来连接后端 API
2. **API 配置**：真机测试时务必更新 API 地址为实际 IP
3. **证书签名**：在 Xcode 中配置正确的开发团队和证书

## 开发说明

### 数据模型

所有数据模型定义在 `Models/Models.swift` 中，包括：
- `Category` - 分类
- `Item` - 商品
- `CategoryProperty` - 分类属性
- `ColorTier` - 颜色等级枚举

### API 客户端

`Services/APIClient.swift` 包含所有 API 调用方法，使用 async/await 进行异步操作。

### 视图结构

- `ContentView` - 应用主视图，包含导航
- `DashboardView` - 显示所有分类的网格视图
- `CategoryDetailView` - 显示分类下的商品列表

