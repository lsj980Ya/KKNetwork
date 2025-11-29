//
//  KKChainRequest.swift
//  KKNetwork
//
//  链式请求管理（参考 YTKNetwork）
//

import Foundation

/// 链式请求
public class KKChainRequest {
    
    // MARK: - Properties
    
    private var requestArray: [KKBaseRequest] = []
    private var currentIndex: Int = 0
    private var successBlock: (() -> Void)?
    private var failureBlock: ((KKBaseRequest) -> Void)?
    
    /// 请求回调闭包（用于根据上一个请求结果配置下一个请求）
    public typealias ChainCallback = (KKChainRequest, KKBaseRequest) -> Void
    private var chainCallbacks: [ChainCallback] = []
    
    // MARK: - Public Methods
    
    /// 添加请求
    @discardableResult
    public func addRequest(_ request: KKBaseRequest, callback: ChainCallback? = nil) -> Self {
        requestArray.append(request)
        if let callback = callback {
            chainCallbacks.append(callback)
        }
        return self
    }
    
    /// 开始链式请求
    @discardableResult
    public func start(success: (() -> Void)? = nil,
                     failure: ((KKBaseRequest) -> Void)? = nil) -> Self {
        self.successBlock = success
        self.failureBlock = failure
        
        guard !requestArray.isEmpty else {
            success?()
            return self
        }
        
        KKNetworkLogger.log("⛓ 开始链式请求，共 \(requestArray.count) 个", level: .info)
        
        startNextRequest()
        return self
    }
    
    /// 取消链式请求
    public func cancel() {
        if currentIndex < requestArray.count {
            requestArray[currentIndex].cancel()
        }
        KKNetworkLogger.log("⛓ 取消链式请求", level: .info)
    }
    
    // MARK: - Private Methods
    
    private func startNextRequest() {
        guard currentIndex < requestArray.count else {
            KKNetworkLogger.log("⛓ 链式请求全部完成", level: .info)
            successBlock?()
            return
        }
        
        let request = requestArray[currentIndex]
        let callbackIndex = currentIndex
        
        KKNetworkLogger.log("⛓ 执行第 \(currentIndex + 1)/\(requestArray.count) 个请求", level: .info)
        
        request.start(
            success: { [weak self] finishedRequest in
                guard let self = self else { return }
                
                // 执行回调（如果有）
                if callbackIndex < self.chainCallbacks.count {
                    self.chainCallbacks[callbackIndex](self, finishedRequest)
                }
                
                self.currentIndex += 1
                self.startNextRequest()
            },
            failure: { [weak self] failedRequest in
                guard let self = self else { return }
                KKNetworkLogger.log("⛓ 链式请求失败", level: .error)
                self.failureBlock?(failedRequest)
            }
        )
    }
}
