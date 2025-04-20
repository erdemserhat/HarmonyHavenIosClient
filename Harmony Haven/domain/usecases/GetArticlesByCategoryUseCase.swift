import Foundation

protocol GetArticlesByCategoryUseCase {
    func execute(categoryId: Int, completion: @escaping (Result<[Article], NetworkError>) -> Void)
}

class GetArticlesByCategoryUseCaseImpl: GetArticlesByCategoryUseCase {
    private let repository: ArticleRepository
    
    init(repository: ArticleRepository = ArticleRepositoryImpl()) {
        self.repository = repository
    }
    
    func execute(categoryId: Int, completion: @escaping (Result<[Article], NetworkError>) -> Void) {
        repository.getArticlesByCategory(categoryId: categoryId, completion: completion)
    }
} 