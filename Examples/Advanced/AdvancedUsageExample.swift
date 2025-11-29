//
//  AdvancedUsageExample.swift
//  KKNetwork
//
//  高级使用示例
//

import Foundation
import SwiftyJSON

class AdvancedUsageExample {
    
    // MARK: - 批量请求示例
    
    static func batchRequestExample() {
        let request1 = UserInfoRequest(userId: "123")
        let request2 = UserInfoRequest(userId: "456")
        let request3 = UserInfoRequest(userId: "789")
        
        let batchRequest = KKBatchRequest(requests: [request1, request2, request3])
        batchRequest.start(
            success: {
                print("✅ 所有请求成功")
                print("用户1: \(request1.responseJSON ?? JSON())")
                print("用户2: \(request2.responseJSON ?? JSON())")
                print("用户3: \(request3.responseJSON ?? JSON())")
            },
            failure: { failedRequest in
                print("❌ 批量请求失败")
            }
        )
    }
    
    // MARK: - 链式请求示例
    
    static func chainRequestExample() {
        let loginRequest = LoginRequest(username: "test", password: "123456")
        let userInfoRequest = UserInfoRequest(userId: "")
        
        let chainRequest = KKChainRequest()
        chainRequest
            .addRequest(loginRequest) { chain, finishedRequest in
                // 登录成功后，保存 token
                if let token = finishedRequest.responseJSON?["data"]["token"].string {
                    KKNetworkConfig.shared.commonHeaders.add(name: "Authorization", value: "Bearer \(token)")
                }
            }
            .addRequest(userInfoRequest)
            .start(
                success: {
                    print("✅ 链式请求全部完成")
                },
                failure: { failedRequest in
                    print("❌ 链式请求失败")
                }
            )
    }
    
    // MARK: - 文件上传示例
    
    static func uploadExample() {
        #if canImport(UIKit)
        guard let image = UIImage(named: "test")?.jpegData(compressionQuality: 0.8) else {
            return
        }
        #else
        // macOS 平台示例
        print("⚠️ macOS 平台请使用 NSImage")
        return
        #endif
        
        let request = UploadImageRequest(image: image)
        request.progressBlock = { progress in
            let percent = Int(progress.fractionCompleted * 100)
            print("📤 上传进度: \(percent)%")
        }
        
        request.start(
            success: { request in
                if let imageURL = request.responseJSON?["data"]["url"].string {
                    print("✅ 上传成功: \(imageURL)")
                }
            },
            failure: { request in
                print("❌ 上传失败: \(request.error?.localizedDescription ?? "")")
            }
        )
    }
}
