import SwiftUI

// MARK: - Screen Identifiers
/// Enum to identify all screens in the app
enum AppScreen: Hashable {
    case login
    case register
    case home
    case articlesList
    case articleDetail(Article)
    case categoryArticles(categoryId: Int, categoryName: String)
    case profile
    case notifications
    case quotes
    
    // MARK: - Hashable Implementation
    func hash(into hasher: inout Hasher) {
        switch self {
        case .login:
            hasher.combine(-2)
        case .register:
            hasher.combine(-1)
        case .home:
            hasher.combine(0)
        case .articlesList:
            hasher.combine(1)
        case .articleDetail(let article):
            hasher.combine(2)
            hasher.combine(article.id)
        case .categoryArticles(let categoryId, _):
            hasher.combine(3)
            hasher.combine(categoryId)
        case .profile:
            hasher.combine(4)
        case .notifications:
            hasher.combine(5)
        case .quotes:
            hasher.combine(6)
        }
    }
    
    // MARK: - Equatable Implementation
    static func == (lhs: AppScreen, rhs: AppScreen) -> Bool {
        switch (lhs, rhs) {
        case (.login, .login):
            return true
        case (.register, .register):
            return true
        case (.home, .home):
            return true
        case (.articlesList, .articlesList):
            return true
        case (.articleDetail(let lhsArticle), .articleDetail(let rhsArticle)):
            return lhsArticle.id == rhsArticle.id
        case (.categoryArticles(let lhsCategoryId, _), .categoryArticles(let rhsCategoryId, _)):
            return lhsCategoryId == rhsCategoryId
        case (.profile, .profile):
            return true
        case (.notifications, .notifications):
            return true
        case (.quotes, .quotes):
            return true
        default:
            return false
        }
    }
    
    var title: String {
        switch self {
        case .login:
            return "Login"
        case .register:
            return "Register"
        case .home:
            return "Home"
        case .articlesList:
            return "All Articles"
        case .articleDetail:
            return "Article"
        case .categoryArticles(_, let categoryName):
            return categoryName
        case .profile:
            return "Profile"
        case .notifications:
            return "Notifications"
        case .quotes:
            return "Quotes"
        }
    }
    
    var iconName: String {
        switch self {
        case .login:
            return "person.crop.circle"
        case .register:
            return "person.badge.plus"
        case .home:
            return "house"
        case .articlesList:
            return "newspaper"
        case .articleDetail:
            return "doc.text"
        case .categoryArticles:
            return "folder"
        case .profile:
            return "person"
        case .notifications:
            return "bell"
        case .quotes:
            return "quote.bubble"
        }
    }
}

// MARK: - Navigation Coordinator
/// Coordinator to manage navigation throughout the app
class AppNavigationCoordinator: ObservableObject {
    @Published var path = NavigationPath()
    
    // Navigate to a specific screen
    func navigateTo(_ screen: AppScreen) {
        path.append(screen)
    }
    
    // Go back one screen
    func goBack() {
        if !path.isEmpty {
            path.removeLast()
        }
    }
    
    // Go back to root
    func goToRoot() {
        path = NavigationPath()
    }
}

// MARK: - Navigation View Modifier
/// View modifier to apply consistent navigation styling
struct AppNavigationStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .navigationViewStyle(StackNavigationViewStyle())
            .navigationBarTitleDisplayMode(.large)
    }
}

extension View {
    func withAppNavigation() -> some View {
        self.modifier(AppNavigationStyle())
    }
} 