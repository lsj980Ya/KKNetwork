# KKNetwork

[![Swift](https://img.shields.io/badge/Swift-5.5+-orange.svg)](https://swift.org)
[![Platform](https://img.shields.io/badge/platform-iOS%2013.0%2B%20%7C%20macOS%2010.15%2B-lightgrey.svg)](https://developer.apple.com)
[![SPM](https://img.shields.io/badge/SPM-compatible-brightgreen.svg)](https://swift.org/package-manager)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

一个功能强大、易于使用的 Swift 网络库，基于 Alamofire 构建，提供丰富的高级功能。

## ✨ 特性

### 核心功能
- 🚀 基于 Alamofire，性能强劲
- 📦 使用 Swift Package Manager 轻松集成
- 🔄 自动重试机制，支持域名切换
- 📝 完善的日志系统
- 🎯 请求拦截器，支持请求和响应拦截
- 💾 响应缓存，支持多种缓存策略

### 高级功能
- 🔗 批量请求和链式请求
- 📤 文件上传，支持进度监听
- 📥 文件下载，支持断点续传
- 🔐 参数签名（MD5/SHA1/SHA256）
- ⚡ Async/Await 支持
- 🔄 Combine 支持
- 📡 RxSwift 支持

### 扩展功能
- 🌐 WebSocket 支持
- 📊 GraphQL 支持
- 🛡️ 熔断器、限流器、负载均衡
- 📄 分页请求、流式请求
- 🧪 A/B 测试、金丝雀发布
- 🎭 Mock 数据支持

## 📦 安装

### Swift Package Manager（推荐）

在 `Package.swift` 中添加：

```swift
dependencies: [
    .package(url: "https://github.com/yourusername/KKNetwork.git", from: "1.0.0")
]
```

或在 Xcode 中：
1. File → Add Packages...
2. 输入仓库 URL
3. 选择版本并添加

### CocoaPods

在 `Podfile` 中添加：

```ruby
pod 'KKNetwork'
```

然后运行：

```bash
pod install
```

## 🚀 快速开始

### 1. 初始化配置

```swift
import KKNetwork

// 在 AppDelegate 中配置
func application(_ application: UIApplication,
                didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    
    KKNetworkConfig.shared.setup(
        baseURL: "https://api.example.com",
        backupURLs: ["https://api-backup.example.com"],
        commonHeaders: ["Content-Type": "application/json"],
        userAgent: "MyApp/1.0 iOS",
        timeout: 30,
        enableLog: true,
        logLevel: .verbose
    )
    
    return true
}
```

### 2. 创建请求

```swift
class UserInfoRequest: KKBaseRequest {
    let userId: String
    
    init(userId: String) {
        self.userId = userId
    }
    
    override func requestPath() -> String {
        return "/api/user/\(userId)"
    }
    
    override func requestMethod() -> KKRequestMethod {
        return .get
    }
}
```

### 3. 发起请求

```swift
let request = UserInfoRequest(userId: "123")
request.start(
    success: { request in
        if let json = request.responseJSON {
            print("用户信息: \(json)")
        }
    },
    failure: { request in
        print("请求失败: \(request.error?.localizedDescription ?? "")")
    }
)
```

## 🎯 核心功能

### 1. 自动重试和域名切换

```swift
class MyRequest: KKBaseRequest {
    override func maxRetryCount() -> Int {
        return 3  // 失败后重试 3 次
    }
    
    override func enableBackupURL() -> Bool {
        return true  // 启用域名切换
    }
}
```

### 2. 响应缓存

支持多种缓存策略：
- `cacheOnly` - 只使用缓存
- `networkOnly` - 只使用网络
- `cacheElseNetwork` - 先缓存后网络
- `networkElseCache` - 先网络后缓存
- `cacheThenNetwork` - 先返回缓存再更新

```swift
class UserInfoRequest: KKCacheableRequest {
    override func requestPath() -> String {
        return "/api/user/info"
    }
    
    override func cachePolicy() -> KKCachePolicy {
        return .cacheElseNetwork  // 有缓存则使用缓存，否则请求网络
    }
    
    override func cacheMaxAge() -> TimeInterval {
        return 300  // 缓存 5 分钟
    }
}
```

### 3. 请求拦截器

```swift
// Token 拦截器
let tokenInterceptor = KKTokenInterceptor { request in
    return UserDefaults.standard.string(forKey: "token")
}

KKNetworkConfig.shared.addInterceptor(tokenInterceptor)

// 自定义拦截器
class CustomInterceptor: KKRequestInterceptor {
    func willSend(_ request: KKBaseRequest) {
        print("请求即将发送")
    }
    
    func didReceive(_ request: KKBaseRequest, error: Error?) {
        print("请求已完成")
    }
}
```

### 4. SwiftyJSON 模型转换

```swift
// 定义模型
struct User: JSONMappable {
    let id: String
    let name: String
    let email: String
    
    init?(json: JSON) {
        guard let id = json["id"].string,
              let name = json["name"].string,
              let email = json["email"].string else {
            return nil
        }
        self.id = id
        self.name = name
        self.email = email
    }
}

// 使用
request.start(success: { request in
    // 解析单个模型
    if let user = request.mapToModel(User.self) {
        print(user.name)
    }
    
    // 解析数组
    if let users = request.mapToModelArray(User.self, path: "data.users") {
        print("用户数量: \(users.count)")
    }
    
    // 从指定路径解析
    if let user = request.mapToModel(User.self, path: "data.user") {
        print(user.name)
    }
})
```

### 5. 参数签名

```swift
// 配置签名
KKSignatureManager.shared.isEnabled = true
KKSignatureManager.shared.algorithm = .sha256
KKSignatureManager.shared.secretKey = "your_secret_key"

// 使用签名请求
class SecureRequest: KKSignableRequest {
    override func requestParameters() -> [String: Any]? {
        return ["key": "value"]
    }
}

// 参数会自动添加签名、时间戳和随机数
let request = SecureRequest()
request.start()
```

## � 高级功能

### 批量请求

```swift
let request1 = UserInfoRequest(userId: "1")
let request2 = OrderListRequest(userId: "1")
let request3 = MessageListRequest(userId: "1")

let batchRequest = KKBatchRequest(requests: [request1, request2, request3])
batchRequest.start(
    success: {
        print("所有请求成功")
    },
    failure: { failedRequest in
        print("有请求失败")
    }
)
```

### 链式请求

```swift
let loginRequest = LoginRequest(username: "test", password: "123456")
let userInfoRequest = UserInfoRequest(userId: "123")

let chainRequest = KKChainRequest()
    .addRequest(loginRequest) { chainRequest, finishedRequest in
        // 登录成功后保存 Token
        if let token = finishedRequest.responseJSON?["token"].string {
            KKNetworkConfig.shared.commonHeaders.add(
                name: "Authorization",
                value: "Bearer \(token)"
            )
        }
    }
    .addRequest(userInfoRequest)
    .start(
        success: {
            print("链式请求全部完成")
        },
        failure: { failedRequest in
            print("链式请求失败")
        }
    )
```

### 文件上传

```swift
class UploadImageRequest: KKUploadRequest {
    let imageData: Data
    
    init(imageData: Data) {
        self.imageData = imageData
    }
    
    override func requestPath() -> String {
        return "/api/upload/image"
    }
    
    override func uploadFiles() -> [String: KKUploadFile] {
        return [
            "file": .data(imageData, fileName: "image.jpg", mimeType: "image/jpeg")
        ]
    }
}

// 使用
let request = UploadImageRequest(imageData: imageData)
request.progressBlock = { progress in
    print("上传进度: \(Int(progress.fractionCompleted * 100))%")
}
request.start()
```

### Async/Await

```swift
@available(iOS 13.0, *)
func fetchUserInfo() async throws {
    let request = UserInfoRequest(userId: "123")
    let json = try await request.asyncStart()
    print("用户信息: \(json)")
}
```

### Combine

```swift
@available(iOS 13.0, *)
func fetchUserInfo() {
    let request = UserInfoRequest(userId: "123")
    request.publisher()
        .sink(
            receiveCompletion: { completion in
                print("完成: \(completion)")
            },
            receiveValue: { json in
                print("用户信息: \(json)")
            }
        )
        .store(in: &cancellables)
}
```

## 📖 文档

### 在线文档
📖 [https://yourusername.github.io/KKNetwork/](https://yourusername.github.io/KKNetwork/)

### 本地文档
- [项目结构](STRUCTURE.md) - 目录结构说明
- [核心类介绍](docs/core-classes.md) - 核心类详解
- [请求类型](docs/request-types.md) - 各种请求类型
- [高级功能](docs/advanced-features.md) - 高级用法
- [最佳实践](docs/best-practices.md) - 推荐用法
- [API 参考](docs/api-reference.md) - 完整 API

### 示例代码
- [基础示例](Examples/Basic/) - 基本用法
- [高级示例](Examples/Advanced/) - 高级功能

#### 特定功能
- [SwiftyJSON 模型转换](Examples/Features/SwiftyJSONModelExample.swift)
- [参数签名](Examples/Features/SignatureExample.swift)

## 🏗️ 架构设计

```
Sources/
├── Core/           # 核心功能
│   ├── Base/       # 基础类（请求、配置、日志）
│   ├── Request/    # 批量请求、链式请求
│   └── Interceptor/# 拦截器
├── Features/       # 功能模块
│   ├── Cache/      # 缓存
│   ├── Upload/     # 上传
│   ├── Download/   # 下载
│   ├── Security/   # 安全（签名、证书）
│   ├── Mock/       # Mock 数据
│   └── WebSocket/  # WebSocket
├── Advanced/       # 高级功能
│   ├── GraphQL/    # GraphQL
│   ├── Streaming/  # 流式请求
│   ├── Pagination/ # 分页
│   └── Offline/    # 离线支持
├── Plugins/        # 插件系统
│   ├── Analytics/  # 分析统计
│   ├── Metrics/    # 性能指标
│   └── Tracing/    # 请求追踪
├── Utilities/      # 工具类
│   ├── Queue/      # 请求队列
│   ├── Priority/   # 优先级
│   └── Debounce/   # 防抖
├── Infrastructure/ # 基础设施
│   ├── Network/    # 网络（可达性、DNS、负载均衡）
│   └── Resilience/ # 弹性（熔断、降级、限流）
├── Middleware/     # 中间件
│   └── Compression/# 压缩
├── Experimental/   # 实验性功能
│   ├── ABTest/     # A/B 测试
│   ├── Canary/     # 金丝雀发布
│   └── Idempotent/ # 幂等性
└── Extensions/     # 扩展（Async/Await、Combine、RxSwift）
```

详细结构请查看：[STRUCTURE.md](STRUCTURE.md)

## 🛠️ 系统要求

- iOS 13.0+ / macOS 10.15+
- Xcode 14.0+
- Swift 5.5+

## 📊 依赖

- [Alamofire](https://github.com/Alamofire/Alamofire) 5.6.0+
- [SwiftyJSON](https://github.com/SwiftyJSON/SwiftyJSON) 5.0.0+

## 🤝 贡献

欢迎贡献代码！请：

1. Fork 本仓库
2. 创建特性分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 创建 Pull Request

## 📝 更新日志

查看 [Releases](https://github.com/yourusername/KKNetwork/releases) 了解版本更新。

## 📄 许可证

KKNetwork 使用 MIT 许可证。详见 [LICENSE](LICENSE) 文件。

## 📞 联系方式

- 提交 Issue: [GitHub Issues](https://github.com/yourusername/KKNetwork/issues)
- 查看文档: [在线文档](https://yourusername.github.io/KKNetwork/)

## 🌟 Star History

如果这个项目对你有帮助，请给个 Star ⭐️

---

Made with ❤️ by KKNetwork Team
