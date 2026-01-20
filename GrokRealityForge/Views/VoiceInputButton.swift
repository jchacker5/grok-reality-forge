import SwiftUI

struct VoiceInputButton: View {
    @EnvironmentObject var appModel: AppModel

    var body: some View {
        Button(action: toggleRecording) {
            Image(systemName: appModel.speechRecognizer.isRecording ? "stop.circle.fill" : "mic.circle")
                .font(.title2)
        }
        .buttonStyle(.bordered)
        .onReceive(appModel.speechRecognizer.$transcript) { transcript in
            guard appModel.speechRecognizer.isRecording else { return }
            appModel.promptText = transcript
        }
    }

    private func toggleRecording() {
        if appModel.speechRecognizer.isRecording {
            appModel.speechRecognizer.stopRecording()
            return
        }
        do {
            try appModel.speechRecognizer.startRecording()
        } catch {
            appModel.error = .speechUnavailable
        }
    }
}
