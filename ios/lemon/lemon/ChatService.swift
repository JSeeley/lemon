import Foundation

struct ChatMessageDTO: Codable {
    let role: String
    let content: String
}

final class ChatService {
    private let baseURL = URL(string: "https://backend-mhrc5sccw-jseeleys-projects.vercel.app/api/chat.js")!
    private let schema: [String: Any]
    
    init() {
        // Load the schema JSON bundled with the app
        if let url = Bundle.main.url(forResource: "submit_trip_query", withExtension: "json"),
           let data = try? Data(contentsOf: url),
           let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            self.schema = obj
        } else {
            self.schema = [:]
            print("⚠️ Could not load submit_trip_query.json from bundle; proceeding without schema.")
        }
    }
    
    /// Sends the full chat history and returns the assistant's next message.
    func send(messages: [ChatMessageDTO]) async throws -> ChatMessageDTO {
        var request = URLRequest(url: baseURL)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "messages": messages.map { ["role": $0.role, "content": $0.content] },
            "schema": schema
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        
        struct Response: Decodable {
            let message: ChatMessageDTO
        }
        let decoded = try JSONDecoder().decode(Response.self, from: data)
        return decoded.message
    }
} 