import Foundation

struct ArticleDTO: Codable {
    let id: Int
    let title: String
    let slug: String
    let content: String
    let contentPreview: String
    let publishDate: String
    let categoryId: Int
    let imagePath: String
} 

