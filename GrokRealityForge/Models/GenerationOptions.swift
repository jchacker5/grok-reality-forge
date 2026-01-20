import Foundation

enum GenerationStyle: String, CaseIterable, Identifiable, Codable, Hashable {
    case photorealistic
    case artistic

    var id: String { rawValue }
    var label: String {
        switch self {
        case .photorealistic: return "Photorealistic"
        case .artistic: return "Artistic"
        }
    }
}

enum ImageSize: String, CaseIterable, Identifiable, Codable, Hashable {
    case panorama1024 = "1024x512"
    case panorama2048 = "2048x1024"

    var id: String { rawValue }
    var label: String {
        switch self {
        case .panorama1024: return "Panorama 1024x512"
        case .panorama2048: return "Panorama 2048x1024"
        }
    }

    var width: Int {
        switch self {
        case .panorama1024: return 1024
        case .panorama2048: return 2048
        }
    }

    var height: Int {
        switch self {
        case .panorama1024: return 512
        case .panorama2048: return 1024
        }
    }
}

struct GenerationOptions: Equatable {
    var style: GenerationStyle = .photorealistic
    var variants: Int = 1
    var size: ImageSize = .panorama1024

    static let maxVariants = 4
}
