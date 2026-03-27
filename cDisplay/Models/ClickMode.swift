import Foundation

enum ClickMode: String, CaseIterable, Codable {
    case passthrough
    case blocking

    var displayName: String {
        switch self {
        case .passthrough: return "Click-Through"
        case .blocking:    return "Click-Blocking"
        }
    }
}
