//
//  KKMockManager.swift
//  KKNetwork
//
//  Mock 数据管理（用于测试和开发）
//

import Foundation
import SwiftyJSON

/// Mock 数据配置
public struct KKMockData {
    let json: JSON
    let statusCode: Int
    let delay: TimeInterval
    
    public init(json: JSON, statusCode: Int = 200, delay: TimeInterval = 0.5) {
        self.json = json
        self.statusCode = statusCode
        self.delay = delay
    }
}

/// Mock 管理器
public class KKMockManager {
    
    // MARK: - Singleton
    
    public static let shared = KKMockManager()
    
    private init() {}
    
    // MARK: - Properties
    
    /// 是否启用 Mock
    public var isEnabled: Bool = false
    
    /// Mock 数据映射 [URL: MockData]
    private var mockDataMap: [String: KKMockData] = [:]
    
    // MARK: - Public Methods
    
    /// 注册 Mock 数据
    public func register(url: String, mockData: KKMockData) {
        mockDataMap[url] = mockData
        KKNetworkLogger.log("🎭 注册 Mock 数据: \(url)", level: .info)
    }
    
    /// 注册 Mock 数据（从 JSON 文件）
    public func register(url: String, jsonFile: String, bundle: Bundle = .main, statusCode: Int = 200, delay: TimeInterval = 0.5) {
        guard let path = bundle.path(forResource: jsonFile, ofType: "json"),
              let data = try? Data(contentsOf: URL(fileURLWithPath: path)) else {
            KKNetworkLogger.log("⚠️ 加载 Mock 文件失败: \(jsonFile)", level: .error)
            return
        }
        
        let json = JSON(data)
        let mockData = KKMockData(json: json, statusCode: statusCode, delay: delay)
        register(url: url, mockData: mockData)
    }
    
    /// 获取 Mock 数据
    public func mockData(for url: String) -> KKMockData? {
        return mockDataMap[url]
    }
    
    /// 移除 Mock 数据
    public func removeMock(for url: String) {
        mockDataMap.removeValue(forKey: url)
    }
    
    /// 清空所有 Mock 数据
    public func removeAllMocks() {
        mockDataMap.removeAll()
    }
}

// MARK: - Mock Request

/// 支持 Mock 的请求基类
open class KKMockableRequest: KKBaseRequest {
    
    /// 是否使用 Mock 数据
    open func useMock() -> Bool {
        return KKMockManager.shared.isEnabled
    }
    
    /// Mock 数据的 URL key
    open func mockURLKey() -> String {
        return requestPath()
    }
    
    @discardableResult
    public override func start(success: ((KKBaseRequest) -> Void)? = nil,
                              failure: ((KKBaseRequest) -> Void)? = nil) -> Self {
        
        if useMock(), let mockData = KKMockManager.shared.mockData(for: mockURLKey()) {
            KKNetworkLogger.log("🎭 使用 Mock 数据: \(mockURLKey())", level: .info)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + mockData.delay) { [weak self] in
                guard let self = self else { return }
                
                self.responseJSON = mockData.json
                
                if self.validateResponse(mockData.json) {
                    success?(self)
                } else {
                    let error = NSError(domain: "KKNetwork", code: mockData.statusCode, userInfo: nil)
                    self.error = error
                    failure?(self)
                }
            }
            
            return self
        }
        
        return super.start(success: success, failure: failure)
    }
}
