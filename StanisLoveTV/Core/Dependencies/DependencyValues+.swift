import Dependencies
import Foundation

// MARK: - Repository dependencies

extension DependencyValues {
    var channelRepository: any ChannelRepository {
        get { self[ChannelRepositoryKey.self] }
        set { self[ChannelRepositoryKey.self] = newValue }
    }

    var playlistRepository: any PlaylistRepository {
        get { self[PlaylistRepositoryKey.self] }
        set { self[PlaylistRepositoryKey.self] = newValue }
    }

    var epgRepository: any EPGRepository {
        get { self[EPGRepositoryKey.self] }
        set { self[EPGRepositoryKey.self] = newValue }
    }

    var favoriteRepository: any FavoriteRepository {
        get { self[FavoriteRepositoryKey.self] }
        set { self[FavoriteRepositoryKey.self] = newValue }
    }
}

private struct UnimplementedChannelRepository: ChannelRepository {
    func fetchAll(playlistID: UUID) async throws -> [Channel] { unimplemented("channelRepository.fetchAll — wire in Phase 3", placeholder: []) }
    func fetchFavorites() async throws -> [Channel] { unimplemented("channelRepository.fetchFavorites — wire in Phase 3", placeholder: []) }
    func save(_ channels: [Channel], playlistID: UUID) async throws { unimplemented("channelRepository.save — wire in Phase 3") }
    func search(query: String) async throws -> [Channel] { unimplemented("channelRepository.search — wire in Phase 3", placeholder: []) }
}

private struct UnimplementedPlaylistRepository: PlaylistRepository {
    func fetchAll() async throws -> [Playlist] { unimplemented("playlistRepository.fetchAll — wire in Phase 3", placeholder: []) }
    func insert(_ playlist: Playlist) async throws { unimplemented("playlistRepository.insert — wire in Phase 3") }
    func delete(id: UUID) async throws { unimplemented("playlistRepository.delete — wire in Phase 3") }
    func updateLastFetched(id: UUID, date: Date) async throws { unimplemented("playlistRepository.updateLastFetched — wire in Phase 3") }
    func updateEPGURL(id: UUID, url: URL?) async throws { unimplemented("playlistRepository.updateEPGURL — wire in Phase 3") }
}

private struct UnimplementedEPGRepository: EPGRepository {
    func fetchPrograms(channelID: String, after: Date) async throws -> [EPGProgram] { unimplemented("epgRepository.fetchPrograms — wire in Phase 3", placeholder: []) }
    func replaceAll(channelID: String, programs: [EPGProgram]) async throws { unimplemented("epgRepository.replaceAll — wire in Phase 3") }
    func pruneStale(olderThan: Date) async throws { unimplemented("epgRepository.pruneStale — wire in Phase 3") }
}

private struct UnimplementedFavoriteRepository: FavoriteRepository {
    func fetchAll() async throws -> [UUID] { unimplemented("favoriteRepository.fetchAll — wire in Phase 3", placeholder: []) }
    func toggle(channelID: UUID) async throws -> Bool { unimplemented("favoriteRepository.toggle — wire in Phase 3", placeholder: false) }
}

private enum ChannelRepositoryKey: DependencyKey {
    static var liveValue: any ChannelRepository { DefaultChannelRepository() }
}

private enum PlaylistRepositoryKey: DependencyKey {
    static var liveValue: any PlaylistRepository { DefaultPlaylistRepository() }
}

private enum EPGRepositoryKey: DependencyKey {
    static var liveValue: any EPGRepository { DefaultEPGRepository() }
}

private enum FavoriteRepositoryKey: DependencyKey {
    static var liveValue: any FavoriteRepository { DefaultFavoriteRepository() }
}

// MARK: - Use case dependencies

extension DependencyValues {
    var fetchChannelsUseCase: FetchChannelsUseCase {
        get { self[FetchChannelsUseCase.self] }
        set { self[FetchChannelsUseCase.self] = newValue }
    }

    var fetchPlaylistsUseCase: FetchPlaylistsUseCase {
        get { self[FetchPlaylistsUseCase.self] }
        set { self[FetchPlaylistsUseCase.self] = newValue }
    }

    var addPlaylistUseCase: AddPlaylistUseCase {
        get { self[AddPlaylistUseCase.self] }
        set { self[AddPlaylistUseCase.self] = newValue }
    }

    var deletePlaylistUseCase: DeletePlaylistUseCase {
        get { self[DeletePlaylistUseCase.self] }
        set { self[DeletePlaylistUseCase.self] = newValue }
    }

    var refreshPlaylistUseCase: RefreshPlaylistUseCase {
        get { self[RefreshPlaylistUseCase.self] }
        set { self[RefreshPlaylistUseCase.self] = newValue }
    }

    var fetchEPGUseCase: FetchEPGUseCase {
        get { self[FetchEPGUseCase.self] }
        set { self[FetchEPGUseCase.self] = newValue }
    }

    var toggleFavoriteUseCase: ToggleFavoriteUseCase {
        get { self[ToggleFavoriteUseCase.self] }
        set { self[ToggleFavoriteUseCase.self] = newValue }
    }

    var searchChannelsUseCase: SearchChannelsUseCase {
        get { self[SearchChannelsUseCase.self] }
        set { self[SearchChannelsUseCase.self] = newValue }
    }
}

// MARK: - Phase 4: networkService
