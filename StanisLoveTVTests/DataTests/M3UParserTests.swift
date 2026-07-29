import Foundation
import Testing
@testable import StanisLoveTV

@Suite("M3UParser")
struct M3UParserTests {
    let parser = M3UParser()

    // MARK: - Header validation

    @Test func missingExtm3uHeader_throwsInvalidFormat() {
        #expect(throws: ParseError.self) {
            try parser.parse("http://example.com/stream.m3u8")
        }
    }

    @Test func validHeader_noChannels_returnsEmptyResult() throws {
        let content = "#EXTM3U\n"
        let result = try parser.parse(content)
        #expect(result.channels.isEmpty)
        #expect(result.epgURL == nil)
    }

    // MARK: - EPG URL extraction

    @Test func urlTvgAttribute_extractsEPGURL() throws {
        let content = "#EXTM3U url-tvg=\"http://epg.example.com/guide.xml\"\n"
        let result = try parser.parse(content)
        #expect(result.epgURL == URL(string: "http://epg.example.com/guide.xml"))
    }

    @Test func xTvgUrlFallback_whenUrlTvgAbsent() throws {
        let content = "#EXTM3U x-tvg-url=\"http://fallback.example.com/epg.xml\"\n"
        let result = try parser.parse(content)
        #expect(result.epgURL == URL(string: "http://fallback.example.com/epg.xml"))
    }

    @Test func urlTvgTakesPrecedenceOverXTvgUrl() throws {
        let content = "#EXTM3U url-tvg=\"http://primary.example.com/epg.xml\" x-tvg-url=\"http://fallback.example.com/epg.xml\"\n"
        let result = try parser.parse(content)
        #expect(result.epgURL == URL(string: "http://primary.example.com/epg.xml"))
    }

    // MARK: - Channel parsing

    @Test func singleChannel_allAttributes_parsedCorrectly() throws {
        let content = """
        #EXTM3U
        #EXTINF:-1 tvg-id="ch1" tvg-name="Channel 1" tvg-logo="http://logo.example.com/ch1.png" group-title="News",Channel 1
        http://stream.example.com/ch1.m3u8
        """
        let result = try parser.parse(content)
        #expect(result.channels.count == 1)
        let ch = result.channels[0]
        #expect(ch.name == "Channel 1")
        #expect(ch.tvgID == "ch1")
        #expect(ch.logoURL == URL(string: "http://logo.example.com/ch1.png"))
        #expect(ch.groupTitle == "News")
        #expect(ch.streamURL == URL(string: "http://stream.example.com/ch1.m3u8"))
        #expect(ch.isFavorite == false)
    }

    @Test func multipleChannels_allParsed() throws {
        let content = """
        #EXTM3U
        #EXTINF:-1 group-title="Sports",ESPN
        http://stream.example.com/espn.m3u8
        #EXTINF:-1 group-title="News",CNN
        http://stream.example.com/cnn.m3u8
        #EXTINF:-1 group-title="Kids",Cartoon Network
        http://stream.example.com/cn.m3u8
        """
        let result = try parser.parse(content)
        #expect(result.channels.count == 3)
        #expect(result.channels[0].name == "ESPN")
        #expect(result.channels[1].name == "CNN")
        #expect(result.channels[2].name == "Cartoon Network")
    }

    @Test func groupTitleWithComma_splitAtFirstUnquotedComma() throws {
        let content = """
        #EXTM3U
        #EXTINF:-1 group-title="Comedy, Drama",My Channel
        http://stream.example.com/ch.m3u8
        """
        let result = try parser.parse(content)
        #expect(result.channels.count == 1)
        #expect(result.channels[0].groupTitle == "Comedy, Drama")
        #expect(result.channels[0].name == "My Channel")
    }

    // MARK: - #EXTGRP fallback (providers without group-title attribute, e.g. hls.gd)

    @Test func extgrpLine_usedAsGroupTitleWhenAttributeAbsent() throws {
        let content = """
        #EXTM3U
        #EXTINF:0 tvg-id="ch001" tvg-name="Channel One",Channel One
        #EXTGRP:1. Federal/Федеральные
        http://stream.example.com/ch1.m3u8
        """
        let result = try parser.parse(content)
        #expect(result.channels.count == 1)
        #expect(result.channels[0].groupTitle == "1. Federal/Федеральные")
    }

    @Test func groupTitleAttribute_takesPrecedenceOverExtgrp() throws {
        let content = """
        #EXTM3U
        #EXTINF:-1 group-title="Sports",Channel One
        #EXTGRP:Ignored Group
        http://stream.example.com/ch1.m3u8
        """
        let result = try parser.parse(content)
        #expect(result.channels.count == 1)
        #expect(result.channels[0].groupTitle == "Sports")
    }

    @Test func extgrpDoesNotLeakIntoNextChannelWithoutItsOwnGroup() throws {
        let content = """
        #EXTM3U
        #EXTINF:-1,Channel One
        #EXTGRP:News
        http://stream.example.com/ch1.m3u8
        #EXTINF:-1,Channel Two
        http://stream.example.com/ch2.m3u8
        """
        let result = try parser.parse(content)
        #expect(result.channels.count == 2)
        #expect(result.channels[0].groupTitle == "News")
        #expect(result.channels[1].groupTitle == "")
    }

    // MARK: - Malformed input

    @Test func nonHttpStreamURL_skipped() throws {
        let content = """
        #EXTM3U
        #EXTINF:-1,Valid Channel
        http://stream.example.com/valid.m3u8
        #EXTINF:-1,Invalid Channel
        rtsp://stream.example.com/invalid
        """
        let result = try parser.parse(content)
        #expect(result.channels.count == 1)
        #expect(result.channels[0].name == "Valid Channel")
    }

    @Test func missingUrlLine_extinfSkipped() throws {
        let content = """
        #EXTM3U
        #EXTINF:-1,Orphan Channel
        #EXTINF:-1,Real Channel
        http://stream.example.com/real.m3u8
        """
        let result = try parser.parse(content)
        #expect(result.channels.count == 1)
        #expect(result.channels[0].name == "Real Channel")
    }

    @Test func emptyTvgId_storedAsNil() throws {
        let content = """
        #EXTM3U
        #EXTINF:-1 tvg-id="",No EPG Channel
        http://stream.example.com/ch.m3u8
        """
        let result = try parser.parse(content)
        #expect(result.channels.count == 1)
        #expect(result.channels[0].tvgID == nil)
    }
}
