# KKNetwork 快速开始

## 🚀 5 分钟快速部署

### 1. 克隆或 Fork 仓库

```bash
git clone https://github.com/yourusername/KKNetwork.git
cd KKNetwork
```

### 2. 启用 GitHub Pages

1. 进入仓库 **Settings** → **Pages**
2. **Source** 选择 "**GitHub Actions**"
3. 保存

### 3. 推送代码

```bash
git add .
git commit -m "Initial commit"
git push origin main
```

### 4. 等待部署

- 进入 **Actions** 标签查看部署进度
- 通常需要 1-2 分钟

### 5. 访问文档

```
https://yourusername.github.io/KKNetwork/
```

## 📦 安装框架

### CocoaPods

```ruby
pod 'KKNetwork'
```

### Swift Package Manager

```swift
dependencies: [
    .package(url: "https://github.com/yourusername/KKNetwork.git", from: "1.0.0")
]
```

## 💻 基本使用

### 1. 配置

```swift
import KKNetwork

KKNetwork.setup(
    baseURL: "https://api.example.com",
    enableLog: true
)
```

### 2. 创建请求

```swift
class UserInfoRequest: KKBaseRequest {
    var userId: String
    
    init(userId: String) {
        self.userId = userId
    }
    
    override func requestPath() -> String {
        return "/api/user/\(userId)"
    }
}
```

### 3. 发起请求

```swift
let request = UserInfoRequest(userId: "123")
request.start(
    success: { request in
        print("成功: \(request.responseJSON)")
    },
    failure: { request in
        print("失败: \(request.error)")
    }
)
```

## 📚 更多文档

- [完整文档](docs/index.md)
- [核心类介绍](docs/core-classes.md)
- [请求类型](docs/request-types.md)
- [高级功能](docs/advanced-features.md)
- [最佳实践](docs/best-practices.md)
- [API 参考](docs/api-reference.md)

## ⚙️ GitHub Pages 配置

详细配置指南：[SETUP_GITHUB_PAGES.md](docs/SETUP_GITHUB_PAGES.md)

## 🐛 遇到问题？

### GitHub Pages 部署失败

1. 确保在 Settings → Pages 选择了 "GitHub Actions"
2. 检查 Actions 权限：Settings → Actions → General → Workflow permissions
3. 手动触发：Actions → Deploy Documentation → Run workflow

### 编译错误

1. 确保 Swift 版本 5.5+
2. 确保依赖正确：Alamofire 5.6+, SwiftyJSON 5.0+
3. 运行 `swift build` 检查错误

## 📞 获取帮助

- [GitHub Issues](https://github.com/yourusername/KKNetwork/issues)
- [文档网站](https://yourusername.github.io/KKNetwork/)

## ⭐ 特性

- ✅ 基于 Alamofire 5.x
- ✅ 使用 SwiftyJSON 解析
- ✅ 自动重试机制
- ✅ 域名切换
- ✅ 响应缓存
- ✅ 批量/链式请求
- ✅ 文件上传/下载
- ✅ Async/Await 支持
- ✅ Combine 支持
- ✅ RxSwift 支持

## 📄 许可证

MIT License
