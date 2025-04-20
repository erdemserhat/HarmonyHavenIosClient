import Foundation

class ArticleCategoryService {
    private let apiClient: APIClient
    private let retryManager: RetryManager
    
    init(apiClient: APIClient = APIClient(), retryManager: RetryManager = RetryManager()) {
        self.apiClient = apiClient
        self.retryManager = retryManager
    }
    
    func fetchCategories(completion: @escaping (Result<[ArticleCategoryDTO], NetworkError>) -> Void) {
        retryManager.retry(operation: { callback in
            self.apiClient.request(endpoint: "/api/v1/categories", method: .get) { result in
                switch result {
                case .success(let data):
                    do {
                        let categories = try JSONDecoder().decode([ArticleCategoryDTO].self, from: data)
                        callback(.success(categories))
                    } catch {
                        callback(.failure(.decodingFailed(error)))
                    }
                case .failure(let error):
                    callback(.failure(error))
                }
            }
        }, completion: completion)
    }
} 