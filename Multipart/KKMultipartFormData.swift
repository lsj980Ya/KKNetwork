//
//  KKMultipartFormData.swift
//  KKNetwork
//
//  增强的 Multipart 表单数据构建
//

import Foundation

/// Multipart 表单数据构建器
public class KKMultipartFormDataBuilder {
    
    // MARK: - Properties
    
    private var parts: [Part] = []
    private let boundary: String
    
    // MARK: - Part
    
    private struct Part {
        let name: String
        let data: Data
        let fileName: String?
        let mimeType: String?
    }
    
    // MARK: - Initialization
    
    public init() {
        self.boundary = "Boundary-\(UUID().uuidString)"
    }
    
    // MARK: - Public Methods
    
    /// 添加文本字段
    public func append(_ value: String, withName name: String) {
        if let data = value.data(using: .utf8) {
            parts.append(Part(name: name, data: data, fileName: nil, mimeType: nil))
        }
    }
    
    /// 添加文件数据
    public func append(_ data: Data, withName name: String, fileName: String, mimeType: String) {
        parts.append(Part(name: name, data: data, fileName: fileName, mimeType: mimeType))
    }
    
    /// 添加文件 URL
    public func append(fileURL: URL, withName name: String) throws {
        let data = try Data(contentsOf: fileURL)
        let fileName = fileURL.lastPathComponent
        let mimeType = mimeType(for: fileURL.pathExtension)
        
        parts.append(Part(name: name, data: data, fileName: fileName, mimeType: mimeType))
    }
    
    /// 添加图片
    public func append(image: Data, withName name: String, fileName: String = "image.jpg", quality: CGFloat = 0.8) {
        parts.append(Part(name: name, data: image, fileName: fileName, mimeType: "image/jpeg"))
    }
    
    /// 构建最终数据
    public func build() -> (data: Data, contentType: String) {
        var body = Data()
        
        for part in parts {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            
            if let fileName = part.fileName, let mimeType = part.mimeType {
                body.append("Content-Disposition: form-data; name=\"\(part.name)\"; filename=\"\(fileName)\"\r\n".data(using: .utf8)!)
                body.append("Content-Type: \(mimeType)\r\n\r\n".data(using: .utf8)!)
            } else {
                body.append("Content-Disposition: form-data; name=\"\(part.name)\"\r\n\r\n".data(using: .utf8)!)
            }
            
            body.append(part.data)
            body.append("\r\n".data(using: .utf8)!)
        }
        
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        let contentType = "multipart/form-data; boundary=\(boundary)"
        return (body, contentType)
    }
    
    // MARK: - Private Methods
    
    private func mimeType(for pathExtension: String) -> String {
        switch pathExtension.lowercased() {
        case "jpg", "jpeg": return "image/jpeg"
        case "png": return "image/png"
        case "gif": return "image/gif"
        case "pdf": return "application/pdf"
        case "json": return "application/json"
        case "xml": return "application/xml"
        case "txt": return "text/plain"
        case "mp4": return "video/mp4"
        case "mp3": return "audio/mpeg"
        default: return "application/octet-stream"
        }
    }
}
