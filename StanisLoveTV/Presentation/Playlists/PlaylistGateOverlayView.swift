import SwiftUI

struct PlaylistGateOverlayView: View {
    let onAdd: (URL, String, URL?) async throws -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(Opacity.gateScrim).ignoresSafeArea()
            AddPlaylistView(onAdd: onAdd, isDismissable: false)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: TVSize.thumbnailCornerRadius))
        }
        .focusSection()
        .onExitCommand { } // Swallow Menu — the gate cannot be dismissed except by adding a playlist.
    }
}
