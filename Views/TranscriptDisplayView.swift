import SwiftUI

/// Transcript display component that shows AI conversation transcripts with smooth scrolling
struct TranscriptDisplayView: View {
    let messages: [TranscriptMessage]
    let currentChunk: String
    let onScroll: ((ScrollViewProxy) -> Void)?
    
    // Show only last 2 messages by default, with scrolling for more
    private var displayMessages: [TranscriptMessage] {
        Array(messages.suffix(2))
    }
    
    private var hasMoreMessages: Bool {
        messages.count > 2
    }
    
    init(messages: [TranscriptMessage], currentChunk: String = "", onScroll: ((ScrollViewProxy) -> Void)? = nil) {
        self.messages = messages
        self.currentChunk = currentChunk
        self.onScroll = onScroll
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Scroll indicator if there are more messages
            if hasMoreMessages {
                HStack {
                    Text("↑ \(messages.count - 2) more messages")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.top, 8)
            }
            
            // Scrollable transcript content
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 8) {
                        // All messages (for scrolling history)
                        ForEach(messages) { message in
                            TranscriptMessageView(message: message)
                                .id(message.id)
                        }
                        
                        // Current streaming chunk (if any)
                        if !currentChunk.isEmpty {
                            TranscriptMessageView(
                                message: TranscriptMessage(
                                    text: currentChunk,
                                    isComplete: false
                                )
                            )
                            .id("current-chunk")
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                }
                .onChange(of: messages.count) { _ in
                    // Auto-scroll to latest message
                    withAnimation(.easeOut(duration: 0.3)) {
                        if let lastMessage = messages.last {
                            proxy.scrollTo(lastMessage.id, anchor: .bottom)
                        }
                    }
                }
                .onChange(of: currentChunk) { _ in
                    // Auto-scroll while streaming
                    if !currentChunk.isEmpty {
                        withAnimation(.easeOut(duration: 0.2)) {
                            proxy.scrollTo("current-chunk", anchor: .bottom)
                        }
                    }
                }
                .onAppear {
                    onScroll?(proxy)
                }
            }
        }
        .frame(height: 120) // Fixed height as specified
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
    }
}

/// Individual transcript message view
struct TranscriptMessageView: View {
    let message: TranscriptMessage
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            // AI indicator
            Image(systemName: "brain.head.profile")
                .font(.caption)
                .foregroundColor(.blue)
                .frame(width: 16)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(message.text)
                    .font(.subheadline)
                    .foregroundColor(message.isComplete ? .primary : .secondary)
                    .multilineTextAlignment(.leading)
                    .animation(.easeIn(duration: 0.2), value: message.text)
                
                if message.isComplete {
                    Text(message.timestamp, style: .time)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
        .opacity(message.isComplete ? 1.0 : 0.7)
        .animation(.easeIn(duration: 0.3), value: message.isComplete)
    }
}

// MARK: - Preview
struct TranscriptDisplayView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            TranscriptDisplayView(
                messages: [
                    TranscriptMessage(text: "Hello! I'm here to help you practice your conversation skills. What would you like to work on today?"),
                    TranscriptMessage(text: "Great choice! Let's start with some basic introductions. How would you introduce yourself in a professional setting?")
                ],
                currentChunk: "Remember to maintain eye contact and..."
            )
            .padding()
        }
        .previewLayout(.sizeThatFits)
    }
}
