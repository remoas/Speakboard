import Foundation
import Combine

enum RecordingState: Equatable {
    case idle
    case recording
    case transcribing

    var statusText: String {
        switch self {
        case .idle:
            return "Ready"
        case .recording:
            return "Recording..."
        case .transcribing:
            return "Transcribing..."
        }
    }

    var iconName: String {
        switch self {
        case .idle:
            return "mic"
        case .recording:
            return "mic.fill"
        case .transcribing:
            return "waveform"
        }
    }
}

@MainActor
final class AppState: ObservableObject {
    static let shared = AppState()

    @Published var recordingState: RecordingState = .idle
    @Published var lastTranscription: String = ""
    @Published var errorMessage: String?
    @Published var hasAccessibilityPermission: Bool = false
    @Published var hasMicrophonePermission: Bool = false

    private init() {}

    func setRecording() {
        recordingState = .recording
        errorMessage = nil
    }

    func setTranscribing() {
        recordingState = .transcribing
    }

    func setIdle() {
        recordingState = .idle
    }

    func setError(_ message: String) {
        errorMessage = message
        recordingState = .idle
    }

    func setTranscription(_ text: String) {
        lastTranscription = text
        recordingState = .idle
    }
}
