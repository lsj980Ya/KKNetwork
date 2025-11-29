//
//  KKRequestQueue.swift
//  KKNetwork
//
//  请求队列管理（控制并发数）
//

import Foundation

/// 请求队列
public class KKRequestQueue {
    
    // MARK: - Singleton
    
    public static let shared = KKRequestQueue()
    
    private init() {}
    
    // MARK: - Properties
    
    /// 最大并发数
    public var maxConcurrentRequests: Int = 5 {
        didSet {
            processQueue()
        }
    }
    
    /// 当前执行中的请求
    private var runningRequests: [KKBaseRequest] = []
    
    /// 等待队列
    private var pendingRequests: [(request: KKBaseRequest, success: ((KKBaseRequest) -> Void)?, failure: ((KKBaseRequest) -> Void)?)] = []
    
    /// 队列锁
    private let lock = NSLock()
    
    // MARK: - Public Methods
    
    /// 添加请求到队列
    public func enqueue(_ request: KKBaseRequest,
                       success: ((KKBaseRequest) -> Void)? = nil,
                       failure: ((KKBaseRequest) -> Void)? = nil) {
        lock.lock()
        defer { lock.unlock() }
        
        if runningRequests.count < maxConcurrentRequests {
            executeRequest(request, success: success, failure: failure)
        } else {
            pendingRequests.append((request, success, failure))
            KKNetworkLogger.log("📋 请求加入等待队列: \(request.requestPath())", level: .info)
        }
    }
    
    /// 取消所有请求
    public func cancelAll() {
        lock.lock()
        defer { lock.unlock() }
        
        for request in runningRequests {
            request.cancel()
        }
        
        runningRequests.removeAll()
        pendingRequests.removeAll()
    }
    
    // MARK: - Private Methods
    
    private func executeRequest(_ request: KKBaseRequest,
                               success: ((KKBaseRequest) -> Void)?,
                               failure: ((KKBaseRequest) -> Void)?) {
        runningRequests.append(request)
        
        request.start(
            success: { [weak self] finishedRequest in
                self?.handleRequestComplete(finishedRequest)
                success?(finishedRequest)
            },
            failure: { [weak self] failedRequest in
                self?.handleRequestComplete(failedRequest)
                failure?(failedRequest)
            }
        )
    }
    
    private func handleRequestComplete(_ request: KKBaseRequest) {
        lock.lock()
        defer { lock.unlock() }
        
        if let index = runningRequests.firstIndex(where: { $0 === request }) {
            runningRequests.remove(at: index)
        }
        
        processQueue()
    }
    
    private func processQueue() {
        lock.lock()
        defer { lock.unlock() }
        
        while runningRequests.count < maxConcurrentRequests && !pendingRequests.isEmpty {
            let item = pendingRequests.removeFirst()
            executeRequest(item.request, success: item.success, failure: item.failure)
        }
    }
}
