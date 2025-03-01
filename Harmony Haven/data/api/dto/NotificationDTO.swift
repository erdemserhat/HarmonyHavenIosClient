import Foundation

struct NotificationDTO: Codable {
    let id: Int
    let title: String
    let content: String
    let timeStamp: String
    let screenCode: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case content
        case timeStamp, timestamp, time, date, createdAt
        case screenCode, screen_code, screenId, screen_id
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Decode ID - try different possible formats
        if let idValue = try? container.decode(Int.self, forKey: .id) {
            id = idValue
        } else if let idString = try? container.decode(String.self, forKey: .id), let idValue = Int(idString) {
            id = idValue
        } else {
            // Generate a random ID as fallback
            NotificationLogger.shared.log(.warning, message: "Could not decode id, using random value")
            id = Int.random(in: 1000...9999)
        }
        
        // Decode title
        if let titleValue = try? container.decode(String.self, forKey: .title) {
            title = titleValue
        } else {
            NotificationLogger.shared.log(.warning, message: "Could not decode title, using default value")
            title = "Notification"
        }
        
        // Decode content
        if let contentValue = try? container.decode(String.self, forKey: .content) {
            content = contentValue
        } else {
            NotificationLogger.shared.log(.warning, message: "Could not decode content, using default value")
            content = "No content available"
        }
        
        // Decode screenCode - try different possible keys
        screenCode = try? container.decodeIfPresent(String.self, forKey: .screenCode) 
            ?? container.decodeIfPresent(String.self, forKey: .screen_code)
            ?? container.decodeIfPresent(String.self, forKey: .screenId)
            ?? container.decodeIfPresent(String.self, forKey: .screen_id)
        
        // Handle timestamp which might come in different formats and keys
        // Try all possible timestamp keys
        let timestampKeys: [CodingKeys] = [.timeStamp, .timestamp, .time, .date, .createdAt]
        var foundTimestamp = false
        var timestampValue = ""
        
        for key in timestampKeys {
            // Try as string
            if let timestampString = try? container.decode(String.self, forKey: key) {
                timestampValue = timestampString
                foundTimestamp = true
                NotificationLogger.shared.log(.info, message: "Found timestamp as string with key: \(key)")
                break
            }
            
            // Try as number (unix timestamp)
            if let timestamp = try? container.decode(Double.self, forKey: key) {
                let date = Date(timeIntervalSince1970: timestamp)
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
                timestampValue = formatter.string(from: date)
                foundTimestamp = true
                NotificationLogger.shared.log(.info, message: "Found timestamp as double with key: \(key), value: \(timestamp)")
                break
            }
            
            // Try as integer (unix timestamp)
            if let timestamp = try? container.decode(Int.self, forKey: key) {
                let date = Date(timeIntervalSince1970: TimeInterval(timestamp))
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
                timestampValue = formatter.string(from: date)
                foundTimestamp = true
                NotificationLogger.shared.log(.info, message: "Found timestamp as integer with key: \(key), value: \(timestamp)")
                break
            }
            
            // Try as nested dictionary
            if let timestampDict = try? container.decode([String: String].self, forKey: key),
               let timestampString = timestampDict["date"] ?? timestampDict["value"] {
                timestampValue = timestampString
                foundTimestamp = true
                NotificationLogger.shared.log(.info, message: "Found timestamp in nested dictionary with key: \(key)")
                break
            }
        }
        
        // If all else fails, use current date
        if !foundTimestamp {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
            timestampValue = formatter.string(from: Date())
            NotificationLogger.shared.log(.warning, message: "Could not find timestamp, using current date: \(timestampValue)")
        }
        
        // Assign the final timestamp value
        timeStamp = timestampValue
    }
    
    // Add encode method to properly conform to Encodable
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(content, forKey: .content)
        try container.encode(timeStamp, forKey: .timeStamp)
        try container.encodeIfPresent(screenCode, forKey: .screenCode)
    }
}

// Define NotificationsResponse as a protocol
protocol NotificationsResponse {
    var notifications: [NotificationDTO] { get }
    var totalPages: Int { get }
    var currentPage: Int { get }
    var pageSize: Int { get }
}

// New implementation for handling direct array responses
struct ArrayNotificationsResponse: NotificationsResponse, Codable {
    let notifications: [NotificationDTO]
    let totalPages: Int
    let currentPage: Int
    let pageSize: Int
    
    init(notifications: [NotificationDTO], totalPages: Int = 1, currentPage: Int = 1, pageSize: Int = 20) {
        self.notifications = notifications
        self.totalPages = totalPages
        self.currentPage = currentPage
        self.pageSize = pageSize
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let notificationsArray = try container.decode([NotificationDTO].self)
        
        self.notifications = notificationsArray
        self.totalPages = 1
        self.currentPage = 1
        self.pageSize = 20
        
        NotificationLogger.shared.log(.info, message: "Successfully decoded array response with \(notificationsArray.count) notifications")
    }
}

// Standard implementation of NotificationsResponse
struct StandardNotificationsResponse: NotificationsResponse, Codable {
    let notifications: [NotificationDTO]
    let totalPages: Int
    let currentPage: Int
    let pageSize: Int
    
    enum CodingKeys: String, CodingKey {
        case notifications, data, items, content, results
        case totalPages, total_pages, pages, totalCount, total
        case currentPage, current_page, page
        case pageSize, page_size, size, limit
        case pagination, meta
    }
    
    enum PaginationKeys: String, CodingKey {
        case totalPages, total_pages, pages, totalCount, total
        case currentPage, current_page, page
        case pageSize, page_size, size, limit
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Initialize with default values first
        var notificationsArray: [NotificationDTO] = []
        var totalPagesValue = 1
        var currentPageValue = 1
        var pageSizeValue = 20
        
        // Try to decode notifications from various possible structures
        // Try direct array
        if let directNotifications = try? container.decode([NotificationDTO].self, forKey: .notifications) {
            notificationsArray = directNotifications
            NotificationLogger.shared.log(.info, message: "Decoded notifications directly from 'notifications' key")
        }
        // Try data key
        else if let dataNotifications = try? container.decode([NotificationDTO].self, forKey: .data) {
            notificationsArray = dataNotifications
            NotificationLogger.shared.log(.info, message: "Decoded notifications from 'data' key")
        }
        // Try items key
        else if let itemsNotifications = try? container.decode([NotificationDTO].self, forKey: .items) {
            notificationsArray = itemsNotifications
            NotificationLogger.shared.log(.info, message: "Decoded notifications from 'items' key")
        }
        // Try content key
        else if let contentNotifications = try? container.decode([NotificationDTO].self, forKey: .content) {
            notificationsArray = contentNotifications
            NotificationLogger.shared.log(.info, message: "Decoded notifications from 'content' key")
        }
        // Try results key
        else if let resultsNotifications = try? container.decode([NotificationDTO].self, forKey: .results) {
            notificationsArray = resultsNotifications
            NotificationLogger.shared.log(.info, message: "Decoded notifications from 'results' key")
        }
        // Try nested structure with data key
        else if let notificationsDict = try? container.decode([String: [NotificationDTO]].self, forKey: .notifications),
                let nestedArray = notificationsDict["data"] {
            notificationsArray = nestedArray
            NotificationLogger.shared.log(.info, message: "Decoded notifications from nested structure with 'data' key")
        }
        // Try to decode the entire response as a notification array
        else if let entireResponse = try? [NotificationDTO].self.init(from: decoder) {
            notificationsArray = entireResponse
            NotificationLogger.shared.log(.info, message: "Decoded entire response as notification array")
        }
        // If all else fails, use empty array
        else {
            NotificationLogger.shared.log(.error, message: "Failed to decode notifications from any expected structure")
            
            // Log the raw data for debugging
            if let data = try? JSONSerialization.data(withJSONObject: container, options: []),
               let dataString = String(data: data, encoding: .utf8) {
                NotificationLogger.shared.log(.error, message: "Raw container data: \(dataString)")
            }
        }
        
        // Try to decode pagination info from various possible structures
        
        // First check if pagination is in a nested object
        if let paginationContainer = try? container.nestedContainer(keyedBy: PaginationKeys.self, forKey: .pagination) {
            // Try to decode from pagination container
            for key in [PaginationKeys.totalPages, .total_pages, .pages, .totalCount, .total] {
                if let value = try? paginationContainer.decode(Int.self, forKey: key) {
                    totalPagesValue = value
                    break
                }
            }
            
            for key in [PaginationKeys.currentPage, .current_page, .page] {
                if let value = try? paginationContainer.decode(Int.self, forKey: key) {
                    currentPageValue = value
                    break
                }
            }
            
            for key in [PaginationKeys.pageSize, .page_size, .size, .limit] {
                if let value = try? paginationContainer.decode(Int.self, forKey: key) {
                    pageSizeValue = value
                    break
                }
            }
        }
        // Or in a meta object
        else if let metaContainer = try? container.nestedContainer(keyedBy: PaginationKeys.self, forKey: .meta) {
            // Try to decode from meta container
            for key in [PaginationKeys.totalPages, .total_pages, .pages, .totalCount, .total] {
                if let value = try? metaContainer.decode(Int.self, forKey: key) {
                    totalPagesValue = value
                    break
                }
            }
            
            for key in [PaginationKeys.currentPage, .current_page, .page] {
                if let value = try? metaContainer.decode(Int.self, forKey: key) {
                    currentPageValue = value
                    break
                }
            }
            
            for key in [PaginationKeys.pageSize, .page_size, .size, .limit] {
                if let value = try? metaContainer.decode(Int.self, forKey: key) {
                    pageSizeValue = value
                    break
                }
            }
        }
        // Or directly in the main container
        else {
            // Try to decode from main container
            for key in [CodingKeys.totalPages, .total_pages, .pages, .totalCount, .total] {
                if let value = try? container.decode(Int.self, forKey: key) {
                    totalPagesValue = value
                    break
                }
            }
            
            for key in [CodingKeys.currentPage, .current_page, .page] {
                if let value = try? container.decode(Int.self, forKey: key) {
                    currentPageValue = value
                    break
                }
            }
            
            for key in [CodingKeys.pageSize, .page_size, .size, .limit] {
                if let value = try? container.decode(Int.self, forKey: key) {
                    pageSizeValue = value
                    break
                }
            }
        }
        
        // Assign all properties
        self.notifications = notificationsArray
        self.totalPages = totalPagesValue
        self.currentPage = currentPageValue
        self.pageSize = pageSizeValue
    }
    
    // Add encode method to properly conform to Encodable
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(notifications, forKey: .notifications)
        try container.encode(totalPages, forKey: .totalPages)
        try container.encode(currentPage, forKey: .currentPage)
        try container.encode(pageSize, forKey: .pageSize)
    }
} 