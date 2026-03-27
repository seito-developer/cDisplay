import XCTest
@testable import cDisplay

final class SettingsServiceTests: XCTestCase {

    private var sut: SettingsService!

    override func setUp() {
        super.setUp()
        // Use a throwaway suite so tests never touch real UserDefaults
        let defaults = UserDefaults(suiteName: "SettingsServiceTests")!
        defaults.removePersistentDomain(forName: "SettingsServiceTests")
        sut = SettingsService(defaults: defaults)
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - Default values

    func testDefaultAspectRatio() {
        XCTAssertEqual(sut.aspectRatio, .widescreen)
    }

    func testDefaultOffsetPosition() {
        XCTAssertEqual(sut.offsetPosition, .center)
    }

    func testDefaultClickMode() {
        XCTAssertEqual(sut.clickMode, .passthrough)
    }

    func testDefaultShowGuideline() {
        XCTAssertFalse(sut.showGuideline)
    }

    func testDefaultKeyboardShortcut() {
        XCTAssertEqual(sut.keyboardShortcut, "⌃⌥⌘M")
    }

    // MARK: - Persistence (write → read)

    func testPersistAspectRatio() {
        sut.aspectRatio = .vertical
        XCTAssertEqual(sut.aspectRatio, .vertical)
    }

    func testPersistOffsetPosition() {
        sut.offsetPosition = .top
        XCTAssertEqual(sut.offsetPosition, .top)
    }

    func testPersistClickMode() {
        sut.clickMode = .blocking
        XCTAssertEqual(sut.clickMode, .blocking)
    }

    func testPersistShowGuideline() {
        sut.showGuideline = true
        XCTAssertTrue(sut.showGuideline)
    }

    func testPersistKeyboardShortcut() {
        sut.keyboardShortcut = "⌃⌥M"
        XCTAssertEqual(sut.keyboardShortcut, "⌃⌥M")
    }

    // MARK: - Reset

    func testResetRestoresDefaults() {
        sut.aspectRatio    = .square
        sut.offsetPosition = .bottom
        sut.clickMode      = .blocking
        sut.showGuideline  = true
        sut.keyboardShortcut = "⌃⌥M"

        sut.reset()

        XCTAssertEqual(sut.aspectRatio,    .widescreen)
        XCTAssertEqual(sut.offsetPosition, .center)
        XCTAssertEqual(sut.clickMode,      .passthrough)
        XCTAssertFalse(sut.showGuideline)
        XCTAssertEqual(sut.keyboardShortcut, "⌃⌥⌘M")
    }
}
