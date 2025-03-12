import Foundation

protocol GetArticlesUseCase {
    func execute(completion: @escaping (Result<[Article], NetworkError>) -> Void)
}

class GetArticlesUseCaseImpl: GetArticlesUseCase {
    private let repository: ArticleRepository
    
    init(repository: ArticleRepository = ArticleRepositoryImpl()) {
        self.repository = repository
        
    }
    
    func execute(completion: @escaping (Result<[Article], NetworkError>) -> Void) {
        repository.getArticles(completion: completion)
    }
} 
