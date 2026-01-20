import SwiftUI

struct RootView: View {
    @EnvironmentObject var appModel: AppModel

    var body: some View {
        NavigationSplitView {
            WorldLibraryView(store: appModel.store)
        } detail: {
            WorldDetailView()
        }
    }
}
