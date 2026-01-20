import SwiftUI

@main
struct GrokRealityForgeApp: App {
    @StateObject private var appModel = AppModel()
    @State private var immersionStyle: ImmersionStyle = .full

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appModel)
        }
        .immersionStyle(selection: $immersionStyle, in: .mixed, .full)

        ImmersiveSpace(id: "ImmersiveWorld") {
            ImmersiveWorldView()
                .environmentObject(appModel)
        }
    }
}
