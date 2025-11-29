//
//  KKBaseRequest.swift
//  KKNetwork
//
//  基础请求类（参考 YTKNetwork 设计）
//

import Foundation
import Alamofire
import SwiftyJSON

/// 请求基类
open class KKBaseRequest: NSObject {
    
    // MARK: - Properties
    
    /// 请求任务
    private var dataRequest: DataRequest?
    
    /// 当前使用的域名索引（用于域名切换）
    /// 0 = 主域名 baseURL, 1 = backupBaseURLs[0], 2 = backupBaseURLs[1], ...
    private var currentBaseURLIndex: Int = 0
    
    /// 当前重试次数
    private var currentRetryCount: Int = 0
    
    /// 响应数据
    public internal(set) var responseData: Data?
    
    /// 响应 JSON
    public internal(set) var responseJSON: JSON?
    
    /// 响应字符串
    public internal(set) var responseString: String?
    
    /// 错误信息
    public internal(set) var error: Error?
    
    /// 成功回调
    private var successBlock: ((KKBaseRequest) -> Void)?
    
    /// 失败回调
    private var failureBlock: ((KKBaseRequest) -> Void)?
    
    /// 请求标识
    public var tag: Int = 0
    
    /// 用户信息
    public var userInfo: [String: Any]?
    
    // MARK: - 子类需要重写的方法
    
    /// 请求路径
    open func requestPath() -> String {
        return ""
    }
    
    /// 请求方法
    open func requestMethod() -> HTTPMethod {
        return .get
    }
    
    /// 请求参数
    open func requestParameters() -> [String: Any]? {
        return nil
    }
    
    /// 请求头
    open func requestHeaders() -> HTTPHeaders? {
        return nil
    }
    
    /// 参数编码方式
    open func parameterEncoding() -> ParameterEncoding {
        switch requestMethod() {
        case .get:
            return URLEncoding.default
        default:
            return JSONEncoding.default
        }
    }
    
    /// 是否使用公共参数
    open func useCommonParameters() -> Bool {
        return true
    }
    
    /// 是否使用公共请求头
    open func useCommonHeaders() -> Bool {
        return true
    }
    
    /// 自定义超时时间
    open func requestTimeoutInterval() -> TimeInterval? {
        return nil
    }
    
    /// 最大重试次数
    open func maxRetryCount() -> Int {
        return 0
    }
    
    /// 是否启用域名切换重试
    open func enableBackupURLRetry() -> Bool {
        return true
    }
    
    /// 自定义 BaseURL（如果返回 nil 则使用配置的 baseURL）
    open func customBaseURL() -> String? {
        return nil
    }
    
    // MARK: - 响应验证
    
    /// 验证响应数据是否有效
    open func validateResponse(_ json: JSON) -> Bool {
        return true
    }
    
    /// 从响应中提取错误信息
    open func errorMessageFromResponse(_ json: JSON) -> String? {
        return json["message"].string ?? json["msg"].string
    }
    
    // MARK: - 请求控制
    
    /// 发起请求
    @discardableResult
    public func start(success: ((KKBaseRequest) -> Void)? = nil,
                     failure: ((KKBaseRequest) -> Void)? = nil) -> Self {
        self.successBlock = success
        self.failureBlock = failure
        
        KKNetworkLogger.log("🚀 开始请求: \(requestPath())", level: .info)
        
        // 执行拦截器的 willSend
        for interceptor in KKNetworkConfig.shared.interceptors {
            interceptor.willSend(self)
        }
        
        startRequest()
        return self
    }
    
    /// 取消请求
    public func cancel() {
        dataRequest?.cancel()
        KKNetworkLogger.log("❌ 取消请求: \(requestPath())", level: .info)
    }
    
    // MARK: - Private Methods
    
    private func startRequest() {
        let url = buildURL()
        let method = requestMethod()
        let parameters = buildParameters()
        let headers = buildHeaders()
        let encoding = parameterEncoding()
        let timeout = requestTimeoutInterval() ?? KKNetworkConfig.shared.timeoutInterval
        
        KKNetworkLogger.logRequest(url: url, method: method, parameters: parameters, headers: headers)
        
        // 创建 Session
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = timeout
        let session = Session(configuration: configuration)
        
        // 发起请求
        dataRequest = session.request(url,
                                      method: method,
                                      parameters: parameters,
                                      encoding: encoding,
                                      headers: headers)
        
        dataRequest?.responseData { [weak self] response in
            guard let self = self else { return }
            self.handleResponse(response)
        }
    }
    
    private func handleResponse(_ response: AFDataResponse<Data>) {
        self.responseData = response.data
        
        switch response.result {
        case .success(let data):
            // 解析 JSON
            let json = JSON(data)
            self.responseJSON = json
            self.responseString = String(data: data, encoding: .utf8)
            
            KKNetworkLogger.logResponse(url: response.request?.url?.absoluteString ?? "",
                                       statusCode: response.response?.statusCode,
                                       json: json)
            
            // 验证响应
            if validateResponse(json) {
                handleSuccess()
            } else {
                let errorMsg = errorMessageFromResponse(json) ?? "响应验证失败"
                let error = NSError(domain: "KKNetwork", code: -1001, userInfo: [NSLocalizedDescriptionKey: errorMsg])
                self.error = error
                handleFailure()
            }
            
        case .failure(let error):
            self.error = error
            
            KKNetworkLogger.logError(url: response.request?.url?.absoluteString ?? "",
                                    error: error)
            
            // 判断是否需要重试
            if shouldRetry() {
                retry()
            } else {
                handleFailure()
            }
        }
    }
    
    private func shouldRetry() -> Bool {
        // 检查是否达到最大重试次数
        if currentRetryCount < maxRetryCount() {
            return true
        }
        
        // 检查是否可以切换域名重试
        // currentBaseURLIndex: 0 = baseURL, 1 = backupURLs[0], 2 = backupURLs[1], ...
        if enableBackupURLRetry() {
            let backupCount = KKNetworkConfig.shared.backupBaseURLs.count
            if currentBaseURLIndex < backupCount {
                return true
            }
        }
        
        return false
    }
    
    private func retry() {
        // 先尝试普通重试
        if currentRetryCount < maxRetryCount() {
            currentRetryCount += 1
            KKNetworkLogger.log("🔄 重试请求 (\(currentRetryCount)/\(maxRetryCount())): \(requestPath())", level: .info)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                self?.startRequest()
            }
        }
        // 再尝试切换域名
        else if enableBackupURLRetry() {
            let backupCount = KKNetworkConfig.shared.backupBaseURLs.count
            if currentBaseURLIndex < backupCount {
                currentBaseURLIndex += 1
                currentRetryCount = 0
                KKNetworkLogger.log("🔄 切换域名重试 (域名索引: \(currentBaseURLIndex)): \(requestPath())", level: .info)
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                    self?.startRequest()
                }
            }
        }
    }
    
    private func handleSuccess() {
        // 执行拦截器的 didReceive
        for interceptor in KKNetworkConfig.shared.interceptors {
            interceptor.didReceive(self, error: nil)
        }
        
        KKNetworkLogger.log("✅ 请求成功: \(requestPath())", level: .info)
        successBlock?(self)
    }
    
    private func handleFailure() {
        // 执行拦截器的 didReceive
        for interceptor in KKNetworkConfig.shared.interceptors {
            interceptor.didReceive(self, error: error)
        }
        
        KKNetworkLogger.log("❌ 请求失败: \(requestPath())", level: .error)
        failureBlock?(self)
    }
    
    // MARK: - URL & Parameters Building
    
    private func buildURL() -> String {
        let baseURL: String
        
        if let customURL = customBaseURL() {
            baseURL = customURL
        } else if currentBaseURLIndex <= 0 {
            // 0 或初始值 -1 都使用主域名
            baseURL = KKNetworkConfig.shared.baseURL
        } else {
            // 1, 2, 3... 使用备用域名
            let backupIndex = currentBaseURLIndex - 1
            if backupIndex < KKNetworkConfig.shared.backupBaseURLs.count {
                baseURL = KKNetworkConfig.shared.backupBaseURLs[backupIndex]
            } else {
                baseURL = KKNetworkConfig.shared.baseURL
            }
        }
        
        let path = requestPath()
        
        if path.hasPrefix("http://") || path.hasPrefix("https://") {
            return path
        }
        
        return baseURL + path
    }
    
    private func buildParameters() -> [String: Any]? {
        var params = requestParameters() ?? [:]
        
        if useCommonParameters() {
            for (key, value) in KKNetworkConfig.shared.commonParameters {
                if params[key] == nil {
                    params[key] = value
                }
            }
        }
        
        return params.isEmpty ? nil : params
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
