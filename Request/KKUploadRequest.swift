//
//  KKUploadRequest.swift
//  KKNetwork
//
//  文件上传请求
//

import Foundation
import Alamofire

/// 上传数据类型
public enum KKUploadData {
    case file(URL)
    case data(Data, fileName: String, mimeType: String)
}

/// 文件上传请求
open class KKUploadRequest: KKBaseRequest {
    
    // MARK: - Properties
    
    private var uploadRequest: UploadRequest?
    
    /// 上传进度回调
    public var progressBlock: ((Progress) -> Void)?
    
    // MARK: - Upload Configuration
    
    /// 上传数据
    open func uploadData() -> [String: KKUploadData] {
        return [:]
    }
    
    /// 表单字段
    open func formFields() -> [String: String]? {
        return nil
    }
    
    // MARK: - Override
    
    @discardableResult
    public override func start(success: ((KKBaseRequest) -> Void)? = nil,
                              failure: ((KKBaseRequest) -> Void)? = nil) -> Self {
        
        KKNetworkLogger.log("📤 开始上传: \(requestPath())", level: .info)
        
        // 执行拦截器
        for interceptor in KKNetworkConfig.shared.interceptors {
            interceptor.willSend(self)
        }
        
        let url = buildFullURL()
        let headers = buildHeaders()
        
        uploadRequest = AF.upload(multipartFormData: { [weak self] multipartFormData in
            guard let self = self else { return }
            
            // 添加表单字段
            if let fields = self.formFields() {
                for (key, value) in fields {
                    if let data = value.data(using: .utf8) {
                        multipartFormData.append(data, withName: key)
                    }
                }
            }
            
            // 添加文件
            for (name, uploadData) in self.uploadData() {
                switch uploadData {
                case .file(let fileURL):
                    multipartFormData.append(fileURL, withName: name)
                case .data(let data, let fileName, let mimeType):
                    multipartFormData.append(data, withName: name, fileName: fileName, mimeType: mimeType)
                }
            }
        }, to: url, headers: headers)
        
        // 监听上传进度
        uploadRequest?.uploadProgress { [weak self] progress in
            self?.progressBlock?(progress)
        }
        
        // 处理响应
        uploadRequest?.responseData { [weak self] response in
            guard let self = self else { return }
            self.handleUploadResponse(response, success: success, failure: failure)
        }
        
        return self
    }
    
    public override func cancel() {
        uploadRequest?.cancel()
        KKNetworkLogger.log("❌ 取消上传: \(requestPath())", level: .info)
    }
    
    // MARK: - Private Methods
    
    private func handleUploadResponse(_ response: AFDataResponse<Data>,
                                     success: ((KKBaseRequest) -> Void)?,
                                     failure: ((KKBaseRequest) -> Void)?) {
        self.responseData = response.data
        
        switch response.result {
        case .success(let data):
            let json = JSON(data)
            self.responseJSON = json
            self.responseString = String(data: data, encoding: .utf8)
            
            KKNetworkLogger.logResponse(url: response.request?.url?.absoluteString ?? "",
                                       statusCode: response.response?.statusCode,
                                       json: json)
            
            if validateResponse(json) {
                KKNetworkLogger.log("✅ 上传成功: \(requestPath())", level: .info)
                success?(self)
            } else {
                let errorMsg = errorMessageFromResponse(json) ?? "上传失败"
                let error = NSError(domain: "KKNetwork", code: -1001, userInfo: [NSLocalizedDescriptionKey: errorMsg])
                self.error = error
                failure?(self)
            }
            
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

import SwiftyJSON
