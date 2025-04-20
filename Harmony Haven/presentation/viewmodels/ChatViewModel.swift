import Foundation
import Combine

class ChatViewModel: NSObject, ObservableObject, URLSessionDataDelegate {
    @Published var messages: [ChatMessage] = []
    @Published var currentMessage: String = ""
    @Published var isLoading: Bool = false
    
    private var cancellables = Set<AnyCancellable>()
    private var dataTask: URLSessionDataTask?
    private var currentResponse: String = ""
    private var session: URLSession!
    private var buffer: String = ""
    
    override init() {
        super.init()
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = TimeInterval(INT_MAX)
        config.timeoutIntervalForResource = TimeInterval(INT_MAX)
        config.httpAdditionalHeaders = [
            "Accept": "text/event-stream",
            "Cache-Control": "no-cache"
        ]
        session = URLSession(configuration: config, delegate: self, delegateQueue: nil)
    }
    
    func sendMessage() {
        guard !currentMessage.isEmpty else { return }
        
        let userMessage = ChatMessage(text: currentMessage, isUser: true)
        messages.append(userMessage)
        
        isLoading = true
        let prompt = currentMessage
        currentMessage = ""
        currentResponse = ""
        buffer = ""
        
        guard let url = URL(string: "\(APIConstants.baseURL)/api/v1/chat/\(prompt.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? "")") else {
            print("❌ Invalid URL")
            isLoading = false
            return
        }
        
        print("🌐 Connecting to: \(url.absoluteString)")
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("text/event-stream", forHTTPHeaderField: "Accept")
        request.setValue("no-cache", forHTTPHeaderField: "Cache-Control")
        
        if let token = UserDefaults.standard.string(forKey: "authToken") {
            request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            print("🔑 Using token: \(token.prefix(10))...")
        } else {
            print("⚠️ No auth token found")
        }
        
        dataTask = session.dataTask(with: request)
        dataTask?.resume()
        print("🚀 Request started")
    }
    
    // MARK: - URLSessionDataDelegate
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        if let string = String(data: data, encoding: .utf8) {
            print("📥 Received data: \(string)")
            buffer += string
            
            // Buffer'daki tüm satırları işle
            while let range = buffer.range(of: "\n") {
                let line = String(buffer[buffer.startIndex..<range.lowerBound])
                buffer.removeSubrange(buffer.startIndex...range.lowerBound)
                
                print("📝 Processing line: \(line)")
                
                if line.hasPrefix("data: ") {
                    let content = String(line.dropFirst(6)) // "data: " kısmını atla
                    print("✨ Extracted content: \(content)")
                    
                    DispatchQueue.main.async { [weak self] in
                        guard let self = self else { return }
                        self.currentResponse += content
                        
                        // İlk mesaj geldiğinde veya mesaj güncellendiğinde
                        if !self.currentResponse.isEmpty {
                            let aiMessage = ChatMessage(text: self.currentResponse, isUser: false)
                            if self.messages.last?.isUser == true {
                                self.messages.append(aiMessage)
                                print("➕ Added new message")
                            } else {
                                self.messages[self.messages.count - 1] = aiMessage
                                print("🔄 Updated existing message")
                            }
                        }
                    }
                }
            }
        }
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        DispatchQueue.main.async { [weak self] in
            self?.isLoading = false
            if let error = error {
                print("❌ Stream error: \(error)")
            } else {
                print("✅ Stream completed successfully")
            }
        }
    }
    
    deinit {
        dataTask?.cancel()
        print("🗑️ Cleanup completed")
    }
}

struct ChatMessage: Identifiable {
    let id = UUID()
    let text: String
    let isUser: Bool
} 