import SwiftUI
import RealityKit
import simd
#if canImport(UIKit)
import UIKit
#endif

struct ImmersiveWorldView: View {
    @EnvironmentObject var appModel: AppModel
    @StateObject private var renderer = ImmersiveRenderer()

    var body: some View {
        let _ = renderer.refreshToken
        return RealityView { content in
            renderer.setup(in: content)
        } update: { content in
            renderer.update(
                imageURL: appModel.currentImageURL,
                sharpURL: appModel.sharpModelURL,
                photos: appModel.insertedPhotos,
                in: content
            )
        }
    }
}

@MainActor
final class ImmersiveRenderer: ObservableObject {
    @Published var refreshToken = UUID()
    private var skyboxAnchor: AnchorEntity?
    private var skyboxEntity: ModelEntity?
    private var sharpAnchor: AnchorEntity?
    private var sharpEntity: ModelEntity?
    private var photoAnchor: AnchorEntity?
    private var photoEntities: [UUID: ModelEntity] = [:]
    private var pendingSkybox: ModelEntity?
    private var pendingSharp: ModelEntity?
    private var pendingPhotos: [UUID: ModelEntity] = [:]
    private var lastImageURL: URL?
    private var lastSharpURL: URL?

    func setup(in content: RealityViewContent) {
        if skyboxAnchor == nil {
            let anchor = AnchorEntity(.world(transform: matrix_identity_float4x4))
            skyboxAnchor = anchor
            content.add(anchor)
        }
        if sharpAnchor == nil {
            let anchor = AnchorEntity(.world(transform: matrix_identity_float4x4))
            sharpAnchor = anchor
            content.add(anchor)
        }
        if photoAnchor == nil {
            let anchor = AnchorEntity(.world(transform: matrix_identity_float4x4))
            photoAnchor = anchor
            content.add(anchor)
        }
    }

    func update(imageURL: URL?, sharpURL: URL?, photos: [InsertedPhoto], in content: RealityViewContent) {
        if lastImageURL != imageURL {
            lastImageURL = imageURL
            if let imageURL {
                loadSkybox(from: imageURL)
            }
        }
        if lastSharpURL != sharpURL {
            lastSharpURL = sharpURL
            if let sharpURL {
                loadSharpModel(from: sharpURL)
            } else {
                sharpEntity?.removeFromParent()
                sharpEntity = nil
            }
        }
        applyPending(in: content)
        syncPhotos(photos)
    }

    private func loadSkybox(from url: URL) {
        Task { @MainActor in
            do {
                let data = try Data(contentsOf: url)
                #if canImport(UIKit)
                guard let image = UIImage(data: data), let cgImage = image.cgImage else { return }
                let texture = try TextureResource.generate(from: cgImage, options: .init(semantic: .color))
                var material = UnlitMaterial()
                material.color = .init(texture: .init(texture))
                let mesh = MeshResource.generateSphere(radius: 8)
                let entity = ModelEntity(mesh: mesh, materials: [material])
                entity.scale = SIMD3<Float>(-1, 1, 1)
                pendingSkybox = entity
                refreshToken = UUID()
                #endif
            } catch {
                return
            }
        }
    }

    private func loadSharpModel(from url: URL) {
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let entity = try ModelEntity.loadModel(contentsOf: url)
                Task { @MainActor in
                    entity.position = .zero
                    self.pendingSharp = entity
                    self.refreshToken = UUID()
                }
            } catch {
                return
            }
        }
    }

    private func applyPending(in content: RealityViewContent) {
        if let anchor = skyboxAnchor, let pendingSkybox {
            if let skyboxEntity {
                skyboxEntity.removeFromParent()
            }
            anchor.addChild(pendingSkybox)
            skyboxEntity = pendingSkybox
            self.pendingSkybox = nil
        }

        if let anchor = sharpAnchor, let pendingSharp {
            if let sharpEntity {
                sharpEntity.removeFromParent()
            }
            anchor.addChild(pendingSharp)
            sharpEntity = pendingSharp
            self.pendingSharp = nil
        }

        if let skyboxEntity {
            skyboxEntity.isEnabled = (sharpEntity == nil)
        }

        if let anchor = photoAnchor, !pendingPhotos.isEmpty {
            for (id, entity) in pendingPhotos {
                anchor.addChild(entity)
                photoEntities[id] = entity
            }
            pendingPhotos.removeAll()
        }
    }

    private func syncPhotos(_ photos: [InsertedPhoto]) {
        let currentIDs = Set(photoEntities.keys)
        let incomingIDs = Set(photos.map { $0.id })

        for removed in currentIDs.subtracting(incomingIDs) {
            photoEntities[removed]?.removeFromParent()
            photoEntities.removeValue(forKey: removed)
        }

        for (index, photo) in photos.enumerated() {
            let position = SIMD3<Float>(Float(index) * 0.5, 1.2, -1.5)
            if let entity = photoEntities[photo.id] {
                entity.position = position
                continue
            }
            if let pending = pendingPhotos[photo.id] {
                pending.position = position
                continue
            }
            loadPhoto(photo, position: position)
        }
    }

    private func loadPhoto(_ photo: InsertedPhoto, position: SIMD3<Float>) {
        Task { @MainActor in
            do {
                let entity = try await PhotoPlaneEntity.make(from: photo.imageData)
                entity.position = position
                pendingPhotos[photo.id] = entity
                refreshToken = UUID()
            } catch {
                return
            }
        }
    }
}
