import AppKit

/// Builds and updates the NSMenu for the status bar dropdown.
@MainActor
final class MenuBuilder {

    // MARK: - Callbacks

    var onToggleMask: (() -> Void)?
    var onSelectAspectRatio: ((AspectRatio) -> Void)?
    var onSelectOffset: ((OffsetPosition) -> Void)?
    var onSelectClickMode: ((ClickMode) -> Void)?
    var onToggleGuideline: (() -> Void)?
    var onQuit: (() -> Void)?

    // MARK: - Build

    func buildMenu(
        isMaskEnabled: Bool,
        aspectRatio: AspectRatio,
        offset: OffsetPosition,
        clickMode: ClickMode,
        showGuideline: Bool,
        displayInfo: DisplayInfo?,
        displayRect: CGRect
    ) -> NSMenu {
        let menu = NSMenu()

        // 1. Mask ON/OFF toggle
        let toggleTitle = isMaskEnabled ? "Disable Mask" : "Enable Mask"
        let toggleItem = NSMenuItem(title: toggleTitle, action: #selector(toggleMaskAction(_:)), keyEquivalent: "")
        toggleItem.target = self
        menu.addItem(toggleItem)

        menu.addItem(.separator())

        // 2. Aspect Ratio submenu
        let ratioItem = NSMenuItem(title: "Aspect Ratio", action: nil, keyEquivalent: "")
        let ratioMenu = NSMenu()
        for ar in AspectRatio.allCases {
            let item = NSMenuItem(title: ar.displayName, action: #selector(selectAspectRatioAction(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = ar
            item.state = (ar == aspectRatio) ? .on : .off
            ratioMenu.addItem(item)
        }
        ratioItem.submenu = ratioMenu
        menu.addItem(ratioItem)

        // 3. Offset Position submenu
        let offsetItem = NSMenuItem(title: "Position", action: nil, keyEquivalent: "")
        let offsetMenu = NSMenu()
        for pos in OffsetPosition.allCases {
            let item = NSMenuItem(title: pos.displayName, action: #selector(selectOffsetAction(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = pos
            item.state = (pos == offset) ? .on : .off
            offsetMenu.addItem(item)
        }
        offsetItem.submenu = offsetMenu
        menu.addItem(offsetItem)

        // 4. Click Mode submenu
        let clickItem = NSMenuItem(title: "Click Mode", action: nil, keyEquivalent: "")
        let clickMenu = NSMenu()
        for mode in ClickMode.allCases {
            let item = NSMenuItem(title: mode.displayName, action: #selector(selectClickModeAction(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = mode
            item.state = (mode == clickMode) ? .on : .off
            clickMenu.addItem(item)
        }
        clickItem.submenu = clickMenu
        menu.addItem(clickItem)

        // 5. Guideline toggle
        let guideItem = NSMenuItem(title: "Show Guideline", action: #selector(toggleGuidelineAction(_:)), keyEquivalent: "")
        guideItem.target = self
        guideItem.state = showGuideline ? .on : .off
        menu.addItem(guideItem)

        menu.addItem(.separator())

        // 6. Display info (mask ON only)
        if isMaskEnabled, let info = displayInfo {
            let screenSize = info.screenSize
            let screenItem = NSMenuItem(
                title: "Display: \(Int(screenSize.width))×\(Int(screenSize.height))",
                action: nil, keyEquivalent: ""
            )
            screenItem.isEnabled = false
            menu.addItem(screenItem)

            if displayRect != .zero {
                let areaItem = NSMenuItem(
                    title: "Visible: \(Int(displayRect.width))×\(Int(displayRect.height))",
                    action: nil, keyEquivalent: ""
                )
                areaItem.isEnabled = false
                menu.addItem(areaItem)
            }

            menu.addItem(.separator())
        }

        // 7. Version
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "–"
        let versionItem = NSMenuItem(title: "Version \(version)", action: nil, keyEquivalent: "")
        versionItem.isEnabled = false
        menu.addItem(versionItem)

        // 8. Quit
        menu.addItem(.separator())
        let quitItem = NSMenuItem(title: "Quit cDisplay", action: #selector(quitAction(_:)), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        return menu
    }

    // MARK: - Actions

    @objc private func toggleMaskAction(_ sender: NSMenuItem) {
        onToggleMask?()
    }

    @objc private func selectAspectRatioAction(_ sender: NSMenuItem) {
        guard let ar = sender.representedObject as? AspectRatio else { return }
        onSelectAspectRatio?(ar)
    }

    @objc private func selectOffsetAction(_ sender: NSMenuItem) {
        guard let pos = sender.representedObject as? OffsetPosition else { return }
        onSelectOffset?(pos)
    }

    @objc private func selectClickModeAction(_ sender: NSMenuItem) {
        guard let mode = sender.representedObject as? ClickMode else { return }
        onSelectClickMode?(mode)
    }

    @objc private func toggleGuidelineAction(_ sender: NSMenuItem) {
        onToggleGuideline?()
    }

    @objc private func quitAction(_ sender: NSMenuItem) {
        onQuit?()
    }
}
