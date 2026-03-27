import AppKit

/// The content view of a MaskOverlayPanel.
/// Draws an optional 1pt white guideline on the edge facing the display area.
final class MaskPanelView: NSView {

    enum GuidelineEdge {
        case top, bottom, left, right
    }

    var showGuideline: Bool = false {
        didSet { needsDisplay = true }
    }

    var guidelineEdge: GuidelineEdge = .top {
        didSet { needsDisplay = true }
    }

    override var isFlipped: Bool { false }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        guard showGuideline else { return }

        NSColor.white.setStroke()
        let path = NSBezierPath()
        path.lineWidth = 1.0

        switch guidelineEdge {
        case .top:
            path.move(to: NSPoint(x: bounds.minX, y: bounds.maxY - 0.5))
            path.line(to: NSPoint(x: bounds.maxX, y: bounds.maxY - 0.5))
        case .bottom:
            path.move(to: NSPoint(x: bounds.minX, y: bounds.minY + 0.5))
            path.line(to: NSPoint(x: bounds.maxX, y: bounds.minY + 0.5))
        case .left:
            path.move(to: NSPoint(x: bounds.maxX - 0.5, y: bounds.minY))
            path.line(to: NSPoint(x: bounds.maxX - 0.5, y: bounds.maxY))
        case .right:
            path.move(to: NSPoint(x: bounds.minX + 0.5, y: bounds.minY))
            path.line(to: NSPoint(x: bounds.minX + 0.5, y: bounds.maxY))
        }

        path.stroke()
    }

    // MARK: - Click-blocking cursor

    override func resetCursorRects() {
        // Cursor is set by MaskOverlayPanel based on clickMode.
        // This override is intentionally empty; addCursorRect is called externally.
    }
}
