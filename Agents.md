# StreakBar — Agent Guidelines

StreakBar is a native macOS menubar-only app (no Dock icon) that displays GitHub contribution activity. It is built with **AppKit** for the OS-level shell and **SwiftUI** for all UI rendering, following a lightweight MVVM pattern.

---

## Project Structure

```
streak-bar/streak-bar/
├── AppDelegate.swift          # App entry point, NSStatusItem, popover, hourly timer
├── ViewModel.swift            # ObservableObject — all @Published state
├── Theme.swift                # Theme name → per-level Color dictionary
├── ColorExtension.swift       # Color(hex:) initializer
├── ViewController.swift       # Unused Xcode stub
├── GitHub/
│   ├── Client.swift           # GitHub GraphQL API networking (Alamofire)
│   └── Dto.swift              # Codable response models
├── Settings/
│   ├── Settings.swift         # Defaults keys + ViewMode enum
│   └── Keychain.swift         # @KeychainStorage property wrapper
└── Views/
    ├── ContentView.swift
    ├── StatusItemView.swift    # Menu bar contribution heat-map
    ├── CommitsChartView.swift  # Popover bar chart + stats
    ├── SettingsView.swift      # Settings form window
    ├── OnboardingView.swift    # First-launch wizard
    ├── AboutView.swift
    ├── ThemeCardView.swift
    ├── HoverableLabel.swift
    └── ViewExtension.swift     # Mouse hover tracking (AppKit bridge)
```

---

## Architecture

### Entry Point — `AppDelegate`
The central coordinator. It owns the `NSStatusItem`, `NSPopover`, and the single shared `ViewModel` instance. It drives an hourly `Timer` that calls `redrawBarItem()`, which tears down and rebuilds the entire menu bar subview hierarchy and triggers fresh API fetches. Settings and About are presented as standalone `NSWindow` instances.

### Data Layer — `ViewModel`
A single `ObservableObject` created in `AppDelegate` and passed by reference to all views. Key `@Published` properties:
- `contributions: [ContributionWeek]` — heat-map data for the menu bar.
- `contributionsByRepo: [CommitContributionsByRepository]` — per-repo breakdown for the popover chart.
- `loadingState` / `chartLoadingState` — `LoadingState` enum (`idle | loading | success | error(String)`).
- `lastUpdateTime: Date?` — surfaced in the context menu and tooltips.

There is **no local cache**. All data lives in memory and is re-fetched on launch and every hour.

### Networking — `GitHub/Client.swift`
All API calls use the **GitHub GraphQL API** (`POST https://api.github.com/graphql`). There are two queries:
1. `getContributions(from:completion:)` — fetches the contribution calendar for the menu bar heat-map.
2. `getContributionsByRepository(from:maxRepos:completion:)` — fetches per-repository commit counts for the popover stacked bar chart.

All network callbacks dispatch back to the main queue before mutating `@Published` properties.

### UI
- **Menu bar item**: `StatusItemView` embedded in `NSStatusItem.button` as an `NSHostingView`.
- **Popover**: `CommitsChartView` inside an `NSHostingController`, shown on left-click.
- **Settings / About**: Separate `NSWindow` instances using `NSHostingController`.
- The popover's chart uses Apple's native **Charts** framework (`BarMark` stacked by repository).

---

## Dependencies

### Alamofire — HTTP Networking
Used exclusively in `GitHub/Client.swift` for all network requests to the GitHub GraphQL API. Use `AF.request(...)` with `.responseDecodable` for all new API calls. Do not introduce `URLSession` directly.

```swift
AF.request(url, method: .post, parameters: body, encoder: JSONParameterEncoder.default,
           headers: headers)
  .validate()
  .responseDecodable(of: MyResponse.self) { response in ... }
```

### Defaults — User Preferences
[`sindresorhus/Defaults`](https://github.com/sindresorhus/Defaults) provides a type-safe `UserDefaults` wrapper. All user preferences are declared as `Defaults.Keys` in `Settings/Settings.swift` and read/written via the `@Default` property wrapper. Views that declare `@Default(...)` automatically re-render on change.

```swift
// Declare a key (Settings/Settings.swift)
extension Defaults.Keys {
    static let myPreference = Key<Bool>("myPreference", default: true)
}

// Read/write anywhere
Defaults[.myPreference] = false
let value = Defaults[.myPreference]

// Reactive in SwiftUI
@Default(.myPreference) var myPreference: Bool
```

**Never store user preferences directly in `UserDefaults`. Always use `Defaults`.**

### KeychainAccess — Secret Storage
The GitHub Personal Access Token is stored exclusively in the macOS Keychain via the [`kishikawakatsuki/KeychainAccess`](https://github.com/kishikawakatsuki/KeychainAccess) library. It is **never written to `UserDefaults`**.

Access is wrapped in the custom `@KeychainStorage` / `@FromKeychain` property wrapper defined in `Settings/Keychain.swift`, which implements `DynamicProperty` so SwiftUI views react to Keychain changes. A shared `ObservablesStore` dictionary prevents duplicate instances across re-renders.

```swift
// Usage in a view or model
@FromKeychain(.githubToken) var token: String
```

For any new secret (API keys, tokens), follow the same pattern: add a `KeychainAccessKey` case and use `@FromKeychain`.

### LaunchAtLogin-Modern
[`sindresorhus/LaunchAtLogin-Modern`](https://github.com/sindresorhus/LaunchAtLogin-Modern) provides `LaunchAtLogin.Toggle` — a SwiftUI toggle wired to `SMAppService`. Used in `SettingsView.swift`.

---

## Key Conventions

- **No Dock icon**: The app uses `.accessory` activation policy. Do not change this.
- **Single ViewModel**: Do not create additional `ObservableObject` view models. Pass the existing `ViewModel` instance down through views.
- **Dynamic menu bar width**: Always call `appDelegate.redrawBarItem()` after any setting change that affects the menu bar layout.
- **Settings changes**: Every control in `SettingsView` calls `appDelegate.redrawBarItem()` immediately on change.
- **Motion**: All animations must check `accessibilityReduceMotion` before running.
- **Security**: The GitHub PAT must only ever be read or written through `@FromKeychain`. Never log or expose it.
- **Main queue**: All `@Published` property mutations must happen on `DispatchQueue.main`.
