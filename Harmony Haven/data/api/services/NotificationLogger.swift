import Foundation

class NotificationLogger {
    static let shared = NotificationLogger()
    
    private init() {}
    
    #if DEBUG
    var isEnabled = true
    #else
    var isEnabled = false
    #endif
    
    func log(_ level: LogLevel, message: String) {
        guard isEnabled else { return }
        print("\(level.prefix) [NotificationLogger] [\(Date())] - \(message)")
    }
    
    func logRawResponse(data: Data?) {
        guard isEnabled, let data = data else { return }
        
        var logMessage = "\n---------- NOTIFICATION RAW RESPONSE ----------\n"
        
        // Log the raw data as a string
        if let dataString = String(data: data, encoding: .utf8) {
            logMessage += "Raw JSON:\n\(dataString)\n"
        } else {
            logMessage += "Could not convert data to UTF-8 string\n"
        }
        
        // Try to parse as JSON and pretty print
        do {
            // First try to parse as JSON array
            if let jsonArray = try? JSONSerialization.jsonObject(with: data, options: []) as? [[String: Any]] {
                let prettyData = try JSONSerialization.data(withJSONObject: jsonArray, options: .prettyPrinted)
                if let prettyString = String(data: prettyData, encoding: .utf8) {
                    logMessage += "\nPretty JSON (Array):\n\(prettyString)\n"
                }
                
                // Analyze and log the structure of the first item if available
                if let firstItem = jsonArray.first {
                    logMessage += "\nJSON Array Structure Analysis (first item):\n"
                    logMessage += analyzeJsonStructure(firstItem, level: 0)
                }
            }
            // Then try as JSON dictionary
            else if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                let prettyData = try JSONSerialization.data(withJSONObject: json, options: .prettyPrinted)
                if let prettyString = String(data: prettyData, encoding: .utf8) {
                    logMessage += "\nPretty JSON:\n\(prettyString)\n"
                }
                
                // Analyze and log the structure
                logMessage += "\nJSON Structure Analysis:\n"
                logMessage += analyzeJsonStructure(json, level: 0)
            }
        } catch {
            logMessage += "\nError parsing JSON: \(error.localizedDescription)\n"
        }
        
        logMessage += "---------- END NOTIFICATION RAW RESPONSE ----------"
        log(.info, message: logMessage)
    }
    
    private func analyzeJsonStructure(_ json: [String: Any], level: Int) -> String {
        var result = ""
        let indent = String(repeating: "  ", count: level)
        
        for (key, value) in json {
            let valueType = type(of: value)
            
            if let nestedDict = value as? [String: Any] {
                result += "\(indent)- \(key) (Object):\n"
                result += analyzeJsonStructure(nestedDict, level: level + 1)
            } else if let nestedArray = value as? [Any] {
                result += "\(indent)- \(key) (Array[\(nestedArray.count)]):\n"
                
                // If it's an array of dictionaries, analyze the first item
                if let firstDict = nestedArray.first as? [String: Any] {
                    result += "\(indent)  First item structure:\n"
                    result += analyzeJsonStructure(firstDict, level: level + 2)
                } else if let firstItem = nestedArray.first {
                    let firstItemType = type(of: firstItem)
                    result += "\(indent)  Items type: \(firstItemType)\n"
                }
            } else {
                // For simple values, show the type and a preview of the value
                var valuePreview = "\(value)"
                if valuePreview.count > 50 {
                    valuePreview = String(valuePreview.prefix(47)) + "..."
                }
                result += "\(indent)- \(key) (\(valueType)): \(valuePreview)\n"
            }
        }
        
        return result
    }
    
    func logDateParsingAttempt(dateString: String) {
        guard isEnabled else { return }
        
        var logMessage = "\n---------- DATE PARSING ATTEMPT ----------\n"
        logMessage += "Attempting to parse date: \(dateString)\n"
        
        // Try to parse as a timestamp (seconds since 1970)
        if let timestampSeconds = Int(dateString) {
            let date = Date(timeIntervalSince1970: TimeInterval(timestampSeconds))
            logMessage += "✅ Successfully parsed as timestamp (seconds): \(date)\n"
            logMessage += "Unix timestamp value: \(timestampSeconds)\n"
        } else {
            logMessage += "❌ Failed to parse as timestamp (seconds)\n"
        }
        
        // Try different date formats
        let formats = [
            "yyyy-MM-dd'T'HH:mm:ss.SSSZ",
            "yyyy-MM-dd'T'HH:mm:ssZ",
            "yyyy-MM-dd'T'HH:mm:ss",
            "yyyy-MM-dd HH:mm:ss",
            "yyyy/MM/dd HH:mm:ss",
            "MM/dd/yyyy HH:mm:ss",
            "dd-MM-yyyy HH:mm:ss",
            "dd/MM/yyyy HH:mm:ss",
            "yyyy-MM-dd",
            "MM/dd/yyyy",
            "dd-MM-yyyy"
        ]
        
        for format in formats {
            let formatter = DateFormatter()
            formatter.dateFormat = format
            if let date = formatter.date(from: dateString) {
                logMessage += "✅ Successfully parsed with format: \(format)\n"
                logMessage += "Parsed date: \(date)\n"
            } else {
                logMessage += "❌ Failed to parse with format: \(format)\n"
            }
        }
        
        // Try to parse as a timestamp (milliseconds since 1970)
        if let timestampMilliseconds = Double(dateString) {
            let date = Date(timeIntervalSince1970: timestampMilliseconds / 1000.0)
            logMessage += "✅ Successfully parsed as timestamp (milliseconds): \(date)\n"
            logMessage += "Unix timestamp value (ms): \(timestampMilliseconds)\n"
        } else {
            logMessage += "❌ Failed to parse as timestamp (milliseconds)\n"
        }
        
        logMessage += "---------- END DATE PARSING ATTEMPT ----------"
        log(.info, message: logMessage)
    }
    
    func logDecodingError(_ error: Error, data: Data?) {
        guard isEnabled else { return }
        
        var logMessage = "\n---------- NOTIFICATION DECODING ERROR ----------\n"
        logMessage += "Error: \(error.localizedDescription)\n"
        
        if let decodingError = error as? DecodingError {
            switch decodingError {
            case .typeMismatch(let type, let context):
                logMessage += "Type mismatch: \(type)\n"
                logMessage += "Coding path: \(context.codingPath.map { $0.stringValue })\n"
            case .valueNotFound(let type, let context):
                logMessage += "Value not found: \(type)\n"
                logMessage += "Coding path: \(context.codingPath.map { $0.stringValue })\n"
            case .keyNotFound(let key, let context):
                logMessage += "Key not found: \(key.stringValue)\n"
                logMessage += "Coding path: \(context.codingPath.map { $0.stringValue })\n"
            case .dataCorrupted(let context):
                logMessage += "Data corrupted\n"
                logMessage += "Coding path: \(context.codingPath.map { $0.stringValue })\n"
                logMessage += "Debug description: \(context.debugDescription)\n"
            @unknown default:
                logMessage += "Unknown decoding error\n"
            }
        }
        
        // Try to extract partial data
        if let data = data {
            logMessage += "\nRaw data:\n"
            if let dataString = String(data: data, encoding: .utf8) {
                logMessage += dataString
            } else {
                logMessage += "Unable to convert data to string"
            }
            
            // Try to analyze the JSON structure
            do {
                // First try to parse as JSON array
                if let jsonArray = try? JSONSerialization.jsonObject(with: data, options: []) as? [[String: Any]] {
                    logMessage += "\n\nJSON Array Structure Analysis (first item):\n"
                    if let firstItem = jsonArray.first {
                        logMessage += analyzeJsonStructure(firstItem, level: 0)
                    }
                }
                // Then try as JSON dictionary
                else if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                    logMessage += "\n\nJSON Structure Analysis:\n"
                    logMessage += analyzeJsonStructure(json, level: 0)
                }
            } catch {
                logMessage += "\n\nCould not analyze JSON structure: \(error.localizedDescription)"
            }
        }
        
        logMessage += "\n---------- END NOTIFICATION DECODING ERROR ----------"
        log(.error, message: logMessage)
    }
} 