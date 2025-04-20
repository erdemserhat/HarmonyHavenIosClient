import Foundation

class AuthenticationService {
    private let apiClient: APIClient
    private let retryManager: RetryManager
    
    init(apiClient: APIClient = APIClient(), retryManager: RetryManager = RetryManager()) {
        self.apiClient = apiClient
        self.retryManager = retryManager
    }
    
    // Login user
    func login(email: String, password: String, completion: @escaping (Result<AuthenticationResponse, NetworkError>) -> Void) {
        let request = UserAuthenticationRequest(email: email, password: password)
        
        // Convert request to dictionary
        guard let requestDict = try? request.asDictionary() else {
            completion(.failure(.requestFailed(NSError(domain: "AuthenticationService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to serialize request"]))))
            return
        }
        
        retryManager.retry { callback in
            self.apiClient.request(
                endpoint: "/api/v1/user/authenticate",
                method: .post,
                parameters: requestDict
            ) { result in
                switch result {
                case .success(let data):
                    do {
                        let response = try JSONDecoder().decode(AuthenticationResponse.self, from: data)
                        callback(.success(response))
                    } catch {
                        callback(.failure(.decodingFailed(error)))
                    }
                case .failure(let error):
                    callback(.failure(error))
                }
            }
        } completion: { result in
            completion(result)
        }
    }
    
    // Register user
    func register(name: String, email: String, password: String, completion: @escaping (Result<AuthenticationResponse, NetworkError>) -> Void) {
        let request = UserRegistrationRequest(name: name, email: email, password: password)
        
        // Convert request to dictionary
        guard let requestDict = try? request.asDictionary() else {
            completion(.failure(.requestFailed(NSError(domain: "AuthenticationService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to serialize request"]))))
            return
        }
        
        retryManager.retry { callback in
            self.apiClient.request(
                endpoint: "/api/v2/user/authenticate",
                method: .post,
                parameters: requestDict
            ) { result in
                switch result {
                case .success(let data):
                    do {
                        let response = try JSONDecoder().decode(AuthenticationResponse.self, from: data)
                        callback(.success(response))
                    } catch {
                        callback(.failure(.decodingFailed(error)))
                    }
                case .failure(let error):
                    callback(.failure(error))
                }
            }
        } completion: { result in
            completion(result)
        }
    }
}

// Extension to convert Encodable objects to dictionaries
extension Encodable {
    func asDictionary() throws -> [String: Any] {
        let data = try JSONEncoder().encode(self)
        guard let dictionary = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any] else {
            throw NSError(domain: "EncodableExtension", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to convert to dictionary"])
        }
        return dictionary
    }
} 