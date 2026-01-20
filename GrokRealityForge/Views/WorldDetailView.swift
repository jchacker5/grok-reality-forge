import SwiftUI
import PhotosUI

struct WorldDetailView: View {
    @EnvironmentObject var appModel: AppModel
    @Environment(\.openImmersiveSpace) private var openImmersiveSpace

    @State private var showingSettings = false
    @State private var selectedPhoto: PhotosPickerItem?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                PromptComposerView()

                WorldPreviewView(imageURL: appModel.currentImageURL)

                if appModel.settings.sharpEnabled {
                    HStack(spacing: 8) {
                        Image(systemName: "cube.transparent")
                        Text(appModel.isSharpProcessing ? "Building SHARP scene..." : "SHARP enabled")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }

                HStack(spacing: 12) {
                    Button("Enter Immersive") {
                        Task {
                            let result = await openImmersiveSpace(id: "ImmersiveWorld")
                            if case .error = result {
                                appModel.error = .apiError(message: "Unable to open immersive space.")
                            }
                        }
                    }
                    .buttonStyle(.borderedProminent)

                    if appModel.draftImageURL != nil {
                        Button("Save World") {
                            appModel.saveDraftAsWorld()
                        }
                        .buttonStyle(.bordered)
                    }

                    if let shareURL = appModel.currentImageURL {
                        ShareLink(item: shareURL) {
                            Label("Share", systemImage: "square.and.arrow.up")
                        }
                    }
                }

                if appModel.draftImageURL != nil {
                    HStack(spacing: 12) {
                        Button("Undo") { appModel.undoDraft() }
                            .buttonStyle(.bordered)
                        Button("Redo") { appModel.redoDraft() }
                            .buttonStyle(.bordered)
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Refine current world")
                        .font(.headline)
                    TextField("Add rain, change lighting...", text: $appModel.refinementText)
                        .textFieldStyle(.roundedBorder)
                    Button("Refine") {
                        appModel.refineDraft()
                    }
                    .buttonStyle(.bordered)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Insert photo")
                        .font(.headline)
                    PhotosPicker(selection: $selectedPhoto, matching: .images) {
                        Label("Choose Photo", systemImage: "photo")
                    }
                }

                if let error = appModel.error {
                    Text(error.localizedDescription)
                        .foregroundColor(.red)
                }
            }
            .padding(16)
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingSettings = true
                } label: {
                    Label("Settings", systemImage: "gear")
                }
            }
        }
        .onChange(of: selectedPhoto) { _, newValue in
            guard let newValue else { return }
            Task {
                if let data = try? await newValue.loadTransferable(type: Data.self) {
                    appModel.insertPhoto(data: data)
                }
            }
        }
        .onChange(of: appModel.settings.sharpEnabled) { _, _ in
            appModel.refreshSharpForCurrent()
        }
        .onChange(of: appModel.settings.sharpEndpoint) { _, _ in
            appModel.refreshSharpForCurrent()
        }
        .onChange(of: appModel.settings.sharpApiKey) { _, _ in
            appModel.refreshSharpForCurrent()
        }
    }
}
