//
//  KKRequestTracing.swift
//  KKNetwork
//
//  请求追踪（分布式追踪、链路追踪）
//

import Foundation

/// 追踪上下文
public struct KKTraceContext {
    public let traceId: String
    public let spanId: String
    public let parentSpanId: String?
    public let timestamp: Date
    
    public init(traceId: String? = nil, spanId: String? = nil, parentSpanId: String? = nil) {
        self.traceId = traceId ?? UUID().uuidString
        self.spanId = spanId ?? UUID().uuidString
        self.parentSpanId = parentSpanId
        self.timestamp = Date()
    }
}

/// 追踪 Span
public struct KKTraceSpan {
    public let context: KKTraceContext
    public let operationName: String
    public let startTime: Date
    public var endTime: Date?
    public var tags: [String: String] = [:]
    public var logs: [(Date, String)] = []
    
    public var duration: TimeInterval? {
        guard let endTime = endTime else { return nil }
        return endTime.timeIntervalSince(startTime)
    }
}

/// 请求追踪管理器
public class KKRequestTracing {
    
    // MARK: - Singleton
    
    public static let shared = KKRequestTracing()
    
    private init() {}
    
    // MARK: - Properties
    
    /// 是否启用追踪
    public var isEnabled: Bool = false
    
    /// 追踪数据存储
    private var spans: [String: KKTraceSpan] = [:]
    
    /// 追踪回调
    public var traceHandler: ((KKTraceSpan) -> Void)?
    
    // MARK: - Public Methods
    
    /// 开始追踪
    public func startTrace(operationName: String, parentContext: KKTraceContext? = nil) -> KKTraceContext {
        guard isEnabled else {
            return KKTraceContext()
        }
        
        let context = KKTraceContext(
            traceId: parentContext?.traceId,
            parentSpanId: parentContext?.spanId
        )
        
        var span = KKTraceSpan(
            context: context,
            operationName: operationName,
            startTime: Date()
        )
        
        span.tags["trace.id"] = context.traceId
        span.tags["span.id"] = context.spanId
        
        if let parentSpanId = context.parentSpanId {
            span.tags["parent.span.id"] = parentSpanId
        }
        
        spans[context.spanId] = span
        
        KKNetworkLogger.log("🔍 开始追踪: \(operationName) [TraceID: \(context.traceId)]", level: .verbose)
        
        return context
    }
    
    /// 结束追踪
    public func endTrace(context: KKTraceContext) {
        guard isEnabled else { return }
        guard var span = spans[context.spanId] else { return }
        
        span.endTime = Date()
        spans[context.spanId] = span
        
        if let duration = span.duration {
            KKNetworkLogger.log("🔍 结束追踪: \(span.operationName) - 耗时: \(String(format: "%.2f", duration * 1000))ms", level: .verbose)
        }
        
        traceHandler?(span)
    }
    
    /// 添加标签
    public func addTag(context: KKTraceContext, key: String, value: String) {
        guard isEnabled else { return }
        guard var span = spans[context.spanId] else { return }
        
        span.tags[key] = value
        spans[context.spanId] = span
    }
    
    /// 添加日志
    public func addLog(context: KKTraceContext, message: String) {
        guard isEnabled else { return }
        guard var span = spans[context.spanId] else { return }
        
        span.logs.append((Date(), message))
        spans[context.spanId] = span
    }
    
    /// 获取追踪头
    public func traceHeaders(for context: KKTraceContext) -> [String: String] {
        return [
            "X-Trace-Id": context.traceId,
            "X-Span-Id": context.spanId,
            "X-Parent-Span-Id": context.parentSpanId ?? ""
        ]
    }
    
    /// 导出追踪数据（Jaeger 格式）
    public func exportTraces() -> [[String: Any]] {
        return spans.values.map { span in
            var dict: [String: Any] = [
                "traceId": span.context.traceId,
                "spanId": span.context.spanId,
                "operationName": span.operationName,
                "startTime": span.startTime.timeIntervalSince1970,
                "tags": span.tags
            ]
            
            if let parentSpanId = span.context.parentSpanId {
                dict["parentSpanId"] = parentSpanId
            }
            
            if let endTime = span.endTime {
                dict["endTime"] = endTime.timeIntervalSince1970
                dict["duration"] = span.duration ?? 0
            }
            
            if !span.logs.isEmpty {
                dict["logs"] = span.logs.map { ["timestamp": $0.0.timeIntervalSince1970, "message": $0.1] }
            }
            
            return dict
        }
    }
}

// MARK: - 支持追踪的请求

open class KKTracedRequest: KKBaseRequest {
    
    private var traceContext: KKTraceContext?
    
    @discardableResult
    public override func start(success: ((KKBaseRequest) -> Void)? = nil,
                              failure: ((KKBaseRequest) -> Void)? = nil) -> Self {
        
        // 开始追踪
        traceContext = KKRequestTracing.shared.startTrace(operationName: requestPath())
        
        if let context = traceContext {
            KKRequestTracing.shared.addTag(context: context, key: "http.method", value: requestMethod().rawValue)
            KKRequestTracing.shared.addTag(context: context, key: "http.url", value: requestPath())
        }
        
        return super.start(
            success: { [weak self] request in
                if let context = self?.traceContext {
                    KKRequestTracing.shared.addTag(context: context, key: "http.status", value: "success")
                    KKRequestTracing.shared.endTrace(context: context)
                }
                success?(request)
            },
            failure: { [weak self] request in
                if let context = self?.traceContext {
                    KKRequestTracing.shared.addTag(context: context, key: "http.status", value: "failure")
                    KKRequestTracing.shared.addTag(context: context, key: "error", value: request.error?.localizedDescription ?? "unknown")
                    KKRequestTracing.shared.endTrace(context: context)
                }
                failure?(request)
            }
        )
    }
}
