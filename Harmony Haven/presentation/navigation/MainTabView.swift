import SwiftUI

struct MainTabView: View {
    @StateObject private var navigationCoordinator = AppNavigationCoordinator()
    @EnvironmentObject private var authViewModel: AuthenticationViewModel
    
    var body: some View {
        //BOTTOM NAVBAR
        TabView {
            //HOME NAVIGATION BAR
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
            
            //QUOTES NAVIGATION BAR
            NavigationStack{
                AppScreenFactory.makeQuotesScreen()
                    
            }.tabItem {
                Label("Quotes", systemImage: "quote.bubble")
            }
        
        
            //NOTIFICATION NAVIGATION BAR
            NavigationStack {
                AppScreenFactory.makeNotificationsScreen()
                    .navigationDestination(for: AppScreen.self) { screen in
                        //FOR NAVIGATING ARTICLES IN THE FUTURE
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
            
            //PROFILE NAVIGATION BAR
            NavigationStack {
                ProfileView()
            }
            .tabItem {
                Label("Profile", systemImage: "person")
            }
            
            
        }
    }
} 
