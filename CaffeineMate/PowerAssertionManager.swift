//
//  PowerAssertionManager.swift
//  CaffeineMate
//
//  Created by Edd on 07/10/2025.
//

import Foundation
import IOKit.pwr_mgt

class PowerAssertionManager {
    static let shared = PowerAssertionManager()

    private var displayAssertionID: IOPMAssertionID = 0
    private var systemAssertionID: IOPMAssertionID = 0
    private var durationTimer: Timer?

    private(set) var isActive: Bool = false
    private(set) var keepDisplayAwake: Bool = false
    private(set) var remainingSeconds: Int = 0

    // Callback invoked when state changes (activate/deactivate)
    var onStateChanged: (() -> Void)?

    private init() {}

    // MARK: - Public Methods

    func activate(keepDisplayAwake: Bool, durationMinutes: Int = 0) {
        // Deactivate any existing assertions first
        deactivate()

        self.keepDisplayAwake = keepDisplayAwake

        // Always create system sleep prevention assertion
        createSystemAssertion()

        // Conditionally create display sleep prevention assertion
        if keepDisplayAwake {
            createDisplayAssertion()
        }

        isActive = true

        // Set up duration timer if specified
        if durationMinutes > 0 {
            remainingSeconds = durationMinutes * 60
            startDurationTimer()
        } else {
            remainingSeconds = 0
        }

        // Notify listeners that state has changed
        onStateChanged?()
    }

    func deactivate() {
        // Release all assertions if active
        if displayAssertionID != 0 {
            IOPMAssertionRelease(displayAssertionID)
            displayAssertionID = 0
        }

        if systemAssertionID != 0 {
            IOPMAssertionRelease(systemAssertionID)
            systemAssertionID = 0
        }

        // Stop timer
        durationTimer?.invalidate()
        durationTimer = nil

        isActive = false
        keepDisplayAwake = false
        remainingSeconds = 0

        // Notify listeners that state has changed
        onStateChanged?()
    }

    func toggle(keepDisplayAwake: Bool, durationMinutes: Int = 0) {
        if isActive {
            deactivate()
        } else {
            activate(keepDisplayAwake: keepDisplayAwake, durationMinutes: durationMinutes)
        }
    }

    // MARK: - Private Methods

    private func createDisplayAssertion() {
        let result = IOPMAssertionCreateWithName(
            kIOPMAssertionTypeNoDisplaySleep as CFString,
            IOPMAssertionLevel(kIOPMAssertionLevelOn),
            "CaffeineMate: Preventing Display Sleep" as CFString,
            &displayAssertionID
        )

        if result != kIOReturnSuccess {
            print("Error creating display assertion: \(result)")
        }
    }

    private func createSystemAssertion() {
        let result = IOPMAssertionCreateWithName(
            kIOPMAssertionTypePreventUserIdleSystemSleep as CFString,
            IOPMAssertionLevel(kIOPMAssertionLevelOn),
            "CaffeineMate: Preventing System Sleep" as CFString,
            &systemAssertionID
        )

        if result != kIOReturnSuccess {
            print("Error creating system assertion: \(result)")
        }
    }

    private func startDurationTimer() {
        let timer = Timer(timeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }

            if self.remainingSeconds > 0 {
                self.remainingSeconds -= 1
            } else {
                // Time's up - deactivate
                self.deactivate()
            }
        }
        RunLoop.main.add(timer, forMode: .common)
        durationTimer = timer
    }

    // MARK: - Utility Methods

    func getRemainingTimeString() -> String? {
        guard remainingSeconds > 0 else { return nil }

        let hours = remainingSeconds / 3600
        let minutes = (remainingSeconds % 3600) / 60

        if hours > 0 {
            return "\(hours)h \(minutes)m remaining"
        } else {
            return "\(minutes)m remaining"
        }
    }
}
