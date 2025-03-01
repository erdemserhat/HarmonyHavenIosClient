import Foundation

struct ArticleCategory {
    let id: Int
    let name: String
    let imagePath: String
    
    // Computed property to get the full image URL
    var imageURL: URL? {
        URL(string: imagePath)
    }
} 