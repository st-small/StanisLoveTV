import AVFoundation
import Observation

@MainActor
@Observable
final class PlayerViewModel {
    let channel: Channel
    let player: AVPlayer

    var observedBitrate: Double?
    var indicatedBitrate: Double?
    var stallCount: Int = 0
    var presentationSize: CGSize = .zero
    var isLikelyToKeepUp = false

    @ObservationIgnored private var statusObserver: NSKeyValueObservation?
    @ObservationIgnored private var keepUpObserver: NSKeyValueObservation?
    @ObservationIgnored private var presentationSizeObserver: NSKeyValueObservation?
    @ObservationIgnored private var accessLogObserver: NSObjectProtocol?

    init(channel: Channel) {
        self.channel = channel
        self.player = AVPlayer(url: channel.streamURL)
    }

    func play() {
        observeStatus()
        if PlayerDebugFlags.showStatsOverlay {
            observePlaybackStats()
        }
        player.play()
    }

    func togglePlayback() {
        player.rate == 0 ? player.play() : player.pause()
    }

    func stop() {
        statusObserver = nil
        keepUpObserver = nil
        presentationSizeObserver = nil
        if let accessLogObserver {
            NotificationCenter.default.removeObserver(accessLogObserver)
        }
        accessLogObserver = nil
        observedBitrate = nil
        indicatedBitrate = nil
        stallCount = 0
        presentationSize = .zero
        isLikelyToKeepUp = false
        player.pause()
    }

    // TEMPORARY DEBUG LOGGING, #if DEBUG-gated — remove once Phase 7 adds real error handling/retry.
    private func observeStatus() {
        #if DEBUG
        let channelName = channel.name
        let streamURL = channel.streamURL
        statusObserver = player.currentItem?.observe(\.status, options: [.new, .initial]) { item, _ in
            switch item.status {
            case .unknown:
                print("[PlayerViewModel] \(channelName) (\(streamURL)): loading…")
            case .readyToPlay:
                print("[PlayerViewModel] \(channelName): ready to play")
            case .failed:
                print("[PlayerViewModel] \(channelName) (\(streamURL)): FAILED — \(String(describing: item.error))")
            @unknown default:
                print("[PlayerViewModel] \(channelName): unexpected status \(item.status)")
            }
        }
        #endif
    }

    // Feeds PlaybackStatsOverlayView — gated behind PlayerDebugFlags.showStatsOverlay.
    private func observePlaybackStats() {
        guard let item = player.currentItem else { return }

        keepUpObserver = item.observe(\.isPlaybackLikelyToKeepUp, options: [.new, .initial]) { [weak self] item, _ in
            let value = item.isPlaybackLikelyToKeepUp
            Task { @MainActor [weak self] in
                self?.isLikelyToKeepUp = value
            }
        }

        presentationSizeObserver = item.observe(\.presentationSize, options: [.new, .initial]) { [weak self] item, _ in
            let value = item.presentationSize
            Task { @MainActor [weak self] in
                self?.presentationSize = value
            }
        }

        accessLogObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemNewAccessLogEntry,
            object: item,
            queue: .main
        ) { [weak self] _ in
            guard let event = item.accessLog()?.events.last else { return }
            let indicated = event.indicatedBitrate
            let observed = event.observedBitrate
            let stalls = event.numberOfStalls
            Task { @MainActor [weak self] in
                self?.indicatedBitrate = indicated
                self?.observedBitrate = observed
                self?.stallCount = stalls
            }
        }
    }
}
