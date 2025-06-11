import Foundation

struct TripPlannerService {
    private let baseURL: URL = {
        // Use the deployed Vercel backend for all build configs
        return URL(string: "https://backend-jseeleys-projects.vercel.app/api/plan.js")!
    }()

    func planTrip(destination: String,
                  startDate: Date,
                  endDate: Date,
                  travelers: Int = 1,
                  preferences: String? = nil) async throws -> String {
        var request = URLRequest(url: baseURL)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        var body: [String: Any] = [
            "destination": destination,
            "startDate": isoDateFormatter.string(from: startDate),
            "endDate": isoDateFormatter.string(from: endDate),
            "travelers": travelers
        ]
        if let prefs = preferences {
            body["preferences"] = prefs
        }
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }

        guard httpResponse.statusCode == 200 else {
            let serverMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            print("Server responded with status \(httpResponse.statusCode): \(serverMessage)")
            throw URLError(.badServerResponse)
        }

        struct PlanResponse: Decodable { let itinerary: String }
        let decoded = try JSONDecoder().decode(PlanResponse.self, from: data)
        return decoded.itinerary
    }

    private var isoDateFormatter: ISO8601DateFormatter {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate]
        return formatter
    }
} 