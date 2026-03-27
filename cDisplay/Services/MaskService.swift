import AppKit

/// Manages the lifecycle of mask overlay panels:
/// creation, positioning, fade animation, and teardown.
@MainActor
final class MaskService {

    private var panels: [MaskOverlayPanel] = []
    private let displayService: DisplayService

    private static let fadeDuration: TimeInterval = 0.25

    // MARK: - Init

    init(displayService: DisplayService = DisplayService()) {
        self.displayService = displayService
    }

    // MARK: - Show / Hide

    func showMask(for aspectRatio: AspectRatio, offset: OffsetPosition = .center) {
        removePanels()

        let visibleFrame = displayService.currentVisibleFrame()
        guard let maskRects = displayService.maskRects(for: aspectRatio, offset: offset, in: visibleFrame) else {
            return
        }

        panels = maskRects.maskRects.map { rect in
            let edge = guidelineEdge(for: rect, displayRect: maskRects.displayRect)
            let panel = MaskOverlayPanel(frame: rect, guidelineEdge: edge)
            panel.alphaValue = 0
            panel.orderFront(nil)
            return panel
        }

        fadeIn()
    }

    func hideMask(completion: (() -> Void)? = nil) {
        guard !panels.isEmpty else {
            completion?()
            return
        }
        fadeOut { [weak self] in
            self?.removePanels()
            completion?()
        }
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

    private func removePanels() {
        panels.forEach { $0.orderOut(nil) }
        panels.removeAll()
    }

    private func guidelineEdge(for maskRect: CGRect, displayRect: CGRect) -> MaskPanelView.GuidelineEdge {
        let epsilon: CGFloat = 1.0
        if abs(maskRect.maxY - displayRect.minY) < epsilon { return .top }
        if abs(maskRect.minY - displayRect.maxY) < epsilon { return .bottom }
        if abs(maskRect.maxX - displayRect.minX) < epsilon { return .left }
        return .right
    }
}
