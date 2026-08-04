import SwiftUI

struct PlaylistsView: View {
    @Bindable var viewModel: PlaylistsViewModel

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.playlists.isEmpty && !viewModel.isLoading {
                    emptyState
                } else {
                    playlistList
                }
            }
            .navigationTitle("Playlists")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Add", systemImage: "plus") {
                        viewModel.showAddSheet = true
                    }
                }
            }
            .overlay {
                if viewModel.isLoading {
                    ProgressView()
                }
            }
        }
        .sheet(isPresented: $viewModel.showAddSheet) {
            AddPlaylistView { url, name, epgURL in
                try await viewModel.add(url: url, name: name, epgURL: epgURL)
            }
        }
        .alert("Error", isPresented: Binding(
            get: { viewModel.error != nil },
            set: { _ in viewModel.error = nil }
        )) {
            Button("OK") {}
        } message: {
            Text(viewModel.error?.errorDescription ?? "An error occurred.")
        }
    }

    private var emptyState: some View {
        VStack(spacing: DSSpacing.l) {
            Image(systemName: "list.bullet.clipboard")
                .font(.system(size: 80))
                .foregroundStyle(.secondary)
            Text("No Playlists")
                .font(.title2)
            Text("Add an M3U playlist to get started.")
                .foregroundStyle(.secondary)
            Button("Add Playlist") { viewModel.showAddSheet = true }
                .buttonStyle(.borderedProminent)
                .padding(.top, DSSpacing.s)
        }
    }

    private var playlistList: some View {
        List {
            ForEach(viewModel.playlists) { playlist in
                PlaylistRowView(
                    playlist: playlist,
                    isActive: playlist.id == viewModel.activePlaylistID,
                    onRefresh: { Task { await viewModel.refresh(id: playlist.id) } },
                    onDelete: { Task { await viewModel.delete(id: playlist.id) } }
                )
            }
        }
    }
}

private struct PlaylistRowView: View {
    let playlist: Playlist
    let isActive: Bool
    let onRefresh: () -> Void
    let onDelete: () -> Void

    @State private var showDeleteConfirmation = false

    var body: some View {
        HStack(spacing: DSSpacing.l) {
            VStack(alignment: .leading, spacing: DSSpacing.xs) {
                HStack(spacing: DSSpacing.xs) {
                    if isActive {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                    }
                    Text(playlist.name)
                        .font(.headline)
                }
                Text(playlist.url.absoluteString)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                if let updated = playlist.lastUpdated {
                    Text("Updated \(updated.formatted(.relative(presentation: .named)))")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }

            Spacer()

            HStack(spacing: DSSpacing.s) {
                Button("Refresh", systemImage: "arrow.clockwise") { onRefresh() }
                    .labelStyle(.iconOnly)
                    .accessibilityLabel("Refresh \(playlist.name)")

                Button("Delete", systemImage: "trash", role: .destructive) {
                    showDeleteConfirmation = true
                }
                .labelStyle(.iconOnly)
                .accessibilityLabel("Delete \(playlist.name)")
            }
        }
        .padding(.vertical, DSSpacing.xs)
        .confirmationDialog("Delete \"\(playlist.name)\"?", isPresented: $showDeleteConfirmation) {
            Button("Delete", role: .destructive) { onDelete() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will remove the playlist and all its channels.")
        }
    }
}
