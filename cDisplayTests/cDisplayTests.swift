import XCTest
@testable import cDisplay

final class AspectRatioTests: XCTestCase {

    func testRatioValues() {
        XCTAssertEqual(AspectRatio.widescreen.ratio,  16.0 / 9.0,  accuracy: 0.001)
        XCTAssertEqual(AspectRatio.standard.ratio,    4.0 / 3.0,   accuracy: 0.001)
        XCTAssertEqual(AspectRatio.cinemascope.ratio, 2.39,         accuracy: 0.001)
        XCTAssertEqual(AspectRatio.square.ratio,      1.0,          accuracy: 0.001)
        XCTAssertEqual(AspectRatio.vertical.ratio,    9.0 / 16.0,   accuracy: 0.001)
    }

    func testAllCasesCount() {
        XCTAssertEqual(AspectRatio.allCases.count, 5)
    }

    func testRawValueRoundtrip() {
        for ar in AspectRatio.allCases {
            XCTAssertEqual(AspectRatio(rawValue: ar.rawValue), ar)
        }
    }
}

final class OffsetPositionTests: XCTestCase {

    func testAllCasesCount() {
        XCTAssertEqual(OffsetPosition.allCases.count, 3)
    }

    func testRawValueRoundtrip() {
        for pos in OffsetPosition.allCases {
            XCTAssertEqual(OffsetPosition(rawValue: pos.rawValue), pos)
        }
    }
}

final class ClickModeTests: XCTestCase {

    func testAllCasesCount() {
        XCTAssertEqual(ClickMode.allCases.count, 2)
    }

    func testRawValueRoundtrip() {
        for mode in ClickMode.allCases {
            XCTAssertEqual(ClickMode(rawValue: mode.rawValue), mode)
        }
    }
}

final class DisplayInfoTests: XCTestCase {

    func testAspectRatioCalculation() {
        let info = DisplayInfo(
            screenFrame: CGRect(x: 0, y: 0, width: 1920, height: 1080),
            visibleFrame: CGRect(x: 0, y: 0, width: 1920, height: 1055)
        )
        XCTAssertEqual(info.screenAspectRatio, 1920.0 / 1055.0, accuracy: 0.001)
    }

    func testMatchesRatioWithinTolerance() {
        // 16:9 screen (1920x1080)
        let info = DisplayInfo(
            screenFrame: CGRect(x: 0, y: 0, width: 1920, height: 1080),
            visibleFrame: CGRect(x: 0, y: 0, width: 1920, height: 1080)
        )
        XCTAssertTrue(info.matches(ratio: AspectRatio.widescreen.ratio))
        XCTAssertFalse(info.matches(ratio: AspectRatio.standard.ratio))
    }

    func testZeroHeightGuard() {
        let info = DisplayInfo(
            screenFrame: CGRect(x: 0, y: 0, width: 1920, height: 0),
            visibleFrame: CGRect(x: 0, y: 0, width: 1920, height: 0)
        )
        XCTAssertEqual(info.screenAspectRatio, 1.0)
    }
}
