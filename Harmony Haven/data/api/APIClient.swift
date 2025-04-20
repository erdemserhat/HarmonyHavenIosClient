import Foundation

enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
}

class APIClient {
    let baseURL = URL(string: "https://harmonyhavenappserver.erdemserhat.com/")!
    private let logger = NetworkLogger.shared
    
    func request(
        endpoint: String,
        method: HTTPMethod = .get,
        parameters: [String: Any]? = nil,
        completion: @escaping (Result<Data, NetworkError>) -> Void
    ) {
        // Check for internet connectivity
        guard NetworkMonitor.shared.isConnected else {
            logger.log(.error, message: "No internet connection")
            completion(.failure(.connectionError))
            return
        }
        
        var url = baseURL.appendingPathComponent(endpoint)
        
        // For GET requests with parameters, add them as query items
        if method == .get, let parameters = parameters {
            var components = URLComponents(url: url, resolvingAgainstBaseURL: true)!
            components.queryItems = parameters.map { URLQueryItem(name: $0.key, value: "\($0.value)") }
            url = components.url ?? url
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        
        // For non-GET requests with parameters, add them to the request body
        if method != .get, let parameters = parameters {
            do {
                request.httpBody = try JSONSerialization.data(withJSONObject: parameters)
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            } catch {
                logger.log(.error, message: "Failed to serialize request body: \(error.localizedDescription)")
                completion(.failure(.requestFailed(error)))
                return
            }
        }
        
        // Log the request
        logger.logRequest(request)
        
        let task = URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }
            
            // Log the response
            self.logger.logResponse(response as? HTTPURLResponse, data: data, error: error)
            
            if let error = error {
                let networkError = NetworkError.mapError(error)
                self.logger.log(.error, message: "Network request failed: \(networkError.errorDescription)")
                completion(.failure(networkError))
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                self.logger.log(.error, message: "Invalid response")
                completion(.failure(.invalidResponse))
                return
            }
            
            switch httpResponse.statusCode {
            case 200...299:
                guard let data = data else {
                    self.logger.log(.error, message: "No data received")
                    completion(.failure(.noData))
                    return
                }
                self.logger.log(.info, message: "Request succeeded")
                completion(.success(data))
            case 401:
                self.logger.log(.error, message: "Unauthorized")
                completion(.failure(.unauthorized))
            case 500...599:
                self.logger.log(.error, message: "Server error: \(httpResponse.statusCode)")
                completion(.failure(.serverError))
            default:
                self.logger.log(.error, message: "HTTP error: \(httpResponse.statusCode)")
                completion(.failure(.httpError(statusCode: httpResponse.statusCode, data: data)))
            }
        }
        
        task.resume()
    }
    
    // Convenience method for backward compatibility
    func fetchData(endpoint: String, completion: @escaping (Result<Data, NetworkError>) -> Void) {
        request(endpoint: endpoint, method: .get, parameters: nil, completion: completion)
    }
} 