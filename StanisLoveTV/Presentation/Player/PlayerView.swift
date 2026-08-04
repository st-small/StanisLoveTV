import SwiftUI

struct PlayerView: View {
    @State private var viewModel: PlayerViewModel
    let onDismiss: () -> Void

    init(channel: Channel, onDismiss: @escaping () -> Void) {
        _viewModel = State(wrappedValue: PlayerViewModel(channel: channel))
        self.onDismiss = onDismiss
    }

    var body: some View {
        VideoPlayerView(player: viewModel.player)
            .ignoresSafeArea()
            .overlay(alignment: .topTrailing) {
                if PlayerDebugFlags.showStatsOverlay {
                    PlaybackStatsOverlayView(
                        observedBitrate: viewModel.observedBitrate,
                        indicatedBitrate: viewModel.indicatedBitrate,
                        stallCount: viewModel.stallCount,
                        presentationSize: viewModel.presentationSize,
                        isLikelyToKeepUp: viewModel.isLikelyToKeepUp
                    )
                    .padding(DSSpacing.l)
                }
            }
            .onAppear { viewModel.play() }
            .onDisappear { viewModel.stop() }
            .onExitCommand { onDismiss() }
            .onPlayPauseCommand { viewModel.togglePlayback() }
    }
}
