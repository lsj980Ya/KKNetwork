//
//  KKResponseValidator.swift
//  KKNetwork
//
//  响应验证器（支持多种验证规则）
//

import Foundation
import SwiftyJSON

/// 响应验证器协议
public protocol KKResponseValidator {
    func validate(_ json: JSON) -> Bool
    func errorMessage(_ json: JSON) -> String?
}

// MARK: - 状态码验证器

/// 状态码验证器
public struct KKStatusCodeValidator: KKResponseValidator {
    
    private let codeKey: String
    private let successCodes: Set<Int>
    private let messageKey: String
    
    public init(codeKey: String = "code",
                successCodes: Set<Int> = [0, 200],
                messageKey: String = "message") {
        self.codeKey = codeKey
        self.successCodes = successCodes
        self.messageKey = messageKey
    }
    
    public func validate(_ json: JSON) -> Bool {
        let code = json[codeKey].intValue
        return successCodes.contains(code)
    }
    
    public func errorMessage(_ json: JSON) -> String? {
        return json[messageKey].string
    }
}

// MARK: - 数据存在验证器

/// 数据存在验证器
public struct KKDataExistenceValidator: KKResponseValidator {
    
    private let dataKey: String
    
    public init(dataKey: String = "data") {
        self.dataKey = dataKey
    }
    
    public func validate(_ json: JSON) -> Bool {
        return json[dataKey].exists()
    }
    
    public func errorMessage(_ json: JSON) -> String? {
        return "数据不存在"
    }
}

// MARK: - 组合验证器

/// 组合验证器（所有验证器都通过才算成功）
public struct KKCompositeValidator: KKResponseValidator {
    
    private let validators: [KKResponseValidator]
    
    public init(validators: [KKResponseValidator]) {
        self.validators = validators
    }
    
    public func validate(_ json: JSON) -> Bool {
        return validators.allSatisfy { $0.validate(json) }
    }
    
    public func errorMessage(_ json: JSON) -> String? {
        for validator in validators {
            if !validator.validate(json) {
                return validator.errorMessage(json)
            }
        }
        return nil
    }
}

// MARK: - 自定义验证器

/// 自定义验证器
public struct KKCustomValidator: KKResponseValidator {
    
    private let validationBlock: (JSON) -> Bool
    private let errorMessageBlock: (JSON) -> String?
    
    public init(validation: @escaping (JSON) -> Bool,
                errorMessage: @escaping (JSON) -> String?) {
        self.validationBlock = validation
        self.errorMessageBlock = errorMessage
    }
    
    public func validate(_ json: JSON) -> Bool {
        return validationBlock(json)
    }
    
    public func errorMessage(_ json: JSON) -> String? {
        return errorMessageBlock(json)
    }
}

// MARK: - 支持验证器的请求

open class KKValidatableRequest: KKBaseRequest {
    
    /// 响应验证器
    open func responseValidator() -> KKResponseValidator? {
        return KKStatusCodeValidator()
    }
    
    public override func validateResponse(_ json: JSON) -> Bool {
        guard let validator = responseValidator() else {
            return true
        }
        return validator.validate(json)
    }
    
    public override func errorMessageFromResponse(_ json: JSON) -> String? {
        guard let validator = responseValidator() else {
            return nil
        }
        return validator.errorMessage(json)
    }
}
