import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct WorldCardView: View {
    let world: World
    let isSelected: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack {
                if let image = loadImage() {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                } else {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.gray.opacity(0.2))
                    Text("No image")
                        .foregroundColor(.secondary)
                }
            }
            .frame(height: 140)
            .clipShape(RoundedRectangle(cornerRadius: 12))

            Text(world.prompt)
                .font(.headline)
                .lineLimit(2)

            Text(world.createdAt, style: .date)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(12)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
        )
    }

    private func loadImage() -> UIImage? {
        #if canImport(UIKit)
        return UIImage(contentsOfFile: world.imageURL.path)
        #else
        return nil
        #endif
    }
}
