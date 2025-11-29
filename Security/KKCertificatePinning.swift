//
//  KKCertificatePinning.swift
//  KKNetwork
//
//  SSL Pinning（证书锁定）
//

import Foundation
import Alamofire

/// SSL Pinning 配置
public class KKCertificatePinning {
    
    // MARK: - Properties
    
    /// 证书列表
    private var certificates: [SecCertificate] = []
    
    /// 是否启用
    public var isEnabled: Bool = false
    
    // MARK: - Singleton
    
    public static let shared = KKCertificatePinning()
    
    private init() {}
    
    // MARK: - Public Methods
    
    /// 添加证书（从 Bundle 加载）
    public func addCertificate(filename: String, bundle: Bundle = .main) {
        guard let path = bundle.path(forResource: filename, ofType: "cer"),
              let data = try? Data(contentsOf: URL(fileURLWithPath: path)),
              let certificate = SecCertificateCreateWithData(nil, data as CFData) else {
            KKNetworkLogger.log("⚠️ 加载证书失败: \(filename)", level: .error)
            return
        }
        
        certificates.append(certificate)
        KKNetworkLogger.log("🔒 添加证书: \(filename)", level: .info)
    }
    
    /// 创建 ServerTrustManager
    public func createServerTrustManager(for hosts: [String]) -> ServerTrustManager? {
        guard isEnabled, !certificates.isEmpty else {
            return nil
        }
        
        let evaluators = hosts.reduce(into: [String: ServerTrustEvaluating]()) { result, host in
            result[host] = PinnedCertificatesTrustEvaluator(certificates: certificates)
        }
        
        return ServerTrustManager(evaluators: evaluators)
    }
}
