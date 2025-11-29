//
//  KKPrefetchManager.swift
//  KKNetwork
//
//  预加载管理器（智能预取数据）
//

import Foundation

/// 预加载策略
public enum KKPrefetchStrategy {
    case immediate      // 立即预加载
    case idle          // 空闲时预加载
    case wifi          // 仅 WiFi 下预加载
}

/// 预加载项
public struct KKPrefetchItem {
    let request: KKBaseRequest
    let priority: KKRequestPriority
    let strategy: KKPrefetchStrategy
}

/// 预加载管理器
public class KKPrefetchManager {
    
    // MARK: - Singleton
    
    public static let shared = KKPrefetchManager()
    
    private init() {}
    
    // MARK: - Properties
    
    private var prefetchQueue: [KKPrefetchItem] = []
    private var isProcessing = false
    
    /// 是否启用预加载
    public var isEnabled: Bool = true
    
    // MARK: - Public Methods
    
    /// 添加预加载请求
    public func addPrefetch(_ request: KKBaseRequest,
                           priority: KKRequestPriority = .low,
                           strategy: KKPrefetchStrategy = .idle) {
        guard isEnabled else { return }
        
        let item = KKPrefetchItem(request: request, priority: priority, strategy: strategy)
        prefetchQueue.append(item)
        
        processPrefetchQueue()
    }
    
    /// 清空预加载队列
    public func clearQueue() {
        prefetchQueue.removeAll()
    }
    
    // MARK: - Private Methods
    
    private func processPrefetchQueue() {
        guard !isProcessing else { return }
        guard !prefetchQueue.isEmpty else { return }
        
        isProcessing = true
        
        // 按优先级排序
        prefetchQueue.sort { $0.priority > $1.priority }
        
        for item in prefetchQueue {
            if shouldPrefetch(item) {
                executePrefetch(item)
            }
        }
        
        prefetchQueue.removeAll()
        isProcessing = false
    }
    
    private func shouldPrefetch(_ item: KKPrefetchItem) -> Bool {
        switch item.strategy {
        case .immediate:
            return true
            
        case .idle:
            // 检查系统是否空闲（简化实现）
            return true
            
        case .wifi:
            return KKReachability.shared.isReachableViaWiFi
        }
    }
    
    private func executePrefetch(_ item: KKPrefetchItem) {
        KKNetworkLogger.log("🔮 预加载: \(item.request.requestPath())", level: .info)
        
        item.request.start(
            success: { _ in
                KKNetworkLogger.log("✅ 预加载成功", level: .info)
            },
            failure: { _ in
                KKNetworkLogger.log("❌ 预加载失败", level: .error)
            }
        )
    }
}
