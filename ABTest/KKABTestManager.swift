//
//  KKABTestManager.swift
//  KKNetwork
//
//  A/B 测试管理
//

import Foundation

/// A/B 测试实验
public struct KKABExperiment {
    public let name: String
    public let variants: [String: Double]  // 变体名称 -> 权重
    public let defaultVariant: String
    
    public init(name: String, variants: [String: Double], defaultVariant: String) {
        self.name = name
        self.variants = variants
        self.defaultVariant = defaultVariant
    }
}

/// A/B 测试管理器
public class KKABTestManager {
    
    // MARK: - Singleton
    
    public static let shared = KKABTestManager()
    
    private init() {
        loadAssignments()
    }
    
    // MARK: - Properties
    
    /// 是否启用 A/B 测试
    public var isEnabled: Bool = false
    
    /// 实验配置
    private var experiments: [String: KKABExperiment] = [:]
    
    /// 用户分配记录
    private var assignments: [String: String] = [:]
    
    /// 用户 ID 提供者
    public var userIdProvider: (() -> String)?
    
    // MARK: - Public Methods
    
    /// 添加实验
    public func addExperiment(_ experiment: KKABExperiment) {
        experiments[experiment.name] = experiment
        KKNetworkLogger.log("🧪 添加 A/B 实验: \(experiment.name)", level: .info)
    }
    
    /// 获取变体
    public func variant(for experimentName: String) -> String {
        guard isEnabled else {
            return experiments[experimentName]?.defaultVariant ?? ""
        }
        
        guard let experiment = experiments[experimentName] else {
            return ""
        }
        
        // 检查是否已分配
        if let assigned = assignments[experimentName] {
            return assigned
        }
        
        // 分配新变体
        let variant = assignVariant(for: experiment)
        assignments[experimentName] = variant
        saveAssignments()
        
        KKNetworkLogger.log("🧪 A/B 测试分配: \(experimentName) -> \(variant)", level: .info)
        
        return variant
    }
    
    /// 强制设置变体（用于测试）
    public func forceVariant(_ variant: String, for experimentName: String) {
        assignments[experimentName] = variant
        saveAssignments()
    }
    
    /// 清除所有分配
    public func clearAssignments() {
        assignments.removeAll()
        saveAssignments()
    }
    
    // MARK: - Private Methods
    
    private func assignVariant(for experiment: KKABExperiment) -> String {
        let totalWeight = experiment.variants.values.reduce(0, +)
        var random = Double.random(in: 0..<totalWeight)
        
        for (variant, weight) in experiment.variants {
            random -= weight
            if random < 0 {
                return variant
            }
        }
        
        return experiment.defaultVariant
    }
    
    private func saveAssignments() {
        UserDefaults.standard.set(assignments, forKey: "KKABTestAssignments")
    }
    
    private func loadAssignments() {
        if let saved = UserDefaults.standard.dictionary(forKey: "KKABTestAssignments") as? [String: String] {
            assignments = saved
        }
    }
}

// MARK: - 支持 A/B 测试的请求

open class KKABTestRequest: KKBaseRequest {
    
    /// A/B 测试实验名称
    open func experimentName() -> String? {
        return nil
    }
    
    /// 根据变体修改请求参数
    open func modifyParameters(for variant: String, parameters: inout [String: Any]) {
        // 子类重写
    }
    
    public override func requestParameters() -> [String: Any]? {
        var params = super.requestParameters() ?? [:]
        
        if let experimentName = experimentName() {
            let variant = KKABTestManager.shared.variant(for: experimentName)
            modifyParameters(for: variant, parameters: &params)
            
            // 添加 A/B 测试标识
            params["ab_experiment"] = experimentName
            params["ab_variant"] = variant
        }
        
        return params
    }
}
