//
//  UsageExample.swift
//  KKNetwork
//
//  使用示例
//

import Foundation
import SwiftyJSON

class UsageExample {
    
    /// 初始化配置
    static func setupNetwork() {
        KKNetwork.setup(
            baseURL: "https://api.example.com",
            backupURLs: [
                "https://api-backup1.example.com",
                "https://api-backup2.example.com"
            ],
            commonHeaders: [
                "Content-Type": "application/json",
                "Accept": "application/json"
            ],
            commonParameters: [
                "platform": "iOS",
                "version": "1.0.0"
            ],
            timeoutInterval: 30,
            enableLog: true,
            logLevel: .verbose
        )
        
        // 添加 Token 拦截器
        let tokenInterceptor = KKTokenInterceptor {
            return UserDefaults.standard.string(forKey: "token")
        }
        KKNetworkConfig.shared.addInterceptor(tokenInterceptor)
        
        // 添加通用响应拦截器
        let responseInterceptor = KKResponseInterceptor { request, error in
            if let error = error {
                print("请求失败: \(error.localizedDescription)")
            }
        }
        KKNetworkConfig.shared.addInterceptor(responseInterceptor)
    }
    
    /// 基础请求示例
    static func basicRequestExample() {
        let request = LoginRequest(username: "test", password: "123456")
        request.start(
            success: { request in
                if let json = request.responseJSON {
                    print("登录成功: \(json)")
                }
            },
            failure: { request in
                print("登录失败: \(request.error?.localizedDescription ?? "")")
            }
        )
    }
}
