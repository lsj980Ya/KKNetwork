---
layout: default
title: 核心类介绍
---

# 核心类介绍

本文档详细介绍 KKNetwork 框架的核心类及其使用方法。

## 目录

- [KKNetworkConfig](#kknetworkconfig)
- [KKBaseRequest](#kkbaserequest)
- [KKBatchRequest](#kkbatchrequest)
- [KKChainRequest](#kkchainrequest)
- [KKNetworkLogger](#kknetworklogger)
- [KKRequestInterceptor](#kkrequestinterceptor)

---

## KKNetworkConfig

网络配置管理类，用于配置全局网络参数。

### 属性

| 属性 | 类型 | 说明 |
|------|------|------|
| `baseURL` | `String` | 主域名 |
| `backupBaseURLs` | `[String]` | 备用域名列表 |
| `commonHeaders` | `HTTPHeaders` | 公共请求头 |
| `commonParameters` | `[String: Any]` | 公共参数 |
| `timeoutInterval` | `TimeInterval` | 超时时间（默认 30 秒）|
| `enableLog` | `Bool` | 是否启用日志 |
| `logLevel` | `KKLogLevel` | 日志级别 |

### 方法

#### addInterceptor(_:)

添加请求拦截器。

```swift
public func addInterceptor(_ interceptor: KKRequestInterceptor)
```

**示例：**

```swift
let tokenInterceptor = KKTokenInterceptor {
    return UserDefaults.standard.string(forKey: "token")
}
KKNetworkConfig.shared.addInterceptor(tokenInterceptor)
```

#### removeAllInterceptors()

移除所有拦截器。

```swift
public func removeAllInterceptors()
```

### 使用示例

```swift
// 配置网络
let config = KKNetworkConfig.shared
config.baseURL = "https://api.example.com"
config.backupBaseURLs = ["https://api-backup.example.com"]
config.timeoutInterval = 30
config.enableLog = true
config.logLevel = .verbose

// 添加公共请求头
config.commonHeaders.add(name: "Content-Type", value: "application/json")
config.commonHeaders.add(name: "Accept", value: "application/json")

// 添加公共参数
config.commonParameters = [
    "platform": "iOS",
    "version": "1.0.0"
]
```

---

## KKBaseRequest

基础请求类，所有请求都应该继承此类。

### 需要重写的方法

#### requestPath()

返回请求路径。

```swift
open func requestPath() -> String
```

**示例：**

```swift
override func requestPath() -> String {
    return "/api/user/\(userId)"
}
```

#### requestMethod()

返回请求方法（默认为 GET）。

```swift
open func requestMethod() -> HTTPMethod
```

**示例：**

```swift
override func requestMethod() -> HTTPMethod {
    return .post
}
```

#### requestParameters()

返回请求参数。

```swift
open func requestParameters() -> [String: Any]?
```

**示例：**

```swift
override func requestParameters() -> [String: Any]? {
    return [
        "username": username,
        "password": password
    ]
}
```

#### requestHeaders()

返回自定义请求头。

```swift
open func requestHeaders() -> HTTPHeaders?
```

**示例：**

```swift
override func requestHeaders() -> HTTPHeaders? {
    return [
        "Custom-Header": "value"
    ]
}
```

### 配置方法

#### maxRetryCount()

返回最大重试次数（默认为 0）。

```swift
open func maxRetryCount() -> Int
```

**示例：**

```swift
override func maxRetryCount() -> Int {
    return 3  // 失败后重试 3 次
}
```

#### enableBackupURLRetry()

是否启用域名切换重试（默认为 true）。

```swift
open func enableBackupURLRetry() -> Bool
```

**示例：**

```swift
override func enableBackupURLRetry() -> Bool {
    return true
}
```

#### customBaseURL()

自定义 BaseURL（如果返回 nil 则使用配置的 baseURL）。

```swift
open func customBaseURL() -> String?
```

**示例：**

```swift
override func customBaseURL() -> String? {
    return "https://custom-api.example.com"
}
```

#### requestTimeoutInterval()

自定义超时时间。

```swift
open func requestTimeoutInterval() -> TimeInterval?
```

**示例：**

```swift
override func requestTimeoutInterval() -> TimeInterval? {
    return 60  // 60 秒超时
}
```

### 响应验证方法

#### validateResponse(_:)

验证响应数据是否有效（默认返回 true）。

```swift
open func validateResponse(_ json: JSON) -> Bool
```

**示例：**

```swift
override func validateResponse(_ json: JSON) -> Bool {
    return json["code"].intValue == 200
}
```

#### errorMessageFromResponse(_:)

从响应中提取错误信息。

```swift
open func errorMessageFromResponse(_ json: JSON) -> String?
```

**示例：**

```swift
override func errorMessageFromResponse(_ json: JSON) -> String? {
    return json["message"].string ?? json["msg"].string
}
```

### 请求控制方法

#### start(success:failure:)

发起请求。

```swift
@discardableResult
public func start(success: ((KKBaseRequest) -> Void)? = nil,
                 failure: ((KKBaseRequest) -> Void)? = nil) -> Self
```

**示例：**

```swift
request.start(
    success: { request in
        print("成功: \(request.responseJSON)")
    },
    failure: { request in
        print("失败: \(request.error)")
    }
)
```

#### cancel()

取消请求。

```swift
public func cancel()
```

**示例：**

```swift
request.cancel()
```

### 响应属性

| 属性 | 类型 | 说明 |
|------|------|------|
| `responseData` | `Data?` | 响应数据 |
| `responseJSON` | `JSON?` | 响应 JSON |
| `responseString` | `String?` | 响应字符串 |
| `error` | `Error?` | 错误信息 |

### 完整示例

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
    
    override func maxRetryCount() -> Int {
        return 2
    }
    
    override func validateResponse(_ json: JSON) -> Bool {
        return json["code"].intValue == 200
    }
    
    override func errorMessageFromResponse(_ json: JSON) -> String? {
        return json["message"].string
    }
}

// 使用
let request = LoginRequest(username: "test", password: "123456")
request.start(
    success: { request in
        if let token = request.responseJSON?["data"]["token"].string {
            print("登录成功，Token: \(token)")
        }
    },
    failure: { request in
        print("登录失败: \(request.error?.localizedDescription ?? "")")
    }
)
```

---

## KKBatchRequest

批量请求管理类，用于同时发起多个请求，所有请求成功才算成功。

### 初始化

```swift
public init(requests: [KKBaseRequest])
```

### 方法

#### start(success:failure:)

开始批量请求。

```swift
@discardableResult
public func start(success: (() -> Void)? = nil,
                 failure: ((KKBaseRequest) -> Void)? = nil) -> Self
```

#### cancel()

取消所有请求。

```swift
public func cancel()
```

### 使用示例

```swift
let request1 = UserInfoRequest(userId: "1")
let request2 = OrderListRequest(userId: "1")
let request3 = MessageListRequest(userId: "1")

let batchRequest = KKBatchRequest(requests: [request1, request2, request3])
batchRequest.start(
    success: {
        print("所有请求成功")
        print("用户信息: \(request1.responseJSON)")
        print("订单列表: \(request2.responseJSON)")
        print("消息列表: \(request3.responseJSON)")
    },
    failure: { failedRequest in
        print("有请求失败: \(failedRequest.requestPath())")
    }
)
```

---

## KKChainRequest

链式请求管理类，用于按顺序执行多个请求，前一个请求成功后才执行下一个。

### 方法

#### addRequest(_:callback:)

添加请求到链中。

```swift
@discardableResult
public func addRequest(_ request: KKBaseRequest, 
                      callback: ChainCallback? = nil) -> Self
```

**ChainCallback 定义：**

```swift
public typealias ChainCallback = (KKChainRequest, KKBaseRequest) -> Void
```

#### start(success:failure:)

开始链式请求。

```swift
@discardableResult
public func start(success: (() -> Void)? = nil,
                 failure: ((KKBaseRequest) -> Void)? = nil) -> Self
```

#### cancel()

取消链式请求。

```swift
public func cancel()
```

### 使用示例

```swift
let loginRequest = LoginRequest(username: "test", password: "123456")
let userInfoRequest = UserInfoRequest(userId: "123")
let orderListRequest = OrderListRequest(userId: "123")

let chainRequest = KKChainRequest()
chainRequest
    .addRequest(loginRequest) { chain, finishedRequest in
        // 登录成功后，保存 Token
        if let token = finishedRequest.responseJSON?["data"]["token"].string {
            KKNetworkConfig.shared.commonHeaders.add(
                name: "Authorization", 
                value: "Bearer \(token)"
            )
        }
    }
    .addRequest(userInfoRequest) { chain, finishedRequest in
        // 获取用户信息后，可以做一些处理
        print("用户信息: \(finishedRequest.responseJSON)")
    }
    .addRequest(orderListRequest)
    .start(
        success: {
            print("链式请求全部完成")
        },
        failure: { failedRequest in
            print("链式请求失败: \(failedRequest.requestPath())")
        }
    )
```

---

## KKNetworkLogger

网络日志工具类，用于打印网络请求和响应信息。

### 日志级别

```swift
public enum KKLogLevel: Int {
    case none = 0      // 不打印
    case error = 1     // 只打印错误
    case info = 2      // 打印基本信息
    case verbose = 3   // 打印详细信息
}
```

### 方法

#### log(_:level:)

打印日志。

```swift
public static func log(_ message: String, level: KKLogLevel = .verbose)
```

**示例：**

```swift
KKNetworkLogger.log("自定义日志", level: .info)
```

### 配置日志

```swift
// 启用日志
KKNetworkConfig.shared.enableLog = true

// 设置日志级别
KKNetworkConfig.shared.logLevel = .verbose

// 关闭日志
KKNetworkConfig.shared.enableLog = false
```

### 日志输出示例

**请求日志：**

```
[14:30:25.123] [KKNetwork] 🚀 开始请求: /api/login

╔═══════════════════════════════════════════════════════════════════════
║ 📤 REQUEST
╠═══════════════════════════════════════════════════════════════════════
║ URL: https://api.example.com/api/login
║ Method: POST
║ Headers:
║   Content-Type: application/json
║   Accept: application/json
║ Parameters:
║   {
║     "username": "test",
║     "password": "123456"
║   }
╚═══════════════════════════════════════════════════════════════════════
```

**响应日志：**

```
╔═══════════════════════════════════════════════════════════════════════
║ 📥 RESPONSE
╠═══════════════════════════════════════════════════════════════════════
║ URL: https://api.example.com/api/login
║ Status Code: 200
║ Response:
║   {
║     "code": 200,
║     "message": "success",
║     "data": {
║       "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
║     }
║   }
╚═══════════════════════════════════════════════════════════════════════

[14:30:25.456] [KKNetwork] ✅ 请求成功: /api/login
```

---

## KKRequestInterceptor

请求拦截器协议，用于在请求发送前后执行自定义逻辑。

### 协议方法

```swift
public protocol KKRequestInterceptor {
    /// 请求即将发送
    func willSend(_ request: KKBaseRequest)
    
    /// 请求已收到响应
    func didReceive(_ request: KKBaseRequest, error: Error?)
}
```

### 内置拦截器

#### KKTokenInterceptor

Token 拦截器，自动添加认证 Token。

```swift
let tokenInterceptor = KKTokenInterceptor {
    return UserDefaults.standard.string(forKey: "token")
}
KKNetworkConfig.shared.addInterceptor(tokenInterceptor)
```

#### KKResponseInterceptor

通用响应拦截器。

```swift
let responseInterceptor = KKResponseInterceptor { request, error in
    if let error = error {
        print("请求失败: \(error)")
    } else {
        print("请求成功: \(request.requestPath())")
    }
}
KKNetworkConfig.shared.addInterceptor(responseInterceptor)
```

### 自定义拦截器

```swift
class CustomInterceptor: KKRequestInterceptor {
    func willSend(_ request: KKBaseRequest) {
        // 请求发送前的处理
        print("即将发送请求: \(request.requestPath())")
        
        // 添加时间戳
        request.userInfo = ["timestamp": Date().timeIntervalSince1970]
    }
    
    func didReceive(_ request: KKBaseRequest, error: Error?) {
        // 请求完成后的处理
        if let error = error {
            print("请求失败: \(error.localizedDescription)")
            
            // 统一错误处理
            if (error as NSError).code == 401 {
                // Token 过期，跳转到登录页
                NotificationCenter.default.post(name: .userNeedLogin, object: nil)
            }
        } else {
            print("请求成功: \(request.requestPath())")
            
            // 计算请求耗时
            if let timestamp = request.userInfo?["timestamp"] as? TimeInterval {
                let duration = Date().timeIntervalSince1970 - timestamp
                print("请求耗时: \(duration) 秒")
            }
        }
    }
}

// 添加拦截器
KKNetworkConfig.shared.addInterceptor(CustomInterceptor())
```

### 实用拦截器示例

#### 统一错误处理拦截器

```swift
class ErrorHandlerInterceptor: KKRequestInterceptor {
    func didReceive(_ request: KKBaseRequest, error: Error?) {
        guard let error = error else { return }
        
        let nsError = error as NSError
        
        switch nsError.code {
        case 401:
            // Token 过期
            NotificationCenter.default.post(name: .userNeedLogin, object: nil)
        case 403:
            // 无权限
            showAlert(message: "您没有权限访问此资源")
        case 404:
            // 资源不存在
            showAlert(message: "请求的资源不存在")
        case 500...599:
            // 服务器错误
            showAlert(message: "服务器错误，请稍后重试")
        default:
            // 其他错误
            showAlert(message: error.localizedDescription)
        }
    }
    
    private func showAlert(message: String) {
        // 显示错误提示
        DispatchQueue.main.async {
            // 显示 Alert 或 Toast
        }
    }
}
```

#### 性能监控拦截器

```swift
class PerformanceInterceptor: KKRequestInterceptor {
    private var requestStartTimes: [String: TimeInterval] = [:]
    
    func willSend(_ request: KKBaseRequest) {
        let key = "\(request.requestPath())-\(request.tag)"
        requestStartTimes[key] = Date().timeIntervalSince1970
    }
    
    func didReceive(_ request: KKBaseRequest, error: Error?) {
        let key = "\(request.requestPath())-\(request.tag)"
        
        if let startTime = requestStartTimes[key] {
            let duration = Date().timeIntervalSince1970 - startTime
            
            // 记录性能数据
            print("📊 请求耗时: \(request.requestPath()) - \(duration) 秒")
            
            // 如果请求时间过长，记录警告
            if duration > 5.0 {
                print("⚠️ 慢请求警告: \(request.requestPath()) 耗时 \(duration) 秒")
            }
            
            requestStartTimes.removeValue(forKey: key)
        }
    }
}
```

---

## 下一步

- 查看 [请求类型](request-types.md) 了解不同的请求类型
- 查看 [高级功能](advanced-features.md) 了解更多高级用法
- 查看 [API 参考](api-reference.md) 了解完整的 API 文档
