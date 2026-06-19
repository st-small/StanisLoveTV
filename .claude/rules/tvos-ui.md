---
paths:
  - "StanisLoveTV/Presentation/**"
  - "StanisLoveTV/**/*View.swift"
  - "StanisLoveTV/**/*ViewModel.swift"
---

# tvOS UI Rules

## Focus Engine

- All interactive elements must be focusable — never disable the focus ring without reason
- `focusSection()` groups focusable items (sidebar vs content area)
- `@FocusState` for programmatic focus control
- Never rely on tap gestures alone — always handle remote button commands

```swift
struct ChannelCardView: View {
    let channel: Channel
    @FocusState private var isFocused: Bool

    var body: some View {
        ChannelCard(channel: channel)
            .focusable()
            .focused($isFocused)
            .scaleEffect(isFocused ? 1.1 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: isFocused)
            .accessibilityLabel("\(channel.name), \(channel.groupTitle)")
            .accessibilityHint("Play channel")
            .accessibilityAddTraits(.isButton)
    }
}
```

## Remote Control Handlers

```swift
.onPlayPauseCommand { viewModel.togglePlayback() }
.onExitCommand { viewModel.handleBack() }
.onMoveCommand { direction in
    switch direction {
    case .up:    viewModel.moveFocusUp()
    case .down:  viewModel.moveFocusDown()
    default:     break
    }
}
```

Every screen with custom navigation must handle `.onExitCommand`. Omitting it breaks the Menu button.

## 10-Foot UI

- Minimum interactive target: 100×100pt
- Body text: 17pt minimum. Titles: 28pt minimum
- High contrast — viewed from 3m
- Horizontal channel lists: `ScrollView(.horizontal)` + `LazyHStack`
- No dense layouts — generous padding

## Design Constants — use these, no magic numbers

```swift
enum Spacing {
    static let xs: CGFloat = 8
    static let sm: CGFloat = 16
    static let md: CGFloat = 24
    static let lg: CGFloat = 40
    static let xl: CGFloat = 60
}

enum TVSize {
    static let channelCardWidth: CGFloat = 300
    static let channelCardHeight: CGFloat = 170
    static let thumbnailCornerRadius: CGFloat = 12
}
```

## Video Playback

- `AVPlayerViewController` via `UIViewControllerRepresentable` — system controls included, do not rebuild them
- `AVPlayer` owned by `PlayerViewModel`, never by a View struct
- HLS (`.m3u8`) is the primary stream format
- Retry: 3× with exponential backoff, then show error with retry button
- Use `transportBarCustomMenuItems` for channel-switching actions
- Use `customInfoViewController` for current EPG programme info
- Do not build a custom overlay for what the system transport bar already provides

```swift
struct VideoPlayerView: UIViewControllerRepresentable {
    let player: AVPlayer

    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let vc = AVPlayerViewController()
        vc.player = player
        vc.showsPlaybackControls = true
        return vc
    }

    func updateUIViewController(_ vc: AVPlayerViewController, context: Context) {
        vc.player = player
    }
}
```

## tvOS Accessibility

tvOS VoiceOver is focus-based (D-pad), not swipe-based:

- Focusable cards: `accessibilityLabel` = channel name + group, `accessibilityHint` = action
- EPG cards: `accessibilityValue` = programme title + time remaining
- Play/Pause button label must reflect current state ("Play" / "Pause")
- Decorative images: `Image(decorative:)` or `.accessibilityHidden(true)`
- Test: tvOS Simulator → Settings → Accessibility → VoiceOver
