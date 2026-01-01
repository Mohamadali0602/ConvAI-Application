import Foundation

/// Transcript message model used by LessonView to store streamed transcript chunks
struct TranscriptMessage: Identifiable, Codable, Equatable {
    let id: UUID
    let text: String
    let timestamp: Date
    let isComplete: Bool // Indicates whether this message is a completed chunk

    init(id: UUID = UUID(), text: String, timestamp: Date = Date(), isComplete: Bool = true) {
        self.id = id
        self.text = text
        self.timestamp = timestamp
        self.isComplete = isComplete
    }
}
