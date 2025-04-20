import SwiftUI

struct NotificationView: View {
    @StateObject private var viewModel = NotificationViewModel()
    @EnvironmentObject private var navigationCoordinator: AppNavigationCoordinator
    
    var body: some View {
        NavigationView {
            ZStack {
                if viewModel.isLoading && viewModel.notifications.isEmpty {
                    ProgressView()
                        .scaleEffect(1.5)
                } else if let errorMessage = viewModel.errorMessage, viewModel.notifications.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 60, height: 60)
                            .foregroundColor(.orange)
                        
                        Text("Error")
                            .font(.title)
                            .foregroundColor(.red)
                        
                        Text(errorMessage)
                            .multilineTextAlignment(.center)
                            .padding()
                        
                        Button("Retry") {
                            viewModel.refreshNotifications()
                        }
                        .padding()
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                    .padding()
                } else if viewModel.notifications.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "bell.slash")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 60, height: 60)
                            .foregroundColor(.gray)
                        
                        Text("No Notifications")
                            .font(.title2)
                            .foregroundColor(.gray)
                        
                        Text("You don't have any notifications yet.")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                } else {
                    List {
                        ForEach(viewModel.notifications) { notification in
                            NotificationRow(notification: notification)
                                .onAppear {
                                    viewModel.loadMoreNotificationsIfNeeded(notification: notification)
                                }
                                .onTapGesture {
                                    handleNotificationTap(notification)
                                }
                        }
                        
                        if viewModel.isLoading && !viewModel.notifications.isEmpty {
                            HStack {
                                Spacer()
                                ProgressView()
                                Spacer()
                            }
                            .padding()
                            .listRowSeparator(.hidden)
                        }
                        
                        if let errorMessage = viewModel.errorMessage, !viewModel.notifications.isEmpty {
                            HStack {
                                Image(systemName: "exclamationmark.triangle")
                                    .foregroundColor(.orange)
                                Text(errorMessage)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Spacer()
                                Button("Retry") {
                                    viewModel.refreshNotifications()
                                }
                                .font(.caption)
                                .foregroundColor(.blue)
                            }
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                            .padding(.horizontal)
                            .listRowSeparator(.hidden)
                        }
                    }
                    .listStyle(PlainListStyle())
                    .refreshable {
                        viewModel.refreshNotifications()
                    }
                }
            }
            .navigationTitle("Notifications")
        }
        .onAppear {
            viewModel.loadNotifications()
        }
    }
    
    private func handleNotificationTap(_ notification: Notification) {
        // Handle navigation based on screenCode if needed
        if let screenCode = notification.screenCode {
            // Navigate to the appropriate screen based on the code
            // This would depend on your app's navigation structure
            print("Navigate to screen with code: \(screenCode)")
        }
    }
}

struct NotificationRow: View {
    let notification: Notification
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(notification.title)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                if notification.isRecent {
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 8, height: 8)
                }
            }
            
            Text(notification.content)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(2)
            
            Text(notification.formattedDate)
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    let navigationCoordinator = AppNavigationCoordinator()
    
    return NotificationView()
        .environmentObject(navigationCoordinator)
} 