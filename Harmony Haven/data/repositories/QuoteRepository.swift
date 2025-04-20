import Foundation

protocol QuoteRepositoryProtocol {
    func fetchQuotes(categories: [Int], page: Int, pageSize: Int, seed: Int, completion: @escaping (Result<(quotes: [Quote], totalPages: Int, currentPage: Int), Error>) -> Void)
}

class QuoteRepository: QuoteRepositoryProtocol {
    private let quoteService: QuoteService
    
    init(quoteService: QuoteService = QuoteService()) {
        self.quoteService = quoteService
    }
    
    func fetchQuotes(categories: [Int] = [21], page: Int = 1, pageSize: Int = 100, seed: Int, completion: @escaping (Result<(quotes: [Quote], totalPages: Int, currentPage: Int), Error>) -> Void) {
        quoteService.fetchQuotes(categories: categories, page: page, pageSize: pageSize, seed: seed) { result in
            switch result {
            case .success(let response):
                let quotes = QuoteMapper.mapToDomain(dtos: response.quotes)
                completion(.success((quotes: quotes, totalPages: response.totalPages, currentPage: response.currentPage)))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}


protocol PersonDetails {
    var name:String { get set }
}
