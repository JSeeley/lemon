//
//  ContentView.swift
//  lemon
//
//  Created by Big Gurl on 6/10/25.
//

import SwiftUI

/// Root view that hosts the TabView (Itinerary / To-Do / Chat).
struct ContentView: View {
    enum Tab { case itinerary, todo, chat }

    @State private var selectedTab: Tab = .chat
    @State private var routeString: String?

    var body: some View {
        TabView(selection: $selectedTab) {
            ItineraryTab(route: routeString)
                .tabItem { Label("Itinerary", systemImage: "map") }
                .tag(Tab.itinerary)

            TodoTab()
                .tabItem { Label("To-Do", systemImage: "checkmark") }
                .tag(Tab.todo)

            ChatTab { newRoute in
                routeString = newRoute
                selectedTab = .itinerary
            }
            .tabItem { Label("Chat", systemImage: "bubble.left.and.bubble.right") }
            .tag(Tab.chat)
        }
    }
}

// MARK: - Itinerary Tab

struct ItineraryTab: View {
    let route: String?

    var body: some View {
        NavigationStack {
            if let route {                
                RouteView(route: route)
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
    typealias RouteHandler = (String) -> Void
    let onRouteDetected: RouteHandler

    struct Message: Identifiable {
        let id = UUID()
        let role: String
        let content: String
    }

    @State private var messages: [Message] = []
    @State private var inputText = ""
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
                        .textFieldStyle(.roundedBorder)
                        .submitLabel(.send)
                        .onSubmit(sendMessage)
                    Button(action: sendMessage) {
                        if isSending { ProgressView() } else { Image(systemName: "paperplane.fill") }
                    }
                    .tint(.yellow)
                    .disabled(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSending)
                }
                .padding()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(
                LinearGradient(colors: [Color.white, Color.yellow.opacity(0.15)], startPoint: .topLeading, endPoint: .bottomTrailing)
                    .ignoresSafeArea()
            )
            .navigationTitle("🍋 Chat")
            .onAppear(perform: startNewSession)
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
            defer { isSending = false }
            do {
                let dtoMsgs = messages.map { ChatMessageDTO(role: $0.role, content: $0.content, tool_calls: nil) }
                let assistantDTO = try await chatService.send(messages: dtoMsgs)
                if let text = assistantDTO.content, !text.isEmpty {
                    messages.append(Message(role: assistantDTO.role, content: text))

                    // Detect route pattern
                    if text.contains(" -> ") && text.components(separatedBy: "->").count >= 5 {
                        onRouteDetected(text)
                    }
                }
            } catch {
                errorMessage = error.localizedDescription
            }
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
