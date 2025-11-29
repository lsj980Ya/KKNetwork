---
layout: default
title: KKNetwork 完整文档
---

# KKNetwork 完整文档

欢迎使用 KKNetwork！这是一个基于 Alamofire 和 SwiftyJSON 的完整网络请求框架。

## 目录

1. [快速开始](#快速开始)
2. [核心类介绍](core-classes.md)
3. [请求类型](request-types.md)
4. [高级功能](advanced-features.md)
5. [最佳实践](best-practices.md)
6. [API 参考](api-reference.md)

## 快速开始

### 安装

#### CocoaPods

在 `Podfile` 中添加：

```ruby
pod 'KKNetwork'
```

然后运行：

```bash
pod install
```

#### Swift Package Manager

在 `Package.swift` 中添加：

```swift
dependencies: [
    .package(url: "https://github.com/lsj980ya/KKNetwork.git", from: "1.0.0")
]
```

### 初始化

在 `AppDelegate.swift` 中配置：

```swift
import KKNetwork

func application(_ application: UIApplication, 
                didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    
    KKNetwork.setup(
        baseURL: "https://api.example.com",
        backupURLs: [
            "https://api-backup1.example.com",
            "https://api-backup2.example.com"
        ],
        commonHeaders: [
            "Content-Type": "application/json",
            "Accept": "application/json"
        ],
        commonParameters: [
            "platform": "iOS",
            "version": Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
        ],
        timeoutInterval: 30,
        enableLog: true,
        logLevel: .verbose
    )
    
    return true
}
```

### 创建第一个请求

```swift
import KKNetwork
import Alamofire

class UserInfoRequest: KKBaseRequest {
    var userId: String
    
    init(userId: String) {
        self.userId = userId
    }
    
    override func requestPath() -> String {
        return "/api/user/\(userId)"
    }
    
    override func requestMethod() -> HTTPMethod {
        return .get
    }
}
```

### 发起请求

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

## 主要特性

### 1. 自动重试

```swift
class MyRequest: KKBaseRequest {
    override func maxRetryCount() -> Int {
        return 3  // 失败后自动重试 3 次
    }
}
```

### 2. 域名切换

当主域名不可用时，自动切换到备用域名：

```swift
class MyRequest: KKBaseRequest {
    override func enableBackupURLRetry() -> Bool {
        return true  // 启用域名切换
    }
}
```

### 3. 响应缓存

```swift
class UserInfoRequest: KKCacheableRequest {
    override func cachePolicy() -> KKCachePolicy {
        return .cacheElseNetwork  // 先使用缓存，缓存不存在则请求网络
    }
    
    override func cacheMaxAge() -> TimeInterval {
        return 300  // 缓存有效期 5 分钟
    }
}
```

### 4. 批量请求

```swift
let request1 = UserInfoRequest(userId: "1")
let request2 = UserInfoRequest(userId: "2")
let request3 = UserInfoRequest(userId: "3")

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

### 5. 链式请求

```swift
let loginRequest = LoginRequest(username: "test", password: "123456")
let userInfoRequest = UserInfoRequest(userId: "123")

let chainRequest = KKChainRequest()
chainRequest
    .addRequest(loginRequest) { chain, finishedRequest in
        // 根据登录结果配置下一个请求
        if let token = finishedRequest.responseJSON?["token"].string {
            KKNetworkConfig.shared.commonHeaders.add(name: "Authorization", value: "Bearer \(token)")
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

### 6. 文件上传

```swift
class UploadImageRequest: KKUploadRequest {
    var imageData: Data
    
    init(imageData: Data) {
        self.imageData = imageData
    }
    
    override func requestPath() -> String {
        return "/api/upload/image"
    }
    
    override func uploadData() -> [String: KKUploadData] {
        return [
            "file": .data(imageData, fileName: "image.jpg", mimeType: "image/jpeg")
        ]
    }
}

// 使用
let request = UploadImageRequest(imageData: imageData)
request.progressBlock = { progress in
    print("上传进度: \(progress.fractionCompleted * 100)%")
}
request.start(
    success: { _ in
        print("上传成功")
    },
    failure: { _ in
        print("上传失败")
    }
)
```

### 7. 文件下载

```swift
class DownloadFileRequest: KKDownloadRequest {
    var fileURL: String
    var savePath: URL
    
    init(fileURL: String, savePath: URL) {
        self.fileURL = fileURL
        self.savePath = savePath
    }
    
    override func requestPath() -> String {
        return fileURL
    }
    
    override func downloadDestination() -> URL? {
        return savePath
    }
}

// 使用
let request = DownloadFileRequest(
    fileURL: "https://example.com/file.zip",
    savePath: destinationURL
)
request.progressBlock = { progress in
    print("下载进度: \(progress.fractionCompleted * 100)%")
}
request.start(
    success: { request in
        print("下载完成，文件路径: \(request.downloadedFileURL?.path ?? "")")
    },
    failure: { _ in
        print("下载失败")
    }
)
```

### 8. Async/Await 支持

```swift
@available(iOS 13.0, *)
func fetchUserInfo() async throws {
    let request = UserInfoRequest(userId: "123")
    let json = try await request.asyncStart()
    print("用户信息: \(json)")
}
```

### 9. Combine 支持

```swift
@available(iOS 13.0, *)
func fetchUserWithCombine() {
    let request = UserInfoRequest(userId: "123")
    request.publisher()
        .sink(
            receiveCompletion: { completion in
                switch completion {
                case .finished:
                    print("请求完成")
                case .failure(let error):
                    print("请求失败: \(error)")
                }
            },
            receiveValue: { json in
                print("用户信息: \(json)")
            }
        )
        .store(in: &cancellables)
}
```

### 10. 请求拦截器

```swift
// Token 拦截器
let tokenInterceptor = KKTokenInterceptor {
    return UserDefaults.standard.string(forKey: "token")
}
KKNetworkConfig.shared.addInterceptor(tokenInterceptor)

// 自定义拦截器
class CustomInterceptor: KKRequestInterceptor {
    func willSend(_ request: KKBaseRequest) {
        print("请求即将发送: \(request.requestPath())")
    }
    
    func didReceive(_ request: KKBaseRequest, error: Error?) {
        if let error = error {
            print("请求失败: \(error)")
        } else {
            print("请求成功: \(request.requestPath())")
        }
    }
}

KKNetworkConfig.shared.addInterceptor(CustomInterceptor())
```

## 下一步

- 查看 [核心类介绍](core-classes.md) 了解框架的核心组件
- 查看 [请求类型](request-types.md) 了解不同的请求类型
- 查看 [高级功能](advanced-features.md) 了解更多高级用法
- 查看 [最佳实践](best-practices.md) 了解推荐的使用方式
- 查看 [API 参考](api-reference.md) 了解完整的 API 文档

## 支持

如果您在使用过程中遇到问题，请：

1. 查看文档
2. 搜索 [Issues](https://github.com/lsj980ya/KKNetwork/issues)
3. 提交新的 Issue

## 贡献

欢迎贡献代码！请查看 [贡献指南](../CONTRIBUTING.md)。

## 许可证

KKNetwork 使用 MIT 许可证。详见 [LICENSE](../LICENSE) 文件。
