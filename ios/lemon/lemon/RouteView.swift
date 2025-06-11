import SwiftUI

/// Presents a city-to-city route like "Paris -> Fly 8 h -> Rome -> Train 3 h -> Paris" in a graphic timeline.
struct RouteView: View {
    struct Leg: Identifiable {
        let id = UUID()
        let fromCity: String
        let transportEmoji: String
        let duration: String
    }

    private let legs: [Leg]
    private let finalCity: String

    init(route: String) {
        // Very simple parser for the "City -> Transport & duration -> City" format
        // Split on arrow, trim whitespace
        let tokens = route.components(separatedBy: "->")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        var tmpLegs: [Leg] = []
        var i = 0
        while i + 2 < tokens.count { // ensure city, transport, city triple
            let cityA = tokens[i]
            let transportSegment = tokens[i + 1]
            let cityB = tokens[i + 2]

            let (emoji, duration) = RouteView.parseTransport(transportSegment)
            tmpLegs.append(Leg(fromCity: cityA, transportEmoji: emoji, duration: duration))
            i += 2 // Move to next city as start of next leg (overlap one token)
        }
        self.legs = tmpLegs
        self.finalCity = tokens.last ?? ""
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                ForEach(legs) { leg in
                    Text(leg.fromCity)
                        .font(.title2)
                        .padding(.top, leg.id == legs.first?.id ? 0 : 20)

                    HStack(alignment: .center) {
                        ZStack {
                            // Dashed baseline
                            Rectangle()
                                .foregroundColor(.clear)
                                .frame(height: 1)
                                .overlay(
                                    Rectangle()
                                        .stroke(style: StrokeStyle(lineWidth: 1, dash: [6]))
                                        .foregroundColor(.gray.opacity(0.5))
                                )

                            // Emoji + duration badge
                            HStack(spacing: 4) {
                                Text(leg.transportEmoji)
                                Text(leg.duration)
                                    .font(.subheadline)
                            }
                            .padding(.horizontal, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color(.systemBackground))
                            )
                        }
                    }
                    .padding(.horizontal)
                }

                // Final city
                Text(finalCity)
                    .font(.title2)
                    .padding(.top, 20)
            }
            .padding()
        }
        .navigationTitle("Trip Route")
    }

    static func parseTransport(_ segment: String) -> (String, String) {
        let lower = segment.lowercased()
        let emoji: String
        if lower.contains("fly") || lower.contains("plane") || lower.contains("flight") {
            emoji = "✈️"
        } else if lower.contains("train") {
            emoji = "🚆"
        } else if lower.contains("bus") {
            emoji = "🚌"
        } else {
            emoji = "🚗"
        }

        // Remove transport words to leave duration text
        var duration = segment.replacingOccurrences(of: "(?i)(fly|flight|plane|by plane|train|by train|drive|driving|car|bus|by bus)", with: "", options: .regularExpression)
        // Remove common extra symbols such as "&" or "~"
        duration = duration.replacingOccurrences(of: "&", with: "")
        duration = duration.replacingOccurrences(of: "~", with: "")
        duration = duration.trimmingCharacters(in: .whitespaces)
        return (emoji, duration)
    }
}

#Preview {
    RouteView(route: "Chicago -> Fly 8 h -> Paris -> Train 11 h -> Rome -> Fly 10 h -> Chicago")
} 