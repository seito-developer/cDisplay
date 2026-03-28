import AppKit

/// Manages the NSStatusItem and wires up all components.
@MainActor
final class StatusBarController {

    private var statusItem: NSStatusItem?
    private let menuBuilder = MenuBuilder()
    private let viewModel: DisplayModeViewModel

    private static let iconOff = "rectangle.dashed"
    private static let iconOn  = "rectangle.fill"

    // MARK: - Init

    init(displayModeService: DisplayModeService = DisplayModeService(),
         settings: SettingsService = .shared) {
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

    func toggle() {
        viewModel.toggle()
    }

    func showMenu() {
        guard let button = statusItem?.button else { return }
        let menu = rebuildMenu()
        statusItem?.menu = menu
        menu.popUp(positioning: nil, at: NSPoint(x: 0, y: button.bounds.height), in: button)
    }

    func restoreOnTerminate() {
        viewModel.restoreOnTerminate()
    }

    // MARK: - Menu

    private func rebuildMenu() -> NSMenu {
        let native = viewModel.nativeResolution()
        return menuBuilder.buildMenu(
            isActive: viewModel.isActive,
            activeMethod: viewModel.activeMethod,
            targetGroups: viewModel.targetResolutions(),
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
        menuBuilder.onToggle = { [weak self] in
            self?.viewModel.toggle()
        }

        menuBuilder.onSelectTarget = { [weak self] target in
            self?.viewModel.applyTarget(target)
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
