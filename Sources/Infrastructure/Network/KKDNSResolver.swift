//
//  KKDNSResolver.swift
//  KKNetwork
//
//  自定义 DNS 解析（HttpDNS）
//

import Foundation

/// DNS 解析结果
public struct KKDNSResult {
    public let hostname: String
    public let ipAddresses: [String]
    public let ttl: TimeInterval
    public let timestamp: Date
    
    public var isExpired: Bool {
        return Date().timeIntervalSince(timestamp) > ttl
    }
}

/// DNS 解析器
public class KKDNSResolver {
    
    // MARK: - Singleton
    
    public static let shared = KKDNSResolver()
    
    private init() {}
    
    // MARK: - Properties
    
    /// 是否启用 HttpDNS
    public var enableHttpDNS: Bool = false
    
    /// HttpDNS 服务地址
    public var httpDNSServer: String = "https://dns.example.com/resolve"
    
    /// DNS 缓存
    private var dnsCache: [String: KKDNSResult] = [:]
    
    /// 自定义 IP 映射（用于测试环境）
    public var customIPMapping: [String: String] = [:]
    
    // MARK: - Public Methods
    
    /// 解析域名
    public func resolve(hostname: String, completion: @escaping (Result<[String], Error>) -> Void) {
        // 1. 检查自定义映射
        if let customIP = customIPMapping[hostname] {
            completion(.success([customIP]))
            return
        }
        
        // 2. 检查缓存
        if let cached = dnsCache[hostname], !cached.isExpired {
            completion(.success(cached.ipAddresses))
            return
        }
        
        // 3. HttpDNS 解析
        if enableHttpDNS {
            resolveViaHttpDNS(hostname: hostname, completion: completion)
        } else {
            // 4. 系统 DNS 解析
            resolveViaSystemDNS(hostname: hostname, completion: completion)
        }
    }
    
    /// 清除 DNS 缓存
    public func clearCache() {
        dnsCache.removeAll()
    }
    
    // MARK: - Private Methods
    
    private func resolveViaHttpDNS(hostname: String, completion: @escaping (Result<[String], Error>) -> Void) {
        guard let url = URL(string: "\(httpDNSServer)?hostname=\(hostname)") else {
            completion(.failure(NSError(domain: "KKNetwork", code: -1, userInfo: [NSLocalizedDescriptionKey: "无效的 HttpDNS 地址"])))
            return
        }
        
        let task = URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let ips = json["ips"] as? [String] else {
                completion(.failure(NSError(domain: "KKNetwork", code: -1, userInfo: [NSLocalizedDescriptionKey: "HttpDNS 解析失败"])))
                return
            }
            
            let ttl = json["ttl"] as? TimeInterval ?? 300
            let result = KKDNSResult(hostname: hostname, ipAddresses: ips, ttl: ttl, timestamp: Date())
            self?.dnsCache[hostname] = result
            
            completion(.success(ips))
        }
        
        task.resume()
    }
    
    private func resolveViaSystemDNS(hostname: String, completion: @escaping (Result<[String], Error>) -> Void) {
        DispatchQueue.global().async {
            var hints = addrinfo()
            hints.ai_family = AF_UNSPEC
            hints.ai_socktype = SOCK_STREAM
            
            var result: UnsafeMutablePointer<addrinfo>?
            let status = getaddrinfo(hostname, nil, &hints, &result)
            
            guard status == 0, let result = result else {
                completion(.failure(NSError(domain: "KKNetwork", code: -1, userInfo: [NSLocalizedDescriptionKey: "DNS 解析失败"])))
                return
            }
            
            var ips: [String] = []
            var current = result
            
            while true {
                if let addr = current.pointee.ai_addr {
                    var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                    getnameinfo(addr, current.pointee.ai_addrlen, &hostname, socklen_t(hostname.count), nil, 0, NI_NUMERICHOST)
                    ips.append(String(cString: hostname))
                }
                
                if let next = current.pointee.ai_next {
                    current = next
                } else {
                    break
                }
            }
            
            freeaddrinfo(result)
            
            let dnsResult = KKDNSResult(hostname: hostname, ipAddresses: ips, ttl: 300, timestamp: Date())
            self.dnsCache[hostname] = dnsResult
            
            completion(.success(ips))
        }
    }
}
