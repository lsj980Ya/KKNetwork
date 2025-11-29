//
//  KKDataTransformer.swift
//  KKNetwork
//
//  数据转换器（支持加密、压缩、编码等）
//

import Foundation
import SwiftyJSON

/// 数据转换器协议
public protocol KKDataTransformer {
    /// 转换请求数据
    func transformRequest(_ data: Data) -> Data
    
    /// 转换响应数据
    func transformResponse(_ data: Data) -> Data
}

// MARK: - 加密转换器

/// AES 加密转换器
public class KKAESTransformer: KKDataTransformer {
    
    private let key: String
    private let iv: String
    
    public init(key: String, iv: String) {
        self.key = key
        self.iv = iv
    }
    
    public func transformRequest(_ data: Data) -> Data {
        // 实现 AES 加密
        // 这里需要导入 CryptoKit 或 CommonCrypto
        return data // 简化实现
    }
    
    public func transformResponse(_ data: Data) -> Data {
        // 实现 AES 解密
        return data // 简化实现
    }
}

// MARK: - 压缩转换器

/// Gzip 压缩转换器
public class KKGzipTransformer: KKDataTransformer {
    
    public init() {}
    
    public func transformRequest(_ data: Data) -> Data {
        // 压缩请求数据
        return (data as NSData).compressed(using: .zlib) as Data? ?? data
    }
    
    public func transformResponse(_ data: Data) -> Data {
        // 解压响应数据
        return (data as NSData).decompressed(using: .zlib) as Data? ?? data
    }
}

// MARK: - Base64 转换器

/// Base64 编码转换器
public class KKBase64Transformer: KKDataTransformer {
    
    public init() {}
    
    public func transformRequest(_ data: Data) -> Data {
        let base64String = data.base64EncodedString()
        return base64String.data(using: .utf8) ?? data
    }
    
    public func transformResponse(_ data: Data) -> Data {
        guard let base64String = String(data: data, encoding: .utf8),
              let decodedData = Data(base64Encoded: base64String) else {
            return data
        }
        return decodedData
    }
}

// MARK: - 组合转换器

/// 组合多个转换器
public class KKCompositeTransformer: KKDataTransformer {
    
    private let transformers: [KKDataTransformer]
    
    public init(transformers: [KKDataTransformer]) {
        self.transformers = transformers
    }
    
    public func transformRequest(_ data: Data) -> Data {
        return transformers.reduce(data) { result, transformer in
            transformer.transformRequest(result)
        }
    }
    
    public func transformResponse(_ data: Data) -> Data {
        return transformers.reversed().reduce(data) { result, transformer in
            transformer.transformResponse(result)
        }
    }
}

// MARK: - 支持数据转换的请求

open class KKTransformableRequest: KKBaseRequest {
    
    /// 数据转换器
    open func dataTransformer() -> KKDataTransformer? {
        return nil
    }
}
