import AVFoundation
import Foundation

final class AudioRecorder {
    private var audioEngine: AVAudioEngine?
    private var converter: AVAudioConverter?
    private var outputFormat: AVAudioFormat?

    // Callback to stream samples
    var onSamples: (([Float]) -> Void)?

    var isRecording: Bool {
        audioEngine?.isRunning ?? false
    }

    func requestPermission() async -> Bool {
        await withCheckedContinuation { continuation in
            AVCaptureDevice.requestAccess(for: .audio) { granted in
                continuation.resume(returning: granted)
            }
        }
    }

    func checkPermission() -> Bool {
        AVCaptureDevice.authorizationStatus(for: .audio) == .authorized
    }

    func startRecording() throws {
        audioEngine = AVAudioEngine()
        guard let audioEngine = audioEngine else {
            throw AudioRecorderError.engineInitFailed
        }

        let inputNode = audioEngine.inputNode
        let inputFormat = inputNode.outputFormat(forBus: 0)

        // 16kHz mono format for Whisper
        guard let targetFormat = AVAudioFormat(
            commonFormat: .pcmFormatFloat32,
            sampleRate: 16000,
            channels: 1,
            interleaved: false
        ) else {
            throw AudioRecorderError.formatError
        }
        outputFormat = targetFormat

        guard let audioConverter = AVAudioConverter(from: inputFormat, to: targetFormat) else {
            throw AudioRecorderError.converterError
        }
        converter = audioConverter

        // Smaller buffer = lower latency (1024 samples at 48kHz = ~21ms)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: inputFormat) { [weak self] buffer, _ in
            self?.processBuffer(buffer)
        }

        audioEngine.prepare()
        try audioEngine.start()
    }

    private func processBuffer(_ inputBuffer: AVAudioPCMBuffer) {
        guard let converter = converter,
              let outputFormat = outputFormat else { return }

        // Calculate output frame count
        let ratio = outputFormat.sampleRate / inputBuffer.format.sampleRate
        let outputFrameCount = AVAudioFrameCount(Double(inputBuffer.frameLength) * ratio)

        guard outputFrameCount > 0,
              let outputBuffer = AVAudioPCMBuffer(pcmFormat: outputFormat, frameCapacity: outputFrameCount) else {
            return
        }

        var error: NSError?
        var inputConsumed = false

        let status = converter.convert(to: outputBuffer, error: &error) { _, outStatus in
            if inputConsumed {
                outStatus.pointee = .noDataNow
                return nil
            }
            inputConsumed = true
            outStatus.pointee = .haveData
            return inputBuffer
        }

        guard status != .error, error == nil, outputBuffer.frameLength > 0,
              let floatData = outputBuffer.floatChannelData?[0] else {
            return
        }

        // Convert to array and send to callback
        let samples = Array(UnsafeBufferPointer(start: floatData, count: Int(outputBuffer.frameLength)))
        onSamples?(samples)
    }

    func stopRecording() {
        audioEngine?.inputNode.removeTap(onBus: 0)
        audioEngine?.stop()
        audioEngine = nil
        converter = nil
    }

    func cleanup() {
        stopRecording()
    }
}

enum AudioRecorderError: Error, LocalizedError {
    case engineInitFailed
    case formatError
    case converterError
    case permissionDenied

    var errorDescription: String? {
        switch self {
        case .engineInitFailed:
            return "Failed to initialize audio engine"
        case .formatError:
            return "Failed to create audio format"
        case .converterError:
            return "Failed to create audio converter"
        case .permissionDenied:
            return "Microphone permission denied"
        }
    }
}
