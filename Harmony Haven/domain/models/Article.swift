import Foundation

struct Article {
    let id: Int
    let title: String
    let slug: String
    let content: String
    let contentPreview: String
    let publishDate: Date
    let categoryId: Int
    let imagePath: String
    
    // Computed property to get the full image URL
    var imageURL: URL? {
        URL(string: imagePath)
    }
    
    // Computed property to format the publish date
    var formattedPublishDate: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        return dateFormatter.string(from: publishDate)
    }
} 