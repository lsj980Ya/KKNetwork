//
//  KKNetworkAnalytics.swift
//  KKNetwork
//
//  网络请求分析统计
//

import Foundation

/// 请求统计数据
public struct KKRequestStatistics {
    public let url: String
    public let method: String
    public let duration: TimeInterval
    public let statusCode: Int?
    public let success: Bool
    public let timestamp: Date
    public let requestSize: Int
    public let responseSize: Int
}

/// 网络分析器
public class KKNetworkAnalytics {
    
    // MARK: - Singleton
    
    public static let shared = KKNetworkAnalytics()
    
    private init() {}
    
    // MARK: - Properties
    
    /// 是否启用统计
    public var isEnabled: Bool = false
    
    /// 统计数据
    private var statistics: [KKRequestStatistics] = []
    
    /// 最大保存数量
    public var maxStatisticsCount: Int = 100
    
    /// 统计回调
    public var statisticsHandler: ((KKRequestStatistics) -> Void)?
    
    // MARK: - Public Methods
    
    /// 记录请求统计
    public func record(url: String,
                      method: String,
                      duration: TimeInterval,
                      statusCode: Int?,
                      success: Bool,
                      requestSize: Int = 0,
                      responseSize: Int = 0) {
        guard isEnabled else { return }
        
        let stat = KKRequestStatistics(
            url: url,
            method: method,
            duration: duration,
            statusCode: statusCode,
            success: success,
            timestamp: Date(),
            requestSize: requestSize,
            responseSize: responseSize
        )
        
        statistics.append(stat)
        
        // 限制数量
        if statistics.count > maxStatisticsCount {
            statistics.removeFirst()
        }
        
        statisticsHandler?(stat)
    }
    
    /// 获取统计报告
    public func getReport() -> KKAnalyticsReport {
        return KKAnalyticsReport(statistics: statistics)
    }
    
    /// 清空统计
    public func clear() {
        statistics.removeAll()
    }
}

/// 统计报告
public struct KKAnalyticsReport {
    public let totalRequests: Int
    public let successRequests: Int
    public let failedRequests: Int
    public let averageDuration: TimeInterval
    public let totalDataTransferred: Int
    
    init(statistics: [KKRequestStatistics]) {
        self.totalRequests = statistics.count
        self.successRequests = statistics.filter { $0.success }.count
        self.failedRequests = statistics.filter { !$0.success }.count
        self.averageDuration = statistics.isEmpty ? 0 : statistics.map { $0.duration }.reduce(0, +) / Double(statistics.count)
        self.totalDataTransferred = statistics.map { $0.requestSize + $0.responseSize }.reduce(0, +)
    }
    
    public func printReport() {
        print("""
        
        ╔═══════════════════════════════════════════════════════════════════════
        ║ 📊 网络请求统计报告
        ╠═══════════════════════════════════════════════════════════════════════
        ║ 总请求数: \(totalRequests)
        ║ 成功: \(successRequests)
        ║ 失败: \(failedRequests)
        ║ 成功率: \(String(format: "%.2f", Double(successRequests) / Double(totalRequests) * 100))%
        ║ 平均耗时: \(String(format: "%.2f", averageDuration))s
        ║ 总流量: \(formatBytes(totalDataTransferred))
        ╚═══════════════════════════════════════════════════════════════════════
        
        """)
    }
    
    private func formatBytes(_ bytes: Int) -> String {
        let kb = Double(bytes) / 1024
        if kb < 1024 {
            return String(format: "%.2f KB", kb)
        }
        let mb = kb / 1024
        return String(format: "%.2f MB", mb)
    }
}
