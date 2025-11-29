//
//  KKGraphQLRequest.swift
//  KKNetwork
//
//  GraphQL 请求支持
//

import Foundation
import Alamofire
import SwiftyJSON

/// GraphQL 请求
open class KKGraphQLRequest: KKBaseRequest {
    
    // MARK: - Properties
    
    /// GraphQL 查询语句
    open func query() -> String {
        return ""
    }
    
    /// GraphQL 变量
    open func variables() -> [String: Any]? {
        return nil
    }
    
    /// 操作名称
    open func operationName() -> String? {
        return nil
    }
    
    // MARK: - Override
    
    public override func requestMethod() -> HTTPMethod {
        return .post
    }
    
    public override func requestParameters() -> [String: Any]? {
        var params: [String: Any] = [
            "query": query()
        ]
        
        if let variables = variables() {
            params["variables"] = variables
        }
        
        if let operationName = operationName() {
            params["operationName"] = operationName
        }
        
        return params
    }
    
    public override func parameterEncoding() -> ParameterEncoding {
        return JSONEncoding.default
    }
    
    public override func validateResponse(_ json: JSON) -> Bool {
        // GraphQL 特殊处理：即使 HTTP 200，也可能有错误
        if json["errors"].exists() {
            return false
        }
        return json["data"].exists()
    }
    
    public override func errorMessageFromResponse(_ json: JSON) -> String? {
        if let errors = json["errors"].array, let firstError = errors.first {
            return firstError["message"].string
        }
        return nil
    }
    
    /// 获取 GraphQL 数据
    public var graphQLData: JSON? {
        return responseJSON?["data"]
    }
    
    /// 获取 GraphQL 错误
    public var graphQLErrors: [JSON]? {
        return responseJSON?["errors"].array
    }
}

// MARK: - GraphQL 示例

/// 示例：查询用户信息
class UserQueryRequest: KKGraphQLRequest {
    
    let userId: String
    
    init(userId: String) {
        self.userId = userId
    }
    
    override func requestPath() -> String {
        return "/graphql"
    }
    
    override func query() -> String {
        return """
        query GetUser($userId: ID!) {
            user(id: $userId) {
                id
                name
                email
                avatar
            }
        }
        """
    }
    
    override func variables() -> [String: Any]? {
        return ["userId": userId]
    }
    
    override func operationName() -> String? {
        return "GetUser"
    }
}
