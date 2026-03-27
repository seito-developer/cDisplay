import XCTest
@testable import cDisplay

final class DisplayServiceTests: XCTestCase {

    private let sut = DisplayService()

    // 16:9 screen (1920×1080)
    private let screen169 = CGRect(x: 0, y: 0, width: 1920, height: 1080)
    // 16:10 screen (1920×1200)
    private let screen1610 = CGRect(x: 0, y: 0, width: 1920, height: 1200)

    // MARK: - Same ratio → nil

    func testSameRatioReturnsNil() {
        // 16:9 screen with 16:9 mask → no masking needed
        let result = sut.maskRects(for: .widescreen, offset: .center, in: screen169)
        XCTAssertNil(result)
    }

    // MARK: - Letterbox (horizontal bars, wider target than screen)

    func testLetterboxCenterProducesTwoBars() {
        // 2.39:1 on a 16:9 screen → top and bottom bars
        let result = sut.maskRects(for: .cinemascope, offset: .center, in: screen169)
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.maskRects.count, 2)

        let rects = result!.maskRects
        // Both bars should span full width
        XCTAssertTrue(rects.allSatisfy { $0.width == screen169.width })
        // Top and bottom bars should have equal height
        let heights = rects.map(\.height).sorted()
        XCTAssertEqual(heights[0], heights[1], accuracy: 0.5)
    }

    func testLetterboxTopOffsetBottomBarOnly() {
        // 2.39:1 top-aligned → display at top, single bottom bar
        let result = sut.maskRects(for: .cinemascope, offset: .top, in: screen169)
        XCTAssertNotNil(result)
        // Should have 1 bar (bottom only)
        XCTAssertEqual(result?.maskRects.count, 1)
        let bar = result!.maskRects[0]
        XCTAssertEqual(bar.minY, screen169.minY, accuracy: 0.5)
    }

    func testLetterboxBottomOffsetTopBarOnly() {
        // 2.39:1 bottom-aligned → single top bar
        let result = sut.maskRects(for: .cinemascope, offset: .bottom, in: screen169)
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.maskRects.count, 1)
        let bar = result!.maskRects[0]
        XCTAssertEqual(bar.maxY, screen169.maxY, accuracy: 0.5)
    }

    // MARK: - Pillarbox (vertical bars, narrower target than screen)

    func testPillarboxProducesTwoBars() {
        // 4:3 on a 16:9 screen → left and right bars
        let result = sut.maskRects(for: .standard, offset: .center, in: screen169)
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.maskRects.count, 2)

        let rects = result!.maskRects
        // Both bars should span full display height
        let displayH = result!.displayRect.height
        XCTAssertTrue(rects.allSatisfy { abs($0.height - displayH) < 0.5 })
        // Symmetric widths
        let widths = rects.map(\.width).sorted()
        XCTAssertEqual(widths[0], widths[1], accuracy: 0.5)
    }

    // MARK: - Display rect coverage

    func testDisplayRectFillsScreenWidth_letterbox() {
        let result = sut.maskRects(for: .cinemascope, offset: .center, in: screen169)!
        XCTAssertEqual(result.displayRect.width, screen169.width, accuracy: 0.5)
    }

    func testDisplayRectFillsScreenHeight_pillarbox() {
        let result = sut.maskRects(for: .standard, offset: .center, in: screen169)!
        XCTAssertEqual(result.displayRect.height, screen169.height, accuracy: 0.5)
    }

    func testDisplayRectAspectRatioIsCorrect() {
        for ar in AspectRatio.allCases {
            let frame = screen1610 // use a non-matching screen
            guard let result = sut.maskRects(for: ar, offset: .center, in: frame) else {
                continue // same ratio, skip
            }
            let actualRatio = result.displayRect.width / result.displayRect.height
            XCTAssertEqual(actualRatio, ar.ratio, accuracy: 0.01, "Failed for \(ar)")
        }
    }

    // MARK: - Mask rects cover remainder of screen

    func testMaskRectsDoNotOverlapDisplayRect() {
        let result = sut.maskRects(for: .standard, offset: .center, in: screen169)!
        for maskRect in result.maskRects {
            XCTAssertFalse(maskRect.intersects(result.displayRect),
                           "Mask rect \(maskRect) overlaps display rect \(result.displayRect)")
        }
    }

    // MARK: - Vertical (9:16) is always horizontally centred

    func testVerticalIsHorizontallyCentred() {
        let result = sut.maskRects(for: .vertical, offset: .top, in: screen169)!
        let displayCentreX = result.displayRect.midX
        XCTAssertEqual(displayCentreX, screen169.midX, accuracy: 0.5)
    }
}
