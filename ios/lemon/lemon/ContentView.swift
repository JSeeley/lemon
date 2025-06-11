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
    @State private var errorMessage: String?

    private let chatService = ChatService()

    var body: some View {
        NavigationStack {
            VStack {
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(alignment: .leading, spacing: 12) {
                            ForEach(messages) { message in
                                HStack {
                                    if message.role == "assistant" {
                                        Text(message.content)
                                            .padding(8)
                                            .background(Color.gray.opacity(0.2))
                                            .cornerRadius(10)
                                        Spacer()
                                    } else {
                                        Spacer()
                                        Text(message.content)
                                            .padding(8)
                                            .background(Color.blue.opacity(0.8))
                                            .foregroundColor(.white)
                                            .cornerRadius(10)
                                    }
                                }
                                .id(message.id)
                            }
                        }
                        .padding()
                    }
                    .onChange(of: messages.count) { _ in
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
                    Button(action: sendMessage) {
                        if isSending {
                            ProgressView()
                        } else {
                            Image(systemName: "paperplane.fill")
                        }
                    }
                    .disabled(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSending)
                }
                .padding()
            }
            .navigationTitle("🍋 Lemon")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("New Session") {
                        messages.removeAll()
                        errorMessage = nil
                        inputText = ""
                    }
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
                let dtoMsgs = messages.map { ChatMessageDTO(role: $0.role, content: $0.content) }
                let assistantDTO = try await chatService.send(messages: dtoMsgs)
                let assistantMsg = Message(role: assistantDTO.role, content: assistantDTO.content)
                messages.append(assistantMsg)
            } catch {
                errorMessage = error.localizedDescription
            }
            isSending = false
        }
    }
}

#Preview {
    ContentView()
}
