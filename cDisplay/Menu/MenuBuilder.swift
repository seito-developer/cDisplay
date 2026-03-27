import AppKit

/// Builds the NSMenu for the status bar dropdown.
@MainActor
final class MenuBuilder {

    // MARK: - Callbacks

    var onToggle: (() -> Void)?
    var onSelectAspectRatio: ((AspectRatio) -> Void)?
    var onSelectResolution: ((DisplayMode, AspectRatio) -> Void)?
    var onQuit: (() -> Void)?

    // MARK: - Build

    func buildMenu(
        isActive: Bool,
        activeMethod: DisplayMethod?,
        modesForRatio: (AspectRatio) -> [DisplayMode],
        nativeWidth: Int,
        nativeHeight: Int
    ) -> NSMenu {
        let menu = NSMenu()

        // 1. Toggle
        let toggleTitle = isActive ? "Disable" : "Enable"
        let toggleItem = NSMenuItem(title: toggleTitle, action: #selector(toggleAction(_:)), keyEquivalent: "")
        toggleItem.target = self
        menu.addItem(toggleItem)

        menu.addItem(.separator())

        // 2. Aspect Ratio submenu
        let arItem = NSMenuItem(title: "Aspect Ratio", action: nil, keyEquivalent: "")
        let arMenu = NSMenu()

        for ar in AspectRatio.allCases {
            let modes = modesForRatio(ar)

            if modes.isEmpty {
                // No matching resolution — single item, applies mask
                let item = NSMenuItem(title: ar.displayName + " (mask)", action: #selector(selectAspectRatioAction(_:)), keyEquivalent: "")
                item.target = self
                item.representedObject = ARWrapper(aspectRatio: ar)
                if case .mask(let activeAR) = activeMethod, activeAR == ar {
                    item.state = .on
                }
                arMenu.addItem(item)
            } else {
                // Has matching resolutions — submenu
                let groupItem = NSMenuItem(title: ar.displayName, action: nil, keyEquivalent: "")
                let groupMenu = NSMenu()

                for mode in modes {
                    var title = mode.displayName
                    if mode.width == nativeWidth && mode.height == nativeHeight {
                        title += " (native)"
                    }
                    let mItem = NSMenuItem(title: title, action: #selector(selectResolutionAction(_:)), keyEquivalent: "")
                    mItem.target = self
                    mItem.representedObject = ModeARWrapper(mode: mode, aspectRatio: ar)
                    if case .resolution(let activeMode) = activeMethod, activeMode == mode {
                        mItem.state = .on
                    }
                    groupMenu.addItem(mItem)
                }

                // Also add mask option as fallback
                let maskItem = NSMenuItem(title: "Mask overlay", action: #selector(selectAspectRatioAction(_:)), keyEquivalent: "")
                maskItem.target = self
                maskItem.representedObject = ARWrapper(aspectRatio: ar)
                if case .mask(let activeAR) = activeMethod, activeAR == ar {
                    maskItem.state = .on
                }
                groupMenu.addItem(.separator())
                groupMenu.addItem(maskItem)

                groupItem.submenu = groupMenu
                arMenu.addItem(groupItem)
            }
        }

        arItem.submenu = arMenu
        menu.addItem(arItem)

        menu.addItem(.separator())

        // 3. Display info
        let nativeItem = NSMenuItem(
            title: "Display: \(nativeWidth) × \(nativeHeight)",
            action: nil, keyEquivalent: ""
        )
        nativeItem.isEnabled = false
        menu.addItem(nativeItem)

        if case .resolution(let mode) = activeMethod {
            let activeItem = NSMenuItem(
                title: "Active: \(mode.width) × \(mode.height)",
                action: nil, keyEquivalent: ""
            )
            activeItem.isEnabled = false
            menu.addItem(activeItem)
        } else if case .mask(let ar) = activeMethod {
            let activeItem = NSMenuItem(
                title: "Active: \(ar.displayName) (mask)",
                action: nil, keyEquivalent: ""
            )
            activeItem.isEnabled = false
            menu.addItem(activeItem)
        }

        menu.addItem(.separator())

        // 4. Version
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "–"
        let versionItem = NSMenuItem(title: "Version \(version)", action: nil, keyEquivalent: "")
        versionItem.isEnabled = false
        menu.addItem(versionItem)

        // 5. Quit
        menu.addItem(.separator())
        let quitItem = NSMenuItem(title: "Quit cDisplay", action: #selector(quitAction(_:)), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        return menu
    }

    // MARK: - Actions

    @objc private func toggleAction(_ sender: NSMenuItem) {
        onToggle?()
    }

    @objc private func selectAspectRatioAction(_ sender: NSMenuItem) {
        guard let wrapper = sender.representedObject as? ARWrapper else { return }
        onSelectAspectRatio?(wrapper.aspectRatio)
    }

    @objc private func selectResolutionAction(_ sender: NSMenuItem) {
        guard let wrapper = sender.representedObject as? ModeARWrapper else { return }
        onSelectResolution?(wrapper.mode, wrapper.aspectRatio)
    }

    @objc private func quitAction(_ sender: NSMenuItem) {
        onQuit?()
    }
}

// MARK: - Wrappers for representedObject

private final class ARWrapper: NSObject {
    let aspectRatio: AspectRatio
    init(aspectRatio: AspectRatio) { self.aspectRatio = aspectRatio }
}

private final class ModeARWrapper: NSObject {
    let mode: DisplayMode
    let aspectRatio: AspectRatio
    init(mode: DisplayMode, aspectRatio: AspectRatio) {
        self.mode = mode
        self.aspectRatio = aspectRatio
    }
}
