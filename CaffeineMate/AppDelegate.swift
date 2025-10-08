//
//  AppDelegate.swift
//  CaffeineMate
//
//  Created by Edd on 07/10/2025.
//

import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var menu: NSMenu!
    private var updateTimer: Timer?

    private let powerManager = PowerAssertionManager.shared
    private let settings = SettingsManager.shared
    private let shortcutMonitor = ShortcutMonitor.shared

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Create status bar item with variable length to accommodate countdown
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem.button {
            // Set up click handlers
            button.action = #selector(statusBarButtonClicked(_:))
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }

        // Create menu
        setupMenu()

        // Initialize menu checkmarks with stored preferences
        updateMenuCheckmarks()

        // Set up shortcut monitor
        shortcutMonitor.onShortcutPressed = { [weak self] in
            self?.toggleAwakeMode()
        }
        shortcutMonitor.startMonitoring()

        // Set up power manager state change callback
        powerManager.onStateChanged = { [weak self] in
            self?.updateStatusBarDisplay()
        }

        // Initial display update (timer will be started only if countdown is active)
        updateStatusBarDisplay()
    }

    func applicationWillTerminate(_ notification: Notification) {
        // Clean up - release all power assertions
        powerManager.deactivate()
        updateTimer?.invalidate()
    }

    deinit {
        updateTimer?.invalidate()
        updateTimer = nil
        shortcutMonitor.stopMonitoring()
    }

    @objc private func statusBarButtonClicked(_ sender: NSStatusBarButton) {
        let event = NSApp.currentEvent!

        if event.type == .rightMouseUp {
            // Right click - show menu
            // Refresh menu checkmarks to reflect current settings
            updateMenuCheckmarks()
            statusItem.menu = menu
            statusItem.button?.performClick(nil)
            statusItem.menu = nil
        } else {
            // Left click - toggle awake mode
            toggleAwakeMode()
        }
    }

    private func setupMenu() {
        menu = NSMenu()

        // Duration submenu
        let durationMenu = NSMenu()
        durationMenu.addItem(NSMenuItem(title: "Indefinite", action: #selector(setIndefiniteDuration), keyEquivalent: ""))
        durationMenu.addItem(NSMenuItem(title: "15 minutes", action: #selector(set15MinDuration), keyEquivalent: ""))
        durationMenu.addItem(NSMenuItem(title: "1 hour", action: #selector(set1HourDuration), keyEquivalent: ""))
        durationMenu.addItem(NSMenuItem(title: "3 hours", action: #selector(set3HoursDuration), keyEquivalent: ""))
        durationMenu.addItem(NSMenuItem(title: "Custom...", action: #selector(setCustomDuration), keyEquivalent: ""))

        let durationMenuItem = NSMenuItem(title: "Duration", action: nil, keyEquivalent: "")
        durationMenuItem.submenu = durationMenu
        menu.addItem(durationMenuItem)
        
        // Keep Display Awake
        menu.addItem(NSMenuItem(title: "Keep Display Awake", action: #selector(toggleKeepDisplayAwake), keyEquivalent: ""))

        menu.addItem(NSMenuItem.separator())

        // Start at Login
        menu.addItem(NSMenuItem(title: "Start at Login", action: #selector(toggleStartAtLogin), keyEquivalent: ""))

        // Assign Shortcut
        menu.addItem(NSMenuItem(title: "Assign Shortcut...", action: #selector(assignShortcut), keyEquivalent: ""))

        menu.addItem(NSMenuItem.separator())

        // Quit
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
    }

    // MARK: - Actions

    @objc private func toggleAwakeMode() {
        powerManager.toggle(keepDisplayAwake: settings.keepDisplayAwake, durationMinutes: settings.awakeDuration)
        // Display will update automatically via onStateChanged callback
    }

    @objc private func toggleKeepDisplayAwake() {
        settings.keepDisplayAwake.toggle()
        if powerManager.isActive {
            powerManager.activate(keepDisplayAwake: settings.keepDisplayAwake, durationMinutes: settings.awakeDuration)
        }
        updateMenuCheckmarks()
    }

    @objc private func setIndefiniteDuration() {
        settings.awakeDuration = 0
        if powerManager.isActive {
            powerManager.activate(keepDisplayAwake: settings.keepDisplayAwake, durationMinutes: 0)
        }
        updateMenuCheckmarks()
    }

    @objc private func set15MinDuration() {
        settings.awakeDuration = 15
        if powerManager.isActive {
            powerManager.activate(keepDisplayAwake: settings.keepDisplayAwake, durationMinutes: 15)
        }
        updateMenuCheckmarks()
    }

    @objc private func set1HourDuration() {
        settings.awakeDuration = 60
        if powerManager.isActive {
            powerManager.activate(keepDisplayAwake: settings.keepDisplayAwake, durationMinutes: 60)
        }
        updateMenuCheckmarks()
    }

    @objc private func set3HoursDuration() {
        settings.awakeDuration = 180
        if powerManager.isActive {
            powerManager.activate(keepDisplayAwake: settings.keepDisplayAwake, durationMinutes: 180)
        }
        updateMenuCheckmarks()
    }

    @objc private func setCustomDuration() {
        let alert = NSAlert()
        alert.messageText = "Custom Duration"
        alert.informativeText = "Enter duration in minutes:"
        alert.addButton(withTitle: "OK")
        alert.addButton(withTitle: "Cancel")

        let inputTextField = NSTextField(frame: NSRect(x: 0, y: 0, width: 200, height: 24))
        inputTextField.placeholderString = "Minutes"
        alert.accessoryView = inputTextField

        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            if let minutes = Int(inputTextField.stringValue), minutes > 0 {
                settings.awakeDuration = minutes
                if powerManager.isActive {
                    powerManager.activate(keepDisplayAwake: settings.keepDisplayAwake, durationMinutes: minutes)
                }
                updateMenuCheckmarks()
            }
        }
    }

    @objc private func toggleStartAtLogin() {
        LaunchAtLoginManager.shared.toggle()
        updateMenuCheckmarks()
    }

    @objc private func assignShortcut() {
        let alert = NSAlert()
        alert.messageText = "Assign Keyboard Shortcut"

        if let currentShortcut = shortcutMonitor.getShortcutDescription() {
            alert.informativeText = "Current shortcut: \(currentShortcut)\n\nPress a new key combination (must include ⌘, ⌃, or ⌥)"
        } else {
            alert.informativeText = "Press a key combination (must include ⌘, ⌃, or ⌥)"
        }

        alert.addButton(withTitle: "OK")
        alert.addButton(withTitle: "Cancel")
        alert.addButton(withTitle: "Clear")

        // Create custom shortcut capture field
        let captureField = ShortcutCaptureField(frame: NSRect(x: 0, y: 0, width: 250, height: 24))

        var capturedKey: String?
        var capturedModifiers: NSEvent.ModifierFlags?

        captureField.onShortcutCaptured = { key, modifiers in
            capturedKey = key
            capturedModifiers = modifiers
        }

        // Show current shortcut if exists
        if let currentShortcut = shortcutMonitor.getShortcutDescription() {
            captureField.stringValue = currentShortcut
        }

        alert.accessoryView = captureField

        // Make the capture field first responder after window appears
        DispatchQueue.main.async {
            alert.window.makeFirstResponder(captureField)
        }

        let response = alert.runModal()

        if response == .alertFirstButtonReturn {
            // OK button - save shortcut if one was captured
            if let key = capturedKey, let modifiers = capturedModifiers {
                // Check for Accessibility permissions
                if !checkAccessibilityPermissions() {
                    showAccessibilityPermissionAlert()
                    return
                }

                shortcutMonitor.updateShortcut(key: key, modifiers: modifiers)
                updateMenuCheckmarks()
            } else if captureField.stringValue.isEmpty {
                // User cleared the field - remove shortcut
                shortcutMonitor.clearShortcut()
                updateMenuCheckmarks()
            }
        } else if response == .alertThirdButtonReturn {
            // Clear button
            shortcutMonitor.clearShortcut()
            updateMenuCheckmarks()
        }
        // Cancel button - do nothing
    }

    private func checkAccessibilityPermissions() -> Bool {
        return AXIsProcessTrusted()
    }

    private func showAccessibilityPermissionAlert() {
        let alert = NSAlert()
        alert.messageText = "Accessibility Permission Required"
        alert.informativeText = "CaffeineMate needs Accessibility permission to use global keyboard shortcuts.\n\nPlease:\n1. Open System Settings\n2. Go to Privacy & Security → Accessibility\n3. Enable CaffeineMate\n4. Try setting the shortcut again"
        alert.alertStyle = .informational
        alert.addButton(withTitle: "Open System Settings")
        alert.addButton(withTitle: "Cancel")

        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            // Open System Settings to Accessibility pane
            NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!)
        }
    }

    // MARK: - UI Updates

    private func updateStatusBarDisplay() {
        guard let button = statusItem.button else { return }

        // Update icon
        let iconName = powerManager.isActive ? "cup.and.saucer.fill" : "cup.and.saucer"
        button.image = NSImage(systemSymbolName: iconName, accessibilityDescription: "CaffeineMate")
        button.image?.isTemplate = true

        // Update countdown text and tooltip
        if powerManager.isActive {
            let modeString = settings.keepDisplayAwake ? "System & Display" : "System"

            // Show countdown in menu bar if duration is set
            if powerManager.remainingSeconds > 0 {
                let countdownText = formatCountdown(powerManager.remainingSeconds)
                button.title = " \(countdownText)"
                button.toolTip = "CaffeineMate Active (\(modeString))\n\(powerManager.getRemainingTimeString() ?? "")"

                // Ensure timer is running for countdown updates
                startUpdateTimerIfNeeded()
            } else {
                // Indefinite mode - no countdown
                button.title = ""
                button.toolTip = "CaffeineMate Active (\(modeString))\nIndefinite"

                // Stop timer when in indefinite mode (no countdown to update)
                stopUpdateTimer()
            }
        } else {
            button.title = ""
            button.toolTip = "CaffeineMate (Inactive)\nClick to activate"

            // Stop timer when inactive
            stopUpdateTimer()
        }
    }

    private func startUpdateTimerIfNeeded() {
        // Only start timer if it's not already running
        guard updateTimer == nil else { return }

        updateTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateStatusBarDisplay()
        }
    }

    private func stopUpdateTimer() {
        updateTimer?.invalidate()
        updateTimer = nil
    }

    private func formatCountdown(_ seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        let secs = seconds % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, secs)
        } else {
            return String(format: "%d:%02d", minutes, secs)
        }
    }

    private func updateMenuCheckmarks() {
        guard let menu = menu else { return }

        // Update Keep Display Awake checkmark
        menu.item(withTitle: "Keep Display Awake")?.state = settings.keepDisplayAwake ? .on : .off

        // Update duration checkmarks
        if let durationMenuItem = menu.item(withTitle: "Duration"),
           let durationSubmenu = durationMenuItem.submenu {
            for item in durationSubmenu.items {
                item.state = .off
            }

            switch settings.awakeDuration {
            case 0:
                durationSubmenu.item(withTitle: "Indefinite")?.state = .on
            case 15:
                durationSubmenu.item(withTitle: "15 minutes")?.state = .on
            case 60:
                durationSubmenu.item(withTitle: "1 hour")?.state = .on
            case 180:
                durationSubmenu.item(withTitle: "3 hours")?.state = .on
            default:
                durationSubmenu.item(withTitle: "Custom...")?.state = .on
            }
        }

        // Update launch at login checkmark
        menu.item(withTitle: "Start at Login")?.state = LaunchAtLoginManager.shared.isEnabled ? .on : .off

        // Update shortcut menu item to show current shortcut
        if let shortcutMenuItem = menu.items.first(where: { $0.action == #selector(assignShortcut) }) {
            if let shortcut = shortcutMonitor.getShortcutDescription() {
                shortcutMenuItem.title = "Shortcut: \(shortcut)"
            } else {
                shortcutMenuItem.title = "Assign Shortcut..."
            }
        }
    }
}

