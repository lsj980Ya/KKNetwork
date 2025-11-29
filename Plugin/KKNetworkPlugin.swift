//
//  KKNetworkPlugin.swift
//  KKNetwork
//
//  网络插件系统（支持更灵活的扩展）
//

import Foundation
import Alamofire

/// 网络插件协议
public protocol KKNetworkPlugin {
    /// 准备发送请求（可以修改请求）
    func prepare(_ request: inout URLRequest, target: KKBaseRequest)
    
    /// 请求即将发送
    func willSend(_ request: URLRequest, target: KKBaseRequest)
    
    /// 收到响应
    func didReceive(_ result: Result<Data, Error>, target: KKBaseRequest)
    
    /// 请求完成（无论成功失败）
    func didComplete(_ target: KKBaseRequest)
}

// MARK: - 默认实现

public extension KKNetworkPlugin {
    func prepare(_ request: inout URLRequest, target: KKBaseRequest) {}
    func willSend(_ request: URLRequest, target: KKBaseRequest) {}
    func didReceive(_ result: Result<Data, Error>, target: KKBaseRequest) {}
    func didComplete(_ target: KKBaseRequest) {}
}

// MARK: - 内置插件

/// 网络状态插件
public class KKNetworkStatusPlugin: KKNetworkPlugin {
    
    public func willSend(_ request: URLRequest, target: KKBaseRequest) {
        if !isNetworkAvailable() {
            KKNetworkLogger.log("⚠️ 网络不可用", level: .error)
        }
    }
    
    private func isNetworkAvailable() -> Bool {
        // 简化实现，实际应使用 Reachability
        return true
    }
}

/// 性能监控插件
public class KKPerformancePlugin: KKNetworkPlugin {
    
    private var startTimes: [String: Date] = [:]
    
    public func willSend(_ request: URLRequest, target: KKBaseRequest) {
        let key = requestKey(target)
        startTimes[key] = Date()
    }
    
    public func didComplete(_ target: KKBaseRequest) {
        let key = requestKey(target)
        if let startTime = startTimes[key] {
            let duration = Date().timeIntervalSince(startTime)
            KKNetworkLogger.log("⏱ 请求耗时: \(String(format: "%.2f", duration))s - \(target.requestPath())", level: .info)
            startTimes.removeValue(forKey: key)
        }
    }
    
    private func requestKey(_ target: KKBaseRequest) -> String {
        return "\(target.requestPath())-\(target.tag)"
    }
}

/// 数据加密插件
public class KKEncryptionPlugin: KKNetworkPlugin {
    
    private let encryptionHandler: ([String: Any]) -> [String: Any]
    
    public init(encryptionHandler: @escaping ([String: Any]) -> [String: Any]) {
        self.encryptionHandler = encryptionHandler
    }
    
    public func prepare(_ request: inout URLRequest, target: KKBaseRequest) {
        // 加密请求参数
        if let params = target.requestParameters() {
            let encryptedParams = encryptionHandler(params)
            // 更新请求体
            if let jsonData = try? JSONSerialization.data(withJSONObject: encryptedParams) {
                request.httpBody = jsonData
            }
        }
    }
}
