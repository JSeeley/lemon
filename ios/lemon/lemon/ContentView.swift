//
//  ContentView.swift
//  lemon
//
//  Created by Big Gurl on 6/10/25.
//

import SwiftUI

// MARK: - Shared models

struct Stop: Codable, Identifiable {
    var id: String { name }
    let name: String
    let days: Int
    let hotel: String?
}

struct PlanData: Codable {
    let route: String
    let total_days: Int
    let daily_budget: Double
    let stops: [Stop]
}

/// Root view that hosts the TabView (Itinerary / To-Do / Chat).
struct ContentView: View {
    enum Tab { case itinerary, todo, chat }

    @State private var selectedTab: Tab = .chat
    @State private var plan: PlanData?

    var body: some View {
        TabView(selection: $selectedTab) {
            ItineraryTab(plan: plan)
                .tabItem { Label("Itinerary", systemImage: "map") }
                .tag(Tab.itinerary)

            TodoTab()
                .tabItem { Label("To-Do", systemImage: "checkmark") }
                .tag(Tab.todo)

            ChatTab { newPlan in
                self.plan = newPlan
                selectedTab = .itinerary
            }
            .tabItem { Label("Chat", systemImage: "bubble.left.and.bubble.right") }
            .tag(Tab.chat)
        }
    }
}

// MARK: - Itinerary Tab

struct ItineraryTab: View {
    let plan: PlanData?

    var body: some View {
        NavigationStack {
            if let plan {
                RouteView(route: plan.route, stops: plan.stops)
            } else {
                VStack(spacing: 16) {
                    Image(systemName: "map")
                        .font(.system(size: 48))
                        .foregroundColor(.gray)
                    Text("Your route will appear here once planned.")
                        .font(.headline)
                        .multilineTextAlignment(.center)
                        .padding()
                }
            }
        }
    }
}

// MARK: - To-Do Tab (placeholder)

struct TodoTab: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Image(systemName: "checkmark.circle")
                    .font(.system(size: 48))
                    .foregroundColor(.gray)
                Text("To-Do list coming soon!")
                    .font(.headline)
            }
            .padding()
        }
    }
}

// MARK: - Chat Tab

struct ChatTab: View {
    typealias RouteHandler = (PlanData) -> Void
    let onRouteDetected: RouteHandler

    struct Message: Identifiable {
        let id = UUID()
        let role: String
        let content: String
    }

    @State private var messages: [Message] = []
    @State private var inputText = ""
    @FocusState private var isInputFocused: Bool
    @State private var isSending = false
    @State private var errorMessage: String?

    private let chatService = ChatService()

    var body: some View {
        NavigationStack {
            VStack {
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(alignment: .leading, spacing: 12) {
                            ForEach(messages) { message in
                                ChatBubble(message: message)
                                    .id(message.id)
                            }
                        }
                        .padding()
                    }
                    .onChange(of: messages.count) { _, _ in
                        if let last = messages.last {
                            withAnimation {
                                proxy.scrollTo(last.id, anchor: .bottom)
                            }
                        }
                    }
                }

                if let errorMessage {
                    Text(errorMessage).foregroundColor(.red)
                }

                HStack {
                    TextField("Message", text: $inputText)
                        .focused($isInputFocused)
                        .submitLabel(.send)
                        .onSubmit(sendMessage)
                        .padding(12)
                        .background(Color(.secondarySystemBackground))
                        .clipShape(Capsule())
                }
                .padding()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(
                LinearGradient(colors: [Color.white, Color.yellow.opacity(0.15)], startPoint: .topLeading, endPoint: .bottomTrailing)
                    .ignoresSafeArea()
            )
            .navigationTitle("🍋 Chat")
            .onAppear {
                startNewSession()
                isInputFocused = true
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("New Session", action: startNewSession)
                }
            }
        }
    }

    // MARK: - Networking

    private func sendMessage() {
        let trimmed = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let userMsg = Message(role: "user", content: trimmed)
        messages.append(userMsg)
        inputText = ""
        isSending = true

        Task {
            defer {
                isSending = false
                isInputFocused = true
            }
            do {
                let dtoMsgs = messages.map { ChatMessageDTO(role: $0.role, content: $0.content, tool_calls: nil) }
                let assistantDTO = try await chatService.send(messages: dtoMsgs)
                if let text = assistantDTO.content, !text.isEmpty {
                    messages.append(Message(role: assistantDTO.role, content: text))

                    // Try to decode plan JSON first
                    if let data = text.data(using: .utf8),
                       let decoded = try? JSONDecoder().decode(PlanData.self, from: data) {
                        onRouteDetected(decoded)
                    } else if text.contains(" -> ") && text.components(separatedBy: "->").count >= 5 {
                        // Fallback to simple route detection (old format)
                        onRouteDetected(PlanData(route: text, total_days: 0, daily_budget: 0, stops: []))
                    }
                }
            } catch {
                errorMessage = error.localizedDescription
            }
        }

        // Immediately restore focus so keyboard stays up
        DispatchQueue.main.async {
            isInputFocused = true
        }
    }

    private func startNewSession() {
        messages.removeAll()
        errorMessage = nil
        inputText = ""

        Task {
            do {
                let assistantDTO = try await chatService.send(messages: [])
                if let text = assistantDTO.content {
                    messages.append(Message(role: assistantDTO.role, content: text))
                }
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    struct ChatBubble: View {
        let message: Message
        var isUser: Bool { message.role == "user" }

        var body: some View {
            HStack {
                if isUser { Spacer() }
                Text(isUser ? message.content : "🍋 " + message.content)
                    .padding(12)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(isUser ? Color.blue.opacity(0.4) : Color.yellow.opacity(0.6), lineWidth: 1)
                    )
                    .foregroundColor(.primary)
                    .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 2)
                if !isUser { Spacer() }
            }
            .padding(.horizontal, 4)
            .padding(.vertical, 2)
        }
    }
}

#Preview {
    ContentView()
}
