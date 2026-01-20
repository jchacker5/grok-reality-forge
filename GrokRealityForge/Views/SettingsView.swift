import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var appModel: AppModel
    @Environment(\.dismiss) private var dismiss

    @State private var apiKey: String = ""
    @State private var showKey: Bool = false

    private let keychain = KeychainService()

    var body: some View {
        NavigationStack {
            Form {
                Section("xAI API") {
                    if showKey {
                        TextField("API Key", text: $apiKey)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                    } else {
                        SecureField("API Key", text: $apiKey)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                    }
                    Toggle("Show key", isOn: $showKey)

                    TextField("Endpoint", text: $appModel.settings.apiEndpoint)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    TextField("Model", text: $appModel.settings.apiModel)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    TextField("Response format", text: $appModel.settings.responseFormat)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    TextField("Quality", text: $appModel.settings.quality)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }

                Section("SHARP (Experimental)") {
                    Toggle("Enable SHARP", isOn: $appModel.settings.sharpEnabled)

                    TextField("SHARP Endpoint", text: $appModel.settings.sharpEndpoint)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    SecureField("SHARP API Key (optional)", text: $appModel.settings.sharpApiKey)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()

                    Text("Requires a SHARP-compatible service that returns a USDZ model.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Section {
                    Button("Save API Key") {
                        appModel.updateApiKey(apiKey)
                        dismiss()
                    }
                    .buttonStyle(.borderedProminent)

                    Button("Delete API Key", role: .destructive) {
                        keychain.deleteApiKey()
                        apiKey = ""
                    }
                }
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .onAppear {
            if let stored = keychain.readApiKey() {
                apiKey = stored
            }
        }
    }
}
