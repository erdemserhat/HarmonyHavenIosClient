import SwiftUI

struct LoginView: View {
    @EnvironmentObject private var authViewModel: AuthenticationViewModel
    @EnvironmentObject private var navigationCoordinator: AppNavigationCoordinator
    @State private var showingRegistration = false
    
    // Initialize with default credentials
    init() {
        // Use this approach to set default values for the ViewModel
        _authViewModel = EnvironmentObject()
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                Color(.systemBackground)
                    .ignoresSafeArea()
                
                // Content
                ScrollView {
                    VStack(spacing: 30) {
                        // Logo and app name
                        VStack(spacing: 12) {
                            // App logo
                            Image(systemName: "leaf.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 60, height: 60)
                                .foregroundColor(.accentColor)
                                .padding(.top, 40)
                            
                            Text("Harmony Haven")
                                .font(.system(size: 32, weight: .bold, design: .default))
                                .foregroundColor(.primary)
                            
                            Text("Your wellness journey begins here")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding(.bottom, 20)
                        
                        // Login form
                        VStack(spacing: 20) {
                            // Email field
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Email")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                
                                HStack {
                                    TextField("iosclient@test.com", text: $authViewModel.email)
                                        .font(.body)
                                        .foregroundColor(.primary)
                                        .autocapitalization(.none)
                                        .keyboardType(.emailAddress)
                                        .textContentType(.emailAddress)
                                        .disableAutocorrection(true)
                                    
                                    if !authViewModel.email.isEmpty {
                                        Button(action: {
                                            authViewModel.email = ""
                                        }) {
                                            Image(systemName: "xmark.circle.fill")
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                }
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(Color(.systemGray6))
                                )
                                
                                if !authViewModel.emailError.isEmpty {
                                    Text(authViewModel.emailError)
                                        .font(.caption)
                                        .foregroundColor(.red)
                                }
                            }
                            
                            // Password field
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Password")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                
                                SecureField("Password.0101.", text: $authViewModel.password)
                                    .font(.body)
                                    .foregroundColor(.primary)
                                    .textContentType(.password)
                                    .padding()
                                    .background(
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(Color(.systemGray6))
                                    )
                                
                                if !authViewModel.passwordError.isEmpty {
                                    Text(authViewModel.passwordError)
                                        .font(.caption)
                                        .foregroundColor(.red)
                                }
                            }
                            
                            // Error message
                            if !authViewModel.errorMessage.isEmpty {
                                Text(authViewModel.errorMessage)
                                    .font(.callout)
                                    .foregroundColor(.red)
                                    .multilineTextAlignment(.center)
                            }
                            
                            // Login button
                            Button(action: {
                                authViewModel.login()
                            }) {
                                ZStack {
                                    if authViewModel.isLoading {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle())
                                    } else {
                                        Text("Sign In")
                                            .font(.headline)
                                            .foregroundColor(.white)
                                            .frame(maxWidth: .infinity)
                                    }
                                }
                                .padding()
                                .background(Color.accentColor)
                                .cornerRadius(10)
                            }
                            .disabled(authViewModel.isLoading)
                            
                            // Quick login button
                            Button(action: {
                                authViewModel.email = "iosclient@test.com"
                                authViewModel.password = "Password.0101."
                                authViewModel.login()
                            }) {
                                Text("Quick Login with Test Account")
                                    .font(.subheadline)
                                    .foregroundColor(.accentColor)
                            }
                            .padding(.top, 5)
                            
                            // Register link
                            HStack {
                                Text("Don't have an account?")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                Button(action: {
                                    showingRegistration = true
                                }) {
                                    Text("Sign Up")
                                        .font(.subheadline.bold())
                                        .foregroundColor(.accentColor)
                                }
                            }
                            .padding(.top, 10)
                        }
                        .padding(.horizontal, 20)
                    }
                    .padding(.bottom, 30)
                }
            }
            .navigationBarHidden(true)
            .navigationDestination(isPresented: $showingRegistration) {
                RegisterView()
            }
        }
        .onChange(of: authViewModel.isAuthenticated) { oldValue, newValue in
            if newValue {
                navigationCoordinator.navigateTo(.home)
            }
        }
        .onAppear {
            // Reset the registration flag when the login view appears
            authViewModel.showingRegistration = false
            
            // Set default credentials
            if authViewModel.email.isEmpty && authViewModel.password.isEmpty {
                authViewModel.email = "iosclient@test.com"
                authViewModel.password = "Password.0101."
            }
        }
    }
}

// Helper extension for hex colors
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
} 