import Foundation

protocol ArticleCategoryRepository {
    func getCategories(completion: @escaping (Result<[ArticleCategory], NetworkError>) -> Void)
}

class ArticleCategoryRepositoryImpl: ArticleCategoryRepository {
    private let service: ArticleCategoryService
    
    init(service: ArticleCategoryService = ArticleCategoryService()) {
        self.service = service
    }
    
    func getCategories(completion: @escaping (Result<[ArticleCategory], NetworkError>) -> Void) {
        service.fetchCategories { result in
            switch result {
            case .success(let dtoList):
                let domainList = ArticleCategoryMapper.mapToDomainList(dtoList: dtoList)
                completion(.success(domainList))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
} 