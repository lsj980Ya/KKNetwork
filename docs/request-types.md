---
layout: default
title: 请求类型
---

# 请求类型

KKNetwork 提供了多种请求类型，满足不同的业务需求。

## 目录

- [KKBaseRequest - 基础请求](#kkbaserequest---基础请求)
- [KKCacheableRequest - 缓存请求](#kkcacheablerequest---缓存请求)
- [KKUploadRequest - 文件上传](#kkuploadrequest---文件上传)
- [KKDownloadRequest - 文件下载](#kkdownloadrequest---文件下载)

---

## KKBaseRequest - 基础请求

所有请求的基类，支持 GET、POST、PUT、DELETE 等 HTTP 方法。

### 基本用法

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
```

### GET 请求示例

```swift
class SearchRequest: KKBaseRequest {
    var keyword: String
    var page: Int
    
    init(keyword: String, page: Int = 1) {
        self.keyword = keyword
        self.page = page
    }
    
    override func requestPath() -> String {
        return "/api/search"
    }
    
    override func requestMethod() -> HTTPMethod {
        return .get
    }
    
    override func requestParameters() -> [String: Any]? {
        return [
            "keyword": keyword,
            "page": page,
            "pageSize": 20
        ]
    }
}

// 使用
let request = SearchRequest(keyword: "Swift", page: 1)
request.start(
    success: { request in
        if let results = request.responseJSON?["data"]["results"].array {
            print("搜索结果: \(results)")
        }
    },
    failure: { request in
        print("搜索失败: \(request.error?.localizedDescription ?? "")")
    }
)
```

### POST 请求示例

```swift
class CreatePostRequest: KKBaseRequest {
    var title: String
    var content: String
    
    init(title: String, content: String) {
        self.title = title
        self.content = content
    }
    
    override func requestPath() -> String {
        return "/api/posts"
    }
    
    override func requestMethod() -> HTTPMethod {
        return .post
    }
    
    override func requestParameters() -> [String: Any]? {
        return [
            "title": title,
            "content": content
        ]
    }
    
    override func validateResponse(_ json: JSON) -> Bool {
        return json["code"].intValue == 200
    }
}

// 使用
let request = CreatePostRequest(title: "标题", content: "内容")
request.start(
    success: { request in
        print("创建成功")
    },
    failure: { request in
        print("创建失败")
    }
)
```

### PUT 请求示例

```swift
class UpdateUserRequest: KKBaseRequest {
    var userId: String
    var nickname: String
    var avatar: String
    
    init(userId: String, nickname: String, avatar: String) {
        self.userId = userId
        self.nickname = nickname
        self.avatar = avatar
    }
    
    override func requestPath() -> String {
        return "/api/user/\(userId)"
    }
    
    override func requestMethod() -> HTTPMethod {
        return .put
    }
    
    override func requestParameters() -> [String: Any]? {
        return [
            "nickname": nickname,
            "avatar": avatar
        ]
    }
}
```

### DELETE 请求示例

```swift
class DeletePostRequest: KKBaseRequest {
    var postId: String
    
    init(postId: String) {
        self.postId = postId
    }
    
    override func requestPath() -> String {
        return "/api/posts/\(postId)"
    }
    
    override func requestMethod() -> HTTPMethod {
        return .delete
    }
}
```

---

## KKCacheableRequest - 缓存请求

支持响应缓存的请求类，可以减少网络请求，提升用户体验。

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

### 基本用法

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
        return 300  // 缓存 5 分钟
    }
}
```

### 缓存策略详解

#### 1. cacheElseNetwork - 先缓存后网络

适用场景：数据更新不频繁，优先使用缓存提升速度。

```swift
class HomeDataRequest: KKCacheableRequest {
    override func requestPath() -> String {
        return "/api/home"
    }
    
    override func cachePolicy() -> KKCachePolicy {
        return .cacheElseNetwork
    }
    
    override func cacheMaxAge() -> TimeInterval {
        return 600  // 缓存 10 分钟
    }
}

// 使用
let request = HomeDataRequest()
request.start(
    success: { request in
        // 如果有缓存，立即返回缓存数据
        // 如果没有缓存，请求网络
        print("数据: \(request.responseJSON)")
    },
    failure: { request in
        print("失败: \(request.error)")
    }
)
```

#### 2. networkElseCache - 先网络后缓存

适用场景：优先获取最新数据，网络失败时使用缓存兜底。

```swift
class NewsListRequest: KKCacheableRequest {
    override func requestPath() -> String {
        return "/api/news"
    }
    
    override func cachePolicy() -> KKCachePolicy {
        return .networkElseCache
    }
    
    override func cacheMaxAge() -> TimeInterval {
        return 3600  // 缓存 1 小时
    }
}
```

#### 3. cacheThenNetwork - 先返回缓存再更新

适用场景：需要快速显示内容，同时获取最新数据更新界面。

```swift
class ProductDetailRequest: KKCacheableRequest {
    var productId: String
    
    init(productId: String) {
        self.productId = productId
    }
    
    override func requestPath() -> String {
        return "/api/product/\(productId)"
    }
    
    override func cachePolicy() -> KKCachePolicy {
        return .cacheThenNetwork
    }
    
    override func cacheMaxAge() -> TimeInterval {
        return 1800  // 缓存 30 分钟
    }
}

// 使用
let request = ProductDetailRequest(productId: "123")
request.start(
    success: { request in
        // 这个回调会被调用两次：
        // 1. 如果有缓存，立即返回缓存数据
        // 2. 网络请求成功后，返回最新数据
        updateUI(with: request.responseJSON)
    },
    failure: { request in
        print("失败: \(request.error)")
    }
)
```

#### 4. cacheOnly - 只使用缓存

适用场景：离线模式或只读取已缓存的数据。

```swift
class OfflineDataRequest: KKCacheableRequest {
    override func requestPath() -> String {
        return "/api/data"
    }
    
    override func cachePolicy() -> KKCachePolicy {
        return .cacheOnly
    }
}
```

#### 5. networkOnly - 只使用网络

适用场景：必须获取最新数据，但需要缓存功能。

```swift
class RealTimeDataRequest: KKCacheableRequest {
    override func requestPath() -> String {
        return "/api/realtime"
    }
    
    override func cachePolicy() -> KKCachePolicy {
        return .networkOnly
    }
    
    override func cacheMaxAge() -> TimeInterval {
        return 60  // 缓存 1 分钟，供下次使用
    }
}
```

### 自定义缓存 Key

默认情况下，缓存 Key 由 URL 和参数生成。你可以自定义缓存 Key：

```swift
class CustomCacheRequest: KKCacheableRequest {
    var userId: String
    
    init(userId: String) {
        self.userId = userId
    }
    
    override func requestPath() -> String {
        return "/api/user/\(userId)"
    }
    
    override func cacheKey() -> String {
        return "user_\(userId)"  // 自定义缓存 Key
    }
    
    override func cachePolicy() -> KKCachePolicy {
        return .cacheElseNetwork
    }
    
    override func cacheMaxAge() -> TimeInterval {
        return 300
    }
}
```

### 手动管理缓存

```swift
// 获取缓存
if let cachedJSON = KKNetworkCache.shared.cache(forKey: "user_123") {
    print("缓存数据: \(cachedJSON)")
}

// 保存缓存
let json = JSON(["name": "John", "age": 30])
KKNetworkCache.shared.setCache(json, forKey: "user_123", maxAge: 300)

// 删除缓存
KKNetworkCache.shared.removeCache(forKey: "user_123")

// 清空所有缓存
KKNetworkCache.shared.clearAllCache()
```

---

## KKUploadRequest - 文件上传

支持文件上传的请求类，可以上传图片、视频、文档等文件。

### 上传数据类型

```swift
public enum KKUploadData {
    case file(URL)                                      // 文件路径
    case data(Data, fileName: String, mimeType: String) // 数据
}
```

### 上传图片示例

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
    let percent = progress.fractionCompleted * 100
    print("上传进度: \(String(format: "%.1f", percent))%")
}
request.start(
    success: { request in
        if let imageURL = request.responseJSON?["data"]["url"].string {
            print("上传成功，图片地址: \(imageURL)")
        }
    },
    failure: { request in
        print("上传失败: \(request.error?.localizedDescription ?? "")")
    }
)
```

### 上传文件示例

```swift
class UploadFileRequest: KKUploadRequest {
    var fileURL: URL
    
    init(fileURL: URL) {
        self.fileURL = fileURL
    }
    
    override func requestPath() -> String {
        return "/api/upload/file"
    }
    
    override func uploadData() -> [String: KKUploadData] {
        return [
            "file": .file(fileURL)
        ]
    }
}

// 使用
let fileURL = URL(fileURLWithPath: "/path/to/file.pdf")
let request = UploadFileRequest(fileURL: fileURL)
request.progressBlock = { progress in
    print("上传进度: \(progress.fractionCompleted)")
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

### 上传多个文件

```swift
class UploadMultipleFilesRequest: KKUploadRequest {
    var images: [Data]
    
    init(images: [Data]) {
        self.images = images
    }
    
    override func requestPath() -> String {
        return "/api/upload/multiple"
    }
    
    override func uploadData() -> [String: KKUploadData] {
        var uploadData: [String: KKUploadData] = [:]
        
        for (index, imageData) in images.enumerated() {
            uploadData["file\(index)"] = .data(
                imageData,
                fileName: "image\(index).jpg",
                mimeType: "image/jpeg"
            )
        }
        
        return uploadData
    }
}
```

### 上传文件并附加表单字段

```swift
class UploadWithFormRequest: KKUploadRequest {
    var imageData: Data
    var title: String
    var description: String
    
    init(imageData: Data, title: String, description: String) {
        self.imageData = imageData
        self.title = title
        self.description = description
    }
    
    override func requestPath() -> String {
        return "/api/upload/post"
    }
    
    override func uploadData() -> [String: KKUploadData] {
        return [
            "image": .data(imageData, fileName: "image.jpg", mimeType: "image/jpeg")
        ]
    }
    
    override func formFields() -> [String: String]? {
        return [
            "title": title,
            "description": description
        ]
    }
}

// 使用
let request = UploadWithFormRequest(
    imageData: imageData,
    title: "标题",
    description: "描述"
)
request.start(
    success: { _ in
        print("上传成功")
    },
    failure: { _ in
        print("上传失败")
    }
)
```

### 上传进度监听

```swift
let request = UploadImageRequest(imageData: imageData)

// 方式 1：使用 progressBlock
request.progressBlock = { progress in
    DispatchQueue.main.async {
        // 更新 UI
        progressView.progress = Float(progress.fractionCompleted)
        percentLabel.text = "\(Int(progress.fractionCompleted * 100))%"
    }
}

// 方式 2：使用 KVO
request.start()
```

---

## KKDownloadRequest - 文件下载

支持文件下载的请求类，可以下载图片、视频、文档等文件。

### 基本用法

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
let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
let savePath = documentsPath.appendingPathComponent("file.zip")

let request = DownloadFileRequest(
    fileURL: "https://example.com/file.zip",
    savePath: savePath
)
request.progressBlock = { progress in
    let percent = progress.fractionCompleted * 100
    print("下载进度: \(String(format: "%.1f", percent))%")
}
request.start(
    success: { request in
        if let fileURL = request.downloadedFileURL {
            print("下载完成，文件路径: \(fileURL.path)")
        }
    },
    failure: { request in
        print("下载失败: \(request.error?.localizedDescription ?? "")")
    }
)
```

### 下载图片示例

```swift
class DownloadImageRequest: KKDownloadRequest {
    var imageURL: String
    
    init(imageURL: String) {
        self.imageURL = imageURL
    }
    
    override func requestPath() -> String {
        return imageURL
    }
    
    override func downloadDestination() -> URL? {
        let cachesPath = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        let fileName = (imageURL as NSString).lastPathComponent
        return cachesPath.appendingPathComponent(fileName)
    }
}

// 使用
let request = DownloadImageRequest(imageURL: "https://example.com/image.jpg")
request.progressBlock = { progress in
    print("下载进度: \(progress.fractionCompleted)")
}
request.start(
    success: { request in
        if let fileURL = request.downloadedFileURL,
           let imageData = try? Data(contentsOf: fileURL),
           let image = UIImage(data: imageData) {
            imageView.image = image
        }
    },
    failure: { _ in
        print("下载失败")
    }
)
```

### 断点续传

```swift
class ResumableDownloadRequest: KKDownloadRequest {
    override func resumable() -> Bool {
        return true  // 启用断点续传
    }
}
```

### 下载进度监听

```swift
let request = DownloadFileRequest(fileURL: url, savePath: savePath)

request.progressBlock = { progress in
    DispatchQueue.main.async {
        // 更新 UI
        progressView.progress = Float(progress.fractionCompleted)
        
        // 显示下载速度和剩余时间
        let completed = progress.completedUnitCount
        let total = progress.totalUnitCount
        let percent = Int(progress.fractionCompleted * 100)
        
        statusLabel.text = """
        已下载: \(ByteCountFormatter.string(fromByteCount: completed, countStyle: .file))
        总大小: \(ByteCountFormatter.string(fromByteCount: total, countStyle: .file))
        进度: \(percent)%
        """
    }
}

request.start(
    success: { request in
        print("下载完成")
    },
    failure: { request in
        print("下载失败")
    }
)
```

### 取消下载

```swift
// 开始下载
let request = DownloadFileRequest(fileURL: url, savePath: savePath)
request.start()

// 取消下载
request.cancel()
```

---

## 模型解析

所有请求类型都支持自动解析为模型。

### 使用 Codable

```swift
struct User: Codable {
    let id: String
    let name: String
    let email: String
}

let request = UserInfoRequest(userId: "123")
request.start(
    success: { request in
        if let user = request.decode(User.self) {
            print("用户: \(user.name)")
        }
    },
    failure: { _ in
        print("失败")
    }
)
```

### 解析数组

```swift
struct Post: Codable {
    let id: String
    let title: String
    let content: String
}

let request = PostListRequest()
request.start(
    success: { request in
        if let posts = request.decodeArray(Post.self) {
            print("文章数量: \(posts.count)")
        }
    },
    failure: { _ in
        print("失败")
    }
)
```

---

## 下一步

- 查看 [高级功能](advanced-features.md) 了解更多高级用法
- 查看 [最佳实践](best-practices.md) 了解推荐的使用方式
- 查看 [API 参考](api-reference.md) 了解完整的 API 文档
