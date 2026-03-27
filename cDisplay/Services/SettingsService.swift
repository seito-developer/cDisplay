import Foundation

final class SettingsService {

    static let shared = SettingsService()

    private let defaults: UserDefaults

    // MARK: - Keys

    private enum Key {
        static let selectedAspectRatio = "selectedAspectRatio"
        static let selectedModeID      = "selectedModeID"
        static let keyboardShortcut    = "keyboardShortcut"
    }

    // MARK: - Defaults

    static let defaultKeyboardShortcut = "⌃⌥⌘M"

    // MARK: - Init

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    // MARK: - Selected Aspect Ratio

    var selectedAspectRatio: AspectRatio? {
        get {
            guard let raw = defaults.string(forKey: Key.selectedAspectRatio),
                  let value = AspectRatio(rawValue: raw) else {
                return nil
            }
            return value
        }
        set {
            if let value = newValue {
                defaults.set(value.rawValue, forKey: Key.selectedAspectRatio)
            } else {
                defaults.removeObject(forKey: Key.selectedAspectRatio)
            }
        }
    }

    // MARK: - Selected Mode ID

    var selectedModeID: Int32? {
        get {
            defaults.object(forKey: Key.selectedModeID) == nil
                ? nil
                : Int32(defaults.integer(forKey: Key.selectedModeID))
        }
        set {
            if let value = newValue {
                defaults.set(Int(value), forKey: Key.selectedModeID)
            } else {
                defaults.removeObject(forKey: Key.selectedModeID)
            }
        }
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
        [Key.selectedAspectRatio, Key.selectedModeID, Key.keyboardShortcut].forEach {
            defaults.removeObject(forKey: $0)
        }
    }
}
