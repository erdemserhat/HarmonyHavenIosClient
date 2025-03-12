import SwiftUI

struct MainTabView: View {
    @StateObject private var navigationCoordinator = AppNavigationCoordinator()
    @EnvironmentObject private var authViewModel: AuthenticationViewModel
    
    var body: some View {
        TabView {
            NavigationStack(path: $navigationCoordinator.path) {
                AppScreenFactory.makeHomeScreen()
                    .navigationDestination(for: AppScreen.self) { screen in
                        switch screen {
                        case .login:
                            AppScreenFactory.makeLoginScreen()
                        case .register:
                            AppScreenFactory.makeRegisterScreen()
                        case .articleDetail(let article):
                            AppScreenFactory.makeArticleDetailScreen(article: article)
                        case .categoryArticles(let categoryId, let categoryName):
                            AppScreenFactory.makeCategoryArticlesScreen(categoryId: categoryId, categoryName: categoryName)
                        case .articlesList:
                            AppScreenFactory.makeAllArticlesScreen()
                        case .profile:
                            AppScreenFactory.makeProfileScreen()
                        case .home:
                            AppScreenFactory.makeHomeScreen()
                        case .notifications:
                            AppScreenFactory.makeNotificationsScreen()
                        case .quotes:
                            AppScreenFactory.makeQuotesScreen()
                        }
                    }
            }
            .environmentObject(navigationCoordinator)
            .tabItem {
                Label("Home", systemImage: "house")
            }
            
            // Quotes Tab
            AppScreenFactory.makeQuotesScreen()
                .tabItem {
                    Label("Quotes", systemImage: "quote.bubble")
                }
            
            NavigationStack {
                AppScreenFactory.makeNotificationsScreen()
                    .navigationDestination(for: AppScreen.self) { screen in
                        switch screen {
                        case .articleDetail(let article):
                            AppScreenFactory.makeArticleDetailScreen(article: article)
                        default:
                            EmptyView()
                        }
                    }
            }
            .environmentObject(navigationCoordinator)
            .tabItem {
                Label("Notifications", systemImage: "bell")
            }
            
            NavigationStack {
                ProfileView()
            }
            .tabItem {
                Label("Profile", systemImage: "person")
            }
        }
    }
} 