import Foundation

struct XMLTVParser {
    nonisolated func parse(_ data: Data) async throws -> [EPGProgram] {
        try await Task.detached(priority: .userInitiated) {
            let delegate = XMLTVParserDelegate()
            let xmlParser = XMLParser(data: data)
            xmlParser.delegate = delegate
            guard xmlParser.parse() else {
                throw ParseError.xmlParsingFailed(
                    xmlParser.parserError?.localizedDescription ?? "Unknown XML error"
                )
            }
            return delegate.programs
        }.value
    }
}

private final class XMLTVParserDelegate: NSObject, XMLParserDelegate {
    nonisolated(unsafe) private(set) var programs: [EPGProgram] = []

    nonisolated(unsafe) private var currentChannelID: String?
    nonisolated(unsafe) private var currentStart: Date?
    nonisolated(unsafe) private var currentEnd: Date?
    nonisolated(unsafe) private var currentTitle: String?
    nonisolated(unsafe) private var currentDesc: String?
    nonisolated(unsafe) private var insideElement: String?

    nonisolated override init() {
        super.init()
    }

    private nonisolated func parseDate(_ string: String) -> Date? {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyyMMddHHmmss Z"
        return formatter.date(from: string)
    }

    nonisolated func parser(
        _ parser: XMLParser,
        didStartElement elementName: String,
        namespaceURI: String?,
        qualifiedName qName: String?,
        attributes: [String: String] = [:]
    ) {
        switch elementName.lowercased() {
        case "programme":
            currentChannelID = attributes["channel"]
            currentStart = attributes["start"].flatMap(parseDate)
            currentEnd = attributes["stop"].flatMap(parseDate)
            currentTitle = nil
            currentDesc = nil
            insideElement = nil
        case "title", "desc":
            insideElement = elementName.lowercased()
        default:
            insideElement = nil
        }
    }

    nonisolated func parser(_ parser: XMLParser, foundCharacters string: String) {
        switch insideElement {
        case "title":
            currentTitle = (currentTitle ?? "") + string
        case "desc":
            currentDesc = (currentDesc ?? "") + string
        default:
            break
        }
    }

    nonisolated func parser(
        _ parser: XMLParser,
        didEndElement elementName: String,
        namespaceURI: String?,
        qualifiedName qName: String?
    ) {
        let lower = elementName.lowercased()
        guard lower != "title" && lower != "desc" else {
            insideElement = nil
            return
        }

        guard lower == "programme" else { return }

        guard
            let channelID = currentChannelID,
            let start = currentStart,
            let end = currentEnd,
            let rawTitle = currentTitle,
            !rawTitle.trimmingCharacters(in: .whitespaces).isEmpty
        else {
            resetCurrentProgram()
            return
        }

        programs.append(EPGProgram(
            id: UUID(),
            channelID: channelID,
            title: rawTitle.trimmingCharacters(in: .whitespaces),
            startTime: start,
            endTime: end,
            description: currentDesc?.trimmingCharacters(in: .whitespaces)
        ))

        resetCurrentProgram()
    }

    private nonisolated func resetCurrentProgram() {
        currentChannelID = nil
        currentStart = nil
        currentEnd = nil
        currentTitle = nil
        currentDesc = nil
        insideElement = nil
    }
}
