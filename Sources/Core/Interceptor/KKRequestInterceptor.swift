//
//  KKRequestInterceptor.swift
//  KKNetwork
//
//  请求拦截器协议
//

import Foundation

/// 请求拦截器协议
public protocol KKRequestInterceptor {
    
    /// 请求即将发送
    func willSend(_ request: KKBaseRequest)
    
    /// 请求已收到响应
    func didReceive(_ request: KKBaseRequest, error: Error?)
}

// MARK: - 默认实现

public extension KKRequestInterceptor {
    func willSend(_ request: KKBaseRequest) {}
    func didReceive(_ request: KKBaseRequest, error: Error?) {}
}

// MARK: - 常用拦截器

/// Token 拦截器示例
public class KKTokenInterceptor: KKRequestInterceptor {
    
    private let tokenProvider: () -> String?
    
    public init(tokenProvider: @escaping () -> String?) {
        self.tokenProvider = tokenProvider
    }
    
    public func willSend(_ request: KKBaseRequest) {
        if let token = tokenProvider() {
            KKNetworkConfig.shared.commonHeaders.add(name: "Authorization", value: "Bearer \(token)")
        }
    }
}

/// 通用响应拦截器
public class KKResponseInterceptor: KKRequestInterceptor {
    
    private let handler: (KKBaseRequest, Error?) -> Void
    
    public init(handler: @escaping (KKBaseRequest, Error?) -> Void) {
        self.handler = handler
    }
    
    public func didReceive(_ request: KKBaseRequest, error: Error?) {
        handler(request, error)
    }
}
