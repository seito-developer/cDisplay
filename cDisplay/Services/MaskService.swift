import AppKit

/// Manages the lifecycle of mask overlay panels:
/// creation, positioning, fade animation, and teardown.
@MainActor
final class MaskService {

    private var panels: [MaskOverlayPanel] = []
    private let displayService: DisplayService
    private let settings: SettingsService

    private static let fadeDuration: TimeInterval = 0.25

    // MARK: - Init

    init(displayService: DisplayService = DisplayService(),
         settings: SettingsService = .shared) {
        self.displayService = displayService
        self.settings = settings
    }

    // MARK: - Show / Hide

    func showMask() {
        removePanels()

        guard let maskRects = computeMaskRects() else { return }

        panels = maskRects.maskRects.enumerated().map { index, rect in
            let edge = guidelineEdge(for: rect, displayRect: maskRects.displayRect)
            let panel = MaskOverlayPanel(frame: rect, guidelineEdge: edge)
            panel.showGuideline = settings.showGuideline
            panel.setClickMode(settings.clickMode)
            panel.alphaValue = 0
            panel.orderFront(nil)
            return panel
        }

        fadeIn()
    }

    func hideMask(completion: (() -> Void)? = nil) {
        fadeOut { [weak self] in
            self?.removePanels()
            completion?()
        }
    }

    // MARK: - Update (settings changed while mask is visible)

    func updatePanels() {
        guard !panels.isEmpty else { return }

        guard let maskRects = computeMaskRects() else {
            removePanels()
            return
        }

        removePanels()
        panels = maskRects.maskRects.enumerated().map { index, rect in
            let edge = guidelineEdge(for: rect, displayRect: maskRects.displayRect)
            let panel = MaskOverlayPanel(frame: rect, guidelineEdge: edge)
            panel.showGuideline = settings.showGuideline
            panel.setClickMode(settings.clickMode)
            panel.alphaValue = 1
            panel.orderFront(nil)
            return panel
        }
    }

    func updateGuideline() {
        let show = settings.showGuideline
        panels.forEach { $0.showGuideline = show }
    }

    func updateClickMode() {
        let mode = settings.clickMode
        panels.forEach { $0.setClickMode(mode) }
    }

    // MARK: - Fade animation

    private func fadeIn() {
        NSAnimationContext.runAnimationGroup { context in
            context.duration = Self.fadeDuration
            for panel in panels {
                panel.animator().alphaValue = 1.0
            }
        }
    }

    private func fadeOut(completion: @escaping () -> Void) {
        NSAnimationContext.runAnimationGroup { context in
            context.duration = Self.fadeDuration
            for panel in panels {
                panel.animator().alphaValue = 0.0
            }
        } completionHandler: {
            completion()
        }
    }

    // MARK: - Private helpers

    private func computeMaskRects() -> MaskRects? {
        let visibleFrame = displayService.currentVisibleFrame()
        return displayService.maskRects(
            for: settings.aspectRatio,
            offset: settings.offsetPosition,
            in: visibleFrame
        )
    }

    private func removePanels() {
        panels.forEach { $0.orderOut(nil) }
        panels.removeAll()
    }

    private func guidelineEdge(for maskRect: CGRect, displayRect: CGRect) -> MaskPanelView.GuidelineEdge {
        // Determine which edge of the mask panel faces the display area.
        let epsilon: CGFloat = 1.0
        if abs(maskRect.maxY - displayRect.minY) < epsilon { return .top }
        if abs(maskRect.minY - displayRect.maxY) < epsilon { return .bottom }
        if abs(maskRect.maxX - displayRect.minX) < epsilon { return .left }
        return .right
    }
}
