import Cocoa
import AVFoundation

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusBarController: StatusBarController!
    private var keyboardMonitor: KeyboardMonitor!
    private var audioRecorder: AudioRecorder!
    private var whisperTranscriber: WhisperTranscriber!
    private var textInjector: TextInjector!
    private var onboardingWindow: OnboardingWindow?

    private let appState = AppState.shared
    private var isModelReady = false

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSLog("[Speakboard] Application starting...")

        // Initialize components
        statusBarController = StatusBarController(appState: appState)
        statusBarController.setup()

        keyboardMonitor = KeyboardMonitor()
        audioRecorder = AudioRecorder()
        textInjector = TextInjector()
        whisperTranscriber = WhisperTranscriber()

        // Stream audio samples directly to transcriber
        audioRecorder.onSamples = { [weak self] samples in
            self?.whisperTranscriber.addSamples(samples)
        }

        // Set up keyboard callbacks for hold-to-record
        keyboardMonitor.onKeyDown = { [weak self] in
            Task { @MainActor in
                self?.startRecording()
            }
        }
        keyboardMonitor.onKeyUp = { [weak self] in
            Task { @MainActor in
                self?.stopRecordingAndTranscribe()
            }
        }

        // Set up notification observers
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleCheckPermissionsRequest),
            name: .checkPermissionsRequested,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleShowOnboardingRequest),
            name: .showOnboardingRequested,
            object: nil
        )

        // Check if this is first launch
        if !OnboardingWindow.hasCompletedOnboarding {
            showOnboarding()
        } else {
            completeSetup()
        }
    }

    private func showOnboarding() {
        onboardingWindow = OnboardingWindow()
        onboardingWindow?.onComplete = { [weak self] in
            self?.completeSetup()
        }
        onboardingWindow?.show()
    }

    private func completeSetup() {
        // Start keyboard monitor immediately (no accessibility needed!)
        do {
            try keyboardMonitor.start()
            NSLog("[Speakboard] Keyboard monitor started successfully")
        } catch {
            NSLog("[Speakboard] Keyboard monitor error: \(error)")
        }

        // Request accessibility permission upfront (shows system prompt)
        if !textInjector.checkAccessibilityPermission() {
            _ = textInjector.requestAccessibilityPermission()
        }

        // Initial setup
        Task {
            await requestMicrophonePermission()
            await initializeModel()
        }
    }

    private func requestMicrophonePermission() async {
        let micPermission = await audioRecorder.requestPermission()
        appState.hasMicrophonePermission = micPermission
        NSLog("[Speakboard] Microphone permission: \(micPermission)")

        if !micPermission {
            showAlert(
                title: "Microphone Permission Required",
                message: "Speakboard needs microphone access to record speech. Please grant permission in System Settings."
            )
        }
    }

    private func initializeModel() async {
        NSLog("[Speakboard] Initializing Parakeet model...")
        do {
            try await whisperTranscriber.initialize { progress in
                NSLog("[Speakboard] Model loading: \(Int(progress * 100))%%")
            }
            isModelReady = true
            NSLog("[Speakboard] Model ready!")
        } catch {
            NSLog("[Speakboard] Model load error: \(error)")
            showAlert(title: "Model Load Error", message: error.localizedDescription)
        }
    }

    private func startRecording() {
        // Don't start if already recording or transcribing
        guard appState.recordingState == .idle else { return }

        guard audioRecorder.checkPermission() else {
            showAlert(
                title: "Microphone Permission Required",
                message: "Please grant microphone permission in System Settings."
            )
            return
        }

        guard isModelReady else {
            showAlert(
                title: "Model Not Ready",
                message: "Please wait for the Whisper model to finish loading."
            )
            return
        }

        do {
            // Start fresh session
            whisperTranscriber.startSession()
            try audioRecorder.startRecording()
            appState.setRecording()
            NSLog("[Speakboard] Recording started")

            // Play start sound
            NSSound.beep()
        } catch {
            appState.setError(error.localizedDescription)
            showAlert(title: "Recording Error", message: error.localizedDescription)
        }
    }

    private func stopRecordingAndTranscribe() {
        // Only process if we were recording
        guard appState.recordingState == .recording else { return }

        NSLog("[Speakboard] Stopping recording...")
        audioRecorder.stopRecording()
        appState.setTranscribing()

        Task {
            do {
                NSLog("[Speakboard] Transcribing audio...")
                let startTime = CFAbsoluteTimeGetCurrent()

                let text = try await whisperTranscriber.transcribeAccumulated()

                let elapsed = CFAbsoluteTimeGetCurrent() - startTime
                NSLog("[Speakboard] Transcription completed in %.2f seconds", elapsed)

                if text.isEmpty {
                    appState.setError("No speech detected")
                    NSLog("[Speakboard] No speech detected")
                } else {
                    appState.setTranscription(text)
                    NSLog("[Speakboard] Transcription: \(text)")

                    // Check accessibility permission before pasting
                    if !self.textInjector.checkAccessibilityPermission() {
                        self.promptForAccessibility()
                    }

                    // Inject text into focused field
                    try self.textInjector.injectText(text)
                }

            } catch {
                appState.setError(error.localizedDescription)
                NSLog("[Speakboard] Transcription error: \(error)")
            }
        }
    }

    @objc private func handleCheckPermissionsRequest() {
        var messages: [String] = []

        let micGranted = audioRecorder.checkPermission()

        messages.append("Microphone: \(micGranted ? "✓ Granted" : "✗ Not Granted")")
        messages.append("Model Ready: \(isModelReady ? "✓ Yes" : "⏳ Loading...")")

        let alert = NSAlert()
        alert.messageText = "Status"
        alert.informativeText = messages.joined(separator: "\n")
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }

    @objc private func handleShowOnboardingRequest() {
        OnboardingWindow.resetOnboarding()
        showOnboarding()
    }

    private func showAlert(title: String, message: String) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.alertStyle = .warning
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }

    private func promptForAccessibility() {
        // This will show Apple's native permission prompt
        _ = textInjector.requestAccessibilityPermission()
    }

    func applicationWillTerminate(_ notification: Notification) {
        keyboardMonitor.stop()
        audioRecorder.cleanup()
    }
}
