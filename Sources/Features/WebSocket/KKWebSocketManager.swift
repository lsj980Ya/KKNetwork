//
//  KKWebSocketManager.swift
//  KKNetwork
//
//  WebSocket 支持（增强版）
//

import Foundation

/// WebSocket 消息
public struct KKWebSocketMessage {
    public let data: Data?
    public let string: String?
    public let timestamp: Date
    
    init(data: Data? = nil, string: String? = nil) {
        self.data = data
        self.string = string
        self.timestamp = Date()
    }
}

/// WebSocket 连接状态
public enum KKWebSocketState {
    case disconnected
    case connecting
    case connected
    case reconnecting
}

/// WebSocket 管理器
public class KKWebSocketManager: NSObject {
    
    // MARK: - Singleton
    
    public static let shared = KKWebSocketManager()
    
    private override init() {
        super.init()
    }
    
    // MARK: - Properties
    
    private var webSocketTask: URLSessionWebSocketTask?
    private var session: URLSession?
    private var currentURL: String?
    private var currentHeaders: [String: String]?
    
    /// 连接状态
    public private(set) var state: KKWebSocketState = .disconnected
    
    /// 是否已连接
    public var isConnected: Bool {
        return state == .connected
    }
    
    /// 是否启用自动重连
    public var autoReconnect: Bool = true
    
    /// 重连间隔（秒）
    public var reconnectInterval: TimeInterval = 3.0
    
    /// 最大重连次数（0 表示无限制）
    public var maxReconnectAttempts: Int = 0
    
    /// 当前重连次数
    private var reconnectAttempts: Int = 0
    
    /// 心跳间隔（秒，0 表示不发送心跳）
    public var heartbeatInterval: TimeInterval = 30.0
    
    /// 心跳消息
    public var heartbeatMessage: String = "ping"
    
    /// 心跳定时器
    private var heartbeatTimer: Timer?
    
    /// 消息队列（连接断开时缓存）
    private var messageQueue: [URLSessionWebSocketTask.Message] = []
    
    /// 是否启用消息队列
    public var enableMessageQueue: Bool = true
    
    /// 最大队列长度
    public var maxQueueLength: Int = 100
    
    // MARK: - Callbacks
    
    /// 消息回调
    public var messageHandler: ((KKWebSocketMessage) -> Void)?
    
    /// 连接状态回调
    public var stateChangeHandler: ((KKWebSocketState) -> Void)?
    
    /// 错误回调
    public var errorHandler: ((Error) -> Void)?
    
    /// 心跳回调
    public var heartbeatHandler: (() -> String?)?
    
    // MARK: - Public Methods
    
    /// 连接 WebSocket
    public func connect(url: String, headers: [String: String]? = nil) {
        guard let wsURL = URL(string: url) else {
            KKNetworkLogger.log("⚠️ WebSocket URL 无效", level: .error)
            return
        }
        
        var request = URLRequest(url: wsURL)
        headers?.forEach { request.setValue($1, forHTTPHeaderField: $0) }
        
        let configuration = URLSessionConfiguration.default
        session = URLSession(configuration: configuration, delegate: self, delegateQueue: nil)
        
        webSocketTask = session?.webSocketTask(with: request)
        webSocketTask?.resume()
        
        receiveMessage()
        
        KKNetworkLogger.log("🔌 WebSocket 连接中: \(url)", level: .info)
    }
    
    /// 发送消息
    public func send(string: String) {
        let message = URLSessionWebSocketTask.Message.string(string)
        webSocketTask?.send(message) { [weak self] error in
            if let error = error {
                KKNetworkLogger.log("⚠️ WebSocket 发送失败: \(error)", level: .error)
                self?.errorHandler?(error)
            }
        }
    }
    
    /// 发送数据
    public func send(data: Data) {
        let message = URLSessionWebSocketTask.Message.data(data)
        webSocketTask?.send(message) { [weak self] error in
            if let error = error {
                KKNetworkLogger.log("⚠️ WebSocket 发送失败: \(error)", level: .error)
                self?.errorHandler?(error)
            }
        }
    }
    
    /// 断开连接
    public func disconnect() {
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        isConnected = false
        KKNetworkLogger.log("🔌 WebSocket 已断开", level: .info)
    }
    
    // MARK: - Private Methods
    
    private func receiveMessage() {
        webSocketTask?.receive { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let message):
                switch message {
                case .string(let text):
                    let wsMessage = KKWebSocketMessage(data: nil, string: text)
                    self.messageHandler?(wsMessage)
                    
                case .data(let data):
                    let wsMessage = KKWebSocketMessage(data: data, string: nil)
                    self.messageHandler?(wsMessage)
                    
                @unknown default:
                    break
                }
                
                // 继续接收
                self.receiveMessage()
                
            case .failure(let error):
                KKNetworkLogger.log("⚠️ WebSocket 接收失败: \(error)", level: .error)
                self.errorHandler?(error)
            }
        }
    }
}

// MARK: - URLSessionWebSocketDelegate

extension KKWebSocketManager: URLSessionWebSocketDelegate {
    
    public func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
        isConnected = true
        KKNetworkLogger.log("✅ WebSocket 已连接", level: .info)
        connectionHandler?(true)
    }
    
    public func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        isConnected = false
        KKNetworkLogger.log("🔌 WebSocket 已关闭", level: .info)
        connectionHandler?(false)
    }
}
