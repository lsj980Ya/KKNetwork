//
//  KKOfflineManager.swift
//  KKNetwork
//
//  离线请求管理（网络恢复后自动发送）
//

import Foundation
import SwiftyJSON

/// 离线请求记录
struct KKOfflineRequest: Codable {
    let url: String
    let method: String
    let parameters: Data?
    let headers: [String: String]
    let timestamp: Date
}

/// 离线请求管理器
public class KKOfflineManager {
    
    // MARK: - Singleton
    
    public static let shared = KKOfflineManager()
    
    private init() {
        setupNetworkMonitoring()
    }
    
    // MARK: - Properties
    
    /// 是否启用离线模式
    public var isEnabled: Bool = false
    
    /// 离线请求队列
    private var offlineQueue: [KKOfflineRequest] = []
    
    /// 最大离线请求数
    public var maxOfflineRequests: Int = 50
    
    /// 离线请求过期时间（秒）
    public var offlineRequestExpiration: TimeInterval = 86400 // 24小时
    
    // MARK: - Public Methods
    
    /// 保存离线请求
    public func saveOfflineRequest(_ request: KKBaseRequest) {
        guard isEnabled else { return }
        guard !KKReachability.shared.isReachable else { return }
        
        let offlineRequest = KKOfflineRequest(
            url: request.requestPath(),
            method: request.requestMethod().rawValue,
            parameters: try? JSONSerialization.data(withJSONObject: request.requestParameters() ?? [:]),
            headers: request.requestHeaders()?.dictionary ?? [:],
            timestamp: Date()
        )
        
        offlineQueue.append(offlineRequest)
        
        // 限制队列大小
        if offlineQueue.count > maxOfflineRequests {
            offlineQueue.removeFirst()
        }
        
        saveToStorage()
        
        KKNetworkLogger.log("💾 保存离线请求: \(request.requestPath())", level: .info)
    }
    
    /// 发送所有离线请求
    public func sendOfflineRequests() {
        guard !offlineQueue.isEmpty else { return }
        guard KKReachability.shared.isReachable else { return }
        
        KKNetworkLogger.log("📤 发送 \(offlineQueue.count) 个离线请求", level: .info)
        
        let requests = offlineQueue
        offlineQueue.removeAll()
        saveToStorage()
        
        for offlineRequest in requests {
            // 检查是否过期
            if Date().timeIntervalSince(offlineRequest.timestamp) > offlineRequestExpiration {
                continue
            }
            
            // 重新发送请求
            // 这里需要根据实际情况创建请求对象
        }
    }
    
    // MARK: - Private Methods
    
    private func setupNetworkMonitoring() {
        KKReachability.shared.statusChangeHandler = { [weak self] status in
            if status != .notReachable {
                self?.sendOfflineRequests()
            }
        }
    }
    
    private func saveToStorage() {
        // 保存到本地存储
        if let data = try? JSONEncoder().encode(offlineQueue) {
            UserDefaults.standard.set(data, forKey: "KKOfflineRequests")
        }
    }
    
    private func loadFromStorage() {
        if let data = UserDefaults.standard.data(forKey: "KKOfflineRequests"),
           let requests = try? JSONDecoder().decode([KKOfflineRequest].self, from: data) {
            offlineQueue = requests
        }
    }
}
