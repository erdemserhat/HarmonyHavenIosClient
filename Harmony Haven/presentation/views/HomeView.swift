import SwiftUI

struct HomeView: View {
    @StateObject private var categoryViewModel = CategoryListViewModel()
    @StateObject private var articleViewModel = ArticleListViewModel()
    @State private var selectedCategoryId: Int? = nil
    @State private var selectedCategoryName: String = "All Articles"
    @State private var searchText: String = ""
    @EnvironmentObject private var navigationCoordinator: AppNavigationCoordinator
    
    // Filtered articles based on search text
    private var filteredArticles: [Article] {
        if searchText.isEmpty {
            return articleViewModel.articles
        } else {
            return articleViewModel.articles.filter { article in
                article.title.localizedCaseInsensitiveContains(searchText) ||
                article.contentPreview.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                
                TextField("Search articles", text: $searchText)
                    .font(.system(size: 16, design: .rounded))
                
                if !searchText.isEmpty {
                    Button(action: {
                        searchText = ""
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding(10)
            .background(Color(.systemGray6))
            .cornerRadius(12)
            .padding(.horizontal)
            .padding(.top, 12)
            .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
            
            // Categories horizontal scrollable row
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("Categories")
                        .font(.system(.headline, design: .rounded))
                        .fontWeight(.semibold)
                    
                    if categoryViewModel.isLoading {
                        ProgressView()
                            .scaleEffect(0.7)
                            .padding(.leading, 4)
                    }
                    
                    Spacer()
                    
                    if let _ = categoryViewModel.error {
                        Button(action: {
                            categoryViewModel.refreshCategories()
                        }) {
                            Image(systemName: "arrow.clockwise")
                                .foregroundColor(.red)
                        }
                        .padding(.trailing, 4)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 8)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        // "All" category option
                        CategoryChip(
                            name: "All",
                            isSelected: selectedCategoryId == nil,
                            action: {
                                selectedCategoryId = nil
                                selectedCategoryName = "All Articles"
                                articleViewModel.filterByCategory(categoryId: nil)
                            }
                        )
                        
                        // Category chips
                        if categoryViewModel.error != nil {
                            Text("Failed to load categories")
                                .font(.caption)
                                .foregroundColor(.red)
                                .padding(.horizontal)
                        } else {
                            ForEach(categoryViewModel.categories, id: \.id) { category in
                                CategoryChip(
                                    name: category.name,
                                    isSelected: selectedCategoryId == category.id,
                                    action: {
                                        selectedCategoryId = category.id
                                        selectedCategoryName = category.name
                                        articleViewModel.filterByCategory(categoryId: category.id)
                                    }
                                )
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 8)
                }
            }
            .padding(.vertical, 8)
            .background(Color(.systemBackground))
            .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 2)
            
            // Articles list - using GeometryReader to ensure it fills available space
            GeometryReader { geometry in
                ZStack {
                    // Background to ensure the ZStack fills the space
                    Color(.systemBackground)
                        .edgesIgnoringSafeArea(.bottom)
                    
                    if articleViewModel.isLoading {
                        ProgressView()
                            .scaleEffect(1.5)
                            .frame(width: geometry.size.width, height: geometry.size.height)
                    } else if let _ = articleViewModel.error {
                        VStack(spacing: 16) {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.system(size: 50))
                                .foregroundColor(.orange)
                            
                            Text("Could not load articles")
                                .font(.system(.headline, design: .rounded))
                                .fontWeight(.semibold)
                            
                            Text("There was a problem loading the articles. Please try again.")
                                .font(.system(.subheadline, design: .rounded))
                                .multilineTextAlignment(.center)
                                .foregroundColor(.secondary)
                                .padding(.horizontal)
                            
                            Button(action: {
                                articleViewModel.refreshAllData()
                                if let categoryId = selectedCategoryId {
                                    articleViewModel.filterByCategory(categoryId: categoryId)
                                }
                            }) {
                                HStack {
                                    Image(systemName: "arrow.clockwise")
                                    Text("Try Again")
                                }
                                .padding(.horizontal, 20)
                                .padding(.vertical, 12)
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        .padding()
                        .frame(width: geometry.size.width, height: geometry.size.height)
                    } else if articleViewModel.articles.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "newspaper")
                                .font(.system(size: 50))
                                .foregroundColor(.gray)
                            
                            Text("No articles found")
                                .font(.system(.headline, design: .rounded))
                                .fontWeight(.semibold)
                            
                            Text("There are no articles in this category yet.")
                                .font(.system(.subheadline, design: .rounded))
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                        .frame(width: geometry.size.width, height: geometry.size.height)
                    } else if !searchText.isEmpty && filteredArticles.isEmpty {
                        // No search results
                        VStack(spacing: 16) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 50))
                                .foregroundColor(.gray)
                            
                            Text("No matching articles")
                                .font(.system(.headline, design: .rounded))
                                .fontWeight(.semibold)
                            
                            Text("Try a different search term")
                                .font(.system(.subheadline, design: .rounded))
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                        .frame(width: geometry.size.width, height: geometry.size.height)
                    } else {
                        // Use the full available space for the list
                        ScrollView {
                            LazyVStack(spacing: 16) {
                                ForEach(filteredArticles, id: \.id) { article in
                                    Button(action: {
                                        navigationCoordinator.navigateTo(.articleDetail(article))
                                    }) {
                                        // Updated article card with iOS-like design
                                        VStack(alignment: .leading, spacing: 10) {
                                            // Article image with 2:1 aspect ratio
                                            ZStack {
                                                if let imageURL = article.imageURL {
                                                    AsyncImage(url: imageURL) { phase in
                                                        switch phase {
                                                        case .empty:
                                                            Rectangle()
                                                                .fill(Color.gray.opacity(0.2))
                                                                .overlay(
                                                                    ProgressView()
                                                                        .scaleEffect(0.7)
                                                                )
                                                        case .success(let image):
                                                            image
                                                                .resizable()
                                                                .aspectRatio(contentMode: .fill)
                                                        case .failure:
                                                            Rectangle()
                                                                .fill(Color.gray.opacity(0.2))
                                                                .overlay(
                                                                    Image(systemName: "photo")
                                                                        .foregroundColor(.gray)
                                                                )
                                                        @unknown default:
                                                            EmptyView()
                                                        }
                                                    }
                                                } else {
                                                    Rectangle()
                                                        .fill(Color.gray.opacity(0.2))
                                                        .overlay(
                                                            Image(systemName: "photo")
                                                                .foregroundColor(.gray)
                                                        )
                                                }
                                            }
                                            .aspectRatio(2, contentMode: .fit) // 2:1 aspect ratio
                                            .cornerRadius(12)
                                            .clipped()
                                            
                                            VStack(alignment: .leading, spacing: 6) {
                                                // Article title
                                                Text(article.title)
                                                    .font(.system(.headline, design: .rounded))
                                                    .fontWeight(.semibold)
                                                    .lineLimit(2)
                                                    .foregroundColor(.primary)
                                                
                                                // Article content preview
                                                Text(article.contentPreview)
                                                    .font(.system(.subheadline, design: .rounded))
                                                    .foregroundColor(.secondary)
                                                    .lineLimit(3)
                                                
                                                // Date and category info
                                                HStack {
                                                    Image(systemName: "calendar")
                                                        .font(.caption)
                                                        .foregroundColor(.gray)
                                                    
                                                    Text(article.formattedPublishDate)
                                                        .font(.system(.caption, design: .rounded))
                                                        .foregroundColor(.gray)
                                                    
                                                    Spacer()
                                                    
                                                    if let category = categoryViewModel.categories.first(where: { $0.id == article.categoryId }) {
                                                        Text(category.name)
                                                            .font(.system(.caption, design: .rounded))
                                                            .padding(.horizontal, 8)
                                                            .padding(.vertical, 4)
                                                            .background(Color.blue.opacity(0.1))
                                                            .foregroundColor(.blue)
                                                            .cornerRadius(8)
                                                    }
                                                }
                                            }
                                            .padding(.horizontal, 4)
                                        }
                                        .padding(12)
                                        .background(Color(.systemBackground))
                                        .cornerRadius(16)
                                        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                                        .padding(.horizontal)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                            .padding(.vertical, 12)
                        }
                        .refreshable {
                            await refreshData()
                        }
                    }
                }
            }
        }
        .navigationTitle(selectedCategoryName)
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            loadData()
        }
    }
    
    private func loadData() {
        categoryViewModel.loadCategories()
        articleViewModel.loadArticles()
    }
    
    private func refreshData() async {
        articleViewModel.refreshAllData()
        categoryViewModel.refreshCategories()
        if let categoryId = selectedCategoryId {
            articleViewModel.filterByCategory(categoryId: categoryId)
        }
    }
}

// Enhanced CategoryChip with more iOS-like design
struct CategoryChip: View {
    let name: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(name)
                .font(.system(.subheadline, design: .rounded))
                .fontWeight(isSelected ? .semibold : .regular)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.blue : Color(.systemGray6))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(20)
                .shadow(color: isSelected ? Color.blue.opacity(0.3) : Color.clear, radius: 3, x: 0, y: 2)
                .animation(.easeInOut(duration: 0.2), value: isSelected)
        }
        .buttonStyle(PlainButtonStyle())
    }
} 