import AppKit

/// The method used to apply the current aspect ratio.
enum DisplayMethod {
    case resolution(DisplayMode) // Actual display mode change
    case mask(AspectRatio)       // Black overlay mask fallback
}

/// Manages display state — either resolution change or mask overlay.
@MainActor
final class DisplayModeViewModel {

    private(set) var isActive: Bool = false
    private(set) var activeMethod: DisplayMethod?

    var onStateChanged: ((Bool) -> Void)?

    private let displayModeService: DisplayModeService
    private let maskService: MaskService
    private let settings: SettingsService

    init(displayModeService: DisplayModeService = DisplayModeService(),
         maskService: MaskService? = nil,
         settings: SettingsService = .shared) {
        self.displayModeService = displayModeService
        self.maskService = maskService ?? MaskService()
        self.settings = settings
    }

    // MARK: - Actions

    func toggle() {
        if isActive {
            disable()
        } else {
            // Re-apply last used aspect ratio
            if let ar = settings.selectedAspectRatio {
                applyAspectRatio(ar, modeID: settings.selectedModeID)
            }
        }
    }

    func applyAspectRatio(_ ar: AspectRatio, modeID: Int32? = nil) {
        // First disable any existing state
        disableWithoutNotify()

        let matchingModes = displayModeService.modesMatching(aspectRatio: ar)

        if let modeID = modeID,
           let mode = matchingModes.first(where: { $0.modeID == modeID }) {
            // User selected a specific resolution
            if displayModeService.applyMode(mode) {
                isActive = true
                activeMethod = .resolution(mode)
                settings.selectedAspectRatio = ar
                settings.selectedModeID = modeID
                onStateChanged?(true)
            }
        } else if let first = matchingModes.first {
            // Has matching resolutions — use the largest
            if displayModeService.applyMode(first) {
                isActive = true
                activeMethod = .resolution(first)
                settings.selectedAspectRatio = ar
                settings.selectedModeID = first.modeID
                onStateChanged?(true)
            }
        } else {
            // No matching resolution — use mask overlay
            maskService.showMask(for: ar)
            isActive = true
            activeMethod = .mask(ar)
            settings.selectedAspectRatio = ar
            settings.selectedModeID = nil
            onStateChanged?(true)
        }
    }

    func applyResolution(_ mode: DisplayMode, aspectRatio: AspectRatio) {
        disableWithoutNotify()

        if displayModeService.applyMode(mode) {
            isActive = true
            activeMethod = .resolution(mode)
            settings.selectedAspectRatio = aspectRatio
            settings.selectedModeID = mode.modeID
            onStateChanged?(true)
        }
    }

    func disable() {
        disableWithoutNotify()
        onStateChanged?(false)
    }

    func restoreOnTerminate() {
        disableWithoutNotify()
    }

    // MARK: - Query

    func modesForAspectRatio(_ ar: AspectRatio) -> [DisplayMode] {
        displayModeService.modesMatching(aspectRatio: ar)
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
        case nil:
            break
        }
        isActive = false
        activeMethod = nil
    }
}
