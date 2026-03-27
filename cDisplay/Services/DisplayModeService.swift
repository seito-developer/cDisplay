import CoreGraphics
import AppKit

/// Represents a single display mode the user can select.
struct DisplayMode: Equatable {
    let modeRef: CGDisplayMode
    let width: Int
    let height: Int
    let refreshRate: Double
    let isHiDPI: Bool
    let aspectRatioLabel: String

    var modeID: Int32 { modeRef.ioDisplayModeID }

    var displayName: String {
        "\(width) × \(height)"
    }

    static func == (lhs: DisplayMode, rhs: DisplayMode) -> Bool {
        lhs.modeID == rhs.modeID
    }
}

/// A group of display modes sharing the same aspect ratio.
struct DisplayModeGroup {
    let label: String
    let modes: [DisplayMode]
}

/// Core service for querying, switching, and restoring display modes
/// using CoreGraphics APIs.
final class DisplayModeService {

    private(set) var originalMode: CGDisplayMode?
    private(set) var activeMode: DisplayMode?

    private static let crashRecoveryModeIDKey = "crashRecovery_originalModeID"

    // MARK: - Query

    /// Returns all usable display modes for the main display, grouped by aspect ratio.
    func availableModeGroups() -> [DisplayModeGroup] {
        let displayID = CGMainDisplayID()
        let options = [kCGDisplayShowDuplicateLowResolutionModes: kCFBooleanTrue] as CFDictionary
        guard let allModes = CGDisplayCopyAllDisplayModes(displayID, options) as? [CGDisplayMode] else {
            return []
        }

        var modesByRatio: [String: [DisplayMode]] = [:]

        for mode in allModes {
            let w = mode.width
            let h = mode.height
            guard w > 0, h > 0 else { continue }

            let label = aspectRatioLabel(width: w, height: h)
            let isHiDPI = mode.pixelWidth > w

            let dm = DisplayMode(
                modeRef: mode,
                width: w,
                height: h,
                refreshRate: mode.refreshRate,
                isHiDPI: isHiDPI,
                aspectRatioLabel: label
            )

            modesByRatio[label, default: []].append(dm)
        }

        // Deduplicate: keep HiDPI variant when both exist for same width×height
        for (key, modes) in modesByRatio {
            var seen: [String: DisplayMode] = [:]
            for mode in modes {
                let sizeKey = "\(mode.width)x\(mode.height)"
                if let existing = seen[sizeKey] {
                    if mode.isHiDPI && !existing.isHiDPI {
                        seen[sizeKey] = mode
                    }
                } else {
                    seen[sizeKey] = mode
                }
            }
            modesByRatio[key] = seen.values.sorted { $0.width > $1.width }
        }

        // Sort groups: common ratios first, then alphabetical
        let priorityOrder = ["16:10", "16:9", "4:3", "5:4", "1:1", "21:9"]
        let sorted = modesByRatio.sorted { a, b in
            let ai = priorityOrder.firstIndex(of: a.key) ?? Int.max
            let bi = priorityOrder.firstIndex(of: b.key) ?? Int.max
            if ai != bi { return ai < bi }
            return a.key < b.key
        }

        return sorted.map { DisplayModeGroup(label: $0.key, modes: $0.value) }
    }

    /// Returns the native (current) mode's width and height.
    func nativeResolution() -> (width: Int, height: Int) {
        guard let mode = CGDisplayCopyDisplayMode(CGMainDisplayID()) else {
            return (0, 0)
        }
        return (mode.width, mode.height)
    }

    /// Returns the current display mode.
    func currentMode() -> CGDisplayMode? {
        CGDisplayCopyDisplayMode(CGMainDisplayID())
    }

    // MARK: - Switch

    /// Switches to the given mode. Returns true on success.
    @discardableResult
    func applyMode(_ mode: DisplayMode) -> Bool {
        let displayID = CGMainDisplayID()

        // Capture original mode on first switch
        if originalMode == nil {
            originalMode = CGDisplayCopyDisplayMode(displayID)
        }

        saveOriginalModeForCrashRecovery()

        let result = CGDisplaySetDisplayMode(displayID, mode.modeRef, nil)
        if result == .success {
            activeMode = mode
            return true
        }
        return false
    }

    /// Restores the original display mode. Returns true on success.
    @discardableResult
    func restoreOriginalMode() -> Bool {
        guard let original = originalMode else { return false }
        let displayID = CGMainDisplayID()
        let result = CGDisplaySetDisplayMode(displayID, original, nil)
        if result == .success {
            activeMode = nil
            originalMode = nil
            clearCrashRecoveryFlag()
            return true
        }
        return false
    }

    var isResolutionChanged: Bool {
        activeMode != nil
    }

    // MARK: - Crash Recovery

    func saveOriginalModeForCrashRecovery() {
        guard let original = originalMode else { return }
        UserDefaults.standard.set(original.ioDisplayModeID, forKey: Self.crashRecoveryModeIDKey)
    }

    func clearCrashRecoveryFlag() {
        UserDefaults.standard.removeObject(forKey: Self.crashRecoveryModeIDKey)
    }

    /// Called at app launch (from main.swift) to restore resolution if previous session crashed.
    static func restoreIfNeeded() {
        let defaults = UserDefaults.standard
        guard let modeID = defaults.object(forKey: crashRecoveryModeIDKey) as? Int32 else { return }

        let displayID = CGMainDisplayID()
        let options = [kCGDisplayShowDuplicateLowResolutionModes: kCFBooleanTrue] as CFDictionary
        guard let allModes = CGDisplayCopyAllDisplayModes(displayID, options) as? [CGDisplayMode] else { return }

        if let target = allModes.first(where: { $0.ioDisplayModeID == modeID }) {
            CGDisplaySetDisplayMode(displayID, target, nil)
        }

        defaults.removeObject(forKey: crashRecoveryModeIDKey)
    }

    // MARK: - Helpers

    private func aspectRatioLabel(width: Int, height: Int) -> String {
        let g = gcd(width, height)
        let rw = width / g
        let rh = height / g
        switch (rw, rh) {
        case (16, 9):           return "16:9"
        case (16, 10), (8, 5):  return "16:10"
        case (4, 3):            return "4:3"
        case (5, 4):            return "5:4"
        case (5, 3):            return "5:3"
        case (1, 1):            return "1:1"
        case (64, 27), (21, 9): return "21:9"
        case (32, 9):           return "32:9"
        default:                return "\(rw):\(rh)"
        }
    }

    private func gcd(_ a: Int, _ b: Int) -> Int {
        b == 0 ? a : gcd(b, a % b)
    }
}
