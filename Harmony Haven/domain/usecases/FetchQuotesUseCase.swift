import Foundation

protocol FetchQuotesUseCaseProtocol {
    func execute(categories: [Int], page: Int, pageSize: Int, seed: Int, completion: @escaping (Result<(quotes: [Quote], totalPages: Int, currentPage: Int), Error>) -> Void)
}

class FetchQuotesUseCase: FetchQuotesUseCaseProtocol {
    private let quoteRepository: QuoteRepositoryProtocol
    
    init(quoteRepository: QuoteRepositoryProtocol = QuoteRepository()) {
        self.quoteRepository = quoteRepository
    }
    
    func execute(categories: [Int] = [21], page: Int = 1, pageSize: Int = 10, seed: Int, completion: @escaping (Result<(quotes: [Quote], totalPages: Int, currentPage: Int), Error>) -> Void) {
        quoteRepository.fetchQuotes(categories: categories, page: page, pageSize: pageSize, seed: seed, completion: completion)
    }
}
//
