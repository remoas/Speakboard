import Cocoa
import ApplicationServices

final class TextInjector {
    private let pasteboard = NSPasteboard.general

    func injectText(_ text: String) throws {
        // Save current clipboard contents
        let savedContents = saveClipboard()

        // Put transcribed text on clipboard
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)

        // Delay to ensure target app has focus back after key release
        usleep(150000) // 150ms

        // Simulate Cmd+V to paste
        simulatePaste()

        // Restore original clipboard after a brief delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.restoreClipboard(savedContents)
        }
    }

    func checkAccessibilityPermission() -> Bool {
        // Check without prompting
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: false] as CFDictionary
        return AXIsProcessTrustedWithOptions(options)
    }

    func requestAccessibilityPermission() -> Bool {
        // Check AND prompt if not granted
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        return AXIsProcessTrustedWithOptions(options)
    }

    private func saveClipboard() -> [NSPasteboard.PasteboardType: Data] {
        var contents: [NSPasteboard.PasteboardType: Data] = [:]

        for type in pasteboard.types ?? [] {
            if let data = pasteboard.data(forType: type) {
                contents[type] = data
            }
        }

        return contents
    }

    private func restoreClipboard(_ contents: [NSPasteboard.PasteboardType: Data]) {
        pasteboard.clearContents()

        for (type, data) in contents {
            pasteboard.setData(data, forType: type)
        }
    }

    private func simulatePaste() {
        // Create Cmd+V key event
        let source = CGEventSource(stateID: .hidSystemState)

        // Key code for 'V' is 9
        let keyDown = CGEvent(keyboardEventSource: source, virtualKey: 9, keyDown: true)
        let keyUp = CGEvent(keyboardEventSource: source, virtualKey: 9, keyDown: false)

        // Add Command modifier
        keyDown?.flags = .maskCommand
        keyUp?.flags = .maskCommand

        // Post events
        keyDown?.post(tap: .cghidEventTap)
        keyUp?.post(tap: .cghidEventTap)
    }

    /// Alternative method: directly set text in focused element using Accessibility API
    func injectTextViaAccessibility(_ text: String) -> Bool {
        guard let focusedElement = getFocusedElement() else {
            return false
        }

        // Try to set the value directly
        let result = AXUIElementSetAttributeValue(
            focusedElement,
            kAXValueAttribute as CFString,
            text as CFTypeRef
        )

        if result == .success {
            return true
        }

        // If direct value setting fails, try inserting at selection
        return insertAtSelection(focusedElement, text: text)
    }

    private func getFocusedElement() -> AXUIElement? {
        let systemWide = AXUIElementCreateSystemWide()

        var focusedApp: CFTypeRef?
        let appResult = AXUIElementCopyAttributeValue(
            systemWide,
            kAXFocusedApplicationAttribute as CFString,
            &focusedApp
        )

        guard appResult == .success, let app = focusedApp else {
            return nil
        }

        var focusedElement: CFTypeRef?
        let elementResult = AXUIElementCopyAttributeValue(
            app as! AXUIElement,
            kAXFocusedUIElementAttribute as CFString,
            &focusedElement
        )

        guard elementResult == .success else {
            return nil
        }

        return (focusedElement as! AXUIElement)
    }

    private func insertAtSelection(_ element: AXUIElement, text: String) -> Bool {
        // Get current selection range
        var selectedRange: CFTypeRef?
        let rangeResult = AXUIElementCopyAttributeValue(
            element,
            kAXSelectedTextRangeAttribute as CFString,
            &selectedRange
        )

        guard rangeResult == .success else {
            return false
        }

        // Set selected text (replaces selection or inserts at cursor)
        let setResult = AXUIElementSetAttributeValue(
            element,
            kAXSelectedTextAttribute as CFString,
            text as CFTypeRef
        )

        return setResult == .success
    }
}

enum TextInjectorError: Error, LocalizedError {
    case accessibilityDenied
    case noFocusedElement
    case injectionFailed

    var errorDescription: String? {
        switch self {
        case .accessibilityDenied:
            return "Accessibility permission required for text injection"
        case .noFocusedElement:
            return "No text field is focused"
        case .injectionFailed:
            return "Failed to inject text"
        }
    }
}
