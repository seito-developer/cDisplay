import AppKit

/// Manages the NSStatusItem and wires up all components.
@MainActor
final class StatusBarController {

    private var statusItem: NSStatusItem?
    private let menuBuilder = MenuBuilder()
    private let viewModel: DisplayModeViewModel
    private let displayModeService: DisplayModeService

    private static let iconOff = "rectangle.dashed"
    private static let iconOn  = "rectangle.fill"

    // MARK: - Init

    init(displayModeService: DisplayModeService = DisplayModeService(),
         settings: SettingsService = .shared) {
        self.displayModeService = displayModeService
        self.viewModel = DisplayModeViewModel(displayModeService: displayModeService, settings: settings)
    }

    // MARK: - Setup

    func setup() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        statusItem = item

        updateIcon(active: false)
        bindMenuCallbacks()
        bindViewModelCallbacks()

        item.menu = rebuildMenu()
    }

    // MARK: - Public

    func toggleResolution() {
        viewModel.toggleResolution()
    }

    func restoreOnTerminate() {
        if viewModel.isResolutionChanged {
            viewModel.restoreOriginalMode()
        }
    }

    var isResolutionChanged: Bool {
        viewModel.isResolutionChanged
    }

    // MARK: - Menu

    private func rebuildMenu() -> NSMenu {
        let native = viewModel.nativeResolution()
        return menuBuilder.buildMenu(
            isResolutionChanged: viewModel.isResolutionChanged,
            activeMode: viewModel.activeMode,
            modeGroups: viewModel.availableModeGroups(),
            nativeWidth: native.width,
            nativeHeight: native.height
        )
    }

    private func refreshMenu() {
        statusItem?.menu = rebuildMenu()
    }

    // MARK: - Icon

    private func updateIcon(active: Bool) {
        guard let button = statusItem?.button else { return }
        let name = active ? Self.iconOn : Self.iconOff
        if let image = NSImage(systemSymbolName: name, accessibilityDescription: "cDisplay") {
            image.isTemplate = true
            button.image = image
        }
    }

    // MARK: - Bindings

    private func bindMenuCallbacks() {
        menuBuilder.onToggleResolution = { [weak self] in
            self?.viewModel.toggleResolution()
        }

        menuBuilder.onSelectResolution = { [weak self] mode in
            self?.viewModel.applyMode(mode)
        }

        menuBuilder.onQuit = {
            NSApp.terminate(nil)
        }
    }

    private func bindViewModelCallbacks() {
        viewModel.onStateChanged = { [weak self] active in
            self?.updateIcon(active: active)
            self?.refreshMenu()
        }
    }
}
