import SwiftUI

struct PromptComposerView: View {
    @EnvironmentObject var appModel: AppModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Describe your world")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Jump-in scenes")
                .font(.headline)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(StarterWorlds.presets) { preset in
                        Button {
                            appModel.promptText = preset.prompt
                            appModel.options.style = preset.style
                            appModel.options.size = preset.size
                        } label: {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(preset.title)
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                Text(preset.style.label)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 6)
                            .padding(.horizontal, 10)
                        }
                        .buttonStyle(.bordered)
                    }
                }
            }

            HStack(spacing: 12) {
                TextField("A serene mountain lake at dawn...", text: $appModel.promptText, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                VoiceInputButton()
            }

            HStack {
                Picker("Style", selection: $appModel.options.style) {
                    ForEach(GenerationStyle.allCases) { style in
                        Text(style.label).tag(style)
                    }
                }
                .pickerStyle(.segmented)

                Stepper("Variants: \(appModel.options.variants)", value: $appModel.options.variants, in: 1...GenerationOptions.maxVariants)
                    .frame(maxWidth: 220)
            }

            Picker("Size", selection: $appModel.options.size) {
                ForEach(ImageSize.allCases) { size in
                    Text(size.label).tag(size)
                }
            }
            .pickerStyle(.menu)

            HStack(spacing: 12) {
                Button(action: appModel.generateDraft) {
                    Label(appModel.isGenerating ? "Generating..." : "Generate", systemImage: "sparkles")
                }
                .buttonStyle(.borderedProminent)
                .disabled(appModel.isGenerating)

                Text("Free generations left today: \(appModel.quota.remaining)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 8)
    }
}
