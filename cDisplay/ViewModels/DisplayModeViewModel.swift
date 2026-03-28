import AppKit

/// A target resolution the user wants to achieve.
struct TargetResolution: Equatable {
    let width: Int
    let height: Int
    let aspectLabel: String

    var displayName: String { "\(width) × \(height)" }
    var ratio: Double { Double(width) / Double(height) }
}

/// The method used to achieve the target resolution.
enum DisplayMethod {
    /// Exact display mode match — no mask needed.
    case resolution(DisplayMode)
    /// No matching display mode — mask overlay only.
    case mask(AspectRatio)
    /// Closest display mode + mask overlay to trim to exact target ratio.
    case resolutionPlusMask(DisplayMode, TargetResolution)
}

/// Manages display state — resolution change, mask overlay, or both combined.
@MainActor
final class DisplayModeViewModel {

    private(set) var isActive: Bool = false
    private(set) var activeMethod: DisplayMethod?

    var onStateChanged: ((Bool) -> Void)?

    private let displayModeService: DisplayModeService
    private let maskService: MaskService
    private let displayService: DisplayService
    private let settings: SettingsService

    init(displayModeService: DisplayModeService = DisplayModeService(),
         maskService: MaskService? = nil,
         displayService: DisplayService = DisplayService(),
         settings: SettingsService = .shared) {
        self.displayModeService = displayModeService
        self.maskService = maskService ?? MaskService(displayService: displayService)
        self.displayService = displayService
        self.settings = settings
    }

    // MARK: - Actions

    func toggle() {
        if isActive {
            disable()
        } else if let target = settings.selectedTarget {
            applyTarget(target)
        }
    }

    /// Apply a target resolution. Finds closest display mode and adds mask if needed.
    func applyTarget(_ target: TargetResolution) {
        disableWithoutNotify()

        settings.selectedTarget = target

        // Find the closest available display mode
        guard let closestMode = displayModeService.closestMode(toWidth: target.width, toHeight: target.height) else {
            // No display modes at all — pure mask
            applyMaskOnly(target)
            return
        }

        let modeRatio = Double(closestMode.width) / Double(closestMode.height)
        let targetRatio = target.ratio

        // Check if mode exactly matches the target
        if closestMode.width == target.width && closestMode.height == target.height {
            // Exact match — resolution only
            if displayModeService.applyMode(closestMode) {
                isActive = true
                activeMethod = .resolution(closestMode)
                onStateChanged?(true)
            }
            return
        }

        // Change to closest mode, then mask to trim to target ratio
        if displayModeService.applyMode(closestMode) {
            // After resolution change, apply mask to achieve target ratio
            // Need a short delay for the display mode change to take effect
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                guard let self else { return }
                let visibleFrame = self.displayService.currentVisibleFrame()
                let currentRatio = visibleFrame.width / visibleFrame.height

                if abs(currentRatio - targetRatio) > 0.01 {
                    // Ratios differ — add mask to trim
                    self.maskService.showMaskForRatio(targetRatio, in: visibleFrame)
                }
            }

            isActive = true
            activeMethod = .resolutionPlusMask(closestMode, target)
            onStateChanged?(true)
        }
    }

    /// Apply mask only (no resolution change) for a preset aspect ratio.
    func applyMaskOnly(_ target: TargetResolution) {
        disableWithoutNotify()

        settings.selectedTarget = target

        let visibleFrame = displayService.currentVisibleFrame()
        maskService.showMaskForRatio(target.ratio, in: visibleFrame)

        isActive = true
        activeMethod = .mask(AspectRatio.allCases.first { abs($0.ratio - target.ratio) < 0.01 } ?? .widescreen)
        onStateChanged?(true)
    }

    func disable() {
        disableWithoutNotify()
        onStateChanged?(false)
    }

    func restoreOnTerminate() {
        disableWithoutNotify()
    }

    // MARK: - Query

    func targetResolutions() -> [String: [TargetResolution]] {
        var groups: [String: [TargetResolution]] = [:]
        for t in DisplayModeService.targetResolutions {
            let tr = TargetResolution(width: t.width, height: t.height, aspectLabel: t.label)
            groups[t.label, default: []].append(tr)
        }
        return groups
    }

    func nativeResolution() -> (width: Int, height: Int) {
        displayModeService.nativeResolution()
    }

    // MARK: - Private

    private func disableWithoutNotify() {
        switch activeMethod {
        case .resolution:
            displayModeService.restoreOriginalMode()
        case .mask:
            maskService.hideMask()
        case .resolutionPlusMask:
            maskService.hideMask()
            displayModeService.restoreOriginalMode()
        case nil:
            break
        }
        isActive = false
        activeMethod = nil
    }
}
