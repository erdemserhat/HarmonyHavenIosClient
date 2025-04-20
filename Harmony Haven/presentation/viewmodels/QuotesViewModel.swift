import Foundation
import Combine
import SwiftUI

class QuotesViewModel: ObservableObject {
    // Published properties for UI
    @Published var quotes: [Quote] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String = ""
    @Published var selectedCategoryId: Int = 21
    
    // Pagination properties
    private var currentPage: Int = 1
    private var totalPages: Int = 1
    private(set) var isFetchingNextPage: Bool = false
    private var seed: Int
    
    // Debug properties
    private var lastLoadedQuoteId: Int?
    
    // Dependencies
    private let fetchQuotesUseCase: FetchQuotesUseCaseProtocol
    
    init(fetchQuotesUseCase: FetchQuotesUseCaseProtocol = FetchQuotesUseCase()) {
        self.fetchQuotesUseCase = fetchQuotesUseCase
        self.seed = Int.random(in: 1...100000)
        
        // Load initial quotes
        loadQuotes()
    }
    
    // Load initial quotes
    func loadQuotes() {
        isLoading = true
        errorMessage = ""
        currentPage = 1
        
        print("Loading initial quotes for category \(selectedCategoryId)")
        
        fetchQuotesUseCase.execute(
            categories: [selectedCategoryId],
            page: currentPage,
            pageSize: 100,
            seed: seed
        ) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.isLoading = false
                
                switch result {
                case .success(let data):
                    self.quotes = data.quotes
                    self.totalPages = data.totalPages
                    self.currentPage = data.currentPage
                    print("Loaded initial quotes: \(data.quotes.count), total pages: \(data.totalPages), current page: \(data.currentPage)")
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                    print("Error loading quotes: \(error.localizedDescription)")
                }
            }
        }
    }
    
    // Load next page of quotes
    func loadNextPageIfNeeded(currentQuote: Quote) {
        // If we're already at the last page or already fetching, don't do anything
        guard currentPage < totalPages else {
            print("Already at last page (\(currentPage) of \(totalPages)). Not loading more.")
            return
        }
        
        guard !isFetchingNextPage else {
            print("Already fetching next page. Not starting another request.")
            return
        }
        
        // Check if we've already loaded this quote to prevent duplicate calls
        if let lastId = lastLoadedQuoteId, lastId == currentQuote.id {
            print("Already triggered pagination for quote ID: \(currentQuote.id). Skipping.")
            return
        }
        
        // If we're at the last few items, fetch the next page
        let thresholdIndex = quotes.index(quotes.endIndex, offsetBy: -3, limitedBy: quotes.startIndex) ?? quotes.startIndex
        if let currentIndex = quotes.firstIndex(where: { $0.id == currentQuote.id }) {
            print("Current quote index: \(currentIndex), threshold: \(thresholdIndex)")
            if currentIndex >= thresholdIndex {
                print("Threshold reached. Loading next page...")
                lastLoadedQuoteId = currentQuote.id
                loadNextPage()
            }
        } else {
            // If we can't find the current quote, load the next page anyway as a fallback
            print("Current quote not found in list. Loading next page as fallback...")
            loadNextPage()
        }
    }
    
    // Force load the next page regardless of conditions
    func forceLoadNextPage() {
        print("🔍 Force load next page called. Current page: \(currentPage), Total pages: \(totalPages), isFetching: \(isFetchingNextPage), Current quotes count: \(quotes.count)")
        
        // If we're already at the last page, reset pagination to try again
        if currentPage >= totalPages {
            print("⚠️ Cannot force load: Already at last page (\(currentPage) of \(totalPages))")
            // Reset pagination state to try again
            if !quotes.isEmpty {
                currentPage = max(1, currentPage - 1)
                print("🔄 Reset pagination to page \(currentPage) to try loading again")
            }
        }
        
        if isFetchingNextPage {
            print("⚠️ Already fetching next page. Will try again in 1 second")
            // Try again after a short delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
                self?.forceLoadNextPage()
            }
            return
        }
        
        print("✅ Force loading next page...")
        
        // Ensure we're not at the last page
        if currentPage >= totalPages && totalPages > 0 {
            print("⚠️ Already at last page. Attempting to reset and retry...")
            currentPage = max(1, currentPage - 1)
        }
        
        loadNextPage()
    }
    
    private func loadNextPage() {
        isFetchingNextPage = true
        let nextPage = currentPage + 1
        
        print("📄 Loading page \(nextPage) of \(totalPages) with category ID: \(selectedCategoryId), seed: \(seed)")
        
        fetchQuotesUseCase.execute(
            categories: [selectedCategoryId],
            page: nextPage,
            pageSize: 10,
            seed: seed
        ) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { 
                    print("⚠️ Self was deallocated during quote fetch")
                    return 
                }
                
                self.isFetchingNextPage = false
                
                switch result {
                case .success(let data):
                    let newQuotes = data.quotes
                    print("✅ Loaded \(newQuotes.count) new quotes for page \(data.currentPage)")
                    
                    if newQuotes.isEmpty {
                        print("⚠️ Received empty quotes array for page \(data.currentPage)")
                        self.errorMessage = "No more quotes available"
                        return
                    }
                    
                    // Avoid duplicates by checking IDs
                    let existingIds = Set(self.quotes.map { $0.id })
                    let uniqueNewQuotes = newQuotes.filter { !existingIds.contains($0.id) }
                    
                    if uniqueNewQuotes.count < newQuotes.count {
                        print("⚠️ Filtered out \(newQuotes.count - uniqueNewQuotes.count) duplicate quotes")
                    }
                    
                    if uniqueNewQuotes.isEmpty {
                        print("⚠️ All new quotes were duplicates. Trying to load next page...")
                        // If all quotes were duplicates, try loading the next page
                        self.currentPage = data.currentPage
                        if self.currentPage < data.totalPages {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                self.loadNextPage()
                            }
                        }
                        return
                    }
                    
                    self.quotes.append(contentsOf: uniqueNewQuotes)
                    self.totalPages = data.totalPages
                    self.currentPage = data.currentPage
                    
                    print("📊 Total quotes after append: \(self.quotes.count), Current page: \(self.currentPage), Total pages: \(self.totalPages)")
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                    print("❌ Error loading next page: \(error.localizedDescription)")
                }
            }
        }
    }
    
    // Change category
    func changeCategory(to categoryId: Int) {
        if selectedCategoryId != categoryId {
            print("Changing category from \(selectedCategoryId) to \(categoryId)")
            selectedCategoryId = categoryId
            loadQuotes()
        }
    }
    
    // Refresh quotes with a new seed
    func refreshQuotes() {
        let oldSeed = seed
        seed = Int.random(in: 1...100000)
        print("Refreshing quotes with new seed: \(oldSeed) -> \(seed)")
        loadQuotes()
    }
} 
