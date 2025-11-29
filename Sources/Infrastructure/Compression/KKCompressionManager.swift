//
//  KKCompressionManager.swift
//  KKNetwork
//
//  数据压缩管理
//

import Foundation
import Compression

/// 压缩算法
public enum KKCompressionAlgorithm {
    case gzip
    case lz4
    case lzma
    case zlib
    
    var algorithm: compression_algorithm {
        switch self {
        case .gzip: return COMPRESSION_ZLIB
        case .lz4: return COMPRESSION_LZ4
        case .lzma: return COMPRESSION_LZMA
        case .zlib: return COMPRESSION_ZLIB
        }
    }
}

/// 压缩管理器
public class KKCompressionManager {
    
    // MARK: - Singleton
    
    public static let shared = KKCompressionManager()
    
    private init() {}
    
    // MARK: - Properties
    
    /// 是否启用自动压缩
    public var autoCompress: Bool = false
    
    /// 压缩阈值（字节数，超过此大小才压缩）
    public var compressionThreshold: Int = 1024
    
    /// 默认压缩算法
    public var defaultAlgorithm: KKCompressionAlgorithm = .gzip
    
    // MARK: - Public Methods
    
    /// 压缩数据
    public func compress(_ data: Data, algorithm: KKCompressionAlgorithm? = nil) -> Data? {
        let algo = algorithm ?? defaultAlgorithm
        
        return data.withUnsafeBytes { (sourcePtr: UnsafeRawBufferPointer) -> Data? in
            let sourceSize = data.count
            let destinationSize = sourceSize
            
            var destinationBuffer = [UInt8](repeating: 0, count: destinationSize)
            
            let compressedSize = compression_encode_buffer(
                &destinationBuffer,
                destinationSize,
                sourcePtr.baseAddress!.assumingMemoryBound(to: UInt8.self),
                sourceSize,
                nil,
                algo.algorithm
            )
            
            guard compressedSize > 0 else { return nil }
            
            return Data(bytes: destinationBuffer, count: compressedSize)
        }
    }
    
    /// 解压数据
    public func decompress(_ data: Data, algorithm: KKCompressionAlgorithm? = nil) -> Data? {
        let algo = algorithm ?? defaultAlgorithm
        
        return data.withUnsafeBytes { (sourcePtr: UnsafeRawBufferPointer) -> Data? in
            let sourceSize = data.count
            let destinationSize = sourceSize * 4 // 假设解压后最多4倍大小
            
            var destinationBuffer = [UInt8](repeating: 0, count: destinationSize)
            
            let decompressedSize = compression_decode_buffer(
                &destinationBuffer,
                destinationSize,
                sourcePtr.baseAddress!.assumingMemoryBound(to: UInt8.self),
                sourceSize,
                nil,
                algo.algorithm
            )
            
            guard decompressedSize > 0 else { return nil }
            
            return Data(bytes: destinationBuffer, count: decompressedSize)
        }
    }
    
    /// 是否应该压缩
    public func shouldCompress(_ data: Data) -> Bool {
        return autoCompress && data.count > compressionThreshold
    }
}
