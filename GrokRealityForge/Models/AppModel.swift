import Foundation
import SwiftUI

@MainActor
final class AppModel: ObservableObject {
    @Published var promptText: String = ""
    @Published var refinementText: String = ""
    @Published var options: GenerationOptions = .init()
    @Published var isGenerating: Bool = false
    @Published var draftImageURL: URL?
    @Published var draftPrompt: String = ""
    @Published var draftStyle: GenerationStyle = .photorealistic
    @Published var draftSize: ImageSize = .panorama1024
    @Published var currentWorld: World?
    @Published var sharpModelURL: URL?
    @Published var isSharpProcessing: Bool = false
    @Published var error: AppError?
    @Published var insertedPhotos: [InsertedPhoto] = []

    let store = WorldStore()
    @Published var settings = AppSettings()
    let quota = GenerationQuota()
    let history = PromptHistory()
    let networkMonitor = NetworkMonitor()
    let speechRecognizer = SpeechRecognizer()

    @AppStorage("starter_worlds_version") private var starterWorldsVersion: Int = 0
    private var isSeedingStarterWorlds = false

    private let keychain = KeychainService()
    private let generator = ImageGenerationService()
    private let sharpService = SharpService()

    private var undoStack: [URL] = []
    private var redoStack: [URL] = []

    init() {
        if keychain.readApiKey() == nil {
            let envKey = ProcessInfo.processInfo.environment["XAI_API_KEY"] ?? ""
            if !envKey.isEmpty {
                try? keychain.saveApiKey(envKey)
            }
        }
        #if DEBUG
        if keychain.readApiKey() == nil {
            let overrideKey = UserDefaults.standard.string(forKey: "xai_api_key_override") ?? ""
            if !overrideKey.isEmpty {
                try? keychain.saveApiKey(overrideKey)
            }
        }
        #endif
        if settings.apiModel == "grok-2-image" {
            settings.apiModel = "grok-2-image-1212"
        }
        if !settings.quality.isEmpty && !settings.apiModel.contains("imagine") {
            settings.quality = ""
        }
        if hasApiKey {
            seedStarterWorldsIfNeeded()
        }
    }

    var hasApiKey: Bool { effectiveApiKey != nil }

    private var effectiveApiKey: String? {
        if let key = keychain.readApiKey(), !key.isEmpty {
            return key
        }
        #if DEBUG
        let overrideKey = UserDefaults.standard.string(forKey: "xai_api_key_override") ?? ""
        if !overrideKey.isEmpty {
            return overrideKey
        }
        #endif
        return nil
    }

    var currentImageURL: URL? {
        if let world = currentWorld {
            return world.imageURL
        }
        return draftImageURL
    }

    func updateApiKey(_ key: String) {
        do {
            try keychain.saveApiKey(key)
            seedStarterWorldsIfNeeded()
        } catch {
            self.error = error as? AppError ?? .fileError(message: "Unable to store API key.")
        }
    }

    func seedStarterWorldsIfNeeded() {
        guard !isSeedingStarterWorlds else { return }
        guard starterWorldsVersion < StarterWorlds.version else { return }
        let existingPrompts = Set(store.worlds.map { $0.prompt })
        let missingPresets = StarterWorlds.presets.filter { !existingPrompts.contains($0.prompt) }
        guard !missingPresets.isEmpty else {
            starterWorldsVersion = StarterWorlds.version
            return
        }
        guard let apiKey = effectiveApiKey else { return }

        isSeedingStarterWorlds = true

        #if DEBUG
        print("Seeding starter worlds: \(StarterWorlds.presets.count)")
        let markerURL = FileManager.worldsDirectory.appendingPathComponent("seed_debug.txt")
        try? "seeding_started".write(to: markerURL, atomically: true, encoding: .utf8)
        #endif

        Task { @MainActor in
            var created = 0
            for preset in missingPresets {
                var presetOptions = GenerationOptions()
                presetOptions.style = preset.style
                presetOptions.variants = 1
                presetOptions.size = preset.size

                do {
                    let images = try await generator.generateImages(prompt: preset.prompt, options: presetOptions, settings: settings, apiKey: apiKey)
                    if let data = images.first {
                        let filename = "starter_\(UUID().uuidString).png"
                        let url = FileManager.worldsDirectory.appendingPathComponent(filename)
                        try data.write(to: url, options: .atomic)
                        let world = World(prompt: preset.prompt, style: preset.style, imageFilename: filename, imageSize: preset.size)
                        store.add(world)
                        created += 1
                        #if DEBUG
                        print("Seeded starter world: \(preset.title)")
                        #endif
                    }
                } catch {
                    self.error = error as? AppError ?? .apiError(message: error.localizedDescription)
                    #if DEBUG
                    print("Starter world seed failed: \(error)")
                    #endif
                }
            }

            if created == missingPresets.count {
                starterWorldsVersion = StarterWorlds.version
            }
            isSeedingStarterWorlds = false
        }
    }

    func generateDraft() {
        error = nil
        let trimmed = promptText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            error = .invalidPrompt
            return
        }
        guard let apiKey = effectiveApiKey else {
            error = .missingApiKey
            return
        }
        guard networkMonitor.isOnline else {
            error = .networkUnavailable
            return
        }
        guard quota.canConsume(options.variants) else {
            error = .apiError(message: "Daily free generations exhausted. Upgrade to continue.")
            return
        }

        isGenerating = true
        history.add(trimmed)

        Task {
            do {
                let images = try await generator.generateImages(prompt: trimmed, options: options, settings: settings, apiKey: apiKey)
                quota.consume(options.variants)
                if let data = images.first {
                    let url = try writeDraftImage(data)
                    setDraftImage(url)
                    draftPrompt = trimmed
                    draftStyle = options.style
                    draftSize = options.size
                    prepareSharpModelIfNeeded(imageURL: url, prompt: trimmed)
                }
                isGenerating = false
            } catch {
                self.error = error as? AppError ?? .apiError(message: error.localizedDescription)
                isGenerating = false
            }
        }
    }

    func refineDraft() {
        guard let baseImageURL = draftImageURL else {
            error = .apiError(message: "Generate a world before refining.")
            return
        }
        let trimmed = refinementText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            error = .invalidPrompt
            return
        }
        promptText = "\(draftPrompt). Update: \(trimmed)"
        refineFrom(baseImageURL: baseImageURL)
    }

    private func refineFrom(baseImageURL: URL) {
        error = nil
        guard let apiKey = effectiveApiKey else {
            error = .missingApiKey
            return
        }
        guard networkMonitor.isOnline else {
            error = .networkUnavailable
            return
        }

        isGenerating = true

        Task {
            do {
                let images = try await generator.generateImages(prompt: promptText, options: options, settings: settings, apiKey: apiKey)
                if let data = images.first {
                    let url = try writeDraftImage(data)
                    setDraftImage(url)
                    prepareSharpModelIfNeeded(imageURL: url, prompt: promptText)
                }
                isGenerating = false
            } catch {
                self.error = error as? AppError ?? .apiError(message: error.localizedDescription)
                isGenerating = false
            }
        }
    }

    func saveDraftAsWorld() {
        guard let draftImageURL else {
            error = .apiError(message: "No draft image to save.")
            return
        }
        do {
            let filename = "world_\(UUID().uuidString).png"
            let destination = FileManager.worldsDirectory.appendingPathComponent(filename)
            try FileManager.default.copyItem(at: draftImageURL, to: destination)
            let world = World(prompt: draftPrompt, style: draftStyle, imageFilename: filename, imageSize: draftSize)
            store.add(world)
            currentWorld = world
        } catch {
            self.error = .fileError(message: "Unable to save world.")
        }
    }

    func selectWorld(_ world: World) {
        currentWorld = world
        promptText = world.prompt
        draftPrompt = world.prompt
        draftStyle = world.style
        draftSize = world.imageSize
        options.style = world.style
        options.size = world.imageSize
        refinementText = ""
        prepareSharpModelIfNeeded(imageURL: world.imageURL, prompt: world.prompt)
    }

    func clearSelection() {
        currentWorld = nil
        sharpModelURL = nil
    }

    func deleteWorld(_ world: World) {
        store.delete(world)
        if currentWorld == world {
            currentWorld = nil
        }
    }

    func insertPhoto(data: Data) {
        let photo = InsertedPhoto(id: UUID(), imageData: data)
        insertedPhotos.append(photo)
    }

    func undoDraft() {
        guard let last = undoStack.popLast() else { return }
        if let current = draftImageURL { redoStack.append(current) }
        draftImageURL = last
    }

    func redoDraft() {
        guard let next = redoStack.popLast() else { return }
        if let current = draftImageURL { undoStack.append(current) }
        draftImageURL = next
    }

    func clearDraft() {
        draftImageURL = nil
        draftPrompt = ""
        refinementText = ""
        undoStack.removeAll()
        redoStack.removeAll()
        sharpModelURL = nil
    }

    private func setDraftImage(_ url: URL) {
        if let current = draftImageURL {
            undoStack.append(current)
        }
        redoStack.removeAll()
        draftImageURL = url
    }

    private func writeDraftImage(_ data: Data) throws -> URL {
        let filename = "draft_\(UUID().uuidString).png"
        let url = FileManager.draftDirectory.appendingPathComponent(filename)
        try data.write(to: url, options: .atomic)
        return url
    }

    func refreshSharpForCurrent() {
        let prompt = currentWorld?.prompt ?? draftPrompt
        prepareSharpModelIfNeeded(imageURL: currentImageURL, prompt: prompt)
    }

    private func prepareSharpModelIfNeeded(imageURL: URL?, prompt: String) {
        guard settings.sharpEnabled else {
            sharpModelURL = nil
            return
        }
        let endpoint = settings.sharpEndpoint.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !endpoint.isEmpty, let imageURL else {
            sharpModelURL = nil
            return
        }

        let cached = sharpService.cachedModelURL(for: imageURL)
        if FileManager.default.fileExists(atPath: cached.path) {
            sharpModelURL = cached
            return
        }

        isSharpProcessing = true
        Task { @MainActor in
            do {
                let modelURL = try await sharpService.generateModel(
                    imageURL: imageURL,
                    prompt: prompt,
                    endpoint: endpoint,
                    apiKey: settings.sharpApiKey
                )
                sharpModelURL = modelURL
            } catch {
                self.error = error as? AppError ?? .apiError(message: error.localizedDescription)
                sharpModelURL = nil
            }
            isSharpProcessing = false
        }
    }
}

struct InsertedPhoto: Identifiable, Equatable {
    let id: UUID
    let imageData: Data
}
