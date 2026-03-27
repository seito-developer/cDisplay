import AppKit

/// Builds the NSMenu for the status bar dropdown.
@MainActor
final class MenuBuilder {

    // MARK: - Callbacks

    var onToggleResolution: (() -> Void)?
    var onSelectResolution: ((DisplayMode) -> Void)?
    var onQuit: (() -> Void)?

    // MARK: - Build

    func buildMenu(
        isResolutionChanged: Bool,
        activeMode: DisplayMode?,
        modeGroups: [DisplayModeGroup],
        nativeWidth: Int,
        nativeHeight: Int
    ) -> NSMenu {
        let menu = NSMenu()

        // 1. Toggle resolution
        let toggleTitle = isResolutionChanged ? "Disable Resolution" : "Enable Resolution"
        let toggleItem = NSMenuItem(title: toggleTitle, action: #selector(toggleAction(_:)), keyEquivalent: "")
        toggleItem.target = self
        if !isResolutionChanged && activeMode == nil {
            // No mode selected yet — disable toggle until user picks one
        }
        menu.addItem(toggleItem)

        menu.addItem(.separator())

        // 2. Resolution submenu grouped by aspect ratio
        let resItem = NSMenuItem(title: "Resolution", action: nil, keyEquivalent: "")
        let resMenu = NSMenu()

        for group in modeGroups {
            // Section header
            let header = NSMenuItem(title: group.label, action: nil, keyEquivalent: "")
            header.isEnabled = false
            resMenu.addItem(header)

            for mode in group.modes {
                var title = mode.displayName
                if mode.width == nativeWidth && mode.height == nativeHeight {
                    title += " (native)"
                }
                let item = NSMenuItem(title: "    " + title, action: #selector(selectResolutionAction(_:)), keyEquivalent: "")
                item.target = self
                item.representedObject = ModeWrapper(mode: mode)
                if let active = activeMode, active == mode {
                    item.state = .on
                }
                resMenu.addItem(item)
            }
        }

        resItem.submenu = resMenu
        menu.addItem(resItem)

        menu.addItem(.separator())

        // 3. Display info
        let nativeItem = NSMenuItem(
            title: "Display: \(nativeWidth) × \(nativeHeight) (native)",
            action: nil, keyEquivalent: ""
        )
        nativeItem.isEnabled = false
        menu.addItem(nativeItem)

        if let active = activeMode {
            let activeItem = NSMenuItem(
                title: "Active: \(active.width) × \(active.height)",
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
        onToggleResolution?()
    }

    @objc private func selectResolutionAction(_ sender: NSMenuItem) {
        guard let wrapper = sender.representedObject as? ModeWrapper else { return }
        onSelectResolution?(wrapper.mode)
    }

    @objc private func quitAction(_ sender: NSMenuItem) {
        onQuit?()
    }
}

/// Wraps DisplayMode for use as NSMenuItem.representedObject (must be AnyObject).
private final class ModeWrapper: NSObject {
    let mode: DisplayMode
    init(mode: DisplayMode) { self.mode = mode }
}
