import Cocoa
import AVFoundation

@MainActor
final class OnboardingWindow: NSObject {
    private var window: NSWindow?
    private var currentStep = 0
    private let totalSteps = 4

    private var contentView: NSView!
    private var stepIndicator: NSView!
    private var titleLabel: NSTextField!
    private var descriptionLabel: NSTextField!
    private var imageView: NSImageView!
    private var primaryButton: NSButton!
    private var secondaryButton: NSButton!

    var onComplete: (() -> Void)?

    func show() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 520, height: 480),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )

        window.title = "Welcome to Speakboard"
        window.center()
        window.isReleasedWhenClosed = false
        window.level = .floating

        setupUI(in: window)
        showStep(0)

        self.window = window
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    private func setupUI(in window: NSWindow) {
        let container = NSView(frame: window.contentView!.bounds)
        container.wantsLayer = true
        container.layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor

        // App icon at top
        imageView = NSImageView(frame: NSRect(x: 185, y: 320, width: 150, height: 150))
        imageView.imageScaling = .scaleProportionallyUpOrDown

        // Create a simple microphone icon
        if let micImage = NSImage(systemSymbolName: "mic.fill", accessibilityDescription: "Speakboard") {
            let config = NSImage.SymbolConfiguration(pointSize: 80, weight: .light)
            imageView.image = micImage.withSymbolConfiguration(config)
            imageView.contentTintColor = NSColor.controlAccentColor
        }
        container.addSubview(imageView)

        // Title
        titleLabel = NSTextField(labelWithString: "")
        titleLabel.frame = NSRect(x: 40, y: 250, width: 440, height: 36)
        titleLabel.font = NSFont.systemFont(ofSize: 28, weight: .semibold)
        titleLabel.alignment = .center
        titleLabel.textColor = NSColor.labelColor
        container.addSubview(titleLabel)

        // Description
        descriptionLabel = NSTextField(wrappingLabelWithString: "")
        descriptionLabel.frame = NSRect(x: 50, y: 130, width: 420, height: 110)
        descriptionLabel.font = NSFont.systemFont(ofSize: 15, weight: .regular)
        descriptionLabel.alignment = .center
        descriptionLabel.textColor = NSColor.secondaryLabelColor
        container.addSubview(descriptionLabel)

        // Step indicator
        stepIndicator = NSView(frame: NSRect(x: 210, y: 100, width: 100, height: 10))
        container.addSubview(stepIndicator)
        updateStepIndicator()

        // Primary button
        primaryButton = NSButton(frame: NSRect(x: 175, y: 40, width: 170, height: 44))
        primaryButton.bezelStyle = .rounded
        primaryButton.font = NSFont.systemFont(ofSize: 14, weight: .medium)
        primaryButton.target = self
        primaryButton.action = #selector(primaryAction)
        primaryButton.keyEquivalent = "\r"
        container.addSubview(primaryButton)

        // Secondary button (skip/back)
        secondaryButton = NSButton(frame: NSRect(x: 20, y: 48, width: 100, height: 30))
        secondaryButton.bezelStyle = .inline
        secondaryButton.isBordered = false
        secondaryButton.font = NSFont.systemFont(ofSize: 13, weight: .regular)
        secondaryButton.target = self
        secondaryButton.action = #selector(secondaryAction)
        secondaryButton.isHidden = true
        container.addSubview(secondaryButton)

        window.contentView = container
        contentView = container
    }

    private func updateStepIndicator() {
        stepIndicator.subviews.forEach { $0.removeFromSuperview() }

        let dotSize: CGFloat = 8
        let spacing: CGFloat = 12
        let totalWidth = CGFloat(totalSteps) * dotSize + CGFloat(totalSteps - 1) * spacing
        var x = (stepIndicator.bounds.width - totalWidth) / 2

        for i in 0..<totalSteps {
            let dot = NSView(frame: NSRect(x: x, y: 1, width: dotSize, height: dotSize))
            dot.wantsLayer = true
            dot.layer?.cornerRadius = dotSize / 2
            dot.layer?.backgroundColor = (i == currentStep)
                ? NSColor.controlAccentColor.cgColor
                : NSColor.separatorColor.cgColor
            stepIndicator.addSubview(dot)
            x += dotSize + spacing
        }
    }

    private func showStep(_ step: Int) {
        currentStep = step
        updateStepIndicator()

        switch step {
        case 0:
            showWelcomeStep()
        case 1:
            showMicrophoneStep()
        case 2:
            showHowItWorksStep()
        case 3:
            showReadyStep()
        default:
            completeOnboarding()
        }
    }

    private func showWelcomeStep() {
        if let micImage = NSImage(systemSymbolName: "mic.fill", accessibilityDescription: "Speakboard") {
            let config = NSImage.SymbolConfiguration(pointSize: 80, weight: .light)
            imageView.image = micImage.withSymbolConfiguration(config)
            imageView.contentTintColor = NSColor.controlAccentColor
        }

        titleLabel.stringValue = "Welcome to Speakboard"
        descriptionLabel.stringValue = "Transform your voice into text instantly.\n\nSpeakboard runs quietly in your menu bar and transcribes your speech with a simple key press — no clicks, no windows, just speak."

        primaryButton.title = "Get Started"
        secondaryButton.isHidden = true
    }

    private func showMicrophoneStep() {
        if let micImage = NSImage(systemSymbolName: "mic.badge.plus", accessibilityDescription: "Microphone Permission") {
            let config = NSImage.SymbolConfiguration(pointSize: 80, weight: .light)
            imageView.image = micImage.withSymbolConfiguration(config)
            imageView.contentTintColor = NSColor.systemGreen
        }

        titleLabel.stringValue = "Microphone Access"
        descriptionLabel.stringValue = "Speakboard needs access to your microphone to hear your voice and convert it to text.\n\nYour audio is processed locally on your Mac — nothing is sent to the cloud."

        let hasPermission = checkMicrophonePermission()
        if hasPermission {
            primaryButton.title = "Continue"
            imageView.contentTintColor = NSColor.systemGreen
        } else {
            primaryButton.title = "Grant Access"
        }

        secondaryButton.title = "Back"
        secondaryButton.isHidden = false
    }

    private func showHowItWorksStep() {
        if let keyImage = NSImage(systemSymbolName: "option", accessibilityDescription: "Option Key") {
            let config = NSImage.SymbolConfiguration(pointSize: 80, weight: .light)
            imageView.image = keyImage.withSymbolConfiguration(config)
            imageView.contentTintColor = NSColor.systemOrange
        }

        titleLabel.stringValue = "How It Works"
        descriptionLabel.stringValue = "1. Hold the Option (⌥) key to start recording\n\n2. Speak clearly into your microphone\n\n3. Release the key — your words appear instantly\n\nThe transcribed text is automatically typed wherever your cursor is."

        primaryButton.title = "Continue"
        secondaryButton.title = "Back"
        secondaryButton.isHidden = false
    }

    private func showReadyStep() {
        if let checkImage = NSImage(systemSymbolName: "checkmark.circle.fill", accessibilityDescription: "Ready") {
            let config = NSImage.SymbolConfiguration(pointSize: 80, weight: .light)
            imageView.image = checkImage.withSymbolConfiguration(config)
            imageView.contentTintColor = NSColor.systemGreen
        }

        titleLabel.stringValue = "You're All Set!"
        descriptionLabel.stringValue = "Speakboard is now running in your menu bar.\n\nLook for the microphone icon (🎤) at the top of your screen. The first transcription may take a moment while the AI model loads.\n\nEnjoy voice typing!"

        primaryButton.title = "Start Using Speakboard"
        secondaryButton.title = "Back"
        secondaryButton.isHidden = false
    }

    @objc private func primaryAction() {
        switch currentStep {
        case 1:
            // Microphone permission step
            if !checkMicrophonePermission() {
                requestMicrophonePermission()
                return
            }
            showStep(currentStep + 1)
        default:
            showStep(currentStep + 1)
        }
    }

    @objc private func secondaryAction() {
        if currentStep > 0 {
            showStep(currentStep - 1)
        }
    }

    private func checkMicrophonePermission() -> Bool {
        return AVCaptureDevice.authorizationStatus(for: .audio) == .authorized
    }

    private func requestMicrophonePermission() {
        AVCaptureDevice.requestAccess(for: .audio) { [weak self] granted in
            DispatchQueue.main.async {
                if granted {
                    self?.showStep((self?.currentStep ?? 0) + 1)
                } else {
                    self?.showPermissionDeniedAlert()
                }
            }
        }
    }

    private func showPermissionDeniedAlert() {
        let alert = NSAlert()
        alert.messageText = "Microphone Access Required"
        alert.informativeText = "Speakboard needs microphone access to work. Please enable it in System Settings > Privacy & Security > Microphone."
        alert.addButton(withTitle: "Open System Settings")
        alert.addButton(withTitle: "Continue Anyway")

        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Microphone") {
                NSWorkspace.shared.open(url)
            }
        } else {
            showStep(currentStep + 1)
        }
    }

    private func completeOnboarding() {
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
        window?.close()
        onComplete?()
    }

    static var hasCompletedOnboarding: Bool {
        return UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
    }

    static func resetOnboarding() {
        UserDefaults.standard.removeObject(forKey: "hasCompletedOnboarding")
    }
}
