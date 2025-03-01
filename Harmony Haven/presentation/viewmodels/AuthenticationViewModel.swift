import Foundation
import Combine

class AuthenticationViewModel: ObservableObject {
    // Login state
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var name: String = ""
    
    // UI state
    @Published var isLoading: Bool = false
    @Published var errorMessage: String = ""
    @Published var isAuthenticated: Bool = false
    @Published var showingRegistration: Bool = false
    
    // Validation state
    @Published var emailError: String = ""
    @Published var passwordError: String = ""
    @Published var nameError: String = ""
    
    // JWT token
    @Published var token: String = ""
    
    private let loginUseCase: LoginUseCase
    private let registerUseCase: RegisterUseCase
    
    init(
        loginUseCase: LoginUseCase = LoginUseCaseImpl(),
        registerUseCase: RegisterUseCase = RegisterUseCaseImpl()
    ) {
        self.loginUseCase = loginUseCase
        self.registerUseCase = registerUseCase
    }
    
    // MARK: - Validation
    
    func validateEmail() -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        let isValid = emailPredicate.evaluate(with: email)
        
        emailError = isValid ? "" : "Please enter a valid email address"
        return isValid
    }
    
    func validatePassword() -> Bool {
        let isValid = password.count >= 6
        passwordError = isValid ? "" : "Password must be at least 6 characters"
        return isValid
    }
    
    func validateName() -> Bool {
        let isValid = name.count >= 2
        nameError = isValid ? "" : "Name must be at least 2 characters"
        return isValid
    }
    
    // MARK: - Authentication
    
    func login() {
        guard validateEmail(), validatePassword() else {
            return
        }
        
        isLoading = true
        errorMessage = ""
        
        loginUseCase.execute(email: email, password: password) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.isLoading = false
                
                switch result {
                case .success(let response):
                    if response.isAuthenticated.value {
                        if let jwt = response.jwt {
                            self.token = jwt
                            self.isAuthenticated = true
                            // Save token to UserDefaults or Keychain
                            UserDefaults.standard.set(jwt, forKey: "authToken")
                        } else {
                            self.errorMessage = "Authentication failed: No token received"
                        }
                    } else {
                        // Handle validation errors
                        if !response.formValidationResult.isValid {
                            self.errorMessage = response.formValidationResult.errorMessage
                        } else if let credentialsError = response.credentialsValidationResult, !credentialsError.isValid {
                            self.errorMessage = credentialsError.errorMessage
                        } else {
                            self.errorMessage = "Authentication failed"
                        }
                    }
                case .failure(let error):
                    self.errorMessage = error.errorDescription
                }
            }
        }
    }
    
    func register() {
        guard validateName(), validateEmail(), validatePassword() else {
            return
        }
        
        isLoading = true
        errorMessage = ""
        
        registerUseCase.execute(name: name, email: email, password: password) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.isLoading = false
                
                switch result {
                case .success(let response):
                    if response.isAuthenticated.value {
                        if let jwt = response.jwt {
                            self.token = jwt
                            self.isAuthenticated = true
                            // Save token to UserDefaults or Keychain
                            UserDefaults.standard.set(jwt, forKey: "authToken")
                        } else {
                            self.errorMessage = "Registration successful but no token received"
                        }
                    } else {
                        // Handle validation errors
                        if !response.formValidationResult.isValid {
                            self.errorMessage = response.formValidationResult.errorMessage
                        } else {
                            self.errorMessage = "Registration failed"
                        }
                    }
                case .failure(let error):
                    self.errorMessage = error.errorDescription
                }
            }
        }
    }
    
    func logout() {
        // Clear token and authentication state
        token = ""
        isAuthenticated = false
        UserDefaults.standard.removeObject(forKey: "authToken")
        
        // Reset form fields
        email = ""
        password = ""
        name = ""
        errorMessage = ""
    }
    
    func checkAuthentication() {
        // Check if user is already authenticated
        if let savedToken = UserDefaults.standard.string(forKey: "authToken"), !savedToken.isEmpty {
            token = savedToken
            isAuthenticated = true
        }
    }
} 