//
//  ContentView.swift
//  lemon
//
//  Created by Big Gurl on 6/10/25.
//

import SwiftUI

struct ContentView: View {
    struct Message: Identifiable {
        let id = UUID()
        let role: String // "user" or "assistant"
        let content: String
    }

    @State private var messages: [Message] = []
    @State private var inputText: String = ""
    @State private var isSending = false
    @State private var showingRoute = false
    @State private var routeString: String?
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

                if let error = errorMessage {
                    Text(error).foregroundColor(.red)
                }

                HStack {
                    TextField("Message", text: $inputText)
                        .textFieldStyle(.roundedBorder)
                        .submitLabel(.send)
                        .onSubmit(sendMessage)
                    Button(action: sendMessage) {
                        if isSending {
                            ProgressView()
                        } else {
                            Image(systemName: "paperplane.fill")
                        }
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
            .navigationTitle("🍋 Lemon")
            .onAppear {
                if messages.isEmpty {
                    startNewSession()
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("New Session") {
                        startNewSession()
                    }
                }
            }
            .sheet(isPresented: $showingRoute) {
                if let route = routeString {
                    RouteView(route: route)
                }
            }
        }
    }

    private func sendMessage() {
        let trimmed = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let userMsg = Message(role: "user", content: trimmed)
        messages.append(userMsg)
        inputText = ""
        isSending = true

        Task {
            do {
                let dtoMsgs = messages.map { ChatMessageDTO(role: $0.role, content: $0.content, tool_calls: nil) }
                let assistantDTO = try await chatService.send(messages: dtoMsgs)
                if let text = assistantDTO.content, !text.isEmpty {
                    let assistantMsg = Message(role: assistantDTO.role, content: text)
                    messages.append(assistantMsg)

                    // Detect single-line route pattern with arrows
                    if text.contains(" -> ") && text.components(separatedBy: "->").count >= 5 {
                        routeString = text
                        showingRoute = true
                    }
                }
                if let calls = assistantDTO.tool_calls {
                    // For now, just show a placeholder message that the request was submitted
                    for call in calls {
                        let text = "\u{2705} Called \(call.function.name) with args: \(call.function.arguments)"
                        let callMsg = Message(role: assistantDTO.role, content: text)
                        messages.append(callMsg)
                    }
                }
            } catch {
                errorMessage = error.localizedDescription
            }
            isSending = false
        }
    }

    // MARK: - Session helpers

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
