# KKNetwork

[![Swift](https://img.shields.io/badge/Swift-5.5+-orange.svg)](https://swift.org)
[![Platform](https://img.shields.io/badge/platform-iOS%2013.0%2B%20%7C%20macOS%2010.15%2B-lightgrey.svg)](https://developer.apple.com)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

基于 Alamofire 和 SwiftyJSON 的完整网络请求框架，参考 YTKNetwork 设计思路。

## 特性

- ✅ 基于 Alamofire 5.x
- ✅ 使用 SwiftyJSON 进行 JSON 解析
- ✅ 支持请求重试机制
- ✅ 支持域名切换重试
- ✅ 完善的日志系统
- ✅ 请求拦截器
- ✅ 响应缓存
- ✅ 批量请求
- ✅ 链式请求
- ✅ 文件上传/下载
- ✅ 公共参数和请求头
- ✅ Async/Await 支持
- ✅ Combine 支持
- ✅ RxSwift 支持

## 安装

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

## 快速开始

### 1. 初始化配置

在 `AppDelegate` 中配置网络框架：

```swift
import KKNetwork

KKNetwork.setup(
    baseURL: "https://api.example.com",
    backupURLs: [
        "https://api-backup1.example.com",
        "https://api-backup2.example.com"
    ],
    commonHeaders: [
        "Content-Type": "application/json"
    ],
    commonParameters: [
        "platform": "iOS",
        "version": "1.0.0"
    ],
    timeoutInterval: 30,
    enableLog: true,
    logLevel: .verbose
)
```

### 2. 创建请求类

```swift
class LoginRequest: KKBaseRequest {
    var username: String
    var password: String
    
    init(username: String, password: String) {
        self.username = username
        self.password = password
    }
    
    override func requestPath() -> String {
        return "/api/login"
    }
    
    override func requestMethod() -> HTTPMethod {
        return .post
    }
    
    override func requestParameters() -> [String: Any]? {
        return [
            "username": username,
            "password": password
        ]
    }
}
```

### 3. 发起请求

```swift
let request = LoginRequest(username: "test", password: "123456")
request.start(
    success: { request in
        if let json = request.responseJSON {
            print("登录成功: \(json)")
        }
    },
    failure: { request in
        print("登录失败: \(request.error?.localizedDescription ?? "")")
    }
)
```

## 文档

完整文档请访问：[KKNetwork Documentation](docs/index.md)

- [核心类介绍](docs/core-classes.md)
- [请求类型](docs/request-types.md)
- [高级功能](docs/advanced-features.md)
- [最佳实践](docs/best-practices.md)

## 架构设计

```
KKNetwork/
├── Core/                      # 核心模块
│   ├── KKNetworkConfig.swift  # 网络配置
│   ├── KKBaseRequest.swift    # 基础请求类
│   ├── KKNetworkLogger.swift  # 日志工具
│   ├── KKRequestInterceptor.swift # 拦截器
│   ├── KKBatchRequest.swift   # 批量请求
│   └── KKChainRequest.swift   # 链式请求
├── Request/                   # 请求类型
│   ├── KKCacheableRequest.swift # 缓存请求
│   ├── KKUploadRequest.swift  # 上传请求
│   └── KKDownloadRequest.swift # 下载请求
├── Cache/                     # 缓存模块
│   └── KKNetworkCache.swift   # 缓存管理
└── Extensions/                # 扩展
    └── KKRequestExtensions.swift # 便捷扩展
```

## License

MIT License

Copyright (c) 2024 KKNetwork

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
