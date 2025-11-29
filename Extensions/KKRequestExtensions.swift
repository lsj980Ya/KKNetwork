//
//  KKRequestExtensions.swift
//  KKNetwork
//
//  便捷扩展
//

import Foundation
import SwiftyJSON

// MARK: - Async/Await 支持

@available(iOS 13.0, macOS 10.15, *)
extension KKBaseRequest {
    
    /// 使用 async/await 发起请求
    public func asyncStart() async throws -> JSON {
        return try await withCheckedThrowingContinuation { continuation in
            self.start(
                success: { request in
                    if let json = request.responseJSON {
                        continuation.resume(returning: json)
                    } else {
                        let error = NSError(domain: "KKNetwork", code: -1, userInfo: [NSLocalizedDescriptionKey: "响应数据为空"])
                        continuation.resume(throwing: error)
                    }
                },
                failure: { request in
                    let error = request.error ?? NSError(domain: "KKNetwork", code: -1, userInfo: [NSLocalizedDescriptionKey: "未知错误"])
                    continuation.resume(throwing: error)
                }
            )
        }
    }
}

// MARK: - Combine 支持

#if canImport(Combine)
import Combine

@available(iOS 13.0, macOS 10.15, *)
extension KKBaseRequest {
    
    /// 返回 Combine Publisher
    public func publisher() -> AnyPublisher<JSON, Error> {
        return Future<JSON, Error> { promise in
            self.start(
                success: { request in
                    if let json = request.responseJSON {
                        promise(.success(json))
                    } else {
                        let error = NSError(domain: "KKNetwork", code: -1, userInfo: [NSLocalizedDescriptionKey: "响应数据为空"])
                        promise(.failure(error))
                    }
                },
                failure: { request in
                    let error = request.error ?? NSError(domain: "KKNetwork", code: -1, userInfo: [NSLocalizedDescriptionKey: "未知错误"])
                    promise(.failure(error))
                }
            )
        }
        .eraseToAnyPublisher()
    }
}
#endif

// MARK: - RxSwift 支持（需要导入 RxSwift）

#if canImport(RxSwift)
import RxSwift

extension KKBaseRequest {
    
    /// 返回 RxSwift Observable
    public func asObservable() -> Observable<JSON> {
        return Observable.create { observer in
            self.start(
                success: { request in
                    if let json = request.responseJSON {
                        observer.onNext(json)
                        observer.onCompleted()
                    } else {
                        let error = NSError(domain: "KKNetwork", code: -1, userInfo: [NSLocalizedDescriptionKey: "响应数据为空"])
                        observer.onError(error)
                    }
                },
                failure: { request in
                    let error = request.error ?? NSError(domain: "KKNetwork", code: -1, userInfo: [NSLocalizedDescriptionKey: "未知错误"])
                    observer.onError(error)
                }
            )
            
            return Disposables.create {
                self.cancel()
            }
        }
    }
}
#endif

// MARK: - JSON 解析便捷方法

extension KKBaseRequest {
    
    /// 解析为模型（需要模型遵循 Codable）
    public func decode<T: Codable>(_ type: T.Type) -> T? {
        guard let json = responseJSON,
              let data = try? json.rawData() else {
            return nil
        }
        
        return try? JSONDecoder().decode(type, from: data)
    }
    
    /// 解析为模型数组
    public func decodeArray<T: Codable>(_ type: T.Type) -> [T]? {
        guard let json = responseJSON,
              let data = try? json.rawData() else {
            return nil
        }
        
        return try? JSONDecoder().decode([T].self, from: data)
    }
}
