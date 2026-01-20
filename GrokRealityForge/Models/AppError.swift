import Foundation

enum AppError: LocalizedError, Identifiable {
    case missingApiKey
    case invalidPrompt
    case networkUnavailable
    case apiError(message: String)
    case decodingFailed
    case fileError(message: String)
    case speechUnavailable

    var id: String { localizedDescription }

    var errorDescription: String? {
        switch self {
        case .missingApiKey:
            return "Missing xAI API key. Add it in Settings."
        case .invalidPrompt:
            return "Please enter a prompt before generating."
        case .networkUnavailable:
            return "Network unavailable. Connect to Wi-Fi and try again."
        case .apiError(let message):
            return message
        case .decodingFailed:
            return "Unable to decode the generation response."
        case .fileError(let message):
            return message
        case .speechUnavailable:
            return "Speech recognition is unavailable."
        }
    }
}
