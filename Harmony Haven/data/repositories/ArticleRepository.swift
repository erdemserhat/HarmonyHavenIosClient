import Foundation

protocol ArticleRepository {
    func getArticles(completion: @escaping (Result<[Article], NetworkError>) -> Void)
    func getArticlesByCategory(categoryId: Int, completion: @escaping (Result<[Article], NetworkError>) -> Void)
}

class ArticleRepositoryImpl: ArticleRepository {
    private let service: ArticleService
    
    init(service: ArticleService = ArticleService()) {
        self.service = service
    }
    
    func getArticles(completion: @escaping (Result<[Article], NetworkError>) -> Void) {
        service.fetchArticles { result in
            switch result {
            case .success(let dtoList):
                let domainList = ArticleMapper.mapToDomainList(dtoList: dtoList)
                completion(.success(domainList))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func getArticlesByCategory(categoryId: Int, completion: @escaping (Result<[Article], NetworkError>) -> Void) {
        service.fetchArticlesByCategory(categoryId: categoryId) { result in
            switch result {
            case .success(let dtoList):
                let domainList = ArticleMapper.mapToDomainList(dtoList: dtoList)
                completion(.success(domainList))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
} 