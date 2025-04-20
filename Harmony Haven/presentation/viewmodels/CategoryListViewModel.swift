import Foundation
import Combine

class CategoryListViewModel: ObservableObject {
    @Published var categories: [ArticleCategory] = []
    @Published var isLoading = false
    @Published var error: NetworkError?
    
    private let getCategoriesUseCase: GetCategoriesUseCase
    private var categoriesCache: [ArticleCategory] = []
    private var hasLoadedCategories = false
    
    init(getCategoriesUseCase: GetCategoriesUseCase = GetCategoriesUseCaseImpl()) {
        self.getCategoriesUseCase = getCategoriesUseCase
    }
    
    func loadCategories(forceRefresh: Bool = false) {
        // If categories are already cached and not forcing refresh, use cached data
        if !categoriesCache.isEmpty && !forceRefresh {
            self.categories = categoriesCache
            return
        }
        
        isLoading = true
        error = nil
        
        getCategoriesUseCase.execute { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                switch result {
                case .success(let categories):
                    self?.categories = categories
                    // Cache the categories
                    self?.categoriesCache = categories
                    self?.hasLoadedCategories = true
                case .failure(let error):
                    self?.error = error
                }
            }
        }
    }
    
    // Method to force refresh categories
    func refreshCategories() {
        loadCategories(forceRefresh: true)
    }
} 