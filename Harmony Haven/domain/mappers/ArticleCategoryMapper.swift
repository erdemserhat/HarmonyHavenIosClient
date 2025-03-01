import Foundation

class ArticleCategoryMapper {
    static func mapToDomain(dto: ArticleCategoryDTO) -> ArticleCategory {
        return ArticleCategory(
            id: dto.id,
            name: dto.name,
            imagePath: dto.imagePath
        )
    }
    
    static func mapToDomainList(dtoList: [ArticleCategoryDTO]) -> [ArticleCategory] {
        return dtoList.map { mapToDomain(dto: $0) }
    }
} 