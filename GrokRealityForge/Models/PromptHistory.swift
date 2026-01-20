import Foundation

final class PromptHistory: ObservableObject {
    private let storageKey = "prompt_history"
    @Published private(set) var prompts: [String]

    init() {
        prompts = UserDefaults.standard.stringArray(forKey: storageKey) ?? []
    }

    func add(_ prompt: String) {
        let trimmed = prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        if let index = prompts.firstIndex(of: trimmed) {
            prompts.remove(at: index)
        }
        prompts.insert(trimmed, at: 0)
        if prompts.count > 20 {
            prompts.removeLast(prompts.count - 20)
        }
        UserDefaults.standard.set(prompts, forKey: storageKey)
    }
}
