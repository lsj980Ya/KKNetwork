//
//  KKNetworkCache.swift
//  KKNetwork
//
//  网络缓存管理
//

import Foundation
import SwiftyJSON
import CryptoKit

/// 缓存策略
public enum KKCachePolicy {
    case none                    // 不使用缓存
    case cacheOnly              // 只使用缓存
    case networkOnly            // 只使用网络
    case cacheElseNetwork       // 先使用缓存，缓存不存在则请求网络
    case networkElseCache       // 先请求网络，失败则使用缓存
    case cacheThenNetwork       // 先返回缓存，然后请求网络更新
}

/// 网络缓存管理器
public class KKNetworkCache {
    
    // MARK: - Singleton
    public static let shared = KKNetworkCache()
    
    private init() {}
    
    // MARK: - Properties
    
    private let cache = NSCache<NSString, CacheObject>()
    private let fileManager = FileManager.default
    private lazy var cacheDirectory: URL = {
        let paths = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)
        let cacheDir = paths[0].appendingPathComponent("KKNetworkCache")
        try? fileManager.createDirectory(at: cacheDir, withIntermediateDirectories: true)
        return cacheDir
    }()
    
    // MARK: - Public Methods
    
    /// 保存缓存
    public func setCache(_ json: JSON, forKey key: String, maxAge: TimeInterval = 0) {
        let cacheObject = CacheObject(json: json, maxAge: maxAge)
        
        // 内存缓存
        cache.setObject(cacheObject, forKey: key as NSString)
        
        // 磁盘缓存
        saveToDisk(cacheObject, forKey: key)
    }
    
    /// 获取缓存
    public func cache(forKey key: String) -> JSON? {
        // 先从内存获取
        if let cacheObject = cache.object(forKey: key as NSString) {
            if cacheObject.isValid() {
                return cacheObject.json
            } else {
                cache.removeObject(forKey: key as NSString)
            }
        }
        
        // 再从磁盘获取
        if let cacheObject = loadFromDisk(forKey: key) {
            if cacheObject.isValid() {
                cache.setObject(cacheObject, forKey: key as NSString)
                return cacheObject.json
            } else {
                removeFromDisk(forKey: key)
            }
        }
        
        return nil
    }
    
    /// 移除缓存
    public func removeCache(forKey key: String) {
        cache.removeObject(forKey: key as NSString)
        removeFromDisk(forKey: key)
    }
    
    /// 清空所有缓存
    public func clearAllCache() {
        cache.removeAllObjects()
        try? fileManager.removeItem(at: cacheDirectory)
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    }
    
    /// 生成缓存 Key
    public func cacheKey(url: String, parameters: [String: Any]?) -> String {
        var key = url
        if let params = parameters, !params.isEmpty {
            let sortedParams = params.sorted { $0.key < $1.key }
            let paramString = sortedParams.map { "\($0.key)=\($0.value)" }.joined(separator: "&")
            key += "?" + paramString
        }
        return key.md5()
    }
    
    // MARK: - Private Methods
    
    private func saveToDisk(_ cacheObject: CacheObject, forKey key: String) {
        let fileURL = cacheDirectory.appendingPathComponent(key.md5())
        
        do {
            let data = try JSONEncoder().encode(cacheObject)
            try data.write(to: fileURL)
        } catch {
            KKNetworkLogger.log("保存缓存失败: \(error)", level: .error)
        }
    }
    
    private func loadFromDisk(forKey key: String) -> CacheObject? {
        let fileURL = cacheDirectory.appendingPathComponent(key.md5())
        
        guard let data = try? Data(contentsOf: fileURL) else {
            return nil
        }
        
        return try? JSONDecoder().decode(CacheObject.self, from: data)
    }
    
    private func removeFromDisk(forKey key: String) {
        let fileURL = cacheDirectory.appendingPathComponent(key.md5())
        try? fileManager.removeItem(at: fileURL)
    }
}

// MARK: - CacheObject

private class CacheObject: NSObject, Codable {
    let json: JSON
    let createTime: TimeInterval
    let maxAge: TimeInterval
    
    init(json: JSON, maxAge: TimeInterval) {
        self.json = json
        self.createTime = Date().timeIntervalSince1970
        self.maxAge = maxAge
    }
    
    func isValid() -> Bool {
        if maxAge <= 0 {
            return true
        }
        let currentTime = Date().timeIntervalSince1970
        return currentTime - createTime < maxAge
    }
    
    // Codable
    enum CodingKeys: String, CodingKey {
        case jsonString, createTime, maxAge
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let jsonString = try container.decode(String.self, forKey: .jsonString)
        self.json = JSON(parseJSON: jsonString)
        self.createTime = try container.decode(TimeInterval.self, forKey: .createTime)
        self.maxAge = try container.decode(TimeInterval.self, forKey: .maxAge)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(json.rawString() ?? "", forKey: .jsonString)
        try container.encode(createTime, forKey: .createTime)
        try container.encode(maxAge, forKey: .maxAge)
    }
}

// MARK: - String Extension

extension String {
    func md5() -> String {
        guard let data = self.data(using: .utf8) else { return self }
        let digest = Insecure.MD5.hash(data: data)
        return digest.map { String(format: "%02x", $0) }.joined()
    }
}
