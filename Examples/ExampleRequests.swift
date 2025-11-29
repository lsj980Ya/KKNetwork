//
//  ExampleRequests.swift
//  KKNetwork
//
//  示例请求类
//

import Foundation
import Alamofire
import SwiftyJSON

// MARK: - 基础请求示例

/// 登录请求
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

// MARK: - 缓存请求示例

/// 用户信息请求（带缓存）
class UserInfoRequest: KKCacheableRequest {
    
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
    
    override func cachePolicy() -> KKCachePolicy {
        return .cacheElseNetwork
    }
    
    override func cacheMaxAge() -> TimeInterval {
        return 300 // 5分钟
    }
    
    override func validateResponse(_ json: JSON) -> Bool {
        return json["code"].intValue == 200
    }
}

// MARK: - 上传请求示例

/// 图片上传请求
class UploadImageRequest: KKUploadRequest {
    
    var image: Data
    
    init(image: Data) {
        self.image = image
    }
    
    override func requestPath() -> String {
        return "/api/upload/image"
    }
    
    override func uploadData() -> [String: KKUploadData] {
        return [
            "file": .data(image, fileName: "image.jpg", mimeType: "image/jpeg")
        ]
    }
    
    override func formFields() -> [String: String]? {
        return [
            "type": "avatar"
        ]
    }
    
    override func validateResponse(_ json: JSON) -> Bool {
        return json["code"].intValue == 200
    }
}

// MARK: - 下载请求示例

/// 文件下载请求
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
    
    override func resumable() -> Bool {
        return true
    }
}
