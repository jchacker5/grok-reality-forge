import Foundation

final class WorldStore: ObservableObject {
    @Published private(set) var worlds: [World] = []

    private let storeURL: URL
    private let maxCachedWorlds = 5

    init() {
        storeURL = FileManager.worldsDirectory.appendingPathComponent("worlds.json")
        load()
    }

    func load() {
        guard FileManager.default.fileExists(atPath: storeURL.path) else {
            worlds = []
            return
        }
        do {
            let data = try Data(contentsOf: storeURL)
            worlds = try JSONDecoder().decode([World].self, from: data)
        } catch {
            worlds = []
        }
    }

    func add(_ world: World) {
        worlds.insert(world, at: 0)
        pruneIfNeeded()
        persist()
    }

    func delete(_ world: World) {
        if let index = worlds.firstIndex(of: world) {
            worlds.remove(at: index)
            try? FileManager.default.removeItem(at: world.imageURL)
            persist()
        }
    }

    private func persist() {
        do {
            let data = try JSONEncoder().encode(worlds)
            try data.write(to: storeURL, options: .atomic)
        } catch {
            // Swallow persistence errors for now.
        }
    }

    private func pruneIfNeeded() {
        if worlds.count > maxCachedWorlds {
            let overflow = worlds.suffix(from: maxCachedWorlds)
            for world in overflow {
                try? FileManager.default.removeItem(at: world.imageURL)
            }
            worlds = Array(worlds.prefix(maxCachedWorlds))
        }
    }
}
