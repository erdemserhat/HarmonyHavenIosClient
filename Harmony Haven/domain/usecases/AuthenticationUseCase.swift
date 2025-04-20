import Foundation

// Login Use Case
protocol LoginUseCase {
    func execute(email: String, password: String, completion: @escaping (Result<AuthenticationResponse, NetworkError>) -> Void)
}

class LoginUseCaseImpl: LoginUseCase {
    private let authenticationService: AuthenticationService
    
    init(authenticationService: AuthenticationService = AuthenticationService()) {
        self.authenticationService = authenticationService
    }
    
    func execute(email: String, password: String, completion: @escaping (Result<AuthenticationResponse, NetworkError>) -> Void) {
        authenticationService.login(email: email, password: password, completion: completion)
    }
}

// Registration Use Case
protocol RegisterUseCase {
    func execute(name: String, email: String, password: String, completion: @escaping (Result<AuthenticationResponse, NetworkError>) -> Void)
}

class RegisterUseCaseImpl: RegisterUseCase {
    private let authenticationService: AuthenticationService
    
    init(authenticationService: AuthenticationService = AuthenticationService()) {
        self.authenticationService = authenticationService
    }
    
    func execute(name: String, email: String, password: String, completion: @escaping (Result<AuthenticationResponse, NetworkError>) -> Void) {
        authenticationService.register(name: name, email: email, password: password, completion: completion)
    }
} 