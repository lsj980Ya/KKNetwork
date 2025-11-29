//
//  KKCanaryRelease.swift
//  KKNetwork
//
//  金丝雀发布（灰度发布）
//

import Foundation

/// 金丝雀规则
public struct KKCanaryRule {
    public let percentage: Double        // 流量百分比 (0-100)
    public let targetURL: String         // 目标服务器
    public let userIds: Set<String>?     // 指定用户 ID
    public let regions: Set<String>?     // 指定地区
    public let versions: Set<String>?    // 指定版本
    
    public init(percentage: Double,
                targetURL: String,
                userIds: Set<String>? = nil,
                regions: Set<String>? = nil,
                versions: Set<String>? = nil) {
        self.percentage = percentage
        self.targetURL = targetURL
        self.userIds = userIds
        self.regions = regions
        self.versions = versions
    }
}

/// 金丝雀发布管理器
public class KKCanaryRelease {
    
    // MARK: - Singleton
    
    public static let shared = KKCanaryRelease()
    
    private init() {}
    
    // MARK: - Properties
    
    /// 是否启用金丝雀发布
    public var isEnabled: Bool = false
    
    /// 金丝雀规则
    private var rules: [String: KKCanaryRule] = [:]
    
    /// 用户信息提供者
    public var userInfoProvider: (() -> (userId: String?, region: String?, version: String?))?
    
    // MARK: - Public Methods
    
    /// 添加金丝雀规则
    public func addRule(for path: String, rule: KKCanaryRule) {
        rules[path] = rule
        KKNetworkLogger.log("🐤 添加金丝雀规则: \(path) -> \(rule.targetURL) (\(rule.percentage)%)", level: .info)
    }
    
    /// 移除规则
    public func removeRule(for path: String) {
        rules.removeValue(forKey: path)
    }
    
    /// 获取目标 URL
    public func targetURL(for path: String, defaultURL: String) -> String {
        guard isEnabled else { return defaultURL }
        guard let rule = rules[path] else { return defaultURL }
        
        // 检查用户 ID
        if let userIds = rule.userIds,
           let userId = userInfoProvider?().userId,
           userIds.contains(userId) {
            KKNetworkLogger.log("🐤 金丝雀命中（用户ID）: \(rule.targetURL)", level: .info)
            return rule.targetURL
        }
        
        // 检查地区
        if let regions = rule.regions,
           let region = userInfoProvider?().region,
           regions.contains(region) {
            KKNetworkLogger.log("🐤 金丝雀命中（地区）: \(rule.targetURL)", level: .info)
            return rule.targetURL
        }
        
        // 检查版本
        if let versions = rule.versions,
           let version = userInfoProvider?().version,
           versions.contains(version) {
            KKNetworkLogger.log("🐤 金丝雀命中（版本）: \(rule.targetURL)", level: .info)
            return rule.targetURL
        }
        
        // 按百分比随机
        let random = Double.random(in: 0...100)
        if random < rule.percentage {
            KKNetworkLogger.log("🐤 金丝雀命中（随机）: \(rule.targetURL)", level: .info)
            return rule.targetURL
        }
        
        return defaultURL
    }
}

// MARK: - 支持金丝雀的请求

open class KKCanaryRequest: KKBaseRequest {
    
    open override func customBaseURL() -> String? {
        let defaultURL = KKNetworkConfig.shared.baseURL
        return KKCanaryRelease.shared.targetURL(for: requestPath(), defaultURL: defaultURL)
    }
}
