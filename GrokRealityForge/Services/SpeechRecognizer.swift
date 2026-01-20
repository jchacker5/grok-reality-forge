import Foundation
import Speech
import AVFoundation

final class SpeechRecognizer: ObservableObject {
    @Published private(set) var transcript: String = ""
    @Published private(set) var isRecording: Bool = false
    @Published private(set) var isAuthorized: Bool = false

    private let recognizer = SFSpeechRecognizer()
    private let audioEngine = AVAudioEngine()
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?

    init() {
        requestAuthorization()
    }

    func requestAuthorization() {
        SFSpeechRecognizer.requestAuthorization { [weak self] status in
            DispatchQueue.main.async {
                self?.isAuthorized = (status == .authorized)
            }
        }
    }

    func startRecording() throws {
        guard isAuthorized else { throw AppError.speechUnavailable }
        if audioEngine.isRunning {
            stopRecording()
        }

        let session = AVAudioSession.sharedInstance()
        switch session.recordPermission {
        case .undetermined:
            session.requestRecordPermission { _ in }
            throw AppError.speechUnavailable
        case .denied:
            throw AppError.speechUnavailable
        case .granted:
            break
        @unknown default:
            throw AppError.speechUnavailable
        }

        try session.setCategory(.record, mode: .measurement, options: [.duckOthers])
        try session.setActive(true, options: .notifyOthersOnDeactivation)

        transcript = ""
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest else { throw AppError.speechUnavailable }
        recognitionRequest.shouldReportPartialResults = true

        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.inputFormat(forBus: 0)
        guard recordingFormat.sampleRate > 0, recordingFormat.channelCount > 0 else {
            throw AppError.speechUnavailable
        }
        inputNode.removeTap(onBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
            self?.recognitionRequest?.append(buffer)
        }

        audioEngine.prepare()
        try audioEngine.start()
        isRecording = true

        recognitionTask = recognizer?.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            DispatchQueue.main.async {
                if let result {
                    self?.transcript = result.bestTranscription.formattedString
                }
                if error != nil {
                    self?.stopRecording()
                }
            }
        }
    }

    func stopRecording() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        recognitionRequest = nil
        recognitionTask = nil
        isRecording = false
    }
}
