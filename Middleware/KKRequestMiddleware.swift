//
//  KKRequestMiddleware.swift
//  KKNetwork
//
//  请求中间件（类似 Express 的中间件模式）
//

import Foundation

/// 中间件协议
public protocol KKRequestMiddleware {
    /// 处理请求（返回 true 继续，false 中断）
    func process(_ request: KKBaseRequest, next: @escaping () -> Void) -> Bool
}

/// 中间件管理器
public class KKMiddlewareManager {
    
    // MARK: - Singleton
    
    public static let shared = KKMiddlewareManager()
    
    private init() {}
    
    // MARK: - Properties
    
    private var middlewares: [KKRequestMiddleware] = []
    
    // MARK: - Public Methods
    
    /// 添加中间件
    public func use(_ middleware: KKRequestMiddleware) {
        middlewares.append(middleware)
    }
    
    /// 执行中间件链
    public func execute(for request: KKBaseRequest, completion: @escaping () -> Void) {
        executeMiddleware(at: 0, for: request, completion: completion)
    }
    
    // MARK: - Private Methods
    
    private func executeMiddleware(at index: Int, for request: KKBaseRequest, completion: @escaping () -> Void) {
        guard index < middlewares.count else {
            completion()
            return
        }
        
        let middleware = middlewares[index]
        let shouldContinue = middleware.process(request) { [weak self] in
            self?.executeMiddleware(at: index + 1, for: request, completion: completion)
        }
        
        if !shouldContinue {
            KKNetworkLogger.log("⚠️ 请求被中间件拦截: \(request.requestPath())", level: .info)
        }
    }
}

// MARK: - 内置中间件

/// 认证中间件
public class KKAuthMiddleware: KKRequestMiddleware {
    
    private let tokenProvider: () -> String?
    
    public init(tokenProvider: @escaping () -> String?) {
        self.tokenProvider = tokenProvider
    }
    
    public func process(_ request: KKBaseRequest, next: @escaping () -> Void) -> Bool {
        if let token = tokenProvider() {
            KKNetworkConfig.shared.commonHeaders.add(name: "Authorization", value: "Bearer \(token)")
            next()
            return true
        } else {
            KKNetworkLogger.log("⚠️ Token 不存在，请求被拦截", level: .error)
            return false
        }
    }
}

/// 签名中间件
public class KKSignatureMiddleware: KKRequestMiddleware {
    
    private let signatureGenerator: ([String: Any]?) -> String
    
    public init(signatureGenerator: @escaping ([String: Any]?) -> String) {
        self.signatureGenerator = signatureGenerator
    }
    
    public func process(_ request: KKBaseRequest, next: @escaping () -> Void) -> Bool {
        let signature = signatureGenerator(request.requestParameters())
        KKNetworkConfig.shared.commonHeaders.add(name: "X-Signature", value: signature)
        next()
        return true
    }
}
