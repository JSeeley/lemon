import SwiftUI

/// Visualizes a route with expandable city cards connected by vertical dotted lines that show transport info.
struct RouteView: View {

    // MARK: - Data models
    struct City: Identifiable {
        let id = UUID()
        let name: String
        let days: Int?
        let hotel: String?
    }

    struct Transport: Identifiable {
        let id = UUID()
        let emoji: String
        let duration: String
    }

    private let cities: [City]
    private let transports: [Transport] // transports[i] connects cities[i] -> cities[i+1]

    private let stopsByCity: [String: (days: Int, hotel: String?)]

    // Track which cards are expanded
    @State private var expandedIDs: Set<UUID> = []

    init(route: String, stops: [Stop] = []) {
        var sbc: [String: (days: Int, hotel: String?)] = [:]
        stops.forEach { sbc[$0.name] = ($0.days, $0.hotel) }
        self.stopsByCity = sbc

        // Parse "City -> Transport & duration -> City" repeated tokens
        let tokens = route.components(separatedBy: "->")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines).trimmingCharacters(in: CharacterSet(charactersIn: ".")) }
            .filter { !$0.isEmpty }

        var tmpCities: [City] = []
        var tmpTransports: [Transport] = []

        var i = 0
        while i < tokens.count {
            // Expect pattern city, transport, city, transport, ... ending with city
            let cityName = tokens[i]
            tmpCities.append(City(name: cityName, days: sbc[cityName]?.days, hotel: sbc[cityName]?.hotel))

            if i + 2 < tokens.count {
                let transportSegment = tokens[i + 1]
                let (emoji, duration) = RouteView.parseTransport(transportSegment)
                tmpTransports.append(Transport(emoji: emoji, duration: duration))
            }
            i += 2
        }

        self.cities = tmpCities
        self.transports = tmpTransports
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .center, spacing: 0) {
                ForEach(cities.indices, id: \.self) { idx in
                    let city = cities[idx]

                    CityCard(city: city,
                             isExpanded: expandedIDs.contains(city.id),
                             toggle: { toggle(city.id) })

                    if idx < transports.count {
                        TransportConnector(transport: transports[idx])
                    }
                }
            }
            .padding(.vertical)
        }
        .navigationTitle("Trip Route")
    }

    private func toggle(_ id: UUID) {
        if expandedIDs.contains(id) {
            expandedIDs.remove(id)
        } else {
            expandedIDs.insert(id)
        }
    }

    // MARK: - Sub-Views

    struct CityCard: View {
        let city: City
        let isExpanded: Bool
        let toggle: () -> Void

        var body: some View {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(city.name)
                            .font(.title3.weight(.semibold))
                        if let d = city.days {
                            Text("\(d) days")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    Spacer()
                    Image(systemName: "chevron.down")
                        .rotationEffect(isExpanded ? Angle(degrees: 180) : .zero)
                        .foregroundColor(.gray)
                }
                .contentShape(Rectangle())
                .onTapGesture(perform: toggle)

                if isExpanded {
                    Divider()
                    VStack(alignment: .leading, spacing: 6) {
                        if let hotel = city.hotel {
                            ToDoRow(title: "Lodging: \(hotel)")
                        } else {
                            ToDoRow(title: "Lodging (TBD)")
                        }
                        ToDoRow(title: "Dinner")
                    }
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.yellow.opacity(0.6), lineWidth: 1)
            )
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
    }

    struct ToDoRow: View {
        let title: String
        var body: some View {
            HStack {
                Image(systemName: "square") // empty checkbox
                    .foregroundColor(.gray)
                Text(title)
                    .foregroundColor(.primary)
                Spacer()
            }
            .padding(8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(.secondarySystemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.yellow.opacity(0.6), lineWidth: 1)
            )
            .font(.subheadline)
        }
    }

    struct TransportConnector: View {
        let transport: Transport

        var body: some View {
            VStack(spacing: 4) {
                DottedLine()
                    .frame(width: 1, height: 20)

                HStack(spacing: 4) {
                    Text(transport.emoji)
                    Text(transport.duration)
                        .font(.subheadline)
                }

                DottedLine()
                    .frame(width: 1, height: 20)
            }
            .frame(maxWidth: .infinity)
        }
    }

    struct DottedLine: View {
        var body: some View {
            Rectangle()
                .foregroundColor(.clear)
                .overlay(
                    Rectangle()
                        .stroke(style: StrokeStyle(lineWidth: 1, dash: [4]))
                        .foregroundColor(.gray.opacity(0.5))
                )
        }
    }

    // MARK: - Parser helpers

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

        var duration = segment.replacingOccurrences(of: "(?i)(fly|flight|plane|by plane|train|by train|drive|driving|car|bus|by bus)", with: "", options: .regularExpression)
        duration = duration.replacingOccurrences(of: "&", with: "")
        duration = duration.replacingOccurrences(of: "~", with: "")
        duration = duration.trimmingCharacters(in: .whitespaces)
        return (emoji, duration)
    }
}

#Preview {
    RouteView(route: "Seattle -> Fly 10h -> Paris -> Train 6h -> Toulouse -> Car 3h -> Gordes -> Car 1.5h -> Saint Tropez -> Car 1.5h -> Nice -> Train 5h -> Paris -> Fly 10h -> Seattle", stops: [])
} 