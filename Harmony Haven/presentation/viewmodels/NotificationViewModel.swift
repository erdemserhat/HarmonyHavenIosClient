import Foundation
import Combine

class NotificationViewModel: ObservableObject {
    @Published var notifications: [Notification] = []
    @Published var isLoading = false
    @Published var error: NetworkError?
    @Published var hasMorePages = false
    @Published var currentPage = 1
    @Published var errorMessage: String?
    
    private let getNotificationsUseCase: GetNotificationsUseCase
    private let logger = NotificationLogger.shared
    private var totalPages = 1
    private var isRetrying = false
    
    init(getNotificationsUseCase: GetNotificationsUseCase = GetNotificationsUseCaseImpl()) {
        self.getNotificationsUseCase = getNotificationsUseCase
        logger.log(.info, message: "NotificationViewModel initialized")
    }
    
    func loadNotifications(forceRefresh: Bool = false) {
        if forceRefresh {
            logger.log(.info, message: "Force refreshing notifications")
            currentPage = 1
            notifications = []
            errorMessage = nil
        }
        
        guard !isLoading else {
            logger.log(.info, message: "Skipping loadNotifications because already loading")
            return
        }
        
        isLoading = true
        error = nil
        
        logger.log(.info, message: "Loading notifications for page \(currentPage)")
        
        getNotificationsUseCase.execute(page: currentPage, pageSize: 20) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.isLoading = false
                
                switch result {
                case .success(let data):
                    self.logger.log(.info, message: "Successfully loaded \(data.notifications.count) notifications")
                    
                    if self.currentPage == 1 {
                        self.notifications = data.notifications
                    } else {
                        self.notifications.append(contentsOf: data.notifications)
                    }
                    
                    self.totalPages = data.pagination.totalPages
                    self.hasMorePages = self.currentPage < self.totalPages
                    self.errorMessage = nil
                    
                case .failure(let error):
                    self.logger.log(.error, message: "Failed to load notifications: \(error.errorDescription)")
                    self.error = error
                    self.errorMessage = self.userFriendlyErrorMessage(for: error)
                    
                    // If this was a retry, don't try again
                    if !self.isRetrying && self.currentPage == 1 && self.notifications.isEmpty {
                        self.retryLoadingAfterDelay()
                    }
                }
            }
        }
    }
    
    private func retryLoadingAfterDelay() {
        logger.log(.info, message: "Scheduling retry after delay")
        isRetrying = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
            guard let self = self else { return }
            self.logger.log(.info, message: "Executing retry")
            self.isRetrying = false
            self.loadNotifications(forceRefresh: true)
        }
    }
    
    private func userFriendlyErrorMessage(for error: NetworkError) -> String {
        switch error {
        case .connectionError:
            return "No internet connection. Please check your network settings and try again."
        case .unauthorized:
            return "Your session has expired. Please log in again."
        case .serverError:
            return "The server is experiencing issues. Please try again later."
        case .decodingFailed:
            return "There was a problem processing the data. The development team has been notified."
        default:
            return "An unexpected error occurred. Please try again later."
        }
    }
    
    func loadMoreNotificationsIfNeeded(notification: Notification) {
        let thresholdIndex = notifications.index(notifications.endIndex, offsetBy: -5)
        if notifications.firstIndex(where: { $0.id == notification.id }) == thresholdIndex,
           hasMorePages && !isLoading {
            logger.log(.info, message: "Loading more notifications, moving to page \(currentPage + 1)")
            currentPage += 1
            loadNotifications()
        }
    }
    
    func refreshNotifications() {
        logger.log(.info, message: "Manual refresh triggered")
        loadNotifications(forceRefresh: true)
    }
} 