---
layout: default
title: 最佳实践
---

# 最佳实践

本文档介绍使用 KKNetwork 的最佳实践和推荐模式。

## 目录

- [项目结构](#项目结构)
- [请求管理](#请求管理)
- [错误处理](#错误处理)
- [缓存策略](#缓存策略)
- [性能优化](#性能优化)
- [安全性](#安全性)
- [测试](#测试)

---

## 项目结构

### 推荐的目录结构

```
YourProject/
├── Network/
│   ├── NetworkConfig.swift       # 网络配置
│   ├── NetworkError.swift        # 错误定义
│   ├── Interceptors/             # 拦截器
│   │   ├── TokenInterceptor.swift
│   │   ├── ErrorInterceptor.swift
│   │   └── LogInterceptor.swift
│   ├── Requests/                 # 请求类
│   │   ├── User/
│   │   │   ├── LoginRequest.swift
│   │   │   ├── UserInfoRequest.swift
│   │   │   └── UpdateUserRequest.swift
│   │   ├── Order/
│   │   │   ├── OrderListRequest.swift
│   │   │   └── OrderDetailRequest.swift
│   │   └── Common/
│   │       └── UploadImageRequest.swift
│   └── Models/                   # 数据模型
│       ├── User.swift
│       ├── Order.swift
│       └── Response.swift
```

### 网络配置文件

创建一个统一的网络配置文件：

```swift
// NetworkConfig.swift
import KKNetwork

class NetworkConfig {
    static func setup() {
        #if DEBUG
        let baseURL = "https://dev-api.example.com"
        let enableLog = true
        let logLevel = KKLogLevel.verbose
        #else
        let baseURL = "https://api.example.com"
        let enableLog = false
        let logLevel = KKLogLevel.error
        #endif
        
        KKNetwork.setup(
            baseURL: baseURL,
            backupURLs: [
                "https://api-backup1.example.com",
                "https://api-backup2.example.com"
            ],
            commonHeaders: [
                "Content-Type": "application/json",
                "Accept": "application/json",
                "App-Version": Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
            ],
            commonParameters: [
                "platform": "iOS",
                "device_id": UIDevice.current.identifierForVendor?.uuidString ?? ""
            ],
            timeoutInterval: 30,
            enableLog: enableLog,
            logLevel: logLevel
        )
        
        // 添加拦截器
        setupInterceptors()
    }
    
    private static func setupInterceptors() {
        // Token 拦截器
        let tokenInterceptor = KKTokenInterceptor {
            return UserDefaults.standard.string(forKey: "token")
        }
        KKNetworkConfig.shared.addInterceptor(tokenInterceptor)
        
        // 错误处理拦截器
        KKNetworkConfig.shared.addInterceptor(ErrorHandlerInterceptor())
        
        // 性能监控拦截器
        #if DEBUG
        KKNetworkConfig.shared.addInterceptor(PerformanceInterceptor())
        #endif
    }
}
```

在 `AppDelegate` 中调用：

```swift
func application(_ application: UIApplication, 
                didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    NetworkConfig.setup()
    return true
}
```

---

## 请求管理

### 基础请求类

创建一个基础请求类，统一处理通用逻辑：

```swift
// BaseAPIRequest.swift
import KKNetwork

class BaseAPIRequest: KKBaseRequest {
    // 统一的响应验证
    override func validateResponse(_ json: JSON) -> Bool {
        let code = json["code"].intValue
        return code == 200
    }
    
    // 统一的错误消息提取
    override func errorMessageFromResponse(_ json: JSON) -> String? {
        return json["message"].string ?? json["msg"].string
    }
    
    // 默认重试 2 次
    override func maxRetryCount() -> Int {
        return 2
    }
}
```

### 请求分类

按业务模块组织请求类：

```swift
// User/LoginRequest.swift
class LoginRequest: BaseAPIRequest {
    var username: String
    var password: String
    
    init(username: String, password: String) {
        self.username = username
        self.password = password
    }
    
    override func requestPath() -> String {
        return "/api/v1/auth/login"
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

// User/UserInfoRequest.swift
class UserInfoRequest: KKCacheableRequest {
    var userId: String
    
    init(userId: String) {
        self.userId = userId
    }
    
    override func requestPath() -> String {
        return "/api/v1/user/\(userId)"
    }
    
    override func cachePolicy() -> KKCachePolicy {
        return .cacheElseNetwork
    }
    
    override func cacheMaxAge() -> TimeInterval {
        return 300  // 5 分钟
    }
}
```

### 使用 Service 层

创建 Service 层封装网络请求：

```swift
// UserService.swift
class UserService {
    static let shared = UserService()
    private init() {}
    
    // 登录
    func login(username: String, password: String, completion: @escaping (Result<User, Error>) -> Void) {
        let request = LoginRequest(username: username, password: password)
        request.start(
            success: { request in
                if let user = request.decode(User.self) {
                    completion(.success(user))
                } else {
                    let error = NSError(domain: "UserService", code: -1, userInfo: [NSLocalizedDescriptionKey: "解析失败"])
                    completion(.failure(error))
                }
            },
            failure: { request in
                let error = request.error ?? NSError(domain: "UserService", code: -1, userInfo: [NSLocalizedDescriptionKey: "未知错误"])
                completion(.failure(error))
            }
        )
    }
    
    // 获取用户信息
    func getUserInfo(userId: String, completion: @escaping (Result<User, Error>) -> Void) {
        let request = UserInfoRequest(userId: userId)
        request.start(
            success: { request in
                if let user = request.decode(User.self) {
                    completion(.success(user))
                } else {
                    let error = NSError(domain: "UserService", code: -1, userInfo: [NSLocalizedDescriptionKey: "解析失败"])
                    completion(.failure(error))
                }
            },
            failure: { request in
                let error = request.error ?? NSError(domain: "UserService", code: -1, userInfo: [NSLocalizedDescriptionKey: "未知错误"])
                completion(.failure(error))
            }
        )
    }
}

// 使用
UserService.shared.login(username: "test", password: "123456") { result in
    switch result {
    case .success(let user):
        print("登录成功: \(user.name)")
    case .failure(let error):
        print("登录失败: \(error.localizedDescription)")
    }
}
```

### 使用 Async/Await 的 Service

```swift
@available(iOS 13.0, *)
class UserService {
    static let shared = UserService()
    private init() {}
    
    func login(username: String, password: String) async throws -> User {
        let request = LoginRequest(username: username, password: password)
        let json = try await request.asyncStart()
        
        guard let user = try? JSONDecoder().decode(User.self, from: json.rawData()) else {
            throw NSError(domain: "UserService", code: -1, userInfo: [NSLocalizedDescriptionKey: "解析失败"])
        }
        
        return user
    }
    
    func getUserInfo(userId: String) async throws -> User {
        let request = UserInfoRequest(userId: userId)
        let json = try await request.asyncStart()
        
        guard let user = try? JSONDecoder().decode(User.self, from: json.rawData()) else {
            throw NSError(domain: "UserService", code: -1, userInfo: [NSLocalizedDescriptionKey: "解析失败"])
        }
        
        return user
    }
}

// 使用
Task {
    do {
        let user = try await UserService.shared.login(username: "test", password: "123456")
        print("登录成功: \(user.name)")
    } catch {
        print("登录失败: \(error.localizedDescription)")
    }
}
```

---

## 错误处理

### 定义错误类型

```swift
// NetworkError.swift
enum NetworkError: Error {
    case invalidResponse
    case decodingFailed
    case unauthorized
    case forbidden
    case notFound
    case serverError
    case networkUnavailable
    case timeout
    case unknown(Error)
    
    var localizedDescription: String {
        switch self {
        case .invalidResponse:
            return "响应数据无效"
        case .decodingFailed:
            return "数据解析失败"
        case .unauthorized:
            return "未授权，请先登录"
        case .forbidden:
            return "无权限访问"
        case .notFound:
            return "资源不存在"
        case .serverError:
            return "服务器错误"
        case .networkUnavailable:
            return "网络不可用"
        case .timeout:
            return "请求超时"
        case .unknown(let error):
            return error.localizedDescription
        }
    }
}
```

### 统一错误处理

```swift
class ErrorHandlerInterceptor: KKRequestInterceptor {
    func didReceive(_ request: KKBaseRequest, error: Error?) {
        guard let error = error else { return }
        
        let nsError = error as NSError
        let networkError: NetworkError
        
        switch nsError.code {
        case NSURLErrorNotConnectedToInternet:
            networkError = .networkUnavailable
        case NSURLErrorTimedOut:
            networkError = .timeout
        case 401:
            networkError = .unauthorized
            // 跳转到登录页
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: .userNeedLogin, object: nil)
            }
        case 403:
            networkError = .forbidden
        case 404:
            networkError = .notFound
        case 500...599:
            networkError = .serverError
        default:
            networkError = .unknown(error)
        }
        
        // 显示错误提示
        DispatchQueue.main.async {
            self.showError(networkError)
        }
    }
    
    private func showError(_ error: NetworkError) {
        // 显示 Toast 或 Alert
        print("错误: \(error.localizedDescription)")
    }
}
```

---

## 缓存策略

### 根据业务选择缓存策略

```swift
// 用户信息 - 优先使用缓存
class UserInfoRequest: KKCacheableRequest {
    override func cachePolicy() -> KKCachePolicy {
        return .cacheElseNetwork
    }
    
    override func cacheMaxAge() -> TimeInterval {
        return 300  // 5 分钟
    }
}

// 新闻列表 - 优先网络，失败使用缓存
class NewsListRequest: KKCacheableRequest {
    override func cachePolicy() -> KKCachePolicy {
        return .networkElseCache
    }
    
    override func cacheMaxAge() -> TimeInterval {
        return 3600  // 1 小时
    }
}

// 商品详情 - 先显示缓存，再更新
class ProductDetailRequest: KKCacheableRequest {
    override func cachePolicy() -> KKCachePolicy {
        return .cacheThenNetwork
    }
    
    override func cacheMaxAge() -> TimeInterval {
        return 1800  // 30 分钟
    }
}

// 实时数据 - 只使用网络
class RealTimeDataRequest: KKCacheableRequest {
    override func cachePolicy() -> KKCachePolicy {
        return .networkOnly
    }
}
```

### 缓存管理

```swift
class CacheManager {
    static let shared = CacheManager()
    private init() {}
    
    // 清除用户相关缓存
    func clearUserCache() {
        KKNetworkCache.shared.removeCache(forKey: "user_info")
        KKNetworkCache.shared.removeCache(forKey: "user_orders")
    }
    
    // 清除所有缓存
    func clearAllCache() {
        KKNetworkCache.shared.clearAllCache()
    }
    
    // 登出时清除缓存
    func logout() {
        clearAllCache()
        UserDefaults.standard.removeObject(forKey: "token")
    }
}
```

---

## 性能优化

### 1. 使用批量请求

```swift
// 不推荐：串行请求
func fetchDataSerially() {
    UserInfoRequest().start { _ in
        OrderListRequest().start { _ in
            MessageListRequest().start { _ in
                print("全部完成")
            }
        }
    }
}

// 推荐：批量请求
func fetchDataInBatch() {
    let requests = [
        UserInfoRequest(),
        OrderListRequest(),
        MessageListRequest()
    ]
    
    KKBatchRequest(requests: requests).start(
        success: {
            print("全部完成")
        }
    )
}
```

### 2. 合理使用缓存

```swift
// 频繁访问的数据使用缓存
class FrequentDataRequest: KKCacheableRequest {
    override func cachePolicy() -> KKCachePolicy {
        return .cacheElseNetwork
    }
    
    override func cacheMaxAge() -> TimeInterval {
        return 600  // 10 分钟
    }
}
```

### 3. 控制并发数

```swift
// 使用请求队列控制并发
let requests = (1...100).map { UserInfoRequest(userId: "\($0)") }

for request in requests {
    KKRequestQueue.shared.enqueue(request)
}

// 设置最大并发数
KKRequestQueue.shared.maxConcurrentRequests = 5
```

### 4. 取消不需要的请求

```swift
class ViewController: UIViewController {
    var currentRequest: KKBaseRequest?
    
    func loadData() {
        // 取消之前的请求
        currentRequest?.cancel()
        
        // 发起新请求
        let request = DataRequest()
        currentRequest = request
        request.start()
    }
    
    deinit {
        // 页面销毁时取消请求
        currentRequest?.cancel()
    }
}
```

### 5. 图片下载优化

```swift
class ImageCache {
    static let shared = ImageCache()
    private var cache = NSCache<NSString, UIImage>()
    private var downloadingURLs = Set<String>()
    
    func loadImage(url: String, completion: @escaping (UIImage?) -> Void) {
        // 1. 检查内存缓存
        if let cachedImage = cache.object(forKey: url as NSString) {
            completion(cachedImage)
            return
        }
        
        // 2. 检查是否正在下载
        if downloadingURLs.contains(url) {
            return
        }
        
        // 3. 下载图片
        downloadingURLs.insert(url)
        
        let request = DownloadImageRequest(imageURL: url)
        request.start(
            success: { [weak self] request in
                self?.downloadingURLs.remove(url)
                
                if let fileURL = request.downloadedFileURL,
                   let imageData = try? Data(contentsOf: fileURL),
                   let image = UIImage(data: imageData) {
                    self?.cache.setObject(image, forKey: url as NSString)
                    completion(image)
                } else {
                    completion(nil)
                }
            },
            failure: { [weak self] _ in
                self?.downloadingURLs.remove(url)
                completion(nil)
            }
        )
    }
}
```

---

## 安全性

### 1. HTTPS

始终使用 HTTPS：

```swift
KKNetwork.setup(
    baseURL: "https://api.example.com",  // 使用 HTTPS
    backupURLs: [
        "https://api-backup.example.com"
    ]
)
```

### 2. Token 管理

安全地存储和使用 Token：

```swift
class TokenManager {
    static let shared = TokenManager()
    private init() {}
    
    private let tokenKey = "user_token"
    
    var token: String? {
        get {
            // 使用 Keychain 存储 Token（更安全）
            return KeychainWrapper.standard.string(forKey: tokenKey)
        }
        set {
            if let token = newValue {
                KeychainWrapper.standard.set(token, forKey: tokenKey)
            } else {
                KeychainWrapper.standard.removeObject(forKey: tokenKey)
            }
        }
    }
    
    func clearToken() {
        token = nil
    }
}

// 使用 Token 拦截器
let tokenInterceptor = KKTokenInterceptor {
    return TokenManager.shared.token
}
KKNetworkConfig.shared.addInterceptor(tokenInterceptor)
```

### 3. 参数加密

对敏感参数进行加密：

```swift
class SecureRequest: KKBaseRequest {
    var sensitiveData: String
    
    init(sensitiveData: String) {
        self.sensitiveData = sensitiveData
    }
    
    override func requestParameters() -> [String: Any]? {
        // 加密敏感数据
        let encryptedData = encrypt(sensitiveData)
        
        return [
            "data": encryptedData
        ]
    }
    
    private func encrypt(_ data: String) -> String {
        // 实现加密逻辑
        return data
    }
}
```

### 4. 请求签名

添加请求签名防止篡改：

```swift
class SignatureInterceptor: KKRequestInterceptor {
    func willSend(_ request: KKBaseRequest) {
        let timestamp = String(Int(Date().timeIntervalSince1970))
        let nonce = UUID().uuidString
        
        var params = request.requestParameters() ?? [:]
        params["timestamp"] = timestamp
        params["nonce"] = nonce
        
        // 生成签名
        let signature = generateSignature(params: params)
        
        // 添加签名到请求头
        KKNetworkConfig.shared.commonHeaders.add(name: "X-Signature", value: signature)
    }
    
    private func generateSignature(params: [String: Any]) -> String {
        // 1. 排序参数
        let sortedParams = params.sorted { $0.key < $1.key }
        
        // 2. 拼接字符串
        let paramString = sortedParams.map { "\($0.key)=\($0.value)" }.joined(separator: "&")
        
        // 3. 添加密钥
        let signString = paramString + "&key=YOUR_SECRET_KEY"
        
        // 4. 计算 MD5 或 SHA256
        return signString.md5()
    }
}
```

---

## 测试

### 单元测试

```swift
import XCTest
@testable import YourApp

class NetworkTests: XCTestCase {
    func testLoginRequest() {
        let expectation = self.expectation(description: "Login")
        
        let request = LoginRequest(username: "test", password: "123456")
        request.start(
            success: { request in
                XCTAssertNotNil(request.responseJSON)
                XCTAssertEqual(request.responseJSON?["code"].intValue, 200)
                expectation.fulfill()
            },
            failure: { request in
                XCTFail("Request failed: \(request.error?.localizedDescription ?? "")")
                expectation.fulfill()
            }
        )
        
        waitForExpectations(timeout: 10, handler: nil)
    }
    
    func testUserInfoCache() {
        let request = UserInfoRequest(userId: "123")
        XCTAssertEqual(request.cachePolicy(), .cacheElseNetwork)
        XCTAssertEqual(request.cacheMaxAge(), 300)
    }
}
```

### 使用 Mock 数据

```swift
// 在测试环境使用 Mock 数据
#if DEBUG
class MockLoginRequest: LoginRequest {
    override func start(success: ((KKBaseRequest) -> Void)? = nil,
                       failure: ((KKBaseRequest) -> Void)? = nil) -> Self {
        // 模拟延迟
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            // 返回 Mock 数据
            self.responseJSON = JSON([
                "code": 200,
                "message": "success",
                "data": [
                    "token": "mock_token",
                    "user": [
                        "id": "123",
                        "name": "Test User"
                    ]
                ]
            ])
            success?(self)
        }
        return self
    }
}
#endif
```

---

## 总结

遵循这些最佳实践可以帮助你：

1. **代码组织清晰**：按业务模块组织请求类
2. **错误处理统一**：使用拦截器统一处理错误
3. **性能优化**：合理使用缓存和批量请求
4. **安全可靠**：使用 HTTPS、Token 管理、请求签名
5. **易于测试**：使用 Service 层和 Mock 数据

## 下一步

- 查看 [API 参考](api-reference.md) 了解完整的 API 文档
- 查看 [核心类介绍](core-classes.md) 了解框架的核心组件
- 查看 [请求类型](request-types.md) 了解不同的请求类型
