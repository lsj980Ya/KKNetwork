# 高级功能

本文档介绍 KKNetwork 的高级功能和使用技巧。

## 目录

- [Async/Await 支持](#asyncawait-支持)
- [Combine 支持](#combine-支持)
- [RxSwift 支持](#rxswift-支持)
- [请求重试机制](#请求重试机制)
- [域名切换](#域名切换)
- [请求拦截器](#请求拦截器)
- [响应验证](#响应验证)
- [自定义配置](#自定义配置)

---

## Async/Await 支持

KKNetwork 支持 Swift 的 async/await 语法，让异步代码更简洁。

### 基本用法

```swift
@available(iOS 13.0, *)
func fetchUserInfo() async throws -> JSON {
    let request = UserInfoRequest(userId: "123")
    return try await request.asyncStart()
}

// 使用
Task {
    do {
        let json = try await fetchUserInfo()
        print("用户信息: \(json)")
    } catch {
        print("错误: \(error)")
    }
}
```

### 串行请求

```swift
@available(iOS 13.0, *)
func loginAndFetchData() async throws {
    // 1. 登录
    let loginRequest = LoginRequest(username: "test", password: "123456")
    let loginJSON = try await loginRequest.asyncStart()
    
    // 2. 保存 Token
    if let token = loginJSON["data"]["token"].string {
        KKNetworkConfig.shared.commonHeaders.add(
            name: "Authorization",
            value: "Bearer \(token)"
        )
    }
    
    // 3. 获取用户信息
    let userRequest = UserInfoRequest(userId: "123")
    let userJSON = try await userRequest.asyncStart()
    print("用户信息: \(userJSON)")
    
    // 4. 获取订单列表
    let orderRequest = OrderListRequest(userId: "123")
    let orderJSON = try await orderRequest.asyncStart()
    print("订单列表: \(orderJSON)")
}

// 使用
Task {
    do {
        try await loginAndFetchData()
    } catch {
        print("错误: \(error)")
    }
}
```

### 并行请求

```swift
@available(iOS 13.0, *)
func fetchMultipleData() async throws {
    async let userInfo = UserInfoRequest(userId: "123").asyncStart()
    async let orderList = OrderListRequest(userId: "123").asyncStart()
    async let messageList = MessageListRequest(userId: "123").asyncStart()
    
    let (user, orders, messages) = try await (userInfo, orderList, messageList)
    
    print("用户: \(user)")
    print("订单: \(orders)")
    print("消息: \(messages)")
}
```

### 使用 TaskGroup

```swift
@available(iOS 13.0, *)
func fetchUserList(userIds: [String]) async throws -> [JSON] {
    return try await withThrowingTaskGroup(of: JSON.self) { group in
        for userId in userIds {
            group.addTask {
                let request = UserInfoRequest(userId: userId)
                return try await request.asyncStart()
            }
        }
        
        var results: [JSON] = []
        for try await json in group {
            results.append(json)
        }
        return results
    }
}

// 使用
Task {
    do {
        let users = try await fetchUserList(userIds: ["1", "2", "3"])
        print("用户列表: \(users)")
    } catch {
        print("错误: \(error)")
    }
}
```

---

## Combine 支持

KKNetwork 支持 Combine 框架，可以使用响应式编程。

### 基本用法

```swift
import Combine

@available(iOS 13.0, *)
class ViewModel {
    var cancellables = Set<AnyCancellable>()
    
    func fetchUserInfo() {
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
}
```

### 链式请求

```swift
@available(iOS 13.0, *)
func loginAndFetchData() {
    let loginRequest = LoginRequest(username: "test", password: "123456")
    
    loginRequest.publisher()
        .flatMap { loginJSON -> AnyPublisher<JSON, Error> in
            // 保存 Token
            if let token = loginJSON["data"]["token"].string {
                KKNetworkConfig.shared.commonHeaders.add(
                    name: "Authorization",
                    value: "Bearer \(token)"
                )
            }
            
            // 获取用户信息
            let userRequest = UserInfoRequest(userId: "123")
            return userRequest.publisher()
        }
        .sink(
            receiveCompletion: { completion in
                print("完成: \(completion)")
            },
            receiveValue: { userJSON in
                print("用户信息: \(userJSON)")
            }
        )
        .store(in: &cancellables)
}
```

### 并行请求

```swift
@available(iOS 13.0, *)
func fetchMultipleData() {
    let userRequest = UserInfoRequest(userId: "123")
    let orderRequest = OrderListRequest(userId: "123")
    let messageRequest = MessageListRequest(userId: "123")
    
    Publishers.Zip3(
        userRequest.publisher(),
        orderRequest.publisher(),
        messageRequest.publisher()
    )
    .sink(
        receiveCompletion: { completion in
            print("完成: \(completion)")
        },
        receiveValue: { (user, orders, messages) in
            print("用户: \(user)")
            print("订单: \(orders)")
            print("消息: \(messages)")
        }
    )
    .store(in: &cancellables)
}
```

### 操作符使用

```swift
@available(iOS 13.0, *)
func searchWithDebounce(searchText: String) {
    searchTextPublisher
        .debounce(for: .milliseconds(500), scheduler: DispatchQueue.main)
        .removeDuplicates()
        .flatMap { text -> AnyPublisher<JSON, Error> in
            let request = SearchRequest(keyword: text)
            return request.publisher()
        }
        .receive(on: DispatchQueue.main)
        .sink(
            receiveCompletion: { _ in },
            receiveValue: { json in
                print("搜索结果: \(json)")
            }
        )
        .store(in: &cancellables)
}
```

---

## RxSwift 支持

KKNetwork 支持 RxSwift，可以使用响应式编程。

### 基本用法

```swift
import RxSwift

class ViewModel {
    let disposeBag = DisposeBag()
    
    func fetchUserInfo() {
        let request = UserInfoRequest(userId: "123")
        request.asObservable()
            .subscribe(
                onNext: { json in
                    print("用户信息: \(json)")
                },
                onError: { error in
                    print("错误: \(error)")
                },
                onCompleted: {
                    print("完成")
                }
            )
            .disposed(by: disposeBag)
    }
}
```

### 链式请求

```swift
func loginAndFetchData() {
    let loginRequest = LoginRequest(username: "test", password: "123456")
    
    loginRequest.asObservable()
        .flatMap { loginJSON -> Observable<JSON> in
            // 保存 Token
            if let token = loginJSON["data"]["token"].string {
                KKNetworkConfig.shared.commonHeaders.add(
                    name: "Authorization",
                    value: "Bearer \(token)"
                )
            }
            
            // 获取用户信息
            let userRequest = UserInfoRequest(userId: "123")
            return userRequest.asObservable()
        }
        .subscribe(
            onNext: { userJSON in
                print("用户信息: \(userJSON)")
            },
            onError: { error in
                print("错误: \(error)")
            }
        )
        .disposed(by: disposeBag)
}
```

### 并行请求

```swift
func fetchMultipleData() {
    let userRequest = UserInfoRequest(userId: "123")
    let orderRequest = OrderListRequest(userId: "123")
    let messageRequest = MessageListRequest(userId: "123")
    
    Observable.zip(
        userRequest.asObservable(),
        orderRequest.asObservable(),
        messageRequest.asObservable()
    )
    .subscribe(
        onNext: { (user, orders, messages) in
            print("用户: \(user)")
            print("订单: \(orders)")
            print("消息: \(messages)")
        },
        onError: { error in
            print("错误: \(error)")
        }
    )
    .disposed(by: disposeBag)
}
```

---

## 请求重试机制

KKNetwork 支持自动重试失败的请求。

### 基本重试

```swift
class MyRequest: KKBaseRequest {
    override func maxRetryCount() -> Int {
        return 3  // 失败后重试 3 次
    }
}
```

### 条件重试

只在特定错误时重试：

```swift
class ConditionalRetryRequest: KKBaseRequest {
    override func maxRetryCount() -> Int {
        return 3
    }
    
    override func validateResponse(_ json: JSON) -> Bool {
        let code = json["code"].intValue
        
        // 只在服务器错误时重试
        if code >= 500 {
            return false  // 返回 false 触发重试
        }
        
        return code == 200
    }
}
```

### 自定义重试延迟

```swift
class CustomRetryRequest: KKBaseRequest {
    private var retryDelays: [TimeInterval] = [1.0, 2.0, 5.0]
    
    override func maxRetryCount() -> Int {
        return retryDelays.count
    }
    
    // 可以在子类中重写重试逻辑
}
```

---

## 域名切换

当主域名不可用时，自动切换到备用域名。

### 配置备用域名

```swift
KKNetwork.setup(
    baseURL: "https://api.example.com",
    backupURLs: [
        "https://api-backup1.example.com",
        "https://api-backup2.example.com",
        "https://api-backup3.example.com"
    ]
)
```

### 启用域名切换

```swift
class MyRequest: KKBaseRequest {
    override func enableBackupURLRetry() -> Bool {
        return true  // 启用域名切换（默认为 true）
    }
}
```

### 域名切换流程

1. 首先使用主域名 `api.example.com`
2. 如果失败，重试 `maxRetryCount()` 次
3. 如果仍然失败，切换到第一个备用域名 `api-backup1.example.com`
4. 重复步骤 2-3，直到所有域名都尝试过

### 自定义域名

```swift
class CustomURLRequest: KKBaseRequest {
    override func customBaseURL() -> String? {
        return "https://custom-api.example.com"
    }
}
```

---

## 请求拦截器

拦截器可以在请求发送前后执行自定义逻辑。

### Token 拦截器

```swift
let tokenInterceptor = KKTokenInterceptor {
    return UserDefaults.standard.string(forKey: "token")
}
KKNetworkConfig.shared.addInterceptor(tokenInterceptor)
```

### 统一错误处理

```swift
class ErrorHandlerInterceptor: KKRequestInterceptor {
    func didReceive(_ request: KKBaseRequest, error: Error?) {
        guard let error = error else { return }
        
        let nsError = error as NSError
        
        DispatchQueue.main.async {
            switch nsError.code {
            case 401:
                // Token 过期，跳转登录
                NotificationCenter.default.post(name: .userNeedLogin, object: nil)
            case 403:
                showAlert(message: "无权限访问")
            case 404:
                showAlert(message: "资源不存在")
            case 500...599:
                showAlert(message: "服务器错误")
            default:
                showAlert(message: error.localizedDescription)
            }
        }
    }
}

KKNetworkConfig.shared.addInterceptor(ErrorHandlerInterceptor())
```

### 请求签名

```swift
class SignatureInterceptor: KKRequestInterceptor {
    func willSend(_ request: KKBaseRequest) {
        // 生成签名
        let timestamp = String(Int(Date().timeIntervalSince1970))
        let nonce = UUID().uuidString
        
        // 添加签名参数
        var params = request.requestParameters() ?? [:]
        params["timestamp"] = timestamp
        params["nonce"] = nonce
        params["sign"] = generateSignature(params: params)
        
        // 更新请求参数（需要在 KKBaseRequest 中添加方法）
    }
    
    private func generateSignature(params: [String: Any]) -> String {
        // 实现签名算法
        return "signature"
    }
}
```

### 性能监控

```swift
class PerformanceInterceptor: KKRequestInterceptor {
    private var startTimes: [String: TimeInterval] = [:]
    
    func willSend(_ request: KKBaseRequest) {
        let key = requestKey(request)
        startTimes[key] = Date().timeIntervalSince1970
    }
    
    func didReceive(_ request: KKBaseRequest, error: Error?) {
        let key = requestKey(request)
        
        if let startTime = startTimes[key] {
            let duration = Date().timeIntervalSince1970 - startTime
            
            // 记录性能数据
            print("📊 \(request.requestPath()) 耗时: \(duration) 秒")
            
            // 上报到性能监控平台
            if duration > 3.0 {
                reportSlowRequest(request: request, duration: duration)
            }
            
            startTimes.removeValue(forKey: key)
        }
    }
    
    private func requestKey(_ request: KKBaseRequest) -> String {
        return "\(request.requestPath())-\(request.tag)"
    }
    
    private func reportSlowRequest(request: KKBaseRequest, duration: TimeInterval) {
        // 上报慢请求
    }
}
```

---

## 响应验证

自定义响应验证逻辑。

### 基本验证

```swift
class MyRequest: KKBaseRequest {
    override func validateResponse(_ json: JSON) -> Bool {
        return json["code"].intValue == 200
    }
}
```

### 复杂验证

```swift
class ComplexValidationRequest: KKBaseRequest {
    override func validateResponse(_ json: JSON) -> Bool {
        let code = json["code"].intValue
        let message = json["message"].stringValue
        
        // 验证状态码
        guard code == 200 else {
            return false
        }
        
        // 验证数据完整性
        guard json["data"].exists() else {
            return false
        }
        
        // 验证必要字段
        let data = json["data"]
        guard data["id"].exists(),
              data["name"].exists() else {
            return false
        }
        
        return true
    }
    
    override func errorMessageFromResponse(_ json: JSON) -> String? {
        // 优先使用 message 字段
        if let message = json["message"].string {
            return message
        }
        
        // 其次使用 msg 字段
        if let msg = json["msg"].string {
            return msg
        }
        
        // 根据错误码返回默认消息
        let code = json["code"].intValue
        switch code {
        case 400:
            return "请求参数错误"
        case 401:
            return "未授权，请先登录"
        case 403:
            return "无权限访问"
        case 404:
            return "资源不存在"
        case 500:
            return "服务器错误"
        default:
            return "未知错误"
        }
    }
}
```

---

## 自定义配置

### 自定义超时时间

```swift
class LongTimeoutRequest: KKBaseRequest {
    override func requestTimeoutInterval() -> TimeInterval? {
        return 120  // 2 分钟超时
    }
}
```

### 自定义参数编码

```swift
class CustomEncodingRequest: KKBaseRequest {
    override func parameterEncoding() -> ParameterEncoding {
        return URLEncoding.queryString  // 使用 Query String 编码
    }
}
```

### 禁用公共参数

```swift
class NoCommonParamsRequest: KKBaseRequest {
    override func useCommonParameters() -> Bool {
        return false  // 不使用公共参数
    }
}
```

### 禁用公共请求头

```swift
class NoCommonHeadersRequest: KKBaseRequest {
    override func useCommonHeaders() -> Bool {
        return false  // 不使用公共请求头
    }
}
```

### 完全自定义请求

```swift
class FullyCustomRequest: KKBaseRequest {
    override func customBaseURL() -> String? {
        return "https://custom-api.example.com"
    }
    
    override func requestTimeoutInterval() -> TimeInterval? {
        return 60
    }
    
    override func useCommonParameters() -> Bool {
        return false
    }
    
    override func useCommonHeaders() -> Bool {
        return false
    }
    
    override func requestHeaders() -> HTTPHeaders? {
        return [
            "Custom-Header": "value",
            "Another-Header": "value"
        ]
    }
    
    override func maxRetryCount() -> Int {
        return 0  // 不重试
    }
    
    override func enableBackupURLRetry() -> Bool {
        return false  // 不切换域名
    }
}
```

---

## 下一步

- 查看 [最佳实践](best-practices.md) 了解推荐的使用方式
- 查看 [API 参考](api-reference.md) 了解完整的 API 文档
