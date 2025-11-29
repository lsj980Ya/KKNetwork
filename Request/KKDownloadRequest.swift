//
//  KKDownloadRequest.swift
//  KKNetwork
//
//  文件下载请求
//

import Foundation
import Alamofire

/// 文件下载请求
open class KKDownloadRequest: KKBaseRequest {
    
    // MARK: - Properties
    
    private var downloadRequest: DownloadRequest?
    
    /// 下载进度回调
    public var progressBlock: ((Progress) -> Void)?
    
    /// 下载完成后的文件路径
    public private(set) var downloadedFileURL: URL?
    
    // MARK: - Download Configuration
    
    /// 下载目标路径
    open func downloadDestination() -> URL? {
        return nil
    }
    
    /// 是否支持断点续传
    open func resumable() -> Bool {
        return true
    }
    
    // MARK: - Override
    
    @discardableResult
    public override func start(success: ((KKBaseRequest) -> Void)? = nil,
                              failure: ((KKBaseRequest) -> Void)? = nil) -> Self {
        
        KKNetworkLogger.log("📥 开始下载: \(requestPath())", level: .info)
        
        // 执行拦截器
        for interceptor in KKNetworkConfig.shared.interceptors {
            interceptor.willSend(self)
        }
        
        let url = buildFullURL()
        let headers = buildHeaders()
        
        // 配置下载目标
        let destination: DownloadRequest.Destination = { [weak self] _, _ in
            guard let self = self else {
                let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
                return (tempURL, [])
            }
            
            let destinationURL = self.downloadDestination() ?? FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
            return (destinationURL, [.removePreviousFile, .createIntermediateDirectories])
        }
        
        // 创建下载请求
        if resumable() {
            downloadRequest = AF.download(resumingWith: Data(), to: destination)
        } else {
            downloadRequest = AF.download(url, headers: headers, to: destination)
        }
        
        // 监听下载进度
        downloadRequest?.downloadProgress { [weak self] progress in
            self?.progressBlock?(progress)
        }
        
        // 处理响应
        downloadRequest?.responseData { [weak self] response in
            guard let self = self else { return }
            self.handleDownloadResponse(response, success: success, failure: failure)
        }
        
        return self
    }
    
    public override func cancel() {
        downloadRequest?.cancel()
        KKNetworkLogger.log("❌ 取消下载: \(requestPath())", level: .info)
    }
    
    // MARK: - Private Methods
    
    private func handleDownloadResponse(_ response: AFDownloadResponse<Data>,
                                       success: ((KKBaseRequest) -> Void)?,
                                       failure: ((KKBaseRequest) -> Void)?) {
        switch response.result {
        case .success:
            self.downloadedFileURL = response.fileURL
            KKNetworkLogger.log("✅ 下载成功: \(requestPath())", level: .info)
            success?(self)
            
        case .failure(let error):
            self.error = error
            KKNetworkLogger.logError(url: response.request?.url?.absoluteString ?? "", error: error)
            failure?(self)
        }
    }
    
    private func buildFullURL() -> String {
        let baseURL = customBaseURL() ?? KKNetworkConfig.shared.baseURL
        let path = requestPath()
        return baseURL + path
    }
    
    private func buildHeaders() -> HTTPHeaders {
        var headers = HTTPHeaders()
        
        if useCommonHeaders() {
            for header in KKNetworkConfig.shared.commonHeaders {
                headers.add(header)
            }
        }
        
        if let customHeaders = requestHeaders() {
            for header in customHeaders {
                headers.add(header)
            }
        }
        
        return headers
    }
}
