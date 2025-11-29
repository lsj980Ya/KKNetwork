//
//  KKWebSocketClient.swift
//  KKNetwork
//
//  增强版 WebSocket 客户端（支持心跳、自动重连、消息队列）
//

import Foundation
import SwiftyJSON

/// WebSocket 连接状态
public enum KKWebSocketState {
    case disconnected
    case connecting
    case connected
    case reconnecting
}

/// WebSocket 客户端配置
public struct KKWebSocketConfig {
    public var enableHeartbeat: Bool = true
    public var heartbeatInterval: TimeInterval = 30
    public var enableAutoReconnect: Bool = true
    public var maxReconnectAttempts: Int = 5
    public var reconnectDelay: TimeInterval = 2
    public var messageQueueSize: Int = 100
    
    public init() {}
}

/// 增强版 WebSocket 客户端
public class KKWebSocketClient: NSObject {
    
    // MARK: - Properties
    
    private var webSocketTask: URLSessionWebSocketTask?
    private var session: URLSession?
    private let url: String
    private var headers: [String: String]
    
    /// 配置
    public var config = KKWebSocketConfig()
    
    /// 当前状态
    public private(set) var state: KKWebSocketState = .disconnected
    
    /// 重连次数
    private var reconnectAttempts: Int = 0
    
    /// 心跳定时器
    private var heartbeatTimer: Timer?
    
    /// 消息队列（连接断开时缓存消息）
    private var messageQueue: [URLSessionWebSocketTask.Message] = []
    
    // MARK: - Callbacks
    
    public var onConnected: (() -> Void)?
    public var onDisconnected: ((Error?) -> Void)?
    public var onMessage: ((KKWebSocketMessage) -> Void)?
    public var onError: ((Error) -> Void)?
    public var onStateChanged: ((KKWebSocketState) -> Void)?
    
    // MARK: - Initialization
    
    public init(url: String, headers: [String: String] = [:]) {
        self.url = url
        self.headers = headers
        super.init()
    }
    
    // MARK: - Public Methods
    
    /// 连接
    public func connect() {
        guard state == .disconnected else {
            KKNetworkLogger.log("⚠️ WebSocket 已连接或正在连接", level: .info)
            return
        }
        
        updateState(.connecting)
        performConnect()
    }
    
    /// 断开连接
    public func disconnect() {
        stopHeartbeat()
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        updateState(.disconnected)
        reconnectAttempts = 0
        messageQueue.removeAll()
    }
    
    /// 发送文本消息
    public func send(text: String) {
        let message = URLSessionWebSocketTask.Message.string(text)
        sendMessage(message)
    }
    
    /// 发送二进制消息
    public func send(data: Data) {
        let message = URLSessionWebSocketTask.Message.data(data)
        sendMessage(message)
    }
    
    /// 发送 JSON 消息
    public func send(json: JSON) {
        if let jsonString = json.rawString() {
            send(text: jsonString)
        }
    }
    
    /// 发送 Ping
    public func ping() {
        webSocketTask?.sendPing { [weak self] error in
            if let error = error {
                KKNetworkLogger.log("⚠️ WebSocket Ping 失败: \(error)", level: .error)
                self?.handleError(error)
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func performConnect() {
        guard let wsURL = URL(string: url) else {
            let error = NSError(domain: "KKNetwork", code: -1, userInfo: [NSLocalizedDescriptionKey: "WebSocket URL 无效"])
            handleError(error)
            return
        }
        
        var request = URLRequest(url: wsURL)
        headers.forEach { request.setValue($1, forHTTPHeaderField: $0) }
        
        let configuration = URLSessionConfiguration.default
        session = URLSession(configuration: configuration, delegate: self, delegateQueue: nil)
        
        webSocketTask = session?.webSocketTask(with: request)
        webSocketTask?.resume()
        
        receiveMessage()
        
        KKNetworkLogger.log("🔌 WebSocket 连接中: \(url)", level: .info)
    }
    
    private func sendMessage(_ message: URLSessionWebSocketTask.Message) {
        if state == .connected {
            webSocketTask?.send(message) { [weak self] error in
                if let error = error {
                    KKNetworkLogger.log("⚠️ WebSocket 发送失败: \(error)", level: .error)
                    self?.handleError(error)
                }
            }
        } else {
            // 连接断开时，加入队列
            if messageQueue.count < config.messageQueueSize {
                messageQueue.append(message)
                KKNetworkLogger.log("📋 消息已加入队列", level: .info)
            } else {
                KKNetworkLogger.log("⚠️ 消息队列已满", level: .error)
            }
        }
    }
    
    private func receiveMessage() {
        webSocketTask?.receive { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let message):
                switch message {
                case .string(let text):
                    let wsMessage = KKWebSocketMessage(data: nil, string: text)
                    self.onMessage?(wsMessage)
                    
                case .data(let data):
                    let wsMessage = KKWebSocketMessage(data: data, string: nil)
                    self.onMessage?(wsMessage)
                    
                @unknown default:
                    break
                }
                
                // 继续接收
                self.receiveMessage()
                
            case .failure(let error):
                KKNetworkLogger.log("⚠️ WebSocket 接收失败: \(error)", level: .error)
                self.handleError(error)
            }
        }
    }
    
    private func startHeartbeat() {
        guard config.enableHeartbeat else { return }
        
        stopHeartbeat()
        
        heartbeatTimer = Timer.scheduledTimer(withTimeInterval: config.heartbeatInterval, repeats: true) { [weak self] _ in
            self?.ping()
        }
    }
    
    private func stopHeartbeat() {
        heartbeatTimer?.invalidate()
        heartbeatTimer = nil
    }
    
    private func reconnect() {
        guard config.enableAutoReconnect else { return }
        guard reconnectAttempts < config.maxReconnectAttempts else {
            KKNetworkLogger.log("⚠️ WebSocket 重连次数已达上限", level: .error)
            updateState(.disconnected)
            return
        }
        
        reconnectAttempts += 1
        updateState(.reconnecting)
        
        KKNetworkLogger.log("🔄 WebSocket 重连中 (\(reconnectAttempts)/\(config.maxReconnectAttempts))", level: .info)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + config.reconnectDelay) { [weak self] in
            self?.performConnect()
        }
    }
    
    private func sendQueuedMessages() {
        guard !messageQueue.isEmpty else { return }
        
        KKNetworkLogger.log("📤 发送队列中的 \(messageQueue.count) 条消息", level: .info)
        
        for message in messageQueue {
            webSocketTask?.send(message) { error in
                if let error = error {
                    KKNetworkLogger.log("⚠️ 队列消息发送失败: \(error)", level: .error)
                }
            }
        }
        
        messageQueue.removeAll()
    }
    
    private func handleError(_ error: Error) {
        onError?(error)
        
        if state == .connected {
            updateState(.disconnected)
            reconnect()
        }
    }
    
    private func updateState(_ newState: KKWebSocketState) {
        state = newState
        onStateChanged?(newState)
    }
}

// MARK: - URLSessionWebSocketDelegate

extension KKWebSocketClient: URLSessionWebSocketDelegate {
    
    public func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
        updateState(.connected)
        reconnectAttempts = 0
        
        KKNetworkLogger.log("✅ WebSocket 已连接", level: .info)
        
        startHeartbeat()
        sendQueuedMessages()
        
        onConnected?()
    }
    
    public func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        stopHeartbeat()
        
        let reasonString = reason.flatMap { String(data: $0, encoding: .utf8) } ?? "未知原因"
        KKNetworkLogger.log("🔌 WebSocket 已关闭: \(reasonString)", level: .info)
        
        updateState(.disconnected)
        onDisconnected?(nil)
        
        if config.enableAutoReconnect {
            reconnect()
        }
    }
}
