import AVFoundation
import Testing
import Foundation
@testable import StanisLoveTV

@Suite("PlayerViewModel")
@MainActor
struct PlayerViewModelTests {

    @Test("init sets the channel property")
    func init_setsChannelProperty() {
        let channel = Channel.mock(name: "BBC One")
        let viewModel = PlayerViewModel(channel: channel)
        #expect(viewModel.channel == channel)
    }

    @Test("init creates a player with the channel's stream URL")
    func init_createsPlayerWithChannelStreamURL() {
        let channel = Channel.mock(streamURL: URL(string: "https://example.com/live.m3u8")!)
        let viewModel = PlayerViewModel(channel: channel)
        let currentItemURL = (viewModel.player.currentItem?.asset as? AVURLAsset)?.url
        #expect(currentItemURL == channel.streamURL)
    }
}
