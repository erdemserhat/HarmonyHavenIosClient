import Foundation

class NotificationService {
    private let apiClient: APIClient
    private let retryManager: RetryManager
    private let logger = NotificationLogger.shared
    
    init(apiClient: APIClient = APIClient(), retryManager: RetryManager = RetryManager()) {
        self.apiClient = apiClient
        self.retryManager = retryManager
    }
    
    func fetchNotifications(page: Int = 1, pageSize: Int = 20, completion: @escaping (Result<NotificationsResponse, NetworkError>) -> Void) {
        let parameters = ["page": page, "pageSize": pageSize]
        
        logger.log(.info, message: "Fetching notifications with page: \(page), pageSize: \(pageSize)")
        
        retryManager.retry { callback in
            // Get the auth token from UserDefaults
            let token = UserDefaults.standard.string(forKey: "authToken") ?? ""
            
            // Create a custom request with the authorization header
            var customRequest = URLRequest(url: self.apiClient.baseURL.appendingPathComponent("/api/v1/user/get-notifications"))
            customRequest.httpMethod = "GET"
            customRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            customRequest.setValue("application/json", forHTTPHeaderField: "Accept")
            
            // Add query parameters
            var components = URLComponents(url: customRequest.url!, resolvingAgainstBaseURL: true)!
            components.queryItems = parameters.map { URLQueryItem(name: $0.key, value: "\($0.value)") }
            customRequest.url = components.url
            
            self.logger.log(.info, message: "Making request to: \(customRequest.url?.absoluteString ?? "unknown URL")")
            
            // Make the request
            URLSession.shared.dataTask(with: customRequest) { data, response, error in
                if let error = error {
                    self.logger.log(.error, message: "Network error: \(error.localizedDescription)")
                    callback(.failure(NetworkError.mapError(error)))
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    self.logger.log(.error, message: "Invalid response: not an HTTP response")
                    callback(.failure(.invalidResponse))
                    return
                }
                
                self.logger.log(.info, message: "Received response with status code: \(httpResponse.statusCode)")
                
                // Log response headers for debugging
                let headers = httpResponse.allHeaderFields
                self.logger.log(.info, message: "Response headers: \(headers)")
                
                switch httpResponse.statusCode {
                case 200...299:
                    guard let data = data else {
                        self.logger.log(.error, message: "No data received in response")
                        callback(.failure(.noData))
                        return
                    }
                    
                    // Log the raw response data
                    self.logger.logRawResponse(data: data)
                    
                    // Try to decode with JSONDecoder
                    do {
                        let decoder = JSONDecoder()
                        
                        // First try to decode as an array
                        do {
                            let arrayResponse = try decoder.decode(ArrayNotificationsResponse.self, from: data)
                            self.logger.log(.info, message: "Successfully decoded response as array with \(arrayResponse.notifications.count) notifications")
                            
                            // Log a sample timestamp if available
                            if let firstNotification = arrayResponse.notifications.first {
                                self.logger.log(.info, message: "Sample timestamp: \(firstNotification.timeStamp)")
                                self.logger.logDateParsingAttempt(dateString: firstNotification.timeStamp)
                            }
                            
                            callback(.success(arrayResponse))
                            return
                        } catch {
                            self.logger.log(.info, message: "Response is not a direct array, trying standard format: \(error.localizedDescription)")
                        }
                        
                        // If array decoding fails, try standard format
                        let response = try decoder.decode(StandardNotificationsResponse.self, from: data)
                        self.logger.log(.info, message: "Successfully decoded response with \(response.notifications.count) notifications")
                        
                        // Log a sample timestamp if available
                        if let firstNotification = response.notifications.first {
                            self.logger.log(.info, message: "Sample timestamp: \(firstNotification.timeStamp)")
                            self.logger.logDateParsingAttempt(dateString: firstNotification.timeStamp)
                        }
                        
                        callback(.success(response))
                    } catch {
                        self.logger.log(.error, message: "Failed to decode response: \(error.localizedDescription)")
                        self.logger.logDecodingError(error, data: data)
                        
                        // Try manual parsing as fallback
                        self.tryManualParsing(data: data) { result in
                            switch result {
                            case .success(let response):
                                self.logger.log(.info, message: "Successfully parsed response manually with \(response.notifications.count) notifications")
                                callback(.success(response))
                            case .failure(let error):
                                self.logger.log(.error, message: "Manual parsing also failed: \(error.localizedDescription)")
                                callback(.failure(.decodingFailed(error)))
                            }
                        }
                    }
                case 401:
                    self.logger.log(.error, message: "Unauthorized: Invalid or expired token")
                    callback(.failure(.unauthorized))
                case 500...599:
                    self.logger.log(.error, message: "Server error with status code: \(httpResponse.statusCode)")
                    callback(.failure(.serverError))
                default:
                    self.logger.log(.error, message: "HTTP error with status code: \(httpResponse.statusCode)")
                    callback(.failure(.httpError(statusCode: httpResponse.statusCode, data: data)))
                }
            }.resume()
        } completion: { result in
            completion(result)
        }
    }
    
    // Manual parsing as a fallback when JSONDecoder fails
    private func tryManualParsing(data: Data, completion: @escaping (Result<NotificationsResponse, Error>) -> Void) {
        logger.log(.info, message: "Attempting manual parsing of response")
        
        do {
            // First try to parse as a JSON array
            if let jsonArray = try? JSONSerialization.jsonObject(with: data, options: []) as? [[String: Any]] {
                logger.log(.info, message: "Successfully parsed raw JSON as array with \(jsonArray.count) items")
                
                // Convert the array of dictionaries to NotificationDTO objects
                var notifications: [NotificationDTO] = []
                
                for notificationDict in jsonArray {
                    do {
                        // Convert dictionary to JSON data
                        let notificationData = try JSONSerialization.data(withJSONObject: notificationDict, options: [])
                        
                        // Try to decode as NotificationDTO
                        let notification = try JSONDecoder().decode(NotificationDTO.self, from: notificationData)
                        notifications.append(notification)
                    } catch {
                        logger.log(.warning, message: "Failed to parse individual notification: \(error.localizedDescription)")
                        // Continue with next notification
                    }
                }
                
                // Create an ArrayNotificationsResponse
                let response = ArrayNotificationsResponse(
                    notifications: notifications,
                    totalPages: 1,
                    currentPage: 1,
                    pageSize: 20
                )
                
                completion(.success(response))
                return
            }
            
            // If not an array, try to parse as JSON dictionary
            guard let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
                logger.log(.error, message: "Failed to parse response as JSON dictionary")
                throw NSError(domain: "NotificationService", code: 1001, userInfo: [NSLocalizedDescriptionKey: "Invalid JSON format"])
            }
            
            logger.log(.info, message: "Successfully parsed raw JSON, keys: \(json.keys.joined(separator: ", "))")
            
            // Try to find notifications array in various possible locations
            var notificationsArray: [[String: Any]] = []
            var totalPages = 1
            var currentPage = 1
            var pageSize = 20
            
            // Check for notifications directly
            if let notifications = json["notifications"] as? [[String: Any]] {
                notificationsArray = notifications
                logger.log(.info, message: "Found notifications array directly")
            }
            // Check for data key
            else if let data = json["data"] as? [[String: Any]] {
                notificationsArray = data
                logger.log(.info, message: "Found notifications in data key")
            }
            // Check for items key
            else if let items = json["items"] as? [[String: Any]] {
                notificationsArray = items
                logger.log(.info, message: "Found notifications in items key")
            }
            // Check for content key
            else if let content = json["content"] as? [[String: Any]] {
                notificationsArray = content
                logger.log(.info, message: "Found notifications in content key")
            }
            // Check for results key
            else if let results = json["results"] as? [[String: Any]] {
                notificationsArray = results
                logger.log(.info, message: "Found notifications in results key")
            }
            // Check for nested data structure
            else if let notificationsDict = json["notifications"] as? [String: Any],
                    let data = notificationsDict["data"] as? [[String: Any]] {
                notificationsArray = data
                logger.log(.info, message: "Found notifications in nested data structure")
            }
            // If the entire response is an array
            else if let entireArray = try? JSONSerialization.jsonObject(with: data, options: []) as? [[String: Any]] {
                notificationsArray = entireArray
                logger.log(.info, message: "Entire response is an array of notifications")
            }
            
            // Try to find pagination info
            if let pagination = json["pagination"] as? [String: Any] {
                totalPages = pagination["totalPages"] as? Int ?? pagination["total_pages"] as? Int ?? pagination["pages"] as? Int ?? 1
                currentPage = pagination["currentPage"] as? Int ?? pagination["current_page"] as? Int ?? pagination["page"] as? Int ?? 1
                pageSize = pagination["pageSize"] as? Int ?? pagination["page_size"] as? Int ?? pagination["size"] as? Int ?? 20
                logger.log(.info, message: "Found pagination in pagination key")
            }
            else if let meta = json["meta"] as? [String: Any] {
                totalPages = meta["totalPages"] as? Int ?? meta["total_pages"] as? Int ?? meta["pages"] as? Int ?? 1
                currentPage = meta["currentPage"] as? Int ?? meta["current_page"] as? Int ?? meta["page"] as? Int ?? 1
                pageSize = meta["pageSize"] as? Int ?? meta["page_size"] as? Int ?? meta["size"] as? Int ?? 20
                logger.log(.info, message: "Found pagination in meta key")
            }
            else {
                // Try to find pagination directly in the main object
                totalPages = json["totalPages"] as? Int ?? json["total_pages"] as? Int ?? json["pages"] as? Int ?? 1
                currentPage = json["currentPage"] as? Int ?? json["current_page"] as? Int ?? json["page"] as? Int ?? 1
                pageSize = json["pageSize"] as? Int ?? json["page_size"] as? Int ?? json["size"] as? Int ?? 20
                logger.log(.info, message: "Found pagination directly in main object")
            }
            
            // Convert the array of dictionaries to NotificationDTO objects
            var notifications: [NotificationDTO] = []
            
            for notificationDict in notificationsArray {
                do {
                    // Convert dictionary to JSON data
                    let notificationData = try JSONSerialization.data(withJSONObject: notificationDict, options: [])
                    
                    // Try to decode as NotificationDTO
                    let notification = try JSONDecoder().decode(NotificationDTO.self, from: notificationData)
                    notifications.append(notification)
                } catch {
                    logger.log(.warning, message: "Failed to parse individual notification: \(error.localizedDescription)")
                    // Continue with next notification
                }
            }
            
            // Create a ManualNotificationsResponse object
            let response = ManualNotificationsResponse(
                notifications: notifications,
                totalPages: totalPages,
                currentPage: currentPage,
                pageSize: pageSize
            )
            
            completion(.success(response))
        } catch {
            logger.log(.error, message: "Manual parsing failed: \(error.localizedDescription)")
            completion(.failure(error))
        }
    }
}

// Helper struct for manual parsing
struct ManualNotificationsResponse: NotificationsResponse, Codable {
    let notifications: [NotificationDTO]
    let totalPages: Int
    let currentPage: Int
    let pageSize: Int
} 