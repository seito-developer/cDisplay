import AppKit

/// Builds the NSMenu for the status bar dropdown.
@MainActor
final class MenuBuilder {

    // MARK: - Callbacks

    var onToggle: (() -> Void)?
    var onSelectTarget: ((TargetResolution) -> Void)?
    var onQuit: (() -> Void)?

    // MARK: - Build

    func buildMenu(
        isActive: Bool,
        activeMethod: DisplayMethod?,
        targetGroups: [String: [TargetResolution]],
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

        // 2. Resolution submenu grouped by aspect ratio
        let resItem = NSMenuItem(title: "Resolution", action: nil, keyEquivalent: "")
        let resMenu = NSMenu()

        let groupOrder = ["16:9", "4:3", "2.39:1", "1:1", "9:16"]
        for label in groupOrder {
            guard let targets = targetGroups[label], !targets.isEmpty else { continue }

            // Section header
            let header = NSMenuItem(title: label, action: nil, keyEquivalent: "")
            header.isEnabled = false
            resMenu.addItem(header)

            for target in targets {
                let item = NSMenuItem(
                    title: "    \(target.displayName)",
                    action: #selector(selectTargetAction(_:)),
                    keyEquivalent: ""
                )
                item.target = self
                item.representedObject = TargetWrapper(target: target)

                // Checkmark for active target
                if let active = activeTarget(from: activeMethod), active == target {
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
            title: "Display: \(nativeWidth) × \(nativeHeight)",
            action: nil, keyEquivalent: ""
        )
        nativeItem.isEnabled = false
        menu.addItem(nativeItem)

        if let activeMethod {
            let desc: String
            switch activeMethod {
            case .resolution(let mode):
                desc = "Active: \(mode.width) × \(mode.height)"
            case .mask(let ar):
                desc = "Active: \(ar.displayName) (mask)"
            case .resolutionPlusMask(let mode, let target):
                desc = "Active: \(target.displayName) (via \(mode.width)×\(mode.height) + mask)"
            }
            let activeItem = NSMenuItem(title: desc, action: nil, keyEquivalent: "")
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

    // MARK: - Helpers

    private func activeTarget(from method: DisplayMethod?) -> TargetResolution? {
        switch method {
        case .resolutionPlusMask(_, let target): return target
        case .mask(let ar):
            return TargetResolution(width: 0, height: 0, aspectLabel: ar.rawValue)
        default: return nil
        }
    }

    // MARK: - Actions

    @objc private func toggleAction(_ sender: NSMenuItem) {
        onToggle?()
    }

    @objc private func selectTargetAction(_ sender: NSMenuItem) {
        guard let wrapper = sender.representedObject as? TargetWrapper else { return }
        onSelectTarget?(wrapper.target)
    }

    @objc private func quitAction(_ sender: NSMenuItem) {
        onQuit?()
    }
}

private final class TargetWrapper: NSObject {
    let target: TargetResolution
    init(target: TargetResolution) { self.target = target }
}
