//
//  KKCacheableRequest.swift
//  KKNetwork
//
//  支持缓存的请求
//

import Foundation
import SwiftyJSON

/// 支持缓存的请求基类
open class KKCacheableRequest: KKBaseRequest {
    
    // MARK: - Cache Configuration
    
    /// 缓存策略
    open func cachePolicy() -> KKCachePolicy {
        return .none
    }
    
    /// 缓存有效期（秒），0 表示永久有效
    open func cacheMaxAge() -> TimeInterval {
        return 0
    }
    
    /// 缓存 Key（默认使用 URL + 参数生成）
    open func cacheKey() -> String {
        let url = buildFullURL()
        let params = requestParameters()
        return KKNetworkCache.shared.cacheKey(url: url, parameters: params)
    }
    
    // MARK: - Override
    
    @discardableResult
    public override func start(success: ((KKBaseRequest) -> Void)? = nil,
                              failure: ((KKBaseRequest) -> Void)? = nil) -> Self {
        let policy = cachePolicy()
        
        switch policy {
        case .none:
            return super.start(success: success, failure: failure)
            
        case .cacheOnly:
            return loadFromCache(success: success, failure: failure)
            
        case .networkOnly:
            return super.start(success: { [weak self] request in
                self?.saveToCache()
                success?(request)
            }, failure: failure)
            
        case .cacheElseNetwork:
            if let cachedJSON = KKNetworkCache.shared.cache(forKey: cacheKey()) {
                self.responseJSON = cachedJSON
                KKNetworkLogger.log("📦 使用缓存: \(requestPath())", level: .info)
                success?(self)
                return self
            } else {
                return super.start(success: { [weak self] request in
                    self?.saveToCache()
                    success?(request)
                }, failure: failure)
            }
            
        case .networkElseCache:
            return super.start(success: { [weak self] request in
                self?.saveToCache()
                success?(request)
            }, failure: { [weak self] request in
                guard let self = self else { return }
                if let cachedJSON = KKNetworkCache.shared.cache(forKey: self.cacheKey()) {
                    self.responseJSON = cachedJSON
                    KKNetworkLogger.log("📦 网络失败，使用缓存: \(self.requestPath())", level: .info)
                    success?(self)
                } else {
                    failure?(request)
                }
            })
            
        case .cacheThenNetwork:
            if let cachedJSON = KKNetworkCache.shared.cache(forKey: cacheKey()) {
                self.responseJSON = cachedJSON
                KKNetworkLogger.log("📦 先返回缓存: \(requestPath())", level: .info)
                success?(self)
            }
            return super.start(success: { [weak self] request in
                self?.saveToCache()
                success?(request)
            }, failure: failure)
        }
    }
    
    // MARK: - Private Methods
    
    private func loadFromCache(success: ((KKBaseRequest) -> Void)?,
                              failure: ((KKBaseRequest) -> Void)?) -> Self {
        if let cachedJSON = KKNetworkCache.shared.cache(forKey: cacheKey()) {
            self.responseJSON = cachedJSON
            KKNetworkLogger.log("📦 从缓存加载: \(requestPath())", level: .info)
            success?(self)
        } else {
            let error = NSError(domain: "KKNetwork", code: -1002, userInfo: [NSLocalizedDescriptionKey: "缓存不存在"])
            self.error = error
            failure?(self)
        }
        return self
    }
    
    private func saveToCache() {
        guard let json = responseJSON else { return }
        KKNetworkCache.shared.setCache(json, forKey: cacheKey(), maxAge: cacheMaxAge())
        KKNetworkLogger.log("📦 保存缓存: \(requestPath())", level: .info)
    }
    
    private func buildFullURL() -> String {
        let baseURL = customBaseURL() ?? KKNetworkConfig.shared.baseURL
        let path = requestPath()
        return baseURL + path
    }
}
