import Foundation

protocol GetCategoriesUseCase {
    func execute(completion: @escaping (Result<[ArticleCategory], NetworkError>) -> Void)
}

class GetCategoriesUseCaseImpl: GetCategoriesUseCase {
    private let repository: ArticleCategoryRepository
    
    init(repository: ArticleCategoryRepository = ArticleCategoryRepositoryImpl()) {
        self.repository = repository
    }
    
    func execute(completion: @escaping (Result<[ArticleCategory], NetworkError>) -> Void) {
        repository.getCategories(completion: completion)
    }
} 