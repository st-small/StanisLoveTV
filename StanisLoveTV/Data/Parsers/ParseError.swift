import Foundation

enum ParseError: LocalizedError {
    case invalidFormat(String)
    case xmlParsingFailed(String)

    var errorDescription: String? {
        switch self {
        case .invalidFormat(let detail):
            return "Invalid M3U format: \(detail)"
        case .xmlParsingFailed(let detail):
            return "XML parsing failed: \(detail)"
        }
    }
}
