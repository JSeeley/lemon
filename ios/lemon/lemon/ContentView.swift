//
//  ContentView.swift
//  lemon
//
//  Created by Big Gurl on 6/10/25.
//

import SwiftUI

struct ContentView: View {
    @State private var destination = ""
    @State private var startDate = Date()
    @State private var endDate = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()
    @State private var generatedItinerary: String?
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                Section("Trip Basics") {
                    TextField("Destination", text: $destination)
                    DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                    DatePicker("End Date", selection: $endDate, displayedComponents: .date)
                }

                Section {
                    Button(action: generatePlan) {
                        HStack {
                            if isLoading { ProgressView() }
                            Text("Generate Itinerary")
                        }
                    }
                    .disabled(isLoading || destination.isEmpty)
                }

                if let itinerary = generatedItinerary {
                    Section("Itinerary") {
                        Text(itinerary)
                            .font(.body)
                    }
                }

                if let error = errorMessage {
                    Section("Error") {
                        Text(error).foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("🍋 Lemon")
        }
    }

    private func generatePlan() {
        isLoading = true
        errorMessage = nil
        generatedItinerary = nil

        Task {
            do {
                let planner = TripPlannerService()
                let itinerary = try await planner.planTrip(destination: destination, startDate: startDate, endDate: endDate)
                generatedItinerary = itinerary
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }
}

#Preview {
    ContentView()
}
