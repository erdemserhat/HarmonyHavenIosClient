import Foundation

class RetryManager {
    private let maxRetries: Int
    private let retryDelay: TimeInterval
    
    init(maxRetries: Int = 3, retryDelay: TimeInterval = 1.0) {
        self.maxRetries = maxRetries
        self.retryDelay = retryDelay
    }
    
    func retry<T>(
        retryCount: Int = 0,
        operation: @escaping (@escaping (Result<T, NetworkError>) -> Void) -> Void,
        completion: @escaping (Result<T, NetworkError>) -> Void
    ) {
        operation { result in
            switch result {
            case .success:
                completion(result)
            case .failure(let error):
                // Only retry for certain types of errors
                let shouldRetry = self.shouldRetry(error: error)
                
                if shouldRetry && retryCount < self.maxRetries {
                    // Wait before retrying
                    DispatchQueue.global().asyncAfter(deadline: .now() + self.retryDelay) {
                        self.retry(
                            retryCount: retryCount + 1,
                            operation: operation,
                            completion: completion
                        )
                    }
                } else {
                    completion(result)
                }
            }
        }
    }
    
    private func shouldRetry(error: NetworkError) -> Bool {
        switch error {
        case .connectionError, .timeoutError, .serverError:
            return true
        default:
            return false
        }
    }
} 