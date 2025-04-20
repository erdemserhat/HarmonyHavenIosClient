import Foundation

enum LogLevel {
    case debug
    case info
    case warning
    case error
    
    var prefix: String {
        switch self {
        case .debug: return "🔍 DEBUG"
        case .info: return "ℹ️ INFO"
        case .warning: return "⚠️ WARNING"
        case .error: return "❌ ERROR"
        }
    }
}

class NetworkLogger {
    static let shared = NetworkLogger()
    
    private init() {}
    
    #if DEBUG
    var isEnabled = true
    #else
    var isEnabled = false
    #endif
    
    func log(_ level: LogLevel, message: String) {
        guard isEnabled else { return }
        print("\(level.prefix) [\(Date())] - \(message)")
    }
    
    func logRequest(_ request: URLRequest) {
        guard isEnabled else { return }
        
        let method = request.httpMethod ?? "Unknown"
        let url = request.url?.absoluteString ?? "Unknown"
        
        var logMessage = "\n---------- REQUEST ----------\n"
        logMessage += "📤 \(method) \(url)\n"
        
        if let headers = request.allHTTPHeaderFields, !headers.isEmpty {
            logMessage += "HEADERS:\n"
            headers.forEach { logMessage += "\($0.key): \($0.value)\n" }
        }
        
        if let body = request.httpBody, let bodyString = String(data: body, encoding: .utf8) {
            logMessage += "BODY:\n\(bodyString)\n"
        }
        
        logMessage += "---------- END REQUEST ----------"
        log(.info, message: logMessage)
    }
    
    func logResponse(_ response: HTTPURLResponse?, data: Data?, error: Error?) {
        guard isEnabled else { return }
        
        var logMessage = "\n---------- RESPONSE ----------\n"
        
        if let response = response {
            let statusCode = response.statusCode
            let url = response.url?.absoluteString ?? "Unknown"
            logMessage += "📥 [\(statusCode)] \(url)\n"
            
            if let headers = response.allHeaderFields as? [String: Any], !headers.isEmpty {
                logMessage += "HEADERS:\n"
                headers.forEach { logMessage += "\($0.key): \($0.value)\n" }
            }
        }
        
        if let data = data, let dataString = String(data: data, encoding: .utf8) {
            logMessage += "BODY:\n\(dataString)\n"
        }
        
        if let responseError = error {
            logMessage += "ERROR:\n\(responseError.localizedDescription)\n"
        }
        
        logMessage += "---------- END RESPONSE ----------"
        
        if let _ = error {
            log(.error, message: logMessage)
        } else {
            log(.info, message: logMessage)
        }
    }
} 