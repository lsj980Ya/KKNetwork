//
//  KKRateLimiter.swift
//  KKNetwork
//
//  请求频率限制器（防止接口被刷）
//

import Foundation

/// 频率限制器
public class KKRateLimiter {
    
    // MARK: - Singleton
    
    public static let shared = KKRateLimiter()
    
    private init() {}
    
    // MARK: - Properties
    
    /// 请求记录 [URL: [请求时间]]
    private var requestRecords: [String: [Date]] = [:]
    
    /// 默认时间窗口（秒）
    private let defaultTimeWindow: TimeInterval = 60
    
    /// 默认最大请求次数
    private let defaultMaxRequests: Int = 10
    
    /// 自定义限制规则 [URL: (时间窗口, 最大次数)]
    private var customRules: [String: (TimeInterval, Int)] = [:]
    
    // MARK: - Public Methods
    
    /// 设置自定义限制规则
    public func setRule(for url: String, timeWindow: TimeInterval, maxRequests: Int) {
        customRules[url] = (timeWindow, maxRequests)
    }
    
    /// 检查是否允许请求
    public func shouldAllowRequest(for url: String) -> Bool {
        let now = Date()
        let (timeWindow, maxRequests) = customRules[url] ?? (defaultTimeWindow, defaultMaxRequests)
        
        // 获取该 URL 的请求记录
        var records = requestRecords[url] ?? []
        
        // 移除过期记录
        records = records.filter { now.timeIntervalSince($0) < timeWindow }
        
        // 检查是否超过限制
        if records.count >= maxRequests {
            KKNetworkLogger.log("⚠️ 请求频率超限: \(url)", level: .error)
            return false
        }
        
        // 记录本次请求
        records.append(now)
        requestRecords[url] = records
        
        return true
    }
    
    /// 清空记录
    public func clearRecords(for url: String? = nil) {
        if let url = url {
            requestRecords.removeValue(forKey: url)
        } else {
            requestRecords.removeAll()
        }
    }
}

// MARK: - Rate Limited Request

/// 支持频率限制的请求
open class KKRateLimitedRequest: KKBaseRequest {
    
    /// 是否启用频率限制
    open func enableRateLimit() -> Bool {
        return true
    }
    
    /// 频率限制的 URL key
    open func rateLimitKey() -> String {
        return requestPath()
    }
    
    @discardableResult
    public override func start(success: ((KKBaseRequest) -> Void)? = nil,
                              failure: ((KKBaseRequest) -> Void)? = nil) -> Self {
        
        if enableRateLimit() {
            let key = rateLimitKey()
            
            if !KKRateLimiter.shared.shouldAllowRequest(for: key) {
                // 直接调用失败回调，不需要设置 error（error 是 private(set)）
                DispatchQueue.main.async {
                    failure?(self)
                }
                
                return self
            }
        }
        
        return super.start(success: success, failure: failure)
    }
}
