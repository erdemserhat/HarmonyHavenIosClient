import Foundation

// Request DTO
struct QuotesRequest: Codable {
    let categories: [Int]
    let page: Int
    let pageSize: Int
    let seed: Int
    
    func asDictionary() throws -> [String: Any] {
        let data = try JSONEncoder().encode(self)
        guard let dictionary = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any] else {
            throw NSError(domain: "EncodableExtension", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to convert to dictionary"])
        }
        return dictionary
    }
}

// Response DTO with more flexible decoding
struct QuoteDTO: Codable {
    let id: Int
    let quote: String
    let writer: String?  // Made optional in case it's missing
    let imageUrl: String
    let quoteCategory: Int
    let isLiked: Bool
    
    // Custom coding keys to handle potential different field names
    enum CodingKeys: String, CodingKey {
        case id
        case quote
        case writer
        case imageUrl = "imageUrl"  // Try alternative keys if needed
        case quoteCategory
        case isLiked
    }
    
    // Custom initializer to handle potential missing fields
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Required fields
        id = try container.decode(Int.self, forKey: .id)
        quote = try container.decode(String.self, forKey: .quote)
        imageUrl = try container.decode(String.self, forKey: .imageUrl)
        
        // Optional fields with defaults
        writer = try container.decodeIfPresent(String.self, forKey: .writer)
        quoteCategory = try container.decodeIfPresent(Int.self, forKey: .quoteCategory) ?? 0
        isLiked = try container.decodeIfPresent(Bool.self, forKey: .isLiked) ?? false
    }
    
    var isVideo: Bool {
        let lowercasedUrl = imageUrl.lowercased()
        return lowercasedUrl.hasSuffix(".mp4") || 
               lowercasedUrl.hasSuffix(".mov") || 
               lowercasedUrl.hasSuffix(".avi") ||
               lowercasedUrl.hasSuffix(".wmv")
    }
}

// Response wrapper with more flexible decoding
struct QuotesResponse: Codable {
    let quotes: [QuoteDTO]
    let totalCount: Int
    let currentPage: Int
    let totalPages: Int
    
    // Custom coding keys to handle potential different field names
    enum CodingKeys: String, CodingKey {
        case quotes
        case totalCount
        case currentPage
        case totalPages
        
        // Alternative keys
        case data
        case total
        case page
        case pages
    }
    
    // Custom initializer to handle different response formats
    init(from decoder: Decoder) throws {
        // First, try to decode as an array directly
        if let quotesArray = try? [QuoteDTO].self(from: decoder) {
            // If successful, we have an array response
            self.quotes = quotesArray
            self.totalCount = quotesArray.count
            self.currentPage = 1
            self.totalPages = 1
            return
        }
        
        // If not an array, try to decode as an object with nested properties
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Try to decode quotes using primary key, then fallback to alternative key
        if let quotes = try? container.decode([QuoteDTO].self, forKey: .quotes) {
            self.quotes = quotes
        } else {
            self.quotes = try container.decode([QuoteDTO].self, forKey: .data)
        }
        
        // Try to decode totalCount using primary key, then fallback to alternative key
        if let totalCount = try? container.decode(Int.self, forKey: .totalCount) {
            self.totalCount = totalCount
        } else {
            self.totalCount = try container.decode(Int.self, forKey: .total)
        }
        
        // Try to decode currentPage using primary key, then fallback to alternative key
        if let currentPage = try? container.decode(Int.self, forKey: .currentPage) {
            self.currentPage = currentPage
        } else {
            self.currentPage = try container.decode(Int.self, forKey: .page)
        }
        
        // Try to decode totalPages using primary key, then fallback to alternative key
        if let totalPages = try? container.decode(Int.self, forKey: .totalPages) {
            self.totalPages = totalPages
        } else {
            self.totalPages = try container.decode(Int.self, forKey: .pages)
        }
    }
    
    // Add encode method to satisfy Encodable protocol
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(quotes, forKey: .quotes)
        try container.encode(totalCount, forKey: .totalCount)
        try container.encode(currentPage, forKey: .currentPage)
        try container.encode(totalPages, forKey: .totalPages)
    }
} 