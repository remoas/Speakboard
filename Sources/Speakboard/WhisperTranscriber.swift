import Foundation
import FluidAudio
import AVFoundation

final class WhisperTranscriber {
    private var asrManager: AsrManager?
    private var models: AsrModels?

    // Streaming state
    private var audioSamples: [Float] = []
    private let sampleRate: Double = 16000

    var isInitialized: Bool {
        asrManager != nil && models != nil
    }

    func initialize(progress: @escaping (Double) -> Void) async throws {
        guard !isInitialized else {
            progress(1.0)
            return
        }

        progress(0.1)

        // Download and load Parakeet v3 model (multilingual, fast)
        NSLog("[Speakboard] Downloading Parakeet model...")
        models = try await AsrModels.downloadAndLoad(version: .v3)

        progress(0.5)

        // Initialize ASR manager
        NSLog("[Speakboard] Initializing ASR manager...")
        asrManager = AsrManager(config: .default)
        try await asrManager?.initialize(models: models!)

        progress(0.8)

        // Pre-warm the model with a tiny sample so first real transcription is fast
        NSLog("[Speakboard] Pre-warming model...")
        let warmupSamples = [Float](repeating: 0.0, count: 16000) // 1 second of silence
        _ = try? await asrManager?.transcribe(warmupSamples)

        progress(1.0)
        NSLog("[Speakboard] Parakeet model ready and warmed up!")
    }

    // Reset for new recording
    func startSession() {
        audioSamples = []
    }

    // Add audio samples during recording
    func addSamples(_ samples: [Float]) {
        audioSamples.append(contentsOf: samples)
    }

    // Fast transcription from accumulated samples using Parakeet
    func transcribeAccumulated() async throws -> String {
        guard let asrManager = asrManager else {
            throw TranscriberError.notInitialized
        }

        guard !audioSamples.isEmpty else {
            throw TranscriberError.invalidAudioFile
        }

        NSLog("[Speakboard] Transcribing \(audioSamples.count) samples with Parakeet...")

        let result = try await asrManager.transcribe(audioSamples)

        return result.text.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
    }
}

enum TranscriberError: Error, LocalizedError {
    case modelNotFound
    case modelLoadFailed
    case downloadFailed
    case notInitialized
    case invalidAudioFile
    case transcriptionFailed

    var errorDescription: String? {
        switch self {
        case .modelNotFound:
            return "Parakeet model not found. Please download it first."
        case .modelLoadFailed:
            return "Failed to load Parakeet model"
        case .downloadFailed:
            return "Failed to download Parakeet model"
        case .notInitialized:
            return "Transcriber not initialized"
        case .invalidAudioFile:
            return "Invalid audio file"
        case .transcriptionFailed:
            return "Transcription failed"
        }
    }
}
