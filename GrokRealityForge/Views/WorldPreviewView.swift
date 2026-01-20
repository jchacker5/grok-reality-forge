import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct WorldPreviewView: View {
    let imageURL: URL?

    var body: some View {
        Group {
            if let image = loadImage() {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .cornerRadius(12)
            } else {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.gray.opacity(0.2))
                    Text("No preview yet")
                        .foregroundColor(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity, minHeight: 220)
    }

    private func loadImage() -> UIImage? {
        #if canImport(UIKit)
        guard let url = imageURL else { return nil }
        return UIImage(contentsOfFile: url.path)
        #else
        return nil
        #endif
    }
}
