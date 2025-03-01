import Foundation

class ArticleService {
    private let apiClient: APIClient
    private let retryManager: RetryManager
    
    init(apiClient: APIClient = APIClient(), retryManager: RetryManager = RetryManager()) {
        self.apiClient = apiClient
        self.retryManager = retryManager
    }
    
    func fetchArticles(completion: @escaping (Result<[ArticleDTO], NetworkError>) -> Void) {
        retryManager.retry(operation: { callback in
            self.apiClient.request(endpoint: "/api/v1/articles", method: .get) { result in
                switch result {
                case .success(let data):
                    do {
                        let articles = try JSONDecoder().decode([ArticleDTO].self, from: data)
                        callback(.success(articles))
                    } catch {
                        callback(.failure(.decodingFailed(error)))
                    }
                case .failure(let error):
                    callback(.failure(error))
                }
            }
        }, completion: completion)
    }
    
    func fetchArticlesByCategory(categoryId: Int, completion: @escaping (Result<[ArticleDTO], NetworkError>) -> Void) {
        retryManager.retry(operation: { callback in
            let parameters = ["categoryId": categoryId]
            self.apiClient.request(endpoint: "/api/v1/articles", method: .get, parameters: parameters) { result in
                switch result {
                case .success(let data):
                    do {
                        let articles = try JSONDecoder().decode([ArticleDTO].self, from: data)
                        callback(.success(articles))
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