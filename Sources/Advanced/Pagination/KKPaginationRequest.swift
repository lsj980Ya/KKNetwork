//
//  KKPaginationRequest.swift
//  KKNetwork
//
//  分页请求支持
//

import Foundation
import SwiftyJSON

/// 分页配置
public struct KKPaginationConfig {
    public var pageKey: String = "page"
    public var pageSizeKey: String = "pageSize"
    public var defaultPageSize: Int = 20
    
    public init() {}
}

/// 分页请求基类
open class KKPaginationRequest: KKBaseRequest {
    
    // MARK: - Properties
    
    /// 当前页码
    public var currentPage: Int = 1
    
    /// 每页数量
    public var pageSize: Int
    
    /// 是否还有更多数据
    public private(set) var hasMore: Bool = true
    
    /// 总数据量
    public private(set) var totalCount: Int = 0
    
    /// 分页配置
    public var paginationConfig = KKPaginationConfig()
    
    // MARK: - Initialization
    
    public init(pageSize: Int? = nil) {
        self.pageSize = pageSize ?? paginationConfig.defaultPageSize
        super.init()
    }
    
    // MARK: - Override
    
    public override func requestParameters() -> [String: Any]? {
        var params = customParameters() ?? [:]
        params[paginationConfig.pageKey] = currentPage
        params[paginationConfig.pageSizeKey] = pageSize
        return params
    }
    
    // MARK: - Subclass Override
    
    /// 自定义参数（子类重写）
    open func customParameters() -> [String: Any]? {
        return nil
    }
    
    /// 从响应中解析分页信息
    open func parsePaginationInfo(_ json: JSON) {
        // 子类重写，根据实际 API 格式解析
        // 示例：
        // totalCount = json["total"].intValue
        // hasMore = json["hasMore"].boolValue
    }
    
    /// 从响应中提取数据列表
    open func extractDataList(_ json: JSON) -> [JSON] {
        // 子类重写，根据实际 API 格式提取
        return json["data"]["list"].arrayValue
    }
    
    // MARK: - Public Methods
    
    /// 加载第一页
    @discardableResult
    public func loadFirstPage(success: ((KKPaginationRequest) -> Void)? = nil,
                             failure: ((KKPaginationRequest) -> Void)? = nil) -> Self {
        currentPage = 1
        hasMore = true
        
        return start(
            success: { [weak self] request in
                guard let self = self, let json = self.responseJSON else { return }
                self.parsePaginationInfo(json)
                success?(self)
            },
            failure: failure
        )
    }
    
    /// 加载下一页
    @discardableResult
    public func loadNextPage(success: ((KKPaginationRequest) -> Void)? = nil,
                            failure: ((KKPaginationRequest) -> Void)? = nil) -> Self {
        guard hasMore else {
            KKNetworkLogger.log("⚠️ 没有更多数据", level: .info)
            return self
        }
        
        currentPage += 1
        
        return start(
            success: { [weak self] request in
                guard let self = self, let json = self.responseJSON else { return }
                self.parsePaginationInfo(json)
                success?(self)
            },
            failure: { [weak self] request in
                // 失败时回退页码
                self?.currentPage -= 1
                failure?(request)
            }
        )
    }
    
    /// 刷新当前页
    @discardableResult
    public func refresh(success: ((KKPaginationRequest) -> Void)? = nil,
                       failure: ((KKPaginationRequest) -> Void)? = nil) -> Self {
        return start(
            success: { [weak self] request in
                guard let self = self, let json = self.responseJSON else { return }
                self.parsePaginationInfo(json)
                success?(self)
            },
            failure: failure
        )
    }
}

// MARK: - 分页管理器

/// 分页数据管理器
public class KKPaginationManager<T> {
    
    // MARK: - Properties
    
    private var dataList: [T] = []
    private let request: KKPaginationRequest
    private let mapper: (JSON) -> T?
    
    /// 数据列表
    public var items: [T] {
        return dataList
    }
    
    /// 是否正在加载
    public private(set) var isLoading: Bool = false
    
    // MARK: - Initialization
    
    public init(request: KKPaginationRequest, mapper: @escaping (JSON) -> T?) {
        self.request = request
        self.mapper = mapper
    }
    
    // MARK: - Public Methods
    
    /// 加载第一页
    public func loadFirstPage(completion: @escaping (Result<[T], Error>) -> Void) {
        guard !isLoading else { return }
        
        isLoading = true
        dataList.removeAll()
        
        request.loadFirstPage(
            success: { [weak self] _ in
                guard let self = self else { return }
                self.isLoading = false
                
                if let json = self.request.responseJSON {
                    let newItems = self.request.extractDataList(json).compactMap(self.mapper)
                    self.dataList = newItems
                    completion(.success(newItems))
                }
            },
            failure: { [weak self] request in
                self?.isLoading = false
                let error = request.error ?? NSError(domain: "KKNetwork", code: -1, userInfo: nil)
                completion(.failure(error))
            }
        )
    }
    
    /// 加载下一页
    public func loadNextPage(completion: @escaping (Result<[T], Error>) -> Void) {
        guard !isLoading else { return }
        guard request.hasMore else {
            completion(.success([]))
            return
        }
        
        isLoading = true
        
        request.loadNextPage(
            success: { [weak self] _ in
                guard let self = self else { return }
                self.isLoading = false
                
                if let json = self.request.responseJSON {
                    let newItems = self.request.extractDataList(json).compactMap(self.mapper)
                    self.dataList.append(contentsOf: newItems)
                    completion(.success(newItems))
                }
            },
            failure: { [weak self] request in
                self?.isLoading = false
                let error = request.error ?? NSError(domain: "KKNetwork", code: -1, userInfo: nil)
                completion(.failure(error))
            }
        )
    }
    
    /// 刷新
    public func refresh(completion: @escaping (Result<[T], Error>) -> Void) {
        loadFirstPage(completion: completion)
    }
}
