import AppKit

/// Manages the NSStatusItem in the menu bar.
/// Wires up MenuBuilder, MaskViewModel, and MaskService.
@MainActor
final class StatusBarController {

    private var statusItem: NSStatusItem?
    private let menuBuilder = MenuBuilder()
    private let viewModel: MaskViewModel
    private let maskService: MaskService
    private let settings: SettingsService
    private let displayService: DisplayService

    // MARK: - Icon names (SF Symbols)

    private static let iconOff = "rectangle.dashed"
    private static let iconOn  = "rectangle.fill"

    // MARK: - Init

    init(settings: SettingsService = .shared,
         displayService: DisplayService = DisplayService()) {
        self.settings = settings
        self.displayService = displayService
        self.viewModel = MaskViewModel(settings: settings, displayService: displayService)
        self.maskService = MaskService(displayService: displayService, settings: settings)
    }

    // MARK: - Setup

    func setup() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        statusItem = item

        updateIcon(maskEnabled: false)

        bindMenuCallbacks()
        bindViewModelCallbacks()

        // Build initial menu via delegate
        item.button?.target = self
        item.menu = rebuildMenu()
    }

    // MARK: - Public (for AppDelegate)

    func toggleMask() {
        viewModel.toggleMask()
    }

    var isMaskEnabled: Bool {
        viewModel.isMaskEnabled
    }

    // MARK: - Menu rebuild

    private func rebuildMenu() -> NSMenu {
        menuBuilder.buildMenu(
            isMaskEnabled: viewModel.isMaskEnabled,
            aspectRatio: settings.aspectRatio,
            offset: settings.offsetPosition,
            clickMode: settings.clickMode,
            showGuideline: settings.showGuideline,
            displayInfo: displayService.displayInfo(),
            displayRect: viewModel.currentDisplayRect
        )
    }

    private func refreshMenu() {
        statusItem?.menu = rebuildMenu()
    }

    // MARK: - Icon

    private func updateIcon(maskEnabled: Bool) {
        guard let button = statusItem?.button else { return }
        let name = maskEnabled ? Self.iconOn : Self.iconOff
        if let image = NSImage(systemSymbolName: name, accessibilityDescription: "cDisplay") {
            image.isTemplate = true
            button.image = image
        }
    }

    // MARK: - Bindings

    private func bindMenuCallbacks() {
        menuBuilder.onToggleMask = { [weak self] in
            self?.viewModel.toggleMask()
        }

        menuBuilder.onSelectAspectRatio = { [weak self] ar in
            guard let self else { return }
            self.settings.aspectRatio = ar
            if self.viewModel.isMaskEnabled {
                self.maskService.updatePanels()
                self.viewModel.enableMask() // refresh displayRect
            }
            self.refreshMenu()
        }

        menuBuilder.onSelectOffset = { [weak self] pos in
            guard let self else { return }
            self.settings.offsetPosition = pos
            if self.viewModel.isMaskEnabled {
                self.maskService.updatePanels()
                self.viewModel.enableMask()
            }
            self.refreshMenu()
        }

        menuBuilder.onSelectClickMode = { [weak self] mode in
            guard let self else { return }
            self.settings.clickMode = mode
            self.maskService.updateClickMode()
            self.refreshMenu()
        }

        menuBuilder.onToggleGuideline = { [weak self] in
            guard let self else { return }
            self.settings.showGuideline.toggle()
            self.maskService.updateGuideline()
            self.refreshMenu()
        }

        menuBuilder.onQuit = {
            NSApp.terminate(nil)
        }
    }

    private func bindViewModelCallbacks() {
        viewModel.onMaskStateChanged = { [weak self] enabled in
            guard let self else { return }
            if enabled {
                self.maskService.showMask()
            } else {
                self.maskService.hideMask()
            }
            self.updateIcon(maskEnabled: enabled)
            self.refreshMenu()
        }
    }
}
