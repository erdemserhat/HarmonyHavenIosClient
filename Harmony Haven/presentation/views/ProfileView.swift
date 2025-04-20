import SwiftUI

struct ProfileView: View {
    @EnvironmentObject private var authViewModel: AuthenticationViewModel
    @State private var showingLogoutConfirmation = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 30) {
                    // Profile header
                    VStack(spacing: 15) {
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 100, height: 100)
                            .foregroundColor(.blue)
                        
                        Text("Welcome to Your Profile")
                            .font(.title)
                            .fontWeight(.bold)
                    }
                    .padding(.top, 40)
                    
                    // Profile sections
                    VStack(spacing: 20) {
                        // Account section
                        ProfileSection(title: "Account", icon: "person.fill") {
                            ProfileRow(title: "Edit Profile", icon: "pencil") {
                                // Edit profile action
                            }
                            
                            ProfileRow(title: "Change Password", icon: "lock") {
                                // Change password action
                            }
                        }
                        
                        // Preferences section
                        ProfileSection(title: "Preferences", icon: "gear") {
                            ProfileRow(title: "Notifications", icon: "bell") {
                                // Notifications action
                            }
                            
                            ProfileRow(title: "Appearance", icon: "paintbrush") {
                                // Appearance action
                            }
                        }
                        
                        // Support section
                        ProfileSection(title: "Support", icon: "questionmark.circle") {
                            ProfileRow(title: "Help Center", icon: "lifepreserver") {
                                // Help center action
                            }
                            
                            ProfileRow(title: "Contact Us", icon: "envelope") {
                                // Contact us action
                            }
                        }
                        
                        // Logout button
                        Button(action: {
                            showingLogoutConfirmation = true
                        }) {
                            HStack {
                                Image(systemName: "arrow.right.square")
                                Text("Logout")
                                    .fontWeight(.semibold)
                            }
                            .foregroundColor(.red)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(10)
                        }
                        .padding(.top, 20)
                    }
                    .padding(.horizontal)
                }
                .padding(.bottom, 30)
            }
            .navigationTitle("Profile")
            .alert("Logout", isPresented: $showingLogoutConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Logout", role: .destructive) {
                    authViewModel.logout()
                }
            } message: {
                Text("Are you sure you want to logout?")
            }
        }
    }
}

// MARK: - Supporting Views

struct ProfileSection<Content: View>: View {
    let title: String
    let icon: String
    let content: Content
    
    init(title: String, icon: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.icon = icon
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.blue)
                Text(title)
                    .font(.headline)
            }
            
            content
                .padding(.leading, 10)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}

struct ProfileRow: View {
    let title: String
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .frame(width: 25, height: 25)
                    .foregroundColor(.blue)
                
                Text(title)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .padding(.vertical, 8)
        }
    }
} 