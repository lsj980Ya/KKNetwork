//
//  KKLoadBalancer.swift
//  KKNetwork
//
//  负载均衡器（多服务器负载均衡）
//

import Foundation

/// 负载均衡策略
public enum KKLoadBalanceStrategy {
    case roundRobin        // 轮询
    case random            // 随机
    case leastConnections  // 最少连接
    case weightedRandom    // 加权随机
    case ipHash            // IP 哈希
}

/// 服务器节点
public struct KKServerNode {
    public let url: String
    public let weight: Int
    public var activeConnections: Int
    public var isHealthy: Bool
    
    public init(url: String, weight: Int = 1) {
        self.url = url
        self.weight = weight
        self.activeConnections = 0
        self.isHealthy = true
    }
}

/// 负载均衡器
public class KKLoadBalancer {
    
    // MARK: - Singleton
    
    public static let shared = KKLoadBalancer()
    
    private init() {}
    
    // MARK: - Properties
    
    private var servers: [KKServerNode] = []
    private var currentIndex: Int = 0
    private let lock = NSLock()
    
    /// 负载均衡策略
    public var strategy: KKLoadBalanceStrategy = .roundRobin
    
    /// 健康检查间隔
    public var healthCheckInterval: TimeInterval = 30
    
    /// 健康检查定时器
    private var healthCheckTimer: Timer?
    
    // MARK: - Public Methods
    
    /// 添加服务器
    public func addServer(_ server: KKServerNode) {
        lock.lock()
        defer { lock.unlock() }
        
        servers.append(server)
        KKNetworkLogger.log("⚖️ 添加服务器: \(server.url)", level: .info)
    }
    
    /// 移除服务器
    public func removeServer(url: String) {
        lock.lock()
        defer { lock.unlock() }
        
        servers.removeAll { $0.url == url }
    }
    
    /// 获取下一个服务器
    public func nextServer() -> String? {
        lock.lock()
        defer { lock.unlock() }
        
        let healthyServers = servers.filter { $0.isHealthy }
        guard !healthyServers.isEmpty else {
            KKNetworkLogger.log("⚠️ 没有健康的服务器", level: .error)
            return nil
        }
        
        switch strategy {
        case .roundRobin:
            return roundRobinServer(from: healthyServers)
            
        case .random:
            return healthyServers.randomElement()?.url
            
        case .leastConnections:
            return leastConnectionsServer(from: healthyServers)
            
        case .weightedRandom:
            return weightedRandomServer(from: healthyServers)
            
        case .ipHash:
            return ipHashServer(from: healthyServers)
        }
    }
    
    /// 记录连接
    public func recordConnection(for url: String) {
        lock.lock()
        defer { lock.unlock() }
        
        if let index = servers.firstIndex(where: { $0.url == url }) {
            servers[index].activeConnections += 1
        }
    }
    
    /// 释放连接
    public func releaseConnection(for url: String) {
        lock.lock()
        defer { lock.unlock() }
        
        if let index = servers.firstIndex(where: { $0.url == url }) {
            servers[index].activeConnections = max(0, servers[index].activeConnections - 1)
        }
    }
    
    /// 开始健康检查
    public func startHealthCheck() {
        stopHealthCheck()
        
        healthCheckTimer = Timer.scheduledTimer(withTimeInterval: healthCheckInterval, repeats: true) { [weak self] _ in
            self?.performHealthCheck()
        }
    }
    
    /// 停止健康检查
    public func stopHealthCheck() {
        healthCheckTimer?.invalidate()
        healthCheckTimer = nil
    }
    
    // MARK: - Private Methods
    
    private func roundRobinServer(from servers: [KKServerNode]) -> String? {
        guard !servers.isEmpty else { return nil }
        
        let server = servers[currentIndex % servers.count]
        currentIndex += 1
        
        return server.url
    }
    
    private func leastConnectionsServer(from servers: [KKServerNode]) -> String? {
        return servers.min(by: { $0.activeConnections < $1.activeConnections })?.url
    }
    
    private func weightedRandomServer(from servers: [KKServerNode]) -> String? {
        let totalWeight = servers.reduce(0) { $0 + $1.weight }
        var random = Int.random(in: 0..<totalWeight)
        
        for server in servers {
            random -= server.weight
            if random < 0 {
                return server.url
            }
        }
        
        return servers.first?.url
    }
    
    private func ipHashServer(from servers: [KKServerNode]) -> String? {
        // 简化实现，实际应该基于客户端 IP
        let hash = abs("client_ip".hashValue)
        let index = hash % servers.count
        return servers[index].url
    }
    
    private func performHealthCheck() {
        for (index, server) in servers.enumerated() {
            checkServerHealth(server) { [weak self] isHealthy in
                self?.lock.lock()
                self?.servers[index].isHealthy = isHealthy
                self?.lock.unlock()
                
                KKNetworkLogger.log("💓 服务器健康检查: \(server.url) - \(isHealthy ? "健康" : "异常")", level: .info)
            }
        }
    }
    
    private func checkServerHealth(_ server: KKServerNode, completion: @escaping (Bool) -> Void) {
        guard let url = URL(string: server.url + "/health") else {
            completion(false)
            return
        }
        
        let task = URLSession.shared.dataTask(with: url) { _, response, error in
            if let httpResponse = response as? HTTPURLResponse {
                completion(httpResponse.statusCode == 200)
            } else {
                completion(false)
            }
        }
        
        task.resume()
    }
}
