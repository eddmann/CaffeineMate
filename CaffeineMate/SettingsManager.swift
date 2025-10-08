//
//  SettingsManager.swift
//  CaffeineMate
//
//  Created by Edd on 07/10/2025.
//

import Foundation

class SettingsManager {
    static let shared = SettingsManager()

    private let defaults = UserDefaults.standard

    // UserDefaults Keys
    private enum Keys {
        static let keepDisplayAwake = "keepDisplayAwake"
        static let awakeDuration = "awakeDuration"
        static let launchAtLogin = "launchAtLogin"
        static let shortcutKey = "shortcutKey"
        static let shortcutModifiers = "shortcutModifiers"
    }

    private init() {}

    // MARK: - Keep Display Awake

    var keepDisplayAwake: Bool {
        get {
            defaults.bool(forKey: Keys.keepDisplayAwake)
        }
        set {
            defaults.set(newValue, forKey: Keys.keepDisplayAwake)
        }
    }

    // MARK: - Duration (in minutes, 0 = indefinite)

    var awakeDuration: Int {
        get {
            defaults.integer(forKey: Keys.awakeDuration)
        }
        set {
            defaults.set(newValue, forKey: Keys.awakeDuration)
        }
    }

    // MARK: - Launch at Login

    var launchAtLogin: Bool {
        get {
            defaults.bool(forKey: Keys.launchAtLogin)
        }
        set {
            defaults.set(newValue, forKey: Keys.launchAtLogin)
        }
    }

    // MARK: - Keyboard Shortcut

    var shortcutKey: String? {
        get {
            defaults.string(forKey: Keys.shortcutKey)
        }
        set {
            defaults.set(newValue, forKey: Keys.shortcutKey)
        }
    }

    var shortcutModifiers: UInt {
        get {
            UInt(defaults.integer(forKey: Keys.shortcutModifiers))
        }
        set {
            defaults.set(Int(newValue), forKey: Keys.shortcutModifiers)
        }
    }

    // MARK: - Convenience Methods

    func getDurationMinutes() -> Int {
        return awakeDuration
    }

    func setDurationMinutes(_ minutes: Int) {
        awakeDuration = minutes
    }

    func resetToDefaults() {
        keepDisplayAwake = false
        awakeDuration = 0
        launchAtLogin = false
        shortcutKey = nil
        shortcutModifiers = 0
    }
}
