import AppKit

struct MaskRects {
    /// The display area (the "hole" left visible after masking).
    let displayRect: CGRect
    /// The mask panels to show. 2 panels for letterbox/pillarbox, up to 4 for mixed.
    let maskRects: [CGRect]
}

final class DisplayService {

    // MARK: - Screen Info

    /// Returns the current main screen's visible frame (below menu bar, above Dock).
    func currentVisibleFrame() -> CGRect {
        NSScreen.main?.visibleFrame ?? .zero
    }

    func displayInfo() -> DisplayInfo? {
        guard let screen = NSScreen.main else { return nil }
        return DisplayInfo(screenFrame: screen.frame, visibleFrame: screen.visibleFrame)
    }

    // MARK: - Geometry

    /// Computes the display rect and mask rects for the given aspect ratio and offset.
    /// Returns nil if the screen matches the target ratio (no masking needed).
    func maskRects(
        for ratio: AspectRatio,
        offset: OffsetPosition,
        in visibleFrame: CGRect
    ) -> MaskRects? {
        let targetRatio = ratio.ratio
        let screenRatio = visibleFrame.width / visibleFrame.height

        // Detect same aspect ratio (within tolerance) — no mask needed.
        guard abs(screenRatio - targetRatio) >= 0.01 else { return nil }

        let displayRect = self.displayRect(targetRatio: targetRatio, offset: offset, in: visibleFrame)
        let masks = buildMaskRects(displayRect: displayRect, visibleFrame: visibleFrame)

        return MaskRects(displayRect: displayRect, maskRects: masks)
    }

    // MARK: - Private helpers

    private func displayRect(
        targetRatio: Double,
        offset: OffsetPosition,
        in frame: CGRect
    ) -> CGRect {
        let screenRatio = frame.width / frame.height

        let size: CGSize
        if targetRatio < screenRatio {
            // Target is taller than screen → pillarbox: constrain by height
            let h = frame.height
            size = CGSize(width: h * targetRatio, height: h)
        } else {
            // Target is wider than screen → letterbox: constrain by width
            let w = frame.width
            size = CGSize(width: w, height: w / targetRatio)
        }

        // Horizontal: always centred
        let x = frame.minX + (frame.width - size.width) / 2

        // Vertical: depends on offset (only meaningful for letterbox)
        let y: CGFloat
        switch offset {
        case .center:
            y = frame.minY + (frame.height - size.height) / 2
        case .top:
            y = frame.maxY - size.height
        case .bottom:
            y = frame.minY
        }

        return CGRect(origin: CGPoint(x: x, y: y), size: size)
    }

    private func buildMaskRects(displayRect: CGRect, visibleFrame: CGRect) -> [CGRect] {
        var rects: [CGRect] = []

        // Bottom strip
        if displayRect.minY > visibleFrame.minY {
            rects.append(CGRect(
                x: visibleFrame.minX,
                y: visibleFrame.minY,
                width: visibleFrame.width,
                height: displayRect.minY - visibleFrame.minY
            ))
        }

        // Top strip
        if displayRect.maxY < visibleFrame.maxY {
            rects.append(CGRect(
                x: visibleFrame.minX,
                y: displayRect.maxY,
                width: visibleFrame.width,
                height: visibleFrame.maxY - displayRect.maxY
            ))
        }

        // Left strip (spanning display height only, to avoid overlap)
        if displayRect.minX > visibleFrame.minX {
            rects.append(CGRect(
                x: visibleFrame.minX,
                y: displayRect.minY,
                width: displayRect.minX - visibleFrame.minX,
                height: displayRect.height
            ))
        }

        // Right strip
        if displayRect.maxX < visibleFrame.maxX {
            rects.append(CGRect(
                x: displayRect.maxX,
                y: displayRect.minY,
                width: visibleFrame.maxX - displayRect.maxX,
                height: displayRect.height
            ))
        }

        return rects
    }
}
