//
//  KKRequestPriority.swift
//  KKNetwork
//
//  请求优先级管理
//

import Foundation

/// 请求优先级
public enum KKRequestPriority: Int, Comparable {
    case low = 0
    case normal = 1
    case high = 2
    case critical = 3
    
    public static func < (lhs: KKRequestPriority, rhs: KKRequestPriority) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }
}

/// 优先级队列
public class KKPriorityQueue {
    
    // MARK: - Singleton
    
    public static let shared = KKPriorityQueue()
    
    private init() {}
    
    // MARK: - Properties
    
    private var queues: [KKRequestPriority: [(request: KKBaseRequest, success: ((KKBaseRequest) -> Void)?, failure: ((KKBaseRequest) -> Void)?)]] = [
        .low: [],
        .normal: [],
        .high: [],
        .critical: []
    ]
    
    private var runningRequests: [KKBaseRequest] = []
    private let lock = NSLock()
    
    /// 最大并发数
    public var maxConcurrentRequests: Int = 5
    
    // MARK: - Public Methods
    
    /// 添加请求
    public func enqueue(_ request: KKBaseRequest,
                       priority: KKRequestPriority = .normal,
                       success: ((KKBaseRequest) -> Void)? = nil,
                       failure: ((KKBaseRequest) -> Void)? = nil) {
        lock.lock()
        defer { lock.unlock() }
        
        queues[priority]?.append((request, success, failure))
        processQueue()
    }
    
    // MARK: - Private Methods
    
    private func processQueue() {
        while runningRequests.count < maxConcurrentRequests {
            guard let nextItem = dequeueHighestPriority() else { break }
            
            runningRequests.append(nextItem.request)
            
            nextItem.request.start(
                success: { [weak self] finishedRequest in
                    self?.handleRequestComplete(finishedRequest)
                    nextItem.success?(finishedRequest)
                },
                failure: { [weak self] failedRequest in
                    self?.handleRequestComplete(failedRequest)
                    nextItem.failure?(failedRequest)
                }
            )
        }
    }
    
    private func dequeueHighestPriority() -> (request: KKBaseRequest, success: ((KKBaseRequest) -> Void)?, failure: ((KKBaseRequest) -> Void)?)? {
        let priorities: [KKRequestPriority] = [.critical, .high, .normal, .low]
        
        for priority in priorities {
            if let queue = queues[priority], !queue.isEmpty {
                let item = queues[priority]?.removeFirst()
                return item
            }
        }
        
        return nil
    }
    
    private func handleRequestComplete(_ request: KKBaseRequest) {
        lock.lock()
        defer { lock.unlock() }
        
        if let index = runningRequests.firstIndex(where: { $0 === request }) {
            runningRequests.remove(at: index)
        }
        
        processQueue()
    }
}

// MARK: - 支持优先级的请求

open class KKPriorityRequest: KKBaseRequest {
    
    /// 请求优先级
    open func priority() -> KKRequestPriority {
        return .normal
    }
    
    @discardableResult
    public override func start(success: ((KKBaseRequest) -> Void)? = nil,
                              failure: ((KKBaseRequest) -> Void)? = nil) -> Self {
        KKPriorityQueue.shared.enqueue(self, priority: priority(), success: success, failure: failure)
        return self
    }
}
