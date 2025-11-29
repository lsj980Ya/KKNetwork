---
layout: default
title: API 参考
---

# API 参考

完整的 KKNetwork API 文档。

## 目录

- [KKNetwork](#kknetwork)
- [KKNetworkConfig](#kknetworkconfig)
- [KKBaseRequest](#kkbaserequest)
- [KKCacheableRequest](#kkcacheablerequest)
- [KKUploadRequest](#kkuploadrequest)
- [KKDownloadRequest](#kkdownloadrequest)
- [KKBatchRequest](#kkbatchrequest)
- [KKChainRequest](#kkchainrequest)
- [KKNetworkCache](#kknetworkcache)
- [KKNetworkLogger](#kknetworklogger)
- [KKRequestInterceptor](#kkrequestinterceptor)
- [扩展方法](#扩展方法)

---

## KKNetwork

框架入口类。

### 类方法

#### setup(baseURL:backupURLs:commonHeaders:commonParameters:timeoutInterval:enableLog:logLevel:)

配置网络框架。

```swift
public static func setup(
    baseURL: String,
    backupURLs: [String] = [],
    commonHeaders: [String: String] = [:],
    commonParameters: [String: Any] = [:],
    timeoutInterval: TimeInterval = 30,
    enableLog: Bool = true,
    logLevel: KKLogLevel = .verbose
)
```

**参数：**

- `baseURL`: 主域名
- `backupURLs`: 备用域名列表
- `commonHeaders`: 公共请求头
- `commonParameters`: 公共参数
- `timeoutInterval`: 超时时间（秒）
- `enableLog`: 是否启用日志
- `logLevel`: 日志级别

**示例：**

```swift
KKNetwork.setup(
    baseURL: "https://api.example.com",
    backupURLs: ["https://api-backup.example.com"],
    commonHeaders: ["Content-Type": "application/json"],
    commonParameters: ["platform": "iOS"],
    timeoutInterval: 30,
    enableLog: true,
    logLevel: .verbose
)
```

### 属性

#### version

框架版本号。

```swift
public static let version: String
```

---

## KKNetworkConfig

网络配置管理类（单例）。

### 单例

```swift
public static let shared: KKNetworkConfig
```

### 属性

#### baseURL

主域名。

```swift
public var baseURL: String
```

#### backupBaseURLs

备用域名列表。

```swift
public var backupBaseURLs: [String]
```

#### commonHeaders

公共请求头。

```swift
public var commonHeaders: HTTPHeaders
```

#### commonParameters

公共参数。

```swift
public var commonParameters: [String: Any]
```

#### timeoutInterval

超时时间。

```swift
public var timeoutInterval: TimeInterval
```

#### enableLog

是否启用日志。

```swift
public var enableLog: Bool
```

#### logLevel

日志级别。

```swift
public var logLevel: KKLogLevel
```

### 方法

#### addInterceptor(_:)

添加请求拦截器。

```swift
public func addInterceptor(_ interceptor: KKRequestInterceptor)
```

#### removeAllInterceptors()

移除所有拦截器。

```swift
public func removeAllInterceptors()
```

---

## KKBaseRequest

基础请求类。

### 需要重写的方法

#### requestPath()

返回请求路径。

```swift
open func requestPath() -> String
```

#### requestMethod()

返回请求方法（默认为 GET）。

```swift
open func requestMethod() -> HTTPMethod
```

#### requestParameters()

返回请求参数。

```swift
open func requestParameters() -> [String: Any]?
```

#### requestHeaders()

返回自定义请求头。

```swift
open func requestHeaders() -> HTTPHeaders?
```

#### parameterEncoding()

返回参数编码方式。

```swift
open func parameterEncoding() -> ParameterEncoding
```

#### useCommonParameters()

是否使用公共参数（默认为 true）。

```swift
open func useCommonParameters() -> Bool
```

#### useCommonHeaders()

是否使用公共请求头（默认为 true）。

```swift
open func useCommonHeaders() -> Bool
```

#### requestTimeoutInterval()

自定义超时时间。

```swift
open func requestTimeoutInterval() -> TimeInterval?
```

#### maxRetryCount()

最大重试次数（默认为 0）。

```swift
open func maxRetryCount() -> Int
```

#### enableBackupURLRetry()

是否启用域名切换重试（默认为 true）。

```swift
open func enableBackupURLRetry() -> Bool
```

#### customBaseURL()

自定义 BaseURL。

```swift
open func customBaseURL() -> String?
```

#### validateResponse(_:)

验证响应数据是否有效（默认返回 true）。

```swift
open func validateResponse(_ json: JSON) -> Bool
```

#### errorMessageFromResponse(_:)

从响应中提取错误信息。

```swift
open func errorMessageFromResponse(_ json: JSON) -> String?
```

### 实例方法

#### start(success:failure:)

发起请求。

```swift
@discardableResult
public func start(
    success: ((KKBaseRequest) -> Void)? = nil,
    failure: ((KKBaseRequest) -> Void)? = nil
) -> Self
```

**参数：**

- `success`: 成功回调
- `failure`: 失败回调

**返回值：** 返回 self，支持链式调用

#### cancel()

取消请求。

```swift
public func cancel()
```

### 属性

#### responseData

响应数据。

```swift
public private(set) var responseData: Data?
```

#### responseJSON

响应 JSON。

```swift
public private(set) var responseJSON: JSON?
```

#### responseString

响应字符串。

```swift
public private(set) var responseString: String?
```

#### error

错误信息。

```swift
public private(set) var error: Error?
```

#### tag

请求标识。

```swift
public var tag: Int
```

#### userInfo

用户信息。

```swift
public var userInfo: [String: Any]?
```

---

## KKCacheableRequest

支持缓存的请求类，继承自 `KKBaseRequest`。

### 需要重写的方法

#### cachePolicy()

返回缓存策略（默认为 .none）。

```swift
open func cachePolicy() -> KKCachePolicy
```

#### cacheMaxAge()

返回缓存有效期（秒），0 表示永久有效（默认为 0）。

```swift
open func cacheMaxAge() -> TimeInterval
```

#### cacheKey()

返回缓存 Key（默认使用 URL + 参数生成）。

```swift
open func cacheKey() -> String
```

### 缓存策略

```swift
public enum KKCachePolicy {
    case none                    // 不使用缓存
    case cacheOnly              // 只使用缓存
    case networkOnly            // 只使用网络
    case cacheElseNetwork       // 先使用缓存，缓存不存在则请求网络
    case networkElseCache       // 先请求网络，失败则使用缓存
    case cacheThenNetwork       // 先返回缓存，然后请求网络更新
}
```

---

## KKUploadRequest

文件上传请求类，继承自 `KKBaseRequest`。

### 需要重写的方法

#### uploadData()

返回上传数据。

```swift
open func uploadData() -> [String: KKUploadData]
```

#### formFields()

返回表单字段。

```swift
open func formFields() -> [String: String]?
```

### 属性

#### progressBlock

上传进度回调。

```swift
public var progressBlock: ((Progress) -> Void)?
```

### 上传数据类型

```swift
public enum KKUploadData {
    case file(URL)                                      // 文件路径
    case data(Data, fileName: String, mimeType: String) // 数据
}
```

---

## KKDownloadRequest

文件下载请求类，继承自 `KKBaseRequest`。

### 需要重写的方法

#### downloadDestination()

返回下载目标路径。

```swift
open func downloadDestination() -> URL?
```

#### resumable()

是否支持断点续传（默认为 true）。

```swift
open func resumable() -> Bool
```

### 属性

#### progressBlock

下载进度回调。

```swift
public var progressBlock: ((Progress) -> Void)?
```

#### downloadedFileURL

下载完成后的文件路径。

```swift
public private(set) var downloadedFileURL: URL?
```

---

## KKBatchRequest

批量请求管理类。

### 初始化

#### init(requests:)

创建批量请求。

```swift
public init(requests: [KKBaseRequest])
```

**参数：**

- `requests`: 请求数组

### 方法

#### start(success:failure:)

开始批量请求。

```swift
@discardableResult
public func start(
    success: (() -> Void)? = nil,
    failure: ((KKBaseRequest) -> Void)? = nil
) -> Self
```

**参数：**

- `success`: 所有请求成功回调
- `failure`: 有请求失败回调，参数为失败的请求

#### cancel()

取消所有请求。

```swift
public func cancel()
```

---

## KKChainRequest

链式请求管理类。

### 类型定义

#### ChainCallback

链式请求回调闭包。

```swift
public typealias ChainCallback = (KKChainRequest, KKBaseRequest) -> Void
```

### 方法

#### addRequest(_:callback:)

添加请求到链中。

```swift
@discardableResult
public func addRequest(
    _ request: KKBaseRequest,
    callback: ChainCallback? = nil
) -> Self
```

**参数：**

- `request`: 请求对象
- `callback`: 请求完成后的回调

**返回值：** 返回 self，支持链式调用

#### start(success:failure:)

开始链式请求。

```swift
@discardableResult
public func start(
    success: (() -> Void)? = nil,
    failure: ((KKBaseRequest) -> Void)? = nil
) -> Self
```

**参数：**

- `success`: 所有请求成功回调
- `failure`: 有请求失败回调，参数为失败的请求

#### cancel()

取消链式请求。

```swift
public func cancel()
```

---

## KKNetworkCache

网络缓存管理类（单例）。

### 单例

```swift
public static let shared: KKNetworkCache
```

### 方法

#### setCache(_:forKey:maxAge:)

保存缓存。

```swift
public func setCache(
    _ json: JSON,
    forKey key: String,
    maxAge: TimeInterval = 0
)
```

**参数：**

- `json`: JSON 数据
- `key`: 缓存 Key
- `maxAge`: 缓存有效期（秒），0 表示永久有效

#### cache(forKey:)

获取缓存。

```swift
public func cache(forKey key: String) -> JSON?
```

**参数：**

- `key`: 缓存 Key

**返回值：** 缓存的 JSON 数据，如果不存在或已过期则返回 nil

#### removeCache(forKey:)

移除缓存。

```swift
public func removeCache(forKey key: String)
```

**参数：**

- `key`: 缓存 Key

#### clearAllCache()

清空所有缓存。

```swift
public func clearAllCache()
```

#### cacheKey(url:parameters:)

生成缓存 Key。

```swift
public func cacheKey(url: String, parameters: [String: Any]?) -> String
```

**参数：**

- `url`: 请求 URL
- `parameters`: 请求参数

**返回值：** 缓存 Key

---

## KKNetworkLogger

网络日志工具类。

### 日志级别

```swift
public enum KKLogLevel: Int {
    case none = 0      // 不打印
    case error = 1     // 只打印错误
    case info = 2      // 打印基本信息
    case verbose = 3   // 打印详细信息
}
```

### 类方法

#### log(_:level:)

打印日志。

```swift
public static func log(_ message: String, level: KKLogLevel = .verbose)
```

**参数：**

- `message`: 日志消息
- `level`: 日志级别

#### logRequest(url:method:parameters:headers:)

打印请求信息。

```swift
public static func logRequest(
    url: String,
    method: HTTPMethod,
    parameters: [String: Any]?,
    headers: HTTPHeaders
)
```

#### logResponse(url:statusCode:json:)

打印响应信息。

```swift
public static func logResponse(
    url: String,
    statusCode: Int?,
    json: JSON
)
```

#### logError(url:error:)

打印错误信息。

```swift
public static func logError(url: String, error: Error)
```

---

## KKRequestInterceptor

请求拦截器协议。

### 协议方法

#### willSend(_:)

请求即将发送。

```swift
func willSend(_ request: KKBaseRequest)
```

**参数：**

- `request`: 请求对象

#### didReceive(_:error:)

请求已收到响应。

```swift
func didReceive(_ request: KKBaseRequest, error: Error?)
```

**参数：**

- `request`: 请求对象
- `error`: 错误信息，如果请求成功则为 nil

### 内置拦截器

#### KKTokenInterceptor

Token 拦截器。

```swift
public class KKTokenInterceptor: KKRequestInterceptor {
    public init(tokenProvider: @escaping () -> String?)
}
```

**示例：**

```swift
let tokenInterceptor = KKTokenInterceptor {
    return UserDefaults.standard.string(forKey: "token")
}
KKNetworkConfig.shared.addInterceptor(tokenInterceptor)
```

#### KKResponseInterceptor

通用响应拦截器。

```swift
public class KKResponseInterceptor: KKRequestInterceptor {
    public init(handler: @escaping (KKBaseRequest, Error?) -> Void)
}
```

**示例：**

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

---

## 扩展方法

### KKBaseRequest 扩展

#### asyncStart() (Async/Await)

使用 async/await 发起请求。

```swift
@available(iOS 13.0, macOS 10.15, *)
public func asyncStart() async throws -> JSON
```

**返回值：** 响应 JSON

**抛出：** 请求失败时抛出错误

**示例：**

```swift
Task {
    do {
        let json = try await request.asyncStart()
        print("响应: \(json)")
    } catch {
        print("错误: \(error)")
    }
}
```

#### publisher() (Combine)

返回 Combine Publisher。

```swift
@available(iOS 13.0, macOS 10.15, *)
public func publisher() -> AnyPublisher<JSON, Error>
```

**返回值：** Combine Publisher

**示例：**

```swift
request.publisher()
    .sink(
        receiveCompletion: { completion in
            print("完成: \(completion)")
        },
        receiveValue: { json in
            print("响应: \(json)")
        }
    )
    .store(in: &cancellables)
```

#### asObservable() (RxSwift)

返回 RxSwift Observable。

```swift
public func asObservable() -> Observable<JSON>
```

**返回值：** RxSwift Observable

**示例：**

```swift
request.asObservable()
    .subscribe(
        onNext: { json in
            print("响应: \(json)")
        },
        onError: { error in
            print("错误: \(error)")
        }
    )
    .disposed(by: disposeBag)
```

#### decode(_:)

解析为模型（需要模型遵循 Codable）。

```swift
public func decode<T: Codable>(_ type: T.Type) -> T?
```

**参数：**

- `type`: 模型类型

**返回值：** 解析后的模型，失败返回 nil

**示例：**

```swift
if let user = request.decode(User.self) {
    print("用户: \(user.name)")
}
```

#### decodeArray(_:)

解析为模型数组。

```swift
public func decodeArray<T: Codable>(_ type: T.Type) -> [T]?
```

**参数：**

- `type`: 模型类型

**返回值：** 解析后的模型数组，失败返回 nil

**示例：**

```swift
if let users = request.decodeArray(User.self) {
    print("用户数量: \(users.count)")
}
```

---

## 常量和枚举

### HTTPMethod

HTTP 请求方法（来自 Alamofire）。

```swift
public enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
    case patch = "PATCH"
    case head = "HEAD"
    case options = "OPTIONS"
    case trace = "TRACE"
    case connect = "CONNECT"
}
```

### ParameterEncoding

参数编码方式（来自 Alamofire）。

```swift
public protocol ParameterEncoding {
    // URLEncoding.default
    // URLEncoding.queryString
    // JSONEncoding.default
    // JSONEncoding.prettyPrinted
}
```

---

## 完整示例

### 基本请求

```swift
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

// 使用
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

### 缓存请求

```swift
class UserInfoRequest: KKCacheableRequest {
    var userId: String
    
    init(userId: String) {
        self.userId = userId
    }
    
    override func requestPath() -> String {
        return "/api/user/\(userId)"
    }
    
    override func cachePolicy() -> KKCachePolicy {
        return .cacheElseNetwork
    }
    
    override func cacheMaxAge() -> TimeInterval {
        return 300
    }
}
```

### 文件上传

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
    print("进度: \(progress.fractionCompleted)")
}
request.start()
```

### 文件下载

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
let request = DownloadFileRequest(fileURL: url, savePath: savePath)
request.progressBlock = { progress in
    print("进度: \(progress.fractionCompleted)")
}
request.start()
```

---

## 相关文档

- [快速开始](index.md)
- [核心类介绍](core-classes.md)
- [请求类型](request-types.md)
- [高级功能](advanced-features.md)
- [最佳实践](best-practices.md)
