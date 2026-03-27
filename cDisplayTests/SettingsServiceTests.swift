import XCTest
@testable import cDisplay

final class SettingsServiceTests: XCTestCase {

    private var sut: SettingsService!

    override func setUp() {
        super.setUp()
        let defaults = UserDefaults(suiteName: "SettingsServiceTests")!
        defaults.removePersistentDomain(forName: "SettingsServiceTests")
        sut = SettingsService(defaults: defaults)
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - Default values

    func testDefaultSelectedModeID() {
        XCTAssertNil(sut.selectedModeID)
    }

    func testDefaultKeyboardShortcut() {
        XCTAssertEqual(sut.keyboardShortcut, "⌃⌥⌘M")
    }

    // MARK: - Persistence

    func testPersistSelectedModeID() {
        sut.selectedModeID = 42
        XCTAssertEqual(sut.selectedModeID, 42)
    }

    func testClearSelectedModeID() {
        sut.selectedModeID = 42
        sut.selectedModeID = nil
        XCTAssertNil(sut.selectedModeID)
    }

    func testPersistKeyboardShortcut() {
        sut.keyboardShortcut = "⌃⌥M"
        XCTAssertEqual(sut.keyboardShortcut, "⌃⌥M")
    }

    // MARK: - Reset

    func testResetRestoresDefaults() {
        sut.selectedModeID = 99
        sut.keyboardShortcut = "⌃⌥M"

        sut.reset()

        XCTAssertNil(sut.selectedModeID)
        XCTAssertEqual(sut.keyboardShortcut, "⌃⌥⌘M")
    }
}
