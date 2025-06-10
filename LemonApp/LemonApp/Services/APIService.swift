import Foundation
import Combine

class APIService: ObservableObject {
    static let shared = APIService()
    
    // Update this with your Vercel deployment URL
    private let baseURL = "https://your-app-name.vercel.app/api"
    
    // For local development
    // private let baseURL = "http://localhost:3000/api"
    
    private init() {}
    
    func planTrip(destination: String, duration: String? = nil, preferences: String? = nil, budget: String? = nil) -> AnyPublisher<TripPlan, Error> {
        guard let url = URL(string: "\(baseURL)/plan-trip") else {
            return Fail(error: URLError(.badURL))
                .eraseToAnyPublisher()
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "destination": destination,
            "duration": duration ?? "",
            "preferences": preferences ?? "",
            "budget": budget ?? ""
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        } catch {
            return Fail(error: error)
                .eraseToAnyPublisher()
        }
        
        return URLSession.shared.dataTaskPublisher(for: request)
            .map(\.data)
            .decode(type: TripPlan.self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    
    func checkHealth() -> AnyPublisher<HealthStatus, Error> {
        guard let url = URL(string: "\(baseURL)/health") else {
            return Fail(error: URLError(.badURL))
                .eraseToAnyPublisher()
        }
        
        return URLSession.shared.dataTaskPublisher(for: url)
            .map(\.data)
            .decode(type: HealthStatus.self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
}

// MARK: - Data Models
struct TripPlan: Codable {
    let success: Bool
    let destination: String
    let itinerary: String
    let generatedAt: String
}

struct HealthStatus: Codable {
    let status: String
    let service: String
    let timestamp: String
}