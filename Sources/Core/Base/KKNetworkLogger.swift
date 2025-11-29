//
//  KKNetworkLogger.swift
//  KKNetwork
//
//  网络日志工具
//

import Foundation
import Alamofire
import SwiftyJSON

/// 网络日志工具
public class KKNetworkLogger {
    
    /// 打印日志
    public static func log(_ message: String, level: KKLogLevel = .verbose) {
        guard KKNetworkConfig.shared.enableLog else { return }
        guard level.rawValue <= KKNetworkConfig.shared.logLevel.rawValue else { return }
        
        print("[\(currentTime())] [KKNetwork] \(message)")
    }
    
    /// 打印请求信息
    public static func logRequest(url: String,
                                  method: HTTPMethod,
                                  parameters: [String: Any]?,
                                  headers: HTTPHeaders) {
        guard KKNetworkConfig.shared.enableLog else { return }
        guard KKNetworkConfig.shared.logLevel == .verbose else { return }
        
        var logMessage = """
        
        ╔═══════════════════════════════════════════════════════════════════════
        ║ 📤 REQUEST
        ╠═══════════════════════════════════════════════════════════════════════
        ║ URL: \(url)
        ║ Method: \(method.rawValue)
        """
        
        if !headers.isEmpty {
            logMessage += "\n║ Headers:"
            for header in headers {
                logMessage += "\n║   \(header.name): \(header.value)"
            }
        }
        
        if let parameters = parameters, !parameters.isEmpty {
            logMessage += "\n║ Parameters:"
            if let jsonData = try? JSONSerialization.data(withJSONObject: parameters, options: .prettyPrinted),
               let jsonString = String(data: jsonData, encoding: .utf8) {
                let lines = jsonString.components(separatedBy: .newlines)
                for line in lines {
                    logMessage += "\n║   \(line)"
                }
            }
        }
        
        logMessage += "\n╚═══════════════════════════════════════════════════════════════════════\n"
        
        print(logMessage)
    }
    
    /// 打印响应信息
    public static func logResponse(url: String,
                                   statusCode: Int?,
                                   json: JSON) {
        guard KKNetworkConfig.shared.enableLog else { return }
        guard KKNetworkConfig.shared.logLevel == .verbose else { return }
        
        var logMessage = """
        
        ╔═══════════════════════════════════════════════════════════════════════
        ║ 📥 RESPONSE
        ╠═══════════════════════════════════════════════════════════════════════
        ║ URL: \(url)
        ║ Status Code: \(statusCode ?? 0)
        ║ Response:
        """
        
        if let jsonString = json.rawString(.utf8, options: .prettyPrinted) {
            let lines = jsonString.components(separatedBy: .newlines)
            for line in lines {
                logMessage += "\n║   \(line)"
            }
        }
        
        logMessage += "\n╚═══════════════════════════════════════════════════════════════════════\n"
        
        print(logMessage)
    }
    
    /// 打印错误信息
    public static func logError(url: String, error: Error) {
        guard KKNetworkConfig.shared.enableLog else { return }
        guard KKNetworkConfig.shared.logLevel.rawValue >= KKLogLevel.error.rawValue else { return }
        
        let logMessage = """
        
        ╔═══════════════════════════════════════════════════════════════════════
        ║ ❌ ERROR
        ╠═══════════════════════════════════════════════════════════════════════
        ║ URL: \(url)
        ║ Error: \(error.localizedDescription)
        ╚═══════════════════════════════════════════════════════════════════════
        
        """
        
        print(logMessage)
    }
    
    // MARK: - Private
    
    private static func currentTime() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        return formatter.string(from: Date())
    }
}
