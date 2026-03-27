import AppKit

/// A borderless, non-activating floating panel that renders one black mask strip.
/// Multiple panels are combined to form the full letterbox / pillarbox mask.
@MainActor
final class MaskOverlayPanel: NSPanel {

    private(set) var panelView: MaskPanelView

    // MARK: - Init

    init(frame: CGRect, guidelineEdge: MaskPanelView.GuidelineEdge) {
        let view = MaskPanelView()
        view.guidelineEdge = guidelineEdge
        self.panelView = view

        super.init(
            contentRect: frame,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        configure()
        contentView = view
        view.frame = contentView?.bounds ?? .zero
        view.autoresizingMask = [.width, .height]
    }

    private func configure() {
        level = .floating
        backgroundColor = .black
        isOpaque = true
        hasShadow = false
        ignoresMouseEvents = true          // default: click-through
        collectionBehavior = [.canJoinAllSpaces, .stationary]
        isReleasedWhenClosed = false
    }

    // MARK: - Guideline

    var showGuideline: Bool {
        get { panelView.showGuideline }
        set { panelView.showGuideline = newValue }
    }

    // MARK: - Prevent panel from becoming key/main

    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
}
