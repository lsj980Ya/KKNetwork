//
//  KKIdempotentManager.swift
//  KKNetwork
//
//  幂等性管理（防止重复提交）
//

import Foundation

/// 幂等性管理器
public class KKIdempotentManager {
    
    // MARK: - Singleton
    
    public static let shared = KKIdempotentManager()
    
    private init() {}
    
    // MARK: - Properties
    
    /// 是否启用幂等性检查
    public var isEnabled: Bool = true
    
    /// 请求记录（用于检测重复）
    private var requestRecords: [String: Date] = [:]
    
    /// 幂等性有效期（秒）
    private let idempotentWindow: TimeInterval = 5
    
    /// Token 缓存
    private var tokenCache: [String: String] = [:]
    
    // MARK: - Public Methods
    
    /// 生成幂等性 Token
    public func generateToken(for key: String) -> String {
        let token = UUID().uuidString
        tokenCache[key] = token
        return token
    }
    
    /// 验证幂等性 Token
    public func validateToken(_ token: String, for key: String) -> Bool {
        guard let cachedToken = tokenCache[key] else {
            return false
        }
        
        if cachedToken == token {
            tokenCache.removeValue(forKey: key)
            return true
        }
        
        return false
    }
    
    /// 检查是否重复请求
    public func isDuplicateRequest(for key: String) -> Bool {
        guard isEnabled else { return false }
        
        let now = Date()
        
        // 清理过期记录
        requestRecords = requestRecords.filter { now.timeIntervalSince($0.value) < idempotentWindow }
        
        // 检查是否存在
        if let lastRequestTime = requestRecords[key] {
            let timeSinceLastRequest = now.timeIntervalSince(lastRequestTime)
            
            if timeSinceLastRequest < idempotentWindow {
                KKNetworkLogger.log("⚠️ 检测到重复请求: \(key)", level: .error)
                return true
            }
        }
        
        // 记录本次请求
        requestRecords[key] = now
        return false
    }
    
    /// 清除记录
    public func clearRecord(for key: String) {
        requestRecords.removeValue(forKey: key)
    }
}

// MARK: - 支持幂等性的请求

open class KKIdempotentRequest: KKBaseRequest {
    
    /// 幂等性 Key（默认使用 URL + 参数）
    open func idempotentKey() -> String {
        let url = requestPath()
        let params = requestParameters()
        
        if let params = params,
           let jsonData = try? JSONSerialization.data(withJSONObject: params),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            return "\(url)-\(jsonString)"
        }
        
        return url
    }
    
    /// 是否需要幂等性 Token
    open func requiresIdempotentToken() -> Bool {
        return false
    }
    
    @discardableResult
    public override func start(success: ((KKBaseRequest) -> Void)? = nil,
                              failure: ((KKBaseRequest) -> Void)? = nil) -> Self {
        
        let key = idempotentKey()
        
        // 检查重复请求
        if KKIdempotentManager.shared.isDuplicateRequest(for: key) {
            let error = NSError(domain: "KKNetwork",
                              code: -1005,
                              userInfo: [NSLocalizedDescriptionKey: "请求过于频繁，请稍后再试"])
            self.error = error
            
            DispatchQueue.main.async {
                failure?(self)
            }
            
            return self
        }
        
        return super.start(
            success: { request in
                KKIdempotentManager.shared.clearRecord(for: key)
                success?(request)
            },
            failure: { request in
                KKIdempotentManager.shared.clearRecord(for: key)
                failure?(request)
            }
        )
    }
    
    public override func requestHeaders() -> HTTPHeaders? {
        var headers = super.requestHeaders() ?? HTTPHeaders()
        
        // 添加幂等性 Token
        if requiresIdempotentToken() {
            let token = KKIdempotentManager.shared.generateToken(for: idempotentKey())
            headers.add(name: "X-Idempotent-Token", value: token)
        }
        
        return headers
    }
}

import Alamofire
