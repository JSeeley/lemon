import SwiftUI

struct ContentView: View {
    @State private var searchText = ""
    @State private var showingNewTripView = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    gradient: Gradient(colors: [Color.yellow.opacity(0.1), Color.white]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                VStack(spacing: 30) {
                    // Logo and Title
                    VStack(spacing: 10) {
                        Text("🍋")
                            .font(.system(size: 80))
                            .padding(.top, 50)
                        
                        Text("Lemon")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        Text("Your AI Travel Companion")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    // Search/Input Field
                    VStack(spacing: 20) {
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.gray)
                            TextField("Where do you want to go?", text: $searchText)
                                .textFieldStyle(PlainTextFieldStyle())
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(12)
                        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                        .padding(.horizontal)
                        
                        Button(action: {
                            showingNewTripView = true
                        }) {
                            HStack {
                                Image(systemName: "sparkles")
                                Text("Plan My Trip")
                                    .fontWeight(.semibold)
                            }
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color.yellow, Color.orange]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(12)
                            .shadow(color: Color.orange.opacity(0.3), radius: 5, x: 0, y: 3)
                        }
                        .padding(.horizontal)
                        .disabled(searchText.isEmpty)
                        .opacity(searchText.isEmpty ? 0.6 : 1.0)
                    }
                    
                    Spacer()
                    
                    // Quick Start Suggestions
                    VStack(alignment: .leading, spacing: 15) {
                        Text("Popular Destinations")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 15) {
                                ForEach(["Paris 🇫🇷", "Tokyo 🇯🇵", "Bali 🇮🇩", "New York 🇺🇸"], id: \.self) { destination in
                                    Button(action: {
                                        searchText = destination.components(separatedBy: " ")[0]
                                    }) {
                                        Text(destination)
                                            .padding(.horizontal, 20)
                                            .padding(.vertical, 10)
                                            .background(Color.yellow.opacity(0.2))
                                            .cornerRadius(20)
                                            .foregroundColor(.primary)
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    .padding(.bottom, 30)
                }
            }
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showingNewTripView) {
            TripPlanningView(destination: searchText)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}