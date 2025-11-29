//
//  KKBatchRequest.swift
//  KKNetwork
//
//  批量请求管理（参考 YTKNetwork）
//

import Foundation

/// 批量请求
public class KKBatchRequest {
    
    // MARK: - Properties
    
    private let requests: [KKBaseRequest]
    private var successBlock: (() -> Void)?
    private var failureBlock: ((KKBaseRequest) -> Void)?
    private var finishedCount: Int = 0
    private var isFailed: Bool = false
    
    // MARK: - Initialization
    
    public init(requests: [KKBaseRequest]) {
        self.requests = requests
    }
    
    // MARK: - Public Methods
    
    /// 开始批量请求
    @discardableResult
    public func start(success: (() -> Void)? = nil,
                     failure: ((KKBaseRequest) -> Void)? = nil) -> Self {
        self.successBlock = success
        self.failureBlock = failure
        
        guard !requests.isEmpty else {
            success?()
            return self
        }
        
        KKNetworkLogger.log("📦 开始批量请求，共 \(requests.count) 个", level: .info)
        
        for request in requests {
            request.start(
                success: { [weak self] _ in
                    self?.handleRequestFinished()
                },
                failure: { [weak self] failedRequest in
                    self?.handleRequestFailed(failedRequest)
                }
            )
        }
        
        return self
    }
    
    /// 取消所有请求
    public func cancel() {
        for request in requests {
            request.cancel()
        }
        KKNetworkLogger.log("📦 取消批量请求", level: .info)
    }
    
    // MARK: - Private Methods
    
    private func handleRequestFinished() {
        finishedCount += 1
        
        if finishedCount == requests.count && !isFailed {
            KKNetworkLogger.log("📦 批量请求全部成功", level: .info)
            successBlock?()
        }
    }
    
    private func handleRequestFailed(_ request: KKBaseRequest) {
        if !isFailed {
            isFailed = true
            KKNetworkLogger.log("📦 批量请求失败", level: .error)
            failureBlock?(request)
        }
    }
}
