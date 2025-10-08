//
//  ShortcutCaptureField.swift
//  CaffeineMate
//
//  Created by Edd on 07/10/2025.
//

import AppKit

class ShortcutCaptureField: NSTextField {
    var onShortcutCaptured: ((String, NSEvent.ModifierFlags) -> Void)?

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        placeholderString = "Press key combination..."
        isEditable = false
        isSelectable = false
        isBordered = true
        bezelStyle = .roundedBezel
        focusRingType = .default
    }

    override func keyDown(with event: NSEvent) {
        // Allow Escape key to cancel the dialog
        if event.keyCode == 53 { // Escape key code
            window?.close()
            return
        }

        let modifiers = event.modifierFlags.intersection(.deviceIndependentFlagsMask)

        // Validate that at least one modifier key is pressed
        let hasModifier = modifiers.contains(.command) ||
                         modifiers.contains(.control) ||
                         modifiers.contains(.option)

        if !hasModifier {
            NSSound.beep()
            return
        }

        // Get key character or use key code for special keys
        var keyString: String
        if let chars = event.charactersIgnoringModifiers, !chars.isEmpty {
            keyString = chars
        } else {
            // Handle special keys by key code
            keyString = getKeyName(for: event.keyCode)
        }

        // Build the shortcut description
        var shortcutDesc = ""
        if modifiers.contains(.control) { shortcutDesc += "⌃" }
        if modifiers.contains(.option) { shortcutDesc += "⌥" }
        if modifiers.contains(.shift) { shortcutDesc += "⇧" }
        if modifiers.contains(.command) { shortcutDesc += "⌘" }
        shortcutDesc += keyString.uppercased()

        // Update the text field
        stringValue = shortcutDesc

        // Notify the callback with only relevant modifier flags
        let relevantModifiers = modifiers.intersection([.command, .control, .option, .shift])
        onShortcutCaptured?(keyString, relevantModifiers)
    }

    override var acceptsFirstResponder: Bool {
        return true
    }

    override func becomeFirstResponder() -> Bool {
        let result = super.becomeFirstResponder()
        if result {
            // Clear selection when focused
            stringValue = stringValue
        }
        return result
    }

    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        keyDown(with: event)
        return true
    }

    // MARK: - Helper Methods

    private func getKeyName(for keyCode: UInt16) -> String {
        switch keyCode {
        case 122: return "F1"
        case 120: return "F2"
        case 99: return "F3"
        case 118: return "F4"
        case 96: return "F5"
        case 97: return "F6"
        case 98: return "F7"
        case 100: return "F8"
        case 101: return "F9"
        case 109: return "F10"
        case 103: return "F11"
        case 111: return "F12"
        case 123: return "←"
        case 124: return "→"
        case 125: return "↓"
        case 126: return "↑"
        case 36: return "↩"  // Return
        case 48: return "⇥"  // Tab
        case 49: return "Space"
        case 51: return "⌫"  // Delete
        case 53: return "⎋"  // Escape
        default: return "Key\(keyCode)"
        }
    }
}
