import Foundation

class QuoteMapper {
    static func mapToDomain(dto: QuoteDTO) -> Quote {
        return Quote(
            id: dto.id,
            content: dto.quote,
            writer: dto.writer ?? "",
            mediaUrl: dto.imageUrl,
            categoryId: dto.quoteCategory,
            isLiked: dto.isLiked,
            isVideo: dto.isVideo
        )
    }
    
    static func mapToDomain(dtos: [QuoteDTO]) -> [Quote] {
        return dtos.map { mapToDomain(dto: $0) }
    }
} 