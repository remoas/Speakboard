import Cocoa

final class KeyboardMonitor {
    private var globalMonitor: Any?
    private var localMonitor: Any?
    private var optionKeyIsDown = false

    var onKeyDown: (() -> Void)?
    var onKeyUp: (() -> Void)?

    func start() throws {
        NSLog("[Speakboard] Starting keyboard monitor (Option key)...")

        // Use NSEvent global monitor - App Store compatible!
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: .flagsChanged) { [weak self] event in
            self?.handleFlagsChanged(event)
        }

        // Also monitor local events (when our app is focused)
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: .flagsChanged) { [weak self] event in
            self?.handleFlagsChanged(event)
            return event
        }

        guard globalMonitor != nil else {
            throw KeyboardMonitorError.monitorCreationFailed
        }

        NSLog("[Speakboard] Keyboard monitor started - hold Option (⌥) to record")
    }

    private func handleFlagsChanged(_ event: NSEvent) {
        let optionPressed = event.modifierFlags.contains(.option)

        if optionPressed && !optionKeyIsDown {
            // Option key just pressed
            optionKeyIsDown = true
            NSLog("[Speakboard] Option key pressed - starting recording")
            DispatchQueue.main.async { [weak self] in
                self?.onKeyDown?()
            }
        } else if !optionPressed && optionKeyIsDown {
            // Option key just released
            optionKeyIsDown = false
            NSLog("[Speakboard] Option key released - stopping recording")
            DispatchQueue.main.async { [weak self] in
                self?.onKeyUp?()
            }
        }
    }

    func stop() {
        if let monitor = globalMonitor {
            NSEvent.removeMonitor(monitor)
            globalMonitor = nil
        }
        if let monitor = localMonitor {
            NSEvent.removeMonitor(monitor)
            localMonitor = nil
        }
    }

    // Not needed for App Store version - NSEvent monitors don't require accessibility
    func checkAccessibilityPermission() -> Bool {
        return true
    }

    func requestAccessibilityPermission() {
        // Not needed
    }

    deinit {
        stop()
    }
}

enum KeyboardMonitorError: Error, LocalizedError {
    case monitorCreationFailed

    var errorDescription: String? {
        switch self {
        case .monitorCreationFailed:
            return "Failed to create keyboard monitor"
        }
    }
}
