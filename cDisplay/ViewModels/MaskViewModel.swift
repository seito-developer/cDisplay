import AppKit

/// Holds the mask state and notifies observers via a callback.
@MainActor
final class MaskViewModel {

    // MARK: - State

    private(set) var isMaskEnabled: Bool = false
    private(set) var currentDisplayRect: CGRect = .zero

    /// Called whenever `isMaskEnabled` changes.
    var onMaskStateChanged: ((Bool) -> Void)?

    // MARK: - Dependencies

    private let settings: SettingsService
    private let displayService: DisplayService

    // MARK: - Init

    init(settings: SettingsService = .shared, displayService: DisplayService = DisplayService()) {
        self.settings = settings
        self.displayService = displayService
    }

    // MARK: - Actions

    func toggleMask() {
        if isMaskEnabled {
            disableMask()
        } else {
            enableMask()
        }
    }

    func enableMask() {
        isMaskEnabled = true
        currentDisplayRect = computeDisplayRect()
        onMaskStateChanged?(true)
    }

    func disableMask() {
        isMaskEnabled = false
        currentDisplayRect = .zero
        onMaskStateChanged?(false)
    }

    // MARK: - Geometry

    /// Returns the mask rects for the current settings, or nil if same aspect ratio.
    func currentMaskRects() -> MaskRects? {
        let visibleFrame = displayService.currentVisibleFrame()
        return displayService.maskRects(
            for: settings.aspectRatio,
            offset: settings.offsetPosition,
            in: visibleFrame
        )
    }

    private func computeDisplayRect() -> CGRect {
        currentMaskRects()?.displayRect ?? .zero
    }
}
