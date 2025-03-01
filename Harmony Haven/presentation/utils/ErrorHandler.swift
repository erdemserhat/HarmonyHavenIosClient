import Foundation
import UIKit

class ErrorHandler {
    static func handleNetworkError(_ error: NetworkError, on viewController: UIViewController) {
        let title: String
        let message: String
        
        switch error {
        case .connectionError, .timeoutError:
            title = "Connection Error"
            message = "Please check your internet connection and try again."
        case .unauthorized:
            title = "Authentication Error"
            message = "You need to log in to access this feature."
            // You might want to redirect to login screen here
        case .serverError:
            title = "Server Error"
            message = "Our servers are experiencing issues. Please try again later."
        case .decodingFailed:
            title = "Data Error"
            message = "There was a problem processing the data. Please try again later."
        default:
            title = "Error"
            message = error.errorDescription
        }
        
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        
        DispatchQueue.main.async {
            viewController.present(alert, animated: true)
        }
    }
    
    // For SwiftUI
    static func getErrorMessage(for error: NetworkError) -> (title: String, message: String) {
        switch error {
        case .connectionError, .timeoutError:
            return ("Connection Error", "Please check your internet connection and try again.")
        case .unauthorized:
            return ("Authentication Error", "You need to log in to access this feature.")
        case .serverError:
            return ("Server Error", "Our servers are experiencing issues. Please try again later.")
        case .decodingFailed:
            return ("Data Error", "There was a problem processing the data. Please try again later.")
        default:
            return ("Error", error.errorDescription)
        }
    }
} 