import Foundation

enum NetworkError: Error {
    case invalidURL
    case requestFailed(Error)
    case invalidResponse
    case httpError(statusCode: Int, data: Data?)
    case noData
    case decodingFailed(Error)
    case unauthorized
    case serverError
    case connectionError
    case timeoutError
    case unknown
    
    var errorDescription: String {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .requestFailed(let error):
            return "Request failed: \(error.localizedDescription)"
        case .invalidResponse:
            return "Invalid response from the server"
        case .httpError(let statusCode, _):
            return "HTTP error with status code: \(statusCode)"
        case .noData:
            return "No data received from the server"
        case .decodingFailed(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        case .unauthorized:
            return "Unauthorized access"
        case .serverError:
            return "Server error"
        case .connectionError:
            return "Connection error"
        case .timeoutError:
            return "Request timed out"
        case .unknown:
            return "Unknown error occurred"
        }
    }
    
    static func mapError(_ error: Error) -> NetworkError {
        if let networkError = error as? NetworkError {
            return networkError
        }
        
        let nsError = error as NSError
        switch nsError.code {
        case NSURLErrorTimedOut:
            return .timeoutError
        case NSURLErrorNotConnectedToInternet, NSURLErrorNetworkConnectionLost:
            return .connectionError
        case 401:
            return .unauthorized
        case 500...599:
            return .serverError
        default:
            return .requestFailed(error)
        }
    }
} 