# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

CaffeineMate is a macOS menu bar application that prevents the system from going to sleep, similar to the `caffeinate` command-line tool. It uses SwiftUI for the app structure and AppKit for the menu bar interface.

## Building and Running

- **Open in Xcode**: Open `CaffeineMate.xcodeproj`
- **Build**: ⌘B in Xcode
- **Run**: ⌘R in Xcode
- **Requirements**: macOS 15.6+ (deployment target), Swift 5.0, Xcode 26.0+

## Architecture

### Core Components

**AppDelegate** (`AppDelegate.swift:10`)

- Primary controller managing the menu bar UI and user interactions
- Handles left-click (toggle) and right-click (menu) on status bar icon
- Updates status bar display with countdown timer when active
- Coordinates between PowerAssertionManager, SettingsManager, and ShortcutMonitor

**PowerAssertionManager** (`PowerAssertionManager.swift:11`)

- Singleton managing IOKit power assertions
- Creates two types of assertions:
  - System assertion (`kIOPMAssertionTypePreventUserIdleSystemSleep`) - always created when active
  - Display assertion (`kIOPMAssertionTypeNoDisplaySleep`) - created only if "Keep Display Awake" is enabled
- Manages duration timer with countdown that auto-deactivates when expired
- All state changes flow through this manager (activate/deactivate/toggle)

**SettingsManager** (`SettingsManager.swift:10`)

- Singleton persisting user preferences to UserDefaults
- Stores: keepDisplayAwake, awakeDuration (minutes, 0=indefinite), launchAtLogin, keyboard shortcut

**ShortcutMonitor** (`ShortcutMonitor.swift:10`)

- Manages global keyboard shortcuts using NSEvent monitors
- Requires Accessibility permissions to capture key events system-wide
- Uses both global and local monitors to capture shortcuts regardless of app focus

**LaunchAtLoginManager** (`LaunchAtLoginManager.swift:12`)

- Uses ServiceManagement framework's SMAppService (macOS 13+)
- Falls back to UserDefaults for older macOS versions (no programmatic launch control)

### Data Flow

1. User clicks status bar icon → AppDelegate toggles → PowerAssertionManager activates/deactivates → IOKit assertions created/released
2. Settings changed in menu → SettingsManager persists → If active, PowerAssertionManager re-activates with new settings
3. Keyboard shortcut pressed → ShortcutMonitor detects → Triggers same toggle flow as status bar click
4. Timer running → PowerAssertionManager updates remainingSeconds every second → AppDelegate updates menu bar display

## Key Behaviors

- **Duration timer**: When set, displays countdown in menu bar (e.g., "15:30") and auto-deactivates at 0
- **Indefinite mode**: No countdown, stays active until manually toggled off
- **Display vs System**: System assertion always created. Display assertion only when "Keep Display Awake" is checked
- **Settings persistence**: All settings survive app restarts via UserDefaults
- **Accessibility permissions**: Required only for global keyboard shortcuts, prompted when user assigns a shortcut

## Entitlements

- **App Sandbox**: Enabled (`ENABLE_APP_SANDBOX = YES`)
- **Hardened Runtime**: Enabled
- Menu bar app (LSUIElement = YES) - no Dock icon, only status bar presence

## Code Signing & Distribution

- **Signed**: Developer ID Application certificate
- **Notarized**: Submitted to Apple for notarization via App Store Connect API
- **Stapled**: Notarization ticket stapled to the app bundle
- GitHub Actions workflow handles signing, notarization, and release creation
