//
//  KKCircuitBreaker.swift
//  KKNetwork
//
//  熔断器（防止雪崩效应）
//

import Foundation

/// 熔断器状态
public enum KKCircuitState {
    case closed      // 正常状态
    case open        // 熔断状态（拒绝请求）
    case halfOpen    // 半开状态（尝试恢复）
}

/// 熔断器配置
public struct KKCircuitBreakerConfig {
    /// 失败阈值（连续失败多少次后熔断）
    public var failureThreshold: Int = 5
    
    /// 成功阈值（半开状态下成功多少次后恢复）
    public var successThreshold: Int = 2
    
    /// 超时时间（熔断后多久尝试恢复）
    public var timeout: TimeInterval = 60
    
    /// 时间窗口（统计时间范围）
    public var timeWindow: TimeInterval = 60
    
    public init() {}
}

/// 熔断器
public class KKCircuitBreaker {
    
    // MARK: - Properties
    
    private let config: KKCircuitBreakerConfig
    private var state: KKCircuitState = .closed
    private var failureCount: Int = 0
    private var successCount: Int = 0
    private var lastFailureTime: Date?
    private var openTime: Date?
    private let lock = NSLock()
    
    /// 状态变化回调
    public var stateChangeHandler: ((KKCircuitState) -> Void)?
    
    // MARK: - Initialization
    
    public init(config: KKCircuitBreakerConfig = KKCircuitBreakerConfig()) {
        self.config = config
    }
    
    // MARK: - Public Methods
    
    /// 是否允许请求
    public func allowRequest() -> Bool {
        lock.lock()
        defer { lock.unlock() }
        
        switch state {
        case .closed:
            return true
            
        case .open:
            // 检查是否可以进入半开状态
            if let openTime = openTime,
               Date().timeIntervalSince(openTime) >= config.timeout {
                changeState(.halfOpen)
                return true
            }
            return false
            
        case .halfOpen:
            return true
        }
    }
    
    /// 记录成功
    public func recordSuccess() {
        lock.lock()
        defer { lock.unlock() }
        
        switch state {
        case .closed:
            failureCount = 0
            
        case .halfOpen:
            successCount += 1
            if successCount >= config.successThreshold {
                changeState(.closed)
                successCount = 0
                failureCount = 0
            }
            
        case .open:
            break
        }
    }
    
    /// 记录失败
    public func recordFailure() {
        lock.lock()
        defer { lock.unlock() }
        
        lastFailureTime = Date()
        
        switch state {
        case .closed:
            failureCount += 1
            if failureCount >= config.failureThreshold {
                changeState(.open)
                openTime = Date()
            }
            
        case .halfOpen:
            changeState(.open)
            openTime = Date()
            successCount = 0
            
        case .open:
            break
        }
    }
    
    /// 重置
    public func reset() {
        lock.lock()
        defer { lock.unlock() }
        
        changeState(.closed)
        failureCount = 0
        successCount = 0
        lastFailureTime = nil
        openTime = nil
    }
    
    // MARK: - Private Methods
    
    private func changeState(_ newState: KKCircuitState) {
        if state != newState {
            state = newState
            KKNetworkLogger.log("⚡️ 熔断器状态变化: \(stateDescription(newState))", level: .info)
            stateChangeHandler?(newState)
        }
    }
    
    private func stateDescription(_ state: KKCircuitState) -> String {
        switch state {
        case .closed: return "正常"
        case .open: return "熔断"
        case .halfOpen: return "半开"
        }
    }
}

/// 熔断器管理器
public class KKCircuitBreakerManager {
    
    // MARK: - Singleton
    
    public static let shared = KKCircuitBreakerManager()
    
    private init() {}
    
    // MARK: - Properties
    
    private var breakers: [String: KKCircuitBreaker] = [:]
    
    /// 默认配置
    public var defaultConfig = KKCircuitBreakerConfig()
    
    // MARK: - Public Methods
    
    /// 获取熔断器
    public func breaker(for key: String) -> KKCircuitBreaker {
        if let breaker = breakers[key] {
            return breaker
        }
        
        let breaker = KKCircuitBreaker(config: defaultConfig)
        breakers[key] = breaker
        return breaker
    }
    
    /// 移除熔断器
    public func removeBreaker(for key: String) {
        breakers.removeValue(forKey: key)
    }
    
    /// 重置所有熔断器
    public func resetAll() {
        breakers.values.forEach { $0.reset() }
    }
}

// MARK: - 支持熔断的请求

open class KKCircuitBreakerRequest: KKBaseRequest {
    
    /// 熔断器 Key
    open func circuitBreakerKey() -> String {
        return requestPath()
    }
    
    @discardableResult
    public override func start(success: ((KKBaseRequest) -> Void)? = nil,
                              failure: ((KKBaseRequest) -> Void)? = nil) -> Self {
        
        let breaker = KKCircuitBreakerManager.shared.breaker(for: circuitBreakerKey())
        
        if !breaker.allowRequest() {
            let error = NSError(domain: "KKNetwork",
                              code: -1004,
                              userInfo: [NSLocalizedDescriptionKey: "服务熔断，请稍后再试"])
            self.error = error
            
            DispatchQueue.main.async {
                failure?(self)
            }
            
            return self
        }
        
        return super.start(
            success: { request in
                breaker.recordSuccess()
                success?(request)
            },
            failure: { request in
                breaker.recordFailure()
                failure?(request)
            }
        )
    }
}
