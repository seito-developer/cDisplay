import Foundation

final class SettingsService {

    static let shared = SettingsService()

    private let defaults: UserDefaults

    // MARK: - Keys

    private enum Key {
        static let aspectRatio      = "aspectRatio"
        static let offsetPosition   = "offsetPosition"
        static let clickMode        = "clickMode"
        static let showGuideline    = "showGuideline"
        static let keyboardShortcut = "keyboardShortcut"
    }

    // MARK: - Defaults

    static let defaultAspectRatio      = AspectRatio.widescreen
    static let defaultOffsetPosition   = OffsetPosition.center
    static let defaultClickMode        = ClickMode.passthrough
    static let defaultShowGuideline    = false
    static let defaultKeyboardShortcut = "⌃⌥⌘M"

    // MARK: - Init

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    // MARK: - AspectRatio

    var aspectRatio: AspectRatio {
        get {
            guard let raw = defaults.string(forKey: Key.aspectRatio),
                  let value = AspectRatio(rawValue: raw) else {
                return Self.defaultAspectRatio
            }
            return value
        }
        set { defaults.set(newValue.rawValue, forKey: Key.aspectRatio) }
    }

    // MARK: - OffsetPosition

    var offsetPosition: OffsetPosition {
        get {
            guard let raw = defaults.string(forKey: Key.offsetPosition),
                  let value = OffsetPosition(rawValue: raw) else {
                return Self.defaultOffsetPosition
            }
            return value
        }
        set { defaults.set(newValue.rawValue, forKey: Key.offsetPosition) }
    }

    // MARK: - ClickMode

    var clickMode: ClickMode {
        get {
            guard let raw = defaults.string(forKey: Key.clickMode),
                  let value = ClickMode(rawValue: raw) else {
                return Self.defaultClickMode
            }
            return value
        }
        set { defaults.set(newValue.rawValue, forKey: Key.clickMode) }
    }

    // MARK: - Show Guideline

    var showGuideline: Bool {
        get {
            defaults.object(forKey: Key.showGuideline) == nil
                ? Self.defaultShowGuideline
                : defaults.bool(forKey: Key.showGuideline)
        }
        set { defaults.set(newValue, forKey: Key.showGuideline) }
    }

    // MARK: - Keyboard Shortcut

    var keyboardShortcut: String {
        get {
            defaults.string(forKey: Key.keyboardShortcut) ?? Self.defaultKeyboardShortcut
        }
        set { defaults.set(newValue, forKey: Key.keyboardShortcut) }
    }

    // MARK: - Reset

    func reset() {
        [Key.aspectRatio, Key.offsetPosition, Key.clickMode,
         Key.showGuideline, Key.keyboardShortcut].forEach {
            defaults.removeObject(forKey: $0)
        }
    }
}
