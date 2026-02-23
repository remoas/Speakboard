import Cocoa
import SwiftUI
import Combine

@MainActor
final class StatusBarController: NSObject, ObservableObject {
    private var statusItem: NSStatusItem?
    private var cancellables = Set<AnyCancellable>()

    let appState: AppState

    init(appState: AppState) {
        self.appState = appState
        super.init()
    }

    func setup() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        guard statusItem?.button != nil else { return }

        updateIcon()

        // Observe state changes
        appState.$recordingState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateIcon()
            }
            .store(in: &cancellables)

        setupMenu()
    }

    private func updateIcon() {
        guard let button = statusItem?.button else { return }

        let iconName = appState.recordingState.iconName
        let config = NSImage.SymbolConfiguration(pointSize: 16, weight: .medium)

        if let image = NSImage(systemSymbolName: iconName, accessibilityDescription: "Speakboard") {
            let configuredImage = image.withSymbolConfiguration(config)
            button.image = configuredImage

            // Change color based on state
            switch appState.recordingState {
            case .idle:
                button.contentTintColor = nil
            case .recording:
                button.contentTintColor = .systemRed
            case .transcribing:
                button.contentTintColor = .systemOrange
            }
        }
    }

    private func setupMenu() {
        let menu = NSMenu()

        // Status item
        let statusItem = NSMenuItem(title: "Status: \(appState.recordingState.statusText)", action: nil, keyEquivalent: "")
        statusItem.isEnabled = false
        statusItem.tag = 1
        menu.addItem(statusItem)

        menu.addItem(NSMenuItem.separator())

        // Last transcription
        let transcriptionItem = NSMenuItem(title: "Last: (none)", action: nil, keyEquivalent: "")
        transcriptionItem.isEnabled = false
        transcriptionItem.tag = 2
        menu.addItem(transcriptionItem)

        menu.addItem(NSMenuItem.separator())

        // Shortcut info
        let shortcutItem = NSMenuItem(title: "Hold Option (⌥) to record", action: nil, keyEquivalent: "")
        shortcutItem.isEnabled = false
        menu.addItem(shortcutItem)

        menu.addItem(NSMenuItem.separator())

        // Check status
        let statusMenuItem = NSMenuItem(title: "Check Status...", action: #selector(checkPermissions), keyEquivalent: "s")
        statusMenuItem.target = self
        menu.addItem(statusMenuItem)

        // Show onboarding
        let onboardingItem = NSMenuItem(title: "Show Tutorial...", action: #selector(showOnboarding), keyEquivalent: "")
        onboardingItem.target = self
        menu.addItem(onboardingItem)

        menu.addItem(NSMenuItem.separator())

        // About
        let aboutItem = NSMenuItem(title: "About Speakboard", action: #selector(showAbout), keyEquivalent: "")
        aboutItem.target = self
        menu.addItem(aboutItem)

        menu.addItem(NSMenuItem.separator())

        // Quit
        let quitItem = NSMenuItem(title: "Quit Speakboard", action: #selector(quit), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        self.statusItem?.menu = menu

        // Update menu items when state changes
        appState.$recordingState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.updateMenuStatus(state)
            }
            .store(in: &cancellables)

        appState.$lastTranscription
            .receive(on: DispatchQueue.main)
            .sink { [weak self] text in
                self?.updateLastTranscription(text)
            }
            .store(in: &cancellables)
    }

    private func updateMenuStatus(_ state: RecordingState) {
        guard let menu = statusItem?.menu,
              let statusItem = menu.item(withTag: 1) else { return }
        statusItem.title = "Status: \(state.statusText)"
    }

    private func updateLastTranscription(_ text: String) {
        guard let menu = statusItem?.menu,
              let item = menu.item(withTag: 2) else { return }

        if text.isEmpty {
            item.title = "Last: (none)"
        } else {
            let truncated = text.count > 40 ? String(text.prefix(40)) + "..." : text
            item.title = "Last: \(truncated)"
        }
    }

    @objc private func checkPermissions() {
        NotificationCenter.default.post(name: .checkPermissionsRequested, object: nil)
    }

    @objc private func showOnboarding() {
        NotificationCenter.default.post(name: .showOnboardingRequested, object: nil)
    }

    @objc private func showAbout() {
        let alert = NSAlert()
        alert.messageText = "Speakboard"
        alert.informativeText = "Version 1.0\n\nVoice-to-text transcription for macOS.\n\nHold Option (⌥) to record, release to transcribe.\n\n© 2024 Ben Spink"
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }

    @objc private func quit() {
        NSApplication.shared.terminate(nil)
    }
}

extension Notification.Name {
    static let checkPermissionsRequested = Notification.Name("checkPermissionsRequested")
    static let showOnboardingRequested = Notification.Name("showOnboardingRequested")
}
