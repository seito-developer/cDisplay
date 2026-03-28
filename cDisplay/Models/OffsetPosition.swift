import Foundation

enum OffsetPosition: String, CaseIterable, Codable {
    case center
    case top
    case bottom

    var displayName: String {
        switch self {
        case .center: return "Center"
        case .top:    return "Top"
        case .bottom: return "Bottom"
        }
    }
}
