//
//  KKNetworkConfig.swift
//  KKNetwork
//
//  网络配置管理类
//

import Foundation
import Alamofire

/// 网络配置单例
public class KKNetworkConfig {
    
    // MARK: - Singleton
    public static let shared = KKNetworkConfig()
    
    private init() {}
    
    // MARK: - Properties
    
    /// 主域名
    public var baseURL: String = ""
    
    /// 备用域名列表（用于域名切换重试）
    public var backupBaseURLs: [String] = []
    
    /// 公共请求头
    public var commonHeaders: HTTPHeaders = [:]
    
    /// 公共参数
    public var commonParameters: [String: Any] = [:]
    
    /// 超时时间
    public var timeoutInterval: TimeInterval = 30
    
    /// 是否启用日志
    public var enableLog: Bool = true
    
    /// 日志级别
    public var logLevel: KKLogLevel = .verbose
    
    /// Session 配置
    public lazy var sessionConfiguration: URLSessionConfiguration = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = timeoutInterval
        config.timeoutIntervalForResource = timeoutInterval
        return config
    }()
    
    /// 拦截器列表
    internal var interceptors: [KKRequestInterceptor] = []
    
    /// 添加拦截器
    public func addInterceptor(_ interceptor: KKRequestInterceptor) {
        interceptors.append(interceptor)
    }
    
    /// 移除所有拦截器
    public func removeAllInterceptors() {
        interceptors.removeAll()
    }
}

/// 日志级别
public enum KKLogLevel: Int {
    case none = 0      // 不打印
    case error = 1     // 只打印错误
    case info = 2      // 打印基本信息
    case verbose = 3   // 打印详细信息
}
