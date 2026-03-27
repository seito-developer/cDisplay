import AppKit

/// Manages the resolution switching state.
@MainActor
final class DisplayModeViewModel {

    private(set) var isResolutionChanged: Bool = false
    private(set) var activeMode: DisplayMode?

    var onStateChanged: ((Bool) -> Void)?

    private let displayModeService: DisplayModeService
    private let settings: SettingsService

    init(displayModeService: DisplayModeService = DisplayModeService(),
         settings: SettingsService = .shared) {
        self.displayModeService = displayModeService
        self.settings = settings
    }

    // MARK: - Actions

    func toggleResolution() {
        if isResolutionChanged {
            restoreOriginalMode()
        } else {
            applyLastSelectedMode()
        }
    }

    func applyMode(_ mode: DisplayMode) {
        if displayModeService.applyMode(mode) {
            isResolutionChanged = true
            activeMode = mode
            settings.selectedModeID = mode.modeID
            onStateChanged?(true)
        }
    }

    func restoreOriginalMode() {
        if displayModeService.restoreOriginalMode() {
            isResolutionChanged = false
            activeMode = nil
            onStateChanged?(false)
        }
    }

    // MARK: - Query

    func availableModeGroups() -> [DisplayModeGroup] {
        displayModeService.availableModeGroups()
    }

    func nativeResolution() -> (width: Int, height: Int) {
        displayModeService.nativeResolution()
    }

    // MARK: - Private

    private func applyLastSelectedMode() {
        guard let modeID = settings.selectedModeID else { return }
        let groups = displayModeService.availableModeGroups()
        for group in groups {
            if let mode = group.modes.first(where: { $0.modeID == modeID }) {
                applyMode(mode)
                return
            }
        }
    }
}
