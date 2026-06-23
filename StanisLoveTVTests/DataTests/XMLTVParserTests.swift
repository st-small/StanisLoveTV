import Foundation
import Testing
@testable import StanisLoveTV

@Suite("XMLTVParser")
struct XMLTVParserTests {
    let parser = XMLTVParser()

    // MARK: - Helpers

    private func makeXMLTV(programs: String) -> Data {
        """
        <?xml version="1.0" encoding="UTF-8"?>
        <tv>
        \(programs)
        </tv>
        """.data(using: .utf8)!
    }

    // MARK: - Date / timezone parsing

    @Test func parseSingleProgram_utcTimezone() async throws {
        let xml = makeXMLTV(programs: """
        <programme start="20240115120000 +0000" stop="20240115130000 +0000" channel="ch1">
          <title>Morning News</title>
        </programme>
        """)
        let programs = try await parser.parse(xml)
        #expect(programs.count == 1)
        #expect(programs[0].title == "Morning News")
        #expect(programs[0].channelID == "ch1")
    }

    @Test func parseSingleProgram_positiveOffset() async throws {
        let xml = makeXMLTV(programs: """
        <programme start="20240115120000 +0300" stop="20240115130000 +0300" channel="ch2">
          <title>Evening Show</title>
        </programme>
        """)
        let programs = try await parser.parse(xml)
        #expect(programs.count == 1)
        #expect(programs[0].channelID == "ch2")
    }

    @Test func parseSingleProgram_negativeOffset() async throws {
        let xml = makeXMLTV(programs: """
        <programme start="20240115060000 -0500" stop="20240115070000 -0500" channel="ch3">
          <title>Late Night</title>
        </programme>
        """)
        let programs = try await parser.parse(xml)
        #expect(programs.count == 1)
        #expect(programs[0].title == "Late Night")
    }

    // MARK: - Description field

    @Test func parseProgramWithDescription() async throws {
        let xml = makeXMLTV(programs: """
        <programme start="20240115120000 +0000" stop="20240115130000 +0000" channel="ch1">
          <title>Documentary</title>
          <desc>A fascinating look at wildlife.</desc>
        </programme>
        """)
        let programs = try await parser.parse(xml)
        #expect(programs.count == 1)
        #expect(programs[0].description == "A fascinating look at wildlife.")
    }

    // MARK: - Multiple channels

    @Test func parseProgramsForMultipleChannels() async throws {
        let xml = makeXMLTV(programs: """
        <programme start="20240115120000 +0000" stop="20240115130000 +0000" channel="ch1">
          <title>Show A</title>
        </programme>
        <programme start="20240115120000 +0000" stop="20240115130000 +0000" channel="ch2">
          <title>Show B</title>
        </programme>
        """)
        let programs = try await parser.parse(xml)
        #expect(programs.count == 2)
        #expect(programs.map(\.channelID).sorted() == ["ch1", "ch2"])
    }

    // MARK: - Malformed input

    @Test func programWithMissingTitle_skipped() async throws {
        let xml = makeXMLTV(programs: """
        <programme start="20240115120000 +0000" stop="20240115130000 +0000" channel="ch1">
        </programme>
        """)
        let programs = try await parser.parse(xml)
        #expect(programs.isEmpty)
    }
}
