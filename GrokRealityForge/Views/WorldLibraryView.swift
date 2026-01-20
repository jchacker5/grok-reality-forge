import SwiftUI

struct WorldLibraryView: View {
    @EnvironmentObject var appModel: AppModel
    @ObservedObject var store: WorldStore
    @Environment(\.openImmersiveSpace) private var openImmersiveSpace

    var body: some View {
        VStack(alignment: .leading) {
            Text("My Worlds")
                .font(.title2)
                .fontWeight(.semibold)
                .padding(.top, 8)

            if store.worlds.isEmpty {
                Text("Generate a world to see it here.")
                    .foregroundColor(.secondary)
                    .padding(.vertical, 12)
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(store.worlds) { world in
                            Button {
                                appModel.selectWorld(world)
                                Task { await openImmersiveSpace(id: "ImmersiveWorld") }
                            } label: {
                                WorldCardView(world: world, isSelected: appModel.currentWorld?.id == world.id)
                            }
                            .buttonStyle(.plain)
                            .contextMenu {
                                Button(role: .destructive) {
                                    appModel.deleteWorld(world)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }
            }

            if appModel.draftImageURL != nil {
                Button("Clear Draft") {
                    appModel.clearDraft()
                }
                .buttonStyle(.bordered)
                .padding(.bottom, 8)
            }
        }
        .padding(.horizontal, 12)
    }
}
