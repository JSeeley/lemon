import Foundation

struct TripPlannerService {
    private let baseURL: URL = {
        #if DEBUG
        return URL(string: "http://localhost:3000/api/plan")!
        #else
        return URL(string: "https://backend-h29njyqyn-jseeleys-projects.vercel.app/api/plan.js")!
        #endif
    }()

    func planTrip(destination: String, startDate: Date, endDate: Date) async throws -> String {
        var request = URLRequest(url: baseURL)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "destination": destination,
            "startDate": isoDateFormatter.string(from: startDate),
            "endDate": isoDateFormatter.string(from: endDate)
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
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