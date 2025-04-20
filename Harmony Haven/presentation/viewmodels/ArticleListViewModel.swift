import Foundation
import Combine

class ArticleListViewModel: ObservableObject {
    @Published var articles: [Article] = []
    @Published var isLoading = false
    @Published var error: NetworkError?
    
    private let getArticlesUseCase: GetArticlesUseCase
    private let getArticlesByCategoryUseCase: GetArticlesByCategoryUseCase
    
    // Single cache for all articles
    private var allArticlesCache: [Article] = []
    private var hasLoadedArticles = false
    
    init(
        getArticlesUseCase: GetArticlesUseCase = GetArticlesUseCaseImpl(),
        getArticlesByCategoryUseCase: GetArticlesByCategoryUseCase = GetArticlesByCategoryUseCaseImpl()
    ) {
        self.getArticlesUseCase = getArticlesUseCase
        self.getArticlesByCategoryUseCase = getArticlesByCategoryUseCase
    }
    
    func loadArticles(forceRefresh: Bool = false) {
        // If articles are already cached and not forcing refresh, use cached data
        if !allArticlesCache.isEmpty && !forceRefresh {
            self.articles = allArticlesCache
            return
        }
        
        isLoading = true
        error = nil
        
        getArticlesUseCase.execute { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                switch result {
                case .success(let articles):
                    self?.articles = articles
                    // Cache all articles
                    self?.allArticlesCache = articles
                    self?.hasLoadedArticles = true
                case .failure(let error):
                    self?.error = error
                }
            }
        }
    }
    
    func loadArticlesByCategory(categoryId: Int) {
        // If we have all articles cached, filter them locally
        if !allArticlesCache.isEmpty {
            self.articles = allArticlesCache.filter { $0.categoryId == categoryId }
            return
        }
        
        // If we don't have articles cached yet, load all articles first
        if allArticlesCache.isEmpty && !isLoading {
            isLoading = true
            error = nil
            
            getArticlesUseCase.execute { [weak self] result in
                DispatchQueue.main.async {
                    self?.isLoading = false
                    
                    switch result {
                    case .success(let articles):
                        // Cache all articles
                        self?.allArticlesCache = articles
                        self?.hasLoadedArticles = true
                        // Filter and display only the requested category
                        self?.articles = articles.filter { $0.categoryId == categoryId }
                    case .failure(let error):
                        self?.error = error
                    }
                }
            }
        }
    }
    
    // Method to force refresh all data
    func refreshAllData() {
        loadArticles(forceRefresh: true)
    }
    
    // Method to filter articles by category without making a network request
    func filterByCategory(categoryId: Int?) {
        if let categoryId = categoryId {
            self.articles = allArticlesCache.filter { $0.categoryId == categoryId }
        } else {
            // If categoryId is nil, show all articles
            self.articles = allArticlesCache
        }
    }
} 