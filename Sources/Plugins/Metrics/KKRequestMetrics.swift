//
//  KKRequestMetrics.swift
//  KKNetwork
//
//  请求性能指标收集
//

import Foundation

/// 请求性能指标
public struct KKRequestMetrics {
    public let url: String
    public let method: String
    
    // 时间指标
    public let startTime: Date
    public let endTime: Date
    public let duration: TimeInterval
    
    // DNS 解析时间
    public let dnsLookupDuration: TimeInterval?
    
    // TCP 连接时间
    public let connectDuration: TimeInterval?
    
    // SSL 握手时间
    public let secureConnectionDuration: TimeInterval?
    
    // 请求发送时间
    public let requestDuration: TimeInterval?
    
    // 响应接收时间
    public let responseDuration: TimeInterval?
    
    // 数据大小
    public let requestSize: Int
    public let responseSize: Int
    
    // 状态
    public let statusCode: Int?
    public let success: Bool
    public let error: Error?
}

/// 性能指标收集器
public class KKMetricsCollector {
    
    // MARK: - Singleton
    
    public static let shared = KKMetricsCollector()
    
    private init() {}
    
    // MARK: - Properties
    
    /// 是否启用
    public var isEnabled: Bool = false
    
    /// 指标回调
    public var metricsHandler: ((KKRequestMetrics) -> Void)?
    
    /// 指标存储
    private var metricsStore: [KKRequestMetrics] = []
    
    /// 最大存储数量
    public var maxMetricsCount: Int = 100
    
    // MARK: - Public Methods
    
    /// 记录指标
    public func record(_ metrics: KKRequestMetrics) {
        guard isEnabled else { return }
        
        metricsStore.append(metrics)
        
        if metricsStore.count > maxMetricsCount {
            metricsStore.removeFirst()
        }
        
        metricsHandler?(metrics)
        
        // 打印性能报告
        if KKNetworkConfig.shared.logLevel == .verbose {
            printMetrics(metrics)
        }
    }
    
    /// 获取所有指标
    public func getAllMetrics() -> [KKRequestMetrics] {
        return metricsStore
    }
    
    /// 清空指标
    public func clear() {
        metricsStore.removeAll()
    }
    
    // MARK: - Private Methods
    
    private func printMetrics(_ metrics: KKRequestMetrics) {
        var report = """
        
        ╔═══════════════════════════════════════════════════════════════════════
        ║ ⏱ 性能指标
        ╠═══════════════════════════════════════════════════════════════════════
        ║ URL: \(metrics.url)
        ║ 总耗时: \(String(format: "%.2f", metrics.duration * 1000))ms
        """
        
        if let dns = metrics.dnsLookupDuration {
            report += "\n║ DNS 解析: \(String(format: "%.2f", dns * 1000))ms"
        }
        
        if let connect = metrics.connectDuration {
            report += "\n║ TCP 连接: \(String(format: "%.2f", connect * 1000))ms"
        }
        
        if let ssl = metrics.secureConnectionDuration {
            report += "\n║ SSL 握手: \(String(format: "%.2f", ssl * 1000))ms"
        }
        
        report += """
        
        ║ 请求大小: \(formatBytes(metrics.requestSize))
        ║ 响应大小: \(formatBytes(metrics.responseSize))
        ║ 状态: \(metrics.success ? "✅ 成功" : "❌ 失败")
        ╚═══════════════════════════════════════════════════════════════════════
        
        """
        
        print(report)
    }
    
    private func formatBytes(_ bytes: Int) -> String {
        if bytes < 1024 {
            return "\(bytes) B"
        }
        let kb = Double(bytes) / 1024
        if kb < 1024 {
            return String(format: "%.2f KB", kb)
        }
        let mb = kb / 1024
        return String(format: "%.2f MB", mb)
    }
}
