# StanisLoveTV — Apple TV IPTV App

**Platform**: tvOS 27+ | **UI**: SwiftUI only | **Architecture**: Clean Architecture | **Language**: Swift 5.9+

IPTV player for Apple TV: M3U playlist management, channel browsing, EPG guide, video playback.

---

## Getting Started

1. **Xcode**: latest release (`APPLETVOS_DEPLOYMENT_TARGET = 27`)
2. **Packages**: Xcode → File → Packages → Resolve, or `xcodebuild -resolvePackageDependencies`
3. **Run**: scheme `StanisLoveTV` + Apple TV Simulator → ⌘R
4. **Tests**: ⌘U or `xcodebuild test -scheme StanisLoveTV -destination 'platform=tvOS Simulator,name=Apple TV'`
5. **New feature**: run `planner` agent first — saves plan to `.claude/plans/`
6. **Before commit**: run `reviewer` agent

---

## Architecture

```
Presentation  →  Domain  ←  Data
    (UI)       (Business)  (Network/Storage)
```

Domain is framework-free. Data implements Domain protocols. Presentation calls use cases only.

Detailed rules: `.claude/rules/architecture.md` (always loaded)

## Project Structure

```
StanisLoveTV/
├── App/
├── Domain/
│   ├── Entities/          # Channel, Playlist, EPGProgram, Category
│   ├── Repositories/      # protocols only
│   └── UseCases/
├── Data/
│   ├── Parsers/           # M3UParser, XMLTVParser
│   ├── Network/           # NetworkService, Endpoint
│   ├── Persistence/
│   │   ├── DatabaseStack.swift
│   │   ├── Migrations/
│   │   └── Tables/        # @Table nonisolated structs + domainModel extensions
│   └── Repositories/      # DefaultXxxRepository
├── Presentation/
│   ├── Player/
│   ├── Channels/
│   ├── EPG/
│   ├── Playlists/
│   └── Settings/
├── Core/
│   ├── Dependencies/      # DependencyValues+.swift
│   └── Constants/         # Spacing.swift, Typography.swift
└── Tests/
    ├── DomainTests/
    ├── DataTests/
    └── PresentationTests/
```

---

## Key Dependencies

```swift
.package(url: "https://github.com/pointfreeco/swift-dependencies", from: "1.3.0"),
.package(url: "https://github.com/pointfreeco/sqlite-data", from: "1.4.0"),
.package(url: "https://github.com/onevcat/Kingfisher", from: "8.0.0"),
```

SQLiteData brings GRDB + StructuredQueries transitively — don't add them separately.

---

## Anti-Patterns

- ❌ `AVPlayer` in a View struct — must live in `PlayerViewModel`
- ❌ M3U/EPG parsing on `@MainActor` — always background `Task`
- ❌ `UIApplication.shared` in Domain or Data layers
- ❌ Force-unwrap on stream URLs — validate at parse time
- ❌ `DispatchQueue.main.async` — use `@MainActor` + structured concurrency
- ❌ `@Model` (SwiftData) — this project uses SQLiteData `@Table`
- ❌ `ObservableObject` — use `@Observable`, tvOS 27 always supports it
- ❌ `.onExitCommand` missing on screens with custom navigation

---

## Project Agents

Agents live in `.claude/agents/`. Claude routes automatically, or use explicit commands.

| Agent | Как вызвать |
|-------|------------|
| `slt-planner` | "спланируй X", "plan X", "используй агент slt-planner" |
| `reviewer` | "проверь изменения", "review my changes", "используй агент reviewer" |

**slt-planner**: reads project context + existing plans → creates `.claude/plans/<feature>.md` with layers, steps, schema changes, DI registrations, tests, tvOS notes, DoD.

**reviewer**: reads `git diff` → runs 6 checklists (Architecture, SQLiteData, DI, tvOS/SwiftUI, Concurrency, Tests) → Critical 🔴 / Warnings 🟡 / Suggestions 🟢 + verdict.

---

## Detailed Rules (loaded on demand)

| File | Loads when |
|------|-----------|
| `.claude/rules/architecture.md` | always |
| `.claude/rules/tvos-ui.md` | editing Presentation/, *View.swift, *ViewModel.swift |
| `.claude/rules/persistence.md` | editing Data/Persistence/, Data/Repositories/ |
| `.claude/rules/networking.md` | editing Data/Network/, Data/Parsers/ |
| `.claude/rules/testing.md` | editing Tests/ |

---

## Git Commit Guidelines

- Never include "Co-Authored-By: Claude" or any AI co-authoring references
- Keep commit messages clean and attributed solely to the human author
