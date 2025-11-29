//
//  KKTimeoutManager.swift
//  KKNetwork
//
//  超时管理（支持动态超时、自适应超时）
//

import Foundation

/// 超时策略
public enum KKTimeoutStrategy {
    case fixed(TimeInterval)                    // 固定超时
    case adaptive                                // 自适应超时
    case networkDependent                        // 根据网络类型
}

/// 超时管理器
public class KKTimeoutManager {
    
    // MARK: - Singleton
    
    public static let shared = KKTimeoutManager()
    
    private init() {}
    
    // MARK: - Properties
    
    /// 默认超时时间
    public var defaultTimeout: TimeInterval = 30
    
    /// WiFi 超时时间
    public var wifiTimeout: TimeInterval = 15
    
    /// 蜂窝网络超时时间
    public var cellularTimeout: TimeInterval = 30
    
    /// 自适应超时的历史记录
    private var responseTimeHistory: [String: [TimeInterval]] = [:]
    
    /// 历史记录最大数量
    private let maxHistoryCount = 10
    
    // MARK: - Public Methods
    
    /// 获取超时时间
    public func timeout(for url: String, strategy: KKTimeoutStrategy = .fixed(30)) -> TimeInterval {
        switch strategy {
        case .fixed(let timeout):
            return timeout
            
        case .adaptive:
            return adaptiveTimeout(for: url)
            
        case .networkDependent:
            return networkDependentTimeout()
        }
    }
    
    /// 记录响应时间
    public func recordResponseTime(_ time: TimeInterval, for url: String) {
        var history = responseTimeHistory[url] ?? []
        history.append(time)
        
        if history.count > maxHistoryCount {
            history.removeFirst()
        }
        
        responseTimeHistory[url] = history
    }
    
    // MARK: - Private Methods
    
    private func adaptiveTimeout(for url: String) -> TimeInterval {
        guard let history = responseTimeHistory[url], !history.isEmpty else {
            return defaultTimeout
        }
        
        // 计算平均响应时间
        let average = history.reduce(0, +) / Double(history.count)
        
        // 计算标准差
        let variance = history.map { pow($0 - average, 2) }.reduce(0, +) / Double(history.count)
        let standardDeviation = sqrt(variance)
        
        // 超时时间 = 平均时间 + 2倍标准差
        let timeout = average + (2 * standardDeviation)
        
        // 限制在合理范围内
        return min(max(timeout, 5), 60)
    }
    
    private func networkDependentTimeout() -> TimeInterval {
        if KKReachability.shared.isReachableViaWiFi {
            return wifiTimeout
        } else if KKReachability.shared.isReachableViaCellular {
            return cellularTimeout
        } else {
            return defaultTimeout
        }
    }
}
