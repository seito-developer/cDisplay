import XCTest
@testable import cDisplay

final class DisplayInfoTests: XCTestCase {

    func testAspectRatioCalculation() {
        let info = DisplayInfo(
            screenFrame: CGRect(x: 0, y: 0, width: 1920, height: 1080),
            visibleFrame: CGRect(x: 0, y: 0, width: 1920, height: 1055)
        )
        XCTAssertEqual(info.screenAspectRatio, 1920.0 / 1055.0, accuracy: 0.001)
    }

    func testMatchesRatioWithinTolerance() {
        let info = DisplayInfo(
            screenFrame: CGRect(x: 0, y: 0, width: 1920, height: 1080),
            visibleFrame: CGRect(x: 0, y: 0, width: 1920, height: 1080)
        )
        XCTAssertTrue(info.matches(ratio: 16.0 / 9.0))
        XCTAssertFalse(info.matches(ratio: 4.0 / 3.0))
    }

    func testZeroHeightGuard() {
        let info = DisplayInfo(
            screenFrame: CGRect(x: 0, y: 0, width: 1920, height: 0),
            visibleFrame: CGRect(x: 0, y: 0, width: 1920, height: 0)
        )
        XCTAssertEqual(info.screenAspectRatio, 1.0)
    }
}
