import Foundation
import RealityKit
#if canImport(UIKit)
import UIKit
#endif

enum PhotoPlaneEntity {
    static func make(from data: Data) async throws -> ModelEntity {
        #if canImport(UIKit)
        guard let image = UIImage(data: data), let cgImage = image.cgImage else {
            throw AppError.decodingFailed
        }
        let texture = try await TextureResource.generate(from: cgImage, options: .init(semantic: .color))
        var material = UnlitMaterial()
        material.color = .init(texture: .init(texture))
        let mesh = MeshResource.generatePlane(width: 0.8, height: 0.5)
        let entity = ModelEntity(mesh: mesh, materials: [material])
        entity.generateCollisionShapes(recursive: true)
        return entity
        #else
        throw AppError.decodingFailed
        #endif
    }
}
