//
//  KKReachability.swift
//  KKNetwork
//
//  网络状态监听
//

import Foundation
import SystemConfiguration

/// 网络状态
public enum KKNetworkStatus {
    case unknown
    case notReachable
    case reachableViaWiFi
    case reachableViaCellular
}

/// 网络状态监听器
public class KKReachability {
    
    // MARK: - Singleton
    
    public static let shared = KKReachability()
    
    private init() {
        startMonitoring()
    }
    
    // MARK: - Properties
    
    private var reachability: SCNetworkReachability?
    
    /// 当前网络状态
    public private(set) var currentStatus: KKNetworkStatus = .unknown
    
    /// 网络状态变化回调
    public var statusChangeHandler: ((KKNetworkStatus) -> Void)?
    
    // MARK: - Public Methods
    
    /// 是否有网络连接
    public var isReachable: Bool {
        return currentStatus != .notReachable && currentStatus != .unknown
    }
    
    /// 是否是 WiFi
    public var isReachableViaWiFi: Bool {
        return currentStatus == .reachableViaWiFi
    }
    
    /// 是否是蜂窝网络
    public var isReachableViaCellular: Bool {
        return currentStatus == .reachableViaCellular
    }
    
    // MARK: - Private Methods
    
    private func startMonitoring() {
        var zeroAddress = sockaddr_in()
        zeroAddress.sin_len = UInt8(MemoryLayout<sockaddr_in>.size)
        zeroAddress.sin_family = sa_family_t(AF_INET)
        
        guard let reachability = withUnsafePointer(to: &zeroAddress, {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                SCNetworkReachabilityCreateWithAddress(nil, $0)
            }
        }) else {
            return
        }
        
        self.reachability = reachability
        
        var context = SCNetworkReachabilityContext(
            version: 0,
            info: Unmanaged.passUnretained(self).toOpaque(),
            retain: nil,
            release: nil,
            copyDescription: nil
        )
        
        let callback: SCNetworkReachabilityCallBack = { (_, flags, info) in
            guard let info = info else { return }
            let reachability = Unmanaged<KKReachability>.fromOpaque(info).takeUnretainedValue()
            reachability.updateStatus(flags: flags)
        }
        
        SCNetworkReachabilitySetCallback(reachability, callback, &context)
        SCNetworkReachabilityScheduleWithRunLoop(reachability, CFRunLoopGetMain(), CFRunLoopMode.commonModes.rawValue)
        
        // 初始状态
        var flags = SCNetworkReachabilityFlags()
        if SCNetworkReachabilityGetFlags(reachability, &flags) {
            updateStatus(flags: flags)
        }
    }
    
    private func updateStatus(flags: SCNetworkReachabilityFlags) {
        let newStatus = networkStatus(from: flags)
        
        if newStatus != currentStatus {
            currentStatus = newStatus
            KKNetworkLogger.log("📶 网络状态变化: \(statusDescription(newStatus))", level: .info)
            statusChangeHandler?(newStatus)
        }
    }
    
    private func networkStatus(from flags: SCNetworkReachabilityFlags) -> KKNetworkStatus {
        guard flags.contains(.reachable) else {
            return .notReachable
        }
        
        if flags.contains(.isWWAN) {
            return .reachableViaCellular
        }
        
        return .reachableViaWiFi
    }
    
    private func statusDescription(_ status: KKNetworkStatus) -> String {
        switch status {
        case .unknown: return "未知"
        case .notReachable: return "无网络"
        case .reachableViaWiFi: return "WiFi"
        case .reachableViaCellular: return "蜂窝网络"
        }
    }
}
