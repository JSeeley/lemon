import SwiftUI
import Combine

struct TripPlanningView: View {
    @Environment(\.dismiss) var dismiss
    @State private var destination: String
    @State private var duration: String = ""
    @State private var preferences: String = ""
    @State private var budget: String = ""
    @State private var isLoading = false
    @State private var generatedItinerary: String? = nil
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var cancellables = Set<AnyCancellable>()
    
    let apiService = APIService.shared
    
    init(destination: String) {
        _destination = State(initialValue: destination)
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    if generatedItinerary == nil {
                        // Input Form
                        VStack(alignment: .leading, spacing: 15) {
                            Text("Plan Your Trip to \(destination)")
                                .font(.title2)
                                .fontWeight(.bold)
                                .padding(.horizontal)
                            
                            // Duration Input
                            VStack(alignment: .leading, spacing: 8) {
                                Label("Duration", systemImage: "calendar")
                                    .font(.headline)
                                TextField("e.g., 5 days, 1 week", text: $duration)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                            }
                            .padding(.horizontal)
                            
                            // Preferences Input
                            VStack(alignment: .leading, spacing: 8) {
                                Label("Travel Preferences", systemImage: "heart")
                                    .font(.headline)
                                TextField("e.g., family-friendly, adventure, cultural", text: $preferences)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                            }
                            .padding(.horizontal)
                            
                            // Budget Input
                            VStack(alignment: .leading, spacing: 8) {
                                Label("Budget", systemImage: "dollarsign.circle")
                                    .font(.headline)
                                TextField("e.g., $2000, budget-friendly, luxury", text: $budget)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                            }
                            .padding(.horizontal)
                            
                            // Generate Button
                            Button(action: generateItinerary) {
                                if isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .frame(maxWidth: .infinity)
                                } else {
                                    HStack {
                                        Image(systemName: "sparkles")
                                        Text("Generate Itinerary")
                                            .fontWeight(.semibold)
                                    }
                                    .frame(maxWidth: .infinity)
                                }
                            }
                            .foregroundColor(.white)
                            .padding()
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color.yellow, Color.orange]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(12)
                            .disabled(isLoading)
                            .padding(.horizontal)
                            .padding(.top, 10)
                        }
                    } else {
                        // Generated Itinerary Display
                        VStack(alignment: .leading, spacing: 20) {
                            HStack {
                                Text("Your Itinerary")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                Spacer()
                                Button("Edit") {
                                    withAnimation {
                                        generatedItinerary = nil
                                    }
                                }
                                .foregroundColor(.orange)
                            }
                            .padding(.horizontal)
                            
                            Text(generatedItinerary ?? "")
                                .font(.body)
                                .padding()
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(12)
                                .padding(.horizontal)
                            
                            // Save/Share Buttons
                            HStack(spacing: 15) {
                                Button(action: {
                                    // Save functionality
                                }) {
                                    Label("Save", systemImage: "square.and.arrow.down")
                                        .frame(maxWidth: .infinity)
                                }
                                .buttonStyle(.borderedProminent)
                                .tint(.orange)
                                
                                Button(action: shareItinerary) {
                                    Label("Share", systemImage: "square.and.arrow.up")
                                        .frame(maxWidth: .infinity)
                                }
                                .buttonStyle(.bordered)
                            }
                            .padding(.horizontal)
                        }
                    }
                }
                .padding(.vertical)
            }
            .navigationBarItems(
                leading: Button("Cancel") {
                    dismiss()
                }
                .foregroundColor(.orange)
            )
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private func generateItinerary() {
        isLoading = true
        
        apiService.planTrip(
            destination: destination,
            duration: duration.isEmpty ? nil : duration,
            preferences: preferences.isEmpty ? nil : preferences,
            budget: budget.isEmpty ? nil : budget
        )
        .sink(
            receiveCompletion: { completion in
                isLoading = false
                if case .failure(let error) = completion {
                    errorMessage = error.localizedDescription
                    showError = true
                }
            },
            receiveValue: { tripPlan in
                withAnimation {
                    generatedItinerary = tripPlan.itinerary
                }
            }
        )
        .store(in: &cancellables)
    }
    
    private func shareItinerary() {
        guard let itinerary = generatedItinerary else { return }
        
        let textToShare = "My \(destination) Trip Itinerary\n\n\(itinerary)\n\nPlanned with Lemon 🍋"
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            let activityVC = UIActivityViewController(
                activityItems: [textToShare],
                applicationActivities: nil
            )
            window.rootViewController?.present(activityVC, animated: true)
        }
    }
}

struct TripPlanningView_Previews: PreviewProvider {
    static var previews: some View {
        TripPlanningView(destination: "Paris")
    }
}