//
//  ShortcutMonitor.swift
//  CaffeineMate
//
//  Created by Edd on 07/10/2025.
//

import AppKit

class ShortcutMonitor {
    static let shared = ShortcutMonitor()

    private var globalMonitor: Any?
    private var localMonitor: Any?
    private let settings = SettingsManager.shared

    var onShortcutPressed: (() -> Void)?

    private init() {}

    deinit {
        stopMonitoring()
    }

    // MARK: - Public Methods

    func startMonitoring() {
        stopMonitoring()

        guard let shortcutKey = settings.shortcutKey,
              !shortcutKey.isEmpty else {
            return
        }

        // Check for accessibility permissions
        guard AXIsProcessTrusted() else {
            print("Warning: Accessibility permissions not granted. Global keyboard shortcuts will not work.")
            print("Please enable accessibility permissions in System Settings → Privacy & Security → Accessibility")
            return
        }

        let modifiers = NSEvent.ModifierFlags(rawValue: settings.shortcutModifiers)

        // Add global monitor (captures events when app is not focused)
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            self?.handleKeyEvent(event, modifiers: modifiers, key: shortcutKey)
        }

        // Add local monitor (captures events when app IS focused)
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            self?.handleKeyEvent(event, modifiers: modifiers, key: shortcutKey)
            return event
        }
    }

    func stopMonitoring() {
        if let monitor = globalMonitor {
            NSEvent.removeMonitor(monitor)
            globalMonitor = nil
        }
        if let monitor = localMonitor {
            NSEvent.removeMonitor(monitor)
            localMonitor = nil
        }
    }

    func updateShortcut(key: String?, modifiers: NSEvent.ModifierFlags) {
        settings.shortcutKey = key
        settings.shortcutModifiers = modifiers.rawValue

        // Restart monitoring with new shortcut
        startMonitoring()
    }

    func clearShortcut() {
        settings.shortcutKey = nil
        settings.shortcutModifiers = 0
        stopMonitoring()
    }

    // MARK: - Utility Methods

    func getShortcutDescription() -> String? {
        guard let key = settings.shortcutKey, !key.isEmpty else {
            return nil
        }

        let modifiers = NSEvent.ModifierFlags(rawValue: settings.shortcutModifiers)
        var parts: [String] = []

        if modifiers.contains(.control) {
            parts.append("⌃")
        }
        if modifiers.contains(.option) {
            parts.append("⌥")
        }
        if modifiers.contains(.shift) {
            parts.append("⇧")
        }
        if modifiers.contains(.command) {
            parts.append("⌘")
        }

        parts.append(key.uppercased())

        return parts.joined()
    }

    // MARK: - Private Methods

    private func handleKeyEvent(_ event: NSEvent, modifiers: NSEvent.ModifierFlags, key: String) {
        // Only compare relevant modifier flags (ignore Caps Lock, Fn, etc.)
        let relevantFlags: NSEvent.ModifierFlags = [.command, .control, .option, .shift]
        let eventModifiers = event.modifierFlags.intersection(relevantFlags)
        let requiredModifiers = modifiers.intersection(relevantFlags)

        if eventModifiers == requiredModifiers && event.charactersIgnoringModifiers == key {
            onShortcutPressed?()
        }
    }
}
