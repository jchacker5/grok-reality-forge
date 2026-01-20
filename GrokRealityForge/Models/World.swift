import Foundation

struct World: Identifiable, Codable, Equatable, Hashable {
    let id: UUID
    let prompt: String
    let style: GenerationStyle
    let createdAt: Date
    let imageFilename: String
    let imageSize: ImageSize

    init(id: UUID = UUID(), prompt: String, style: GenerationStyle, createdAt: Date = Date(), imageFilename: String, imageSize: ImageSize) {
        self.id = id
        self.prompt = prompt
        self.style = style
        self.createdAt = createdAt
        self.imageFilename = imageFilename
        self.imageSize = imageSize
    }

    var imageURL: URL {
        FileManager.worldsDirectory.appendingPathComponent(imageFilename)
    }
}
