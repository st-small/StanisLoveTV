import SwiftUI

struct PlaylistGateOverlayView: View {
    let onAdd: (URL, String, URL?) async throws -> Void

    var body: some View {
        ZStack {
            Color.ds.background.overlay.ignoresSafeArea()
            AddPlaylistView(onAdd: onAdd, isDismissable: false)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: DSRadius.s))
        }
        .focusSection()
        .onExitCommand { } // Swallow Menu — the gate cannot be dismissed except by adding a playlist.
    }
}
