//
//  KKStreamingRequest.swift
//  KKNetwork
//
//  流式请求（SSE - Server-Sent Events）
//

import Foundation
import SwiftyJSON

/// 流式数据回调
public typealias KKStreamDataHandler = (Data) -> Void
public typealias KKStreamEventHandler = (String, JSON) -> Void

/// 流式请求（支持 SSE）
open class KKStreamingRequest: KKBaseRequest {
    
    // MARK: - Properties
    
    private var streamTask: URLSessionDataTask?
    private var buffer = Data()
    
    /// 数据回调
    public var dataHandler: KKStreamDataHandler?
    
    /// 事件回调
    public var eventHandler: KKStreamEventHandler?
    
    /// 是否自动解析 SSE
    open func autoParseSSE() -> Bool {
        return true
    }
    
    // MARK: - Override
    
    @discardableResult
    public override func start(success: ((KKBaseRequest) -> Void)? = nil,
                              failure: ((KKBaseRequest) -> Void)? = nil) -> Self {
        
        let url = buildFullURL()
        let headers = buildHeaders()
        
        var request = URLRequest(url: URL(string: url)!)
        request.httpMethod = requestMethod().rawValue
        headers.forEach { request.setValue($0.value, forHTTPHeaderField: $0.name) }
        
        let session = URLSession(configuration: .default, delegate: self, delegateQueue: nil)
        streamTask = session.dataTask(with: request)
        streamTask?.resume()
        
        KKNetworkLogger.log("🌊 开始流式请求: \(requestPath())", level: .info)
        
        return self
    }
    
    public override func cancel() {
        streamTask?.cancel()
        KKNetworkLogger.log("❌ 取消流式请求: \(requestPath())", level: .info)
    }
    
    // MARK: - Private Methods
    
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
        
        // SSE 需要的 header
        headers.add(name: "Accept", value: "text/event-stream")
        headers.add(name: "Cache-Control", value: "no-cache")
        
        return headers
    }
    
    private func parseSSE(_ data: Data) {
        buffer.append(data)
        
        guard let text = String(data: buffer, encoding: .utf8) else { return }
        
        let lines = text.components(separatedBy: "\n\n")
        
        // 保留最后一个不完整的消息
        if lines.count > 1 {
            buffer = lines.last?.data(using: .utf8) ?? Data()
        }
        
        // 解析完整的消息
        for i in 0..<(lines.count - 1) {
            let message = lines[i]
            parseSSEMessage(message)
        }
    }
    
    private func parseSSEMessage(_ message: String) {
        var eventType = "message"
        var eventData = ""
        
        let lines = message.components(separatedBy: "\n")
        
        for line in lines {
            if line.hasPrefix("event:") {
                eventType = line.replacingOccurrences(of: "event:", with: "").trimmingCharacters(in: .whitespaces)
            } else if line.hasPrefix("data:") {
                eventData = line.replacingOccurrences(of: "data:", with: "").trimmingCharacters(in: .whitespaces)
            }
        }
        
        if !eventData.isEmpty {
            let json = JSON(parseJSON: eventData)
            eventHandler?(eventType, json)
        }
    }
}

// MARK: - URLSessionDataDelegate

extension KKStreamingRequest: URLSessionDataDelegate {
    
    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        dataHandler?(data)
        
        if autoParseSSE() {
            parseSSE(data)
        }
    }
    
    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error {
            self.error = error
            KKNetworkLogger.logError(url: task.originalRequest?.url?.absoluteString ?? "", error: error)
        } else {
            KKNetworkLogger.log("✅ 流式请求完成: \(requestPath())", level: .info)
        }
    }
}

import Alamofire
