import Foundation

struct M3UParseResult {
    let channels: [Channel]
    let epgURL: URL?
}

struct M3UParser {
    nonisolated func parse(_ content: String) throws -> M3UParseResult {
        let lines = content.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }

        guard let firstLine = lines.first, firstLine.uppercased().hasPrefix("#EXTM3U") else {
            throw ParseError.invalidFormat("Missing #EXTM3U header")
        }

        let epgURL = extractEPGURL(from: firstLine)
        var channels: [Channel] = []
        var pendingExtinf: String?

        for line in lines.dropFirst() {
            if line.isEmpty { continue }

            if line.uppercased().hasPrefix("#EXTINF:") {
                pendingExtinf = line
                continue
            }

            if line.hasPrefix("#") { continue }

            guard let extinf = pendingExtinf else { continue }
            pendingExtinf = nil

            guard let channel = parseChannel(extinf: extinf, urlString: line) else { continue }
            channels.append(channel)
        }

        return M3UParseResult(channels: channels, epgURL: epgURL)
    }

    private nonisolated func extractEPGURL(from header: String) -> URL? {
        if let raw = extractAttribute("url-tvg", from: header),
           let url = URL(string: raw) { return url }
        if let raw = extractAttribute("x-tvg-url", from: header),
           let url = URL(string: raw) { return url }
        return nil
    }

    private nonisolated func parseChannel(extinf: String, urlString: String) -> Channel? {
        guard
            let url = URL(string: urlString),
            url.scheme == "http" || url.scheme == "https"
        else { return nil }

        let (attributesPart, displayName) = splitExtinfLine(extinf)
        let tvgID = extractAttribute("tvg-id", from: attributesPart)
        let logoRaw = extractAttribute("tvg-logo", from: attributesPart)
        let groupTitle = extractAttribute("group-title", from: attributesPart) ?? ""
        let tvgName = extractAttribute("tvg-name", from: attributesPart)
        let name = displayName.isEmpty ? (tvgName ?? "Unknown") : displayName

        return Channel(
            id: UUID(),
            name: name,
            streamURL: url,
            logoURL: logoRaw.flatMap(URL.init(string:)),
            groupTitle: groupTitle,
            tvgID: tvgID.flatMap { $0.isEmpty ? nil : $0 },
            isFavorite: false
        )
    }

    // Finds the first unquoted comma to split attributes from display name.
    private nonisolated func splitExtinfLine(_ line: String) -> (attributes: String, name: String) {
        var inQuote = false
        var idx = line.startIndex
        while idx < line.endIndex {
            let char = line[idx]
            if char == "\"" {
                inQuote.toggle()
            } else if char == "," && !inQuote {
                let nameStart = line.index(after: idx)
                return (
                    String(line[line.startIndex..<idx]),
                    String(line[nameStart...]).trimmingCharacters(in: .whitespaces)
                )
            }
            idx = line.index(after: idx)
        }
        return (line, "")
    }

    private nonisolated func extractAttribute(_ key: String, from line: String) -> String? {
        // key="value"
        if let range = line.range(of: "\(key)=\"", options: .caseInsensitive) {
            let after = line[range.upperBound...]
            if let endQuote = after.firstIndex(of: "\"") {
                return String(after[after.startIndex..<endQuote])
            }
        }
        // key=value (unquoted)
        if let range = line.range(of: "\(key)=", options: .caseInsensitive) {
            let after = line[range.upperBound...]
            let end = after.firstIndex(where: { " ,\"".contains($0) }) ?? after.endIndex
            let value = String(after[after.startIndex..<end])
            return value.isEmpty ? nil : value
        }
        return nil
    }
}
