import Foundation

struct Notification: Identifiable {
    let id: Int
    let title: String
    let content: String
    let timeStamp: Date
    let screenCode: String?
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: timeStamp)
    }
    
    var isRecent: Bool {
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.day], from: timeStamp, to: now)
        return components.day ?? 0 < 3
    }
} 
