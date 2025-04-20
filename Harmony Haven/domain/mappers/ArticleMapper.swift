import Foundation

class ArticleMapper {
    static func mapToDomain(dto: ArticleDTO) -> Article {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ" // Adjust this format to match your API's date format
        
        // Default to current date if parsing fails
        let publishDate = dateFormatter.date(from: dto.publishDate) ?? Date()
        
        return Article(
            id: dto.id,
            title: dto.title,
            slug: dto.slug,
            content: dto.content,
            contentPreview: dto.contentPreview,
            publishDate: publishDate,
            categoryId: dto.categoryId,
            imagePath: dto.imagePath
        )
    }
    
    static func mapToDomainList(dtoList: [ArticleDTO]) -> [Article] {
        return dtoList.map { mapToDomain(dto: $0) }
    }
} 