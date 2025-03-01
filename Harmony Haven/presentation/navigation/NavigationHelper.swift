import SwiftUI

// MARK: - Navigation Helper
/// Helper extension to make navigation easier throughout the app
extension View {
    /// Navigate to article detail screen
    func navigateToArticleDetail(article: Article, coordinator: AppNavigationCoordinator) -> some View {
        self.onTapGesture {
            coordinator.navigateTo(.articleDetail(article))
        }
    }
    
    /// Navigate to category articles screen
    func navigateToCategoryArticles(categoryId: Int, categoryName: String, coordinator: AppNavigationCoordinator) -> some View {
        self.onTapGesture {
            coordinator.navigateTo(.categoryArticles(categoryId: categoryId, categoryName: categoryName))
        }
    }
    
    /// Apply standard navigation bar styling
    func withStandardNavigation(title: String) -> some View {
        self.navigationTitle(title)
            .navigationBarTitleDisplayMode(.large)
    }
    
    /// Apply detail screen navigation bar styling
    func withDetailNavigation(title: String) -> some View {
        self.navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Screen Factory
/// Factory to create screens with proper navigation
struct ScreenFactory {
    static func makeArticleDetailScreen(article: Article) -> some View {
        ArticleDetailView(article: article)
            .withDetailNavigation(title: "Article")
    }
    
    static func makeCategoryArticlesScreen(categoryId: Int, categoryName: String) -> some View {
        ArticleListView(viewModel: ArticleListViewModel(), categoryId: categoryId)
            .withStandardNavigation(title: categoryName)
    }
    
    static func makeHomeScreen() -> some View {
        HomeView()
            .withStandardNavigation(title: "Home")
    }
    
    static func makeAllArticlesScreen() -> some View {
        ArticleListView(viewModel: ArticleListViewModel())
            .withStandardNavigation(title: "All Articles")
    }
    
    static func makeProfileScreen() -> some View {
        Text("Profile Coming Soon")
            .font(.title)
            .foregroundColor(.gray)
            .withStandardNavigation(title: "Profile")
    }
} 