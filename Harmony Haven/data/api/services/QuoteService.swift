import Foundation

class QuoteService {
    private let apiClient: APIClient
    private let retryManager: RetryManager
    private let logger = NetworkLogger.shared
    
    init(apiClient: APIClient = APIClient(), retryManager: RetryManager = RetryManager()) {
        self.apiClient = apiClient
        self.retryManager = retryManager
    }
    
    func fetchQuotes(categories: [Int] = [21], page: Int = 1, pageSize: Int = 200, seed: Int, completion: @escaping (Result<QuotesResponse, NetworkError>) -> Void) {
        let request = QuotesRequest(categories: categories, page: page, pageSize: pageSize, seed: seed)
        
        // Convert request to dictionary
        guard let requestDict = try? request.asDictionary() else {
            completion(.failure(.requestFailed(NSError(domain: "QuoteService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to serialize request"]))))
            return
        }
        
        logger.log(.info, message: "Fetching quotes with categories: \(categories), page: \(page), pageSize: \(pageSize), seed: \(seed)")
        
        retryManager.retry { callback in
            // Get the auth token from UserDefaults
            let token = UserDefaults.standard.string(forKey: "authToken") ?? ""
            
            // Create a custom request with the authorization header
            var customRequest = URLRequest(url: self.apiClient.baseURL.appendingPathComponent("/api/v3/get-quotes"))
            customRequest.httpMethod = "POST"
            customRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            customRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
            customRequest.setValue("application/json", forHTTPHeaderField: "Accept")
            
            // Add request body
            do {
                customRequest.httpBody = try JSONSerialization.data(withJSONObject: requestDict)
            } catch {
                callback(.failure(.requestFailed(error)))
                return
            }
            
            self.logger.log(.info, message: "Making request to: \(customRequest.url?.absoluteString ?? "unknown URL")")
            
            // Make the request
            URLSession.shared.dataTask(with: customRequest) { data, response, error in
                if let error = error {
                    let networkError = NetworkError.mapError(error)
                    self.logger.log(.error, message: "Network request failed: \(networkError.errorDescription)")
                    callback(.failure(networkError))
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    self.logger.log(.error, message: "Invalid response")
                    callback(.failure(.invalidResponse))
                    return
                }
                
                switch httpResponse.statusCode {
                case 200...299:
                    guard let data = data else {
                        self.logger.log(.error, message: "No data received")
                        callback(.failure(.noData))
                        return
                    }
                    
                    // Log the raw response data for debugging
                    if let jsonString = String(data: data, encoding: .utf8) {
                        self.logger.log(.info, message: "Raw server response: \(jsonString)")
                    } else {
                        self.logger.log(.error, message: "Could not convert response data to string")
                    }
                    
                    // Try to parse as a dictionary to see the structure
                    do {
                        if let jsonDict = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                            self.logger.log(.info, message: "Response structure: \(jsonDict.keys)")
                            
                            // Check if there's a quotes array
                            if let quotes = jsonDict["quotes"] as? [[String: Any]], !quotes.isEmpty {
                                self.logger.log(.info, message: "First quote structure: \(quotes[0].keys)")
                            }
                        }
                    } catch {
                        self.logger.log(.error, message: "Failed to parse response as JSON: \(error.localizedDescription)")
                    }
                    
                    do {
                        let response = try JSONDecoder().decode(QuotesResponse.self, from: data)
                        self.logger.log(.info, message: "Successfully fetched \(response.quotes.count) quotes")
                        callback(.success(response))
                    } catch {
                        self.logger.log(.error, message: "Failed to decode response: \(error.localizedDescription)")
                        
                        // More detailed decoding error information
                        if let decodingError = error as? DecodingError {
                            switch decodingError {
                            case .keyNotFound(let key, let context):
                                self.logger.log(.error, message: "Key '\(key.stringValue)' not found: \(context.debugDescription)")
                            case .typeMismatch(let type, let context):
                                self.logger.log(.error, message: "Type '\(type)' mismatch: \(context.debugDescription)")
                            case .valueNotFound(let type, let context):
                                self.logger.log(.error, message: "Value of type '\(type)' not found: \(context.debugDescription)")
                            case .dataCorrupted(let context):
                                self.logger.log(.error, message: "Data corrupted: \(context.debugDescription)")
                            @unknown default:
                                self.logger.log(.error, message: "Unknown decoding error: \(decodingError)")
                            }
                        }
                        
                        callback(.failure(.decodingFailed(error)))
                    }
                case 401:
                    self.logger.log(.error, message: "Unauthorized")
                    callback(.failure(.unauthorized))
                case 500...599:
                    self.logger.log(.error, message: "Server error: \(httpResponse.statusCode)")
                    callback(.failure(.serverError))
                default:
                    self.logger.log(.error, message: "HTTP error: \(httpResponse.statusCode)")
                    callback(.failure(.httpError(statusCode: httpResponse.statusCode, data: data)))
                }
            }.resume()
        } completion: { result in
            completion(result)
        }
    }
} 
