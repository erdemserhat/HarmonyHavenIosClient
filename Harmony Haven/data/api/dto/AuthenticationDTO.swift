import Foundation

// Request DTOs
struct UserAuthenticationRequest: Codable {
    let email: String
    let password: String
}

struct UserRegistrationRequest: Codable {
    let name: String
    let email: String
    let password: String
}

// Response DTOs
struct AuthenticationResponse: Codable {
    let formValidationResult: ValidationResult
    let credentialsValidationResult: ValidationResult?
    let isAuthenticated: Boolean
    let jwt: String?
    
    // Swift doesn't have a Boolean type, so we need to map it
    struct Boolean: Codable {
        let value: Bool
        
        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            value = try container.decode(Bool.self)
        }
        
        func encode(to encoder: Encoder) throws {
            var container = encoder.singleValueContainer()
            try container.encode(value)
        }
    }
}

struct ValidationResult: Codable {
    let isValid: Bool
    let errorMessage: String
    let errorCode: Int
} 
