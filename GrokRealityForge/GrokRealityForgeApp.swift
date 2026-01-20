import SwiftUI

@main
struct GrokRealityForgeApp: App {
    @StateObject private var appModel = AppModel()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appModel)
        }

        ImmersiveSpace(id: "ImmersiveWorld") {
            ImmersiveWorldView()
                .environmentObject(appModel)
        }
    }
}
