# Plan: Разделение персистентности — UserDefaults (плейлисты/избранное) vs SQLite (кэш каналов/EPG)

**Created**: 2026-07-30
**Status**: pending
**Estimated complexity**: L

## Goal

На tvOS система может в любой момент вычистить `Library/Caches` под давлением памяти/диска, а `DatabaseStack.live()` (`StanisLoveTV/Data/Persistence/DatabaseStack.swift:13`) сегодня кладёт единственный `stanislove.sqlite` именно туда — вместе с таблицами `playlists` и `favorites`, которые содержат **не регенерируемые** данные, введённые пользователем (URL/имя плейлиста, вручную заданный EPG URL, набор избранных каналов). Если ОС вычистит `Caches`, пользователь безвозвратно теряет свои плейлисты и избранное, хотя `channels`/`epgPrograms` в той же базе — это чистый производный кэш, который можно перекачать и перепарсить заново по URL плейлиста.

Цель фазы: перенести `playlists` и избранное в `UserDefaults` (гарантированно персистентен, лимит ~500KB, наши данные на 2-3 порядка меньше), оставить `channels`/`epgPrograms` в SQLite в `Caches` как есть, и добавить rehydration-логику на холодном старте, которая при пустой БД (после установки/восстановления из бэкапа или после вычистки `Caches`) переиспользует уже существующий `RefreshPlaylistUseCase` для каждого сохранённого в `UserDefaults` плейлиста.

Попутно план фиксирует и чинит скрытый баг, обнаруженный при разборе кода: `Channel.id` — это `UUID()`, генерируемый заново при **каждом** парсинге M3U (`M3UParser.swift:75`), а `DefaultChannelRepository.save()` удаляет и заново вставляет все каналы плейлиста при каждом refresh. Сегодняшняя `FavoriteRecord` (и её домен-протокол `FavoriteRepository`) хранит избранное по `Channel.id` — то есть уже сейчас каждый refresh плейлиста молча отвязывает всё избранное от каналов (просто это не заметно, поскольку экран избранного/Phase 9 ещё не реализован). План меняет ключ избранного на `Channel.tvgID` (со стабильным fallback на `streamURL`), что и разрешает эту проблему, и делает избранное переносимым в `UserDefaults`, где такой join через SQL уже невозможен.

Также план приводит в соответствие `.claude/rules/persistence.md` реальному коду: файл сегодня утверждает `applicationSupportDirectory`, хотя код уже использует `cachesDirectory` — это не будет меняться (код уже верный, это фактическая, устоявшаяся директория), но правило будет переписано, чтобы не вводить в заблуждение при следующей загрузке контекста.

**Проверено перед планированием**: по `.claude/plans/master-plan.md` проект ещё не публиковался ни в TestFlight, ни в App Store (Phase 6.5 явно помечена как пройденная только вручную в Simulator; Risk Register прямо предупреждает "не отправлять Phase 6.5 плеер в TestFlight/production"). Значит миграция базы данных может быть **разрушающей** (`DROP TABLE`) без необходимости писать data-preserving миграцию для уже установленных пользователей — таких пока не существует.

## Affected Layers

- [x] Domain (protocols `FavoriteRepository`/`ChannelRepository`, use cases `ToggleFavoriteUseCase`/`DeletePlaylistUseCase`, новый `RehydrateCacheUseCase`, `Channel.favoriteKey`)
- [x] Data (SQLite миграция v3, удаление `PlaylistRecord`/`FavoriteRecord`, новые UserDefaults-репозитории, правка `DefaultChannelRepository`)
- [x] Presentation (`AppState`, `RootView`/`MainTabView`, `PlaylistsViewModel`, опционально `ChannelListView`)
- [x] Core (`DependencyValues+.swift`, новый `UserDefaultsClient`, `PersistenceKeys`)
- [x] Tests
- [x] Документация (`.claude/rules/persistence.md`, сверка с `master-plan.md`)

## Files to Create

| Путь | Назначение |
|------|-----------|
| `StanisLoveTV/Core/Constants/PersistenceKeys.swift` | Константы ключей `UserDefaults` (`storedPlaylistsV1`, `favoriteChannelKeysV1`) — без магических строк |
| `StanisLoveTV/Data/Persistence/UserDefaults/UserDefaultsClient.swift` | `DependencyKey`-обёртка над `UserDefaults` (get/set `Data`, get/set `[String]`) для тестируемости |
| `StanisLoveTV/Data/Persistence/UserDefaults/PlaylistDefaultsRecord.swift` | `Codable` DTO плейлиста для хранения в `UserDefaults` + `domainModel`/reverse-mapping (по аналогии с конвенцией `@Table` → `domainModel`) |
| `StanisLoveTV/Domain/UseCases/RehydrateCacheUseCase.swift` | На холодном старте: для каждого плейлиста из `UserDefaults`, если в SQLite 0 каналов — вызвать `RefreshPlaylistUseCase.execute(id:)` |
| `StanisLoveTVTests/DataTests/DefaultPlaylistRepositoryTests.swift` | Round-trip тесты UserDefaults-репозитория плейлистов |
| `StanisLoveTVTests/DataTests/DefaultFavoriteRepositoryTests.swift` | Round-trip + конкурентность тестов избранного |
| `StanisLoveTVTests/DataTests/MigrationV3Tests.swift` | Проверка миграции v3 (таблицы удалены, `channels`/`epgPrograms` не пострадали) |
| `StanisLoveTVTests/DomainTests/RehydrateCacheUseCaseTests.swift` | Логика rehydration |
| `StanisLoveTVTests/DomainTests/DeletePlaylistUseCaseTests.swift` | Файл тестов use case ещё не существовал — теперь need cascade-delete проверить руками |
| `StanisLoveTVTests/DomainTests/ToggleFavoriteUseCaseTests.swift` | Новая сигнатура `execute(Channel)` |

## Files to Modify

| Путь | Изменение |
|------|-----------|
| `StanisLoveTV/Domain/Entities/Channel.swift` | Добавить `var favoriteKey: String { tvgID ?? streamURL.absoluteString }` |
| `StanisLoveTV/Domain/Repositories/ChannelRepository.swift` | Добавить `func deleteAll(playlistID: UUID) async throws` (нужно, т.к. FK-каскад из SQLite уйдёт вместе с таблицей `playlists`) |
| `StanisLoveTV/Domain/Repositories/FavoriteRepository.swift` | Сигнатура `fetchAll() -> Set<String>`, `toggle(favoriteKey: String) -> Bool` вместо `UUID` |
| `StanisLoveTV/Domain/UseCases/ToggleFavoriteUseCase.swift` | `execute: (Channel) async throws -> Bool`, вызывает `repo.toggle(favoriteKey: channel.favoriteKey)` |
| `StanisLoveTV/Domain/UseCases/DeletePlaylistUseCase.swift` | После `playlistRepository.delete(id:)` явно вызывать `channelRepository.deleteAll(playlistID:)` — раньше это делал FK `ON DELETE CASCADE`, теперь каскада нет |
| `StanisLoveTV/Data/Repositories/DefaultChannelRepository.swift` | Убрать SQL `leftJoin` с `FavoriteRecord`; резолвить `isFavorite` через `@Dependency(\.favoriteRepository)` и `channel.favoriteKey` в памяти; добавить `deleteAll(playlistID:)`; вынести общий helper резолва избранного, использовать его и в `search(query:playlistID:)` (сейчас там `isFavorite` вообще не резолвится — заодно чиним) |
| `StanisLoveTV/Data/Repositories/DefaultPlaylistRepository.swift` | Полная замена реализации: `actor`, backed by `UserDefaultsClient` + `PlaylistDefaultsRecord` вместо `SQLiteData` |
| `StanisLoveTV/Data/Repositories/DefaultFavoriteRepository.swift` | Полная замена реализации: `actor`, backed by `UserDefaultsClient` + `Set<String>` вместо `SQLiteData` |
| `StanisLoveTV/Data/Persistence/Migrations/Migrations.swift` | Добавить `v3_move_playlists_favorites_to_userdefaults`: пересоздать `channels` без FK на `playlists`, `DROP TABLE favorites`, `DROP TABLE playlists` |
| `StanisLoveTV/Core/Dependencies/DependencyValues+.swift` | Зарегистрировать `userDefaultsClient`, `rehydrateCacheUseCase`; обновить `UnimplementedFavoriteRepository`/`UnimplementedChannelRepository`/`UnimplementedPlaylistRepository` под новые сигнатуры |
| `StanisLoveTV/App/AppState.swift` | Добавить transient `var isRehydratingCache: Bool = false` (без `didSet`/UserDefaults — это чисто UI-сигнал на время жизни процесса) |
| `StanisLoveTV/App/RootView.swift` | В `MainTabView`: вызвать `playlistsViewModel.rehydrateCacheIfNeeded()` после `load()`; перезапускать `channelListViewModel.load()`, когда `isRehydratingCache` переходит `true → false` |
| `StanisLoveTV/Presentation/Playlists/PlaylistsViewModel.swift` | Добавить `@ObservationIgnored @Dependency(\.rehydrateCacheUseCase)` и метод `rehydrateCacheIfNeeded()` |
| `StanisLoveTV/Presentation/Channels/ChannelListView.swift` | (опционально, см. DoD) состояние "Restoring your channels…", когда `channels.isEmpty && isRehydratingCache` |
| `.claude/rules/persistence.md` | Переписать: убрать `applicationSupportDirectory`, убрать `playlists`/`favorites` из таблиц SQLite, задокументировать UserDefaults-хранилище, обновить DDL/миграции, обновить пример репозитория |
| `.claude/plans/master-plan.md` | Точечно обновить "Cross-Cutting Concerns → Schema Versions" и "→ UserDefaults Keys" таблицы (добавить v3, `storedPlaylistsV1`, `favoriteChannelKeysV1`), т.к. этими таблицами будут руководствоваться будущие Phase 8/9/10 |

## Files to Delete

- `StanisLoveTV/Data/Persistence/Tables/PlaylistRecord.swift`
- `StanisLoveTV/Data/Persistence/Tables/FavoriteRecord.swift`

## Implementation Steps

Каждый шаг — самостоятельно компилируемое изменение (кроме отмеченных как "атомарная группа", где Swift требует менять протокол и всех его конформеров одновременно).

1. **`Core/Constants/PersistenceKeys.swift`** — новый файл с enum строковых констант ключей `UserDefaults`. Чистое добавление.
2. **`Data/Persistence/UserDefaults/UserDefaultsClient.swift`** — новый `DependencyKey`: closures `data(forKey:) -> Data?`, `setData(_:forKey:)`, `stringArray(forKey:) -> [String]?`, `setStringArray(_:forKey:)`. `liveValue` — обёртка над `UserDefaults.standard`; `testValue` — `unimplemented(...)` на каждом closure (следуя `testing.md`). Зарегистрировать в `DependencyValues+.swift`. Чистое добавление, компилируется независимо.
3. **`Channel.favoriteKey`** — добавить computed property в `Domain/Entities/Channel.swift`. Чистое добавление.
4. **Атомарная группа A — `ChannelRepository.deleteAll`**:
   - `Domain/Repositories/ChannelRepository.swift`: добавить `func deleteAll(playlistID: UUID) async throws`.
   - `Data/Repositories/DefaultChannelRepository.swift`: реализовать (`ChannelRecord.where{ $0.playlistID.eq(playlistID) }.delete()`).
   - `Core/Dependencies/DependencyValues+.swift`: добавить метод в `UnimplementedChannelRepository`.
   Три файла меняются одним коммитом — иначе проект не собирается.
5. **Атомарная группа B — `FavoriteRepository` → String-ключ**:
   - `Domain/Repositories/FavoriteRepository.swift`: `fetchAll() async throws -> Set<String>`, `toggle(favoriteKey: String) async throws -> Bool`.
   - `Data/Repositories/DefaultFavoriteRepository.swift`: переписать как `actor DefaultFavoriteRepository`, backed by `UserDefaultsClient` (см. "SQLiteData Schema Changes" ниже — там же обоснование `actor`). Хранит `Set<String>` под ключом `PersistenceKeys.favoriteChannelKeysV1` через `stringArray`/`setStringArray`.
   - `Domain/UseCases/ToggleFavoriteUseCase.swift`: `execute: (Channel) async throws -> Bool`, вызывает `repo.toggle(favoriteKey: channel.favoriteKey)`.
   - `Core/Dependencies/DependencyValues+.swift`: обновить `UnimplementedFavoriteRepository`.
   - Удалить `Data/Persistence/Tables/FavoriteRecord.swift` (больше не используется).
   Пять правок одним коммитом — протокол, единственный конформер, единственный вызывающий use case, DI-заглушка и удаление таблицы должны обновиться синхронно.
6. **`DefaultChannelRepository`: резолв `isFavorite` без SQL join** — заменить `leftJoin(FavoriteRecord...)` в `fetchAll(playlistID:)` на: один вызов `favoriteRepository.fetchAll()` → `Set<String>`, затем `channel.isFavorite = favoriteKeys.contains(channel.favoriteKey)` в памяти. Аналогично переписать `fetchFavorites()` (полный скан `ChannelRecord`, фильтр по `favoriteKey`) и добавить резолв в `search(query:playlistID:)` (сегодня там `isFavorite` не резолвится вовсе — побочная починка). Вынести общий приватный helper `private func resolveFavorites(_ channels: [Channel]) async throws -> [Channel]`, чтобы не дублировать в трёх методах. Один файл, один коммит — компилируется сразу после шага 5.
7. **`Data/Persistence/UserDefaults/PlaylistDefaultsRecord.swift`** — новый `Codable` DTO: `id: UUID`, `name: String`, `urlString: String`, `typeRaw: String`, `epgURLString: String?`, `lastFetchedTimestamp: Date?` + `domainModel: Playlist` + `static func from(_ playlist: Playlist) -> PlaylistDefaultsRecord`. Чистое добавление.
8. **`DefaultPlaylistRepository` — переписать на UserDefaults** — тот же файл `Data/Repositories/DefaultPlaylistRepository.swift`, протокол `PlaylistRepository` **не меняется** (он уже storage-agnostic), поэтому это самостоятельный шаг: `actor DefaultPlaylistRepository`, читает/декодирует `[PlaylistDefaultsRecord]` из `UserDefaultsClient.data(forKey: PersistenceKeys.storedPlaylistsV1)`, мутирует массив в памяти внутри actor-изолированного метода, кодирует обратно. Удалить `Data/Persistence/Tables/PlaylistRecord.swift`. Компилируется сразу — сигнатура протокола не менялась, только тело.
9. **HIGH RISK — SQLite миграция v3** — `Data/Persistence/Migrations/Migrations.swift`: зарегистрировать `"v3_move_playlists_favorites_to_userdefaults"` (DDL — см. раздел ниже). Не зависит компиляционно от шагов 5/8, но логически должна попасть в тот же релиз — иначе в БД будут висеть мёртвые таблицы `playlists`/`favorites`, которые больше никто не пишет и не читает.
10. **`DeletePlaylistUseCase`** — добавить вызов `channelRepository.deleteAll(playlistID: id)` после `playlistRepository.delete(id: id)`. Обязательно **после** шага 4 (нужен `deleteAll`) и **после** шага 9 (без миграции ещё есть FK-каскад, но он всё равно скоро исчезнет — использовать `deleteAll` можно и раньше, каскад просто станет избыточным-безвредным до миграции).
11. **`RehydrateCacheUseCase`** — новый файл, Domain layer:
    ```swift
    struct RehydrateCacheUseCase {
        var execute: () async throws -> Void
    }
    extension RehydrateCacheUseCase: DependencyKey {
        static var liveValue: Self {
            .init {
                @Dependency(\.playlistRepository) var playlistRepo
                @Dependency(\.channelRepository) var channelRepo
                @Dependency(\.refreshPlaylistUseCase) var refreshPlaylist

                let playlists = try await playlistRepo.fetchAll()
                for playlist in playlists {
                    let existing = try await channelRepo.fetchAll(playlistID: playlist.id)
                    guard existing.isEmpty else { continue }
                    // Best-effort: один сбойный плейлист (например, недоступен офлайн)
                    // не должен блокировать rehydration остальных.
                    try? await refreshPlaylist.execute(playlist.id)
                }
            }
        }
        static let testValue = RehydrateCacheUseCase(
            execute: { unimplemented("RehydrateCacheUseCase.execute") }
        )
    }
    ```
    Переиспользует уже существующий `RefreshPlaylistUseCase` (`Domain/UseCases/RefreshPlaylistUseCase.swift`) — он уже делает ровно download+parse+`channelRepository.save`+`updateLastFetched`, ничего нового изобретать не нужно. Зарегистрировать `rehydrateCacheUseCase` в `DependencyValues+.swift`.
12. **`AppState.isRehydratingCache`** — добавить transient `var isRehydratingCache: Bool = false` без персистентности (в отличие от `activePlaylistID` это не должно переживать перезапуск — если процесс убит посреди rehydration, следующий холодный старт просто начнёт заново).
13. **`PlaylistsViewModel.rehydrateCacheIfNeeded()`**:
    ```swift
    @ObservationIgnored @Dependency(\.rehydrateCacheUseCase) private var rehydrateCache

    func rehydrateCacheIfNeeded() async {
        appState.isRehydratingCache = true
        defer { appState.isRehydratingCache = false }
        do {
            try await rehydrateCache.execute()
        } catch {
            self.error = AppError(error)
        }
    }
    ```
14. **`RootView.swift` / `MainTabView`** — последовательно: `.task { await playlistsViewModel.load(); await playlistsViewModel.rehydrateCacheIfNeeded() }` (await внутри одного `.task` гарантирует порядок — сначала список плейлистов, потом rehydration). Добавить `.onChange(of: appState.isRehydratingCache) { old, new in if old, !new { Task { await channelListViewModel.load() } } }`, чтобы вкладка Channels перезагрузилась после того, как rehydration докачает каналы для активного плейлиста — по аналогии с уже задокументированным в `master-plan.md` (Decision #6) паттерном "`@Observable` не перезапускает уже завершённый `.task`, нужен явный триггер".
15. **(опционально, см. Definition of Done) `ChannelListView.swift`** — добавить ветку состояния "Restoring your channels…" при `viewModel.channels.isEmpty && appState.isRehydratingCache`, отличную от "No Playlists" / "No Channels".
16. **`.claude/rules/persistence.md`** — переписать целиком под новую архитектуру (см. ниже, отдельный черновик).
17. **`.claude/plans/master-plan.md`** — точечно обновить таблицы "Schema Versions" и "UserDefaults Keys" в разделе "Cross-Cutting Concerns".

## SQLiteData Schema Changes

**Новая миграция**: `v3_move_playlists_favorites_to_userdefaults`
**Риск**: HIGH — реструктуризация схемы, удаление таблиц, на которые ссылается FK.

SQLite не поддерживает `ALTER TABLE ... DROP CONSTRAINT`, поэтому FK `channels.playlistID REFERENCES playlists(id) ON DELETE CASCADE` убирается через пересоздание таблицы (12-step procedure):

```sql
-- 1. Пересоздать channels без FK на playlists (playlistID остаётся простым TEXT-полем,
--    целостность теперь на уровне приложения — см. DeletePlaylistUseCase.deleteAll)
CREATE TABLE "channels_new" (
    "id"         TEXT PRIMARY KEY NOT NULL DEFAULT (uuid()),
    "playlistID" TEXT NOT NULL,
    "name"       TEXT NOT NULL DEFAULT '',
    "streamURL"  TEXT NOT NULL,
    "logoURL"    TEXT,
    "groupTitle" TEXT NOT NULL DEFAULT '',
    "tvgID"      TEXT,
    "position"   INTEGER NOT NULL DEFAULT 0
) STRICT;

INSERT INTO "channels_new" SELECT * FROM "channels";
DROP TABLE "channels";
ALTER TABLE "channels_new" RENAME TO "channels";

CREATE INDEX "idx_channels_playlistID" ON "channels" ("playlistID");
-- Новый индекс: DefaultChannelRepository теперь резолвит isFavorite/fetchFavorites
-- в памяти по tvgID, полезно для будущих SQL-фильтров по tvgID (Phase 8 EPG join).
CREATE INDEX "idx_channels_tvgID" ON "channels" ("tvgID");

-- 2. Удалить таблицы, переехавшие в UserDefaults
DROP TABLE "favorites";
DROP TABLE "playlists";
```

**Важно проверить при реализации**: `DatabaseStack.live()` создаёт `DatabaseQueue` с `config.foreignKeysEnabled = true`. Нужно на практике убедиться (тест `MigrationV3Tests`, реальный прогон на симуляторе с непустой БД, накопленной за Phase 6.5), что `DROP TABLE "playlists"` не падает из-за всё ещё существующего FK в `channels` **на момент выполнения DROP** — по этой причине шаг 1 (пересоздание `channels` без FK) должен физически идти **до** `DROP TABLE "playlists"` в той же миграции, что и заложено выше. Если GRDB's `DatabaseMigrator` всё равно ругается — использовать `migrator.registerMigration(_:foreignKeyChecks:migrate:)` c отложенной проверкой FK для этой конкретной миграции (уточнить точный API у установленной версии `sqlite-data`/GRDB на этапе реализации).

**Никогда не редактировать** `v1_initial` / `v2_playlist_epg_url` — только новая версия.

## Dependency Registration

Новые ключи в `Core/Dependencies/DependencyValues+.swift`:

| Key | Type | Provided by |
|-----|------|------------|
| `userDefaultsClient` | `UserDefaultsClient` | `UserDefaultsClient.swift` |
| `rehydrateCacheUseCase` | `RehydrateCacheUseCase` | inline `liveValue` в `RehydrateCacheUseCase.swift` |

Существующие ключи без изменения типа, но с изменённой реализацией/сигнатурой методов протокола:

| Key | Что меняется |
|-----|-------------|
| `playlistRepository` | `liveValue` теперь `DefaultPlaylistRepository` (actor, UserDefaults) вместо SQLite; сам тип протокола `any PlaylistRepository` не меняется |
| `favoriteRepository` | протокол `FavoriteRepository` меняет сигнатуры методов (`UUID` → `String`); `liveValue` — actor, UserDefaults |
| `channelRepository` | добавлен метод `deleteAll(playlistID:)` в протокол |
| `toggleFavoriteUseCase` | `ToggleFavoriteUseCase.execute` меняет параметр `UUID` → `Channel` |

## Tests to Write

`Tests/DataTests/DefaultPlaylistRepositoryTests.swift`:
```
@Test func insertsAndFetchesPlaylist()
@Test func deletePersistsRemoval()
@Test func updateLastFetched_persists()
@Test func updateEPGURL_persists()
@Test func survivesReencodeRoundTrip_allFieldsPreserved()
@Test func corruptedStoredJSON_returnsEmptyArray_notCrash()
```

`Tests/DataTests/DefaultFavoriteRepositoryTests.swift`:
```
@Test func toggle_unfavorited_addsKey()
@Test func toggle_favorited_removesKey()
@Test func fetchAll_returnsStoredKeys()
@Test func concurrentToggles_serializedCorrectly()  // N параллельных toggle на разные ключи через withThrowingTaskGroup — проверяет, что actor-изоляция не теряет записи при read-modify-write в UserDefaults
```

`Tests/DataTests/DefaultChannelRepositoryTests.swift` (расширить существующий/создать при отсутствии):
```
@Test func fetchAll_resolvesIsFavoriteViaTvgID()
@Test func fetchAll_resolvesIsFavoriteViaStreamURLFallbackWhenTvgIDNil()
@Test func deleteAll_removesChannelsForPlaylist_leavesOthersUntouched()
@Test func fetchFavorites_mergesAcrossPlaylists()
@Test func search_resolvesIsFavorite()  // ранее не резолвилось вовсе — регрессионный тест на побочную починку
```

`Tests/DataTests/MigrationV3Tests.swift`:
```
@Test func migrationV3_dropsPlaylistsAndFavoritesTables()
@Test func migrationV3_preservesExistingChannelsAndEPGRows()
@Test func migrationV3_channelsInsertSucceedsWithoutParentPlaylistsRow()  // подтверждает, что FK реально снят
```

`Tests/DomainTests/RehydrateCacheUseCaseTests.swift`:
```
@Test func rehydrate_refreshesPlaylistsWithZeroChannels()
@Test func rehydrate_skipsPlaylistsThatAlreadyHaveChannels()
@Test func rehydrate_continuesAfterOnePlaylistFailure()  // best-effort — одна упавшая сеть не блокирует остальные
@Test func rehydrate_noPlaylistsStored_isNoOp()
```

`Tests/DomainTests/DeletePlaylistUseCaseTests.swift`:
```
@Test func delete_removesPlaylistFromRepository()
@Test func delete_alsoDeletesItsChannels()  // критично: без FK-каскада это теперь единственная точка защиты от осиротевших channels
```

`Tests/DomainTests/ToggleFavoriteUseCaseTests.swift`:
```
@Test func toggle_usesChannelTvgIDAsFavoriteKey()
@Test func toggle_fallsBackToStreamURLWhenTvgIDIsNil()
```

`Tests/PresentationTests/PlaylistsViewModelTests.swift` (дополнить существующий):
```
@Test func rehydrateCacheIfNeeded_togglesIsRehydratingCacheDuringRun()
@Test func rehydrateCacheIfNeeded_noOpWhenAllPlaylistsAlreadyHaveChannels()
```

Примечание: файл `StanisLoveTVTests/DomainTests/AddPlaylistUseCaseTests.swift` сегодня целиком закомментирован (`/* ... */`, строки 32–183) — вне скоупа этого плана, но стоит поднять вопрос отдельно (см. Open Questions), поскольку он покрывает соседний код (`AddPlaylistUseCase`, `RefreshPlaylistUseCase`), который этот план активно переиспользует в `RehydrateCacheUseCase`.

## tvOS Considerations

- Rehydration выполняется в `RehydrateCacheUseCase.liveValue`, чьё тело не помечено `@MainActor` — сетевые вызовы и парсинг M3U по-прежнему идут в фоне, несмотря на то что `PlaylistsViewModel` (вызывающий) сам `@MainActor`; это тот же паттерн, что уже используется в `AddPlaylistUseCase`/`RefreshPlaylistUseCase` — регрессии нет.
- Состояние "Restoring your channels…" (шаг 15) должно быть неинтерактивным `ProgressView`+текст без фокусируемых элементов, но с `accessibilityLabel` для VoiceOver ("Restoring your channels from your saved playlist").
- Экран Channels не должен залипать в "No Playlists" во время rehydration, если плейлисты уже есть в `UserDefaults`, но каналов в SQLite ещё нет — это отдельное третье состояние, отличное от "No Playlists" (плейлистов действительно нет) и "No Channels" (плейлист есть, каналов нет и это не rehydration, а реальная пустота/ошибка сети). `ChannelListViewModel.hasActivePlaylists` уже читает `appState.activePlaylistID`, который для этого случая **не nil** (сохранён в `UserDefaults` отдельно от списка плейлистов) — значит различение "No Channels" vs "Restoring" полностью определяется `appState.isRehydratingCache`, дополнительной вьюмодель-логики не требуется.
- `.onChange(of: appState.isRehydratingCache)` в `MainTabView` — не забыть про `.onExitCommand`/фокус: пока идёт rehydration, пользователь может свободно уйти на вкладку Playlists/Settings, это не блокирующий модальный экран.
- Актор-базированные `DefaultPlaylistRepository`/`DefaultFavoriteRepository` — вызовы из `@MainActor`-вьюмоделей автоматически становятся `await`-suspend точками (переход через границу актора), уже согласуется с существующим паттерном `async throws` в протоколах.

## Open Questions

1. **Подтвердить отсутствие продакшен-пользователей.** План исходит из того, что разрушающая миграция (`DROP TABLE playlists/favorites`) безопасна, потому что в TestFlight/App Store ничего не публиковалось (см. "Goal" — вывод сделан из `master-plan.md`). Если это не так — нужен отдельный data-preserving шаг миграции (прочитать старые строки `playlists`/`favorites` в последний раз перед `DROP TABLE` и переложить их в `UserDefaults` через `UserDefaultsClient` прямо в теле миграции v3, до её выполнения).
2. **Надёжность `favoriteKey`-fallback на `streamURL`.** Если у канала нет `tvg-id` и провайдер меняет `streamURL` между обновлениями плейлиста (токенизированные URL) — избранное для такого канала может незаметно потеряться после refresh. Это принятый компромисс (лучше, чем текущее поведение — терять вообще всё избранное при каждом refresh), но стоит явно решить, устраивает ли это продукт, или нужен более устойчивый идентификатор (например, комбинация `name+groupTitle` как третий fallback).
3. **Взаимодействие с будущим Phase 8 (EPG Guide, ещё не реализован).** По дизайну из `master-plan.md`, `FetchEPGUseCase.loadIfNeeded()` должен сверяться с TTL из `UserDefaults["epgLastFetchedAt"]` (переживает вычистку `Caches`), а не с наличием строк в `epgPrograms` (не переживает). Если `Caches` вычищена, а TTL ещё не истёк (< 24ч с последнего фетча), Guide молча покажет пустой таймлайн вместо повторного фетча. Эта проблема **не решается в рамках текущего плана** (Phase 8 ещё не написан в коде), но должна быть заложена в дизайн `EPGViewModel.loadIfNeeded()`, когда Phase 8 будет реализовываться: проверка должна быть "TTL истёк ИЛИ таблица `epgPrograms` для канала пуста", а не только TTL.
4. **`AddPlaylistUseCaseTests.swift` закомментирован целиком.** Не в скоупе этого плана, но `RehydrateCacheUseCase` полагается на тот же `RefreshPlaylistUseCase`, который эти тесты частично покрывают — стоит решить отдельно, раскомментировать ли и почему они были отключены, до или после этой фазы.
5. **Расширять ли `AppError.databaseError` или завести отдельный `.persistenceError`** для ошибок декодирования JSON из `UserDefaults` (повреждённые данные) — план сейчас предполагает переиспользование `.databaseError(String)` (тесты `corruptedStoredJSON_returnsEmptyArray_notCrash` подразумевают, что репозиторий сам восстанавливается без throw, но стоит явно решить поведение при частичном повреждении, а не пустом значении).

## Definition of Done

- `playlists` и избранное читаются/пишутся исключительно через `UserDefaultsClient`; `Data/Persistence/Tables/PlaylistRecord.swift` и `FavoriteRecord.swift` удалены из проекта.
- Миграция `v3_move_playlists_favorites_to_userdefaults` применена; таблицы `playlists`/`favorites` отсутствуют в SQLite; `channels`/`epgPrograms` не пострадали (проверено `MigrationV3Tests`).
- `channels.playlistID` больше не имеет FK на `playlists`; `DeletePlaylistUseCase` явно удаляет каналы плейлиста через `channelRepository.deleteAll(playlistID:)`.
- `FavoriteRepository`/`ToggleFavoriteUseCase` работают по `Channel.tvgID` (с fallback на `streamURL`), а не по `Channel.id` — избранное переживает `RefreshPlaylistUseCase`.
- На холодном старте, если в `UserDefaults` есть сохранённые плейлисты, а в SQLite для них 0 каналов, `RehydrateCacheUseCase` в фоне докачивает и парсит их через уже существующий `RefreshPlaylistUseCase`, без блокировки UI.
- Вкладка Channels корректно отражает переход "Restoring…" → заполненный список без перезапуска приложения (вручную проверено на симуляторе: очистить `Caches` приложения через `xcrun simctl`, перезапустить, убедиться, что плейлисты видны сразу, а каналы дозагружаются).
- `.claude/rules/persistence.md` и таблицы в `.claude/plans/master-plan.md` (Schema Versions, UserDefaults Keys) синхронизированы с фактической реализацией.
- Все тесты из раздела "Tests to Write" написаны и зелёные; coverage на новых use cases/репозиториях соответствует таргетам из `.claude/rules/testing.md` (90%+ use cases, integration-тесты на репозитории).
- Ноль регрессий в существующих тестах Phase 5/6 (`ChannelListViewModelTests`, `PlaylistsViewModelTests`).
