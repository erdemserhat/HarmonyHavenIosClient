import Foundation

protocol GetNotificationsUseCase {
    func execute(page: Int, pageSize: Int, completion: @escaping (Result<(notifications: [Notification], pagination: PaginationInfo), NetworkError>) -> Void)
}

struct PaginationInfo {
    let currentPage: Int
    let totalPages: Int
    let pageSize: Int
}

class GetNotificationsUseCaseImpl: GetNotificationsUseCase {
    private let notificationService: NotificationService
    private let logger = NotificationLogger.shared
    
    init(notificationService: NotificationService = NotificationService()) {
        self.notificationService = notificationService
    }
    
    func execute(page: Int = 1, pageSize: Int = 20, completion: @escaping (Result<(notifications: [Notification], pagination: PaginationInfo), NetworkError>) -> Void) {
        logger.log(.info, message: "Executing GetNotificationsUseCase with page: \(page), pageSize: \(pageSize)")
        
        notificationService.fetchNotifications(page: page, pageSize: pageSize) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let response):
                self.logger.log(.info, message: "Received \(response.notifications.count) notifications from service")
                
                // Map DTOs to domain models
                var successfullyParsedCount = 0
                var failedParsingCount = 0
                
                let notifications = response.notifications.compactMap { dto -> Notification? in
                    self.logger.log(.debug, message: "Processing notification ID: \(dto.id), timestamp: \(dto.timeStamp)")
                    
                    // Try to parse the timestamp
                    if let date = self.parseTimestamp(dto.timeStamp) {
                        successfullyParsedCount += 1
                        return Notification(
                            id: dto.id,
                            title: dto.title,
                            content: dto.content,
                            timeStamp: date,
                            screenCode: dto.screenCode
                        )
                    } else {
                        failedParsingCount += 1
                        self.logger.log(.error, message: "Failed to parse timestamp after all attempts: \(dto.timeStamp)")
                        
                        // Use current date as fallback
                        self.logger.log(.warning, message: "Using current date as fallback for notification ID: \(dto.id)")
                        return Notification(
                            id: dto.id,
                            title: dto.title,
                            content: dto.content,
                            timeStamp: Date(),
                            screenCode: dto.screenCode
                        )
                    }
                }
                
                self.logger.log(.info, message: "Successfully parsed \(successfullyParsedCount) notifications, failed to parse \(failedParsingCount)")
                
                let paginationInfo = PaginationInfo(
                    currentPage: response.currentPage,
                    totalPages: response.totalPages,
                    pageSize: response.pageSize
                )
                
                completion(.success((notifications: notifications, pagination: paginationInfo)))
                
            case .failure(let error):
                self.logger.log(.error, message: "Failed to fetch notifications: \(error.errorDescription)")
                completion(.failure(error))
            }
        }
    }
    
    // Helper method to parse timestamp with multiple formats
    private func parseTimestamp(_ timestampString: String) -> Date? {
        // First, try to parse as Unix timestamp (seconds since 1970)
        if let timestampValue = Int(timestampString) {
            let date = Date(timeIntervalSince1970: TimeInterval(timestampValue))
            logger.log(.info, message: "Successfully parsed timestamp as Unix timestamp (seconds): \(timestampValue)")
            return date
        }
        
        // Try standard formats
        let formats = [
            "yyyy-MM-dd'T'HH:mm:ss.SSSZ",
            "yyyy-MM-dd'T'HH:mm:ssZ",
            "yyyy-MM-dd'T'HH:mm:ss",
            "yyyy-MM-dd HH:mm:ss",
            "yyyy/MM/dd HH:mm:ss",
            "MM/dd/yyyy HH:mm:ss",
            "dd-MM-yyyy HH:mm:ss",
            "dd/MM/yyyy HH:mm:ss",
            "yyyy-MM-dd",
            "MM/dd/yyyy",
            "dd-MM-yyyy"
        ]
        
        let dateFormatter = DateFormatter()
        
        // Try each format
        for format in formats {
            dateFormatter.dateFormat = format
            if let date = dateFormatter.date(from: timestampString) {
                logger.log(.info, message: "Successfully parsed timestamp with format: \(format)")
                return date
            }
        }
        
        // Try ISO8601 date formatter
        let iso8601Formatter = ISO8601DateFormatter()
        iso8601Formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = iso8601Formatter.date(from: timestampString) {
            logger.log(.info, message: "Successfully parsed timestamp with ISO8601 formatter")
            return date
        }
        
        // Try without fractional seconds
        iso8601Formatter.formatOptions = [.withInternetDateTime]
        if let date = iso8601Formatter.date(from: timestampString) {
            logger.log(.info, message: "Successfully parsed timestamp with ISO8601 formatter (no fractional seconds)")
            return date
        }
        
        // Try as Unix timestamp (milliseconds since 1970)
        if let timestampMilliseconds = Double(timestampString) {
            let date = Date(timeIntervalSince1970: timestampMilliseconds / 1000.0)
            logger.log(.info, message: "Successfully parsed timestamp as Unix timestamp (milliseconds)")
            return date
        }
        
        // Log the failure for debugging
        logger.logDateParsingAttempt(dateString: timestampString)
        
        return nil
    }
} 