import SwiftUI

struct RegisterView: View {
    @EnvironmentObject private var authViewModel: AuthenticationViewModel
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject private var navigationCoordinator: AppNavigationCoordinator
    
    var body: some View {
        ZStack {
            // Background
            Color(.systemBackground)
                .ignoresSafeArea()
            
            // Content
            ScrollView {
                VStack(spacing: 25) {
                    // Header
                    VStack(spacing: 8) {
                        Text("Create Account")
                            .font(.system(size: 28, weight: .bold, design: .default))
                            .foregroundColor(.primary)
                        
                        Text("Join Harmony Haven today")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 20)
                    .padding(.bottom, 10)
                    
                    // Registration form
                    VStack(spacing: 20) {
                        // Name field
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Full Name")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            HStack {
                                TextField("Your name", text: $authViewModel.name)
                                    .font(.body)
                                    .foregroundColor(.primary)
                                    .textContentType(.name)
                                    .disableAutocorrection(true)
                                
                                if !authViewModel.name.isEmpty {
                                    Button(action: {
                                        authViewModel.name = ""
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
                            
                            if !authViewModel.nameError.isEmpty {
                                Text(authViewModel.nameError)
                                    .font(.caption)
                                    .foregroundColor(.red)
                            }
                        }
                        
                        // Email field
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Email")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            HStack {
                                TextField("Your email", text: $authViewModel.email)
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
                            
                            SecureField("Create a strong password", text: $authViewModel.password)
                                .font(.body)
                                .foregroundColor(.primary)
                                .textContentType(.newPassword)
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
                        
                        // Register button
                        Button(action: {
                            authViewModel.register()
                        }) {
                            ZStack {
                                if authViewModel.isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle())
                                } else {
                                    Text("Create Account")
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
                        
                        // Login link
                        HStack {
                            Text("Already have an account?")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            Button(action: {
                                dismiss()
                            }) {
                                Text("Sign In")
                                    .font(.subheadline.bold())
                                    .foregroundColor(.accentColor)
                            }
                        }
                        .padding(.top, 5)
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.bottom, 30)
            }
        }
        .navigationBarTitle("", displayMode: .inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    dismiss()
                }) {
                    HStack(spacing: 5) {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                    .foregroundColor(.accentColor)
                }
            }
        }
        .onChange(of: authViewModel.isAuthenticated) { oldValue, newValue in
            if newValue {
                navigationCoordinator.navigateTo(.home)
            }
        }
    }
} 


