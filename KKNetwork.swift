//
//  KKNetwork.swift
//  KKNetwork
//
//  框架入口文件
//

import Foundation

/// KKNetwork 框架入口
public class KKNetwork {
    
    /// 版本号
    public static let version = "1.0.0"
    
    /// 配置网络框架
    public static func setup(baseURL: String,
                            backupURLs: [String] = [],
                            commonHeaders: [String: String] = [:],
                            commonParameters: [String: Any] = [:],
                            timeoutInterval: TimeInterval = 30,
                            enableLog: Bool = true,
                            logLevel: KKLogLevel = .verbose) {
        
        let config = KKNetworkConfig.shared
        config.baseURL = baseURL
        config.backupBaseURLs = backupURLs
        config.timeoutInterval = timeoutInterval
        config.enableLog = enableLog
        config.logLevel = logLevel
        
        // 设置公共请求头
        for (key, value) in commonHeaders {
            config.commonHeaders.add(name: key, value: value)
        }
        
        // 设置公共参数
        config.commonParameters = commonParameters
        
        KKNetworkLogger.log("🚀 KKNetwork v\(version) 初始化完成", level: .info)
    }
}
