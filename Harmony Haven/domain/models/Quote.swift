import Foundation

struct Quote: Identifiable {
    let id: Int
    let content: String
    let writer: String
    let mediaUrl: String
    let categoryId: Int
    let isLiked: Bool
    let isVideo: Bool
    
    // Computed property to determine if the media is a video
    static func isVideoUrl(_ url: String) -> Bool {
        let lowercasedUrl = url.lowercased()
        return lowercasedUrl.hasSuffix(".mp4") || 
               lowercasedUrl.hasSuffix(".mov") || 
               lowercasedUrl.hasSuffix(".avi") ||
               lowercasedUrl.hasSuffix(".wmv")
    }
} 