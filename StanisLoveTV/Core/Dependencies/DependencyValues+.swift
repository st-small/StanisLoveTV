import Dependencies

// MARK: - Dependency registrations
// All DependencyKey extensions live here to keep DI in one place.
// Keys will be added phase by phase:
//   Phase 3: database
//   Phase 4: networkService
//   Phase 5: fetchChannelsUseCase, addPlaylistUseCase, refreshPlaylistUseCase
//   Phase 8: fetchEPGUseCase
