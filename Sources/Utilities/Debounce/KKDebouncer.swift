//
//  KKDebouncer.swift
//  KKNetwork
//
//  防抖和节流（用于搜索等场景）
//

import Foundation

/// 防抖器
public class KKDebouncer {
    
    private let delay: TimeInterval
    private var workItem: DispatchWorkItem?
    
    public init(delay: TimeInterval) {
        self.delay = delay
    }
    
    /// 执行防抖
    public func debounce(action: @escaping () -> Void) {
        workItem?.cancel()
        
        let newWorkItem = DispatchWorkItem(block: action)
        workItem = newWorkItem
        
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: newWorkItem)
    }
    
    /// 取消
    public func cancel() {
        workItem?.cancel()
    }
}

/// 节流器
public class KKThrottler {
    
    private let interval: TimeInterval
    private var lastExecutionTime: Date?
    private var workItem: DispatchWorkItem?
    
    public init(interval: TimeInterval) {
        self.interval = interval
    }
    
    /// 执行节流
    public func throttle(action: @escaping () -> Void) {
        let now = Date()
        
        if let lastTime = lastExecutionTime {
            let timeSinceLastExecution = now.timeIntervalSince(lastTime)
            
            if timeSinceLastExecution < interval {
                // 还在节流期内，延迟执行
                workItem?.cancel()
                
                let delay = interval - timeSinceLastExecution
                let newWorkItem = DispatchWorkItem { [weak self] in
                    self?.lastExecutionTime = Date()
                    action()
                }
                workItem = newWorkItem
                
                DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: newWorkItem)
                return
            }
        }
        
        // 立即执行
        lastExecutionTime = now
        action()
    }
    
    /// 取消
    public func cancel() {
        workItem?.cancel()
    }
}

// MARK: - 防抖请求

/// 支持防抖的请求
open class KKDebouncedRequest: KKBaseRequest {
    
    private static var debouncers: [String: KKDebouncer] = [:]
    
    /// 防抖延迟时间
    open func debounceDelay() -> TimeInterval {
        return 0.3
    }
    
    /// 防抖 Key（相同 Key 的请求会互相取消）
    open func debounceKey() -> String {
        return requestPath()
    }
    
    @discardableResult
    public override func start(success: ((KKBaseRequest) -> Void)? = nil,
                              failure: ((KKBaseRequest) -> Void)? = nil) -> Self {
        
        let key = debounceKey()
        let delay = debounceDelay()
        
        if delay > 0 {
            let debouncer = KKDebouncedRequest.debouncers[key] ?? KKDebouncer(delay: delay)
            KKDebouncedRequest.debouncers[key] = debouncer
            
            debouncer.debounce { [self] in
                _ = self.startSuper(success: success, failure: failure)
            }
            
            return self
        } else {
            return super.start(success: success, failure: failure)
        }
    }
    
    /// 调用父类的 start 方法
    private func startSuper(success: ((KKBaseRequest) -> Void)?,
                           failure: ((KKBaseRequest) -> Void)?) -> Self {
        return super.start(success: success, failure: failure)
    }
}

// MARK: - 搜索请求示例

/// 搜索请求（自动防抖）
open class KKSearchRequest: KKDebouncedRequest {
    
    public var keyword: String
    
    public init(keyword: String) {
        self.keyword = keyword
        super.init()
    }
    
    open override func requestPath() -> String {
        return "/api/search"
    }
    
    open override func requestParameters() -> [String: Any]? {
        return ["keyword": keyword]
    }
    
    open override func debounceDelay() -> TimeInterval {
        return 0.5 // 搜索延迟 500ms
    }
}
