import Testing
import Foundation
@testable import StanisLoveTV

@Suite("Domain Entities")
struct EntitiesTests {

    @Test("Channel.mock() produces expected fields")
    func channelMockHasExpectedFields() {
        let id = UUID()
        let channel = Channel.mock(
            id: id,
            name: "Test Channel",
            groupTitle: "Sports"
        )

        #expect(channel.id == id)
        #expect(channel.name == "Test Channel")
        #expect(channel.groupTitle == "Sports")
        #expect(channel.isFavorite == false)
    }

    @Test("Channel.mock() isFavorite defaults to false")
    func channelMockIsFavoriteDefaultsFalse() {
        let channel = Channel.mock()
        #expect(channel.isFavorite == false)
    }

    @Test("Playlist.mock() produces expected fields")
    func playlistMockHasExpectedFields() {
        let id = UUID()
        let playlist = Playlist.mock(id: id, name: "My Playlist")

        #expect(playlist.id == id)
        #expect(playlist.name == "My Playlist")
        #expect(playlist.epgURL == nil)
        #expect(playlist.lastUpdated == nil)
    }

    @Test("EPGProgram.mock() endTime is after startTime")
    func epgProgramMockEndTimeAfterStart() {
        let program = EPGProgram.mock()
        #expect(program.endTime > program.startTime)
    }

    @Test("Category id equals groupTitle")
    func categoryIdEqualsGroupTitle() {
        let category = Category(groupTitle: "Movies", channelCount: 42)
        #expect(category.id == "Movies")
        #expect(category.channelCount == 42)
    }
}
