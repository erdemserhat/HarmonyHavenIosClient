import SwiftUI

/// Factory class to create screens
struct AppScreenFactory {
    // Authentication screens
    static func makeLoginScreen() -> some View {
        LoginView()
    }
    
    static func makeRegisterScreen() -> some View {
        RegisterView()
    }
    
    // Main screens
    static func makeHomeScreen() -> some View {
        HomeView()
    }
    
    static func makeAllArticlesScreen() -> some View {
        ArticlesListView()
    }
    
    static func makeArticleDetailScreen(article: Article) -> some View {
        ArticleDetailView(article: article)
    }
    
    static func makeCategoryArticlesScreen(categoryId: Int, categoryName: String) -> some View {
        CategoryArticlesView(categoryId: categoryId, categoryName: categoryName)
    }
    
    static func makeProfileScreen() -> some View {
        ProfileView()
    }
    
    static func makeNotificationsScreen() -> some View {
        NotificationView()
    }
} 