//
//  KKObservability.swift
//  KKNetwork
//
//  可观测性（Metrics、Logs、Traces 三大支柱）
//

import Foundation

/// 可观测性事件
public enum KKObservabilityEvent {
    case requestStarted(url: String, method: String)
    case requestCompleted(url: String, duration: TimeInterval, statusCode: Int?)
    case requestFailed(url: String, error: Error)
    case cacheHit(url: String)
    case cacheMiss(url: String)
    case retryAttempt(url: String, attempt: Int)
    case circuitBreakerOpened(service: String)
    case circuitBreakerClosed(service: String)
}

/// 可观测性管理器
public class KKObservability {
    
    // MARK: - Singleton
    
    public static let shared = KKObservability()
    
    private init() {}
    
    // MARK: - Properties
    
    /// 事件回调
    public var eventHandler: ((KKObservabilityEvent) -> Void)?
    
    /// 是否启用
    public var isEnabled: Bool = false
    
    // MARK: - Public Methods
    
    /// 记录事件
    public func record(_ event: KKObservabilityEvent) {
        guard isEnabled else { return }
        
        eventHandler?(event)
        logEvent(event)
    }
    
    // MARK: - Private Methods
    
    private func logEvent(_ event: KKObservabilityEvent) {
        switch event {
        case .requestStarted(let url, let method):
            KKNetworkLogger.log("📊 [Observability] 请求开始: \(method) \(url)", level: .verbose)
            
        case .requestCompleted(let url, let duration, let statusCode):
            KKNetworkLogger.log("📊 [Observability] 请求完成: \(url) - \(String(format: "%.2f", duration * 1000))ms - \(statusCode ?? 0)", level: .verbose)
            
        case .requestFailed(let url, let error):
            KKNetworkLogger.log("📊 [Observability] 请求失败: \(url) - \(error.localizedDescription)", level: .verbose)
            
        case .cacheHit(let url):
            KKNetworkLogger.log("📊 [Observability] 缓存命中: \(url)", level: .verbose)
            
        case .cacheMiss(let url):
            KKNetworkLogger.log("📊 [Observability] 缓存未命中: \(url)", level: .verbose)
            
        case .retryAttempt(let url, let attempt):
            KKNetworkLogger.log("📊 [Observability] 重试: \(url) - 第 \(attempt) 次", level: .verbose)
            
        case .circuitBreakerOpened(let service):
            KKNetworkLogger.log("📊 [Observability] 熔断器打开: \(service)", level: .verbose)
            
        case .circuitBreakerClosed(let service):
            KKNetworkLogger.log("📊 [Observability] 熔断器关闭: \(service)", level: .verbose)
        }
    }
}
