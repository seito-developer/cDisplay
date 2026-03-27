import CoreGraphics

struct DisplayInfo {
    let screenFrame: CGRect
    let visibleFrame: CGRect

    var screenSize: CGSize { screenFrame.size }
    var availableSize: CGSize { visibleFrame.size }

    var screenAspectRatio: Double {
        guard visibleFrame.height > 0 else { return 1.0 }
        return visibleFrame.width / visibleFrame.height
    }

    /// Returns true if the visible frame's aspect ratio matches `ratio` within `tolerance`.
    func matches(ratio: Double, tolerance: Double = 0.01) -> Bool {
        abs(screenAspectRatio - ratio) < tolerance
    }
}
