//
//  KKRetryPolicy.swift
//  KKNetwork
//
//  高级重试策略（指数退避、抖动等）
//

import Foundation

/// 重试策略
public protocol KKRetryPolicy {
    /// 是否应该重试
    func shouldRetry(request: KKBaseRequest, error: Error, attemptCount: Int) -> Bool
    
    /// 重试延迟时间
    func retryDelay(attemptCount: Int) -> TimeInterval
}

/// 简单重试策略
public struct KKSimpleRetryPolicy: KKRetryPolicy {
    
    public let maxAttempts: Int
    public let delay: TimeInterval
    
    public init(maxAttempts: Int = 3, delay: TimeInterval = 1.0) {
        self.maxAttempts = maxAttempts
        self.delay = delay
    }
    
    public func shouldRetry(request: KKBaseRequest, error: Error, attemptCount: Int) -> Bool {
        return attemptCount < maxAttempts
    }
    
    public func retryDelay(attemptCount: Int) -> TimeInterval {
        return delay
    }
}

/// 指数退避重试策略
public struct KKExponentialBackoffRetryPolicy: KKRetryPolicy {
    
    public let maxAttempts: Int
    public let baseDelay: TimeInterval
    public let maxDelay: TimeInterval
    public let multiplier: Double
    
    public init(maxAttempts: Int = 5,
                baseDelay: TimeInterval = 1.0,
                maxDelay: TimeInterval = 60.0,
                multiplier: Double = 2.0) {
        self.maxAttempts = maxAttempts
        self.baseDelay = baseDelay
        self.maxDelay = maxDelay
        self.multiplier = multiplier
    }
    
    public func shouldRetry(request: KKBaseRequest, error: Error, attemptCount: Int) -> Bool {
        return attemptCount < maxAttempts
    }
    
    public func retryDelay(attemptCount: Int) -> TimeInterval {
        let delay = baseDelay * pow(multiplier, Double(attemptCount - 1))
        return min(delay, maxDelay)
    }
}

/// 带抖动的指数退避策略
public struct KKJitteredRetryPolicy: KKRetryPolicy {
    
    public let maxAttempts: Int
    public let baseDelay: TimeInterval
    public let maxDelay: TimeInterval
    public let multiplier: Double
    
    public init(maxAttempts: Int = 5,
                baseDelay: TimeInterval = 1.0,
                maxDelay: TimeInterval = 60.0,
                multiplier: Double = 2.0) {
        self.maxAttempts = maxAttempts
        self.baseDelay = baseDelay
        self.maxDelay = maxDelay
        self.multiplier = multiplier
    }
    
    public func shouldRetry(request: KKBaseRequest, error: Error, attemptCount: Int) -> Bool {
        return attemptCount < maxAttempts
    }
    
    public func retryDelay(attemptCount: Int) -> TimeInterval {
        let exponentialDelay = baseDelay * pow(multiplier, Double(attemptCount - 1))
        let jitter = Double.random(in: 0...1) * exponentialDelay * 0.3
        let delay = exponentialDelay + jitter
        return min(delay, maxDelay)
    }
}

/// 条件重试策略（根据错误类型决定）
public struct KKConditionalRetryPolicy: KKRetryPolicy {
    
    public let maxAttempts: Int
    public let delay: TimeInterval
    public let retryableStatusCodes: Set<Int>
    
    public init(maxAttempts: Int = 3,
                delay: TimeInterval = 1.0,
                retryableStatusCodes: Set<Int> = [408, 429, 500, 502, 503, 504]) {
        self.maxAttempts = maxAttempts
        self.delay = delay
        self.retryableStatusCodes = retryableStatusCodes
    }
    
    public func shouldRetry(request: KKBaseRequest, error: Error, attemptCount: Int) -> Bool {
        guard attemptCount < maxAttempts else { return false }
        
        // 检查是否是网络错误
        let nsError = error as NSError
        if nsError.domain == NSURLErrorDomain {
            // 超时、网络不可达等可以重试
            let retryableErrors: Set<Int> = [
                NSURLErrorTimedOut,
                NSURLErrorCannotConnectToHost,
                NSURLErrorNetworkConnectionLost,
                NSURLErrorNotConnectedToInternet
            ]
            return retryableErrors.contains(nsError.code)
        }
        
        return false
    }
    
    public func retryDelay(attemptCount: Int) -> TimeInterval {
        return delay
    }
}
